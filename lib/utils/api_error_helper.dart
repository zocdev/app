import 'package:flutter/material.dart';
import '/backend/api_requests/api_manager.dart';
import 'api_client_exception.dart';
import 'error_handler.dart';

extension ApiCallResponseExtension on ApiCallResponse {
  bool get hasError => !succeeded || exception != null;

  String? get errorCode {
    if (jsonBody is Map) {
      return (jsonBody as Map)['code'] as String?;
    }
    return null;
  }

  AppError? toAppError() {
    if (succeeded && exception == null) return null;

    if (exception != null) {
      return AppError.fromException(exception!);
    }

    final error = AppError.fromApiResponse(
      statusCode,
      _extractErrorMessage(),
    );
    final code = errorCode;
    if (code == null) return error;
    return AppError(
      type: error.type,
      message: error.message,
      userMessage: error.userMessage,
      originalError: error.originalError,
      stackTrace: error.stackTrace,
      statusCode: error.statusCode,
      metadata: {...?error.metadata, 'code': code},
    );
  }

  String? _extractErrorMessage() {
    if (jsonBody is Map) {
      final body = jsonBody as Map;
      final errors = body['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) {
          return first.first.toString();
        }
        return first.toString();
      }
      return body['message'] as String? ??
          body['error'] as String? ??
          body['detail'] as String?;
    }
    if (jsonBody is String) {
      return jsonBody as String;
    }
    return null;
  }

  void throwIfFailed() {
    if (succeeded && exception == null) return;

    if (exception != null) {
      throw ApiClientException(
        statusCode: statusCode > 0 ? statusCode : -1,
        message: exception.toString(),
        body: jsonBody,
      );
    }

    throw ApiClientException(
      statusCode: statusCode,
      message: _extractErrorMessage() ?? 'HTTP $statusCode',
      body: jsonBody,
    );
  }
}

Future<T?> handleApiCall<T>({
  required BuildContext? context,
  required Future<ApiCallResponse> Function() apiCall,
  required T? Function(ApiCallResponse) onSuccess,
  bool showError = true,
  bool showErrorAsDialog = false,
  VoidCallback? onError,
}) async {
  try {
    final response = await apiCall();

    if (response.hasError) {
      final error = response.toAppError();
      if (error != null && context != null && showError) {
        ErrorHandler().handleError(
          context,
          error,
          showDialog: showErrorAsDialog,
          showSnackbar: !showErrorAsDialog,
        );
      }
      onError?.call();
      return null;
    }

    return onSuccess(response);
  } catch (e, stackTrace) {
    if (context != null && showError) {
      ErrorHandler().handleException(context, e, stackTrace);
    }
    onError?.call();
    return null;
  }
}

