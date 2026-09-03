import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'package:zoc/utils/compress_screenshot.dart';

Future<String?> captureScreenshotBase64() async {
  try {
    final mediaDevices = web.window.navigator.mediaDevices;

    final stream = await mediaDevices
        .getDisplayMedia(
          web.DisplayMediaStreamOptions(video: true.toJS),
        )
        .toDart;

    final video = web.document.createElement('video') as web.HTMLVideoElement
      ..autoplay = true
      ..muted = true
      ..srcObject = stream;

    web.document.body?.append(video);

    try {
      await _waitForVideoFrame(video);

      final width = video.videoWidth;
      final height = video.videoHeight;
      if (width == 0 || height == 0) {
        return null;
      }

      final canvas =
          web.document.createElement('canvas') as web.HTMLCanvasElement
            ..width = width
            ..height = height;
      final context = canvas.getContext('2d') as web.CanvasRenderingContext2D;
      context.drawImage(video, 0, 0, width, height);

      final dataUrl = canvas.toDataURL('image/png');
      const prefix = 'data:image/png;base64,';
      if (!dataUrl.startsWith(prefix)) {
        return null;
      }

      final pngBytes = base64Decode(dataUrl.substring(prefix.length));
      return compressScreenshotBase64(pngBytes);
    } finally {
      _stopStream(stream);
      video.remove();
    }
  } catch (e) {
    debugPrint('Error al capturar en web: $e');
    return null;
  }
}

Future<void> _waitForVideoFrame(web.HTMLVideoElement video) {
  final completer = Completer<void>();

  video.onloadedmetadata = ((web.Event _) {
    video.play().toDart.then((_) {
      Future<void>.delayed(const Duration(milliseconds: 150), () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });
    }).catchError((Object _) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
  }).toJS;

  Future<void>.delayed(const Duration(seconds: 5), () {
    if (!completer.isCompleted) {
      completer.complete();
    }
  });

  return completer.future;
}

void _stopStream(web.MediaStream stream) {
  for (final track in stream.getTracks().toDart) {
    track.stop();
  }
}
