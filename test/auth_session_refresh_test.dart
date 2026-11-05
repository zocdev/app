import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:zoc/auth/auth_session.dart';
import 'package:zoc/auth/custom_auth/auth_util.dart';
import 'package:zoc/auth/custom_auth/custom_auth_user_provider.dart';
import 'package:zoc/backend/api_requests/api_manager.dart';
import 'package:zoc/desktop/pause_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<http.Request> requests;
  late Future<http.Response> Function(http.Request) handler;

  Future<T> withApi<T>(Future<T> Function() body) => http.runWithClient(
      body,
      () => MockClient((request) {
            requests.add(request);
            return handler(request);
          }));

  http.Response tokens(String access, String refresh) => http.Response(
      jsonEncode({
        'access_token': access,
        'refresh_token': refresh,
        'expires_in': 3600,
      }),
      200,
      headers: {'content-type': 'application/json'});

  Future<void> signIn({Duration expiresIn = const Duration(hours: 1)}) =>
      authManager.signIn(
        authenticationToken: 'old-access',
        refreshToken: 'old-refresh',
        tokenExpiration: DateTime.now().add(expiresIn),
        authUid: 'user-1',
      );

  setUp(() async {
    requests = [];
    // logout() clears the pause; keep it off the persisted app state.
    PauseController.instance =
        PauseController(readCache: () => null, writeCache: (_) {});
    handler = (_) async => tokens('new-access', 'new-refresh');
    ApiManager.configureAuthSession(
      accessTokenGetter: () => authManager.authenticationToken,
      tokenRefresher: AuthSession.refreshAccessToken,
      onUnauthorized: AuthSession.handleUnauthorized,
    );
    await signIn();
    ApiManager.syncAccessToken('old-access');
  });

  group('refresh outcome', () {
    test('200 rotates both tokens', () async {
      final outcome = await withApi(AuthSession.refresh);
      expect(outcome, RefreshOutcome.ok);
      expect(authManager.authenticationToken, 'new-access');
      expect(authManager.refreshToken, 'new-refresh');
      expect(authManager.uid, 'user-1');
    });

    test('401 is rejected', () async {
      handler = (_) async => http.Response('{"message":"x"}', 401);
      expect(await withApi(AuthSession.refresh), RefreshOutcome.rejected);
    });

    test('offline and 5xx are unavailable, tokens kept', () async {
      handler = (_) async => throw http.ClientException('offline');
      expect(await withApi(AuthSession.refresh), RefreshOutcome.unavailable);
      handler = (_) async => http.Response('{"message":"x"}', 503);
      expect(await withApi(AuthSession.refresh), RefreshOutcome.unavailable);
      expect(authManager.refreshToken, 'old-refresh');
      expect(zoc1AuthUserSubject.value.loggedIn, isTrue);
    });

    test('concurrent callers share one request', () async {
      final results = await withApi(() =>
          Future.wait([AuthSession.refresh(), AuthSession.refresh()]));
      expect(results, [RefreshOutcome.ok, RefreshOutcome.ok]);
      expect(requests, hasLength(1));
    });
  });

  group('refreshIfDue', () {
    test('does nothing while the token is far from expiring', () async {
      expect(await withApi(() => AuthSession.refreshIfDue()), isNull);
      expect(requests, isEmpty);
    });

    test('refreshes within 5 minutes of expiry', () async {
      await signIn(expiresIn: const Duration(minutes: 4));
      expect(await withApi(() => AuthSession.refreshIfDue()),
          RefreshOutcome.ok);
      expect(authManager.authenticationToken, 'new-access');
    });

    test('a network failure keeps the session', () async {
      await signIn(expiresIn: const Duration(minutes: -1));
      handler = (_) async => throw http.ClientException('offline');
      expect(await withApi(() => AuthSession.refreshIfDue()),
          RefreshOutcome.unavailable);
      expect(authManager.refreshToken, 'old-refresh');
    });

    test('a refused refresh token ends the session', () async {
      await signIn(expiresIn: const Duration(minutes: 1));
      handler = (_) async => http.Response('{"message":"x"}', 401);
      expect(await withApi(() => AuthSession.refreshIfDue()),
          RefreshOutcome.rejected);
      expect(authManager.authenticationToken, isNull);
      expect(zoc1AuthUserSubject.value.loggedIn, isFalse);
    });
  });

  group('401 on an API call', () {
    final url = 'http://localhost/api/v1/thing';

    Future<ApiCallResponse> call() => ApiManager.instance.makeApiCall(
          callName: 'Thing',
          apiUrl: url,
          callType: ApiCallType.GET,
          returnBody: true,
        );

    test('refreshes and retries with the new token', () async {
      handler = (request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          return tokens('new-access', 'new-refresh');
        }
        final ok = request.headers['authorization'] == 'Bearer new-access';
        return http.Response('{}', ok ? 200 : 401);
      };
      final result = await withApi(call);
      expect(result.statusCode, 200);
      expect(requests.map((r) => r.url.path),
          ['/api/v1/thing', '/api/v1/auth/refresh', '/api/v1/thing']);
    });

    test('offline refresh does not log out', () async {
      handler = (request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          throw http.ClientException('offline');
        }
        return http.Response('{}', 401);
      };
      await withApi(call);
      expect(zoc1AuthUserSubject.value.loggedIn, isTrue);
      expect(authManager.refreshToken, 'old-refresh');
    });

    test('refused refresh logs out', () async {
      handler = (_) async => http.Response('{}', 401);
      await withApi(call);
      expect(zoc1AuthUserSubject.value.loggedIn, isFalse);
    });

    test('token refreshed by another call meanwhile: retry, no new refresh',
        () async {
      handler = (request) async {
        // The token changed while this request was in flight.
        ApiManager.syncAccessToken('newer-access');
        final ok = request.headers['authorization'] == 'Bearer newer-access';
        return http.Response('{}', ok ? 200 : 401);
      };
      final result = await withApi(call);
      expect(result.statusCode, 200);
      expect(requests.where((r) => r.url.path.endsWith('/auth/refresh')),
          isEmpty);
    });
  });
}
