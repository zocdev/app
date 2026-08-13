// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class OptionStruct extends BaseStruct {
  OptionStruct({
    String? id,
    String? name,
  })  : _id = id,
        _name = name;

  // "id" field.
  String? _id;
  String get id => _id ?? '';
  set id(String? val) => _id = val;

  bool hasId() => _id != null;

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  set name(String? val) => _name = val;

  bool hasName() => _name != null;

  static OptionStruct fromMap(Map<String, dynamic> data) => OptionStruct(
        id: data['id'] as String?,
        name: data['name'] as String?,
      );

  static OptionStruct? maybeFromMap(dynamic data) =>
      data is Map ? OptionStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'id': _id,
        'name': _name,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'id': serializeParam(
          _id,
          ParamType.String,
        ),
        'name': serializeParam(
          _name,
          ParamType.String,
        ),
      }.withoutNulls;

  static OptionStruct fromSerializableMap(Map<String, dynamic> data) =>
      OptionStruct(
        id: deserializeParam(
          data['id'],
          ParamType.String,
          false,
        ),
        name: deserializeParam(
          data['name'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'OptionStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is OptionStruct && id == other.id && name == other.name;
  }

  @override
  int get hashCode => const ListEquality().hash([id, name]);
}

OptionStruct createOptionStruct({
  String? id,
  String? name,
}) =>
    OptionStruct(
      id: id,
      name: name,
    );
