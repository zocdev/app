import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/instant_timer.dart';
import '/pages/popup_dialog/popup_dialog_widget.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'logout_model.dart';
export 'logout_model.dart';
import '/desktop/popup_window.dart';
import '/utils/capture_screenshot.dart';
import '/utils/zoc_logo.dart';

class LogoutWidget extends StatefulWidget {
  const LogoutWidget({super.key});

  static String routeName = 'Logout';
  static String routePath = '/logout';

  @override
  State<LogoutWidget> createState() => _LogoutWidgetState();
}

class _LogoutWidgetState extends State<LogoutWidget> {
  late LogoutModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LogoutModel());

    // Definimos la variable minutos
    int minutos = 15; // Valor por defecto en caso de que algo falle

    // Parseamos FFAppState().UserData para extraer monitoring_period
    if (FFAppState().UserData != null) {
      Map<String, dynamic> userData = {};
      if (FFAppState().UserData is String) {
        userData = jsonDecode(FFAppState().UserData.toString());
      } else if (FFAppState().UserData is Map<String, dynamic>) {
        userData = FFAppState().UserData;
      }

      // Extraemos el objeto user
      Map<String, dynamic> user = userData['user'] ?? {};

      // Extraemos monitoring_period y validamos que sea un entero mayor que 0
      var monitoringPeriod = user['monitoring_period'];
      if (monitoringPeriod is int && monitoringPeriod > 0) {
        minutos = monitoringPeriod;
      } else {
        // Si monitoring_period es 0, negativo o no es un entero válido, usamos 1 como valor mínimo
        minutos = 15; // Valor mínimo para evitar disparos instantáneos
      }
    }

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      FFAppState().contador = 0;
      _model.FirstTimer = InstantTimer.periodic(
        duration: Duration(minutes: minutos), // MINUTOs
        callback: (timer) async {
          if (!mounted) return;
          print("Timer disparado con intervalo de $minutos minutos!");
          if (FFAppState().isPopupVisible) return;
          FFAppState().isPopupVisible = true;

          FFAppState().contador = FFAppState().contador + 1;
          safeSetState(() {});

          String? screenshotBase64;
          final rawScreenshot = await captureScreenshotBase64();
          screenshotBase64 = rawScreenshot != null
              ? 'data:image/jpeg;base64,$rawScreenshot'
              : null;
          if (!isWeb) {
            await Future.delayed(const Duration(seconds: 1));
            if (!mounted) {
              FFAppState().isPopupVisible = false;
              return;
            }
            await prepareDesktopWindowForPopup();
          }
          if (!mounted) {
            FFAppState().isPopupVisible = false;
            return;
          }
          await showModalBottomSheet(
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            enableDrag: false,
            context: context,
            builder: (context) {
              return GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                child: Padding(
                  padding: MediaQuery.viewInsetsOf(context),
                  child: PopupDialogWidget(
                    screenshotBase64: screenshotBase64,
                    ignoreAfter: Duration(
                      minutes: minutos > 1 ? minutos - 1 : 1,
                    ),
                  ),
                ),
              );
            },
          ).then((value) => safeSetState(() {}));

          await restoreDesktopWindowAfterPopup();
          if (!mounted) return;
          FFAppState().contador = 0;
          FFAppState().isPopupVisible = false;
          safeSetState(() {});
        },
        startImmediately: true,
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    final rawFirstName = getJsonField(
      FFAppState().UserData,
      r'''$.user.first_name''',
    )?.toString();
    final rawLastName = getJsonField(
      FFAppState().UserData,
      r'''$.user.last_name''',
    )?.toString();

    String displayName = '';
    if (rawFirstName != null && rawFirstName.isNotEmpty && rawFirstName != 'null') {
      displayName = rawFirstName[0].toUpperCase() + rawFirstName.substring(1);
      if (rawLastName != null && rawLastName.isNotEmpty && rawLastName != 'null') {
        displayName += ' ${rawLastName[0].toUpperCase()}${rawLastName.substring(1)}';
      }
    } else {
      displayName = 'Usuário';
    }

    final initial = displayName.trim().isNotEmpty
        ? displayName.trim()[0].toUpperCase()
        : 'U';

    final email = FFAppState().email;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Align(
            alignment: Alignment.center,
            child: Container(
              width: 500.0,
              height: 400.0,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).secondaryBackground,
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 4.0,
                    color: Color(0x33000000),
                    offset: Offset(0.0, 2.0),
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 20.0, 20.0, 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const ZocLogo(
                          width: 100.0,
                          showTagline: false,
                        ),
                        Tooltip(
                          message: 'Ver Registro',
                          child: FlutterFlowIconButton(
                            borderRadius: 8.0,
                            buttonSize: 40.0,
                            fillColor: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            icon: const Icon(
                              Icons.assignment_turned_in_outlined,
                              color: Color(0xFF0F8F8A),
                              size: 24.0,
                            ),
                            onPressed: () async {
                              context.pushNamed(ExpedienteWidget.routeName);
                            },
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72.0,
                          height: 72.0,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F6F5),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF0F8F8A).withOpacity(0.35),
                              width: 2.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initial,
                            style: GoogleFonts.inter(
                              fontSize: 28.0,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F8F8A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14.0),
                        Text(
                          displayName,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 22.0,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF101827),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 6.0,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(20.0),
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.mail_outline_rounded,
                                size: 14.0,
                                color: Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 6.0),
                              Text(
                                email.isNotEmpty ? email : '---',
                                style: GoogleFonts.inter(
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF4B5563),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Tooltip(
                          message: 'Sair da conta',
                          child: FlutterFlowIconButton(
                            borderRadius: 8.0,
                            buttonSize: 40.0,
                            fillColor: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            icon: const Icon(
                              Icons.login,
                              color: Color(0xFF0F8F8A),
                              size: 24.0,
                            ),
                            onPressed: () async {
                              context.pushNamed(ConfirmaLogoutWidget.routeName);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
