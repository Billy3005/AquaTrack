import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Shared building blocks for the auth screens (Login / Register / Reset).
///
/// One responsive shell, one field style, one button language — so the three
/// screens cannot drift apart, and the wide-screen layout bug (constrained
/// hero over a full-bleed form) cannot come back.

/// Max content width on tablets/desktop; phones are unaffected.
const double _kAuthMaxWidth = 460;

// ─────────────────────────────────────────────────────────────────────────────
// Scaffold
// ─────────────────────────────────────────────────────────────────────────────

class AuthScaffold extends StatelessWidget {
  final Widget hero;
  final List<Widget> children;

  const AuthScaffold({super.key, required this.hero, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.nightBase,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kAuthMaxWidth),
          child: Column(
            children: [
              hero,
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                  child: Column(children: children),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero: gradient + glow + bubbles + breathing drop
// ─────────────────────────────────────────────────────────────────────────────

class AuthHero extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool showBack;

  const AuthHero({
    super.key,
    required this.title,
    required this.subtitle,
    this.showBack = false,
  });

  @override
  State<AuthHero> createState() => _AuthHeroState();
}

class _AuthHeroState extends State<AuthHero> with TickerProviderStateMixin {
  late final AnimationController _bubbles;
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _bubbles = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    _breath = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bubbles.dispose();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.cyanDeeper, AppColors.nightBase],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
        alignment: Alignment.topCenter,
        children: [
          // Glow halo behind the drop
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.4),
                    radius: 0.9,
                    colors: [
                      AppColors.glow.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          ..._buildBubbles(constraints.maxWidth),
          Column(
            children: [
              AnimatedBuilder(
                animation: _breath,
                builder: (context, child) {
                  final t = Curves.easeInOut.transform(_breath.value);
                  return Transform.scale(
                    scale: 1.0 + 0.04 * t,
                    child: SizedBox(
                      width: 110,
                      height: 110 * 1.13,
                      child: CustomPaint(
                        painter: LivingDropPainter(percent: 66 + 8 * t),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              Text(
                'AQUATRACK',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.cyanLight,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.title,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textBright,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          if (widget.showBack)
            Positioned(
              left: 0,
              top: 0,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.textBright,
                  size: 20,
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }

  List<Widget> _buildBubbles(double width) {
    const positions = [
      (left: 0.12, bottom: 10.0, size: 4.0, delay: 0.0),
      (left: 0.28, bottom: 27.0, size: 6.0, delay: 0.4),
      (left: 0.55, bottom: 44.0, size: 8.0, delay: 0.8),
      (left: 0.78, bottom: 61.0, size: 6.0, delay: 1.2),
      (left: 0.92, bottom: 20.0, size: 4.0, delay: 1.6),
    ];

    return positions.map((b) {
      return AnimatedBuilder(
        animation: _bubbles,
        builder: (context, child) {
          final t = (_bubbles.value + b.delay) % 1.0;
          final opacity = t < 0.3
              ? t / 0.3 * 0.8
              : t > 0.7
                  ? (1.0 - t) / 0.3 * 0.8
                  : 0.8;
          return Positioned(
            left: width * b.left,
            bottom: b.bottom + t * -120.0,
            child: Container(
              width: b.size,
              height: b.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyanLight.withValues(alpha: 0.4 * opacity),
              ),
            ),
          );
        },
      );
    }).toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Text field
// ─────────────────────────────────────────────────────────────────────────────

class AuthTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String placeholder;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final void Function(String)? onFieldSubmitted;

  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.placeholder,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.cyanLight,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            validator: validator,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            onFieldSubmitted: onFieldSubmitted,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
              prefixIcon: Icon(icon, color: AppColors.textMuted, size: 18),
              suffixIcon: suffix,
              filled: true,
              fillColor: AppColors.nightSurface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.glow.withValues(alpha: 0.15),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderActive),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.error),
              ),
              errorStyle: AppTextStyles.labelSmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Buttons
// ─────────────────────────────────────────────────────────────────────────────

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: enabled
              ? const LinearGradient(
                  colors: [AppColors.glow, AppColors.primary],
                )
              : null,
          color: enabled ? null : AppColors.nightCardSoft,
        ),
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: enabled ? Colors.white : AppColors.textDisabled,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (enabled) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward,
                          color: Colors.white, size: 18),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

/// Full-width "Tiếp tục với Google" button (ADR 0006: the one social door).
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.nightSurface,
          side: BorderSide(color: AppColors.glow.withValues(alpha: 0.15)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(AppColors.cyanLight),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CustomPaint(painter: _GoogleLogoPainter()),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Tiếp tục với Google',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Hand-drawn Google "G". Replace with the official brand asset
/// (developers.google.com/identity/branding-guidelines) before a store release.
class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = size.width * 0.22;
    final arcRect = rect.deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    // Four brand-colored arcs approximating the G ring
    paint.color = const Color(0xFF4285F4); // blue: right side
    canvas.drawArc(arcRect, -math.pi / 4, math.pi / 4, false, paint);
    paint.color = const Color(0xFFEA4335); // red: top-left
    canvas.drawArc(arcRect, math.pi, 3 * math.pi / 4, false, paint);
    paint.color = const Color(0xFFFBBC05); // yellow: bottom-left
    canvas.drawArc(arcRect, 3 * math.pi / 4, math.pi / 4, false, paint);
    paint.color = const Color(0xFF34A853); // green: bottom
    canvas.drawArc(arcRect, math.pi / 4, math.pi / 2, false, paint);

    // The G's horizontal bar
    final bar = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    canvas.drawLine(
      Offset(size.width / 2, size.height / 2),
      Offset(size.width - stroke / 4, size.height / 2),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleLogoPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Misc
// ─────────────────────────────────────────────────────────────────────────────

class AuthErrorBanner extends StatelessWidget {
  final String? message;

  const AuthErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          const Expanded(
            child: Divider(height: 1, color: AppColors.dividerColor),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'HOẶC',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const Expanded(
            child: Divider(height: 1, color: AppColors.dividerColor),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Living Drop painter (shared by all auth heroes)
// ─────────────────────────────────────────────────────────────────────────────

class LivingDropPainter extends CustomPainter {
  final double percent;

  LivingDropPainter({this.percent = 50});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final dropPath = Path();
    final w = size.width;
    final h = size.height;

    dropPath.moveTo(w * 0.5, h * 0.05);
    dropPath.cubicTo(
        w * 0.12, h * 0.55, w * 0.12, h * 0.76, w * 0.12, h * 0.76);
    dropPath.cubicTo(w * 0.12, h * 0.96, w * 0.3, h * 1.08, w * 0.5, h * 1.08);
    dropPath.cubicTo(w * 0.7, h * 1.08, w * 0.88, h * 0.96, w * 0.88, h * 0.76);
    dropPath.cubicTo(w * 0.88, h * 0.55, w * 0.5, h * 0.05, w * 0.5, h * 0.05);
    dropPath.close();

    // Vessel (empty drop)
    paint.color = AppColors.cyanDeeper.withValues(alpha: 0.5);
    canvas.drawPath(dropPath, paint);

    // Fill
    if (percent > 0) {
      final fillHeight = (percent / 100) * h * 0.8;
      final fillY = h - fillHeight;

      canvas.save();
      canvas.clipPath(dropPath);
      paint.shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.glow, AppColors.primary],
      ).createShader(Rect.fromLTWH(0, fillY, w, fillHeight));
      canvas.drawRect(Rect.fromLTWH(0, fillY, w, fillHeight), paint);
      canvas.restore();
    }

    // Outline
    paint
      ..shader = null
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.4);
    canvas.drawPath(dropPath, paint);

    // Highlight
    paint
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.35);
    final highlightPath = Path();
    highlightPath.moveTo(w * 0.3, h * 0.3);
    highlightPath.quadraticBezierTo(w * 0.26, h * 0.55, w * 0.38, h * 0.72);
    canvas.drawPath(highlightPath, paint);
  }

  @override
  bool shouldRepaint(covariant LivingDropPainter oldDelegate) =>
      oldDelegate.percent != percent;
}
