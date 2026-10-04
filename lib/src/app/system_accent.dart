import 'dart:async';
import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaru/yaru.dart';

import '../platform/linux_gtk_accent_service.dart';

final busyMarkDefaultAccentColor = YaruVariant.orange.color;
final linuxAccentPlatformProvider = Provider<bool>((ref) => Platform.isLinux);
final linuxGtkAccentSourceProvider = Provider<LinuxAccentSource>(
  (ref) => const LinuxGtkAccentService(),
);
final linuxPortalAccentSourceProvider = Provider<LinuxAccentSource>(
  (ref) => const LinuxPortalAppearance(),
);

final linuxAccentCoordinatorProvider = Provider<LinuxAccentCoordinator>((ref) {
  final coordinator = LinuxAccentCoordinator(
    sources: ref.watch(linuxAccentPlatformProvider)
        ? [
            ref.watch(linuxGtkAccentSourceProvider),
            ref.watch(linuxPortalAccentSourceProvider),
          ]
        : [],
  );
  ref.onDispose(() => unawaited(coordinator.dispose()));
  unawaited(coordinator.initialize());
  return coordinator;
});

final initialSystemAccentColorProvider = Provider<Color>(
  (ref) => busyMarkDefaultAccentColor,
);

final systemAccentColorProvider = StreamProvider<Color>((ref) {
  if (!ref.watch(linuxAccentPlatformProvider)) {
    return Stream.value(ref.watch(initialSystemAccentColorProvider));
  }
  return ref.watch(linuxAccentCoordinatorProvider).colors;
});

/// Sources stay separate throughout startup and live updates. The list is in
/// priority order: GTK, then the portal's named-Yaru / generic-RGB fallback.
class LinuxAccentCoordinator {
  LinuxAccentCoordinator({required List<LinuxAccentSource> sources})
    : _sources = sources,
      _values = List<Color?>.filled(sources.length, null);

  final List<LinuxAccentSource> _sources;
  final List<Color?> _values;
  final _changes = StreamController<Color>.broadcast(sync: true);
  final _subscriptions = <StreamSubscription<Color?>>[];
  final _ready = <Completer<void>>[];
  Future<void>? _initialization;
  Future<void>? _disposal;
  bool _disposed = false;
  Color _color = busyMarkDefaultAccentColor;
  Color get color => _color;

  Stream<Color> get colors => Stream<Color>.multi((listener) {
    final subscription = _changes.stream.listen(
      listener.add,
      onDone: listener.close,
    );
    listener.add(_color);
    listener.onCancel = subscription.cancel;
  });

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    if (_disposed) return;
    final ready = <Future<void>>[];
    for (var index = 0; index < _sources.length; index++) {
      final first = Completer<void>();
      _ready.add(first);
      ready.add(first.future);
      void update(Color? value) {
        if (!first.isCompleted) first.complete();
        if (_disposed) return;
        _values[index] = value;
        final resolved =
            _values.whereType<Color>().firstOrNull ??
            busyMarkDefaultAccentColor;
        if (resolved != _color) {
          _color = resolved;
          _changes.add(resolved);
        }
      }

      try {
        _subscriptions.add(
          _sources[index].watchAccentColor().listen(
            update,
            onError: (Object _, StackTrace _) => update(null),
            onDone: () {
              if (!first.isCompleted) update(null);
            },
          ),
        );
      } on Object {
        update(null);
      }
    }
    await Future.wait(ready);
  }

  Future<void> dispose() => _disposal ??= _dispose();

  Future<void> _dispose() async {
    _disposed = true;
    for (final first in _ready) {
      if (!first.isCompleted) first.complete();
    }
    await Future.wait(
      _subscriptions.map((subscription) => subscription.cancel()),
    );
    await _changes.close();
  }
}

/// Injectable D-Bus boundary. A watch owns one session and closes it on cancel.
abstract interface class LinuxPortalAccentIO {
  Future<Color?> readNamed();
  Future<Color?> readRgb();
  Stream<({String namespace, String key, DBusValue value})> get changes;
  Future<void> close();
}

class LinuxPortalAppearance implements LinuxAccentSource {
  const LinuxPortalAppearance({LinuxPortalAccentIO Function()? open})
    : _open = open ?? _openPortal;
  final LinuxPortalAccentIO Function() _open;

  static const freedesktopAppearance = 'org.freedesktop.appearance';
  static const gnomeInterface = 'org.gnome.desktop.interface';

  Future<Color?> readAccentColor() async {
    final io = _open();
    try {
      return await readPreferredLinuxAccentColor(
        readGnome: io.readNamed,
        readFreedesktop: io.readRgb,
      );
    } finally {
      await io.close();
    }
  }

  @override
  Stream<Color?> watchAccentColor() => accentColorChanges();

  Stream<Color?> accentColorChanges() {
    late StreamController<Color?> controller;
    LinuxPortalAccentIO? io;
    StreamSubscription<({String namespace, String key, DBusValue value})>?
    subscription;
    Color? named;
    Color? rgb;
    var namedGeneration = 0;
    var rgbGeneration = 0;
    var cancelled = false;
    void publish() {
      if (!cancelled) controller.add(named ?? rgb);
    }

    Future<void> initialize() async {
      try {
        final session = io = _open();
        // D-Bus installs the signal match before these method calls. Each key
        // has its own generation so a change cannot be undone by either read.
        subscription = session.changes.listen(
          (change) {
            if (change.key != 'accent-color') return;
            if (change.namespace == gnomeInterface) {
              namedGeneration++;
              named = colorFromUbuntuAccentNameValue(change.value);
            } else if (change.namespace == freedesktopAppearance) {
              rgbGeneration++;
              rgb = colorFromPortalAccentValue(change.value);
            } else {
              return;
            }
            publish();
          },
          onError: (Object _, StackTrace _) {
            // A bad signal does not terminate the subscription or native source.
          },
        );
        final initialNamedGeneration = namedGeneration;
        final initialRgbGeneration = rgbGeneration;
        await Future.wait([
          _readAccentSafely(session.readNamed).then((value) {
            if (namedGeneration == initialNamedGeneration) named = value;
          }),
          _readAccentSafely(session.readRgb).then((value) {
            if (rgbGeneration == initialRgbGeneration) rgb = value;
          }),
        ]);
        publish();
      } on Object {
        publish();
      }
    }

    controller = StreamController<Color?>(
      onListen: () => unawaited(initialize()),
      onCancel: () async {
        cancelled = true;
        try {
          await subscription?.cancel();
        } finally {
          await io?.close();
        }
      },
    );
    return controller.stream.distinct();
  }
}

LinuxPortalAccentIO _openPortal() => _DBusPortalAccentIO();

class _DBusPortalAccentIO implements LinuxPortalAccentIO {
  final _client = DBusClient.session();
  late final _object = DBusRemoteObject(
    _client,
    name: 'org.freedesktop.portal.Desktop',
    path: DBusObjectPath('/org/freedesktop/portal/desktop'),
  );
  static const _settingsInterface = 'org.freedesktop.portal.Settings';

  @override
  Stream<({String namespace, String key, DBusValue value})> get changes =>
      DBusRemoteObjectSignalStream(
        object: _object,
        interface: _settingsInterface,
        name: 'SettingChanged',
        signature: DBusSignature('ssv'),
      ).map(
        (signal) => (
          namespace: signal.values[0].asString(),
          key: signal.values[1].asString(),
          value: signal.values[2].asVariant(),
        ),
      );

  Future<DBusValue> _read(String namespace) async {
    final response = await _object.callMethod(_settingsInterface, 'Read', [
      DBusString(namespace),
      const DBusString('accent-color'),
    ], replySignature: DBusSignature('v'));
    return response.returnValues.single.asVariant();
  }

  @override
  Future<Color?> readNamed() async => colorFromUbuntuAccentNameValue(
    await _read(LinuxPortalAppearance.gnomeInterface),
  );
  @override
  Future<Color?> readRgb() async => colorFromPortalAccentValue(
    await _read(LinuxPortalAppearance.freedesktopAppearance),
  );
  @override
  Future<void> close() => _client.close();
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

/// Retains both portal states so a missing named accent releases precedence.
@visibleForTesting
class LinuxAccentChangeResolver {
  LinuxAccentChangeResolver({bool gnomeAuthoritative = false})
    : _gnomeAuthoritative = gnomeAuthoritative;

  bool _gnomeAuthoritative;
  Color? _generic;

  Color? resolve(String namespace, DBusValue value) {
    if (namespace == LinuxPortalAppearance.gnomeInterface) {
      final color = colorFromUbuntuAccentNameValue(value);
      _gnomeAuthoritative = color != null;
      return color ?? _generic;
    }
    if (namespace == LinuxPortalAppearance.freedesktopAppearance) {
      _generic = colorFromPortalAccentValue(value);
      return _gnomeAuthoritative ? null : _generic;
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
  if (channels.any((channel) => !channel.asDouble().isFinite)) return null;
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
