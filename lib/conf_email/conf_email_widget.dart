import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/utils/api_error_helper.dart';
import '/utils/error_handler.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'conf_email_model.dart';
import '/ui/zoc_ui.dart';
export 'conf_email_model.dart';

class ConfEmailWidget extends StatefulWidget {
  const ConfEmailWidget({super.key});

  static String routeName = 'confEmail';
  static String routePath = '/confEmail';

  @override
  State<ConfEmailWidget> createState() => _ConfEmailWidgetState();
}

class _ConfEmailWidgetState extends State<ConfEmailWidget> {
  late ConfEmailModel _model;
  bool _isSending = false;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ConfEmailModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<void> _goToConfirmOtp({bool resend = false}) async {
    if (_isSending) return;

    final email = FFAppState().email;
    if (email.isEmpty) {
      context.goNamed(LoginWidget.routeName);
      return;
    }

    if (!resend) {
      context.goNamed(VerifyTokenWidget.routeName);
      return;
    }

    safeSetState(() {
      _isSending = true;
    });

    try {
      final response = await ResendEmailConfirmationCall.call(email: email);
      if (!mounted) return;

      if (response.succeeded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código enviado com sucesso.'),
          ),
        );
        context.goNamed(VerifyTokenWidget.routeName);
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
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final email = FFAppState().email;

    return ZocAuthScaffold(
      scaffoldKey: scaffoldKey,
      center: true,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: ZocHeroIcon(Icons.mark_email_read_outlined)),
          const SizedBox(height: 10),
          ZocTitle(
            'Confirme sua conta',
            center: true,
            subtitleWidget: Text.rich(
              TextSpan(
                style: ZocText.sub(),
                children: email.isEmpty
                    ? const [
                        TextSpan(
                            text:
                                'Enviamos um código para o seu e-mail. Confira sua caixa de entrada.'),
                      ]
                    : [
                        const TextSpan(text: 'Enviamos um código para '),
                        TextSpan(
                            text: email,
                            style: ZocText.sub().copyWith(
                                color: ZocColors.text,
                                fontWeight: FontWeight.w600)),
                        const TextSpan(
                            text: '. Confira sua caixa de entrada.'),
                      ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ZocButton(
            'Inserir código',
            expanded: true,
            onPressed: _isSending ? null : () async => _goToConfirmOtp(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Não recebeu? ', style: ZocText.sub()),
              InkWell(
                onTap: _isSending
                    ? null
                    : () async => _goToConfirmOtp(resend: true),
                child: Text(_isSending ? 'Enviando...' : 'Reenviar e-mail',
                    style: ZocText.link()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
