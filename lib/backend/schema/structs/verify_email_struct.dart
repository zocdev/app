// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class VerifyEmailStruct extends BaseStruct {
  VerifyEmailStruct({
    bool? firstTime,
    bool? exists,
    bool? verified,
  })  : _firstTime = firstTime,
        _exists = exists,
        _verified = verified;

  // "first_time" field.
  bool? _firstTime;
  bool get firstTime => _firstTime ?? false;
  set firstTime(bool? val) => _firstTime = val;

  bool hasFirstTime() => _firstTime != null;

  // "exists" field.
  bool? _exists;
  bool get exists => _exists ?? false;
  set exists(bool? val) => _exists = val;

  bool hasExists() => _exists != null;

  // "verified" field.
  bool? _verified;
  bool get verified => _verified ?? false;
  set verified(bool? val) => _verified = val;

  bool hasVerified() => _verified != null;

  static VerifyEmailStruct fromMap(Map<String, dynamic> data) =>
      VerifyEmailStruct(
        firstTime: data['first_time'] as bool?,
        exists: data['exists'] as bool?,
        verified: data['verified'] as bool?,
      );

  static VerifyEmailStruct? maybeFromMap(dynamic data) => data is Map
      ? VerifyEmailStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'first_time': _firstTime,
        'exists': _exists,
        'verified': _verified,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'first_time': serializeParam(
          _firstTime,
          ParamType.bool,
        ),
        'exists': serializeParam(
          _exists,
          ParamType.bool,
        ),
        'verified': serializeParam(
          _verified,
          ParamType.bool,
        ),
      }.withoutNulls;

  static VerifyEmailStruct fromSerializableMap(Map<String, dynamic> data) =>
      VerifyEmailStruct(
        firstTime: deserializeParam(
          data['first_time'],
          ParamType.bool,
          false,
        ),
        exists: deserializeParam(
          data['exists'],
          ParamType.bool,
          false,
        ),
        verified: deserializeParam(
          data['verified'],
          ParamType.bool,
          false,
        ),
      );

  @override
  String toString() => 'VerifyEmailStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is VerifyEmailStruct &&
        firstTime == other.firstTime &&
        exists == other.exists &&
        verified == other.verified;
  }

  @override
  int get hashCode => const ListEquality().hash([firstTime, exists, verified]);
}

VerifyEmailStruct createVerifyEmailStruct({
  bool? firstTime,
  bool? exists,
  bool? verified,
}) =>
    VerifyEmailStruct(
      firstTime: firstTime,
      exists: exists,
      verified: verified,
    );
