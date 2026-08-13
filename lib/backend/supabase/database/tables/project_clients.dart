import '../database.dart';

class ProjectClientsTable extends SupabaseTable<ProjectClientsRow> {
  @override
  String get tableName => 'project_clients';

  @override
  ProjectClientsRow createRow(Map<String, dynamic> data) =>
      ProjectClientsRow(data);
}

class ProjectClientsRow extends SupabaseDataRow {
  ProjectClientsRow(super.data);

  @override
  SupabaseTable get table => ProjectClientsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String? get projectId => getField<String>('project_id');
  set projectId(String? value) => setField<String>('project_id', value);

  String? get clientId => getField<String>('client_id');
  set clientId(String? value) => setField<String>('client_id', value);
}
