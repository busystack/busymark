import 'dart:async';

import 'package:flutter/services.dart';

/// All Linux accent reads start concurrently. Unresolved sources/settings get
/// five seconds, matching rich_clipboard_service.dart's platform I/O timeout.
/// Expiry makes them temporarily unavailable; watchers and unsuperseded late
/// reads remain active and can restore their normal precedence.
const linuxAccentInitializationDeadline = Duration(seconds: 5);

/// Each subscription owns its initialization and platform listener. Null means
/// the source currently has no usable accent, rather than a default color.
abstract interface class LinuxAccentSource {
  Stream<Color?> watchAccentColor();
}

class LinuxGtkAccentService implements LinuxAccentSource {
  const LinuxGtkAccentService({
    MethodChannel channel = const MethodChannel('com.busymark.app/gtk_accent'),
    EventChannel events = const EventChannel(
      'com.busymark.app/gtk_accent/events',
    ),
    this.initializationDeadline = linuxAccentInitializationDeadline,
  }) : _channel = channel,
       _events = events;

  final Duration initializationDeadline;
  final MethodChannel _channel;
  final EventChannel _events;

  Future<Color?> readAccentColor() async {
    try {
      return colorFromGtkAccentPayload(
        await _channel.invokeMethod<Object?>('getAccent'),
      );
    } on Object {
      return null;
    }
  }

  @override
  Stream<Color?> watchAccentColor() => watchInitializedAccent(
    read: readAccentColor,
    changes: _watchEvents,
    initializationDeadline: initializationDeadline,
  );

  Stream<Color?> _watchEvents() {
    // EventChannel.receiveBroadcastStream reports listen/cancel failures to
    // FlutterError instead of its stream. Own this small event-channel protocol
    // so an absent Linux runner remains an ordinary unavailable source.
    final messenger = _events.binaryMessenger;
    final methods = MethodChannel(_events.name, _events.codec, messenger);
    late StreamController<Color?> controller;
    var cancelled = false;
    controller = StreamController<Color?>(
      onListen: () async {
        messenger.setMessageHandler(_events.name, (message) async {
          if (cancelled) return null;
          try {
            controller.add(
              message == null
                  ? null
                  : colorFromGtkAccentPayload(
                      _events.codec.decodeEnvelope(message),
                    ),
            );
          } on Object catch (error, stack) {
            controller.addError(error, stack);
          }
          return null;
        });
        try {
          await methods.invokeMethod<void>('listen');
        } on Object {
          if (!cancelled) controller.add(null);
        }
      },
      onCancel: () async {
        cancelled = true;
        messenger.setMessageHandler(_events.name, null);
        try {
          await methods.invokeMethod<void>('cancel');
        } on Object {
          // A missing channel also has no listener to cancel.
        }
      },
    );
    return controller.stream;
  }
}

Color? colorFromGtkAccentPayload(Object? payload) {
  if (payload is! Map || payload['available'] != true) return null;
  final rgb = payload['rgb'];
  if (rgb is! List || rgb.length != 3) return null;
  final channels = <int>[];
  for (final value in rgb) {
    if (value is! num || !value.isFinite || value < 0 || value > 1) {
      return null;
    }
    channels.add((value * 255).round());
  }
  return Color.fromARGB(255, channels[0], channels[1], channels[2]);
}

/// Attach before reading and reject a snapshot superseded by a change, even
/// when that change explicitly makes the source unavailable.
Stream<Color?> watchInitializedAccent({
  required Future<Color?> Function() read,
  required Stream<Color?> Function() changes,
  Duration initializationDeadline = linuxAccentInitializationDeadline,
}) {
  late StreamController<Color?> controller;
  StreamSubscription<Color?>? subscription;
  Timer? deadline;
  var resolved = false;
  var generation = 0;
  var cancelled = false;
  void changed(Color? color) {
    generation++;
    resolved = true;
    deadline?.cancel();
    if (!cancelled) controller.add(color);
  }

  Future<void> initialize() async {
    final snapshotGeneration = generation;
    try {
      subscription = changes().listen(
        changed,
        onError: (Object _, StackTrace _) => changed(null),
      );
    } on Object {
      changed(null);
    }
    if (!resolved) {
      deadline = Timer(initializationDeadline, () {
        if (!cancelled && !resolved && generation == snapshotGeneration) {
          // Do not advance the event generation: an unsuperseded late snapshot
          // can still recover the source after startup's deadline.
          resolved = true;
          controller.add(null);
        }
      });
    }
    Color? snapshot;
    try {
      snapshot = await read();
    } on Object {
      snapshot = null;
    }
    if (!cancelled && generation == snapshotGeneration) {
      resolved = true;
      deadline?.cancel();
      controller.add(snapshot);
    }
  }

  controller = StreamController<Color?>(
    onListen: () => unawaited(initialize()),
    onCancel: () async {
      cancelled = true;
      deadline?.cancel();
      await subscription?.cancel();
    },
  );
  return controller.stream.distinct();
}
