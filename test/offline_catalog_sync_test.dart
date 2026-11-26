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

import 'package:zoc/auth/auth_session.dart';
import 'package:zoc/auth/custom_auth/auth_util.dart';
import 'package:zoc/auth/custom_auth/custom_auth_user_provider.dart';
import 'package:zoc/backend/api_requests/api_manager.dart';
import 'package:zoc/desktop/add_time_dialog.dart';
import 'package:zoc/desktop/pause_controller.dart';
import 'package:zoc/flutter_flow/flutter_flow_util.dart';
import 'package:zoc/flutter_flow/internationalization.dart';
import 'package:zoc/logout/logout_widget.dart';
import 'package:zoc/pages/popup_dialog/popup_dialog_widget.dart';
import 'package:zoc/ui/zoc_ui.dart';
import 'package:zoc/utils/catalog_cache_service.dart';
import 'package:zoc/utils/offline_sync_service.dart';

http.Response jsonOk(Object body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Widget testHost(Widget child) => ChangeNotifierProvider.value(
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
  late Directory storageDir;

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    storageDir = await Directory.systemTemp.createTemp('zoc-offline-test-');
    Hive.init(storageDir.path);
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
        (_) async => storageDir.path);
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
    await storageDir.delete(recursive: true);
  });

  setUp(() async {
    await Hive.box('zoc_app_storage').clear();
    CatalogCacheService.instance.resetForTest();
    OfflineSyncService.instance.resetForTest();
    PauseController.instance =
        PauseController(readCache: () => null, writeCache: (_) {});
    ApiManager.configureAuthSession(
      accessTokenGetter: () => authManager.authenticationToken,
      tokenRefresher: AuthSession.refreshAccessToken,
      onUnauthorized: AuthSession.handleUnauthorized,
    );
    await authManager.signIn(
      authenticationToken: 'access-1',
      refreshToken: 'refresh-1',
      tokenExpiration: DateTime.now().add(const Duration(hours: 1)),
      authUid: 'u1',
    );
    ApiManager.syncAccessToken('access-1');
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
    FFAppState().clientsOptions = [];
    FFAppState().projectOptions = [];
    FFAppState().taskOptions = [];
    FFAppState().isRemote = true;
    FFAppState().isPopupVisible = false;
  });

  group('CatalogCacheService', () {
    test('extracts clients, projects, and all project tasks and restores offline',
        () async {
      var offline = false;
      final taskRequests = <String>[];
      final client = MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer access-1');
        if (offline) throw const SocketException('offline');
        final path = request.url.path;
        if (path.contains('/clients')) {
          return jsonOk([
            {'id': 'c1', 'name': 'Acme Ltda'},
          ]);
        }
        if (path.contains('/assignments/projects/user/u1')) {
          return jsonOk([
            {'id': 'p1', 'name': 'Projeto Alpha', 'client_id': 'c1'},
            {'id': 'p2', 'name': 'Projeto Beta', 'client_id': 'c1'},
          ]);
        }
        if (path.contains('/tasks/app/project/p1')) {
          taskRequests.add('p1');
          return jsonOk([
            {'id': 't1', 'name': 'Tarefa 1', 'project_id': 'p1'},
          ]);
        }
        if (path.contains('/tasks/app/project/p2')) {
          taskRequests.add('p2');
          return jsonOk([
            {'id': 't2', 'name': 'Tarefa 2', 'project_id': 'p2'},
          ]);
        }
        return jsonOk({});
      });

      await http.runWithClient(() async {
        final first = await CatalogCacheService.instance.sync();
        expect(first.succeeded, isTrue);
        expect(taskRequests, containsAll(['p1', 'p2']));
        expect(FFAppState().clientsOptions, hasLength(1));
        expect(FFAppState().projectOptions, hasLength(2));
        expect(CatalogCacheService.instance.tasksForProject('p1').single['name'],
            'Tarefa 1');
        expect(CatalogCacheService.instance.tasksForProject('p2').single['name'],
            'Tarefa 2');

        // Simulate app restart while offline: memory cleared, then restored from Hive.
        CatalogCacheService.instance.resetForTest();
        FFAppState().clientsOptions = [];
        FFAppState().projectOptions = [];
        CatalogCacheService.instance.restoreFromCache();

        expect(FFAppState().clientsOptions.single.name, 'Acme Ltda');
        expect(FFAppState().projectOptions, hasLength(2));
        expect(CatalogCacheService.instance.tasksForProject('p1').single['name'],
            'Tarefa 1');

        // Sync failure while offline preserves cached clients, projects, and tasks.
        offline = true;
        final failed = await CatalogCacheService.instance.sync();
        expect(failed.succeeded, isFalse);
        expect(failed.usedCache, isTrue);
        expect(CatalogCacheService.instance.lastSyncFailed, isTrue);
        expect(FFAppState().clientsOptions, hasLength(1));
        expect(FFAppState().projectOptions, hasLength(2));
        expect(CatalogCacheService.instance.tasksForProject('p2').single['name'],
            'Tarefa 2');
      }, () => client);
    });

    test('startup keeps session when access token expired but refresh token exists',
        () async {
      await authManager.signIn(
        authenticationToken: 'expired-access',
        refreshToken: 'valid-refresh',
        tokenExpiration: DateTime.now().subtract(const Duration(minutes: 10)),
        authUid: 'u1',
      );
      zoc1AuthUserSubject.add(Zoc1AuthUser(loggedIn: false));

      await authManager.initialize();

      expect(zoc1AuthUserSubject.value.loggedIn, isTrue);
      expect(authManager.refreshToken, 'valid-refresh');
    });
  });

  group('Offline popup + sync queue', () {
    testWidgets(
        'popup shows cached tasks without live fetch when offline, queues entry, and syncs FIFO on reconnect',
        (tester) async {
      tester.view.physicalSize = const Size(540, 650);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      var offline = false;
      var taskFetches = 0;
      final sentEntries = <Map<String, dynamic>>[];

      final client = MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/auth/refresh')) {
          if (offline) throw const SocketException('offline');
          return jsonOk({
            'access_token': 'access-2',
            'refresh_token': 'refresh-2',
            'expires_in': 3600,
          });
        }
        if (offline) throw const SocketException('offline');
        if (path.contains('/clients')) {
          return jsonOk([
            {'id': 'c1', 'name': 'Acme Ltda'},
          ]);
        }
        if (path.contains('/assignments/projects')) {
          return jsonOk([
            {'id': 'p1', 'name': 'Folha de pagamento', 'client_id': 'c1'},
          ]);
        }
        if (path.contains('/tasks/app/project/p1')) {
          taskFetches++;
          return jsonOk([
            {'id': 't1', 'name': 'Conferir lançamentos', 'project_id': 'p1'},
          ]);
        }
        if (request.method == 'POST' && path.contains('timemanager/entries')) {
          sentEntries.add(jsonDecode(request.body) as Map<String, dynamic>);
          return jsonOk({});
        }
        if (path.contains('work-hours')) return jsonOk(2.0);
        if (path.contains('work-goal')) {
          return jsonOk({'period': 'today', 'goal_hours': 8.0});
        }
        return jsonOk({});
      });

      await http.runWithClient(() async {
        // 1. Online initial sync caches clients, projects, and tasks.
        await CatalogCacheService.instance.sync();
        expect(taskFetches, 1);

        // 2. Internet goes down and token expires while offline.
        offline = true;
        await authManager.signIn(
          authenticationToken: 'access-1',
          refreshToken: 'refresh-1',
          tokenExpiration: DateTime.now().subtract(const Duration(minutes: 2)),
          authUid: 'u1',
        );

        await tester.pumpWidget(testHost(Builder(
          builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const PopupDialogWidget(),
            ),
            child: const Text('open'),
          ),
        )));

        await tester.tap(find.text('open'));
        await settle(tester);

        expect(find.byKey(const ValueKey('popup-offline-cache')), findsOneWidget);

        // Select client -> project -> activity works offline with ZERO live task fetch.
        await tester.tap(find.byKey(const ValueKey('popup-client')));
        await settle(tester);
        await tester.tap(find.text('Acme Ltda').last);
        await settle(tester);
        await tester.tap(find.byKey(const ValueKey('popup-project')));
        await settle(tester);
        await tester.tap(find.text('Folha de pagamento').last);
        await settle(tester);
        expect(taskFetches, 1);

        await tester.tap(find.text('Escolha a atividade'));
        await settle(tester);
        await tester.tap(find.text('Conferir lançamentos'));
        await tester.tap(find.text('Concluir'));
        await settle(tester);

        await tester.enterText(find.byType(TextFormField), 'Registro offline 1');
        await tester.tap(find.text('Salvar registro'));
        await settle(tester);

        expect(find.byType(PopupDialogWidget), findsNothing);
        expect(sentEntries, isEmpty);
        expect(OfflineSyncService.instance.pendingCount, 1);

        // 3. Open popup again offline and click "Ignorar" -> also queued locally.
        await tester.tap(find.text('open'));
        await settle(tester);
        await tester.tap(find.text('Ignorar'));
        await settle(tester);

        expect(OfflineSyncService.instance.pendingCount, 2);

        // 4. Internet comes back! Flushing refreshes expired token and sends FIFO.
        offline = false;
        final synced = await OfflineSyncService.instance.flush();
        expect(synced, 2);
        expect(OfflineSyncService.instance.pendingCount, 0);
        expect(authManager.authenticationToken, 'access-2');
        expect(sentEntries, hasLength(2));
        expect(sentEntries[0]['notes'], 'Registro offline 1');
        expect(sentEntries[0]['ignored_popup'], isFalse);
        expect(sentEntries[0]['tasks'], ['t1']);
        expect(sentEntries[1]['ignored_popup'], isTrue);

        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      }, () => client);
      expect(tester.takeException(), isNull);
    });

    testWidgets('LogoutWidget pre-syncs before opening popup and displays pending sync banner',
        (tester) async {
      tester.view.physicalSize = const Size(540, 650);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      var offline = true;
      var syncsOnServer = 0;
      final sentEntries = <Map<String, dynamic>>[];

      final client = MockClient((request) async {
        final path = request.url.path;
        if (offline) throw const SocketException('offline');
        if (path.contains('/clients')) {
          syncsOnServer++;
          return jsonOk([
            {'id': 'c1', 'name': 'Acme Ltda'},
          ]);
        }
        if (path.contains('/assignments/projects')) {
          return jsonOk([
            {'id': 'p1', 'name': 'Projeto X', 'client_id': 'c1'},
          ]);
        }
        if (path.contains('/tasks/app/project/p1')) {
          return jsonOk([
            {'id': 't1', 'name': 'Atividade Atualizada', 'project_id': 'p1'},
          ]);
        }
        if (request.method == 'POST' && path.contains('timemanager/entries')) {
          sentEntries.add(jsonDecode(request.body) as Map<String, dynamic>);
          return jsonOk({});
        }
        if (path.contains('work-hours')) return jsonOk(1.5);
        if (path.contains('work-goal')) {
          return jsonOk({'period': 'today', 'goal_hours': 8.0});
        }
        return jsonOk({});
      });

      await http.runWithClient(() async {
        // Queue one offline entry before mounting LogoutWidget.
        final queuedRes = await OfflineSyncService.instance.submitOrQueuePopupEntry(
          project: 'p1',
          remote: true,
          ignoredPopUp: false,
          tasksList: ['t1'],
          notes: 'Pendente antes',
        );
        expect(queuedRes.outcome, SubmitEntryOutcome.queued);

        // Keep initial login-time popup from opening automatically so we check the banner.
        FFAppState().isPopupVisible = true;
        await tester.pumpWidget(testHost(const LogoutWidget()));
        await settle(tester);
        FFAppState().update(() => FFAppState().isPopupVisible = false);

        expect(
          find.text('1 registro salvo localmente aguardando conexão'),
          findsOneWidget,
        );
        expect(find.text('Sincronizar'), findsOneWidget);

        // Reconnect and tap "Sincronizar" -> sends queued entry and removes banner.
        offline = false;
        await tester.tap(find.text('Sincronizar'));
        await settle(tester);

        expect(sentEntries, hasLength(1));
        expect(sentEntries.single['notes'], 'Pendente antes');
        expect(find.text('Sincronizar'), findsNothing);
        expect(syncsOnServer, greaterThanOrEqualTo(1));

        // Tap "Registrar agora" -> pre-sync runs before opening popup.
        final beforeTapSyncs = syncsOnServer;
        await tester.tap(find.text('Registrar agora'));
        await tester.pump(const Duration(seconds: 1));
        await settle(tester);

        expect(syncsOnServer, greaterThan(beforeTapSyncs));
        expect(find.byType(PopupDialogWidget), findsOneWidget);
        expect(
          CatalogCacheService.instance.tasksForProject('p1').single['name'],
          'Atividade Atualizada',
        );

        await tester.tap(find.text('Ignorar'));
        await settle(tester);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      }, () => client);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AddTimeDialog loads cached workspace offline and queues manual request',
        (tester) async {
      var offline = false;
      final submittedRequests = <Map<String, dynamic>>[];

      final client = MockClient((request) async {
        if (offline) throw const SocketException('offline');
        if (request.url.path == '/api/v1/time-requests/workspace') {
          return jsonOk({
            'user_id': 'u1',
            'is_admin': false,
            'projects': [
              {'id': 'p1', 'name': 'Projeto A'},
            ],
            'tasks': [
              {'id': 't1', 'name': 'Atividade 1', 'project_id': 'p1'},
            ],
          });
        }
        if (request.method == 'POST' &&
            request.url.path == '/api/v1/time-requests') {
          submittedRequests.add(jsonDecode(request.body) as Map<String, dynamic>);
          return jsonOk({'id': 'r1', 'auto_approved': false}, 201);
        }
        return jsonOk({}, 404);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(testHost(Builder(
          builder: (context) => TextButton(
            onPressed: () => showAddTimeDialog(context),
            child: const Text('open-manual'),
          ),
        )));

        // First open online caches the workspace.
        await tester.tap(find.text('open-manual'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('add-time-close')));
        await tester.pumpAndSettle();

        // Go offline: dialog still opens with cached projects/tasks and queues submit.
        offline = true;
        await tester.tap(find.text('open-manual'));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('add-time-project')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Projeto A').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('add-time-task-p1')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Atividade 1').last);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('add-time-reason')),
          'Trabalho offline manual',
        );
        await tester.ensureVisible(find.byKey(const ValueKey('add-time-submit')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('add-time-submit')));
        await tester.pumpAndSettle();

        expect(submittedRequests, isEmpty);
        expect(OfflineSyncService.instance.pendingCount, 1);
        expect(find.textContaining('Solicitação salva localmente'), findsOneWidget);

        // Reconnect and flush.
        offline = false;
        final synced = await OfflineSyncService.instance.flush();
        expect(synced, 1);
        expect(submittedRequests.single['reason'], 'Trabalho offline manual');
      }, () => client);
      expect(tester.takeException(), isNull);
    });
  });
}
