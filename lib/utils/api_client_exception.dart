class ApiClientException implements Exception {
  ApiClientException({
    required this.statusCode,
    required this.message,
    this.body,
  });

  final int statusCode;
  final String message;
  final dynamic body;

  bool get isValidation => statusCode == 400;
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'ApiClientException($statusCode): $message';
}
