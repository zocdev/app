// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class TaskDoneStruct extends BaseStruct {
  TaskDoneStruct({
    String? taskId,
    String? taskName,
    String? projectName,
    double? totalHours,
    double? hours,
    DateTime? startDate,
    DateTime? endDate,
  })  : _taskId = taskId,
        _taskName = taskName,
        _projectName = projectName,
        _totalHours = totalHours,
        _hours = hours,
        _startDate = startDate,
        _endDate = endDate;

  // "task_id" field.
  String? _taskId;
  String get taskId => _taskId ?? '';
  set taskId(String? val) => _taskId = val;

  bool hasTaskId() => _taskId != null;

  // "task_name" field.
  String? _taskName;
  String get taskName => _taskName ?? '';
  set taskName(String? val) => _taskName = val;

  bool hasTaskName() => _taskName != null;

  // "project_name" field.
  String? _projectName;
  String get projectName => _projectName ?? '';
  set projectName(String? val) => _projectName = val;

  bool hasProjectName() => _projectName != null;

  // "total_hours" field.
  double? _totalHours;
  double get totalHours => _totalHours ?? 0.0;
  set totalHours(double? val) => _totalHours = val;

  void incrementTotalHours(double amount) => totalHours = totalHours + amount;

  bool hasTotalHours() => _totalHours != null;

  // "hours" field.
  double? _hours;
  double get hours => _hours ?? 0.0;
  set hours(double? val) => _hours = val;

  void incrementHours(double amount) => hours = hours + amount;

  bool hasHours() => _hours != null;

  // "startDate" field.
  DateTime? _startDate;
  DateTime? get startDate => _startDate;
  set startDate(DateTime? val) => _startDate = val;

  bool hasStartDate() => _startDate != null;

  // "endDate" field.
  DateTime? _endDate;
  DateTime? get endDate => _endDate;
  set endDate(DateTime? val) => _endDate = val;

  bool hasEndDate() => _endDate != null;

  static TaskDoneStruct fromMap(Map<String, dynamic> data) => TaskDoneStruct(
        taskId: data['task_id'] as String?,
        taskName: data['task_name'] as String?,
        projectName: data['project_name'] as String?,
        totalHours: castToType<double>(data['total_hours']),
        hours: castToType<double>(data['hours']),
        startDate: data['startDate'] as DateTime?,
        endDate: data['endDate'] as DateTime?,
      );

  static TaskDoneStruct? maybeFromMap(dynamic data) =>
      data is Map ? TaskDoneStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'task_id': _taskId,
        'task_name': _taskName,
        'project_name': _projectName,
        'total_hours': _totalHours,
        'hours': _hours,
        'startDate': _startDate,
        'endDate': _endDate,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'task_id': serializeParam(
          _taskId,
          ParamType.String,
        ),
        'task_name': serializeParam(
          _taskName,
          ParamType.String,
        ),
        'project_name': serializeParam(
          _projectName,
          ParamType.String,
        ),
        'total_hours': serializeParam(
          _totalHours,
          ParamType.double,
        ),
        'hours': serializeParam(
          _hours,
          ParamType.double,
        ),
        'startDate': serializeParam(
          _startDate,
          ParamType.DateTime,
        ),
        'endDate': serializeParam(
          _endDate,
          ParamType.DateTime,
        ),
      }.withoutNulls;

  static TaskDoneStruct fromSerializableMap(Map<String, dynamic> data) =>
      TaskDoneStruct(
        taskId: deserializeParam(
          data['task_id'],
          ParamType.String,
          false,
        ),
        taskName: deserializeParam(
          data['task_name'],
          ParamType.String,
          false,
        ),
        projectName: deserializeParam(
          data['project_name'],
          ParamType.String,
          false,
        ),
        totalHours: deserializeParam(
          data['total_hours'],
          ParamType.double,
          false,
        ),
        hours: deserializeParam(
          data['hours'],
          ParamType.double,
          false,
        ),
        startDate: deserializeParam(
          data['startDate'],
          ParamType.DateTime,
          false,
        ),
        endDate: deserializeParam(
          data['endDate'],
          ParamType.DateTime,
          false,
        ),
      );

  @override
  String toString() => 'TaskDoneStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is TaskDoneStruct &&
        taskId == other.taskId &&
        taskName == other.taskName &&
        projectName == other.projectName &&
        totalHours == other.totalHours &&
        hours == other.hours &&
        startDate == other.startDate &&
        endDate == other.endDate;
  }

  @override
  int get hashCode => const ListEquality().hash(
      [taskId, taskName, projectName, totalHours, hours, startDate, endDate]);
}

TaskDoneStruct createTaskDoneStruct({
  String? taskId,
  String? taskName,
  String? projectName,
  double? totalHours,
  double? hours,
  DateTime? startDate,
  DateTime? endDate,
}) =>
    TaskDoneStruct(
      taskId: taskId,
      taskName: taskName,
      projectName: projectName,
      totalHours: totalHours,
      hours: hours,
      startDate: startDate,
      endDate: endDate,
    );
