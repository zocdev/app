import 'package:intl/intl.dart';

List<String> formatDropdown(List<String>? selectedValues) {
  if (selectedValues == null || selectedValues.isEmpty) {
    return [];
  }

  List<String> values = [];
  selectedValues.map((e) => values.add(e.trim()));

  return values;
}

DateTime? getPreviusDate(DateTime? date) {
  if (date != null) {
    return date.subtract(Duration(days: 1));
  } else {
    return DateTime.now();
  }
}

DateTime? getNextDay(DateTime? date) {
  if (date != null) {
    DateTime nextDate = date.add(Duration(days: 1));

    if (nextDate.isAfter(DateTime.now())) {
      return DateTime.now();
    }
    return nextDate;
  } else {
    return DateTime.now();
  }
}

List<String>? getLabel(
  List<String> id,
  List<dynamic> items,
) {
  final List<String> result = [];

  for (final item in items) {
    if (id.contains(item['id'].toString())) {
      final name = item['name']?.toString();
      if (name != null) {
        result.add(name);
      }
    }
  }

  return result;
}

String? timeNowTZ() {
  final nowUtc = DateTime.now().toUtc();
  final formattedDate = DateFormat("yyyy-MM-dd HH:mm:ss.SSSSSS").format(nowUtc);
  return "$formattedDate+00";
}

String? formatHours(double? hours) {
  if (hours == null) return '0h 0min';
  if (hours > 24) return '0h 0min'; // ajusta el límite según tu negocio
  final wholeHours = hours.floor();
  final minutes = ((hours - wholeHours) * 60).round();
  return '${wholeHours}h ${minutes}min';
}
