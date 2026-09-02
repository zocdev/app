import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '/auth/custom_auth/auth_util.dart';
import '/backend/api_requests/api_config.dart';
import '/backend/api_requests/api_manager.dart';

class AuthSession {
  static Future<bool>? _refreshFuture;

  static Future<bool> refreshAccessToken() async {
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }

    _refreshFuture = _performRefresh();
    try {
      return await _refreshFuture!;
    } finally {
      _refreshFuture = null;
    }
  }

  static Future<bool> _performRefresh() async {
    final refreshToken = currentAuthRefreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('${getBaseApiUrl()}/api/v1/auth/refresh'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode != 200) {
        if (kDebugMode) {
          print(
            'AuthSession refresh failed: status=${response.statusCode} body=${response.body}',
          );
        }
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = data['access_token'] as String?;
      final newRefreshToken = data['refresh_token'] as String?;
      final expiresIn = data['expires_in'];

      if (accessToken == null || newRefreshToken == null) {
        return false;
      }

      DateTime? expiration;
      if (expiresIn is int) {
        expiration = DateTime.now().add(Duration(seconds: expiresIn));
      } else if (expiresIn is num) {
        expiration = DateTime.now().add(Duration(seconds: expiresIn.toInt()));
      }

      if (loggedIn) {
        await authManager.updateAuthUserData(
          authenticationToken: accessToken,
          refreshToken: newRefreshToken,
          tokenExpiration: expiration,
        );
      } else {
        await authManager.signIn(
          authenticationToken: accessToken,
          refreshToken: newRefreshToken,
          tokenExpiration: expiration,
          authUid: currentUserUid.isNotEmpty ? currentUserUid : authManager.uid,
        );
      }

      ApiManager.syncAccessToken(accessToken);
      return true;
    } catch (error) {
      if (kDebugMode) {
        print('AuthSession refresh error: $error');
      }
      return false;
    }
  }

  static Future<String?> getValidAccessToken() async {
    final token = currentAuthenticationToken;
    final expiration = currentAuthTokenExpiration;
    final refreshThreshold = DateTime.now().add(const Duration(minutes: 1));

    if (token != null &&
        token.isNotEmpty &&
        (expiration == null || expiration.isAfter(refreshThreshold))) {
      return token;
    }

    if (await refreshAccessToken()) {
      return currentAuthenticationToken;
    }

    return null;
  }

  static Future<void> logout({bool callBackend = true}) async {
    if (callBackend) {
      final token = currentAuthenticationToken;
      if (token != null && token.isNotEmpty) {
        try {
          await http.post(
            Uri.parse('${getBaseApiUrl()}/api/v1/auth/logout'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          );
        } catch (_) {}
      }
    }

    await authManager.signOut();
    ApiManager.syncAccessToken(null);
  }

  static Future<void> handleUnauthorized() async {
    final refreshed = await refreshAccessToken();
    if (!refreshed) {
      await logout(callBackend: false);
    }
  }
}
