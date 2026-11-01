import 'package:flutter_test/flutter_test.dart';

import 'package:zoc/backend/api_requests/api_calls.dart';

ApiCallResponse _response(dynamic body, [int status = 200]) =>
    ApiCallResponse(body, const {}, status);

void main() {
  test('goalHours reads goal_hours from the API', () {
    final body = {
      'period': 'week',
      'goal_hours': 36.5,
      'monthly_hours': 160,
      'source': 'member',
    };
    expect(GetWorkGoalCall.goalHours(_response(body), 'week'), 36.5);
    expect(
        GetWorkGoalCall.goalHours(_response({'goal_hours': 6}), 'today'), 6.0);
  });

  test('goalHours falls back to 8h day, 40h week and 176h month', () {
    final failed = _response({'message': 'boom'}, 500);
    expect(GetWorkGoalCall.goalHours(failed, 'today'), 8);
    expect(GetWorkGoalCall.goalHours(failed, 'week'), 40);
    expect(GetWorkGoalCall.goalHours(failed, 'month'), 176);
    expect(GetWorkGoalCall.goalHours(null, 'today'), 8);
    for (final bad in [
      {'goal_hours': 0},
      {'goal_hours': null},
      {'goal_hours': 'abc'},
      'not a map',
    ]) {
      expect(GetWorkGoalCall.goalHours(_response(bad), 'month'), 176,
          reason: '$bad');
    }
  });
}
