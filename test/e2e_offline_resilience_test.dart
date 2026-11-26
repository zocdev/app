import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'package:zoc/auth/auth_session.dart';
import 'package:zoc/auth/custom_auth/auth_util.dart';
import 'package:zoc/auth/custom_auth/custom_auth_user_provider.dart';
import 'package:zoc/backend/api_requests/api_config.dart';
import 'package:zoc/backend/api_requests/api_manager.dart';
import 'package:zoc/desktop/pause_controller.dart';
import 'package:zoc/flutter_flow/flutter_flow_util.dart';
import 'package:zoc/main.dart';
import 'package:zoc/pages/popup_dialog/popup_dialog_widget.dart';
import 'package:zoc/utils/catalog_cache_service.dart';
import 'package:zoc/utils/offline_sync_service.dart';

enum _ServerMode { online, down503, socketDrop, hang }

/// Allows real TCP loopback connections to the local E2E backend while failing
/// external hosts (such as the desktop update feed) immediately.
class _LoopbackOnlyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _GuardedHttpClient(super.createHttpClient(context));
  }
}

class _GuardedHttpClient implements HttpClient {
  _GuardedHttpClient(this._inner);
  final HttpClient _inner;

  bool _isAllowed(Uri url) =>
      url.host == '127.0.0.1' || url.host == 'localhost';

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    if (!_isAllowed(url)) {
      return Future.error(
        SocketException('External host blocked in E2E: ${url.host}'),
      );
    }
    return _inner.openUrl(method, url);
  }

  @override
  Future<HttpClientRequest> open(
      String method, String host, int port, String path) {
    final uri = Uri(scheme: 'http', host: host, port: port, path: path);
    if (!_isAllowed(uri)) {
      return Future.error(
        SocketException('External host blocked in E2E: $host'),
      );
    }
    return _inner.open(method, host, port, path);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Function.apply(_inner.noSuchMethod, [invocation]);

  @override
  set autoUncompress(bool value) => _inner.autoUncompress = value;
  @override
  bool get autoUncompress => _inner.autoUncompress;
  @override
  set connectionTimeout(Duration? value) => _inner.connectionTimeout = value;
  @override
  Duration? get connectionTimeout => _inner.connectionTimeout;
  @override
  set idleTimeout(Duration value) => _inner.idleTimeout = value;
  @override
  Duration get idleTimeout => _inner.idleTimeout;
  @override
  set maxConnectionsPerHost(int? value) => _inner.maxConnectionsPerHost = value;
  @override
  int? get maxConnectionsPerHost => _inner.maxConnectionsPerHost;
  @override
  set userAgent(String? value) => _inner.userAgent = value;
  @override
  String? get userAgent => _inner.userAgent;
  @override
  void close({bool force = false}) => _inner.close(force: force);
}

/// Real stateful local HTTP backend speaking ZOC's REST contract over TCP.
class _TestZocServer {
  _TestZocServer._(this._server) {
    _sub = _server.listen(_handle);
  }

  final HttpServer _server;
  late final StreamSubscription<HttpRequest> _sub;

  int get port => _server.port;
  String get baseUrl => 'http://127.0.0.1:$port';

  _ServerMode mode = _ServerMode.online;
  bool termsPending = true;
  String currentAccess = 'e2e-access-1';
  String currentRefresh = 'e2e-refresh-1';
  bool accessExpiredOnServer = false;
  int tokenSeq = 1;
  int refreshCalls = 0;
  int taskCalls = 0;
  final List<String> requestLog = [];
  final List<Map<String, dynamic>> storedEntries = [];
  final List<Map<String, dynamic>> storedTimeRequests = [];
  final List<Completer<void>> _hanging = [];

  static Future<_TestZocServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    return _TestZocServer._(server);
  }

  void expireAccessTokensNow() {
    accessExpiredOnServer = true;
  }

  void resetState() {
    mode = _ServerMode.online;
    termsPending = true;
    currentAccess = 'e2e-access-1';
    currentRefresh = 'e2e-refresh-1';
    accessExpiredOnServer = false;
    tokenSeq = 1;
    refreshCalls = 0;
    taskCalls = 0;
    requestLog.clear();
    storedEntries.clear();
    storedTimeRequests.clear();
    for (final c in _hanging) {
      if (!c.isCompleted) c.complete();
    }
    _hanging.clear();
  }

  Future<void> close() async {
    for (final c in _hanging) {
      if (!c.isCompleted) c.complete();
    }
    _hanging.clear();
    await _sub.cancel();
    await _server.close(force: true);
  }

  bool _isAuthorized(HttpRequest req) {
    if (accessExpiredOnServer) return false;
    final auth = req.headers.value(HttpHeaders.authorizationHeader) ?? '';
    return auth == 'Bearer $currentAccess';
  }

  Future<Map<String, dynamic>> _readJson(HttpRequest req) async {
    final text = await utf8.decoder.bind(req).join();
    if (text.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(text);
    return decoded is Map<String, dynamic>
        ? decoded
        : Map<String, dynamic>.from(decoded as Map);
  }

  Future<void> _sendJson(HttpRequest req, int status, Object body) async {
    req.response.statusCode = status;
    req.response.headers.contentType = ContentType.json;
    req.response.write(jsonEncode(body));
    await req.response.close();
  }

  Future<void> _handle(HttpRequest req) async {
    final path = req.uri.path;
    requestLog.add('${req.method} $path');

    if (mode == _ServerMode.socketDrop) {
      final socket = await req.response.detachSocket(writeHeaders: false);
      socket.destroy();
      return;
    }
    if (mode == _ServerMode.hang) {
      final c = Completer<void>();
      _hanging.add(c);
      await c.future;
      try {
        await req.response.close();
      } catch (_) {}
      return;
    }
    if (mode == _ServerMode.down503) {
      await _sendJson(req, 503, {'message': 'temporarily unavailable'});
      return;
    }

    if (req.method == 'GET' && path == '/api/v1/auth/verify-email') {
      await _sendJson(req, 200, {
        'first_time': false,
        'exists': true,
        'verified': true,
        'screenshots_enabled': false,
      });
      return;
    }

    if (req.method == 'POST' && path == '/api/v1/auth/login-app') {
      await _readJson(req);
      tokenSeq++;
      currentAccess = 'e2e-access-$tokenSeq';
      currentRefresh = 'e2e-refresh-$tokenSeq';
      accessExpiredOnServer = false;
      await _sendJson(req, 200, {
        'access_token': currentAccess,
        'refresh_token': currentRefresh,
        'expires_in': 3600,
        'user': {
          'id': 'u-e2e-1',
          'auth_id': 'auth-e2e-1',
          'org_id': 'org-1',
          'first_name': 'Maria',
          'last_name': 'Silva',
          'email': 'maria@zoc.test',
          'monitoring': true,
          'monitoring_period': 15,
          'screenshots_enabled': false,
        },
      });
      return;
    }

    if (req.method == 'POST' && path == '/api/v1/auth/refresh') {
      refreshCalls++;
      final body = await _readJson(req);
      if (body['refresh_token'] != currentRefresh) {
        await _sendJson(req, 401, {'message': 'invalid refresh token'});
        return;
      }
      tokenSeq++;
      currentAccess = 'e2e-access-$tokenSeq';
      currentRefresh = 'e2e-refresh-$tokenSeq';
      accessExpiredOnServer = false;
      await _sendJson(req, 200, {
        'access_token': currentAccess,
        'refresh_token': currentRefresh,
        'expires_in': 3600,
      });
      return;
    }

    if (req.method == 'POST' && path == '/api/v1/auth/logout') {
      currentAccess = '';
      currentRefresh = '';
      await _sendJson(req, 200, {'ok': true});
      return;
    }

    if (!_isAuthorized(req)) {
      await _sendJson(req, 401, {'message': 'unauthorized'});
      return;
    }

    if (req.method == 'GET' && path == '/api/v1/onboarding/status') {
      await _sendJson(req, 200, {
        'terms_pending': termsPending,
        'terms_version': '2026-10',
        'terms_url': 'https://example.test/terms',
        'privacy_url': 'https://example.test/privacy',
      });
      return;
    }

    if (req.method == 'POST' && path == '/api/v1/onboarding/terms') {
      termsPending = false;
      await _sendJson(req, 200, {
        'terms_pending': false,
        'terms_version': '2026-10',
        'terms_url': 'https://example.test/terms',
        'privacy_url': 'https://example.test/privacy',
      });
      return;
    }

    if (req.method == 'GET' && path == '/api/v1/users/org/auth/auth-e2e-1') {
      await _sendJson(req, 200, {
        'id': 'u-e2e-1',
        'auth_id': 'auth-e2e-1',
        'org_id': 'org-1',
        'first_name': 'Maria',
        'last_name': 'Silva',
        'monitoring': true,
        'monitoring_period': 15,
        'screenshots_enabled': false,
      });
      return;
    }

    if (req.method == 'GET' && path == '/api/v1/clients') {
      await _sendJson(req, 200, [
        {'id': 'c1', 'name': 'Acme Ltda'},
        {'id': 'c2', 'name': 'Beta Engenharia'},
      ]);
      return;
    }

    if (req.method == 'GET' &&
        path == '/api/v1/assignments/projects/user/u-e2e-1') {
      await _sendJson(req, 200, [
        {'id': 'p1', 'name': 'Folha Mensal', 'client_id': 'c1'},
        {'id': 'p2', 'name': 'Auditoria Fiscal', 'client_id': 'c2'},
      ]);
      return;
    }

    if (req.method == 'GET' && path == '/api/v1/tasks/app/project/p1') {
      taskCalls++;
      await _sendJson(req, 200, [
        {'id': 't1', 'name': 'Conferir lançamentos', 'project_id': 'p1'},
        {'id': 't2', 'name': 'Fechar folha', 'project_id': 'p1'},
      ]);
      return;
    }

    if (req.method == 'GET' && path == '/api/v1/tasks/app/project/p2') {
      taskCalls++;
      await _sendJson(req, 200, [
        {'id': 't3', 'name': 'Revisar notas fiscais', 'project_id': 'p2'},
      ]);
      return;
    }

    if (req.method == 'POST' && path == '/api/v1/timemanager/entries') {
      final body = await _readJson(req);
      storedEntries.add(body);
      await _sendJson(req, 201, {'id': 'entry-${storedEntries.length}'});
      return;
    }

    if (req.method == 'GET' && path == '/api/v1/users/work-hours/u-e2e-1') {
      final activeCount =
          storedEntries.where((e) => e['ignored_popup'] != true).length;
      await _sendJson(req, 200, activeCount * 0.5);
      return;
    }

    if (req.method == 'GET' && path == '/api/v1/users/work-goal/u-e2e-1') {
      await _sendJson(req, 200, {'period': 'today', 'goal_hours': 8.0});
      return;
    }

    if (req.method == 'GET' &&
        path == '/api/v1/timemanager/entries/ignored/u-e2e-1') {
      final ignored =
          storedEntries.where((e) => e['ignored_popup'] == true).length;
      await _sendJson(req, 200, ignored);
      return;
    }

    if (req.method == 'GET' && path == '/api/v1/tasks/user/done/u-e2e-1') {
      final items = storedEntries
          .where((e) => e['ignored_popup'] != true)
          .map((e) => {
                'task_name':
                    (e['tasks'] as List?)?.contains('t3') == true
                        ? 'Revisar notas fiscais'
                        : 'Conferir lançamentos',
                'project_name': e['project_id'] == 'p2'
                    ? 'Auditoria Fiscal'
                    : 'Folha Mensal',
                'client_name': e['project_id'] == 'p2'
                    ? 'Beta Engenharia'
                    : 'Acme Ltda',
                'hours': 0.5,
                'created_at': DateTime.now().toUtc().toIso8601String(),
                'ended_at': DateTime.now().toUtc().toIso8601String(),
              })
          .toList();
      await _sendJson(req, 200, items);
      return;
    }

    if (req.method == 'GET' && path == '/api/v1/time-requests/workspace') {
      await _sendJson(req, 200, {
        'user_id': 'u-e2e-1',
        'is_admin': false,
        'projects': [
          {'id': 'p1', 'name': 'Folha Mensal', 'client_id': 'c1', 'client_name': 'Acme Ltda'},
        ],
        'tasks': [
          {'id': 't1', 'name': 'Conferir lançamentos', 'project_id': 'p1'},
        ],
      });
      return;
    }

    if (req.method == 'POST' && path == '/api/v1/time-requests') {
      final body = await _readJson(req);
      storedTimeRequests.add(body);
      await _sendJson(req, 201, {'id': 'req-1', 'auto_approved': false});
      return;
    }

    if (path.startsWith('/api/v1/presence/')) {
      await _sendJson(req, 200, {
        'status': 'active',
        'server_time': DateTime.now().toUtc().toIso8601String(),
        'pause': null,
      });
      return;
    }

    if (req.method == 'GET' && path == '/api/v1/organizations/org-1') {
      await _sendJson(req, 200, {'id': 'org-1', 'name': 'ZOC E2E Org'});
      return;
    }

    await _sendJson(req, 404, {'message': 'not found: $path'});
  }
}

/// Pumps frames and advances real async I/O until [predicate] holds.
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 6),
  String? reason,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for condition${reason != null ? ": $reason" : ""}');
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> settleE2e(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory storageDir;
  late _TestZocServer server;
  HttpOverrides? previousHttpOverrides;

  setUpAll(() async {
    previousHttpOverrides = HttpOverrides.current;
    HttpOverrides.global = _LoopbackOnlyHttpOverrides();

    FlutterSecureStorage.setMockInitialValues({});
    storageDir = await Directory.systemTemp.createTemp('zoc-e2e-test-');
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
        const MethodChannel('package_info_plus'),
        (_) async => {'version': '1.6.8', 'buildNumber': '1'});
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

    server = await _TestZocServer.start();
    debugApiBaseOverride = server.baseUrl;
  });

  tearDownAll(() async {
    debugApiBaseOverride = null;
    await server.close();
    await Hive.close();
    await storageDir.delete(recursive: true);
    HttpOverrides.global = previousHttpOverrides;
  });

  setUp(() async {
    server.resetState();
    await Hive.box('zoc_app_storage').clear();
    AppStateNotifier.resetForTest();
    FFAppState.reset();
    await FFAppState().initializePersistedState();
    CatalogCacheService.instance.resetForTest();
    OfflineSyncService.instance.resetForTest();
    PauseController.instance = PauseController();

    await authManager.signOut();
    zoc1AuthUserSubject.add(Zoc1AuthUser(loggedIn: false));
    ApiManager.configureAuthSession(
      accessTokenGetter: () => authManager.authenticationToken,
      tokenRefresher: AuthSession.refreshAccessToken,
      onUnauthorized: AuthSession.handleUnauthorized,
    );
    ApiManager.syncAccessToken(null);
  });

  Future<void> bootMyApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(640, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('pt')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: FFAppState(),
      child: const MyApp(),
    ));
  }

  testWidgets(
      'E2E full user journey: login -> terms -> popup sync -> offline outage + token expiry -> FIFO sync -> Expediente -> logout',
      (tester) async {
    await bootMyApp(tester);
    await pumpUntil(
      tester,
      () => find.text('Entrar no ZOC').evaluate().isNotEmpty,
      reason: 'boot to login screen',
    );

    // 1. Login: e-mail -> password -> terms -> onboarding notice -> home.
    await tester.enterText(find.byType(TextFormField).first, 'maria@zoc.test');
    await tester.tap(find.text('Continuar').last);
    await pumpUntil(
      tester,
      () => find.text('Digite sua senha').evaluate().isNotEmpty,
      reason: 'navigate to password screen',
    );

    await tester.enterText(find.byType(TextFormField).last, 'Secret123!');
    await tester.tap(find.text('Entrar').last);
    await pumpUntil(
      tester,
      () => find.byType(Checkbox).evaluate().isNotEmpty,
      reason: 'navigate to TermsGate and load status',
    );

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('Aceitar e continuar'));
    await pumpUntil(
      tester,
      () => find.text('Entendi, começar').evaluate().isNotEmpty,
      reason: 'navigate to MensajeAntesExpediente',
    );

    await tester.tap(find.text('Entendi, começar'));
    await pumpUntil(
      tester,
      () => find.text('Ignorar').hitTestable().evaluate().isNotEmpty,
      reason: 'home opens initial popup after pre-sync',
    );
    await settleE2e(tester);

    // Initial pre-sync extracted clients, projects, and tasks for BOTH p1 and p2.
    expect(CatalogCacheService.instance.tasksForProject('p1'), hasLength(2));
    expect(CatalogCacheService.instance.tasksForProject('p2'), hasLength(1));
    final initialTaskCalls = server.taskCalls;

    // 2. First popup online: pick Client 1 -> Project 1 -> Task 1 -> Save.
    await tester.tap(find.byKey(const ValueKey('popup-client')));
    await settleE2e(tester);
    await tester.tap(find.text('Acme Ltda').last);
    await settleE2e(tester);
    await tester.tap(find.byKey(const ValueKey('popup-project')));
    await settleE2e(tester);
    await tester.tap(find.text('Folha Mensal').last);
    await settleE2e(tester);
    // Selecting cached project made ZERO additional live task API calls.
    expect(server.taskCalls, initialTaskCalls);

    await tester.tap(find.text('Escolha a atividade'));
    await settleE2e(tester);
    await tester.tap(find.text('Conferir lançamentos'));
    await tester.tap(find.text('Concluir'));
    await settleE2e(tester);

    await tester.enterText(find.byType(TextFormField), 'Primeiro registro online');
    await tester.tap(find.text('Salvar registro'));
    await pumpUntil(
      tester,
      () =>
          find.byType(PopupDialogWidget).evaluate().isEmpty &&
          server.storedEntries.length == 1,
      reason: 'first online popup entry saved on server',
    );
    expect(server.storedEntries.single['notes'], 'Primeiro registro online');

    // 3. Internet drops (real TCP socket destruction) AND token expires on server.
    server.mode = _ServerMode.socketDrop;
    server.expireAccessTokensNow();
    final taskCallsBeforeOffline = server.taskCalls;

    await tester.tap(find.text('Registrar agora'));
    await pumpUntil(
      tester,
      () => find.text('Ignorar').hitTestable().evaluate().isNotEmpty,
      reason: 'popup still opens when offline using cached catalog',
    );
    await settleE2e(tester);

    // Offline cache banner appears; Client 2 -> Project 2 -> Task 3 load from memory!
    expect(find.byKey(const ValueKey('popup-offline-cache')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('popup-client')));
    await settleE2e(tester);
    await tester.tap(find.text('Beta Engenharia').last);
    await settleE2e(tester);
    await tester.tap(find.byKey(const ValueKey('popup-project')));
    await settleE2e(tester);
    await tester.tap(find.text('Auditoria Fiscal').last);
    await settleE2e(tester);
    expect(server.taskCalls, taskCallsBeforeOffline);

    await tester.tap(find.text('Escolha a atividade'));
    await settleE2e(tester);
    await tester.tap(find.text('Revisar notas fiscais'));
    await tester.tap(find.text('Concluir'));
    await settleE2e(tester);

    await tester.enterText(find.byType(TextFormField), 'Registro offline E2E');
    await tester.tap(find.text('Salvar registro'));
    await pumpUntil(
      tester,
      () => find.byType(PopupDialogWidget).evaluate().isEmpty,
      reason: 'offline entry queues and closes popup',
    );
    expect(OfflineSyncService.instance.pendingCount, 1);
    expect(
      find.text('1 registro salvo localmente aguardando conexão'),
      findsOneWidget,
    );

    // 4. Second popup while still offline: click "Ignorar" -> also queued locally.
    await tester.tap(find.text('Registrar agora'));
    await pumpUntil(
      tester,
      () => find.text('Ignorar').hitTestable().evaluate().isNotEmpty,
      reason: 'second offline popup opens',
    );
    await settleE2e(tester);
    await tester.tap(find.text('Ignorar'));
    await pumpUntil(
      tester,
      () =>
          find.byType(PopupDialogWidget).evaluate().isEmpty &&
          OfflineSyncService.instance.pendingCount == 2,
      reason: 'ignored offline popup queued locally',
    );
    expect(
      find.text('2 registros salvos localmente aguardando conexão'),
      findsOneWidget,
    );

    // 5. Internet recovers (with old access token expired on server!).
    // Tapping "Sincronizar" refreshes token via /auth/refresh and sends FIFO.
    server.mode = _ServerMode.online;
    final refreshesBeforeReconnect = server.refreshCalls;
    await tester.tap(find.text('Sincronizar'));
    await pumpUntil(
      tester,
      () =>
          OfflineSyncService.instance.pendingCount == 0 &&
          server.storedEntries.length == 3,
      reason: 'FIFO queue synced to real server after token refresh',
    );

    expect(server.refreshCalls, greaterThan(refreshesBeforeReconnect));
    expect(server.storedEntries[1]['notes'], 'Registro offline E2E');
    expect(server.storedEntries[1]['project_id'], 'p2');
    expect(server.storedEntries[1]['tasks'], ['t3']);
    expect(server.storedEntries[1]['ignored_popup'], isFalse);
    expect(server.storedEntries[2]['ignored_popup'], isTrue);
    expect(find.text('Sincronizar'), findsNothing);

    // 6. Open Expediente ("Ver registros") -> server shows 1h 00min (2 active entries) and synced task.
    await settleE2e(tester);
    await tester.tap(find.text('Ver registros'));
    await pumpUntil(
      tester,
      () =>
          find.text('Revisar notas fiscais').hitTestable().evaluate().isNotEmpty &&
          find.byTooltip('Fechar').hitTestable().evaluate().isNotEmpty,
      reason: 'Expediente shows synced offline activity from backend',
    );
    await settleE2e(tester);
    expect(find.text('1h 00min'), findsWidgets);

    await tester.tap(find.byTooltip('Fechar'));
    await pumpUntil(
      tester,
      () =>
          find.byTooltip('Fechar').evaluate().isEmpty &&
          find.byTooltip('Sair da conta').hitTestable().evaluate().isNotEmpty,
      reason: 'returned to home screen',
    );
    await settleE2e(tester);

    // 7. Logout clears catalog cache and hits /auth/logout.
    await tester.tap(find.byTooltip('Sair da conta'));
    await pumpUntil(
      tester,
      () => find.text('Sair').hitTestable().evaluate().isNotEmpty,
      reason: 'confirm logout modal opens',
    );
    await settleE2e(tester);
    await tester.tap(find.text('Sair'));
    await pumpUntil(
      tester,
      () => find.text('Você saiu').evaluate().isNotEmpty ||
          find.text('Entrar novamente').evaluate().isNotEmpty ||
          !CatalogCacheService.instance.hasAnyCatalog,
      reason: 'logout completes and clears catalog cache',
    );
    expect(CatalogCacheService.instance.hasAnyCatalog, isFalse);

    await tester.pumpWidget(const SizedBox());
    await settleE2e(tester);
  });

  testWidgets(
      'E2E offline cold restart: expired access token keeps session, restores Hive catalog & queue, survives 503, and syncs on recovery',
      (tester) async {
    // Seed persisted state in Hive as if user closed the app before internet dropped.
    await authManager.signIn(
      authenticationToken: 'e2e-access-1',
      refreshToken: 'e2e-refresh-1',
      tokenExpiration: DateTime.now().add(const Duration(hours: 1)),
      authUid: 'u-e2e-1',
    );
    ApiManager.syncAccessToken('e2e-access-1');
    FFAppState().UserData = {
      'user': {
        'id': 'u-e2e-1',
        'auth_id': 'auth-e2e-1',
        'org_id': 'org-1',
        'first_name': 'Maria',
        'last_name': 'Silva',
        'monitoring': true,
        'monitoring_period': 15,
        'screenshots_enabled': false,
      }
    };

    // Perform an initial online sync & queue one entry while offline, persisted in Hive.
    await tester.runAsync(() async {
      await CatalogCacheService.instance.sync();
      server.mode = _ServerMode.socketDrop;
      await OfflineSyncService.instance.submitOrQueuePopupEntry(
        project: 'p2',
        remote: true,
        ignoredPopUp: false,
        tasksList: ['t3'],
        notes: 'Salvo antes de reiniciar',
      );
      await Hive.box('zoc_app_storage').flush();
    });
    expect(OfflineSyncService.instance.pendingCount, 1);

    // Simulate access token expiring while app is closed & internet is unstable (503).
    await authManager.signIn(
      authenticationToken: 'e2e-access-1',
      refreshToken: 'e2e-refresh-1',
      tokenExpiration: DateTime.now().subtract(const Duration(minutes: 15)),
      authUid: 'u-e2e-1',
    );
    server.expireAccessTokensNow();
    server.mode = _ServerMode.down503;

    // Reset in-memory singletons ONLY (Hive box stays on disk!).
    CatalogCacheService.instance.resetForTest();
    OfflineSyncService.instance.resetForTest();
    FFAppState.reset();
    AppStateNotifier.resetForTest();

    await tester.runAsync(() async {
      await authManager.initialize();
      await FFAppState().initializePersistedState();
      CatalogCacheService.instance.restoreFromCache();
      OfflineSyncService.instance.restoreFromCache();
    });

    // Even with an expired access token + 503 offline startup, user stays logged in!
    expect(zoc1AuthUserSubject.value.loggedIn, isTrue);
    expect(CatalogCacheService.instance.tasksForProject('p2'), hasLength(1));
    expect(OfflineSyncService.instance.pendingCount, 1);

    // Startup AuthSession.refresh() gets 503 (unavailable) -> session MUST survive.
    final outcome = await tester.runAsync(AuthSession.refresh);
    expect(outcome, RefreshOutcome.unavailable);
    expect(zoc1AuthUserSubject.value.loggedIn, isTrue);
    expect(authManager.refreshToken, 'e2e-refresh-1');

    // Bring server back online -> Terms accepted -> LogoutWidget flushes persisted queue!
    server.termsPending = false;
    server.mode = _ServerMode.online;
    FFAppState().isPopupVisible = true; // Focus on home + auto flush without popup blocking.
    await bootMyApp(tester);
    await pumpUntil(
      tester,
      () => find.text('Entendi, começar').evaluate().isNotEmpty,
      reason: 'cold restart offline lands inside authenticated app, not /login',
    );

    await tester.tap(find.text('Entendi, começar'));
    await pumpUntil(
      tester,
      () =>
          OfflineSyncService.instance.pendingCount == 0 &&
          server.storedEntries.length == 1,
      reason: 'persisted offline entry flushed automatically once back online',
    );
    expect(server.storedEntries.single['notes'], 'Salvo antes de reiniciar');
    expect(authManager.authenticationToken, isNot('e2e-access-1'));

    await tester.pumpWidget(const SizedBox());
    await settleE2e(tester);
  });

  test('E2E rotating refresh token concurrency & timeout handling over real TCP',
      () async {
    await authManager.signIn(
      authenticationToken: 'e2e-access-1',
      refreshToken: 'e2e-refresh-1',
      tokenExpiration: DateTime.now().add(const Duration(minutes: 10)),
      authUid: 'u-e2e-1',
    );
    ApiManager.syncAccessToken('e2e-access-1');
    FFAppState().UserData = {
      'user': {'id': 'u-e2e-1'}
    };

    // Expire access token on server while client still thinks it's valid -> triggers 401 on concurrent calls.
    server.expireAccessTokensNow();
    final result = await CatalogCacheService.instance.sync();
    expect(result.succeeded, isTrue);
    // Rotating refresh token MUST only be refreshed once across concurrent Clients + Projects calls!
    expect(server.refreshCalls, 1);
    expect(CatalogCacheService.instance.tasksForProject('p1'), hasLength(2));

    // Hanging connection triggers ApiManager timeout and preserves cached tasks!
    server.mode = _ServerMode.hang;
    final timeoutResult = await CatalogCacheService.instance.sync(
      requestTimeout: const Duration(milliseconds: 200),
      totalTimeout: const Duration(milliseconds: 400),
    );
    expect(timeoutResult.succeeded, isFalse);
    expect(timeoutResult.usedCache, isTrue);
    expect(CatalogCacheService.instance.tasksForProject('p1'), hasLength(2));
  });
}
