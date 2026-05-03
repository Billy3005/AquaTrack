import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/repositories/intake_repository.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/models/user.dart';
import '../../core/utils/logger.dart';

/// Home Screen - Living Drop với real backend integration
class HomeScreenV2 extends ConsumerStatefulWidget {
  const HomeScreenV2({super.key});

  @override
  ConsumerState<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends ConsumerState<HomeScreenV2> {
  final _intakeRepository = IntakeRepository();
  final _authRepository = AuthRepository();

  User? _currentUser;
  int _todayIntakeMl = 0;
  int _dailyGoalMl = 2000; // Default goal
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load user data
      _currentUser = await _authRepository.getCurrentUser();

      // Load today's summary
      final summary = await _intakeRepository.getTodaySummary();
      _todayIntakeMl = summary.totalVolumeMl;

      setState(() {
        _isLoading = false;
      });

      AppLogger.info('HomeV2', 'Data loaded: ${_todayIntakeMl}ml today');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      AppLogger.error('HomeV2', 'Failed to load data', e);
    }
  }

  Future<void> _quickLog(int amount) async {
    try {
      HapticFeedback.mediumImpact();

      final intakeLog = await _intakeRepository.quickLogWater(amount);

      // Update local state
      setState(() {
        _todayIntakeMl += amount;
      });

      // Success feedback
      HapticFeedback.lightImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã ghi nhận ${amount}ml nước!'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      AppLogger.info('HomeV2', 'Quick logged ${amount}ml: ${intakeLog.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi ghi nhận: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      AppLogger.error('HomeV2', 'Quick log failed', e);
    }
  }

  Future<void> _logout() async {
    try {
      await _authRepository.logout();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      AppLogger.error('HomeV2', 'Logout failed', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: _isLoading ? _buildLoading() : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.cyanAccent),
          SizedBox(height: 16),
          Text(
            'Đang tải dữ liệu...',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return _buildError();
    }

    final progress = _todayIntakeMl / _dailyGoalMl;
    final progressClamped = progress.clamp(0.0, 1.0);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với user info
            _buildHeader(),
            const SizedBox(height: 32),

            // Greeting
            _buildGreeting(),
            const SizedBox(height: 40),

            // Living Drop (simplified)
            _buildLivingDrop(progressClamped),
            const SizedBox(height: 40),

            // Progress info
            _buildProgressInfo(),
            const SizedBox(height: 32),

            // Quick log buttons
            _buildQuickLogSection(),
            const SizedBox(height: 32),

            // Action cards
            _buildActionCards(),

            // Add bottom padding for better scrolling
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Có lỗi xảy ra',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentUser?.fullName ?? _currentUser?.email ?? 'User',
              style: AppTextStyles.titleLarge,
            ),
            Text(
              'Hôm nay bạn thế nào?',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '🔥 Streak 5 ngày',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.cyanAccent,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _logout,
              icon: const Icon(
                Icons.logout,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    String greeting;

    if (hour < 12) {
      greeting = 'CHÀO BUỔI SÁNG';
    } else if (hour < 17) {
      greeting = 'CHÀO BUỔI CHIỀU';
    } else {
      greeting = 'CHÀO BUỔI TỐI';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.cyanAccent,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Hãy tiếp tục giữ nhịp hydration nhé!',
          style: AppTextStyles.headlineLarge,
        ),
      ],
    );
  }

  Widget _buildLivingDrop(double progress) {
    return Center(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          // TODO: Show drop detail modal
        },
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColors.dropGradientStart.withValues(alpha: 0.3),
                AppColors.dropGradientEnd.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyanAccent.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Drop background
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceColor.withValues(alpha: 0.5),
                ),
              ),

              // Progress fill
              ClipOval(
                child: Container(
                  width: 160,
                  height: 160,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Water fill
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 800),
                        width: 160,
                        height: 160 * progress,
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                        ),
                      ),

                      // Drop icon
                      const Icon(
                        Icons.water_drop,
                        size: 60,
                        color: AppColors.textPrimary,
                      ),
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

  Widget _buildProgressInfo() {
    final progress = (_todayIntakeMl / _dailyGoalMl * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_todayIntakeMl ml',
                style: AppTextStyles.waterAmount.copyWith(fontSize: 32),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Mục tiêu: $_dailyGoalMl ml',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '$progress% hoàn thành',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.borderColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (_todayIntakeMl / _dailyGoalMl).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLogSection() {
    final amounts = [150, 250, 350, 500];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Log',
          style: AppTextStyles.headlineMedium,
        ),
        const SizedBox(height: 16),
        Row(
          children: amounts.map((amount) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: amount == amounts.last ? 0 : 12,
                ),
                child: _QuickLogButton(
                  label: '${amount}ml',
                  onTap: () => _quickLog(amount),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/log-drink'),
            icon: const Icon(Icons.add),
            label: const Text('Ghi nhận khác'),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tiếp theo',
          style: AppTextStyles.headlineMedium,
        ),
        const SizedBox(height: 16),

        // AI Coach card
        _ActionCard(
          icon: Icons.psychology,
          title: 'AQUA AI Coach',
          subtitle: 'Tiến độ tốt! Nhớ uống thêm vào buổi chiều nhé.',
          color: AppColors.cyanLight,
          onTap: () => context.push('/coach'),
        ),
        const SizedBox(height: 12),

        // Stats card
        _ActionCard(
          icon: Icons.analytics,
          title: 'Xem thống kê',
          subtitle: 'Phân tích xu hướng hydration của bạn',
          color: AppColors.purpleXP,
          onTap: () => context.push('/stats'),
        ),
      ],
    );
  }
}

/// Quick log button widget
class _QuickLogButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickLogButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.cyanAccent.withValues(alpha: 0.3),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.buttonTextMedium.copyWith(
              color: AppColors.cyanAccent,
            ),
          ),
        ),
      ),
    );
  }
}

/// Action card widget
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textTertiary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
