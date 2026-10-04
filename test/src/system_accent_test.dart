import 'dart:async';

import 'package:busymark/src/app/system_accent.dart';
import 'package:dbus/dbus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaru/yaru.dart';

import '../support/linux_accent_fakes.dart';

void main() {
  test('uses the native Yaru orange accent as the offline fallback', () {
    expect(busyMarkDefaultAccentColor, YaruVariant.orange.color);
  });

  test('keeps exact RGB portal accent color values authoritative', () {
    final value = DBusStruct([
      const DBusDouble(0.7843137383460999),
      const DBusDouble(0.5333333611488342),
      const DBusDouble(0),
    ]);

    expect(colorFromPortalAccentValue(value), const Color(0xffc88800));
    expect(
      colorFromPortalAccentValue(DBusVariant(value)),
      const Color(0xffc88800),
    );
  });

  test('maps Ubuntu accent names when RGB portal value is unavailable', () {
    const expectedVariants = <String, YaruVariant>{
      'blue': YaruVariant.blue,
      'teal': YaruVariant.adwaitaTeal,
      'green': YaruVariant.adwaitaGreen,
      'yellow': YaruVariant.adwaitaYellow,
      'orange': YaruVariant.orange,
      'red': YaruVariant.red,
      'pink': YaruVariant.magenta,
      'purple': YaruVariant.purple,
      'slate': YaruVariant.adwaitaSlate,
      'brown': YaruVariant.wartyBrown,
      'wartybrown': YaruVariant.wartyBrown,
      'magenta': YaruVariant.magenta,
      'olive': YaruVariant.olive,
      'prussiangreen': YaruVariant.prussianGreen,
      'sage': YaruVariant.sage,
    };

    for (final MapEntry(:key, :value) in expectedVariants.entries) {
      expect(ubuntuAccentNameColor(key), value.color, reason: key);
    }
    expect(
      colorFromUbuntuAccentNameValue(const DBusString('purple')),
      YaruVariant.purple.color,
    );
    expect(colorFromUbuntuAccentNameValue(const DBusString('unknown')), isNull);
  });

  test('falls back to RGB when the Ubuntu accent is unavailable', () async {
    var readFreedesktop = false;
    const exactRgb = Color(0xFF336699);

    final color = await readPreferredLinuxAccentColor(
      readGnome: () =>
          Future<Color?>.error(StateError('Ubuntu accent key is unavailable')),
      readFreedesktop: () async {
        readFreedesktop = true;
        return exactRgb;
      },
    );

    expect(color, exactRgb);
    expect(readFreedesktop, isTrue);
  });

  test('Yaru accent wins over a different generic portal RGB', () async {
    var readFreedesktop = false;

    final color = await readPreferredLinuxAccentColor(
      readGnome: () async => YaruVariant.magenta.color,
      readFreedesktop: () async {
        readFreedesktop = true;
        return const Color(0xFFD56199);
      },
    );

    expect(color, const Color(0xFFB34CB3));
    expect(readFreedesktop, isFalse);
  });

  test('a Yaru accent signal remains authoritative over generic RGB', () {
    final resolver = LinuxAccentChangeResolver();
    final exactRgb = DBusStruct([
      const DBusDouble(0.2),
      const DBusDouble(0.4),
      const DBusDouble(0.6),
    ]);

    expect(
      resolver.resolve('org.freedesktop.appearance', exactRgb),
      const Color(0xFF336699),
    );
    expect(
      resolver.resolve(
        'org.gnome.desktop.interface',
        const DBusString('orange'),
      ),
      YaruVariant.orange.color,
    );
    expect(resolver.resolve('org.freedesktop.appearance', exactRgb), isNull);
  });
  test('an unavailable named accent releases the current generic RGB', () {
    final resolver = LinuxAccentChangeResolver();
    resolver.resolve(
      LinuxPortalAppearance.gnomeInterface,
      const DBusString('purple'),
    );
    resolver.resolve(
      LinuxPortalAppearance.freedesktopAppearance,
      DBusStruct([
        const DBusDouble(0.2),
        const DBusDouble(0.4),
        const DBusDouble(0.6),
      ]),
    );
    expect(
      resolver.resolve(
        LinuxPortalAppearance.gnomeInterface,
        const DBusString('unknown'),
      ),
      const Color(0xff336699),
    );
  });

  test(
    'portal subscribes before both reads and retains changes during reads',
    () async {
      final io = FakePortalIO()
        ..namedRead = Completer<Color?>()
        ..rgbRead = Completer<Color?>();
      final values = <Color?>[];
      final subscription = LinuxPortalAppearance(
        open: () => io,
      ).accentColorChanges().listen(values.add);
      expect(io.subscribedBeforeReads, isTrue);
      io.change(
        LinuxPortalAppearance.gnomeInterface,
        const DBusString('purple'),
      );
      io.change(
        LinuxPortalAppearance.freedesktopAppearance,
        DBusStruct([
          const DBusDouble(0.2),
          const DBusDouble(0.4),
          const DBusDouble(0.6),
        ]),
      );
      io.namedRead!.complete(YaruVariant.orange.color);
      io.rgbRead!.complete(const Color(0xff000000));
      await Future<void>.delayed(Duration.zero);
      expect(values, [YaruVariant.purple.color]);
      io.change(
        LinuxPortalAppearance.gnomeInterface,
        const DBusString('unknown'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(values.last, const Color(0xff336699));
      await subscription.cancel();
      expect(io.closes, 1);
      expect(io.signals.hasListener, isFalse);
      await io.signals.close();
    },
  );

  test(
    'missing portal keys, malformed signals, cancellation and resubscription',
    () async {
      final sessions = <FakePortalIO>[];
      final portal = LinuxPortalAppearance(
        open: () {
          final io = FakePortalIO();
          sessions.add(io);
          return io;
        },
      );
      final values = <Color?>[];
      var subscription = portal.accentColorChanges().listen(values.add);
      await Future<void>.delayed(Duration.zero);
      expect(values, [null]);
      sessions.single.signals.addError(StateError('malformed signal'));
      sessions.single.change(
        LinuxPortalAppearance.gnomeInterface,
        const DBusString('blue'),
        key: 'color-scheme',
      );
      sessions.single.change('unknown.namespace', const DBusString('blue'));
      sessions.single.change(
        LinuxPortalAppearance.gnomeInterface,
        const DBusString('green'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(values, [null, YaruVariant.adwaitaGreen.color]);
      await subscription.cancel();
      subscription = portal.accentColorChanges().listen(values.add);
      await Future<void>.delayed(Duration.zero);
      expect(sessions, hasLength(2));
      await subscription.cancel();
      for (final io in sessions) {
        expect(io.closes, 1);
        expect(io.signals.hasListener, isFalse);
        await io.signals.close();
      }
    },
  );

  test(
    'generic portal initialization cannot overwrite a newer generic change',
    () async {
      final io = FakePortalIO()..rgbRead = Completer<Color?>();
      final values = <Color?>[];
      final subscription = LinuxPortalAppearance(
        open: () => io,
      ).accentColorChanges().listen(values.add);
      io.change(
        LinuxPortalAppearance.freedesktopAppearance,
        DBusStruct([
          const DBusDouble(0.2),
          const DBusDouble(0.4),
          const DBusDouble(0.6),
        ]),
      );
      io.rgbRead!.complete(YaruVariant.orange.color);
      await Future<void>.delayed(Duration.zero);
      expect(values, [const Color(0xff336699)]);
      await subscription.cancel();
      await io.signals.close();
    },
  );

  for (final gtkFirst in [true, false]) {
    test(
      'GTK wins with gtkFirst=$gtkFirst; unavailability selects current portal',
      () async {
        const gtkColor = Color(0xff287b9c);
        final gtkRead = Completer<Color?>();
        final gtk = FakeAccentSource(() => gtkRead.future);
        final io = FakePortalIO()
          ..namedRead = Completer<Color?>()
          ..rgbRead = Completer<Color?>();
        final coordinator = LinuxAccentCoordinator(
          sources: [
            gtk,
            LinuxPortalAppearance(open: () => io),
          ],
        );
        final initialization = coordinator.initialize();
        final values = <Color>[];
        final subscription = coordinator.colors.listen(values.add);
        await Future<void>.delayed(Duration.zero);
        if (gtkFirst) gtkRead.complete(gtkColor);
        io.rgbRead!.complete(const Color(0xff112233));
        io.namedRead!.complete(YaruVariant.purple.color);
        await Future<void>.delayed(Duration.zero);
        if (!gtkFirst) gtkRead.complete(gtkColor);
        await initialization;
        expect(coordinator.color, gtkColor);
        io.change(
          LinuxPortalAppearance.freedesktopAppearance,
          DBusStruct([
            const DBusDouble(0),
            const DBusDouble(0.4),
            const DBusDouble(0),
          ]),
        );
        io.change(
          LinuxPortalAppearance.gnomeInterface,
          const DBusString('blue'),
        );
        await Future<void>.delayed(Duration.zero);
        expect(coordinator.color, gtkColor);
        gtk.events.add(null);
        await Future<void>.delayed(Duration.zero);
        expect(coordinator.color, YaruVariant.blue.color);
        io.change(
          LinuxPortalAppearance.gnomeInterface,
          const DBusString('unavailable'),
        );
        await Future<void>.delayed(Duration.zero);
        expect(coordinator.color, const Color(0xff006600));
        gtk.events.add(gtkColor);
        gtk.events.add(gtkColor);
        await Future<void>.delayed(Duration.zero);
        expect(coordinator.color, gtkColor);
        expect(values.last, gtkColor);
        expect(values.length, gtkFirst ? 5 : 6);
        await subscription.cancel();
        await coordinator.dispose();
        expect(gtk.listens, 1);
        expect(gtk.cancels, 1);
        expect(io.closes, 1);
        await gtk.events.close();
        await io.signals.close();
      },
    );
  }

  test(
    'source errors remain independent and healthy native updates continue',
    () async {
      final gtk = FakeAccentSource(() async => const Color(0xff336699));
      final portal = FakeAccentSource(
        () => Future.error(StateError('no portal')),
      );
      final coordinator = LinuxAccentCoordinator(sources: [gtk, portal]);
      await coordinator.initialize();
      expect(coordinator.color, const Color(0xff336699));
      portal.events.addError(StateError('portal disconnected'));
      gtk.events.add(const Color(0xff7764d8));
      await Future<void>.delayed(Duration.zero);
      expect(coordinator.color, const Color(0xff7764d8));
      gtk.events.addError(StateError('native disconnected'));
      portal.events.add(const Color(0xff123456));
      await Future<void>.delayed(Duration.zero);
      expect(coordinator.color, const Color(0xff123456));
      await coordinator.dispose();
      await gtk.events.close();
      await portal.events.close();
    },
  );

  test(
    'startup changes supersede native snapshots, including unavailable changes',
    () async {
      final snapshot = Completer<Color?>();
      final gtk = FakeAccentSource(() => snapshot.future);
      final portal = FakeAccentSource(() async => const Color(0xff112233));
      final coordinator = LinuxAccentCoordinator(sources: [gtk, portal]);
      final initialized = coordinator.initialize();
      gtk.events.add(const Color(0xff287b9c));
      await initialized;
      expect(coordinator.color, const Color(0xff287b9c));
      gtk.events.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(coordinator.color, const Color(0xff112233));
      snapshot.complete(const Color(0xff336699));
      await Future<void>.delayed(Duration.zero);
      expect(coordinator.color, const Color(0xff112233));
      await coordinator.dispose();
      await gtk.events.close();
      await portal.events.close();
    },
  );

  test(
    'disposal completes pending startup and cancels each owned source once',
    () async {
      final snapshot = Completer<Color?>();
      final gtk = FakeAccentSource(() => snapshot.future);
      final coordinator = LinuxAccentCoordinator(sources: [gtk]);
      final initialized = coordinator.initialize();
      await Future.wait([coordinator.dispose(), coordinator.dispose()]);
      await initialized;
      expect(gtk.listens, 1);
      expect(gtk.cancels, 1);
      expect(gtk.events.hasListener, isFalse);
      snapshot.complete(const Color(0xff336699));
      await Future<void>.delayed(Duration.zero);
      expect(coordinator.color, busyMarkDefaultAccentColor);
      await gtk.events.close();
    },
  );
}
