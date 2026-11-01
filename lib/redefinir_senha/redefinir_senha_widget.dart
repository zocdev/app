import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/ui/zoc_ui.dart';
import 'package:flutter/material.dart';
import '/backend/api_requests/api_calls.dart';
import '/utils/api_error_helper.dart';
import '/utils/error_handler.dart';
import 'redefinir_senha_model.dart';
export 'redefinir_senha_model.dart';

class RedefinirSenhaWidget extends StatefulWidget {
  const RedefinirSenhaWidget({super.key});

  static String routeName = 'RedefinirSenha';
  static String routePath = '/forgot-password';
  static String legacyRoutePath = '/redefinirSenha';

  @override
  State<RedefinirSenhaWidget> createState() => _RedefinirSenhaWidgetState();
}

class _RedefinirSenhaWidgetState extends State<RedefinirSenhaWidget> {
  late RedefinirSenhaModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RedefinirSenhaModel());

    _model.emailTextController ??= TextEditingController();
    _model.emailFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<void> _send() async {
    if (_model.formKey.currentState == null ||
        !_model.formKey.currentState!.validate()) {
      return;
    }
    final email = _model.emailTextController.text.trim();
    final response = await ForgotPasswordCall.call(email: email);
    if (!mounted) return;
    if (response.succeeded) {
      FFAppState().email = email;
      context.pushNamed(EmailEnviadoWidget.routeName);
      return;
    }
    final error = response.toAppError();
    if (error != null && context.mounted) {
      ErrorHandler().handleError(context, error, showSnackbar: true);
    }
  }

  @override
  Widget build(BuildContext context) => ZocAuthScaffold(
        scaffoldKey: scaffoldKey,
        topAction: IconButton(
            onPressed: () => context.pushNamed(EntrarConSenhaWidget.routeName),
            icon: const Icon(Icons.close_rounded, color: ZocColors.muted),
            tooltip: 'Voltar ao login'),
        body: Form(
            key: _model.formKey,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ZocTitle('Redefinir senha',
                      subtitle:
                          'Informe seu e-mail e enviaremos um link para criar uma nova senha.'),
                  const SizedBox(height: 14),
                  ZocTextField(
                      label: 'E-mail',
                      hintText: 'seu@email.com',
                      icon: Icons.mail_outline_rounded,
                      controller: _model.emailTextController,
                      focusNode: _model.emailFocusNode,
                      keyboardType: TextInputType.emailAddress,
                      validator: _model.emailTextControllerValidator
                          .asValidator(context)),
                  const SizedBox(height: 14),
                  ZocButton('Enviar link',
                      icon: Icons.arrow_forward_rounded,
                      expanded: true,
                      onPressed: _send),
                  const SizedBox(height: 12),
                  Center(
                      child: InkWell(
                          onTap: () =>
                              context.pushNamed(EntrarConSenhaWidget.routeName),
                          child: Text('← Voltar ao login',
                              style: ZocText.link()))),
                ])),
      );
}
