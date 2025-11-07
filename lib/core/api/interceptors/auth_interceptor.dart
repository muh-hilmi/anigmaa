import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/app_logger.dart';

/// Interceptor to handle authentication tokens
/// Automatically attaches Bearer token to requests
class AuthInterceptor extends Interceptor {
  final _logger = AppLogger();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _secureStorage.read(key: 'access_token');

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      _logger.error('Failed to read auth token', e);
    }

    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 Unauthorized - token expired
    if (err.response?.statusCode == 401) {
      _logger.warning('Unauthorized request - token may be expired');

      // Clear invalid tokens
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken != null && refreshToken.isNotEmpty) {
        // TODO: Implement token refresh logic
        await _secureStorage.delete(key: 'access_token');
        await _secureStorage.delete(key: 'refresh_token');
      }
    }

    handler.next(err);
  }
}
