import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/body_map_provider.dart';
import '../widgets/svg_body_map.dart';
import '../widgets/organ_info_cards.dart';
import '../models/organ_model.dart';

/// Screen 03 — Body Map (Ecosystem)
/// SVG human body với organ glow effects
class BodyMapScreen extends ConsumerWidget {
  const BodyMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bodyMapState = ref.watch(bodyMapNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('CƠ THỂ', style: AppTextStyles.headingMedium),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        actions: [
          // Refresh button
          IconButton(
            onPressed: () {
              ref.read(bodyMapNotifierProvider.notifier).refresh();
            },
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overall health summary
                _buildHealthSummary(ref, bodyMapState),
                const SizedBox(height: 24),

                // Interactive body map
                _buildBodyMapSection(ref, bodyMapState),
                const SizedBox(height: 24),

                // Critical organs alert (if any)
                _buildCriticalOrgansAlert(ref, bodyMapState),

                // Organ grid summary
                _buildOrganGridSummary(bodyMapState),

                // Bottom spacing
                const SizedBox(height: 100),
              ],
            ),
          ),

          // Floating organ info card
          if (bodyMapState.selectedOrgan != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: OrganInfoCards(
                selectedOrgan: bodyMapState.organHealths
                    .where(
                        (oh) => oh.organ.id == bodyMapState.selectedOrgan?.id)
                    .firstOrNull,
                onClose: () {
                  ref.read(bodyMapNotifierProvider.notifier).clearSelection();
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Build overall health summary
  Widget _buildHealthSummary(WidgetRef ref, BodyMapState bodyMapState) {
    final notifier = ref.read(bodyMapNotifierProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cyan.withValues(alpha: 0.1),
            AppColors.xpPurple.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.health_and_safety,
                  color: AppColors.cyan,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tình trạng cơ thể',
                      style: AppTextStyles.headingMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${(notifier.overallHealthScore * 100).round()}% Hydration',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Health message
          Text(
            notifier.overallHealthMessage,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          // Suggested action
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.cyan,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    notifier.suggestedAction,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
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

  /// Build interactive body map section
  Widget _buildBodyMapSection(WidgetRef ref, BodyMapState bodyMapState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bản đồ cơ thể tương tác',
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Chạm vào cơ quan để xem thông tin chi tiết',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        // SVG Body Map
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.cyan.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SvgBodyMap(
              organHealths: bodyMapState.organHealths,
              height: 450,
              onOrganTap: (organ) {
                ref.read(bodyMapNotifierProvider.notifier).selectOrgan(organ);
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Build critical organs alert
  Widget _buildCriticalOrgansAlert(WidgetRef ref, BodyMapState bodyMapState) {
    final criticalOrgans =
        ref.read(bodyMapNotifierProvider.notifier).getCriticalOrgans();

    if (criticalOrgans.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Cơ quan cần chú ý',
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.error,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...criticalOrgans.take(3).map((organHealth) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${organHealth.organ.name}: ${organHealth.statusMessage}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  /// Build organ grid summary
  Widget _buildOrganGridSummary(BodyMapState bodyMapState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tóm tắt các cơ quan',
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: bodyMapState.organHealths.length,
          itemBuilder: (context, index) {
            final organHealth = bodyMapState.organHealths[index];
            return _buildOrganSummaryCard(organHealth);
          },
        ),
      ],
    );
  }

  /// Build individual organ summary card
  Widget _buildOrganSummaryCard(OrganHealth organHealth) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: organHealth.currentColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Health indicator
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: organHealth.currentColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),

          // Organ info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  organHealth.organ.name,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '${(organHealth.hydrationLevel * 100).round()}%',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: organHealth.currentColor,
                    fontWeight: FontWeight.w700,
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
