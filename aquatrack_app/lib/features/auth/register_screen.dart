import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/utils/logger.dart';

/// Register screen with email/password/name registration
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _authRepository = AuthRepository();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// Handle registration
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final fullName = _nameController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call register API
      final authResponse = await _authRepository.register(
        email: email,
        password: password,
        fullName: fullName.isEmpty ? null : fullName,
      );

      AppLogger.info(
        'Register',
        'Registration successful: ${authResponse.user.email}',
      );

      // Navigate to home
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      setState(() {
        _errorMessage = _parseErrorMessage(e.toString());
      });
      AppLogger.error('Register', 'Registration failed', e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Parse error message for user-friendly display
  String _parseErrorMessage(String error) {
    if (error.contains('409') || error.contains('already exists')) {
      return 'Email này đã được sử dụng';
    } else if (error.contains('400') || error.contains('validation')) {
      return 'Thông tin đăng ký không hợp lệ';
    } else if (error.contains('Connection failed') ||
        error.contains('SocketException')) {
      return 'Không thể kết nối đến máy chủ';
    } else if (error.contains('timeout')) {
      return 'Kết nối quá thời gian chờ';
    } else {
      return 'Có lỗi xảy ra, vui lòng thử lại';
    }
  }

  /// Navigate back to login screen
  void _goToLogin() {
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Back button
                    _buildBackButton(),
                    const SizedBox(height: 24),

                    // Logo and title
                    _buildHeader(),
                    const SizedBox(height: 40),

                    // Registration form
                    _buildRegistrationForm(),
                    const SizedBox(height: 24),

                    // Error message
                    if (_errorMessage != null) _buildErrorMessage(),

                    // Register button
                    _buildRegisterButton(),
                    const SizedBox(height: 16),

                    // Login link
                    _buildLoginLink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: _isLoading ? null : _goToLogin,
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
          ),
          child: const Icon(
            Icons.water_drop,
            size: 40,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 24),

        // Title
        Text(
          'Tạo tài khoản',
          style: AppTextStyles.displayMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Bắt đầu hành trình hydration với AquaTrack',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRegistrationForm() {
    return Column(
      children: [
        // Name field (optional)
        TextFormField(
          controller: _nameController,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          style: AppTextStyles.inputText,
          decoration: InputDecoration(
            labelText: 'Họ và tên (tùy chọn)',
            hintText: 'Nhập họ và tên của bạn',
            prefixIcon: const Icon(Icons.person_outlined),
            enabled: !_isLoading,
          ),
        ),
        const SizedBox(height: 16),

        // Email field
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          style: AppTextStyles.inputText,
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'Nhập địa chỉ email của bạn',
            prefixIcon: const Icon(Icons.email_outlined),
            enabled: !_isLoading,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập email';
            }
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
              return 'Email không hợp lệ';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Password field
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          style: AppTextStyles.inputText,
          decoration: InputDecoration(
            labelText: 'Mật khẩu',
            hintText: 'Tạo mật khẩu mạnh',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            enabled: !_isLoading,
            helperText: 'Ít nhất 6 ký tự',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập mật khẩu';
            }
            if (value.length < 6) {
              return 'Mật khẩu phải có ít nhất 6 ký tự';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Confirm password field
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          style: AppTextStyles.inputText,
          decoration: InputDecoration(
            labelText: 'Xác nhận mật khẩu',
            hintText: 'Nhập lại mật khẩu',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility
                    : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            enabled: !_isLoading,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng xác nhận mật khẩu';
            }
            if (value != _passwordController.text) {
              return 'Mật khẩu không khớp';
            }
            return null;
          },
          onFieldSubmitted: (_) => _register(),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _register,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: AppColors.textPrimary,
                strokeWidth: 2,
              ),
            )
          : Text('Tạo tài khoản', style: AppTextStyles.buttonTextLarge),
    );
  }

  Widget _buildLoginLink() {
    return TextButton(
      onPressed: _isLoading ? null : _goToLogin,
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.bodyMedium,
          children: [
            TextSpan(
              text: 'Đã có tài khoản? ',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            TextSpan(
              text: 'Đăng nhập',
              style: TextStyle(
                color: AppColors.cyanAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
