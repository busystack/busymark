import 'dart:async';

import 'package:busymark/src/app/app_router.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/busymark_app.dart';
import 'package:busymark/src/app/system_accent.dart';
import 'package:busymark/src/platform/linux_header_bar_service.dart';
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

  testWidgets(
    'startup and updated production light/dark themes consume GTK accent',
    (tester) async {
      const first = Color(0xff336699);
      const second = Color(0xff7764d8);
      final gtk = FakeAccentSource(() async => first);
      final io = FakePortalIO();
      final coordinator = LinuxAccentCoordinator(
        sources: [
          gtk,
          LinuxPortalAppearance(open: () => io),
        ],
      );
      final initialized = coordinator.initialize();
      await tester.pump();
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
    },
  );
}

class _MemorySettings implements LocalSettingsStore {
  @override
  Future<Map<String, Object?>> load() async => {};
  @override
  Future<void> save(Map<String, Object?> json) async {}
}
