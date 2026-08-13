import '../database.dart';

class HeartbeatsTable extends SupabaseTable<HeartbeatsRow> {
  @override
  String get tableName => 'heartbeats';

  @override
  HeartbeatsRow createRow(Map<String, dynamic> data) => HeartbeatsRow(data);
}

class HeartbeatsRow extends SupabaseDataRow {
  HeartbeatsRow(super.data);

  @override
  SupabaseTable get table => HeartbeatsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String get status => getField<String>('status')!;
  set status(String value) => setField<String>('status', value);

  DateTime get lastSeen => getField<DateTime>('last_seen')!;
  set lastSeen(DateTime value) => setField<DateTime>('last_seen', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  DateTime get updatedAt => getField<DateTime>('updated_at')!;
  set updatedAt(DateTime value) => setField<DateTime>('updated_at', value);
}
