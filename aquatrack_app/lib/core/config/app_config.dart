/// Application configuration constants
class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();

  // API Configuration (temporary port 8001 for testing)
  static const String apiBaseUrl = 'http://localhost:8001';
  static const String apiVersion = 'v1';

  // Simple endpoints for CORS testing
  static const String simpleLoginUrl = 'http://localhost:8001/simple-login';
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Authentication
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const Duration tokenRefreshThreshold = Duration(minutes: 5);

  // App Settings
  static const String appName = 'AquaTrack';
  static const String appVersion = '1.0.0';
  static const bool enableLogging = true;
  static const bool enableAnalytics = false;

  // Hydration Defaults
  static const int defaultDailyGoalMl = 2000;
  static const int minDailyGoalMl = 1000;
  static const int maxDailyGoalMl = 5000;
  static const int quickLogAmounts = 250; // Default quick log amount

  // Gamification
  static const int baseXpPerMl = 1; // 1 XP per 100ml
  static const List<int> quickLogOptions = [150, 250, 350, 500];

  // Cache Configuration
  static const Duration cacheExpiration = Duration(minutes: 15);
  static const int maxCacheSize = 50; // Number of cached responses

  // Network Configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Development/Debug Settings
  static const bool isDevelopment = true;
  static const bool enableDebugLogging = true;
  static const bool enableNetworkLogs = true;

  // Environment Detection
  static bool get isDebug {
    bool debug = false;
    assert(debug = true);
    return debug;
  }

  static bool get isProduction => !isDebug;

  // API Endpoints Helper
  static String get fullApiUrl => '$apiBaseUrl/api/$apiVersion';

  /// Get configuration based on environment
  static Map<String, dynamic> get config => {
        'apiBaseUrl': apiBaseUrl,
        'apiTimeout': apiTimeout.inMilliseconds,
        'enableLogging': enableLogging && isDebug,
        'enableAnalytics': enableAnalytics && isProduction,
        'maxRetries': maxRetries,
      };
}
