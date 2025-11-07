import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';
import '../../core/api/api_exception.dart';
import '../models/api/auth_models.dart';

class AuthApiService {
  final DioClient _dioClient;

  AuthApiService(this._dioClient);

  // Register new user
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _dioClient.post(
        '/auth/register',
        data: request.toJson(),
      );

      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // Login user
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _dioClient.post(
        '/auth/login',
        data: request.toJson(),
      );

      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      await _dioClient.post('/auth/logout');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // Refresh access token
  Future<AuthResponse> refreshToken(String refreshToken) async {
    try {
      final response = await _dioClient.post(
        '/auth/refresh',
        data: RefreshTokenRequest(refreshToken: refreshToken).toJson(),
      );

      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // Forgot password
  Future<void> forgotPassword(String email) async {
    try {
      await _dioClient.post(
        '/auth/forgot-password',
        data: ForgotPasswordRequest(email: email).toJson(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // Reset password
  Future<void> resetPassword(String token, String newPassword) async {
    try {
      await _dioClient.post(
        '/auth/reset-password',
        data: ResetPasswordRequest(
          token: token,
          newPassword: newPassword,
        ).toJson(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // Verify email
  Future<void> verifyEmail(String token) async {
    try {
      await _dioClient.post(
        '/auth/verify-email',
        data: VerifyEmailRequest(token: token).toJson(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
