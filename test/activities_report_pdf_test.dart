import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zoc/custom_code/actions/generate_p_d_f.dart';

void main() {
  test('period text shows label and dates', () {
    expect(reportPeriodText('Dia', DateTime(2026, 10, 31), DateTime(2026, 10, 31)),
        'Dia (31/10/2026)');
    expect(
        reportPeriodText('Semana', DateTime(2026, 10, 26), DateTime(2026, 11, 1)),
        'Semana (26/10/2026 a 01/11/2026)');
  });

  test('builds the report with org, worker and period', () async {
    final rows = List.generate(
      30,
      (i) => {
        'entry_date': '2026-10-${(i % 28 + 1).toString().padLeft(2, '0')}',
        'client_name': 'Cliente ${i % 3}',
        'project_name': 'Projeto ${i % 4}',
        'task_name': 'Tarefa de revisão número $i',
        'hours': 1.25,
        'created_at': '2026-10-${(i % 28 + 1).toString().padLeft(2, '0')}T12:00:00Z',
        'ended_at': i == 0
            ? null
            : '2026-10-${(i % 28 + 1).toString().padLeft(2, '0')}T13:15:00Z',
        'user_name': 'Ana Souza',
      },
    );
    final bytes = await buildActivitiesReportPdf(
      activities: rows,
      userName: 'Ana Souza',
      orgName: 'Acme Engenharia',
      periodLabel: 'Mês',
      periodStart: DateTime(2026, 10, 1),
      periodEnd: DateTime(2026, 10, 31),
      ignoredPopUps: 3,
      generatedAt: DateTime(2026, 10, 31, 15, 30),
    );
    expect(bytes.length, greaterThan(1000));
    final out = Platform.environment['REPORT_PDF_OUT'];
    if (out != null) File(out).writeAsBytesSync(bytes);
  });
}
