import 'dart:convert';

import '../../../core/storage/secure_storage.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/utils/logger.dart';
import '../domain/entities/user.dart';
import 'models/auth_models.dart';

/// Auth storage interface
///
/// Abstract interface cho local storage operations related to authentication.
/// Handles tokens, user data, và onboarding state.
abstract class AuthStorage {
  /// Token management
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });
  Future<void> clearTokens();

  /// User data management
  Future<User?> getStoredUser();
  Future<void> saveUser(User user);
  Future<void> clearUserData();

  /// Onboarding state
  Future<bool> hasCompletedOnboarding();
  Future<void> setOnboardingCompleted();
  Future<void> clearOnboardingState();

  /// Authentication state
  Future<bool> isAuthenticated();
  Future<void> clearAllData();

  /// Token metadata
  Future<DateTime?> getTokenExpiry();
  Future<void> setTokenExpiry(DateTime expiry);
}

/// Concrete implementation sử dụng SecureStorage cho tokens và
/// StorageService cho non-sensitive data
class AuthStorageImpl implements AuthStorage {
  static const String _tag = 'AuthStorage';

  // Storage keys
  static const String _userDataKey = 'user_data';
  static const String _onboardingKey = 'onboarding_completed';
  static const String _tokenExpiryKey = 'token_expiry';

  final SecureStorage _secureStorage;
  final StorageService _storageService;

  AuthStorageImpl({
    required SecureStorage secureStorage,
    required StorageService storageService,
  })  : _secureStorage = secureStorage,
        _storageService = storageService;

  // ═══════════════════════════════════════════════════════════════════════════════════
  // TOKEN MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════════════

  @override
  Future<String?> getAccessToken() async {
    try {
      final token = await _secureStorage.getAccessToken();
      AppLogger.debug(_tag, 'Retrieved access token: ${token != null ? 'exists' : 'not found'}');
      return token;
    } catch (e) {
      AppLogger.error(_tag, 'Error getting access token', e);
      return null;
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      final token = await _secureStorage.getRefreshToken();
      AppLogger.debug(_tag, 'Retrieved refresh token: ${token != null ? 'exists' : 'not found'}');
      return token;
    } catch (e) {
      AppLogger.error(_tag, 'Error getting refresh token', e);
      return null;
    }
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await Future.wait([
        _secureStorage.saveAccessToken(accessToken),
        _secureStorage.saveRefreshToken(refreshToken),
      ]);
      AppLogger.debug(_tag, 'Tokens saved successfully');
    } catch (e) {
      AppLogger.error(_tag, 'Error saving tokens', e);
      rethrow;
    }
  }

  @override
  Future<void> clearTokens() async {
    try {
      await _secureStorage.clearTokens();
      await _storageService.remove(_tokenExpiryKey);
      AppLogger.debug(_tag, 'Tokens cleared successfully');
    } catch (e) {
      AppLogger.error(_tag, 'Error clearing tokens', e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // USER DATA MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════════════

  @override
  Future<User?> getStoredUser() async {
    try {
      final userJson = await _storageService.getString(_userDataKey);
      if (userJson == null) {
        AppLogger.debug(_tag, 'No stored user data found');
        return null;
      }

      // Parse JSON và convert to domain entity
      final userMap = _parseJsonString(userJson);
      if (userMap == null) return null;

      final userModel = UserModel.fromJson(userMap);
      final user = userModel.toDomainEntity();

      AppLogger.debug(_tag, 'Retrieved stored user: ${user.username}');
      return user;
    } catch (e) {
      AppLogger.error(_tag, 'Error getting stored user', e);
      return null;
    }
  }

  @override
  Future<void> saveUser(User user) async {
    try {
      final userModel = UserModel.fromDomainEntity(user);
      final userJson = _jsonToString(userModel.toJson());

      await _storageService.setString(_userDataKey, userJson);
      AppLogger.debug(_tag, 'User data saved: ${user.username}');
    } catch (e) {
      AppLogger.error(_tag, 'Error saving user data', e);
      rethrow;
    }
  }

  @override
  Future<void> clearUserData() async {
    try {
      await _storageService.remove(_userDataKey);
      AppLogger.debug(_tag, 'User data cleared');
    } catch (e) {
      AppLogger.error(_tag, 'Error clearing user data', e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // ONBOARDING STATE
  // ═══════════════════════════════════════════════════════════════════════════════════

  @override
  Future<bool> hasCompletedOnboarding() async {
    try {
      final completed = await _storageService.getBool(_onboardingKey) ?? false;
      AppLogger.debug(_tag, 'Onboarding completed: $completed');
      return completed;
    } catch (e) {
      AppLogger.error(_tag, 'Error checking onboarding state', e);
      return false;
    }
  }

  @override
  Future<void> setOnboardingCompleted() async {
    try {
      await _storageService.setBool(_onboardingKey, true);
      AppLogger.debug(_tag, 'Onboarding marked as completed');
    } catch (e) {
      AppLogger.error(_tag, 'Error setting onboarding completed', e);
      rethrow;
    }
  }

  @override
  Future<void> clearOnboardingState() async {
    try {
      await _storageService.remove(_onboardingKey);
      AppLogger.debug(_tag, 'Onboarding state cleared');
    } catch (e) {
      AppLogger.error(_tag, 'Error clearing onboarding state', e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // AUTHENTICATION STATE
  // ═══════════════════════════════════════════════════════════════════════════════════

  @override
  Future<bool> isAuthenticated() async {
    try {
      final accessToken = await getAccessToken();
      final user = await getStoredUser();

      final isAuth = accessToken != null && accessToken.isNotEmpty && user != null;
      AppLogger.debug(_tag, 'Authentication state: $isAuth');
      return isAuth;
    } catch (e) {
      AppLogger.error(_tag, 'Error checking authentication state', e);
      return false;
    }
  }

  @override
  Future<void> clearAllData() async {
    try {
      await Future.wait([
        clearTokens(),
        clearUserData(),
        clearOnboardingState(),
      ]);
      AppLogger.info(_tag, 'All authentication data cleared');
    } catch (e) {
      AppLogger.error(_tag, 'Error clearing all auth data', e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // TOKEN METADATA
  // ═══════════════════════════════════════════════════════════════════════════════════

  @override
  Future<DateTime?> getTokenExpiry() async {
    try {
      final expiryString = await _storageService.getString(_tokenExpiryKey);
      if (expiryString == null) return null;

      return DateTime.tryParse(expiryString);
    } catch (e) {
      AppLogger.error(_tag, 'Error getting token expiry', e);
      return null;
    }
  }

  @override
  Future<void> setTokenExpiry(DateTime expiry) async {
    try {
      await _storageService.setString(_tokenExpiryKey, expiry.toIso8601String());
      AppLogger.debug(_tag, 'Token expiry set: $expiry');
    } catch (e) {
      AppLogger.error(_tag, 'Error setting token expiry', e);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════════════

  /// Parse JSON string to Map
  Map<String, dynamic>? _parseJsonString(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) return decoded;
      AppLogger.warning(_tag, 'Stored user data is not a JSON object');
      return null;
    } catch (e) {
      AppLogger.error(_tag, 'Error parsing JSON string', e);
      return null;
    }
  }

  /// Convert Map to JSON string
  String _jsonToString(Map<String, dynamic> map) {
    try {
      return jsonEncode(map);
    } catch (e) {
      AppLogger.error(_tag, 'Error converting to JSON string', e);
      rethrow;
    }
  }
}