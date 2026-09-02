import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:window_manager/window_manager.dart';
import 'package:system_tray/system_tray.dart';
import 'dart:io' show Platform, exit;

import 'auth/custom_auth/auth_util.dart';
import 'auth/custom_auth/custom_auth_user_provider.dart';

import '/backend/supabase/supabase.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'flutter_flow/internationalization.dart';
import 'index.dart';

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
        size: Size(510, 435),
        minimumSize: Size(510, 435),
        maximumSize: Size(600, 600),
        center: true,
        title: "Zoc",
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
        title: "Zoc",
        iconPath: "assets/app_icon.ico",
      );

      final Menu menu = Menu();
      await menu.buildFrom([
        MenuItemLabel(
          label: 'Abrir',
          onClicked: (menuItem) async {
            await windowManager.show();
            await windowManager.focus();
          },
        ),
        MenuItemLabel(
          label: 'Cerrar sesión',
          onClicked: (menuItem) async {
            await authManager.signOut();
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
          label: 'Salir',
          onClicked: (menuItem) async {
            final hasSession = authManager.authenticationToken != null;
            final context = navigatorKey.currentContext;
            if (hasSession && context != null) {
              await windowManager.show();
              await windowManager.focus();
              await context.pushNamed(ConfirmaLogoutWidget.routeName);
            } else if (!hasSession) {
              exit(0);
            }
          },
        ),
      ]);

      await systemTray.setContextMenu(menu);

      systemTray.registerSystemTrayEventHandler((eventName) {
        if (eventName == kSystemTrayEventClick) {
          windowManager.show();
          windowManager.focus();
        } else if (eventName == kSystemTrayEventRightClick) {
          systemTray.popUpContextMenu();
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
        await authManager.signOut();
        _appStateNotifier.update(Zoc1AuthUser(loggedIn: false));
        _appStateNotifier.stopShowingSplashImage();
        _router.go('/login');
      } catch (e) {
        if (kDebugMode) {
          print('DEBUG: Error en inicialización: $e');
        }
        _appStateNotifier.update(Zoc1AuthUser(loggedIn: false));
        _appStateNotifier.stopShowingSplashImage();
        _router.go('/login');
      }
    });

    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS)) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS)) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowFocus() {
    if (_lastBlurTime != null) {
      DateTime.now().difference(_lastBlurTime!);
    }
  }

  @override
  void onWindowBlur() {
    _lastBlurTime = DateTime.now();
  }

  @override
  void onWindowMinimize() {
    if (!_isDialogOpen) {
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
      title: 'Zoc1',
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
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: false,
      ),
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}
