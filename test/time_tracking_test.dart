import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:zoc/utils/time_tracking.dart';

void main() {
  test('monitoring false disables time tracking', () {
    expect(timeTrackingEnabledIn({'user': {'monitoring': false}}), isFalse);
    expect(
      timeTrackingEnabledIn(jsonEncode({'user': {'monitoring': false}})),
      isFalse,
    );
  });

  test('monitoring true or missing keeps time tracking on', () {
    expect(timeTrackingEnabledIn({'user': {'monitoring': true}}), isTrue);
    expect(timeTrackingEnabledIn({'user': {}}), isTrue);
    expect(timeTrackingEnabledIn(null), isTrue);
    expect(timeTrackingEnabledIn('not json'), isTrue);
  });
}
