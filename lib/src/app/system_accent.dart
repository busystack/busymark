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
        readFreedesktop: () => _readFreedesktopAccent(object),
        readGnome: () => _readGnomeAccentName(object),
      );
    } finally {
      await client.close();
    }
  }

  Stream<Color> accentColorChanges() async* {
    final client = DBusClient.session();
    try {
      final object = _portalObject(client);
      final freedesktopAccent = await _readAccentSafely(
        () => _readFreedesktopAccent(object),
      );
      final resolver = LinuxAccentChangeResolver(
        freedesktopAuthoritative: freedesktopAccent != null,
      );
      if (freedesktopAccent != null) {
        yield freedesktopAccent;
      } else {
        final gnomeAccent = await _readAccentSafely(
          () => _readGnomeAccentName(object),
        );
        if (gnomeAccent != null) {
          yield gnomeAccent;
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

/// Reads the exact freedesktop RGB value first, while keeping the Ubuntu
/// named-accent setting as an independent fallback for older portals.
@visibleForTesting
Future<Color?> readPreferredLinuxAccentColor({
  required Future<Color?> Function() readFreedesktop,
  required Future<Color?> Function() readGnome,
}) async {
  final freedesktopAccent = await _readAccentSafely(readFreedesktop);
  if (freedesktopAccent != null) {
    return freedesktopAccent;
  }
  return _readAccentSafely(readGnome);
}

Future<Color?> _readAccentSafely(Future<Color?> Function() read) async {
  try {
    return await read();
  } on Object {
    return null;
  }
}

/// Resolves portal change signals without allowing an approximate named color
/// to replace an exact RGB value once the modern freedesktop key is available.
@visibleForTesting
class LinuxAccentChangeResolver {
  LinuxAccentChangeResolver({bool freedesktopAuthoritative = false})
    : _freedesktopAuthoritative = freedesktopAuthoritative;

  bool _freedesktopAuthoritative;

  Color? resolve(String namespace, DBusValue value) {
    if (namespace == LinuxPortalAppearance._freedesktopAppearance) {
      final color = colorFromPortalAccentValue(value);
      if (color != null) {
        _freedesktopAuthoritative = true;
      }
      return color;
    }
    if (namespace == LinuxPortalAppearance._gnomeInterface &&
        !_freedesktopAuthoritative) {
      return colorFromUbuntuAccentNameValue(value);
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
