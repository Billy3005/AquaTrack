import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/home_state.dart';

/// Living Drop — Core widget của AquaTrack
/// Animated water drop với fill level, breathing animation, 5 states
class LivingDrop extends StatefulWidget {
  final double progress; // 0.0 → 1.0
  final HomeState state;
  final int currentMl;
  final int goalMl;
  final VoidCallback? onTap;

  const LivingDrop({
    super.key,
    required this.progress,
    required this.state,
    required this.currentMl,
    required this.goalMl,
    this.onTap,
  });

  @override
  State<LivingDrop> createState() => _LivingDropState();
}

class _LivingDropState extends State<LivingDrop>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _fillController;

  @override
  void initState() {
    super.initState();

    // Breathing animation: 1.0 → 1.02 → 1.0, 2s cycle
    _breathingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Fill animation for progress changes
    _fillController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fillController.animateTo(widget.progress);
  }

  @override
  void didUpdateWidget(LivingDrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _fillController.animateTo(widget.progress);
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _fillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _breathingController,
        builder: (context, child) {
          final breathingScale = 1.0 + (_breathingController.value * 0.02);

          return Transform.scale(
            scale: breathingScale,
            child: SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                children: [
                  // Drop container (outline)
                  CustomPaint(
                    size: const Size(200, 200),
                    painter: _DropOutlinePainter(),
                  ),

                  // Filled water (animated based on progress)
                  AnimatedBuilder(
                    animation: _fillController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(200, 200),
                        painter: _DropFillPainter(
                          fillLevel: _fillController.value,
                          fillColor: HomeStateHelper.dropColor(widget.state),
                        ),
                      );
                    },
                  ),

                  // Progress text overlay
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(widget.progress * 100).round()}%',
                          style: AppTextStyles.displayMedium.copyWith(
                            color: _getTextColor(),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.currentMl}/${widget.goalMl}ml',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: _getTextColor().withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getTextColor() {
    // Text color thay đổi theo fill level để đảm bảo contrast
    return widget.progress > 0.3 ? AppColors.textPrimary : AppColors.textSecondary;
  }
}

/// Drop outline painter (border)
class _DropOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.surfaceLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = _createDropPath(size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Drop fill painter (animated water fill)
class _DropFillPainter extends CustomPainter {
  final double fillLevel;
  final Color fillColor;

  _DropFillPainter({required this.fillLevel, required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (fillLevel <= 0) return;

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          fillColor.withValues(alpha: 0.6),
          fillColor,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = _createDropPath(size);

    // Clip to show only filled portion
    final clipRect = Rect.fromLTRB(
      0,
      size.height * (1 - fillLevel), // Fill from bottom up
      size.width,
      size.height,
    );

    canvas.save();
    canvas.clipPath(path);
    canvas.clipRect(clipRect);
    canvas.drawPath(path, gradientPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DropFillPainter oldDelegate) {
    return oldDelegate.fillLevel != fillLevel || oldDelegate.fillColor != fillColor;
  }
}

/// Create water drop path shape
Path _createDropPath(Size size) {
  final path = Path();
  final width = size.width;
  final height = size.height;

  // Water drop shape: rounded bottom, pointed top
  path.moveTo(width * 0.5, height * 0.1); // Top point

  // Right curve
  path.quadraticBezierTo(
    width * 0.85, height * 0.4, // Control point
    width * 0.85, height * 0.7, // End point
  );

  // Bottom right curve
  path.quadraticBezierTo(
    width * 0.85, height * 0.95, // Control point
    width * 0.5, height * 0.95,  // Bottom center
  );

  // Bottom left curve
  path.quadraticBezierTo(
    width * 0.15, height * 0.95, // Control point
    width * 0.15, height * 0.7,  // End point
  );

  // Left curve back to top
  path.quadraticBezierTo(
    width * 0.15, height * 0.4, // Control point
    width * 0.5, height * 0.1,  // Back to top
  );

  path.close();
  return path;
}