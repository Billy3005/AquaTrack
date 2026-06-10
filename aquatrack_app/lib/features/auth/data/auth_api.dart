import '../../../core/network/api_client.dart';
import '../domain/entities/user.dart';
import 'models/auth_models.dart';

/// Auth API interface
///
/// Abstract interface cho authentication operations với backend.
/// Cho phép easy mocking cho testing và potential backend changes.
abstract class AuthAPI {
  /// Login user với email và password
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  });

  /// Register new user
  Future<AuthResponseModel> register({
    required String email,
    required String password,
    required String username,
    String? fullName,
    int? dailyGoalMl,
  });

  /// Refresh access token using refresh token
  Future<TokenRefreshResponseModel> refreshToken({
    required String refreshToken,
  });

  /// Get current user profile
  Future<UserModel> getCurrentUser();

  /// Logout (invalidate tokens)
  Future<void> logout();

  /// Update user profile
  Future<UserModel> updateProfile({
    required String userId,
    required Map<String, dynamic> updates,
  });

  /// Test API connectivity
  Future<bool> ping();
}

/// Concrete implementation của AuthAPI sử dụng ApiClient
class AuthAPIImpl implements AuthAPI {
  final ApiClient _apiClient;

  AuthAPIImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );

    return AuthResponseModel.fromJson(response.data!);
  }

  @override
  Future<AuthResponseModel> register({
    required String email,
    required String password,
    required String username,
    String? fullName,
    int? dailyGoalMl,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        'username': username,
        if (fullName != null) 'full_name': fullName,
        if (dailyGoalMl != null) 'daily_goal_ml': dailyGoalMl,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );

    return AuthResponseModel.fromJson(response.data!);
  }

  @override
  Future<TokenRefreshResponseModel> refreshToken({
    required String refreshToken,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {
        'refresh_token': refreshToken,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );

    return TokenRefreshResponseModel.fromJson(response.data!);
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/auth/me',
      fromJson: (data) => data as Map<String, dynamic>,
    );

    return UserModel.fromJson(response.data!);
  }

  @override
  Future<void> logout() async {
    await _apiClient.post<void>(
      '/auth/logout',
      data: {},
    );
  }

  @override
  Future<UserModel> updateProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '/users/$userId',
      data: updates,
      fromJson: (data) => data as Map<String, dynamic>,
    );

    return UserModel.fromJson(response.data!);
  }

  @override
  Future<bool> ping() async {
    try {
      await _apiClient.get('/ping');
      return true;
    } catch (e) {
      return false;
    }
  }
}