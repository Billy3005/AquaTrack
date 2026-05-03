import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/models/user.dart';
import '../../core/utils/logger.dart';

/// Profile Screen - User info, settings, logout
class ProfileScreenV2 extends ConsumerStatefulWidget {
  const ProfileScreenV2({super.key});

  @override
  ConsumerState<ProfileScreenV2> createState() => _ProfileScreenV2State();
}

class _ProfileScreenV2State extends ConsumerState<ProfileScreenV2> {
  final _authRepository = AuthRepository();

  User? _currentUser;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      _currentUser = await _authRepository.getCurrentUser();

      setState(() {
        _isLoading = false;
      });

      AppLogger.info('ProfileV2', 'User data loaded: ${_currentUser?.email}');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      AppLogger.error('ProfileV2', 'Failed to load user data', e);
    }
  }

  Future<void> _logout() async {
    // Show confirmation dialog
    final confirmed = await _showLogoutConfirmation();
    if (!confirmed) return;

    try {
      await _authRepository.logout();
      if (mounted) {
        context.go('/login');
      }
      AppLogger.info('ProfileV2', 'User logged out successfully');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đăng xuất: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      AppLogger.error('ProfileV2', 'Logout failed', e);
    }
  }

  Future<bool> _showLogoutConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Đăng xuất'),
            content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Đăng xuất'),
              ),
            ],
          ),
        ) ??
        false;
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
            'Đang tải thông tin...',
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 32),

          // User info card
          _buildUserInfoCard(),
          const SizedBox(height: 24),

          // Settings section
          _buildSettingsSection(),
          const SizedBox(height: 24),

          // App info section
          _buildAppInfoSection(),
          const SizedBox(height: 32),

          // Logout button
          _buildLogoutButton(),

          const SizedBox(height: 32),
        ],
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
              onPressed: _loadUserData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          'Tài khoản',
          style: AppTextStyles.displayMedium,
        ),
        const Spacer(),
        IconButton(
          onPressed: () => context.push('/profile/edit'),
          icon: const Icon(
            Icons.edit,
            color: AppColors.cyanAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cyanAccent.withValues(alpha: 0.2),
        ),
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
            child: Center(
              child: Text(
                _getAvatarText(),
                style: AppTextStyles.displaySmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            _currentUser?.fullName ?? 'Người dùng AquaTrack',
            style: AppTextStyles.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Email
          Text(
            _currentUser?.email ?? 'No email',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // User stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'Level',
                value: '${_currentUser?.level ?? 1}',
                color: AppColors.purpleXP,
              ),
              _StatItem(
                label: 'XP',
                value: '${_currentUser?.totalXp ?? 0}',
                color: AppColors.cyanAccent,
              ),
              _StatItem(
                label: 'Streak',
                value: '5', // Mock data
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cài đặt',
          style: AppTextStyles.headlineSmall,
        ),
        const SizedBox(height: 16),
        _SettingItem(
          icon: Icons.water_drop,
          title: 'Mục tiêu hàng ngày',
          subtitle: '2000ml',
          onTap: () {
            // TODO: Open goal setting
          },
        ),
        _SettingItem(
          icon: Icons.notifications,
          title: 'Thông báo',
          subtitle: 'Nhắc nhở uống nước',
          onTap: () {
            // TODO: Open notification settings
          },
        ),
        _SettingItem(
          icon: Icons.palette,
          title: 'Giao diện',
          subtitle: 'Dark Mode',
          onTap: () {
            // TODO: Open theme settings
          },
        ),
        _SettingItem(
          icon: Icons.backup,
          title: 'Đồng bộ dữ liệu',
          subtitle: 'Sao lưu thông tin',
          onTap: () {
            // TODO: Open backup settings
          },
        ),
      ],
    );
  }

  Widget _buildAppInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Về ứng dụng',
          style: AppTextStyles.headlineSmall,
        ),
        const SizedBox(height: 16),
        _SettingItem(
          icon: Icons.help,
          title: 'Hướng dẫn',
          subtitle: 'Cách sử dụng AquaTrack',
          onTap: () {
            // TODO: Open help
          },
        ),
        _SettingItem(
          icon: Icons.privacy_tip,
          title: 'Chính sách bảo mật',
          subtitle: 'Xem chính sách',
          onTap: () {
            // TODO: Open privacy policy
          },
        ),
        _SettingItem(
          icon: Icons.info,
          title: 'Phiên bản',
          subtitle: '1.0.0',
          onTap: () {
            // TODO: Show about dialog
          },
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return OutlinedButton.icon(
      onPressed: _logout,
      icon: const Icon(Icons.logout),
      label: const Text('Đăng xuất'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: const BorderSide(color: AppColors.error),
        minimumSize: const Size(double.infinity, 52),
      ),
    );
  }

  String _getAvatarText() {
    final name = _currentUser?.fullName ?? _currentUser?.email ?? 'U';
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }
}

/// Stat item widget for user stats
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headlineMedium.copyWith(color: color),
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
}

/// Setting item widget
class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.borderColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cyanAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppColors.cyanAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
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
