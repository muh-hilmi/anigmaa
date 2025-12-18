import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_logger.dart';
import '../../../main.dart' show navigatorKey;

/// Interceptor to handle authentication tokens
/// Automatically attaches Bearer token to requests
class AuthInterceptor extends Interceptor {
  final _logger = AppLogger();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _isRedirectingToLogin = false;

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
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 Unauthorized - token expired
    if (err.response?.statusCode == 401 && !_isRedirectingToLogin) {
      _logger.warning('Sesi kadaluarsa - mengarahkan ke login');

      _isRedirectingToLogin = true;

      // Clear invalid tokens and user data
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');

      // Clear SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', false);
        await prefs.remove('user_email');
        await prefs.remove('user_name');
        await prefs.remove('user_id');
      } catch (e) {
        _logger.error('Failed to clear preferences', e);
      }

      // Navigate to login screen using global navigator key
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        // Show persistent dialog instead of quick snackbar
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.logout, color: Colors.orange),
                SizedBox(width: 12),
                Text('Sesi Berakhir'),
              ],
            ),
            content: const Text(
              'Sesi kamu udah habis nih. Yuk login lagi biar bisa lanjut! 🔐',
              style: TextStyle(fontSize: 15),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Login Sekarang',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );

        // Navigate to login and clear navigation stack
        if (context.mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      }

      _isRedirectingToLogin = false;
    }

    handler.next(err);
  }
}
