import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:zoc/backend/api_requests/api_manager.dart';
import 'package:zoc/desktop/pause_controller.dart';
import 'package:zoc/desktop/pause_sheet.dart';
import 'package:zoc/flutter_flow/flutter_flow_util.dart';
import 'package:zoc/flutter_flow/internationalization.dart';
import 'package:zoc/logout/logout_widget.dart';
import 'package:zoc/pages/popup_dialog/popup_dialog_widget.dart';
import 'package:zoc/ui/zoc_ui.dart';

http.Response response(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json; charset=utf-8'});

Widget host(Widget child) => ChangeNotifierProvider.value(
      value: FFAppState(),
      child: MaterialApp(
        theme: zocThemeData(),
        locale: const Locale('pt'),
        localizationsDelegates: const [
          FFLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('pt'), Locale('en')],
        home: Scaffold(body: child),
      ),
    );

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Map<String, dynamic> pauseJson(
        {int? minutes = 30, String? reason, required DateTime started}) =>
    {
      'id': 'p1',
      'started_at': started.toUtc().toIso8601String(),
      'planned_end_at': minutes == null
          ? null
          : started.add(Duration(minutes: minutes)).toUtc().toIso8601String(),
      'reason': reason,
      'overdue': false,
    };

Map<String, dynamic> me(Map<String, dynamic>? pause) => {
      'status': pause == null ? 'active' : 'paused',
      'server_time': DateTime.now().toUtc().toIso8601String(),
      'login_at': null,
      'last_seen_at': null,
      'pause': pause,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage;
  late List<http.Request> requests;
  late List<Map<String, dynamic>> entries;

  /// Server-side pause; the presence routes answer with it.
  Map<String, dynamic>? serverPause;
  int presenceStatus = 200;
  bool offline = false;

  final client = MockClient((request) async {
    final path = request.url.path;
    if (path.contains('/presence/')) {
      requests.add(request);
      if (offline) throw http.ClientException('offline');
      if (presenceStatus != 200) return response({}, presenceStatus);
      if (path.endsWith('/pause')) {
        final body = jsonDecode(request.body) as Map;
        serverPause = pauseJson(
            minutes: body['minutes'] as int?,
            reason: body['reason'] as String?,
            started: DateTime.now());
        return response(me(serverPause), 201);
      }
      if (path.endsWith('/pause/extend')) {
        final p = PresencePause.tryParse(serverPause)!;
        serverPause = {
          ...serverPause!,
          'planned_end_at': p.plannedEndAt!
              .add(
                  Duration(minutes: jsonDecode(request.body)['minutes'] as int))
              .toIso8601String(),
        };
      }
      if (path.endsWith('/resume')) serverPause = null;
      return response(me(serverPause));
    }
    if (request.method == 'POST' && path.contains('timemanager/entries')) {
      entries.add(jsonDecode(request.body) as Map<String, dynamic>);
      return response({});
    }
    if (path.contains('work-hours')) return response(3.5);
    if (path.contains('work-goal')) {
      return response({'period': 'today', 'goal_hours': 8.0});
    }
    if (path.contains('assignments/projects')) {
      return response([
        {'id': 'p1', 'name': 'Folha de pagamento', 'client_id': 'c1'},
      ]);
    }
    if (path.contains('clients')) {
      return response([
        {'id': 'c1', 'name': 'Acme Ltda'}
      ]);
    }
    return response({});
  });

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    storage = await Directory.systemTemp.createTemp('zoc-pause-test-');
    Hive.init(storage.path);
    await Hive.openBox('zoc_app_storage', bytes: Uint8List(0));
    await FFAppState().initializePersistedState();

    final font = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    const codec = StandardMessageCodec();
    final manifest =
        (codec.decodeMessage(await rootBundle.load('AssetManifest.bin')) as Map)
            .cast<Object?, Object?>();
    final fonts = [
      for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold'])
        'Inter-$weight.ttf'
    ];
    for (final name in fonts) {
      manifest[name] = [
        {'asset': name}
      ];
    }
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        const MethodChannel('window_manager'), (_) async => null);
    messenger.setMockMessageHandler('flutter/assets', (message) async {
      final asset = utf8.decode(message!.buffer.asUint8List());
      if (asset == 'AssetManifest.bin') return codec.encodeMessage(manifest);
      if (fonts.contains(asset)) return font;
      final file = File('${Platform.environment['UNIT_TEST_ASSETS']}/$asset');
      return file.existsSync()
          ? ByteData.view(file.readAsBytesSync().buffer)
          : null;
    });
    GoogleFonts.config.allowRuntimeFetching = false;
    messenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => storage.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await storage.delete(recursive: true);
  });

  setUp(() {
    FFAppState().UserData = {
      'user': {
        'id': 'u1',
        'first_name': 'Maria',
        'last_name': 'Souza',
        'monitoring': true,
        'monitoring_period': 1,
        'screenshots_enabled': false,
      }
    };
    FFAppState().isRemote = true;
    FFAppState().isPopupVisible = false;
    FFAppState().presencePause = null;
    ApiManager.syncAccessToken('test-token');
    PauseController.instance = PauseController();
    requests = [];
    entries = [];
    serverPause = null;
    presenceStatus = 200;
    offline = false;
  });

  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(540, 650);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host(const LogoutWidget()));
    await settle(tester);
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  /// Answers the login-time record popup with "Ignorar".
  Future<void> ignorePopup(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 1));
    await settle(tester);
    expect(find.byType(PopupDialogWidget), findsOneWidget);
    await tester.tap(find.text('Ignorar'));
    await settle(tester);
  }

  testWidgets('sheet: 1 hora + reason, then "Até eu voltar" without reason',
      (tester) async {
    await http.runWithClient(() async {
      await pumpHome(tester);
      await ignorePopup(tester);
      expect(find.text('Pausar'), findsOneWidget);
      expect(find.text('Registrar agora'), findsOneWidget);

      await tester.tap(find.text('Pausar'));
      await settle(tester);
      expect(find.text('Pausar registros'), findsOneWidget);
      // No reason is preselected.
      expect(find.byIcon(Icons.check_rounded), findsNothing);
      await tester.tap(find.text('1 hora'));
      await tester.tap(find.text('Almoço'));
      await settle(tester);
      final back = pauseClock(DateTime.now().add(const Duration(hours: 1)));
      expect(find.text('Volta prevista às  $back', findRichText: true),
          findsOneWidget);
      await tester.tap(find.widgetWithText(ZocButton, 'Pausar').last);
      await settle(tester);

      expect(
          jsonDecode(requests.last.body), {'minutes': 60, 'reason': 'almoco'});
      expect(find.text('Pausar registros'), findsNothing);
      expect(PauseController.instance.isPaused, isTrue);
      expect(find.text('Em pausa · Almoço'), findsOneWidget);
      expect(find.text('Registrar agora'), findsNothing);
      expect(find.text('Volta prevista às $back'), findsOneWidget);

      await tester.tap(find.text('Retomar agora'));
      await settle(tester);
      expect(PauseController.instance.isPaused, isFalse);
      // Resuming records right away, like a login.
      await ignorePopup(tester);

      await tester.tap(find.text('Pausar'));
      await settle(tester);
      await tester.tap(find.text('Até eu voltar'));
      await settle(tester);
      expect(find.text('Sem horário de volta'), findsOneWidget);
      await tester.tap(find.widgetWithText(ZocButton, 'Pausar').last);
      await settle(tester);
      expect(jsonDecode(requests.last.body), {'minutes': null, 'reason': null});
      expect(find.textContaining('Em pausa desde'), findsOneWidget);
      expect(find.text('+15 min'), findsNothing);
      await unmount(tester);
    }, () => client);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sheet: custom stepper stops at 8 h', (tester) async {
    tester.view.physicalSize = const Size(540, 650);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await http.runWithClient(() async {
      await tester.pumpWidget(host(Builder(
          builder: (context) => TextButton(
              onPressed: () => showPauseSheet(context, resizeWindow: false),
              child: const Text('open')))));
      await tester.tap(find.text('open'));
      await settle(tester);
      await tester.tap(find.text('Personalizado'));
      await settle(tester);
      expect(find.text('Até 8 h'), findsOneWidget);
      for (var i = 0; i < 10; i++) {
        await tester.tap(find.byTooltip('Mais h'));
        await tester.pump();
      }
      await settle(tester);
      // 8 h 30 min would pass the limit: minutes drop to 0, "+" turns off.
      expect(find.text('8 h', findRichText: true), findsOneWidget);
      expect(find.text('0 min', findRichText: true), findsOneWidget);
      await tester.tap(find.byTooltip('Mais min'));
      await tester.pump();
      expect(find.text('0 min', findRichText: true), findsOneWidget);
      await tester.tap(find.widgetWithText(ZocButton, 'Pausar'));
      await settle(tester);
      expect(
          jsonDecode(requests.single.body), {'minutes': 480, 'reason': null});
      await unmount(tester);
    }, () => client);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sheet: network error shows a snackbar and stays unpaused',
      (tester) async {
    await http.runWithClient(() async {
      await pumpHome(tester);
      await ignorePopup(tester);
      offline = true;
      await tester.tap(find.text('Pausar'));
      await settle(tester);
      await tester.tap(find.widgetWithText(ZocButton, 'Pausar').last);
      await settle(tester);
      expect(find.text('Sem conexão, tente de novo.'), findsOneWidget);
      expect(PauseController.instance.isPaused, isFalse);
      expect(find.text('Registrar agora'), findsOneWidget);
      await unmount(tester);
    }, () => client);
    expect(tester.takeException(), isNull);
  });

  testWidgets('paused home: countdown, +15 min, no popups while paused',
      (tester) async {
    serverPause = pauseJson(
        minutes: 60,
        reason: 'almoco',
        started: DateTime.now().subtract(const Duration(minutes: 37)));
    FFAppState().presencePause = serverPause;
    PauseController.instance.restoreFromCache();
    await http.runWithClient(() async {
      await pumpHome(tester);
      expect(find.text('Em pausa · Trabalho remoto'), findsOneWidget);
      expect(find.text('Em pausa · Almoço'), findsOneWidget);
      expect(find.text('faltam 23 min'), findsOneWidget);
      expect(find.text('Registrar agora'), findsNothing);
      expect(find.text('Pausar'), findsNothing);
      expect(find.textContaining('a pausa não conta'), findsOneWidget);

      await tester.tap(find.text('+15 min'));
      await settle(tester);
      expect(requests.last.url.path, '/api/v1/presence/pause/extend');
      expect(find.text('faltam 38 min'), findsOneWidget);

      // monitoring_period is 1 min: two periods pass without any popup.
      await tester.pump(const Duration(minutes: 2));
      await settle(tester);
      expect(find.byType(PopupDialogWidget), findsNothing);
      expect(entries, isEmpty);
      await unmount(tester);
    }, () => client);
    expect(tester.takeException(), isNull);
  });

  testWidgets('paused home: indefinite pause counts up', (tester) async {
    serverPause = pauseJson(
        minutes: null,
        started: DateTime.now().subtract(const Duration(minutes: 80)));
    FFAppState().presencePause = serverPause;
    PauseController.instance.restoreFromCache();
    await http.runWithClient(() async {
      await pumpHome(tester);
      expect(find.text('há 1 h 20 min'), findsOneWidget);
      expect(find.text('Sem horário de volta'), findsOneWidget);
      expect(find.text('+15 min'), findsNothing);
      expect(find.text('Retomar agora'), findsOneWidget);
      await unmount(tester);
    }, () => client);
    expect(tester.takeException(), isNull);
  });

  testWidgets('return dialog: expired pause on start, Mais 15 then Sim voltei',
      (tester) async {
    serverPause = pauseJson(
        minutes: 30,
        reason: 'almoco',
        started: DateTime.now().subtract(const Duration(minutes: 31)));
    FFAppState().presencePause = serverPause;
    PauseController.instance.restoreFromCache();
    await http.runWithClient(() async {
      await pumpHome(tester);
      await tester.pump(const Duration(seconds: 1));
      await settle(tester);
      expect(find.text('Já voltou?'), findsOneWidget);
      expect(find.textContaining('Pausa de 30 min'), findsOneWidget);
      expect(find.textContaining('Almoço'), findsWidgets);

      await tester.tap(find.text('Mais 15 min'));
      await settle(tester);
      expect(requests.last.url.path, '/api/v1/presence/pause/extend');
      expect(find.text('Já voltou?'), findsNothing);
      expect(PauseController.instance.isExpired, isFalse);

      // The extension ends too: the dialog comes back, no popup meanwhile.
      serverPause = {
        ...serverPause!,
        'planned_end_at': DateTime.now()
            .subtract(const Duration(seconds: 1))
            .toUtc()
            .toIso8601String(),
      };
      await PauseController.instance.refresh();
      await tester.pump(const Duration(seconds: 1));
      await settle(tester);
      expect(find.text('Já voltou?'), findsOneWidget);
      expect(find.byType(PopupDialogWidget), findsNothing);

      await tester.tap(find.text('Sim, voltei'));
      await settle(tester);
      expect(requests.last.url.path, '/api/v1/presence/resume');
      expect(find.text('Já voltou?'), findsNothing);
      // The record popup opens right away.
      await ignorePopup(tester);
      expect(entries.single['ignored_popup'], isTrue);
      await unmount(tester);
    }, () => client);
    expect(tester.takeException(), isNull);
  });

  testWidgets('time tracking off or old API: no Pausar button', (tester) async {
    FFAppState().UserData = {
      'user': {'id': 'u1', 'first_name': 'Maria', 'monitoring': false}
    };
    await http.runWithClient(() async {
      await pumpHome(tester);
      expect(PauseController.instance.available, isTrue);
      expect(find.text('Pausar'), findsNothing);
      expect(find.text('Controle de tempo desativado'), findsOneWidget);
      await unmount(tester);

      FFAppState().UserData = {
        'user': {'id': 'u1', 'first_name': 'Maria', 'monitoring': true}
      };
      PauseController.instance = PauseController();
      presenceStatus = 404;
      requests.clear();
      await pumpHome(tester);
      await ignorePopup(tester);
      expect(PauseController.instance.off, isTrue);
      expect(find.text('Pausar'), findsNothing);
      expect(find.text('Registrar agora'), findsOneWidget);
      // Heartbeats stop after the 404.
      await tester.pump(const Duration(seconds: 61));
      await settle(tester);
      expect(requests, hasLength(1));
      await unmount(tester);
    }, () => client);
    expect(tester.takeException(), isNull);
  });
}
