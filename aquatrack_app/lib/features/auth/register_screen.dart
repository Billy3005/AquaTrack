import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import 'auth.dart';
import 'widgets/auth_widgets.dart';

/// Register screen: email/password + Google Sign-In (ADR 0006 — with Google,
/// sign-up and sign-in are the same find-or-create door).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _referralController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  void _handleAuthSuccess() {
    final authState = ref.read(authStateProvider);
    AppLogger.info('Register', 'Signed in: ${authState.currentUser?.email}');

    resetUserSession(ref);

    if (!mounted) return;
    if (authState.needsOnboarding) {
      context.go('/onboarding');
    } else {
      context.go('/');
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final fullName = _nameController.text.trim();

      final referralCode = _referralController.text.trim().toUpperCase();
      final authNotifier = ref.read(authStateProvider.notifier);
      await authNotifier.register(
        email: email,
        password: _passwordController.text,
        // Username from the email prefix; the display name lives in fullName.
        username: email.split('@').first,
        fullName: fullName.isEmpty ? null : fullName,
        referralCode: referralCode.isEmpty ? null : referralCode,
      );

      final authState = ref.read(authStateProvider);
      if (authState.isAuthenticated && authState.currentUser != null) {
        _handleAuthSuccess();
      } else {
        setState(() {
          _errorMessage = authState.error ?? 'Đăng ký thất bại';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Có lỗi xảy ra, vui lòng thử lại';
      });
      AppLogger.error('Register', 'Registration failed', e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
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
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể đăng ký với Google';
      });
      AppLogger.error('Register', 'Google sign-up failed', e);
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isLoading || _isGoogleLoading;

    return AuthScaffold(
      hero: const AuthHero(
        title: 'Tạo một cuộc đời nhiều nước',
        subtitle: 'Vài giây thôi — đồng hành cùng bạn mỗi ngụm',
        showBack: true,
        dropPercent: 50,
        dropSize: 92,
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
                  label: 'Tên hiển thị',
                  controller: _nameController,
                  placeholder: 'Minh Nguyễn',
                  icon: Icons.person_outline,
                  autofillHints: const [AutofillHints.name],
                  validator: (value) {
                    final name = value?.trim() ?? '';
                    if (name.isEmpty) return 'Vui lòng nhập tên hiển thị';
                    if (name.length < 2) return 'Tên phải có ít nhất 2 ký tự';
                    return null;
                  },
                ),
                AuthTextField(
                  label: 'Email',
                  controller: _emailController,
                  placeholder: 'ban@vidu.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                        .hasMatch(value.trim())) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),
                AuthTextField(
                  label: 'Mật khẩu',
                  controller: _passwordController,
                  placeholder: 'Ít nhất 8 ký tự',
                  icon: Icons.lock_outlined,
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    if (value.length < 8) {
                      return 'Mật khẩu phải có ít nhất 8 ký tự';
                    }
                    return null;
                  },
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
                AuthTextField(
                  label: 'Nhập lại mật khẩu',
                  controller: _confirmController,
                  placeholder: 'Lặp lại để chắc chắn',
                  icon: Icons.lock_outlined,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  validator: (value) => value != _passwordController.text
                      ? 'Mật khẩu nhập lại không khớp'
                      : null,
                ),
                AuthTextField(
                  label: 'Mã giới thiệu (tuỳ chọn)',
                  controller: _referralController,
                  placeholder: 'VD: AQUA-X7K2P9',
                  icon: Icons.card_giftcard_outlined,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => busy ? null : _register(),
                ),
                const SizedBox(height: 8),
                AuthPrimaryButton(
                  label: 'Tạo tài khoản',
                  loading: _isLoading,
                  onPressed: busy ? null : _register,
                ),
              ],
            ),
          ),
        ),
        const AuthOrDivider(),
        GoogleSignInButton(
          loading: _isGoogleLoading,
          onPressed: busy ? null : _signUpWithGoogle,
        ),
        const SizedBox(height: 22),
        _buildLoginLink(),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Đã có tài khoản? ',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () => context.pop(),
          child: Text(
            'Đăng nhập',
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
