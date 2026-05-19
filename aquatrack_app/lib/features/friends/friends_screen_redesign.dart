import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/coin_badge.dart';
import 'providers/friends_provider.dart';
import 'models/friend_model.dart';

/// Friends Screen - Social hydration with leaderboard and social actions
class FriendsScreenRedesign extends ConsumerStatefulWidget {
  const FriendsScreenRedesign({super.key});

  @override
  ConsumerState<FriendsScreenRedesign> createState() =>
      _FriendsScreenRedesignState();
}

class _FriendsScreenRedesignState extends ConsumerState<FriendsScreenRedesign>
    with TickerProviderStateMixin {
  String _currentTab = 'friends';
  String? _toastMessage;
  late AnimationController _toastController;
  final Set<String> _remindedFriends = <String>{}; // Track reminded friends

  // Helper methods to map backend data to UI
  Color _getFriendMoodColor(FriendStatus status) {
    switch (status) {
      case FriendStatus.thirsty:
        return const Color(0xFFF97316);
      case FriendStatus.stressed:
        return const Color(0xFFFBBF24);
      case FriendStatus.normal:
        return const Color(0xFF10B981);
      case FriendStatus.offline:
        return const Color(0xFF666666);
    }
  }

  String _getFriendMoodLabel(FriendStatus status) {
    switch (status) {
      case FriendStatus.thirsty:
        return 'Đang khát';
      case FriendStatus.stressed:
        return 'Hơi thấp';
      case FriendStatus.normal:
        return 'Đủ nước';
      case FriendStatus.offline:
        return 'Offline';
    }
  }

  bool _isThirstyOrStressed(FriendStatus status) {
    return status == FriendStatus.thirsty || status == FriendStatus.stressed;
  }

  Color _getAvatarColor(String? avatarUrl, String userId) {
    // Generate color based on user ID if no avatar
    final hash = userId.hashCode;
    final colors = [
      const Color(0xFFFBBF24),
      const Color(0xFFF97316),
      const Color(0xFFA78BFA),
      const Color(0xFF10B981),
      const Color(0xFFEC4899),
      const Color(0xFF06B6D4),
    ];
    return colors[hash.abs() % colors.length];
  }

  String _getLastActiveText(DateTime? lastActive) {
    if (lastActive == null) return 'Chưa rõ';
    final now = DateTime.now();
    final diff = now.difference(lastActive);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else {
      return '${diff.inDays} ngày trước';
    }
  }

  @override
  void initState() {
    super.initState();
    _toastController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _toastController.dispose();
    super.dispose();
  }

  void _showToast(String message) {
    setState(() => _toastMessage = message);
    _toastController.forward();

    Future.delayed(const Duration(seconds: 2), () {
      _toastController.reverse().then((_) {
        if (mounted) {
          setState(() => _toastMessage = null);
        }
      });
    });
  }

  void _nudgeFriend(String friendId) async {
    setState(() {
      _remindedFriends.add(friendId);
    });

    // Send reminder through provider
    final success = await ref
        .read(friendsNotifierProvider.notifier)
        .sendHydrationReminder(friendId);

    if (success) {
      final currentState = ref.read(friendsNotifierProvider).valueOrNull;
      if (currentState != null) {
        final friend = currentState.friends.firstWhere((f) => f.id == friendId);
        final firstName = friend.displayName.split(' ').last;
        _showToast('Đã nhắc $firstName uống nước 💧');
        HapticFeedback.lightImpact();
      }
    } else {
      // Remove from reminded set if failed
      setState(() {
        _remindedFriends.remove(friendId);
      });
      _showToast('Không thể gửi nhắc nhở. Thử lại sau!');
    }
  }

  void _challengeFriend(String friendId) {
    final currentState = ref.read(friendsNotifierProvider).valueOrNull;
    if (currentState != null) {
      final friend = currentState.friends.firstWhere((f) => f.id == friendId);
      final firstName = friend.displayName.split(' ').last;
      _showToast('Đã gửi thách đấu cho $firstName ⚔️');
      HapticFeedback.lightImpact();
    }
  }

  void _acceptFriendRequest(String requestId) async {
    final success = await ref
        .read(friendsNotifierProvider.notifier)
        .acceptFriendRequest(requestId);

    if (success) {
      _showToast('Đã chấp nhận lời mời kết bạn! 🤝');
      HapticFeedback.lightImpact();
    } else {
      _showToast('Không thể chấp nhận lời mời. Thử lại sau!');
    }
  }

  void _declineFriendRequest(String requestId) async {
    final success = await ref
        .read(friendsNotifierProvider.notifier)
        .declineFriendRequest(requestId);

    if (success) {
      _showToast('Đã từ chối lời mời kết bạn');
      HapticFeedback.lightImpact();
    } else {
      _showToast('Không thể từ chối lời mời. Thử lại sau!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsNotifierProvider);

    return friendsAsync.when(
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error.toString()),
      data: (friendsState) => _buildMainContent(friendsState),
    );
  }

  Widget _buildMainContent(FriendsState friendsState) {
    return Scaffold(
      backgroundColor: AppColors.nightBase,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(friendsState),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  child: _currentTab == 'friends'
                      ? _buildFriendsTab(friendsState)
                      : _buildRequestsTab(friendsState),
                ),
              ),
            ],
          ),
          if (_toastMessage != null) _buildToast(),
        ],
      ),
    );
  }

  Widget _buildHeader(FriendsState friendsState) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0C2A4A), Color(0xFF0B1120)],
        ),
      ),
      child: Stack(
        children: [
          // Background decoration
          Positioned(
            top: -50,
            right: -30,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF38BDF8).withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coin badge row
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [CoinBadge(amount: 1240)],
                  ),
                  const SizedBox(height: 4),

                  // Title row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BẠN BÈ',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textBright,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Cùng giữ nhịp uống',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.02,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildHeaderButton(Icons.search, false),
                          const SizedBox(width: 8),
                          _buildHeaderButton(Icons.add, true),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Tab selector
                  _buildTabSelector(friendsState),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(IconData icon, bool isPrimary) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: isPrimary
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
              )
            : null,
        color: isPrimary ? null : Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          color: isPrimary
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.08),
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Icon(icon, color: Colors.white, size: isPrimary ? 14 : 14),
    );
  }

  Widget _buildTabSelector(FriendsState friendsState) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTab('friends', 'Bạn bè · ${friendsState.friends.length}'),
          const SizedBox(width: 4),
          _buildTab(
            'requests',
            'Lời mời · ${friendsState.pendingRequests.length}',
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String id, String label) {
    final isActive = _currentTab == id;
    return GestureDetector(
      onTap: () {
        setState(() => _currentTab = id);
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF38BDF8).withValues(alpha: 0.18)
              : Colors.transparent,
          border: Border.all(
            color: isActive
                ? const Color(0xFF38BDF8).withValues(alpha: 0.35)
                : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? AppColors.textBright : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsTab(FriendsState friendsState) {
    // Sort friends by status priority (thirsty > stressed > normal > offline)
    final sortedFriends = List<Friend>.from(friendsState.friends)
      ..sort((a, b) {
        final priorityA = a.status == FriendStatus.thirsty
            ? 0
            : a.status == FriendStatus.stressed
            ? 1
            : a.status == FriendStatus.normal
            ? 2
            : 3;
        final priorityB = b.status == FriendStatus.thirsty
            ? 0
            : b.status == FriendStatus.stressed
            ? 1
            : b.status == FriendStatus.normal
            ? 2
            : 3;
        return priorityA.compareTo(priorityB);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWeeklyPodium(friendsState),
        const SizedBox(height: 16),
        _buildFilterChips(friendsState),
        const SizedBox(height: 12),
        _buildSectionHeader(),
        const SizedBox(height: 8),
        ...sortedFriends.map(
          (friend) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildFriendCard(friend),
          ),
        ),
        const SizedBox(height: 16),
        _buildGroupChallengeBanner(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildWeeklyPodium(FriendsState friendsState) {
    final topThree = friendsState.weeklyLeaderboard.take(3).toList();
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromRGBO(251, 191, 36, 0.10),
            Color.fromRGBO(168, 85, 247, 0.06),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFFBBF24).withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.emoji_events,
                    color: Color(0xFFFBBF24),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'TUẦN NÀY',
                    style: TextStyle(
                      fontSize: 11,
                      color: const Color(0xFFFCD34D),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.08,
                    ),
                  ),
                ],
              ),
              Text(
                'Còn 2 ngày',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (topThree.length >= 3)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 2nd place
                _buildPodiumPosition(2, topThree[1], 62, '🥈'),
                const SizedBox(width: 10),
                // 1st place
                _buildPodiumPosition(1, topThree[0], 84, '🥇'),
                const SizedBox(width: 10),
                // 3rd place
                _buildPodiumPosition(3, topThree[2], 48, '🥉'),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPodiumPosition(
    int rank,
    WeeklyLeaderboardEntry entry,
    double height,
    String medal,
  ) {
    final ringColor = rank == 1
        ? const Color(0xFFFBBF24)
        : rank == 2
        ? const Color(0xFFCBD5E1)
        : const Color(0xFFD97706);
    final size = rank == 1 ? 56.0 : 46.0;

    return Expanded(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.7, -0.7),
                    colors: [
                      _getAvatarColor(
                        entry.avatarUrl,
                        entry.userId,
                      ).withValues(alpha: 0.93),
                      _getAvatarColor(
                        entry.avatarUrl,
                        entry.userId,
                      ).withValues(alpha: 0.53),
                    ],
                  ),
                  border: Border.all(color: ringColor, width: 2),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: rank == 1
                      ? [
                          BoxShadow(
                            color: ringColor.withValues(alpha: 0.53),
                            blurRadius: 16,
                          ),
                        ]
                      : null,
                ),
                child: const Icon(
                  Icons.water_drop,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              Positioned(
                top: -8,
                right: -8,
                child: Text(
                  medal,
                  style: TextStyle(fontSize: rank == 1 ? 18 : 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 80,
            child: Text(
              entry.displayName.split(' ').last,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: rank == 1
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        ringColor.withValues(alpha: 0.20),
                        ringColor.withValues(alpha: 0.07),
                      ],
                    )
                  : null,
              color: rank == 1 ? null : Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                color: rank == 1
                    ? ringColor.withValues(alpha: 0.27)
                    : Colors.white.withValues(alpha: 0.08),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${entry.hydrationPercentage.toInt()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.01,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(FriendsState friendsState) {
    final chips = [
      FilterChip(
        id: 'all',
        label: 'Tất cả',
        count: friendsState.friends.length,
        active: true,
      ),
      FilterChip(
        id: 'low',
        label: 'Đang khát',
        count: friendsState.friends
            .where(
              (f) =>
                  f.status == FriendStatus.thirsty ||
                  f.status == FriendStatus.stressed,
            )
            .length,
        color: const Color(0xFFF97316),
      ),
      FilterChip(
        id: 'on',
        label: 'Online',
        count: friendsState.friends.where((f) => f.isOnline).length,
        color: const Color(0xFF10B981),
      ),
      FilterChip(
        id: 'streak',
        label: 'Đang streak',
        count: friendsState.friends.where((f) => f.currentStreak > 5).length,
        color: const Color(0xFFA78BFA),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips
            .map(
              (chip) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _buildFilterChip(chip),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildFilterChip(FilterChip chip) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chip.active
            ? const Color(0xFF38BDF8).withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: chip.active
              ? const Color(0xFF38BDF8).withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.06),
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (chip.color != null) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: chip.color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            chip.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: chip.active
                  ? AppColors.textBright
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${chip.count}',
            style: TextStyle(
              fontSize: 11,
              color:
                  (chip.active ? AppColors.textBright : AppColors.textSecondary)
                      .withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'BẠN BÈ',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              letterSpacing: 0.08,
              fontWeight: FontWeight.w600,
            ),
          ),
          RichText(
            text: TextSpan(
              text: 'Sắp theo: ',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              children: [
                TextSpan(
                  text: 'cần nhắc',
                  style: TextStyle(
                    color: const Color(0xFF7DD3FC),
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

  Widget _buildFriendCard(Friend friend) {
    final moodColor = _getFriendMoodColor(friend.status);
    final moodLabel = _getFriendMoodLabel(friend.status);
    final isThirsty = _isThirstyOrStressed(friend.status);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.nightSurface,
        border: Border.all(
          color: friend.status == FriendStatus.thirsty
              ? const Color(0xFFF97316).withValues(alpha: 0.3)
              : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          // Hot glow for thirsty friends
          if (friend.status == FriendStatus.thirsty)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-1.0, 0.0),
                    colors: [
                      const Color(0xFFF97316).withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Friend info row
                Row(
                  children: [
                    _buildAvatar(friend),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name and streak
                          Row(
                            children: [
                              Text(
                                friend.displayName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: -0.01,
                                ),
                              ),
                              if (friend.currentStreak >= 7) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFF97316,
                                    ).withValues(alpha: 0.12),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFF97316,
                                      ).withValues(alpha: 0.3),
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '🔥 ${friend.currentStreak}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFFB923C),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),

                          // Mood and last drink
                          Row(
                            children: [
                              Text(
                                moodLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: moodColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                ' · ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              Text(
                                _getLastActiveText(friend.lastActive),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Progress bar
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Stack(
                                    children: [
                                      Container(
                                        height: 5,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.05,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                      ),
                                      FractionallySizedBox(
                                        widthFactor: friend.dailyProgress,
                                        child: Container(
                                          height: 5,
                                          decoration: BoxDecoration(
                                            gradient: _getProgressGradient(
                                              friend.status,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            boxShadow:
                                                friend.status ==
                                                    FriendStatus.normal
                                                ? [
                                                    BoxShadow(
                                                      color: const Color(
                                                        0xFF38BDF8,
                                                      ).withValues(alpha: 0.6),
                                                      blurRadius: 8,
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 32,
                                child: Text(
                                  '${(friend.dailyProgress * 100).toInt()}%',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.01,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    Expanded(child: _buildNudgeButton(friend)),
                    const SizedBox(width: 6),
                    _buildChallengeButton(friend),
                    const SizedBox(width: 6),
                    _buildMenuButton(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getProgressGradient(FriendStatus status) {
    switch (status) {
      case FriendStatus.thirsty:
        return const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFFB923C)],
        );
      case FriendStatus.stressed:
        return const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
        );
      case FriendStatus.normal:
        return const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
        );
      case FriendStatus.offline:
        return const LinearGradient(
          colors: [Color(0xFF666666), Color(0xFF888888)],
        );
    }
  }

  Widget _buildAvatar(Friend friend) {
    final avatarColor = _getAvatarColor(friend.avatarUrl, friend.id);
    return Stack(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.7, -0.7),
              colors: [
                avatarColor.withValues(alpha: 0.93),
                avatarColor.withValues(alpha: 0.53),
              ],
            ),
            border: Border.all(
              color: avatarColor.withValues(alpha: 0.33),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: avatarColor.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.water_drop, color: Colors.white, size: 22),
        ),
        // Level badge (placeholder - no level in backend model)
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B4B),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.nightBase, width: 1.5),
            ),
            child: Text(
              '${friend.currentStreak}', // Show streak as level alternative
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(0xFFC7D2FE),
                letterSpacing: 0.04,
              ),
            ),
          ),
        ),
        // Online indicator
        if (friend.isOnline)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.nightBase, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNudgeButton(Friend friend) {
    final isReminded = _remindedFriends.contains(friend.id);
    final isThirsty = _isThirstyOrStressed(friend.status);

    return GestureDetector(
      onTap: isReminded ? null : () => _nudgeFriend(friend.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          gradient: isReminded
              ? null
              : isThirsty
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF38BDF8).withValues(alpha: 0.22),
                    const Color(0xFF0EA5E9).withValues(alpha: 0.16),
                  ],
                )
              : null,
          color: isReminded
              ? const Color(0xFF10B981).withValues(alpha: 0.10)
              : !isThirsty
              ? const Color(0xFF38BDF8).withValues(alpha: 0.10)
              : null,
          border: Border.all(
            color: isReminded
                ? const Color(0xFF10B981).withValues(alpha: 0.3)
                : const Color(0xFF38BDF8).withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isReminded ? Icons.check : Icons.notifications,
              color: isReminded
                  ? const Color(0xFF86EFAC)
                  : AppColors.textBright,
              size: 13,
            ),
            const SizedBox(width: 5),
            Text(
              isReminded ? 'Đã nhắc' : 'Nhắc uống nước',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isReminded
                    ? const Color(0xFF86EFAC)
                    : AppColors.textBright,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeButton(Friend friend) {
    return GestureDetector(
      onTap: () => _challengeFriend(friend.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFA855F7).withValues(alpha: 0.10),
          border: Border.all(
            color: const Color(0xFFA855F7).withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚔️', style: TextStyle(fontSize: 11)),
            const SizedBox(width: 5),
            Text(
              'Đua',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFDDD6FE),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton() {
    return Container(
      width: 36,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.more_horiz, color: AppColors.textSecondary, size: 14),
    );
  }

  Widget _buildGroupChallengeBanner() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFA855F7).withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFA78BFA), Color(0xFF6366F1)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thách đấu nhóm',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Tạo cuộc đua 7 ngày · thưởng XP gấp đôi',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFC4B5FD),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFA855F7).withValues(alpha: 0.18),
                border: Border.all(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.4),
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Tạo',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFDDD6FE),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsTab(FriendsState friendsState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LỜI MỜI MỚI',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            letterSpacing: 0.08,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...friendsState.pendingRequests.map(
          (request) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildRequestCard(request),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'CÓ THỂ BẠN BIẾT',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            letterSpacing: 0.08,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildSuggestedFriend(
          'Khánh Lê',
          '@khanhle',
          6,
          5,
          const Color(0xFF0EA5E9),
        ),
        const SizedBox(height: 8),
        _buildSuggestedFriend(
          'Trang Phạm',
          '@trangp',
          10,
          2,
          const Color(0xFFFB7185),
        ),
        const SizedBox(height: 8),
        _buildSuggestedFriend('An Đỗ', '@ando', 3, 8, const Color(0xFF34D399)),
      ],
    );
  }

  Widget _buildRequestCard(FriendRequest request) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.nightSurface,
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.18),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildRequestAvatar(request),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.fromUser.displayName,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '@${request.fromUser.username}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _acceptFriendRequest(request.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                ),
                borderRadius: BorderRadius.all(Radius.circular(999)),
              ),
              child: const Text(
                'Chấp nhận',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _declineFriendRequest(request.id),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                Icons.close,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestAvatar(FriendRequest request) {
    final avatarColor = _getAvatarColor(
      request.fromUser.avatarUrl,
      request.fromUser.id,
    );
    return Stack(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.7, -0.7),
              colors: [
                avatarColor.withValues(alpha: 0.93),
                avatarColor.withValues(alpha: 0.53),
              ],
            ),
            border: Border.all(
              color: avatarColor.withValues(alpha: 0.33),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: avatarColor.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.water_drop, color: Colors.white, size: 20),
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B4B),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.nightBase, width: 1.5),
            ),
            child: Text(
              '${request.fromUser.currentStreak}',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(0xFFC7D2FE),
                letterSpacing: 0.04,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestedFriend(
    String name,
    String handle,
    int level,
    int mutual,
    Color avatar,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.nightCard,
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.7, -0.7),
                colors: [
                  avatar.withValues(alpha: 0.93),
                  avatar.withValues(alpha: 0.53),
                ],
              ),
              border: Border.all(
                color: avatar.withValues(alpha: 0.33),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: avatar.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.water_drop, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '$mutual bạn chung',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
              border: Border.all(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '+ Kết bạn',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textBright,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToast() {
    return AnimatedBuilder(
      animation: _toastController,
      builder: (context, child) {
        return Positioned(
          left: 0,
          right: 0,
          bottom: 100 + (16 * (1 - _toastController.value)),
          child: Opacity(
            opacity: _toastController.value,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Text(
                  _toastMessage!,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textBright,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: AppColors.nightBase,
      body: Column(
        children: [
          _buildHeader(const FriendsState()),
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF38BDF8)),
                  SizedBox(height: 16),
                  Text(
                    'Đang tải danh sách bạn bè...',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Scaffold(
      backgroundColor: AppColors.nightBase,
      body: Column(
        children: [
          _buildHeader(const FriendsState()),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: const Color(0xFFF97316),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Lỗi tải dữ liệu',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => ref.refresh(friendsNotifierProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper classes for UI
class FilterChip {
  final String id;
  final String label;
  final int count;
  final bool active;
  final Color? color;

  const FilterChip({
    required this.id,
    required this.label,
    required this.count,
    this.active = false,
    this.color,
  });
}
