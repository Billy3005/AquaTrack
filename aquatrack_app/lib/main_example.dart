// EXAMPLE: How to integrate AquaTrack backend with Flutter app
// This shows the complete integration flow

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/models/user.dart';
import 'core/repositories/auth_repository.dart';
import 'core/repositories/intake_repository.dart';
import 'core/services/app_service.dart';
import 'core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize app services
  try {
    await AppService().initialize();
    AppLogger.info('Main', 'App services initialized successfully');
  } catch (e) {
    AppLogger.error('Main', 'Failed to initialize app services', e);
    // Handle initialization failure
  }

  runApp(const ProviderScope(child: AquaTrackApp()));
}

class AquaTrackApp extends StatelessWidget {
  const AquaTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Inter'),
      home: const AppInitializationWrapper(),
    );
  }
}

/// Wrapper to check app initialization and authentication
class AppInitializationWrapper extends ConsumerStatefulWidget {
  const AppInitializationWrapper({super.key});

  @override
  ConsumerState<AppInitializationWrapper> createState() =>
      _AppInitializationWrapperState();
}

class _AppInitializationWrapperState
    extends ConsumerState<AppInitializationWrapper> {
  bool _isInitialized = false;
  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkInitialization();
  }

  Future<void> _checkInitialization() async {
    try {
      // Check if app services are initialized
      _isInitialized = AppService().isInitialized;

      if (_isInitialized) {
        // Check authentication status
        _isAuthenticated = await AppService().isUserAuthenticated();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Initialization Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isLoading = true;
                  });
                  _checkInitialization();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Route to appropriate screen based on authentication
    if (_isAuthenticated) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}

/// Example Login Screen showing API integration
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepository = AuthRepository();
  bool _isLoading = false;
  String? _error;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Please enter email and password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Call login API
      final authResponse = await _authRepository.login(
        email: email,
        password: password,
      );

      AppLogger.info('Login', 'Login successful: ${authResponse.user.email}');

      // Navigate to home screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      AppLogger.error('Login', 'Login failed', e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AquaTrack Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

/// Example Home Screen showing intake logging
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _intakeRepository = IntakeRepository();
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final authRepo = AuthRepository();
      _currentUser = await authRepo.getCurrentUser();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('HomeScreen', 'Failed to load user data', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _quickLogWater() async {
    try {
      final result = await _intakeRepository.quickLogWater(250);
      AppLogger.info(
          'HomeScreen', 'Quick logged 250ml water: ${result.intakeLog.id}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Logged 250ml water!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('HomeScreen', 'Failed to log water', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to log water: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      final authRepo = AuthRepository();
      await authRepo.logout();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      AppLogger.error('HomeScreen', 'Logout failed', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AquaTrack Home'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User welcome
            if (_currentUser != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${_currentUser!.fullName ?? _currentUser!.email}!',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Level ${_currentUser!.level} • ${_currentUser!.totalXp} XP',
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Quick actions
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _quickLogWater,
                    icon: const Icon(Icons.water_drop),
                    label: const Text('Log 250ml Water'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // API Health Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'System Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<Map<String, dynamic>>(
                      future: AppService().getHealthStatus(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final health = snapshot.data!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '✅ App Initialized: ${health['app_initialized']}',
                              ),
                              if (health.containsKey('api_connected'))
                                Text(
                                  health['api_connected']
                                      ? '✅ API Connected'
                                      : '❌ API Disconnected',
                                ),
                              if (health.containsKey('user_authenticated'))
                                Text(
                                  '✅ User Authenticated: ${health['user_authenticated']}',
                                ),
                            ],
                          );
                        }
                        return const CircularProgressIndicator();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
