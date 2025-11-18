import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

part 'auth_models.g.dart';

// Register Request
// REVIEW: CRITICAL FIELD NAME MISMATCH - Backend expects "name" not "full_name".
// Backend RegisterRequest at backend_anigmaa/internal/domain/user/entity.go:79 uses json:"name".
// This @JsonKey(name: 'full_name') will cause ALL registrations to fail because backend validation
// will reject the request with "name is required" error. The frontend is sending the wrong field name.
// FIX: Change to @JsonKey(name: 'name') and rename the Dart field to just "name" for consistency.
@JsonSerializable()
class RegisterRequest {
  final String email;
  final String username;
  final String password;
  @JsonKey(name: 'full_name')
  final String fullName;
  final String? phone;

  RegisterRequest({
    required this.email,
    required this.username,
    required this.password,
    required this.fullName,
    this.phone,
  });

  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}

// Login Request
@JsonSerializable()
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

// Auth Response
@JsonSerializable()
class AuthResponse {
  @JsonKey(name: 'access_token')
  final String accessToken;
  @JsonKey(name: 'refresh_token')
  final String refreshToken;
  final UserModel user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

// Refresh Token Request
@JsonSerializable()
class RefreshTokenRequest {
  @JsonKey(name: 'refresh_token')
  final String refreshToken;

  RefreshTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() => _$RefreshTokenRequestToJson(this);
}

// Forgot Password Request
@JsonSerializable()
class ForgotPasswordRequest {
  final String email;

  ForgotPasswordRequest({required this.email});

  Map<String, dynamic> toJson() => _$ForgotPasswordRequestToJson(this);
}

// Reset Password Request
@JsonSerializable()
class ResetPasswordRequest {
  final String token;
  @JsonKey(name: 'new_password')
  final String newPassword;

  ResetPasswordRequest({
    required this.token,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => _$ResetPasswordRequestToJson(this);
}

// Verify Email Request
@JsonSerializable()
class VerifyEmailRequest {
  final String token;

  VerifyEmailRequest({required this.token});

  Map<String, dynamic> toJson() => _$VerifyEmailRequestToJson(this);
}
