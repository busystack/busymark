import 'package:busymark/src/app/busymark_dialogs.dart';
import 'package:busymark/src/app/busymark_shortcuts.dart';
import 'package:busymark/src/platform/linux_header_bar_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('modal dialogs stop app and document-view shortcuts', (
    tester,
  ) async {
    const channel = MethodChannel('com.busymark.test/modal-shortcuts');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      return call.method == 'initialize' ? true : null;
    });
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    });
    final headerBar = LinuxHeaderBarService(channel: channel);
    await headerBar.initialize();
    var appShortcutInvocations = 0;
    var documentViewShortcutInvocations = 0;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => Shortcuts(
          shortcuts: <ShortcutActivator, Intent>{
            BusyMarkAppShortcutActivators.nextTab: const _AppShortcutIntent(),
            BusyMarkAppShortcutActivators.previousTab:
                const _AppShortcutIntent(),
            BusyMarkAppShortcutActivators.closeTab: const _AppShortcutIntent(),
            BusyMarkDocumentViewShortcutActivators.editor:
                const _DocumentViewShortcutIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              _AppShortcutIntent: CallbackAction<_AppShortcutIntent>(
                onInvoke: (_) {
                  appShortcutInvocations += 1;
                  return null;
                },
              ),
              _DocumentViewShortcutIntent:
                  CallbackAction<_DocumentViewShortcutIntent>(
                    onInvoke: (_) {
                      documentViewShortcutInvocations += 1;
                      return null;
                    },
                  ),
            },
            child: child!,
          ),
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  showBusyMarkModalDialog<void>(
                    context,
                    headerBarService: headerBar,
                    builder: (dialogContext) => TextButton(
                      autofocus: true,
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
    );

    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    expect(find.text('Dismiss'), findsOneWidget);

    await _pressControlShortcut(tester, LogicalKeyboardKey.tab);
    await _pressControlShortcut(tester, LogicalKeyboardKey.tab, shift: true);
    await _pressControlShortcut(tester, LogicalKeyboardKey.keyW);
    await _pressControlShortcut(tester, LogicalKeyboardKey.digit1, alt: true);

    expect(appShortcutInvocations, 0);
    expect(documentViewShortcutInvocations, 0);
    expect(find.text('Dismiss'), findsOneWidget);
  });

  testWidgets('overlapping dialogs synchronize native modal depth', (
    tester,
  ) async {
    const channel = MethodChannel('com.busymark.test/modal-barrier');
    final barrierDepths = <int>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'initialize') {
        return true;
      }
      if (call.method == 'setModalBarrierDepth') {
        barrierDepths.add(call.arguments as int);
      }
      return null;
    });
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    });
    final headerBar = LinuxHeaderBarService(channel: channel);
    await headerBar.initialize();
    late BuildContext hostContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            hostContext = context;
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    );

    final first = showBusyMarkModalDialog<void>(
      hostContext,
      headerBarService: headerBar,
      builder: (_) => const Text('First dialog'),
    );
    await tester.pumpAndSettle();
    final second = showBusyMarkModalDialog<void>(
      hostContext,
      headerBarService: headerBar,
      builder: (_) => const Text('Second dialog'),
    );
    await tester.pumpAndSettle();

    expect(barrierDepths, [1, 2]);

    Navigator.of(hostContext, rootNavigator: true).pop();
    await tester.pumpAndSettle();
    await second;
    expect(barrierDepths, [1, 2, 1]);

    Navigator.of(hostContext, rootNavigator: true).pop();
    await tester.pumpAndSettle();
    await first;
    expect(barrierDepths, [1, 2, 1, 0]);
  });
}

Future<void> _pressControlShortcut(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool shift = false,
  bool alt = false,
}) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  if (shift) {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  }
  if (alt) {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
  }
  await tester.sendKeyDownEvent(key);
  await tester.sendKeyUpEvent(key);
  if (alt) {
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
  }
  if (shift) {
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  }
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();
}

class _AppShortcutIntent extends Intent {
  const _AppShortcutIntent();
}

class _DocumentViewShortcutIntent extends Intent {
  const _DocumentViewShortcutIntent();
}
