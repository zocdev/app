import '/backend/api_requests/api_calls.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_data_table.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'expediente_widget.dart' show ExpedienteWidget;
import 'package:flutter/material.dart';

class ExpedienteModel extends FlutterFlowModel<ExpedienteWidget> {
  ///  Local state fields for this page.

  bool? buttonDownload = false;

  DateTime? initialDate;

  FFUploadedFile? pruebaandriana;

  double? workedHours;

  bool day = true;

  bool week = false;

  bool month = false;

  dynamic tasksDone;

  String? firstName;

  DateTime? initDate;

  DateTime? endDate;

  int? ignoredPopUps = 0;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - API (GetWorkedHours)] action in Expediente widget.
  ApiCallResponse? getDayWorkedHoursRow;
  // Stores action output result for [Backend Call - API (GetTaskDoneByUser)] action in Expediente widget.
  ApiCallResponse? getTaskDoneByDayRowResp;
  // Stores action output result for [Backend Call - API (ignoredPopUps)] action in Expediente widget.
  ApiCallResponse? ignoredPopups;
  // Stores action output result for [Backend Call - API (GetWorkedHours)] action in Button widget.
  ApiCallResponse? getDayWorkedHours;
  // Stores action output result for [Backend Call - API (GetTaskDoneByUser)] action in Button widget.
  ApiCallResponse? getTaskDoneByDayResp;
  // Stores action output result for [Backend Call - API (ignoredPopUps)] action in Button widget.
  ApiCallResponse? ignoredPopupsByDay;
  // Stores action output result for [Backend Call - API (GetWorkedHours)] action in Button widget.
  ApiCallResponse? getWeekWorkedHours;
  // Stores action output result for [Backend Call - API (GetTaskDoneByUser)] action in Button widget.
  ApiCallResponse? getTaskDoneByWeekResp;
  // Stores action output result for [Backend Call - API (ignoredPopUps)] action in Button widget.
  ApiCallResponse? ignoredPopupsByWeek;
  // Stores action output result for [Backend Call - API (GetWorkedHours)] action in Button widget.
  ApiCallResponse? getMonthWorkedHours;
  // Stores action output result for [Backend Call - API (GetTaskDoneByUser)] action in Button widget.
  ApiCallResponse? getTaskDoneByMonthResp;
  // Stores action output result for [Backend Call - API (ignoredPopUps)] action in Button widget.
  ApiCallResponse? ignoredPopupsByMonth;
  DateTime? datePicked1;
  DateTime? datePicked2;
  // Stores action output result for [Backend Call - API (GetWorkedHours)] action in Button widget.
  ApiCallResponse? getInitAndEndWorkedHours;
  // Stores action output result for [Backend Call - API (GetTaskDoneByUser)] action in Button widget.
  ApiCallResponse? getTaskDoneByInitAndEndDateResp;
  // Stores action output result for [Backend Call - API (ignoredPopUps)] action in Button widget.
  ApiCallResponse? ignoredPopupsInit;
  // Stores action output result for [Backend Call - API (GetWorkedHours)] action in Icon widget.
  ApiCallResponse? getDayInitWorkedHours;
  // Stores action output result for [Backend Call - API (GetTaskDoneByUser)] action in Icon widget.
  ApiCallResponse? getTaskDoneByInitResp;
  // Stores action output result for [Backend Call - API (ignoredPopUps)] action in Icon widget.
  ApiCallResponse? ignoredPopupsByInit;
  // State field(s) for PaginatedDataTable widget.
  final paginatedDataTableController =
      FlutterFlowDataTableController<TaskDoneStruct>();

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    paginatedDataTableController.dispose();
  }
}
