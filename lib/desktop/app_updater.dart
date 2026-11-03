import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'update_config.dart';

class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.downloadUrl,
    this.notes,
  });

  final String version;
  final String downloadUrl;
  final String? notes;
}

class AppUpdater {
  AppUpdater._();

  static bool get isDesktopSupported =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS);

  static Future<UpdateInfo?> checkForUpdate() async {
    if (!isDesktopSupported) return null;

    try {
      final response = await http
          .get(Uri.parse(kDesktopUpdateFeedUrl))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        if (kDebugMode) {
          print('Update feed HTTP ${response.statusCode}');
        }
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final remoteVersion = (data['version'] as String?)?.trim();
      if (remoteVersion == null || remoteVersion.isEmpty) return null;

      final downloadUrl = Platform.isWindows
          ? data['windows'] as String?
          : data['macos'] as String?;
      if (downloadUrl == null || downloadUrl.isEmpty) return null;

      final info = await PackageInfo.fromPlatform();
      final localVersion = info.version.trim();
      if (kDebugMode) {
        print(
          'AppUpdater: local="$localVersion" (build "${info.buildNumber}"), remote="$remoteVersion"',
        );
      }
      if (localVersion.isEmpty || !isNewer(remoteVersion, localVersion)) {
        return null;
      }

      return UpdateInfo(
        version: remoteVersion,
        downloadUrl: downloadUrl,
        notes: data['notes'] as String?,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Update check failed: $e');
      }
      return null;
    }
  }

  /// Downloads the zip, stages files, spawns a restart helper, then exits.
  static Future<void> downloadAndApply(UpdateInfo update) async {
    final tempDir = await getTemporaryDirectory();
    final workDir = Directory(
      '${tempDir.path}${Platform.pathSeparator}zoc_update_${update.version}',
    );
    if (await workDir.exists()) {
      await workDir.delete(recursive: true);
    }
    await workDir.create(recursive: true);

    final zipPath = '${workDir.path}${Platform.pathSeparator}update.zip';
    final zipFile = File(zipPath);

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(update.downloadUrl));
      final streamed = await client.send(request).timeout(
            const Duration(minutes: 5),
          );
      if (streamed.statusCode != 200) {
        throw Exception('Download HTTP ${streamed.statusCode}');
      }
      await streamed.stream.pipe(zipFile.openWrite());
    } finally {
      client.close();
    }

    final extractDir = Directory(
      '${workDir.path}${Platform.pathSeparator}extracted',
    );
    await extractDir.create(recursive: true);
    await extractFileToDisk(zipPath, extractDir.path);

    if (Platform.isWindows) {
      await _applyWindows(extractDir, workDir);
    } else if (Platform.isMacOS) {
      await _applyMacos(extractDir, workDir);
    }
  }

  static Future<void> _applyWindows(
    Directory extractDir,
    Directory workDir,
  ) async {
    final exePath = Platform.resolvedExecutable;
    final installDir = File(exePath).parent.path;
    final staged = _findFile(extractDir, 'zoc.exe')?.parent;
    if (staged == null) {
      throw Exception('Windows release folder not found in zip');
    }

    final psScriptPath =
        '${workDir.path}${Platform.pathSeparator}apply_update.ps1';
    // Relay .bat breaks the Windows Job Object so PowerShell survives
    // after the Flutter parent process exits.
    final batRelayPath =
        '${workDir.path}${Platform.pathSeparator}launch_updater.bat';
    final targetPid = pid;
    final logPath = '${workDir.path}${Platform.pathSeparator}update.log';

    // NOTE: Do NOT use $ErrorActionPreference = "Stop" at the top level —
    // it causes the script to terminate silently on any transient error
    // (e.g. antivirus file lock). We handle errors per-block instead.
    final psScript = '''
\$targetPid = $targetPid
\$source = "${_ps(staged.path)}"
\$dest = "${_ps(installDir)}"
\$exe = "${_ps(exePath)}"
\$logFile = "${_ps(logPath)}"

function Write-Log(\$msg) {
  try {
    "[\$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] \$msg" | `
      Out-File -FilePath \$logFile -Append -Encoding utf8
  } catch {}
}

Write-Log "Updater started. Waiting for PID \$targetPid to exit..."
\$waited = 0
while (Get-Process -Id \$targetPid -ErrorAction SilentlyContinue) {
  Start-Sleep -Milliseconds 400
  \$waited += 400
  if (\$waited -gt 60000) {
    Write-Log "Timed out waiting for process to exit."
    exit 1
  }
}
Start-Sleep -Seconds 2
Write-Log "Process exited. Beginning file copy from \$source to \$dest"

# Use robocopy — purpose-built for reliable Windows file copying with retries.
# /E  = include subdirectories (even empty)
# /PURGE = delete files in dest that don't exist in source
# /R:10 = retry 10 times per file
# /W:2  = wait 2 seconds between retries
# /NFL /NDL /NJH /NJS /NC /NS = suppress verbose output
\$roboResult = robocopy "\$source" "\$dest" /E /PURGE /R:10 /W:2 /NFL /NDL /NJH /NJS /NC /NS
\$exitCode = \$LASTEXITCODE

# Robocopy exit codes < 8 are success (0-7 = OK, 8+ = error), but it also
# returns 0 when it cannot open the destination folder (access denied), so
# check that zoc.exe really was replaced.
function Test-Copied {
  \$a = (Get-FileHash (Join-Path \$source "zoc.exe") -ErrorAction SilentlyContinue).Hash
  \$b = (Get-FileHash (Join-Path \$dest "zoc.exe") -ErrorAction SilentlyContinue).Hash
  return (\$a -and \$a -eq \$b)
}
if (\$exitCode -ge 8 -or -not (Test-Copied)) {
  Write-Log "Robocopy did not copy (exit code \$exitCode). Trying Copy-Item fallback..."
  \$retries = 5
  while (\$retries -gt 0) {
    try {
      Copy-Item -Path (Join-Path \$source "*") `
        -Destination \$dest -Recurse -Force -ErrorAction Stop
      if (-not (Test-Copied)) { throw "zoc.exe was not replaced" }
      Write-Log "Copy-Item fallback succeeded."
      \$exitCode = 0
      break
    } catch {
      \$retries--
      Write-Log "Copy-Item attempt failed: \$_. Retries left: \$retries"
      if (\$retries -eq 0) {
        Write-Log "All copy attempts failed. Reopening the current version."
      }
      Start-Sleep -Seconds 2
    }
  }
} else {
  Write-Log "Robocopy completed (code \$exitCode)."
}

\$already = Get-Process -Name "zoc" -ErrorAction SilentlyContinue
if (\$already) {
  Write-Log "Zoc already running (PID \$(\$already.Id)). Skipping extra launch."
} else {
  Write-Log "Launching updated app: \$exe"
  \$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
      [Security.Principal.WindowsBuiltInRole]::Administrator)
  try {
    # Elevated: start Zoc through the shell so it runs as the normal user.
    if (\$isAdmin) { throw "elevated" }
    \$proc = Start-Process -FilePath \$exe `
      -WorkingDirectory \$dest -WindowStyle Normal -PassThru
    Write-Log "App launched with PID \$(\$proc.Id)."
  } catch {
    Write-Log "Direct launch failed: \$_. Trying via explorer..."
    try {
      Start-Process "explorer.exe" -ArgumentList "`"\$exe`""
      Write-Log "Launched via explorer.exe."
    } catch {
      Write-Log "Explorer fallback also failed: \$_"
    }
  }
}
Write-Log "Updater finished."
''';

    final batRelay = _relayBat(psScriptPath);
    await File(psScriptPath).writeAsString(psScript);
    await File(batRelayPath).writeAsString(batRelay);

    if (!await _canWrite(Directory(installDir))) {
      // Per-machine install (Program Files): copying needs admin rights.
      // Ask for them (UAC) and run the same script elevated. If the user
      // declines, Zoc keeps running and shows the error.
      await _runElevated(psScriptPath, workDir);
      exit(0);
    }

    // Launch via cmd.exe — this creates the PowerShell process outside the
    // Flutter job object so it won't be killed when Flutter exits.
    await Process.start(
      'cmd.exe',
      ['/c', batRelayPath],
      workingDirectory: workDir.path,
      mode: ProcessStartMode.detached,
    );

    exit(0);
  }

  static Future<void> _applyMacos(
    Directory extractDir,
    Directory workDir,
  ) async {
    final exePath = Platform.resolvedExecutable;
    // .../zoc.app/Contents/MacOS/zoc
    final appBundle = File(exePath).parent.parent.parent;
    final stagedApp = _findMacAppBundle(extractDir);
    if (stagedApp == null) {
      throw Exception('macOS .app not found in zip');
    }

    final scriptPath =
        '${workDir.path}${Platform.pathSeparator}apply_update.sh';
    final currentPid = pid;
    final script = '''
#!/bin/bash
set -e
TARGET_PID=$currentPid
SOURCE="${stagedApp.path}"
DEST="${appBundle.path}"

while kill -0 "\$TARGET_PID" 2>/dev/null; do
  sleep 0.4
done
sleep 1

rm -rf "\$DEST"
cp -R "\$SOURCE" "\$DEST"
chmod -R u+w "\$DEST" || true
xattr -cr "\$DEST" 2>/dev/null || true
open "\$DEST"
''';
    await File(scriptPath).writeAsString(script);
    await Process.run('chmod', ['+x', scriptPath]);

    await Process.start(
      '/bin/bash',
      [scriptPath],
      mode: ProcessStartMode.detached,
    );

    exit(0);
  }

  static Future<bool> _canWrite(Directory dir) async {
    final probe = File(
      '${dir.path}${Platform.pathSeparator}.zoc_update_probe_$pid',
    );
    try {
      await probe.writeAsString('ok', flush: true);
      await probe.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _runElevated(
    String psScriptPath,
    Directory workDir,
  ) async {
    final sep = Platform.pathSeparator;
    final launcherPath = '${workDir.path}${sep}elevate_updater.ps1';
    final relayPath = '${workDir.path}${sep}elevate_updater.bat';
    final result = File('${workDir.path}${sep}elevate_result.txt');
    // Start-Process -Verb RunAs shows the UAC prompt and throws when the
    // user declines. The elevated PowerShell is started by Windows, so it
    // is outside any job object of this process. The answer comes back
    // through a file: PowerShell started without a console prints nothing.
    await File(launcherPath).writeAsString('''
\$result = Join-Path \$PSScriptRoot "elevate_result.txt"
try {
  \$script = Join-Path \$PSScriptRoot "apply_update.ps1"
  Start-Process -FilePath powershell.exe -Verb RunAs -WindowStyle Hidden `
    -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass",
      "-NonInteractive", "-WindowStyle", "Hidden", "-File", "`"\$script`"") `
    -ErrorAction Stop
  Set-Content -Path \$result -Value "elevated"
} catch {
  Set-Content -Path \$result -Value "denied: \$(\$_.Exception.Message)"
}
''');
    await File(relayPath).writeAsString(_relayBat(launcherPath));
    await Process.start(
      'cmd.exe',
      ['/c', relayPath],
      workingDirectory: workDir.path,
      mode: ProcessStartMode.detached,
    );

    // The UAC prompt waits for the user; give up after 10 minutes.
    final deadline = DateTime.now().add(const Duration(minutes: 10));
    var answer = '';
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!await result.exists()) continue;
      try {
        // Windows PowerShell writes the system ANSI code page, not UTF-8.
        answer = const Utf8Decoder(allowMalformed: true)
            .convert(await result.readAsBytes())
            .trim();
      } on FileSystemException {
        continue; // PowerShell is still writing it.
      }
      if (answer.isNotEmpty) break;
    }
    if (!answer.startsWith('elevated')) {
      if (kDebugMode) print('Elevation failed: $answer');
      throw Exception(
        'é preciso permitir a atualização como administrador. '
        'Tente de novo e clique em "Sim".',
      );
    }
  }

  /// cmd relay: "start /b" puts PowerShell in a new process group, outside
  /// the Flutter job object, so it survives when this process exits.
  static String _relayBat(String psScriptPath) => '''
@echo off
start "" /b powershell.exe -NoProfile -ExecutionPolicy Bypass -NonInteractive -WindowStyle Hidden -File "${psScriptPath.replaceAll('/', '\\')}"
exit /b 0
''';

  static Directory? _findMacAppBundle(Directory root) {
    try {
      for (final entity in root.listSync(recursive: true)) {
        if (entity is Directory && entity.path.endsWith('.app')) {
          return entity;
        }
      }
    } catch (_) {}
    return null;
  }

  static File? _findFile(Directory root, String name) {
    try {
      for (final entity in root.listSync(recursive: true)) {
        if (entity is File &&
            entity.uri.pathSegments.isNotEmpty &&
            entity.uri.pathSegments.last.toLowerCase() == name.toLowerCase()) {
          return entity;
        }
      }
    } catch (_) {}
    return null;
  }

  static String _ps(String path) => path.replaceAll('"', '`"');

  /// Compares dotted versions; build number (+N) is ignored.
  @visibleForTesting
  static bool isNewer(String remote, String local) {
    final r = _parseVersion(remote);
    final l = _parseVersion(local);
    for (var i = 0; i < 3; i++) {
      if (r[i] > l[i]) return true;
      if (r[i] < l[i]) return false;
    }
    return false;
  }

  static List<int> _parseVersion(String raw) {
    var core = raw.trim();
    if (core.toLowerCase().startsWith('v')) {
      core = core.substring(1).trim();
    }
    core = core.split('+').first.split('-').first.trim();
    final parts = core.split('.');
    return List<int>.generate(3, (i) {
      if (i >= parts.length) return 0;
      return int.tryParse(parts[i].trim()) ?? 0;
    });
  }
}
