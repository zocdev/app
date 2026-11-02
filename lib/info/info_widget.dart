import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/utils/screenshot_consent_dialog.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'info_model.dart';
export 'info_model.dart';
import '/ui/zoc_ui.dart';

/// First access of an invited member: asks for the activation code e-mailed by
/// `POST /auth/activation-code` together with the new password, so the
/// password is only saved with proof that the person owns the e-mail.
class InfoWidget extends StatefulWidget {
  const InfoWidget({super.key});

  static String routeName = 'info';
  static String routePath = '/info';

  static const resendCooldown = Duration(seconds: 30);
  static const invalidCodeMessage =
      'Código inválido ou expirado. Peça um novo código.';

  @override
  State<InfoWidget> createState() => _InfoWidgetState();
}

class _InfoWidgetState extends State<InfoWidget> {
  bool _passwordsDiffer = false;
  bool _codeSent = false;
  bool _codeSendFailed = false;
  bool _isSendingCode = false;
  bool _isSubmitting = false;
  bool _invalidCode = false;
  int _resendCooldownSeconds = 0;
  Timer? _resendTimer;

  late InfoModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  bool get _canResend =>
      _resendCooldownSeconds <= 0 && !_isSendingCode && !_isSubmitting;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => InfoModel());

    _model.codeTextController ??= TextEditingController();
    _model.codeFocusNode ??= FocusNode();

    _model.emailTextController1 ??=
        TextEditingController(text: FFAppState().email);
    _model.emailFocusNode1 ??= FocusNode();

    _model.textFieldNovaSenhaTextController ??= TextEditingController();
    _model.textFieldNovaSenhaFocusNode ??= FocusNode();

    _model.textFieldConfirmSenhaTextController ??= TextEditingController();
    _model.textFieldConfirmSenhaFocusNode ??= FocusNode();

    _model.emailTextController2 ??=
        TextEditingController(text: FFAppState().email);
    _model.emailFocusNode2 ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      safeSetState(() {});
      _sendActivationCode();
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _model.dispose();

    super.dispose();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    safeSetState(() {
      _resendCooldownSeconds = InfoWidget.resendCooldown.inSeconds;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldownSeconds <= 1) {
        timer.cancel();
        safeSetState(() => _resendCooldownSeconds = 0);
        return;
      }
      safeSetState(() => _resendCooldownSeconds -= 1);
    });
  }

  Future<void> _sendActivationCode() async {
    if (!_canResend) return;

    final email = FFAppState().email;
    if (email.trim().isEmpty) {
      context.goNamed(LoginWidget.routeName);
      return;
    }

    safeSetState(() => _isSendingCode = true);
    try {
      _model.activationCodeResult = await ActivationCodeCall.call(email: email);
      if (!mounted) return;
      final sent = _model.activationCodeResult?.succeeded ?? false;
      safeSetState(() {
        _codeSent = _codeSent || sent;
        _codeSendFailed = !sent;
        if (sent) _invalidCode = false;
      });
      if (sent) _startResendCooldown();
    } finally {
      if (mounted) safeSetState(() => _isSendingCode = false);
    }
  }

  Future<void> _showConsentAndContinue() async {
    bool? screenshotsEnabled;
    final emailData = FFAppState().emailData;
    if (emailData is Map && emailData['screenshots_enabled'] is bool) {
      screenshotsEnabled = emailData['screenshots_enabled'] as bool;
    }
    final approved = await showScreenshotConsentDialog(
      context,
      screenshotsEnabled: screenshotsEnabled,
    );
    if (!mounted) return;
    if (!approved) {
      await denyScreenshotConsentAndLogout(context);
      return;
    }
    context.goNamed(EntrarConSenhaWidget.routeName);
  }

  Future<void> _showError(String message, {String title = 'Atenção'}) {
    return showDialog(
      context: context,
      builder: (alertDialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(alertDialogContext),
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _finish() async {
    if (_isSubmitting) return;
    FFAppState().password = _model.textFieldConfirmSenhaTextController.text;
    safeSetState(() {});
    final code = _model.codeTextController!.text.trim();
    if (!((code != '') &&
        (_model.textFieldNovaSenhaTextController.text != '') &&
        (_model.textFieldConfirmSenhaTextController.text != ''))) {
      await _showError('Todos os campos são requeridos');
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      await _showError('Digite o código de 6 dígitos enviado ao seu e-mail.');
      return;
    }
    final differ = _model.textFieldNovaSenhaTextController.text !=
        _model.textFieldConfirmSenhaTextController.text;
    if (differ != _passwordsDiffer) {
      safeSetState(() => _passwordsDiffer = differ);
    }
    if (differ) return;

    safeSetState(() {
      _isSubmitting = true;
      _invalidCode = false;
    });
    try {
      _model.sendInfo = await RegisterUserCall.call(
        email: FFAppState().email,
        password: _model.textFieldNovaSenhaTextController.text,
        termsAccepted: true,
        code: code,
      );
      if (!mounted) return;

      final result = _model.sendInfo;
      if (result?.succeeded ?? false) {
        // 201: the account is created already confirmed.
        await _showConsentAndContinue();
        return;
      }

      if (result != null &&
          result.statusCode == 400 &&
          ActivationCodeCall.registerError(result) ==
              ActivationCodeCall.invalidActivationCode) {
        _model.codeTextController!.clear();
        safeSetState(() => _invalidCode = true);
        _model.codeFocusNode?.requestFocus();
        return;
      }

      await _showError('Usuario não criado', title: 'Atencão');
    } finally {
      if (mounted) safeSetState(() => _isSubmitting = false);
    }
  }

  String _cooldownLabel() {
    final m = _resendCooldownSeconds ~/ 60;
    final s = (_resendCooldownSeconds % 60).toString().padLeft(2, '0');
    return 'Reenviar em $m:$s';
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final email = FFAppState().email.trim().toLowerCase();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: ZocAuthScaffold(
        scaffoldKey: scaffoldKey,
        body: Form(
          key: _model.formKey,
          autovalidateMode: AutovalidateMode.disabled,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ZocTitle(
                'Boas-vindas ao ZOC',
                subtitle: 'Confirme o código enviado ao seu e-mail e crie uma '
                    'senha para acessar o app nas próximas vezes.',
              ),
              const SizedBox(height: 14),
              if (_codeSendFailed)
                const ZocNotice(
                  'Não foi possível enviar o código. Tente reenviar.',
                  kind: ZocNoticeKind.error,
                )
              else if (_codeSent)
                ZocNotice('Enviamos um código de 6 dígitos para $email.')
              else
                ZocNotice('Enviando código para $email...'),
              const SizedBox(height: 14),
              ZocTextField(
                label: 'Código de verificação',
                icon: Icons.pin_outlined,
                hintText: 'Código de 6 dígitos',
                controller: _model.codeTextController,
                focusNode: _model.codeFocusNode,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onFieldSubmitted: (_) =>
                    _model.textFieldNovaSenhaFocusNode?.requestFocus(),
              ),
              if (_invalidCode) ...[
                const SizedBox(height: 10),
                const ZocNotice(
                  InfoWidget.invalidCodeMessage,
                  kind: ZocNoticeKind.error,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ZocTextField(
                      label: 'Nova senha',
                      icon: Icons.lock_outline_rounded,
                      hintText: 'Nova senha',
                      password: true,
                      controller: _model.textFieldNovaSenhaTextController,
                      focusNode: _model.textFieldNovaSenhaFocusNode,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FFAppState().password =
                            _model.textFieldConfirmSenhaTextController.text;
                        safeSetState(() {});
                        _model.textFieldConfirmSenhaFocusNode?.requestFocus();
                      },
                      validator: _model
                          .textFieldNovaSenhaTextControllerValidator
                          .asValidator(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZocTextField(
                      label: 'Confirmar senha',
                      icon: Icons.lock_outline_rounded,
                      hintText: 'Repita a senha',
                      password: true,
                      controller: _model.textFieldConfirmSenhaTextController,
                      focusNode: _model.textFieldConfirmSenhaFocusNode,
                      textInputAction: TextInputAction.go,
                      onFieldSubmitted: (_) => _finish(),
                      validator: _model
                          .textFieldConfirmSenhaTextControllerValidator
                          .asValidator(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 15, color: ZocColors.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Mínimo de 8 caracteres.',
                        style: ZocText.caption()),
                  ),
                ],
              ),
              if (_passwordsDiffer) ...[
                const SizedBox(height: 10),
                const ZocNotice(
                  'As senhas não coincidem.',
                  kind: ZocNoticeKind.error,
                ),
              ],
              if (FFAppState().loginFailed) ...[
                const SizedBox(height: 10),
                const ZocNotice(
                  'Email ou senha inválidos. Por favor, tente novamente.',
                  kind: ZocNoticeKind.error,
                ),
              ],
              const SizedBox(height: 14),
              ZocButton(
                'Finalizar',
                expanded: true,
                loading: _isSubmitting,
                onPressed: _isSubmitting ? null : _finish,
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Não recebeu? ', style: ZocText.sub()),
                  InkWell(
                    splashColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: _canResend ? _sendActivationCode : null,
                    child: Text(
                      _isSendingCode
                          ? 'Enviando...'
                          : _resendCooldownSeconds > 0
                              ? _cooldownLabel()
                              : 'Reenviar código',
                      style: _canResend
                          ? ZocText.link()
                          : ZocText.sub(color: ZocColors.faint),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
