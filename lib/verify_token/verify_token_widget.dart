import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/utils/api_error_helper.dart';
import '/utils/error_handler.dart';
import 'dart:async';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'verify_token_model.dart';
export 'verify_token_model.dart';

class VerifyTokenWidget extends StatefulWidget {
  const VerifyTokenWidget({super.key});

  static String routeName = 'verifyToken';
  static String routePath = '/verifyToken';

  @override
  State<VerifyTokenWidget> createState() => _VerifyTokenWidgetState();
}

class _VerifyTokenWidgetState extends State<VerifyTokenWidget> {
  late VerifyTokenModel _model;
  Timer? _resendTimer;
  int _resendCooldownSeconds = 0;
  bool _isConfirming = false;
  bool _isResending = false;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  bool get _canResend =>
      _resendCooldownSeconds <= 0 && !_isResending && !_isConfirming;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => VerifyTokenModel());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _model.focusFirst();
      }
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
      _resendCooldownSeconds = 60;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldownSeconds <= 1) {
        timer.cancel();
        safeSetState(() {
          _resendCooldownSeconds = 0;
        });
        return;
      }
      safeSetState(() {
        _resendCooldownSeconds -= 1;
      });
    });
  }

  void _clearOtp() {
    _model.clearOtp();
    safeSetState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _model.focusFirst();
      }
    });
  }

  void _onOtpChanged(int index, String value) {
    if (_isConfirming) return;

    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < VerifyTokenModel.otpLength; i++) {
        _model.otpControllers[i].text =
            i < digits.length ? digits[i] : '';
      }
      final focusIndex = digits.length.clamp(0, VerifyTokenModel.otpLength - 1);
      _model.otpFocusNodes[focusIndex].requestFocus();
      safeSetState(() {});
      return;
    }

    if (value.isNotEmpty) {
      _model.otpControllers[index].text = value.substring(value.length - 1);
      if (index < VerifyTokenModel.otpLength - 1) {
        _model.otpFocusNodes[index + 1].requestFocus();
      } else {
        _model.otpFocusNodes[index].unfocus();
      }
    }

    safeSetState(() {});
  }

  KeyEventResult _onOtpKeyEvent(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }

    if (_model.otpControllers[index].text.isNotEmpty) {
      return KeyEventResult.ignored;
    }
    if (index > 0) {
      _model.otpControllers[index - 1].clear();
      _model.otpFocusNodes[index - 1].requestFocus();
      safeSetState(() {});
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  bool _isInvalidOtpResponse(ApiCallResponse response) {
    final status = response.statusCode;
    if (status == 401 || status == 400) return true;

    final body = response.jsonBody;
    if (body is! Map) return false;
    final raw = ((body['message'] as String?) ??
            (body['error'] as String?) ??
            '')
        .toLowerCase();
    return raw.contains('invalid token') ||
        raw.contains('invalid otp') ||
        raw.contains('código inválido') ||
        raw.contains('codigo invalido') ||
        raw.contains('código expirou') ||
        raw.contains('codigo expirou') ||
        raw.contains('expir');
  }

  String _invalidOtpMessage(ApiCallResponse response) {
    final body = response.jsonBody;
    if (body is Map) {
      final raw = ((body['message'] as String?) ??
              (body['error'] as String?) ??
              '')
          .trim();
      final lower = raw.toLowerCase();
      if (lower.contains('expir')) {
        return 'Código expirado. Solicite um novo código.';
      }
      if (raw.isNotEmpty &&
          !lower.contains('invalid token') &&
          !lower.contains('internal')) {
        return raw;
      }
    }
    return 'Código inválido. Verifique e tente novamente.';
  }

  Future<void> _confirmOtp() async {
    if (_isConfirming) return;

    final otp = _model.otp;
    if (otp.length != 6 || int.tryParse(otp) == null) {
      return;
    }

    safeSetState(() {
      _isConfirming = true;
    });

    try {
      _model.otpResult = await VerifyOtpCall.call(otp: otp);
      if (!mounted) return;

      final result = _model.otpResult;
      if (result == null) return;

      if (result.statusCode == 200) {
        context.goNamed(EntrarConSenhaWidget.routeName);
        return;
      }

      if (_isInvalidOtpResponse(result)) {
        _clearOtp();
        await showDialog(
          context: context,
          builder: (alertDialogContext) {
            return AlertDialog(
              title: const Text('Atenção'),
              content: Text(_invalidOtpMessage(result)),
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

      final error = result.toAppError();
      if (error != null) {
        ErrorHandler().handleError(
          context,
          error,
          showSnackbar: true,
        );
      }
    } finally {
      if (mounted) {
        safeSetState(() {
          _isConfirming = false;
        });
      }
    }
  }

  Future<void> _resendConfirmation() async {
    if (!_canResend) return;

    final email = FFAppState().email;
    if (email.isEmpty) {
      context.goNamed(LoginWidget.routeName);
      return;
    }

    safeSetState(() {
      _isResending = true;
    });

    try {
      final response = await ResendEmailConfirmationCall.call(email: email);
      if (!mounted) return;

      if (response.succeeded) {
        _startResendCooldown();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código reenviado com sucesso.'),
          ),
        );
        return;
      }

      final error = response.toAppError();
      if (error != null) {
        ErrorHandler().handleError(
          context,
          error,
          showSnackbar: true,
        );
      }
    } finally {
      if (mounted) {
        safeSetState(() {
          _isResending = false;
        });
      }
    }
  }

  Widget _buildOtpBox(int index) {
    final hasFocus = _model.otpFocusNodes[index].hasFocus;
    final hasValue = _model.otpControllers[index].text.isNotEmpty;
    final borderColor = hasFocus
        ? const Color(0xFF4CAED1)
        : hasValue
            ? const Color(0xFF006994)
            : FlutterFlowTheme.of(context).alternate;

    return SizedBox(
      width: 44.0,
      height: 44.0,
      child: Focus(
        onKeyEvent: (node, event) => _onOtpKeyEvent(index, event),
        child: TextField(
          controller: _model.otpControllers[index],
          focusNode: _model.otpFocusNodes[index],
          enabled: !_isConfirming,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: FlutterFlowTheme.of(context).bodyLarge.override(
                font: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
                letterSpacing: 0.0,
                fontWeight: FontWeight.w600,
              ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            counterText: '',
            hintText: '●',
            hintStyle: TextStyle(
              color: FlutterFlowTheme.of(context).alternate,
            ),
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: borderColor, width: 2.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide:
                  const BorderSide(color: Color(0xFF4CAED1), width: 2.0),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: FlutterFlowTheme.of(context).alternate,
                width: 2.0,
              ),
            ),
          ),
          onChanged: (value) => _onOtpChanged(index, value),
          onTap: () {
            _model.otpControllers[index].selection = TextSelection(
              baseOffset: 0,
              extentOffset: _model.otpControllers[index].text.length,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final email = FFAppState().email;

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
            child: SafeArea(
              child: Container(
                width: 500.0,
                height: 480.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 4.0,
                      color: Color(0x33000000),
                      offset: Offset(0.0, 2.0),
                    )
                  ],
                  border: Border.all(color: Colors.transparent),
                ),
                child: Align(
                  alignment: const AlignmentDirectional(0.0, -1.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            20.0, 0.0, 20.0, 0.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.asset(
                                'assets/images/ZOC.webp',
                                width: 90.0,
                                height: 80.0,
                                fit: BoxFit.cover,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                context.goNamed(LoginWidget.routeName);
                              },
                              icon: const Icon(
                                Icons.close,
                                color: Color(0xFF102A43),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            40.0, 20.0, 40.0, 0.0),
                        child: Column(
                          children: [
                            Text(
                              'Confirmar e-mail',
                              textAlign: TextAlign.center,
                              style: FlutterFlowTheme.of(context)
                                  .displaySmall
                                  .override(
                                    font: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    color: const Color(0xFF102A43),
                                    fontSize: 20.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 12.0, 0.0, 0.0),
                              child: Text(
                                email.isEmpty
                                    ? 'Digite o código de 6 dígitos enviado ao seu e-mail.'
                                    : 'Digite o código de 6 dígitos enviado para\n$email',
                                textAlign: TextAlign.center,
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.montserrat(
                                        fontWeight: FontWeight.normal,
                                      ),
                                      color: const Color(0xFF102A43),
                                      fontSize: 14.0,
                                      letterSpacing: 0.0,
                                    ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  20.0, 30.0, 20.0, 0.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: List.generate(
                                  VerifyTokenModel.otpLength,
                                  _buildOtpBox,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            0.0, 20.0, 0.0, 0.0),
                        child: FFButtonWidget(
                          onPressed: _isConfirming
                              ? null
                              : () async {
                                  await _confirmOtp();
                                },
                          text: _isConfirming ? 'Confirmando...' : 'Confirmar',
                          options: FFButtonOptions(
                            width: 150.0,
                            height: 40.0,
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                16.0, 0.0, 16.0, 0.0),
                            color: const Color(0xFF006994),
                            disabledColor:
                                const Color(0xFF006994).withValues(alpha: 0.5),
                            textStyle: FlutterFlowTheme.of(context)
                                .labelSmall
                                .override(
                                  font: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  fontSize: 16.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                ),
                            elevation: 0.0,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            0.0, 30.0, 0.0, 0.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 10.0, 2.0),
                              child: Text(
                                'Não recebeu o e-mail?',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.montserrat(
                                        fontWeight: FontWeight.normal,
                                      ),
                                      color: const Color(0xFF102A43),
                                      fontSize: 13.0,
                                      letterSpacing: 0.0,
                                    ),
                              ),
                            ),
                            InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: _canResend
                                  ? () async {
                                      await _resendConfirmation();
                                    }
                                  : null,
                              child: Text(
                                _isResending
                                    ? 'enviando...'
                                    : _resendCooldownSeconds > 0
                                        ? 'reenviar (${_resendCooldownSeconds}s)'
                                        : 'reenviar e-mail',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.montserrat(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      color: _canResend
                                          ? const Color(0xFF006994)
                                          : const Color(0xFF102A43)
                                              .withValues(alpha: 0.4),
                                      fontSize: 13.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            0.0, 24.0, 0.0, 0.0),
                        child: InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () {
                            context.goNamed(EntrarConSenhaWidget.routeName);
                          },
                          child: Text(
                            'Voltar para o login',
                            style:
                                FlutterFlowTheme.of(context).bodyMedium.override(
                                      font: GoogleFonts.montserrat(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      color: const Color(0xFF006994),
                                      fontSize: 13.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                        ),
                      ),
                    ],
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
