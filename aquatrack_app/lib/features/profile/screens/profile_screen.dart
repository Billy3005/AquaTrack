import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../level/providers/level_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/avatar_selector.dart';
import '../widgets/settings_section.dart';
import '../widgets/stats_summary.dart';

/// Screen 08 — Profile
/// User info, avatar selection, stats summary, and app settings
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);
    final levelState = ref.watch(levelNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: levelState.when(
        data: (level) => CustomScrollView(
          controller: _scrollController,
          slivers: [
            // User profile header
            SliverToBoxAdapter(child: _buildUserHeader(profileState, level)),

            // Stats summary
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: StatsSummary(
                  stats: ref.read(profileNotifierProvider.notifier).getStats(),
                ),
              ),
            ),

            // Avatar selection
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: AvatarSelector(
                  selectedAvatar: profileState.selectedAvatar,
                  unlockedAvatars: _getUnlockedAvatars(level.currentLevel),
                  onAvatarSelected: (avatar) {
                    ref
                        .read(profileNotifierProvider.notifier)
                        .updateAvatar(avatar);
                  },
                ),
              ),
            ),

            // Settings section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SettingsSection(
                  dailyGoalMl: profileState.dailyGoalMl,
                  notificationsEnabled: profileState.notificationsEnabled,
                  selectedTheme: profileState.selectedTheme,
                  soundEnabled: profileState.soundEnabled,
                  language: profileState.language,
                  onDailyGoalChanged: (goal) {
                    ref
                        .read(profileNotifierProvider.notifier)
                        .updateDailyGoal(goal);
                  },
                  onNotificationsChanged: (enabled) {
                    ref
                        .read(profileNotifierProvider.notifier)
                        .updateNotifications(enabled);
                  },
                  onThemeChanged: (theme) {
                    ref
                        .read(profileNotifierProvider.notifier)
                        .updateTheme(theme);
                  },
                  onSoundChanged: (enabled) {
                    ref
                        .read(profileNotifierProvider.notifier)
                        .updateSound(enabled);
                  },
                  onLanguageChanged: (language) {
                    ref
                        .read(profileNotifierProvider.notifier)
                        .updateLanguage(language);
                  },
                ),
              ),
            ),

            // Account section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: _buildAccountSection(),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error', style: TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  /// Build app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'HỒ SƠ CÁ NHÂN',
        style: AppTextStyles.headingMedium.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_vert_rounded,
            color: AppColors.textSecondary,
          ),
          color: AppColors.surface,
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit_name',
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_outlined,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sửa tên hiển thị',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'export_data',
              child: Row(
                children: [
                  const Icon(
                    Icons.download_outlined,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Xuất dữ liệu',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build user header section
  Widget _buildUserHeader(ProfileState profileState, LevelState levelState) {
    return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.cyan.withValues(alpha: 0.2),
                AppColors.xpPurple.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.cyan.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Avatar display
              Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.cyan, AppColors.xpPurple],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cyan.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.water_drop,
                      color: Colors.white,
                      size: 40,
                    ),
                  )
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .scale(
                    begin: const Offset(0.95, 0.95),
                    end: const Offset(1.05, 1.05),
                    duration: 2000.ms,
                  ),

              const SizedBox(width: 16),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profileState.userName,
                      style: AppTextStyles.headingMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.xpPurple, AppColors.cyan],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Level ${levelState.currentLevel}',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${levelState.currentXP} XP',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mục tiêu: ${profileState.dailyGoalMl}ml/ngày',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate(delay: const Duration(milliseconds: 200))
        .fadeIn(duration: 500.ms)
        .slideY(begin: -0.2, end: 0.0);
  }

  /// Build account section
  Widget _buildAccountSection() {
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
                Icons.account_circle_outlined,
                color: AppColors.cyan,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Tài khoản',
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Account actions
          _buildAccountAction(
            icon: Icons.info_outline,
            title: 'Về AquaTrack',
            subtitle: 'Phiên bản 1.0.0',
            onTap: () => _showAboutDialog(),
          ),

          const SizedBox(width: 8),

          _buildAccountAction(
            icon: Icons.privacy_tip_outlined,
            title: 'Chính sách bảo mật',
            subtitle: 'Dữ liệu của bạn được bảo vệ',
            onTap: () => _showPrivacyDialog(),
          ),

          const SizedBox(width: 8),

          _buildAccountAction(
            icon: Icons.feedback_outlined,
            title: 'Phản hồi',
            subtitle: 'Giúp chúng tôi cải thiện app',
            onTap: () => _showFeedbackDialog(),
          ),
        ],
      ),
    );
  }

  /// Build account action item
  Widget _buildAccountAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.cyan, size: 20),
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
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  /// Get unlocked avatars based on level
  Set<String> _getUnlockedAvatars(int currentLevel) {
    const avatarLevels = {
      'avatar_1': 1,
      'avatar_2': 3,
      'avatar_3': 5,
      'avatar_4': 8,
      'avatar_5': 12,
      'avatar_6': 15,
      'avatar_7': 20,
      'avatar_8': 25,
    };

    return avatarLevels.entries
        .where((entry) => currentLevel >= entry.value)
        .map((entry) => entry.key)
        .toSet();
  }

  /// Handle menu actions
  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit_name':
        _showEditNameDialog();
        break;
      case 'export_data':
        _exportUserData();
        break;
    }
  }

  /// Show edit name dialog
  void _showEditNameDialog() {
    final controller = TextEditingController(
      text: ref.read(profileNotifierProvider).userName,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Sửa tên hiển thị',
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Nhập tên mới',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Hủy',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(profileNotifierProvider.notifier)
                  .updateUserName(controller.text.trim());
              Navigator.of(context).pop();
            },
            child: Text(
              'Lưu',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.cyan),
            ),
          ),
        ],
      ),
    );
  }

  /// Export user data (placeholder)
  void _exportUserData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Tính năng xuất dữ liệu sẽ có trong phiên bản tiếp theo',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.surface,
      ),
    );
  }

  /// Show about dialog
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Về AquaTrack',
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'AquaTrack v1.0.0\n\nỨng dụng theo dõi hydration thông minh với AI Coach và gamification system.\n\nPhát triển bởi: Aqua Team',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Đóng',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.cyan),
            ),
          ),
        ],
      ),
    );
  }

  /// Show privacy dialog
  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Chính sách bảo mật',
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'AquaTrack cam kết bảo vệ dữ liệu cá nhân của bạn. Tất cả dữ liệu được lưu trữ local trên thiết bị và không được chia sẻ với bên thứ ba.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Đóng',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.cyan),
            ),
          ),
        ],
      ),
    );
  }

  /// Show feedback dialog
  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Gửi phản hồi',
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Cảm ơn bạn đã sử dụng AquaTrack! Vui lòng liên hệ team phát triển qua email: feedback@aquatrack.app',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Đóng',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.cyan),
            ),
          ),
        ],
      ),
    );
  }
}
