import 'dart:async';
import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaru/yaru.dart';

final busyMarkDefaultAccentColor = YaruVariant.orange.color;

final initialSystemAccentColorProvider = Provider<Color>(
  (ref) => busyMarkDefaultAccentColor,
);

final systemAccentColorProvider = StreamProvider<Color>((ref) async* {
  final fallback = ref.watch(initialSystemAccentColorProvider);
  var current = fallback;
  yield current;

  if (!Platform.isLinux) {
    return;
  }

  final appearance = LinuxPortalAppearance();
  final initial = await appearance.readAccentColor();
  if (initial != null && initial != current) {
    current = initial;
    yield initial;
  }
  await for (final color in appearance.accentColorChanges()) {
    if (color == current) {
      continue;
    }
    current = color;
    yield color;
  }
});

class LinuxPortalAppearance {
  const LinuxPortalAppearance();

  static const _portalDestination = 'org.freedesktop.portal.Desktop';
  static const _portalPath = '/org/freedesktop/portal/desktop';
  static const _settingsInterface = 'org.freedesktop.portal.Settings';
  static const _freedesktopAppearance = 'org.freedesktop.appearance';
  static const _gnomeInterface = 'org.gnome.desktop.interface';
  static const _accentColor = 'accent-color';

  Future<Color?> readAccentColor() async {
    final client = DBusClient.session();
    try {
      final object = _portalObject(client);
      return await readPreferredLinuxAccentColor(
        readGnome: () => _readGnomeAccentName(object),
        readFreedesktop: () => _readFreedesktopAccent(object),
      );
    } finally {
      await client.close();
    }
  }

  Stream<Color> accentColorChanges() async* {
    final client = DBusClient.session();
    try {
      final object = _portalObject(client);
      final gnomeAccent = await _readAccentSafely(
        () => _readGnomeAccentName(object),
      );
      final resolver = LinuxAccentChangeResolver(
        gnomeAuthoritative: gnomeAccent != null,
      );
      if (gnomeAccent != null) {
        yield gnomeAccent;
      } else {
        final freedesktopAccent = await _readAccentSafely(
          () => _readFreedesktopAccent(object),
        );
        if (freedesktopAccent != null) {
          yield freedesktopAccent;
        }
      }
      final signals = DBusRemoteObjectSignalStream(
        object: object,
        interface: _settingsInterface,
        name: 'SettingChanged',
        signature: DBusSignature('ssv'),
      );
      await for (final signal in signals) {
        final namespace = signal.values[0].asString();
        final key = signal.values[1].asString();
        if (key != _accentColor) {
          continue;
        }
        final color = resolver.resolve(namespace, signal.values[2].asVariant());
        if (color != null) {
          yield color;
        }
      }
    } on Object {
      return;
    } finally {
      await client.close();
    }
  }

  DBusRemoteObject _portalObject(DBusClient client) {
    return DBusRemoteObject(
      client,
      name: _portalDestination,
      path: DBusObjectPath(_portalPath),
    );
  }

  Future<Color?> _readFreedesktopAccent(DBusRemoteObject object) async {
    final value = await _readSetting(
      object,
      _freedesktopAppearance,
      _accentColor,
    );
    return value == null ? null : colorFromPortalAccentValue(value);
  }

  Future<Color?> _readGnomeAccentName(DBusRemoteObject object) async {
    final value = await _readSetting(object, _gnomeInterface, _accentColor);
    return value == null ? null : colorFromUbuntuAccentNameValue(value);
  }

  Future<DBusValue?> _readSetting(
    DBusRemoteObject object,
    String namespace,
    String key,
  ) async {
    final response = await object.callMethod(_settingsInterface, 'Read', [
      DBusString(namespace),
      DBusString(key),
    ], replySignature: DBusSignature('v'));
    return response.returnValues.single.asVariant();
  }
}

/// Resolves the Yaru accent selected by Ubuntu before consulting the generic
/// freedesktop RGB fallback.
///
/// Ubuntu's portal exposes both values, but its generic RGB is an Adwaita
/// palette color and can differ from the active Yaru GTK theme. The named
/// setting maps to the same [YaruVariant] used by native GTK controls.
@visibleForTesting
Future<Color?> readPreferredLinuxAccentColor({
  required Future<Color?> Function() readGnome,
  required Future<Color?> Function() readFreedesktop,
}) async {
  final gnomeAccent = await _readAccentSafely(readGnome);
  if (gnomeAccent != null) {
    return gnomeAccent;
  }
  return _readAccentSafely(readFreedesktop);
}

Future<Color?> _readAccentSafely(Future<Color?> Function() read) async {
  try {
    return await read();
  } on Object {
    return null;
  }
}

/// Resolves portal changes without allowing the generic freedesktop palette to
/// replace the Yaru variant that owns native GTK controls.
@visibleForTesting
class LinuxAccentChangeResolver {
  LinuxAccentChangeResolver({bool gnomeAuthoritative = false})
    : _gnomeAuthoritative = gnomeAuthoritative;

  bool _gnomeAuthoritative;

  Color? resolve(String namespace, DBusValue value) {
    if (namespace == LinuxPortalAppearance._gnomeInterface) {
      final color = colorFromUbuntuAccentNameValue(value);
      if (color != null) {
        _gnomeAuthoritative = true;
      }
      return color;
    }
    if (namespace == LinuxPortalAppearance._freedesktopAppearance &&
        !_gnomeAuthoritative) {
      return colorFromPortalAccentValue(value);
    }
    return null;
  }
}

Color? colorFromPortalAccentValue(DBusValue value) {
  final resolved = value.signature == DBusSignature('v')
      ? value.asVariant()
      : value;
  if (resolved.signature != DBusSignature('(ddd)')) {
    return null;
  }
  final channels = resolved.asStruct();
  if (channels.length != 3) {
    return null;
  }
  final red = _colorChannel(channels[0].asDouble());
  final green = _colorChannel(channels[1].asDouble());
  final blue = _colorChannel(channels[2].asDouble());
  return Color.fromARGB(255, red, green, blue);
}

Color? colorFromUbuntuAccentNameValue(DBusValue value) {
  final resolved = value.signature == DBusSignature('v')
      ? value.asVariant()
      : value;
  if (resolved.signature != DBusSignature('s')) {
    return null;
  }
  return ubuntuAccentNameColor(resolved.asString());
}

Color? ubuntuAccentNameColor(String name) {
  return switch (name) {
    'blue' => YaruVariant.blue.color,
    'teal' => YaruVariant.adwaitaTeal.color,
    'green' => YaruVariant.adwaitaGreen.color,
    'yellow' => YaruVariant.adwaitaYellow.color,
    'orange' => YaruVariant.orange.color,
    'red' => YaruVariant.red.color,
    'pink' => YaruVariant.magenta.color,
    'purple' => YaruVariant.purple.color,
    'slate' => YaruVariant.adwaitaSlate.color,
    'brown' || 'wartybrown' => YaruVariant.wartyBrown.color,
    'magenta' => YaruVariant.magenta.color,
    'olive' => YaruVariant.olive.color,
    'prussiangreen' => YaruVariant.prussianGreen.color,
    'sage' => YaruVariant.sage.color,
    _ => null,
  };
}

int _colorChannel(double value) {
  return (value.clamp(0, 1) * 255).round();
}
