import '../database.dart';

class UserTasksTable extends SupabaseTable<UserTasksRow> {
  @override
  String get tableName => 'user_tasks';

  @override
  UserTasksRow createRow(Map<String, dynamic> data) => UserTasksRow(data);
}

class UserTasksRow extends SupabaseDataRow {
  UserTasksRow(super.data);

  @override
  SupabaseTable get table => UserTasksTable();

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String get taskId => getField<String>('task_id')!;
  set taskId(String value) => setField<String>('task_id', value);

  DateTime? get assignedAt => getField<DateTime>('assigned_at');
  set assignedAt(DateTime? value) => setField<DateTime>('assigned_at', value);

  int? get status => getField<int>('status');
  set status(int? value) => setField<int>('status', value);
}
