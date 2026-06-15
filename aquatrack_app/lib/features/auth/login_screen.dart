import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import 'auth.dart';
import 'widgets/auth_widgets.dart';

/// Login screen: email/password + Google Sign-In (ADR 0006).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Shared landing logic: every successful door ends here.
  void _handleAuthSuccess() {
    final authState = ref.read(authStateProvider);
    AppLogger.info('Login', 'Signed in: ${authState.currentUser?.email}');

    // Clear any cached data from a previous account
    resetUserSession(ref);

    if (!mounted) return;
    if (authState.needsOnboarding) {
      context.go('/onboarding');
    } else {
      context.go('/');
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authNotifier = ref.read(authStateProvider.notifier);
      await authNotifier.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final authState = ref.read(authStateProvider);
      if (authState.isAuthenticated && authState.currentUser != null) {
        _handleAuthSuccess();
      } else {
        setState(() {
          _errorMessage = authState.error ?? 'Đăng nhập thất bại';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Có lỗi xảy ra, vui lòng thử lại';
      });
      AppLogger.error('Login', 'Login failed', e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authStateProvider.notifier).loginWithGoogle();

      final authState = ref.read(authStateProvider);
      if (authState.isAuthenticated && authState.currentUser != null) {
        _handleAuthSuccess();
      } else if (authState.hasError) {
        setState(() => _errorMessage = authState.error);
      }
      // No error + not authenticated = user closed the picker: stay silent.
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể đăng nhập với Google';
      });
      AppLogger.error('Login', 'Google sign-in failed', e);
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isLoading || _isGoogleLoading;

    return AuthScaffold(
      hero: const AuthHero(
        title: 'Chào mừng trở lại 👋',
        subtitle: 'Đăng nhập để tiếp tục hành trình hydrate',
        dropPercent: 70,
        dropSize: 110,
      ),
      children: [
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthErrorBanner(message: _errorMessage),
                AuthTextField(
                  label: 'Email',
                  controller: _emailController,
                  placeholder: 'ban@vidu.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: _validateEmail,
                ),
                AuthTextField(
                  label: 'Mật khẩu',
                  controller: _passwordController,
                  placeholder: 'Mật khẩu của bạn',
                  icon: Icons.lock_outlined,
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => busy ? null : _login(),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Vui lòng nhập mật khẩu'
                      : null,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: () => setState(() {
                      _obscurePassword = !_obscurePassword;
                    }),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: Text(
                      'Quên mật khẩu?',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.cyanLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                AuthPrimaryButton(
                  label: 'Đăng nhập',
                  loading: _isLoading,
                  onPressed: busy ? null : _login,
                ),
              ],
            ),
          ),
        ),
        const AuthOrDivider(),
        GoogleSignInButton(
          loading: _isGoogleLoading,
          onPressed: busy ? null : _loginWithGoogle,
        ),
        const SizedBox(height: 22),
        _buildRegisterLink(),
      ],
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Chưa có tài khoản? ',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () => context.push('/register'),
          child: Text(
            'Đăng ký miễn phí',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.cyanLight,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
