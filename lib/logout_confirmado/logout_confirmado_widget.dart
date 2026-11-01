import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/ui/zoc_ui.dart';
import 'package:flutter/material.dart';
import 'logout_confirmado_model.dart';
export 'logout_confirmado_model.dart';

class LogoutConfirmadoWidget extends StatefulWidget {
  const LogoutConfirmadoWidget({super.key});

  static String routeName = 'LogoutConfirmado';
  static String routePath = '/logoutConfirmado';

  @override
  State<LogoutConfirmadoWidget> createState() => _LogoutConfirmadoWidgetState();
}

class _LogoutConfirmadoWidgetState extends State<LogoutConfirmadoWidget> {
  late LogoutConfirmadoModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LogoutConfirmadoModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ZocAuthScaffold(
        scaffoldKey: scaffoldKey,
        center: true,
        body: Column(mainAxisSize: MainAxisSize.min, children: [
          const ZocHeroIcon(Icons.check_circle_outline_rounded,
              tone: ZocTone.success),
          const SizedBox(height: 14),
          const ZocTitle('Sessão encerrada',
              subtitle: 'Até logo! Quando quiser voltar, é só entrar de novo.',
              center: true),
          const SizedBox(height: 18),
          ZocButton('Entrar novamente',
              expanded: true,
              onPressed: () => context.pushNamed(LoginWidget.routeName)),
        ]),
      );
}
