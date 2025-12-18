/// Application-wide constants following Clean Architecture principles
/// Centralized configuration for better maintainability
class AppConstants {
  // App Information
  static const String appName = 'flyerr';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String baseUrl = 'https://anigmaa.muhhilmi.site';
  static const String apiVersion = 'v1';
  static const String apiBasePath = '/api/v1';

  // Network Timeouts (in milliseconds)
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;

  // Image Configuration
  static const String defaultEventImage = 'https://doodleipsum.com/600x400/abstract';
  static const String defaultAvatarImage = 'https://doodleipsum.com/100x100/avatar';
  static const int maxImageSize = 1200;
  static const int imageQuality = 85;

  // Event Validation Constants
  static const int maxEventTitle = 100;
  static const int minEventDescription = 10;
  static const int maxEventDescription = 1000;
  static const int maxAttendees = 1000;
  static const double maxEventPrice = 10000000;

  // UI Design System
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  static const double spacing = 16.0;

  // Animation Durations (in milliseconds)
  static const int fadeAnimationDuration = 500;
  static const int slideAnimationDuration = 300;
  static const int buttonAnimationDuration = 200;

  // Pagination
  static const int defaultPageSize = 20;

  // Cache Configuration
  static const int maxCacheSize = 100;
  static const Duration cacheExpiration = Duration(hours: 1);

  // Security
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
}