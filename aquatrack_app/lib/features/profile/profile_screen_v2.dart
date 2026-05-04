import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Profile Screen - Simple UI testing version (NO AUTH)
class ProfileScreenV2 extends ConsumerWidget {
  const ProfileScreenV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildUserProfile(),
                      const SizedBox(height: 24),
                      _buildQuickStats(),
                      const SizedBox(height: 24),
                      _buildSettingsSection(),
                      const SizedBox(height: 24),
                      _buildTestMessage(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Header with title
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Hồ sơ',
            style: AppTextStyles.displayMedium,
          ),
          IconButton(
            onPressed: () {
              // Settings navigation (disabled for testing)
            },
            icon: const Icon(
              Icons.settings,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// User profile card with mock data
  Widget _buildUserProfile() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: const Icon(
              Icons.person,
              size: 40,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            'Demo User',
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: 4),

          // Email
          Text(
            'demo@aquatrack.com',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.purpleXP.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: AppColors.purpleXP.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star,
                  size: 16,
                  color: AppColors.purpleXP,
                ),
                const SizedBox(width: 4),
                Text(
                  'Level 5',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.purpleXP,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Quick stats section with mock data
  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: AppColors.cyanAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Thống kê nhanh',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.cyanAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'XP',
                '1,250',
                Icons.emoji_events,
                AppColors.purpleXP,
              ),
              _buildStatItem(
                'Streak',
                '7 ngày',
                Icons.local_fire_department,
                AppColors.juiceColor,
              ),
              _buildStatItem(
                'Tổng',
                '45.2L',
                Icons.water_drop,
                AppColors.cyanAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Individual stat item
  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Settings section
  Widget _buildSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune,
                color: AppColors.cyanAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Cài đặt',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.cyanAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            'Mục tiêu hàng ngày',
            '2,000 ml',
            Icons.flag_outlined,
            () {},
          ),
          _buildSettingItem(
            'Thông báo',
            'Bật',
            Icons.notifications_outlined,
            () {},
          ),
          _buildSettingItem(
            'Ngôn ngữ',
            'Tiếng Việt',
            Icons.language_outlined,
            () {},
          ),
          _buildSettingItem(
            'Chế độ tối',
            'Bật',
            Icons.dark_mode_outlined,
            () {},
          ),
        ],
      ),
    );
  }

  /// Individual setting item
  Widget _buildSettingItem(
      String title, String value, IconData icon, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right,
            color: AppColors.textTertiary,
            size: 20,
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  /// Test message for UI testing
  Widget _buildTestMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cyanAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cyanAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppColors.cyanAccent,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Profile Screen Test Mode',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.cyanAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Authentication bypassed - UI testing ready!',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.cyanAccent,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
