import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/ui/zoc_ui.dart';
import 'package:flutter/material.dart';
import 'senha_alterada_model.dart';
export 'senha_alterada_model.dart';

class SenhaAlteradaWidget extends StatefulWidget {
  const SenhaAlteradaWidget({super.key});

  static String routeName = 'senhaAlterada';
  static String routePath = '/senhaAlterada';

  @override
  State<SenhaAlteradaWidget> createState() => _SenhaAlteradaWidgetState();
}

class _SenhaAlteradaWidgetState extends State<SenhaAlteradaWidget> {
  late SenhaAlteradaModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SenhaAlteradaModel());

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
          const ZocHeroIcon(Icons.celebration_outlined, tone: ZocTone.success),
          const SizedBox(height: 14),
          const ZocTitle('Senha alterada',
              subtitle: 'Tudo certo! Use a nova senha no próximo acesso.',
              center: true),
          const SizedBox(height: 18),
          ZocButton('Ir para o login',
              expanded: true,
              onPressed: () => context.goNamed(EntrarConSenhaWidget.routeName)),
        ]),
      );
}
