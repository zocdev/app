class ForgotPasswordRequest {
  const ForgotPasswordRequest({required this.email});

  final String email;

  Map<String, dynamic> toJson() => {'email': email};
}

class ResetPasswordRequest {
  const ResetPasswordRequest({
    required this.token,
    required this.password,
  });

  final String token;
  final String password;

  Map<String, dynamic> toJson() => {
        'token': token,
        'password': password,
      };
}

class MessageResponse {
  const MessageResponse({required this.message});

  final String message;

  factory MessageResponse.fromJson(Map<String, dynamic> json) =>
      MessageResponse(
        message: (json['message'] as String?) ??
            (json['error'] as String?) ??
            '',
      );
}

class ConfirmEmailRequest {
  const ConfirmEmailRequest({required this.otp});

  final String otp;

  Map<String, dynamic> toJson() => {'otp': otp};
}

class ResendConfirmationRequest {
  const ResendConfirmationRequest({required this.email});

  final String email;

  Map<String, dynamic> toJson() => {'email': email};
}

class RegisterAppRequest {
  const RegisterAppRequest({
    required this.email,
    required this.password,
    required this.termsAccepted,
    this.firstName,
    this.lastName,
  });

  final String email;
  final String password;
  final bool termsAccepted;
  final String? firstName;
  final String? lastName;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'email': email,
      'password': password,
      'termsAccepted': termsAccepted,
    };
    if (firstName != null && firstName!.isNotEmpty) {
      json['firstName'] = firstName;
    }
    if (lastName != null && lastName!.isNotEmpty) {
      json['lastName'] = lastName;
    }
    return json;
  }
}

class LoginAppRequest {
  const LoginAppRequest({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class VerifyEmailResponse {
  const VerifyEmailResponse({
    required this.firstTime,
    required this.exists,
    required this.verified,
  });

  final bool firstTime;
  final bool exists;
  final bool verified;

  factory VerifyEmailResponse.fromJson(Map<String, dynamic> json) =>
      VerifyEmailResponse(
        firstTime: json['first_time'] as bool? ?? false,
        exists: json['exists'] as bool? ?? false,
        verified: json['verified'] as bool? ?? false,
      );
}

class AuthError {
  const AuthError({
    required this.error,
    this.code,
  });

  final String error;
  final String? code;

  static const emailNotVerified = 'EMAIL_NOT_VERIFIED';

  bool get isEmailNotVerified => code == emailNotVerified;

  factory AuthError.fromJson(Map<String, dynamic> json) => AuthError(
        error: (json['error'] as String?) ??
            (json['message'] as String?) ??
            '',
        code: json['code'] as String?,
      );

  static AuthError? tryParse(dynamic body) {
    if (body is! Map) return null;
    final map = Map<String, dynamic>.from(body);
    if (map['error'] == null &&
        map['message'] == null &&
        map['code'] == null) {
      return null;
    }
    return AuthError.fromJson(map);
  }
}
