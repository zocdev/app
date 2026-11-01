import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_updater.dart';
import '/ui/zoc_ui.dart';

Future<void> checkAndPromptDesktopUpdate({
  required BuildContext context,
  bool silentIfNone = true,
}) async {
  if (!AppUpdater.isDesktopSupported) return;

  final update = await AppUpdater.checkForUpdate();
  if (update == null) {
    if (!silentIfNone && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você já está na versão mais recente.')),
      );
    }
    return;
  }

  if (!context.mounted) return;

  final accepted = await showZocModal<bool>(
    context,
    builder: (ctx) => ZocModal(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ZocHeroIcon(Icons.download_rounded),
        const SizedBox(height: 14),
        ZocTitle('Atualização disponível',
            center: true,
            small: true,
            subtitle: 'A versão ${update.version} está pronta para instalar.'),
        if (update.notes != null && update.notes!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 100),
              child: SingleChildScrollView(
                  child: Text(update.notes!, style: ZocText.sub()))),
        ],
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
              child: ZocButton('Depois',
                  expanded: true,
                  variant: ZocButtonVariant.secondary,
                  onPressed: () => Navigator.of(ctx).pop(false))),
          const SizedBox(width: 10),
          Expanded(
              child: ZocButton('Atualizar',
                  expanded: true,
                  icon: Icons.refresh_rounded,
                  onPressed: () => Navigator.of(ctx).pop(true))),
        ]),
      ],
    )),
  );

  if (accepted != true || !context.mounted) return;

  showZocModal<void>(
    context,
    barrierDismissible: false,
    builder: (_) => ZocModal(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const ZocHeroIcon(Icons.download_rounded),
        const SizedBox(height: 14),
        const ZocTitle('Baixando atualização...', center: true, small: true),
        const SizedBox(height: 18),
        const LinearProgressIndicator(
            color: ZocColors.brand, backgroundColor: ZocColors.brandSoft),
      ]),
    ),
  );

  try {
    await AppUpdater.downloadAndApply(update);
  } catch (e) {
    if (kDebugMode) {
      print('Update apply failed: $e');
    }
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao atualizar: $e')),
      );
    }
  }
}
