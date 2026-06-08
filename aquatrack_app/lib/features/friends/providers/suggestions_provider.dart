import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/suggested_friend.dart';
import 'friends_provider.dart';

/// People-you-may-know suggestions (friends-of-friends by mutual count).
/// `autoDispose` so the list re-fetches each time the Requests tab is opened —
/// after sending a request the row disappears on the next fetch (the backend
/// filters out pending requests).
final friendSuggestionsProvider =
    FutureProvider.autoDispose<List<SuggestedFriend>>((ref) async {
  final service = ref.watch(socialServiceProvider);
  return service.getSuggestedFriends();
});
