import '/auth/custom_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'confirma_logout_model.dart';
import '/utils/zoc_logo.dart';
export 'confirma_logout_model.dart';

class ConfirmaLogoutWidget extends StatefulWidget {
  const ConfirmaLogoutWidget({super.key});

  static String routeName = 'ConfirmaLogout';
  static String routePath = '/confirmaLogout';

  @override
  State<ConfirmaLogoutWidget> createState() => _ConfirmaLogoutWidgetState();
}

class _ConfirmaLogoutWidgetState extends State<ConfirmaLogoutWidget> {
  late ConfirmaLogoutModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ConfirmaLogoutModel());

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
                      Text(
                        'Deseja realmente encerrar sua sessão?',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF101827),
                          fontSize: 20.0,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 28.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FFButtonWidget(
                            onPressed: () async {
                              GoRouter.of(context).prepareAuthEvent();
                              await authManager.signOut();
                              GoRouter.of(context).clearRedirectLocation();

                              context.goNamedAuth(
                                  LogoutConfirmadoWidget.routeName,
                                  context.mounted);

                              FFAppState().UserData = null;
                              FFAppState().dataSave = [];
                              safeSetState(() {});
                            },
                            text: 'Confirmar',
                            options: FFButtonOptions(
                              width: 120.0,
                              height: 40.0,
                              padding: EdgeInsets.zero,
                              iconPadding: EdgeInsets.zero,
                              color: const Color(0xFF0F8F8A),
                              textStyle: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 14.0,
                              ),
                              elevation: 0.0,
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          FFButtonWidget(
                            onPressed: () async {
                              context.safePop();
                            },
                            text: 'Cancelar',
                            options: FFButtonOptions(
                              width: 120.0,
                              height: 40.0,
                              padding: EdgeInsets.zero,
                              iconPadding: EdgeInsets.zero,
                              color: Colors.white,
                              textStyle: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F8F8A),
                                fontSize: 14.0,
                              ),
                              elevation: 0.0,
                              borderSide: const BorderSide(
                                color: Color(0xFF0F8F8A),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(10.0),
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
