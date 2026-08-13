// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_util.dart';
// Imports other custom actions
// Imports custom functions
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> generatePDF(
    List<dynamic>? ativities,
    String? workedHours,
    String? taskName,
    String? projectName,
    String? data,
    String? startDate,
    String? endDate,
    String? clientName,
    String? userName,
    String? popUps) async {
  final pdf = pw.Document(compress: false);
  final customPageFormat = PdfPageFormat.a4;

  final dateFormatter = DateFormat('d/M h:mm a');

  String formatDate(String? dateStr,
      {Duration timezoneOffset = const Duration(hours: -3)}) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final parsedUtc = DateTime.parse(dateStr).toUtc();
      final adjusted = parsedUtc.add(timezoneOffset);
      return dateFormatter.format(adjusted);
    } catch (e) {
      return dateStr; // si falla el parseo, devuelve el original
    }
  }

  String formatHoursToHhMm(num? hours) {
    if (hours == null) return '0h 0min';

    final wholeHours = hours.floor();
    final minutes = ((hours - wholeHours) * 60).round();
    if (minutes == 60) {
      return '${wholeHours + 1}h 0min';
    }
    return '${wholeHours}h ${minutes}min';
  }

  final parsedActivities =
      ativities?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];

  String resolvedUserName = '';
  if (parsedActivities.isNotEmpty) {
    resolvedUserName = parsedActivities.first['user_name']?.toString() ?? '';
  }
  parsedActivities.sort((a, b) {
    final aDateStr = a['created_at']?.toString();
    final bDateStr = b['created_at']?.toString();

    try {
      final aDate = DateTime.tryParse(aDateStr ?? '');
      final bDate = DateTime.tryParse(bDateStr ?? '');

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return aDate.compareTo(bDate);
    } catch (_) {
      return 0;
    }
  });

  num totalHours = 0;
  for (final row in parsedActivities) {
    final hours = row['hours'] is num
        ? row['hours'] as num
        : num.tryParse(row['hours']?.toString() ?? '0') ?? 0;
    totalHours += hours;
  }

  final tableRows = parsedActivities.map((row) {
    final createdAtStr = row['created_at']?.toString();
    final endedAtStr = row['ended_at']?.toString();

    return [
      row['entry_date']?.toString() ?? '',
      row['client_name']?.toString() ?? '',
      row['project_name']?.toString() ?? '',
      row['task_name']?.toString() ?? '',
      formatHoursToHhMm(
        row['hours'] is num
            ? row['hours']
            : num.tryParse(row['hours']?.toString() ?? '0'),
      ),
      formatDate(createdAtStr),
      formatDate(endedAtStr).isEmpty
          ? 'Não finalizado'
          : formatDate(endedAtStr),
      popUps ?? '',
    ];
  }).toList();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: customPageFormat,
      build: (pw.Context context) {
        return [
          pw.Text(
            'Relatório de Atividades - $resolvedUserName',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(
            headerDecoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#4AA9DA'),
            ),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
              color: PdfColor.fromInt(0xFFFFFFFF),
            ),
            headerAlignment: pw.Alignment.center,
            cellStyle: pw.TextStyle(
              fontSize: 8,
              color: PdfColor.fromInt(0xFF000000),
            ),
            cellAlignment: pw.Alignment.centerLeft,
            border: pw.TableBorder.all(
              color: PdfColor.fromInt(0xFFCCCCCC),
              width: 0.5,
            ),
            rowDecoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFFFFFFF),
            ),
            oddRowDecoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F7F7F7'),
            ),
            columnWidths: {
              0: const pw.FixedColumnWidth(60),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FixedColumnWidth(45),
              5: const pw.FixedColumnWidth(60),
              6: const pw.FixedColumnWidth(60),
              7: const pw.FixedColumnWidth(60),
            },
            headers: [
              'Data',
              'Cliente',
              'Projeto',
              'Tarefa',
              'Horas',
              'Início',
              'Fim',
              'PopUps ignorados'
            ],
            data: tableRows,
          ),
          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Total de horas no período: ${formatHoursToHhMm(totalHours)}',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ];
      },
    ),
  );

  try {
    print("Iniciando impresión directa...");
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => await pdf.save(),
    );
    print("Impresión iniciada con éxito");
  } catch (e, stack) {
    print("Error al imprimir: $e\nStack: $stack");
  }
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
