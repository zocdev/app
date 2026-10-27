import 'package:flutter/material.dart';

import '/auth/custom_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';

const _brand = Color(0xFF0F8F8A);

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

/// Opens the "Registrar tempo" form so the user can add past time without the web app.
Future<void> showAddTimeDialog(BuildContext context) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => const _AddTimeDialog(),
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
  String? _project;
  String? _task;
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
      } else {
        _error = _apiMessage(response, 'Não foi possível carregar os projetos.');
      }
    });
  }

  List<Map> _list(String key) =>
      ((_workspace?[key] as List?) ?? const []).whereType<Map>().toList();

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
    setState(() => _error = null);
    if (_project == null || _task == null) {
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
      projectId: _project!,
      taskId: _task!,
      startedAt: _start,
      endedAt: end,
      reason: _reason.text.trim(),
      remote: _remote,
    );
    if (!mounted) return;
    if (response.succeeded) {
      final body = response.jsonBody;
      Navigator.of(context)
          .pop(body is Map && body['auto_approved'] == true);
      return;
    }
    setState(() {
      _busy = false;
      _error = _apiMessage(response, 'Não foi possível enviar. Tente novamente.');
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar tempo'),
      content: SizedBox(
        width: 420,
        child: _loading
            ? const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator(color: _brand)),
              )
            : _workspace == null
                ? Text(_error ?? '')
                : _form(),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: _brand),
          child: const Text('Cancelar'),
        ),
        if (_workspace != null)
          ElevatedButton(
            key: const ValueKey('add-time-submit'),
            onPressed: _busy ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _brand,
              foregroundColor: Colors.white,
            ),
            child: Text(_busy
                ? 'Enviando...'
                : _isAdmin
                    ? 'Registrar'
                    : 'Enviar para aprovação'),
          ),
      ],
    );
  }

  Widget _form() {
    final tasks = _list('tasks').where((t) => t['project_id'] == _project);
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isAdmin
                ? 'Como Administrador, seus lançamentos são aprovados automaticamente.'
                : 'O tempo só entra nos relatórios após aprovação.',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: const ValueKey('add-time-project'),
            initialValue: _project,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Projeto'),
            items: [
              for (final p in _list('projects'))
                DropdownMenuItem(value: '${p['id']}', child: Text('${p['name']}')),
            ],
            onChanged: _busy
                ? null
                : (value) => setState(() {
                      _project = value;
                      _task = null;
                    }),
          ),
          DropdownButtonFormField<String>(
            key: ValueKey('add-time-task-$_project'),
            initialValue: _task,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Atividade'),
            items: [
              for (final t in tasks)
                DropdownMenuItem(value: '${t['id']}', child: Text('${t['name']}')),
            ],
            onChanged: _busy ? null : (value) => setState(() => _task = value),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  key: const ValueKey('add-time-start'),
                  onTap: _busy ? null : _pickStart,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Início'),
                    child: Text(
                        '${_two(_start.day)}/${_two(_start.month)}/${_start.year} ${_two(_start.hour)}:${_two(_start.minute)}'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: TextField(
                  key: const ValueKey('add-time-duration'),
                  controller: _duration,
                  enabled: !_busy,
                  decoration: const InputDecoration(
                      labelText: 'Duração (HH:mm)', hintText: '01:30'),
                ),
              ),
            ],
          ),
          TextField(
            key: const ValueKey('add-time-reason'),
            controller: _reason,
            enabled: !_busy,
            maxLength: 2000,
            minLines: 2,
            maxLines: 4,
            decoration:
                const InputDecoration(labelText: 'Motivo / descrição'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: _brand,
            title: const Text('Trabalho remoto'),
            value: _remote,
            onChanged: _busy ? null : (value) => setState(() => _remote = value),
          ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}
