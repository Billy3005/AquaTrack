/// Plain models for the notifications inbox and friend races (cuộc đua).
/// Hand-written (no codegen) to keep the feature self-contained.

/// Type of social notification shown in the bell inbox.
enum FriendNotificationType { reminder, challenge }

/// A single notification item from the backend (/friends/notifications/).
class AppNotification {
  final String id;
  final FriendNotificationType type;
  final String senderName;
  final String message;
  final DateTime? createdAt;
  final bool isRead;

  /// Set when [type] is [FriendNotificationType.challenge].
  final String? challengeId;
  final String? challengeStatus; // pending | active | completed | declined

  const AppNotification({
    required this.id,
    required this.type,
    required this.senderName,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.challengeId,
    this.challengeStatus,
  });

  /// True when this is a pending invite the user can accept/decline.
  bool get isPendingInvite =>
      type == FriendNotificationType.challenge && challengeStatus == 'pending';

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'reminder';
    return AppNotification(
      id: json['id'] as String,
      type: typeStr == 'challenge'
          ? FriendNotificationType.challenge
          : FriendNotificationType.reminder,
      senderName: json['sender_name'] as String? ?? 'Một người bạn',
      message: json['message'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      isRead: json['is_read'] as bool? ?? false,
      challengeId: json['challenge_id'] as String?,
      challengeStatus: json['challenge_status'] as String?,
    );
  }
}

/// A head-to-head hydration race (/friends/challenges/).
class HydrationChallenge {
  final String id;
  final String status; // pending | active | completed | declined
  final String opponentName;
  final String opponentUsername;
  final bool isChallenger;
  final int durationDays;
  final String? message;
  final int myScoreMl;
  final int opponentScoreMl;
  final DateTime? endsAt;

  const HydrationChallenge({
    required this.id,
    required this.status,
    required this.opponentName,
    required this.opponentUsername,
    required this.isChallenger,
    required this.durationDays,
    required this.myScoreMl,
    required this.opponentScoreMl,
    this.message,
    this.endsAt,
  });

  bool get isActive => status == 'active';
  bool get isWinning => myScoreMl >= opponentScoreMl;

  factory HydrationChallenge.fromJson(Map<String, dynamic> json) {
    return HydrationChallenge(
      id: json['id'] as String,
      status: json['status'] as String? ?? 'pending',
      opponentName: json['opponent_name'] as String? ?? 'Một người bạn',
      opponentUsername: json['opponent_username'] as String? ?? '',
      isChallenger: json['is_challenger'] as bool? ?? false,
      durationDays: json['duration_days'] as int? ?? 7,
      message: json['message'] as String?,
      myScoreMl: json['my_score_ml'] as int? ?? 0,
      opponentScoreMl: json['opponent_score_ml'] as int? ?? 0,
      endsAt: json['ends_at'] != null
          ? DateTime.tryParse(json['ends_at'] as String)
          : null,
    );
  }
}
