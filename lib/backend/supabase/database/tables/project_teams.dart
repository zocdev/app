import '../database.dart';

class ProjectTeamsTable extends SupabaseTable<ProjectTeamsRow> {
  @override
  String get tableName => 'project_teams';

  @override
  ProjectTeamsRow createRow(Map<String, dynamic> data) => ProjectTeamsRow(data);
}

class ProjectTeamsRow extends SupabaseDataRow {
  ProjectTeamsRow(super.data);

  @override
  SupabaseTable get table => ProjectTeamsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get projectId => getField<String>('project_id');
  set projectId(String? value) => setField<String>('project_id', value);

  String? get teamId => getField<String>('team_id');
  set teamId(String? value) => setField<String>('team_id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
