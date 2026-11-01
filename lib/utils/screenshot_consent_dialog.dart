import 'package:flutter/material.dart';

import '/auth/auth_session.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/ui/zoc_ui.dart';
import '/utils/capture_screenshot.dart';

Future<bool> showScreenshotConsentDialog(
  BuildContext context, {
  bool? screenshotsEnabled,
}) async {
  if (!areScreenshotsEnabled(override: screenshotsEnabled)) {
    return true;
  }

  final approved = await showZocModal<bool>(
    context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      child: ZocModal(
        width: 420,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ZocHeroIcon(Icons.photo_camera_outlined),
            const SizedBox(height: 14),
            const ZocTitle(
              'Capturas de tela',
              subtitle: 'Durante o expediente, o ZOC tira capturas de tela '
                  'periodicamente para acompanhar a produtividade.',
              center: true,
              small: true,
            ),
            const SizedBox(height: 14),
            const ZocNotice(
              'Sem a sua aprovação não é possível continuar e a sessão '
              'será encerrada.',
              kind: ZocNoticeKind.warn,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ZocButton(
                    'Não aprovo',
                    variant: ZocButtonVariant.secondary,
                    expanded: true,
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ZocButton(
                    'Aprovar',
                    expanded: true,
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  return approved == true;
}

Future<void> denyScreenshotConsentAndLogout(BuildContext context) async {
  GoRouter.of(context).prepareAuthEvent();
  await AuthSession.logout();
  GoRouter.of(context).clearRedirectLocation();

  FFAppState().UserData = null;
  FFAppState().email = '';
  FFAppState().emailData = null;
  FFAppState().password = '';
  FFAppState().isPopupVisible = false;
  FFAppState().dataSave = [];

  if (!context.mounted) return;
  context.goNamed(LoginWidget.routeName);
}
