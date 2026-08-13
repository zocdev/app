import '../database.dart';

class TimeEntriesTable extends SupabaseTable<TimeEntriesRow> {
  @override
  String get tableName => 'time_entries';

  @override
  TimeEntriesRow createRow(Map<String, dynamic> data) => TimeEntriesRow(data);
}

class TimeEntriesRow extends SupabaseDataRow {
  TimeEntriesRow(super.data);

  @override
  SupabaseTable get table => TimeEntriesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  dynamic get tasks => getField<dynamic>('tasks');
  set tasks(dynamic value) => setField<dynamic>('tasks', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);
}
