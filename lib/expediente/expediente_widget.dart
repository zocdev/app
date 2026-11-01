import '/auth/custom_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart' as actions;
import '/ui/zoc_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '/desktop/add_time_dialog.dart';
import 'expediente_model.dart';
export 'expediente_model.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;
import '/desktop/popup_window.dart';

/// "3h 30min", "1h 00min" or "20min".
String expedienteHoursLabel(double? hours) {
  final total = ((hours ?? 0) * 60).round().clamp(0, 1 << 31);
  final h = total ~/ 60, m = total % 60;
  if (h == 0) return '${m}min';
  return '${h}h ${m.toString().padLeft(2, '0')}min';
}

/// Goal label: "8h", "7h 30min".
String expedienteGoalLabel(double hours) {
  if (hours == hours.roundToDouble()) return '${hours.round()}h';
  return expedienteHoursLabel(hours);
}

/// Weekdays (Mon–Fri) between [a] and [b], inclusive; at least 1.
int _weekdays(DateTime a, DateTime b) {
  var start = DateTime(a.year, a.month, a.day);
  var end = DateTime(b.year, b.month, b.day);
  if (end.isBefore(start)) (start, end) = (end, start);
  var count = 0;
  for (var d = start;
      !d.isAfter(end);
      d = DateTime(d.year, d.month, d.day + 1)) {
    if (d.weekday <= DateTime.friday) count++;
  }
  return count < 1 ? 1 : count;
}

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

  bool _loading = true;
  int _loadSeq = 0;

  /// Label and dates of the loaded records: the PDF prints them together.
  (String, DateTime, DateTime)? _loadedPeriod;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ExpedienteModel());
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS)) {
      windowManager.setSize(kDesktopMainWindowSize);
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
      ).toString();
      safeSetState(() {});
      await _load('day');
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS)) {
      windowManager.setSize(kDesktopWindowSize);
    }

    super.dispose();
  }

  /// Loads worked hours, tasks done, ignored popups and the work goal for
  /// [period] ('day', 'week', 'month' or 'range' with [start] / [end]).
  /// Responses of an older selection are ignored.
  Future<void> _load(String period, {DateTime? start, DateTime? end}) async {
    final seq = ++_loadSeq;
    bool current() => mounted && seq == _loadSeq;
    // The previous selection's records must not be shown or exported as this one's.
    _model.tasksDone = null;
    _model.ignoredPopUps = null;
    _loadedPeriod = _selectedPeriod();
    safeSetState(() => _loading = true);
    final token = currentAuthenticationToken;
    final userId = UserDataStruct.maybeFromMap(FFAppState().UserData)?.user.id;
    final rawUserId = getJsonField(
      FFAppState().UserData,
      r'''$.user.id''',
    ).toString();
    final startDate = start?.toString() ?? '';
    final endDate = end?.toString() ?? '';
    // Worked hours call "today" what the other endpoints call "day".
    final hoursPeriod = period == 'day' ? 'today' : period;
    final goalPeriod = period == 'range' ? 'today' : hoursPeriod;

    await Future.wait([
      Future(() async {
        final response = await GetWorkedHoursCall.call(
          token: token,
          userId: userId,
          period: hoursPeriod,
          startDate: startDate,
          endDate: endDate,
        );
        if (!current()) return;
        _model.workedHoursResp = response;
        final body = getJsonField(response.jsonBody, r'''$''');
        if (response.succeeded && body is num) {
          _model.workedHours = body.toDouble();
          safeSetState(() {});
        }
      }),
      Future(() async {
        final response = await GetTaskDoneByUserCall.call(
          token: token,
          userId: userId,
          period: period,
          startDate: startDate,
          endDate: endDate,
        );
        if (!current()) return;
        _model.tasksDoneResp = response;
        final body = getJsonField(response.jsonBody, r'''$''');
        _model.tasksDone = body is List ? body : <dynamic>[];
        safeSetState(() {});
      }),
      Future(() async {
        final response = await IgnoredPopUpsCall.call(
          id: rawUserId,
          period: period,
          token: token,
          startDate: startDate,
          endDate: endDate,
        );
        if (!current()) return;
        _model.ignoredPopupsResp = response;
        if (response.succeeded) {
          _model.ignoredPopUps = IgnoredPopUpsCall.count(response);
          safeSetState(() {});
        }
      }),
      Future(() async {
        final response = await GetWorkGoalCall.call(
          token: token,
          userId: userId,
          period: goalPeriod,
        );
        if (!current()) return;
        _model.workGoalResp = response;
        var goal = GetWorkGoalCall.goalHours(response, goalPeriod);
        if (period == 'range' && start != null && end != null) {
          goal *= _weekdays(start, end);
        }
        _model.goalHours = goal;
        safeSetState(() {});
      }),
    ]);
    if (current()) safeSetState(() => _loading = false);
  }

  Future<void> _selectPeriod(int index) async {
    _model.endDate = null;
    _model.initDate = null;
    _model.day = index == 0;
    _model.week = index == 1;
    _model.month = index == 2;
    safeSetState(() {});
    await _load(const ['day', 'week', 'month'][index]);
  }

  Future<DateTime?> _showDatePicker() => showDatePicker(
        context: context,
        initialDate: getCurrentTimestamp,
        firstDate: DateTime(1900),
        lastDate: DateTime(2050),
        builder: (context, child) => wrapInMaterialDatePickerTheme(
          context,
          child!,
          headerBackgroundColor: ZocColors.brand,
          headerForegroundColor: Colors.white,
          headerTextStyle: ZocText.title(color: Colors.white)
              .copyWith(fontSize: 32, fontWeight: FontWeight.w600),
          pickerBackgroundColor: ZocColors.surface,
          pickerForegroundColor: ZocColors.text,
          selectedDateTimeBackgroundColor: ZocColors.brand,
          selectedDateTimeForegroundColor: Colors.white,
          actionButtonForegroundColor: ZocColors.text,
          iconSize: 24.0,
        ),
      );

  Future<void> _pickStart() async {
    final picked = await _showDatePicker();
    if (picked != null) {
      _model.datePicked1 = DateTime(picked.year, picked.month, picked.day);
    } else if (_model.datePicked1 != null) {
      _model.datePicked1 = getCurrentTimestamp;
    }
    _model.initDate = _model.datePicked1;
    safeSetState(() {});
  }

  Future<void> _pickEnd() async {
    final picked = await _showDatePicker();
    if (picked != null) {
      _model.datePicked2 = DateTime(picked.year, picked.month, picked.day);
    } else if (_model.datePicked2 != null) {
      _model.datePicked2 = getCurrentTimestamp;
    }
    _model.endDate = _model.datePicked2;
    safeSetState(() {});
    // Range queries need both dates; otherwise the API gets the literal
    // "null" and returns 500.
    if (_model.initDate == null || _model.endDate == null) return;
    await _load('range', start: _model.initDate, end: _model.endDate);
  }

  Future<void> _clearRange() async {
    _model.endDate = null;
    _model.initDate = null;
    _model.day = true;
    _model.week = false;
    _model.month = false;
    safeSetState(() {});
    await _load('day');
  }

  Map<String, dynamic>? _org;
  bool _exporting = false;

  /// Name and avatar of the user's organization, fetched once per screen.
  Future<Map<String, dynamic>?> _loadOrg() async {
    if (_org != null) return _org;
    final orgId = getJsonField(FFAppState().UserData, r'''$.user.org_id''')
            ?.toString() ??
        '';
    if (orgId.isEmpty || orgId == 'null') return null;
    try {
      final response = await GetOrganizationCall.call(
        token: currentAuthenticationToken,
        orgId: orgId,
      ).timeout(const Duration(seconds: 8));
      final body = response.jsonBody;
      if (response.succeeded && body is Map) {
        _org = Map<String, dynamic>.from(body);
      }
    } catch (_) {}
    return _org;
  }

  Future<void> _exportPdf() async {
    final period = _loadedPeriod;
    if (_exporting || _loading || period == null) return;
    _exporting = true;
    // Taken before any await: a period change meanwhile must not mix selections.
    final (label, start, end) = period;
    final activities = _tasks;
    final ignoredPopUps = _model.ignoredPopUps;
    try {
      final org = await _loadOrg();
      final user = getJsonField(FFAppState().UserData, r'''$.user''');
      final userName = user is Map
          ? [user['first_name'], user['last_name']]
              .map((v) => '${v ?? ''}'.trim())
              .where((v) => v.isNotEmpty && v != 'null')
              .join(' ')
          : '';
      await actions.generatePDF(
        activities: activities,
        userName: userName,
        orgName: org?['name']?.toString(),
        orgAvatarUrl: org?['avatar']?.toString(),
        periodLabel: label,
        periodStart: start,
        periodEnd: end,
        ignoredPopUps: ignoredPopUps,
      );
    } finally {
      _exporting = false;
    }
  }

  String get _locale => FFLocalizations.of(context).languageCode;

  List<Map> get _tasks =>
      (_model.tasksDone is List ? (_model.tasksDone as List) : const [])
          .whereType<Map>()
          .toList();

  bool get _customRange => _model.initDate != null || _model.endDate != null;

  /// Label and dates of the selected period, as the PDF prints them.
  (String, DateTime, DateTime) _selectedPeriod() {
    final ranged = _model.initDate != null && _model.endDate != null;
    final (start, end) =
        ranged ? (_model.initDate!, _model.endDate!) : _periodBounds();
    final label = ranged
        ? 'Período personalizado'
        : _model.week
            ? 'Semana'
            : _model.month
                ? 'Mês'
                : 'Dia';
    return start.isAfter(end) ? (label, end, start) : (label, start, end);
  }

  /// Dates covered by Dia / Semana (Mon–Sun) / Mês, as the API resolves them.
  (DateTime, DateTime) _periodBounds() {
    final now = FFAppState().currentDate ?? getCurrentTimestamp;
    final today = DateTime(now.year, now.month, now.day);
    if (_model.week) {
      final start = today.subtract(Duration(days: today.weekday - 1));
      return (start, start.add(const Duration(days: 6)));
    }
    if (_model.month) {
      return (
        DateTime(now.year, now.month, 1),
        DateTime(now.year, now.month + 1, 0)
      );
    }
    return (today, today);
  }

  String _shortDate(DateTime d) =>
      dateTimeFormat('d MMM', d, locale: _locale).replaceAll('.', '');

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
        backgroundColor: ZocColors.background,
        body: ZocBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(),
                  const SizedBox(height: 14),
                  _toolbar(),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 118,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 57, child: _hero()),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 41,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _MiniStat(
                                  icon: Icons.checklist_rounded,
                                  label: 'Atividades',
                                  value: '${_tasks.length}',
                                ),
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: _MiniStat(
                                  icon: Icons.notifications_off_outlined,
                                  label: 'Popups ignorados',
                                  value: '${_model.ignoredPopUps ?? 0}',
                                  warn: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: _activities()),
                  const SizedBox(height: 8),
                  const ZocDisclaimer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final raw = _model.firstName ?? '';
    final name = raw == 'null' ? '' : raw.trim();
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
              color: ZocColors.brandSoft, shape: BoxShape.circle),
          child: name.isEmpty
              ? const Icon(Icons.person_outline_rounded,
                  size: 20, color: ZocColors.brand)
              : Text(name.characters.first.toUpperCase(),
                  style: ZocText.h2(color: ZocColors.brand)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name.isEmpty ? 'Olá!' : 'Olá, $name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ZocText.h3().copyWith(fontSize: 15.5)),
              const SizedBox(height: 2),
              Text(
                dateTimeFormat("EEEE, d 'de' MMMM", FFAppState().currentDate,
                    locale: _locale),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ZocText.caption().copyWith(fontSize: 12.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ZocButton(
          'Registrar tempo',
          key: const ValueKey('add-time-open'),
          variant: ZocButtonVariant.secondary,
          small: true,
          icon: Icons.edit_calendar_outlined,
          onPressed: () => showAddTimeDialog(context),
        ),
        const SizedBox(width: 8),
        _IconAction(
          icon: Icons.picture_as_pdf_outlined,
          tooltip: 'Exportar PDF',
          onTap: _loading ? null : _exportPdf,
        ),
        const SizedBox(width: 4),
        _IconAction(
          icon: Icons.close_rounded,
          tooltip: 'Fechar',
          ghost: true,
          onTap: () async => context.safePop(),
        ),
      ],
    );
  }

  Widget _toolbar() {
    final custom = _customRange;
    final selected = custom
        ? -1
        : _model.week
            ? 1
            : _model.month
                ? 2
                : 0;
    final (periodStart, periodEnd) = _periodBounds();
    final startLabel = custom
        ? (_model.initDate == null ? 'Início' : _shortDate(_model.initDate!))
        : _shortDate(periodStart);
    final endLabel = custom
        ? (_model.endDate == null ? 'Fim' : _shortDate(_model.endDate!))
        : _shortDate(periodEnd);

    return Row(
      children: [
        ZocSegmented(
          labels: const ['Dia', 'Semana', 'Mês'],
          selected: selected,
          onChanged: _selectPeriod,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: ZocColors.surface,
              borderRadius: BorderRadius.circular(ZocRadii.pill),
              boxShadow: ZocShadows.card,
            ),
            child: Row(
              children: [
                _DateChip(
                  label: startLabel,
                  tooltip: 'Data de início',
                  active: _model.initDate != null,
                  onTap: _pickStart,
                ),
                Text('–', style: ZocText.body(color: ZocColors.faint)),
                _DateChip(
                  label: endLabel,
                  tooltip: 'Data de fim',
                  active: _model.endDate != null,
                  onTap: _pickEnd,
                ),
                const Spacer(),
                if (custom)
                  _IconAction(
                    icon: Icons.close_rounded,
                    tooltip: 'Limpar período',
                    ghost: true,
                    size: 28,
                    onTap: _clearRange,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _hero() {
    final worked = _model.workedHours ?? 0;
    final goal = _model.goalHours;
    final progress = ZocGoalProgress(worked, goal);
    final ratio = progress.ratio;
    final caption = goal == null
        ? 'Carregando meta…'
        : progress.reached
            ? (progress.hasOvertime
                ? 'Meta cumprida ✓'
                : 'Meta de ${expedienteGoalLabel(goal)} cumprida ✓')
            : '${(ratio * 100).round()}% da meta de ${expedienteGoalLabel(goal)}';
    final soft =
        ZocText.caption(color: const Color(0xE6FFFFFF)).copyWith(fontSize: 13);
    return ZocHeroCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 15),
              const SizedBox(width: 6),
              Text('Horas trabalhadas', style: soft),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(expedienteHoursLabel(worked),
                style: ZocText.big(color: Colors.white)),
          ),
          ZocProgressBar(value: ratio, onDark: true),
          Row(
            children: [
              Flexible(
                child: Text(caption,
                    style: soft, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              if (progress.hasOvertime) ...[
                const SizedBox(width: 8),
                ZocOvertimePill(
                    '+${expedienteHoursLabel(progress.overtimeHours)} além da meta'),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _activities() {
    final tasks = _tasks;
    final dayView = _model.day && !_customRange;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: ZocColors.surface,
        borderRadius: BorderRadius.circular(ZocRadii.card),
        boxShadow: ZocShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart_rounded,
                  size: 18, color: ZocColors.brand),
              const SizedBox(width: 8),
              Expanded(
                  child: Text('Atividades feitas',
                      style: ZocText.h3().copyWith(fontSize: 15.5))),
              ZocBadge('${tasks.length}'),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: tasks.isEmpty
                ? (_loading
                    ? const Center(
                        child: SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: ZocColors.brand),
                        ),
                      )
                    : const _EmptyActivities())
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, i) =>
                        _taskItem(tasks[i], i, showDate: !dayView),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _taskItem(Map task, int index, {required bool showDate}) {
    String text(String key) {
      final v = task[key];
      return v == null ? '' : '$v'.trim();
    }

    DateTime? time(String key) => DateTime.tryParse(text(key))?.toLocal();
    final subtitle = [text('project_name'), text('client_name')]
        .where((s) => s.isNotEmpty)
        .join(' · ');
    final hours = task['hours'];
    final start = time('created_at'), end = time('ended_at');
    String hm(DateTime d) => dateTimeFormat('HH:mm', d, locale: _locale);
    var range =
        [if (start != null) hm(start), if (end != null) hm(end)].join(' – ');
    if (showDate && start != null) {
      final day = dateTimeFormat('dd/MM', start, locale: _locale);
      range = range.isEmpty ? day : '$day · $range';
    }
    return ZocListItem(
      title: text('task_name'),
      subtitle: subtitle.isEmpty ? null : subtitle,
      barColor: ZocColors.accents[index % ZocColors.accents.length],
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ZocBadge(expedienteHoursLabel(hours is num ? hours.toDouble() : 0)),
          if (range.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(range, style: ZocText.caption()),
          ],
        ],
      ),
    );
  }
}

/// Small stat card next to the hero (Atividades / Popups ignorados).
class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    this.warn = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool warn;

  @override
  Widget build(BuildContext context) => ZocCard(
        color: warn ? ZocColors.warnSurface : ZocColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Icon(icon,
                size: 15, color: warn ? ZocColors.warn : ZocColors.brand),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ZocText.body(color: ZocColors.muted)
                      .copyWith(fontSize: 13)),
            ),
            Text(value,
                style: ZocText.title().copyWith(fontSize: 20, height: 1)),
          ],
        ),
      );
}

/// Round icon button: white with a soft shadow, or [ghost] (no fill).
class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.ghost = false,
    this.size = 34,
  });

  final IconData icon;
  final String tooltip;
  final Future<void> Function()? onTap;
  final bool ghost;
  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ghost ? Colors.transparent : ZocColors.surface,
            shape: BoxShape.circle,
            boxShadow: ghost ? null : ZocShadows.card,
          ),
          child: Material(
            type: MaterialType.transparency,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: SizedBox.square(
                dimension: size,
                child: Icon(icon,
                    size: ghost ? 18 : 16,
                    color: onTap == null
                        ? ZocColors.faint
                        : ghost
                            ? ZocColors.muted
                            : ZocColors.brand),
              ),
            ),
          ),
        ),
      );
}

/// Tappable date inside the range pill.
class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  final String label;
  final String tooltip;
  final bool active;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ZocRadii.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: ZocColors.brand),
                const SizedBox(width: 6),
                Text(label,
                    style: ZocText.body(
                        weight: active ? FontWeight.w600 : FontWeight.w500)),
              ],
            ),
          ),
        ),
      );
}

class _EmptyActivities extends StatelessWidget {
  const _EmptyActivities();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ZocHeroIcon(Icons.event_note_outlined, small: true),
            const SizedBox(height: 10),
            Text('Nenhuma atividade no período', style: ZocText.strong()),
            const SizedBox(height: 2),
            Text('As atividades registradas aparecem aqui.',
                style: ZocText.caption()),
          ],
        ),
      );
}
