import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/organ_model.dart';

/// SVG Human Body Map với interactive organs
class SvgBodyMap extends StatelessWidget {
  final List<OrganHealth> organHealths;
  final Function(OrganInfo)? onOrganTap;
  final double height;

  const SvgBodyMap({
    super.key,
    required this.organHealths,
    this.onOrganTap,
    this.height = 400,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size(double.infinity, height),
        painter: BodyMapPainter(
          organHealths: organHealths,
          onOrganTap: onOrganTap,
        ),
        child: GestureDetector(
          onTapDown: (details) => _handleTap(details.localPosition),
        ),
      ),
    );
  }

  /// Handle tap on body parts
  void _handleTap(Offset position) {
    final organId = _getOrganAtPosition(position);
    if (organId != null && onOrganTap != null) {
      final organ = DefaultOrgans.getById(organId);
      if (organ != null) {
        onOrganTap!(organ);
      }
    }
  }

  /// Detect which organ was tapped based on position
  String? _getOrganAtPosition(Offset position) {
    // Simple hit testing based on body regions
    // In a real implementation, you'd have precise SVG path hit testing

    final relativeX = position.dx / 200; // Assuming body width of 200
    final relativeY = position.dy / height;

    // Head region (brain)
    if (relativeY < 0.15 && relativeX > 0.3 && relativeX < 0.7) {
      return 'brain';
    }

    // Chest region (heart, lungs)
    if (relativeY >= 0.15 && relativeY < 0.45) {
      if (relativeX > 0.2 && relativeX < 0.5) {
        return 'heart';
      }
      if (relativeX > 0.5 && relativeX < 0.8) {
        return 'lungs';
      }
    }

    // Upper abdomen (liver, stomach)
    if (relativeY >= 0.45 && relativeY < 0.65) {
      if (relativeX > 0.5 && relativeX < 0.8) {
        return 'liver';
      }
      if (relativeX > 0.2 && relativeX < 0.5) {
        return 'stomach';
      }
    }

    // Lower abdomen (kidneys)
    if (relativeY >= 0.55 && relativeY < 0.75) {
      if (relativeX > 0.15 && relativeX < 0.35 ||
          relativeX > 0.65 && relativeX < 0.85) {
        return 'kidneys';
      }
    }

    // Arms and legs (muscles)
    if (relativeY >= 0.35 && relativeY < 0.9) {
      if (relativeX < 0.2 || relativeX > 0.8) {
        return 'muscles';
      }
    }

    // Skin (entire body outline)
    return 'skin';
  }
}

/// Custom painter for human body with organs
class BodyMapPainter extends CustomPainter {
  final List<OrganHealth> organHealths;
  final Function(OrganInfo)? onOrganTap;

  BodyMapPainter({
    required this.organHealths,
    this.onOrganTap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0;

    // Draw body outline
    _drawBodyOutline(canvas, size, paint);

    // Draw organs
    _drawOrgans(canvas, size, paint);

    // Draw glow effects
    _drawGlowEffects(canvas, size, paint);
  }

  /// Draw human body silhouette
  void _drawBodyOutline(Canvas canvas, Size size, Paint paint) {
    final bodyPath = Path();
    final centerX = size.width / 2;
    final bodyWidth = size.width * 0.6;
    final bodyHeight = size.height;

    // Head (circle)
    final headRadius = bodyWidth / 8;
    final headCenter = Offset(centerX, headRadius + 20);

    // Body outline path
    bodyPath.addOval(Rect.fromCenter(
      center: headCenter,
      width: headRadius * 2,
      height: headRadius * 2.2,
    ));

    // Neck
    bodyPath.addRect(Rect.fromLTWH(
      centerX - 15,
      headCenter.dy + headRadius,
      30,
      25,
    ));

    // Torso
    final torsoTop = headCenter.dy + headRadius + 25;
    final torsoBottom = bodyHeight * 0.7;
    final torsoPath = Path();

    torsoPath.moveTo(centerX - bodyWidth / 4, torsoTop);
    torsoPath.lineTo(centerX - bodyWidth / 3, torsoTop + 60);
    torsoPath.lineTo(centerX - bodyWidth / 3.5, torsoBottom);
    torsoPath.lineTo(centerX + bodyWidth / 3.5, torsoBottom);
    torsoPath.lineTo(centerX + bodyWidth / 3, torsoTop + 60);
    torsoPath.lineTo(centerX + bodyWidth / 4, torsoTop);
    torsoPath.close();

    // Arms
    const armWidth = 25.0;
    const armLength = 120.0;

    // Left arm
    bodyPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(
        centerX - bodyWidth / 3 - armWidth,
        torsoTop + 20,
        armWidth,
        armLength,
      ),
      const Radius.circular(12),
    ));

    // Right arm
    bodyPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(
        centerX + bodyWidth / 3,
        torsoTop + 20,
        armWidth,
        armLength,
      ),
      const Radius.circular(12),
    ));

    // Legs
    const legWidth = 35.0;
    final legHeight = bodyHeight * 0.3;

    // Left leg
    bodyPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(
        centerX - bodyWidth / 6 - legWidth / 2,
        torsoBottom,
        legWidth,
        legHeight,
      ),
      const Radius.circular(15),
    ));

    // Right leg
    bodyPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(
        centerX + bodyWidth / 6 - legWidth / 2,
        torsoBottom,
        legWidth,
        legHeight,
      ),
      const Radius.circular(15),
    ));

    // Combine all paths
    bodyPath.addPath(torsoPath, Offset.zero);

    // Draw body outline
    paint.color = AppColors.textSecondary.withValues(alpha: 0.3);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    canvas.drawPath(bodyPath, paint);
  }

  /// Draw organ regions
  void _drawOrgans(Canvas canvas, Size size, Paint paint) {
    final centerX = size.width / 2;
    paint.style = PaintingStyle.fill;

    for (final organHealth in organHealths) {
      final organ = organHealth.organ;
      paint.color = organHealth.currentColor.withValues(alpha: 0.7);

      switch (organ.id) {
        case 'brain':
          _drawBrain(canvas, centerX, 50, paint);
          break;
        case 'heart':
          _drawHeart(canvas, centerX - 30, size.height * 0.3, paint);
          break;
        case 'lungs':
          _drawLungs(canvas, centerX, size.height * 0.28, paint);
          break;
        case 'liver':
          _drawLiver(canvas, centerX + 20, size.height * 0.5, paint);
          break;
        case 'kidneys':
          _drawKidneys(canvas, centerX, size.height * 0.55, paint);
          break;
        case 'stomach':
          _drawStomach(canvas, centerX - 20, size.height * 0.52, paint);
          break;
        case 'muscles':
          _drawMuscles(canvas, size, paint);
          break;
        case 'skin':
          // Skin is represented by the body outline glow
          break;
      }
    }
  }

  /// Draw brain organ
  void _drawBrain(Canvas canvas, double x, double y, Paint paint) {
    final brainPath = Path();
    brainPath.addOval(Rect.fromCenter(
      center: Offset(x, y),
      width: 60,
      height: 45,
    ));
    canvas.drawPath(brainPath, paint);
  }

  /// Draw heart organ
  void _drawHeart(Canvas canvas, double x, double y, Paint paint) {
    final heartPath = Path();
    heartPath.moveTo(x, y + 15);
    heartPath.cubicTo(x - 15, y - 5, x - 35, y + 5, x - 20, y + 25);
    heartPath.cubicTo(x - 10, y + 35, x, y + 30, x, y + 15);
    heartPath.cubicTo(x, y + 30, x + 10, y + 35, x + 20, y + 25);
    heartPath.cubicTo(x + 35, y + 5, x + 15, y - 5, x, y + 15);
    canvas.drawPath(heartPath, paint);
  }

  /// Draw lungs organ
  void _drawLungs(Canvas canvas, double x, double y, Paint paint) {
    // Left lung
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - 35, y), width: 25, height: 60),
      paint,
    );
    // Right lung
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x + 35, y), width: 25, height: 60),
      paint,
    );
  }

  /// Draw liver organ
  void _drawLiver(Canvas canvas, double x, double y, Paint paint) {
    final liverPath = Path();
    liverPath.moveTo(x - 25, y);
    liverPath.lineTo(x + 30, y - 5);
    liverPath.lineTo(x + 35, y + 20);
    liverPath.lineTo(x - 20, y + 25);
    liverPath.close();
    canvas.drawPath(liverPath, paint);
  }

  /// Draw kidneys organ
  void _drawKidneys(Canvas canvas, double x, double y, Paint paint) {
    // Left kidney
    final leftKidney = Path();
    leftKidney.addOval(Rect.fromCenter(
      center: Offset(x - 40, y),
      width: 15,
      height: 35,
    ));
    // Right kidney
    final rightKidney = Path();
    rightKidney.addOval(Rect.fromCenter(
      center: Offset(x + 40, y),
      width: 15,
      height: 35,
    ));
    canvas.drawPath(leftKidney, paint);
    canvas.drawPath(rightKidney, paint);
  }

  /// Draw stomach organ
  void _drawStomach(Canvas canvas, double x, double y, Paint paint) {
    final stomachPath = Path();
    stomachPath.addOval(Rect.fromCenter(
      center: Offset(x, y),
      width: 30,
      height: 40,
    ));
    canvas.drawPath(stomachPath, paint);
  }

  /// Draw muscles representation
  void _drawMuscles(Canvas canvas, Size size, Paint paint) {
    final centerX = size.width / 2;

    // Arm muscles
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 90, size.height * 0.35, 15, 60),
        const Radius.circular(8),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 75, size.height * 0.35, 15, 60),
        const Radius.circular(8),
      ),
      paint,
    );

    // Leg muscles
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 35, size.height * 0.72, 20, 80),
        const Radius.circular(10),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 15, size.height * 0.72, 20, 80),
        const Radius.circular(10),
      ),
      paint,
    );
  }

  /// Draw glow effects cho healthy organs
  void _drawGlowEffects(Canvas canvas, Size size, Paint paint) {
    for (final organHealth in organHealths) {
      if (organHealth.state == OrganState.excellent ||
          organHealth.state == OrganState.good) {
        paint.color = organHealth.currentColor.withValues(alpha: 0.2);
        paint.maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);

        // Add glow effect based on organ position
        _drawOrganGlow(canvas, organHealth.organ.id, size, paint);

        paint.maskFilter = null;
      }
    }
  }

  /// Draw glow effect cho specific organ
  void _drawOrganGlow(Canvas canvas, String organId, Size size, Paint paint) {
    final centerX = size.width / 2;

    switch (organId) {
      case 'brain':
        canvas.drawCircle(Offset(centerX, 50), 35, paint);
        break;
      case 'heart':
        canvas.drawCircle(Offset(centerX - 30, size.height * 0.3), 25, paint);
        break;
      case 'lungs':
        canvas.drawCircle(Offset(centerX - 35, size.height * 0.28), 20, paint);
        canvas.drawCircle(Offset(centerX + 35, size.height * 0.28), 20, paint);
        break;
      // Add more glow effects for other organs...
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Always repaint for animations
  }
}
