import 'package:flutter/foundation.dart';

/// Base URL for the backend API.
///
/// Override at build/run time with `--dart-define=API_BASE=http://localhost:8099`
/// (used by the E2E/integration tests against the isolated test stack).
/// Falls back to localhost in debug and the hosted API in release.
String getBaseApiUrl() {
  const override = String.fromEnvironment('API_BASE');
  if (override.isNotEmpty) {
    return override;
  }
  if (kDebugMode) {
    return 'http://localhost:8089';
  }
  return 'https://zoc-be-api-60512640268.southamerica-east1.run.app';
}
