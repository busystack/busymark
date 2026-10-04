import 'dart:async';

import 'package:busymark/src/app/system_accent.dart';
import 'package:busymark/src/platform/linux_gtk_accent_service.dart';
import 'package:dbus/dbus.dart';
import 'package:flutter/material.dart';

class FakeAccentSource implements LinuxAccentSource {
  FakeAccentSource(this.snapshot);
  final Future<Color?> Function() snapshot;
  int listens = 0;
  int cancels = 0;
  late final events = StreamController<Color?>.broadcast(
    sync: true,
    onListen: () => listens++,
    onCancel: () => cancels++,
  );
  @override
  Stream<Color?> watchAccentColor() =>
      watchInitializedAccent(read: snapshot, changes: () => events.stream);
}

class FakePortalIO implements LinuxPortalAccentIO {
  FakePortalIO({this.named, this.rgb});
  Color? named;
  Color? rgb;
  Completer<Color?>? namedRead;
  Completer<Color?>? rgbRead;
  bool subscribedBeforeReads = true;
  int closes = 0;
  late final signals =
      StreamController<
        ({String namespace, String key, DBusValue value})
      >.broadcast(sync: true);
  @override
  Stream<({String namespace, String key, DBusValue value})> get changes =>
      signals.stream;
  @override
  Future<Color?> readNamed() async {
    subscribedBeforeReads &= signals.hasListener;
    return namedRead == null ? named : await namedRead!.future;
  }

  @override
  Future<Color?> readRgb() async {
    subscribedBeforeReads &= signals.hasListener;
    return rgbRead == null ? rgb : await rgbRead!.future;
  }

  void change(
    String namespace,
    DBusValue value, {
    String key = 'accent-color',
  }) {
    signals.add((namespace: namespace, key: key, value: value));
  }

  @override
  Future<void> close() async {
    closes++;
  }
}
