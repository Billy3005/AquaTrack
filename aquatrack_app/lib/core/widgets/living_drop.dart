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
    ).animate(CurvedAnimation(parent: _waveController, curve: Curves.linear));

    _breathingAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  // Color tiers mirror drop.jsx exactly:
  //   < 31  → dark (low / cracked)   31–69 → default cyan   ≥ 70 → bright
  Color _getFillColor() {
    final pct = math.max(0.0, math.min(100.0, widget.percent));
    if (pct < 31) return AppColors.dropEmpty; // #1E3A5F
    if (pct >= 70) return AppColors.glow; // #38BDF8
    return AppColors.primary; // #0EA5E9
  }

  Color _getSecondaryColor() {
    final pct = math.max(0.0, math.min(100.0, widget.percent));
    if (pct < 31) return AppColors.dropEmptySecondary; // #2C4F7A
    if (pct >= 70) return AppColors.cyanLight; // #7DD3FC
    return AppColors.glow; // #38BDF8
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
    final w = size.width;
    final h = size.height;
    // drop.jsx authors in a 100 × 113 viewBox. The widget sizes the canvas as
    // (size, size * 1.13), so a single uniform factor maps both axes exactly.
    final k = w / 100.0;
    final pct = math.max(0.0, math.min(100.0, percent));

    // Exact teardrop bezier from drop.jsx:
    // M50,5 C50,5 12,55 12,76 C12,96 30,108 50,108
    //       C70,108 88,96 88,76 C88,55 50,5 50,5 Z
    final dropPath = Path()
      ..moveTo(50 * k, 5 * k)
      ..cubicTo(50 * k, 5 * k, 12 * k, 55 * k, 12 * k, 76 * k)
      ..cubicTo(12 * k, 96 * k, 30 * k, 108 * k, 50 * k, 108 * k)
      ..cubicTo(70 * k, 108 * k, 88 * k, 96 * k, 88 * k, 76 * k)
      ..cubicTo(88 * k, 55 * k, 50 * k, 5 * k, 50 * k, 5 * k)
      ..close();

    // Vessel (empty shell) — rgba(8,30,56,0.5)
    canvas.drawPath(
      dropPath,
      Paint()..color = const Color.fromRGBO(8, 30, 56, 0.5),
    );

    // Water surface height: drop.jsx uses waveY = 100 - pct (viewBox units).
    final waveYvb = 100.0 - pct;
    final waveY = waveYvb * k;

    if (pct > 0) {
      canvas.save();
      canvas.clipPath(dropPath);

      // Base gradient fill (secondary at the surface → fill at the bottom).
      final fillRect = Rect.fromLTWH(0, waveY, w, h - waveY);
      canvas.drawRect(
        fillRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [secondaryColor, fillColor],
          ).createShader(fillRect),
      );

      // Two animated wave layers (drop.jsx: opacity 0.55 + 0.35).
      _drawWave(canvas, w, h,
          surfaceY: waveY,
          amplitude: 2.6 * k,
          waveLen: w * 0.5,
          phase: waveOffset,
          color: secondaryColor.withValues(alpha: 0.55));
      _drawWave(canvas, w, h,
          surfaceY: waveY + 2 * k,
          amplitude: 2.0 * k,
          waveLen: w * 0.62,
          phase: waveOffset * 1.3 + 1.0,
          color: secondaryColor.withValues(alpha: 0.35));

      // Highlight bubbles inside the water.
      if (pct > 35) {
        canvas.drawCircle(
          Offset(38 * k, math.max(waveYvb + 12, 30.0) * k),
          2.3 * k,
          Paint()..color = Colors.white.withValues(alpha: 0.5),
        );
      }
      if (pct > 50) {
        canvas.drawCircle(
          Offset(62 * k, math.max(waveYvb + 22, 40.0) * k),
          1.4 * k,
          Paint()..color = Colors.white.withValues(alpha: 0.4),
        );
      }

      canvas.restore();
    }

    // Outline — white gradient stroke (0.4 → 0.1).
    canvas.drawPath(
      dropPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * k
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.4),
            Colors.white.withValues(alpha: 0.1),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Gloss highlight on the shell — M30,30 Q26,55 38,72
    canvas.drawPath(
      Path()
        ..moveTo(30 * k, 30 * k)
        ..quadraticBezierTo(26 * k, 55 * k, 38 * k, 72 * k),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * k
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.35),
    );

    // Crack overlay when the drop is running low.
    if (pct < 31) {
      final crack = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6 * k
        ..color = const Color(0xFF1E293B).withValues(alpha: 0.45);
      canvas
        ..drawPath(
            Path()
              ..moveTo(55 * k, 30 * k)
              ..lineTo(52 * k, 45 * k)
              ..lineTo(58 * k, 55 * k)
              ..lineTo(54 * k, 70 * k),
            crack)
        ..drawPath(
            Path()
              ..moveTo(40 * k, 40 * k)
              ..lineTo(45 * k, 52 * k)
              ..lineTo(41 * k, 62 * k),
            crack)
        ..drawPath(
            Path()
              ..moveTo(65 * k, 55 * k)
              ..lineTo(70 * k, 68 * k),
            crack);
    }
  }

  /// Filled sine wave from [surfaceY] down to the canvas bottom, extended past
  /// both edges so the clipped drop shows no gaps.
  void _drawWave(
    Canvas canvas,
    double w,
    double h, {
    required double surfaceY,
    required double amplitude,
    required double waveLen,
    required double phase,
    required Color color,
  }) {
    final ext = waveLen;
    final path = Path()..moveTo(-ext, surfaceY);
    for (double x = -ext; x <= w + ext; x += 2) {
      final y =
          surfaceY + amplitude * math.sin((x / waveLen) * 2 * math.pi + phase);
      path.lineTo(x, y);
    }
    path
      ..lineTo(w + ext, h)
      ..lineTo(-ext, h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(LivingDropPainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.waveOffset != waveOffset ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}
