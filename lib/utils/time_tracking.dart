import 'dart:convert';

import '/app_state.dart';

/// Reads monitoring ("Controle de tempo") from live UserData (default true if
/// missing). When false, the app must not show popups or record time.
bool isTimeTrackingEnabled() => timeTrackingEnabledIn(FFAppState().UserData);

bool timeTrackingEnabledIn(dynamic raw) {
  dynamic userData = raw;
  if (raw is String) {
    try {
      userData = jsonDecode(raw);
    } catch (_) {
      return true;
    }
  }
  if (userData is! Map) return true;
  final user = userData['user'];
  if (user is! Map) return true;
  final flag = user['monitoring'];
  if (flag is bool) return flag;
  return true;
}
