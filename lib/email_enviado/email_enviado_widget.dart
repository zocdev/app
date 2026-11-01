import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/ui/zoc_ui.dart';
import 'package:flutter/material.dart';
import '/backend/api_requests/api_calls.dart';
import '/utils/api_error_helper.dart';
import '/utils/error_handler.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'email_enviado_model.dart';
export 'email_enviado_model.dart';

class EmailEnviadoWidget extends StatefulWidget {
  const EmailEnviadoWidget({super.key});

  static String routeName = 'EmailEnviado';
  static String routePath = '/emailEnviado';

  @override
  State<EmailEnviadoWidget> createState() => _EmailEnviadoWidgetState();
}

class _EmailEnviadoWidgetState extends State<EmailEnviadoWidget> {
  late EmailEnviadoModel _model;
  Timer? _resendTimer;
  int _resendCooldownSeconds = 60;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  bool get _canResend => _resendCooldownSeconds <= 0;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EmailEnviadoModel());
    _resendCooldownSeconds = 60;
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

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
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

  Future<void> _resendEmail() async {
    if (!_canResend) return;

    final email = FFAppState().email;
    if (email.isEmpty) {
      context.pushNamed(RedefinirSenhaWidget.routeName);
      return;
    }

    final response = await ForgotPasswordCall.call(email: email);
    if (!mounted) return;

    if (response.succeeded) {
      _startResendCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Se existir uma conta para esse e-mail, enviamos um link para redefinir a senha.',
          ),
        ),
      );
      return;
    }

    final error = response.toAppError();
    if (error != null) {
      ErrorHandler().handleError(context, error, showSnackbar: true);
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    return ZocAuthScaffold(
      scaffoldKey: scaffoldKey,
      center: true,
      body: Column(mainAxisSize: MainAxisSize.min, children: [
        const ZocHeroIcon(Icons.check_circle_outline_rounded,
            tone: ZocTone.success),
        const SizedBox(height: 14),
        const ZocTitle('Verifique seu e-mail',
            center: true,
            subtitle:
                'Se existir uma conta para esse e-mail, enviamos um link para redefinir a senha.'),
        const SizedBox(height: 18),
        ZocButton('Voltar ao login',
            expanded: true,
            onPressed: () => context.pushNamed(EntrarConSenhaWidget.routeName)),
        const SizedBox(height: 14),
        Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Não chegou? ', style: ZocText.caption()),
              InkWell(
                  onTap: _canResend ? _resendEmail : null,
                  child: Text(
                      _canResend
                          ? 'Reenviar'
                          : 'Reenviar em ${_resendCooldownSeconds}s',
                      style: ZocText.link().copyWith(
                          color:
                              _canResend ? ZocColors.brand : ZocColors.muted))),
            ]),
      ]),
    );
  }
}
