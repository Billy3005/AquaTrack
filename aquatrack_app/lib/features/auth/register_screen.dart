import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/session.dart';
import '../../core/utils/logger.dart';
import 'auth.dart';

/// Register screen with email/password/name registration
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  // Auth repository now injected via Riverpod - removed singleton

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _agreed = false;
  late AnimationController _bubbleController;

  @override
  void initState() {
    super.initState();
    _bubbleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  /// Handle registration using new auth architecture
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final fullName = _nameController.text.trim();

    setState(() {
      _isLoading = true;
    });

    print('🔄 Starting registration for: $email');

    try {
      // Generate username from email (user@domain.com -> user)
      final username = email.split('@').first;

      // Use new auth state notifier
      print('📡 Calling register API...');
      final authNotifier = ref.read(authStateProvider.notifier);
      await authNotifier.register(
        email: email,
        password: password,
        username: username,
        fullName: fullName.isEmpty ? null : fullName,
      );

      // Check if registration was successful
      final authState = ref.read(authStateProvider);
      if (authState.isAuthenticated && authState.currentUser != null) {
        print('✅ Registration API success: ${authState.currentUser!.email}');

        AppLogger.info(
          'Register',
          'Registration successful: ${authState.currentUser!.email}',
        );

        // Clear any cached data from previous sessions
        resetUserSession(ref);

        // Navigate to onboarding for new users
        print('🚀 Attempting navigation to /onboarding');
        if (mounted) {
          context.go('/onboarding');
          print('✅ Navigation called successfully');
        }
      } else {
        // Registration failed - auth state will have error
        print('❌ Registration failed: ${authState.error}');
        AppLogger.error(
            'Register', 'Registration failed: ${authState.error}', null);
      }
    } catch (e) {
      print('❌ Registration failed: $e');
      AppLogger.error('Register', 'Registration failed', e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF0B1120), // nightBase
        child: Column(
          children: [
            // Hero section
            _buildHeroSection(),
            // Form section
            Expanded(child: _buildFormSection()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A3460), Color(0xFF0B1933)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 58, 24, 22),
      child: Stack(
        children: [
          // Back button
          Positioned(
            top: 50,
            left: 0,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0x0FFFFFFF),
                border: Border.all(color: const Color(0x14FFFFFF)),
                borderRadius: BorderRadius.circular(999),
              ),
              child: IconButton(
                onPressed: _goToLogin,
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
          // Glow effect
          Positioned(
            top: -60,
            left: 0,
            right: 0,
            child: Container(
              height: 320,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x4038BDF8), // rgba(56,189,248,0.25)
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.6],
                ),
              ),
            ),
          ),
          // Animated bubbles
          ..._buildBubbles(),
          // Main content
          Column(
            children: [
              const SizedBox(height: 60), // Space for back button
              // Living Drop
              _buildLivingDrop(),
              const SizedBox(height: 14),
              // Brand and title
              _buildHeroText(),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBubbles() {
    final bubblePositions = [
      {'left': 12.0, 'bottom': 10.0, 'size': 4.0, 'delay': 0.0},
      {'left': 28.0, 'bottom': 27.0, 'size': 6.0, 'delay': 0.4},
      {'left': 55.0, 'bottom': 44.0, 'size': 8.0, 'delay': 0.8},
      {'left': 78.0, 'bottom': 61.0, 'size': 6.0, 'delay': 1.2},
      {'left': 92.0, 'bottom': 20.0, 'size': 4.0, 'delay': 1.6},
    ];

    return bubblePositions.map((bubble) {
      return AnimatedBuilder(
        animation: _bubbleController,
        builder: (context, child) {
          final animValue = (_bubbleController.value + bubble['delay']!) % 1.0;
          final opacity = animValue < 0.3
              ? animValue / 0.3 * 0.8
              : animValue > 0.7
                  ? (1.0 - animValue) / 0.3 * 0.8
                  : 0.8;
          final yOffset = animValue * -120.0;

          return Positioned(
            left: MediaQuery.of(context).size.width * bubble['left']! / 100,
            bottom: bubble['bottom']! + yOffset,
            child: Container(
              width: bubble['size']!,
              height: bubble['size']!,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x667DD3FC).withValues(alpha: opacity),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildLivingDrop() {
    return Container(
      width: 92,
      height: 92 * 1.13,
      child: CustomPaint(painter: LivingDropPainter(percent: 50)),
    );
  }

  Widget _buildHeroText() {
    return Column(
      children: [
        const Text(
          'AQUATRACK',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF7DD3FC),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.98, // 0.18 * 11
            fontFamily: 'SF Pro Text',
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tạo một cuộc đời nhiều nước',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.48, // -0.02 * 24
            fontFamily: 'SF Pro Rounded',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text(
          'Vài giây thôi — đồng hành cùng bạn mỗi ngụm',
          style: TextStyle(
            fontSize: 12.5,
            color: Color(0xFFBAE6FD),
            fontFamily: 'SF Pro Text',
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Name field
              _buildField(
                label: 'Tên hiển thị',
                controller: _nameController,
                placeholder: 'Minh Nguyễn',
                keyboardType: TextInputType.name,
                icon: Icons.person_outlined,
              ),
              // Email field
              _buildField(
                label: 'Email',
                controller: _emailController,
                placeholder: 'ban@vidu.com',
                keyboardType: TextInputType.emailAddress,
                icon: Icons.email_outlined,
              ),
              // Password field
              _buildField(
                label: 'Mật khẩu',
                controller: _passwordController,
                placeholder: 'Ít nhất 8 ký tự',
                obscureText: _obscurePassword,
                icon: Icons.lock_outlined,
                trailing: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: const Color(0xFF64748B),
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              // Confirm Password field
              _buildField(
                label: 'Nhập lại mật khẩu',
                controller: _confirmPasswordController,
                placeholder: 'Lặp lại để chắc chắn',
                obscureText: _obscurePassword,
                icon: Icons.lock_outlined,
              ),
              // Password strength indicator
              if (_passwordController.text.isNotEmpty) _buildPasswordStrength(),
              // Agreement checkbox
              _buildAgreementRow(),
              // Submit button
              _buildSubmitButton(),
              // Divider
              _buildOrDivider(),
              // Social buttons
              _buildSocialButtons(),
              // Login link
              _buildLoginLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    TextInputType? keyboardType,
    bool obscureText = false,
    required IconData icon,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFF7DD3FC),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.84, // 0.08 * 10.5
              fontFamily: 'SF Pro Text',
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F1A2E), // nightSurface
              border: Border.all(
                color: const Color(0x2638BDF8), // rgba(56,189,248,0.15)
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF64748B), size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    keyboardType: keyboardType,
                    obscureText: obscureText,
                    onChanged: (value) {
                      // Trigger rebuild for password strength indicator
                      if (label == 'Mật khẩu') {
                        setState(() {});
                      }
                    },
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'SF Pro Text',
                    ),
                    decoration: InputDecoration(
                      hintText: placeholder,
                      hintStyle: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    validator: (value) {
                      if (label == 'Email') {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập email';
                        }
                        if (!RegExp(
                          r'^[^@]+@[^@]+\.[^@]+',
                        ).hasMatch(value.trim())) {
                          return 'Email không hợp lệ';
                        }
                      } else if (label == 'Mật khẩu') {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mật khẩu';
                        }
                        if (value.length < 8) {
                          return 'Mật khẩu phải có ít nhất 8 ký tự';
                        }
                      } else if (label == 'Nhập lại mật khẩu') {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng xác nhận mật khẩu';
                        }
                        if (value != _passwordController.text) {
                          return 'Mật khẩu không khớp';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStrength() {
    final password = _passwordController.text;
    final score = _calculatePasswordScore(password);
    final labels = ['Quá yếu', 'Yếu', 'Trung bình', 'Khá', 'Mạnh'];
    final colors = [
      const Color(0xFFEF4444),
      const Color(0xFFF97316),
      const Color(0xFFFBBF24),
      const Color(0xFFA3E635),
      const Color(0xFF10B981),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(4, (index) {
              return Expanded(
                child: Container(
                  height: 3,
                  margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                  decoration: BoxDecoration(
                    color:
                        index < score ? colors[score] : const Color(0x0FFFFFFF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Text(
            '${labels[score]} · gợi ý: dùng chữ hoa, số, ký tự đặc biệt',
            style: TextStyle(
              fontSize: 10.5,
              color: colors[score],
              fontWeight: FontWeight.w600,
              fontFamily: 'SF Pro Text',
            ),
          ),
        ],
      ),
    );
  }

  int _calculatePasswordScore(String password) {
    return (password.length >= 8 ? 1 : 0) +
        (RegExp(r'[A-Z]').hasMatch(password) ? 1 : 0) +
        (RegExp(r'[0-9]').hasMatch(password) ? 1 : 0) +
        (RegExp(r'[^A-Za-z0-9]').hasMatch(password) ? 1 : 0);
  }

  Widget _buildAgreementRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 6, 0, 16),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _agreed = !_agreed;
          });
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: _agreed
                    ? const LinearGradient(
                        colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: _agreed ? null : const Color(0x0AFFFFFF),
                border: Border.all(
                  color: _agreed
                      ? const Color(0xFF38BDF8)
                      : const Color(0x26FFFFFF),
                ),
              ),
              child: _agreed
                  ? const Icon(Icons.check, color: Colors.white, size: 10)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF94A3B8),
                    fontFamily: 'SF Pro Text',
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(text: 'Tôi đồng ý với '),
                    TextSpan(
                      text: 'Điều khoản dịch vụ',
                      style: TextStyle(
                        color: Color(0xFF7DD3FC),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(text: ' và '),
                    TextSpan(
                      text: 'Chính sách riêng tư',
                      style: TextStyle(
                        color: Color(0xFF7DD3FC),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(text: ' của AquaTrack.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _nameController.text.isNotEmpty &&
        _agreed &&
        _passwordController.text == _confirmPasswordController.text;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      child: ElevatedButton(
        onPressed: canSubmit && !_isLoading ? _register : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              canSubmit ? Colors.transparent : const Color(0x0DFFFFFF),
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Container(
          decoration: canSubmit
              ? const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x590EA5E9),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                )
              : null,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(right: 8),
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              Text(
                _isLoading ? 'Đang xử lý…' : 'Tạo tài khoản',
                style: TextStyle(
                  color: canSubmit ? Colors.white : const Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'SF Pro Rounded',
                  letterSpacing: 0.28, // 0.02 * 14
                ),
              ),
              if (!_isLoading) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward,
                  color: canSubmit ? Colors.white : const Color(0xFF64748B),
                  size: 14,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 14),
      child: const Row(
        children: [
          Expanded(child: Divider(height: 1, color: Color(0x14FFFFFF))),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'HOẶC',
              style: TextStyle(
                fontSize: 10.5,
                color: Color(0xFF64748B),
                fontFamily: 'SF Pro Text',
                letterSpacing: 1.05, // 0.1 * 10.5
              ),
            ),
          ),
          Expanded(child: Divider(height: 1, color: Color(0x14FFFFFF))),
        ],
      ),
    );
  }

  Widget _buildSocialButtons() {
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      child: Row(
        children: [
          // Apple
          Expanded(
            child: _buildSocialButton(
              label: 'Apple',
              backgroundColor: const Color(0xFF0F172A),
              icon: Icons.apple,
            ),
          ),
          const SizedBox(width: 8),
          // Google
          Expanded(
            child: _buildSocialButton(
              label: 'Google',
              backgroundColor: const Color(0x0FFFFFFF),
              icon: Icons.search, // Using search as placeholder for G
            ),
          ),
          const SizedBox(width: 8),
          // Facebook
          Expanded(
            child: _buildSocialButton(
              label: 'Facebook',
              backgroundColor: const Color(0x2D1877F2),
              icon: Icons.facebook,
              iconColor: const Color(0xFF60A5FA),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required Color backgroundColor,
    required IconData icon,
    Color? iconColor,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: const Color(0x14FFFFFF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor ?? Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'SF Pro Text',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(
          fontSize: 12.5,
          color: Color(0xFF94A3B8),
          fontFamily: 'SF Pro Text',
        ),
        children: [
          const TextSpan(text: 'Đã có tài khoản? '),
          WidgetSpan(
            child: GestureDetector(
              onTap: _goToLogin,
              child: const Text(
                'Đăng nhập ngay',
                style: TextStyle(
                  color: Color(0xFF7DD3FC),
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  fontFamily: 'SF Pro Text',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the Living Drop (shared with login screen)
class LivingDropPainter extends CustomPainter {
  final double percent;

  LivingDropPainter({this.percent = 50});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Drop path
    final dropPath = Path();
    final w = size.width;
    final h = size.height;

    dropPath.moveTo(w * 0.5, h * 0.05);
    dropPath.cubicTo(
      w * 0.12,
      h * 0.55,
      w * 0.12,
      h * 0.76,
      w * 0.12,
      h * 0.76,
    );
    dropPath.cubicTo(w * 0.12, h * 0.96, w * 0.3, h * 1.08, w * 0.5, h * 1.08);
    dropPath.cubicTo(w * 0.7, h * 1.08, w * 0.88, h * 0.96, w * 0.88, h * 0.76);
    dropPath.cubicTo(w * 0.88, h * 0.55, w * 0.5, h * 0.05, w * 0.5, h * 0.05);
    dropPath.close();

    // Draw vessel (empty drop)
    paint.color = const Color(0x80081E38);
    canvas.drawPath(dropPath, paint);

    // Draw fill
    if (percent > 0) {
      final fillHeight = (percent / 100) * h * 0.8;
      final fillY = h - fillHeight;

      canvas.save();
      canvas.clipPath(dropPath);

      // Gradient fill
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF38BDF8), const Color(0xFF0EA5E9)],
      );

      paint.shader = gradient.createShader(
        Rect.fromLTWH(0, fillY, w, fillHeight),
      );
      canvas.drawRect(Rect.fromLTWH(0, fillY, w, fillHeight), paint);

      canvas.restore();
    }

    // Drop outline
    paint
      ..shader = null
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0x66FFFFFF);
    canvas.drawPath(dropPath, paint);

    // Highlight
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0x59FFFFFF);
    final highlightPath = Path();
    highlightPath.moveTo(w * 0.3, h * 0.3);
    highlightPath.quadraticBezierTo(w * 0.26, h * 0.55, w * 0.38, h * 0.72);
    canvas.drawPath(highlightPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
