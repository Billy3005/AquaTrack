import 'package:flutter/material.dart';
// import '../../features/auth/presentation/pages/login_page.dart';
// import '../../features/auth/presentation/pages/register_page.dart';
// import '../../features/home/presentation/pages/home_page.dart';
// import '../../features/coach/presentation/pages/coach_page.dart';
// import '../../features/body/presentation/pages/body_page.dart';
// import '../../features/stats/presentation/pages/stats_page.dart';
// import '../../features/level/presentation/pages/level_page.dart';
// import '../../features/profile/presentation/pages/profile_page.dart';
// import '../../features/log/presentation/pages/log_drink_page.dart';
// import '../../features/scan/presentation/pages/smart_scan_page.dart';
import 'main_navigation.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// App routing configuration
class AppRouter {
  AppRouter._();

  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String main = '/main';
  static const String home = '/home';
  static const String coach = '/coach';
  static const String body = '/body';
  static const String stats = '/stats';
  static const String level = '/level';
  static const String profile = '/profile';
  static const String logDrink = '/log-drink';
  static const String smartScan = '/smart-scan';

  /// Generate routes
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashPage(), settings);

      case login:
        return _buildRoute(const _PlaceholderPage(title: 'Login'), settings);

      case register:
        return _buildRoute(const _PlaceholderPage(title: 'Register'), settings);

      case main:
        final initialIndex = (settings.arguments as int?) ?? 0;
        return _buildRoute(
            MainNavigation(initialIndex: initialIndex), settings);

      case logDrink:
        return _buildRoute(
            const _PlaceholderPage(title: 'Log Drink'), settings);

      case smartScan:
        return _buildRoute(
            const _PlaceholderPage(title: 'Smart Scan'), settings);

      default:
        return _buildRoute(const NotFoundPage(), settings);
    }
  }

  /// Build route with custom transition
  static PageRoute<T> _buildRoute<T extends Object?>(
    Widget page,
    RouteSettings settings, {
    bool fullscreenDialog = false,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      fullscreenDialog: fullscreenDialog,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Slide transition from right
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
    );
  }

  /// Push named route
  static Future<T?> pushNamed<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamed<T>(context, routeName, arguments: arguments);
  }

  /// Push replacement named route
  static Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    BuildContext context,
    String routeName, {
    TO? result,
    Object? arguments,
  }) {
    return Navigator.pushReplacementNamed<T, TO>(
      context,
      routeName,
      result: result,
      arguments: arguments,
    );
  }

  /// Push and clear stack
  static Future<T?> pushNamedAndClearStack<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Pop until route
  static void popUntilRoute(BuildContext context, String routeName) {
    Navigator.popUntil(context, ModalRoute.withName(routeName));
  }
}

/// Splash page placeholder
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// Placeholder page for development
class _PlaceholderPage extends StatelessWidget {
  final String title;

  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.construction,
                size: 64,
                color: AppColors.cyanAccent,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: AppTextStyles.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Đang phát triển...',
                style: AppTextStyles.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Not found page
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64),
            SizedBox(height: 16),
            Text('Page not found'),
          ],
        ),
      ),
    );
  }
}
