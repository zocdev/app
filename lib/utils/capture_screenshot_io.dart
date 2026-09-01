import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screen_capturer/screen_capturer.dart';
import 'package:zoc1/utils/compress_screenshot.dart';

Future<String?> captureScreenshotBase64() async {
  try {
    final dir = await getTemporaryDirectory();
    final filePath =
        '${dir.path}${Platform.pathSeparator}temp_screenshot.png';

    if (Platform.isWindows) {
      await ScreenCapturerPlatform.instance.captureScreen(
        imagePath: filePath,
      );
    } else if (Platform.isMacOS || Platform.isLinux) {
      await screenCapturer.capture(
        mode: CaptureMode.screen,
        imagePath: filePath,
        copyToClipboard: false,
        silent: true,
      );
    } else {
      debugPrint('Captura de pantalla no soportada en esta plataforma');
      return null;
    }

    final file = File(filePath);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      await file.delete();
      return compressScreenshotBase64(bytes);
    }

    debugPrint('Error al capturar: no se generó el archivo');
    return null;
  } catch (e) {
    debugPrint('Error inesperado: $e');
    return null;
  }
}
