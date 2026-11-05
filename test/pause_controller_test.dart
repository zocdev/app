import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zoc/backend/api_requests/api_manager.dart';
import 'package:zoc/desktop/pause_controller.dart';

http.Response json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json; charset=utf-8'});

final t0 = DateTime.utc(2026, 11, 3, 12, 15);

Map<String, dynamic> me({Map<String, dynamic>? pause, DateTime? serverTime}) =>
    {
      'status': pause == null ? 'active' : 'paused',
      'server_time': (serverTime ?? t0).toIso8601String(),
      'login_at': t0.subtract(const Duration(hours: 3)).toIso8601String(),
      'last_seen_at': t0.toIso8601String(),
      'pause': pause,
    };

Map<String, dynamic> pauseJson(
        {int? minutes = 30, String? reason = 'almoco', DateTime? started}) =>
    {
      'id': 'p1',
      'started_at': (started ?? t0).toIso8601String(),
      'planned_end_at': minutes == null
          ? null
          : (started ?? t0).add(Duration(minutes: minutes)).toIso8601String(),
      'reason': reason,
      'overdue': false,
    };

void main() {
  late DateTime now;
  late Map<String, dynamic>? cache;
  late List<http.Request> requests;
  late Future<http.Response> Function(http.Request) handler;

  PauseController controller() => PauseController(
        clock: () => now,
        readCache: () => cache,
        writeCache: (value) => cache = value,
      );

  Future<T> withApi<T>(Future<T> Function() body) => http.runWithClient(
      body,
      () => MockClient((request) {
            requests.add(request);
            return handler(request);
          }));

  setUp(() {
    now = t0;
    cache = null;
    requests = [];
    handler = (_) async => json(me());
    ApiManager.syncAccessToken('test-token');
  });

  test('refresh restores an open pause from the server and caches it',
      () async {
    handler = (_) async => json(me(pause: pauseJson()));
    final c = controller();
    expect(c.available, isFalse);
    await withApi(c.refresh);
    expect(requests.single.method, 'GET');
    expect(requests.single.url.path, '/api/v1/presence/me');
    expect(c.available, isTrue);
    expect(c.isPaused, isTrue);
    expect(c.pause!.plannedEndAt, t0.add(const Duration(minutes: 30)));
    expect(c.pause!.reasonLabel, 'Almoço');
    expect(cache!['id'], 'p1');
  });

  test('pause, extend and resume follow the server answers', () async {
    final c = controller();
    var notified = 0;
    c.addListener(() => notified++);
    handler = (request) async {
      final path = request.url.path;
      if (path.endsWith('/pause')) return json(me(pause: pauseJson()), 201);
      if (path.endsWith('/pause/extend')) {
        return json(me(pause: pauseJson(minutes: 45)));
      }
      return json(me());
    };
    await withApi(() async {
      expect(await c.startPause(minutes: 30, reason: 'almoco'),
          PauseActionResult.ok);
      expect(jsonDecode(requests.last.body),
          {'minutes': 30, 'reason': 'almoco'});
      expect(c.isPaused, isTrue);
      expect(c.remaining, const Duration(minutes: 30));

      expect(await c.extend(15), PauseActionResult.ok);
      expect(requests.last.url.path, '/api/v1/presence/pause/extend');
      expect(jsonDecode(requests.last.body), {'minutes': 15});
      expect(c.remaining, const Duration(minutes: 45));

      expect(await c.resume(), PauseActionResult.ok);
      expect(requests.last.url.path, '/api/v1/presence/resume');
      expect(c.isPaused, isFalse);
      expect(cache, isNull);
    });
    expect(notified, greaterThan(0));
  });

  test('"Até eu voltar" sends minutes null and has no planned end', () async {
    handler = (_) async =>
        json(me(pause: pauseJson(minutes: null, reason: null)), 201);
    final c = controller();
    await withApi(() => c.startPause());
    expect(jsonDecode(requests.single.body), {'minutes': null, 'reason': null});
    expect(c.pause!.timed, isFalse);
    now = t0.add(const Duration(hours: 1, minutes: 20));
    expect(c.isExpired, isFalse);
    expect(c.elapsed, const Duration(hours: 1, minutes: 20));
  });

  test('expiry follows the wall clock, corrected by the server clock',
      () async {
    // The PC clock runs 2 minutes behind the server.
    now = t0.subtract(const Duration(minutes: 2));
    handler = (_) async => json(me(pause: pauseJson(minutes: 15)));
    final c = controller();
    await withApi(c.refresh);
    expect(c.now(), t0);
    expect(c.isExpired, isFalse);

    // A sleeping PC never fires timers: only the wall clock moves.
    now = t0.add(const Duration(minutes: 12, seconds: 59));
    expect(c.isExpired, isFalse);
    now = t0.add(const Duration(minutes: 13));
    expect(c.isExpired, isTrue);
    expect(c.remaining, Duration.zero);
  });

  test('404 turns the feature off: no pause, no more heartbeats', () async {
    cache = pauseJson();
    final c = controller()..restoreFromCache();
    expect(c.isPaused, isTrue);
    handler = (_) async => json({'error': 'not found'}, 404);
    await withApi(() async {
      await c.heartbeat();
      expect(c.off, isTrue);
      expect(c.available, isFalse);
      expect(c.isPaused, isFalse);
      expect(cache, isNull);

      await c.heartbeat();
      expect(await c.startPause(minutes: 15), PauseActionResult.unavailable);
    });
    expect(requests, hasLength(1));
  });

  test('after a 404 heartbeats try again every 10 minutes', () async {
    handler = (_) async => json({'message': 'Not Found'}, 404);
    final c = controller();
    await withApi(() async {
      await c.heartbeat();
      expect(c.off, isTrue);
      now = t0.add(const Duration(minutes: 9));
      await c.heartbeat();
      expect(requests, hasLength(1));

      handler = (_) async => json(me());
      now = t0.add(const Duration(minutes: 10));
      await c.heartbeat();
    });
    expect(requests, hasLength(2));
    expect(c.off, isFalse);
    expect(c.available, isTrue);
  });

  test('an HTML 404 (proxy, captive portal) is a network error', () async {
    cache = pauseJson();
    final c = controller()..restoreFromCache();
    handler = (_) async => http.Response('<html>Not Found</html>', 404,
        headers: {'content-type': 'text/html'});
    await withApi(() async {
      await c.heartbeat();
      expect(await c.resume(), PauseActionResult.network);
    });
    expect(c.off, isFalse);
    expect(c.isPaused, isTrue);
    expect(cache, isNotNull);
  });

  test('logout turns presence back on for the next login', () async {
    handler = (_) async => json({'message': 'Not Found'}, 404);
    final c = controller();
    await withApi(() => c.heartbeat());
    expect(c.off, isTrue);
    c.clear();
    expect(c.off, isFalse);
    handler = (_) async => json(me());
    await withApi(() => c.heartbeat());
    expect(requests, hasLength(2));
  });

  test('network errors keep the current state', () async {
    handler = (_) async => throw http.ClientException('offline');
    final c = controller();
    await withApi(() async {
      expect(await c.startPause(minutes: 15), PauseActionResult.network);
    });
    expect(c.isPaused, isFalse);
    expect(c.busy, isFalse);
    expect(c.off, isFalse);
  });

  test('restart restores the cached pause, already expired or not', () async {
    cache = pauseJson(minutes: 15);
    now = t0.add(const Duration(minutes: 40));
    final c = controller()..restoreFromCache();
    expect(c.isPaused, isTrue);
    expect(c.available, isTrue);
    expect(c.isExpired, isTrue);
  });

  test('a cached pause older than 12 h is dropped', () {
    cache = pauseJson(minutes: null);
    now = t0.add(const Duration(hours: 12, minutes: 1));
    final c = controller()..restoreFromCache();
    expect(c.isPaused, isFalse);
    expect(cache, isNull);
  });

  test('extend 409 refreshes the stale local pause', () async {
    cache = pauseJson();
    final c = controller()..restoreFromCache();
    handler = (request) async => request.url.path.endsWith('/extend')
        ? json({'code': 'no_open_pause'}, 409)
        : json(me());
    await withApi(() async {
      expect(await c.extend(15), PauseActionResult.failed);
      await Future<void>.delayed(Duration.zero);
    });
    expect(requests.map((r) => r.url.path),
        ['/api/v1/presence/pause/extend', '/api/v1/presence/me']);
    expect(c.isPaused, isFalse);
  });

  test('clear forgets the pause on logout', () async {
    cache = pauseJson();
    final c = controller()..restoreFromCache();
    c.clear();
    expect(c.isPaused, isFalse);
    expect(c.available, isFalse);
    expect(cache, isNull);
  });

  test('labels', () {
    expect(pauseDurationLabel(const Duration(minutes: 30)), '30 min');
    expect(pauseDurationLabel(const Duration(minutes: 60)), '1 h');
    expect(pauseDurationLabel(const Duration(minutes: 80)), '1 h 20 min');
    expect(pauseRemainingLabel(const Duration(minutes: 22, seconds: 10)),
        'faltam 23 min');
    expect(pauseRemainingLabel(const Duration(seconds: 40)), 'faltam 40 s');
  });
}
