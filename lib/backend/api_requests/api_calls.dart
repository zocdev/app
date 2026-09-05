import 'dart:convert';

import 'package:flutter/foundation.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';
import 'api_config.dart';
import 'auth_models.dart';

export 'api_manager.dart' show ApiCallResponse;
export 'auth_models.dart';

class LoginCall {
  static Future<ApiCallResponse> call({
    String? email = '',
    String? password = '',
    bool? remoteValue,
  }) async {
    final ffApiRequestBody = '''
{
  "email": "${escapeStringForJson(email)}",
  "password": "${escapeStringForJson(password)}",
  "remote": $remoteValue
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'login',
      apiUrl: '${getBaseApiUrl()}/api/v1/auth/login-app',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: true,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static int? expiresIn(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.expires_in''',
      ));
  static String? refreshToken(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.refresh_token''',
      ));
  static String? accessToken(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.access_token''',
      ));

  static AuthError? authError(ApiCallResponse response) =>
      AuthError.tryParse(response.jsonBody);

  static bool isEmailNotVerified(ApiCallResponse response) {
    if (response.statusCode != 403) return false;
    return authError(response)?.isEmailNotVerified ?? false;
  }
}

class AddAtivitiesCall {
  static Future<ApiCallResponse> call({
    List<String>? tasksList,
    String? token = '',
    String? project = '',
    bool? remote,
    bool? ignoredPopUp = false,
    String? notes = '',
    String? createdAt = '',
    String? screenshot = '',
  }) async {
    final tasks = _serializeList(tasksList);

    final ffApiRequestBody = '''
{
  "tasks": $tasks,
  "project_id": "${escapeStringForJson(project)}",
  "remote": $remote,
  "ignored_popup": $ignoredPopUp,
  "notes": "${escapeStringForJson(notes)}",
  "createdAt": "${escapeStringForJson(createdAt)}",
  "screenshot": "${escapeStringForJson(screenshot)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'AddAtivities',
      apiUrl: '${getBaseApiUrl()}/api/v1/timemanager/entries',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: true,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetProjectsCall {
  static Future<ApiCallResponse> call({
    String? token = '',
    String? orgId = '',
    String? userid = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'GetProjects',
      apiUrl: '${getBaseApiUrl()}/api/v1/assignments/projects/user/$userid',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer $token',
      },
      params: {
        'org_id': orgId,
        'status': '1',
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: true,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetClientsCall {
  static Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'GetClients',
      apiUrl: '${getBaseApiUrl()}/api/v1/clients',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer $token',
      },
      params: {
        'status': '1',
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: true,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetAtivitiesByProjectCall {
  static Future<ApiCallResponse> call({
    String? token = '',
    String? id = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'GetAtivitiesByProject',
      apiUrl: '${getBaseApiUrl()}/api/v1/tasks/app/project/$id',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer $token',
      },
      params: {
        'id': id,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: true,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetWorkedHoursCall {
  static Future<ApiCallResponse> call({
    String? token = '',
    String? userId = '',
    String? endDate = '',
    String? startDate = '',
    String? period = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'GetWorkedHours',
      apiUrl: '${getBaseApiUrl()}/api/v1/users/work-hours/$userId',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer $token',
      },
      params: {
        'period': period,
        'startDate': startDate,
        'endDate': endDate,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: true,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetTaskDoneByUserCall {
  static Future<ApiCallResponse> call({
    String? token = '',
    String? userId = '',
    String? endDate = '',
    String? startDate = '',
    String? period = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'GetTaskDoneByUser',
      apiUrl: '${getBaseApiUrl()}/api/v1/tasks/user/done/$userId',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer $token',
      },
      params: {
        'userId': userId,
        'period': period,
        'startDate': startDate,
        'endDate': endDate,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: true,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class VerifyEmailCall {
  static const emailNotFoundFallback =
      'Email no encontrado. Verifica el email o pide a tu administrador un invitación.';

  static Future<ApiCallResponse> call({
    String? email = '',
  }) async {
    final normalizedEmail = (email ?? '').trim().toLowerCase();
    return ApiManager.instance.makeApiCall(
      callName: 'verifyEmail',
      apiUrl: '${getBaseApiUrl()}/api/v1/auth/verify-email',
      callType: ApiCallType.GET,
      headers: {
        'Accept': 'application/json',
      },
      params: {
        'email': normalizedEmail,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: true,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static VerifyEmailResponse? parse(dynamic response) {
    if (response is! Map) return null;
    return VerifyEmailResponse.fromJson(Map<String, dynamic>.from(response));
  }

  static String emailNotFoundMessage(ApiCallResponse response) {
    return emailNotFoundFallback;
  }
}

class RegisterUserCall {
  static Future<ApiCallResponse> call({
    String? email = '',
    String? password = '',
    bool? termsAccepted,
    String? firstName,
    String? lastName,
  }) async {
    final request = RegisterAppRequest(
      email: email ?? '',
      password: password ?? '',
      termsAccepted: termsAccepted ?? false,
      firstName: firstName,
      lastName: lastName,
    );
    return ApiManager.instance.makeApiCall(
      callName: 'registerUser',
      apiUrl: '${getBaseApiUrl()}/api/v1/auth/register-app',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      params: {},
      body: jsonEncode(request.toJson()),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: true,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class VerifyOtpCall {
  static Future<ApiCallResponse> call({
    String? otp,
  }) async {
    final request = ConfirmEmailRequest(otp: otp ?? '');
    return ApiManager.instance.makeApiCall(
      callName: 'verifyOtp',
      apiUrl: '${getBaseApiUrl()}/api/v1/auth/confirm-email',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      params: {},
      body: jsonEncode(request.toJson()),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: true,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static AuthError? authError(ApiCallResponse response) =>
      AuthError.tryParse(response.jsonBody);
}

class ResendEmailConfirmationCall {
  static Future<ApiCallResponse> call({
    String? email = '',
  }) async {
    final request = ResendConfirmationRequest(email: email ?? '');
    return ApiManager.instance.makeApiCall(
      callName: 'resend email confirmation',
      apiUrl: '${getBaseApiUrl()}/api/v1/auth/resend-confirmation',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      params: {},
      body: jsonEncode(request.toJson()),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: true,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static AuthError? authError(ApiCallResponse response) =>
      AuthError.tryParse(response.jsonBody);
}

class ForgotPasswordCall {
  static Future<ApiCallResponse> call({
    String? email = '',
  }) async {
    final ffApiRequestBody = '''
{
  "email": "${escapeStringForJson(email)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'forgot password',
      apiUrl: '${getBaseApiUrl()}/api/v1/auth/forgot-password',
      callType: ApiCallType.POST,
      headers: {},
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: true,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
}

class ResetPasswordCall {
  static Future<ApiCallResponse> call({
    String? token = '',
    String? password = '',
  }) async {
    final ffApiRequestBody = '''
{
  "token": "${escapeStringForJson(token)}",
  "password": "${escapeStringForJson(password)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'reset password',
      apiUrl: '${getBaseApiUrl()}/api/v1/auth/reset-password',
      callType: ApiCallType.POST,
      headers: {},
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: true,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
}

class IgnoredPopUpsCall {
  static Future<ApiCallResponse> call({
    String? id = '',
    String? startDate = '',
    String? endDate = '',
    String? period = '',
    String? token = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'ignoredPopUps',
      apiUrl: '${getBaseApiUrl()}/api/v1/timemanager/entries/ignored/$id',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer $token',
      },
      params: {
        'id': id,
        'period': period,
        'startDate': startDate,
        'endDate': endDate,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: true,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static int count(ApiCallResponse? response) {
    final body = response?.jsonBody;
    final direct = castToType<int>(body);
    if (direct != null) return direct;
    if (body is Map) {
      return castToType<int>(getJsonField(body, r'''$.count''')) ??
          castToType<int>(getJsonField(body, r'''$.total''')) ??
          castToType<int>(getJsonField(body, r'''$.ignored''')) ??
          castToType<int>(getJsonField(body, r'''$.ignored_popups''')) ??
          castToType<int>(getJsonField(body, r'''$.ignored_popup''')) ??
          0;
    }
    if (body is String) {
      return int.tryParse(body.trim()) ?? 0;
    }
    return 0;
  }
}

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}

String _toEncodable(dynamic item) {
  return item;
}

String _serializeList(List? list) {
  list ??= <String>[];
  try {
    return json.encode(list, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("List serialization failed. Returning empty list.");
    }
    return '[]';
  }
}

String? escapeStringForJson(String? input) {
  if (input == null) {
    return null;
  }
  return input
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\t', '\\t');
}
