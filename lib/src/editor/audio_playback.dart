import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum AudioPlaybackState {
  ready,
  opening,
  playing,
  paused,
  buffering,
  ended,
  failed,
}

class AudioPlayback extends ChangeNotifier {
  AudioPlayback() {
    _channel.setMethodCallHandler(_nativeEvent);
  }

  static final shared = AudioPlayback();
  static const _channel = MethodChannel('com.busymark.app/audio_player');

  Object? _owner;
  int _serial = 0;
  int? _nativeId;
  Timer? _poll;
  bool _querying = false;
  AudioPlaybackState state = AudioPlaybackState.ready;
  double position = 0;
  double? duration;
  bool seekable = false;
  double volume = 1;
  double rate = 1;
  bool mute = false;
  bool loop = false;

  bool owns(Object owner) => owner == _owner;
  bool get running =>
      state == AudioPlaybackState.playing ||
      state == AudioPlaybackState.buffering ||
      state == AudioPlaybackState.opening;

  Future<bool> open(
    Object owner,
    File file, {
    bool muted = false,
    bool looping = false,
  }) async {
    final previous = _nativeId;
    final id = ++_serial;
    _owner = owner;
    _nativeId = id;
    state = AudioPlaybackState.opening;
    position = 0;
    duration = null;
    seekable = false;
    mute = muted;
    loop = looping;
    volume = rate = 1;
    notifyListeners();
    if (previous != null) await _call('close', previous);
    if (_nativeId != id) return false;
    final ok = await _call('open', id, {
      'path': file.path,
      'mute': muted,
      'loop': looping,
    });
    if (!ok && _nativeId == id) {
      state = AudioPlaybackState.failed;
      notifyListeners();
    }
    return ok && _nativeId == id;
  }

  Future<void> toggle(Object owner) async {
    final id = _nativeId;
    if (!owns(owner) || id == null) return;
    if (state == AudioPlaybackState.ended) await seek(owner, 0);
    if (!owns(owner) || _nativeId != id) return;
    if (await _call(running ? 'pause' : 'play', id) &&
        _nativeId == id &&
        !running) {
      state = AudioPlaybackState.opening;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    final id = _nativeId;
    if (id != null && running && await _call('pause', id) && _nativeId == id) {
      state = AudioPlaybackState.paused;
      notifyListeners();
    }
  }

  Future<void> close(Object owner) async {
    if (!owns(owner)) return;
    final id = _nativeId;
    _nativeId = null;
    _owner = null;
    _poll?.cancel();
    _poll = null;
    state = AudioPlaybackState.ready;
    notifyListeners();
    if (id != null) await _call('close', id);
  }

  Future<void> seek(Object owner, double target, {double? speed}) async {
    final id = _nativeId;
    if (!owns(owner) || id == null || !seekable) return;
    if (await _call('seek', id, {'position': target, 'rate': speed ?? rate}) &&
        _nativeId == id) {
      position = target;
      rate = speed ?? rate;
      notifyListeners();
    }
  }

  Future<void> configure(
    Object owner, {
    double? level,
    bool? muted,
    bool? looping,
  }) async {
    final id = _nativeId;
    if (!owns(owner) || id == null) return;
    final nextVolume = level ?? volume;
    final nextMute = muted ?? mute;
    final nextLoop = looping ?? loop;
    if (await _call('audio', id, {
          'volume': nextVolume,
          'mute': nextMute,
          'loop': nextLoop,
        }) &&
        _nativeId == id) {
      volume = nextVolume;
      mute = nextMute;
      loop = nextLoop;
      notifyListeners();
    }
  }

  Future<bool> _call(String method, int id, [Map<String, Object>? data]) async {
    try {
      return await _channel.invokeMethod<bool>(method, {'id': id, ...?data}) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> _nativeEvent(MethodCall call) async {
    final payload = call.arguments;
    if (call.method != 'state' ||
        payload is! Map ||
        payload['id'] != _nativeId) {
      return;
    }
    final next = AudioPlaybackState.values
        .where((value) => value.name == payload['state'])
        .firstOrNull;
    if (next == null) return;
    state = next;
    final id = _nativeId!;
    _poll?.cancel();
    _poll =
        next == AudioPlaybackState.playing ||
            next == AudioPlaybackState.buffering
        ? Timer.periodic(const Duration(milliseconds: 250), (_) {
            unawaited(_readPosition(id));
          })
        : null;
    notifyListeners();
    if (next != AudioPlaybackState.failed) await _readPosition(id);
  }

  Future<void> _readPosition(int id) async {
    if (_querying || _nativeId != id) return;
    _querying = true;
    try {
      final result = await _channel.invokeMapMethod<String, Object?>(
        'position',
        {'id': id},
      );
      if (result == null || _nativeId != id) return;
      final newPosition = result['position'];
      final newDuration = result['duration'];
      if (newPosition is double && newPosition.isFinite && newPosition >= 0) {
        position = newPosition;
      }
      duration =
          newDuration is double && newDuration.isFinite && newDuration >= 0
          ? newDuration
          : null;
      seekable = result['seekable'] == true;
      notifyListeners();
    } on PlatformException {
      // A native session can close while a position query is in flight.
    } on MissingPluginException {
      // This runner does not provide a native audio service.
    } on TypeError {
      // The native session was replaced before the query was serviced.
    } finally {
      _querying = false;
    }
  }
}
