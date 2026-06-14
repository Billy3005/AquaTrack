import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/session.dart';
import '../../core/repositories/auth_repository.dart';
import '../../shared/widgets/coin_badge.dart';
import '../avatars/avatar_collection_screen.dart';
import '../avatars/data/avatar_catalog.dart';
import '../avatars/widgets/aqua_avatar.dart';
import '../reminders/data/reminder_slot.dart';
import '../reminders/providers/reminder_provider.dart';
import '../reminders/widgets/reminder_sheets.dart';
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
                                profile.displayName,
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
                                  Flexible(
                                    child: Text(
                                      profile.userEmail,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: Color(0xFFA5B4FC),
                                        fontFamily: 'SF Pro Rounded',
                                        fontWeight: FontWeight.w600,
                                      ),
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
      clipBehavior: Clip.none,
      children: [
        Consumer(
          builder: (context, ref, _) {
            final spec = avatarSpecOrDefault(
              ref.watch(profileNotifierProvider).selectedAvatar,
            );
            return AvatarBubble(spec: spec, size: 76);
          },
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
    return Consumer(
      builder: (context, ref, _) {
        final profile = ref.watch(profileNotifierProvider);

        AvatarOwnership stateOf(AquaAvatarSpec spec) => avatarOwnership(
              spec,
              level: profile.currentLevel,
              longestStreak: profile.longestStreak,
              ownedAvatars: profile.ownedAvatars,
              equippedId: profile.selectedAvatar,
            );

        final ownedCount = kAvatarCatalog
            .where((a) => stateOf(a) != AvatarOwnership.locked)
            .length;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AvatarCollectionScreen()),
          ),
          child: Column(
            children: [
              _buildSectionHeader(
                title: 'Bộ sưu tập avatar',
                trailing: '$ownedCount/${kAvatarCatalog.length} ›',
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 104,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: kAvatarCatalog.length,
                  itemBuilder: (context, index) {
                    final spec = kAvatarCatalog[index];
                    final state = stateOf(spec);
                    final locked = state == AvatarOwnership.locked;
                    final equipped = state == AvatarOwnership.equipped;
                    return Container(
                      width: 78,
                      margin: EdgeInsets.only(left: index == 0 ? 0 : 10),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: equipped
                                  ? Border.all(
                                      color: spec.tierStyle.color, width: 2)
                                  : Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: AquaAvatar(
                                spec: spec, size: 60, silhouette: locked),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            spec.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: locked
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                              fontFamily: 'SF Pro Rounded',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemesSection() {
    // Theme switching is not wired to a real theme engine yet, so every option
    // is locked and labelled "Sắp ra mắt" — no theme is presented as active or
    // owned until the feature actually changes the app's appearance.
    final themes = [
      ThemeData(
        name: 'Ocean Night',
        gradient: const LinearGradient(
          colors: [Color(0xFF0C4A80), Color(0xFF082F5C)],
        ),
        current: false,
        unlocked: false,
      ),
      ThemeData(
        name: 'Default Blue',
        gradient: const LinearGradient(
          colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
        ),
        current: false,
        unlocked: false,
      ),
      ThemeData(
        name: 'Desert Sunset',
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFF92400E)],
        ),
        current: false,
        unlocked: false,
      ),
      ThemeData(
        name: 'Forest Rain',
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF064E3B)],
        ),
        current: false,
        unlocked: false,
      ),
    ];

    return Column(
      children: [
        _buildSectionHeader(title: 'Themes', trailing: 'Sắp ra mắt'),
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
                            'Sắp ra mắt',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
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

        // Drop every cached user-scoped provider so the next account that logs
        // in on this device starts from a clean slate (no leaked data).
        resetUserSession(ref);

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
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(reminderProvider);
        final slots = state.slots;
        return Column(
          children: [
            _buildSectionHeader(
              title: 'Lịch nhắc nhở',
              trailing: '${state.activeCount}/${slots.length}',
            ),
            const SizedBox(height: 10),
            if (state.blockedByPermission) ...[
              _buildReminderPermissionHint(ref),
              const SizedBox(height: 10),
            ],
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.textHint),
              ),
              child: Column(
                children: [
                  if (slots.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Text(
                        'Chưa có mốc nhắc nào — thêm hoặc dùng gợi ý',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          fontFamily: 'SF Pro Text',
                        ),
                      ),
                    )
                  else
                    ...List.generate(slots.length, (index) {
                      return _buildReminderRow(
                        ref,
                        slots[index],
                        index == slots.length - 1,
                      );
                    }),
                  _buildReminderAction(
                    icon: Icons.auto_awesome,
                    label: 'Gợi ý lịch',
                    onTap: () => showSuggestionSheet(context, ref),
                  ),
                  _buildReminderAction(
                    icon: Icons.add,
                    label: 'Thêm mốc',
                    onTap: () => showSlotEditSheet(context, ref),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReminderPermissionHint(WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ref.read(reminderProvider.notifier).ensurePermission(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
        decoration: BoxDecoration(
          color: const Color(0x1FF59E0B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x4DF59E0B)),
        ),
        child: Row(
          children: [
            const Icon(Icons.notifications_off_outlined,
                color: Color(0xFFFBBF24), size: 16),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Thông báo đang tắt — bật để nhận nhắc nhở',
                style: TextStyle(
                  color: Color(0xFFFBBF24),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF Pro Text',
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFFBBF24), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF38BDF8), size: 15),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF7DD3FC),
                fontFamily: 'SF Pro Text',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderRow(WidgetRef ref, ReminderSlot slot, bool isLast) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showSlotEditSheet(context, ref, existing: slot),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom:
                      BorderSide(color: Colors.white.withValues(alpha: 0.04)),
                ),
        ),
        child: Row(
          children: [
            // Time display
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: slot.enabled
                    ? const Color(0x1F38BDF8) // rgba(56,189,248,0.12)
                    : Colors.white.withValues(alpha: 0.04),
                border: Border.all(
                  color: slot.enabled
                      ? const Color(0x4D38BDF8) // rgba(56,189,248,0.3)
                      : Colors.white.withValues(alpha: 0.06),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  slot.timeLabel,
                  style: TextStyle(
                    fontFamily: 'SF Pro Rounded',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: slot.enabled
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
                    slot.label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: slot.enabled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Giọng: ${slot.tone.label}',
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
              isOn: slot.enabled,
              onChanged: () =>
                  ref.read(reminderProvider.notifier).toggleSlot(slot.id),
            ),
          ],
        ),
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
                  child: const Row(
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
