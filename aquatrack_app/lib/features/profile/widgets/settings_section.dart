import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Settings section for user preferences
class SettingsSection extends StatelessWidget {
  final int dailyGoalMl;
  final bool notificationsEnabled;
  final String selectedTheme;
  final bool soundEnabled;
  final String language;
  final Function(int)? onDailyGoalChanged;
  final Function(bool)? onNotificationsChanged;
  final Function(String)? onThemeChanged;
  final Function(bool)? onSoundChanged;
  final Function(String)? onLanguageChanged;

  const SettingsSection({
    super.key,
    required this.dailyGoalMl,
    required this.notificationsEnabled,
    required this.selectedTheme,
    required this.soundEnabled,
    required this.language,
    this.onDailyGoalChanged,
    this.onNotificationsChanged,
    this.onThemeChanged,
    this.onSoundChanged,
    this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surface.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.settings_outlined,
                color: AppColors.cyan,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Cài đặt',
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Daily goal slider
          _buildDailyGoalSetting(),

          const SizedBox(height: 16),

          // Toggle settings
          _buildToggleSetting(
            icon: Icons.notifications_outlined,
            title: 'Thông báo',
            subtitle: 'Nhắc nhở uống nước định kỳ',
            value: notificationsEnabled,
            onChanged: onNotificationsChanged,
          ),

          const SizedBox(height: 12),

          _buildToggleSetting(
            icon: Icons.volume_up_outlined,
            title: 'Âm thanh',
            subtitle: 'Hiệu ứng âm thanh trong app',
            value: soundEnabled,
            onChanged: onSoundChanged,
          ),

          const SizedBox(height: 16),

          // Dropdown settings
          _buildDropdownSetting(
            icon: Icons.palette_outlined,
            title: 'Giao diện',
            value: selectedTheme,
            options: const {
              'dark': 'Tối',
              'light': 'Sáng',
              'auto': 'Tự động',
            },
            onChanged: onThemeChanged,
          ),

          const SizedBox(width: 12),

          _buildDropdownSetting(
            icon: Icons.language_outlined,
            title: 'Ngôn ngữ',
            value: language,
            options: const {
              'vi': 'Tiếng Việt',
              'en': 'English',
            },
            onChanged: onLanguageChanged,
          ),
        ],
      ),
    );
  }

  /// Build daily goal slider setting
  Widget _buildDailyGoalSetting() {
    return Builder(
      builder: (context) => _buildDailyGoalContent(),
    );
  }

  /// Build daily goal content with context
  Widget _buildDailyGoalContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.flag_outlined,
              color: AppColors.cyan,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Mục tiêu hàng ngày',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: const SliderThemeData(
                  activeTrackColor: AppColors.cyan,
                  inactiveTrackColor: AppColors.surface,
                  thumbColor: AppColors.cyan,
                  overlayColor: AppColors.cyan,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: dailyGoalMl.toDouble(),
                  min: 1000,
                  max: 4000,
                  divisions: 20,
                  onChanged: (value) => onDailyGoalChanged?.call(value.round()),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.cyan.withValues(alpha: 0.2),
                    AppColors.cyan.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.cyan.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                '${dailyGoalMl}ml',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.cyan,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        Text(
          'Lượng nước cần uống mỗi ngày',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Build toggle setting item
  Widget _buildToggleSetting({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool)? onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.cyan,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.cyan,
          activeTrackColor: AppColors.cyan.withValues(alpha: 0.3),
          inactiveThumbColor: AppColors.textSecondary,
          inactiveTrackColor: AppColors.surface.withValues(alpha: 0.5),
        ),
      ],
    );
  }

  /// Build dropdown setting item
  Widget _buildDropdownSetting({
    required IconData icon,
    required String title,
    required String value,
    required Map<String, String> options,
    required Function(String)? onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.cyan,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.surface.withValues(alpha: 0.7),
              width: 1,
            ),
          ),
          child: DropdownButton<String>(
            value: value,
            onChanged: (String? newValue) {
              if (newValue != null) {
                onChanged?.call(newValue);
              }
            },
            underline: const SizedBox.shrink(),
            dropdownColor: AppColors.surface,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            items: options.entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Text(
                  entry.value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
