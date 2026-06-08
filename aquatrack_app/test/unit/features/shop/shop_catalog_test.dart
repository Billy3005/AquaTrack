import 'package:flutter_test/flutter_test.dart';
import 'package:aquatrack_app/features/avatars/data/avatar_catalog.dart';

/// The Shop sells exactly the coin-purchasable Avatars (ADR 0004): coin is an
/// alternative path to the level/streak rail. These tests guard the selection
/// rule the Shop relies on so a catalog edit can't silently leak a
/// level/streak/mission-only avatar onto the storefront (or drop a sellable one).
void main() {
  final sellable = kAvatarCatalog.where((a) => a.unlock.coinPrice != null);

  test('every sellable avatar has a positive coin price', () {
    expect(sellable, isNotEmpty);
    for (final a in sellable) {
      expect(a.unlock.coinPrice, greaterThan(0), reason: a.id);
    }
  });

  test('non-coin avatars are excluded from the storefront', () {
    final sellableIds = sellable.map((a) => a.id).toSet();
    // Default (free), mission-only, streak-only, and level-only avatars must not
    // be sold for coins.
    expect(sellableIds, isNot(contains('giot_nuoc'))); // default
    expect(sellableIds, isNot(contains('lam_ha'))); // mission
    expect(sellableIds, isNot(contains('long_thuy'))); // streak 100
    expect(sellableIds, isNot(contains('suong_mai'))); // level 3 only
  });

  test('dual-path avatars are sellable (coin OR level)', () {
    final sellableIds = sellable.map((a) => a.id).toSet();
    expect(sellableIds, contains('dong_chay')); // level 10 OR 280 xu
    expect(sellableIds, contains('thuy_de')); // 5000 xu OR level 40
  });

  test('thuy_de label reads as an OR, not a hard level gate', () {
    final thuyDe = kAvatarById['thuy_de']!;
    expect(thuyDe.unlock.sub, contains('hoặc'));
  });
}
