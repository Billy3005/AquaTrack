import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Smart Scan overlay — oval framing zone matching the design mock.
///
/// The "Quét thông minh · AI" pill sits up top, a dim mask cuts an oval window,
/// a cyan sweep line runs continuously inside it, and a status caption sits
/// below. Capture stays manual (the shutter lives in [ScanControls]); this is
/// purely the framing chrome.
class ScanOverlay extends StatefulWidget {
  const ScanOverlay({super.key});

  @override
  State<ScanOverlay> createState() => _ScanOverlayState();
}

class _ScanOverlayState extends State<ScanOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final ovalWidth = math.min(size.width * 0.66, 260.0);
    final ovalHeight = ovalWidth * 1.3;

    return Stack(
      children: [
        // Dim mask with an oval cutout
        Positioned.fill(
          child: CustomPaint(
            painter: _OvalMaskPainter(
              ovalWidth: ovalWidth,
              ovalHeight: ovalHeight,
            ),
          ),
        ),

        // Top "AI" pill
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.cyanAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: AppColors.cyanAccent,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Quét thông minh · AI',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textBright,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Oval frame + sweep
        Center(
          child: SizedBox(
            width: ovalWidth,
            height: ovalHeight,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _OvalFramePainter(sweep: _controller.value),
                );
              },
            ),
          ),
        ),

        // Status caption below the oval
        Center(
          child: Padding(
            padding: EdgeInsets.only(top: ovalHeight + 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.cyanAccent.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.center_focus_strong,
                    color: AppColors.cyanAccent,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Đặt ly/chai vào khung rồi chụp',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textBright,
                    ),
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

/// Dims everything outside the oval framing zone.
class _OvalMaskPainter extends CustomPainter {
  final double ovalWidth;
  final double ovalHeight;

  _OvalMaskPainter({required this.ovalWidth, required this.ovalHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.6);

    final full = Path()..addRect(Offset.zero & size);
    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: ovalWidth,
      height: ovalHeight,
    );
    final cutout = Path()..addOval(ovalRect);
    final masked = Path.combine(PathOperation.difference, full, cutout);
    canvas.drawPath(masked, paint);
  }

  @override
  bool shouldRepaint(covariant _OvalMaskPainter oldDelegate) =>
      oldDelegate.ovalWidth != ovalWidth ||
      oldDelegate.ovalHeight != ovalHeight;
}

/// Draws the cyan oval ring, corner ticks, and the moving sweep line.
class _OvalFramePainter extends CustomPainter {
  /// 0..1 vertical position of the sweep line.
  final double sweep;

  _OvalFramePainter({required this.sweep});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;

    // Dashed-feel oval ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.cyanAccent, Color(0xFF0EA5E9)],
      ).createShader(rect);
    canvas.drawOval(rect.deflate(1), ringPaint);

    // Soft inner glow toward the edge
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          AppColors.cyanAccent.withValues(alpha: 0.12),
        ],
        stops: const [0.6, 1.0],
      ).createShader(rect);
    canvas.drawOval(rect.deflate(1), glowPaint);

    // Corner ticks around the oval's bounding box
    final tickPaint = Paint()
      ..color = AppColors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    const len = 18.0;
    const inset = 6.0;
    final corners = [
      (const Offset(inset, inset), 1.0, 1.0), // top-left
      (Offset(size.width - inset, inset), -1.0, 1.0), // top-right
      (Offset(inset, size.height - inset), 1.0, -1.0), // bottom-left
      (Offset(size.width - inset, size.height - inset), -1.0, -1.0),
    ];
    for (final (corner, dx, dy) in corners) {
      canvas.drawLine(corner, corner.translate(len * dx, 0), tickPaint);
      canvas.drawLine(corner, corner.translate(0, len * dy), tickPaint);
    }

    // Sweep line, clipped to the oval so it never bleeds outside the window
    canvas.save();
    canvas.clipPath(Path()..addOval(rect.deflate(1)));
    final y = rect.top + 12 + sweep * (size.height - 24);
    final sweepPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.cyanAccent.withValues(alpha: 0.0),
          AppColors.cyanAccent,
          AppColors.cyanAccent.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, y - 1, size.width, 2))
      ..strokeWidth = 2;
    canvas.drawLine(Offset(8, y), Offset(size.width - 8, y), sweepPaint);
    canvas.restore();

    // Center focus dot
    final dotPaint = Paint()
      ..color = AppColors.cyanAccent.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 10, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _OvalFramePainter oldDelegate) =>
      oldDelegate.sweep != sweep;
}
