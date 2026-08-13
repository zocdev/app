import '/backend/api_requests/api_calls.dart';

Future<void> sendVerificationEmail(
    String userEmail, String userPassword) async {
  final response = await ResendEmailConfirmationCall.call(email: userEmail);
  if (!response.succeeded) {
    final body = response.jsonBody;
    final message = body is Map
        ? ((body['message'] as String?) ??
            (body['error'] as String?) ??
            'Falha ao reenviar confirmação')
        : 'Falha ao reenviar confirmação';
    throw Exception(message);
  }
}
