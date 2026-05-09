import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/storage/hive_storage_service.dart';
import '../models/friend_model.dart';
import '../services/social_service.dart';

part 'friends_provider.g.dart';

/// Provider for Social Service dependency injection
@riverpod
SocialService socialService(Ref ref) {
  return SocialService(ApiService());
}

/// Friends state for social hydration tracking
class FriendsState {
  final List<Friend> friends;
  final List<FriendRequest> pendingRequests;
  final List<WeeklyLeaderboardEntry> weeklyLeaderboard;
  final SocialStats socialStats;
  final bool isLoading;
  final String? error;
  final FriendStatusFilter currentFilter;
  final DateTime? updatedAt; // Track when data was last updated

  /// Data is considered stale after 5 minutes
  static const _staleThreshold = Duration(minutes: 5);

  const FriendsState({
    this.friends = const [],
    this.pendingRequests = const [],
    this.weeklyLeaderboard = const [],
    this.socialStats = const SocialStats(
      totalFriends: 0,
      onlineFriends: 0,
      thirstyFriends: 0,
      stressedFriends: 0,
      pendingRequests: 0,
    ),
    this.isLoading = false,
    this.error,
    this.currentFilter = FriendStatusFilter.all,
    this.updatedAt, // Can be null for empty states
  });

  /// Check if cached data is stale (older than 5 minutes)
  bool get isStale {
    if (updatedAt == null) return true; // No timestamp = stale
    return DateTime.now().difference(updatedAt!) > _staleThreshold;
  }

  FriendsState copyWith({
    List<Friend>? friends,
    List<FriendRequest>? pendingRequests,
    List<WeeklyLeaderboardEntry>? weeklyLeaderboard,
    SocialStats? socialStats,
    bool? isLoading,
    String? error,
    FriendStatusFilter? currentFilter,
    DateTime? updatedAt,
    bool clearError = false,
  }) {
    return FriendsState(
      friends: friends ?? this.friends,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      weeklyLeaderboard: weeklyLeaderboard ?? this.weeklyLeaderboard,
      socialStats: socialStats ?? this.socialStats,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentFilter: currentFilter ?? this.currentFilter,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get filtered friends based on current filter
  List<Friend> get filteredFriends {
    switch (currentFilter) {
      case FriendStatusFilter.all:
        return friends;
      case FriendStatusFilter.thirsty:
        return friends.where((f) => f.status == FriendStatus.thirsty).toList();
      case FriendStatusFilter.online:
        return friends.where((f) => f.isOnline).toList();
      case FriendStatusFilter.stressed:
        return friends.where((f) => f.status == FriendStatus.stressed).toList();
    }
  }
}

/// Friend status filter enumeration
enum FriendStatusFilter {
  all,
  thirsty,
  online,
  stressed;

  String get displayName {
    switch (this) {
      case FriendStatusFilter.all:
        return 'Tất cả';
      case FriendStatusFilter.thirsty:
        return 'Đang khát';
      case FriendStatusFilter.online:
        return 'Online';
      case FriendStatusFilter.stressed:
        return 'Đang stress';
    }
  }
}

/// Friends notifier với social features
@riverpod
class FriendsNotifier extends _$FriendsNotifier {
  late final SocialService _socialService;

  @override
  Future<FriendsState> build() async {
    _socialService = ref.read(socialServiceProvider);
    return _loadFriendsData();
  }

  /// Load friends data from API với fallback to local storage
  Future<FriendsState> _loadFriendsData() async {
    try {
      final results = await Future.wait([
        _socialService.getFriends(),
        _socialService.getPendingRequests(),
        _socialService.getWeeklyLeaderboard(),
        _socialService.getSocialStats(),
      ]);

      final friends = results[0] as List<Friend>;
      final requests = results[1] as List<FriendRequest>;
      final leaderboard = results[2] as List<WeeklyLeaderboardEntry>;
      final stats = results[3] as SocialStats;

      // Cache to local storage
      await _cacheFriendsData(friends, requests, leaderboard, stats);

      return FriendsState(
        friends: friends,
        pendingRequests: requests,
        weeklyLeaderboard: leaderboard,
        socialStats: stats,
        updatedAt: DateTime.now(), // Fresh data timestamp
      );
    } catch (e) {
      debugPrint('❌ Failed to load friends from API: $e');

      // Fallback to local storage
      return _loadFromLocalStorage();
    }
  }

  /// Load from local storage when API fails
  Future<FriendsState> _loadFromLocalStorage() async {
    try {
      final storage = HiveStorageService.instance;
      final cachedFriendsData = storage.loadCachedFriends();
      final cachedRequestsData = storage.loadCachedFriendRequests();
      final cachedLeaderboardData =
          storage.loadCachedWeeklyLeaderboard(); // Fix: Load leaderboard
      final cachedStatsData =
          storage.loadCachedSocialStats(); // Fix: Load real stats
      final cachedTimestamp =
          storage.loadCachedSocialDataTimestamp(); // Fix: Load timestamp

      if (cachedFriendsData.isNotEmpty) {
        debugPrint(
            '🏠 FriendsProvider: Loaded cached data with timestamp (friends, requests, leaderboard, stats)');

        // Convert cached data to models
        final cachedFriends =
            cachedFriendsData.map((json) => Friend.fromJson(json)).toList();
        final cachedRequests = cachedRequestsData
            .map((json) => FriendRequest.fromJson(json))
            .toList();
        final cachedLeaderboard = cachedLeaderboardData
            .map((json) => WeeklyLeaderboardEntry.fromJson(json))
            .toList();

        // Use cached stats if available, otherwise compute from friends
        final socialStats = cachedStatsData != null
            ? SocialStats.fromJson(cachedStatsData)
            : SocialStats(
                totalFriends: cachedFriends.length,
                onlineFriends: cachedFriends.where((f) => f.isOnline).length,
                thirstyFriends: cachedFriends
                    .where((f) => f.status == FriendStatus.thirsty)
                    .length,
                stressedFriends: cachedFriends
                    .where((f) => f.status == FriendStatus.stressed)
                    .length,
                pendingRequests: cachedRequests.length,
              );

        return FriendsState(
          friends: cachedFriends,
          pendingRequests: cachedRequests,
          weeklyLeaderboard:
              cachedLeaderboard, // Fix: Include cached leaderboard
          socialStats: socialStats, // Fix: Use real cached stats
          updatedAt:
              cachedTimestamp, // Fix: Include cached timestamp for staleness check
        );
      }

      // Return empty state if no cached data
      return const FriendsState();
    } catch (e) {
      debugPrint('❌ FriendsProvider: Error loading from local storage: $e');
      return const FriendsState(error: 'Failed to load friends data');
    }
  }

  /// Cache friends data to local storage
  Future<void> _cacheFriendsData(
    List<Friend> friends,
    List<FriendRequest> requests,
    List<WeeklyLeaderboardEntry> leaderboard,
    SocialStats stats,
  ) async {
    try {
      final storage = HiveStorageService.instance;
      await storage.cacheFriends(friends);
      await storage.cacheFriendRequests(requests);
      await storage.cacheWeeklyLeaderboard(leaderboard);
      await storage
          .cacheSocialStats(stats.toJson()); // Fix: Add missing stats caching
      await storage
          .cacheSocialDataTimestamp(DateTime.now()); // Fix: Cache timestamp
      debugPrint(
          '💾 FriendsProvider: Cached all social data with timestamp (friends, requests, leaderboard, stats)');
    } catch (e) {
      debugPrint('❌ FriendsProvider: Error caching data: $e');
    }
  }

  /// Send friend request
  Future<bool> sendFriendRequest(String username, {String? message}) async {
    try {
      final success = await _socialService.sendFriendRequest(username, message);

      if (success) {
        // Refresh pending requests
        final requests = await _socialService.getPendingRequests();
        state = AsyncValue.data(
          state.valueOrNull?.copyWith(pendingRequests: requests) ??
              FriendsState(pendingRequests: requests),
        );
      }

      return success;
    } catch (e) {
      debugPrint('❌ FriendsProvider: Error sending friend request: $e');
      return false;
    }
  }

  /// Accept friend request
  Future<bool> acceptFriendRequest(String requestId) async {
    try {
      final success =
          await _socialService.respondToFriendRequest(requestId, accept: true);

      if (success) {
        // Refresh friends data
        await refresh();
      }

      return success;
    } catch (e) {
      debugPrint('❌ FriendsProvider: Error accepting friend request: $e');
      return false;
    }
  }

  /// Decline friend request
  Future<bool> declineFriendRequest(String requestId) async {
    try {
      final success =
          await _socialService.respondToFriendRequest(requestId, accept: false);

      if (success) {
        // Remove from pending requests
        final currentState = state.valueOrNull;
        if (currentState != null) {
          final updatedRequests = currentState.pendingRequests
              .where((req) => req.id != requestId)
              .toList();

          state = AsyncValue.data(
            currentState.copyWith(pendingRequests: updatedRequests),
          );
        }
      }

      return success;
    } catch (e) {
      debugPrint('❌ FriendsProvider: Error declining friend request: $e');
      return false;
    }
  }

  /// Remove friend
  Future<bool> removeFriend(String friendId) async {
    try {
      final success = await _socialService.removeFriend(friendId);

      if (success) {
        // Remove from friends list
        final currentState = state.valueOrNull;
        if (currentState != null) {
          final updatedFriends = currentState.friends
              .where((friend) => friend.id != friendId)
              .toList();

          state = AsyncValue.data(
            currentState.copyWith(friends: updatedFriends),
          );
        }
      }

      return success;
    } catch (e) {
      debugPrint('❌ FriendsProvider: Error removing friend: $e');
      return false;
    }
  }

  /// Send hydration reminder to friend
  Future<bool> sendHydrationReminder(String friendId) async {
    try {
      final success = await _socialService.sendHydrationReminder(friendId);

      if (success) {
        debugPrint('✅ FriendsProvider: Sent reminder to friend $friendId');
      }

      return success;
    } catch (e) {
      debugPrint('❌ FriendsProvider: Error sending reminder: $e');
      return false;
    }
  }

  /// Set filter for friends list
  void setFilter(FriendStatusFilter filter) {
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(currentFilter: filter));
    }
  }

  /// Refresh all friends data
  Future<void> refresh() async {
    state = const AsyncValue.loading();

    try {
      final newData = await _loadFriendsData();
      state = AsyncValue.data(newData);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Search friends by username
  Future<List<Friend>> searchFriends(String query) async {
    try {
      return await _socialService.searchUsers(query);
    } catch (e) {
      debugPrint('❌ FriendsProvider: Error searching friends: $e');
      return [];
    }
  }

  /// Get friend by ID
  Friend? getFriend(String friendId) {
    final currentState = state.valueOrNull;
    if (currentState == null) return null;

    try {
      return currentState.friends.firstWhere((friend) => friend.id == friendId);
    } catch (e) {
      return null;
    }
  }
}
