import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:zoc/desktop/add_time_dialog.dart';

void main() {
  testWidgets('submits a manual time request from the app', (tester) async {
    Map<String, dynamic>? sent;
    final client = MockClient((request) async {
      if (request.method == 'GET' &&
          request.url.path == '/api/v1/time-requests/workspace') {
        return http.Response(
            jsonEncode({
              'user_id': 'u-1',
              'is_admin': false,
              'projects': [
                {'id': 'p-1', 'name': 'Projeto A'}
              ],
              'tasks': [
                {'id': 't-1', 'name': 'Atividade 1', 'project_id': 'p-1'}
              ],
              'members': [],
            }),
            200);
      }
      if (request.method == 'POST' &&
          request.url.path == '/api/v1/time-requests') {
        sent = jsonDecode(request.body);
        return http.Response(
            jsonEncode({'id': 'r-1', 'auto_approved': false}), 201);
      }
      return http.Response('not found', 404);
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAddTimeDialog(context),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('add-time-project')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Projeto A').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-time-task-p-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Atividade 1').last);
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const ValueKey('add-time-reason')), 'Reunião fora do PC');
      await tester.tap(find.byKey(const ValueKey('add-time-submit')));
      await tester.pumpAndSettle();
    }, () => client);

    expect(sent, isNotNull);
    expect(sent!['user_id'], 'u-1');
    expect(sent!['project_id'], 'p-1');
    expect(sent!['task_id'], 't-1');
    expect(sent!['reason'], 'Reunião fora do PC');
    expect(sent!['remote'], true);
    final start = DateTime.parse(sent!['started_at']);
    final end = DateTime.parse(sent!['ended_at']);
    expect(end.isAfter(start), isTrue);
    expect(sent!['started_at'], endsWith('Z'));
    expect(find.text('Registrar tempo'), findsNothing);
    expect(find.textContaining('Solicitação enviada'), findsOneWidget);
  });

  testWidgets('picks the client first when projects share a name',
      (tester) async {
    Map<String, dynamic>? sent;
    final client = MockClient((request) async {
      if (request.method == 'GET' &&
          request.url.path == '/api/v1/time-requests/workspace') {
        return http.Response(
            jsonEncode({
              'user_id': 'u-1',
              'is_admin': false,
              'projects': [
                {
                  'id': 'p-1',
                  'name': 'Projeto A',
                  'client_id': 'c-1',
                  'client_name': 'Cliente Um'
                },
                {
                  'id': 'p-2',
                  'name': 'Projeto A',
                  'client_id': 'c-2',
                  'client_name': 'Cliente Dois'
                }
              ],
              'tasks': [
                {'id': 't-1', 'name': 'Atividade 1', 'project_id': 'p-1'},
                {'id': 't-2', 'name': 'Atividade 2', 'project_id': 'p-2'}
              ],
              'members': [],
            }),
            200);
      }
      if (request.method == 'POST' &&
          request.url.path == '/api/v1/time-requests') {
        sent = jsonDecode(request.body);
        return http.Response(
            jsonEncode({'id': 'r-1', 'auto_approved': false}), 201);
      }
      return http.Response('not found', 404);
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAddTimeDialog(context),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Escolha o projeto'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('add-time-client')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cliente Dois').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-time-project-c-2')));
      await tester.pumpAndSettle();
      expect(find.text('Projeto A'), findsOneWidget);
      await tester.tap(find.text('Projeto A').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-time-task-p-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Atividade 2').last);
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const ValueKey('add-time-reason')), 'Reunião fora do PC');
      await tester.ensureVisible(find.byKey(const ValueKey('add-time-submit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-time-submit')));
      await tester.pumpAndSettle();
    }, () => client);

    expect(sent, isNotNull);
    expect(sent!['project_id'], 'p-2');
    expect(sent!['task_id'], 't-2');
  });
}
