import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/vision_result.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Bottom sheet showing scan results with confirmation.
///
/// Pops the user-approved PHYSICAL volume (ml). The hydration coefficient is
/// applied once at the log step — the preview line here is display-only.
/// Low confidence never blocks: the result stays editable as a suggestion.
class ScanResultSheet extends StatefulWidget {
  final VisionResult result;

  const ScanResultSheet({super.key, required this.result});

  @override
  State<ScanResultSheet> createState() => _ScanResultSheetState();
}

class _ScanResultSheetState extends State<ScanResultSheet> {
  late double _adjustedVolume;

  bool get _isHighConfidence => widget.result.isHighConfidence;

  @override
  void initState() {
    super.initState();
    _adjustedVolume =
        widget.result.estimatedVolumeMl.clamp(50, 2000).toDouble();
  }

  /// Display-only hydration preview (Log Drink owns the real calculation)
  int get _effectivePreviewMl {
    final coeff = AppConstants.hydrationCoeff[widget.result.liquidType] ?? 1.0;
    return (_adjustedVolume * coeff).round();
  }

  String _getLiquidDisplayName(String liquidType) {
    const nameMap = {
      'water': 'Nước lọc',
      'tea': 'Trà',
      'coffee': 'Cà phê',
      'juice': 'Nước trái cây',
      'smoothie': 'Sinh tố',
    };
    return nameMap[liquidType] ?? liquidType;
  }

  Color get _confidenceColor {
    if (_isHighConfidence) return Colors.green;
    if (widget.result.confidence >= 0.60) return Colors.orange;
    return Colors.red;
  }

  String get _confidenceText {
    if (_isHighConfidence) return 'Độ tin cậy cao';
    if (widget.result.confidence >= 0.60) {
      return 'Kiểm tra lại kết quả giúp mình nhé';
    }
    return 'Độ tin cậy thấp — hãy chỉnh lại thể tích';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              color: AppColors.textSecondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const Icon(
                  Icons.camera_alt,
                  color: AppColors.cyanAccent,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Kết quả quét',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Confidence indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _confidenceColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _confidenceColor, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isHighConfidence
                              ? Icons.check_circle
                              : Icons.warning,
                          color: _confidenceColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _confidenceText,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: _confidenceColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Detection results
                  _buildResultCard(
                    icon: Icons.local_drink,
                    title: 'Vật chứa',
                    value: widget.result.containerLabel,
                  ),

                  const SizedBox(height: 16),

                  _buildResultCard(
                    icon: Icons.opacity,
                    title: 'Mức độ đầy',
                    value:
                        '${(widget.result.fillLevelPercent * 100).toStringAsFixed(0)}% '
                        'của ~${widget.result.containerCapacityMl}ml',
                  ),

                  const SizedBox(height: 16),

                  _buildResultCard(
                    icon: Icons.water_drop,
                    title: 'Loại đồ uống',
                    value: _getLiquidDisplayName(widget.result.liquidType),
                  ),

                  const SizedBox(height: 24),

                  // Volume adjustment
                  Text(
                    _isHighConfidence
                        ? 'Thể tích ước lượng'
                        : 'Điều chỉnh thể tích',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Volume display
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cyanAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.cyanAccent.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${_adjustedVolume.round()}ml',
                          style: AppTextStyles.displaySmall.copyWith(
                            color: AppColors.cyanAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '≈ ${_effectivePreviewMl}ml hydration',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Slider is always available; below the auto-fill threshold
                  // it is the focal point of the sheet
                  Slider(
                    value: _adjustedVolume,
                    min: 50,
                    max: 2000,
                    divisions: 195,
                    activeColor: AppColors.cyanAccent,
                    inactiveColor: AppColors.textSecondary,
                    onChanged: (value) {
                      setState(() => _adjustedVolume = value);
                    },
                  ),

                  const SizedBox(height: 80), // Space for buttons
                ],
              ),
            ),
          ),

          // Action buttons — retake is always secondary, never forced
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.surfaceColor,
              border: Border(
                top: BorderSide(color: AppColors.borderColor, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.cyanAccent),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Quét lại',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.cyanAccent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      // Pop the PHYSICAL volume; Log Drink applies the
                      // hydration coefficient exactly once
                      Navigator.of(context).pop(_adjustedVolume.round());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cyanAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Xác nhận ${_adjustedVolume.round()}ml',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.cyanAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.cyanAccent, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
