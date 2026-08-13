import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'verify_token_widget.dart' show VerifyTokenWidget;
import 'package:flutter/material.dart';

class VerifyTokenModel extends FlutterFlowModel<VerifyTokenWidget> {
  static const otpLength = 6;

  final List<TextEditingController> otpControllers =
      List.generate(otpLength, (_) => TextEditingController());
  final List<FocusNode> otpFocusNodes =
      List.generate(otpLength, (_) => FocusNode());

  ApiCallResponse? otpResult;

  String get otp => otpControllers.map((c) => c.text).join();

  void clearOtp() {
    for (final controller in otpControllers) {
      controller.clear();
    }
  }

  void focusFirst() {
    if (otpFocusNodes.isNotEmpty) {
      otpFocusNodes.first.requestFocus();
    }
  }

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    for (final controller in otpControllers) {
      controller.dispose();
    }
    for (final focusNode in otpFocusNodes) {
      focusNode.dispose();
    }
  }
}
