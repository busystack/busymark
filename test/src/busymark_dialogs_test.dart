import 'package:busymark/src/app/command_registry.dart';
import 'package:busymark/src/app/keymap_controller.dart';
import 'package:busymark/src/app/shortcut_binding.dart';
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

import '../support/desktop_focus.dart';

void main() {
  _delayedModalFocusRegressions();
  testWidgets('delayed modal barrier release respects a newer focus owner', (
    tester,
  ) async {
    const channel = MethodChannel('com.busymark.test/focus-modal-barrier');
    final release = Completer<void>();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'initialize') return true;
      if (call.method == 'setModalBarrierDepth' && call.arguments == 0) {
        await release.future;
      }
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    final service = LinuxHeaderBarService(channel: channel);
    await service.initialize();
    final previous = FocusNode();
    final newer = FocusNode();
    addTearDown(previous.dispose);
    addTearDown(newer.dispose);
    late BuildContext host;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            host = context;
            return Scaffold(
              body: Column(
                children: [
                  TextField(focusNode: previous),
                  TextField(focusNode: newer),
                ],
              ),
            );
          },
        ),
      ),
    );
    previous.requestFocus();
    await tester.pumpAndSettle();
    final result = showBusyMarkModalDialog<void>(
      host,
      headerBarService: service,
      builder: (_) => const Text('Modal focus test'),
    );
    await tester.pumpAndSettle();
    Navigator.of(host, rootNavigator: true).pop();
    await tester.pumpAndSettle();
    newer.requestFocus();
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, same(newer));
    release.complete();
    await result;
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, same(newer));
  });

  testWidgets(
    'modal text input preserves local editing when an application binding overlaps it',
    (tester) async {
      var executed = 0;
      final registry = effectiveCommandRegistry(
        BusyMarkCommandCatalog.create(
          executions: {BusyMarkCommandIds.newDocument: () => executed++},
        ),
        {
          'file.newDocument': const BusyMarkKeyBinding(
            LogicalKeyboardKey.keyA,
            control: true,
          ),
          'text.selectAll': null,
        },
      );
      final text = TextEditingController(text: 'local modal input');
      addTearDown(text.dispose);
      late BuildContext host;
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => BusyMarkCommandRegistryScope(
            registry: registry,
            child: Shortcuts(
              shortcuts: registry.shortcutIntents(
                scopes: {BusyMarkCommandScope.application},
                intentFor: BusyMarkCommandIntent.new,
              ),
              child: Actions(
                actions: {
                  BusyMarkCommandIntent: CallbackAction<BusyMarkCommandIntent>(
                    onInvoke: (i) {
                      registry.execute(i.commandId);
                      return null;
                    },
                  ),
                },
                child: child!,
              ),
            ),
          ),
          home: Builder(
            builder: (c) {
              host = c;
              return const SizedBox();
            },
          ),
        ),
      );
      final dialog = showBusyMarkModalDialog<void>(
        host,
        builder: (_) =>
            Dialog(child: TextField(controller: text, autofocus: true)),
      );
      await tester.pumpAndSettle();
      text.selection = const TextSelection.collapsed(offset: 1);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(
        text.selection,
        TextSelection(baseOffset: 0, extentOffset: text.text.length),
      );
      expect(executed, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await dialog;
    },
  );

  testWidgets('modal dialogs stop app and editor shortcuts', (tester) async {
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
    var editorShortcutInvocations = 0;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => Shortcuts(
          shortcuts: <ShortcutActivator, Intent>{
            BusyMarkAppShortcuts.nextTab.activator: const _AppShortcutIntent(),
            BusyMarkAppShortcuts.previousTab.activator:
                const _AppShortcutIntent(),
            BusyMarkAppShortcuts.closeTab.activator: const _AppShortcutIntent(),
            BusyMarkEditorShortcuts.heading1.activator:
                const _EditorShortcutIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              _AppShortcutIntent: CallbackAction<_AppShortcutIntent>(
                onInvoke: (_) {
                  appShortcutInvocations += 1;
                  return null;
                },
              ),
              _EditorShortcutIntent: CallbackAction<_EditorShortcutIntent>(
                onInvoke: (_) {
                  editorShortcutInvocations += 1;
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
    expect(editorShortcutInvocations, 0);
    expect(find.text('Dismiss'), findsOneWidget);
  });

  testWidgets('Escape closes a modal without an initially focused control', (
    tester,
  ) async {
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

    final result = showBusyMarkModalDialog<void>(
      hostContext,
      barrierDismissible: false,
      builder: (_) => const Dialog(child: Text('Modal content')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Modal content'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Modal content'), findsNothing);
    await result;
  });

  testWidgets('modal fallback does not steal a child autofocus request', (
    tester,
  ) async {
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

    final result = showBusyMarkModalDialog<void>(
      hostContext,
      builder: (_) => const Dialog(
        child: TextField(
          autofocus: true,
          decoration: InputDecoration(labelText: 'Modal input'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final input = tester.widget<EditableText>(find.byType(EditableText));
    expect(input.focusNode.hasPrimaryFocus, isTrue);

    Navigator.of(tester.element(find.byType(Dialog))).pop();
    await tester.pumpAndSettle();
    await result;
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
    expect(transitions, [
      1,
    ], reason: 'the native hide must wait for the in-flight native show');

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

class _EditorShortcutIntent extends Intent {
  const _EditorShortcutIntent();
}

void _delayedModalFocusRegressions() {
  for (final scenario in [
    'inactive editor',
    'inactive newer owner',
    'resumed newer owner',
    'newer owner before close',
    'newer owner then scope',
    'disposed host',
    'ordinary return',
  ]) {
    testWidgets('deferred modal focus respects $scenario', (tester) async {
      enableDesktopFocusLifecycle(tester);
      final barrier = _GatedFocusBarrierService();
      addTearDown(barrier.dispose);
      addTearDown(() {
        if (!barrier.release.isCompleted) barrier.release.complete();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
      });
      final previous = FocusNode(debugLabel: 'Previous editor');
      final newer = FocusNode(debugLabel: 'Newer search control');
      final text = TextEditingController(text: 'search');
      addTearDown(previous.dispose);
      addTearDown(newer.dispose);
      addTearDown(text.dispose);
      late BuildContext host;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              host = context;
              return Scaffold(
                body: Column(
                  children: [
                    TextField(focusNode: previous),
                    TextField(focusNode: newer, controller: text),
                  ],
                ),
              );
            },
          ),
        ),
      );
      previous.requestFocus();
      await tester.pumpAndSettle();
      final dialog = showBusyMarkModalDialog<void>(
        host,
        headerBarService: barrier,
        builder: (_) => const AlertDialog(content: Text('Dismiss focus race')),
      );
      await tester.pumpAndSettle();
      Navigator.of(host, rootNavigator: true).pop();
      if (scenario == 'newer owner before close') {
        newer.requestFocus();
        FocusManager.instance.applyFocusChangesIfNeeded();
      }
      await tester.pumpAndSettle();
      expect(barrier.releaseStarted, isTrue);
      if (scenario.contains('newer')) {
        newer.requestFocus();
        await tester.pumpAndSettle();
        expect(FocusManager.instance.primaryFocus, same(newer));
      }
      final inactive = scenario.startsWith('inactive');
      if (inactive || scenario == 'resumed newer owner') {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        expect(
          FocusManager.instance.primaryFocus,
          same(FocusManager.instance.rootScope),
        );
        for (var frame = 0; frame < 30; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        if (!inactive) {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.pumpAndSettle();
          expect(FocusManager.instance.primaryFocus, same(newer));
        }
      }
      if (scenario == 'newer owner then scope') {
        newer.unfocus();
        await tester.pumpAndSettle();
      }
      if (scenario == 'disposed host') {
        await tester.pumpWidget(const SizedBox());
      }
      final owner = FocusManager.instance.primaryFocus;
      barrier.release.complete();
      await dialog;
      for (var frame = 0; frame < 30; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(FocusManager.instance.primaryFocus, same(owner));
      }
      if (inactive) {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        expect(
          FocusManager.instance.primaryFocus,
          same(scenario.contains('newer') ? newer : previous),
        );
      }
      if (scenario.contains('newer') && scenario != 'newer owner then scope') {
        expect(tester.testTextInput.hasAnyClients, isTrue);
        tester.testTextInput.updateEditingValue(
          const TextEditingValue(
            text: 'search!',
            selection: TextSelection.collapsed(offset: 7),
          ),
        );
        await tester.pumpAndSettle();
        expect(text.text, 'search!');
      }
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
  }
}

class _GatedFocusBarrierService extends LinuxHeaderBarService {
  _GatedFocusBarrierService()
    : super(channel: const MethodChannel('com.busymark.test/deferred-focus'));

  final release = Completer<void>();
  bool releaseStarted = false;

  @override
  Future<void> setModalBarrierDepth(int depth) async {
    if (depth == 0) {
      releaseStarted = true;
      await release.future;
    }
  }
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
