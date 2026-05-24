import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/repositories/body_map_repository.dart';
import '../../../core/sync/body_map_sync_repository.dart';
import '../../../shared/storage/hive_storage_service.dart';
import '../models/organ_model.dart';

part 'body_map_provider.g.dart';

/// Provider for BodyMapRepository dependency injection
@riverpod
BodyMapRepository bodyMapRepository(ref) {
  return BodyMapRepository();
}

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
    bool clearSelectedOrgan = false,
  }) {
    return BodyMapState(
      organHealths: organHealths ?? this.organHealths,
      overallHydrationLevel:
          overallHydrationLevel ?? this.overallHydrationLevel,
      selectedOrgan:
          clearSelectedOrgan ? null : (selectedOrgan ?? this.selectedOrgan),
      isAnimating: isAnimating ?? this.isAnimating,
    );
  }

  /// Clear selected organ
  BodyMapState clearSelection() {
    return copyWith(clearSelectedOrgan: true);
  }
}

/// Body map notifier với organ health calculation từ backend
@riverpod
class BodyMapNotifier extends _$BodyMapNotifier {
  late final BodyMapRepository _bodyMapRepository;

  @override
  Future<BodyMapState> build() async {
    // Initialize repository via dependency injection
    _bodyMapRepository = ref.read(bodyMapRepositoryProvider);
    return _loadBodyMapStateFromApi();
  }

  /// Load body map state từ backend API
  Future<BodyMapState> _loadBodyMapStateFromApi() async {
    try {
      // Fetch data from API in parallel for better performance
      final results = await Future.wait([
        _bodyMapRepository.getHydrationStatus(),
        _bodyMapRepository.getGoalProgress(days: 7),
        _bodyMapRepository.getLiquidTypesBreakdown(days: 7),
      ]);

      final hydrationResponse =
          results[0] as BodyMapApiResponse<HydrationStatus>;
      final goalResponse = results[1] as BodyMapApiResponse<GoalProgressData>;
      final liquidResponse = results[2] as BodyMapApiResponse<LiquidTypesData>;

      // Check for any API errors
      if (!hydrationResponse.isSuccess) {
        throw Exception(
          hydrationResponse.error ?? 'Failed to load hydration data',
        );
      }
      if (!goalResponse.isSuccess) {
        throw Exception(goalResponse.error ?? 'Failed to load goal data');
      }
      if (!liquidResponse.isSuccess) {
        throw Exception(liquidResponse.error ?? 'Failed to load liquid data');
      }

      // Convert API responses to BodyMapState
      return _convertApiDataToBodyMapState(
        hydrationResponse.data!,
        goalResponse.data!,
        liquidResponse.data!,
      );
    } catch (e) {
      debugPrint('❌ Failed to load body map from API: $e');

      // Only fallback to local storage for genuine connectivity issues
      final isConnectivityError = e.toString().contains('SocketException') ||
          e.toString().contains('HttpException') ||
          e.toString().contains('TimeoutException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('No route to host');

      if (isConnectivityError) {
        debugPrint(
          '🌐 Network connectivity issue detected, falling back to local storage',
        );
        return _loadBodyMapStateFromLocal();
      } else {
        // Re-throw API errors for proper error handling in UI
        debugPrint('🚨 API error (not connectivity), exposing to UI: $e');
        rethrow;
      }
    }
  }

  /// Convert API data to BodyMapState
  BodyMapState _convertApiDataToBodyMapState(
    HydrationStatus hydrationStatus,
    GoalProgressData goalProgress,
    LiquidTypesData liquidTypes,
  ) {
    // Calculate enhanced hydration level using multiple factors
    final baseHydrationLevel = hydrationStatus.overallHydrationLevel;
    final goalAchievementBonus =
        (goalProgress.achievementRatePercentage / 100.0) * 0.1;
    final liquidQualityBonus = liquidTypes.liquidEffectivenessRatio * 0.1;
    final streakBonus =
        (hydrationStatus.currentStreak / 7.0).clamp(0.0, 1.0) * 0.1;

    final enhancedHydrationLevel = (baseHydrationLevel +
            goalAchievementBonus +
            liquidQualityBonus +
            streakBonus)
        .clamp(0.0, 1.0);

    // Calculate organ healths with enhanced data
    final organHealths = DefaultOrgans.all.map((organ) {
      return OrganHealth.fromHydration(
        organ: organ,
        hydrationLevel: enhancedHydrationLevel,
      );
    }).toList();

    return BodyMapState(
      organHealths: organHealths,
      overallHydrationLevel: enhancedHydrationLevel,
    );
  }

  /// Fallback to local storage if API fails
  BodyMapState _loadBodyMapStateFromLocal() {
    return _loadBodyMapState();
  }

  /// Load body map state từ current hydration data
  BodyMapState _loadBodyMapState() {
    // Default hydration level, will be updated by async load
    final hydrationLevel = 0.0;

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
    state.whenData((currentState) {
      // Recalculate organ healths with new hydration level
      final updatedOrganHealths = DefaultOrgans.all.map((organ) {
        return OrganHealth.fromHydration(
          organ: organ,
          hydrationLevel: newLevel,
        );
      }).toList();

      state = AsyncValue.data(
        currentState.copyWith(
          organHealths: updatedOrganHealths,
          overallHydrationLevel: newLevel,
        ),
      );
    });
  }

  /// Select an organ for detailed view
  void selectOrgan(OrganInfo organ) {
    state.whenData((currentState) {
      state = AsyncValue.data(currentState.copyWith(selectedOrgan: organ));
    });
  }

  /// Clear organ selection
  void clearSelection() {
    state.whenData((currentState) {
      state = AsyncValue.data(currentState.clearSelection());
    });
  }

  /// Refresh data from API
  Future<void> refresh() async {
    state = const AsyncValue.loading();

    try {
      final newData = await _loadBodyMapStateFromApi();
      state = AsyncValue.data(newData);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Get organs sorted by health priority (most critical first)
  List<OrganHealth> getCriticalOrgans() {
    return state.when(
      data: (bodyMapState) => bodyMapState.organHealths
          .where(
            (organHealth) =>
                organHealth.state == OrganState.critical ||
                organHealth.state == OrganState.poor,
          )
          .toList()
        ..sort((a, b) => a.organ.priority.compareTo(b.organ.priority)),
      loading: () => [],
      error: (error, stack) => [],
    );
  }

  /// Get healthy organs for positive feedback
  List<OrganHealth> getHealthyOrgans() {
    return state.when(
      data: (bodyMapState) => bodyMapState.organHealths
          .where(
            (organHealth) =>
                organHealth.state == OrganState.excellent ||
                organHealth.state == OrganState.good,
          )
          .toList(),
      loading: () => [],
      error: (error, stack) => [],
    );
  }

  /// Calculate overall body health score (0.0-1.0)
  double get overallHealthScore {
    return state.when(
      data: (bodyMapState) {
        if (bodyMapState.organHealths.isEmpty) return 0.0;

        double totalScore = 0.0;
        double totalWeight = 0.0;

        for (final organHealth in bodyMapState.organHealths) {
          final weight = organHealth.organ.priority;
          final score = _getOrganScore(organHealth.state);

          totalScore += score * weight;
          totalWeight += weight;
        }

        return totalWeight > 0 ? totalScore / totalWeight : 0.0;
      },
      loading: () => 0.0,
      error: (error, stack) => 0.0,
    );
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
    return state.when(
      data: (bodyMapState) {
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
      },
      loading: () => 'Đang tính toán tình trạng cơ thể...',
      error: (error, stack) => 'Không thể đánh giá tình trạng cơ thể',
    );
  }

  /// Get suggested action based on current state
  String get suggestedAction {
    return state.when(
      data: (bodyMapState) {
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
      },
      loading: () => 'Đang phân tích...',
      error: (error, stack) => 'Hãy thử refresh để cập nhật dữ liệu',
    );
  }

  /// Start animation effect (for level up or achievement)
  void startAnimation() {
    state.whenData((currentState) {
      state = AsyncValue.data(currentState.copyWith(isAnimating: true));

      // Auto stop animation after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        state.whenData((animatingState) {
          state = AsyncValue.data(animatingState.copyWith(isAnimating: false));
        });
      });
    });
  }

  /// Get organ by ID
  OrganHealth? getOrganHealth(String organId) {
    return state.when(
      data: (bodyMapState) {
        try {
          return bodyMapState.organHealths.firstWhere(
            (organHealth) => organHealth.organ.id == organId,
          );
        } catch (e) {
          return null;
        }
      },
      loading: () => null,
      error: (error, stack) => null,
    );
  }
}
