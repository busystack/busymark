import 'dart:io';

import 'package:busymark/src/editor/audio_playback.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a native pause event before the method reply stays paused', () async {
    const channel = MethodChannel('com.busymark.app/audio_player');
    const codec = StandardMethodCodec();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final calls = <String>[];
    Future<void> send(int? id, String state) => messenger.handlePlatformMessage(
      channel.name,
      codec.encodeMethodCall(MethodCall('state', {'id': id, 'state': state})),
      (_) {},
    );
    messenger.setMockMethodCallHandler(channel, (call) async {
      final arguments = (call.arguments as Map).cast<String, Object>();
      final id = arguments['id']! as int;
      calls.add(call.method);
      switch (call.method) {
        case 'open':
        case 'play':
          await send(id, 'playing');
          return true;
        case 'pause':
          await send(id, 'paused');
          return true;
        case 'position':
          return {'position': 1.0, 'duration': 4.0, 'seekable': true};
        default:
          return true;
      }
    });
    final playback = AudioPlayback.shared;
    final owner = Object();
    addTearDown(() async {
      await playback.close(owner);
      messenger.setMockMethodCallHandler(channel, null);
    });
    expect(await playback.open(owner, File('/owned.wav')), true);
    expect(playback.state, AudioPlaybackState.playing);
    await playback.toggle(owner);
    expect(playback.state, AudioPlaybackState.paused);
    await playback.toggle(owner);
    expect(playback.state, AudioPlaybackState.playing);
    expect(calls.where((method) => method != 'position'), [
      'open',
      'pause',
      'play',
    ]);
    await playback.close(owner);
    await send(null, 'playing');
    expect(playback.state, AudioPlaybackState.ready);
  });
}
