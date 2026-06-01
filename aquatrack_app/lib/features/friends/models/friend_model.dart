// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'friend_model.freezed.dart';
part 'friend_model.g.dart';

/// Friend user model
@freezed
class Friend with _$Friend {
  const factory Friend({
    required String id,
    required String username,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'hydration_level') required double hydrationLevel,
    @JsonKey(name: 'daily_progress') required double dailyProgress,
    @JsonKey(name: 'current_streak') required int currentStreak,
    @JsonKey(name: 'is_online') required bool isOnline,
    required FriendStatus status,
    @JsonKey(name: 'last_active') DateTime? lastActive,
    @JsonKey(name: 'weekly_rank') int? weeklyRank,
    @JsonKey(name: 'weekly_score') double? weeklyScore,
  }) = _Friend;

  factory Friend.fromJson(Map<String, dynamic> json) => _$FriendFromJson(json);
}

/// Friend request model
@freezed
class FriendRequest with _$FriendRequest {
  const factory FriendRequest({
    required String id,
    @JsonKey(name: 'from_user_id') required String fromUserId,
    @JsonKey(name: 'to_user_id') required String toUserId,
    @JsonKey(name: 'from_user') required Friend fromUser,
    required FriendRequestStatus status,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'responded_at') DateTime? respondedAt,
    String? message,
  }) = _FriendRequest;

  factory FriendRequest.fromJson(Map<String, dynamic> json) =>
      _$FriendRequestFromJson(json);
}

/// Friend status enumeration
@JsonEnum(valueField: 'value')
enum FriendStatus {
  normal('normal'),
  thirsty('thirsty'),
  dry('dry'),
  stressed('stressed'), // retired; kept for backward compatibility
  offline('offline');

  const FriendStatus(this.value);
  final String value;

  /// Get Vietnamese display name
  String get displayName {
    switch (this) {
      case FriendStatus.normal:
        return 'Đủ nước';
      case FriendStatus.thirsty:
        return 'Đang khát';
      case FriendStatus.dry:
        return 'Khô';
      case FriendStatus.stressed:
        return 'Đang stress';
      case FriendStatus.offline:
        return 'Offline';
    }
  }

  /// Get status color
  String get colorHex {
    switch (this) {
      case FriendStatus.normal:
        return '#10B981'; // Green — đủ nước
      case FriendStatus.thirsty:
        return '#F97316'; // Orange — đang khát
      case FriendStatus.dry:
        return '#666666'; // Gray — khô
      case FriendStatus.stressed:
        return '#FFB74D';
      case FriendStatus.offline:
        return '#666666'; // Gray
    }
  }
}

/// Friend request status
@JsonEnum(valueField: 'value')
enum FriendRequestStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined'),
  cancelled('cancelled');

  const FriendRequestStatus(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case FriendRequestStatus.pending:
        return 'Đang chờ';
      case FriendRequestStatus.accepted:
        return 'Đã chấp nhận';
      case FriendRequestStatus.declined:
        return 'Đã từ chối';
      case FriendRequestStatus.cancelled:
        return 'Đã hủy';
    }
  }
}

/// Weekly leaderboard entry
@freezed
class WeeklyLeaderboardEntry with _$WeeklyLeaderboardEntry {
  const factory WeeklyLeaderboardEntry({
    @JsonKey(name: 'user_id') required String userId,
    required String username,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'weekly_score') required double weeklyScore,
    @JsonKey(name: 'hydration_percentage') required double hydrationPercentage,
    @JsonKey(name: 'daily_goal_achieved') required int dailyGoalAchieved,
    @JsonKey(name: 'total_volume_ml') required int totalVolumeMl,
    required int rank,
  }) = _WeeklyLeaderboardEntry;

  factory WeeklyLeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      _$WeeklyLeaderboardEntryFromJson(json);
}

/// Interaction ranking entry ("BẠN TÔI ƠI") — a friend ranked by how much they
/// interact with the current user (incoming reminders + coin gifts), all-time.
@freezed
class InteractionEntry with _$InteractionEntry {
  const factory InteractionEntry({
    @JsonKey(name: 'user_id') required String userId,
    required String username,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'interaction_count') required int interactionCount,
    required int rank,
  }) = _InteractionEntry;

  factory InteractionEntry.fromJson(Map<String, dynamic> json) =>
      _$InteractionEntryFromJson(json);
}

/// Social stats summary
@freezed
class SocialStats with _$SocialStats {
  const factory SocialStats({
    @JsonKey(name: 'total_friends') required int totalFriends,
    @JsonKey(name: 'online_friends') required int onlineFriends,
    @JsonKey(name: 'thirsty_friends') required int thirstyFriends,
    @JsonKey(name: 'stressed_friends') required int stressedFriends,
    @JsonKey(name: 'pending_requests') required int pendingRequests,
    @JsonKey(name: 'my_rank') int? myRank,
    @JsonKey(name: 'my_weekly_score') double? myWeeklyScore,
  }) = _SocialStats;

  factory SocialStats.fromJson(Map<String, dynamic> json) =>
      _$SocialStatsFromJson(json);
}
