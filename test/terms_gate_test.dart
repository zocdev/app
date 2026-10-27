import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zoc/auth/terms_gate.dart';
import 'package:zoc/backend/api_requests/api_manager.dart';
import 'package:zoc/flutter_flow/flutter_flow_util.dart';

Map<String, dynamic> status(
        {bool pending = true, String version = '2026-10'}) =>
    {
      'terms_pending': pending,
      'terms_version': version,
      'terms_url': 'https://example.test/termos-de-uso',
      'privacy_url': 'https://example.test/politica-de-privacidade',
    };

http.Response jsonResponse(Object body, [int code = 200]) => http.Response(
      jsonEncode(body),
      code,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Widget app({Widget? child}) => MaterialApp(
      theme: ThemeData(
        useMaterial3: false,
        colorScheme: const ColorScheme.light(primary: Color(0xFF0F8F8A)),
      ),
      home: RepaintBoundary(
        key: const ValueKey('terms-render'),
        child: TermsGate(child: child ?? const Text('Trabalho liberado')),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storageDir;
  setUpAll(() async {
    final font = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    await font.load();
    FlutterSecureStorage.setMockInitialValues({});
    storageDir = await Directory.systemTemp.createTemp('zoc-terms-test-');
    Hive.init(storageDir.path);
    await Hive.openBox('zoc_app_storage');
    await FFAppState().initializePersistedState();
  });
  tearDownAll(() async {
    await Hive.close();
    await storageDir.delete(recursive: true);
  });
  setUp(() => ApiManager.syncAccessToken('test-session'));
  tearDown(() => ApiManager.syncAccessToken(null));

  testWidgets('blocks monitoring until explicit acceptance is saved',
      (tester) async {
    final check = Completer<http.Response>();
    final save = Completer<http.Response>();
    var mountedWork = false;
    var submissions = 0;
    await http.runWithClient(() async {
      await tester.pumpWidget(app(child: Builder(builder: (_) {
        mountedWork = true;
        return const Text('Trabalho liberado');
      })));
      expect(mountedWork, isFalse);
      check.complete(jsonResponse(status()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aceitar e continuar'));
      await tester.pump();
      expect(submissions, 0);
      expect(mountedWork, isFalse);
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.text('Aceitar e continuar'));
      await tester.pump();
      expect(mountedWork, isFalse);
      expect(find.text('Salvando...'), findsOneWidget);
      save.complete(jsonResponse(status(pending: false)));
      await tester.pumpAndSettle();
      expect(mountedWork, isTrue);
      expect(submissions, 1);
    },
        () => MockClient((request) async {
              expect(request.headers['Authorization'], 'Bearer test-session');
              if (request.method == 'GET') {
                expect(request.url.path, '/api/v1/onboarding/status');
                return check.future;
              }
              submissions++;
              expect(request.url.path, '/api/v1/onboarding/terms');
              expect(jsonDecode(request.body), {'version': '2026-10'});
              return save.future;
            }));
  });

  testWidgets('load and save failures stay blocked and can be retried',
      (tester) async {
    var reads = 0;
    var saves = 0;
    await http.runWithClient(() async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('Trabalho liberado'), findsNothing);
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.text('Aceitar e continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Não foi possível registrar o aceite. Tente novamente.'),
          findsOneWidget);
      expect(find.text('Trabalho liberado'), findsNothing);
      await tester.tap(find.text('Aceitar e continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Trabalho liberado'), findsOneWidget);
    },
        () => MockClient((request) async {
              if (request.method == 'GET') {
                return ++reads == 1
                    ? jsonResponse({}, 503)
                    : jsonResponse(status());
              }
              return ++saves == 1
                  ? jsonResponse({}, 500)
                  : jsonResponse(status(pending: false));
            }));
  });

  testWidgets('version conflict reloads documents and requires a new check',
      (tester) async {
    var reads = 0;
    var saves = 0;
    await http.runWithClient(() async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.text('Aceitar e continuar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('2026-11'), findsOneWidget);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
      await tester.tap(find.text('Aceitar e continuar'));
      await tester.pump();
      expect(saves, 1);
      expect(find.text('Trabalho liberado'), findsNothing);
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.text('Aceitar e continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Trabalho liberado'), findsOneWidget);
    },
        () => MockClient((request) async {
              if (request.method == 'GET') {
                return jsonResponse(
                    status(version: ++reads == 1 ? '2026-10' : '2026-11'));
              }
              if (++saves == 1) return jsonResponse({}, 409);
              expect(jsonDecode(request.body), {'version': '2026-11'});
              return jsonResponse(status(pending: false, version: '2026-11'));
            }));
  });

  testWidgets('already accepted users continue without a dialog',
      (tester) async {
    await http.runWithClient(() async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('Trabalho liberado'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
    }, () => MockClient((_) async => jsonResponse(status(pending: false))));
  });

  testWidgets('invalid or old API response cannot bypass the gate',
      (tester) async {
    await http.runWithClient(() async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('Trabalho liberado'), findsNothing);
      expect(find.text('Tentar novamente'), findsOneWidget);
    }, () => MockClient((_) async => jsonResponse({})));
  });

  testWidgets('Sair returns to login without accepting', (tester) async {
    final router = GoRouter(routes: [
      GoRoute(
          path: '/',
          builder: (_, __) =>
              const TermsGate(child: Text('Trabalho liberado'))),
      GoRoute(
          path: '/login',
          builder: (_, __) => const Scaffold(body: Text('Login'))),
    ]);
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Sair'));
        await Future<void>.delayed(Duration.zero);
        await Hive.box('zoc_app_storage').flush();
      });
      await tester.pumpAndSettle();
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Trabalho liberado'), findsNothing);
    },
        () => MockClient((request) async {
              expect(request.method, 'GET');
              return jsonResponse(status());
            }));
    router.dispose();
  });

  testWidgets('fits the minimum desktop window', (tester) async {
    tester.view.physicalSize = const Size(510, 435);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await http.runWithClient(() async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Termos de Uso'), findsOneWidget);
      expect(find.text('Política de Privacidade'), findsOneWidget);
      expect(find.text('Sair').hitTestable(), findsOneWidget);
      expect(find.text('Aceitar e continuar').hitTestable(), findsOneWidget);
      await expectLater(find.byKey(const ValueKey('terms-render')),
          matchesGoldenFile('goldens/terms-gate.png'));
    }, () => MockClient((_) async => jsonResponse(status())));
  });
}
