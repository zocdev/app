// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class TaskOptionStruct extends BaseStruct {
  TaskOptionStruct({
    String? id,
    String? name,
    String? projectId,
  })  : _id = id,
        _name = name,
        _projectId = projectId;

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

  // "project_id" field.
  String? _projectId;
  String get projectId => _projectId ?? '';
  set projectId(String? val) => _projectId = val;

  bool hasProjectId() => _projectId != null;

  static TaskOptionStruct fromMap(Map<String, dynamic> data) =>
      TaskOptionStruct(
        id: data['id'] as String?,
        name: data['name'] as String?,
        projectId: data['project_id'] as String?,
      );

  static TaskOptionStruct? maybeFromMap(dynamic data) => data is Map
      ? TaskOptionStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'id': _id,
        'name': _name,
        'project_id': _projectId,
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
        'project_id': serializeParam(
          _projectId,
          ParamType.String,
        ),
      }.withoutNulls;

  static TaskOptionStruct fromSerializableMap(Map<String, dynamic> data) =>
      TaskOptionStruct(
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
        projectId: deserializeParam(
          data['project_id'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'TaskOptionStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is TaskOptionStruct &&
        id == other.id &&
        name == other.name &&
        projectId == other.projectId;
  }

  @override
  int get hashCode => const ListEquality().hash([id, name, projectId]);
}

TaskOptionStruct createTaskOptionStruct({
  String? id,
  String? name,
  String? projectId,
}) =>
    TaskOptionStruct(
      id: id,
      name: name,
      projectId: projectId,
    );
