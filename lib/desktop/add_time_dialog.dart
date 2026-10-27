import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/custom_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/utils/zoc_logo.dart';

const _brand = Color(0xFF0F8F8A);
const _ink = Color(0xFF101827);

/// Parses "HH:mm" into minutes (1 to 1440), same rules as the web form.
int durationMinutes(String value) {
  final match = RegExp(r'^(\d{1,2}):([0-5]\d)$').firstMatch(value.trim());
  if (match == null) throw const FormatException('Informe a duração em HH:mm.');
  final minutes = int.parse(match[1]!) * 60 + int.parse(match[2]!);
  if (minutes <= 0 || minutes > 1440) {
    throw const FormatException(
        'A duração deve ser maior que zero e de até 24 horas.');
  }
  return minutes;
}

/// End of a period that starts at [start] and lasts [duration]; it must be in the past.
DateTime requestEnd(DateTime start, String duration, {DateTime? now}) {
  final end = start.add(Duration(minutes: durationMinutes(duration)));
  if (end.isAfter(now ?? DateTime.now())) {
    throw const FormatException('O período precisa terminar no passado.');
  }
  return end;
}

/// Default form period: the last hour, without crossing midnight.
({DateTime start, String duration}) defaultPeriod([DateTime? now]) {
  now ??= DateTime.now();
  final midnight = DateTime(now.year, now.month, now.day);
  var start = now.subtract(const Duration(hours: 1));
  if (start.isBefore(midnight)) start = midnight;
  start = DateTime(start.year, start.month, start.day, start.hour, start.minute);
  final minutes = now.difference(start).inMinutes.clamp(1, 60);
  return (start: start, duration: _hhmm(minutes));
}

String _hhmm(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

String _two(int n) => n.toString().padLeft(2, '0');

String _apiMessage(ApiCallResponse response, String fallback) {
  final body = response.jsonBody;
  if (body is Map && body['message'] is String) return body['message'];
  return fallback;
}

/// Opens the "Registrar tempo" form, styled like the activity popup, so the
/// user can add past time without the web app.
Future<void> showAddTimeDialog(BuildContext context) async {
  final saved = await showModalBottomSheet<bool>(
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: false,
    context: context,
    builder: (sheet) => GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Padding(
        padding: MediaQuery.viewInsetsOf(sheet),
        child: const _AddTimeDialog(),
      ),
    ),
  );
  if (saved == null || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(saved
        ? 'Registro aprovado: as horas já entram nos relatórios.'
        : 'Solicitação enviada. Aguarde a aprovação do administrador ou supervisor.'),
  ));
}

class _AddTimeDialog extends StatefulWidget {
  const _AddTimeDialog();

  @override
  State<_AddTimeDialog> createState() => _AddTimeDialogState();
}

class _AddTimeDialogState extends State<_AddTimeDialog> {
  Map<String, dynamic>? _workspace;
  String? _error;
  bool _loading = true;
  bool _busy = false;
  final _clientController = FormFieldController<String>(null);
  final _projectController = FormFieldController<String>(null);
  final _taskController = FormFieldController<String>(null);
  late DateTime _start;
  final _duration = TextEditingController();
  final _reason = TextEditingController();
  bool _remote = true;

  @override
  void initState() {
    super.initState();
    final period = defaultPeriod();
    _start = period.start;
    _duration.text = period.duration;
    _load();
  }

  @override
  void dispose() {
    _clientController.dispose();
    _projectController.dispose();
    _taskController.dispose();
    _duration.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final response =
        await TimeRequestWorkspaceCall.call(token: currentAuthenticationToken);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (response.succeeded && response.jsonBody is Map) {
        _workspace = Map<String, dynamic>.from(response.jsonBody);
        final clients = _clients;
        if (clients.length == 1) {
          _clientController.value = '${clients.first['id']}';
        }
      } else {
        _error = _apiMessage(response, 'Não foi possível carregar os projetos.');
      }
    });
  }

  List<Map> _list(String key) =>
      ((_workspace?[key] as List?) ?? const []).whereType<Map>().toList();

  // Projects of different clients may share a name, so the client is picked
  // first, as in the popup. Older APIs send no client: then it is skipped.
  List<Map> get _clients {
    final byId = <String, Map>{};
    for (final p in _list('projects')) {
      if (p['client_id'] != null) {
        byId.putIfAbsent('${p['client_id']}',
            () => {'id': p['client_id'], 'name': p['client_name'] ?? ''});
      }
    }
    return byId.values.toList();
  }

  bool get _isAdmin => _workspace?['is_admin'] == true;

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (time == null) return;
    setState(() =>
        _start = DateTime(day.year, day.month, day.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    final project = _projectController.value;
    final task = _taskController.value;
    setState(() => _error = null);
    if (project == null || task == null) {
      setState(() => _error = 'Selecione o projeto e a atividade.');
      return;
    }
    if (_reason.text.trim().length < 3) {
      setState(() => _error = 'Informe o motivo (ao menos 3 caracteres).');
      return;
    }
    final DateTime end;
    try {
      end = requestEnd(_start, _duration.text);
    } on FormatException catch (e) {
      setState(() => _error = e.message);
      return;
    }
    setState(() => _busy = true);
    final response = await SubmitTimeRequestCall.call(
      token: currentAuthenticationToken,
      userId: '${_workspace!['user_id']}',
      projectId: project,
      taskId: task,
      startedAt: _start,
      endedAt: end,
      reason: _reason.text.trim(),
      remote: _remote,
    );
    if (!mounted) return;
    if (response.succeeded) {
      final body = response.jsonBody;
      Navigator.of(context).pop(body is Map && body['auto_approved'] == true);
      return;
    }
    setState(() {
      _busy = false;
      _error = _apiMessage(response, 'Não foi possível enviar. Tente novamente.');
    });
  }

  TextStyle _text(double size, FontWeight weight, [Color color = _ink]) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

  // Same filled, borderless field as the popup's "Notas".
  InputDecoration _field(String hint) {
    final theme = FlutterFlowTheme.of(context);
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderSide: BorderSide(color: color, width: 1.0),
          borderRadius: BorderRadius.circular(8.0),
        );
    return InputDecoration(
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12.0, vertical: 9.0),
      hintText: hint,
      hintStyle: _text(14, FontWeight.w400, const Color(0xFF667085)),
      enabledBorder: border(const Color(0x00000000)),
      focusedBorder: border(const Color(0x00000000)),
      disabledBorder: border(const Color(0x00000000)),
      errorBorder: border(theme.error),
      focusedErrorBorder: border(theme.error),
      filled: true,
      fillColor: theme.primaryBackground,
    );
  }

  Widget _dropDown({
    required Key key,
    required FormFieldController<String> controller,
    required List<Map> options,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return FlutterFlowDropDown<String>(
      key: key,
      controller: controller,
      options: [for (final o in options) '${o['id']}'],
      optionLabels: [for (final o in options) '${o['name']}'],
      onChanged: onChanged,
      width: 400.0,
      height: 35.0,
      maxHeight: 200.0,
      searchHintTextStyle: _text(14, FontWeight.w400),
      searchTextStyle: _text(14, FontWeight.w400),
      textStyle: _text(14, FontWeight.w500),
      hintText: hint,
      searchHintText: 'Search...',
      searchCursorColor: theme.primaryBackground,
      icon: const Icon(Icons.keyboard_arrow_down, color: _brand, size: 25.0),
      fillColor: theme.primaryBackground,
      elevation: 1.0,
      borderColor: theme.secondaryBackground,
      borderWidth: 0.0,
      borderRadius: 6.0,
      margin: const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
      hidesUnderline: true,
      disabled: _busy,
      isSearchable: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Align(
      child: Container(
        width: 500.0,
        height: 570.4,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Color(0xFFF6F8FA),
              Color(0xFFE6F4F3),
              Color(0xFFD5F0EE),
            ],
            stops: [0.0, 0.4, 0.75, 1.0],
            begin: AlignmentDirectional(-1.0, -1.0),
            end: AlignmentDirectional(1.0, 1.0),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: ZocLogo(width: 100.0, showTagline: false),
                    ),
                    IconButton(
                      key: const ValueKey('add-time-close'),
                      tooltip: 'Fechar',
                      onPressed: _busy ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: _ink, size: 20.0),
                    ),
                  ],
                ),
              ),
              Text('Registrar tempo',
                  style: _text(22, FontWeight.w600).copyWith(letterSpacing: -0.2)),
              const SizedBox(height: 4.0),
              Text(
                _isAdmin
                    ? 'Como Administrador, seu lançamento é aprovado automaticamente.'
                    : 'O tempo só entra nos relatórios após aprovação.',
                style: _text(12, FontWeight.w400, const Color(0xFF667085)),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 40.0),
                  child: CircularProgressIndicator(color: _brand),
                )
              else if (_workspace != null)
                ..._form(theme),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(50.0, 12.0, 50.0, 0.0),
                  child: Text(_error!,
                      textAlign: TextAlign.center,
                      style: _text(13, FontWeight.w500, theme.error)),
                ),
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _form(FlutterFlowTheme theme) {
    final clients = _clients;
    final client = _clientController.value;
    final projects = _list('projects')
        .where((p) => clients.isEmpty || '${p['client_id']}' == client);
    final project = _projectController.value;
    final tasks = _list('tasks').where((t) => t['project_id'] == project);
    return [
      const SizedBox(height: 16.0),
      if (clients.isNotEmpty) ...[
        _dropDown(
          key: const ValueKey('add-time-client'),
          controller: _clientController,
          options: clients,
          hint: 'Escolha o cliente',
          onChanged: (_) => setState(() {
            _projectController.value = null;
            _taskController.value = null;
          }),
        ),
        const SizedBox(height: 15.0),
      ],
      if (clients.isEmpty || client != null)
        _dropDown(
          key: ValueKey(
              client == null ? 'add-time-project' : 'add-time-project-$client'),
          controller: _projectController,
          options: projects.toList(),
          hint: 'Escolha o projeto',
          onChanged: (_) => setState(() => _taskController.value = null),
        ),
      if (project != null) ...[
        const SizedBox(height: 15.0),
        _dropDown(
          key: ValueKey('add-time-task-$project'),
          controller: _taskController,
          options: tasks.toList(),
          hint: 'Escolha a atividade',
          onChanged: (_) => setState(() {}),
        ),
      ],
      const SizedBox(height: 15.0),
      SizedBox(
        width: 400.0,
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                key: const ValueKey('add-time-start'),
                borderRadius: BorderRadius.circular(8.0),
                onTap: _busy ? null : _pickStart,
                child: InputDecorator(
                  decoration: _field('Início').copyWith(
                    suffixIcon: const Icon(Icons.calendar_today_outlined,
                        color: _brand, size: 18.0),
                    suffixIconConstraints:
                        const BoxConstraints(minWidth: 36.0, minHeight: 18.0),
                  ),
                  child: Text(
                    'Início: ${_two(_start.day)}/${_two(_start.month)}/${_start.year} ${_two(_start.hour)}:${_two(_start.minute)}',
                    style: _text(14, FontWeight.w500),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12.0),
            SizedBox(
              width: 150.0,
              child: TextFormField(
                key: const ValueKey('add-time-duration'),
                controller: _duration,
                enabled: !_busy,
                decoration: _field('Duração').copyWith(
                  prefixText: 'Duração ',
                  prefixStyle: _text(14, FontWeight.w400, const Color(0xFF667085)),
                ),
                style: _text(14, FontWeight.w500),
                cursorColor: theme.primaryText,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 15.0),
      SizedBox(
        width: 400.0,
        child: TextFormField(
          key: const ValueKey('add-time-reason'),
          controller: _reason,
          enabled: !_busy,
          maxLength: 2000,
          maxLines: 3,
          decoration: _field('Motivo / descrição').copyWith(counterText: ''),
          style: _text(14, FontWeight.w400),
          cursorColor: theme.primaryText,
        ),
      ),
      const SizedBox(height: 12.0),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Switch.adaptive(
            value: _remote,
            onChanged: _busy ? null : (value) => setState(() => _remote = value),
            activeThumbColor: theme.secondaryBackground,
            activeTrackColor: _brand,
            inactiveTrackColor: theme.alternate,
            inactiveThumbColor: theme.secondaryBackground,
          ),
          const SizedBox(width: 8.0),
          Text('Trabalho remoto', style: _text(14, FontWeight.w500)),
        ],
      ),
      const SizedBox(height: 16.0),
      FFButtonWidget(
        key: const ValueKey('add-time-submit'),
        onPressed: _busy ? null : _submit,
        text: _isAdmin ? 'REGISTRAR' : 'ENVIAR',
        options: FFButtonOptions(
          width: 140.0,
          height: 50.0,
          padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
          color: _brand,
          textStyle: _text(14, FontWeight.bold, theme.secondaryBackground),
          elevation: 0.0,
          borderRadius: BorderRadius.circular(12.0),
        ),
        showLoadingIndicator: true,
      ),
    ];
  }
}
