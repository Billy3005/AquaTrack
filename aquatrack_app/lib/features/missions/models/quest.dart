/// Quest as returned by GET /quests (derived progress + claim state).
class Quest {
  final String id;
  final String period; // "daily" | "weekly"
  final String name;
  final String description;
  final String unit;
  final int progress;
  final int target;
  final int rewardXp;
  final int rewardCoin;
  final bool isBonus;
  final bool isChest;
  final bool done;
  final bool claimed;

  const Quest({
    required this.id,
    required this.period,
    required this.name,
    required this.description,
    required this.unit,
    required this.progress,
    required this.target,
    required this.rewardXp,
    required this.rewardCoin,
    required this.isBonus,
    required this.isChest,
    required this.done,
    required this.claimed,
  });

  factory Quest.fromJson(Map<String, dynamic> json) => Quest(
        id: json['id'] as String,
        period: json['period'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        unit: (json['unit'] as String?) ?? '',
        progress: (json['progress'] as num).toInt(),
        target: (json['target'] as num).toInt(),
        rewardXp: (json['reward_xp'] as num).toInt(),
        rewardCoin: (json['reward_coin'] as num).toInt(),
        isBonus: json['is_bonus'] as bool? ?? false,
        isChest: json['is_chest'] as bool? ?? false,
        done: json['done'] as bool? ?? false,
        claimed: json['claimed'] as bool? ?? false,
      );
}

/// One day in the 7-day week strip.
class WeekDayStatus {
  final String dayLabel; // "T2" … "CN"
  final String dateIso; // "2026-05-25"
  final String status; // "done" | "partial" | "today" | "future"
  final int? progressPct; // 0–100, null for future

  const WeekDayStatus({
    required this.dayLabel,
    required this.dateIso,
    required this.status,
    this.progressPct,
  });

  factory WeekDayStatus.fromJson(Map<String, dynamic> json) => WeekDayStatus(
        dayLabel: json['day_label'] as String,
        dateIso: json['date_iso'] as String,
        status: json['status'] as String,
        progressPct: (json['progress_pct'] as num?)?.toInt(),
      );
}

/// Full payload of GET /quests: quests grouped by period + header balances.
class QuestsData {
  final List<Quest> daily;
  final List<Quest> weekly;
  final int coins;
  final int totalXp;
  final int currentLevel;
  final int currentStreak;
  final List<WeekDayStatus> weekStrip;
  final DateTime dailyResetAt;
  final DateTime weeklyResetAt;

  const QuestsData({
    required this.daily,
    required this.weekly,
    required this.coins,
    required this.totalXp,
    required this.currentLevel,
    required this.currentStreak,
    required this.weekStrip,
    required this.dailyResetAt,
    required this.weeklyResetAt,
  });

  factory QuestsData.fromJson(Map<String, dynamic> json) => QuestsData(
        daily: (json['daily'] as List)
            .map((e) => Quest.fromJson(e as Map<String, dynamic>))
            .toList(),
        weekly: (json['weekly'] as List)
            .map((e) => Quest.fromJson(e as Map<String, dynamic>))
            .toList(),
        coins: (json['coins'] as num?)?.toInt() ?? 0,
        totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
        currentLevel: (json['current_level'] as num?)?.toInt() ?? 1,
        currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
        weekStrip: (json['week_strip'] as List? ?? [])
            .map((e) => WeekDayStatus.fromJson(e as Map<String, dynamic>))
            .toList(),
        dailyResetAt: DateTime.parse(json['daily_reset_at'] as String),
        weeklyResetAt: DateTime.parse(json['weekly_reset_at'] as String),
      );
}
