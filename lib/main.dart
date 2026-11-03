import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:window_manager/window_manager.dart';
import 'package:system_tray/system_tray.dart';
import 'dart:async' show Timer;
import 'dart:io' show Platform, exit;

import 'auth/auth_session.dart';
import 'auth/custom_auth/auth_util.dart';
import 'auth/custom_auth/custom_auth_user_provider.dart';

import '/backend/api_requests/api_manager.dart';
import '/desktop/pause_controller.dart';
import '/desktop/pause_sheet.dart' show pauseErrorMessage;
import '/desktop/update_dialog.dart';
import '/utils/time_tracking.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'flutter_flow/internationalization.dart';
import 'index.dart';
import '/ui/zoc_theme.dart';
import '/desktop/popup_window.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      print('FlutterError: ${details.exception}');
      print('StackTrace: ${details.stack}');
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      print('PlatformDispatcher error: $error');
      print('StackTrace: $stack');
    }
    return true;
  };

  final appState = FFAppState();

  try {
    await authManager.initialize();
    await appState.initializePersistedState();
    PauseController.instance.restoreFromCache();

    ApiManager.configureAuthSession(
      accessTokenGetter: () => authManager.authenticationToken,
      tokenRefresher: AuthSession.refreshAccessToken,
      onUnauthorized: AuthSession.handleUnauthorized,
    );
    ApiManager.syncAccessToken(authManager.authenticationToken);
  } catch (e, stack) {
    if (kDebugMode) {
      print('Startup initialization error: $e');
      print('StackTrace: $stack');
    }
  }

  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS)) {
    try {
      await windowManager.ensureInitialized();
      WindowOptions windowOptions = const WindowOptions(
        size: kDesktopWindowSize,
        minimumSize: kDesktopWindowSize,
        maximumSize: kDesktopMainWindowSize,
        center: true,
        title: "ZOC",
        skipTaskbar: false,
      );
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (e) {
      print('Error al inicializar window_manager: $e');
    }
  }

  if (!kIsWeb && Platform.isWindows) {
    final SystemTray systemTray = SystemTray();
    try {
      await systemTray.initSystemTray(
        title: "ZOC",
        iconPath: "assets/app_icon.ico",
      );

      final pauseTray = _PauseTray(systemTray);
      await pauseTray.attach();

      systemTray.registerSystemTrayEventHandler((eventName) {
        if (eventName == kSystemTrayEventClick) {
          windowManager.show();
          windowManager.focus();
        } else if (eventName == kSystemTrayEventRightClick) {
          // Some inputs of the menu (e.g. "Controle de tempo" turned on by the
          // admin) change without notifying: rebuild it right before it opens.
          pauseTray._sync().whenComplete(systemTray.popUpContextMenu);
        }
      });
    } catch (e) {
      print('Error al inicializar system_tray: $e');
    }
  }

  runApp(ChangeNotifierProvider(
    create: (context) => appState,
    child: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class MyAppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

class _MyAppState extends State<MyApp> with WindowListener {
  Locale? _locale;

  ThemeMode _themeMode = ThemeMode.system;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;

  late Stream<Zoc1AuthUser> userStream;

  DateTime? _lastBlurTime;
  bool _isDialogOpen = false;

  // Desktop auto-update: re-checked on window focus and on a timer so a
  // long-lived session (no restart) still picks up new releases.
  static const Duration _updateCheckInterval = Duration(hours: 6);
  DateTime? _lastUpdateCheck;
  Timer? _updateCheckTimer;

  void _maybeCheckForDesktopUpdate() {
    if (kIsWeb || !(Platform.isWindows || Platform.isMacOS)) return;
    final now = DateTime.now();
    if (_lastUpdateCheck != null &&
        now.difference(_lastUpdateCheck!) < _updateCheckInterval) {
      return;
    }
    _lastUpdateCheck = now;
    final context = navigatorKey.currentContext;
    if (context != null) {
      checkAndPromptDesktopUpdate(context: context);
    }
  }

  void setDialogOpen(bool isOpen) => safeSetState(() => _isDialogOpen = isOpen);

  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e as RouteMatch))
          .toList();

  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier, navigatorKey: navigatorKey);

    final initialUser = zoc1AuthUserSubject.value;
    _appStateNotifier.update(initialUser);
    _appStateNotifier.stopShowingSplashImage();

    userStream = zoc1AuthUserStream()
      ..listen((user) {
        if (kDebugMode) {
          print(
              'DEBUG: User stream updated - loggedIn: ${user.loggedIn}, uid: ${user.uid}');
        }
        _appStateNotifier.update(user);
      });

    Future.microtask(() async {
      try {
        final hasStoredSession = authManager.authenticationToken != null &&
            authManager.authenticationToken!.isNotEmpty;

        if (hasStoredSession) {
          final refreshed = await AuthSession.refreshAccessToken();
          if (!refreshed) {
            await authManager.signOut();
            ApiManager.syncAccessToken(null);
          }
        }

        final user = zoc1AuthUserSubject.value;
        _appStateNotifier.update(user);
        _appStateNotifier.stopShowingSplashImage();
        ApiManager.syncAccessToken(authManager.authenticationToken);

        if (!user.loggedIn) {
          _router.go('/login');
        }
      } catch (e) {
        if (kDebugMode) {
          print('DEBUG: Error en inicialización: $e');
        }
        _appStateNotifier.update(Zoc1AuthUser(loggedIn: false));
        _appStateNotifier.stopShowingSplashImage();
        _router.go('/login');
      }

      if (!kIsWeb && (Platform.isWindows || Platform.isMacOS)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _lastUpdateCheck = DateTime.now();
          final context = navigatorKey.currentContext;
          if (context != null) {
            checkAndPromptDesktopUpdate(context: context);
          }
        });
      }
    });

    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS)) {
      windowManager.addListener(this);
      _updateCheckTimer = Timer.periodic(
        _updateCheckInterval,
        (_) => _maybeCheckForDesktopUpdate(),
      );
    }
  }

  @override
  void dispose() {
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS)) {
      windowManager.removeListener(this);
      _updateCheckTimer?.cancel();
    }
    super.dispose();
  }

  @override
  void onWindowFocus() {
    if (_lastBlurTime != null) {
      DateTime.now().difference(_lastBlurTime!);
    }
    _maybeCheckForDesktopUpdate();
  }

  @override
  void onWindowBlur() {
    _lastBlurTime = DateTime.now();
  }

  @override
  void onWindowMinimize() {
    // Only Windows has a tray icon to bring a hidden window back.
    if (Platform.isWindows &&
        !_isDialogOpen &&
        !FFAppState().isPopupVisible) {
      windowManager.hide();
    }
  }

  @override
  void onWindowRestore() {
    windowManager.show();
    windowManager.focus();
  }

  void setLocale(String language) {
    safeSetState(() => _locale = createLocale(language));
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'zoc',
      scrollBehavior: MyAppScrollBehavior(),
      localizationsDelegates: const [
        FFLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FallbackMaterialLocalizationDelegate(),
        FallbackCupertinoLocalizationDelegate(),
      ],
      locale: _locale,
      supportedLocales: const [
        Locale('pt'),
        Locale('en'),
      ],
      theme: zocThemeData(),
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}

/// Windows tray menu. Rebuilt when the pause state changes: "Pausar registros"
/// submenu while working, "Retomar registros" on top while paused.
class _PauseTray {
  _PauseTray(this.tray);

  final SystemTray tray;
  final PauseController pauses = PauseController.instance;
  String? _shape;

  Future<void> attach() async {
    pauses.addListener(_sync);
    FFAppState().addListener(_sync);
    await _sync();
  }

  bool get _signedIn => (authManager.authenticationToken ?? '').isNotEmpty;

  Future<void> _sync() async {
    final pause = pauses.pause;
    final canPause = _signedIn &&
        pauses.available &&
        pause == null &&
        isTimeTrackingEnabled();
    final end = pause?.plannedEndAt;
    final tooltip = pause == null
        ? 'ZOC'
        : end == null
            ? 'ZOC · Em pausa'
            : 'ZOC · Em pausa até ${pauseClock(end)}';
    final shape = '${pause != null}|$canPause|$tooltip';
    if (shape == _shape) return;
    _shape = shape;
    try {
      await tray.setToolTip(tooltip);
      final menu = Menu();
      await menu.buildFrom([
        if (pause != null)
          MenuItemLabel(
            label: 'Retomar registros',
            onClicked: (_) => _run(pauses.resume),
          ),
        MenuItemLabel(label: 'Abrir', onClicked: (_) => _showWindow()),
        if (canPause)
          SubMenu(label: 'Pausar registros', children: [
            for (final (label, minutes) in const [
              ('15 min', 15),
              ('30 min', 30),
              ('1 hora', 60),
            ])
              MenuItemLabel(
                label: label,
                onClicked: (_) =>
                    _run(() => pauses.startPause(minutes: minutes)),
              ),
            MenuSeparator(),
            MenuItemLabel(
              label: 'Personalizado…',
              onClicked: (_) async {
                await _showWindow();
                pauses.requestSheet();
              },
            ),
            MenuItemLabel(
              label: 'Até eu voltar',
              onClicked: (_) => _run(() => pauses.startPause()),
            ),
          ]),
        MenuItemLabel(
          label: 'Verificar atualizações',
          onClicked: (menuItem) async {
            await _showWindow();
            final context = navigatorKey.currentContext;
            if (context != null) {
              await checkAndPromptDesktopUpdate(
                context: context,
                silentIfNone: false,
              );
            }
          },
        ),
        MenuSeparator(),
        MenuItemLabel(
          label: 'Encerrar sessão',
          onClicked: (menuItem) async {
            await AuthSession.logout();
            FFAppState().UserData = null;
            FFAppState().email = '';
            FFAppState().isPopupVisible = false;
            final context = navigatorKey.currentContext;
            if (context != null) {
              await context.pushNamed(LoginWidget.routeName);
            }
            await windowManager.hide();
          },
        ),
        MenuItemLabel(
          label: 'Sair',
          onClicked: (menuItem) async {
            final hasSession = authManager.authenticationToken != null;
            final context = navigatorKey.currentContext;
            if (hasSession && context != null) {
              await _showWindow();
              await context.pushNamed(ConfirmaLogoutWidget.routeName);
            } else if (!hasSession) {
              exit(0);
            }
          },
        ),
      ]);
      await tray.setContextMenu(menu);
    } catch (e) {
      _shape = null;
      debugPrint('system_tray menu: $e');
    }
  }

  Future<void> _showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  /// Runs a pause action from the tray. A record popup on screen comes
  /// first: answering it would close the pause on the server anyway.
  Future<void> _run(Future<PauseActionResult> Function() action) async {
    if (FFAppState().isPopupVisible) {
      await _showWindow();
      return;
    }
    final result = await action();
    if (result == PauseActionResult.ok) return;
    await _showWindow();
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(pauseErrorMessage(result))));
  }
}
