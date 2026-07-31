import 'dart:async';

import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/busymark_dialogs.dart';
import 'package:busymark/src/app/busymark_shortcuts.dart';
import 'package:busymark/src/platform/linux_header_bar_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  testWidgets('serializes rapid manual native barrier transitions', (
    tester,
  ) async {
    const channel = MethodChannel('com.busymark.test/serialized-modal-barrier');
    final firstUpdate = Completer<void>();
    final transitions = <int>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'initialize') {
        return true;
      }
      if (call.method == 'setModalBarrierDepth') {
        transitions.add(call.arguments as int);
        if (transitions.length == 1) {
          await firstUpdate.future;
        }
      }
      return null;
    });
    addTearDown(() {
      if (!firstUpdate.isCompleted) {
        firstUpdate.complete();
      }
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    });
    final headerBar = LinuxHeaderBarService(channel: channel);
    addTearDown(headerBar.dispose);
    await headerBar.initialize();

    final acquire = acquireBusyMarkModalBarrier(headerBar);
    await tester.pump();
    expect(transitions, [1]);

    final release = releaseBusyMarkModalBarrier(headerBar);
    await tester.pump();
    expect(
      transitions,
      [1],
      reason: 'the native hide must wait for the in-flight native show',
    );

    firstUpdate.complete();
    await Future.wait([acquire, release]);
    expect(transitions, [1, 0]);
  });

  testWidgets('failed native barrier acquisition rolls back and can retry', (
    tester,
  ) async {
    final headerBar = _FailingModalBarrierService();
    addTearDown(headerBar.dispose);

    await expectLater(
      acquireBusyMarkModalBarrier(headerBar),
      throwsA(isA<StateError>()),
    );
    expect(headerBar.transitions, [1, 0]);

    await acquireBusyMarkModalBarrier(headerBar);
    await releaseBusyMarkModalBarrier(headerBar);
    expect(headerBar.transitions, [1, 0, 1, 0]);
  });

  testWidgets('modal coordinator resolves the service from ProviderScope', (
    tester,
  ) async {
    const channel = MethodChannel('com.busymark.test/automatic-modal-barrier');
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      return call.method == 'initialize' ? true : null;
    });
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    });
    final headerBar = LinuxHeaderBarService(channel: channel);
    addTearDown(headerBar.dispose);
    await headerBar.initialize();
    late BuildContext hostContext;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [linuxHeaderBarServiceProvider.overrideWithValue(headerBar)],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              hostContext = context;
              return const Scaffold(body: SizedBox.expand());
            },
          ),
        ),
      ),
    );

    final result = showBusyMarkModalDialog<void>(
      hostContext,
      builder: (_) => const Text('Automatic barrier dialog'),
    );
    await tester.pumpAndSettle();

    expect(
      calls
          .where((call) => call.method == 'setModalBarrierDepth')
          .map((call) => call.arguments),
      [1],
    );

    Navigator.of(hostContext, rootNavigator: true).pop();
    await tester.pumpAndSettle();
    await result;

    expect(
      calls
          .where((call) => call.method == 'setModalBarrierDepth')
          .map((call) => call.arguments),
      [1, 0],
    );
  });

  testWidgets('open modal barrier follows live theme changes', (tester) async {
    const accent = Color(0xFF3584E4);
    final lightTheme = buildBusyMarkTheme(
      brightness: Brightness.light,
      accentColor: accent,
    );
    final darkTheme = buildBusyMarkTheme(
      brightness: Brightness.dark,
      accentColor: accent,
    );
    final themeMode = ValueNotifier(ThemeMode.light);
    addTearDown(themeMode.dispose);
    late BuildContext hostContext;

    await tester.pumpWidget(
      ValueListenableBuilder(
        valueListenable: themeMode,
        builder: (context, mode, child) {
          return MaterialApp(
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: mode,
            home: Builder(
              builder: (context) {
                hostContext = context;
                return const SizedBox.shrink();
              },
            ),
          );
        },
      ),
    );

    final result = showBusyMarkModalDialog<void>(
      hostContext,
      builder: (context) => const Dialog(child: Text('Theme-aware dialog')),
    );
    await tester.pumpAndSettle();

    Color? currentBarrierColor() {
      return tester
          .widget<AnimatedModalBarrier>(find.byType(AnimatedModalBarrier).last)
          .color
          .value;
    }

    expect(
      currentBarrierColor(),
      lightTheme.extension<BusyMarkSurfaceColors>()!.shade,
    );

    themeMode.value = ThemeMode.dark;
    await tester.pumpAndSettle();

    expect(
      currentBarrierColor(),
      darkTheme.extension<BusyMarkSurfaceColors>()!.shade,
    );

    themeMode.value = ThemeMode.light;
    await tester.pumpAndSettle();

    expect(
      currentBarrierColor(),
      lightTheme.extension<BusyMarkSurfaceColors>()!.shade,
    );

    Navigator.of(hostContext, rootNavigator: true).pop();
    await tester.pumpAndSettle();
    await result;
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

class _FailingModalBarrierService extends LinuxHeaderBarService {
  final transitions = <int>[];
  var _failNextShow = true;

  @override
  Future<void> setModalBarrierDepth(int value) async {
    transitions.add(value);
    if (value > 0 && _failNextShow) {
      _failNextShow = false;
      throw StateError('simulated native modal-barrier failure');
    }
  }
}
