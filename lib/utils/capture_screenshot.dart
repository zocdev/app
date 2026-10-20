export 'capture_screenshot_stub.dart'
    if (dart.library.io) 'capture_screenshot_io.dart'
    if (dart.library.js_interop) 'capture_screenshot_web.dart';

import 'dart:convert';

import '/app_state.dart';

/// Reads screenshots_enabled from live UserData (default true if missing).
bool areScreenshotsEnabled({bool? override}) {
  if (override != null) return override;

  final raw = FFAppState().UserData;
  if (raw == null) return true;

  Map<String, dynamic>? userData;
  if (raw is Map<String, dynamic>) {
    userData = raw;
  } else if (raw is Map) {
    userData = Map<String, dynamic>.from(raw);
  } else if (raw is String) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        userData = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return true;
    }
  }

  final user = userData?['user'];
  if (user is! Map) return true;

  final flag = user['screenshots_enabled'];
  if (flag is bool) return flag;
  return true;
}
