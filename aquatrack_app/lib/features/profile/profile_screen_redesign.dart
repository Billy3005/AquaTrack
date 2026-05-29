import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/repositories/auth_repository.dart';
import '../../shared/widgets/coin_badge.dart';
import 'providers/profile_provider.dart';
import 'edit_body_info_screen.dart';

/// Profile Screen - Complete redesign matching aquatrack/project/components/profile.jsx
class ProfileScreenRedesign extends ConsumerStatefulWidget {
  const ProfileScreenRedesign({super.key});

  @override
  ConsumerState<ProfileScreenRedesign> createState() =>
      _ProfileScreenRedesignState();
}

class _ProfileScreenRedesignState extends ConsumerState<ProfileScreenRedesign> {
  // Daily goal is computed-only via Water Formula, not editable

  @override
  void initState() {
    super.initState();
    // Force refresh profile data when ProfileScreen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileNotifierProvider.notifier).refreshProfile();
    });
  }

  final List<ReminderData> _reminders = [
    ReminderData(
      time: '08:00',
      tone: 'Năng động',
      label: 'Khởi động ngày mới',
      isOn: true,
    ),
    ReminderData(
      time: '12:00',
      tone: 'Thân thiện',
      label: 'Nhắc giữa trưa',
      isOn: true,
    ),
    ReminderData(
      time: '15:00',
      tone: 'Nhẹ nhàng',
      label: 'Buổi chiều dễ quên',
      isOn: true,
    ),
    ReminderData(
      time: '18:30',
      tone: 'Thân thiện',
      label: 'Sau giờ làm',
      isOn: false,
    ),
    ReminderData(
      time: '20:00',
      tone: 'Bình yên',
      label: 'Cuối ngày',
      isOn: true,
    ),
  ];

  // No initialization needed - using ProfileProvider computed goal

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.background,
        child: SafeArea(
          child: Column(
            children: [
              // Header with gradient and avatar
              _buildHeader(),

              // Scrollable content with pull-to-refresh
              Expanded(
                child: RefreshIndicator(
                  backgroundColor: AppColors.surface,
                  color: AppColors.cyan,
                  onRefresh: () async {
                    await ref
                        .read(profileNotifierProvider.notifier)
                        .refreshProfile();
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    physics:
                        const AlwaysScrollableScrollPhysics(), // Ensure pull-to-refresh works
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Lifetime stats
                        _buildLifetimeStats(),
                        const SizedBox(height: 18),

                        // Avatar collection
                        _buildAvatarCollection(),
                        const SizedBox(height: 18),

                        // Themes
                        _buildThemesSection(),
                        const SizedBox(height: 18),

                        // Daily goal
                        _buildDailyGoalSection(),
                        const SizedBox(height: 18),

                        // Reminder schedule
                        _buildReminderSection(),
                        const SizedBox(height: 18),

                        // Body data
                        _buildBodyDataSection(),
                        const SizedBox(height: 18),

                        // Sign out
                        _buildSignOutButton(),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0C2A4A), AppColors.background],
        ),
      ),
      child: Stack(
        children: [
          // Glow effect
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0x2E38BDF8), // rgba(56,189,248,0.18)
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6],
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 54, 20, 16),
            child: Column(
              children: [
                // Title and settings
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'HỒ SƠ',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                    Row(
                      children: [
                        Consumer(
                          builder: (context, ref, child) {
                            final profile = ref.watch(profileNotifierProvider);
                            return CoinBadge(amount: profile.coins);
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildSettingsButton(),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Avatar and user info
                Row(
                  children: [
                    // Avatar with animated ring
                    _buildAvatar(),
                    const SizedBox(width: 14),

                    // User info - Real user data from ProfileProvider
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, child) {
                          final profile = ref.watch(profileNotifierProvider);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.userName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: -0.02,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Text(
                                    'Chiến binh Nước',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFFA5B4FC),
                                      fontFamily: 'SF Pro Rounded',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFA5B4FC,
                                      ).withValues(alpha: 0.6),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Consumer(
                                    builder: (context, ref, child) {
                                      final profile =
                                          ref.watch(profileNotifierProvider);
                                      return Text(
                                        'Tham gia ${profile.daysSinceJoined} ngày',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontFamily: 'SF Pro Text',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12.5,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildXPBar(),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.settings, color: Colors.white, size: 16),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: 76,
          height: 76,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            gradient: const SweepGradient(
              startAngle: 3.83, // 220deg in radians
              colors: [
                Color(0xFFFBBF24),
                Color(0xFF818CF8),
                Color(0xFF38BDF8),
                Color(0xFFFBBF24),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0x5938BDF8), // rgba(56,189,248,0.35)
                blurRadius: 24,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                center: Alignment(0.3, 0.3),
                colors: [Color(0xFF7DD3FC), Color(0xFF0284C7)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.background, width: 2),
            ),
            child: const Icon(Icons.water_drop, color: Colors.white, size: 32),
          ),
        ),
        Positioned(
          bottom: -4,
          right: -4,
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.background, width: 2),
            ),
            child: Consumer(
              builder: (context, ref, child) {
                final profile = ref.watch(profileNotifierProvider);
                return Text(
                  profile.levelDisplay,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE0E7FF),
                    fontFamily: 'SF Pro Rounded',
                    letterSpacing: 0.04,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildXPBar() {
    return Consumer(
      builder: (context, ref, child) {
        final profile = ref.watch(profileNotifierProvider);
        final pct = profile.xpProgress;

        return Column(
          children: [
            // XP info row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      profile.levelDisplay,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.xpPurple,
                        fontFamily: 'SF Pro Rounded',
                        letterSpacing: 0.04,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '· Chiến binh Nước',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  profile.xpProgressDisplay,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Progress bar
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF312E81),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct / 100,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.xpPurple, Color(0xFFA5B4FC)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.xpPurple.withValues(alpha: 0.53),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLifetimeStats() {
    return Consumer(
      builder: (context, ref, child) {
        final profile = ref.watch(profileNotifierProvider);
        return Row(
          children: [
            Expanded(
              child: _buildLifetimeStatCard(
                icon: const Icon(
                  Icons.water_drop,
                  color: Color(0xFF38BDF8),
                  size: 16,
                ),
                value: profile.totalVolumeLiters,
                label: 'Tổng nước',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildLifetimeStatCard(
                icon: const Icon(
                  Icons.local_fire_department,
                  color: Color(0xFFF97316),
                  size: 16,
                ),
                value: profile.longestStreak.toString(),
                label: 'Streak dài nhất',
                subtitle: 'ngày',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildLifetimeStatCard(
                icon: const Icon(
                  Icons.calendar_today,
                  color: Color(0xFFA78BFA),
                  size: 16,
                ),
                value: profile.daysSinceJoined.toString(),
                label: 'Ngày hoạt động',
                subtitle:
                    'trên ${(profile.daysSinceJoined * 1.2).ceil()}', // Realistic target based on days joined
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLifetimeStatCard({
    required Widget icon,
    required String value,
    required String label,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [icon]),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: 'SF Pro Rounded',
                letterSpacing: -0.02,
                height: 1,
              ),
              children: subtitle != null
                  ? [
                      TextSpan(
                        text: ' $subtitle',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
              fontFamily: 'SF Pro Text',
              letterSpacing: 0.02,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarCollection() {
    final avatars = [
      AvatarData(
        color: const Color(0xFF38BDF8),
        name: 'Drop',
        unlocked: true,
        current: true,
      ),
      AvatarData(
        color: const Color(0xFF0EA5E9),
        name: 'Wave',
        unlocked: true,
        current: false,
      ),
      AvatarData(
        color: const Color(0xFFA78BFA),
        name: 'Glacier',
        unlocked: true,
        current: false,
      ),
      AvatarData(
        color: const Color(0xFF0284C7),
        name: 'Ocean',
        unlocked: false,
        current: false,
        level: 'LV 10',
      ),
      AvatarData(
        color: const Color(0xFF94A3B8),
        name: 'Cloud',
        unlocked: false,
        current: false,
        level: 'LV 12',
      ),
      AvatarData(
        color: const Color(0xFF10B981),
        name: 'Spring',
        unlocked: false,
        current: false,
        level: 'LV 15',
      ),
    ];

    return Column(
      children: [
        _buildSectionHeader(title: 'Bộ sưu tập avatar', trailing: '3/5'),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: avatars.length,
            itemBuilder: (context, index) {
              final avatar = avatars[index];
              return Container(
                width: 84,
                margin: EdgeInsets.only(left: index == 0 ? 0 : 10),
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        gradient: avatar.unlocked
                            ? RadialGradient(
                                center: const Alignment(0.3, 0.3),
                                colors: [
                                  avatar.color.withValues(alpha: 0.87),
                                  avatar.color.withValues(alpha: 0.33),
                                ],
                              )
                            : null,
                        color: avatar.unlocked
                            ? null
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(18),
                        border: avatar.current
                            ? Border.all(
                                color: const Color(0xFFFBBF24),
                                width: 2,
                              )
                            : avatar.unlocked
                                ? Border.all(
                                    color: avatar.color.withValues(alpha: 0.4),
                                  )
                                : Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    style: BorderStyle.solid,
                                  ),
                        boxShadow: avatar.unlocked
                            ? [
                                BoxShadow(
                                  color: avatar.color.withValues(alpha: 0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          avatar.unlocked
                              ? const Icon(
                                  Icons.water_drop,
                                  color: Colors.white,
                                  size: 30,
                                )
                              : Text(
                                  '🔒',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                          if (avatar.current)
                            Positioned(
                              top: -8,
                              right: -8,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(7, 2, 7, 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFBBF24),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'CUR',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF451A03),
                                    fontFamily: 'SF Pro Rounded',
                                    letterSpacing: 0.04,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      avatar.name,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFamily: 'SF Pro Rounded',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!avatar.unlocked && avatar.level != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        avatar.level!,
                        style: TextStyle(
                          fontSize: 9.5,
                          color: AppColors.textSecondary,
                          fontFamily: 'SF Pro Rounded',
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildThemesSection() {
    final themes = [
      ThemeData(
        name: 'Ocean Night',
        gradient: const LinearGradient(
          colors: [Color(0xFF0C4A80), Color(0xFF082F5C)],
        ),
        current: true,
        unlocked: true,
      ),
      ThemeData(
        name: 'Default Blue',
        gradient: const LinearGradient(
          colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
        ),
        current: false,
        unlocked: true,
      ),
      ThemeData(
        name: 'Desert Sunset',
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFF92400E)],
        ),
        current: false,
        unlocked: false,
        level: 'LV 9',
      ),
      ThemeData(
        name: 'Forest Rain',
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF064E3B)],
        ),
        current: false,
        unlocked: false,
        level: 'LV 11',
      ),
    ];

    return Column(
      children: [
        _buildSectionHeader(title: 'Themes', trailing: '2/4'),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.5,
          ),
          itemCount: themes.length,
          itemBuilder: (context, index) {
            final theme = themes[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: theme.current
                    ? Border.all(color: const Color(0xFFFBBF24), width: 1.5)
                    : Border.all(color: Colors.white.withValues(alpha: 0.06)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Opacity(
                opacity: theme.unlocked ? 1.0 : 0.6,
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: theme.gradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: theme.unlocked
                          ? null
                          : const Center(
                              child: Text('🔒', style: TextStyle(fontSize: 13)),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            theme.name,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'SF Pro Text',
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            theme.current
                                ? 'Đang dùng'
                                : theme.unlocked
                                    ? 'Đã mở'
                                    : theme.level ?? '',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.current
                                  ? const Color(0xFFFBBF24)
                                  : AppColors.textSecondary,
                              fontFamily: 'SF Pro Rounded',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDailyGoalSection() {
    return Column(
      children: [
        _buildSectionHeader(title: 'Mục tiêu hàng ngày'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0x2638BDF8), // rgba(56,189,248,0.15)
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.water_drop, color: Color(0xFF38BDF8), size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAILY GOAL',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.06,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Computed daily goal from Water Formula (read-only)
                    Consumer(
                      builder: (context, ref, child) {
                        final profile = ref.watch(profileNotifierProvider);
                        return Row(
                          children: [
                            Text(
                              profile.dailyGoalMl.toString(),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'SF Pro Rounded',
                                letterSpacing: -0.02,
                              ),
                            ),
                            Text(
                              ' ml / day',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0x1A7B5EA7),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0x337B5EA7)),
                              ),
                              child: Text(
                                'Tự động',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Color(0xFF38BDF8),
                          size: 11,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'AI điều chỉnh +300ml hôm nay (nóng)',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textPrimary,
                            fontFamily: 'SF Pro Text',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // No edit button - daily goal is computed automatically
            ],
          ),
        ),
      ],
    );
  }

  // Daily goal is computed via Water Formula - no manual editing needed

  /// Handle sign out functionality
  Future<void> _handleSignOut() async {
    // Show confirmation dialog
    final shouldSignOut = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xác nhận đăng xuất',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi AquaTrack?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Hủy',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFCA5A5),
            ),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      try {
        // Show loading state
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Đang đăng xuất...'),
                ],
              ),
              backgroundColor: AppColors.surface,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Perform logout
        await AuthRepository().logout();

        if (mounted) {
          // Clear snackbar and navigate to login
          ScaffoldMessenger.of(context).clearSnackBars();

          // Navigate to login screen and clear all routes
          context.go('/login');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi đăng xuất: ${e.toString()}'),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Widget _buildReminderSection() {
    final activeCount = _reminders.where((r) => r.isOn).length;

    return Column(
      children: [
        _buildSectionHeader(
          title: 'Lịch nhắc nhở',
          trailing: '$activeCount/${_reminders.length}',
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.textHint),
          ),
          child: Column(
            children: [
              ...List.generate(_reminders.length, (index) {
                final reminder = _reminders[index];
                return _buildReminderRow(
                  reminder,
                  index,
                  index == _reminders.length - 1,
                );
              }),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add, color: Color(0xFF38BDF8), size: 14),
                    const SizedBox(width: 8),
                    Text(
                      'Thêm slot',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: const Color(0xFF7DD3FC),
                        fontFamily: 'SF Pro Text',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReminderRow(ReminderData reminder, int index, bool isLast) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
              ),
      ),
      child: Row(
        children: [
          // Time display
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: reminder.isOn
                  ? const Color(0x1F38BDF8) // rgba(56,189,248,0.12)
                  : Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                color: reminder.isOn
                    ? const Color(0x4D38BDF8) // rgba(56,189,248,0.3)
                    : Colors.white.withValues(alpha: 0.06),
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                reminder.time,
                style: TextStyle(
                  fontFamily: 'SF Pro Rounded',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: reminder.isOn
                      ? const Color(0xFFBAE6FD)
                      : AppColors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Label and tone
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: reminder.isOn
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontFamily: 'SF Pro Text',
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Tone: ${reminder.tone}',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                    fontFamily: 'SF Pro Text',
                  ),
                ),
              ],
            ),
          ),

          // Toggle switch
          _buildToggleSwitch(
            isOn: reminder.isOn,
            onChanged: () {
              setState(() {
                _reminders[index] = _reminders[index].copyWith(
                  isOn: !_reminders[index].isOn,
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSwitch({
    required bool isOn,
    required VoidCallback onChanged,
  }) {
    return GestureDetector(
      onTap: onChanged,
      child: Container(
        width: 42,
        height: 24,
        decoration: BoxDecoration(
          color: isOn
              ? const Color(0xFF0EA5E9)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          boxShadow: isOn
              ? [
                  BoxShadow(
                    color: const Color(0x800EA5E9), // rgba(14,165,233,0.5)
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: AnimatedAlign(
          alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Container(
            margin: const EdgeInsets.all(2),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyDataSection() {
    return Consumer(
      builder: (context, ref, child) {
        final profile = ref.watch(profileNotifierProvider);

        final bodyData = [
          BodyRowData(
            label: 'Cân nặng · Chiều cao',
            value: profile.weightHeightDisplay,
            hint: 'Cập nhật 2 tuần trước',
          ),
          BodyRowData(
            label: 'Giới tính · Tuổi',
            value: profile.genderAgeDisplay,
          ),
          BodyRowData(
            label: 'Mức vận động',
            value: profile.activityLevelDisplay,
            pillColor: const Color(0xFF10B981),
          ),
          BodyRowData(
            label: 'Công việc',
            value: profile.jobTypeDisplay,
            pillColor: const Color(0xFF38BDF8),
          ),
          BodyRowData(
            label: 'Sức khoẻ đặc biệt',
            value: profile.healthConditionsDisplay,
          ),
          BodyRowData(
            label: 'Cà phê · Rượu bia',
            value: profile.coffeealcoholDisplay,
          ),
          BodyRowData(
            label: 'Climate zone',
            value: 'Nhiệt đới (HCMC)', // TODO: Add climate zone to backend
            pillColor: const Color(0xFFF59E0B),
            isLast: true,
          ),
        ];

        return Column(
          children: [
            _buildSectionHeader(
              title: 'Hồ sơ cơ thể',
              subtitle: 'Dùng để AI tính goal',
              trailing: GestureDetector(
                onTap: () => _navigateToEditBodyInfo(context),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
                  decoration: BoxDecoration(
                    color: const Color(0x1F38BDF8), // rgba(56,189,248,0.12)
                    border: Border.all(
                      color: const Color(0x4D38BDF8), // rgba(56,189,248,0.3)
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit,
                          color: Color(0xFFBAE6FD), size: 10),
                      const SizedBox(width: 4),
                      const Text(
                        'Sửa',
                        style: TextStyle(
                          color: Color(0xFFBAE6FD),
                          fontFamily: 'SF Pro Text',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
              ),
              child: Column(
                children: bodyData.map((data) => _buildBodyRow(data)).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBodyRow(BodyRowData data) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        border: data.isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    fontFamily: 'SF Pro Text',
                  ),
                ),
                if (data.hint != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    data.hint!,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (data.pillColor != null)
            Container(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
              decoration: BoxDecoration(
                color: data.pillColor!.withValues(alpha: 0.12),
                border: Border.all(
                  color: data.pillColor!.withValues(alpha: 0.2),
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                data.value,
                style: TextStyle(
                  fontSize: 11.5,
                  fontFamily: 'SF Pro Text',
                  fontWeight: FontWeight.w600,
                  color: data.pillColor,
                ),
              ),
            )
          else
            Text(
              data.value,
              style: const TextStyle(
                fontSize: 13.5,
                color: Colors.white,
                fontFamily: 'SF Pro Rounded',
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          const SizedBox(width: 10),
          Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 14),
        ],
      ),
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _handleSignOut(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0x0FEF4444), // rgba(239,68,68,0.06)
          foregroundColor: const Color(0xFFFCA5A5),
          side: BorderSide(
            color: const Color(0x26EF4444), // rgba(239,68,68,0.15)
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Đăng xuất',
          style: TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    String? subtitle,
    dynamic trailing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'SF Pro Text',
                letterSpacing: -0.01,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textSecondary,
                  fontFamily: 'SF Pro Text',
                ),
              ),
            ],
          ],
        ),
        if (trailing != null)
          trailing is Widget
              ? trailing
              : Text(
                  trailing.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontFamily: 'SF Pro Rounded',
                    fontWeight: FontWeight.w600,
                  ),
                ),
      ],
    );
  }

  /// Navigate to edit body info screen
  void _navigateToEditBodyInfo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditBodyInfoScreen(),
      ),
    );
  }
}

// Data classes
class ReminderData {
  final String time;
  final String tone;
  final String label;
  final bool isOn;

  ReminderData({
    required this.time,
    required this.tone,
    required this.label,
    required this.isOn,
  });

  ReminderData copyWith({
    String? time,
    String? tone,
    String? label,
    bool? isOn,
  }) {
    return ReminderData(
      time: time ?? this.time,
      tone: tone ?? this.tone,
      label: label ?? this.label,
      isOn: isOn ?? this.isOn,
    );
  }
}

class AvatarData {
  final Color color;
  final String name;
  final bool unlocked;
  final bool current;
  final String? level;

  AvatarData({
    required this.color,
    required this.name,
    required this.unlocked,
    required this.current,
    this.level,
  });
}

class ThemeData {
  final String name;
  final LinearGradient gradient;
  final bool current;
  final bool unlocked;
  final String? level;

  ThemeData({
    required this.name,
    required this.gradient,
    required this.current,
    required this.unlocked,
    this.level,
  });
}

class BodyRowData {
  final String label;
  final String value;
  final String? hint;
  final Color? pillColor;
  final bool isLast;

  BodyRowData({
    required this.label,
    required this.value,
    this.hint,
    this.pillColor,
    this.isLast = false,
  });
}
