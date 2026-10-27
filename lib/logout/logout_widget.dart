import 'dart:async';

import '/auth/custom_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
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
import '/utils/time_tracking.dart';
import '/utils/zoc_logo.dart';

class LogoutWidget extends StatefulWidget {
  const LogoutWidget({super.key});

  static String routeName = 'Logout';
  static String routePath = '/logout';

  @override
  State<LogoutWidget> createState() => _LogoutWidgetState();
}

class _LogoutWidgetState extends State<LogoutWidget>
    with WidgetsBindingObserver {
  late LogoutModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  int _periodMinutes = 15;
  DateTime? _lastPopupAt;
  DateTime? _timerStartedAt;
  bool _pendingReschedule = false;
  bool _refreshInFlight = false;
  Timer? _rescheduleDelayTimer;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LogoutModel());
    WidgetsBinding.instance.addObserver(this);

    _periodMinutes = _readMonitoringPeriod();
    _timerStartedAt = DateTime.now();

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      FFAppState().contador = 0;
      _startPopupTimer(fireImmediately: true);
      _startUserPolling();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshUserSettings());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rescheduleDelayTimer?.cancel();
    _model.dispose();

    super.dispose();
  }

  Map<String, dynamic>? _parseUserDataMap() {
    final raw = FFAppState().UserData;
    if (raw == null) return null;
    if (raw is String) {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    }
    if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  int _parsePeriod(dynamic value) {
    int? minutes;
    if (value is int) {
      minutes = value;
    } else if (value is num) {
      minutes = value.toInt();
    } else if (value is String) {
      minutes = int.tryParse(value);
    }
    if (minutes != null && minutes > 0) return minutes;
    return 15;
  }

  int _readMonitoringPeriod() {
    final userData = _parseUserDataMap();
    if (userData == null) return 15;
    final user = userData['user'];
    if (user is! Map) return 15;
    return _parsePeriod(user['monitoring_period']);
  }

  void _startUserPolling() {
    _model.pollTimer?.cancel();
    _model.pollTimer = InstantTimer.periodic(
      duration: const Duration(seconds: 30),
      callback: (_) {
        unawaited(_refreshUserSettings());
      },
      startImmediately: false,
    );
  }

  Future<void> _refreshUserSettings() async {
    if (!mounted || _refreshInFlight) return;
    _refreshInFlight = true;
    try {
      final token = currentAuthenticationToken;
      if (token == null || token.isEmpty) return;

      final userData = _parseUserDataMap() ?? <String, dynamic>{};
      final existingUser = userData['user'];
      String? authId;
      if (existingUser is Map) {
        authId = existingUser['auth_id']?.toString();
      }
      if (authId == null || authId.isEmpty || authId == 'null') {
        final meResult = await GetMeCall.call(token: token);
        if (!meResult.succeeded) return;
        authId = getJsonField(meResult.jsonBody, r'''$.auth_id''')?.toString();
        if (authId == null || authId.isEmpty || authId == 'null') return;
      }

      final result = await GetOrgUserByAuthCall.call(
        token: token,
        authId: authId,
      );
      if (!result.succeeded || result.jsonBody == null) return;

      final freshUserRaw = result.jsonBody;
      if (freshUserRaw is! Map) return;
      final freshUser = Map<String, dynamic>.from(freshUserRaw);

      userData['user'] = {
        if (existingUser is Map) ...Map<String, dynamic>.from(existingUser),
        ...freshUser,
      };
      FFAppState().UserData = userData;
      safeSetState(() {});

      final newPeriod = _parsePeriod(freshUser['monitoring_period']);
      if (newPeriod == _periodMinutes) return;

      _periodMinutes = newPeriod;
      if (FFAppState().isPopupVisible) {
        _pendingReschedule = true;
        return;
      }
      _reschedulePopupTimer();
    } catch (_) {
      // Keep previous monitoring_period on network/parse errors.
    } finally {
      _refreshInFlight = false;
    }
  }

  void _startPopupTimer({required bool fireImmediately}) {
    _model.FirstTimer?.cancel();
    _rescheduleDelayTimer?.cancel();
    if (fireImmediately) {
      _model.FirstTimer = InstantTimer.periodic(
        duration: Duration(minutes: _periodMinutes),
        callback: (_) {
          unawaited(_runPopupCycle());
        },
        startImmediately: true,
      );
      return;
    }
    _reschedulePopupTimer();
  }

  void _reschedulePopupTimer() {
    _model.FirstTimer?.cancel();
    _rescheduleDelayTimer?.cancel();

    final anchor = _lastPopupAt ?? _timerStartedAt ?? DateTime.now();
    final nextDue = anchor.add(Duration(minutes: _periodMinutes));
    final now = DateTime.now();
    final delay = nextDue.isAfter(now)
        ? nextDue.difference(now)
        : const Duration(seconds: 1);

    _rescheduleDelayTimer = Timer(delay, () {
      if (!mounted) return;
      unawaited(_runPopupCycle());
      _model.FirstTimer = InstantTimer.periodic(
        duration: Duration(minutes: _periodMinutes),
        callback: (_) {
          unawaited(_runPopupCycle());
        },
        startImmediately: false,
      );
    });
  }

  Future<void> _runPopupCycle() async {
    if (!mounted) return;
    if (FFAppState().isPopupVisible) return;
    if (!isTimeTrackingEnabled()) return;

    final periodForPopup = _periodMinutes;
    print('Timer disparado com intervalo de $periodForPopup minutos!');

    _lastPopupAt = DateTime.now();
    FFAppState().isPopupVisible = true;
    FFAppState().contador = FFAppState().contador + 1;
    safeSetState(() {});

    try {
      String? screenshotBase64;
      if (areScreenshotsEnabled()) {
        final rawScreenshot = await captureScreenshotBase64();
        screenshotBase64 = rawScreenshot != null
            ? 'data:image/jpeg;base64,$rawScreenshot'
            : null;
      }
      if (!isWeb) {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        await prepareDesktopWindowForPopup();
      }
      if (!mounted) return;
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
                  minutes: periodForPopup > 1 ? periodForPopup - 1 : 1,
                ),
              ),
            ),
          );
        },
      ).then((value) => safeSetState(() {}));

      await restoreDesktopWindowAfterPopup();
    } finally {
      FFAppState().isPopupVisible = false;
      if (mounted) {
        FFAppState().contador = 0;
        safeSetState(() {});
        if (_pendingReschedule) {
          _pendingReschedule = false;
          _reschedulePopupTimer();
        }
      }
    }
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
                        if (!isTimeTrackingEnabled()) ...[
                          const SizedBox(height: 10.0),
                          Text(
                            'Controle de tempo desativado pelo administrador',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                        ],
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
