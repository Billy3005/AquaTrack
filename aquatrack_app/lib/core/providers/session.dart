import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/body_map/providers/body_map_provider.dart';
import '../../features/coach/providers/coach_chat_provider.dart';
import '../../features/coach/providers/coach_provider.dart';
import '../../features/friends/providers/friends_provider.dart';
import '../../features/friends/providers/notifications_provider.dart';
import '../../features/home/providers/home_provider.dart';
import '../../features/level/providers/level_data_provider.dart';
import '../../features/missions/providers/quests_provider.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../../features/stats/providers/stats_provider.dart';
import 'user_stats_provider.dart';

/// Invalidate every user-scoped data provider so cached data from a previous
/// account can never leak into the next session.
///
/// Non-`autoDispose` Future/Notifier providers keep their last value for the
/// app's lifetime; without this reset, logging into (or registering) a second
/// account in the same session shows the first account's level, achievements,
/// friends, stats, etc. Call this right after a successful login/register and
/// on logout.
void resetUserSession(WidgetRef ref) {
  // Level & XP
  ref.invalidate(levelDataProvider);
  ref.invalidate(userStatsProvider);
  // Profile / avatars / coins
  ref.invalidate(profileNotifierProvider);
  // Home (today's logs + summary)
  ref.invalidate(todayIntakeLogsProvider);
  ref.invalidate(homeNotifierProvider);
  // Missions / quests
  ref.invalidate(questsProvider);
  // Social
  ref.invalidate(friendsNotifierProvider);
  ref.invalidate(notificationsProvider);
  // Stats, coach history, body map
  ref.invalidate(statsNotifierProvider);
  ref.invalidate(coachNotifierProvider);
  ref.invalidate(coachChatNotifierProvider);
  ref.invalidate(bodyMapNotifierProvider);
}
