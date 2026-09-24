import '/auth/custom_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/api_requests/api_manager.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'entrar_con_senha_model.dart';
import '/utils/zoc_logo.dart';
export 'entrar_con_senha_model.dart';

class EntrarConSenhaWidget extends StatefulWidget {
  const EntrarConSenhaWidget({super.key});

  static String routeName = 'EntrarConSenha';
  static String routePath = '/entrarConSenha';

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
              content: const Text('Senha invalida'),
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
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.transparent,
        body: SafeArea(
          top: true,
          child: Align(
            alignment: const AlignmentDirectional(0.0, 0.0),
            child: Container(
              width: 500.0,
              height: 400.0,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).secondaryBackground,
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 4.0,
                    color: Color(0x33000000),
                    offset: Offset(
                      0.0,
                      2.0,
                    ),
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        ZocLogo(
                          width: 100.0,
                          showTagline: false,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Center(
                      child: SizedBox(
                        width: 297.0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 297.0,
                              child: TextFormField(
                                controller: _model.emailTextController,
                                focusNode: _model.emailFocusNode,
                                autofocus: false,
                                readOnly: true,
                                obscureText: false,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  isDense: true,
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Color(0x3F0F8F8A),
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Color(0x3F0F8F8A),
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context).error,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context).error,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  filled: true,
                                  fillColor: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 10.0,
                                  ),
                                ),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF101827),
                                  fontSize: 15.0,
                                ),
                                cursorColor:
                                    FlutterFlowTheme.of(context).primaryText,
                                validator: _model.emailTextControllerValidator
                                    .asValidator(context),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            Text(
                              'Senha',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF101827),
                                fontSize: 14.0,
                              ),
                            ),
                            const SizedBox(height: 6.0),
                            SizedBox(
                              width: 297.0,
                              child: TextFormField(
                                controller: _model.senhaTextController,
                                focusNode: _model.senhaFocusNode,
                                autofocus: true,
                                obscureText: !_model.senhaVisibility,
                                onFieldSubmitted: (_) => _submitLogin(),
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText: 'Digite sua senha',
                                  hintStyle: GoogleFonts.inter(
                                    color: const Color(0xFF667085),
                                    fontSize: 14.0,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Color(0x3F0F8F8A),
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Color(0xFF0F8F8A),
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context).error,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context).error,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  filled: true,
                                  fillColor: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 12.0,
                                  ),
                                  suffixIcon: InkWell(
                                    onTap: () => safeSetState(
                                      () => _model.senhaVisibility =
                                          !_model.senhaVisibility,
                                    ),
                                    focusNode: FocusNode(skipTraversal: true),
                                    child: Icon(
                                      _model.senhaVisibility
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: const Color(0xFF0F8F8A),
                                      size: 20,
                                    ),
                                  ),
                                ),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF101827),
                                  fontSize: 14.0,
                                ),
                                cursorColor:
                                    FlutterFlowTheme.of(context).primaryText,
                                validator: _model.senhaTextControllerValidator
                                    .asValidator(context),
                              ),
                            ),
                            const SizedBox(height: 10.0),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  context.pushNamed(
                                      RedefinirSenhaWidget.routeName);
                                },
                                child: Text(
                                  'Esqueceu sua Senha?',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF0F8F8A),
                                    fontSize: 13.0,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20.0),
                            Center(
                              child: FFButtonWidget(
                                onPressed: _submitLogin,
                                text: 'Entrar',
                                options: FFButtonOptions(
                                  width: 150.0,
                                  height: 42.0,
                                  padding: EdgeInsets.zero,
                                  iconPadding: EdgeInsets.zero,
                                  color: const Color(0xFF0F8F8A),
                                  textStyle: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 15.0,
                                  ),
                                  elevation: 0.0,
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                showLoadingIndicator: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
