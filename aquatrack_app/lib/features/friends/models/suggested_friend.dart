/// People-you-may-know entry — a friend-of-friend the backend suggests, ranked
/// by how many friends are shared ("X bạn chung"). Plain model (no codegen) so
/// the suggestion list stays decoupled from the freezed [Friend] contract.
class SuggestedFriend {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final int currentStreak;
  final int mutualFriends;

  const SuggestedFriend({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.currentStreak = 0,
    this.mutualFriends = 0,
  });

  factory SuggestedFriend.fromJson(Map<String, dynamic> json) {
    return SuggestedFriend(
      id: json['id'] as String,
      username: json['username'] as String? ?? '',
      displayName:
          json['display_name'] as String? ?? json['username'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      mutualFriends: (json['mutual_friends'] as num?)?.toInt() ?? 0,
    );
  }
}
