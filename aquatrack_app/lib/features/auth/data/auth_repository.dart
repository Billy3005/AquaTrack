import 'dart:convert';

import '../../../core/error/app_exceptions.dart';
import '../../../core/error/error_handler.dart';
import '../../../core/repositories/base_repository.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/utils/logger.dart';
import '../domain/entities/user.dart';
import 'auth_api.dart';
import 'auth_storage.dart';
import 'models/auth_models.dart';

/// Auth repository interface
///
/// Abstract interface cho authentication operations. Handles integration
/// giữa API, local storage, và caching logic.
abstract class AuthRepository {
  /// Authentication operations
  Future<User> login({required String email, required String password});
  Future<User> register({
    required String email,
    required String password,
    required String username,
    String? fullName,
    int? dailyGoalMl,
  });
  Future<void> logout();

  /// Token management
  Future<void> refreshToken();
  Future<bool> isAuthenticated();
  Future<String?> getAccessToken();

  /// User data
  Future<User?> getCurrentUser({bool forceRefresh = false});
  Future<User> updateProfile(Map<String, dynamic> updates);

  /// Onboarding
  Future<bool> hasCompletedOnboarding();
  Future<void> setOnboardingCompleted();

  /// Repository lifecycle
  Future<void> initialize();
  Future<void> clearAllData();
  void dispose();
}

/// Concrete implementation của AuthRepository
class AuthRepositoryImpl extends BaseRepository implements AuthRepository {
  static const String _tag = 'AuthRepository';

  final AuthAPI _authAPI;
  final AuthStorage _authStorage;

  // Cache keys
  static const String _currentUserCacheKey = 'current_user';

  AuthRepositoryImpl({
    required AuthAPI authAPI,
    required AuthStorage authStorage,
    required ApiClient apiClient,
    required StorageService storageService,
  })  : _authAPI = authAPI,
        _authStorage = authStorage,
        super(apiClient: apiClient, storageService: storageService);

  @override
  String get repositoryName => 'Auth';

  @override
  Duration get defaultCacheTtl => const Duration(minutes: 5);

  // ═══════════════════════════════════════════════════════════════════════════════════
  // AUTHENTICATION OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════════════

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info(_tag, 'Login attempt for email: $email');

      // Call API directly (not using executeApiCall wrapper since AuthAPI handles ApiResponse internally)
      final authResponse = await _authAPI.login(email: email, password: password);

      // Save tokens
      await _authStorage.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );

      // Calculate token expiry
      final expiry = DateTime.now().add(Duration(seconds: authResponse.expiresIn));
      await _authStorage.setTokenExpiry(expiry);

      // Save user data
      final user = authResponse.user.toDomainEntity();
      await _authStorage.saveUser(user);

      // Update API client với new token
      apiClient.setAuthToken(authResponse.accessToken);

      // Cache user data
      await saveToCache(
        key: _currentUserCacheKey,
        data: user,
        serializer: (user) => jsonEncode(UserModel.fromDomainEntity(user).toJson()),
      );

      AppLogger.info(_tag, 'Login successful for user: ${user.username}');
      return user;
    } catch (e) {
      AppLogger.error(_tag, 'Login failed for email: $email', e);
      final exception = ErrorHandler.handleError(e);
      throw exception;
    }
  }

  @override
  Future<User> register({
    required String email,
    required String password,
    required String username,
    String? fullName,
    int? dailyGoalMl,
  }) async {
    try {
      AppLogger.info(_tag, 'Register attempt for email: $email');

      // Call API directly
      final authResponse = await _authAPI.register(
        email: email,
        password: password,
        username: username,
        fullName: fullName,
        dailyGoalMl: dailyGoalMl,
      );

      // Save tokens
      await _authStorage.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );

      // Calculate token expiry
      final expiry = DateTime.now().add(Duration(seconds: authResponse.expiresIn));
      await _authStorage.setTokenExpiry(expiry);

      // Save user data
      final user = authResponse.user.toDomainEntity();
      await _authStorage.saveUser(user);

      // Update API client với new token
      apiClient.setAuthToken(authResponse.accessToken);

      // Cache user data
      await saveToCache(
        key: _currentUserCacheKey,
        data: user,
        serializer: (user) => jsonEncode(UserModel.fromDomainEntity(user).toJson()),
      );

      AppLogger.info(_tag, 'Registration successful for user: ${user.username}');
      return user;
    } catch (e) {
      AppLogger.error(_tag, 'Registration failed for email: $email', e);
      final exception = ErrorHandler.handleError(e);
      throw exception;
    }
  }

  @override
  Future<void> logout() async {
    try {
      AppLogger.info(_tag, 'Logout initiated');

      // Try to call logout API (best effort)
      try {
        await _authAPI.logout();
      } catch (e) {
        AppLogger.warning(_tag, 'API logout failed (continuing with local logout)', e);
      }

      // Clear local data
      await Future.wait([
        _authStorage.clearAllData(),
        clearCache(),
      ]);

      // Clear API client token
      apiClient.clearAuthToken();

      AppLogger.info(_tag, 'Logout completed');
    } catch (e) {
      AppLogger.error(_tag, 'Logout failed', e);
      throw ErrorHandler.handleError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // TOKEN MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════════════

  @override
  Future<void> refreshToken() async {
    try {
      AppLogger.debug(_tag, 'Token refresh initiated');

      final refreshToken = await _authStorage.getRefreshToken();
      if (refreshToken == null) {
        throw AuthException(
          'No refresh token available',
          code: 'NO_REFRESH_TOKEN',
        );
      }

      // Call refresh API directly
      final tokenResponse = await _authAPI.refreshToken(refreshToken: refreshToken);

      // Save new tokens
      await _authStorage.saveTokens(
        accessToken: tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken ?? refreshToken,
      );

      // Update token expiry
      final expiry = DateTime.now().add(Duration(seconds: tokenResponse.expiresIn));
      await _authStorage.setTokenExpiry(expiry);

      // Update API client
      apiClient.setAuthToken(tokenResponse.accessToken);

      AppLogger.debug(_tag, 'Token refresh successful');
    } catch (e) {
      AppLogger.error(_tag, 'Token refresh failed', e);

      // If refresh fails, logout user
      await logout();
      throw ErrorHandler.handleError(e);
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      // Read storage directly — no caching. A cached `true` could outlive a
      // server-side revoke/logout-elsewhere and let guarded screens fire
      // requests that 401.
      final isAuth = await _authStorage.isAuthenticated();

      // Check token expiry
      if (isAuth) {
        final expiry = await _authStorage.getTokenExpiry();
        if (expiry != null && DateTime.now().isAfter(expiry)) {
          AppLogger.debug(_tag, 'Token expired, attempting refresh');
          try {
            await refreshToken();
          } catch (e) {
            AppLogger.warning(_tag, 'Token refresh failed during auth check', e);
            return false;
          }
        }
      }

      return isAuth;
    } catch (e) {
      AppLogger.error(_tag, 'Error checking authentication state', e);
      return false;
    }
  }

  @override
  Future<String?> getAccessToken() async {
    try {
      return await _authStorage.getAccessToken();
    } catch (e) {
      AppLogger.error(_tag, 'Error getting access token', e);
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // USER DATA
  // ═══════════════════════════════════════════════════════════════════════════════════

  @override
  Future<User?> getCurrentUser({bool forceRefresh = false}) async {
    try {
      // Try cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedUser = await loadFromCache<User>(
          key: _currentUserCacheKey,
          deserializer: (data) =>
              UserModel.fromJson(jsonDecode(data) as Map<String, dynamic>)
                  .toDomainEntity(),
        );

        if (cachedUser != null) {
          AppLogger.debug(_tag, 'Retrieved user from cache: ${cachedUser.username}');
          return cachedUser;
        }
      }

      // Try storage
      final storedUser = await _authStorage.getStoredUser();
      if (storedUser != null && !forceRefresh) {
        // Cache the stored user
        await saveToCache(
          key: _currentUserCacheKey,
          data: storedUser,
          serializer: (user) => jsonEncode(UserModel.fromDomainEntity(user).toJson()),
        );
        AppLogger.debug(_tag, 'Retrieved user from storage: ${storedUser.username}');
        return storedUser;
      }

      // Fetch from API if authenticated
      if (await isAuthenticated()) {
        final userModel = await _authAPI.getCurrentUser();

        final user = userModel.toDomainEntity();

        // Save to storage và cache
        await Future.wait([
          _authStorage.saveUser(user),
          saveToCache(
            key: _currentUserCacheKey,
            data: user,
            serializer: (user) => jsonEncode(UserModel.fromDomainEntity(user).toJson()),
          ),
        ]);

        AppLogger.debug(_tag, 'Retrieved user from API: ${user.username}');
        return user;
      }

      AppLogger.debug(_tag, 'No current user available');
      return null;
    } catch (e) {
      AppLogger.error(_tag, 'Error getting current user', e);
      throw ErrorHandler.handleError(e);
    }
  }

  @override
  Future<User> updateProfile(Map<String, dynamic> updates) async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        throw AuthException(
          'No current user to update',
          code: 'NO_CURRENT_USER',
        );
      }

      AppLogger.info(_tag, 'Updating profile for user: ${currentUser.username}');

      // Call API directly
      final userModel = await _authAPI.updateProfile(
        userId: currentUser.id,
        updates: updates,
      );

      final updatedUser = userModel.toDomainEntity();

      // Update storage và cache
      await Future.wait([
        _authStorage.saveUser(updatedUser),
        saveToCache(
          key: _currentUserCacheKey,
          data: updatedUser,
          serializer: (user) => jsonEncode(UserModel.fromDomainEntity(user).toJson()),
        ),
      ]);

      AppLogger.info(_tag, 'Profile updated successfully');
      return updatedUser;
    } catch (e) {
      AppLogger.error(_tag, 'Profile update failed', e);
      throw ErrorHandler.handleError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // ONBOARDING
  // ═══════════════════════════════════════════════════════════════════════════════════

  @override
  Future<bool> hasCompletedOnboarding() async {
    try {
      return await _authStorage.hasCompletedOnboarding();
    } catch (e) {
      AppLogger.error(_tag, 'Error checking onboarding state', e);
      return false;
    }
  }

  @override
  Future<void> setOnboardingCompleted() async {
    try {
      await _authStorage.setOnboardingCompleted();
      AppLogger.info(_tag, 'Onboarding marked as completed');
    } catch (e) {
      AppLogger.error(_tag, 'Error setting onboarding completed', e);
      throw ErrorHandler.handleError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // REPOSITORY LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════════════

  @override
  Future<void> initialize() async {
    try {
      await super.initialize();

      // Check if we have a valid token and set it in API client
      if (await isAuthenticated()) {
        final token = await getAccessToken();
        if (token != null) {
          apiClient.setAuthToken(token);
        }
      }

      AppLogger.info(_tag, 'AuthRepository initialized');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to initialize AuthRepository', e);
      rethrow;
    }
  }

  @override
  Future<void> clearAllData() async {
    try {
      await Future.wait([
        _authStorage.clearAllData(),
        clearCache(),
      ]);

      apiClient.clearAuthToken();
      AppLogger.info(_tag, 'All auth data cleared');
    } catch (e) {
      AppLogger.error(_tag, 'Error clearing all auth data', e);
      throw ErrorHandler.handleError(e);
    }
  }

  @override
  void dispose() {
    super.dispose();
    AppLogger.debug(_tag, 'AuthRepository disposed');
  }
}