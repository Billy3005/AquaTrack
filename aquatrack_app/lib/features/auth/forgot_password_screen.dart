import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import 'auth.dart';
import 'widgets/auth_widgets.dart';

/// Password Reset (ADR 0006): email → 6-digit code → new password.
///
/// Two steps on one screen. The same flow re-arms a password disabled by
/// Account Linking and lets a Google-first account add a password.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _codeSent = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authServiceProvider)
          .forgotPassword(email: _emailController.text.trim());

      if (!mounted) return;
      setState(() => _codeSent = true);
    } catch (e) {
      AppLogger.error('ForgotPassword', 'Request failed', e);
      setState(() {
        _errorMessage = 'Không gửi được yêu cầu. Kiểm tra kết nối và thử lại.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authServiceProvider).resetPassword(
            email: _emailController.text.trim(),
            code: _codeController.text.trim(),
            newPassword: _passwordController.text,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu đã được đặt lại. Hãy đăng nhập.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop(); // back to login
    } catch (e) {
      AppLogger.error('ForgotPassword', 'Reset failed', e);
      setState(() {
        _errorMessage = 'Mã không đúng hoặc đã hết hạn. Hãy yêu cầu mã mới.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      hero: const AuthHero(
        title: 'Quên mật khẩu?',
        subtitle: 'Nhập email — mã đặt lại sẽ được gửi tới hộp thư của bạn',
        showBack: true,
      ),
      children: [
        Form(
          key: _formKey,
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
              if (_codeSent) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.glow.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Nếu email tồn tại, mã 6 số đã được gửi '
                    '(hiệu lực 10 phút). Kiểm tra cả mục Spam nhé.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textBright,
                    ),
                  ),
                ),
                AuthTextField(
                  label: 'Mã xác nhận',
                  controller: _codeController,
                  placeholder: '6 chữ số trong email',
                  icon: Icons.pin_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final code = value?.trim() ?? '';
                    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
                      return 'Mã gồm đúng 6 chữ số';
                    }
                    return null;
                  },
                ),
                AuthTextField(
                  label: 'Mật khẩu mới',
                  controller: _passwordController,
                  placeholder: 'Ít nhất 8 ký tự',
                  icon: Icons.lock_outlined,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _isLoading ? null : _resetPassword(),
                  validator: (value) {
                    if (value == null || value.length < 8) {
                      return 'Mật khẩu mới phải có ít nhất 8 ký tự';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 8),
              AuthPrimaryButton(
                label: _codeSent ? 'Đặt lại mật khẩu' : 'Gửi mã',
                loading: _isLoading,
                onPressed: _isLoading
                    ? null
                    : (_codeSent ? _resetPassword : _requestCode),
              ),
              if (_codeSent)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextButton(
                    onPressed: _isLoading ? null : _requestCode,
                    child: Text(
                      'Gửi lại mã',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.cyanLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
