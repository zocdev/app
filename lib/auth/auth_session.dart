import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '/auth/custom_auth/auth_util.dart';
import '/backend/api_requests/api_config.dart';
import '/backend/api_requests/api_manager.dart';
import '/desktop/pause_controller.dart';

/// Outcome of `POST /auth/refresh`.
enum RefreshOutcome {
  ok,

  /// The API refused the refresh token (400 / 401 / 403): the session is over.
  rejected,

  /// No usable answer (offline, timeout, 5xx): the session may still be
  /// valid, try again later.
  unavailable,
}

class AuthSession {
  static Future<RefreshOutcome>? _refreshFuture;
  static RefreshOutcome? _lastOutcome;
  static Timer? _autoRefreshTimer;

  /// Refresh this long before the access token expires, so requests never
  /// run into an expired token (and a network blip at that moment is
  /// retried on the next tick instead of ending the session).
  static const Duration refreshAhead = Duration(minutes: 5);

  /// How often [startAutoRefresh] checks the token expiration.
  static const Duration autoRefreshInterval = Duration(seconds: 30);

  /// Outcome of the last finished refresh.
  static RefreshOutcome? get lastOutcome => _lastOutcome;

  /// Used by the ApiManager after a 401: true when a new token is ready.
  static Future<bool> refreshAccessToken() async =>
      await refresh() == RefreshOutcome.ok;

  /// One refresh at a time: concurrent callers share the request in flight.
  static Future<RefreshOutcome> refresh() async {
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }

    _refreshFuture = _performRefresh().then((outcome) => _lastOutcome = outcome);
    try {
      return await _refreshFuture!;
    } finally {
      _refreshFuture = null;
    }
  }

  static Future<RefreshOutcome> _performRefresh() async {
    final refreshToken = currentAuthRefreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return RefreshOutcome.rejected;
    }

    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${getBaseApiUrl()}/api/v1/auth/refresh'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(const Duration(seconds: 30));
    } catch (error) {
      if (kDebugMode) {
        print('AuthSession refresh error: $error');
      }
      return RefreshOutcome.unavailable;
    }

    if (response.statusCode != 200) {
      if (kDebugMode) {
        print(
          'AuthSession refresh failed: status=${response.statusCode} body=${response.body}',
        );
      }
      const refused = {400, 401, 403};
      return refused.contains(response.statusCode)
          ? RefreshOutcome.rejected
          : RefreshOutcome.unavailable;
    }

    // A logout or another login while the request was in flight wins.
    if (currentAuthRefreshToken != refreshToken) {
      return currentAuthRefreshToken == null
          ? RefreshOutcome.rejected
          : RefreshOutcome.ok;
    }

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return RefreshOutcome.unavailable;
    }
    final accessToken = data['access_token'] as String?;
    final newRefreshToken = data['refresh_token'] as String?;
    final expiresIn = data['expires_in'];

    if (accessToken == null || newRefreshToken == null) {
      return RefreshOutcome.unavailable;
    }

    DateTime? expiration;
    if (expiresIn is num) {
      expiration = DateTime.now().add(Duration(seconds: expiresIn.toInt()));
    }

    if (loggedIn) {
      await authManager.updateAuthUserData(
        authenticationToken: accessToken,
        refreshToken: newRefreshToken,
        tokenExpiration: expiration,
        authUid: authManager.uid,
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
    return RefreshOutcome.ok;
  }

  /// Checks every [autoRefreshInterval] and refreshes the access token once
  /// it is within [refreshAhead] of expiring. Uses the wall clock, so it
  /// catches up right after the computer wakes from sleep.
  static void startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer =
        Timer.periodic(autoRefreshInterval, (_) => unawaited(refreshIfDue()));
  }

  static void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  /// Refreshes when signed in and the token is about to expire. Ends the
  /// session only when the API refused the refresh token.
  static Future<RefreshOutcome?> refreshIfDue({DateTime? now}) async {
    final token = currentAuthenticationToken;
    final refreshToken = currentAuthRefreshToken;
    final expiration = currentAuthTokenExpiration;
    if (token == null || token.isEmpty) return null;
    if (refreshToken == null || refreshToken.isEmpty) return null;
    if (expiration == null) return null;
    final threshold = (now ?? DateTime.now()).add(refreshAhead);
    if (expiration.isAfter(threshold)) return null;

    final outcome = await refresh();
    if (outcome == RefreshOutcome.rejected &&
        currentAuthRefreshToken == refreshToken) {
      await logout(callBackend: false);
    }
    return outcome;
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
    // The API closes the open pause on /auth/logout.
    PauseController.instance.clear();
  }

  /// Called by the ApiManager when a 401 could not be fixed by a refresh.
  /// Ends the session only when the API refused the refresh token: a
  /// network failure keeps it, the next request or [refreshIfDue] retries.
  static Future<void> handleUnauthorized() async {
    if (_lastOutcome != RefreshOutcome.rejected) return;
    await logout(callBackend: false);
  }
}
