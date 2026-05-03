import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'shared/storage/hive_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/services/app_service.dart';
import 'core/utils/logger.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemUiOverlayStyle);

  // Initialize Hive storage (existing)
  await HiveStorageService.initialize();

  // Initialize app services
  try {
    await AppService().initialize();
    AppLogger.info('Main', 'App services initialized successfully');
  } catch (e) {
    AppLogger.error('Main', 'Failed to initialize app services', e);
    // Continue anyway for development
  }

  runApp(
    const ProviderScope(
      child: AquaTrackApp(),
    ),
  );
}
