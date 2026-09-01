export 'capture_screenshot_stub.dart'
    if (dart.library.io) 'capture_screenshot_io.dart'
    if (dart.library.js_interop) 'capture_screenshot_web.dart';
