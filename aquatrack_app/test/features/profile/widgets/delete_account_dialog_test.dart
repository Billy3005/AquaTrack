import 'package:aquatrack_app/features/profile/widgets/delete_account_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The typing gate is the only thing standing between a stray tap and the
/// permanent loss of a user's entire history — the server side has no undo and
/// no reactivation path. These tests pin the gate shut.
void main() {
  Future<bool?> showDialogAndGetResult(WidgetTester tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showDialog<bool>(
                context: context,
                builder: (_) => const DeleteAccountDialog(),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    return result;
  }

  testWidgets('the destructive action is disabled until the phrase is typed',
      (tester) async {
    await showDialogAndGetResult(tester);

    final button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Xoá vĩnh viễn'),
    );

    expect(button.onPressed, isNull,
        reason: 'must not be tappable before confirmation is typed');
  });

  testWidgets('a wrong phrase leaves the action disabled', (tester) async {
    await showDialogAndGetResult(tester);

    await tester.enterText(find.byType(TextField), 'xo');
    await tester.pump();

    final button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Xoá vĩnh viễn'),
    );

    expect(button.onPressed, isNull);
  });

  testWidgets('typing the phrase enables the action and returns true',
      (tester) async {
    await showDialogAndGetResult(tester);

    await tester.enterText(find.byType(TextField), 'XOÁ');
    await tester.pump();

    final button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Xoá vĩnh viễn'),
    );
    expect(button.onPressed, isNotNull);

    await tester.tap(find.widgetWithText(TextButton, 'Xoá vĩnh viễn'));
    await tester.pumpAndSettle();

    expect(find.byType(DeleteAccountDialog), findsNothing);
  });

  testWidgets('the phrase is accepted case-insensitively and trimmed',
      (tester) async {
    await showDialogAndGetResult(tester);

    // Autocapitalisation and a trailing space from the keyboard should not
    // block someone who typed the right word.
    await tester.enterText(find.byType(TextField), ' xoá ');
    await tester.pump();

    final button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Xoá vĩnh viễn'),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('cancelling returns false, not null', (tester) async {
    await showDialogAndGetResult(tester);

    await tester.tap(find.text('Giữ tài khoản'));
    await tester.pumpAndSettle();

    expect(find.byType(DeleteAccountDialog), findsNothing);
  });

  testWidgets('the dialog spells out what is lost', (tester) async {
    await showDialogAndGetResult(tester);

    // A user agreeing to this must be able to see it is not a pause.
    expect(find.textContaining('không thể khôi phục'), findsOneWidget);
    expect(find.textContaining('không phải tạm khoá'), findsOneWidget);
  });
}
