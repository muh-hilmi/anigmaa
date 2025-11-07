class AppConstants {
  // App Information
  static const String appName = 'Anigmaa';
  static const String appVersion = '1.0.0';

  // API Constants
  static const String baseUrl = 'https://anigmaa.muhhilmi.site';
  static const String apiVersion = 'v1';
  static const String apiBasePath = '/api/v1';

  // API Timeouts
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  static const int sendTimeout = 30000; // 30 seconds

  // Image Constants
  static const String defaultEventImage = 'https://doodleipsum.com/600x400/abstract';
  static const String defaultAvatarImage = 'https://doodleipsum.com/100x100/avatar';
  static const int maxImageSize = 1200;
  static const int imageQuality = 85;

  // Event Constants
  static const int maxEventTitle = 100;
  static const int minEventDescription = 10;
  static const int maxEventDescription = 1000;
  static const int maxAttendees = 1000;
  static const double maxEventPrice = 10000000;

  // UI Constants
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  static const double spacing = 16.0;

  // Animation Durations
  static const int fadeAnimationDuration = 500;
  static const int slideAnimationDuration = 300;
  static const int buttonAnimationDuration = 200;
}