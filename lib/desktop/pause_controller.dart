import 'dart:async';

import 'package:flutter/foundation.dart';

import '/app_state.dart';
import '/backend/api_requests/api_calls.dart';

/// Reasons accepted by `POST /presence/pause`, with their chip labels.
const Map<String, String> kPauseReasons = {
  'almoco': 'Almoço',
  'cafe': 'Café',
  'reuniao_externa': 'Reunião externa',
  'pessoal': 'Pessoal',
  'outro': 'Outro',
};

/// Longest pause the API accepts (and the custom stepper allows).
const int kMaxPauseMinutes = 480;

/// After a 404 turned presence off, heartbeats try again after this long
/// (the API may have been updated, or the 404 came from the network).
const Duration kPresenceOffRetry = Duration(minutes: 10);

/// The server treats an open pause as ended 12 h after it started.
const Duration kPauseMaxAge = Duration(hours: 12);

/// Open pause as returned by `/presence/*` (`Pause` in the API contract).
@immutable
class PresencePause {
  const PresencePause({
    required this.id,
    required this.startedAt,
    this.plannedEndAt,
    this.reason,
  });

  final String id;
  final DateTime startedAt;

  /// Null for "Até eu voltar".
  final DateTime? plannedEndAt;
  final String? reason;

  bool get timed => plannedEndAt != null;
  String? get reasonLabel => kPauseReasons[reason];
  Duration? get planned => plannedEndAt?.difference(startedAt);

  static PresencePause? tryParse(dynamic json) {
    if (json is! Map) return null;
    final started = DateTime.tryParse('${json['started_at']}');
    if (started == null) return null;
    final end = json['planned_end_at'];
    return PresencePause(
      id: '${json['id'] ?? ''}',
      startedAt: started.toUtc(),
      plannedEndAt: end == null ? null : DateTime.tryParse('$end')?.toUtc(),
      reason: json['reason'] is String ? json['reason'] as String : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'started_at': startedAt.toUtc().toIso8601String(),
        'planned_end_at': plannedEndAt?.toUtc().toIso8601String(),
        'reason': reason,
      };

  @override
  bool operator ==(Object other) =>
      other is PresencePause &&
      other.id == id &&
      other.startedAt == startedAt &&
      other.plannedEndAt == plannedEndAt &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(id, startedAt, plannedEndAt, reason);
}

/// Outcome of a user action (pause / extend / resume).
enum PauseActionResult {
  ok,

  /// No answer from the API (offline, DNS, timeout).
  network,

  /// The API answered 404: it has no presence routes, the feature is off.
  unavailable,

  /// Any other non-2xx answer.
  failed,
}

/// Pause state of the signed-in worker. The server is the source of truth;
/// the last known pause is cached in [FFAppState.presencePause] so a restart
/// comes back paused before `GET /presence/me` answers.
class PauseController extends ChangeNotifier {
  PauseController({
    DateTime Function()? clock,
    Map<String, dynamic>? Function()? readCache,
    void Function(Map<String, dynamic>?)? writeCache,
  })  : _clock = clock ?? DateTime.now,
        _readCache = readCache ?? (() => FFAppState().presencePause),
        _writeCache =
            writeCache ?? ((value) => FFAppState().presencePause = value);

  /// Shared by the home screen and the Windows tray.
  static PauseController instance = PauseController();

  final DateTime Function() _clock;
  final Map<String, dynamic>? Function() _readCache;
  final void Function(Map<String, dynamic>?) _writeCache;

  PresencePause? _pause;
  bool _available = false;
  bool _off = false;
  DateTime? _offAt;
  Duration _skew = Duration.zero;
  int _sent = 0;
  int _applied = 0;
  bool _busy = false;
  bool _signedOut = false;

  /// Set by the home screen: opens the "Pausar registros" sheet (tray
  /// "Personalizado…").
  VoidCallback? onOpenSheetRequested;

  PresencePause? get pause => _pause;
  bool get isPaused => _pause != null;

  /// True once a presence call succeeded and none answered 404.
  bool get available => _available && !_off;

  /// A presence call answered 404 (old API): no pause, no heartbeats.
  bool get off => _off;

  /// [clear] ran (logout) and no presence call succeeded since.
  bool get signedOut => _signedOut;

  /// An action (pause / extend / resume) is in flight.
  bool get busy => _busy;

  /// Wall clock corrected by the server clock (UTC).
  DateTime now() => _clock().toUtc().add(_skew);

  /// The planned end of a timed pause has passed.
  bool get isExpired {
    final end = _pause?.plannedEndAt;
    return end != null && !now().isBefore(end);
  }

  /// Time left on a timed pause (negative once overdue).
  Duration? get remaining => _pause?.plannedEndAt?.difference(now());

  Duration get elapsed =>
      _pause == null ? Duration.zero : now().difference(_pause!.startedAt);

  /// Loads the cached pause (no network). Call once at startup.
  void restoreFromCache() {
    final cached = PresencePause.tryParse(_readCache());
    final pause = _fresh(cached);
    if (pause == null && cached != null) _writeCache(null);
    if (pause == _pause) return;
    _pause = pause;
    if (pause != null) _available = true;
    notifyListeners();
  }

  /// `GET /presence/me`: restores the server state.
  Future<PauseActionResult> refresh() => _send(() => PresenceCall.me());

  /// `POST /presence/heartbeat` (every 60 s). While the feature is off it
  /// only tries again every [kPresenceOffRetry].
  Future<void> heartbeat() async {
    if (_off) {
      final offAt = _offAt;
      if (offAt != null && _clock().difference(offAt) < kPresenceOffRetry) {
        return;
      }
      _off = false;
    }
    await _send(() => PresenceCall.heartbeat());
  }

  /// Starts a pause of [minutes] (1..480) or, when null, until resumed.
  Future<PauseActionResult> startPause({int? minutes, String? reason}) =>
      _action(() => PresenceCall.pause(minutes: minutes, reason: reason));

  /// Adds [minutes] to the open timed pause.
  Future<PauseActionResult> extend(int minutes) async {
    final result = await _action(() => PresenceCall.extend(minutes: minutes));
    // 409 no_open_pause / pause_indefinite: the local state is stale.
    if (result == PauseActionResult.failed) unawaited(refresh());
    return result;
  }

  /// Ends the open pause (idempotent on the server).
  Future<PauseActionResult> resume() => _action(() => PresenceCall.resume());

  /// Asks the home screen to open the pause sheet.
  void requestSheet() => onOpenSheetRequested?.call();

  /// Forgets the pause (logout). The server closes it on `/auth/logout`.
  void clear() {
    _sent++;
    _applied = _sent;
    _writeCache(null);
    _pause = null;
    _available = false;
    _off = false;
    _offAt = null;
    _signedOut = true;
    notifyListeners();
  }

  Future<PauseActionResult> _action(
      Future<ApiCallResponse> Function() call) async {
    if (_off) return PauseActionResult.unavailable;
    _busy = true;
    notifyListeners();
    try {
      return await _send(call);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<PauseActionResult> _send(
      Future<ApiCallResponse> Function() call) async {
    if (_off) return PauseActionResult.unavailable;
    final seq = ++_sent;
    final ApiCallResponse response;
    try {
      response = await call();
    } catch (_) {
      return PauseActionResult.network;
    }
    // Only the API's own JSON 404 means "no presence routes": an HTML 404
    // from a proxy or captive portal is a network problem.
    if (response.statusCode == 404 && response.jsonBody is Map) {
      _off = true;
      _offAt = _clock();
      _setPause(null);
      notifyListeners();
      return PauseActionResult.unavailable;
    }
    if (response.statusCode <= 0 || response.statusCode == 404) {
      return PauseActionResult.network;
    }
    if (!response.succeeded) return PauseActionResult.failed;
    // An older request that answers late must not undo a newer one.
    if (seq < _applied) return PauseActionResult.ok;
    _applied = seq;
    _applyMe(response.jsonBody);
    return PauseActionResult.ok;
  }

  void _applyMe(dynamic body) {
    final wasAvailable = _available;
    _available = true;
    _signedOut = false;
    if (body is Map) {
      final serverTime = DateTime.tryParse('${body['server_time']}');
      if (serverTime != null) {
        _skew = serverTime.toUtc().difference(_clock().toUtc());
      }
    }
    final pause =
        body is Map ? _fresh(PresencePause.tryParse(body['pause'])) : null;
    final changed = _setPause(pause);
    if (changed || !wasAvailable) notifyListeners();
  }

  bool _setPause(PresencePause? pause) {
    if (pause == _pause) return false;
    _pause = pause;
    _writeCache(pause?.toJson());
    return true;
  }

  PresencePause? _fresh(PresencePause? pause) {
    if (pause == null) return null;
    return now().difference(pause.startedAt) >= kPauseMaxAge ? null : pause;
  }
}

/// "13:15" in local time.
String pauseClock(DateTime time) {
  final local = time.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

/// "15 min", "1 h", "1 h 20 min".
String pauseDurationLabel(Duration duration) {
  final minutes = duration.inMinutes < 0 ? 0 : duration.inMinutes;
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '$m min';
  return m == 0 ? '$h h' : '$h h $m min';
}

/// Countdown of a timed pause, rounded up: "faltam 23 min", "faltam 40 s".
String pauseRemainingLabel(Duration remaining) {
  final ms = remaining.inMilliseconds;
  if (ms >= Duration.millisecondsPerMinute) {
    final minutes = (ms / Duration.millisecondsPerMinute).ceil();
    return 'faltam ${pauseDurationLabel(Duration(minutes: minutes))}';
  }
  final seconds = (ms / Duration.millisecondsPerSecond).ceil();
  return 'faltam ${seconds < 0 ? 0 : seconds} s';
}
