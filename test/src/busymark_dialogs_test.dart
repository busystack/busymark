import 'package:busymark/src/app/busymark_dialogs.dart';
import 'package:busymark/src/app/busymark_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('modal dialogs stop app-level tab shortcuts', (tester) async {
    var appShortcutInvocations = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Shortcuts(
          shortcuts: <ShortcutActivator, Intent>{
            BusyMarkAppShortcutActivators.nextTab: const _AppShortcutIntent(),
            BusyMarkAppShortcutActivators.previousTab:
                const _AppShortcutIntent(),
            BusyMarkAppShortcutActivators.closeTab: const _AppShortcutIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              _AppShortcutIntent: CallbackAction<_AppShortcutIntent>(
                onInvoke: (_) {
                  appShortcutInvocations += 1;
                  return null;
                },
              ),
            },
            child: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showBusyMarkModalDialog<void>(
                        context,
                        builder: (dialogContext) => TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Dismiss'),
                        ),
                      );
                    },
                    child: const Text('Open dialog'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    expect(find.text('Dismiss'), findsOneWidget);

    await _pressControlShortcut(tester, LogicalKeyboardKey.tab);
    await _pressControlShortcut(tester, LogicalKeyboardKey.tab, shift: true);
    await _pressControlShortcut(tester, LogicalKeyboardKey.keyW);

    expect(appShortcutInvocations, 0);
    expect(find.text('Dismiss'), findsOneWidget);
  });
}

Future<void> _pressControlShortcut(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool shift = false,
}) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  if (shift) {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  }
  await tester.sendKeyDownEvent(key);
  await tester.sendKeyUpEvent(key);
  if (shift) {
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  }
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();
}

class _AppShortcutIntent extends Intent {
  const _AppShortcutIntent();
}
