import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:zoc/backend/api_requests/auth_models.dart';
import 'package:zoc/flutter_flow/flutter_flow_util.dart';
import 'package:zoc/info/info_widget.dart';
import 'package:zoc/utils/error_handler.dart';

http.Response jsonResponse(Object body, [int code = 200]) => http.Response(
      jsonEncode(body),
      code,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Widget app() {
  final router = GoRouter(routes: [
    GoRoute(
      name: InfoWidget.routeName,
      path: '/',
      builder: (_, __) => const InfoWidget(),
    ),
    GoRoute(
      name: 'EntrarConSenha',
      path: '/entrarConSenha',
      builder: (_, __) => const Scaffold(body: Text('Tela de senha')),
    ),
    GoRoute(
      name: 'verifyToken',
      path: '/verifyToken',
      builder: (_, __) => const Scaffold(body: Text('Tela de token')),
    ),
    GoRoute(
      name: 'Login',
      path: '/login',
      builder: (_, __) => const Scaffold(body: Text('Login')),
    ),
  ]);
  return ChangeNotifierProvider<FFAppState>.value(
    value: FFAppState(),
    child: MaterialApp.router(routerConfig: router),
  );
}

/// Records every request and answers activation-code with [activationCode]
/// (200 by default) and register-app with [register].
class FakeServer {
  FakeServer(this.register, {this.activationCode});

  final http.Response Function(Map<String, dynamic> body) register;
  final http.Response Function()? activationCode;
  final List<http.Request> requests = [];

  List<Map<String, dynamic>> bodiesFor(String path) => requests
      .where((r) => r.url.path == path)
      .map((r) => Map<String, dynamic>.from(jsonDecode(r.body) as Map))
      .toList();

  MockClient client() => MockClient((request) async {
        requests.add(request);
        expect(request.method, 'POST');
        switch (request.url.path) {
          case '/api/v1/auth/activation-code':
            return activationCode?.call() ??
                jsonResponse({'message': 'Activation code sent'});
          case '/api/v1/auth/register-app':
            return register(
                Map<String, dynamic>.from(jsonDecode(request.body) as Map));
        }
        fail('unexpected request ${request.url}');
      });
}

Future<void> fillForm(WidgetTester tester,
    {String code = '123456', String password = 'senhaforte1'}) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), code);
  await tester.enterText(fields.at(1), password);
  await tester.enterText(fields.at(2), password);
}

/// Lets the request finish and a dialog open. The submit spinner keeps
/// animating while the dialog is awaited, so pumpAndSettle would never return.
Future<void> settleDialog(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storageDir;
  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    storageDir = await Directory.systemTemp.createTemp('zoc-info-test-');
    Hive.init(storageDir.path);
    await Hive.openBox('zoc_app_storage');
    await FFAppState().initializePersistedState();
  });
  tearDownAll(() async {
    await Hive.close();
    await storageDir.delete(recursive: true);
  });
  setUp(() {
    FFAppState().email = ' Ana@Empresa.com ';
    FFAppState().emailData = {'first_time': true, 'screenshots_enabled': true};
    FFAppState().loginFailed = false;
  });

  test('RegisterAppRequest sends the activation code under "code"', () {
    const request = RegisterAppRequest(
      email: 'ana@empresa.com',
      password: 'senhaforte1',
      termsAccepted: true,
      code: '123456',
    );
    expect(request.toJson(), {
      'email': 'ana@empresa.com',
      'password': 'senhaforte1',
      'termsAccepted': true,
      'code': '123456',
    });
  });

  testWidgets('opening the screen sends the code to the normalized e-mail',
      (tester) async {
    final server = FakeServer((_) => jsonResponse({}, 500));
    await http.runWithClient(() async {
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pump();

      expect(server.bodiesFor('/api/v1/auth/activation-code'), [
        {'email': 'ana@empresa.com'}
      ]);
      expect(find.text('Enviamos um código de 6 dígitos para ana@empresa.com.'),
          findsOneWidget);
      expect(find.text('Código de verificação'), findsOneWidget);
      expect(find.text('Nova senha'), findsWidgets);
      expect(find.text('Confirmar senha'), findsWidgets);

      // Resend is blocked by a 30 s cooldown, then calls the endpoint again.
      expect(find.text('Reenviar em 0:30'), findsOneWidget);
      await tester.tap(find.text('Reenviar em 0:30'));
      await tester.pump();
      expect(server.bodiesFor('/api/v1/auth/activation-code'), hasLength(1));

      await tester.pump(const Duration(seconds: 30));
      expect(find.text('Reenviar código'), findsOneWidget);
      await tester.tap(find.text('Reenviar código'));
      await tester.pump();
      await tester.pump();
      expect(server.bodiesFor('/api/v1/auth/activation-code'), hasLength(2));

      await tester.pumpWidget(const SizedBox());
    }, server.client);
  });

  testWidgets('invalid code clears the code and keeps the passwords',
      (tester) async {
    final server = FakeServer(
        (_) => jsonResponse({'error': 'invalid_activation_code'}, 400));
    await http.runWithClient(() async {
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pump();

      await fillForm(tester, code: '654321');
      await tester.tap(find.text('Finalizar'));
      await tester.pumpAndSettle();

      expect(server.bodiesFor('/api/v1/auth/register-app'), [
        {
          'email': ' Ana@Empresa.com ',
          'password': 'senhaforte1',
          'termsAccepted': true,
          'code': '654321',
        }
      ]);
      expect(find.text(InfoWidget.invalidCodeMessage), findsOneWidget);
      expect(find.text('Tela de token'), findsNothing);

      final fields = find.byType(TextFormField);
      String text(int i) =>
          tester.widget<TextFormField>(fields.at(i)).controller!.text;
      expect(text(0), isEmpty);
      expect(text(1), 'senhaforte1');
      expect(text(2), 'senhaforte1');

      await tester.pumpWidget(const SizedBox());
    }, server.client);
  });

  testWidgets('201 shows screenshot consent, then the password screen',
      (tester) async {
    final server = FakeServer(
        (_) => jsonResponse({'message': 'User registered successfully'}, 201));
    await http.runWithClient(() async {
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pump();

      await fillForm(tester);
      await tester.tap(find.text('Finalizar'));
      await settleDialog(tester);

      expect(server.bodiesFor('/api/v1/auth/register-app').single['code'],
          '123456');
      expect(find.text('Capturas de tela'), findsOneWidget);
      expect(find.text('Tela de token'), findsNothing);

      await tester.tap(find.text('Aprovar'));
      await tester.pumpAndSettle();

      expect(find.text('Tela de senha'), findsOneWidget);
      expect(find.text('Tela de token'), findsNothing);
      expect(
          server.requests
              .where((r) => r.url.path == '/api/v1/auth/confirm-email'),
          isEmpty);
    }, server.client);
  });

  testWidgets('other register errors keep the existing dialog', (tester) async {
    final server =
        FakeServer((_) => jsonResponse({'error': 'Email já existe'}, 409));
    await http.runWithClient(() async {
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pump();

      await fillForm(tester);
      await tester.tap(find.text('Finalizar'));
      await settleDialog(tester);

      expect(find.text('Usuario não criado'), findsOneWidget);
      expect(find.text(InfoWidget.invalidCodeMessage), findsNothing);

      await tester.tap(find.text('Ok'));
      await tester.pumpAndSettle();
      expect(find.text('Finalizar'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }, server.client);
  });

  testWidgets('register 429 shows the too-many-attempts dialog',
      (tester) async {
    final server = FakeServer((_) =>
        jsonResponse({'error': 'too many attempts, try again later'}, 429));
    await http.runWithClient(() async {
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pump();

      await fillForm(tester);
      await tester.tap(find.text('Finalizar'));
      await settleDialog(tester);

      expect(find.text('Atenção'), findsOneWidget);
      expect(find.text(AppError.tooManyAttemptsMessage), findsOneWidget);
      expect(find.text('Usuario não criado'), findsNothing);
      expect(find.text(InfoWidget.invalidCodeMessage), findsNothing);

      await tester.tap(find.text('Ok'));
      await tester.pumpAndSettle();
      expect(find.text('Finalizar'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }, server.client);
  });

  testWidgets('activation-code 429 says to wait instead of resend',
      (tester) async {
    final server = FakeServer((_) => jsonResponse({}, 500),
        activationCode: () =>
            jsonResponse({'error': 'rate limit exceeded'}, 429));
    await http.runWithClient(() async {
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pump();

      expect(find.text(AppError.tooManyAttemptsMessage), findsOneWidget);
      expect(find.text('Não foi possível enviar o código. Tente reenviar.'),
          findsNothing);
      await tester.pumpWidget(const SizedBox());
    }, server.client);
  });

  testWidgets('other activation-code errors keep the resend notice',
      (tester) async {
    final server = FakeServer((_) => jsonResponse({}, 500),
        activationCode: () => jsonResponse({'error': 'boom'}, 500));
    await http.runWithClient(() async {
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pump();

      expect(find.text('Não foi possível enviar o código. Tente reenviar.'),
          findsOneWidget);
      expect(find.text(AppError.tooManyAttemptsMessage), findsNothing);
      await tester.pumpWidget(const SizedBox());
    }, server.client);
  });
}
