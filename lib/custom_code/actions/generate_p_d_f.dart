// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_util.dart';
// Imports other custom actions
// Imports custom functions
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Same palette as the web exports (zoc-fe src/utils/exportUtils.ts).
final _brand = PdfColor.fromInt(0xFF4CAED1);
final _navy = PdfColor.fromInt(0xFF102A43);
final _muted = PdfColor.fromInt(0xFF646464);
final _faint = PdfColor.fromInt(0xFF969696);
final _text = PdfColor.fromInt(0xFF282828);
final _border = PdfColor.fromInt(0xFFDCE1E6);
final _zebra = PdfColor.fromInt(0xFFF8FAFC);
final _footFill = PdfColor.fromInt(0xFFECF5FA);

/// "3h 05min", "0h 20min".
String _hoursLabel(num? hours) {
  final total = ((hours ?? 0) * 60).round();
  final h = total ~/ 60, m = total % 60;
  return '${h}h ${m.toString().padLeft(2, '0')}min';
}

num _hoursOf(Map row) {
  final raw = row['hours'];
  if (raw is num) return raw;
  return num.tryParse('${raw ?? ''}') ?? 0;
}

DateTime? _parseLocal(dynamic raw) {
  final s = raw?.toString() ?? '';
  if (s.isEmpty || s == 'null') return null;
  return DateTime.tryParse(s)?.toLocal();
}

final _dayFormat = DateFormat('dd/MM/yyyy');
final _timeFormat = DateFormat('HH:mm');
final _dayTimeFormat = DateFormat('dd/MM HH:mm');

/// "Hoje (31/10/2026)", "Semana (27/10/2026 a 02/11/2026)".
String reportPeriodText(String label, DateTime start, DateTime end) {
  final a = _dayFormat.format(start), b = _dayFormat.format(end);
  final range = a == b ? a : '$a a $b';
  return label.isEmpty ? range : '$label ($range)';
}

/// Builds the "Relatório de Atividades" PDF of one worker.
///
/// [activities] are rows of `GET /tasks/user/done/:id` (entry_date,
/// client_name, project_name, task_name, hours, created_at, ended_at).
Future<Uint8List> buildActivitiesReportPdf({
  required List<dynamic> activities,
  required String userName,
  required String periodLabel,
  required DateTime periodStart,
  required DateTime periodEnd,
  String? orgName,
  pw.ImageProvider? orgLogo,
  int? ignoredPopUps,
  DateTime? generatedAt,
}) async {
  final rows = activities.whereType<Map>().toList()
    ..sort((a, b) {
      final x = _parseLocal(a['created_at']), y = _parseLocal(b['created_at']);
      if (x == null && y == null) return 0;
      if (x == null) return 1;
      if (y == null) return -1;
      return x.compareTo(y);
    });

  num totalHours = 0;
  final projects = <String>{};
  final tasks = <String>{};
  for (final row in rows) {
    totalHours += _hoursOf(row);
    final p = '${row['project_name'] ?? ''}'.trim();
    final t = '${row['task_name'] ?? ''}'.trim();
    if (p.isNotEmpty) projects.add(p);
    if (t.isNotEmpty) tasks.add('$p/$t');
  }

  final name = userName.trim().isNotEmpty
      ? userName.trim()
      : (rows.isNotEmpty ? '${rows.first['user_name'] ?? ''}'.trim() : '');
  final org = (orgName ?? '').trim();
  final period = reportPeriodText(periodLabel, periodStart, periodEnd);
  final now = generatedAt ?? DateTime.now();

  String dayOf(Map row) {
    final raw = '${row['entry_date'] ?? ''}';
    final d = DateTime.tryParse(raw) ?? _parseLocal(row['created_at']);
    return d == null ? raw : _dayFormat.format(d);
  }

  String timeOf(DateTime? t, String day) {
    if (t == null) return '';
    return _dayFormat.format(t) == day
        ? _timeFormat.format(t)
        : _dayTimeFormat.format(t);
  }

  final body = rows.map((row) {
    final day = dayOf(row);
    final end = _parseLocal(row['ended_at']);
    return [
      day,
      '${row['client_name'] ?? ''}',
      '${row['project_name'] ?? ''}',
      '${row['task_name'] ?? ''}',
      _hoursLabel(_hoursOf(row)),
      timeOf(_parseLocal(row['created_at']), day),
      end == null ? 'Em andamento' : timeOf(end, day),
    ];
  }).toList();

  final metaStyle = pw.TextStyle(fontSize: 9, color: _muted);
  final metaBold =
      pw.TextStyle(fontSize: 9, color: _navy, fontWeight: pw.FontWeight.bold);

  pw.Widget meta(String label, String value) => pw.RichText(
        text: pw.TextSpan(children: [
          pw.TextSpan(text: '$label: ', style: metaStyle),
          pw.TextSpan(text: value.isEmpty ? '-' : value, style: metaBold),
        ]),
      );

  pw.Widget header() => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (orgLogo != null) ...[
                pw.ClipRRect(
                  horizontalRadius: 4,
                  verticalRadius: 4,
                  child: pw.Image(orgLogo,
                      width: 46, height: 46, fit: pw.BoxFit.cover),
                ),
                pw.SizedBox(width: 12),
              ],
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (org.isNotEmpty)
                      pw.Text(org,
                          style: pw.TextStyle(
                              fontSize: 17,
                              color: _brand,
                              fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 2),
                    pw.Text('Relatório de Atividades',
                        style: pw.TextStyle(
                            fontSize: 14,
                            color: _navy,
                            fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    meta('Funcionário', name),
                    pw.SizedBox(height: 3),
                    meta('Organização', org),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    meta('Período', period),
                    pw.SizedBox(height: 3),
                    meta('Gerado em',
                        DateFormat('dd/MM/yyyy HH:mm').format(now)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Container(height: 1.6, color: _brand),
          pw.SizedBox(height: 12),
        ],
      );

  pw.Widget kpi(String label, String value) => pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: pw.BoxDecoration(
            color: _zebra,
            border: pw.Border.all(color: _brand, width: 0.8),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            children: [
              pw.Text(label, style: pw.TextStyle(fontSize: 8, color: _muted)),
              pw.SizedBox(height: 3),
              pw.Text(value,
                  style: pw.TextStyle(
                      fontSize: 13,
                      color: _navy,
                      fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
      );

  final cellPadding =
      const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4);
  final center = <int, pw.Alignment>{
    0: pw.Alignment.center,
    4: pw.Alignment.center,
    5: pw.Alignment.center,
    6: pw.Alignment.center,
  };

  final table = pw.TableHelper.fromTextArray(
    headers: const [
      'Data',
      'Cliente',
      'Projeto',
      'Tarefa',
      'Horas',
      'Início',
      'Fim',
    ],
    data: body.isEmpty
        ? [
            ['-', 'Nenhuma atividade no período', '', '', '-', '', '']
          ]
        : body,
    border: pw.TableBorder.all(color: _border, width: 0.4),
    headerDecoration: pw.BoxDecoration(color: _brand),
    headerStyle: pw.TextStyle(
        fontSize: 8.5, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
    headerAlignment: pw.Alignment.center,
    headerPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
    cellStyle: pw.TextStyle(fontSize: 8, color: _text),
    cellPadding: cellPadding,
    cellAlignment: pw.Alignment.centerLeft,
    cellAlignments: center,
    oddRowDecoration: pw.BoxDecoration(color: _zebra),
    columnWidths: const {
      0: pw.FlexColumnWidth(1.0),
      1: pw.FlexColumnWidth(1.6),
      2: pw.FlexColumnWidth(1.6),
      3: pw.FlexColumnWidth(2.6),
      4: pw.FlexColumnWidth(1.0),
      5: pw.FlexColumnWidth(1.1),
      6: pw.FlexColumnWidth(1.1),
    },
  );

  // Total row, styled like the web "foot" row.
  final totalRow = pw.Container(
    decoration: pw.BoxDecoration(
      color: _footFill,
      border: pw.Border(
        left: pw.BorderSide(color: _border, width: 0.4),
        right: pw.BorderSide(color: _border, width: 0.4),
        bottom: pw.BorderSide(color: _border, width: 0.4),
      ),
    ),
    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
    child: pw.Row(
      children: [
        pw.Expanded(
          flex: 68,
          child: pw.Text('Total de horas no período $period',
              style: pw.TextStyle(
                  fontSize: 8.5,
                  color: _navy,
                  fontWeight: pw.FontWeight.bold)),
        ),
        pw.Expanded(
          flex: 10,
          child: pw.Text(_hoursLabel(totalHours),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                  fontSize: 8.5,
                  color: _navy,
                  fontWeight: pw.FontWeight.bold)),
        ),
        pw.Spacer(flex: 22),
      ],
    ),
  );

  final doc = pw.Document(
    title: 'Relatório de Atividades - $name',
    author: org.isEmpty ? 'ZOC' : org,
    creator: 'ZOC',
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.fromLTRB(28, 26, 28, 22),
      header: (context) => context.pageNumber == 1
          ? header()
          : pw.Container(
              width: double.infinity,
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.only(bottom: 4),
              decoration: pw.BoxDecoration(
                  border: pw.Border(
                      bottom: pw.BorderSide(color: _brand, width: 0.8))),
              child: pw.Text(
                [
                  if (org.isNotEmpty) org,
                  'Relatório de Atividades',
                  name,
                  period
                ].where((s) => s.isNotEmpty).join('  |  '),
                style: pw.TextStyle(fontSize: 8, color: _muted),
              ),
            ),
      footer: (context) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 8),
        child: pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                  'Este relatório foi gerado automaticamente pelo sistema ZOC',
                  style: pw.TextStyle(fontSize: 7.5, color: _faint)),
            ),
            pw.Text('Página ${context.pageNumber} de ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 7.5, color: _faint)),
          ],
        ),
      ),
      build: (context) => [
        pw.Row(children: [
          kpi('Horas no período', _hoursLabel(totalHours)),
          pw.SizedBox(width: 8),
          kpi('Registros', '${rows.length}'),
          pw.SizedBox(width: 8),
          kpi('Projetos', '${projects.length}'),
          pw.SizedBox(width: 8),
          kpi('Tarefas', '${tasks.length}'),
          if (ignoredPopUps != null) ...[
            pw.SizedBox(width: 8),
            kpi('Popups ignorados', '$ignoredPopUps'),
          ],
        ]),
        pw.SizedBox(height: 14),
        table,
        totalRow,
      ],
    ),
  );

  return doc.save();
}

/// Builds the worker report and opens the system print / save dialog.
Future<void> generatePDF({
  required List<dynamic> activities,
  required String userName,
  required String periodLabel,
  required DateTime periodStart,
  required DateTime periodEnd,
  String? orgName,
  String? orgAvatarUrl,
  int? ignoredPopUps,
}) async {
  pw.ImageProvider? logo;
  final url = (orgAvatarUrl ?? '').trim();
  if (url.startsWith('http')) {
    try {
      logo = await networkImage(url).timeout(const Duration(seconds: 5));
    } catch (_) {
      logo = null; // Report still prints without the logo.
    }
  }

  try {
    final bytes = await buildActivitiesReportPdf(
      activities: activities,
      userName: userName,
      orgName: orgName,
      orgLogo: logo,
      periodLabel: periodLabel,
      periodStart: periodStart,
      periodEnd: periodEnd,
      ignoredPopUps: ignoredPopUps,
    );
    final stamp = DateFormat('yyyy-MM-dd').format(periodStart);
    // dynamicLayout must stay false: with dynamic layout the macOS plugin
    // blocks the main thread waiting for Dart to send the document, and
    // since Flutter runs Dart on that same thread the app deadlocks.
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'relatorio-atividades-$stamp.pdf',
      dynamicLayout: false,
    );
  } catch (e, stack) {
    debugPrint('PDF export failed: $e\n$stack');
  }
}
