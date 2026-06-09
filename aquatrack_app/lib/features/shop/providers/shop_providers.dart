import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/app_providers.dart';

/// Whether the user currently owns a Streak Freeze, plus its Coin price.
/// Mirrors `GET /shop/streak-freeze` (ADR 0004).
class StreakFreezeStatus {
  final bool owned;
  final int price;

  const StreakFreezeStatus({required this.owned, required this.price});
}

/// Fetches the user's Streak Freeze ownership/price. `autoDispose` so each time
/// the Shop is opened the status is re-fetched — otherwise a Freeze consumed by
/// logging on another screen would leave a stale `owned=true` here. Also
/// invalidated right after a purchase for an immediate update.
final streakFreezeStatusProvider =
    FutureProvider.autoDispose<StreakFreezeStatus>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get('/shop/streak-freeze');
  final data = res.data;
  if (res.statusCode == 200 && data is Map) {
    return StreakFreezeStatus(
      owned: data['owned'] == true,
      price: (data['price'] as num?)?.toInt() ?? 300,
    );
  }
  return const StreakFreezeStatus(owned: false, price: 300);
});
