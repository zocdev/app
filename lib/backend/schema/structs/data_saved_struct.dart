// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class DataSavedStruct extends BaseStruct {
  DataSavedStruct({
    List<String>? task,
    List<String>? taskId,
    String? token,
    List<String>? project,
    List<String>? projectId,
    bool? remote,
  })  : _task = task,
        _taskId = taskId,
        _token = token,
        _project = project,
        _projectId = projectId,
        _remote = remote;

  // "task" field.
  List<String>? _task;
  List<String> get task => _task ?? const [];
  set task(List<String>? val) => _task = val;

  void updateTask(Function(List<String>) updateFn) {
    updateFn(_task ??= []);
  }

  bool hasTask() => _task != null;

  // "taskId" field.
  List<String>? _taskId;
  List<String> get taskId => _taskId ?? const [];
  set taskId(List<String>? val) => _taskId = val;

  void updateTaskId(Function(List<String>) updateFn) {
    updateFn(_taskId ??= []);
  }

  bool hasTaskId() => _taskId != null;

  // "token" field.
  String? _token;
  String get token => _token ?? '';
  set token(String? val) => _token = val;

  bool hasToken() => _token != null;

  // "project" field.
  List<String>? _project;
  List<String> get project => _project ?? const [];
  set project(List<String>? val) => _project = val;

  void updateProject(Function(List<String>) updateFn) {
    updateFn(_project ??= []);
  }

  bool hasProject() => _project != null;

  // "projectId" field.
  List<String>? _projectId;
  List<String> get projectId => _projectId ?? const [];
  set projectId(List<String>? val) => _projectId = val;

  void updateProjectId(Function(List<String>) updateFn) {
    updateFn(_projectId ??= []);
  }

  bool hasProjectId() => _projectId != null;

  // "remote" field.
  bool? _remote;
  bool get remote => _remote ?? false;
  set remote(bool? val) => _remote = val;

  bool hasRemote() => _remote != null;

  static DataSavedStruct fromMap(Map<String, dynamic> data) => DataSavedStruct(
        task: getDataList(data['task']),
        taskId: getDataList(data['taskId']),
        token: data['token'] as String?,
        project: getDataList(data['project']),
        projectId: getDataList(data['projectId']),
        remote: data['remote'] as bool?,
      );

  static DataSavedStruct? maybeFromMap(dynamic data) => data is Map
      ? DataSavedStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'task': _task,
        'taskId': _taskId,
        'token': _token,
        'project': _project,
        'projectId': _projectId,
        'remote': _remote,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'task': serializeParam(
          _task,
          ParamType.String,
          isList: true,
        ),
        'taskId': serializeParam(
          _taskId,
          ParamType.String,
          isList: true,
        ),
        'token': serializeParam(
          _token,
          ParamType.String,
        ),
        'project': serializeParam(
          _project,
          ParamType.String,
          isList: true,
        ),
        'projectId': serializeParam(
          _projectId,
          ParamType.String,
          isList: true,
        ),
        'remote': serializeParam(
          _remote,
          ParamType.bool,
        ),
      }.withoutNulls;

  static DataSavedStruct fromSerializableMap(Map<String, dynamic> data) =>
      DataSavedStruct(
        task: deserializeParam<String>(
          data['task'],
          ParamType.String,
          true,
        ),
        taskId: deserializeParam<String>(
          data['taskId'],
          ParamType.String,
          true,
        ),
        token: deserializeParam(
          data['token'],
          ParamType.String,
          false,
        ),
        project: deserializeParam<String>(
          data['project'],
          ParamType.String,
          true,
        ),
        projectId: deserializeParam<String>(
          data['projectId'],
          ParamType.String,
          true,
        ),
        remote: deserializeParam(
          data['remote'],
          ParamType.bool,
          false,
        ),
      );

  @override
  String toString() => 'DataSavedStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality();
    return other is DataSavedStruct &&
        listEquality.equals(task, other.task) &&
        listEquality.equals(taskId, other.taskId) &&
        token == other.token &&
        listEquality.equals(project, other.project) &&
        listEquality.equals(projectId, other.projectId) &&
        remote == other.remote;
  }

  @override
  int get hashCode => const ListEquality()
      .hash([task, taskId, token, project, projectId, remote]);
}

DataSavedStruct createDataSavedStruct({
  String? token,
  bool? remote,
}) =>
    DataSavedStruct(
      token: token,
      remote: remote,
    );
