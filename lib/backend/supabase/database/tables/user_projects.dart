import '../database.dart';

class UserProjectsTable extends SupabaseTable<UserProjectsRow> {
  @override
  String get tableName => 'user_projects';

  @override
  UserProjectsRow createRow(Map<String, dynamic> data) => UserProjectsRow(data);
}

class UserProjectsRow extends SupabaseDataRow {
  UserProjectsRow(super.data);

  @override
  SupabaseTable get table => UserProjectsTable();

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String get projectId => getField<String>('project_id')!;
  set projectId(String value) => setField<String>('project_id', value);

  DateTime? get assignedAt => getField<DateTime>('assigned_at');
  set assignedAt(DateTime? value) => setField<DateTime>('assigned_at', value);

  String? get role => getField<String>('role');
  set role(String? value) => setField<String>('role', value);

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);
}
