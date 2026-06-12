import '../../../core/utils/logger.dart';
import '../../../core/error/app_exceptions.dart';
import '../data/auth_repository.dart';
import 'entities/user.dart';

/// Auth domain service
///
/// Contains business logic cho authentication operations. Orchestrates
/// auth workflows và enforces business rules.
class AuthService {
  static const String _tag = 'AuthService';

  final AuthRepository _authRepository;

  AuthService({required AuthRepository authRepository})
      : _authRepository = authRepository;

  /// Initialize auth service
  Future<void> initialize() async {
    await _authRepository.initialize();
    AppLogger.debug(_tag, 'AuthService initialized');
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // AUTHENTICATION FLOWS
  // ═══════════════════════════════════════════════════════════════════════════════════

  /// Login user với business validation
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info(_tag, 'Login initiated for: $email');

      // Validate input
      _validateLoginInput(email: email, password: password);

      // Perform login
      final user = await _authRepository.login(
        email: email,
        password: password,
      );

      // Check if user needs onboarding
      final needsOnboarding = await _checkOnboardingStatus(user);

      AppLogger.info(_tag, 'Login successful for: ${user.username}');
      return AuthResult.success(
        user: user,
        needsOnboarding: needsOnboarding,
      );
    } catch (e) {
      AppLogger.error(_tag, 'Login failed for: $email', e);
      return AuthResult.failure(_getAuthError(e));
    }
  }

  /// Register user với business validation
  Future<AuthResult> register({
    required String email,
    required String password,
    required String username,
    String? fullName,
    int? dailyGoalMl,
  }) async {
    try {
      AppLogger.info(_tag, 'Registration initiated for: $email');

      // Validate input
      _validateRegistrationInput(
        email: email,
        password: password,
        username: username,
        fullName: fullName,
        dailyGoalMl: dailyGoalMl,
      );

      // Perform registration
      final user = await _authRepository.register(
        email: email,
        password: password,
        username: username,
        fullName: fullName,
        dailyGoalMl: dailyGoalMl,
      );

      AppLogger.info(_tag, 'Registration successful for: ${user.username}');
      return AuthResult.success(
        user: user,
        needsOnboarding: !user.hasCompletedProfile, // New users need onboarding
      );
    } catch (e) {
      AppLogger.error(_tag, 'Registration failed for: $email', e);
      return AuthResult.failure(_getAuthError(e));
    }
  }

  /// Logout user với cleanup
  Future<void> logout() async {
    try {
      AppLogger.info(_tag, 'Logout initiated');
      await _authRepository.logout();
      AppLogger.info(_tag, 'Logout completed');
    } catch (e) {
      AppLogger.error(_tag, 'Logout failed', e);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // USER STATE MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════════════

  /// Check authentication status
  Future<bool> isAuthenticated() async {
    try {
      return await _authRepository.isAuthenticated();
    } catch (e) {
      AppLogger.error(_tag, 'Error checking authentication status', e);
      return false;
    }
  }

  /// Get current user
  Future<User?> getCurrentUser({bool forceRefresh = false}) async {
    try {
      return await _authRepository.getCurrentUser(forceRefresh: forceRefresh);
    } catch (e) {
      AppLogger.error(_tag, 'Error getting current user', e);
      return null;
    }
  }

  /// Update user profile với business validation
  Future<User> updateProfile(Map<String, dynamic> updates) async {
    try {
      AppLogger.info(_tag, 'Profile update initiated');

      // Validate updates
      _validateProfileUpdates(updates);

      final updatedUser = await _authRepository.updateProfile(updates);

      AppLogger.info(_tag, 'Profile updated successfully');
      return updatedUser;
    } catch (e) {
      AppLogger.error(_tag, 'Profile update failed', e);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // ONBOARDING MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════════════

  /// Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    try {
      return await _authRepository.hasCompletedOnboarding();
    } catch (e) {
      AppLogger.error(_tag, 'Error checking onboarding status', e);
      return false;
    }
  }

  /// Complete onboarding flow
  Future<void> completeOnboarding({
    required Map<String, dynamic> bodyInfo,
  }) async {
    try {
      AppLogger.info(_tag, 'Onboarding completion initiated');

      // Validate body information
      _validateBodyInfo(bodyInfo);

      // Update profile với body information
      await updateProfile(bodyInfo);

      // Mark onboarding as completed
      await _authRepository.setOnboardingCompleted();

      AppLogger.info(_tag, 'Onboarding completed successfully');
    } catch (e) {
      AppLogger.error(_tag, 'Onboarding completion failed', e);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // TOKEN MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════════════

  /// Get access token for API calls
  Future<String?> getAccessToken() async {
    try {
      return await _authRepository.getAccessToken();
    } catch (e) {
      AppLogger.error(_tag, 'Error getting access token', e);
      return null;
    }
  }

  /// Refresh authentication token
  Future<void> refreshToken() async {
    try {
      await _authRepository.refreshToken();
      AppLogger.debug(_tag, 'Token refreshed successfully');
    } catch (e) {
      AppLogger.error(_tag, 'Token refresh failed', e);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // VALIDATION METHODS
  // ═══════════════════════════════════════════════════════════════════════════════════

  /// Validate login input
  void _validateLoginInput({
    required String email,
    required String password,
  }) {
    final errors = <String, List<String>>{};

    // Email validation
    if (email.trim().isEmpty) {
      errors['email'] = ['Email không được để trống'];
    } else if (!_isValidEmail(email)) {
      errors['email'] = ['Email không hợp lệ'];
    }

    // Password validation
    if (password.isEmpty) {
      errors['password'] = ['Mật khẩu không được để trống'];
    } else if (password.length < 6) {
      errors['password'] = ['Mật khẩu phải có ít nhất 6 ký tự'];
    }

    if (errors.isNotEmpty) {
      throw ValidationException(
        'Dữ liệu đăng nhập không hợp lệ',
        fieldErrors: errors,
        code: 'LOGIN_VALIDATION_ERROR',
      );
    }
  }

  /// Validate registration input
  void _validateRegistrationInput({
    required String email,
    required String password,
    required String username,
    String? fullName,
    int? dailyGoalMl,
  }) {
    final errors = <String, List<String>>{};

    // Email validation
    if (email.trim().isEmpty) {
      errors['email'] = ['Email không được để trống'];
    } else if (!_isValidEmail(email)) {
      errors['email'] = ['Email không hợp lệ'];
    }

    // Password validation
    if (password.isEmpty) {
      errors['password'] = ['Mật khẩu không được để trống'];
    } else if (password.length < 6) {
      errors['password'] = ['Mật khẩu phải có ít nhất 6 ký tự'];
    }

    // Username validation
    if (username.trim().isEmpty) {
      errors['username'] = ['Tên người dùng không được để trống'];
    } else if (username.length < 3) {
      errors['username'] = ['Tên người dùng phải có ít nhất 3 ký tự'];
    } else if (!_isValidUsername(username)) {
      errors['username'] = [
        'Tên người dùng chỉ được chứa chữ cái, số và dấu gạch dưới'
      ];
    }

    // Full name validation (optional)
    if (fullName != null && fullName.trim().isNotEmpty) {
      if (fullName.length < 2) {
        errors['fullName'] = ['Họ tên phải có ít nhất 2 ký tự'];
      }
    }

    // Daily goal validation (optional)
    if (dailyGoalMl != null) {
      if (dailyGoalMl < 500 || dailyGoalMl > 5000) {
        errors['dailyGoalMl'] = [
          'Mục tiêu nước hàng ngày phải từ 500ml đến 5000ml'
        ];
      }
    }

    if (errors.isNotEmpty) {
      throw ValidationException(
        'Dữ liệu đăng ký không hợp lệ',
        fieldErrors: errors,
        code: 'REGISTRATION_VALIDATION_ERROR',
      );
    }
  }

  /// Validate profile updates
  void _validateProfileUpdates(Map<String, dynamic> updates) {
    final errors = <String, List<String>>{};

    // Validate each field if present
    if (updates.containsKey('email')) {
      final email = updates['email'] as String?;
      if (email != null && !_isValidEmail(email)) {
        errors['email'] = ['Email không hợp lệ'];
      }
    }

    if (updates.containsKey('username')) {
      final username = updates['username'] as String?;
      if (username != null) {
        if (username.length < 3) {
          errors['username'] = ['Tên người dùng phải có ít nhất 3 ký tự'];
        } else if (!_isValidUsername(username)) {
          errors['username'] = [
            'Tên người dùng chỉ được chứa chữ cái, số và dấu gạch dưới'
          ];
        }
      }
    }

    if (updates.containsKey('age')) {
      final age = updates['age'] as int?;
      if (age != null && (age < 13 || age > 120)) {
        errors['age'] = ['Tuổi phải từ 13 đến 120'];
      }
    }

    if (updates.containsKey('height')) {
      final height = updates['height'] as int?;
      if (height != null && (height < 100 || height > 250)) {
        errors['height'] = ['Chiều cao phải từ 100cm đến 250cm'];
      }
    }

    if (updates.containsKey('weight')) {
      final weight = updates['weight'] as double?;
      if (weight != null && (weight < 30 || weight > 300)) {
        errors['weight'] = ['Cân nặng phải từ 30kg đến 300kg'];
      }
    }

    if (errors.isNotEmpty) {
      throw ValidationException(
        'Dữ liệu cập nhật không hợp lệ',
        fieldErrors: errors,
        code: 'PROFILE_VALIDATION_ERROR',
      );
    }
  }

  /// Validate body information for onboarding
  void _validateBodyInfo(Map<String, dynamic> bodyInfo) {
    final errors = <String, List<String>>{};

    // Required fields for onboarding
    final requiredFields = [
      'gender',
      'age',
      'height',
      'weight',
      'activityLevel'
    ];

    for (final field in requiredFields) {
      if (!bodyInfo.containsKey(field) || bodyInfo[field] == null) {
        errors[field] = ['Trường này là bắt buộc'];
      }
    }

    // Validate specific fields
    final age = bodyInfo['age'] as int?;
    if (age != null && (age < 13 || age > 120)) {
      errors['age'] = ['Tuổi phải từ 13 đến 120'];
    }

    final height = bodyInfo['height'] as int?;
    if (height != null && (height < 100 || height > 250)) {
      errors['height'] = ['Chiều cao phải từ 100cm đến 250cm'];
    }

    final weight = bodyInfo['weight'] as double?;
    if (weight != null && (weight < 30 || weight > 300)) {
      errors['weight'] = ['Cân nặng phải từ 30kg đến 300kg'];
    }

    if (errors.isNotEmpty) {
      throw ValidationException(
        'Thông tin cơ thể không hợp lệ',
        fieldErrors: errors,
        code: 'BODY_INFO_VALIDATION_ERROR',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════════════

  /// Check if user needs onboarding
  Future<bool> _checkOnboardingStatus(User user) async {
    // Check if onboarding is completed in storage
    final onboardingCompleted = await _authRepository.hasCompletedOnboarding();
    if (onboardingCompleted) return false;

    // Check if user profile is complete
    return !user.hasCompletedProfile;
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email.trim());
  }

  /// Validate username format
  bool _isValidUsername(String username) {
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    return usernameRegex.hasMatch(username.trim());
  }

  /// Convert exception to appropriate auth error
  String _getAuthError(dynamic error) {
    if (error is ValidationException) {
      return error.message;
    }
    if (error is AuthException) {
      return error.message;
    }
    if (error is NetworkException) {
      return error.message;
    }
    return 'Có lỗi xảy ra khi xác thực. Vui lòng thử lại.';
  }

  /// Dispose resources
  void dispose() {
    _authRepository.dispose();
    AppLogger.debug(_tag, 'AuthService disposed');
  }
}

/// Auth operation result
class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? error;
  final bool needsOnboarding;

  const AuthResult._({
    required this.isSuccess,
    this.user,
    this.error,
    this.needsOnboarding = false,
  });

  factory AuthResult.success({
    required User user,
    bool needsOnboarding = false,
  }) {
    return AuthResult._(
      isSuccess: true,
      user: user,
      needsOnboarding: needsOnboarding,
    );
  }

  factory AuthResult.failure(String error) {
    return AuthResult._(
      isSuccess: false,
      error: error,
    );
  }

  @override
  String toString() =>
      'AuthResult(success: $isSuccess, error: $error, needsOnboarding: $needsOnboarding)';
}
