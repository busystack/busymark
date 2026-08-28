import 'package:flutter/services.dart';

import '../writerside/writerside_video.dart';

const writersideVideoPlayerChannelName = 'com.busymark.app/video_player';

class WritersideVideoPlayerRequest {
  const WritersideVideoPlayerRequest({
    required this.playerId,
    required this.source,
    required this.rect,
    required this.miniPlayer,
    required this.playLabel,
    required this.pauseLabel,
    required this.borderEffect,
  });

  final String playerId;
  final WritersideVideoPlaybackSource source;
  final Rect rect;
  final bool miniPlayer;
  final String playLabel;
  final String pauseLabel;
  final String borderEffect;

  Map<String, Object?> toMap() => {
    'playerId': playerId,
    'kind': source.kind.name,
    'value': source.value,
    'x': rect.left,
    'y': rect.top,
    'width': rect.width,
    'height': rect.height,
    'miniPlayer': miniPlayer,
    'playLabel': playLabel,
    'pauseLabel': pauseLabel,
    'borderEffect': borderEffect,
  };
}

abstract interface class WritersideVideoPlayerHost {
  Future<bool> show(WritersideVideoPlayerRequest request);

  Future<bool> update(String playerId, Rect rect);

  Future<void> hide(String playerId);
}

class PlatformWritersideVideoPlayerHost implements WritersideVideoPlayerHost {
  const PlatformWritersideVideoPlayerHost({
    MethodChannel channel = const MethodChannel(
      writersideVideoPlayerChannelName,
    ),
  }) : _channel = channel;

  final MethodChannel _channel;

  @override
  Future<bool> show(WritersideVideoPlayerRequest request) async {
    return await _channel.invokeMethod<bool>('show', request.toMap()) ?? false;
  }

  @override
  Future<bool> update(String playerId, Rect rect) async {
    return await _channel.invokeMethod<bool>('update', {
          'playerId': playerId,
          'x': rect.left,
          'y': rect.top,
          'width': rect.width,
          'height': rect.height,
        }) ??
        false;
  }

  @override
  Future<void> hide(String playerId) {
    return _channel.invokeMethod<void>('hide', {'playerId': playerId});
  }
}
