import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:zoc/backend/api_requests/api_manager.dart';
import 'package:zoc/entrar_con_senha/entrar_con_senha_widget.dart';
import 'package:zoc/flutter_flow/flutter_flow_util.dart';
import 'package:zoc/login/login_widget.dart';
import 'package:zoc/utils/api_error_helper.dart';
import 'package:zoc/utils/error_handler.dart';

http.Response jsonResponse(Object body, [int code = 200]) => http.Response(
      jsonEncode(body),
      code,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Widget app(Widget home) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => home),
      GoRoute(
        name: 'verifyToken',
        path: '/verifyToken',
        builder: (_, __) => const Scaffold(body: Text('Tela de token')),
      ),
    ],
  );
  return ChangeNotifierProvider<FFAppState>.value(
    value: FFAppState(),
    child: MaterialApp.router(routerConfig: router),
  );
}

/// Answers every POST to [path] with [response] and fails on anything else.
MockClient serverFor(String path, http.Response response) =>
    MockClient((request) async {
      expect(request.url.path, path);
      return response;
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storageDir;
  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    storageDir = await Directory.systemTemp.createTemp('zoc-429-test-');
    Hive.init(storageDir.path);
    await Hive.openBox('zoc_app_storage');
    await FFAppState().initializePersistedState();
  });
  tearDownAll(() async {
    // The login screen saves the e-mail to Hive from inside the fake-async
    // test zone; those writes never complete, so Hive.close() would wait
    // forever. Give it a moment and move on.
    await Future.any<void>([
      Hive.close(),
      Future<void>.delayed(const Duration(seconds: 2)),
    ]);
    await storageDir.delete(recursive: true);
  });
  setUp(() {
    FFAppState().email = 'ana@empresa.com';
    FFAppState().savedEmail = '';
    FFAppState().loginFailed = false;
  });

  group('AppError for 429', () {
    for (final body in [
      'too many attempts, try again later',
      'too many requests',
      'rate limit exceeded',
    ]) {
      test('maps "$body" to the too-many-attempts message', () {
        final error = ApiCallResponse(
          {'error': body},
          const {},
          429,
        ).toAppError()!;
        expect(error.statusCode, 429);
        expect(error.displayMessage, AppError.tooManyAttemptsMessage);
      });
    }

    test('ignores the body text and uses the status code', () {
      expect(
        AppError.fromApiResponse(429, null).displayMessage,
        AppError.tooManyAttemptsMessage,
      );
      expect(
        AppError.fromApiResponse(429, 'anything').displayMessage,
        AppError.tooManyAttemptsMessage,
      );
    });

    test('other statuses keep their messages', () {
      expect(
        AppError.fromApiResponse(400, 'E-mail inválido').displayMessage,
        'E-mail inválido',
      );
      expect(
        AppError.fromApiResponse(409, 'Email já existe').displayMessage,
        'Email já existe',
      );
      expect(
        AppError.fromApiResponse(500, 'boom').displayMessage,
        'Erro no servidor. Tente novamente mais tarde.',
      );
    });
  });

  group('password login', () {
    Future<void> submit(WidgetTester tester, http.Response response) async {
      await http.runWithClient(() async {
        await tester.pumpWidget(app(const EntrarConSenhaWidget()));
        await tester.pump();
        await tester.enterText(find.byType(TextFormField).first, 'senha1234');
        await tester.tap(find.text('Entrar'));
        await tester.pumpAndSettle();
      }, () => serverFor('/api/v1/auth/login-app', response));
    }

    testWidgets(
      '429 says the e-mail is locked, not that the password is wrong',
      (tester) async {
        await submit(
          tester,
          jsonResponse({'error': 'too many attempts, try again later'}, 429),
        );

        expect(find.text('Atenção'), findsOneWidget);
        expect(
          find.text(EntrarConSenhaWidget.tooManyAttemptsMessage),
          findsOneWidget,
        );
        expect(find.text('Senha invalida'), findsNothing);

        await tester.tap(find.text('Ok'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text('Entrar'), findsOneWidget);
      },
    );

    testWidgets('IP limiter 429 shows the same message', (tester) async {
      await submit(tester, jsonResponse({'error': 'rate limit exceeded'}, 429));

      expect(
        find.text(EntrarConSenhaWidget.tooManyAttemptsMessage),
        findsOneWidget,
      );
      expect(find.text('Senha invalida'), findsNothing);
    });

    testWidgets('401 still says the password is invalid', (tester) async {
      await submit(tester, jsonResponse({'error': 'invalid credentials'}, 401));

      expect(find.text('Atenção'), findsOneWidget);
      expect(find.text('Senha invalida'), findsOneWidget);
      expect(
        find.text(EntrarConSenhaWidget.tooManyAttemptsMessage),
        findsNothing,
      );
    });
  });

  group('login e-mail check', () {
    Future<void> submit(WidgetTester tester, http.Response response) async {
      await http.runWithClient(() async {
        await tester.pumpWidget(app(const LoginWidget()));
        await tester.pump();
        await tester.enterText(
          find.byType(TextFormField).first,
          'ana@empresa.com',
        );
        await tester.tap(find.text('Continuar'));
        await tester.pump();
        await tester.pump();
      }, () => serverFor('/api/v1/auth/verify-email', response));
    }

    testWidgets('429 shows the too-many-attempts message', (tester) async {
      await submit(tester, jsonResponse({'error': 'too many requests'}, 429));

      expect(find.text(AppError.tooManyAttemptsMessage), findsOneWidget);
      expect(find.text('too many requests'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      // Let the e-mail debounce and snackbar timers run out.
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('400 keeps the API message', (tester) async {
      await submit(tester, jsonResponse({'error': 'E-mail inválido'}, 400));

      expect(find.text('E-mail inválido'), findsOneWidget);
      expect(find.text(AppError.tooManyAttemptsMessage), findsNothing);
      await tester.pumpWidget(const SizedBox());
      // Let the e-mail debounce and snackbar timers run out.
      await tester.pump(const Duration(seconds: 5));
    });
  });
}
