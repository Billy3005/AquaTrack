import 'package:aquatrack_app/core/models/vision_result.dart';
import 'package:aquatrack_app/features/smart_scan/widgets/scan_result_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Regression test for the Smart Scan result panel ballooning to full height
  // (unbounded inner Columns) and pushing the action buttons off-screen.
  testWidgets(
    'ScanResultPanel is compact, bottom-anchored, and shows the Log button',
    (tester) async {
      // Emulate a phone screen (logical 360 x 800).
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const result = VisionResult(
        containerLabel: 'Chai nước suối 500ml',
        containerCapacityMl: 500,
        fillLevelPercent: 0.35,
        liquidType: 'water',
        confidence: 0.72,
        estimatedVolumeMl: 175,
        scanId: 'test-scan',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            // Mirrors the real Smart Scan stack: panel pinned to the bottom.
            body: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Colors.black),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ScanResultPanel(
                    result: result,
                    isLogging: false,
                    onRescan: () {},
                    onLog: (_) {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // 1) No RenderFlex overflow.
      expect(tester.takeException(), isNull);

      // 2) The key controls are present.
      expect(find.text('Log thức uống này'), findsOneWidget);
      expect(find.text('Sửa lượng'), findsOneWidget);

      // 3) The panel is compact (well under the 800px screen), so it sits as a
      //    card at the bottom rather than filling the screen.
      final panelHeight = tester.getSize(find.byType(ScanResultPanel)).height;
      expect(panelHeight, lessThan(400));

      // 4) The Log button is fully on-screen (not clipped below the bottom edge).
      final logBottom = tester.getBottomLeft(find.text('Log thức uống này')).dy;
      expect(logBottom, lessThanOrEqualTo(800));
    },
  );
}
