import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'expediente_widget.dart' show ExpedienteWidget;
import 'package:flutter/material.dart';

class ExpedienteModel extends FlutterFlowModel<ExpedienteWidget> {
  ///  Local state fields for this page.

  double? workedHours;

  /// Work target of the selected period (API or 8h/40h/176h fallback).
  double? goalHours;

  bool day = true;

  bool week = false;

  bool month = false;

  dynamic tasksDone;

  String? firstName;

  DateTime? initDate;

  DateTime? endDate;

  int? ignoredPopUps = 0;

  ///  State fields for stateful widgets in this page.

  // Last responses of the dashboard calls (GetWorkedHours, GetTaskDoneByUser,
  // ignoredPopUps, GetWorkGoal) for the selected period.
  ApiCallResponse? workedHoursResp;
  ApiCallResponse? tasksDoneResp;
  ApiCallResponse? ignoredPopupsResp;
  ApiCallResponse? workGoalResp;
  DateTime? datePicked1;
  DateTime? datePicked2;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
