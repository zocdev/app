import '/auth/custom_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'popup_dialog_widget.dart' show PopupDialogWidget;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class PopupDialogModel extends FlutterFlowModel<PopupDialogWidget> {
  ///  Local state fields for this component.

  bool mostrarActividad = true;

  List<String> selectedAtivities = [];
  void addToSelectedAtivities(String item) => selectedAtivities.add(item);
  void removeFromSelectedAtivities(String item) =>
      selectedAtivities.remove(item);
  void removeAtIndexFromSelectedAtivities(int index) =>
      selectedAtivities.removeAt(index);
  void insertAtIndexInSelectedAtivities(int index, String item) =>
      selectedAtivities.insert(index, item);
  void updateSelectedAtivitiesAtIndex(int index, Function(String) updateFn) =>
      selectedAtivities[index] = updateFn(selectedAtivities[index]);

  String? selectedProjects;

  List<String> selectedAtivitieLabel = [];
  void addToSelectedAtivitieLabel(String item) =>
      selectedAtivitieLabel.add(item);
  void removeFromSelectedAtivitieLabel(String item) =>
      selectedAtivitieLabel.remove(item);
  void removeAtIndexFromSelectedAtivitieLabel(int index) =>
      selectedAtivitieLabel.removeAt(index);
  void insertAtIndexInSelectedAtivitieLabel(int index, String item) =>
      selectedAtivitieLabel.insert(index, item);
  void updateSelectedAtivitieLabelAtIndex(
          int index, Function(String) updateFn) =>
      selectedAtivitieLabel[index] = updateFn(selectedAtivitieLabel[index]);

  String? selectedProjectLabel;

  String? selectedClient;

  ///  State fields for stateful widgets in this component.

  final formKey = GlobalKey<FormState>();
  AudioPlayer? soundPlayer;
  // State field(s) for ClientDropDown widget.
  String? clientDropDownValue;
  FormFieldController<String>? clientDropDownValueController;
  // State field(s) for Dropdownprojetos widget.
  String? dropdownprojetosValue;
  FormFieldController<String>? dropdownprojetosValueController;
  // Stores action output result for [Backend Call - API (GetAtivitiesByProject)] action in Dropdownprojetos widget.
  ApiCallResponse? activities;
  // State field(s) for Dropdownatividades widget.
  List<String>? dropdownatividadesValue;
  FormFieldController<List<String>>? dropdownatividadesValueController;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Stores action output result for [Validate Form] action in Button widget.
  bool? validate;
  // Stores action output result for [Backend Call - API (AddAtivities)] action in Button widget.
  ApiCallResponse? apiResult4ww;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }

  /// Action blocks.
  Future fetchdata(BuildContext context) async {
    ApiCallResponse? clients;
    ApiCallResponse? projects;

    await Future.wait([
      Future(() async {
        clients = await GetClientsCall.call(
          token: currentAuthenticationToken,
        );

        if ((clients?.succeeded ?? true)) {
          FFAppState().clientsOptions =
              (((clients?.jsonBody is List ? clients!.jsonBody as List : const [])
                          .map<OptionStruct?>(OptionStruct.maybeFromMap)
                          .toList()) as Iterable<OptionStruct?>)
                  .withoutNulls
                  .toList()
                  .cast<OptionStruct>();
        } else {
          return;
        }
      }),
      Future(() async {
        projects = await GetProjectsCall.call(
          token: currentAuthenticationToken,
          userid: UserDataStruct.maybeFromMap(FFAppState().UserData)?.user.id,
        );

        if ((projects?.succeeded ?? true)) {
          FFAppState().projectOptions =
              (((projects?.jsonBody is List
                              ? projects!.jsonBody as List
                              : const [])
                          .map<ProjectOptionStruct?>(
                              ProjectOptionStruct.maybeFromMap)
                          .toList()) as Iterable<ProjectOptionStruct?>)
                  .withoutNulls
                  .map((e) => e.toMap())
                  .toList()
                  .toList()
                  .cast<dynamic>();
        } else {
          return;
        }
      }),
    ]);
  }
}
