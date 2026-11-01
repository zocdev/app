import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'final_registration_model.dart';
import '/ui/zoc_ui.dart';
export 'final_registration_model.dart';

class FinalRegistrationWidget extends StatefulWidget {
  const FinalRegistrationWidget({super.key});

  static String routeName = 'FinalRegistration';
  static String routePath = '/finalRegistration';

  @override
  State<FinalRegistrationWidget> createState() =>
      _FinalRegistrationWidgetState();
}

class _FinalRegistrationWidgetState extends State<FinalRegistrationWidget> {
  late FinalRegistrationModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FinalRegistrationModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: ZocAuthScaffold(
        scaffoldKey: scaffoldKey,
        center: true,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: ZocHeroIcon(Icons.auto_awesome_outlined)),
            const SizedBox(height: 10),
            const ZocTitle(
              'Informações adicionadas',
              center: true,
              subtitle:
                  'Seu cadastro está completo. Você já pode começar o expediente.',
            ),
            const SizedBox(height: 16),
            ZocButton(
              'Começar',
              icon: Icons.play_arrow_outlined,
              expanded: true,
              onPressed: () async {
                context.pushNamed(VerifyTokenWidget.routeName);
              },
            ),
          ],
        ),
      ),
    );
  }
}
