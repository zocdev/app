import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/backend/schema/structs/index.dart';
import '/index.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'login_model.dart';
import '/utils/api_error_helper.dart';
import '/utils/error_handler.dart';
import '/utils/screenshot_consent_dialog.dart';
import '/utils/zoc_logo.dart';
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
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFF6F8FA),
                Color(0xFFE6F4F3),
                Color(0xFFD5F0EE),
              ],
              stops: [0.0, 0.4, 0.75, 1.0],
              begin: AlignmentDirectional(-1.0, -1.0),
              end: AlignmentDirectional(1.0, 1.0),
            ),
          ),
          child: SafeArea(
            child: Align(
              alignment: AlignmentDirectional(0.0, 0.0),
              child: SizedBox(
                width: 500.0,
                height: 400.0,
                child: Form(
                  key: _model.formKey,
                  autovalidateMode: AutovalidateMode.always,
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
                                Text(
                                  'Login no ZOC',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF101827),
                                    fontSize: 22.0,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 14.0),
                                if (FFAppState().loginFailed)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: Text(
                                      'Email ou senha inválidos. Por favor, tente novamente.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFFD92D20),
                                        fontSize: 13.0,
                                      ),
                                    ),
                                  ),
                                Text(
                                  'E-mail',
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
                                    controller: _model.emailTextController,
                                    focusNode: _model.emailFocusNode,
                                    onChanged: (_) => EasyDebounce.debounce(
                                      '_model.emailTextController',
                                      const Duration(milliseconds: 2000),
                                      () async {
                                        FFAppState().email =
                                            _model.emailTextController.text;
                                        safeSetState(() {});
                                      },
                                    ),
                                    autofocus: false,
                                    obscureText: false,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      hintText: 'seu@email.com',
                                      hintStyle: GoogleFonts.inter(
                                        color: const Color(0xFF667085),
                                        fontSize: 14.0,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          color: Color(0x3F0F8F8A),
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          color: Color(0xFF0F8F8A),
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: FlutterFlowTheme.of(context)
                                              .error,
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: FlutterFlowTheme.of(context)
                                              .error,
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      filled: true,
                                      fillColor: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12.0,
                                        vertical: 12.0,
                                      ),
                                    ),
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF101827),
                                      fontSize: 14.0,
                                    ),
                                    maxLines: 1,
                                    keyboardType: TextInputType.emailAddress,
                                    cursorColor: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    validator: _model
                                        .emailTextControllerValidator
                                        .asValidator(context),
                                  ),
                                ),
                                const SizedBox(height: 12.0),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Switch.adaptive(
                                      value: _model.isRemoteValue!,
                                      onChanged: (newValue) async {
                                        safeSetState(() =>
                                            _model.isRemoteValue = newValue);
                                        FFAppState().isRemote = newValue;
                                        safeSetState(() {});
                                      },
                                      activeColor: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      activeTrackColor: const Color(0xFF0F8F8A),
                                      inactiveTrackColor:
                                          FlutterFlowTheme.of(context)
                                              .alternate,
                                      inactiveThumbColor:
                                          FlutterFlowTheme.of(context)
                                              .secondaryBackground,
                                    ),
                                    const SizedBox(width: 8.0),
                                    Text(
                                      'Trabalho remoto',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF101827),
                                        fontSize: 14.0,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18.0),
                                FFButtonWidget(
                                  onPressed: () async {
                                    if (_model.formKey.currentState != null) {
                                      _model.formKey.currentState!.validate();
                                    }

                                    final email = _model.emailTextController.text
                                        .trim()
                                        .toLowerCase();

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

                                    if (response.statusCode == 404) {
                                      final message =
                                          VerifyEmailCall.emailNotFoundMessage(
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

                                    final result =
                                        VerifyEmailStruct.maybeFromMap(
                                      response.jsonBody,
                                    );

                                    if (result != null) {
                                      FFAppState().emailData = result.toMap();
                                      safeSetState(() {});

                                      if (result.exists == false) {
                                        context.showError(
                                          AppError(
                                            type: ErrorType.validation,
                                            message: VerifyEmailCall
                                                .emailNotFoundFallback,
                                            userMessage: VerifyEmailCall
                                                .emailNotFoundFallback,
                                          ),
                                          asDialog: true,
                                        );
                                      } else if (result.firstTime == true) {
                                        context.pushNamed(InfoWidget.routeName);
                                      } else if (result.verified == false) {
                                        context.pushNamed(
                                            VerifyTokenWidget.routeName);
                                      } else {
                                        final approved =
                                            await showScreenshotConsentDialog(
                                          context,
                                        );
                                        if (!context.mounted) return;
                                        if (!approved) {
                                          await denyScreenshotConsentAndLogout(
                                            context,
                                          );
                                          return;
                                        }
                                        context.pushNamed(
                                            EntrarConSenhaWidget.routeName);
                                      }
                                    }

                                    safeSetState(() {});
                                  },
                                  text: 'ENTRAR',
                                  options: FFButtonOptions(
                                    width: 297.0,
                                    height: 45.0,
                                    padding: EdgeInsets.zero,
                                    iconPadding: EdgeInsets.zero,
                                    color: const Color(0xFF0F8F8A),
                                    textStyle: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 16.0,
                                    ),
                                    elevation: 0.0,
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  showLoadingIndicator: false,
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
        ),
      ),
    );
  }
}
