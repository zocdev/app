import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'error_handler.dart';

Future<T?> handleSupabaseCall<T>({
  required BuildContext? context,
  required Future<T> Function() supabaseCall,
  bool showError = true,
  bool showErrorAsDialog = false,
  VoidCallback? onError,
  T? Function(Object error)? onErrorReturn,
}) async {
  try {
    return await supabaseCall();
  } catch (e, stackTrace) {
    if (context != null && showError) {
      ErrorHandler().handleException(context, e, stackTrace);
    }
    onError?.call();
    return onErrorReturn?.call(e);
  }
}

Future<List<T>> handleSupabaseQuery<T>({
  required BuildContext? context,
  required Future<List<T>> Function() queryCall,
  bool showError = true,
  bool showErrorAsDialog = false,
  VoidCallback? onError,
}) async {
  try {
    return await queryCall();
  } catch (e, stackTrace) {
    if (context != null && showError) {
      ErrorHandler().handleException(context, e, stackTrace);
    }
    onError?.call();
    return [];
  }
}

Future<T?> handleSupabaseInsert<T>({
  required BuildContext? context,
  required Future<T> Function() insertCall,
  bool showError = true,
  bool showErrorAsDialog = false,
  VoidCallback? onError,
}) async {
  try {
    return await insertCall();
  } catch (e, stackTrace) {
    if (e is PostgrestException) {
      final error = AppError.fromException(e, stackTrace);
      if (context != null && showError) {
        ErrorHandler().handleError(
          context,
          error,
          showDialog: showErrorAsDialog,
          showSnackbar: !showErrorAsDialog,
        );
      }
    } else if (context != null && showError) {
      ErrorHandler().handleException(context, e, stackTrace);
    }
    onError?.call();
    return null;
  }
}

Future<bool> handleSupabaseUpdate({
  required BuildContext? context,
  required Future<void> Function() updateCall,
  bool showError = true,
  bool showErrorAsDialog = false,
  VoidCallback? onError,
}) async {
  try {
    await updateCall();
    return true;
  } catch (e, stackTrace) {
    if (e is PostgrestException) {
      final error = AppError.fromException(e, stackTrace);
      if (context != null && showError) {
        ErrorHandler().handleError(
          context,
          error,
          showDialog: showErrorAsDialog,
          showSnackbar: !showErrorAsDialog,
        );
      }
    } else if (context != null && showError) {
      ErrorHandler().handleException(context, e, stackTrace);
    }
    onError?.call();
    return false;
  }
}

Future<bool> handleSupabaseDelete({
  required BuildContext? context,
  required Future<void> Function() deleteCall,
  bool showError = true,
  bool showErrorAsDialog = false,
  VoidCallback? onError,
}) async {
  try {
    await deleteCall();
    return true;
  } catch (e, stackTrace) {
    if (e is PostgrestException) {
      final error = AppError.fromException(e, stackTrace);
      if (context != null && showError) {
        ErrorHandler().handleError(
          context,
          error,
          showDialog: showErrorAsDialog,
          showSnackbar: !showErrorAsDialog,
        );
      }
    } else if (context != null && showError) {
      ErrorHandler().handleException(context, e, stackTrace);
    }
    onError?.call();
    return false;
  }
}

