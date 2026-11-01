import '/auth/custom_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'popup_dialog_model.dart';
export 'popup_dialog_model.dart';
import '/desktop/popup_window.dart';
import 'dart:async';
import 'dart:convert' show base64Decode;
import '/ui/zoc_ui.dart';
import '/utils/capture_screenshot.dart';

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
  Timer? _countdownTimer;
  final DateTime _openedAt = DateTime.now();
  DateTime? _ignoreDeadline;
  bool _saving = false;
  Uint8List? _screenshotBytes;
  bool _submitted = false;
  bool _refreshing = false;

  // Reloads clients and projects, e.g. when the member was assigned to a
  // project after the popup opened. Keeps the client if it still exists.
  Future<void> _refreshOptions() async {
    if (_refreshing) return;
    safeSetState(() => _refreshing = true);
    await _model.fetchdata(context);
    if (!mounted) return;
    final clientStillExists = FFAppState()
        .clientsOptions
        .any((e) => e.id == _model.clientDropDownValue);
    if (!clientStillExists) {
      _model.clientDropDownValue = null;
      _model.selectedClient = null;
      _model.clientDropDownValueController?.value = null;
    }
    _model.dropdownprojetosValue = null;
    _model.selectedProjects = null;
    _model.dropdownprojetosValueController?.value = null;
    _model.dropdownatividadesValue = null;
    _model.dropdownatividadesValueController?.value = null;
    FFAppState().taskOptions = [];
    safeSetState(() => _refreshing = false);
  }

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  void _scheduleIgnoreTimer() {
    _ignoreTimer?.cancel();
    _ignoreDeadline = DateTime.now().add(widget.ignoreAfter);
    _ignoreTimer = Timer(widget.ignoreAfter, _onIgnoreTimeout);
    safeSetState(() {});
  }

  void _dismissPopup() {
    final navigator = Navigator.of(context);
    final popupRoute = ModalRoute.of(context);
    // Close any activity picker or validation dialog before the popup itself.
    if (popupRoute != null) navigator.popUntil((route) => route == popupRoute);
    navigator.pop();
  }

  Future<void> _onIgnoreTimeout() async {
    if (!mounted || _submitted) return;
    _submitted = true;
    FFAppState().popUpIgnorado = FFAppState().popUpIgnorado + 1;
    FFAppState().isPopupVisible = false;
    _dismissPopup();
    await AddAtivitiesCall.call(
      token: currentAuthenticationToken,
      project: '',
      remote: FFAppState().isRemote,
      ignoredPopUp: true,
      createdAt: functions.timeNowTZ(),
      screenshot: widget.screenshotBase64,
    );
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PopupDialogModel());
    final screenshot = widget.screenshotBase64;
    if (screenshot != null && screenshot.isNotEmpty) {
      try {
        _screenshotBytes = base64Decode(screenshot.split(',').last);
      } on FormatException {
        // Preserve the original payload even when its preview is unavailable.
      }
    }

    FFAppState().isPopupVisible = true;
    FFAppState().taskOptions = [];

    // On component load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await prepareDesktopWindowForPopup();
      if (!mounted) return;
      FocusScope.of(context).requestFocus();
      _scheduleIgnoreTimer();

      _model.soundPlayer ??= AudioPlayer();
      if (_model.soundPlayer!.playing) {
        await _model.soundPlayer!.stop();
      }
      _model.soundPlayer!.setVolume(1.0);
      _model.soundPlayer!
          .setAsset('assets/audios/aviso.mp3')
          .then((_) => _model.soundPlayer!.play());

      if (!mounted) return;
      await _model.fetchdata(context);
      if (!mounted) return;
      safeSetState(() {});
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) safeSetState(() {});
    });
    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _ignoreTimer?.cancel();
    _countdownTimer?.cancel();
    _model.maybeDispose();
    restoreDesktopWindowAfterPopup();

    super.dispose();
  }

  Future<void> _saveRecord() async {
    if (_saving || _submitted) return;
    safeSetState(() => _saving = true);
    try {
      _model.validate = true;
      if (_model.formKey.currentState == null ||
          !_model.formKey.currentState!.validate()) {
        safeSetState(() => _model.validate = false);
        return;
      }
      if (_model.clientDropDownValue == null ||
          _model.clientDropDownValue!.isEmpty) {
        await showDialog(
          context: context,
          builder: (alertDialogContext) {
            return AlertDialog(
              title: Text('Atenção'),
              content: Text('Cliente é necessario.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(alertDialogContext),
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
      if (_model.dropdownprojetosValue == null ||
          _model.dropdownprojetosValue!.isEmpty) {
        await showDialog(
          context: context,
          builder: (alertDialogContext) {
            return AlertDialog(
              title: Text('Atenção'),
              content: Text('Projeto é necessario.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(alertDialogContext),
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
      if (_model.dropdownatividadesValue == null ||
          _model.dropdownatividadesValue!.isEmpty) {
        await showDialog(
          context: context,
          builder: (alertDialogContext) {
            return AlertDialog(
              title: Text('Atenção'),
              content: Text('Tarefa é necessario.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(alertDialogContext),
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

      // 403: admin turned time tracking off while the popup was open.
      if ((_model.apiResult4ww?.succeeded ?? true) ||
          _model.apiResult4ww?.statusCode == 403) {
        FFAppState().isPopupVisible = false;
        if (mounted) _dismissPopup();
      } else {
        _submitted = false;
        if (mounted) {
          _scheduleIgnoreTimer();
        }
      }

      safeSetState(() {});
    } finally {
      if (mounted) safeSetState(() => _saving = false);
    }
  }

  void _selectActivities(List<String> values) {
    _model.dropdownatividadesValueController ??=
        FormListFieldController<String>(null);
    _model.dropdownatividadesValueController!.value = values;
    safeSetState(() => _model.dropdownatividadesValue = values);
  }

  Future<void> _showActivities() async {
    if (!_model.mostrarActividad || _model.selectedProjects == null) return;
    final tasks = FFAppState()
        .taskOptions
        .map(TaskOptionStruct.maybeFromMap)
        .withoutNulls
        .toList();
    var search = '';
    await showZocModal(context,
        builder: (context) => StatefulBuilder(
              builder: (context, update) => ZocModal(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Atividades', style: ZocText.h2()),
                      const SizedBox(height: 12),
                      ZocTextField(
                        hintText: 'Buscar atividades...',
                        icon: Icons.search_rounded,
                        onChanged: (value) =>
                            update(() => search = value.toLowerCase()),
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 240),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (tasks.isEmpty)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  child: Text(
                                      'Nenhuma atividade disponível neste projeto.',
                                      style: ZocText.sub()),
                                ),
                              for (final task in tasks.where((task) =>
                                  task.name.toLowerCase().contains(search)))
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: ZocCheckRow(
                                    label: task.name,
                                    value: _model.dropdownatividadesValue
                                            ?.contains(task.id) ??
                                        false,
                                    onChanged: (selected) {
                                      final values = [
                                        ...?_model.dropdownatividadesValue
                                      ];
                                      selected
                                          ? values.add(task.id)
                                          : values.remove(task.id);
                                      _selectActivities(values);
                                      update(() {});
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ZocButton('Concluir',
                          onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ),
              ),
            ));
  }

  Widget _activitiesField() {
    final selected = _model.dropdownatividadesValue ?? <String>[];
    final tasks = FFAppState()
        .taskOptions
        .map(TaskOptionStruct.maybeFromMap)
        .withoutNulls;
    final enabled = _model.mostrarActividad && _model.selectedProjects != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Atividades', style: ZocText.label()),
        const SizedBox(height: 6),
        Material(
          color: ZocColors.inputFill,
          borderRadius: BorderRadius.circular(ZocRadii.input),
          child: InkWell(
            onTap: enabled ? _showActivities : null,
            borderRadius: BorderRadius.circular(ZocRadii.input),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final id in selected)
                          InputChip(
                            label: Text(
                                tasks
                                        .where((task) => task.id == id)
                                        .firstOrNull
                                        ?.name ??
                                    id,
                                style: ZocText.caption(
                                    color: ZocColors.brandInk,
                                    weight: FontWeight.w600)),
                            backgroundColor: ZocColors.brandSoft,
                            side: BorderSide.none,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            labelPadding: const EdgeInsets.only(left: 2),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            deleteIcon: const Icon(Icons.close_rounded,
                                size: 13, color: ZocColors.brandInk),
                            onDeleted: () =>
                                _selectActivities([...selected]..remove(id)),
                          ),
                        Text(
                            selected.isEmpty
                                ? 'Escolha as atividades'
                                : 'Adicionar...',
                            style: ZocText.body(color: ZocColors.faint)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 20, color: ZocColors.faint),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final remaining = (_ignoreDeadline ?? _openedAt.add(widget.ignoreAfter))
        .difference(DateTime.now());
    final seconds = remaining.inSeconds.clamp(0, 1 << 31);
    final closesIn =
        '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    final projects = FFAppState()
        .projectOptions
        .map(ProjectOptionStruct.maybeFromMap)
        .withoutNulls
        .where((project) => project.clientId == _model.selectedClient)
        .toList();
    final hasScreenshot = widget.screenshotBase64?.isNotEmpty == true;

    return SizedBox(
      width: 510,
      height: 600,
      child: Material(
        color: ZocColors.background,
        child: ZocBackground(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      const ZocHeroIcon(Icons.timer_outlined, small: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('No que está trabalhando?',
                                style: ZocText.h3()),
                            const SizedBox(height: 2),
                            Text(
                                'Registro das ${DateFormat('HH:mm').format(_openedAt)} · fecha sozinho em $closesIn',
                                style:
                                    ZocText.caption().copyWith(fontSize: 12.5)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Atualizar clientes e projetos',
                        constraints: const BoxConstraints.tightFor(
                            width: 32, height: 32),
                        padding: EdgeInsets.zero,
                        onPressed: _refreshing ? null : _refreshOptions,
                        icon: _refreshing
                            ? const SizedBox.square(
                                dimension: 17,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: ZocColors.brand))
                            : const Icon(Icons.refresh_rounded,
                                color: ZocColors.muted, size: 20),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ZocCard(
                      child: Form(
                        key: _model.formKey,
                        autovalidateMode: AutovalidateMode.always,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ZocSelect<String>(
                              label: 'Cliente',
                              dropDownKey: const ValueKey('popup-client'),
                              icon: Icons.business_outlined,
                              hintText: 'Escolha o cliente',
                              isSearchable: true,
                              controller:
                                  _model.clientDropDownValueController ??=
                                      FormFieldController<String>(null),
                              options: FFAppState()
                                  .clientsOptions
                                  .map((client) => client.id)
                                  .toList(),
                              optionLabels: FFAppState()
                                  .clientsOptions
                                  .map((client) => client.name)
                                  .toList(),
                              onChanged: (value) {
                                _model.clientDropDownValue = value;
                                _model.selectedClient = value;
                                _model.dropdownprojetosValue = null;
                                _model.selectedProjects = null;
                                _model.dropdownprojetosValueController?.value =
                                    null;
                                _model.dropdownatividadesValue = null;
                                _model.dropdownatividadesValueController
                                    ?.value = null;
                                FFAppState().taskOptions = [];
                                safeSetState(() {});
                              },
                            ),
                            const SizedBox(height: 11),
                            ZocSelect<String>(
                              label: 'Projeto',
                              dropDownKey: const ValueKey('popup-project'),
                              icon: Icons.work_outline_rounded,
                              hintText: 'Escolha o projeto',
                              isSearchable: true,
                              disabled: _model.selectedClient == null,
                              controller:
                                  _model.dropdownprojetosValueController ??=
                                      FormFieldController<String>(null),
                              options: projects
                                  .map((project) => project.id)
                                  .toList(),
                              optionLabels: projects
                                  .map((project) => project.name)
                                  .toList(),
                              onChanged: (value) async {
                                _model.dropdownprojetosValue = value;
                                _model.selectedProjects = value;
                                _model.dropdownatividadesValue = null;
                                _model.dropdownatividadesValueController
                                    ?.value = null;
                                FFAppState().taskOptions = [];
                                safeSetState(() {});
                                _model.activities =
                                    await GetAtivitiesByProjectCall.call(
                                  token: currentAuthenticationToken,
                                  id: _model.selectedProjects,
                                );
                                if (!mounted) return;
                                if (_model.activities?.succeeded ?? true) {
                                  FFAppState().taskOptions = (_model
                                              .activities?.jsonBody is List
                                          ? _model.activities!.jsonBody as List
                                          : const [])
                                      .toList()
                                      .cast<dynamic>();
                                }
                                safeSetState(() {});
                              },
                            ),
                            const SizedBox(height: 11),
                            _activitiesField(),
                            const SizedBox(height: 11),
                            ZocTextField(
                              label: 'Notas (opcional)',
                              hintText: 'Algo que ajude a lembrar depois...',
                              controller: _model.textController,
                              focusNode: _model.textFieldFocusNode,
                              maxLines: 2,
                              validator: _model.textControllerValidator
                                  .asValidator(context),
                            ),
                            const SizedBox(height: 11),
                            ZocToggleRow(
                              title: 'Trabalho remoto',
                              help: 'Hoje estou fora do escritório',
                              value: FFAppState().isRemote,
                              onChanged: (value) => FFAppState()
                                  .update(() => FFAppState().isRemote = value),
                            ),
                            const SizedBox(height: 11),
                            Row(
                              children: [
                                const Icon(Icons.camera_alt_outlined,
                                    size: 15, color: ZocColors.brand),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                      hasScreenshot
                                          ? 'Captura de tela será anexada'
                                          : areScreenshotsEnabled()
                                              ? 'Sem captura de tela neste registro'
                                              : 'Captura de tela desativada',
                                      style: ZocText.caption()),
                                ),
                                if (_screenshotBytes != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.memory(
                                      _screenshotBytes!,
                                      width: 54,
                                      height: 32,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const SizedBox(width: 54, height: 32),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ZocButton('Ignorar',
                          variant: ZocButtonVariant.ghost,
                          onPressed: _saving ? null : _onIgnoreTimeout),
                      ZocButton('Salvar registro',
                          icon: Icons.check_rounded,
                          loading: _saving,
                          onPressed: _saveRecord),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
