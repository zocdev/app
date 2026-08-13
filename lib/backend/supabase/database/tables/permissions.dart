import '../database.dart';

class PermissionsTable extends SupabaseTable<PermissionsRow> {
  @override
  String get tableName => 'permissions';

  @override
  PermissionsRow createRow(Map<String, dynamic> data) => PermissionsRow(data);
}

class PermissionsRow extends SupabaseDataRow {
  PermissionsRow(super.data);

  @override
  SupabaseTable get table => PermissionsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get name => getField<String>('name')!;
  set name(String value) => setField<String>('name', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);
}
