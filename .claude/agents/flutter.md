# agents/flutter.md — Flutter Agent

> Load khi làm bất kỳ file `.dart` hoặc trong `aquatrack_app/`

## Stack
```
Flutter       : 3.x stable
State         : flutter_riverpod + riverpod_annotation
Navigation    : go_router (6 bottom tabs + modals)
HTTP          : dio
Local DB      : hive_flutter
On-device AI  : tflite_flutter
Camera        : camera
Charts        : fl_chart
Auth          : firebase_auth
Push          : firebase_messaging
Animation     : flutter_animate, rive (drop breathing)
```

## Design Rules
```
LUÔN dùng AppColors — không hardcode màu hex trong widget
LUÔN dùng AppTextStyles — không hardcode fontSize
Background mặc định: AppColors.background (#0D1B2A)
Card surface: AppColors.surface (#112236)
Primary action: AppColors.cyan (#00B4D8)
```

## Core Widget — LivingDrop

Widget quan trọng nhất của app. Dùng ở HomeScreen, Widget nhỏ, Lock screen.

```dart
// features/home/widgets/living_drop.dart
class LivingDrop extends StatefulWidget {
  final double progress;        // 0.0 → 1.0
  final HomeState state;        // enum: dehydrated|low|normalCool|normalHot|nearGoal
  final VoidCallback? onTap;

  const LivingDrop({required this.progress, required this.state, this.onTap});
}

// Drop fill color theo state (từ design prototype)
Color _dropColor(HomeState state) => switch (state) {
  HomeState.dehydrated  => const Color(0xFF1A2A3A),
  HomeState.low         => const Color(0xFF1A4A7A),
  HomeState.normalCool  => AppColors.cyan,
  HomeState.normalHot   => const Color(0xFFFF6B35),
  HomeState.nearGoal    => AppColors.cyanLight,
};
// Breathing animation: scale 1.0 → 1.02 → 1.0, duration 2s, repeat
```

## Bottom Navigation (6 tabs)

```dart
// shared/widgets/bottom_nav.dart
const tabs = [
  (icon: Icons.water_drop_outlined, label: 'Drop',  route: '/'),
  (icon: Icons.chat_bubble_outline, label: 'Coach', route: '/coach'),
  (icon: Icons.person_outline,      label: 'Body',  route: '/body'),
  (icon: Icons.bar_chart_outlined,  label: 'Stats', route: '/stats'),
  (icon: Icons.emoji_events_outlined,label:'Level', route: '/level'),
  (icon: Icons.account_circle_outlined,label:'You', route: '/profile'),
];
```

## Screen Build Order (theo priority)

```
1. home/widgets/living_drop.dart          ← core animation
2. home/screens/home_screen.dart          ← layout + 5 states
3. home/widgets/quick_log_bar.dart        ← 100/250/500/Khác
4. log_drink/screens/log_drink_screen.dart
5. coach/screens/coach_screen.dart
6. smart_scan/screens/smart_scan_screen.dart
7. body_map/screens/body_map_screen.dart
8. stats/screens/stats_screen.dart
9. level/screens/level_screen.dart
10. profile/screens/profile_screen.dart
```

## Key Snippets

### HomeState logic
```dart
enum HomeState { dehydrated, low, normalCool, normalHot, nearGoal }

HomeState getHomeState(double progress, double temp) {
  if (progress <= 0.25) return HomeState.dehydrated;
  if (progress <= 0.45) return HomeState.low;
  if (progress >= 0.76) return HomeState.nearGoal;
  if (temp >= 34)       return HomeState.normalHot;
  return HomeState.normalCool;
}
```

### Quick Log (hold để rót dài)
```dart
// 100ml | 250ml | 500ml | + Khác
// Short tap → log ngay
// Long press → mở amount stepper modal
GestureDetector(
  onTap: () => ref.read(homeProvider.notifier).quickLog(250),
  onLongPress: () => showModalBottomSheet(context: context, builder: (_) => const LogDrinkScreen()),
  child: QuickLogChip(label: '250 ml', isSelected: true),
)
```

### Wave Chart (Stats screen)
```dart
// Dùng fl_chart LineChart
// Filled area màu cyan với opacity 0.3
// Dashed line goal 100%
// Data points: ngày không đạt → màu đỏ
LineChartData(
  lineBarsData: [
    LineChartBarData(
      spots: weeklyData.asSpots(),
      color: AppColors.cyan,
      belowBarData: BarAreaData(
        show: true,
        color: AppColors.cyan.withOpacity(0.2),
      ),
    ),
  ],
)
```

### XP Bar (dùng nhiều screen)
```dart
// shared/widgets/xp_bar.dart
class XpBar extends StatelessWidget {
  final int level;
  final int currentXp;
  final int maxXp;
  final String title;  // "Aqua Warrior"
  // Renders: "LV 7 · Aqua Warrior   1240 / 2000 XP"
  // Purple gradient fill bar
}
```

### Riverpod Provider template
```dart
@riverpod
class HomeNotifier extends _$HomeNotifier {
  @override
  AsyncValue<HomeSummary> build() => const AsyncValue.loading();

  Future<void> fetchToday() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(apiServiceProvider).getSummaryToday(),
    );
  }

  Future<void> quickLog(int volumeMl, {String type = 'water'}) async {
    final coeff = hydrationCoeff[type] ?? 1.0;
    final log = IntakeLog(volumeMl: volumeMl, effectiveMl: (volumeMl * coeff).round(), ...);
    await StorageService.saveIntake(log);         // local first
    state = AsyncValue.data(await _buildSummary());
    unawaited(_syncToServer(log));                // background sync
  }
}
```

## Prompt Template
```
[FLUTTER AGENT] [style:terse]
Screen: <tên screen — vd: Home, SmartScan, BodyMap>
Widget: <tên widget cụ thể nếu có>
Task: <1-2 dòng>
File: lib/features/<feature>/...

<paste code nếu debug>
```
