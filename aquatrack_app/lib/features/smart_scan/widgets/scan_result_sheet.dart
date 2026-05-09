import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/vision_service.dart';

/// Bottom sheet showing scan results with confirmation
class ScanResultSheet extends ConsumerStatefulWidget {
  final VisionResult result;

  const ScanResultSheet({super.key, required this.result});

  @override
  ConsumerState<ScanResultSheet> createState() => _ScanResultSheetState();
}

class _ScanResultSheetState extends ConsumerState<ScanResultSheet> {
  late double _adjustedVolume;
  late int _finalVolume;

  @override
  void initState() {
    super.initState();
    _adjustedVolume = widget.result.estimatedVolumeMl.toDouble();
    _finalVolume = widget.result.effectiveVolumeMl;
  }

  void _updateVolume(double newVolume) {
    setState(() {
      _adjustedVolume = newVolume;
      // Recalculate effective volume with hydration coefficient
      final hydrationCoeff = _getHydrationCoeff(widget.result.liquidType);
      _finalVolume = (newVolume * hydrationCoeff).round();
    });
  }

  double _getHydrationCoeff(String liquidType) {
    const coeffMap = {
      'water': 1.00,
      'tea': 0.90,
      'coffee': 0.80,
      'juice': 0.85,
      'smoothie': 0.90,
    };
    return coeffMap[liquidType] ?? 1.0;
  }

  String _getContainerDisplayName(String containerClass) {
    const nameMap = {
      'glass_small': 'Cốc thủy tinh nhỏ',
      'glass_large': 'Cốc thủy tinh lớn',
      'cup_plastic': 'Ly nhựa',
      'bottle_500': 'Chai 500ml',
      'bottle_750': 'Chai 750ml',
      'bottle_1000': 'Chai 1L',
      'bottle_1500': 'Chai 1.5L',
      'mug': 'Cốc/Ca',
      'can_330': 'Lon 330ml',
      'other': 'Khác',
    };
    return nameMap[containerClass] ?? containerClass;
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

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.80) return Colors.green;
    if (confidence >= 0.60) return Colors.orange;
    return Colors.red;
  }

  String _getConfidenceText(double confidence) {
    if (confidence >= 0.80) return 'Độ tin cậy cao';
    if (confidence >= 0.60) return 'Độ tin cậy trung bình';
    return 'Độ tin cậy thấp - Vui lòng điều chỉnh';
  }

  @override
  Widget build(BuildContext context) {
    final confidenceCategory = VisionService().getConfidenceCategory(
      widget.result.confidence,
    );

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
                      color: _getConfidenceColor(
                        widget.result.confidence,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getConfidenceColor(widget.result.confidence),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          confidenceCategory == 'high'
                              ? Icons.check_circle
                              : confidenceCategory == 'medium'
                                  ? Icons.warning
                                  : Icons.error,
                          color: _getConfidenceColor(widget.result.confidence),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getConfidenceText(widget.result.confidence),
                          style: AppTextStyles.labelMedium.copyWith(
                            color: _getConfidenceColor(
                              widget.result.confidence,
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
                    title: 'Loại thùng chứa',
                    value: _getContainerDisplayName(
                      widget.result.containerClass,
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildResultCard(
                    icon: Icons.opacity,
                    title: 'Mức độ đầy',
                    value:
                        '${(widget.result.fillLevelPercent * 100).toStringAsFixed(1)}%',
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
                    'Điều chỉnh thể tích',
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
                          'Hiệu quả hydration: ${_finalVolume}ml',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Volume slider (show for medium/low confidence)
                  if (confidenceCategory != 'high') ...[
                    Slider(
                      value: _adjustedVolume,
                      min: 50,
                      max: 2000,
                      divisions: 195,
                      activeColor: AppColors.cyanAccent,
                      inactiveColor: AppColors.textSecondary,
                      onChanged: _updateVolume,
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 80), // Space for buttons
                ],
              ),
            ),
          ),

          // Action buttons
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
                      // TODO: Log drink with final volume
                      Navigator.of(context).pop(_finalVolume);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cyanAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Xác nhận ${_finalVolume}ml',
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
