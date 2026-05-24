import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

/// Provider to track authentication state changes
/// This helps invalidate other providers when user logs in/out
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier();
});

/// Authentication state
class AuthState {
  final bool isAuthenticated;
  final String? userId;
  final DateTime lastChanged;

  const AuthState({
    required this.isAuthenticated,
    this.userId,
    required this.lastChanged,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    DateTime? lastChanged,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      lastChanged: lastChanged ?? this.lastChanged,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          runtimeType == other.runtimeType &&
          isAuthenticated == other.isAuthenticated &&
          userId == other.userId;

  @override
  int get hashCode => isAuthenticated.hashCode ^ userId.hashCode;
}

/// Global instance for direct access
late AuthStateNotifier globalAuthStateNotifier;

/// Notifier to manage authentication state
class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier()
      : super(AuthState(
          isAuthenticated: false,
          lastChanged: DateTime.now(),
        )) {
    _checkInitialState();
    globalAuthStateNotifier = this; // Set global reference
  }

  /// Check initial authentication state
  void _checkInitialState() async {
    final authService = AuthService();
    final isAuth = await authService.isAuthenticated();
    final userId = await authService.getCurrentUserId();

    if (isAuth != state.isAuthenticated || userId != state.userId) {
      state = state.copyWith(
        isAuthenticated: isAuth,
        userId: userId,
        lastChanged: DateTime.now(),
      );
    }
  }

  /// Called when user logs in
  void onLogin(String userId) {
    state = state.copyWith(
      isAuthenticated: true,
      userId: userId,
      lastChanged: DateTime.now(),
    );
  }

  /// Called when user logs out
  void onLogout() {
    state = state.copyWith(
      isAuthenticated: false,
      userId: null,
      lastChanged: DateTime.now(),
    );
  }

  /// Force refresh authentication state
  void refresh() async {
    final authService = AuthService();
    final isAuth = await authService.isAuthenticated();
    final userId = await authService.getCurrentUserId();

    state = state.copyWith(
      isAuthenticated: isAuth,
      userId: userId,
      lastChanged: DateTime.now(),
    );
  }
}
