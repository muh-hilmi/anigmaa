// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

// RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) =>
//     RegisterRequest(
//       email: json['email'] as String,
//       username: json['username'] as String,
//       password: json['password'] as String,
//       fullName: json['full_name'] as String,
//       phone: json['phone'] as String?,
//     );

Map<String, dynamic> _$RegisterRequestToJson(RegisterRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'username': instance.username,
      'password': instance.password,
      'full_name': instance.fullName,
      'phone': instance.phone,
    };

// LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
//       email: json['email'] as String,
//       password: json['password'] as String,
//     );

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
    };

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'user': instance.user,
    };

// RefreshTokenRequest _$RefreshTokenRequestFromJson(Map<String, dynamic> json) =>
//     RefreshTokenRequest(
//       refreshToken: json['refresh_token'] as String,
//     );

Map<String, dynamic> _$RefreshTokenRequestToJson(
        RefreshTokenRequest instance) =>
    <String, dynamic>{
      'refresh_token': instance.refreshToken,
    };

// ForgotPasswordRequest _$ForgotPasswordRequestFromJson(
//         Map<String, dynamic> json) =>
//     ForgotPasswordRequest(
//       email: json['email'] as String,
//     );

Map<String, dynamic> _$ForgotPasswordRequestToJson(
        ForgotPasswordRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
    };

// ResetPasswordRequest _$ResetPasswordRequestFromJson(
//         Map<String, dynamic> json) =>
//     ResetPasswordRequest(
//       token: json['token'] as String,
//       newPassword: json['new_password'] as String,
//     );

Map<String, dynamic> _$ResetPasswordRequestToJson(
        ResetPasswordRequest instance) =>
    <String, dynamic>{
      'token': instance.token,
      'new_password': instance.newPassword,
    };

// VerifyEmailRequest _$VerifyEmailRequestFromJson(Map<String, dynamic> json) =>
//     VerifyEmailRequest(
//       token: json['token'] as String,
//     );

Map<String, dynamic> _$VerifyEmailRequestToJson(VerifyEmailRequest instance) =>
    <String, dynamic>{
      'token': instance.token,
    };
