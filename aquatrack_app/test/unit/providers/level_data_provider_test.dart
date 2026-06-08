import 'package:flutter_test/flutter_test.dart';

import 'package:aquatrack_app/core/repositories/level_repository.dart';
import 'package:aquatrack_app/features/level/providers/level_data_provider.dart';

LevelInfo _level({
  int current = 4,
  int currentXp = 120,
  int xpForNext = 300,
}) {
  return LevelInfo(
    currentLevel: current,
    currentXP: currentXp,
    xpForNextLevel: xpForNext,
    xpToNextLevel: xpForNext - currentXp,
    levelProgressPercentage: currentXp / xpForNext * 100,
    totalXPEarned: 1000,
  );
}

AchievementProgress _ach({
  required String id,
  String domain = 'streak',
  String tier = 'common',
  int current = 0,
  int required = 10,
  int xp = 50,
  bool unlocked = false,
  bool claimed = false,
}) {
  return AchievementProgress(
    id: id,
    title: id,
    description: 'desc $id',
    icon: '🔥',
    type: domain,
    rarity: tier,
    currentValue: current,
    requiredValue: required,
    progressPercentage: required == 0 ? 0 : (current / required * 100).round(),
    isUnlocked: unlocked,
    isClaimed: claimed,
    xpReward: xp,
    unlockAvatarId: null,
  );
}

void main() {
  group('buildLevelData', () {
    test('maps domain/tier/reward and claim state into LevelAchievement', () {
      final data = buildLevelData(
        levelInfo: _level(),
        achievements: [
          _ach(
              id: 'streak_7',
              domain: 'streak',
              tier: 'rare',
              xp: 150,
              current: 7,
              required: 7,
              unlocked: true,
              claimed: false),
        ],
      );

      final a = data.achievements.single;
      expect(a.domain, 'streak');
      expect(a.tier, 'rare');
      expect(a.rewardXp, 150);
      expect(a.isUnlocked, true);
      expect(a.isClaimed, false);
      // Done but not claimed → claimable.
      expect(a.isClaimable, true);
    });

    test('xp progress comes from LevelInfo', () {
      final data = buildLevelData(
        levelInfo: _level(current: 4, currentXp: 120, xpForNext: 300),
        achievements: const [],
      );
      expect(data.currentLevel, 4);
      expect(data.currentXP, 120);
      expect(data.nextLevelXP, 300);
    });

    test('claimableCount counts only unlocked && not claimed', () {
      final data = buildLevelData(
        levelInfo: _level(),
        achievements: [
          _ach(id: 'a', unlocked: true, claimed: false), // claimable
          _ach(id: 'b', unlocked: true, claimed: true), // already claimed
          _ach(id: 'c', unlocked: false, claimed: false), // locked
        ],
      );
      expect(data.claimableCount, 1);
      expect(data.unlockedCount, 2);
      expect(data.totalCount, 3);
    });

    test('progressFraction is clamped to 0..1', () {
      final data = buildLevelData(
        levelInfo: _level(),
        achievements: [
          _ach(id: 'over', current: 999, required: 10, unlocked: true),
          _ach(id: 'half', current: 5, required: 10),
        ],
      );
      expect(data.achievements[0].progressFraction, 1.0);
      expect(data.achievements[1].progressFraction, closeTo(0.5, 0.001));
    });
  });
}
