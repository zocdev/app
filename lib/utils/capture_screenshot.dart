import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String?> captureScreenshotBase64() async {
  try {
    final dir = await getTemporaryDirectory();
    final filePath =
        '${dir.path}${Platform.pathSeparator}temp_screenshot.png';

    final ProcessResult result;
    if (Platform.isWindows) {
      result = await Process.run(
        r'C:\Program Files\Zoc\tools\nircmd.exe',
        ['savescreenshot', filePath],
        runInShell: false,
      );
    } else if (Platform.isMacOS) {
      result = await Process.run(
        'screencapture',
        ['-x', '-t', 'png', filePath],
        runInShell: false,
      );
    } else {
      print('Captura de pantalla no soportada en esta plataforma');
      return null;
    }

    if (result.exitCode == 0 && await File(filePath).exists()) {
      final bytes = await File(filePath).readAsBytes();
      final base64 = base64Encode(bytes);
      await File(filePath).delete();
      return base64;
    } else {
      print('Error al capturar: ${result.stderr}');
      return null;
    }
  } catch (e) {
    print('Error inesperado: $e');
    return null;
  }
}
