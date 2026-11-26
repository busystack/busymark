import 'package:busymark/src/app/busymark_deferred_editor_focus.dart';
import 'package:busymark/src/app/busymark_dialogs.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final interruption in ['another field', 'a modal', 'app deactivation']) {
    testWidgets('a creation focus request expires after $interruption', (
      tester,
    ) async {
      BusyMarkDeferredEditorFocus? pending;
      bool? consumed;
      addTearDown(() => pending?.cancel());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  const TextField(
                    decoration: InputDecoration(labelText: 'First field'),
                  ),
                  const TextField(
                    decoration: InputDecoration(labelText: 'Other field'),
                  ),
                  TextButton(
                    onPressed: () => pending = BusyMarkDeferredEditorFocus(),
                    child: const Text('Capture creation'),
                  ),
                  TextButton(
                    onPressed: () => consumed = pending!.consume(context),
                    child: const Text('Claim creation'),
                  ),
                  TextButton(
                    onPressed: () => showBusyMarkModalDialog<void>(
                      context,
                      builder: (context) => AlertDialog(
                        content: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close intervening dialog'),
                        ),
                      ),
                    ),
                    child: const Text('Open intervening dialog'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.widgetWithText(TextField, 'First field'));
      await tester.pump();
      // Capture from the button callback without asking the new editor to focus.
      tester
          .widget<TextButton>(
            find.widgetWithText(TextButton, 'Capture creation'),
          )
          .onPressed!();
      if (interruption == 'another field') {
        await tester.tap(find.widgetWithText(TextField, 'Other field'));
        await tester.pump();
      } else if (interruption == 'a modal') {
        await tester.tap(find.text('Open intervening dialog'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Close intervening dialog'));
        await tester.pumpAndSettle();
      } else {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
      }
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Claim creation'))
          .onPressed!();
      expect(consumed, isFalse);
    });
  }
}
