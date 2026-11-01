import 'package:flutter_test/flutter_test.dart';
import 'package:zoc/logout/popup_countdown.dart';

void main() {
  test('countdown uses rounded-up minutes until the last minute', () {
    expect(formatPopupCountdown(const Duration(minutes: 15)), '15 min');
    expect(formatPopupCountdown(const Duration(minutes: 11, seconds: 30)),
        '12 min');
    expect(formatPopupCountdown(const Duration(seconds: 60)), '1 min');
  });

  test('countdown shows seconds under a minute and clamps overdue values', () {
    expect(formatPopupCountdown(const Duration(seconds: 59)), '59 s');
    expect(formatPopupCountdown(const Duration(milliseconds: 59999)), '60 s');
    expect(formatPopupCountdown(const Duration(milliseconds: 1)), '1 s');
    expect(formatPopupCountdown(Duration.zero), '0 s');
    expect(formatPopupCountdown(const Duration(seconds: -30)), '0 s');
  });
}
