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

enum AudioStreamFeed { waiting, accepted, failed }

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
  bool streamed = false;
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
  }) => _open(owner, file: file, muted: muted, looping: looping);

  Future<bool> openStream(Object owner, {bool muted = false}) =>
      _open(owner, muted: muted, looping: false);

  Future<bool> _open(
    Object owner, {
    File? file,
    required bool muted,
    required bool looping,
  }) async {
    final previous = _nativeId;
    final id = ++_serial;
    _owner = owner;
    _nativeId = id;
    state = AudioPlaybackState.opening;
    position = 0;
    duration = null;
    seekable = false;
    streamed = file == null;
    mute = muted;
    loop = looping;
    volume = rate = 1;
    notifyListeners();
    if (previous != null) await _call('close', previous);
    if (_nativeId != id) return false;
    final ok = await _call(file == null ? 'openStream' : 'open', id, {
      if (file != null) 'path': file.path,
      'mute': muted,
      'loop': looping,
    });
    if (!ok && _nativeId == id) {
      state = AudioPlaybackState.failed;
      notifyListeners();
    }
    return ok && _nativeId == id;
  }

  Future<AudioStreamFeed> feedStream(Object owner, [Uint8List? bytes]) async {
    final id = _nativeId;
    if (!streamed || !owns(owner) || id == null) return AudioStreamFeed.failed;
    try {
      final result = await _channel.invokeMethod<int>(
        bytes == null ? 'finishStream' : 'streamBytes',
        {'id': id, if (bytes != null) 'bytes': bytes},
      );
      if (_nativeId != id) return AudioStreamFeed.failed;
      return switch (result) {
        0 => AudioStreamFeed.waiting,
        1 => AudioStreamFeed.accepted,
        _ => AudioStreamFeed.failed,
      };
    } on PlatformException {
      return AudioStreamFeed.failed;
    } on MissingPluginException {
      return AudioStreamFeed.failed;
    }
  }

  Future<void> failStream(Object owner) async {
    if (!streamed || !owns(owner)) return;
    final id = _nativeId;
    _nativeId = null;
    _poll?.cancel();
    _poll = null;
    state = AudioPlaybackState.failed;
    notifyListeners();
    if (id != null) await _call('close', id);
  }

  Future<void> toggle(Object owner) async {
    final id = _nativeId;
    if (!owns(owner) || id == null) return;
    if (running) {
      await pause();
      return;
    }
    state = AudioPlaybackState.opening;
    notifyListeners();
    if (!await _call('play', id) && _nativeId == id) {
      state = AudioPlaybackState.failed;
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
    final nextLoop = !streamed && (looping ?? loop);
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
    final id = _nativeId;
    if (call.method != 'state' ||
        id == null ||
        payload is! Map ||
        payload['id'] != id) {
      return;
    }
    final next = AudioPlaybackState.values
        .where((value) => value.name == payload['state'])
        .firstOrNull;
    if (next == null) return;
    state = next;
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
