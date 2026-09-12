import 'package:flutter_test/flutter_test.dart';
import 'package:zoc/backend/api_requests/api_calls.dart';

void main() {
  test('escapeStringForJson never interpolates dart null as the word null', () {
    expect(escapeStringForJson(null), '');
    expect(escapeStringForJson(''), '');
    expect(escapeStringForJson('data:image/jpeg;base64,abc'), 'data:image/jpeg;base64,abc');
  });
}
