// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AtivitiesStruct extends BaseStruct {
  AtivitiesStruct({
    List<String>? projects,
    List<String>? ativities,
    String? time,
    String? initTime,
    String? finishTime,
  })  : _projects = projects,
        _ativities = ativities,
        _time = time,
        _initTime = initTime,
        _finishTime = finishTime;

  // "projects" field.
  List<String>? _projects;
  List<String> get projects => _projects ?? const [];
  set projects(List<String>? val) => _projects = val;

  void updateProjects(Function(List<String>) updateFn) {
    updateFn(_projects ??= []);
  }

  bool hasProjects() => _projects != null;

  // "ativities" field.
  List<String>? _ativities;
  List<String> get ativities => _ativities ?? const [];
  set ativities(List<String>? val) => _ativities = val;

  void updateAtivities(Function(List<String>) updateFn) {
    updateFn(_ativities ??= []);
  }

  bool hasAtivities() => _ativities != null;

  // "time" field.
  String? _time;
  String get time => _time ?? '';
  set time(String? val) => _time = val;

  bool hasTime() => _time != null;

  // "initTime" field.
  String? _initTime;
  String get initTime => _initTime ?? '';
  set initTime(String? val) => _initTime = val;

  bool hasInitTime() => _initTime != null;

  // "finishTime" field.
  String? _finishTime;
  String get finishTime => _finishTime ?? '';
  set finishTime(String? val) => _finishTime = val;

  bool hasFinishTime() => _finishTime != null;

  static AtivitiesStruct fromMap(Map<String, dynamic> data) => AtivitiesStruct(
        projects: getDataList(data['projects']),
        ativities: getDataList(data['ativities']),
        time: data['time'] as String?,
        initTime: data['initTime'] as String?,
        finishTime: data['finishTime'] as String?,
      );

  static AtivitiesStruct? maybeFromMap(dynamic data) => data is Map
      ? AtivitiesStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'projects': _projects,
        'ativities': _ativities,
        'time': _time,
        'initTime': _initTime,
        'finishTime': _finishTime,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'projects': serializeParam(
          _projects,
          ParamType.String,
          isList: true,
        ),
        'ativities': serializeParam(
          _ativities,
          ParamType.String,
          isList: true,
        ),
        'time': serializeParam(
          _time,
          ParamType.String,
        ),
        'initTime': serializeParam(
          _initTime,
          ParamType.String,
        ),
        'finishTime': serializeParam(
          _finishTime,
          ParamType.String,
        ),
      }.withoutNulls;

  static AtivitiesStruct fromSerializableMap(Map<String, dynamic> data) =>
      AtivitiesStruct(
        projects: deserializeParam<String>(
          data['projects'],
          ParamType.String,
          true,
        ),
        ativities: deserializeParam<String>(
          data['ativities'],
          ParamType.String,
          true,
        ),
        time: deserializeParam(
          data['time'],
          ParamType.String,
          false,
        ),
        initTime: deserializeParam(
          data['initTime'],
          ParamType.String,
          false,
        ),
        finishTime: deserializeParam(
          data['finishTime'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'AtivitiesStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality();
    return other is AtivitiesStruct &&
        listEquality.equals(projects, other.projects) &&
        listEquality.equals(ativities, other.ativities) &&
        time == other.time &&
        initTime == other.initTime &&
        finishTime == other.finishTime;
  }

  @override
  int get hashCode => const ListEquality()
      .hash([projects, ativities, time, initTime, finishTime]);
}

AtivitiesStruct createAtivitiesStruct({
  String? time,
  String? initTime,
  String? finishTime,
}) =>
    AtivitiesStruct(
      time: time,
      initTime: initTime,
      finishTime: finishTime,
    );
