import 'package:hive_flutter/hive_flutter.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';
import '../network/default_api_client.dart';
import '../utils/logger.dart';
import 'auth_service.dart';

/// Main application service for initialization and coordination
class AppService {
  static const String _tag = 'AppService';

  // Singleton pattern
  static final AppService _instance = AppService._internal();
  factory AppService() => _instance;
  AppService._internal();

  // Service dependencies
  late final ApiClient _apiService;
  late final AuthService _authService;

  bool _isInitialized = false;

  /// Initialize all app services
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.warning(_tag, 'AppService already initialized');
      return;
    }

    try {
      AppLogger.info(_tag, 'Initializing AquaTrack app services...');

      // Initialize Hive for local storage
      await _initializeHive();

      // Initialize services in order
      await _initializeAuthService();
      await _initializeApiService();

      // Test API connection
      final isConnected = await _testApiConnection();
      if (isConnected) {
        AppLogger.info(_tag, 'API connection successful');
      } else {
        AppLogger.warning(
          _tag,
          'API connection failed - app will work offline',
        );
      }

      _isInitialized = true;
      AppLogger.info(_tag, 'App services initialized successfully');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to initialize app services', e);
      rethrow;
    }
  }

  /// Initialize Hive database
  Future<void> _initializeHive() async {
    AppLogger.debug(_tag, 'Initializing Hive database...');

    await Hive.initFlutter();

    // Additional Hive setup would go here (adapters, encryption, etc.)
    AppLogger.debug(_tag, 'Hive database initialized');
  }

  /// Initialize authentication service
  Future<void> _initializeAuthService() async {
    AppLogger.debug(_tag, 'Initializing AuthService...');

    _authService = AuthService();
    await _authService.initialize();

    AppLogger.debug(_tag, 'AuthService initialized');
  }

  /// Initialize API client
  Future<void> _initializeApiService() async {
    AppLogger.debug(_tag, 'Initializing ApiClient...');

    _apiService = defaultApiClient;
    await _apiService.initialize();

    AppLogger.debug(_tag, 'ApiClient initialized');
  }

  /// Test API connection
  Future<bool> _testApiConnection() async {
    try {
      return await _apiService.testConnection();
    } catch (e) {
      AppLogger.warning(_tag, 'API connection test failed', e);
      return false;
    }
  }

  /// Get API client instance
  ApiClient get apiService {
    _ensureInitialized();
    return _apiService;
  }

  /// Get auth service instance
  AuthService get authService {
    _ensureInitialized();
    return _authService;
  }

  /// Check if user is authenticated
  Future<bool> isUserAuthenticated() async {
    _ensureInitialized();
    return await _authService.isAuthenticated();
  }

  /// Get app configuration
  Map<String, dynamic> get appConfig => AppConfig.config;

  /// Check if app services are initialized
  bool get isInitialized => _isInitialized;

  /// Ensure services are initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('AppService not initialized. Call initialize() first.');
    }
  }

  /// Dispose all services
  Future<void> dispose() async {
    AppLogger.info(_tag, 'Disposing app services...');

    try {
      _apiService.dispose();
      await _authService.dispose();

      _isInitialized = false;
      AppLogger.info(_tag, 'App services disposed successfully');
    } catch (e) {
      AppLogger.error(_tag, 'Error disposing app services', e);
    }
  }

  /// Get app health status
  Future<Map<String, dynamic>> getHealthStatus() async {
    final health = <String, dynamic>{
      'app_initialized': _isInitialized,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (_isInitialized) {
      health['api_connected'] = await _apiService.testConnection();
      health['user_authenticated'] = await _authService.isAuthenticated();
    }

    return health;
  }

  /// Reset app to initial state (for logout or reset)
  Future<void> reset() async {
    AppLogger.info(_tag, 'Resetting app state...');

    try {
      // Clear authentication data
      await _authService.logout();

      // Clear any cached data
      // Additional cleanup would go here

      AppLogger.info(_tag, 'App state reset successfully');
    } catch (e) {
      AppLogger.error(_tag, 'Error resetting app state', e);
      rethrow;
    }
  }
}
