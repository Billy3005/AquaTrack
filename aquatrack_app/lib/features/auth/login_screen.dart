import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/session.dart';
import '../../core/utils/logger.dart';
import 'auth.dart';

/// Login screen with email/password authentication
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // Auth repository now injected via Riverpod - removed singleton

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _errorMessage;
  late AnimationController _bubbleController;

  @override
  void initState() {
    super.initState();
    // Pre-fill demo credentials
    _emailController.text = '';
    _passwordController.text = '';

    _emailController.addListener(_onFormChanged);
    _passwordController.addListener(_onFormChanged);

    _bubbleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
  }

  void _onFormChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _emailController.removeListener(_onFormChanged);
    _passwordController.removeListener(_onFormChanged);

    _emailController.dispose();
    _passwordController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  /// Handle login using new auth architecture
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use new auth state notifier
      final authNotifier = ref.read(authStateProvider.notifier);
      await authNotifier.login(email: email, password: password);

      // Check if login was successful
      final authState = ref.read(authStateProvider);
      if (authState.isAuthenticated && authState.currentUser != null) {
        AppLogger.info(
            'Login', 'Login successful: ${authState.currentUser!.email}');

        // Clear any cached data from a previous account
        resetUserSession(ref);

        // Navigate based on onboarding status
        if (mounted) {
          if (authState.needsOnboarding) {
            context.go('/onboarding');
          } else {
            context.go('/');
          }
        }
      } else {
        // Login failed - auth state will have error
        setState(() {
          _errorMessage = authState.error ?? 'Đăng nhập thất bại';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = _parseErrorMessage(e.toString());
      });
      AppLogger.error('Login', 'Login failed', e);
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
    if (error.contains('401') || error.contains('Unauthorized')) {
      return 'Email hoặc mật khẩu không đúng';
    } else if (error.contains('Connection failed') ||
        error.contains('SocketException')) {
      return 'Không thể kết nối đến máy chủ';
    } else if (error.contains('timeout')) {
      return 'Kết nối quá thời gian chờ';
    } else {
      return 'Có lỗi xảy ra, vui lòng thử lại';
    }
  }

  /// Navigate to register screen
  void _goToRegister() {
    context.push('/register');
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
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
      child: Stack(
        children: [
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
                color: const Color(0x667DD3FC).withOpacity(opacity),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildLivingDrop() {
    return Container(
      width: 110,
      height: 110 * 1.13,
      child: CustomPaint(painter: LivingDropPainter(percent: 70)),
    );
  }

  Widget _buildHeroText() {
    return Column(
      children: [
        Text(
          'AQUATRACK',
          style: TextStyle(
            fontSize: 11,
            color: const Color(0xFF7DD3FC),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.18 * 11,
            fontFamily: 'SF Pro Text',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Chào mừng trở lại 👋',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.02 * 24,
            fontFamily: 'SF Pro Rounded',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Đăng nhập để tiếp tục hành trình hydrate',
          style: TextStyle(
            fontSize: 12.5,
            color: const Color(0xFFBAE6FD),
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
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
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
              // Remember me row
              _buildRememberMeRow(),
              // Submit button
              _buildSubmitButton(),
              // Divider
              _buildOrDivider(),
              // Social buttons
              _buildSocialButtons(),
              // Register link
              _buildRegisterLink(),
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
              letterSpacing: 0.08 * 10.5,
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
                        if (value.length < 6) {
                          return 'Mật khẩu phải có ít nhất 6 ký tự';
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

  Widget _buildRememberMeRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 4, 0, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _rememberMe = !_rememberMe;
              });
            },
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: _rememberMe
                        ? const LinearGradient(
                            colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: _rememberMe ? null : const Color(0x0AFFFFFF),
                    border: Border.all(
                      color: _rememberMe
                          ? const Color(0xFF38BDF8)
                          : const Color(0x26FFFFFF),
                    ),
                  ),
                  child: _rememberMe
                      ? const Icon(Icons.check, color: Colors.white, size: 10)
                      : null,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Ghi nhớ tôi',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    fontFamily: 'SF Pro Text',
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement forgot password
            },
            child: const Text(
              'Quên mật khẩu?',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF7DD3FC),
                fontWeight: FontWeight.w600,
                fontFamily: 'SF Pro Text',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit =
        _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      child: ElevatedButton(
        onPressed: canSubmit && !_isLoading ? _login : null,
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
                _isLoading ? 'Đang xử lý…' : 'Đăng nhập',
                style: TextStyle(
                  color: canSubmit ? Colors.white : const Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'SF Pro Rounded',
                  letterSpacing: 0.02 * 14,
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
      child: Row(
        children: [
          const Expanded(child: Divider(height: 1, color: Color(0x14FFFFFF))),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            child: const Text(
              'HOẶC',
              style: TextStyle(
                fontSize: 10.5,
                color: Color(0xFF64748B),
                fontFamily: 'SF Pro Text',
                letterSpacing: 0.1 * 10.5,
              ),
            ),
          ),
          const Expanded(child: Divider(height: 1, color: Color(0x14FFFFFF))),
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

  Widget _buildRegisterLink() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(
          fontSize: 12.5,
          color: Color(0xFF94A3B8),
          fontFamily: 'SF Pro Text',
        ),
        children: [
          const TextSpan(text: 'Chưa có tài khoản? '),
          WidgetSpan(
            child: GestureDetector(
              onTap: _goToRegister,
              child: const Text(
                'Đăng ký miễn phí',
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

/// Custom painter for the Living Drop
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

      final fillPath = Path();
      fillPath.addRect(Rect.fromLTWH(0, fillY, w, fillHeight));

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
