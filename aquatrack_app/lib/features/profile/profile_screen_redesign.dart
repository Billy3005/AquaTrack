import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/repositories/auth_repository.dart';
import '../../shared/widgets/coin_badge.dart';

/// Profile Screen - Complete redesign matching aquatrack/project/components/profile.jsx
class ProfileScreenRedesign extends ConsumerStatefulWidget {
  const ProfileScreenRedesign({super.key});

  @override
  ConsumerState<ProfileScreenRedesign> createState() =>
      _ProfileScreenRedesignState();
}

class _ProfileScreenRedesignState extends ConsumerState<ProfileScreenRedesign> {
  int _dailyGoal = 2500;
  bool _editingGoal = false;
  late TextEditingController _goalController;

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

  @override
  void initState() {
    super.initState();
    _goalController = TextEditingController(text: _dailyGoal.toString());
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.nightBase,
        child: SafeArea(
          child: Column(
            children: [
              // Header with gradient and avatar
              _buildHeader(),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
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
          colors: [Color(0xFF0C2A4A), AppColors.nightBase],
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
                        color: AppColors.textBright,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                    Row(
                      children: [
                        const CoinBadge(amount: 1240),
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

                    // User info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Minh Nguyễn',
                            style: TextStyle(
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
                              Text(
                                'Tham gia 84 ngày',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontFamily: 'SF Pro Text',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildXPBar(),
                        ],
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
              border: Border.all(color: AppColors.nightBase, width: 2),
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
              border: Border.all(color: AppColors.nightBase, width: 2),
            ),
            child: const Text(
              'LV 7',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE0E7FF),
                fontFamily: 'SF Pro Rounded',
                letterSpacing: 0.04,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildXPBar() {
    const xp = 1240;
    const xpMax = 2000;
    final pct = (xp / xpMax * 100).clamp(0, 100);

    return Column(
      children: [
        // XP info row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Text(
                  'LV 7',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.purpleXP,
                    fontFamily: 'SF Pro Rounded',
                    letterSpacing: 0.04,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  '· Chiến binh Nước',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const Text(
              '1240 / 2000 XP',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
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
                  colors: [AppColors.purpleXP, Color(0xFFA5B4FC)],
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purpleXP.withValues(alpha: 0.53),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLifetimeStats() {
    return Row(
      children: [
        Expanded(
          child: _buildLifetimeStatCard(
            icon: const Icon(
              Icons.water_drop,
              color: Color(0xFF38BDF8),
              size: 16,
            ),
            value: '284L',
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
            value: '21',
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
            value: '84',
            label: 'Ngày hoạt động',
            subtitle: 'trên 90',
          ),
        ),
      ],
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
        color: AppColors.nightCard,
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
                                    color: AppColors.textMuted,
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
                          color: AppColors.textMuted,
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
                color: AppColors.nightSurface,
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
                                  : AppColors.textMuted,
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
            color: AppColors.nightCard,
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
                        color: AppColors.textMuted,
                        letterSpacing: 0.06,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                    const SizedBox(height: 2),
                    _editingGoal
                        ? Row(
                            children: [
                              SizedBox(
                                width: 90,
                                child: TextField(
                                  controller: _goalController,
                                  keyboardType: TextInputType.number,
                                  autofocus: true,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    fontFamily: 'SF Pro Rounded',
                                    letterSpacing: -0.02,
                                  ),
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                        color: Color(0x6638BDF8),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                        color: Color(0x6638BDF8),
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0x1A38BDF8),
                                    contentPadding: const EdgeInsets.fromLTRB(
                                      6,
                                      2,
                                      6,
                                      2,
                                    ),
                                  ),
                                  onSubmitted: (_) => _saveGoal(),
                                  onEditingComplete: _saveGoal,
                                ),
                              ),
                              Text(
                                ' ml/day',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          )
                        : GestureDetector(
                            onTap: () => setState(() => _editingGoal = true),
                            child: Row(
                              children: [
                                Text(
                                  _dailyGoal.toString(),
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
                              ],
                            ),
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
                            color: AppColors.textBright,
                            fontFamily: 'SF Pro Text',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (_editingGoal) {
                    _saveGoal();
                  } else {
                    setState(() => _editingGoal = true);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                  decoration: BoxDecoration(
                    color: const Color(0x1F38BDF8), // rgba(56,189,248,0.12)
                    border: Border.all(
                      color: const Color(0x4D38BDF8), // rgba(56,189,248,0.3)
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _editingGoal ? 'Lưu' : 'Sửa',
                    style: const TextStyle(
                      color: Color(0xFFBAE6FD),
                      fontFamily: 'SF Pro Text',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _saveGoal() {
    setState(() {
      _dailyGoal = int.tryParse(_goalController.text) ?? _dailyGoal;
      _editingGoal = false;
    });
  }

  /// Handle sign out functionality
  Future<void> _handleSignOut() async {
    // Show confirmation dialog
    final shouldSignOut = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.nightCard,
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
              backgroundColor: AppColors.nightSurface,
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
            color: AppColors.nightSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
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
                      : AppColors.textMuted,
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
                        : AppColors.textMuted,
                    fontFamily: 'SF Pro Text',
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Tone: ${reminder.tone}',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textMuted,
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
    final bodyData = [
      BodyRowData(
        label: 'Cân nặng · Chiều cao',
        value: '62 kg · 168 cm',
        hint: 'Cập nhật 2 tuần trước',
      ),
      BodyRowData(label: 'Giới tính · Tuổi', value: 'Nam · 28'),
      BodyRowData(
        label: 'Mức vận động',
        value: 'Vừa phải',
        pillColor: const Color(0xFF10B981),
      ),
      BodyRowData(
        label: 'Công việc',
        value: 'Văn phòng',
        pillColor: const Color(0xFF38BDF8),
      ),
      BodyRowData(label: 'Sức khoẻ đặc biệt', value: 'Không có'),
      BodyRowData(label: 'Cà phê · Rượu bia', value: '1 cốc · 0 đơn vị'),
      BodyRowData(
        label: 'Climate zone',
        value: 'Nhiệt đới (HCMC)',
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
                  const Icon(Icons.edit, color: Color(0xFFBAE6FD), size: 10),
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
            color: AppColors.nightCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          ),
          child: Column(
            children: bodyData.map((data) => _buildBodyRow(data)).toList(),
          ),
        ),
      ],
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
                      color: AppColors.textMuted,
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
          Icon(Icons.chevron_right, color: AppColors.textMuted, size: 14),
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
                  color: AppColors.textMuted,
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
                    color: AppColors.textMuted,
                    fontFamily: 'SF Pro Rounded',
                    fontWeight: FontWeight.w600,
                  ),
                ),
      ],
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
