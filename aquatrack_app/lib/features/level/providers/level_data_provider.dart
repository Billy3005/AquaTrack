import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/user_stats_provider.dart';
import '../../../core/repositories/level_repository.dart';
import 'level_provider.dart';

/// One achievement as the Level screen needs it — full backend data, no lossy
/// local catalog. Sourced from `/levels/achievements` (see ADR 0003).
class LevelAchievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String domain; // streak | volume | level | ... | quest | coach | ...
  final String tier; // common | rare | epic | legendary
  final int progress;
  final int target;
  final int rewardXp;
  final bool isUnlocked;
  final bool isClaimed;

  const LevelAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.domain,
    required this.tier,
    required this.progress,
    required this.target,
    required this.rewardXp,
    required this.isUnlocked,
    required this.isClaimed,
  });

  /// Done (threshold reached) but the Milestone XP not yet collected.
  bool get isClaimable => isUnlocked && !isClaimed;

  double get progressFraction =>
      target <= 0 ? 0 : (progress / target).clamp(0.0, 1.0);
}

/// Everything the Level screen renders that comes from the levels API:
/// XP progress + the achievement catalog. Coins/streak/levelName come from
/// `userStatsProvider` in the widget (the app-wide single source).
class LevelData {
  final int currentLevel;
  final int currentXP;
  final int nextLevelXP;
  final List<LevelAchievement> achievements;

  const LevelData({
    required this.currentLevel,
    required this.currentXP,
    required this.nextLevelXP,
    required this.achievements,
  });

  int get totalCount => achievements.length;
  int get unlockedCount => achievements.where((a) => a.isUnlocked).length;
  int get claimableCount => achievements.where((a) => a.isClaimable).length;
}

/// Pure mapper: backend responses → UI [LevelData]. No Riverpod/IO so it is
/// unit-testable in isolation.
LevelData buildLevelData({
  required LevelInfo levelInfo,
  required List<AchievementProgress> achievements,
}) {
  final mapped = achievements
      .map((a) => LevelAchievement(
            id: a.id,
            title: a.title,
            description: a.description,
            icon: a.icon,
            domain: a.type,
            tier: a.rarity,
            progress: a.currentValue,
            target: a.requiredValue,
            rewardXp: a.xpReward,
            isUnlocked: a.isUnlocked,
            isClaimed: a.isClaimed,
          ))
      .toList();

  return LevelData(
    currentLevel: levelInfo.currentLevel,
    currentXP: levelInfo.currentXP,
    nextLevelXP: levelInfo.xpForNextLevel,
    achievements: mapped,
  );
}

/// Repository provider (functional, no codegen) for the Level screen.
final levelDataRepositoryProvider =
    Provider<LevelRepository>((ref) => LevelRepository());

/// Fetches level XP + achievements concurrently and maps to [LevelData].
final levelDataProvider = FutureProvider<LevelData>((ref) async {
  final repo = ref.watch(levelDataRepositoryProvider);

  final levelF = repo.getCurrentLevel();
  final achF = repo.getAchievements();

  final levelRes = await levelF;
  final achRes = await achF;

  if (!levelRes.isSuccess || levelRes.data == null) {
    throw Exception(levelRes.error ?? 'Không tải được dữ liệu cấp độ');
  }

  return buildLevelData(
    levelInfo: levelRes.data!,
    achievements: achRes.isSuccess && achRes.data != null
        ? achRes.data!
        : const <AchievementProgress>[],
  );
});

/// Claim a Done achievement's Milestone XP, then refresh level + stats.
Future<LevelApiResponse<ClaimRewardResponse>> claimLevelAchievement(
  WidgetRef ref,
  String achievementId,
) async {
  final repo = ref.read(levelDataRepositoryProvider);
  final res = await repo.claimAchievement(achievementId);
  if (res.isSuccess) {
    final data = res.data;
    // Patch the shared levelNotifierProvider with the claim's authoritative
    // level_progress. Without this the XP bar (which prefers levelNotifier over
    // levelDataProvider) never moves, and a claim that crossed a level never
    // fires the celebration — both bugs the user reported. syncFromServer also
    // detects the level jump and queues LevelUpEvent for the shell to show.
    if (data?.currentLevel != null) {
      await ref.read(levelNotifierProvider.notifier).syncFromServer(
            currentLevel: data!.currentLevel!,
            currentXp: data.currentXp ?? 0,
            nextLevelXp: data.xpForNextLevel ?? 100,
            coinsAwarded: data.coinsAwarded,
          );
    }
    // Refresh the achievement catalog (claimed flag) and coins/level name.
    ref.invalidate(levelDataProvider);
    ref.invalidate(userStatsProvider);
  }
  return res;
}
