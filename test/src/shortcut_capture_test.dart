import 'package:busymark/src/app/shortcut_binding.dart';
import 'package:busymark/src/app/shortcut_capture.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'capture ignores composition and repeats, quarantines release and cancels',
    (tester) async {
      final owner = Object();
      final controller = TextEditingController();
      final focus = FocusNode();
      addTearDown(() async {
        for (final key
            in HardwareKeyboard.instance.logicalKeysPressed.toList()) {
          await tester.sendKeyUpEvent(key);
        }
        BusyMarkShortcutCapture.end(owner);
        controller.dispose();
        focus.dispose();
      });
      var executed = 0, cancelled = 0;
      final candidates = <BusyMarkKeyBinding>[];
      await tester.pumpWidget(
        MaterialApp(
          home: CallbackShortcuts(
            bindings: {
              const SingleActivator(
                LogicalKeyboardKey.f12,
                control: true,
              ): () =>
                  executed++,
            },
            child: Material(
              child: TextField(
                controller: controller,
                focusNode: focus,
                autofocus: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      BusyMarkShortcutCapture.begin(
        owner,
        onCandidate: candidates.add,
        onCancel: () {
          cancelled++;
          BusyMarkShortcutCapture.end(owner);
        },
      );
      controller.value = const TextEditingValue(
        text: 'é',
        composing: TextRange(start: 0, end: 1),
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(candidates, isEmpty);
      expect(executed, 0);
      controller.value = const TextEditingValue(text: 'é');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      expect(
        candidates,
        isEmpty,
        reason: 'A modifier alone is not a candidate.',
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.f12);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.f12);
      expect(candidates, [
        const BusyMarkKeyBinding(LogicalKeyboardKey.f12, control: true),
      ]);
      BusyMarkShortcutCapture.end(owner);
      expect(BusyMarkShortcutCapture.suppressing, isTrue);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.f12);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.f12);
      expect(BusyMarkShortcutCapture.suppressing, isTrue);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(BusyMarkShortcutCapture.suppressing, isFalse);
      expect(executed, 0);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(executed, 1);
      BusyMarkShortcutCapture.begin(
        owner,
        onCandidate: candidates.add,
        onCancel: () {
          cancelled++;
          BusyMarkShortcutCapture.end(owner);
        },
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(cancelled, 1);
      expect(candidates, hasLength(1));
      expect(BusyMarkShortcutCapture.suppressing, isFalse);
      expect(controller.text, 'é');
    },
  );
}
