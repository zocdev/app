import '../database.dart';

class OrganizationUsersTable extends SupabaseTable<OrganizationUsersRow> {
  @override
  String get tableName => 'organization_users';

  @override
  OrganizationUsersRow createRow(Map<String, dynamic> data) =>
      OrganizationUsersRow(data);
}

class OrganizationUsersRow extends SupabaseDataRow {
  OrganizationUsersRow(super.data);

  @override
  SupabaseTable get table => OrganizationUsersTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String? get orgId => getField<String>('org_id');
  set orgId(String? value) => setField<String>('org_id', value);

  String? get email => getField<String>('email');
  set email(String? value) => setField<String>('email', value);

  String? get cpf => getField<String>('cpf');
  set cpf(String? value) => setField<String>('cpf', value);

  String? get cnpj => getField<String>('cnpj');
  set cnpj(String? value) => setField<String>('cnpj', value);

  String? get phone => getField<String>('phone');
  set phone(String? value) => setField<String>('phone', value);

  String? get firstName => getField<String>('first_name');
  set firstName(String? value) => setField<String>('first_name', value);

  String? get lastName => getField<String>('last_name');
  set lastName(String? value) => setField<String>('last_name', value);

  String? get avatar => getField<String>('avatar');
  set avatar(String? value) => setField<String>('avatar', value);

  String? get role => getField<String>('role');
  set role(String? value) => setField<String>('role', value);

  bool? get termsAccepted => getField<bool>('terms_accepted');
  set termsAccepted(bool? value) => setField<bool>('terms_accepted', value);

  int? get status => getField<int>('status');
  set status(int? value) => setField<int>('status', value);

  String? get currency => getField<String>('currency');
  set currency(String? value) => setField<String>('currency', value);

  int? get department => getField<int>('department');
  set department(int? value) => setField<int>('department', value);

  String? get position => getField<String>('position');
  set position(String? value) => setField<String>('position', value);

  int? get salary => getField<int>('salary');
  set salary(int? value) => setField<int>('salary', value);

  dynamic get teams => getField<dynamic>('teams');
  set teams(dynamic value) => setField<dynamic>('teams', value);

  int? get type => getField<int>('type');
  set type(int? value) => setField<int>('type', value);

  dynamic get dataField => getField<dynamic>('data');
  set dataField(dynamic value) => setField<dynamic>('data', value);

  String? get authId => getField<String>('auth_id');
  set authId(String? value) => setField<String>('auth_id', value);

  bool get monitoring => getField<bool>('monitoring')!;
  set monitoring(bool value) => setField<bool>('monitoring', value);

  String? get function => getField<String>('function');
  set function(String? value) => setField<String>('function', value);

  int? get monthlyHours => getField<int>('monthly_hours');
  set monthlyHours(int? value) => setField<int>('monthly_hours', value);

  int? get paymentPeriod => getField<int>('payment_period');
  set paymentPeriod(int? value) => setField<int>('payment_period', value);
}
