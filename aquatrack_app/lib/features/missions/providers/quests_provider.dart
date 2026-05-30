import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
import '../models/quest.dart';

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

  final ApiService _api;

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
  /// Returns true on success.
  Future<bool> claim(String questId) async {
    state = state.copyWith(claimingId: questId, clearError: true);
    try {
      final res = await _api.post('/quests/$questId/claim');
      if (res.isSuccess) {
        await load();
        state = state.copyWith(clearClaiming: true);
        return true;
      }
      state = state.copyWith(clearClaiming: true, error: res.message);
      return false;
    } catch (e) {
      state = state.copyWith(clearClaiming: true, error: e.toString());
      return false;
    }
  }
}

final questsProvider =
    StateNotifierProvider<QuestsNotifier, QuestsState>((ref) {
  return QuestsNotifier(ApiService());
});
