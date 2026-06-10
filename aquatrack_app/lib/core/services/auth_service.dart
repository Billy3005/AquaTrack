import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/app_config.dart';
import '../utils/logger.dart';

/// Authentication service for managing JWT tokens and user sessions
///
/// @deprecated This singleton AuthService will be replaced with the new
/// dependency-injected AuthService in features/auth/domain/auth_service.dart
/// TODO: Migrate all usages to use new AuthService via Riverpod providers
class AuthService {
  static const String _tag = 'AuthService';

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Hive box for secure storage
  late Box _authBox;

  /// Initialize authentication service
  Future<void> initialize() async {
    try {
      _authBox = await Hive.openBox('auth_storage');
      AppLogger.debug(_tag, 'AuthService initialized');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to initialize AuthService', e);
      rethrow;
    }
  }

  /// Get stored access token
  Future<String?> getAccessToken() async {
    try {
      return _authBox.get(AppConfig.accessTokenKey);
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get access token', e);
      return null;
    }
  }

  /// Get stored refresh token
  Future<String?> getRefreshToken() async {
    try {
      return _authBox.get(AppConfig.refreshTokenKey);
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get refresh token', e);
      return null;
    }
  }

  /// Store authentication tokens
  Future<void> storeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await _authBox.put(AppConfig.accessTokenKey, accessToken);
      await _authBox.put(AppConfig.refreshTokenKey, refreshToken);
      AppLogger.debug(_tag, 'Tokens stored successfully');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to store tokens', e);
      rethrow;
    }
  }

  /// Store user data
  Future<void> storeUserData(Map<String, dynamic> userData) async {
    try {
      await _authBox.put(AppConfig.userDataKey, jsonEncode(userData));
      final userId = userData['id'] as String?;
      if (userId != null && userId.isNotEmpty) {
        // TODO: Remove when migrating to new auth architecture
        // globalAuthStateNotifier.onLogin(userId); // Removed - use new auth providers
      }
      AppLogger.debug(_tag, 'User data stored');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to store user data', e);
    }
  }

  /// Get stored user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final userDataJson = _authBox.get(AppConfig.userDataKey);
      if (userDataJson != null) {
        final userData = jsonDecode(userDataJson) as Map<String, dynamic>;
        AppLogger.debug(_tag,
            '📥 AuthService: Retrieved user data - username: ${userData['username']}, email: ${userData['email']}');
        return userData;
      }
      AppLogger.debug(_tag, '❌ AuthService: No user data found in storage');
      return null;
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get user data', e);
      return null;
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  /// Refresh authentication token
  Future<void> refreshToken() async {
    AppLogger.debug(_tag, 'Token refresh requested');

    final refreshToken = await getRefreshToken();
    if (refreshToken == null) {
      throw Exception('No refresh token available');
    }

    // This will be implemented when we integrate with the API
    // For now, throw an exception to trigger logout
    throw Exception('Token refresh not implemented yet');
  }

  /// Clear authentication data (logout)
  Future<void> logout() async {
    try {
      await _authBox.clear();
      // TODO: Remove when migrating to new auth architecture
      // globalAuthStateNotifier.onLogout(); // Removed - use new auth providers
      AppLogger.info(_tag, 'User logged out, auth data cleared');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to logout', e);
      rethrow;
    }
  }

  /// Get current user ID from token or stored data
  Future<String?> getCurrentUserId() async {
    final userData = await getUserData();
    return userData?['id'] as String?;
  }

  /// Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    return _authBox.get('onboarding_completed', defaultValue: false);
  }

  /// Mark onboarding as completed
  Future<void> setOnboardingCompleted() async {
    await _authBox.put('onboarding_completed', true);
    AppLogger.debug(_tag, 'Onboarding marked as completed');
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _authBox.close();
    AppLogger.debug(_tag, 'AuthService disposed');
  }
}
