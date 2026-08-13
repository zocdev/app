import '../database.dart';

class UserClientsTable extends SupabaseTable<UserClientsRow> {
  @override
  String get tableName => 'user_clients';

  @override
  UserClientsRow createRow(Map<String, dynamic> data) => UserClientsRow(data);
}

class UserClientsRow extends SupabaseDataRow {
  UserClientsRow(super.data);

  @override
  SupabaseTable get table => UserClientsTable();

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String get clientId => getField<String>('client_id')!;
  set clientId(String value) => setField<String>('client_id', value);

  DateTime? get assignedAt => getField<DateTime>('assigned_at');
  set assignedAt(DateTime? value) => setField<DateTime>('assigned_at', value);

  String? get role => getField<String>('role');
  set role(String? value) => setField<String>('role', value);
}
