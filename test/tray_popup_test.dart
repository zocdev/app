import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:zoc/backend/api_requests/api_manager.dart';
import 'package:zoc/flutter_flow/flutter_flow_util.dart';
import 'package:zoc/flutter_flow/internationalization.dart';
import 'package:zoc/expediente/expediente_widget.dart';
import 'package:zoc/logout/logout_widget.dart';
import 'package:zoc/pages/popup_dialog/popup_dialog_widget.dart';
import 'package:zoc/ui/zoc_ui.dart';

http.Response response(Object body) => http.Response(jsonEncode(body), 200,
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage;
  late MockClient client;
  late List<Map<String, dynamic>> entries;

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    storage = await Directory.systemTemp.createTemp('zoc-tray-test-');
    Hive.init(storage.path);
    // In memory: a widget test stores app state from fake-async code, where a
    // file write never finishes and Hive.close() in tearDownAll would wait forever.
    await Hive.openBox('zoc_app_storage', bytes: Uint8List(0));
    await FFAppState().initializePersistedState();

    // Font requests use the bundled test font, with no network dependency.
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
    messenger.setMockMethodCallHandler(
        const MethodChannel('com.ryanheise.just_audio.methods'), (call) async {
      if (call.method == 'init') {
        final id = (call.arguments as Map)['id'];
        messenger.setMockMethodCallHandler(
            MethodChannel('com.ryanheise.just_audio.methods.$id'),
            (call) async => call.method == 'load'
                ? {'duration': 1000000}
                : <String, dynamic>{});
        for (final kind in ['events', 'data']) {
          messenger.setMockMethodCallHandler(
              MethodChannel('com.ryanheise.just_audio.$kind.$id'),
              (_) async => null);
        }
      }
      return <String, dynamic>{};
    });
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
    ApiManager.syncAccessToken('test-token');
    entries = [];
    client = MockClient((request) async {
      final path = request.url.path;
      if (request.method == 'POST' && path.contains('timemanager/entries')) {
        entries.add(jsonDecode(request.body) as Map<String, dynamic>);
        return response({});
      }
      if (path.contains('work-hours')) return response(3.5);
      if (path.contains('assignments/projects')) {
        return response([
          {'id': 'p1', 'name': 'Folha de pagamento', 'client_id': 'c1'},
        ]);
      }
      if (path.contains('clients')) {
        return response([
          {'id': 'c1', 'name': 'Acme Ltda'},
          // No project of this client is assigned to the member.
          {'id': 'c2', 'name': 'Seres Baum'},
        ]);
      }
      if (path.contains('tasks/app/project')) {
        return response([
          {'id': 't1', 'name': 'Conferir lançamentos'},
          {'id': 't2', 'name': 'Ajustes'},
        ]);
      }
      return response({});
    });
  });

  testWidgets('Registrar agora uses the popup path and restarts its interval',
      (tester) async {
    tester.view.physicalSize = const Size(510, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await http.runWithClient(() async {
      // The login-time popup is already on screen when this page mounts.
      FFAppState().isPopupVisible = true;
      await tester.pumpWidget(host(const LogoutWidget()));
      await settle(tester);
      FFAppState().update(() => FFAppState().isPopupVisible = false);
      await tester.pump(const Duration(seconds: 30));
      expect(find.text('3h 30min'), findsOneWidget);
      expect(find.text('44%'), findsOneWidget);

      await tester.tap(find.text('Registrar agora'));
      await tester.pump(const Duration(seconds: 1));
      await settle(tester);
      expect(find.byType(PopupDialogWidget), findsOneWidget);
      await tester.tap(find.text('Ignorar'));
      await settle(tester);
      expect(entries.single['ignored_popup'], isTrue);
      expect(find.byType(PopupDialogWidget), findsNothing);

      // The old timer would fire at 60s from mount. The new one waits a full
      // minute from the manual record, which occurred at roughly 30s.
      await tester.pump(const Duration(seconds: 31));
      expect(find.byType(PopupDialogWidget), findsNothing);
      await tester.pump(const Duration(seconds: 29));
      await tester.pump(const Duration(seconds: 1));
      await settle(tester);
      expect(find.byType(PopupDialogWidget), findsOneWidget);
      await tester.tap(find.text('Ignorar'));
      await settle(tester);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }, () => client);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changing report period blocks export until current records load',
      (tester) async {
    tester.view.physicalSize = const Size(620, 660);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final month = Completer<http.Response>();
    client = MockClient((request) async {
      if (request.url.path.contains('tasks/user/done')) {
        if (request.url.queryParameters['period'] == 'month') {
          return month.future;
        }
        return response([
          {'task_name': 'Registro do dia', 'hours': 1}
        ]);
      }
      if (request.url.path.contains('work-hours')) return response(1);
      if (request.url.path.contains('ignored')) return response(0);
      return response({});
    });
    Finder exportButton() => find.descendant(
        of: find.byTooltip('Exportar PDF'), matching: find.byType(InkWell));
    await http.runWithClient(() async {
      await tester.pumpWidget(host(const ExpedienteWidget()));
      await settle(tester);
      expect(find.text('Registro do dia'), findsOneWidget);
      expect(tester.widget<InkWell>(exportButton()).onTap, isNotNull);

      await tester.tap(find.text('Mês'));
      await settle(tester);
      expect(tester.widget<InkWell>(exportButton()).onTap, isNull);
      expect(find.text('Registro do dia'), findsNothing);

      month.complete(response([
        {'task_name': 'Registro do mês', 'hours': 5}
      ]));
      await settle(tester);
      expect(find.text('Registro do mês'), findsOneWidget);
      expect(tester.widget<InkWell>(exportButton()).onTap, isNotNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }, () => client);
    expect(tester.takeException(), isNull);
  });

  testWidgets('popup keeps validation, chips, remote choice and save payload',
      (tester) async {
    tester.view.physicalSize = const Size(510, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final screenshot =
        'data:image/png;base64,${base64Encode(File('assets/images/ZOC_wordmark.png').readAsBytesSync())}';
    await http.runWithClient(() async {
      await tester.pumpWidget(host(Builder(
          builder: (context) => TextButton(
                onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) =>
                        PopupDialogWidget(screenshotBase64: screenshot)),
                child: const Text('open'),
              ))));
      await tester.tap(find.text('open'));
      await settle(tester);
      await tester.tap(find.text('Salvar registro'));
      await settle(tester);
      expect(find.text('Cliente é necessario.'), findsOneWidget);
      await tester.tap(find.text('Ok'));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('popup-client')));
      await settle(tester);
      await tester.tap(find.text('Acme Ltda').last);
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('popup-project')));
      await settle(tester);
      await tester.tap(find.text('Folha de pagamento').last);
      await settle(tester);
      await tester.tap(find.text('Escolha a atividade'));
      await settle(tester);
      await tester.tap(find.text('Ajustes'));
      // Single select: selecting another activity deselects the previous one.
      await tester.tap(find.text('Conferir lançamentos'));
      await tester.tap(find.text('Concluir'));
      await settle(tester);
      expect(find.byType(InputChip), findsOneWidget);
      expect(find.text('Conferir lançamentos'), findsOneWidget);
      expect(find.text('Ajustes'), findsNothing);
      await tester.enterText(
          find.byType(TextFormField), 'Conferência de outubro');
      await tester.tap(find.text('Trabalho remoto'));
      await tester.tap(find.text('Salvar registro'));
      await settle(tester);
      expect(entries.single['tasks'], ['t1']);
      expect(entries.single['project_id'], 'p1');
      expect(entries.single['notes'], 'Conferência de outubro');
      expect(entries.single['remote'], isFalse);
      expect(entries.single['ignored_popup'], isFalse);
      expect(entries.single['screenshot'], screenshot);
      expect(find.byType(PopupDialogWidget), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }, () => client);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'auto-ignore closes the activity picker and records one ignored entry',
      (tester) async {
    tester.view.physicalSize = const Size(510, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await http.runWithClient(() async {
      await tester.pumpWidget(host(Builder(
          builder: (context) => TextButton(
                onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const PopupDialogWidget(
                        ignoreAfter: Duration(seconds: 8))),
                child: const Text('open'),
              ))));
      await tester.tap(find.text('open'));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('popup-client')));
      await settle(tester);
      await tester.tap(find.text('Acme Ltda').last);
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('popup-project')));
      await settle(tester);
      await tester.tap(find.text('Folha de pagamento').last);
      await settle(tester);
      await tester.tap(find.text('Escolha a atividade'));
      await settle(tester);
      expect(find.text('Concluir'), findsOneWidget);
      await tester.pump(const Duration(seconds: 8));
      await settle(tester);
      expect(find.text('Concluir'), findsNothing);
      expect(find.byType(PopupDialogWidget), findsNothing);
      expect(entries.single['ignored_popup'], isTrue);
      expect(FFAppState().isPopupVisible, isFalse);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }, () => client);
    expect(tester.takeException(), isNull);
  });

  testWidgets('popup lists only clients with a project assigned to the member',
      (tester) async {
    tester.view.physicalSize = const Size(510, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var assigned = <Map<String, dynamic>>[];
    final scoped = MockClient((request) async {
      if (request.url.path.contains('assignments/projects')) {
        return response(assigned);
      }
      return client.send(request).then(http.Response.fromStream);
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(host(Builder(
          builder: (context) => TextButton(
                onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const PopupDialogWidget()),
                child: const Text('open'),
              ))));
      await tester.tap(find.text('open'));
      await settle(tester);
      expect(find.byKey(const ValueKey('popup-no-projects')), findsOneWidget);

      // The admin assigns the member; refreshing brings the client in.
      assigned = [
        {'id': 'p1', 'name': 'Folha de pagamento', 'client_id': 'c1'},
      ];
      await tester.tap(find.byTooltip('Atualizar clientes e projetos'));
      await settle(tester);
      expect(find.byKey(const ValueKey('popup-no-projects')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('popup-client')));
      await settle(tester);
      expect(find.text('Acme Ltda'), findsWidgets);
      expect(find.text('Seres Baum'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }, () => scoped);
    expect(tester.takeException(), isNull);
  });
}
