import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mensaje_antes_expediente_model.dart';
import '/utils/zoc_logo.dart';
export 'mensaje_antes_expediente_model.dart';

class MensajeAntesExpedienteWidget extends StatefulWidget {
  const MensajeAntesExpedienteWidget({super.key});

  static String routeName = 'MensajeAntesExpediente';
  static String routePath = '/mensajeAntesExpediente';

  @override
  State<MensajeAntesExpedienteWidget> createState() =>
      _MensajeAntesExpedienteWidgetState();
}

class _MensajeAntesExpedienteWidgetState
    extends State<MensajeAntesExpedienteWidget> {
  late MensajeAntesExpedienteModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MensajeAntesExpedienteModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            alignment: AlignmentDirectional(0.0, 0.0),
            child: SafeArea(
              child: Container(
                width: 500.0,
                height: 400.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 4.0,
                      color: Color(0x33000000),
                      offset: Offset(
                        0.0,
                        2.0,
                      ),
                    )
                  ],
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(0.0),
                    bottomRight: Radius.circular(0.0),
                    topLeft: Radius.circular(0.0),
                    topRight: Radius.circular(0.0),
                  ),
                  border: Border.all(
                    color: Colors.transparent,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              context.pushNamed(LoginWidget.routeName);
                            },
                            child: const ZocLogo(
                              width: 100.0,
                              showTagline: false,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 36.0),
                        child: Text(
                          'Para garantir a produtividade e entender melhor seu fluxo de trabalho, pedimos que informe periodicamente em que está trabalhando. Esses dados nos ajudam a melhorar a organização e o suporte ao time.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFF344054),
                            fontSize: 15.0,
                            height: 1.55,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Center(
                        child: FFButtonWidget(
                          onPressed: () async {
                            context.pushNamed(LogoutWidget.routeName);
                          },
                          text: 'Ok',
                          options: FFButtonOptions(
                            width: 90.0,
                            height: 40.0,
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
