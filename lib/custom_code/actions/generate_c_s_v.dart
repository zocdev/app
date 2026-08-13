// Automatic FlutterFlow imports
// Imports other custom actions
// Imports custom functions
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart'; // Para obtener directorios

Future<void> generateCSV(
  String? ativities,
  String? workedHours,
  String? workingDay,
  String? ignoredPopups,
) async {
  // Contenido del CSV
  String csvContent = "Campo,Valor\n";
  csvContent += "Atividades,${ativities ?? ''}\n";
  csvContent += "Horas trabalhadas,${workedHours ?? ''}\n";
  csvContent += "Jornada laboral,${workingDay ?? ''}\n";
  csvContent += "Pop ups ignorados,${ignoredPopups ?? ''}\n";

  // Codificar a bytes
  final bytes = utf8.encode(csvContent);

  // Obtener el directorio de descargas (o documentos si descargas no está disponible)
  final directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
  final filePath = '${directory.path}\\reporte.csv'; // Usar \ para Windows

  // Escribir el archivo
  final file = File(filePath);
  await file.writeAsBytes(bytes);

  // Opcional: Mostrar un mensaje de éxito (si quieres feedback en la UI)
  print('CSV generado en: $filePath');
}