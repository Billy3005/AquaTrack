import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Scanning overlay with detection zone and guidance
class ScanOverlay extends StatelessWidget {
  const ScanOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final overlayWidth = size.width * 0.8;
    final overlayHeight = overlayWidth * 0.6;

    return Stack(
      children: [
        // Dark overlay with cutout
        CustomPaint(
          size: size,
          painter: ScanOverlayPainter(
            overlayWidth: overlayWidth,
            overlayHeight: overlayHeight,
          ),
        ),

        // Top guidance text
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Đặt ly/chai nước vào khung để đo',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Detection zone frame
        Center(
          child: Container(
            width: overlayWidth,
            height: overlayHeight,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.cyanAccent, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                // Corner indicators
                ...List.generate(4, (index) {
                  final isTop = index < 2;
                  final isLeft = index % 2 == 0;

                  return Positioned(
                    top: isTop ? -1 : null,
                    bottom: !isTop ? -1 : null,
                    left: isLeft ? -1 : null,
                    right: !isLeft ? -1 : null,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.cyanAccent,
                        borderRadius: BorderRadius.only(
                          topLeft: isTop && isLeft
                              ? const Radius.circular(16)
                              : Radius.zero,
                          topRight: isTop && !isLeft
                              ? const Radius.circular(16)
                              : Radius.zero,
                          bottomLeft: !isTop && isLeft
                              ? const Radius.circular(16)
                              : Radius.zero,
                          bottomRight: !isTop && !isLeft
                              ? const Radius.circular(16)
                              : Radius.zero,
                        ),
                      ),
                    ),
                  );
                }),

                // Center crosshair
                Center(
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.cyanAccent.withValues(alpha: 0.8),
                        width: 2,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom instructions
        Positioned(
          bottom: 120,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: AppColors.cyanAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đảm bảo ánh sáng tốt và ly/chai rõ nét',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.center_focus_strong,
                        color: AppColors.cyanAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đặt toàn bộ ly/chai trong khung quét',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for scan overlay with cutout
class ScanOverlayPainter extends CustomPainter {
  final double overlayWidth;
  final double overlayHeight;

  ScanOverlayPainter({required this.overlayWidth, required this.overlayHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final cutoutRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: overlayWidth,
      height: overlayHeight,
    );

    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(cutoutRect, const Radius.circular(16)),
      );

    final overlayPath = Path.combine(
      PathOperation.difference,
      path,
      cutoutPath,
    );

    canvas.drawPath(overlayPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
