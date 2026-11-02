import '/auth/custom_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/api_requests/api_manager.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'entrar_con_senha_model.dart';
import '/ui/zoc_ui.dart';
export 'entrar_con_senha_model.dart';

class EntrarConSenhaWidget extends StatefulWidget {
  const EntrarConSenhaWidget({super.key});

  static String routeName = 'EntrarConSenha';
  static String routePath = '/entrarConSenha';

  /// Shown when login answers 429 (e-mail locked after too many attempts).
  static const String tooManyAttemptsMessage =
      'Muitas tentativas de entrar com este e-mail. Aguarde alguns minutos '
      'ou use "Esqueci minha senha".';

  @override
  State<EntrarConSenhaWidget> createState() => _EntrarConSenhaWidgetState();
}

class _EntrarConSenhaWidgetState extends State<EntrarConSenhaWidget> {
  late EntrarConSenhaModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EntrarConSenhaModel());

    _model.emailTextController ??=
        TextEditingController(text: FFAppState().email);
    _model.emailFocusNode ??= FocusNode();

    _model.senhaTextController ??= TextEditingController();
    _model.senhaFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<void> _submitLogin() async {
    var shouldSetState = false;
    if (_model.senhaTextController.text != '') {
      _model.loginResult = await LoginCall.call(
        email: _model.emailTextController.text,
        password: _model.senhaTextController.text,
        remoteValue: FFAppState().isRemote,
      );

      shouldSetState = true;
      final loginResult = _model.loginResult;
      if (loginResult != null && LoginCall.isEmailNotVerified(loginResult)) {
        FFAppState().email = _model.emailTextController.text;
        safeSetState(() {});
        if (!mounted) return;
        context.pushNamed(VerifyTokenWidget.routeName);
        if (shouldSetState) safeSetState(() {});
        return;
      }
      if ((loginResult?.succeeded ?? true)) {
        if (!mounted) return;
        GoRouter.of(context).prepareAuthEvent();
        final expiresIn = LoginCall.expiresIn(
          loginResult?.jsonBody ?? '',
        );
        final tokenExpiration = expiresIn != null
            ? DateTime.now().add(
                Duration(seconds: expiresIn),
              )
            : null;
        await authManager.signIn(
          authenticationToken: getJsonField(
            (loginResult?.jsonBody ?? ''),
            r'''$.access_token''',
          ).toString(),
          refreshToken: getJsonField(
            (loginResult?.jsonBody ?? ''),
            r'''$.refresh_token''',
          ).toString(),
          tokenExpiration: tokenExpiration,
          authUid: getJsonField(
            (loginResult?.jsonBody ?? ''),
            r'''$.user.id''',
          ).toString(),
        );
        ApiManager.syncAccessToken(
          authManager.authenticationToken,
        );
        FFAppState().UserData = (loginResult?.jsonBody ?? '');
        safeSetState(() {});
      } else {
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (alertDialogContext) {
            return AlertDialog(
              title: const Text('Atenção'),
              content: Text(loginResult?.statusCode == 429
                  ? EntrarConSenhaWidget.tooManyAttemptsMessage
                  : 'Senha invalida'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(alertDialogContext),
                  child: const Text('Ok'),
                ),
              ],
            );
          },
        );
        if (shouldSetState) safeSetState(() {});
        return;
      }

      if (!mounted) return;
      context.goNamedAuth(
          MensajeAntesExpedienteWidget.routeName, context.mounted);
    } else {
      await showDialog(
        context: context,
        builder: (alertDialogContext) {
          return AlertDialog(
            title: const Text('Atenção'),
            content: const Text('Senha deve ser preenchida'),
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
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ZocTitle('Digite sua senha'),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: _EmailChip(
                email: _model.emailTextController?.text ?? '',
                onChange: () => context.goNamed(LoginWidget.routeName),
              ),
            ),
            const SizedBox(height: 14),
            ZocTextField(
              label: 'Senha',
              icon: Icons.lock_outline_rounded,
              hintText: 'Digite sua senha',
              password: true,
              autofocus: true,
              controller: _model.senhaTextController,
              focusNode: _model.senhaFocusNode,
              textInputAction: TextInputAction.go,
              onFieldSubmitted: (_) => _submitLogin(),
              validator:
                  _model.senhaTextControllerValidator.asValidator(context),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () async {
                  context.pushNamed(RedefinirSenhaWidget.routeName);
                },
                child: Text('Esqueceu a senha?', style: ZocText.link()),
              ),
            ),
            const SizedBox(height: 14),
            ZocButton('Entrar', expanded: true, onPressed: _submitLogin),
          ],
        ),
      ),
    );
  }
}

/// Pill showing the e-mail typed on the login screen, with a "Trocar" link.
class _EmailChip extends StatelessWidget {
  const _EmailChip({required this.email, required this.onChange});

  final String email;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 7, 14, 7),
        decoration: BoxDecoration(
          color: ZocColors.brandSoft,
          borderRadius: BorderRadius.circular(ZocRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline_rounded,
                size: 15, color: ZocColors.text),
            const SizedBox(width: 8),
            Flexible(
              child: Text(email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ZocText.body()),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: onChange,
              child: Text('Trocar', style: ZocText.link()),
            ),
          ],
        ),
      );
}
