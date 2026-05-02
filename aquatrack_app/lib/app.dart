import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_colors.dart';
import 'features/home/screens/home_screen.dart';
import 'features/coach/screens/coach_screen.dart';
import 'features/body_map/screens/body_map_screen.dart';
import 'features/stats/screens/stats_screen.dart';
import 'features/level/screens/level_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/log_drink/screens/log_drink_screen.dart';
import 'shared/widgets/bottom_nav.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// GoRouter configuration với 6 bottom tabs
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      // Shell route cho bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return BottomNavigationWrapper(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/coach',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CoachScreen(),
            ),
          ),
          GoRoute(
            path: '/body',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BodyMapScreen(),
            ),
          ),
          GoRoute(
            path: '/stats',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: StatsScreen(),
            ),
          ),
          GoRoute(
            path: '/level',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LevelScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),

      // Modal routes (không có bottom nav)
      GoRoute(
        path: '/log-drink',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const LogDrinkScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(0.0, 1.0), end: Offset.zero),
              ),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/smart-scan',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const Scaffold(
              body: Center(child: Text('Smart Scan Screen'))), // Placeholder
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
    ],
  );
});

/// Main App Widget
class AquaTrackApp extends ConsumerWidget {
  const AquaTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'AquaTrack',
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: AppColors.cyan,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
