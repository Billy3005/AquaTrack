import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/config/app_config.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/home/home_screen_redesign.dart';
import 'features/profile/profile_screen_redesign.dart';
import 'features/coach/coach_screen_redesign.dart';
import 'features/stats/stats_screen_redesign.dart';
import 'features/level/level_screen_redesign.dart';
import 'features/friends/friends_screen_redesign.dart';
import 'features/missions/missions_screen_redesign.dart';
import 'features/log_drink/screens/log_drink_screen.dart';
import 'shared/widgets/bottom_nav.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// GoRouter configuration with authentication flow
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash', // Start with splash screen
    routes: [
      // Authentication routes (no bottom nav)
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const RegisterScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
              ),
              child: child,
            );
          },
        ),
      ),

      // Shell route cho bottom navigation (authenticated users)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return BottomNavigationWrapper(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreenRedesign()),
          ),
          GoRoute(
            path: '/coach',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CoachScreenRedesign()),
          ),
          GoRoute(
            path: '/missions',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MissionsScreenRedesign()),
          ),
          GoRoute(
            path: '/friends',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: FriendsScreenRedesign()),
          ),
          GoRoute(
            path: '/stats',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: StatsScreenRedesign()),
          ),
          GoRoute(
            path: '/level',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: LevelScreenRedesign()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreenRedesign()),
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
            body: Center(child: Text('Smart Scan Screen')),
          ), // Placeholder
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
      title: AppConfig.appName,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: const Locale('vi', 'VN'),
      supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
