import 'dart:async';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/busymark_glyphs.dart';
import 'package:busymark/src/app/busymark_dialogs.dart';
import 'package:busymark/src/app/window_control_service.dart';
import 'package:busymark/src/app/linux/linux_header_style.dart';
import 'package:busymark/src/app/linux/linux_window_host.dart';
import 'package:busymark/src/platform/gtk_window_preferences_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaru/yaru.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const yaruWindowChannel = MethodChannel('yaru_window');
  const yaruEventsChannel = EventChannel('yaru_window/events');
  late List<MethodCall> windowCalls;
  late Map<String, Object?> nativeState;
  late MockStreamHandlerEventSink eventSink;
  late int eventListenCount;
  late int eventCancelCount;

  setUp(() {
    windowCalls = [];
    nativeState = <String, Object?>{};
    eventListenCount = 0;
    eventCancelCount = 0;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(yaruWindowChannel, (call) async {
      windowCalls.add(call);
      return call.method == 'state' ? nativeState : null;
    });
    messenger.setMockStreamHandler(
      yaruEventsChannel,
      MockStreamHandler.inline(
        onListen: (_, sink) {
          eventListenCount += 1;
          eventSink = sink;
        },
        onCancel: (_) {
          eventCancelCount += 1;
        },
      ),
    );
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(yaruWindowChannel, null);
    messenger.setMockStreamHandler(yaruEventsChannel, null);
  });

  testWidgets(
    'dialogs cover application header actions while system Close uses the guarded service',
    (tester) async {
      var headerActions = 0;
      final controls = _RecordingWindowControls();
      addTearDown(controls.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gtkWindowPreferencesProvider.overrideWith(
              (ref) => Stream.value(_closePreferences),
            ),
            windowControlServiceProvider.overrideWith((ref) => controls),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => LinuxWindowHost(child: child!),
            home: Builder(
              builder: (context) => Scaffold(
                body: Column(
                  children: [
                    BusyMarkLinuxHeaderLayout(
                      leading: TextButton(
                        key: const ValueKey('header-action'),
                        onPressed: () => headerActions++,
                        child: const Text('Header action'),
                      ),
                      title: const BusyMarkLinuxHeaderTitle('Workspace'),
                      trailing: const SizedBox.shrink(),
                    ),
                    Expanded(
                      child: Center(
                        child: TextButton(
                          onPressed: () => unawaited(
                            showBusyMarkModalDialog<void>(
                              context,
                              barrierDismissible: false,
                              builder: (_) => const AlertDialog(
                                content: Text('Window modal'),
                              ),
                            ),
                          ),
                          child: const Text('Open modal'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final headerPoint = tester.getCenter(
        find.byKey(const ValueKey('header-action')),
      );
      await tester.tap(find.text('Open modal'));
      await tester.pumpAndSettle();
      await tester.tapAt(headerPoint);
      await tester.pump();
      expect(headerActions, 0);
      expect(find.text('Window modal'), findsOneWidget);
      await tester.tap(find.byType(YaruWindowControl));
      await tester.pump();
      expect(controls.closeRequests, 1);
      expect(windowCalls.where((call) => call.method == 'close'), isEmpty);
    },
  );

  testWidgets('icon uses its physical GTK side and contributes to the inset', (
    tester,
  ) async {
    const preferences = GtkWindowPreferences(
      decorationLayout: GtkDecorationLayout(
        left: [
          GtkWindowDecorationElement.windowIcon,
          GtkWindowDecorationElement.minimize,
        ],
        right: [GtkWindowDecorationElement.close],
      ),
      doubleClick: GtkTitlebarAction.toggleMaximize,
      middleClick: GtkTitlebarAction.none,
      rightClick: GtkTitlebarAction.menu,
    );

    await _pumpHost(
      tester,
      preferences: preferences,
      locale: const Locale('ar'),
    );

    final left = find.byKey(const ValueKey('linux-window-controls-left'));
    final right = find.byKey(const ValueKey('linux-window-controls-right'));
    expect(left, findsOneWidget);
    expect(right, findsOneWidget);
    expect(
      find.descendant(of: left, matching: find.byType(SvgPicture)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: right, matching: find.byType(SvgPicture)),
      findsNothing,
    );
    expect(tester.getRect(left).left, 0);
    expect(tester.getRect(right).right, 800);

    final metrics = LinuxWindowMetricsScope.of(
      tester.element(find.byKey(const ValueKey('metrics-probe'))),
    );
    expect(
      metrics.leftControlInset,
      BusyMarkLinuxWindowMetrics.clusterWidth(
        preferences.decorationLayout.left,
      ),
    );
    expect(
      metrics.rightControlInset,
      BusyMarkLinuxWindowMetrics.clusterWidth(
        preferences.decorationLayout.right,
      ),
    );

    final leftControls = find.descendant(
      of: left,
      matching: find.byType(YaruWindowControl),
    );
    expect(leftControls, findsOneWidget);
    expect(
      tester.getCenter(find.byType(SvgPicture)).dx,
      lessThan(tester.getCenter(leftControls).dx),
    );
  });

  testWidgets(
    'fallback application menu is absent while titlebar menu still works',
    (tester) async {
      const preferences = GtkWindowPreferences(
        decorationLayout: GtkDecorationLayout(
          left: [GtkWindowDecorationElement.fallbackApplicationMenu],
          right: [GtkWindowDecorationElement.close],
        ),
        doubleClick: GtkTitlebarAction.toggleMaximize,
        middleClick: GtkTitlebarAction.none,
        rightClick: GtkTitlebarAction.menu,
      );
      await _pumpHost(
        tester,
        preferences: preferences,
        child: const LinuxTitlebarGestureRegion(
          child: SizedBox(
            key: ValueKey('titlebar-drag-region'),
            width: 180,
            height: 46,
          ),
        ),
      );

      expect(find.byIcon(BusyMarkGlyphs.menuVertical), findsNothing);
      expect(windowCalls.where((call) => call.method == 'showMenu'), isEmpty);
      final metrics = LinuxWindowMetricsScope.of(
        tester.element(find.byKey(const ValueKey('metrics-probe'))),
      );
      expect(metrics.leftControlInset, 0);

      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('titlebar-drag-region'))),
        buttons: kSecondaryMouseButton,
      );
      await tester.pump();

      expect(
        windowCalls.where((call) => call.method == 'showMenu'),
        hasLength(1),
      );
    },
  );

  testWidgets('window-state stream survives unrelated host rebuilds', (
    tester,
  ) async {
    final preferences = StreamController<GtkWindowPreferences>();
    addTearDown(preferences.close);
    final harnessKey = GlobalKey<_HostHarnessState>();

    await _pumpHost(
      tester,
      preferencesStream: preferences.stream,
      harnessKey: harnessKey,
    );
    final initialStateCalls = _callCount(windowCalls, 'state');
    expect(initialStateCalls, 1);
    expect(eventListenCount, 1);

    preferences.add(
      const GtkWindowPreferences(
        decorationLayout: GtkDecorationLayout(
          left: [GtkWindowDecorationElement.windowIcon],
          right: [GtkWindowDecorationElement.maximize],
        ),
        doubleClick: GtkTitlebarAction.minimize,
        middleClick: GtkTitlebarAction.none,
        rightClick: GtkTitlebarAction.menu,
      ),
    );
    await tester.pump();
    await tester.pump();
    harnessKey.currentState!
      ..rebuildParent()
      ..toggleTheme()
      ..toggleLocale();
    await tester.pump();

    expect(_callCount(windowCalls, 'state'), initialStateCalls);
    expect(eventListenCount, 1);
    expect(eventCancelCount, 0);

    await _sendState(tester, eventSink, <String, Object?>{
      'active': true,
      'maximized': true,
      'restorable': true,
    });

    final control = tester.widget<YaruWindowControl>(
      find.byType(YaruWindowControl),
    );
    expect(control.type, YaruWindowControlType.restore);
    expect(_callCount(windowCalls, 'state'), initialStateCalls);
  });

  for (final scenario
      in <(String, Map<String, Object?>, YaruWindowControlType, String)>[
        (
          'normal',
          <String, Object?>{'maximizable': true},
          YaruWindowControlType.maximize,
          'maximize',
        ),
        (
          'maximized',
          <String, Object?>{'maximized': true, 'restorable': true},
          YaruWindowControlType.restore,
          'restore',
        ),
        (
          'fullscreen',
          <String, Object?>{'fullscreen': true, 'restorable': true},
          YaruWindowControlType.restore,
          'restore',
        ),
      ]) {
    testWidgets('${scenario.$1} maximize decoration has matching behavior', (
      tester,
    ) async {
      nativeState = scenario.$2;
      await _pumpHost(tester, preferences: _maximizePreferences);

      final controlFinder = find.byType(YaruWindowControl);
      final control = tester.widget<YaruWindowControl>(controlFinder);
      expect(control.type, scenario.$3);
      expect(
        find.bySemanticsLabel(
          scenario.$3 == YaruWindowControlType.restore ? 'Restore' : 'Maximize',
        ),
        findsWidgets,
      );

      await tester.tap(controlFinder);
      await tester.pump();

      expect(_callCount(windowCalls, scenario.$4), 1);
      if (scenario.$1 == 'fullscreen') {
        expect(_callCount(windowCalls, 'maximize'), 0);
      }
    });
  }

  testWidgets('fullscreen titlebar double-click still restores', (
    tester,
  ) async {
    nativeState = <String, Object?>{'fullscreen': true, 'restorable': true};
    await _pumpHost(
      tester,
      preferences: _maximizePreferences,
      child: const LinuxTitlebarGestureRegion(
        child: SizedBox(
          key: ValueKey('titlebar-double-click-region'),
          width: 180,
          height: 46,
        ),
      ),
    );

    final region = find.byKey(const ValueKey('titlebar-double-click-region'));
    await tester.tapAt(tester.getCenter(region));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(tester.getCenter(region));
    await tester.pump(const Duration(milliseconds: 50));

    expect(_callCount(windowCalls, 'restore'), 1);
    expect(_callCount(windowCalls, 'maximize'), 0);
  });

  testWidgets('the document title itself handles titlebar double-click', (
    tester,
  ) async {
    await _pumpHost(
      tester,
      preferences: _maximizePreferences,
      child: const BusyMarkLinuxHeaderTitle('document.md'),
    );
    final title = find.text('document.md');
    await tester.tap(title);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(title);
    await tester.pump(const Duration(milliseconds: 50));
    expect(_callCount(windowCalls, 'maximize'), 1);
  });

  testWidgets('live GTK layout removal retains each decoration identity', (
    tester,
  ) async {
    final preferences = StreamController<GtkWindowPreferences>();
    addTearDown(preferences.close);
    await _pumpHost(tester, preferencesStream: preferences.stream);
    preferences.add(
      GtkWindowPreferences.fromMessage(const {
        'decorationLayout': ':minimize,maximize,close',
      }),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    Finder maximize() => find.byWidgetPredicate(
      (widget) =>
          widget is YaruWindowControl &&
          widget.type == YaruWindowControlType.maximize,
    );
    final originalState = tester.state(maximize());
    double progress() {
      final paint = tester.widget<CustomPaint>(
        find.descendant(of: maximize(), matching: find.byType(CustomPaint)),
      );
      final dynamic painter = paint.painter;
      return painter.progress as double;
    }

    expect(progress(), 0);
    preferences.add(
      GtkWindowPreferences.fromMessage(const {
        'decorationLayout': ':maximize,close',
      }),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(progress(), 0);
    expect(tester.state(maximize()), same(originalState));
    await tester.tap(maximize());
    expect(_callCount(windowCalls, 'maximize'), 1);
  });

  for (final gtkPolicy in [false, true]) {
    testWidgets(
      'reduced motion settles maximize and restore icons (GTK=$gtkPolicy)',
      (tester) async {
        await _pumpHost(
          tester,
          preferences: _maximizePreferences,
          disableAnimations: !gtkPolicy,
          gtkAnimationsEnabled: !gtkPolicy,
        );
        await tester.pumpAndSettle();
        await _sendState(tester, eventSink, {
          'maximized': true,
          'restorable': true,
        });
        await tester.pump();
        expect(tester.hasRunningAnimations, isFalse);
        await tester.tap(find.bySemanticsLabel('Restore').first);
        expect(_callCount(windowCalls, 'restore'), 1);
        await _sendState(tester, eventSink, {
          'maximized': false,
          'maximizable': true,
        });
        await tester.pump();
        expect(tester.hasRunningAnimations, isFalse);
        await tester.tap(find.bySemanticsLabel('Maximize').first);
        expect(_callCount(windowCalls, 'maximize'), 1);
      },
    );
  }

  testWidgets('GTK reduced motion settles window-control hover immediately', (
    tester,
  ) async {
    await _pumpHost(
      tester,
      preferences: _closePreferences,
      gtkAnimationsEnabled: false,
    );
    await tester.pumpAndSettle();
    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer(location: Offset.zero);
    addTearDown(pointer.removePointer);
    final onSurface = Theme.of(
      tester.element(find.byType(YaruWindowControl)),
    ).colorScheme.onSurface;
    Color background() => tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byKey(const ValueKey('linux-window-controls-right')),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((widget) => widget.decoration)
        .whereType<BoxDecoration>()
        .where(
          (decoration) =>
              decoration.shape == BoxShape.circle &&
              decoration.color != Colors.transparent,
        )
        .single
        .color!;
    expect(background(), onSurface.withValues(alpha: .1));
    await pointer.moveTo(
      tester.getCenter(find.bySemanticsLabel('Close').first),
    );
    await tester.pump();
    // Check the painted control feedback; the separate Tooltip may fade.
    expect(background(), onSurface.withValues(alpha: .15));
    await pointer.moveTo(const Offset(200, 200));
    await tester.pump();
    expect(background(), onSurface.withValues(alpha: .1));
  });

  testWidgets(
    'enabling reduced motion settles an in-flight window icon morph',
    (tester) async {
      final harness = GlobalKey<_HostHarnessState>();
      await _pumpHost(
        tester,
        preferences: _maximizePreferences,
        harnessKey: harness,
      );
      await tester.pumpAndSettle();
      await _sendState(tester, eventSink, {
        'maximized': true,
        'restorable': true,
      });
      await tester.pump(const Duration(milliseconds: 375));
      expect(tester.hasRunningAnimations, isTrue);
      harness.currentState!.setDisableAnimations(true);
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      final paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(YaruWindowControl),
          matching: find.byType(CustomPaint),
        ),
      );
      final dynamic painter = paint.painter;
      expect(painter.progress, 1);
    },
  );

  testWidgets('enabled motion retains the normal active-window fade', (
    tester,
  ) async {
    nativeState = <String, Object?>{'active': true};
    await _pumpHost(tester, preferences: _closePreferences);
    expect(_controlAnimatedOpacity(tester).duration, BusyMarkMotion.fast);

    await _sendState(tester, eventSink, <String, Object?>{'active': false});
    await tester.pump(_half(BusyMarkMotion.fast));

    expect(_renderedControlOpacity(tester), inExclusiveRange(.5, 1));
    await tester.pumpAndSettle();
    expect(_renderedControlOpacity(tester), .5);
  });

  testWidgets('Flutter reduced motion settles the host fade immediately', (
    tester,
  ) async {
    nativeState = <String, Object?>{'active': true};
    await _pumpHost(
      tester,
      preferences: _closePreferences,
      disableAnimations: true,
    );

    await _sendState(tester, eventSink, <String, Object?>{'active': false});

    expect(_controlAnimatedOpacityFinder(), findsNothing);
    expect(_renderedControlOpacity(tester), .5);
  });

  testWidgets('GTK animation policy reaches the actual host overlay', (
    tester,
  ) async {
    nativeState = <String, Object?>{'active': true};
    await _pumpHost(
      tester,
      preferences: _closePreferences,
      gtkAnimationsEnabled: false,
    );

    final hostContext = tester.element(find.byType(LinuxWindowHost));
    expect(MediaQuery.disableAnimationsOf(hostContext), isTrue);
    expect(MediaQuery.alwaysUse24HourFormatOf(hostContext), isTrue);
    expect(_controlAnimatedOpacityFinder(), findsNothing);
  });

  testWidgets('enabling reduced motion stops a fade and later fades can run', (
    tester,
  ) async {
    nativeState = <String, Object?>{'active': true};
    final harnessKey = GlobalKey<_HostHarnessState>();
    await _pumpHost(
      tester,
      preferences: _closePreferences,
      harnessKey: harnessKey,
    );

    await _sendState(tester, eventSink, <String, Object?>{'active': false});
    await tester.pump(_half(BusyMarkMotion.fast));
    expect(_renderedControlOpacity(tester), inExclusiveRange(.5, 1));

    harnessKey.currentState!.setDisableAnimations(true);
    await tester.pump();
    expect(_controlAnimatedOpacityFinder(), findsNothing);
    expect(_renderedControlOpacity(tester), .5);

    harnessKey.currentState!.setDisableAnimations(false);
    await tester.pump();
    expect(_controlAnimatedOpacity(tester).duration, BusyMarkMotion.fast);
    expect(_renderedControlOpacity(tester), .5);

    await _sendState(tester, eventSink, <String, Object?>{'active': true});
    await tester.pump(_half(BusyMarkMotion.fast));
    expect(_renderedControlOpacity(tester), inExclusiveRange(.5, 1));
    await tester.pumpAndSettle();
    expect(_renderedControlOpacity(tester), 1);
  });
}

class _RecordingWindowControls extends WindowControlService {
  _RecordingWindowControls()
    : super(nativeWindow: const WindowManagerNativeWindowController());
  var closeRequests = 0;
  @override
  Future<void> requestClose() async => closeRequests++;
}

const _maximizePreferences = GtkWindowPreferences(
  decorationLayout: GtkDecorationLayout(
    left: [],
    right: [GtkWindowDecorationElement.maximize],
  ),
  doubleClick: GtkTitlebarAction.toggleMaximize,
  middleClick: GtkTitlebarAction.none,
  rightClick: GtkTitlebarAction.menu,
);

const _closePreferences = GtkWindowPreferences(
  decorationLayout: GtkDecorationLayout(
    left: [],
    right: [GtkWindowDecorationElement.close],
  ),
  doubleClick: GtkTitlebarAction.toggleMaximize,
  middleClick: GtkTitlebarAction.none,
  rightClick: GtkTitlebarAction.menu,
);

Future<void> _pumpHost(
  WidgetTester tester, {
  GtkWindowPreferences? preferences,
  Stream<GtkWindowPreferences>? preferencesStream,
  GlobalKey<_HostHarnessState>? harnessKey,
  Widget? child,
  Locale locale = const Locale('en'),
  bool disableAnimations = false,
  bool gtkAnimationsEnabled = true,
}) async {
  final stream =
      preferencesStream ?? Stream.value(preferences ?? _closePreferences);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [gtkWindowPreferencesProvider.overrideWith((ref) => stream)],
      child: _HostHarness(
        key: harnessKey,
        initialLocale: locale,
        initialDisableAnimations: disableAnimations,
        initialGtkAnimationsEnabled: gtkAnimationsEnabled,
        child: child,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void _emitState(MockStreamHandlerEventSink sink, Map<String, Object?> state) {
  sink.success(<String, Object?>{'id': 0, 'type': 'state', ...state});
}

Future<void> _sendState(
  WidgetTester tester,
  MockStreamHandlerEventSink sink,
  Map<String, Object?> state,
) async {
  _emitState(sink, state);
  await tester.runAsync(pumpEventQueue);
  await tester.pump();
}

int _callCount(List<MethodCall> calls, String method) =>
    calls.where((call) => call.method == method).length;

Duration _half(Duration duration) =>
    Duration(microseconds: duration.inMicroseconds ~/ 2);

Finder _controlAnimatedOpacityFinder() => find.byWidgetPredicate(
  (widget) =>
      widget is AnimatedOpacity &&
      widget.key == const ValueKey('linux-window-controls-opacity'),
);

AnimatedOpacity _controlAnimatedOpacity(WidgetTester tester) =>
    tester.widget<AnimatedOpacity>(
      find.byWidgetPredicate(
        (widget) =>
            widget is AnimatedOpacity &&
            widget.key == const ValueKey('linux-window-controls-opacity'),
      ),
    );

double _renderedControlOpacity(WidgetTester tester) {
  final opacity = find.byWidgetPredicate(
    (widget) =>
        widget is Opacity &&
        widget.key == const ValueKey('linux-window-controls-opacity'),
  );
  if (opacity.evaluate().isNotEmpty) {
    return tester.widget<Opacity>(opacity).opacity;
  }
  return tester
      .widget<FadeTransition>(
        find.descendant(
          of: find.byKey(const ValueKey('linux-window-controls-opacity')),
          matching: find.byType(FadeTransition),
        ),
      )
      .opacity
      .value;
}

class _HostHarness extends StatefulWidget {
  const _HostHarness({
    super.key,
    required this.initialLocale,
    required this.initialDisableAnimations,
    required this.initialGtkAnimationsEnabled,
    this.child,
  });

  final Locale initialLocale;
  final bool initialDisableAnimations;
  final bool initialGtkAnimationsEnabled;
  final Widget? child;

  @override
  State<_HostHarness> createState() => _HostHarnessState();
}

class _HostHarnessState extends State<_HostHarness> {
  late Locale locale = widget.initialLocale;
  late bool disableAnimations = widget.initialDisableAnimations;
  late bool gtkAnimationsEnabled = widget.initialGtkAnimationsEnabled;
  var dark = false;
  var rebuilds = 0;

  void rebuildParent() => setState(() => rebuilds += 1);
  void toggleTheme() => setState(() => dark = !dark);
  void toggleLocale() => setState(() {
    locale = locale.languageCode == 'en'
        ? const Locale('ar')
        : const Locale('en');
  });
  void setDisableAnimations(bool value) =>
      setState(() => disableAnimations = value);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: disableAnimations),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: true,
              disableAnimations: disableAnimations || !gtkAnimationsEnabled,
            ),
            child: LinuxWindowHost(
              child: Scaffold(
                body: Stack(
                  children: [
                    Center(child: Text('$rebuilds')),
                    const SizedBox(
                      key: ValueKey('metrics-probe'),
                      width: 1,
                      height: 1,
                    ),
                    if (widget.child case final child?) child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
