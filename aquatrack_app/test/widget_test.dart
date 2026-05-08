import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aquatrack_app/core/theme/app_theme.dart';

void main() {
  group('AquaTrack App Tests', () {
    testWidgets('App theme configuration works correctly', (
      WidgetTester tester,
    ) async {
      // Test theme in isolation without navigation
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(body: Center(child: Text('Test'))),
        ),
      );

      await tester.pump();

      // Verify theme is applied
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, isNotNull);
      expect(materialApp.theme!.brightness, Brightness.dark);
    });

    testWidgets('Riverpod ProviderScope can be initialized', (
      WidgetTester tester,
    ) async {
      bool providerInitialized = false;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              providerInitialized = true;
              return const MaterialApp(
                home: Scaffold(body: Text('Provider Test')),
              );
            },
          ),
        ),
      );

      await tester.pump();

      expect(providerInitialized, true);
      expect(find.text('Provider Test'), findsOneWidget);
    });

    testWidgets('Basic widget rendering works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('AquaTrack Test')),
            body: const Center(child: Text('AquaTrack is working!')),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('AquaTrack Test'), findsOneWidget);
      expect(find.text('AquaTrack is working!'), findsOneWidget);
    });
  });
}
