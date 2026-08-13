import '../database.dart';

class RolePermissionsTable extends SupabaseTable<RolePermissionsRow> {
  @override
  String get tableName => 'role_permissions';

  @override
  RolePermissionsRow createRow(Map<String, dynamic> data) =>
      RolePermissionsRow(data);
}

class RolePermissionsRow extends SupabaseDataRow {
  RolePermissionsRow(super.data);

  @override
  SupabaseTable get table => RolePermissionsTable();

  String get roleId => getField<String>('role_id')!;
  set roleId(String value) => setField<String>('role_id', value);

  bool? get canWrite => getField<bool>('can_write');
  set canWrite(bool? value) => setField<bool>('can_write', value);

  String? get permissionId => getField<String>('permission_id');
  set permissionId(String? value) => setField<String>('permission_id', value);

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);
}
