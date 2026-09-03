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
      if (!_isNewer(remoteVersion, info.version)) return null;

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

    final scriptPath =
        '${workDir.path}${Platform.pathSeparator}apply_update.ps1';
    final targetPid = pid;
    final script = '''
\$ErrorActionPreference = "Stop"
\$targetPid = $targetPid
\$source = "${_ps(staged.path)}"
\$dest = "${_ps(installDir)}"
\$exe = "${_ps(exePath)}"

while (Get-Process -Id \$targetPid -ErrorAction SilentlyContinue) {
  Start-Sleep -Milliseconds 400
}
Start-Sleep -Seconds 1

Copy-Item -Path (Join-Path \$source "*") -Destination \$dest -Recurse -Force
Start-Process -FilePath \$exe
''';
    await File(scriptPath).writeAsString(script);

    await Process.start(
      'powershell.exe',
      [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-WindowStyle',
        'Hidden',
        '-File',
        scriptPath,
      ],
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
    final core = raw.split('+').first.replaceFirst(RegExp(r'^v'), '');
    final parts = core.split('.');
    return List<int>.generate(3, (i) {
      if (i >= parts.length) return 0;
      return int.tryParse(parts[i]) ?? 0;
    });
  }
}
