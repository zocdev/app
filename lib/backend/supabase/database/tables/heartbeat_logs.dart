import '../database.dart';

class HeartbeatLogsTable extends SupabaseTable<HeartbeatLogsRow> {
  @override
  String get tableName => 'heartbeat_logs';

  @override
  HeartbeatLogsRow createRow(Map<String, dynamic> data) =>
      HeartbeatLogsRow(data);
}

class HeartbeatLogsRow extends SupabaseDataRow {
  HeartbeatLogsRow(super.data);

  @override
  SupabaseTable get table => HeartbeatLogsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String get eventType => getField<String>('event_type')!;
  set eventType(String value) => setField<String>('event_type', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  dynamic get metadata => getField<dynamic>('metadata');
  set metadata(dynamic value) => setField<dynamic>('metadata', value);
}
