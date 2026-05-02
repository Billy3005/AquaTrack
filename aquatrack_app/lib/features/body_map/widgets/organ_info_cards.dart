import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/organ_model.dart';

/// Organ information cards với educational content
class OrganInfoCards extends StatelessWidget {
  final OrganHealth? selectedOrgan;
  final VoidCallback? onClose;

  const OrganInfoCards({
    super.key,
    this.selectedOrgan,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedOrgan == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: _buildOrganCard(selectedOrgan!),
    );
  }

  /// Build detailed organ information card
  Widget _buildOrganCard(OrganHealth organHealth) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            organHealth.currentColor.withValues(alpha: 0.15),
            organHealth.currentColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: organHealth.currentColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header với close button
          _buildCardHeader(organHealth),
          const SizedBox(height: 16),

          // Status indicator
          _buildStatusIndicator(organHealth),
          const SizedBox(height: 16),

          // Description và educational content
          _buildEducationalContent(organHealth),
          const SizedBox(height: 16),

          // Action suggestions
          _buildActionSuggestions(organHealth),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.3, end: 0.0, curve: Curves.easeOutQuart);
  }

  /// Build card header với organ name và close button
  Widget _buildCardHeader(OrganHealth organHealth) {
    return Row(
      children: [
        // Organ icon với health color
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: organHealth.currentColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getOrganIcon(organHealth.organ.id),
            color: organHealth.currentColor,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),

        // Organ name và english name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                organHealth.organ.name,
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                ),
              ),
              Text(
                organHealth.organ.nameEn,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),

        // Close button
        if (onClose != null)
          IconButton(
            onPressed: onClose,
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.textSecondary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface.withValues(alpha: 0.8),
            ),
          ),
      ],
    );
  }

  /// Build status indicator với health level
  Widget _buildStatusIndicator(OrganHealth organHealth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: organHealth.currentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Status message
          Row(
            children: [
              Icon(
                _getStatusIcon(organHealth.state),
                color: organHealth.currentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  organHealth.statusMessage,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Health level bar
          _buildHealthLevelBar(organHealth),
        ],
      ),
    );
  }

  /// Build health level progress bar
  Widget _buildHealthLevelBar(OrganHealth organHealth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mức độ hydration',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${(organHealth.hydrationLevel * 100).round()}%',
              style: AppTextStyles.label.copyWith(
                color: organHealth.currentColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Progress bar
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: organHealth.hydrationLevel.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: organHealth.currentColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build educational content về organ
  Widget _buildEducationalContent(OrganHealth organHealth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tại sao quan trọng?',
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),

        // Description
        Text(
          organHealth.organ.description,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),

        // Hydration effect
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: organHealth.currentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: organHealth.currentColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.water_drop,
                color: organHealth.currentColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  organHealth.organ.hydrationEffect,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build action suggestions dựa trên organ state
  Widget _buildActionSuggestions(OrganHealth organHealth) {
    final suggestions = _getActionSuggestions(organHealth);

    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gợi ý cải thiện',
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...suggestions.map((suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: organHealth.currentColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  /// Get icon for organ type
  IconData _getOrganIcon(String organId) {
    switch (organId) {
      case 'brain':
        return Icons.psychology;
      case 'heart':
        return Icons.favorite;
      case 'lungs':
        return Icons.air;
      case 'liver':
        return Icons.biotech;
      case 'kidneys':
        return Icons.filter_alt;
      case 'stomach':
        return Icons.restaurant;
      case 'muscles':
        return Icons.fitness_center;
      case 'skin':
        return Icons.face;
      default:
        return Icons.health_and_safety;
    }
  }

  /// Get status icon based on organ state
  IconData _getStatusIcon(OrganState state) {
    switch (state) {
      case OrganState.excellent:
        return Icons.emoji_events;
      case OrganState.good:
        return Icons.check_circle;
      case OrganState.fair:
        return Icons.warning_amber;
      case OrganState.poor:
        return Icons.priority_high;
      case OrganState.critical:
        return Icons.dangerous;
    }
  }

  /// Get action suggestions based on organ health
  List<String> _getActionSuggestions(OrganHealth organHealth) {
    final organ = organHealth.organ;
    final state = organHealth.state;

    switch (organ.id) {
      case 'brain':
        if (state == OrganState.critical || state == OrganState.poor) {
          return [
            'Uống 2-3 ly nước ngay để cải thiện lưu thông máu lên não',
            'Nghỉ ngơi 10-15 phút trong không gian mát mẻ',
            'Tránh hoạt động đòi hỏi tập trung cao trong 1 giờ',
          ];
        } else if (state == OrganState.fair) {
          return [
            'Uống thêm 1-2 ly nước trong 30 phút tới',
            'Thực hiện bài tập thở sâu 5 phút',
          ];
        }
        return ['Duy trì việc uống nước đều đặn để não hoạt động tối ưu'];

      case 'heart':
        if (state == OrganState.critical || state == OrganState.poor) {
          return [
            'Uống nước từ từ, 1-2 ngụm mỗi 2-3 phút',
            'Ngồi xuống và thở chậm, đều',
            'Tránh vận động mạnh trong 2 giờ tới',
          ];
        }
        return ['Uống nước đều đặn để duy trì huyết áp ổn định'];

      case 'kidneys':
        if (state == OrganState.critical || state == OrganState.poor) {
          return [
            'Uống nhiều nước, mục tiêu 500ml trong 1 giờ tới',
            'Tránh caffeine và đồ uống có cồn',
            'Theo dõi màu nước tiểu - mục tiêu màu vàng nhạt',
          ];
        }
        return ['Uống nước thường xuyên để hỗ trợ chức năng lọc'];

      case 'skin':
        if (state == OrganState.poor || state == OrganState.fair) {
          return [
            'Uống nước nhỏ giọt thường xuyên',
            'Sử dụng kem dưỡng ẩm sau khi rửa mặt',
            'Tránh tiếp xúc trực tiếp với ánh nắng',
          ];
        }
        return ['Duy trì độ ẩm cho da bằng cách uống nước đều đặn'];

      default:
        if (state == OrganState.critical || state == OrganState.poor) {
          return [
            'Uống nước ngay để cải thiện tình trạng cơ quan',
            'Nghỉ ngơi và tránh hoạt động nặng',
          ];
        } else if (state == OrganState.fair) {
          return ['Uống thêm 1-2 ly nước trong giờ tới'];
        }
        return ['Tiếp tục duy trì thói quen uống nước tốt'];
    }
  }
}
