import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_colors.dart';

/// LivingDrop — Animated water drop SVG that fills based on hydration %
/// Uses animated wave path for the water surface with breathing animation
class LivingDrop extends StatefulWidget {
  final double percent; // 0-100
  final double size;
  final String? label;
  final String? sublabel;
  final bool showGlow;

  const LivingDrop({
    Key? key,
    required this.percent,
    this.size = 220,
    this.label,
    this.sublabel,
    this.showGlow = true,
  }) : super(key: key);

  @override
  State<LivingDrop> createState() => _LivingDropState();
}

class _LivingDropState extends State<LivingDrop> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _breathingController;
  late Animation<double> _waveAnimation;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();

    // Wave animation for water surface
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Breathing animation for glow effect
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.linear,
    ));

    _breathingAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _waveController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  Color _getFillColor() {
    final pct = math.max(0.0, math.min(100.0, widget.percent));
    if (pct < 31) return AppColors.dropEmpty;
    if (pct >= 70) return AppColors.cyanLight;
    return AppColors.cyanAccent;
  }

  Color _getSecondaryColor() {
    final pct = math.max(0.0, math.min(100.0, widget.percent));
    if (pct < 31) return const Color(0xFF2C4F7A);
    if (pct >= 70) return const Color(0xFF7DD3FC);
    return AppColors.cyanLight;
  }

  @override
  Widget build(BuildContext context) {
    final pct = math.max(0.0, math.min(100.0, widget.percent));
    final isGoal = pct >= 70;

    return SizedBox(
      width: widget.size,
      height: widget.size * 1.13,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow effect for goal state
          if (widget.showGlow && isGoal)
            AnimatedBuilder(
              animation: _breathingAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _breathingAnimation.value,
                  child: Container(
                    width: widget.size + 40,
                    height: widget.size + 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _getSecondaryColor().withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.6],
                      ),
                    ),
                  ),
                );
              },
            ),

          // Main drop container
          SizedBox(
            width: widget.size,
            height: widget.size * 1.13,
            child: AnimatedBuilder(
              animation: _waveAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(widget.size, widget.size * 1.13),
                  painter: LivingDropPainter(
                    percent: pct,
                    waveOffset: _waveAnimation.value,
                    fillColor: _getFillColor(),
                    secondaryColor: _getSecondaryColor(),
                  ),
                );
              },
            ),
          ),

          // Label and sublabel
          if (widget.label != null || widget.sublabel != null)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.label != null)
                  Text(
                    widget.label!,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: widget.size * 0.15,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                if (widget.sublabel != null)
                  Text(
                    widget.sublabel!,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: widget.size * 0.08,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Custom painter for the living drop with animated wave
class LivingDropPainter extends CustomPainter {
  final double percent;
  final double waveOffset;
  final Color fillColor;
  final Color secondaryColor;

  LivingDropPainter({
    required this.percent,
    required this.waveOffset,
    required this.fillColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Drop shape path
    final dropPath = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final dropWidth = size.width * 0.76;
    final dropHeight = size.height * 0.95;

    // Create drop shape (teardrop)
    dropPath.moveTo(center.dx, size.height * 0.05); // Top point

    // Right curve
    dropPath.quadraticBezierTo(
      center.dx + dropWidth * 0.38,
      center.dy - dropHeight * 0.25,
      center.dx + dropWidth * 0.38,
      center.dy + dropHeight * 0.25,
    );

    // Bottom curve
    dropPath.quadraticBezierTo(
      center.dx + dropWidth * 0.38,
      center.dy + dropHeight * 0.45,
      center.dx,
      center.dy + dropHeight * 0.45,
    );

    // Left curve
    dropPath.quadraticBezierTo(
      center.dx - dropWidth * 0.38,
      center.dy + dropHeight * 0.45,
      center.dx - dropWidth * 0.38,
      center.dy + dropHeight * 0.25,
    );

    dropPath.quadraticBezierTo(
      center.dx - dropWidth * 0.38,
      center.dy - dropHeight * 0.25,
      center.dx,
      size.height * 0.05, // Back to top
    );

    // Draw empty drop outline
    paint.color = const Color(0xFF082F5C).withValues(alpha: 0.5);
    canvas.drawPath(dropPath, paint);

    // Draw drop outline
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.4),
          Colors.white.withValues(alpha: 0.1),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(dropPath, strokePaint);

    // Calculate water fill level
    final fillLevel = size.height - (size.height * (percent / 100));

    if (percent > 0) {
      // Clip to drop shape for water content
      canvas.save();
      canvas.clipPath(dropPath);

      // Create wave path
      final wavePath = Path();
      const waveHeight = 8.0;
      final waveWidth = size.width / 4;

      wavePath.moveTo(-waveWidth, fillLevel);

      for (double x = -waveWidth; x <= size.width + waveWidth; x += 1) {
        final y = fillLevel +
            waveHeight * math.sin((x / waveWidth) * 2 * math.pi + waveOffset) +
            waveHeight *
                0.5 *
                math.sin(
                    (x / (waveWidth * 0.7)) * 2 * math.pi + waveOffset * 1.3);
        wavePath.lineTo(x, y);
      }

      wavePath.lineTo(size.width + waveWidth, size.height);
      wavePath.lineTo(-waveWidth, size.height);
      wavePath.close();

      // Draw water with gradient
      final waterPaint = Paint()
        ..shader = LinearGradient(
          colors: [secondaryColor, fillColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(wavePath, waterPaint);

      // Add subtle highlight wave
      final highlightPath = Path();
      highlightPath.moveTo(-waveWidth, fillLevel - 2);

      for (double x = -waveWidth; x <= size.width + waveWidth; x += 1) {
        final y = fillLevel -
            2 +
            (waveHeight * 0.3) *
                math.sin((x / waveWidth) * 2 * math.pi + waveOffset);
        highlightPath.lineTo(x, y);
      }

      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawPath(highlightPath, highlightPaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(LivingDropPainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.waveOffset != waveOffset ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}
