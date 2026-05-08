import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/error/error_handler.dart';
import 'shared/storage/hive_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/services/app_service.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize global error handling
  AppErrorHandler.initialize();

  // Set production error widget
  if (kReleaseMode) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return ProductionErrorWidget(details);
    };
  }

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemUiOverlayStyle);

  try {
    // Initialize Hive storage (existing)
    await HiveStorageService.initialize();

    // Initialize app services for authentication
    await AppService().initialize();
    debugPrint('App services initialized - Authentication enabled');
  } catch (error, stack) {
    AppErrorHandler.handleProviderError('App Initialization', error, stack);
    // Continue with app launch even if some services fail
  }

  runApp(const ProviderScope(child: AquaTrackApp()));
}
