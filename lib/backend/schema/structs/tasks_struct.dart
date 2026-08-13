// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class TasksStruct extends BaseStruct {
  TasksStruct({
    String? taskId,
    String? task,
  })  : _taskId = taskId,
        _task = task;

  // "taskId" field.
  String? _taskId;
  String get taskId => _taskId ?? '';
  set taskId(String? val) => _taskId = val;

  bool hasTaskId() => _taskId != null;

  // "task" field.
  String? _task;
  String get task => _task ?? '';
  set task(String? val) => _task = val;

  bool hasTask() => _task != null;

  static TasksStruct fromMap(Map<String, dynamic> data) => TasksStruct(
        taskId: data['taskId'] as String?,
        task: data['task'] as String?,
      );

  static TasksStruct? maybeFromMap(dynamic data) =>
      data is Map ? TasksStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'taskId': _taskId,
        'task': _task,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'taskId': serializeParam(
          _taskId,
          ParamType.String,
        ),
        'task': serializeParam(
          _task,
          ParamType.String,
        ),
      }.withoutNulls;

  static TasksStruct fromSerializableMap(Map<String, dynamic> data) =>
      TasksStruct(
        taskId: deserializeParam(
          data['taskId'],
          ParamType.String,
          false,
        ),
        task: deserializeParam(
          data['task'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'TasksStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is TasksStruct && taskId == other.taskId && task == other.task;
  }

  @override
  int get hashCode => const ListEquality().hash([taskId, task]);
}

TasksStruct createTasksStruct({
  String? taskId,
  String? task,
}) =>
    TasksStruct(
      taskId: taskId,
      task: task,
    );
