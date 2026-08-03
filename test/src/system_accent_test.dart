import 'package:busymark/src/app/system_accent.dart';
import 'package:dbus/dbus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaru/yaru.dart';

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
}
