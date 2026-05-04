import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'shared/storage/hive_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/services/app_service.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemUiOverlayStyle);

  // Initialize Hive storage (existing)
  await HiveStorageService.initialize();

  // Initialize app services for authentication
  await AppService().initialize();
  print('App services initialized - Authentication enabled');

  runApp(
    const ProviderScope(
      child: AquaTrackApp(),
    ),
  );
}
