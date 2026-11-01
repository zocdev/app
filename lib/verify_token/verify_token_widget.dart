import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/utils/api_error_helper.dart';
import '/utils/error_handler.dart';
import '/utils/screenshot_consent_dialog.dart';
import 'dart:async';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'verify_token_model.dart';
import '/ui/zoc_ui.dart';
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
      _model.otpResult = await VerifyOtpCall.call(
        otp: otp,
        email: FFAppState().email,
      );
      if (!mounted) return;

      final result = _model.otpResult;
      if (result == null) return;

      if (result.statusCode == 200) {
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
    return SizedBox(
      width: 44.0,
      height: 52.0,
      child: Focus(
        onKeyEvent: (node, event) => _onOtpKeyEvent(index, event),
        child: TextField(
          controller: _model.otpControllers[index],
          focusNode: _model.otpFocusNodes[index],
          enabled: !_isConfirming,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          cursorColor: ZocColors.brand,
          style: ZocText.h2(),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: zocInputDecoration().copyWith(
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
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

  String _cooldownLabel() {
    final m = _resendCooldownSeconds ~/ 60;
    final s = (_resendCooldownSeconds % 60).toString().padLeft(2, '0');
    return 'Reenviar em $m:$s';
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
      child: ZocAuthScaffold(
        scaffoldKey: scaffoldKey,
        center: true,
        topAction: IconButton(
          onPressed: () {
            context.goNamed(LoginWidget.routeName);
          },
          icon: const Icon(Icons.close_rounded, color: ZocColors.muted),
        ),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ZocTitle(
              'Confirmar e-mail',
              center: true,
              subtitle: email.isEmpty
                  ? 'Digite o código de 6 dígitos enviado ao seu e-mail.'
                  : 'Digite o código de 6 dígitos enviado para\n$email',
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                VerifyTokenModel.otpLength,
                _buildOtpBox,
              ),
            ),
            const SizedBox(height: 16),
            ZocButton(
              _isConfirming ? 'Confirmando...' : 'Confirmar',
              expanded: true,
              loading: _isConfirming,
              onPressed: _isConfirming
                  ? null
                  : () async {
                      await _confirmOtp();
                    },
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
                  onTap: _canResend
                      ? () async {
                          await _resendConfirmation();
                        }
                      : null,
                  child: Text(
                    _isResending
                        ? 'Enviando...'
                        : _resendCooldownSeconds > 0
                            ? _cooldownLabel()
                            : 'Reenviar e-mail',
                    style: _canResend
                        ? ZocText.link()
                        : ZocText.sub(color: ZocColors.faint),
                  ),
                ),
                Text(' · ', style: ZocText.sub()),
                InkWell(
                  splashColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () {
                    context.goNamed(EntrarConSenhaWidget.routeName);
                  },
                  child: Text('Voltar ao login', style: ZocText.link()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
