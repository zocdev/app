import 'package:flutter/foundation.dart';

String getBaseApiUrl() {
  if (kDebugMode) {
    return 'http://localhost:8089';
  }
  return 'https://zoc-be-api-mzah.onrender.com';
}
