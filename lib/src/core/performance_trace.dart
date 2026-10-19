import 'dart:developer';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:uuid/uuid.dart';

import 'debug_log.dart';

final class _Timespec extends Struct {
  @Long()
  external int seconds;
  @Long()
  external int nanoseconds;
}

typedef _ClockNative = Int32 Function(Int32, Pointer<_Timespec>);
typedef _ClockDart = int Function(int, Pointer<_Timespec>);

/// Compiled out of ordinary builds. Linux timestamps use CLOCK_MONOTONIC,
/// matching GLib and the external observer; FrameTiming is logged as durations
/// only, never treated as a display-presentation or monotonic-clock timestamp.
abstract final class PerformanceTrace {
  static const enabled = bool.fromEnvironment('BUSYMARK_PERFORMANCE_TRACE');
  static const _ids = Uuid();
  static final _clock = Platform.isLinux
      ? DynamicLibrary.open(
          'libc.so.6',
        ).lookupFunction<_ClockNative, _ClockDart>('clock_gettime')
      : null;

  static void event(String name, [String phase = 'point']) {
    _event(name, phase, null);
  }

  static void _event(String name, String phase, String? span) {
    if (!enabled) return;
    final clock = _clock;
    var timestamp = Timeline.now;
    if (clock != null) {
      final value = calloc<_Timespec>();
      try {
        if (clock(1, value) != 0) throw StateError('clock_gettime failed');
        timestamp = value.ref.seconds * 1000000 + value.ref.nanoseconds ~/ 1000;
      } finally {
        calloc.free(value);
      }
    }
    final identity = span == null ? '' : ' pid=$pid span=$span';
    busyMarkPerformanceLogLine(
      'busymark-dart $name $phase time_us=$timestamp$identity',
    );
  }

  static Future<T> async<T>(String name, Future<T> Function() operation) {
    if (!enabled) return operation();
    return _async(name, operation);
  }

  static Future<T> _async<T>(
    String name,
    Future<T> Function() operation,
  ) async {
    final task = TimelineTask()..start(name);
    // Product engines may return zero for every TimelineTask ID. Diagnostic
    // identity must also be independent of isolate-local counters.
    final id = _ids.v4();
    _event(name, 'begin', id);
    try {
      return await operation();
    } finally {
      _event(name, 'end', id);
      task.finish();
    }
  }

  static T sync<T>(String name, T Function() operation) {
    if (!enabled) return operation();
    final id = _ids.v4();
    Timeline.startSync(name);
    _event(name, 'begin', id);
    try {
      return operation();
    } finally {
      _event(name, 'end', id);
      Timeline.finishSync();
    }
  }
}
