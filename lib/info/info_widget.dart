import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'info_model.dart';
export 'info_model.dart';
import '/ui/zoc_ui.dart';

class InfoWidget extends StatefulWidget {
  const InfoWidget({super.key});

  static String routeName = 'info';
  static String routePath = '/info';

  @override
  State<InfoWidget> createState() => _InfoWidgetState();
}

class _InfoWidgetState extends State<InfoWidget> {
  late InfoModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => InfoModel());

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

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<void> _finish() async {
    var shouldSetState = false;
    FFAppState().password = _model.textFieldConfirmSenhaTextController.text;
    safeSetState(() {});
    if (!((_model.textFieldNovaSenhaTextController.text != '') &&
        (_model.textFieldConfirmSenhaTextController.text != ''))) {
      await showDialog(
        context: context,
        builder: (alertDialogContext) {
          return AlertDialog(
            title: const Text('Atenção'),
            content: const Text('Todos os campos são requeridos'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(alertDialogContext),
                child: const Text('Ok'),
              ),
            ],
          );
        },
      );
      return;
    }
    _model.sendInfo = await RegisterUserCall.call(
      email: FFAppState().email,
      password: _model.textFieldNovaSenhaTextController.text,
      termsAccepted: true,
    );

    shouldSetState = true;
    if (!mounted) return;
    if ((_model.sendInfo?.succeeded ?? false)) {
      // register-app already emailed the OTP
      context.goNamed(VerifyTokenWidget.routeName);
    } else {
      await showDialog(
        context: context,
        builder: (alertDialogContext) {
          return AlertDialog(
            title: const Text('Atencão'),
            content: const Text('Usuario não criado'),
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

    if (shouldSetState) safeSetState(() {});
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

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
                subtitle: 'Crie uma senha para acessar o app nas próximas vezes.',
              ),
              const SizedBox(height: 14),
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
              if (FFAppState().loginFailed) ...[
                const SizedBox(height: 10),
                const ZocNotice(
                  'Email ou senha inválidos. Por favor, tente novamente.',
                  kind: ZocNoticeKind.error,
                ),
              ],
              const SizedBox(height: 14),
              ZocButton('Finalizar', expanded: true, onPressed: _finish),
            ],
          ),
        ),
      ),
    );
  }
}
