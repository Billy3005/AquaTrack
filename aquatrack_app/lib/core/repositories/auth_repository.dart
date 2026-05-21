import '../models/auth.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';
import '../providers/auth_state_provider.dart';

/// Repository for authentication-related API calls
class AuthRepository {
  static const String _tag = 'AuthRepository';

  final ApiService _apiService;
  final AuthService _authService;

  AuthRepository({ApiService? apiService, AuthService? authService})
    : _apiService = apiService ?? ApiService(),
      _authService = authService ?? AuthService();

  /// Login with email and password
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    AppLogger.info(_tag, 'Attempting login for email: $email');

    try {
      final request = LoginRequest(email: email, password: password);

      final response = await _apiService.post<AuthResponse>(
        '/auth/login',
        data: request.toJson(),
        fromJson: (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
      );

      if (response.data != null) {
        // Store tokens and user data
        await _authService.storeTokens(
          accessToken: response.data!.accessToken,
          refreshToken: response.data!.refreshToken,
        );
        await _authService.storeUserData(response.data!.user.toJson());

        // Notify auth state change
        try {
          globalAuthStateNotifier.onLogin(response.data!.user.id);
        } catch (e) {
          // Ignore if global notifier not initialized yet
          AppLogger.debug(_tag, 'Auth state notifier not ready: $e');
        }

        AppLogger.info(
          _tag,
          'Login successful for user: ${response.data!.user.id}',
        );
        return response.data!;
      } else {
        throw Exception('Login response data is null');
      }
    } catch (e) {
      AppLogger.error(_tag, 'Login failed', e);
      rethrow;
    }
  }

  /// Register new user account
  Future<AuthResponse> register({
    required String email,
    required String password,
    String? username,
    String? fullName,
  }) async {
    AppLogger.info(_tag, 'Attempting registration for email: $email');

    try {
      final request = UserCreateRequest(
        email: email,
        password: password,
        username: username,
        fullName: fullName,
      );

      final response = await _apiService.post<AuthResponse>(
        '/auth/register',
        data: request.toJson(),
        fromJson: (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
      );

      if (response.data != null) {
        // Store tokens and user data
        await _authService.storeTokens(
          accessToken: response.data!.accessToken,
          refreshToken: response.data!.refreshToken,
        );
        await _authService.storeUserData(response.data!.user.toJson());

        // Notify auth state change
        try {
          globalAuthStateNotifier.onLogin(response.data!.user.id);
        } catch (e) {
          // Ignore if global notifier not initialized yet
          AppLogger.debug(_tag, 'Auth state notifier not ready: $e');
        }

        AppLogger.info(
          _tag,
          'Registration successful for user: ${response.data!.user.id}',
        );
        return response.data!;
      } else {
        throw Exception('Registration response data is null');
      }
    } catch (e) {
      AppLogger.error(_tag, 'Registration failed', e);
      rethrow;
    }
  }

  /// Refresh access token using refresh token
  Future<RefreshTokenResponse> refreshToken() async {
    AppLogger.debug(_tag, 'Attempting token refresh');

    try {
      final refreshToken = await _authService.getRefreshToken();
      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      final request = RefreshTokenRequest(refreshToken: refreshToken);

      final response = await _apiService.post<RefreshTokenResponse>(
        '/auth/refresh',
        data: request.toJson(),
        fromJson: (json) =>
            RefreshTokenResponse.fromJson(json as Map<String, dynamic>),
      );

      if (response.data != null) {
        // Store new tokens
        await _authService.storeTokens(
          accessToken: response.data!.accessToken,
          refreshToken: response.data!.refreshToken,
        );

        AppLogger.debug(_tag, 'Token refresh successful');
        return response.data!;
      } else {
        throw Exception('Token refresh response data is null');
      }
    } catch (e) {
      AppLogger.error(_tag, 'Token refresh failed', e);
      rethrow;
    }
  }

  /// Logout user and clear stored data
  Future<void> logout() async {
    AppLogger.info(_tag, 'Logging out user');

    try {
      // Attempt to notify backend about logout (optional)
      try {
        await _apiService.post('/auth/logout');
      } catch (e) {
        // Ignore API errors for logout - we'll clear local data anyway
        AppLogger.warning(
          _tag,
          'Backend logout failed, continuing with local logout',
          e,
        );
      }

      // Clear local auth data
      await _authService.logout();

      // Notify auth state change
      try {
        globalAuthStateNotifier.onLogout();
      } catch (e) {
        // Ignore if global notifier not initialized yet
        AppLogger.debug(_tag, 'Auth state notifier not ready: $e');
      }

      AppLogger.info(_tag, 'Logout completed');
    } catch (e) {
      AppLogger.error(_tag, 'Logout failed', e);
      rethrow;
    }
  }

  /// Check if user is currently authenticated
  Future<bool> isAuthenticated() async {
    return _authService.isAuthenticated();
  }

  /// Get current authenticated user data
  Future<User?> getCurrentUser() async {
    try {
      final userData = await _authService.getUserData();
      if (userData != null) {
        return User.fromJson(userData);
      }
      return null;
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get current user', e);
      return null;
    }
  }

  /// Verify if stored token is still valid
  Future<bool> verifyToken() async {
    try {
      final response = await _apiService.get('/auth/verify');
      return response.isSuccess;
    } catch (e) {
      AppLogger.warning(_tag, 'Token verification failed', e);
      return false;
    }
  }

  /// Request password reset
  Future<void> requestPasswordReset(String email) async {
    AppLogger.info(_tag, 'Requesting password reset for: $email');

    try {
      await _apiService.post('/auth/forgot-password', data: {'email': email});
      AppLogger.info(_tag, 'Password reset request sent');
    } catch (e) {
      AppLogger.error(_tag, 'Password reset request failed', e);
      rethrow;
    }
  }

  /// Reset password with token
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    AppLogger.info(_tag, 'Resetting password with token');

    try {
      await _apiService.post(
        '/auth/reset-password',
        data: {'token': token, 'new_password': newPassword},
      );
      AppLogger.info(_tag, 'Password reset successful');
    } catch (e) {
      AppLogger.error(_tag, 'Password reset failed', e);
      rethrow;
    }
  }

  /// Change password for authenticated user
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    AppLogger.info(_tag, 'Changing password for authenticated user');

    try {
      await _apiService.post(
        '/auth/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
      AppLogger.info(_tag, 'Password change successful');
    } catch (e) {
      AppLogger.error(_tag, 'Password change failed', e);
      rethrow;
    }
  }
}
