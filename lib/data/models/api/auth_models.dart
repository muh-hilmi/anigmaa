import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

part 'auth_models.g.dart';

// Register Request
@JsonSerializable()
class RegisterRequest {
  final String email;
  final String username;
  final String password;
  @JsonKey(name: 'name')
  final String name;
  final String? phone;

  RegisterRequest({
    required this.email,
    required this.username,
    required this.password,
    required this.name,
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
