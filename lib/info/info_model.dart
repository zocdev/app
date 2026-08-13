import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'info_widget.dart' show InfoWidget;
import 'package:flutter/material.dart';

class InfoModel extends FlutterFlowModel<InfoWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for email widget.
  FocusNode? emailFocusNode1;
  TextEditingController? emailTextController1;
  String? Function(BuildContext, String?)? emailTextController1Validator;
  // State field(s) for TextFieldNovaSenha widget.
  FocusNode? textFieldNovaSenhaFocusNode;
  TextEditingController? textFieldNovaSenhaTextController;
  late bool textFieldNovaSenhaVisibility;
  String? Function(BuildContext, String?)?
      textFieldNovaSenhaTextControllerValidator;
  // State field(s) for TextFieldConfirmSenha widget.
  FocusNode? textFieldConfirmSenhaFocusNode;
  TextEditingController? textFieldConfirmSenhaTextController;
  late bool textFieldConfirmSenhaVisibility;
  String? Function(BuildContext, String?)?
      textFieldConfirmSenhaTextControllerValidator;
  // Stores action output result for [Backend Call - API (registerUser)] action in finalizar widget.
  ApiCallResponse? sendInfo;
  // State field(s) for email widget.
  FocusNode? emailFocusNode2;
  TextEditingController? emailTextController2;
  String? Function(BuildContext, String?)? emailTextController2Validator;

  @override
  void initState(BuildContext context) {
    textFieldNovaSenhaVisibility = false;
    textFieldConfirmSenhaVisibility = false;
  }

  @override
  void dispose() {
    emailFocusNode1?.dispose();
    emailTextController1?.dispose();

    textFieldNovaSenhaFocusNode?.dispose();
    textFieldNovaSenhaTextController?.dispose();

    textFieldConfirmSenhaFocusNode?.dispose();
    textFieldConfirmSenhaTextController?.dispose();

    emailFocusNode2?.dispose();
    emailTextController2?.dispose();
  }
}
