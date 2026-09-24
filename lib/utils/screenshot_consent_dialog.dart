import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/custom_auth/auth_util.dart';
import '/backend/api_requests/api_manager.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

Future<bool> showScreenshotConsentDialog(BuildContext context) async {
  final approved = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(
          'Capturas de tela',
          style: FlutterFlowTheme.of(dialogContext).titleMedium.override(
                font: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
                color: const Color(0xFF101827),
                letterSpacing: 0.0,
              ),
        ),
        content: Text(
          'Durante o uso do ZOC, serão feitas capturas de tela periodicamente '
          'para monitoramento de produtividade.\n\n'
          'Se você não aprovar, não será possível continuar e a sessão será encerrada.',
          style: FlutterFlowTheme.of(dialogContext).bodyMedium.override(
                font: GoogleFonts.inter(),
                color: const Color(0xFF101827),
                fontSize: 14.0,
                letterSpacing: 0.0,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Não aprovo',
              style: GoogleFonts.inter(
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F8F8A),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Aprovar',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    },
  );

  return approved == true;
}

Future<void> denyScreenshotConsentAndLogout(BuildContext context) async {
  GoRouter.of(context).prepareAuthEvent();
  await authManager.signOut();
  GoRouter.of(context).clearRedirectLocation();
  ApiManager.syncAccessToken(null);

  FFAppState().UserData = null;
  FFAppState().email = '';
  FFAppState().emailData = null;
  FFAppState().password = '';
  FFAppState().isPopupVisible = false;
  FFAppState().dataSave = [];

  if (!context.mounted) return;
  context.goNamed(LoginWidget.routeName);
}
