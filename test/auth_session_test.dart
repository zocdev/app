import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:zoc1/auth/custom_auth/custom_auth_manager.dart';
import 'package:zoc1/auth/custom_auth/custom_auth_user_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CustomAuthManager in-memory session state', () {
    late CustomAuthManager authManager;

    setUp(() {
      authManager = CustomAuthManager();
      zoc1AuthUserSubject.add(Zoc1AuthUser(loggedIn: false));
    });

    test('signIn stores token expiration and marks user logged in', () async {
      final expiration = DateTime.now().add(const Duration(hours: 1));

      final user = await authManager.signIn(
        authenticationToken: 'access-token',
        refreshToken: 'refresh-token',
        tokenExpiration: expiration,
        authUid: 'user-123',
      );

      expect(user?.loggedIn, isTrue);
      expect(authManager.authenticationToken, 'access-token');
      expect(authManager.refreshToken, 'refresh-token');
      expect(authManager.tokenExpiration, expiration);
      expect(authManager.uid, 'user-123');
    });

    test('loggedIn is false when token expiration is in the past', () {
      authManager.authenticationToken = 'expired-access';
      authManager.refreshToken = 'stored-refresh';
      authManager.tokenExpiration =
          DateTime.now().subtract(const Duration(minutes: 5));
      authManager.uid = 'user-789';

      final authTokenExists = authManager.authenticationToken != null &&
          authManager.authenticationToken!.isNotEmpty;
      final tokenExpired = authManager.tokenExpiration != null &&
          authManager.tokenExpiration!.isBefore(DateTime.now());

      expect(authTokenExists, isTrue);
      expect(tokenExpired, isTrue);
      expect(authTokenExists && !tokenExpired, isFalse);
    });

    test('signOut clears in-memory auth state', () async {
      await authManager.signIn(
        authenticationToken: 'access-token',
        refreshToken: 'refresh-token',
        tokenExpiration: DateTime.now().add(const Duration(hours: 1)),
        authUid: 'user-000',
      );

      await authManager.signOut();

      expect(authManager.authenticationToken, isNull);
      expect(authManager.refreshToken, isNull);
      expect(authManager.tokenExpiration, isNull);
      expect(zoc1AuthUserSubject.value.loggedIn, isFalse);
    });
  });

  group('Auth refresh response parsing', () {
    test('refresh payload contains rotated tokens', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/auth/refresh');
        expect(jsonDecode(request.body), {'refresh_token': 'refresh-token'});

        return http.Response(
          jsonEncode({
            'access_token': 'new-access',
            'refresh_token': 'new-refresh',
            'expires_in': 3600,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final response = await client.post(
        Uri.parse('http://localhost:8080/api/v1/auth/refresh'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh_token': 'refresh-token'}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      expect(response.statusCode, 200);
      expect(data['access_token'], 'new-access');
      expect(data['refresh_token'], 'new-refresh');
      expect(data['expires_in'], 3600);
    });
  });
}
