import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_updater.dart';

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

  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      title: const Text('Atualização disponível'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nova versão: ${update.version}'),
          if (update.notes != null && update.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(update.notes!),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Depois'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Atualizar'),
        ),
      ],
    ),
  );

  if (accepted != true || !context.mounted) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 20),
          Expanded(child: Text('Baixando atualização...')),
        ],
      ),
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
