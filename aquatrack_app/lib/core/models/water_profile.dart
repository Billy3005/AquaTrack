import 'package:json_annotation/json_annotation.dart';

part 'water_profile.g.dart';

/// Enums cho water profile
enum Gender {
  @JsonValue('male')
  male,
  @JsonValue('female')
  female,
  @JsonValue('other')
  other
}

enum ActivityLevel {
  @JsonValue('sedentary')
  sedentary,
  @JsonValue('light')
  light,
  @JsonValue('moderate')
  moderate,
  @JsonValue('active')
  active,
  @JsonValue('very_active')
  veryActive
}

enum JobType {
  @JsonValue('office')
  office,
  @JsonValue('mixed')
  mixed,
  @JsonValue('outdoor')
  outdoor,
  @JsonValue('manual')
  manual
}

enum HealthCondition {
  @JsonValue('none')
  none,
  @JsonValue('diabetes')
  diabetes,
  @JsonValue('hypertension')
  hypertension,
  @JsonValue('neurological')
  neurological,
  @JsonValue('heart')
  heart,
  @JsonValue('pregnant')
  pregnant,
  @JsonValue('lactating')
  lactating,
  @JsonValue('gout')
  gout
}

enum VeggieIntake {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high
}

/// Water profile enum labels cho UI
@JsonSerializable()
class WaterProfileEnums {
  final Map<String, String> genders;
  final Map<String, String> activityLevels;
  final Map<String, String> jobTypes;
  final Map<String, String> healthConditions;
  final Map<String, String> veggieIntakes;

  WaterProfileEnums({
    required this.genders,
    required this.activityLevels,
    required this.jobTypes,
    required this.healthConditions,
    required this.veggieIntakes,
  });

  factory WaterProfileEnums.fromJson(Map<String, dynamic> json) =>
      _$WaterProfileEnumsFromJson(json);

  Map<String, dynamic> toJson() => _$WaterProfileEnumsToJson(this);
}

/// Water profile update request
@JsonSerializable()
class WaterProfileUpdate {
  final Gender? gender;
  final int? age;
  final int? height; // cm
  final double? weight; // kg
  final ActivityLevel? activityLevel;
  final JobType? jobType;
  final List<HealthCondition>? healthConditions;
  final VeggieIntake? veggieIntake;
  final int? coffeeCupsPerDay;
  final int? alcoholUnitsPerDay;

  WaterProfileUpdate({
    this.gender,
    this.age,
    this.height,
    this.weight,
    this.activityLevel,
    this.jobType,
    this.healthConditions,
    this.veggieIntake,
    this.coffeeCupsPerDay,
    this.alcoholUnitsPerDay,
  });

  factory WaterProfileUpdate.fromJson(Map<String, dynamic> json) =>
      _$WaterProfileUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$WaterProfileUpdateToJson(this);
}

/// Water calculation breakdown
@JsonSerializable()
class WaterCalculationBreakdown {
  final int baseMl;
  final int activityAdd;
  final int jobAdd;
  final int healthAdd;
  final int veggieAdd;
  final int coffeeAdd;
  final int alcoholAdd;

  WaterCalculationBreakdown({
    required this.baseMl,
    required this.activityAdd,
    required this.jobAdd,
    required this.healthAdd,
    required this.veggieAdd,
    required this.coffeeAdd,
    required this.alcoholAdd,
  });

  factory WaterCalculationBreakdown.fromJson(Map<String, dynamic> json) =>
      _$WaterCalculationBreakdownFromJson(json);

  Map<String, dynamic> toJson() => _$WaterCalculationBreakdownToJson(this);
}

/// Water calculation response
@JsonSerializable()
class WaterCalculationResponse {
  final int totalMl;
  final double dailyGoalL;
  final int dailyGoalCups;
  final WaterCalculationBreakdown breakdown;
  final bool hasWarnings;
  final String? warningMessage;
  final DateTime calculatedAt;

  WaterCalculationResponse({
    required this.totalMl,
    required this.dailyGoalL,
    required this.dailyGoalCups,
    required this.breakdown,
    required this.hasWarnings,
    this.warningMessage,
    required this.calculatedAt,
  });

  factory WaterCalculationResponse.fromJson(Map<String, dynamic> json) =>
      _$WaterCalculationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$WaterCalculationResponseToJson(this);
}

/// Water profile response
@JsonSerializable()
class WaterProfileResponse {
  final Gender? gender;
  final int? age;
  final int? height;
  final double? weight;
  final ActivityLevel? activityLevel;
  final JobType? jobType;
  final List<HealthCondition>? healthConditions;
  final VeggieIntake? veggieIntake;
  final int? coffeeCupsPerDay;
  final int? alcoholUnitsPerDay;
  final bool profileComplete;
  final int? calculatedDailyGoalMl;
  final DateTime? formulaLastUpdated;

  WaterProfileResponse({
    this.gender,
    this.age,
    this.height,
    this.weight,
    this.activityLevel,
    this.jobType,
    this.healthConditions,
    this.veggieIntake,
    this.coffeeCupsPerDay,
    this.alcoholUnitsPerDay,
    required this.profileComplete,
    this.calculatedDailyGoalMl,
    this.formulaLastUpdated,
  });

  factory WaterProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$WaterProfileResponseFromJson(json);

  Map<String, dynamic> toJson() => _$WaterProfileResponseToJson(this);
}

/// User summary response cho B5 Review screen
@JsonSerializable()
class UserSummaryResponse {
  final String genderAge; // "Nam - 28 tuổi"
  final String heightWeight; // "168 cm - 60 kg"
  final String activity; // "Vừa phải"
  final String job; // "Văn phòng"

  UserSummaryResponse({
    required this.genderAge,
    required this.heightWeight,
    required this.activity,
    required this.job,
  });

  factory UserSummaryResponse.fromJson(Map<String, dynamic> json) =>
      _$UserSummaryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UserSummaryResponseToJson(this);
}

/// Extension methods cho enum labels
extension GenderExtension on Gender {
  String get label {
    switch (this) {
      case Gender.male:
        return 'Nam';
      case Gender.female:
        return 'Nữ';
      case Gender.other:
        return 'Khác';
    }
  }
}

extension ActivityLevelExtension on ActivityLevel {
  String get label {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Ít vận động';
      case ActivityLevel.light:
        return 'Nhẹ nhàng';
      case ActivityLevel.moderate:
        return 'Vừa phải';
      case ActivityLevel.active:
        return 'Năng động';
      case ActivityLevel.veryActive:
        return 'Rất năng động';
    }
  }
}

extension JobTypeExtension on JobType {
  String get label {
    switch (this) {
      case JobType.office:
        return 'Văn phòng';
      case JobType.mixed:
        return 'Hỗn hợp';
      case JobType.outdoor:
        return 'Ngoài trời';
      case JobType.manual:
        return 'Tay chân';
    }
  }
}

extension HealthConditionExtension on HealthCondition {
  String get label {
    switch (this) {
      case HealthCondition.none:
        return 'Không có';
      case HealthCondition.diabetes:
        return 'Tiểu đường';
      case HealthCondition.hypertension:
        return 'Cao huyết áp';
      case HealthCondition.neurological:
        return 'Bệnh thần kinh';
      case HealthCondition.heart:
        return 'Tim mạch';
      case HealthCondition.pregnant:
        return 'Đang mang thai';
      case HealthCondition.lactating:
        return 'Đang cho con bú';
      case HealthCondition.gout:
        return 'Gout';
    }
  }
}

extension VeggieIntakeExtension on VeggieIntake {
  String get label {
    switch (this) {
      case VeggieIntake.low:
        return 'Ít (< 1 phần/ngày)';
      case VeggieIntake.medium:
        return 'Vừa (1-2 phần/ngày)';
      case VeggieIntake.high:
        return 'Nhiều (3+ phần/ngày)';
    }
  }
}
