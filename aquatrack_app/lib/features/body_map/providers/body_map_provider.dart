import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../shared/storage/hive_storage_service.dart';
import '../models/organ_model.dart';

part 'body_map_provider.g.dart';

/// Body map state for organ visualization
class BodyMapState {
  final List<OrganHealth> organHealths;
  final double overallHydrationLevel;
  final OrganInfo? selectedOrgan;
  final bool isAnimating;

  const BodyMapState({
    required this.organHealths,
    required this.overallHydrationLevel,
    this.selectedOrgan,
    this.isAnimating = false,
  });

  BodyMapState copyWith({
    List<OrganHealth>? organHealths,
    double? overallHydrationLevel,
    OrganInfo? selectedOrgan,
    bool? isAnimating,
  }) {
    return BodyMapState(
      organHealths: organHealths ?? this.organHealths,
      overallHydrationLevel:
          overallHydrationLevel ?? this.overallHydrationLevel,
      selectedOrgan: selectedOrgan ?? this.selectedOrgan,
      isAnimating: isAnimating ?? this.isAnimating,
    );
  }

  /// Clear selected organ
  BodyMapState clearSelection() {
    return copyWith(selectedOrgan: null);
  }
}

/// Body map notifier với organ health calculation
@riverpod
class BodyMapNotifier extends _$BodyMapNotifier {
  @override
  BodyMapState build() {
    return _loadBodyMapState();
  }

  /// Load body map state từ current hydration data
  BodyMapState _loadBodyMapState() {
    final storage = HiveStorageService.instance;

    // Get today's summary cho hydration level
    final todaysSummary = storage.loadTodaysSummary();
    final hydrationLevel = todaysSummary?.progress ?? 0.0;

    // Calculate organ healths
    final organHealths = DefaultOrgans.all.map((organ) {
      return OrganHealth.fromHydration(
        organ: organ,
        hydrationLevel: hydrationLevel,
      );
    }).toList();

    return BodyMapState(
      organHealths: organHealths,
      overallHydrationLevel: hydrationLevel,
    );
  }

  /// Update hydration data và recalculate organ states
  void updateHydrationLevel(double newLevel) {
    final currentState = state;

    // Recalculate organ healths with new hydration level
    final updatedOrganHealths = DefaultOrgans.all.map((organ) {
      return OrganHealth.fromHydration(
        organ: organ,
        hydrationLevel: newLevel,
      );
    }).toList();

    state = currentState.copyWith(
      organHealths: updatedOrganHealths,
      overallHydrationLevel: newLevel,
    );
  }

  /// Select an organ for detailed view
  void selectOrgan(OrganInfo organ) {
    state = state.copyWith(selectedOrgan: organ);
  }

  /// Clear organ selection
  void clearSelection() {
    state = state.clearSelection();
  }

  /// Refresh data từ storage
  void refresh() {
    state = _loadBodyMapState();
  }

  /// Get organs sorted by health priority (most critical first)
  List<OrganHealth> getCriticalOrgans() {
    return state.organHealths
        .where((organHealth) =>
            organHealth.state == OrganState.critical ||
            organHealth.state == OrganState.poor)
        .toList()
      ..sort((a, b) => a.organ.priority.compareTo(b.organ.priority));
  }

  /// Get healthy organs for positive feedback
  List<OrganHealth> getHealthyOrgans() {
    return state.organHealths
        .where((organHealth) =>
            organHealth.state == OrganState.excellent ||
            organHealth.state == OrganState.good)
        .toList();
  }

  /// Calculate overall body health score (0.0-1.0)
  double get overallHealthScore {
    if (state.organHealths.isEmpty) return 0.0;

    double totalScore = 0.0;
    double totalWeight = 0.0;

    for (final organHealth in state.organHealths) {
      final weight = organHealth.organ.priority;
      final score = _getOrganScore(organHealth.state);

      totalScore += score * weight;
      totalWeight += weight;
    }

    return totalWeight > 0 ? totalScore / totalWeight : 0.0;
  }

  /// Get numeric score cho organ state
  double _getOrganScore(OrganState state) {
    switch (state) {
      case OrganState.excellent:
        return 1.0;
      case OrganState.good:
        return 0.8;
      case OrganState.fair:
        return 0.6;
      case OrganState.poor:
        return 0.3;
      case OrganState.critical:
        return 0.1;
    }
  }

  /// Get overall health message
  String get overallHealthMessage {
    final score = overallHealthScore;

    if (score >= 0.9) {
      return 'Cơ thể bạn đang hoạt động tối ưu! Tuyệt vời! 🌟';
    } else if (score >= 0.75) {
      return 'Cơ thể khỏe mạnh, tiếp tục duy trì nhé! 💪';
    } else if (score >= 0.6) {
      return 'Cơ thể cần thêm nước để hoạt động tốt hơn 💧';
    } else if (score >= 0.4) {
      return 'Nhiều cơ quan đang thiếu nước, hãy uống thêm! 🚰';
    } else {
      return 'Cơ thể cần bù nước gấp để tránh ảnh hưởng sức khỏe! ⚠️';
    }
  }

  /// Get suggested action based on current state
  String get suggestedAction {
    final criticalOrgans = getCriticalOrgans();

    if (criticalOrgans.isNotEmpty) {
      final mostCritical = criticalOrgans.first.organ.name.toLowerCase();
      return 'Uống ngay 2-3 ly nước để cải thiện tình trạng $mostCritical';
    }

    final score = overallHealthScore;
    if (score < 0.7) {
      return 'Uống thêm 1-2 ly nước trong 30 phút tới';
    }

    return 'Duy trì việc uống nước đều đặn trong ngày';
  }

  /// Start animation effect (for level up or achievement)
  void startAnimation() {
    state = state.copyWith(isAnimating: true);

    // Auto stop animation after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      state = state.copyWith(isAnimating: false);
    });
  }

  /// Get organ by ID
  OrganHealth? getOrganHealth(String organId) {
    try {
      return state.organHealths.firstWhere(
        (organHealth) => organHealth.organ.id == organId,
      );
    } catch (e) {
      return null;
    }
  }
}
