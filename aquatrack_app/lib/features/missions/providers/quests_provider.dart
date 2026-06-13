import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/app_providers.dart';
import '../../../core/network/api_client.dart';
import '../models/quest.dart';

class ClaimResult {
  final int rewardCoin;
  final int rewardXp;

  const ClaimResult({required this.rewardCoin, required this.rewardXp});

  factory ClaimResult.fromJson(Map<String, dynamic> json) => ClaimResult(
        rewardCoin: (json['reward_coin'] as num?)?.toInt() ?? 0,
        rewardXp: (json['reward_xp'] as num?)?.toInt() ?? 0,
      );
}

/// State for the missions screen.
class QuestsState {
  final QuestsData? data;
  final bool isLoading;
  final String? error;
  final String? claimingId; // quest currently being claimed (for spinners)

  const QuestsState({
    this.data,
    this.isLoading = false,
    this.error,
    this.claimingId,
  });

  QuestsState copyWith({
    QuestsData? data,
    bool? isLoading,
    String? error,
    String? claimingId,
    bool clearError = false,
    bool clearClaiming = false,
  }) {
    return QuestsState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      claimingId: clearClaiming ? null : (claimingId ?? this.claimingId),
    );
  }
}

class QuestsNotifier extends StateNotifier<QuestsState> {
  QuestsNotifier(this._api) : super(const QuestsState());

  final ApiClient _api;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _api.get<QuestsData>(
        '/quests/',
        fromJson: (d) => QuestsData.fromJson(d as Map<String, dynamic>),
      );
      if (res.isSuccess && res.data != null) {
        state = state.copyWith(data: res.data, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: res.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Claim a Done quest's reward, then refresh so progress/balances update.
  /// Returns [ClaimResult] with coins/xp on success, null on failure.
  Future<ClaimResult?> claim(String questId) async {
    state = state.copyWith(claimingId: questId, clearError: true);
    try {
      final res = await _api.post<ClaimResult>(
        '/quests/$questId/claim',
        fromJson: (d) => ClaimResult.fromJson((d as Map).cast<String, dynamic>()),
      );
      if (res.isSuccess && res.data != null) {
        await load();
        state = state.copyWith(clearClaiming: true);
        return res.data;
      }
      state = state.copyWith(clearClaiming: true, error: res.message);
      return null;
    } catch (e) {
      state = state.copyWith(clearClaiming: true, error: e.toString());
      return null;
    }
  }
}

final questsProvider =
    StateNotifierProvider<QuestsNotifier, QuestsState>((ref) {
  return QuestsNotifier(ref.watch(apiClientProvider));
});
