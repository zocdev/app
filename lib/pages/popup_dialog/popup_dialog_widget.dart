import '/auth/custom_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'popup_dialog_model.dart';
export 'popup_dialog_model.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class PopupDialogWidget extends StatefulWidget {
  const PopupDialogWidget({
    super.key,
    this.screenshotBase64,
    this.ignoreAfter = const Duration(minutes: 15),
  });

  final String? screenshotBase64;
  final Duration ignoreAfter;

  @override
  State<PopupDialogWidget> createState() => _PopupDialogWidgetState();
}

class _PopupDialogWidgetState extends State<PopupDialogWidget> {
  late PopupDialogModel _model;
  Timer? _ignoreTimer;
  bool _submitted = false;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  void _scheduleIgnoreTimer() {
    _ignoreTimer?.cancel();
    _ignoreTimer = Timer(widget.ignoreAfter, _onIgnoreTimeout);
  }

  Future<void> _onIgnoreTimeout() async {
    if (!mounted || _submitted) return;
    _submitted = true;
    FFAppState().popUpIgnorado = FFAppState().popUpIgnorado + 1;
    FFAppState().isPopupVisible = false;
    Navigator.pop(context);
    await AddAtivitiesCall.call(
      token: currentAuthenticationToken,
      project: '',
      remote: FFAppState().isRemote,
      ignoredPopUp: true,
      createdAt: functions.timeNowTZ(),
    );
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PopupDialogModel());
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS)) {
      windowManager.setSize(const Size(510, 600));
    }

    FFAppState().isPopupVisible = true;

    // On component load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _scheduleIgnoreTimer();

      _model.soundPlayer ??= AudioPlayer();
      if (_model.soundPlayer!.playing) {
        await _model.soundPlayer!.stop();
      }
      _model.soundPlayer!.setVolume(1.0);
      _model.soundPlayer!
          .setAsset('assets/audios/aviso.mp3')
          .then((_) => _model.soundPlayer!.play());

      await _model.fetchdata(context);
      if (!mounted) return;
      safeSetState(() {});
    });

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _ignoreTimer?.cancel();
    _model.maybeDispose();
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS)) {
      windowManager.setSize(const Size(510, 435));
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return Align(
      alignment: AlignmentDirectional(0.0, 0.0),
      child: Container(
        width: 500.0,
        height: 570.4,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFADDAEA), Color(0xFF4CAED1)],
            stops: [0.2, 0.5, 1.0],
            begin: AlignmentDirectional(-1.0, -1.0),
            end: AlignmentDirectional(1.0, 1.0),
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(0.0),
            bottomRight: Radius.circular(0.0),
            topLeft: Radius.circular(0.0),
            topRight: Radius.circular(0.0),
          ),
        ),
        alignment: AlignmentDirectional(0.0, 0.0),
        child: Align(
          alignment: AlignmentDirectional(0.0, 0.0),
          child: Form(
            key: _model.formKey,
            autovalidateMode: AutovalidateMode.always,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: AlignmentDirectional(0.0, 0.0),
                    child: Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 0.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Align(
                            alignment: AlignmentDirectional(-1.0, -1.0),
                            child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 20.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.asset(
                                  'assets/images/ZOC.webp',
                                  width: 90.0,
                                  height: 80.0,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    'No que está trabalhando?',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w600,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          color: Color(0xFF102A43),
                          fontSize: 30.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w600,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                  ),
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 25.0, 0.0, 0.0),
                    child: FlutterFlowDropDown<String>(
                      controller: _model.clientDropDownValueController ??=
                          FormFieldController<String>(null),
                      options: List<String>.from(FFAppState()
                          .clientsOptions
                          .map((e) => e.id)
                          .toList()),
                      optionLabels: FFAppState()
                          .clientsOptions
                          .map((e) => e.name)
                          .toList(),
                      onChanged: (val) async {
                        safeSetState(() => _model.clientDropDownValue = val);
                        _model.selectedClient = _model.clientDropDownValue;
                        safeSetState(() {});
                      },
                      width: 400.0,
                      height: 35.0,
                      maxHeight: 200.0,
                      searchHintTextStyle:
                          FlutterFlowTheme.of(context).labelMedium.override(
                                font: GoogleFonts.inter(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .fontStyle,
                                ),
                                fontSize: 14.0,
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .fontStyle,
                              ),
                      searchTextStyle:
                          FlutterFlowTheme.of(context).bodyMedium.override(
                                font: GoogleFonts.inter(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                      textStyle:
                          FlutterFlowTheme.of(context).bodyMedium.override(
                                font: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                                color: Color(0xFF006994),
                                fontSize: 14.0,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w500,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                                lineHeight: 0.5,
                              ),
                      hintText: 'Escolha os clientes',
                      searchHintText: 'Search...',
                      searchCursorColor:
                          FlutterFlowTheme.of(context).primaryBackground,
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFF006994),
                        size: 25.0,
                      ),
                      fillColor: FlutterFlowTheme.of(context).primaryBackground,
                      elevation: 1.0,
                      borderColor:
                          FlutterFlowTheme.of(context).secondaryBackground,
                      borderWidth: 0.0,
                      borderRadius: 6.0,
                      margin:
                          EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
                      hidesUnderline: true,
                      isOverButton: false,
                      isSearchable: true,
                      isMultiSelect: false,
                    ),
                  ),
                  if ((FFAppState().projectOptions.isNotEmpty) == true)
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 15.0, 0.0, 0.0),
                      child: FlutterFlowDropDown<String>(
                        controller: _model.dropdownprojetosValueController ??=
                            FormFieldController<String>(
                          _model.dropdownprojetosValue ??= '3',
                        ),
                        options: List<String>.from(FFAppState()
                            .projectOptions
                            .where((e) =>
                                ProjectOptionStruct.maybeFromMap(e)?.clientId ==
                                _model.clientDropDownValue)
                            .toList()
                            .map((e) => ProjectOptionStruct.maybeFromMap(e)?.id)
                            .withoutNulls
                            .toList()),
                        optionLabels: FFAppState()
                            .projectOptions
                            .where((e) =>
                                ProjectOptionStruct.maybeFromMap(e)?.clientId ==
                                _model.selectedClient)
                            .toList()
                            .map((e) =>
                                ProjectOptionStruct.maybeFromMap(e)?.name)
                            .withoutNulls
                            .toList(),
                        onChanged: (val) async {
                          safeSetState(
                              () => _model.dropdownprojetosValue = val);
                          _model.selectedProjects =
                              _model.dropdownprojetosValue;
                          safeSetState(() {});
                          _model.activities =
                              await GetAtivitiesByProjectCall.call(
                            token: currentAuthenticationToken,
                            id: _model.selectedProjects,
                          );

                          if ((_model.activities?.succeeded ?? true)) {
                            FFAppState().taskOptions =
                                (_model.activities?.jsonBody is List
                                        ? _model.activities!.jsonBody as List
                                        : const [])
                                    .toList()
                                    .cast<dynamic>();
                            safeSetState(() {});
                          }

                          safeSetState(() {});
                        },
                        width: 400.0,
                        height: 35.0,
                        maxHeight: 200.0,
                        searchHintTextStyle:
                            FlutterFlowTheme.of(context).labelMedium.override(
                                  font: GoogleFonts.inter(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontStyle,
                                  ),
                                  fontSize: 14.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .fontStyle,
                                ),
                        searchTextStyle:
                            FlutterFlowTheme.of(context).bodyMedium.override(
                                  font: GoogleFonts.inter(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                        textStyle:
                            FlutterFlowTheme.of(context).bodyMedium.override(
                                  font: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  color: Color(0xFF006994),
                                  fontSize: 14.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                  lineHeight: 0.5,
                                ),
                        hintText: 'Escolha os projetos',
                        searchHintText: 'Search...',
                        searchCursorColor:
                            FlutterFlowTheme.of(context).primaryBackground,
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: Color(0xFF006994),
                          size: 25.0,
                        ),
                        fillColor:
                            FlutterFlowTheme.of(context).primaryBackground,
                        elevation: 1.0,
                        borderColor:
                            FlutterFlowTheme.of(context).secondaryBackground,
                        borderWidth: 0.0,
                        borderRadius: 6.0,
                        margin: EdgeInsetsDirectional.fromSTEB(
                            12.0, 0.0, 12.0, 0.0),
                        hidesUnderline: true,
                        isOverButton: false,
                        isSearchable: true,
                        isMultiSelect: false,
                      ),
                    ),
                  if ((FFAppState().taskOptions.isNotEmpty) == true)
                    Align(
                      alignment: AlignmentDirectional(0.0, 0.0),
                      child: Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 15.0, 0.0, 0.0),
                        child: FlutterFlowDropDown<String>(
                          multiSelectController:
                              _model.dropdownatividadesValueController ??=
                                  FormListFieldController<String>(null),
                          options: List<String>.from(FFAppState()
                              .taskOptions
                              .map((e) => e.toString())
                              .toList()),
                          optionLabels: FFAppState()
                              .taskOptions
                              .map(
                                  (e) => TaskOptionStruct.maybeFromMap(e)?.name)
                              .withoutNulls
                              .toList(),
                          width: 400.0,
                          height: 35.0,
                          maxHeight: 200.0,
                          searchHintTextStyle:
                              FlutterFlowTheme.of(context).labelMedium.override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontStyle,
                                    lineHeight: 0.5,
                                  ),
                          searchTextStyle:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                          textStyle:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: Color(0xFF006994),
                                    fontSize: 14.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                          hintText: 'Escolha as Atividades',
                          searchHintText: 'Search...',
                          icon: Icon(
                            Icons.keyboard_arrow_down_sharp,
                            color: Color(0xFF006994),
                            size: 25.0,
                          ),
                          fillColor:
                              FlutterFlowTheme.of(context).primaryBackground,
                          elevation: 1.0,
                          borderColor:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          borderWidth: 0.0,
                          borderRadius: 6.0,
                          margin: EdgeInsetsDirectional.fromSTEB(
                              12.0, 0.0, 12.0, 0.0),
                          hidesUnderline: true,
                          disabled: _model.mostrarActividad == false,
                          isOverButton: true,
                          isSearchable: true,
                          isMultiSelect: true,
                          onMultiSelectChanged: (val) => safeSetState(
                              () => _model.dropdownatividadesValue = val),
                        ),
                      ),
                    ),
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 15.0, 0.0, 0.0),
                    child: SizedBox(
                      width: 400.0,
                      child: TextFormField(
                        controller: _model.textController,
                        focusNode: _model.textFieldFocusNode,
                        autofocus: false,
                        obscureText: false,
                        decoration: InputDecoration(
                          isDense: true,
                          labelStyle:
                              FlutterFlowTheme.of(context).labelMedium.override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context).primary,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontStyle,
                                  ),
                          hintText: 'Notas',
                          hintStyle:
                              FlutterFlowTheme.of(context).labelMedium.override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                    color: Color(0xFF006994),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontStyle,
                                  ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color(0x00000000),
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color(0x00000000),
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).error,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).error,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          filled: true,
                          fillColor:
                              FlutterFlowTheme.of(context).primaryBackground,
                        ),
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(
                                fontWeight: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              color: FlutterFlowTheme.of(context).primary,
                              letterSpacing: 0.0,
                              fontWeight: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                        maxLines: 3,
                        cursorColor: FlutterFlowTheme.of(context).primaryText,
                        validator:
                            _model.textControllerValidator.asValidator(context),
                      ),
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional(0.0, 1.0),
                    child: Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 20.0, 0.0, 0.0),
                      child: FFButtonWidget(
                        onPressed: () async {
                          _model.validate = true;
                          if (_model.formKey.currentState == null ||
                              !_model.formKey.currentState!.validate()) {
                            safeSetState(() => _model.validate = false);
                            return;
                          }
                          if (_model.clientDropDownValue == null) {
                            await showDialog(
                              context: context,
                              builder: (alertDialogContext) {
                                return AlertDialog(
                                  title: Text('Atenção'),
                                  content: Text('Cliente é necessario.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(alertDialogContext),
                                      child: Text('Ok'),
                                    ),
                                  ],
                                );
                              },
                            );
                            _model.validate = false;
                            safeSetState(() {});
                            return;
                          }
                          _ignoreTimer?.cancel();
                          _submitted = true;
                          _model.apiResult4ww = await AddAtivitiesCall.call(
                            token: currentAuthenticationToken,
                            remote: FFAppState().isRemote,
                            ignoredPopUp: false,
                            tasksList: _model.dropdownatividadesValue,
                            notes: _model.textController.text,
                            createdAt: functions.timeNowTZ(),
                            project: _model.dropdownprojetosValue,
                            screenshot: widget.screenshotBase64,
                          );

                          if ((_model.apiResult4ww?.succeeded ?? true)) {
                            FFAppState().isPopupVisible = false;
                            Navigator.pop(context);
                          } else {
                            _submitted = false;
                            if (mounted) {
                              _scheduleIgnoreTimer();
                            }
                          }

                          safeSetState(() {});
                        },
                        text: 'ACEITAR',
                        options: FFButtonOptions(
                          width: 140.0,
                          height: 50.0,
                          padding: EdgeInsetsDirectional.fromSTEB(
                              16.0, 0.0, 16.0, 0.0),
                          iconPadding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 0.0, 0.0, 0.0),
                          color: Color(0xFF006994),
                          textStyle: FlutterFlowTheme.of(context)
                              .displayMedium
                              .override(
                                font: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .displayMedium
                                      .fontStyle,
                                ),
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                fontSize: 14.0,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.bold,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .displayMedium
                                    .fontStyle,
                              ),
                          elevation: 0.0,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        showLoadingIndicator: true,
                      ),
                    ),
                  ),
                ]
                    .addToStart(SizedBox(height: 20.0))
                    .addToEnd(SizedBox(height: 20.0)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
