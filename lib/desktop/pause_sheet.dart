import 'dart:async';

import 'package:flutter/material.dart';

import '/ui/zoc_ui.dart';
import 'pause_controller.dart';
import 'popup_window.dart';

/// Amber of the pause UI (mockup `--amber`), on top of [ZocColors.warn*].
abstract final class PauseColors {
  static const amber = Color(0xFFF59E0B);
  static const deep = ZocColors.warn;
  static const soft = ZocColors.warnSoft;
  static const surface = ZocColors.warnSurface;
  static const ink = ZocColors.warnInk;
  static const ink2 = Color(0xFF78350F);
}

/// Opens "Pausar registros" in the popup-size window. Returns the result of
/// the pause call, or null when the user cancels. A network error closes the
/// sheet with a "Sem conexão" snackbar and the app stays unpaused.
Future<PauseActionResult?> showPauseSheet(
  BuildContext context, {
  PauseController? controller,
  bool resizeWindow = true,
}) async {
  final pauses = controller ?? PauseController.instance;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (resizeWindow) await showDesktopWindowForSheet();
  if (!context.mounted) return null;
  final result = await showModalBottomSheet<PauseActionResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: ZocColors.scrim,
    builder: (_) => PauseSheet(controller: pauses),
  );
  if (resizeWindow) await resetDesktopWindowSize();
  if (result != null && result != PauseActionResult.ok) {
    messenger?.showSnackBar(SnackBar(content: Text(pauseErrorMessage(result))));
  }
  return result;
}

/// Snackbar copy for a failed pause action.
String pauseErrorMessage(PauseActionResult result) => switch (result) {
      PauseActionResult.network => 'Sem conexão, tente de novo.',
      PauseActionResult.unavailable =>
        'A pausa ainda não está disponível no servidor.',
      _ => 'Não foi possível pausar. Tente de novo.',
    };

enum _Choice { m15, m30, h1, custom, open }

class PauseSheet extends StatefulWidget {
  const PauseSheet({super.key, required this.controller});

  final PauseController controller;

  @override
  State<PauseSheet> createState() => _PauseSheetState();
}

class _PauseSheetState extends State<PauseSheet> {
  _Choice _choice = _Choice.m15;
  int _customHours = 1;
  int _customMinutes = 30;
  String? _reason;
  bool _sending = false;
  Timer? _clockTimer;

  static const _minuteStep = 5;

  @override
  void initState() {
    super.initState();
    // Keeps the "até HH:MM" hints current while the sheet is open.
    _clockTimer = Timer.periodic(
        const Duration(seconds: 15), (_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  int? get _minutes => switch (_choice) {
        _Choice.m15 => 15,
        _Choice.m30 => 30,
        _Choice.h1 => 60,
        _Choice.custom => _customHours * 60 + _customMinutes,
        _Choice.open => null,
      };

  String _until(int minutes) =>
      pauseClock(widget.controller.now().add(Duration(minutes: minutes)));

  Future<void> _submit() async {
    setState(() => _sending = true);
    final result =
        await widget.controller.startPause(minutes: _minutes, reason: _reason);
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  void _stepHours(int delta) => setState(() {
        _customHours = (_customHours + delta).clamp(0, kMaxPauseMinutes ~/ 60);
        if (_customHours * 60 + _customMinutes > kMaxPauseMinutes) {
          _customMinutes = 0;
        }
        if (_customHours == 0 && _customMinutes == 0) {
          _customMinutes = _minuteStep;
        }
      });

  void _stepMinutes(int delta) => setState(() {
        _customMinutes = (_customMinutes + delta * _minuteStep).clamp(0, 55);
      });

  @override
  Widget build(BuildContext context) {
    final total = _customHours * 60 + _customMinutes;
    final minutes = _minutes;
    return Container(
      decoration: const BoxDecoration(
        color: ZocColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
              color: Color(0x59101827),
              offset: Offset(0, -12),
              blurRadius: 40,
              spreadRadius: -12),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const PauseIconBadge(size: 40),
                const SizedBox(width: 12),
                Expanded(child: Text('Pausar registros', style: ZocText.h2())),
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded,
                      size: 20, color: ZocColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Enquanto estiver em pausa, o ZOC não abre o registro e esse '
              'tempo não conta como trabalho.',
              style: ZocText.sub(),
            ),
            const SizedBox(height: 12),
            _option(_Choice.m15, '15 min', meta: 'até ${_until(15)}'),
            _option(_Choice.m30, '30 min', meta: 'até ${_until(30)}'),
            _option(_Choice.h1, '1 hora', meta: 'até ${_until(60)}'),
            _option(
              _Choice.custom,
              'Personalizado',
              help: _choice == _Choice.custom ? 'Até 8 h' : null,
              meta: _choice == _Choice.custom ? null : 'até 8 h',
              trailing: _choice == _Choice.custom
                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                      _Stepper(
                        key: const ValueKey('pause-hours'),
                        value: '$_customHours',
                        unit: 'h',
                        onMinus: _customHours > 0 ? () => _stepHours(-1) : null,
                        onPlus: _customHours < kMaxPauseMinutes ~/ 60
                            ? () => _stepHours(1)
                            : null,
                      ),
                      const SizedBox(width: 6),
                      _Stepper(
                        key: const ValueKey('pause-minutes'),
                        value: '$_customMinutes',
                        unit: 'min',
                        onMinus: _customMinutes > 0 &&
                                total - _minuteStep >= _minuteStep
                            ? () => _stepMinutes(-1)
                            : null,
                        onPlus: _customMinutes < 55 &&
                                total + _minuteStep <= kMaxPauseMinutes
                            ? () => _stepMinutes(1)
                            : null,
                      ),
                    ])
                  : null,
            ),
            _option(_Choice.open, 'Até eu voltar',
                help: 'Sem horário. Você retoma manualmente.', last: true),
            const SizedBox(height: 14),
            Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'Motivo '),
                  TextSpan(
                      text: '(opcional)',
                      style: ZocText.label(color: ZocColors.faint)
                          .copyWith(fontWeight: FontWeight.w500)),
                ]),
                style: ZocText.label()),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final entry in kPauseReasons.entries)
                  _ReasonChip(
                    label: entry.value,
                    selected: _reason == entry.key,
                    onTap: () => setState(() =>
                        _reason = _reason == entry.key ? null : entry.key),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1, color: ZocColors.line),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                    minutes == null
                        ? Icons.all_inclusive_rounded
                        : Icons.schedule_rounded,
                    size: 15,
                    color: ZocColors.brand),
                const SizedBox(width: 6),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: minutes == null
                          ? const [TextSpan(text: 'Sem horário de volta')]
                          : [
                              const TextSpan(text: 'Volta prevista às  '),
                              TextSpan(
                                  text: _until(minutes),
                                  style: ZocText.body(weight: FontWeight.w600)
                                      .copyWith(fontSize: 13)),
                            ],
                    ),
                    style: ZocText.sub().copyWith(fontSize: 13),
                  ),
                ),
                ZocButton('Cancelar',
                    variant: ZocButtonVariant.ghost,
                    onPressed:
                        _sending ? null : () => Navigator.of(context).pop()),
                const SizedBox(width: 6),
                ZocButton('Pausar',
                    icon: Icons.pause_rounded,
                    loading: _sending,
                    onPressed: _submit),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _option(_Choice choice, String title,
      {String? help, String? meta, Widget? trailing, bool last = false}) {
    final on = _choice == choice;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 6),
      child: Semantics(
        selected: on,
        button: true,
        label: title,
        child: Material(
          color: on ? ZocColors.brandSoft : ZocColors.listFill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ZocRadii.item),
            side: on
                ? const BorderSide(color: ZocColors.brand, width: 1.5)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('pause-option-${choice.name}'),
            onTap: _sending ? null : () => setState(() => _choice = choice),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 46),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    _Radio(on: on),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: ZocText.body(weight: FontWeight.w600)),
                          if (help != null) ...[
                            const SizedBox(height: 2),
                            Text(help, style: ZocText.caption()),
                          ],
                        ],
                      ),
                    ),
                    if (trailing != null) trailing,
                    if (meta != null)
                      Text(meta,
                          style: ZocText.caption(
                              color: on ? ZocColors.brandInk : ZocColors.faint,
                              weight: FontWeight.w500)),
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

/// Amber circle with the pause glyph (sheet header, paused card).
class PauseIconBadge extends StatelessWidget {
  const PauseIconBadge({super.key, this.size = 40, this.solid = false});

  final double size;

  /// Solid amber with a white glyph (paused card) instead of the soft tint.
  final bool solid;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: solid ? PauseColors.amber : PauseColors.soft,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.pause_rounded,
            size: size * .48, color: solid ? Colors.white : PauseColors.deep),
      );
}

class _Radio extends StatelessWidget {
  const _Radio({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) => Container(
        width: 18,
        height: 18,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ZocColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
              color: on ? ZocColors.brand : ZocColors.control, width: 1.5),
        ),
        child: on
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: ZocColors.brand, shape: BoxShape.circle),
              )
            : null,
      );
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    super.key,
    required this.value,
    required this.unit,
    required this.onMinus,
    required this.onPlus,
  });

  final String value;
  final String unit;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) => Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: ZocColors.surface,
          borderRadius: BorderRadius.circular(ZocRadii.pill),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0F101827), offset: Offset(0, 1), blurRadius: 2)
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepButton(
                icon: Icons.remove_rounded,
                tooltip: 'Menos $unit',
                onTap: onMinus),
            SizedBox(
              width: 52,
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: value),
                  TextSpan(
                      text: ' $unit',
                      style: ZocText.caption(weight: FontWeight.w500)),
                ]),
                textAlign: TextAlign.center,
                style: ZocText.body(weight: FontWeight.w600).copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ),
            _StepButton(
                icon: Icons.add_rounded, tooltip: 'Mais $unit', onTap: onPlus),
          ],
        ),
      );
}

class _StepButton extends StatelessWidget {
  const _StepButton(
      {required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Material(
          color: onTap == null ? ZocColors.inputFill : ZocColors.brandSoft,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox.square(
              dimension: 28,
              child: Icon(icon,
                  size: 16,
                  color: onTap == null ? ZocColors.faint : ZocColors.brand),
            ),
          ),
        ),
      );
}

class _ReasonChip extends StatelessWidget {
  const _ReasonChip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? ZocColors.brand : ZocColors.inputFill,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected) ...[
                    const Icon(Icons.check_rounded,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                  ],
                  Text(label,
                      style: ZocText.body(
                              color: selected ? Colors.white : ZocColors.text,
                              weight:
                                  selected ? FontWeight.w600 : FontWeight.w500)
                          .copyWith(fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
      );
}
