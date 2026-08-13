import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/instant_timer.dart';
import '/index.dart';
import 'logout_widget.dart' show LogoutWidget;
import 'package:flutter/material.dart';

class LogoutModel extends FlutterFlowModel<LogoutWidget> {
  ///  State fields for stateful widgets in this page.

  InstantTimer? FirstTimer;
  // Stores action output result for [Backend Call - API (AddAtivities)] action in Logout widget.
  ApiCallResponse? apiResult4ww;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    FirstTimer?.cancel();
  }
}
