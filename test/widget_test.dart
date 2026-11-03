import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:zoc/flutter_flow/flutter_flow_util.dart';
import 'package:zoc/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storageDir;

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    storageDir = await Directory.systemTemp.createTemp('zoc-smoke-test-');
    Hive.init(storageDir.path);
    await Hive.openBox('zoc_app_storage');
    await FFAppState().initializePersistedState();
  });

  tearDownAll(() async {
    await Hive.close();
    await storageDir.delete(recursive: true);
  });

  // Same tree as main(): the app under the FFAppState provider, with no session, must land on the e-mail
  // login screen instead of throwing while it builds.
  testWidgets('app boots to the login screen when there is no session',
      (tester) async {
    tester.view.physicalSize = const Size(510, 435);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.localesTestValue = const [Locale('pt')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await http.runWithClient(() async {
      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: FFAppState(),
        child: const MyApp(),
      ));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Entrar no ZOC'), findsOneWidget);
    }, () => MockClient((_) async => http.Response('{}', 404)));
  });
}
