import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/storage/hive_storage_service.dart';
import '../models/notification_models.dart';
import 'friends_provider.dart';

/// Notifications inbox: reminders received + challenge invites/results.
final notificationsProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  final service = ref.read(socialServiceProvider);
  return service.getNotifications();
});

/// The user's hydration races (cuộc đua) with live, derived scores.
final challengesProvider =
    FutureProvider.autoDispose<List<HydrationChallenge>>((ref) async {
  final service = ref.read(socialServiceProvider);
  return service.getChallenges();
});

/// Last time the user opened the inbox. Seeded from Hive, bumped to now() when
/// the dropdown opens — drives the unread badge.
final notificationsSeenAtProvider = StateProvider<DateTime?>((ref) {
  return HiveStorageService.instance.loadNotificationsSeenAt();
});

/// Number of notifications newer than the last "seen" moment — the red badge.
/// Not autoDispose so the count survives while the friends header is alive.
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final seenAt = ref.watch(notificationsSeenAtProvider);
  return ref.watch(notificationsProvider).maybeWhen(
        data: (items) {
          if (seenAt == null) return items.length;
          return items
              .where((n) => n.createdAt != null && n.createdAt!.isAfter(seenAt))
              .length;
        },
        orElse: () => 0,
      );
});

/// Mark every current notification as seen (persist + update state).
/// Takes [WidgetRef] so it can be called from screens/widgets.
Future<void> markNotificationsSeen(WidgetRef ref) async {
  final now = DateTime.now();
  await HiveStorageService.instance.cacheNotificationsSeenAt(now);
  ref.read(notificationsSeenAtProvider.notifier).state = now;
}
