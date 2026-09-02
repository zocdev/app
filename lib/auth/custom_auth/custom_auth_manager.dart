import 'dart:async';

import 'package:flutter/foundation.dart';

import 'custom_auth_user_provider.dart';
import '/utils/secure_storage_service.dart';

export 'custom_auth_manager.dart';

const _kAuthTokenKey = '_auth_authentication_token_';
const _kRefreshTokenKey = '_auth_refresh_token_';
const _kTokenExpirationKey = '_auth_token_expiration_';
const _kUidKey = '_auth_uid_';

class CustomAuthManager {
  String? authenticationToken;
  String? refreshToken;
  DateTime? tokenExpiration;
  String? uid;

  SecureStorageService get _storage => SecureStorageService.instance;

  Future signOut() async {
    authenticationToken = null;
    refreshToken = null;
    tokenExpiration = null;
    uid = null;

    zoc1AuthUserSubject.add(
      Zoc1AuthUser(loggedIn: false),
    );
    await persistAuthData();
  }

  Future<Zoc1AuthUser?> signIn({
    String? authenticationToken,
    String? refreshToken,
    DateTime? tokenExpiration,
    String? authUid,
  }) async =>
      await _updateCurrentUser(
        authenticationToken: authenticationToken,
        refreshToken: refreshToken,
        tokenExpiration: tokenExpiration,
        authUid: authUid,
      );

  Future<void> updateAuthUserData({
    String? authenticationToken,
    String? refreshToken,
    DateTime? tokenExpiration,
    String? authUid,
  }) async {
    assert(
      currentUser?.loggedIn ?? false,
      'User must be logged in to update auth user data.',
    );

    await _updateCurrentUser(
      authenticationToken: authenticationToken,
      refreshToken: refreshToken,
      tokenExpiration: tokenExpiration,
      authUid: authUid,
    );
  }

  Future<Zoc1AuthUser?> _updateCurrentUser({
    String? authenticationToken,
    String? refreshToken,
    DateTime? tokenExpiration,
    String? authUid,
  }) async {
    this.authenticationToken = authenticationToken;
    this.refreshToken = refreshToken;
    this.tokenExpiration = tokenExpiration;
    uid = authUid;

    final updatedUser = Zoc1AuthUser(
      loggedIn: true,
      uid: authUid,
    );
    zoc1AuthUserSubject.add(updatedUser);
    await persistAuthData();
    return updatedUser;
  }

  Future initialize() async {
    try {
      await _storage.initialize();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing auth storage: $e');
      }
      zoc1AuthUserSubject.add(Zoc1AuthUser(loggedIn: false));
      return;
    }

    try {
      authenticationToken = _storage.getString(_kAuthTokenKey);
      refreshToken = _storage.getString(_kRefreshTokenKey);
      final expirationTimestamp = _storage.getInt(_kTokenExpirationKey);
      tokenExpiration = expirationTimestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(expirationTimestamp)
          : null;
      uid = _storage.getString(_kUidKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing auth: $e');
      }
      return;
    }

    final authTokenExists =
        authenticationToken != null && authenticationToken!.isNotEmpty;
    final tokenExpired = tokenExpiration != null &&
        tokenExpiration!.isBefore(DateTime.now());
    final updatedUser = Zoc1AuthUser(
      loggedIn: authTokenExists && !tokenExpired,
      uid: uid,
    );
    zoc1AuthUserSubject.add(updatedUser);
  }

  Future<bool> ensureValidSession() async {
    if (authenticationToken == null || authenticationToken!.isEmpty) {
      zoc1AuthUserSubject.add(Zoc1AuthUser(loggedIn: false, uid: uid));
      return false;
    }

    final refreshThreshold = DateTime.now().add(const Duration(minutes: 1));
    final isExpired = tokenExpiration != null &&
        tokenExpiration!.isBefore(refreshThreshold);

    if (!isExpired) {
      zoc1AuthUserSubject.add(Zoc1AuthUser(loggedIn: true, uid: uid));
      return true;
    }

    if (refreshToken == null || refreshToken!.isEmpty) {
      await signOut();
      return false;
    }

    return false;
  }

  Future<void> persistAuthData() async {
    try {
      if (authenticationToken != null) {
        await _storage.setString(_kAuthTokenKey, authenticationToken!);
      } else {
        await _storage.remove(_kAuthTokenKey);
      }

      if (refreshToken != null) {
        await _storage.setString(_kRefreshTokenKey, refreshToken!);
      } else {
        await _storage.remove(_kRefreshTokenKey);
      }

      if (tokenExpiration != null) {
        await _storage.setInt(_kTokenExpirationKey, tokenExpiration!.millisecondsSinceEpoch);
      } else {
        await _storage.remove(_kTokenExpirationKey);
      }

      if (uid != null) {
        await _storage.setString(_kUidKey, uid!);
      } else {
        await _storage.remove(_kUidKey);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error persisting auth data: $e');
      }
    }
  }
}

Zoc1AuthUser? currentUser;
bool get loggedIn => currentUser?.loggedIn ?? false;
