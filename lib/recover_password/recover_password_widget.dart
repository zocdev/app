import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/ui/zoc_ui.dart';
import 'package:flutter/material.dart';
import '/backend/api_requests/api_calls.dart';
import '/utils/api_client_exception.dart';
import '/utils/api_error_helper.dart';
import '/utils/error_handler.dart';
import 'package:flutter/foundation.dart';
import 'recover_password_model.dart';
export 'recover_password_model.dart';

class RecoverPasswordWidget extends StatefulWidget {
  const RecoverPasswordWidget({
    super.key,
    this.token,
  });

  final String? token;

  static String routeName = 'RecoverPassword';
  static String routePath = '/recover-password';

  @override
  State<RecoverPasswordWidget> createState() => _RecoverPasswordWidgetState();
}

class _RecoverPasswordWidgetState extends State<RecoverPasswordWidget> {
  late RecoverPasswordModel _model;
  late String _token;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RecoverPasswordModel());
    _token = widget.token?.trim() ?? '';

    _model.passwordTextController ??= TextEditingController();
    _model.passwordFocusNode ??= FocusNode();
    _model.confirmPasswordTextController ??= TextEditingController();
    _model.confirmPasswordFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_token.isEmpty && !kDebugMode) {
        safeSetState(() {
          _model.tokenMissingMessage =
              'Link de redefinição inválido. Solicite um novo.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Link de redefinição inválido ou expirado. Solicite um novo.',
            ),
          ),
        );
        context.goNamed(RedefinirSenhaWidget.routeName);
      }
    });
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_model.resetSucceeded) return;

    if (_token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Token ausente. Cole o token do link ou solicite um novo e-mail.',
          ),
        ),
      );
      return;
    }

    if (_model.formKey.currentState == null ||
        !_model.formKey.currentState!.validate()) {
      return;
    }

    final response = await ResetPasswordCall.call(
      token: _token,
      password: _model.passwordTextController.text,
    );

    if (!mounted) return;

    if (response.succeeded) {
      safeSetState(() {
        _model.resetSucceeded = true;
      });
      context.goNamed(SenhaAlteradaWidget.routeName);
      return;
    }

    try {
      response.throwIfFailed();
    } on ApiClientException catch (e) {
      if (e.isUnauthorized) {
        ErrorHandler().handleError(
          context,
          AppError(
            type: ErrorType.authentication,
            message: e.message,
            userMessage:
                'Este link de redefinição é inválido ou expirou. Solicite um novo.',
            statusCode: e.statusCode,
          ),
          showSnackbar: true,
        );
        return;
      }

      ErrorHandler().handleError(
        context,
        AppError.fromApiResponse(e.statusCode, e.message),
        showSnackbar: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formEnabled =
        !_model.resetSucceeded && (_token.isNotEmpty || kDebugMode);
    return ZocAuthScaffold(
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
                const ZocTitle('Nova senha',
                    subtitle: 'Defina uma nova senha para sua conta.'),
                if (_model.tokenMissingMessage != null) ...[
                  const SizedBox(height: 10),
                  ZocNotice(_model.tokenMissingMessage!,
                      kind: ZocNoticeKind.error),
                ],
                if (kDebugMode && _token.isEmpty) ...[
                  const SizedBox(height: 12),
                  ZocTextField(
                      label: 'Token (debug)',
                      hintText: 'Cole o token do e-mail',
                      onChanged: (value) {
                        _token = value.trim();
                      }),
                ],
                const SizedBox(height: 14),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                      child: ZocTextField(
                          label: 'Nova senha',
                          icon: Icons.lock_outline_rounded,
                          password: true,
                          enabled: formEnabled,
                          controller: _model.passwordTextController,
                          focusNode: _model.passwordFocusNode,
                          validator: _model.passwordTextControllerValidator
                              .asValidator(context))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: ZocTextField(
                          label: 'Confirmar senha',
                          icon: Icons.lock_outline_rounded,
                          password: true,
                          enabled: formEnabled,
                          controller: _model.confirmPasswordTextController,
                          focusNode: _model.confirmPasswordFocusNode,
                          validator: _model
                              .confirmPasswordTextControllerValidator
                              .asValidator(context))),
                ]),
                const SizedBox(height: 14),
                ZocButton('Redefinir senha',
                    expanded: true, onPressed: formEnabled ? _submit : null),
                const SizedBox(height: 12),
                Center(
                    child: InkWell(
                        onTap: () =>
                            context.pushNamed(EntrarConSenhaWidget.routeName),
                        child: Text('Voltar ao login', style: ZocText.link()))),
              ])),
    );
  }
}
