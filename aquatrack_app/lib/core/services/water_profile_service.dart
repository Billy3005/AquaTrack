import '../models/water_profile.dart';
import 'api_service.dart';

/// Service để quản lý water profile và calculation
class WaterProfileService {
  final ApiService _apiService = ApiService();

  /// Lấy enum options cho dropdown UI
  Future<WaterProfileEnums> getEnums() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/api/v1/water-profile/enums',
      );
      if (response.isSuccess && response.data != null) {
        return WaterProfileEnums.fromJson(response.data!);
      }
      throw Exception('Không thể lấy danh sách options');
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Lỗi khi lấy danh sách options');
    }
  }

  /// Lấy water profile hiện tại của user
  Future<WaterProfileResponse> getProfile() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/api/v1/water-profile/',
      );
      if (response.isSuccess && response.data != null) {
        return WaterProfileResponse.fromJson(response.data!);
      }
      throw Exception('Không thể lấy thông tin profile');
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Lỗi khi lấy thông tin profile');
    }
  }

  /// Cập nhật water profile
  Future<WaterProfileResponse> updateProfile(WaterProfileUpdate update) async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        '/api/v1/water-profile/',
        data: update.toJson(),
      );
      if (response.isSuccess && response.data != null) {
        return WaterProfileResponse.fromJson(response.data!);
      }
      throw Exception('Không thể cập nhật profile');
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Lỗi khi cập nhật profile');
    }
  }

  /// Tính toán lượng nước cần thiết theo profile hiện tại
  Future<WaterCalculationResponse> calculateWaterIntake() async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/v1/water-profile/calculate',
      );
      if (response.isSuccess && response.data != null) {
        return WaterCalculationResponse.fromJson(response.data!);
      }
      throw Exception('Không thể tính toán lượng nước');
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Lỗi khi tính toán lượng nước');
    }
  }

  /// Lấy user summary cho B5 Review screen
  Future<UserSummaryResponse> getUserSummary() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/api/v1/water-profile/summary',
      );
      if (response.isSuccess && response.data != null) {
        return UserSummaryResponse.fromJson(response.data!);
      }
      throw Exception('Không thể lấy thông tin tóm tắt');
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Lỗi khi lấy thông tin tóm tắt');
    }
  }
}

/// Extension methods cho enum helpers
extension WaterProfileEnumsExt on WaterProfileEnums {
  /// Lấy danh sách gender options cho dropdown
  List<DropdownOption<Gender>> get genderOptions {
    return Gender.values
        .map((gender) => DropdownOption(
              value: gender,
              label: genders[gender.name] ?? gender.label,
            ))
        .toList();
  }

  /// Lấy danh sách activity level options cho dropdown
  List<DropdownOption<ActivityLevel>> get activityLevelOptions {
    return ActivityLevel.values
        .map((level) => DropdownOption(
              value: level,
              label: activityLevels[level.name] ?? level.label,
            ))
        .toList();
  }

  /// Lấy danh sách job type options cho dropdown
  List<DropdownOption<JobType>> get jobTypeOptions {
    return JobType.values
        .map((job) => DropdownOption(
              value: job,
              label: jobTypes[job.name] ?? job.label,
            ))
        .toList();
  }

  /// Lấy danh sách health condition options cho multi-select
  List<DropdownOption<HealthCondition>> get healthConditionOptions {
    return HealthCondition.values
        .map((condition) => DropdownOption(
              value: condition,
              label: healthConditions[condition.name] ?? condition.label,
            ))
        .toList();
  }

  /// Lấy danh sách veggie intake options cho dropdown
  List<DropdownOption<VeggieIntake>> get veggieIntakeOptions {
    return VeggieIntake.values
        .map((veggie) => DropdownOption(
              value: veggie,
              label: veggieIntakes[veggie.name] ?? veggie.label,
            ))
        .toList();
  }
}

/// Helper class cho dropdown options
class DropdownOption<T> {
  final T value;
  final String label;

  DropdownOption({required this.value, required this.label});
}

/// Extension cho water calculation formatting
extension WaterCalculationFormatter on WaterCalculationResponse {
  /// Format total water as "X.Y L"
  String get formattedTotal => '${dailyGoalL.toStringAsFixed(1)} L';

  /// Format total water as "X cups"
  String get formattedCups => '$dailyGoalCups cốc';

  /// Format total water as "X,XXX ml"
  String get formattedMl => '${totalMl.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )} ml';

  /// Kiểm tra có cảnh báo không
  bool get hasAnyWarnings => hasWarnings && warningMessage?.isNotEmpty == true;
}

/// Extension cho profile completion status
extension WaterProfileStatus on WaterProfileResponse {
  /// Kiểm tra profile có hoàn chỉnh không
  bool get isComplete => profileComplete;

  /// Kiểm tra có goal được tính toán chưa
  bool get hasCalculatedGoal =>
      calculatedDailyGoalMl != null && calculatedDailyGoalMl! > 0;

  /// Format calculated goal
  String get formattedGoal {
    if (!hasCalculatedGoal) return 'Chưa tính toán';
    final goalL = (calculatedDailyGoalMl! / 1000).toStringAsFixed(1);
    return '$goalL L';
  }

  /// Progress percentage (0-100)
  double get completionPercentage {
    final fields = [
      gender,
      age,
      height,
      weight,
      activityLevel,
      jobType,
      veggieIntake
    ];
    final completedFields = fields.where((field) => field != null).length;
    return (completedFields / fields.length) * 100;
  }
}
