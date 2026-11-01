import 'package:flutter_test/flutter_test.dart';
import 'package:zoc/ui/zoc_ui.dart';

void main() {
  test('below goal has no overtime', () {
    const p = ZocGoalProgress(6, 8);
    expect(p.ratio, 0.75);
    expect(p.reached, isFalse);
    expect(p.hasOvertime, isFalse);
  });

  test('past goal reports overtime hours', () {
    const p = ZocGoalProgress(10, 8);
    expect(p.ratio, 1.25);
    expect(p.reached, isTrue);
    expect(p.overtimeHours, 2);
    expect(p.hasOvertime, isTrue);
  });

  test('exact goal is reached without overtime', () {
    const p = ZocGoalProgress(8, 8);
    expect(p.reached, isTrue);
    expect(p.hasOvertime, isFalse);
  });

  test('missing goal never reports progress', () {
    const p = ZocGoalProgress(5, null);
    expect(p.ratio, 0);
    expect(p.reached, isFalse);
  });
}
