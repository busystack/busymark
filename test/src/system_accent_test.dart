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

  test('falls back to the Ubuntu setting when the RGB read fails', () async {
    var readGnome = false;

    final color = await readPreferredLinuxAccentColor(
      readFreedesktop: () => Future<Color?>.error(
        StateError('freedesktop accent key is unavailable'),
      ),
      readGnome: () async {
        readGnome = true;
        return YaruVariant.orange.color;
      },
    );

    expect(color, YaruVariant.orange.color);
    expect(readGnome, isTrue);
  });

  test('does not read the named fallback after an exact RGB result', () async {
    var readGnome = false;
    const exactRgb = Color(0xFF336699);

    final color = await readPreferredLinuxAccentColor(
      readFreedesktop: () async => exactRgb,
      readGnome: () async {
        readGnome = true;
        return YaruVariant.blue.color;
      },
    );

    expect(color, exactRgb);
    expect(readGnome, isFalse);
  });

  test('an exact RGB signal remains authoritative over named signals', () {
    final resolver = LinuxAccentChangeResolver();
    final exactRgb = DBusStruct([
      const DBusDouble(0.2),
      const DBusDouble(0.4),
      const DBusDouble(0.6),
    ]);

    expect(
      resolver.resolve(
        'org.gnome.desktop.interface',
        const DBusString('orange'),
      ),
      YaruVariant.orange.color,
    );
    expect(
      resolver.resolve('org.freedesktop.appearance', exactRgb),
      const Color(0xFF336699),
    );
    expect(
      resolver.resolve('org.gnome.desktop.interface', const DBusString('blue')),
      isNull,
    );
  });
}
