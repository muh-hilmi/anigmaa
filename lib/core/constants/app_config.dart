import 'dart:io';

class AppConfig {
  // Environment mode
  static const bool isDevelopment = true;

  // API Base URL
  static String get baseUrl {
    if (isDevelopment) {
      // Android emulator menggunakan 10.0.2.2 untuk akses localhost host machine
      // iOS simulator dan desktop bisa pakai localhost
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8081';  // Emulator
      } else {
        return 'http://localhost:8081';
      }
    } else {
      // Production backend
      return 'https://anigmaa.muhhilmi.site';
    }
  }

  static const String apiVersion = 'v1';
  static const String apiBasePath = '/api/v1';

  // Full API URL
  static String get apiUrl => '$baseUrl$apiBasePath';
}
