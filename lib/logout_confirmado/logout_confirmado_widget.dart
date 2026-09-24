import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'logout_confirmado_model.dart';
import '/utils/zoc_logo.dart';
export 'logout_confirmado_model.dart';

class LogoutConfirmadoWidget extends StatefulWidget {
  const LogoutConfirmadoWidget({super.key});

  static String routeName = 'LogoutConfirmado';
  static String routePath = '/logoutConfirmado';

  @override
  State<LogoutConfirmadoWidget> createState() => _LogoutConfirmadoWidgetState();
}

class _LogoutConfirmadoWidgetState extends State<LogoutConfirmadoWidget> {
  late LogoutConfirmadoModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LogoutConfirmadoModel());

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
                        children: const [
                          ZocLogo(
                            width: 100.0,
                            showTagline: false,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: SvgPicture.asset(
                              'assets/images/Vector_(2).svg',
                              width: 64.0,
                              height: 64.0,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 24.0),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        'Sua sessão foi encerrada. Caso precise acessar novamente, faça ',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF101827),
                                      fontSize: 18.0,
                                      height: 1.4,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'login',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0F8F8A),
                                      fontSize: 18.0,
                                      decoration: TextDecoration.underline,
                                    ),
                                    mouseCursor: SystemMouseCursors.click,
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () async {
                                        context.pushNamed(LoginWidget.routeName);
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
    );
  }
}
