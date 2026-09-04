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
      if (localVersion.isEmpty || !_isNewer(remoteVersion, localVersion)) {
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

    final zipPath =
        '${workDir.path}${Platform.pathSeparator}update.zip';
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
      final sink = zipFile.openWrite();
      await streamed.stream.pipe(sink);
      await sink.close();
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
    final staged = _findWindowsReleaseDir(extractDir);
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
    final logPath =
        '${workDir.path}${Platform.pathSeparator}update.log';

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

# Robocopy exit codes < 8 are success (0-7 = OK, 8+ = error)
if (\$exitCode -ge 8) {
  Write-Log "Robocopy failed with exit code \$exitCode. Trying Copy-Item fallback..."
  \$retries = 5
  while (\$retries -gt 0) {
    try {
      Copy-Item -Path (Join-Path \$source "*") `
        -Destination \$dest -Recurse -Force -ErrorAction Stop
      Write-Log "Copy-Item fallback succeeded."
      \$exitCode = 0
      break
    } catch {
      \$retries--
      Write-Log "Copy-Item attempt failed: \$_. Retries left: \$retries"
      if (\$retries -eq 0) {
        Write-Log "All copy attempts failed. Aborting."
        exit 1
      }
      Start-Sleep -Seconds 2
    }
  }
} else {
  Write-Log "Robocopy completed (code \$exitCode)."
}

Write-Log "Launching updated app: \$exe"
try {
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
Write-Log "Updater finished."
''';

    // The relay batch file uses "start /b" which creates the PowerShell
    // process in a new process group, detached from the Flutter job object.
    // Without this, Windows kills PowerShell when the Flutter parent exits.
    final batRelay = '''
@echo off
start "" /b powershell.exe -NoProfile -ExecutionPolicy Bypass -NonInteractive -WindowStyle Hidden -File "${psScriptPath.replaceAll('/', '\\')}"
exit /b 0
''';
    await File(psScriptPath).writeAsString(psScript);
    await File(batRelayPath).writeAsString(batRelay);

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
open -n "\$DEST" || open "\$DEST"
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

  static Directory? _findWindowsReleaseDir(Directory root) {
    final exe = _findFile(root, 'zoc.exe');
    if (exe != null) return exe.parent;
    return null;
  }

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

  @visibleForTesting
  static bool isNewer(String remote, String local) => _isNewer(remote, local);

  /// Compares dotted versions; build number (+N) is ignored.
  static bool _isNewer(String remote, String local) {
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
