import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Living Drop Widget - Animated water drop with breathing effect
/// Used throughout the app to show hydration progress
class LivingDrop extends StatefulWidget {
  final double fillPercentage;
  final double size;
  final bool enableBreathing;
  final Color? waterColor;
  final bool showGlow;

  const LivingDrop({
    super.key,
    required this.fillPercentage,
    this.size = 100,
    this.enableBreathing = true,
    this.waterColor,
    this.showGlow = true,
  });

  @override
  State<LivingDrop> createState() => _LivingDropState();
}

class _LivingDropState extends State<LivingDrop> with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _waveController;
  late Animation<double> _breathingAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();

    // Breathing animation (scale effect)
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    // Wave animation (water surface)
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_waveController);

    if (widget.enableBreathing) {
      _breathingController.repeat(reverse: true);
    }
    _waveController.repeat();
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_breathingAnimation, _waveAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: widget.enableBreathing ? _breathingAnimation.value : 1.0,
          child: Container(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _LivingDropPainter(
                fillPercentage: widget.fillPercentage,
                wavePhase: _waveAnimation.value,
                waterColor: widget.waterColor ?? const Color(0xFF38BDF8),
                showGlow: widget.showGlow,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LivingDropPainter extends CustomPainter {
  final double fillPercentage;
  final double wavePhase;
  final Color waterColor;
  final bool showGlow;

  _LivingDropPainter({
    required this.fillPercentage,
    required this.wavePhase,
    required this.waterColor,
    required this.showGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Create drop shape path
    final dropPath = _createDropPath(size);

    // Clip to drop shape
    canvas.clipPath(dropPath);

    // Draw background gradient
    _drawBackground(canvas, size);

    // Draw water fill with waves
    _drawWaterFill(canvas, size);

    // Draw highlight
    _drawHighlight(canvas, size);

    // Remove clipping for glow
    canvas.restore();
    canvas.save();

    if (showGlow) {
      _drawGlow(canvas, size);
    }

    // Draw drop outline
    _drawDropOutline(canvas, size);
  }

  Path _createDropPath(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;
    final centerX = width / 2;

    // Create water drop shape using bezier curves
    path.moveTo(centerX, height * 0.1); // Top point

    // Right curve
    path.cubicTo(
      width * 0.85,
      height * 0.25, // Control point 1
      width * 0.85,
      height * 0.75, // Control point 2
      centerX,
      height * 0.9, // End point (bottom)
    );

    // Left curve
    path.cubicTo(
      width * 0.15,
      height * 0.75, // Control point 1
      width * 0.15,
      height * 0.25, // Control point 2
      centerX,
      height * 0.1, // Back to top
    );

    path.close();
    return path;
  }

  void _drawBackground(Canvas canvas, Size size) {
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF1E3A8A).withValues(alpha: 0.3),
        const Color(0xFF0F172A).withValues(alpha: 0.8),
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawWaterFill(Canvas canvas, Size size) {
    final waterLevel = size.height * (1 - fillPercentage / 100);

    // Water gradient
    final waterGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [waterColor.withValues(alpha: 0.8), waterColor],
    );

    final waterPaint = Paint()
      ..shader = waterGradient.createShader(
        Rect.fromLTWH(0, waterLevel, size.width, size.height - waterLevel),
      );

    // Create wavy water surface
    final wavePath = Path();
    wavePath.moveTo(0, waterLevel);

    // Add wave curves
    for (double x = 0; x <= size.width; x += 2) {
      final waveHeight =
          3 * math.sin((x / size.width * 4 * math.pi) + wavePhase);
      wavePath.lineTo(x, waterLevel + waveHeight);
    }

    wavePath.lineTo(size.width, size.height);
    wavePath.lineTo(0, size.height);
    wavePath.close();

    canvas.drawPath(wavePath, waterPaint);

    // Add wave reflection
    final reflectionPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final reflectionPath = Path();
    for (double x = 0; x <= size.width; x += 2) {
      final waveHeight = 2 *
          math.sin((x / size.width * 4 * math.pi) + wavePhase + math.pi / 4);
      if (x == 0) {
        reflectionPath.moveTo(x, waterLevel + waveHeight);
      } else {
        reflectionPath.lineTo(x, waterLevel + waveHeight);
      }
    }

    canvas.drawPath(reflectionPath, reflectionPaint);
  }

  void _drawHighlight(Canvas canvas, Size size) {
    final highlightGradient = RadialGradient(
      center: const Alignment(-0.3, -0.4),
      radius: 0.6,
      colors: [
        Colors.white.withValues(alpha: 0.25),
        Colors.white.withValues(alpha: 0.05),
        Colors.transparent,
      ],
      stops: const [0.0, 0.3, 1.0],
    );

    final highlightPaint = Paint()
      ..shader = highlightGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    final highlightPath = Path()
      ..addOval(
        Rect.fromLTWH(
          size.width * 0.2,
          size.height * 0.15,
          size.width * 0.4,
          size.height * 0.3,
        ),
      );

    canvas.drawPath(highlightPath, highlightPaint);
  }

  void _drawGlow(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..color = waterColor.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    final dropPath = _createDropPath(size);
    canvas.drawPath(dropPath, glowPaint);
  }

  void _drawDropOutline(Canvas canvas, Size size) {
    final outlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final dropPath = _createDropPath(size);
    canvas.drawPath(dropPath, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant _LivingDropPainter oldDelegate) {
    return oldDelegate.fillPercentage != fillPercentage ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.waterColor != waterColor ||
        oldDelegate.showGlow != showGlow;
  }
}
