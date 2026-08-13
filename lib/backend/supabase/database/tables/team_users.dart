import '../database.dart';

class TeamUsersTable extends SupabaseTable<TeamUsersRow> {
  @override
  String get tableName => 'team_users';

  @override
  TeamUsersRow createRow(Map<String, dynamic> data) => TeamUsersRow(data);
}

class TeamUsersRow extends SupabaseDataRow {
  TeamUsersRow(super.data);

  @override
  SupabaseTable get table => TeamUsersTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get teamId => getField<String>('team_id');
  set teamId(String? value) => setField<String>('team_id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get roleInTeam => getField<String>('role_in_team');
  set roleInTeam(String? value) => setField<String>('role_in_team', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
