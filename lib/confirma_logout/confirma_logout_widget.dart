import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/ui/zoc_ui.dart';
import 'package:flutter/material.dart';
import '/auth/auth_session.dart';
import 'confirma_logout_model.dart';
export 'confirma_logout_model.dart';

class ConfirmaLogoutWidget extends StatefulWidget {
  const ConfirmaLogoutWidget({super.key});

  static String routeName = 'ConfirmaLogout';
  static String routePath = '/confirmaLogout';

  @override
  State<ConfirmaLogoutWidget> createState() => _ConfirmaLogoutWidgetState();
}

class _ConfirmaLogoutWidgetState extends State<ConfirmaLogoutWidget> {
  late ConfirmaLogoutModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ConfirmaLogoutModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<void> _logout() async {
    GoRouter.of(context).prepareAuthEvent();
    await AuthSession.logout();
    if (!mounted) return;
    GoRouter.of(context).clearRedirectLocation();
    context.goNamedAuth(LogoutConfirmadoWidget.routeName, context.mounted);
    FFAppState().UserData = null;
    FFAppState().dataSave = [];
    safeSetState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        key: scaffoldKey,
        body: ZocBackground(
            child: Stack(children: [
          const Positioned(left: 32, top: 18, child: ZocWordmark()),
          const Positioned.fill(child: ColoredBox(color: ZocColors.scrim)),
          Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                  width: 412,
                  child: ZocModal(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const ZocHeroIcon(Icons.logout_rounded,
                        tone: ZocTone.danger),
                    const SizedBox(height: 14),
                    const ZocTitle('Encerrar sessão?',
                        center: true,
                        small: true,
                        subtitle:
                            'O monitoramento será pausado até você entrar novamente.'),
                    const SizedBox(height: 18),
                    Row(children: [
                      Expanded(
                          child: ZocButton('Cancelar',
                              variant: ZocButtonVariant.secondary,
                              expanded: true,
                              onPressed: () => context.safePop())),
                      const SizedBox(width: 10),
                      Expanded(
                          child: ZocButton('Sair',
                              variant: ZocButtonVariant.danger,
                              expanded: true,
                              onPressed: _logout)),
                    ]),
                  ])))),
        ])),
      );
}
