import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/repositories/intake_repository.dart';

part 'log_drink_provider.g.dart';

/// Log Drink screen state
class LogDrinkState {
  final String selectedDrinkType;
  final int amountMl;
  final bool isLoading;

  const LogDrinkState({
    this.selectedDrinkType = 'water',
    this.amountMl = 250,
    this.isLoading = false,
  });

  LogDrinkState copyWith({
    String? selectedDrinkType,
    int? amountMl,
    bool? isLoading,
  }) {
    return LogDrinkState(
      selectedDrinkType: selectedDrinkType ?? this.selectedDrinkType,
      amountMl: amountMl ?? this.amountMl,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Calculate effective amount with hydration coefficient
  int get effectiveAmountMl {
    final coeff = AppConstants.hydrationCoeff[selectedDrinkType] ?? 1.0;
    return (amountMl * coeff).round();
  }

  /// Calculate XP gained for this log
  int get xpGained {
    return AppConstants.xpEvents['log_drink'] ?? 10;
  }
}

/// Log Drink screen notifier
@riverpod
class LogDrinkNotifier extends _$LogDrinkNotifier {
  @override
  LogDrinkState build() {
    return const LogDrinkState();
  }

  /// Select drink type
  void selectDrinkType(String drinkType) {
    state = state.copyWith(selectedDrinkType: drinkType);
  }

  /// Set amount (from stepper or presets)
  void setAmount(int amount) {
    state = state.copyWith(amountMl: amount);
  }

  /// Submit log directly to IntakeRepository
  Future<void> submitLog() async {
    if (state.amountMl <= 0) return;

    state = state.copyWith(isLoading: true);

    try {
      final intakeRepository = IntakeRepository();

      // Create intake log with drink type
      await intakeRepository.createIntakeLog(
        volumeMl: state.amountMl,
        liquidType: state.selectedDrinkType,
        source: 'manual_log',
      );

      // Reset form sau khi log thành công
      state = const LogDrinkState();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  /// Reset form
  void reset() {
    state = const LogDrinkState();
  }
}
