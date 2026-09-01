import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

String? compressScreenshotBase64(
  Uint8List bytes, {
  int maxWidth = 1920,
  int quality = 75,
}) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  final resized = decoded.width > maxWidth
      ? img.copyResize(decoded, width: maxWidth)
      : decoded;

  return base64Encode(img.encodeJpg(resized, quality: quality));
}
