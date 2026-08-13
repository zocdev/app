import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SecureStorageService {
  static SecureStorageService? _instance;
  static SecureStorageService get instance => _instance ??= SecureStorageService._();

  SecureStorageService._();

  Box? _hiveBox;
  bool _initialized = false;

  static const String _hiveBoxName = 'zoc_app_storage';
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 100);

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    await _initializeHive();
    _initialized = true;
    _log('Hive storage initialized');
  }

  Future<void> _initializeHive() async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        if (!Hive.isBoxOpen(_hiveBoxName)) {
          await Hive.initFlutter();
          _hiveBox = await Hive.openBox(_hiveBoxName);
        } else {
          _hiveBox = Hive.box(_hiveBoxName);
        }

        await _verifyStorage();
        return;
      } catch (e, stack) {
        _logError('Hive init attempt $attempt failed', e, stack);

        if (attempt < _maxRetries) {
          await Future.delayed(_retryDelay * attempt);
        } else {
          throw StorageException('Failed to initialize storage after $_maxRetries attempts', e);
        }
      }
    }
  }

  Future<void> _verifyStorage() async {
    const testKey = '_storage_verify_';
    final testValue = DateTime.now().millisecondsSinceEpoch.toString();

    await _hiveBox!.put(testKey, testValue);
    final readValue = _hiveBox!.get(testKey);
    await _hiveBox!.delete(testKey);

    if (readValue != testValue) {
      throw StorageException('Storage read/write verification failed');
    }
  }

  Future<bool> setString(String key, String value) async {
    _ensureInitialized();
    return _executeWithRetry(() async {
      await _hiveBox!.put(key, value);
      return true;
    }, 'setString($key)');
  }

  String? getString(String key) {
    _ensureInitialized();
    try {
      return _hiveBox!.get(key) as String?;
    } catch (e, stack) {
      _logError('getString($key) failed', e, stack);
      return null;
    }
  }

  Future<bool> setInt(String key, int value) async {
    _ensureInitialized();
    return _executeWithRetry(() async {
      await _hiveBox!.put(key, value);
      return true;
    }, 'setInt($key)');
  }

  int? getInt(String key) {
    _ensureInitialized();
    try {
      return _hiveBox!.get(key) as int?;
    } catch (e, stack) {
      _logError('getInt($key) failed', e, stack);
      return null;
    }
  }

  Future<bool> setBool(String key, bool value) async {
    _ensureInitialized();
    return _executeWithRetry(() async {
      await _hiveBox!.put(key, value);
      return true;
    }, 'setBool($key)');
  }

  bool? getBool(String key) {
    _ensureInitialized();
    try {
      return _hiveBox!.get(key) as bool?;
    } catch (e, stack) {
      _logError('getBool($key) failed', e, stack);
      return null;
    }
  }

  Future<bool> setStringList(String key, List<String> value) async {
    _ensureInitialized();
    return _executeWithRetry(() async {
      await _hiveBox!.put(key, value);
      return true;
    }, 'setStringList($key)');
  }

  List<String>? getStringList(String key) {
    _ensureInitialized();
    try {
      final value = _hiveBox!.get(key);
      if (value is List) {
        return value.cast<String>();
      }
      return null;
    } catch (e, stack) {
      _logError('getStringList($key) failed', e, stack);
      return null;
    }
  }

  Future<bool> setJson(String key, dynamic value) async {
    try {
      final jsonString = jsonEncode(value);
      return await setString(key, jsonString);
    } catch (e, stack) {
      _logError('setJson($key) encoding failed', e, stack);
      return false;
    }
  }

  dynamic getJson(String key) {
    try {
      final jsonString = getString(key);
      if (jsonString == null || jsonString.isEmpty) return null;
      return jsonDecode(jsonString);
    } catch (e, stack) {
      _logError('getJson($key) decoding failed', e, stack);
      return null;
    }
  }

  bool containsKey(String key) {
    _ensureInitialized();
    try {
      return _hiveBox!.containsKey(key);
    } catch (e) {
      return false;
    }
  }

  Future<bool> remove(String key) async {
    _ensureInitialized();
    return _executeWithRetry(() async {
      await _hiveBox!.delete(key);
      return true;
    }, 'remove($key)');
  }

  Future<bool> clear() async {
    _ensureInitialized();
    try {
      await _hiveBox!.clear();
      return true;
    } catch (e, stack) {
      _logError('clear() failed', e, stack);
      return false;
    }
  }

  Set<String> getKeys() {
    _ensureInitialized();
    try {
      return _hiveBox!.keys.cast<String>().toSet();
    } catch (e) {
      return {};
    }
  }

  Future<bool> _executeWithRetry(
    Future<bool> Function() operation,
    String operationName,
  ) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e, stack) {
        _logError('$operationName attempt $attempt failed', e, stack);

        if (attempt == _maxRetries) {
          return false;
        }

        await Future.delayed(_retryDelay * attempt);
      }
    }
    return false;
  }

  void _ensureInitialized() {
    if (!_initialized || _hiveBox == null) {
      throw StorageException('SecureStorageService not initialized. Call initialize() first.');
    }
  }

  void _log(String message) {
    if (kDebugMode) {
      print('[Storage] $message');
    }
  }

  void _logError(String message, Object error, StackTrace? stack) {
    if (kDebugMode) {
      print('[Storage] ERROR: $message');
      print('[Storage] $error');
      if (stack != null) {
        print('[Storage] $stack');
      }
    }
  }

  Future<StorageDiagnostics> runDiagnostics() async {
    final diagnostics = StorageDiagnostics();

    diagnostics.isInitialized = _initialized;
    diagnostics.hiveAvailable = _hiveBox != null;

    if (_hiveBox != null) {
      try {
        diagnostics.keyCount = _hiveBox!.length;
        diagnostics.storagePath = _hiveBox!.path;
      } catch (e) {
        diagnostics.error = e.toString();
      }
    }

    return diagnostics;
  }

  Future<void> closeStorage() async {
    if (_hiveBox != null && _hiveBox!.isOpen) {
      await _hiveBox!.close();
      _initialized = false;
      _log('Storage closed');
    }
  }
}

class StorageException implements Exception {
  final String message;
  final Object? cause;

  StorageException(this.message, [this.cause]);

  @override
  String toString() => 'StorageException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

class StorageDiagnostics {
  bool isInitialized = false;
  bool hiveAvailable = false;
  int keyCount = 0;
  String? storagePath;
  String? error;

  Map<String, dynamic> toJson() => {
    'isInitialized': isInitialized,
    'hiveAvailable': hiveAvailable,
    'keyCount': keyCount,
    'storagePath': storagePath,
    'error': error,
  };

  @override
  String toString() => 'StorageDiagnostics(${toJson()})';
}

