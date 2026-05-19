import '../constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Home Screen state dựa trên hydration progress + nhiệt độ
enum HomeState { dehydrated, low, normalCool, normalHot, nearGoal }

class HomeStateHelper {
  /// Calculate HomeState từ progress (0.0-1.0) và nhiệt độ
  static HomeState getHomeState(double progress, double tempCelsius) {
    if (progress <= 0.25) return HomeState.dehydrated;
    if (progress <= 0.45) return HomeState.low;
    if (progress >= 0.76) return HomeState.nearGoal;
    if (tempCelsius >= 34) return HomeState.normalHot;
    return HomeState.normalCool;
  }

  /// Drop fill color theo state (Living Drop widget)
  static Color dropColor(HomeState state) => switch (state) {
    HomeState.dehydrated => AppColors.dropDehydrated,
    HomeState.low => AppColors.dropLow,
    HomeState.normalCool => AppColors.dropNormalCool,
    HomeState.normalHot => AppColors.dropNormalHot,
    HomeState.nearGoal => AppColors.dropNearGoal,
  };

  /// Headline message cho từng state
  static String getHeadline(HomeState state) => switch (state) {
    HomeState.dehydrated => "Cơ thể bạn đang khát",
    HomeState.low => "Hãy cùng giữ nhịp uống nước",
    HomeState.normalCool => "Hãy cùng giữ nhịp uống nước",
    HomeState.normalHot => "Trời nóng — uống nhiều hơn nhé",
    HomeState.nearGoal => "Tuyệt vời, gần đủ rồi!",
  };
}
