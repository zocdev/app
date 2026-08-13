// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
// Imports other custom actions
// Imports custom functions
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:supabase_flutter/supabase_flutter.dart';

Future<bool> checkIfEmailExists(String email) async {
  final supabase =
      Supabase.instance.client; // Asegúrate de que Supabase está inicializado

  try {
    final response = await supabase
        .from(
            'users') // Asegúrate de que la tabla de usuarios en Supabase se llama 'users'
        .select('id') // Solo seleccionamos el ID
        .eq('email', email)
        .maybeSingle(); // Evita errores si no hay resultados

    return response != null; // Si response tiene datos, el correo existe
  } catch (e) {
    return false; // Si hay un error, asumimos que el correo no existe
  }
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
