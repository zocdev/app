import 'dart:async';

import '/auth/custom_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/instant_timer.dart';
import '/pages/popup_dialog/popup_dialog_widget.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'logout_model.dart';
export 'logout_model.dart';
import '/desktop/pause_controller.dart';
import '/desktop/pause_return_dialog.dart';
import '/desktop/pause_sheet.dart';
import '/desktop/popup_window.dart';
import '/utils/capture_screenshot.dart';
import '/utils/time_tracking.dart';
import '/expediente/expediente_widget.dart'
    show expedienteGoalLabel, expedienteHoursLabel;
import '/ui/zoc_ui.dart';
import 'popup_countdown.dart';

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
  Timer? _countdownTimer;
  DateTime? _nextPopupAt;
  double? _workedHours;
  double _dailyGoalHours = GetWorkGoalCall.fallbackHours('today');
  bool _hoursLoading = false;

  final PauseController _pauses = PauseController.instance;
  late bool _wasPaused;
  bool _returnDialogOpen = false;
  bool _sheetOpen = false;
  int _pollTicks = 0;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LogoutModel());
    WidgetsBinding.instance.addObserver(this);
    _wasPaused = _pauses.isPaused;
    _pauses.addListener(_onPauseChanged);
    _pauses.onOpenSheetRequested = _openPauseSheet;

    _periodMinutes = _readMonitoringPeriod();
    _timerStartedAt = DateTime.now();

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      FFAppState().contador = 0;
      _startPopupTimer(fireImmediately: true);
      _startUserPolling();
      unawaited(_loadWorkedHours());
      unawaited(_startPresence());
    });

    var ticks = 0;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      ticks++;
      // Dart timers drift after the PC sleeps: compare the wall clock here.
      _checkPauseExpiry();
      // Refresh every 30 seconds, then show every second of the last minute.
      // A pause counts down every second.
      if (_pauses.isPaused || _remaining.inSeconds < 60 || ticks % 30 == 0) {
        safeSetState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshUserSettings());
      unawaited(_loadWorkedHours());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pauses.removeListener(_onPauseChanged);
    if (_pauses.onOpenSheetRequested == _openPauseSheet) {
      _pauses.onOpenSheetRequested = null;
    }
    _rescheduleDelayTimer?.cancel();
    _countdownTimer?.cancel();
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
        unawaited(_loadWorkedHours());
        // Presence heartbeat every 60 s (every other 30 s poll).
        if (++_pollTicks % 2 == 0) unawaited(_pauses.heartbeat());
      },
      startImmediately: false,
    );
  }

  /// Restores the pause from the server, then marks the user as seen.
  Future<void> _startPresence() async {
    await _pauses.refresh();
    await _pauses.heartbeat();
  }

  void _onPauseChanged() {
    final paused = _pauses.isPaused;
    final resumed = _wasPaused && !paused;
    _wasPaused = paused;
    safeSetState(() {});
    // The return dialog restarts the cycle itself once it has closed.
    if (!resumed || _returnDialogOpen) return;
    SchedulerBinding.instance.addPostFrameCallback((_) => _recordAfterPause());
  }

  /// Charges run forward from each record: after a pause, record right away
  /// (same path as login) instead of waiting a full period.
  void _recordAfterPause() {
    // A logout also drops the pause: no record then.
    if (!mounted || _pauses.signedOut) return;
    _startPopupTimer(fireImmediately: true);
  }

  void _checkPauseExpiry() {
    if (!mounted || _returnDialogOpen || !_pauses.isExpired) return;
    if (FFAppState().isPopupVisible) return;
    // Only over the home screen (not over the logout confirmation, etc.).
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    unawaited(_showReturnDialog());
  }

  Future<void> _showReturnDialog() async {
    _returnDialogOpen = true;
    PauseReturnChoice? choice;
    try {
      if (!isWeb) await prepareDesktopWindowForPopup();
      if (!mounted) return;
      choice = await showPauseReturnDialog(context, controller: _pauses);
    } finally {
      _returnDialogOpen = false;
    }
    if (!mounted) return;
    switch (choice) {
      case PauseReturnChoice.resumed:
        _recordAfterPause();
      case PauseReturnChoice.extended:
        await restoreDesktopWindowAfterPopup();
      case PauseReturnChoice.endDay:
        await resetDesktopWindowSize();
        if (mounted) {
          await context.pushNamed(ConfirmaLogoutWidget.routeName);
        }
      case null:
        break;
    }
  }

  Future<void> _openPauseSheet() async {
    if (!mounted || _sheetOpen || _pauses.isPaused) return;
    if (FFAppState().isPopupVisible) return;
    _sheetOpen = true;
    try {
      await showPauseSheet(context, controller: _pauses);
    } finally {
      _sheetOpen = false;
    }
  }

  Future<void> _resumeNow() async {
    final result = await _pauses.resume();
    if (mounted && result == PauseActionResult.network) {
      _showSnack('Sem conexão, tente de novo.');
    } else if (mounted && result == PauseActionResult.failed) {
      _showSnack('Não foi possível retomar. Tente de novo.');
    }
  }

  Future<void> _extendPause() async {
    final result = await _pauses.extend(15);
    if (mounted && result == PauseActionResult.network) {
      _showSnack('Sem conexão, tente de novo.');
    }
  }

  void _showSnack(String message) => ScaffoldMessenger.maybeOf(context)
      ?.showSnackBar(SnackBar(content: Text(message)));

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
      _nextPopupAt = DateTime.now().add(Duration(minutes: _periodMinutes));
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

    _nextPopupAt = now.add(delay);
    safeSetState(() {});
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
    // Paused: no popup, so no "ignored popup" entry either.
    if (_pauses.isPaused) return;
    _nextPopupAt = DateTime.now().add(Duration(minutes: _periodMinutes));
    safeSetState(() {});
    if (FFAppState().isPopupVisible) return;
    if (!isTimeTrackingEnabled()) return;

    final periodForPopup = _periodMinutes;
    debugPrint('Timer disparado com intervalo de $periodForPopup minutos!');

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
        unawaited(_loadWorkedHours());
        safeSetState(() {});
        if (_pendingReschedule) {
          _pendingReschedule = false;
          _reschedulePopupTimer();
        }
      }
    }
  }

  Duration get _remaining =>
      (_nextPopupAt ?? DateTime.now().add(Duration(minutes: _periodMinutes)))
          .difference(DateTime.now());

  Future<void> _loadWorkedHours() async {
    if (_hoursLoading) return;
    final user = _parseUserDataMap()?['user'];
    final userId = user is Map ? user['id']?.toString() : null;
    if (userId == null || userId.isEmpty) return;
    _hoursLoading = true;
    try {
      final result = await GetWorkedHoursCall.call(
        token: currentAuthenticationToken,
        userId: userId,
        period: 'today',
      );
      unawaited(_loadDailyGoal(userId));
      final hours = num.tryParse(result.jsonBody.toString());
      if (mounted && result.succeeded && hours != null && hours.isFinite) {
        setState(
            () => _workedHours = hours.toDouble().clamp(0, double.infinity));
      }
    } catch (_) {
      // Keep the last known value while offline.
    } finally {
      _hoursLoading = false;
    }
  }

  Future<void> _loadDailyGoal(String userId) async {
    try {
      final result = await GetWorkGoalCall.call(
        token: currentAuthenticationToken,
        userId: userId,
        period: 'today',
      );
      final goal = GetWorkGoalCall.goalHours(result, 'today');
      if (mounted && goal != _dailyGoalHours) {
        setState(() => _dailyGoalHours = goal);
      }
    } catch (_) {
      // Keep the fallback goal while offline.
    }
  }

  void _registerNow() {
    if (FFAppState().isPopupVisible || !isTimeTrackingEnabled()) return;
    if (_pauses.isPaused) return;
    // The same capture, popup and desktop-window path as a scheduled record.
    // The API cuts the previous charge back to this record, so an early
    // project switch never charges the same minutes twice.
    unawaited(_runPopupCycle());
    _startPopupTimer(fireImmediately: false);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final user = _parseUserDataMap()?['user'];
    final nameParts = [
      if (user is Map) user['first_name']?.toString(),
      if (user is Map) user['last_name']?.toString(),
    ].whereType<String>().where((part) => part.isNotEmpty && part != 'null');
    final displayName = nameParts.isEmpty
        ? 'Usuário'
        : nameParts
            .map((part) => part[0].toUpperCase() + part.substring(1))
            .join(' ');
    final enabled = isTimeTrackingEnabled();
    final goalProgress = ZocGoalProgress(_workedHours ?? 0, _dailyGoalHours);
    final progress = goalProgress.ratio;
    final extraLap = (progress - 1).clamp(0.0, 1.0);
    final totalMinutes = ((_workedHours ?? 0) * 60).round();
    final workedLabel = _workedHours == null
        ? '—'
        : '${totalMinutes ~/ 60}h ${(totalMinutes % 60).toString().padLeft(2, '0')}min';
    final pause = _pauses.pause;
    final canPause = enabled && _pauses.available && pause == null;
    final mode = FFAppState().isRemote ? 'Trabalho remoto' : 'Presencial';

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: ZocAuthScaffold(
        scaffoldKey: scaffoldKey,
        panelPadding: const EdgeInsets.all(20),
        topAction: IconButton(
          tooltip: 'Sair da conta',
          onPressed: () => context.pushNamed(ConfirmaLogoutWidget.routeName),
          icon: const Icon(Icons.logout_rounded,
              color: ZocColors.muted, size: 19),
        ),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: ZocColors.brandSoft,
                  child: Text(displayName[0].toUpperCase(),
                      style: ZocText.h3(color: ZocColors.brand)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName, style: ZocText.h3()),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: pause != null
                                    ? PauseColors.amber
                                    : enabled
                                        ? ZocColors.ok
                                        : ZocColors.warn,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: pause != null
                                        ? PauseColors.amber
                                            .withValues(alpha: .22)
                                        : enabled
                                            ? ZocColors.okSoft
                                            : ZocColors.warnSoft,
                                    spreadRadius: 3,
                                  )
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              pause != null
                                  ? 'Em pausa · $mode'
                                  : enabled
                                      ? 'Em expediente · $mode'
                                      : 'Controle de tempo desativado pelo administrador',
                              style: ZocText.sub().copyWith(fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (pause != null) ...[
              _PausedCard(pause: pause, controller: _pauses),
              const SizedBox(height: 16),
              _PausedDayRow(
                workedLabel: workedLabel,
                progress: progress,
                goalLabel: expedienteGoalLabel(_dailyGoalHours),
                onOpen: () => context.pushNamed(ExpedienteWidget.routeName),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (pause.timed) ...[
                    Expanded(
                      child: ZocButton(
                        '+15 min',
                        expanded: true,
                        variant: ZocButtonVariant.secondary,
                        onPressed: _pauses.busy ? null : _extendPause,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: ZocButton(
                      'Retomar agora',
                      expanded: true,
                      icon: Icons.play_arrow_rounded,
                      loading: _pauses.busy,
                      onPressed: _resumeNow,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(ZocRadii.heroInner),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [ZocColors.brand, ZocColors.brandInk],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hoje',
                              style: ZocText.caption(
                                  color:
                                      ZocColors.surface.withValues(alpha: .8))),
                          const SizedBox(height: 2),
                          Text(workedLabel,
                              style: ZocText.big(color: ZocColors.surface)),
                          if (goalProgress.hasOvertime) ...[
                            const SizedBox(height: 4),
                            ZocOvertimePill(
                                '+${expedienteHoursLabel(goalProgress.overtimeHours)} além da meta'),
                          ],
                        ],
                      ),
                    ),
                    Semantics(
                      label:
                          '${(progress * 100).round()}% da meta de ${expedienteGoalLabel(_dailyGoalHours)}',
                      child: SizedBox.square(
                        dimension: 64,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned.fill(
                              child: CircularProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                strokeWidth: 6,
                                strokeCap: StrokeCap.round,
                                backgroundColor:
                                    ZocColors.surface.withValues(alpha: .2),
                                color: ZocColors.surface,
                              ),
                            ),
                            if (extraLap > 0)
                              Positioned.fill(
                                child: CircularProgressIndicator(
                                  value: extraLap,
                                  strokeWidth: 6,
                                  strokeCap: StrokeCap.round,
                                  backgroundColor: Colors.transparent,
                                  color: ZocColors.overtime,
                                ),
                              ),
                            Text('${(progress * 100).round()}%',
                                style: ZocText.label(color: ZocColors.surface)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: ZocColors.surface2,
                  borderRadius: BorderRadius.circular(ZocRadii.input),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 15, color: ZocColors.muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(TextSpan(
                        style: ZocText.sub().copyWith(fontSize: 13),
                        children: enabled
                            ? [
                                const TextSpan(text: 'Próximo registro em  '),
                                TextSpan(
                                    text: formatPopupCountdown(_remaining),
                                    style: ZocText.strong()),
                              ]
                            : [
                                const TextSpan(
                                    text: 'Controle de tempo desativado')
                              ],
                      )),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ZocButton(
                      'Ver registros',
                      expanded: true,
                      variant: ZocButtonVariant.secondary,
                      horizontalPadding: canPause ? 14 : null,
                      icon: Icons.bar_chart_rounded,
                      onPressed: () =>
                          context.pushNamed(ExpedienteWidget.routeName),
                    ),
                  ),
                  if (canPause) ...[
                    const SizedBox(width: 10),
                    ZocButton(
                      'Pausar',
                      variant: ZocButtonVariant.secondary,
                      horizontalPadding: 14,
                      icon: Icons.pause_rounded,
                      onPressed:
                          FFAppState().isPopupVisible ? null : _openPauseSheet,
                    ),
                  ],
                  const SizedBox(width: 10),
                  Expanded(
                    child: ZocButton(
                      'Registrar agora',
                      expanded: true,
                      icon: Icons.add_rounded,
                      horizontalPadding: canPause ? 14 : null,
                      onPressed: enabled && !FFAppState().isPopupVisible
                          ? _registerNow
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Amber card that replaces the "Hoje" hero while paused (mockups 04/05).
class _PausedCard extends StatelessWidget {
  const _PausedCard({required this.pause, required this.controller});

  final PresencePause pause;
  final PauseController controller;

  @override
  Widget build(BuildContext context) {
    final reason = pause.reasonLabel;
    final String top;
    final String big;
    if (pause.timed) {
      top = reason == null ? 'Em pausa' : 'Em pausa · $reason';
      final remaining = controller.remaining!;
      final over = -remaining.inMinutes;
      big = !remaining.isNegative
          ? pauseRemainingLabel(remaining)
          : over < 1
              ? 'pausa terminou'
              : 'excedida há ${pauseDurationLabel(Duration(minutes: over))}';
    } else {
      top = 'Em pausa desde ${pauseClock(pause.startedAt)}'
          '${reason == null ? '' : ' · $reason'}';
      final elapsed = controller.elapsed;
      big = elapsed.inMinutes < 1
          ? 'há menos de 1 min'
          : 'há ${pauseDurationLabel(elapsed)}';
    }
    final planned = pause.planned?.inSeconds ?? 0;
    final progress =
        planned <= 0 ? 0.0 : controller.elapsed.inSeconds / planned;
    final subStyle =
        ZocText.caption(color: PauseColors.ink, weight: FontWeight.w500)
            .copyWith(fontSize: 12.5);

    return ClipRRect(
      borderRadius: BorderRadius.circular(ZocRadii.heroInner),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ZocRadii.heroInner),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [PauseColors.surface, PauseColors.soft],
          ),
          border: Border.all(color: PauseColors.amber.withValues(alpha: .25)),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -36,
              top: -46,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: PauseColors.amber.withValues(alpha: .10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const PauseIconBadge(size: 26, solid: true),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(top,
                            style:
                                subStyle.copyWith(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(big, style: ZocText.big(color: PauseColors.ink2)),
                  if (pause.timed) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(ZocRadii.pill),
                      child: Container(
                        height: 6,
                        color: PauseColors.amber.withValues(alpha: .18),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0),
                          heightFactor: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: PauseColors.amber,
                              borderRadius:
                                  BorderRadius.circular(ZocRadii.pill),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                          pause.timed
                              ? Icons.schedule_rounded
                              : Icons.all_inclusive_rounded,
                          size: 14,
                          color: PauseColors.ink),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                            pause.timed
                                ? 'Volta prevista às ${pauseClock(pause.plannedEndAt!)}'
                                : 'Sem horário de volta',
                            style: subStyle),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Muted "Hoje" row shown while paused: the day does not grow.
class _PausedDayRow extends StatelessWidget {
  const _PausedDayRow({
    required this.workedLabel,
    required this.progress,
    required this.goalLabel,
    required this.onOpen,
  });

  final String workedLabel;
  final double progress;
  final String goalLabel;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final small =
        ZocText.caption(color: ZocColors.faint, weight: FontWeight.w500)
            .copyWith(fontSize: 11);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ZocColors.surface2,
        borderRadius: BorderRadius.circular(ZocRadii.input),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hoje', style: small),
              const SizedBox(height: 1),
              Text(workedLabel,
                  style: ZocText.h3(color: ZocColors.muted)
                      .copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(ZocRadii.pill),
                  child: Container(
                    height: 5,
                    color: const Color(0xFFE2E8F0),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      heightFactor: 1,
                      child: const ColoredBox(color: ZocColors.faint),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${(progress * 100).round()}% da meta de $goalLabel · a pausa não conta',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: small.copyWith(fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bar_chart_rounded,
                      size: 15, color: ZocColors.brand),
                  const SizedBox(width: 4),
                  Text('Ver registros',
                      style: ZocText.link().copyWith(fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
