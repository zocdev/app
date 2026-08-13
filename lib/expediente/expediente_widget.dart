import '/auth/custom_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_data_table.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/not_ativities/not_ativities_widget.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:aligned_tooltip/aligned_tooltip.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'expediente_model.dart';
export 'expediente_model.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;

class ExpedienteWidget extends StatefulWidget {
  const ExpedienteWidget({super.key});

  static String routeName = 'Expediente';
  static String routePath = '/expediente';

  @override
  State<ExpedienteWidget> createState() => _ExpedienteWidgetState();
}

class _ExpedienteWidgetState extends State<ExpedienteWidget> {
  late ExpedienteModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ExpedienteModel());
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS)) {
      windowManager.setSize(const Size(600, 600));
    }
    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      FFAppState().currentDate = getCurrentTimestamp;
      FFAppState().update(() {});
      _model.day = true;
      _model.week = false;
      _model.month = false;
      _model.firstName = getJsonField(
        FFAppState().UserData,
        r'''$.user.first_name''',
      ).toString().toString();
      safeSetState(() {});
      await Future.wait([
        Future(() async {
          _model.getDayWorkedHoursRow = await GetWorkedHoursCall.call(
            token: currentAuthenticationToken,
            userId: UserDataStruct.maybeFromMap(FFAppState().UserData)?.user.id,
            period: 'today',
          );

          if ((_model.getDayWorkedHoursRow?.succeeded ?? true)) {
            _model.workedHours =
                castToType<double>(_model.getDayWorkedHoursRow?.jsonBody);
            safeSetState(() {});
          } else {
            return;
          }
        }),
        Future(() async {
          _model.getTaskDoneByDayRowResp = await GetTaskDoneByUserCall.call(
            token: currentAuthenticationToken,
            userId: UserDataStruct.maybeFromMap(FFAppState().UserData)?.user.id,
            period: 'day',
          );

          _model.tasksDone =
              (_model.getTaskDoneByDayRowResp?.jsonBody is List)
                  ? _model.getTaskDoneByDayRowResp!.jsonBody
                  : <dynamic>[];
          safeSetState(() {});
        }),
        Future(() async {
          _model.ignoredPopups = await IgnoredPopUpsCall.call(
            id: getJsonField(
              FFAppState().UserData,
              r'''$.user.id''',
            ).toString().toString(),
            period: 'day',
            token: currentAuthenticationToken,
          );

          if ((_model.ignoredPopups?.succeeded ?? true)) {
            _model.ignoredPopUps = IgnoredPopUpsCall.count(_model.ignoredPopups);
            safeSetState(() {});
          }
        }),
      ]);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS)) {
      windowManager.setSize(const Size(510, 435));
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.transparent,
        body: SafeArea(
          top: true,
          child: Align(
            alignment: AlignmentDirectional(0.0, 0.0),
            child: SafeArea(
              child: Container(
                width: 600.0,
                height: 600.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(0.0),
                    bottomRight: Radius.circular(0.0),
                    topLeft: Radius.circular(0.0),
                    topRight: Radius.circular(0.0),
                  ),
                ),
                child: Align(
                  alignment: AlignmentDirectional(0.0, 0.0),
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Align(
                          alignment: AlignmentDirectional(0.0, -1.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Align(
                                alignment: AlignmentDirectional(-1.0, -1.0),
                                child: Text(
                                  dateTimeFormat(
                                    "MMMMEEEEd",
                                    FFAppState().currentDate,
                                    locale: FFLocalizations.of(context)
                                        .languageCode,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.montserrat(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: Color(0xFF102A43),
                                        letterSpacing: 0.0,
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Align(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 5.0, 0.0, 0.0),
                                      child: FlutterFlowIconButton(
                                        borderRadius: 8.0,
                                        buttonSize: 30.0,
                                        fillColor: Color(0xFF006994),
                                        icon: FaIcon(
                                          FontAwesomeIcons.solidFilePdf,
                                          color: Colors.white,
                                          size: 15.0,
                                        ),
                                        onPressed: () async {
                                          await actions.generatePDF(
                                            getJsonField(
                                              _model.tasksDone,
                                              r'''$''',
                                              true,
                                            ),
                                            formatNumber(
                                              TaskDoneStruct.maybeFromMap(
                                                      getJsonField(
                                                _model.tasksDone,
                                                r'''$.hours''',
                                              ).toString())
                                                  ?.hours,
                                              formatType: FormatType.decimal,
                                            ),
                                            getJsonField(
                                              _model.tasksDone,
                                              r'''$.task_name''',
                                            ).toString(),
                                            getJsonField(
                                              _model.tasksDone,
                                              r'''$.project_name''',
                                            ).toString(),
                                            getJsonField(
                                              _model.tasksDone,
                                              r'''$.entry_date''',
                                            ).toString(),
                                            dateTimeFormat(
                                              "d/M/y",
                                              TaskDoneStruct.maybeFromMap(
                                                      getJsonField(
                                                _model.tasksDone,
                                                r'''$.created_at''',
                                              ).toString())
                                                  ?.endDate,
                                              locale:
                                                  FFLocalizations.of(context)
                                                      .languageCode,
                                            ),
                                            dateTimeFormat(
                                              "d/M/y",
                                              TaskDoneStruct.maybeFromMap(
                                                      getJsonField(
                                                _model.tasksDone,
                                                r'''$.ended_at''',
                                              ).toString())
                                                  ?.endDate,
                                              locale:
                                                  FFLocalizations.of(context)
                                                      .languageCode,
                                            ),
                                            getJsonField(
                                              _model.tasksDone,
                                              r'''$.client_name''',
                                            ).toString(),
                                            getJsonField(
                                              _model.tasksDone,
                                              r'''$.user_name''',
                                            ).toString(),
                                            _model.ignoredPopUps?.toString(),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          10.0, 0.0, 0.0, 0.0),
                                      child: InkWell(
                                        splashColor: Colors.transparent,
                                        focusColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        onTap: () async {
                                          context.safePop();
                                        },
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          child: SvgPicture.asset(
                                            'assets/images/Group_810.svg',
                                            width: 18.0,
                                            height: 18.0,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: AlignmentDirectional(0.0, 0.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  FFButtonWidget(
                                    onPressed: () async {
                                      var shouldSetState = false;
                                      _model.endDate = null;
                                      _model.initDate = null;
                                      safeSetState(() {});
                                      _model.day = true;
                                      _model.week = false;
                                      _model.month = false;
                                      safeSetState(() {});
                                      await Future.wait([
                                        Future(() async {
                                          _model.getDayWorkedHours =
                                              await GetWorkedHoursCall.call(
                                            token: currentAuthenticationToken,
                                            userId: UserDataStruct.maybeFromMap(
                                                    FFAppState().UserData)
                                                ?.user
                                                .id,
                                            period: 'today',
                                          );

                                          shouldSetState = true;
                                          if ((_model.getDayWorkedHours
                                                  ?.succeeded ??
                                              true)) {
                                            _model.workedHours =
                                                castToType<double>(getJsonField(
                                              _model.getDayWorkedHours
                                                  ?.jsonBody,
                                              r'''$''',
                                            ));
                                            safeSetState(() {});
                                          } else {
                                            if (shouldSetState) {
                                              safeSetState(() {});
                                            }
                                            return;
                                          }
                                        }),
                                        Future(() async {
                                          _model.getTaskDoneByDayResp =
                                              await GetTaskDoneByUserCall.call(
                                            token: currentAuthenticationToken,
                                            userId: UserDataStruct.maybeFromMap(
                                                    FFAppState().UserData)
                                                ?.user
                                                .id,
                                            period: 'day',
                                          );

                                          shouldSetState = true;
                                          _model.tasksDone = (_model
                                                      .getTaskDoneByDayResp
                                                      ?.jsonBody is List)
                                              ? _model.getTaskDoneByDayResp!
                                                  .jsonBody
                                              : <dynamic>[];
                                          safeSetState(() {});
                                        }),
                                        Future(() async {
                                          _model.ignoredPopupsByDay =
                                              await IgnoredPopUpsCall.call(
                                            id: getJsonField(
                                              FFAppState().UserData,
                                              r'''$.user.id''',
                                            ).toString(),
                                            period: 'day',
                                            token: currentAuthenticationToken,
                                          );

                                          shouldSetState = true;
                                          if ((_model.ignoredPopupsByDay
                                                  ?.succeeded ??
                                              true)) {
                                            _model.ignoredPopUps =
                                                IgnoredPopUpsCall.count(
                                                    _model.ignoredPopupsByDay);
                                            safeSetState(() {});
                                          }
                                        }),
                                      ]);
                                      if (shouldSetState) safeSetState(() {});
                                    },
                                    text: 'Dia',
                                    options: FFButtonOptions(
                                      width: 90.0,
                                      height: 25.0,
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          16.0, 0.0, 16.0, 0.0),
                                      iconPadding:
                                          EdgeInsetsDirectional.fromSTEB(
                                              0.0, 0.0, 0.0, 0.0),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      textStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .override(
                                            font: GoogleFonts.montserrat(
                                              fontWeight: FontWeight.normal,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleSmall
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            fontSize: 12.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.normal,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                      elevation: 0.0,
                                      borderSide: BorderSide(
                                        color: Color(0x3F4CAED1),
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                      hoverColor: Color(0x414CAED1),
                                      hoverTextColor: Color(0xFF4CAED1),
                                    ),
                                    showLoadingIndicator: false,
                                  ),
                                  FFButtonWidget(
                                    onPressed: () async {
                                      var shouldSetState = false;
                                      _model.endDate = null;
                                      _model.initDate = null;
                                      safeSetState(() {});
                                      _model.week = true;
                                      _model.day = false;
                                      _model.month = false;
                                      safeSetState(() {});
                                      await Future.wait([
                                        Future(() async {
                                          _model.getWeekWorkedHours =
                                              await GetWorkedHoursCall.call(
                                            token: currentAuthenticationToken,
                                            userId: UserDataStruct.maybeFromMap(
                                                    FFAppState().UserData)
                                                ?.user
                                                .id,
                                            period: 'week',
                                          );

                                          shouldSetState = true;
                                          if ((_model.getWeekWorkedHours
                                                  ?.succeeded ??
                                              true)) {
                                            _model.workedHours =
                                                castToType<double>(getJsonField(
                                              _model.getWeekWorkedHours
                                                  ?.jsonBody,
                                              r'''$''',
                                            ));
                                            safeSetState(() {});
                                          } else {
                                            if (shouldSetState) {
                                              safeSetState(() {});
                                            }
                                            return;
                                          }
                                        }),
                                        Future(() async {
                                          _model.getTaskDoneByWeekResp =
                                              await GetTaskDoneByUserCall.call(
                                            token: currentAuthenticationToken,
                                            userId: UserDataStruct.maybeFromMap(
                                                    FFAppState().UserData)
                                                ?.user
                                                .id,
                                            period: 'week',
                                          );

                                          shouldSetState = true;
                                          _model.tasksDone = (_model
                                                      .getTaskDoneByWeekResp
                                                      ?.jsonBody is List)
                                              ? _model.getTaskDoneByWeekResp!
                                                  .jsonBody
                                              : <dynamic>[];
                                          safeSetState(() {});
                                        }),
                                        Future(() async {
                                          _model.ignoredPopupsByWeek =
                                              await IgnoredPopUpsCall.call(
                                            id: getJsonField(
                                              FFAppState().UserData,
                                              r'''$.user.id''',
                                            ).toString(),
                                            period: 'week',
                                            token: currentAuthenticationToken,
                                          );

                                          shouldSetState = true;
                                          if ((_model.ignoredPopupsByWeek
                                                  ?.succeeded ??
                                              true)) {
                                            _model.ignoredPopUps =
                                                IgnoredPopUpsCall.count(
                                                    _model.ignoredPopupsByWeek);
                                            safeSetState(() {});
                                          }
                                        }),
                                      ]);
                                      if (shouldSetState) safeSetState(() {});
                                    },
                                    text: 'Semana',
                                    options: FFButtonOptions(
                                      width: 90.0,
                                      height: 25.0,
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          16.0, 0.0, 16.0, 0.0),
                                      iconPadding:
                                          EdgeInsetsDirectional.fromSTEB(
                                              0.0, 0.0, 0.0, 0.0),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      textStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .override(
                                            font: GoogleFonts.montserrat(
                                              fontWeight: FontWeight.normal,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleSmall
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            fontSize: 12.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.normal,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                      elevation: 0.0,
                                      borderSide: BorderSide(
                                        color: Color(0x3F4CAED1),
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                      hoverColor: Color(0x414CAED1),
                                      hoverTextColor: Color(0xFF4CAED1),
                                    ),
                                    showLoadingIndicator: false,
                                  ),
                                  FFButtonWidget(
                                    onPressed: () async {
                                      var shouldSetState = false;
                                      _model.endDate = null;
                                      _model.initDate = null;
                                      safeSetState(() {});
                                      _model.day = false;
                                      _model.week = false;
                                      _model.month = true;
                                      safeSetState(() {});
                                      await Future.wait([
                                        Future(() async {
                                          _model.getMonthWorkedHours =
                                              await GetWorkedHoursCall.call(
                                            token: currentAuthenticationToken,
                                            userId: UserDataStruct.maybeFromMap(
                                                    FFAppState().UserData)
                                                ?.user
                                                .id,
                                            period: 'month',
                                          );

                                          shouldSetState = true;
                                          if ((_model.getMonthWorkedHours
                                                  ?.succeeded ??
                                              true)) {
                                            _model.workedHours =
                                                castToType<double>(getJsonField(
                                              _model.getMonthWorkedHours
                                                  ?.jsonBody,
                                              r'''$''',
                                            ));
                                            safeSetState(() {});
                                          } else {
                                            if (shouldSetState) {
                                              safeSetState(() {});
                                            }
                                            return;
                                          }
                                        }),
                                        Future(() async {
                                          _model.getTaskDoneByMonthResp =
                                              await GetTaskDoneByUserCall.call(
                                            token: currentAuthenticationToken,
                                            userId: UserDataStruct.maybeFromMap(
                                                    FFAppState().UserData)
                                                ?.user
                                                .id,
                                            period: 'month',
                                          );

                                          shouldSetState = true;
                                          _model.tasksDone = (_model
                                                      .getTaskDoneByMonthResp
                                                      ?.jsonBody is List)
                                              ? _model.getTaskDoneByMonthResp!
                                                  .jsonBody
                                              : <dynamic>[];
                                          safeSetState(() {});
                                        }),
                                        Future(() async {
                                          _model.ignoredPopupsByMonth =
                                              await IgnoredPopUpsCall.call(
                                            id: getJsonField(
                                              FFAppState().UserData,
                                              r'''$.user.id''',
                                            ).toString(),
                                            period: 'month',
                                            token: currentAuthenticationToken,
                                          );

                                          shouldSetState = true;
                                          if ((_model.ignoredPopupsByMonth
                                                  ?.succeeded ??
                                              true)) {
                                            _model.ignoredPopUps =
                                                IgnoredPopUpsCall.count(
                                                    _model.ignoredPopupsByMonth);
                                            safeSetState(() {});
                                          }
                                        }),
                                      ]);
                                      if (shouldSetState) safeSetState(() {});
                                    },
                                    text: 'Mês ',
                                    options: FFButtonOptions(
                                      width: 90.0,
                                      height: 25.0,
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          16.0, 0.0, 16.0, 0.0),
                                      iconPadding:
                                          EdgeInsetsDirectional.fromSTEB(
                                              0.0, 0.0, 0.0, 0.0),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      textStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .override(
                                            font: GoogleFonts.montserrat(
                                              fontWeight: FontWeight.normal,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleSmall
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            fontSize: 12.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.normal,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                      elevation: 0.0,
                                      borderSide: BorderSide(
                                        color: Color(0x3F4CAED1),
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                      hoverColor: Color(0x404CAED1),
                                      hoverTextColor: Color(0xFF4CAED1),
                                    ),
                                    showLoadingIndicator: false,
                                  ),
                                ].divide(SizedBox(width: 10.0)),
                              ),
                            ].divide(SizedBox(width: 10.0)),
                          ),
                        ),
                        Align(
                          alignment: AlignmentDirectional(0.0, 0.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  FFButtonWidget(
                                    onPressed: () async {
                                      final datePicked1Date =
                                          await showDatePicker(
                                        context: context,
                                        initialDate: getCurrentTimestamp,
                                        firstDate: DateTime(1900),
                                        lastDate: DateTime(2050),
                                        builder: (context, child) {
                                          return wrapInMaterialDatePickerTheme(
                                            context,
                                            child!,
                                            headerBackgroundColor:
                                                Color(0xFF006994),
                                            headerForegroundColor:
                                                FlutterFlowTheme.of(context)
                                                    .info,
                                            headerTextStyle: FlutterFlowTheme
                                                    .of(context)
                                                .headlineLarge
                                                .override(
                                                  font: GoogleFonts.montserrat(
                                                    fontWeight: FontWeight.w600,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .headlineLarge
                                                            .fontStyle,
                                                  ),
                                                  fontSize: 32.0,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .headlineLarge
                                                          .fontStyle,
                                                ),
                                            pickerBackgroundColor:
                                                FlutterFlowTheme.of(context)
                                                    .secondaryBackground,
                                            pickerForegroundColor:
                                                FlutterFlowTheme.of(context)
                                                    .primaryText,
                                            selectedDateTimeBackgroundColor:
                                                Color(0xFF006994),
                                            selectedDateTimeForegroundColor:
                                                FlutterFlowTheme.of(context)
                                                    .info,
                                            actionButtonForegroundColor:
                                                FlutterFlowTheme.of(context)
                                                    .primaryText,
                                            iconSize: 24.0,
                                          );
                                        },
                                      );

                                      if (datePicked1Date != null) {
                                        safeSetState(() {
                                          _model.datePicked1 = DateTime(
                                            datePicked1Date.year,
                                            datePicked1Date.month,
                                            datePicked1Date.day,
                                          );
                                        });
                                      } else if (_model.datePicked1 != null) {
                                        safeSetState(() {
                                          _model.datePicked1 =
                                              getCurrentTimestamp;
                                        });
                                      }
                                      _model.initDate = _model.datePicked1;
                                      safeSetState(() {});
                                    },
                                    text: 'Inicio',
                                    options: FFButtonOptions(
                                      width: 50.0,
                                      height: 30.0,
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 0.0, 0.0, 0.0),
                                      iconPadding:
                                          EdgeInsetsDirectional.fromSTEB(
                                              0.0, 0.0, 0.0, 0.0),
                                      color: Color(0xFF006994),
                                      textStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .override(
                                            font: GoogleFonts.montserrat(
                                              fontWeight: FontWeight.w500,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleSmall
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryBackground,
                                            fontSize: 12.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w500,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                      elevation: 0.0,
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    showLoadingIndicator: false,
                                  ),
                                  if (_model.initDate != null)
                                    Text(
                                      dateTimeFormat(
                                        "d/M/y",
                                        _model.datePicked1,
                                        locale: FFLocalizations.of(context)
                                            .languageCode,
                                      ),
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.montserrat(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            color: Color(0xFF102A43),
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                  FFButtonWidget(
                                    onPressed: () async {
                                      var shouldSetState = false;
                                      final datePicked2Date =
                                          await showDatePicker(
                                        context: context,
                                        initialDate: getCurrentTimestamp,
                                        firstDate: DateTime(1900),
                                        lastDate: DateTime(2050),
                                        builder: (context, child) {
                                          return wrapInMaterialDatePickerTheme(
                                            context,
                                            child!,
                                            headerBackgroundColor:
                                                Color(0xFF006994),
                                            headerForegroundColor:
                                                FlutterFlowTheme.of(context)
                                                    .info,
                                            headerTextStyle: FlutterFlowTheme
                                                    .of(context)
                                                .headlineLarge
                                                .override(
                                                  font: GoogleFonts.montserrat(
                                                    fontWeight: FontWeight.w600,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .headlineLarge
                                                            .fontStyle,
                                                  ),
                                                  fontSize: 32.0,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .headlineLarge
                                                          .fontStyle,
                                                ),
                                            pickerBackgroundColor:
                                                FlutterFlowTheme.of(context)
                                                    .secondaryBackground,
                                            pickerForegroundColor:
                                                FlutterFlowTheme.of(context)
                                                    .primaryText,
                                            selectedDateTimeBackgroundColor:
                                                Color(0xFF006994),
                                            selectedDateTimeForegroundColor:
                                                FlutterFlowTheme.of(context)
                                                    .info,
                                            actionButtonForegroundColor:
                                                FlutterFlowTheme.of(context)
                                                    .primaryText,
                                            iconSize: 24.0,
                                          );
                                        },
                                      );

                                      if (datePicked2Date != null) {
                                        safeSetState(() {
                                          _model.datePicked2 = DateTime(
                                            datePicked2Date.year,
                                            datePicked2Date.month,
                                            datePicked2Date.day,
                                          );
                                        });
                                      } else if (_model.datePicked2 != null) {
                                        safeSetState(() {
                                          _model.datePicked2 =
                                              getCurrentTimestamp;
                                        });
                                      }
                                      _model.endDate = _model.datePicked2;
                                      safeSetState(() {});
                                      await Future.wait([
                                        Future(() async {
                                          _model.getInitAndEndWorkedHours =
                                              await GetWorkedHoursCall.call(
                                            token: currentAuthenticationToken,
                                            userId: UserDataStruct.maybeFromMap(
                                                    FFAppState().UserData)
                                                ?.user
                                                .id,
                                            period: 'range',
                                            startDate:
                                                _model.initDate?.toString(),
                                            endDate: _model.endDate?.toString(),
                                          );

                                          shouldSetState = true;
                                          if ((_model.getInitAndEndWorkedHours
                                                  ?.succeeded ??
                                              true)) {
                                            _model.workedHours =
                                                castToType<double>(getJsonField(
                                              _model.getInitAndEndWorkedHours
                                                  ?.jsonBody,
                                              r'''$''',
                                            ));
                                            safeSetState(() {});
                                          } else {
                                            if (shouldSetState) {
                                              safeSetState(() {});
                                            }
                                            return;
                                          }
                                        }),
                                        Future(() async {
                                          _model.getTaskDoneByInitAndEndDateResp =
                                              await GetTaskDoneByUserCall.call(
                                            token: currentAuthenticationToken,
                                            userId: UserDataStruct.maybeFromMap(
                                                    FFAppState().UserData)
                                                ?.user
                                                .id,
                                            period: 'range',
                                            startDate:
                                                _model.initDate?.toString(),
                                            endDate: _model.endDate?.toString(),
                                          );

                                          shouldSetState = true;
                                          final rangeTasks = getJsonField(
                                            _model
                                                .getTaskDoneByInitAndEndDateResp
                                                ?.jsonBody,
                                            r'''$''',
                                          );
                                          _model.tasksDone =
                                              rangeTasks is List
                                                  ? rangeTasks
                                                  : <dynamic>[];
                                          safeSetState(() {});
                                        }),
                                        Future(() async {
                                          _model.ignoredPopupsInit =
                                              await IgnoredPopUpsCall.call(
                                            id: getJsonField(
                                              FFAppState().UserData,
                                              r'''$.user.id''',
                                            ).toString(),
                                            period: 'range',
                                            token: currentAuthenticationToken,
                                            startDate:
                                                _model.initDate?.toString(),
                                            endDate: _model.endDate?.toString(),
                                          );

                                          shouldSetState = true;
                                          if ((_model.ignoredPopupsInit
                                                  ?.succeeded ??
                                              true)) {
                                            _model.ignoredPopUps =
                                                IgnoredPopUpsCall.count(
                                                    _model.ignoredPopupsInit);
                                            safeSetState(() {});
                                          }
                                        }),
                                      ]);
                                      if (shouldSetState) safeSetState(() {});
                                    },
                                    text: 'Fim',
                                    options: FFButtonOptions(
                                      width: 50.0,
                                      height: 30.0,
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 0.0, 0.0, 0.0),
                                      iconPadding:
                                          EdgeInsetsDirectional.fromSTEB(
                                              0.0, 0.0, 0.0, 0.0),
                                      color: Color(0xFF006994),
                                      textStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .override(
                                            font: GoogleFonts.montserrat(
                                              fontWeight: FontWeight.w500,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleSmall
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryBackground,
                                            fontSize: 12.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w500,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                      elevation: 0.0,
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    showLoadingIndicator: false,
                                  ),
                                  if (_model.endDate != null)
                                    Text(
                                      dateTimeFormat(
                                        "d/M/y",
                                        _model.datePicked2,
                                        locale: FFLocalizations.of(context)
                                            .languageCode,
                                      ),
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.montserrat(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            color: Color(0xFF102A43),
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                  if ((_model.initDate != null) ||
                                      (_model.endDate != null))
                                    Align(
                                      alignment: AlignmentDirectional(0.0, 0.0),
                                      child: InkWell(
                                        splashColor: Colors.transparent,
                                        focusColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        onTap: () async {
                                          var shouldSetState = false;
                                          _model.endDate = null;
                                          _model.initDate = null;
                                          safeSetState(() {});
                                          await Future.wait([
                                            Future(() async {
                                              _model.getDayInitWorkedHours =
                                                  await GetWorkedHoursCall.call(
                                                token:
                                                    currentAuthenticationToken,
                                                userId:
                                                    UserDataStruct.maybeFromMap(
                                                            FFAppState()
                                                                .UserData)
                                                        ?.user
                                                        .id,
                                                period: 'today',
                                              );

                                              shouldSetState = true;
                                              if ((_model.getDayInitWorkedHours
                                                      ?.succeeded ??
                                                  true)) {
                                                _model.workedHours =
                                                    castToType<double>(
                                                        getJsonField(
                                                  _model.getDayInitWorkedHours
                                                      ?.jsonBody,
                                                  r'''$''',
                                                ));
                                                safeSetState(() {});
                                              } else {
                                                if (shouldSetState) {
                                                  safeSetState(() {});
                                                }
                                                return;
                                              }
                                            }),
                                            Future(() async {
                                              _model.getTaskDoneByInitResp =
                                                  await GetTaskDoneByUserCall
                                                      .call(
                                                token:
                                                    currentAuthenticationToken,
                                                userId:
                                                    UserDataStruct.maybeFromMap(
                                                            FFAppState()
                                                                .UserData)
                                                        ?.user
                                                        .id,
                                                period: 'day',
                                              );

                                              shouldSetState = true;
                                              _model.tasksDone = (_model
                                                          .getTaskDoneByInitResp
                                                          ?.jsonBody is List)
                                                  ? _model
                                                      .getTaskDoneByInitResp!
                                                      .jsonBody
                                                  : <dynamic>[];
                                              safeSetState(() {});
                                            }),
                                            Future(() async {
                                              _model.ignoredPopupsByInit =
                                                  await IgnoredPopUpsCall.call(
                                                id: getJsonField(
                                                  FFAppState().UserData,
                                                  r'''$.user.id''',
                                                ).toString(),
                                                period: 'day',
                                                token:
                                                    currentAuthenticationToken,
                                              );

                                              shouldSetState = true;
                                              if ((_model.ignoredPopupsByInit
                                                      ?.succeeded ??
                                                  true)) {
                                                _model.ignoredPopUps =
                                                    IgnoredPopUpsCall.count(
                                                        _model
                                                            .ignoredPopupsByInit);
                                                safeSetState(() {});
                                              }
                                            }),
                                          ]);
                                          if (shouldSetState) {
                                            safeSetState(() {});
                                          }
                                        },
                                        child: Icon(
                                          Icons.close,
                                          color: Color(0xFF006994),
                                          size: 20.0,
                                        ),
                                      ),
                                    ),
                                ].divide(SizedBox(width: 4.0)),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Align(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: Container(
                                      width: 145.0,
                                      height: 75.0,
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryBackground,
                                        boxShadow: [
                                          BoxShadow(
                                            blurRadius: 4.0,
                                            color: Color(0x404CAED1),
                                            offset: Offset(
                                              4.0,
                                              4.0,
                                            ),
                                          )
                                        ],
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(10.0),
                                          bottomRight: Radius.circular(10.0),
                                          topLeft: Radius.circular(10.0),
                                          topRight: Radius.circular(10.0),
                                        ),
                                        border: Border.all(
                                          color: Color(0x3F4CAED1),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            4.0, 0.0, 4.0, 0.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      0.0, 10.0, 0.0, 0.0),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 0.0,
                                                                5.0, 0.0),
                                                    child: Text(
                                                      'Horas trabalhadas',
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodyMedium
                                                          .override(
                                                            font: GoogleFonts
                                                                .montserrat(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              fontStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                            ),
                                                            color: Color(
                                                                0xFF102A43),
                                                            fontSize: 14.0,
                                                            letterSpacing: 0.0,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Flexible(
                                              child: Align(
                                                alignment: AlignmentDirectional(
                                                    0.0, 0.0),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Align(
                                                      alignment:
                                                          AlignmentDirectional(
                                                              0.0, 0.0),
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    5.0,
                                                                    0.0,
                                                                    0.0,
                                                                    0.0),
                                                        child: Text(
                                                          valueOrDefault<
                                                              String>(
                                                            functions.formatHours(
                                                                _model
                                                                    .workedHours),
                                                            '0',
                                                          ),
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                                color: Color(
                                                                    0xFF102A43),
                                                                fontSize: 16.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: Container(
                                      width: 145.0,
                                      height: 75.0,
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryBackground,
                                        boxShadow: [
                                          BoxShadow(
                                            blurRadius: 4.0,
                                            color: Color(0x404CAED1),
                                            offset: Offset(
                                              4.0,
                                              4.0,
                                            ),
                                          )
                                        ],
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(10.0),
                                          bottomRight: Radius.circular(10.0),
                                          topLeft: Radius.circular(10.0),
                                          topRight: Radius.circular(10.0),
                                        ),
                                        border: Border.all(
                                          color: Color(0x3F4CAED1),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            4.0, 0.0, 4.0, 0.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      0.0, 10.0, 0.0, 0.0),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 0.0,
                                                                3.0, 0.0),
                                                    child: Text(
                                                      'PopUps ignorados',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodyMedium
                                                          .override(
                                                            font: GoogleFonts
                                                                .montserrat(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              fontStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                            ),
                                                            color: Color(
                                                                0xFF102A43),
                                                            fontSize: 14.0,
                                                            letterSpacing: 0.0,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Flexible(
                                              child: Align(
                                                alignment: AlignmentDirectional(
                                                    0.0, 0.0),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Align(
                                                      alignment:
                                                          AlignmentDirectional(
                                                              0.0, 0.0),
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    5.0,
                                                                    0.0,
                                                                    0.0,
                                                                    0.0),
                                                        child: Text(
                                                          valueOrDefault<
                                                              String>(
                                                            formatNumber(
                                                              _model
                                                                  .ignoredPopUps,
                                                              formatType:
                                                                  FormatType
                                                                      .decimal,
                                                              decimalType:
                                                                  DecimalType
                                                                      .automatic,
                                                            ),
                                                            '0',
                                                          ),
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                                color: Color(
                                                                    0xFF102A43),
                                                                fontSize: 16.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ].divide(SizedBox(width: 10.0)),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional(-1.0, 0.0),
                            child: Container(
                              width: double.infinity,
                              height: MediaQuery.sizeOf(context).height * 0.4,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 4.0,
                                    color: Color(0x404CAED1),
                                    offset: Offset(
                                      4.0,
                                      4.0,
                                    ),
                                  )
                                ],
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(10.0),
                                  bottomRight: Radius.circular(10.0),
                                  topLeft: Radius.circular(10.0),
                                  topRight: Radius.circular(10.0),
                                ),
                                border: Border.all(
                                  color: Color(0x3F4CAED1),
                                  width: 1.0,
                                ),
                              ),
                              alignment: AlignmentDirectional(0.0, 0.0),
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    10.0, 0.0, 10.0, 0.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Align(
                                      alignment: AlignmentDirectional(0.0, 0.0),
                                      child: Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0.0, 10.0, 0.0, 10.0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Align(
                                              alignment: AlignmentDirectional(
                                                  0.0, -1.0),
                                              child: Text(
                                                'Atividades feitas',
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          font: GoogleFonts
                                                              .montserrat(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          color:
                                                              Color(0xFF102A43),
                                                          fontSize: 14.0,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                              ),
                                            ),
                                            AlignedTooltip(
                                              content: Padding(
                                                padding: EdgeInsets.all(4.0),
                                                child: Text(
                                                  'Atividades realizadas no dia.',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyLarge
                                                      .override(
                                                        font: GoogleFonts
                                                            .montserrat(
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyLarge
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyLarge
                                                                  .fontStyle,
                                                        ),
                                                        color:
                                                            Color(0xFF102A43),
                                                        fontSize: 10.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyLarge
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyLarge
                                                                .fontStyle,
                                                      ),
                                                ),
                                              ),
                                              offset: 4.0,
                                              preferredDirection:
                                                  AxisDirection.up,
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              backgroundColor:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                              elevation: 4.0,
                                              tailBaseWidth: 19.0,
                                              tailLength: 9.0,
                                              waitDuration:
                                                  Duration(milliseconds: 100),
                                              showDuration:
                                                  Duration(milliseconds: 700),
                                              triggerMode:
                                                  TooltipTriggerMode.tap,
                                              child: Icon(
                                                Icons.help_sharp,
                                                color: Color(0xFF006994),
                                                size: 20.0,
                                              ),
                                            ),
                                          ].divide(SizedBox(width: 10.0)),
                                        ),
                                      ),
                                    ),
                                    Flexible(
                                      child: Align(
                                        alignment:
                                            AlignmentDirectional(0.0, -1.0),
                                        child: Container(
                                          width: double.infinity,
                                          height: double.infinity,
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryBackground,
                                          ),
                                          child: Builder(
                                            builder: (context) {
                                              final tasks = (((_model.tasksDone
                                                              is List
                                                          ? _model.tasksDone
                                                              as List
                                                          : const [])
                                                      .map<TaskDoneStruct?>(
                                                          TaskDoneStruct
                                                              .maybeFromMap)
                                                      .toList()) as Iterable<
                                                          TaskDoneStruct?>)
                                                  .withoutNulls
                                                  .toList();
                                              if (tasks.isEmpty) {
                                                return Center(
                                                  child: SizedBox(
                                                    width: 200.0,
                                                    height: 200.0,
                                                    child: NotAtivitiesWidget(),
                                                  ),
                                                );
                                              }

                                              return FlutterFlowDataTable<
                                                  TaskDoneStruct>(
                                                controller: _model
                                                    .paginatedDataTableController,
                                                data: tasks,
                                                numRows: tasks.length,
                                                columnsBuilder:
                                                    (onSortChanged) => [
                                                  DataColumn2(
                                                    label:
                                                        DefaultTextStyle.merge(
                                                      softWrap: true,
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    5.0,
                                                                    0.0,
                                                                    0.0,
                                                                    0.0),
                                                        child: Text(
                                                          'Atividade',
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .labelMedium
                                                              .override(
                                                                font: GoogleFonts
                                                                    .montserrat(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontStyle,
                                                                ),
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondaryBackground,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .fontStyle,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  DataColumn2(
                                                    label:
                                                        DefaultTextStyle.merge(
                                                      softWrap: true,
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    30.0,
                                                                    0.0,
                                                                    0.0,
                                                                    0.0),
                                                        child: Text(
                                                          'Projeto',
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .labelMedium
                                                              .override(
                                                                font: GoogleFonts
                                                                    .montserrat(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontStyle,
                                                                ),
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondaryBackground,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .fontStyle,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  DataColumn2(
                                                    label:
                                                        DefaultTextStyle.merge(
                                                      softWrap: true,
                                                      child: Align(
                                                        alignment:
                                                            AlignmentDirectional(
                                                                1.0, -1.0),
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      0.0,
                                                                      0.0,
                                                                      10.0,
                                                                      0.0),
                                                          child: Text(
                                                            'Tempo',
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .labelMedium
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .montserrat(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelMedium
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryBackground,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontStyle,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                                dataRowBuilder: (tasksItem,
                                                        tasksIndex,
                                                        selected,
                                                        onSelectChanged) =>
                                                    DataRow(
                                                  color:
                                                      WidgetStateProperty.all(
                                                    tasksIndex % 2 == 0
                                                        ? FlutterFlowTheme.of(
                                                                context)
                                                            .secondaryBackground
                                                        : FlutterFlowTheme.of(
                                                                context)
                                                            .primaryBackground,
                                                  ),
                                                  cells: [
                                                    Align(
                                                      alignment:
                                                          AlignmentDirectional(
                                                              -1.0, 0.0),
                                                      child: Text(
                                                        tasksItem.taskName,
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodySmall
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .montserrat(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodySmall
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodySmall
                                                                        .fontStyle,
                                                                  ),
                                                                  color: Color(
                                                                      0xFF102A43),
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodySmall
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodySmall
                                                                      .fontStyle,
                                                                ),
                                                      ),
                                                    ),
                                                    Align(
                                                      alignment:
                                                          AlignmentDirectional(
                                                              -1.0, 0.0),
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    35.0,
                                                                    0.0,
                                                                    5.0,
                                                                    0.0),
                                                        child: Text(
                                                          tasksItem.projectName,
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodySmall
                                                              .override(
                                                                font: GoogleFonts
                                                                    .montserrat(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodySmall
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodySmall
                                                                      .fontStyle,
                                                                ),
                                                                color: Color(
                                                                    0xFF102A43),
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodySmall
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodySmall
                                                                    .fontStyle,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                    Align(
                                                      alignment:
                                                          AlignmentDirectional(
                                                              -1.0, 0.0),
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    70.0,
                                                                    0.0,
                                                                    0.0,
                                                                    0.0),
                                                        child: Text(
                                                          valueOrDefault<
                                                              String>(
                                                            functions
                                                                .formatHours(
                                                                    getJsonField(
                                                              tasksItem.toMap(),
                                                              r'''$.hours''',
                                                            )),
                                                            '0',
                                                          ),
                                                          textAlign:
                                                              TextAlign.end,
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                font: GoogleFonts
                                                                    .montserrat(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                                color: Color(
                                                                    0xFF102A43),
                                                                fontSize: 12.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ]
                                                      .map((c) => DataCell(c))
                                                      .toList(),
                                                ),
                                                emptyBuilder: () => Center(
                                                  child: SizedBox(
                                                    width: 200.0,
                                                    height: 200.0,
                                                    child: NotAtivitiesWidget(),
                                                  ),
                                                ),
                                                paginated: true,
                                                selectable: false,
                                                hidePaginator: true,
                                                showFirstLastButtons: false,
                                                height: double.infinity,
                                                headingRowHeight: 20.0,
                                                dataRowHeight: 35.0,
                                                columnSpacing: 34.0,
                                                headingRowColor:
                                                    Color(0xFF006994),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                                addHorizontalDivider: true,
                                                addTopAndBottomDivider: false,
                                                hideDefaultHorizontalDivider:
                                                    true,
                                                horizontalDividerColor:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryBackground,
                                                horizontalDividerThickness: 1.0,
                                                addVerticalDivider: false,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ]
                          .divide(SizedBox(height: 10.0))
                          .addToStart(SizedBox(height: 10.0))
                          .addToEnd(SizedBox(height: 10.0)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
