import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/vision_result.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Inline result panel anchored at the bottom of the Smart Scan screen
/// (camera + "đã nhận diện" overlay stay visible above it), matching the
/// camera.jsx design: drink header with AI confidence + rescan, a two-tile
/// stats grid (estimate + hydration value), an effective-contribution callout,
/// an inline amount stepper ("Sửa lượng"), and a direct "Log" action.
///
/// The shown ml is the PHYSICAL volume; the hydration coefficient is applied
/// once downstream at the log step. [onLog] receives the (possibly edited) ml.
class ScanResultPanel extends StatefulWidget {
  final VisionResult result;
  final bool isLogging;
  final VoidCallback onRescan;
  final void Function(int volumeMl) onLog;

  const ScanResultPanel({
    super.key,
    required this.result,
    required this.isLogging,
    required this.onRescan,
    required this.onLog,
  });

  @override
  State<ScanResultPanel> createState() => _ScanResultPanelState();
}

class _ScanResultPanelState extends State<ScanResultPanel> {
  static const int _step = 50;
  static const int _minMl = 50;
  static const int _maxMl = 2000;

  late int _ml;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _ml = widget.result.estimatedVolumeMl.clamp(_minMl, _maxMl);
  }

  double get _coeff =>
      AppConstants.hydrationCoeff[widget.result.liquidType]?.toDouble() ?? 1.0;

  int get _hydrationPercent => (_coeff * 100).round();

  int get _effectiveMl => (_ml * _coeff).round();

  int get _confidencePercent => (widget.result.confidence * 100).round();

  void _bump(int delta) {
    setState(() => _ml = (_ml + delta).clamp(_minMl, _maxMl));
  }

  String get _liquidName {
    const nameMap = {
      'water': 'Nước lọc',
      'tea': 'Trà',
      'coffee': 'Cà phê',
      'juice': 'Nước trái cây',
      'smoothie': 'Sinh tố',
    };
    return nameMap[widget.result.liquidType] ?? widget.result.liquidType;
  }

  IconData get _liquidIcon {
    const iconMap = {
      'water': Icons.water_drop,
      'tea': Icons.emoji_food_beverage,
      'coffee': Icons.coffee,
      'juice': Icons.local_bar,
      'smoothie': Icons.blender,
    };
    return iconMap[widget.result.liquidType] ?? Icons.local_drink;
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
        border: Border(top: BorderSide(color: Color(0x2E38BDF8))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  TextButton(
                    onPressed: widget.isLogging ? null : widget.onRescan,
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
                      child: _editing ? _buildStepper() : _buildMlDisplay(),
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
                                style:
                                    const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const TextSpan(
                                  text: ' sau khi áp hệ số hydration'),
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
                    onPressed: widget.isLogging
                        ? null
                        : () => setState(() => _editing = !_editing),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: _editing
                              ? AppColors.cyanAccent
                              : Colors.white.withValues(alpha: 0.12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                    ),
                    child: Text(
                      _editing ? 'Xong' : 'Sửa lượng',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: _editing
                            ? AppColors.cyanAccent
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          widget.isLogging ? null : () => widget.onLog(_ml),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5E9),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: widget.isLogging
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
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

  /// Read-only ml number (default view).
  Widget _buildMlDisplay() {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$_ml',
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
    );
  }

  /// Inline +/- stepper shown after tapping "Sửa lượng".
  Widget _buildStepper() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _stepBtn(Icons.remove, () => _bump(-_step)),
        Flexible(
          child: FittedBox(
            child: Text(
              '$_ml',
              style: AppTextStyles.displaySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
        ),
        _stepBtn(Icons.add, () => _bump(_step)),
      ],
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.cyanAccent.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.cyanAccent, size: 18),
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
