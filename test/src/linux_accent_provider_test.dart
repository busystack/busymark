import 'dart:async';

import 'package:busymark/src/app/app_router.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/busymark_app.dart';
import 'package:busymark/src/app/system_accent.dart';
import 'package:busymark/src/platform/linux_header_bar_service.dart';
import 'package:dbus/dbus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yaru/yaru.dart';

import '../support/linux_accent_fakes.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'production provider consumes an older GTK accent without portals',
    (tester) async {
      const channel = MethodChannel('com.busymark.app/gtk_accent');
      const events = MethodChannel('com.busymark.app/gtk_accent/events');
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async => {
          'available': true,
          'rgb': [0.2, 0.4, 0.6],
        },
      );
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        events,
        (_) async => null,
      );
      final io =
          FakePortalIO(); // Ubuntu 24.04: neither portal key is available.
      final container = ProviderContainer(
        overrides: [
          linuxAccentPlatformProvider.overrideWithValue(true),
          linuxPortalAccentSourceProvider.overrideWithValue(
            LinuxPortalAppearance(open: () => io),
          ),
        ],
      );
      final subscription = container.listen(
        systemAccentColorProvider,
        (_, _) {},
      );
      await tester.pump();
      expect(
        container.read(systemAccentColorProvider).value,
        const Color(0xff336699),
      );
      await binding.defaultBinaryMessenger.handlePlatformMessage(
        events.name,
        const StandardMethodCodec().encodeSuccessEnvelope({
          'available': true,
          'rgb': [0.0, 0.6, 0.0],
        }),
        (_) {},
      );
      await tester.pump();
      expect(
        container.read(systemAccentColorProvider).value,
        const Color(0xff009900),
      );
      final coordinator = container.read(linuxAccentCoordinatorProvider);
      subscription.close();
      await tester.runAsync(() async {
        container.dispose();
        await coordinator.dispose();
      });
      await tester.pump();
      expect(io.closes, 1);
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
      binding.defaultBinaryMessenger.setMockMethodCallHandler(events, null);
      await io.signals.close();
    },
  );

  testWidgets('non-Linux never creates platform listeners', (tester) async {
    final gtk = FakeAccentSource(() => throw StateError('must not read GTK'));
    final portal = FakeAccentSource(
      () => throw StateError('must not read portal'),
    );
    final container = ProviderContainer(
      overrides: [
        linuxAccentPlatformProvider.overrideWithValue(false),
        linuxGtkAccentSourceProvider.overrideWithValue(gtk),
        linuxPortalAccentSourceProvider.overrideWithValue(portal),
      ],
    );
    final subscription = container.listen(systemAccentColorProvider, (_, _) {});
    await tester.pump();
    expect(
      container.read(systemAccentColorProvider).value,
      busyMarkDefaultAccentColor,
    );
    expect(gtk.listens, 0);
    expect(portal.listens, 0);
    subscription.close();
    container.dispose();
  });

  testWidgets(
    'missing native snapshot uses portal, then native events regain priority',
    (tester) async {
      const channel = MethodChannel('com.busymark.app/gtk_accent');
      const events = MethodChannel('com.busymark.app/gtk_accent/events');
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => throw MissingPluginException(),
      );
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        events,
        (_) async => null,
      );
      final io = FakePortalIO(
        named: YaruVariant.purple.color,
        rgb: const Color(0xff112233),
      );
      final container = ProviderContainer(
        overrides: [
          linuxAccentPlatformProvider.overrideWithValue(true),
          linuxPortalAccentSourceProvider.overrideWithValue(
            LinuxPortalAppearance(open: () => io),
          ),
        ],
      );
      final subscription = container.listen(
        systemAccentColorProvider,
        (_, _) {},
      );
      await tester.pump();
      expect(
        container.read(systemAccentColorProvider).value,
        YaruVariant.purple.color,
      );
      Future<void> native(Object payload) =>
          binding.defaultBinaryMessenger.handlePlatformMessage(
            events.name,
            const StandardMethodCodec().encodeSuccessEnvelope(payload),
            (_) {},
          );
      await native({
        'available': true,
        'rgb': [0.2, 0.4, 0.6],
      });
      await tester.pump();
      expect(
        container.read(systemAccentColorProvider).value,
        const Color(0xff336699),
      );
      await native({'available': false});
      await tester.pump();
      expect(
        container.read(systemAccentColorProvider).value,
        YaruVariant.purple.color,
      );
      await native({
        'available': true,
        'rgb': [0.0, 0.6, 0.0],
      });
      await tester.pump();
      expect(
        container.read(systemAccentColorProvider).value,
        const Color(0xff009900),
      );
      final coordinator = container.read(linuxAccentCoordinatorProvider);
      subscription.close();
      await tester.runAsync(() async {
        container.dispose();
        await coordinator.dispose();
      });
      expect(io.closes, 1);
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
      binding.defaultBinaryMessenger.setMockMethodCallHandler(events, null);
      await io.signals.close();
    },
  );

  for (final scenario in [
    'GTK with silent portals',
    'named with silent RGB',
    'pending GTK before deadline',
    'pending GTK at deadline',
    'pending named becomes valid',
    'pending named becomes unavailable',
    'pending named at deadline',
    'all silent at deadline',
  ]) {
    testWidgets('first application frame and live light/dark themes: $scenario', (
      tester,
    ) async {
      const gtkColor = Color(0xff336699);
      const second = Color(0xff7764d8);
      const deadline = Duration(milliseconds: 100);
      final snapshot = Completer<Color?>();
      final gtk = FakeAccentSource(
        () => snapshot.future,
        initializationDeadline: deadline,
      );
      final io = FakePortalIO()
        ..namedRead = Completer<Color?>()
        ..rgbRead = Completer<Color?>();
      Color first;
      switch (scenario) {
        case 'GTK with silent portals':
          snapshot.complete(gtkColor);
          first = gtkColor;
        case 'named with silent RGB':
          snapshot.complete(null);
          io.namedRead!.complete(YaruVariant.purple.color);
          first = YaruVariant.purple.color;
        case 'pending GTK before deadline':
          io.namedRead!.complete(YaruVariant.purple.color);
          first = gtkColor;
        case 'pending GTK at deadline':
          io.namedRead!.complete(YaruVariant.purple.color);
          first = YaruVariant.purple.color;
        case 'pending named becomes valid':
          snapshot.complete(null);
          first = YaruVariant.purple.color;
        case 'pending named becomes unavailable':
        case 'pending named at deadline':
          snapshot.complete(null);
          first = gtkColor; // RGB signal is retained until named is resolved.
        case 'all silent at deadline':
          first = busyMarkDefaultAccentColor;
        default:
          throw StateError(scenario);
      }
      final coordinator = LinuxAccentCoordinator(
        initializationDeadline: deadline,
        sources: [
          gtk,
          LinuxPortalAppearance(
            open: () => io,
            initializationDeadline: deadline,
          ),
        ],
      );
      var ready = false;
      final initialized = coordinator.initialize().then((_) => ready = true);
      if (scenario.startsWith('pending named')) {
        io.change(
          LinuxPortalAppearance.freedesktopAppearance,
          portalRgb(0.2, 0.4, 0.6),
        );
      }
      await tester.pump();
      if (scenario.startsWith('pending') || scenario.startsWith('all silent')) {
        expect(ready, isFalse);
      }
      if (scenario == 'pending GTK before deadline') {
        await tester.pump(deadline - const Duration(milliseconds: 1));
        expect(ready, isFalse);
        snapshot.complete(gtkColor);
      } else if (scenario == 'pending named becomes valid') {
        io.namedRead!.complete(YaruVariant.purple.color);
      } else if (scenario == 'pending named becomes unavailable') {
        io.namedRead!.complete(null);
      } else if (scenario.endsWith('at deadline')) {
        await tester.pump(deadline);
      }
      await tester.pump();
      expect(ready, isTrue);
      await initialized;
      final header = LinuxHeaderBarService(
        channel: const MethodChannel('test.busymark/headerbar'),
      );
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Accent test')),
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          linuxAccentPlatformProvider.overrideWithValue(true),
          // The same pre-frame handoff as main; the production stream provider runs.
          linuxAccentCoordinatorProvider.overrideWith((ref) {
            ref.onDispose(() => unawaited(coordinator.dispose()));
            return coordinator;
          }),
          initialSystemAccentColorProvider.overrideWithValue(coordinator.color),
          localSettingsStoreProvider.overrideWithValue(_MemorySettings()),
          linuxHeaderBarServiceProvider.overrideWithValue(header),
          appRouterProvider.overrideWithValue(router),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BusyMarkApp(),
        ),
      );
      void expectThemes(Color accent) {
        final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
        expect(app.theme!.colorScheme.primary, accent);
        expect(app.darkTheme!.colorScheme.primary, accent);
      }

      expectThemes(
        first,
      ); // Includes the first frame, before StreamProvider data.
      gtk.events.add(second);
      await tester.pump();
      await tester.pump();
      expectThemes(second);
      // Lower-priority activity remains owned and cannot overwrite live GTK.
      io.change(
        LinuxPortalAppearance.gnomeInterface,
        const DBusString('green'),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expectThemes(second);
      // Rebuilds must retain one native and one portal listener.
      container
          .read(appSettingsControllerProvider.notifier)
          .setThemeModePreference(BusyMarkThemeModePreference.dark);
      await tester.pump();
      expectThemes(second);
      container
          .read(appSettingsControllerProvider.notifier)
          .setThemeModePreference(BusyMarkThemeModePreference.light);
      await tester.pump();
      expectThemes(second);
      gtk.events.add(null);
      await tester.pump();
      await tester.pump();
      expectThemes(YaruVariant.adwaitaGreen.color);
      gtk.events.add(second);
      await tester.pump();
      await tester.pump();
      expectThemes(second);
      expect(gtk.listens, 1);
      expect(io.signals.hasListener, isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        container.dispose();
        await coordinator.dispose();
      });
      await tester.pump();
      expect(gtk.cancels, 1);
      expect(io.closes, 1);
      router.dispose();
      header.dispose();
      await gtk.events.close();
      await io.signals.close();
    });
  }
  testWidgets(
    'application scope teardown cancels unresolved startup deadlines',
    (tester) async {
      final gtk = FakeAccentSource(() => Completer<Color?>().future);
      final io = FakePortalIO()
        ..namedRead = Completer<Color?>()
        ..rgbRead = Completer<Color?>();
      late LinuxAccentCoordinator coordinator;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            linuxAccentPlatformProvider.overrideWithValue(true),
            linuxGtkAccentSourceProvider.overrideWithValue(gtk),
            linuxPortalAccentSourceProvider.overrideWithValue(
              LinuxPortalAppearance(open: () => io),
            ),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              ref.watch(systemAccentColorProvider);
              coordinator = ref.read(linuxAccentCoordinatorProvider);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(gtk.listens, 1);
      expect(io.listens, 1);
      await tester.pumpWidget(const SizedBox());
      expect(gtk.cancels, 1);
      expect(io.cancels, 1);
      // Flush the provider owner's root-zone cleanup and virtual-clock events.
      final disposed = coordinator.dispose();
      await tester.runAsync(() async {});
      await tester.pump();
      await tester.runAsync(() async {});
      await tester.pump();
      await disposed;
      expect(io.closes, 1);
      await gtk.events.close();
      await io.signals.close();
    },
  );
}

class _MemorySettings implements LocalSettingsStore {
  @override
  Future<Map<String, Object?>> load() async => {};
  @override
  Future<void> save(Map<String, Object?> json) async {}
}
