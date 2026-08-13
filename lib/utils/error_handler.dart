import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:async';
import 'api_client_exception.dart';

enum ErrorType {
  network,
  authentication,
  validation,
  server,
  database,
  unknown,
  timeout,
  permission,
}

class AppError {
  final ErrorType type;
  final String message;
  final String? userMessage;
  final Object? originalError;
  final StackTrace? stackTrace;
  final int? statusCode;
  final Map<String, dynamic>? metadata;

  AppError({
    required this.type,
    required this.message,
    this.userMessage,
    this.originalError,
    this.stackTrace,
    this.statusCode,
    this.metadata,
  });

  String get displayMessage => userMessage ?? _getDefaultMessage();

  String _getDefaultMessage() {
    switch (type) {
      case ErrorType.network:
        return 'Erro de conexão. Verifique sua internet e tente novamente.';
      case ErrorType.authentication:
        return 'Erro de autenticação. Por favor, faça login novamente.';
      case ErrorType.validation:
        return 'Dados inválidos. Verifique as informações e tente novamente.';
      case ErrorType.server:
        return 'Erro no servidor. Tente novamente mais tarde.';
      case ErrorType.database:
        return 'Erro ao acessar os dados. Tente novamente.';
      case ErrorType.timeout:
        return 'Tempo de espera esgotado. Tente novamente.';
      case ErrorType.permission:
        return 'Você não tem permissão para realizar esta ação.';
      case ErrorType.unknown:
        return 'Ocorreu um erro inesperado. Tente novamente.';
    }
  }

  factory AppError.fromException(Object error, [StackTrace? stackTrace]) {
    if (error is ApiClientException) {
      return AppError.fromApiResponse(error.statusCode, error.message);
    }

    if (error is SocketException) {
      return AppError(
        type: ErrorType.network,
        message: error.message,
        userMessage: 'Sem conexão com a internet. Verifique sua rede.',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is HttpException) {
      return AppError(
        type: ErrorType.network,
        message: error.message,
        userMessage: 'Erro de comunicação com o servidor.',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is TimeoutException) {
      return AppError(
        type: ErrorType.timeout,
        message: error.message ?? 'Request timeout',
        userMessage: 'Tempo de espera esgotado. Tente novamente.',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is PostgrestException) {
      final statusCode = error.code != null ? int.tryParse(error.code!) : null;
      ErrorType type = ErrorType.database;
      String? userMessage;

      if (statusCode == 401 || statusCode == 403) {
        type = ErrorType.authentication;
        userMessage = 'Erro de autenticação. Por favor, faça login novamente.';
      } else if (statusCode == 404) {
        userMessage = 'Recurso não encontrado.';
      } else if (statusCode == 409) {
        userMessage = 'Conflito. Este recurso já existe.';
      } else if (statusCode != null && statusCode >= 500) {
        type = ErrorType.server;
        userMessage = 'Erro no servidor. Tente novamente mais tarde.';
      }

      return AppError(
        type: type,
        message: error.message,
        userMessage: userMessage,
        originalError: error,
        stackTrace: stackTrace,
        statusCode: statusCode,
        metadata: {'code': error.code, 'details': error.details},
      );
    }

    if (error is AuthException) {
      return AppError(
        type: ErrorType.authentication,
        message: error.message,
        userMessage: _getAuthErrorMessage(error.statusCode?.toString()),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    return AppError(
      type: ErrorType.unknown,
      message: error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  factory AppError.fromApiResponse(int statusCode, String? message) {
    ErrorType type;
    String? userMessage;

    if (statusCode >= 200 && statusCode < 300) {
      type = ErrorType.unknown;
      userMessage = message ?? 'Erro desconhecido.';
    } else if (statusCode == 401 || statusCode == 403) {
      type = ErrorType.authentication;
      userMessage = message ??
          'Erro de autenticação. Por favor, faça login novamente.';
    } else if (statusCode == 400 || statusCode == 422) {
      type = ErrorType.validation;
      userMessage = message ?? 'Dados inválidos. Verifique as informações.';
    } else if (statusCode == 404) {
      type = ErrorType.unknown;
      userMessage = 'Recurso não encontrado.';
    } else if (statusCode >= 500) {
      type = ErrorType.server;
      userMessage = 'Erro no servidor. Tente novamente mais tarde.';
    } else {
      type = ErrorType.unknown;
      userMessage = message ?? 'Erro ao processar a solicitação.';
    }

    return AppError(
      type: type,
      message: message ?? 'HTTP $statusCode',
      userMessage: userMessage,
      statusCode: statusCode,
    );
  }

  static String _getAuthErrorMessage(String? status) {
    switch (status) {
      case 'invalid_credentials':
        return 'Email ou senha inválidos.';
      case 'email_not_confirmed':
        return 'Por favor, confirme seu email antes de fazer login.';
      case 'user_not_found':
        return 'Usuário não encontrado.';
      case 'too_many_requests':
        return 'Muitas tentativas. Aguarde alguns minutos.';
      default:
        return 'Erro de autenticação. Tente novamente.';
    }
  }

  @override
  String toString() => 'AppError(type: $type, message: $message)';
}

class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  final List<AppError> _errorHistory = [];
  static const int maxHistorySize = 50;

  void handleError(
    BuildContext? context,
    AppError error, {
    bool showSnackbar = true,
    bool showDialog = false,
    VoidCallback? onError,
  }) {
    _addToHistory(error);

    if (context == null || !context.mounted) {
      _logError(error);
      onError?.call();
      return;
    }

    if (showDialog) {
      _showErrorDialog(context, error);
    } else if (showSnackbar) {
      _showErrorSnackbar(context, error);
    }

    _logError(error);
    onError?.call();
  }

  void handleException(
    BuildContext? context,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    final appError = AppError.fromException(error, stackTrace);
    handleError(context, appError);
  }

  void _addToHistory(AppError error) {
    _errorHistory.add(error);
    if (_errorHistory.length > maxHistorySize) {
      _errorHistory.removeAt(0);
    }
  }

  void _showErrorSnackbar(BuildContext context, AppError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.displayMessage),
        backgroundColor: _getErrorColor(error.type),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: error.type == ErrorType.network ? 5 : 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, AppError error) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getErrorIcon(error.type),
              color: _getErrorColor(error.type),
            ),
            SizedBox(width: 8),
            Text(_getErrorTitle(error.type)),
          ],
        ),
        content: Text(error.displayMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Color _getErrorColor(ErrorType type) {
    switch (type) {
      case ErrorType.network:
      case ErrorType.timeout:
        return Colors.orange;
      case ErrorType.authentication:
      case ErrorType.permission:
        return Colors.red;
      case ErrorType.validation:
        return Colors.amber;
      case ErrorType.server:
      case ErrorType.database:
        return Colors.red.shade700;
      case ErrorType.unknown:
        return Colors.grey;
    }
  }

  IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.network:
      case ErrorType.timeout:
        return Icons.wifi_off;
      case ErrorType.authentication:
      case ErrorType.permission:
        return Icons.lock_outline;
      case ErrorType.validation:
        return Icons.error_outline;
      case ErrorType.server:
      case ErrorType.database:
        return Icons.storage;
      case ErrorType.unknown:
        return Icons.error;
    }
  }

  String _getErrorTitle(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return 'Erro de Conexão';
      case ErrorType.timeout:
        return 'Tempo Esgotado';
      case ErrorType.authentication:
        return 'Erro de Autenticação';
      case ErrorType.permission:
        return 'Sem Permissão';
      case ErrorType.validation:
        return 'Dados Inválidos';
      case ErrorType.server:
        return 'Erro no Servidor';
      case ErrorType.database:
        return 'Erro no Banco de Dados';
      case ErrorType.unknown:
        return 'Erro';
    }
  }

  void _logError(AppError error) {
    print('Error: ${error.type} - ${error.message}');
    if (error.originalError != null) {
      print('Original: ${error.originalError}');
    }
    if (error.stackTrace != null) {
      print('StackTrace: ${error.stackTrace}');
    }
  }

  List<AppError> get errorHistory => List.unmodifiable(_errorHistory);

  void clearHistory() {
    _errorHistory.clear();
  }

  AppError? getLastError() {
    return _errorHistory.isNotEmpty ? _errorHistory.last : null;
  }
}

extension ErrorHandlerExtension on BuildContext {
  void showError(AppError error, {bool asDialog = false}) {
    ErrorHandler().handleError(
      this,
      error,
      showDialog: asDialog,
      showSnackbar: !asDialog,
    );
  }

  void showErrorFromException(Object error, [StackTrace? stackTrace]) {
    ErrorHandler().handleException(this, error, stackTrace);
  }
}

