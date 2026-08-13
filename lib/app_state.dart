import 'package:flutter/material.dart';
import '/backend/schema/structs/index.dart';
import 'dart:convert';
import 'utils/error_handler.dart';
import 'utils/secure_storage_service.dart';

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}

dynamic _repairUtf8Mojibake(dynamic value) {
  if (value is String) {
    try {
      return utf8.decode(latin1.encode(value));
    } catch (_) {
      return value;
    }
  }
  if (value is Map) {
    return {
      for (final entry in value.entries)
        entry.key: _repairUtf8Mojibake(entry.value),
    };
  }
  if (value is List) {
    return value.map(_repairUtf8Mojibake).toList();
  }
  return value;
}

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  SecureStorageService get _storage => SecureStorageService.instance;

  Future initializePersistedState() async {
    await _storage.initialize();

    _safeInit(() {
      _email = _storage.getString('ff_email') ?? _email;
    });
    _safeInit(() {
      if (_storage.containsKey('ff_UserData')) {
        try {
          final userData = _storage.getString('ff_UserData');
          if (userData != null && userData.isNotEmpty) {
            _UserData = _repairUtf8Mojibake(jsonDecode(userData));
            _storage.setString('ff_UserData', jsonEncode(_UserData));
          }
        } catch (e) {
          print("Can't decode persisted json. Error: $e.");
        }
      }
    });
    _safeInit(() {
      _rememberMe = _storage.getBool('ff_rememberMe') ?? _rememberMe;
    });
    _safeInit(() {
      _savedEmail = _storage.getString('ff_savedEmail') ?? _savedEmail;
    });
    _safeInit(() {
      _firstLogin = _storage.getBool('ff_firstLogin') ?? _firstLogin;
    });
    _safeInit(() {
      final timestamp = _storage.getInt('ff_currentDate');
      if (timestamp != null) {
        _currentDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    });
    _safeInit(() {
      _dataSave = _storage.getStringList('ff_dataSave')?.map((x) {
            try {
              return jsonDecode(x);
            } catch (e) {
              print("Can't decode persisted json. Error: $e.");
              return {};
            }
          }).toList() ??
          _dataSave;
    });
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  void _persistDataSave() {
    _storage.setStringList(
        'ff_dataSave', _dataSave.map((x) => jsonEncode(x)).toList());
  }

  bool _isPopupVisible = false;
  bool get isPopupVisible => _isPopupVisible;
  set isPopupVisible(bool value) {
    _isPopupVisible = value;
  }

  bool _loginFailed = false;
  bool get loginFailed => _loginFailed;
  set loginFailed(bool value) {
    _loginFailed = value;
  }

  String _email = '';
  String get email => _email;
  set email(String value) {
    _email = value;
    _storage.setString('ff_email', value);
  }

  String _password = '';
  String get password => _password;
  set password(String value) {
    _password = value;
  }

  List<TasksStruct> _selectedTasks = [];
  List<TasksStruct> get selectedTasks => _selectedTasks;
  set selectedTasks(List<TasksStruct> value) {
    _selectedTasks = value;
  }

  void addToSelectedTasks(TasksStruct value) {
    selectedTasks.add(value);
  }

  void removeFromSelectedTasks(TasksStruct value) {
    selectedTasks.remove(value);
  }

  void removeAtIndexFromSelectedTasks(int index) {
    selectedTasks.removeAt(index);
  }

  void updateSelectedTasksAtIndex(
    int index,
    TasksStruct Function(TasksStruct) updateFn,
  ) {
    selectedTasks[index] = updateFn(_selectedTasks[index]);
  }

  void insertAtIndexInSelectedTasks(int index, TasksStruct value) {
    selectedTasks.insert(index, value);
  }

  String _taskDescription = '';
  String get taskDescription => _taskDescription;
  set taskDescription(String value) {
    _taskDescription = value;
  }

  dynamic _UserData;
  dynamic get UserData => _UserData;
  set UserData(dynamic value) {
    _UserData = _repairUtf8Mojibake(value);
    _storage.setString('ff_UserData', jsonEncode(_UserData));
  }

  bool _rememberMe = true;
  bool get rememberMe => _rememberMe;
  set rememberMe(bool value) {
    _rememberMe = value;
    _storage.setBool('ff_rememberMe', value);
  }

  String _savedEmail = '';
  String get savedEmail => _savedEmail;
  set savedEmail(String value) {
    _savedEmail = value;
    _storage.setString('ff_savedEmail', value);
  }

  bool _firstLogin = true;
  bool get firstLogin => _firstLogin;
  set firstLogin(bool value) {
    _firstLogin = value;
    _storage.setBool('ff_firstLogin', value);
  }

  List<String> _atividadesFeitas = [];
  List<String> get atividadesFeitas => _atividadesFeitas;
  set atividadesFeitas(List<String> value) {
    _atividadesFeitas = value;
  }

  void addToAtividadesFeitas(String value) {
    atividadesFeitas.add(value);
  }

  void removeFromAtividadesFeitas(String value) {
    atividadesFeitas.remove(value);
  }

  void removeAtIndexFromAtividadesFeitas(int index) {
    atividadesFeitas.removeAt(index);
  }

  void updateAtividadesFeitasAtIndex(
    int index,
    String Function(String) updateFn,
  ) {
    atividadesFeitas[index] = updateFn(_atividadesFeitas[index]);
  }

  void insertAtIndexInAtividadesFeitas(int index, String value) {
    atividadesFeitas.insert(index, value);
  }

  DateTime? _currentDate = DateTime.fromMillisecondsSinceEpoch(1742353200000);
  DateTime? get currentDate => _currentDate;
  set currentDate(DateTime? value) {
    _currentDate = value;
    if (value != null) {
      _storage.setInt('ff_currentDate', value.millisecondsSinceEpoch);
    } else {
      _storage.remove('ff_currentDate');
    }
  }

  List<String> _selectedProject = [];
  List<String> get selectedProject => _selectedProject;
  set selectedProject(List<String> value) {
    _selectedProject = value;
  }

  void addToSelectedProject(String value) {
    selectedProject.add(value);
  }

  void removeFromSelectedProject(String value) {
    selectedProject.remove(value);
  }

  void removeAtIndexFromSelectedProject(int index) {
    selectedProject.removeAt(index);
  }

  void updateSelectedProjectAtIndex(
    int index,
    String Function(String) updateFn,
  ) {
    selectedProject[index] = updateFn(_selectedProject[index]);
  }

  void insertAtIndexInSelectedProject(int index, String value) {
    selectedProject.insert(index, value);
  }

  List<int> _pdfBytes = [];
  List<int> get pdfBytes => _pdfBytes;
  set pdfBytes(List<int> value) {
    _pdfBytes = value;
  }

  void addToPdfBytes(int value) {
    pdfBytes.add(value);
  }

  void removeFromPdfBytes(int value) {
    pdfBytes.remove(value);
  }

  void removeAtIndexFromPdfBytes(int index) {
    pdfBytes.removeAt(index);
  }

  void updatePdfBytesAtIndex(
    int index,
    int Function(int) updateFn,
  ) {
    pdfBytes[index] = updateFn(_pdfBytes[index]);
  }

  void insertAtIndexInPdfBytes(int index, int value) {
    pdfBytes.insert(index, value);
  }

  List<String> _activitie = [];
  List<String> get activitie => _activitie;
  set activitie(List<String> value) {
    _activitie = value;
  }

  void addToActivitie(String value) {
    activitie.add(value);
  }

  void removeFromActivitie(String value) {
    activitie.remove(value);
  }

  void removeAtIndexFromActivitie(int index) {
    activitie.removeAt(index);
  }

  void updateActivitieAtIndex(
    int index,
    String Function(String) updateFn,
  ) {
    activitie[index] = updateFn(_activitie[index]);
  }

  void insertAtIndexInActivitie(int index, String value) {
    activitie.insert(index, value);
  }

  dynamic _emailData;
  dynamic get emailData => _emailData;
  set emailData(dynamic value) {
    _emailData = value;
  }

  bool _remoteValue = false;
  bool get remoteValue => _isRemote;
  set remoteValue(bool value) {
    _remoteValue = value;
    _isRemote = value;
    _selectedMode = value ? 'Remoto' : 'Local';
  }

  String _selectedMode = 'Local';
  String get selectedMode => _selectedMode;
  set selectedMode(String value) {
    _selectedMode = value;
    final remote = value == 'Remoto';
    _isRemote = remote;
    _remoteValue = remote;
  }

  List<dynamic> _dataSave = [];
  List<dynamic> get dataSave => _dataSave;
  set dataSave(List<dynamic> value) {
    _dataSave = value;
    _persistDataSave();
  }

  void addToDataSave(dynamic value) {
    dataSave.add(value);
    _persistDataSave();
  }

  void removeFromDataSave(dynamic value) {
    dataSave.remove(value);
    _persistDataSave();
  }

  void removeAtIndexFromDataSave(int index) {
    dataSave.removeAt(index);
    _persistDataSave();
  }

  void updateDataSaveAtIndex(
    int index,
    dynamic Function(dynamic) updateFn,
  ) {
    dataSave[index] = updateFn(_dataSave[index]);
    _persistDataSave();
  }

  void insertAtIndexInDataSave(int index, dynamic value) {
    dataSave.insert(index, value);
    _persistDataSave();
  }

  int _popUpIgnorado = 0;
  int get popUpIgnorado => _popUpIgnorado;
  set popUpIgnorado(int value) {
    _popUpIgnorado = value;
  }

  int _contador = 0;
  int get contador => _contador;
  set contador(int value) {
    _contador = value;
  }

  List<dynamic> _projectOptions = [];
  List<dynamic> get projectOptions => _projectOptions;
  set projectOptions(List<dynamic> value) {
    _projectOptions = value;
  }

  void addToProjectOptions(dynamic value) {
    projectOptions.add(value);
  }

  void removeFromProjectOptions(dynamic value) {
    projectOptions.remove(value);
  }

  void removeAtIndexFromProjectOptions(int index) {
    projectOptions.removeAt(index);
  }

  void updateProjectOptionsAtIndex(
    int index,
    dynamic Function(dynamic) updateFn,
  ) {
    projectOptions[index] = updateFn(_projectOptions[index]);
  }

  void insertAtIndexInProjectOptions(int index, dynamic value) {
    projectOptions.insert(index, value);
  }

  List<dynamic> _taskOptions = [];
  List<dynamic> get taskOptions => _taskOptions;
  set taskOptions(List<dynamic> value) {
    _taskOptions = value;
  }

  void addToTaskOptions(dynamic value) {
    taskOptions.add(value);
  }

  void removeFromTaskOptions(dynamic value) {
    taskOptions.remove(value);
  }

  void removeAtIndexFromTaskOptions(int index) {
    taskOptions.removeAt(index);
  }

  void updateTaskOptionsAtIndex(
    int index,
    dynamic Function(dynamic) updateFn,
  ) {
    taskOptions[index] = updateFn(_taskOptions[index]);
  }

  void insertAtIndexInTaskOptions(int index, dynamic value) {
    taskOptions.insert(index, value);
  }

  List<OptionStruct> _clientsOptions = [];
  List<OptionStruct> get clientsOptions => _clientsOptions;
  set clientsOptions(List<OptionStruct> value) {
    _clientsOptions = value;
  }

  void addToClientsOptions(OptionStruct value) {
    clientsOptions.add(value);
  }

  void removeFromClientsOptions(OptionStruct value) {
    clientsOptions.remove(value);
  }

  void removeAtIndexFromClientsOptions(int index) {
    clientsOptions.removeAt(index);
  }

  void updateClientsOptionsAtIndex(
    int index,
    OptionStruct Function(OptionStruct) updateFn,
  ) {
    clientsOptions[index] = updateFn(_clientsOptions[index]);
  }

  void insertAtIndexInClientsOptions(int index, OptionStruct value) {
    clientsOptions.insert(index, value);
  }

  List<TaskDoneStruct> _taskDone = [];
  List<TaskDoneStruct> get taskDone => _taskDone;
  set taskDone(List<TaskDoneStruct> value) {
    _taskDone = value;
  }

  void addToTaskDone(TaskDoneStruct value) {
    taskDone.add(value);
  }

  void removeFromTaskDone(TaskDoneStruct value) {
    taskDone.remove(value);
  }

  void removeAtIndexFromTaskDone(int index) {
    taskDone.removeAt(index);
  }

  void updateTaskDoneAtIndex(
    int index,
    TaskDoneStruct Function(TaskDoneStruct) updateFn,
  ) {
    taskDone[index] = updateFn(_taskDone[index]);
  }

  void insertAtIndexInTaskDone(int index, TaskDoneStruct value) {
    taskDone.insert(index, value);
  }

  bool _isRemote = false;
  bool get isRemote => _isRemote;
  set isRemote(bool value) {
    _isRemote = value;
    _remoteValue = value;
    _selectedMode = value ? 'Remoto' : 'Local';
  }

  AppError? _lastError;
  AppError? get lastError => _lastError;
  set lastError(AppError? value) {
    _lastError = value;
    notifyListeners();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }
}
