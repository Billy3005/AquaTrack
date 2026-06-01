import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/friend_model.dart';
import '../providers/friends_provider.dart';
import '../widgets/friend_card.dart';
import '../widgets/friend_search.dart';
import '../widgets/status_filters.dart';
import '../widgets/weekly_leaderboard.dart';

/// Friends screen with social hydration tracking
class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsState = ref.watch(friendsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Friends/Invites tabs
            _buildTabHeader(ref, friendsState),

            // Content
            Expanded(
              child: friendsState.when(
                data: (state) => _buildContent(context, ref, state),
                loading: () => _buildLoadingState(),
                error: (error, stack) => _buildErrorState(ref, error),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  /// Build header with title and search
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BẠN BÈ',
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Cùng giữ nhịp uống',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () => _navigateToSearch(context),
            icon: const Icon(
              Icons.search,
              color: AppColors.textSecondary,
              size: 24,
            ),
          ),
          IconButton(
            onPressed: () => _showAddFriendOptions(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cyanAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.primaryBackground,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build tab header for Friends/Invitations
  Widget _buildTabHeader(WidgetRef ref, AsyncValue<FriendsState> friendsState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildTabButton(
            'Bạn bè',
            friendsState.valueOrNull?.friends.length ?? 0,
            true,
            () {},
          ),
          const SizedBox(width: 20),
          _buildTabButton(
            'Lời mời',
            friendsState.valueOrNull?.pendingRequests.length ?? 0,
            false,
            () => _showPendingRequests(ref, friendsState),
          ),
        ],
      ),
    );
  }

  /// Build individual tab button
  Widget _buildTabButton(
    String title,
    int count,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.cyanAccent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color:
                    isActive ? AppColors.cyanAccent : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      isActive ? AppColors.cyanAccent : AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isActive
                        ? AppColors.primaryBackground
                        : AppColors.surfaceColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build main content
  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    FriendsState state,
  ) {
    return RefreshIndicator(
      onRefresh: () => ref.read(friendsNotifierProvider.notifier).refresh(),
      color: AppColors.cyanAccent,
      backgroundColor: AppColors.surfaceColor,
      child: CustomScrollView(
        slivers: [
          // Weekly leaderboard
          if (state.weeklyLeaderboard.isNotEmpty)
            SliverToBoxAdapter(
              child: WeeklyLeaderboard(entries: state.weeklyLeaderboard),
            ),

          // Status filters
          const SliverToBoxAdapter(child: StatusFilters()),

          // Friends section header
          SliverToBoxAdapter(child: _buildFriendsHeader(state)),

          // Friends list
          _buildFriendsList(state),
        ],
      ),
    );
  }

  /// Build friends section header
  Widget _buildFriendsHeader(FriendsState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Text(
            'BẠN BÈ',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          Text(
            'Sắp thoát • Cần nước',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  /// Build friends list
  Widget _buildFriendsList(FriendsState state) {
    final filteredFriends = state.filteredFriends;

    if (filteredFriends.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyFriendsList(state.currentFilter),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final friend = filteredFriends[index];
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: index == filteredFriends.length - 1 ? 100 : 0,
          ),
          child: FriendCard(
            friend: friend,
            onTap: () => _showFriendProfile(friend),
          ),
        );
      }, childCount: filteredFriends.length),
    );
  }

  /// Build empty friends list
  Widget _buildEmptyFriendsList(FriendStatusFilter filter) {
    String title;
    String subtitle;
    IconData icon;

    switch (filter) {
      case FriendStatusFilter.all:
        title = 'Chưa có bạn bè';
        subtitle = 'Mời bạn bè để bắt đầu thi đấu hydration!';
        icon = Icons.people_outline;
        break;
      case FriendStatusFilter.thirsty:
        title = 'Không có bạn nào đang khát';
        subtitle = 'Tất cả bạn bè đang hydrate tốt! 💧';
        icon = Icons.water_drop;
        break;
      case FriendStatusFilter.online:
        title = 'Không có bạn nào online';
        subtitle = 'Hãy quay lại sau để xem ai đang hoạt động';
        icon = Icons.circle;
        break;
      case FriendStatusFilter.dry:
        title = 'Không có bạn nào bị khô';
        subtitle = 'Mọi người đều đã uống nước hôm nay! 💧';
        icon = Icons.opacity;
        break;
      case FriendStatusFilter.stressed:
        title = 'Không có bạn nào đang stress';
        subtitle = 'Mọi người đều rất chill! 😌';
        icon = Icons.psychology;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.cyanAccent),
          SizedBox(height: 16),
          Text('Đang tải danh sách bạn bè...', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Không thể tải danh sách bạn bè',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  ref.read(friendsNotifierProvider.notifier).refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyanAccent,
                foregroundColor: AppColors.primaryBackground,
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build floating action button
  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _navigateToSearch(context),
      backgroundColor: AppColors.cyanAccent,
      foregroundColor: AppColors.primaryBackground,
      child: const Icon(Icons.person_add),
    );
  }

  /// Navigate to friend search
  void _navigateToSearch(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const FriendSearch()));
  }

  /// Show add friend options
  void _showAddFriendOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Thêm bạn bè',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.search, color: AppColors.cyanAccent),
              title: const Text('Tìm kiếm bằng tên'),
              onTap: () {
                Navigator.of(context).pop();
                _navigateToSearch(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code, color: AppColors.cyanAccent),
              title: const Text('Chia sẻ mã QR'),
              onTap: () {
                Navigator.of(context).pop();
                _shareQRCode();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link, color: AppColors.cyanAccent),
              title: const Text('Chia sẻ liên kết'),
              onTap: () {
                Navigator.of(context).pop();
                _shareInviteLink();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Show pending friend requests
  void _showPendingRequests(
    WidgetRef ref,
    AsyncValue<FriendsState> friendsState,
  ) {
    // TODO: Implement pending requests modal
    debugPrint('Show pending requests');
  }

  /// Show friend profile
  void _showFriendProfile(Friend friend) {
    // TODO: Implement friend profile screen
    debugPrint('Show profile for ${friend.displayName}');
  }

  /// Share QR code
  void _shareQRCode() {
    // TODO: Implement QR code sharing
    debugPrint('Share QR code');
  }

  /// Share invite link
  void _shareInviteLink() {
    // TODO: Implement invite link sharing
    debugPrint('Share invite link');
  }
}
