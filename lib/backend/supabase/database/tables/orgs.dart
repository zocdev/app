import '../database.dart';

class OrgsTable extends SupabaseTable<OrgsRow> {
  @override
  String get tableName => 'orgs';

  @override
  OrgsRow createRow(Map<String, dynamic> data) => OrgsRow(data);
}

class OrgsRow extends SupabaseDataRow {
  OrgsRow(super.data);

  @override
  SupabaseTable get table => OrgsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get name => getField<String>('name')!;
  set name(String value) => setField<String>('name', value);

  String? get avatar => getField<String>('avatar');
  set avatar(String? value) => setField<String>('avatar', value);

  String? get ownerId => getField<String>('owner_id');
  set ownerId(String? value) => setField<String>('owner_id', value);

  String? get cnpj => getField<String>('cnpj');
  set cnpj(String? value) => setField<String>('cnpj', value);

  String? get cpf => getField<String>('cpf');
  set cpf(String? value) => setField<String>('cpf', value);

  int? get status => getField<int>('status');
  set status(int? value) => setField<int>('status', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  int? get passiveCosts => getField<int>('passive_costs');
  set passiveCosts(int? value) => setField<int>('passive_costs', value);
}
