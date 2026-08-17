import 'package:aquatrack_app/features/onboarding/walkthrough_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The walkthrough paints over the whole app and is dismissed by a first-time
/// user who has no idea what it is. Two failure modes here are worse than
/// having no tour at all: an overlay that never closes (the app is bricked
/// behind a scrim), and "Bỏ qua" that fails to persist, which re-shows the tour
/// on every single launch. These tests pin both, plus the missing-target case
/// that would otherwise spotlight empty space.
void main() {
  final alpha = GlobalKey(debugLabel: 'test.alpha');
  final beta = GlobalKey(debugLabel: 'test.beta');
  final neverMounted = GlobalKey(debugLabel: 'test.neverMounted');

  /// Mounts two real targets, then opens the tour over them.
  /// Returns a one-element list so the test can observe onFinished firing.
  Future<List<int>> openTour(
    WidgetTester tester,
    List<WalkthroughStep> steps,
  ) async {
    final finishedCount = <int>[0];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(key: alpha, width: 80, height: 40),
              SizedBox(key: beta, width: 80, height: 40),
            ],
          ),
        ),
      ),
    );

    WalkthroughHost.show(
      tester.element(find.byType(Scaffold)),
      steps: steps,
      onFinished: () => finishedCount[0]++,
    );
    await tester.pumpAndSettle();

    return finishedCount;
  }

  List<WalkthroughStep> twoSteps() => [
        WalkthroughStep(
          targetKey: alpha,
          title: 'Bước một',
          body: 'Nội dung một',
        ),
        WalkthroughStep(
          targetKey: beta,
          title: 'Bước hai',
          body: 'Nội dung hai',
        ),
      ];

  testWidgets('walks every step, then closes and reports finished',
      (tester) async {
    final finished = await openTour(tester, twoSteps());

    expect(find.text('Bước một'), findsOneWidget);
    expect(find.text('Tiếp'), findsOneWidget,
        reason: 'a non-final step offers "Tiếp", not "Xong"');

    await tester.tap(find.text('Tiếp'));
    await tester.pumpAndSettle();

    expect(find.text('Bước hai'), findsOneWidget);
    expect(find.text('Xong'), findsOneWidget,
        reason: 'the last step must offer the terminal label');

    await tester.tap(find.text('Xong'));
    await tester.pumpAndSettle();

    expect(find.text('Bước hai'), findsNothing,
        reason: 'the overlay must leave the tree, not just go transparent');
    expect(finished[0], 1);
  });

  testWidgets('"Bỏ qua" persists the seen flag, so the tour cannot loop',
      (tester) async {
    final finished = await openTour(tester, twoSteps());

    await tester.tap(find.text('Bỏ qua'));
    await tester.pumpAndSettle();

    expect(find.text('Bước một'), findsNothing);
    expect(finished[0], 1,
        reason: 'skipping is still a completed tour — otherwise it re-shows '
            'on every launch and becomes the top complaint');
  });

  testWidgets('drops steps whose target never rendered', (tester) async {
    final finished = await openTour(tester, [
      WalkthroughStep(
        targetKey: neverMounted,
        title: 'Không có thật',
        body: 'Không nên hiện',
      ),
      WalkthroughStep(targetKey: alpha, title: 'Bước một', body: 'Nội dung'),
    ]);

    expect(find.text('Không có thật'), findsNothing,
        reason: 'an unmounted target would spotlight empty space');
    expect(find.text('Bước một'), findsOneWidget);
    expect(find.text('Xong'), findsOneWidget,
        reason: 'after filtering, the surviving step is the last one');

    await tester.tap(find.text('Xong'));
    await tester.pumpAndSettle();
    expect(finished[0], 1);
  });

  /// The tour was only ever eyeballed on a desktop window, where the card has
  /// room to spare. On a phone the last spotlight sits on the nav bar at the
  /// very bottom, which forces the card upward — the case most likely to
  /// overflow or run off the top. These pin it at real phone sizes.
  group('phone-sized layout', () {
    Future<void> pumpBottomAnchoredTour(
      WidgetTester tester, {
      required Size logicalSize,
      required double dpr,
    }) async {
      tester.view.physicalSize = Size(
        logicalSize.width * dpr,
        logicalSize.height * dpr,
      );
      tester.view.devicePixelRatio = dpr;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            // Mirrors the real shell: the target is a nav tab pinned to the
            // bottom edge, so the card has to render above it.
            bottomNavigationBar: SizedBox(
              height: 72,
              child: Row(
                children: [
                  Expanded(child: SizedBox(key: alpha, height: 48)),
                  const Expanded(child: SizedBox(height: 48)),
                ],
              ),
            ),
            body: const SizedBox.expand(),
          ),
        ),
      );

      WalkthroughHost.show(
        tester.element(find.byType(Scaffold)),
        steps: [
          WalkthroughStep(
            targetKey: alpha,
            title: 'Còn nữa ở đây',
            body: 'Thống kê chi tiết và Cấp độ nằm trong nút "Thêm".',
          ),
        ],
        onFinished: () {},
      );
      await tester.pumpAndSettle();
    }

    void expectCardFullyOnScreen(WidgetTester tester, Size logicalSize) {
      expect(tester.takeException(), isNull,
          reason: 'a RenderFlex overflow here is a visible yellow-stripe bar '
              'on a tester phone');

      final title = tester.getRect(find.text('Còn nữa ở đây'));
      final button = tester.getRect(find.text('Xong'));

      expect(title.top, greaterThanOrEqualTo(0),
          reason: 'card ran off the top of the screen');
      expect(button.bottom, lessThanOrEqualTo(logicalSize.height),
          reason: 'card ran off the bottom / under the nav bar');
      expect(title.left, greaterThanOrEqualTo(0));
      expect(title.right, lessThanOrEqualTo(logicalSize.width));
    }

    testWidgets('fits a common 360x800 phone', (tester) async {
      const size = Size(360, 800);
      await pumpBottomAnchoredTour(tester, logicalSize: size, dpr: 3.0);
      expectCardFullyOnScreen(tester, size);
    });

    testWidgets('fits a small 320x568 phone', (tester) async {
      const size = Size(320, 568);
      await pumpBottomAnchoredTour(tester, logicalSize: size, dpr: 2.0);
      expectCardFullyOnScreen(tester, size);
    });
  });

  testWidgets('closes itself when no target rendered at all', (tester) async {
    final finished = await openTour(tester, [
      WalkthroughStep(
        targetKey: neverMounted,
        title: 'Không có thật',
        body: 'Không nên hiện',
      ),
    ]);

    expect(find.text('Không có thật'), findsNothing);
    expect(finished[0], 1,
        reason: 'must self-close rather than leave an invisible overlay '
            'swallowing every tap on the app underneath');
  });
}
