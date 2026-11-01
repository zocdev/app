/// Rounds up so a pending record never reads "0 min" before it is due.
String formatPopupCountdown(Duration remaining) {
  final milliseconds = remaining.inMilliseconds;
  if (milliseconds >= Duration.millisecondsPerMinute) {
    return '${(milliseconds / Duration.millisecondsPerMinute).ceil()} min';
  }
  final seconds = (milliseconds / Duration.millisecondsPerSecond).ceil();
  return '${seconds < 0 ? 0 : seconds} s';
}
