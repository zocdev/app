import 'package:flutter/material.dart';

import '/ui/zoc_ui.dart';
import 'pause_controller.dart';
import 'pause_sheet.dart' show PauseColors;

/// What the user answered in "Sua pausa terminou. Já voltou?".
enum PauseReturnChoice {
  /// "Sim, voltei": the pause is closed on the server.
  resumed,

  /// "Mais 15 min" / "Mais 30 min": the pause was extended.
  extended,

  /// "Encerrar expediente": go to the logout confirmation.
  endDay,
}

/// Shows the return dialog over the ZOC scrim. It cannot be dismissed
/// without an answer; API calls happen inside and a failure stays on screen.
Future<PauseReturnChoice?> showPauseReturnDialog(
  BuildContext context, {
  PauseController? controller,
}) =>
    showZocModal<PauseReturnChoice>(
      context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: PauseReturnDialog(
            controller: controller ?? PauseController.instance),
      ),
    );

/// "Pausa de 30 min · 12:15–12:45 · Almoço".
String pauseSummary(PresencePause pause) {
  final end = pause.plannedEndAt;
  return [
    if (pause.planned != null) 'Pausa de ${pauseDurationLabel(pause.planned!)}',
    if (end != null)
      '${pauseClock(pause.startedAt)}–${pauseClock(end)}'
    else
      'desde ${pauseClock(pause.startedAt)}',
    if (pause.reasonLabel != null) pause.reasonLabel!,
  ].join(' · ');
}

class PauseReturnDialog extends StatefulWidget {
  const PauseReturnDialog({super.key, required this.controller});

  final PauseController controller;

  @override
  State<PauseReturnDialog> createState() => _PauseReturnDialogState();
}

class _PauseReturnDialogState extends State<PauseReturnDialog> {
  String? _pending;
  String? _error;

  Future<void> _run(String key, Future<PauseActionResult> Function() call,
      PauseReturnChoice choice) async {
    setState(() {
      _pending = key;
      _error = null;
    });
    final result = await call();
    if (!mounted) return;
    // "unavailable" means the API dropped the feature: nothing is paused.
    if (result == PauseActionResult.ok ||
        result == PauseActionResult.unavailable) {
      Navigator.of(context).pop(choice);
      return;
    }
    setState(() {
      _pending = null;
      _error = result == PauseActionResult.network
          ? 'Sem conexão, tente de novo.'
          : 'Não foi possível concluir. Tente de novo.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final pause = widget.controller.pause;
    final busy = _pending != null;
    return ZocModal(
      width: 420,
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: PauseColors.amber.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                  color: PauseColors.soft, shape: BoxShape.circle),
              child: const Icon(Icons.alarm_rounded,
                  size: 28, color: PauseColors.deep),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: PauseColors.soft,
              borderRadius: BorderRadius.circular(ZocRadii.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pause_rounded,
                    size: 13, color: PauseColors.ink),
                const SizedBox(width: 6),
                Text('Sua pausa terminou',
                    style: ZocText.label(color: PauseColors.ink)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text('Já voltou?',
              textAlign: TextAlign.center,
              style: ZocText.title().copyWith(fontSize: 26)),
          if (pause != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 14, color: ZocColors.faint),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(pauseSummary(pause),
                      style: ZocText.sub().copyWith(fontSize: 13)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          ZocButton(
            'Sim, voltei',
            expanded: true,
            icon: Icons.check_rounded,
            loading: _pending == 'resume',
            onPressed: busy
                ? null
                : () => _run('resume', widget.controller.resume,
                    PauseReturnChoice.resumed),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final minutes in const [15, 30]) ...[
                if (minutes == 30) const SizedBox(width: 10),
                Expanded(
                  child: ZocButton(
                    'Mais $minutes min',
                    expanded: true,
                    variant: ZocButtonVariant.secondary,
                    icon: Icons.add_rounded,
                    loading: _pending == 'extend$minutes',
                    onPressed: busy
                        ? null
                        : () => _run(
                            'extend$minutes',
                            () => widget.controller.extend(minutes),
                            PauseReturnChoice.extended),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: busy
                ? null
                : () => Navigator.of(context).pop(PauseReturnChoice.endDay),
            icon: const Icon(Icons.power_settings_new_rounded, size: 15),
            label: const Text('Encerrar expediente'),
            style: TextButton.styleFrom(
              foregroundColor: ZocColors.muted,
              textStyle:
                  ZocText.body(weight: FontWeight.w500).copyWith(fontSize: 13),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 4),
            ZocNotice(_error!, kind: ZocNoticeKind.error),
          ],
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: ZocColors.surface2,
              borderRadius: BorderRadius.circular(ZocRadii.input),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(Icons.info_outline_rounded,
                      size: 14, color: ZocColors.faint),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Enquanto não responder, você aparece como em pausa '
                    'para o gestor.',
                    style: ZocText.caption().copyWith(height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
