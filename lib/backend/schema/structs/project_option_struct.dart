// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ProjectOptionStruct extends BaseStruct {
  ProjectOptionStruct({
    String? id,
    String? name,
    String? clientId,
  })  : _id = id,
        _name = name,
        _clientId = clientId;

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

  // "client_id" field.
  String? _clientId;
  String get clientId => _clientId ?? '';
  set clientId(String? val) => _clientId = val;

  bool hasClientId() => _clientId != null;

  static ProjectOptionStruct fromMap(Map<String, dynamic> data) =>
      ProjectOptionStruct(
        id: data['id'] as String?,
        name: data['name'] as String?,
        clientId: data['client_id'] as String?,
      );

  static ProjectOptionStruct? maybeFromMap(dynamic data) => data is Map
      ? ProjectOptionStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'id': _id,
        'name': _name,
        'client_id': _clientId,
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
        'client_id': serializeParam(
          _clientId,
          ParamType.String,
        ),
      }.withoutNulls;

  static ProjectOptionStruct fromSerializableMap(Map<String, dynamic> data) =>
      ProjectOptionStruct(
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
        clientId: deserializeParam(
          data['client_id'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'ProjectOptionStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is ProjectOptionStruct &&
        id == other.id &&
        name == other.name &&
        clientId == other.clientId;
  }

  @override
  int get hashCode => const ListEquality().hash([id, name, clientId]);
}

ProjectOptionStruct createProjectOptionStruct({
  String? id,
  String? name,
  String? clientId,
}) =>
    ProjectOptionStruct(
      id: id,
      name: name,
      clientId: clientId,
    );
