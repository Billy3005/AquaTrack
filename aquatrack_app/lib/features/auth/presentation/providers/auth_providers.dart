import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';
import '../../data/auth_api.dart';
import '../../data/auth_repository.dart';
import '../../data/auth_storage.dart';
import '../../data/google_signin_service.dart';
import '../../domain/auth_service.dart';
import '../../domain/entities/user.dart';

/// Auth feature dependency injection providers
///
/// Setup cho feature-first architecture với proper dependency injection.
/// All auth-related dependencies được defined ở đây.

// ═══════════════════════════════════════════════════════════════════════════════════
// DATA LAYER PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════════

/// Auth API provider
final authAPIProvider = Provider<AuthAPI>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthAPIImpl(apiClient: apiClient);
});

/// Auth storage provider
final authStorageProvider = Provider<AuthStorage>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final storageService = ref.watch(storageServiceProvider);
  return AuthStorageImpl(
    secureStorage: secureStorage,
    storageService: storageService,
  );
});

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authAPI = ref.watch(authAPIProvider);
  final authStorage = ref.watch(authStorageProvider);
  final apiClient = ref.watch(apiClientProvider);
  final storageService = ref.watch(storageServiceProvider);

  return AuthRepositoryImpl(
    authAPI: authAPI,
    authStorage: authStorage,
    apiClient: apiClient,
    storageService: storageService,
  );
});

// ═══════════════════════════════════════════════════════════════════════════════════
// DOMAIN LAYER PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════════

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthService(authRepository: authRepository);
});

/// Google Sign-In plugin wrapper (ADR 0006)
final googleSignInServiceProvider = Provider<GoogleSignInService>((ref) {
  return GoogleSignInService();
});

// ═══════════════════════════════════════════════════════════════════════════════════
// STATE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════════

/// Authentication state provider
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final googleSignInService = ref.watch(googleSignInServiceProvider);
  return AuthStateNotifier(
    authService: authService,
    googleSignInService: googleSignInService,
  );
});

/// Current user provider
final currentUserProvider = FutureProvider<User?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getCurrentUser();
});

/// Authentication status provider
final isAuthenticatedProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.isAuthenticated();
});

/// Onboarding status provider
final hasCompletedOnboardingProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.hasCompletedOnboarding();
});

// ═══════════════════════════════════════════════════════════════════════════════════
// AUTH STATE NOTIFIER
// ═══════════════════════════════════════════════════════════════════════════════════

/// Authentication state
class AuthState {
  final bool isAuthenticated;
  final User? currentUser;
  final bool isLoading;
  final String? error;
  final bool needsOnboarding;
  final DateTime lastUpdated;

  const AuthState({
    required this.isAuthenticated,
    this.currentUser,
    this.isLoading = false,
    this.error,
    this.needsOnboarding = false,
    required this.lastUpdated,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    User? currentUser,
    bool? isLoading,
    String? error,
    bool? needsOnboarding,
    DateTime? lastUpdated,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      currentUser: clearUser ? null : (currentUser ?? this.currentUser),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      needsOnboarding: needsOnboarding ?? this.needsOnboarding,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  /// Check if user is fully authenticated và ready
  bool get isReady => isAuthenticated && currentUser != null && !isLoading;

  /// Check if there's an active error
  bool get hasError => error != null && error!.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          runtimeType == other.runtimeType &&
          isAuthenticated == other.isAuthenticated &&
          currentUser == other.currentUser &&
          isLoading == other.isLoading &&
          error == other.error &&
          needsOnboarding == other.needsOnboarding;

  @override
  int get hashCode =>
      isAuthenticated.hashCode ^
      currentUser.hashCode ^
      isLoading.hashCode ^
      error.hashCode ^
      needsOnboarding.hashCode;

  @override
  String toString() =>
      'AuthState(isAuth: $isAuthenticated, user: ${currentUser?.username}, loading: $isLoading, error: $error, onboarding: $needsOnboarding)';
}

/// Authentication state notifier
class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final GoogleSignInService? _googleSignInService;

  AuthStateNotifier({
    required AuthService authService,
    GoogleSignInService? googleSignInService,
  })  : _authService = authService,
        _googleSignInService = googleSignInService,
        super(AuthState(
          isAuthenticated: false,
          lastUpdated: DateTime.now(),
        )) {
    _initialize();
  }

  /// Initialize auth state
  Future<void> _initialize() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      await _authService.initialize();
      if (!mounted) return;

      final isAuth = await _authService.isAuthenticated();
      if (!mounted) return;

      if (isAuth) {
        final user = await _authService.getCurrentUser();
        final needsOnboarding = !(await _authService.hasCompletedOnboarding());
        if (!mounted) return;

        state = state.copyWith(
          isAuthenticated: true,
          currentUser: user,
          isLoading: false,
          needsOnboarding: needsOnboarding,
        );
      } else {
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
          clearUser: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        error: 'Lỗi khởi tạo xác thực: $e',
        clearUser: true,
      );
    }
  }

  /// Login user
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final result = await _authService.login(
        email: email,
        password: password,
      );
      if (!mounted) return;

      if (result.isSuccess && result.user != null) {
        state = state.copyWith(
          isAuthenticated: true,
          currentUser: result.user,
          isLoading: false,
          needsOnboarding: result.needsOnboarding,
        );
      } else {
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
          error: result.error ?? 'Đăng nhập thất bại',
          clearUser: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        error: 'Lỗi đăng nhập: $e',
        clearUser: true,
      );
    }
  }

  /// Google Sign-In (ADR 0006): run the account picker, trade the ID token
  /// for app tokens. A dismissed picker is not an error — just stop loading.
  Future<void> loginWithGoogle() async {
    final google = _googleSignInService;
    if (google == null) return;

    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final idToken = await google.getIdToken();
      if (!mounted) return;

      if (idToken == null) {
        state = state.copyWith(isLoading: false);
        return; // user closed the picker
      }

      final result = await _authService.loginWithGoogle(idToken: idToken);
      if (!mounted) return;

      if (result.isSuccess && result.user != null) {
        state = state.copyWith(
          isAuthenticated: true,
          currentUser: result.user,
          isLoading: false,
          needsOnboarding: result.needsOnboarding,
        );
      } else {
        // Backend refused the token — drop the plugin's cached account so a
        // retry shows the picker again instead of silently reusing it.
        await google.signOut();
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
          error: result.error ?? 'Đăng nhập Google thất bại',
          clearUser: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        error: 'Lỗi đăng nhập Google: $e',
        clearUser: true,
      );
    }
  }

  /// Register user
  Future<void> register({
    required String email,
    required String password,
    required String username,
    String? fullName,
    int? dailyGoalMl,
    String? referralCode,
  }) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final result = await _authService.register(
        email: email,
        password: password,
        username: username,
        fullName: fullName,
        dailyGoalMl: dailyGoalMl,
        referralCode: referralCode,
      );
      if (!mounted) return;

      if (result.isSuccess && result.user != null) {
        state = state.copyWith(
          isAuthenticated: true,
          currentUser: result.user,
          isLoading: false,
          needsOnboarding: result.needsOnboarding,
        );
      } else {
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
          error: result.error ?? 'Đăng ký thất bại',
          clearUser: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        error: 'Lỗi đăng ký: $e',
        clearUser: true,
      );
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      await _authService.logout();
      // Also drop the Google account cache so the next sign-in re-prompts.
      await _googleSignInService?.signOut();
      if (!mounted) return;

      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        needsOnboarding: false,
        clearUser: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi đăng xuất: $e',
      );
    }
  }

  /// Update user profile
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final updatedUser = await _authService.updateProfile(updates);
      if (!mounted) return;

      state = state.copyWith(
        currentUser: updatedUser,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi cập nhật hồ sơ: $e',
      );
    }
  }

  /// Complete onboarding
  Future<void> completeOnboarding(Map<String, dynamic> bodyInfo) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      await _authService.completeOnboarding(bodyInfo: bodyInfo);
      if (!mounted) return;

      // Refresh user data
      final updatedUser = await _authService.getCurrentUser(forceRefresh: true);
      if (!mounted) return;

      state = state.copyWith(
        currentUser: updatedUser,
        isLoading: false,
        needsOnboarding: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi hoàn thành thiết lập: $e',
      );
    }
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    try {
      if (!state.isAuthenticated) return;

      final user = await _authService.getCurrentUser(forceRefresh: true);
      if (!mounted) return;
      if (user != null) {
        state = state.copyWith(currentUser: user);
      }
    } catch (e) {
      // Don't update error state for background refresh failures
      // Just log the error
      // Note: Import AppLogger if needed, for now using minimal logging
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }
}
