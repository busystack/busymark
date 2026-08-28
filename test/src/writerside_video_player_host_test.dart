import 'dart:io';

import 'package:busymark/src/editor/writerside_video_player_host.dart';
import 'package:busymark/src/writerside/writerside_video.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'platform host sends reduced source and geometry over one channel',
    () async {
      const channel = MethodChannel(writersideVideoPlayerChannelName);
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return call.method == 'hide' ? null : true;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      const host = PlatformWritersideVideoPlayerHost(channel: channel);
      const rect = Rect.fromLTWH(12, 24, 640, 360);

      expect(
        await host.show(
          const WritersideVideoPlayerRequest(
            playerId: 'video-1',
            source: WritersideVideoPlaybackSource(
              kind: WritersideVideoPlaybackKind.youtube,
              value: 'BeJu9bMPLGU',
            ),
            rect: rect,
            miniPlayer: false,
            playLabel: 'Play video',
            pauseLabel: 'Pause video',
            borderEffect: 'rounded',
          ),
        ),
        isTrue,
      );
      expect(
        await host.update('video-1', rect.shift(const Offset(1, 2))),
        isTrue,
      );
      await host.hide('video-1');

      expect(calls.map((call) => call.method), ['show', 'update', 'hide']);
      expect(calls.first.arguments, {
        'playerId': 'video-1',
        'kind': 'youtube',
        'value': 'BeJu9bMPLGU',
        'x': 12.0,
        'y': 24.0,
        'width': 640.0,
        'height': 360.0,
        'miniPlayer': false,
        'playLabel': 'Play video',
        'pauseLabel': 'Pause video',
        'borderEffect': 'rounded',
      });
    },
  );

  test('Linux player keeps interactive media in a restricted WebKit host', () {
    final native = File('linux/runner/video_player_host.cc').readAsStringSync();
    final application = File(
      'linux/runner/my_application.cc',
    ).readAsStringSync();
    final cmake = File('linux/runner/CMakeLists.txt').readAsStringSync();
    final renderHost = File(
      'linux/runner/web_render_host.cc',
    ).readAsStringSync();
    final snap = File('snap/snapcraft.yaml').readAsStringSync();

    expect(native, contains('webkit_web_context_new_ephemeral()'));
    expect(native, contains('WEBKIT_COOKIE_POLICY_ACCEPT_NEVER'));
    expect(native, contains('webkit_permission_request_deny(request)'));
    expect(
      native,
      contains('webkit_settings_set_enable_media(settings, TRUE)'),
    );
    expect(
      native,
      contains('set_media_playback_requires_user_gesture(settings, FALSE)'),
    );
    expect(native, contains('autoplay=1'));
    expect(native, contains('resource_load_started_cb'));
    expect(
      native,
      contains('webkit_uri_request_set_uri(request, "about:blank")'),
    );
    expect(
      native,
      contains(
        'soup_message_headers_replace(headers, "Referer", '
        'kHostedPlayerBaseUri)',
      ),
    );
    expect(native, contains('kHostedPlayerOriginParameter'));
    expect(native, contains('"https://github.com/busystack/busymark/"'));
    expect(native, isNot(contains('"send-request"')));
    expect(native, contains('youtube-nocookie.com'));
    expect(native, contains('jnn-pa.googleapis.com'));
    expect(native, contains('yt3.ggpht.com'));
    expect(native, contains('player.vimeo.com'));
    expect(native, contains("connect-src 'none'"));
    expect(native, isNot(contains('javascript:')));
    expect(application, contains('busymark_video_player_host_new'));
    expect(application, contains('gtk_overlay_new'));
    expect(native, contains('gtk_overlay_add_overlay'));
    expect(cmake, contains('video_player_host.cc'));

    // Interactive video is separate from the offline generated-content host.
    expect(
      renderHost,
      contains('webkit_settings_set_enable_media(settings, FALSE)'),
    );
    expect(snap, contains('confinement: strict'));
    expect(snap, contains('gstreamer1.0-plugins-good'));
    expect(snap, contains('gstreamer1.0-libav'));
  });
}
