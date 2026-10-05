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
  LinuxAccentCoordinator({
    required List<LinuxAccentSource> sources,
    this.initializationDeadline = linuxAccentInitializationDeadline,
  }) : _sources = sources,
       _values = List<Color?>.filled(sources.length, null),
       _resolved = List<bool>.filled(sources.length, false),
       _deadlines = List<Timer?>.filled(sources.length, null);

  final Duration initializationDeadline;
  final List<LinuxAccentSource> _sources;
  final List<Color?> _values;
  final List<bool> _resolved;
  final List<Timer?> _deadlines;
  final _changes = StreamController<Color>.broadcast(sync: true);
  final _subscriptions = <StreamSubscription<Color?>>[];
  final _ready = Completer<void>();
  Future<void>? _disposal;
  bool _started = false;
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

  Future<void> initialize() {
    if (!_started && !_disposed) {
      _started = true;
      for (var index = 0; index < _sources.length; index++) {
        void update(Color? value) {
          if (_disposed) return;
          _resolved[index] = true;
          _values[index] = value;
          _deadlines[index]?.cancel();
          _recompute();
        }

        try {
          _subscriptions.add(
            _sources[index].watchAccentColor().listen(
              update,
              onError: (Object _, StackTrace _) => update(null),
              onDone: () {
                if (!_resolved[index]) update(null);
              },
            ),
          );
          // Subscribe first: a source's own per-setting deadline must have an
          // opportunity to publish its retained fallback before this safety net.
          if (!_resolved[index]) {
            _deadlines[index] = Timer(initializationDeadline, () {
              if (!_disposed && !_resolved[index]) update(null);
            });
          }
        } on Object {
          update(null);
        }
      }
      _recompute();
    }
    return _ready.future;
  }

  void _recompute() {
    var ready = true;
    Color? selected;
    for (var index = 0; index < _sources.length; index++) {
      if (!_resolved[index]) {
        ready = false;
        break;
      }
      if (_values[index] != null) {
        selected = _values[index];
        break;
      }
    }
    final color = selected ?? busyMarkDefaultAccentColor;
    if (color != _color) {
      _color = color;
      _changes.add(color);
    }
    if (ready && !_ready.isCompleted) _ready.complete();
  }

  Future<void> dispose() => _disposal ??= _dispose();

  Future<void> _dispose() async {
    _disposed = true;
    for (final deadline in _deadlines) {
      deadline?.cancel();
    }
    if (!_ready.isCompleted) _ready.complete();
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
  const LinuxPortalAppearance({
    LinuxPortalAccentIO Function()? open,
    this.initializationDeadline = linuxAccentInitializationDeadline,
  }) : _open = open ?? _openPortal;
  final LinuxPortalAccentIO Function() _open;
  final Duration initializationDeadline;

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
    var namedResolved = false;
    var rgbResolved = false;
    var namedGeneration = 0;
    var rgbGeneration = 0;
    Timer? namedDeadline;
    Timer? rgbDeadline;
    var cancelled = false;
    void publish() {
      if (cancelled || !namedResolved) return;
      if (named != null || rgbResolved) controller.add(named ?? rgb);
    }

    void resolveNamed(Color? value) {
      if (cancelled) return;
      named = value;
      namedResolved = true;
      namedDeadline?.cancel();
      publish();
    }

    void resolveRgb(Color? value) {
      if (cancelled) return;
      rgb = value;
      rgbResolved = true;
      rgbDeadline?.cancel();
      publish();
    }

    void initialize() {
      try {
        final session = io = _open();
        final initialNamedGeneration = namedGeneration;
        final initialRgbGeneration = rgbGeneration;
        subscription = session.changes.listen(
          (change) {
            if (change.key != 'accent-color') return;
            if (change.namespace == gnomeInterface) {
              namedGeneration++;
              resolveNamed(colorFromUbuntuAccentNameValue(change.value));
            } else if (change.namespace == freedesktopAppearance) {
              rgbGeneration++;
              resolveRgb(colorFromPortalAccentValue(change.value));
            }
          },
          onError: (Object _, StackTrace _) {
            // A malformed signal cannot resolve either setting or end native updates.
          },
        );
        namedDeadline = Timer(initializationDeadline, () {
          if (!cancelled &&
              !namedResolved &&
              namedGeneration == initialNamedGeneration) {
            resolveNamed(null);
          }
        });
        rgbDeadline = Timer(initializationDeadline, () {
          if (!cancelled &&
              !rgbResolved &&
              rgbGeneration == initialRgbGeneration) {
            resolveRgb(null);
          }
        });
        // Resolve each read independently. A valid named result is ready even
        // when RGB never responds; generic data waits for named unavailability.
        unawaited(
          _readAccentSafely(session.readNamed).then((value) {
            if (!cancelled && namedGeneration == initialNamedGeneration) {
              resolveNamed(value);
            }
          }),
        );
        unawaited(
          _readAccentSafely(session.readRgb).then((value) {
            if (!cancelled && rgbGeneration == initialRgbGeneration) {
              resolveRgb(value);
            }
          }),
        );
      } on Object {
        namedDeadline?.cancel();
        rgbDeadline?.cancel();
        namedResolved = rgbResolved = true;
        publish();
      }
    }

    controller = StreamController<Color?>(
      onListen: initialize,
      onCancel: () async {
        cancelled = true;
        namedDeadline?.cancel();
        rgbDeadline?.cancel();
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
