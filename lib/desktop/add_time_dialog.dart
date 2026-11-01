import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/auth/custom_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/form_field_controller.dart';
import '/ui/zoc_ui.dart';

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

/// Opens the "Registrar tempo" form as a ZOC modal so the user can add past
/// time without the web app.
Future<void> showAddTimeDialog(BuildContext context) async {
  final saved = await showZocModal<bool>(
    context,
    barrierDismissible: false,
    builder: (dialog) => GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: const _AddTimeDialog(),
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
  // Back the disabled placeholders shown until the previous field is picked.
  final _pendingProject = FormFieldController<String>(null);
  final _pendingTask = FormFieldController<String>(null);
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
    _pendingProject.dispose();
    _pendingTask.dispose();
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

  Widget _select({
    required Key key,
    required String label,
    required IconData icon,
    required FormFieldController<String> controller,
    required List<Map> options,
    required String hint,
    ValueChanged<String?>? onChanged,
    bool disabled = false,
  }) =>
      ZocSelect<String>(
        dropDownKey: key,
        label: label,
        icon: icon,
        controller: controller,
        options: [for (final o in options) '${o['id']}'],
        optionLabels: [for (final o in options) '${o['name']}'],
        onChanged: onChanged ?? (_) {},
        hintText: hint,
        searchHintText: 'Buscar...',
        maxHeight: 200,
        disabled: disabled || _busy,
        isSearchable: true,
      );

  @override
  Widget build(BuildContext context) {
    return ZocModal(
      width: 520,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_calendar_outlined,
                    color: ZocColors.brand, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Registrar tempo',
                      style: ZocText.h2().copyWith(fontSize: 19)),
                ),
                IconButton(
                  key: const ValueKey('add-time-close'),
                  tooltip: 'Fechar',
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  splashRadius: 18,
                  constraints:
                      const BoxConstraints.tightFor(width: 36, height: 36),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close_rounded,
                      color: ZocColors.muted, size: 20),
                ),
              ],
            ),
            Text(
              'Lance um período que não foi registrado.'
              '${_isAdmin ? '' : ' Ele entra nos relatórios após aprovação.'}',
              style: ZocText.sub(),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: ZocColors.brand),
                ),
              )
            else if (_workspace != null)
              ..._form(),
            if (_error != null) ...[
              const SizedBox(height: 12),
              ZocNotice(_error!, kind: ZocNoticeKind.error),
            ],
            if (_workspace == null && !_loading) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ZocButton('Fechar',
                    variant: ZocButtonVariant.ghost,
                    onPressed: () => Navigator.of(context).pop()),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _form() {
    final clients = _clients;
    final client = _clientController.value;
    final projects = _list('projects')
        .where((p) => clients.isEmpty || '${p['client_id']}' == client);
    final project = _projectController.value;
    final tasks = _list('tasks').where((t) => t['project_id'] == project);

    final projectField = clients.isEmpty || client != null
        ? _select(
            key: ValueKey(client == null
                ? 'add-time-project'
                : 'add-time-project-$client'),
            label: 'Projeto',
            icon: Icons.work_outline_rounded,
            controller: _projectController,
            options: projects.toList(),
            hint: 'Escolha o projeto',
            onChanged: (_) => setState(() => _taskController.value = null),
          )
        : _select(
            key: const ValueKey('add-time-project-pending'),
            label: 'Projeto',
            icon: Icons.work_outline_rounded,
            controller: _pendingProject,
            options: const [],
            hint: 'Escolha o cliente antes',
            disabled: true,
          );

    final taskField = project != null
        ? _select(
            key: ValueKey('add-time-task-$project'),
            label: 'Atividade',
            icon: Icons.checklist_rounded,
            controller: _taskController,
            options: tasks.toList(),
            hint: 'Escolha a atividade',
            onChanged: (_) => setState(() {}),
          )
        : _select(
            key: const ValueKey('add-time-task-pending'),
            label: 'Atividade',
            icon: Icons.checklist_rounded,
            controller: _pendingTask,
            options: const [],
            hint: 'Escolha a atividade',
            disabled: true,
          );

    final startText =
        '${_two(_start.day)}/${_two(_start.month)}/${_start.year} ${_two(_start.hour)}:${_two(_start.minute)}';

    return [
      const SizedBox(height: 12),
      if (clients.isNotEmpty)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _select(
                key: const ValueKey('add-time-client'),
                label: 'Cliente',
                icon: Icons.apartment_rounded,
                controller: _clientController,
                options: clients,
                hint: 'Escolha o cliente',
                onChanged: (_) => setState(() {
                  _projectController.value = null;
                  _taskController.value = null;
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: projectField),
          ],
        )
      else
        projectField,
      const SizedBox(height: 10),
      taskField,
      const SizedBox(height: 10),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Início', style: ZocText.label()),
                const SizedBox(height: 6),
                InkWell(
                  key: const ValueKey('add-time-start'),
                  borderRadius: BorderRadius.circular(ZocRadii.input),
                  onTap: _busy ? null : _pickStart,
                  child: InputDecorator(
                    decoration:
                        zocInputDecoration(icon: Icons.calendar_today_outlined),
                    child: Text(startText, style: ZocText.body()),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ZocSwitch(
                      key: const ValueKey('add-time-remote'),
                      value: _remote,
                      onChanged:
                          _busy ? null : (v) => setState(() => _remote = v),
                    ),
                    const SizedBox(width: 8),
                    Text('Trabalho remoto',
                        style: ZocText.caption(color: ZocColors.text)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ZocTextField(
                  key: const ValueKey('add-time-duration'),
                  label: 'Duração',
                  icon: Icons.schedule_rounded,
                  controller: _duration,
                  enabled: !_busy,
                  hintText: '01:00',
                ),
                const SizedBox(height: 8),
                Text('Formato HH:mm',
                    style: ZocText.caption(color: ZocColors.faint)),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      ZocTextField(
        key: const ValueKey('add-time-reason'),
        label: 'Motivo / descrição',
        icon: Icons.edit_outlined,
        controller: _reason,
        enabled: !_busy,
        hintText: 'Ex.: reunião fora do computador',
        inputFormatters: [LengthLimitingTextInputFormatter(2000)],
      ),
      const SizedBox(height: 10),
      ZocNotice(
        _isAdmin
            ? 'Como Administrador, seu lançamento é aprovado automaticamente.'
            : 'O tempo só entra nos relatórios após aprovação do supervisor.',
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: ZocButton(
              'Cancelar',
              variant: ZocButtonVariant.ghost,
              expanded: true,
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ZocButton(
              _isAdmin ? 'Registrar' : 'Enviar solicitação',
              key: const ValueKey('add-time-submit'),
              icon: Icons.check_rounded,
              expanded: true,
              loading: _busy,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    ];
  }
}
