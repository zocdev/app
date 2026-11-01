import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'mensaje_antes_expediente_model.dart';
import '/ui/zoc_ui.dart';
export 'mensaje_antes_expediente_model.dart';

class MensajeAntesExpedienteWidget extends StatefulWidget {
  const MensajeAntesExpedienteWidget({super.key});

  static String routeName = 'MensajeAntesExpediente';
  static String routePath = '/mensajeAntesExpediente';

  @override
  State<MensajeAntesExpedienteWidget> createState() =>
      _MensajeAntesExpedienteWidgetState();
}

class _MensajeAntesExpedienteWidgetState
    extends State<MensajeAntesExpedienteWidget> {
  late MensajeAntesExpedienteModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MensajeAntesExpedienteModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ZocAuthScaffold(
      scaffoldKey: scaffoldKey,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ZocTitle(
            'Como o ZOC funciona',
            subtitle:
                'Durante o expediente, vamos perguntar de vez em quando no que você está trabalhando.',
          ),
          const SizedBox(height: 12),
          const _Step(
            icon: Icons.timer_outlined,
            title: 'Lembretes periódicos',
            help: 'Um aviso curto aparece a cada intervalo definido pela empresa.',
          ),
          const SizedBox(height: 8),
          const _Step(
            icon: Icons.checklist_rounded,
            title: 'Escolha a atividade',
            help: 'Cliente, projeto e tarefa em poucos cliques.',
          ),
          const SizedBox(height: 8),
          const _Step(
            icon: Icons.shield_outlined,
            title: 'Seus dados protegidos',
            help: 'As informações servem para organizar o trabalho do time.',
          ),
          const SizedBox(height: 14),
          ZocButton(
            'Entendi, começar',
            expanded: true,
            onPressed: () async {
              context.pushNamed(LogoutWidget.routeName);
            },
          ),
        ],
      ),
    );
  }
}

/// Explained step row (soft fill, radius 16, teal icon + title + help).
class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.title, required this.help});

  final IconData icon;
  final String title;
  final String help;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: ZocColors.listFill,
          borderRadius: BorderRadius.circular(ZocRadii.item),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 18, color: ZocColors.brand),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: ZocText.strong()),
                  const SizedBox(height: 2),
                  Text(help, style: ZocText.caption()),
                ],
              ),
            ),
          ],
        ),
      );
}
