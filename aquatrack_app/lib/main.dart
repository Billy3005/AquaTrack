import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'shared/storage/hive_storage_service.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive storage
  await HiveStorageService.initialize();

  runApp(
    const ProviderScope(
      child: AquaTrackApp(),
    ),
  );
}
