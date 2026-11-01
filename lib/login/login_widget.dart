import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/backend/schema/structs/index.dart';
import '/index.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'login_model.dart';
import '/utils/api_error_helper.dart';
import '/utils/error_handler.dart';
import '/utils/screenshot_consent_dialog.dart';
import '/ui/zoc_ui.dart';
export 'login_model.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  static String routeName = 'Login';
  static String routePath = '/login';

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  late LoginModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (FFAppState().savedEmail != '') {
        safeSetState(() {
          _model.emailTextController?.text = FFAppState().savedEmail;
        });
      }
    });

    _model.emailTextController ??= TextEditingController();
    _model.emailFocusNode ??= FocusNode();

    _model.isRemoteValue = FFAppState().isRemote;
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<void> _continue() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _verifyEmail();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyEmail() async {
    if (_model.formKey.currentState != null) {
      _model.formKey.currentState!.validate();
    }

    final email = _model.emailTextController.text.trim().toLowerCase();

    if (FFAppState().rememberMe == true) {
      FFAppState().savedEmail = email;
      safeSetState(() {});
    } else {
      FFAppState().savedEmail = '';
      safeSetState(() {});
    }

    FFAppState().email = email;
    safeSetState(() {});

    final response = await VerifyEmailCall.call(
      email: email,
    );
    if (!mounted) return;

    if (response.statusCode == 404) {
      final message = VerifyEmailCall.emailNotFoundMessage(
        response,
      );
      context.showError(
        AppError(
          type: ErrorType.validation,
          message: message,
          userMessage: message,
          statusCode: 404,
        ),
        asDialog: true,
      );
      safeSetState(() {});
      return;
    }

    if (response.hasError) {
      final error = response.toAppError();
      if (error != null) {
        context.showError(error);
      }
      safeSetState(() {});
      return;
    }

    final result = VerifyEmailStruct.maybeFromMap(
      response.jsonBody,
    );

    if (result != null) {
      FFAppState().emailData = result.toMap();
      safeSetState(() {});

      if (result.exists == false) {
        context.showError(
          AppError(
            type: ErrorType.validation,
            message: VerifyEmailCall.emailNotFoundFallback,
            userMessage: VerifyEmailCall.emailNotFoundFallback,
          ),
          asDialog: true,
        );
      } else if (result.firstTime == true) {
        context.pushNamed(InfoWidget.routeName);
      } else if (result.verified == false) {
        context.pushNamed(VerifyTokenWidget.routeName);
      } else {
        final approved = await showScreenshotConsentDialog(
          context,
          screenshotsEnabled: result.screenshotsEnabled,
        );
        if (!mounted) return;
        if (!approved) {
          await denyScreenshotConsentAndLogout(
            context,
          );
          return;
        }
        context.pushNamed(EntrarConSenhaWidget.routeName);
      }
    }

    safeSetState(() {});
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
        footer: const ZocDisclaimer(),
        body: Form(
          key: _model.formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ZocTitle(
                'Entrar no ZOC',
                subtitle:
                    'Use o e-mail da sua empresa para começar o expediente.',
              ),
              const SizedBox(height: 14),
              if (FFAppState().loginFailed) ...[
                const ZocNotice(
                  'E-mail ou senha inválidos. Tente novamente.',
                  kind: ZocNoticeKind.error,
                ),
                const SizedBox(height: 14),
              ],
              ZocTextField(
                label: 'E-mail',
                icon: Icons.mail_outline_rounded,
                hintText: 'seu@email.com',
                controller: _model.emailTextController,
                focusNode: _model.emailFocusNode,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.go,
                autofillHints: const [AutofillHints.email],
                onChanged: (_) => EasyDebounce.debounce(
                  '_model.emailTextController',
                  const Duration(milliseconds: 2000),
                  () async {
                    FFAppState().email = _model.emailTextController.text;
                    safeSetState(() {});
                  },
                ),
                onFieldSubmitted: (_) => _continue(),
                validator:
                    _model.emailTextControllerValidator.asValidator(context),
              ),
              const SizedBox(height: 14),
              ZocToggleRow(
                title: 'Trabalho remoto',
                help: 'Marque se hoje você trabalha fora do escritório',
                value: _model.isRemoteValue!,
                onChanged: (newValue) {
                  safeSetState(() => _model.isRemoteValue = newValue);
                  FFAppState().isRemote = newValue;
                  safeSetState(() {});
                },
              ),
              const SizedBox(height: 14),
              ZocButton(
                'Continuar',
                expanded: true,
                loading: _busy,
                onPressed: _continue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
