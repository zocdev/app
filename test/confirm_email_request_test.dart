import 'package:flutter_test/flutter_test.dart';

import 'package:zoc/backend/api_requests/auth_models.dart';

void main() {
  group('ConfirmEmailRequest.toJson', () {
    test('includes email when provided', () {
      const request = ConfirmEmailRequest(otp: '123456', email: 'user@x.com');
      expect(request.toJson(), {'otp': '123456', 'email': 'user@x.com'});
    });

    test('omits email when empty or null', () {
      expect(const ConfirmEmailRequest(otp: '123456', email: '').toJson(),
          {'otp': '123456'});
      expect(
          const ConfirmEmailRequest(otp: '123456').toJson(), {'otp': '123456'});
    });
  });
}
