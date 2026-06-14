import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/vision_result.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Bottom sheet showing scan results — mirrors the design mock: a drink header
/// with AI confidence, a two-tile stats grid (estimate + hydration value), an
/// effective-contribution callout, and the edit / log actions.
///
/// Pops the user-approved PHYSICAL volume (ml). The hydration coefficient is
/// applied once at the log step; the values here are display-only. Both bottom
/// actions route through Log Drink (the screen always opens it after a pop),
/// so "Sửa lượng" lands on the editor and "Log" lands on the confirm step.
class ScanResultSheet extends StatelessWidget {
  final VisionResult result;

  const ScanResultSheet({super.key, required this.result});

  int get _estimatedMl => result.estimatedVolumeMl.clamp(50, 2000);

  double get _coeff =>
      AppConstants.hydrationCoeff[result.liquidType]?.toDouble() ?? 1.0;

  int get _hydrationPercent => (_coeff * 100).round();

  int get _effectiveMl => (_estimatedMl * _coeff).round();

  int get _confidencePercent => (result.confidence * 100).round();

  String get _liquidName {
    const nameMap = {
      'water': 'Nước lọc',
      'tea': 'Trà',
      'coffee': 'Cà phê',
      'juice': 'Nước trái cây',
      'smoothie': 'Sinh tố',
    };
    return nameMap[result.liquidType] ?? result.liquidType;
  }

  IconData get _liquidIcon {
    const iconMap = {
      'water': Icons.water_drop,
      'tea': Icons.emoji_food_beverage,
      'coffee': Icons.coffee,
      'juice': Icons.local_bar,
      'smoothie': Icons.blender,
    };
    return iconMap[result.liquidType] ?? Icons.local_drink;
  }

  Color get _hydrationColor {
    if (_hydrationPercent >= 90) return const Color(0xFF86EFAC);
    if (_hydrationPercent >= 70) return const Color(0xFF7DD3FC);
    return const Color(0xFFFCD34D);
  }

  Color get _hydrationBarColor {
    if (_hydrationPercent >= 90) return AppColors.success;
    if (_hydrationPercent >= 70) return AppColors.cyanAccent;
    return const Color(0xFFF59E0B);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0B1120),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Color(0x2E38BDF8)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header: icon + name + AI confidence + rescan
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.cyanAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_liquidIcon,
                        color: AppColors.cyanAccent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _liquidName,
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: Colors.white,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome,
                                color: AppColors.cyanAccent, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'AI · $_confidencePercent% chắc chắn',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.textBright,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Rescan: pop null so the screen keeps the camera open
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      'Quét lại',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stats grid
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'Lượng ước tính',
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$_estimatedMl',
                              style: AppTextStyles.displaySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            TextSpan(
                              text: ' ml',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      label: 'Hydration value',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_hydrationPercent%',
                            style: AppTextStyles.displaySmall.copyWith(
                              color: _hydrationColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: _hydrationPercent / 100,
                              minHeight: 4,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.06),
                              valueColor:
                                  AlwaysStoppedAnimation(_hydrationBarColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Effective contribution callout (only when not pure water)
              if (_hydrationPercent < 90) ...[
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.thermostat,
                          color: Color(0xFFF59E0B), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: const Color(0xFFFED7AA),
                              height: 1.4,
                            ),
                            children: [
                              const TextSpan(text: 'Đóng góp thực tế: '),
                              TextSpan(
                                text: '+$_effectiveMl ml',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const TextSpan(
                                text: ' sau khi áp hệ số hydration',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // Actions
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(_estimatedMl),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                    ),
                    child: Text(
                      'Sửa lượng',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(_estimatedMl),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5E9),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Log thức uống này',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '+20 XP',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small stat card used in the result grid.
class _StatTile extends StatelessWidget {
  final String label;
  final Widget child;

  const _StatTile({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
