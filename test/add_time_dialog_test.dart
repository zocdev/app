import 'package:flutter_test/flutter_test.dart';

import 'package:zoc/desktop/add_time_dialog.dart';

void main() {
  test('durationMinutes accepts HH:mm up to 24 hours', () {
    expect(durationMinutes('01:30'), 90);
    expect(durationMinutes('0:05'), 5);
    expect(durationMinutes('24:00'), 1440);
    for (final bad in ['00:00', '24:01', '1:5', 'abc', '']) {
      expect(() => durationMinutes(bad), throwsFormatException, reason: bad);
    }
  });

  test('requestEnd requires a period that ended in the past', () {
    final now = DateTime(2026, 10, 27, 12);
    expect(requestEnd(DateTime(2026, 10, 27, 10), '01:30', now: now),
        DateTime(2026, 10, 27, 11, 30));
    expect(() => requestEnd(DateTime(2026, 10, 27, 11), '02:00', now: now),
        throwsFormatException);
  });

  test('defaultPeriod is the last hour without crossing midnight', () {
    final day = defaultPeriod(DateTime(2026, 10, 27, 15, 20, 30));
    expect(day.start, DateTime(2026, 10, 27, 14, 20));
    expect(day.duration, '01:00');
    final early = defaultPeriod(DateTime(2026, 10, 27, 0, 25));
    expect(early.start, DateTime(2026, 10, 27));
    expect(early.duration, '00:25');
  });
}
