import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

import '../app/busymark_design.dart';
import '../app/busymark_dialogs.dart';
import '../app/busymark_glyphs.dart';
import '../app/localization.dart';
import '../assets/asset_limits.dart';
import '../assets/audio_asset_format.dart';
import '../assets/document_media_context.dart';
import '../markdown/audio_media.dart';
import 'audio_playback.dart';
import 'audio_authoring.dart';

typedef AudioDocumentIdentity = ({
  Object opening,
  String identity,
  String? path,
  int revision,
  String? mediaIdentity,
});

final _documentAudioScopes = <_DocumentAudioScopeState>{};
const _remoteAudioIdleTimeout = Duration(seconds: 15);
const _remoteAudioStreamLimit = Duration(minutes: 30);
const _remoteAudioChunkBytes = 64 * 1024;

class _AudioDownload {
  _AudioDownload(this.directory, this.file);

  final Directory directory;
  final File file;
  Future<void>? _release;

  Future<void> release() => _release ??= delete(directory);

  static Future<void> delete(Directory directory) async {
    try {
      await directory.delete(recursive: true);
    } on FileSystemException {
      // The private temporary directory may already have been removed.
    }
  }
}

typedef _RemoteAudio = ({
  _AudioDownload? download,
  ({HttpClient client, HttpClientResponse response})? stream,
});

Future<void> settleDocumentAudioForWindowClose() async {
  await Future.wait([
    for (final scope in _documentAudioScopes.toList()) scope._reset(),
  ]);
}

class DocumentAudioScope extends StatefulWidget {
  const DocumentAudioScope({
    super.key,
    required this.document,
    required this.openDocuments,
    required this.rootPath,
    required this.child,
    this.editAudio,
  });

  final AudioDocumentIdentity? document;
  final Map<Object, AudioDocumentIdentity> openDocuments;
  final String? rootPath;
  final Widget child;
  final ValueChanged<BusyAudio>? editAudio;

  static _DocumentAudioScopeState? _of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_DocumentAudioContext>()
      ?.state;

  @override
  State<DocumentAudioScope> createState() => _DocumentAudioScopeState();
}

class _DocumentAudioContext extends InheritedWidget {
  const _DocumentAudioContext({required this.state, required super.child});
  final _DocumentAudioScopeState state;
  @override
  bool updateShouldNotify(_DocumentAudioContext oldWidget) =>
      state != oldWidget.state;
}

class _DocumentAudioScopeState extends State<DocumentAudioScope> {
  final playback = AudioPlayback.shared;
  final states = <Object, ValueNotifier<AudioPlaybackState>>{};
  final approvedOrigins = <String>{};
  HttpClient? _client;
  Future<_RemoteAudio?>? _downloading;
  Future<void>? _streaming;
  Future<void> _retiring = Future.value();
  _AudioDownload? _downloaded;
  Object? owner;
  AudioDocumentIdentity? _boundDocument;
  bool _confirmed = false;
  int _version = 0;

  @override
  void initState() {
    super.initState();
    _documentAudioScopes.add(this);
  }

  @override
  void didUpdateWidget(DocumentAudioScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document?.opening != widget.document?.opening) {
      approvedOrigins.clear();
    }
    final bound = _boundDocument;
    if (bound == null) return;
    final stillOpen = widget.openDocuments[bound.opening] == bound;
    if (!stillOpen || (!_confirmed && widget.document != bound)) {
      final closing = owner;
      ++_version;
      _client?.close(force: true);
      _client = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (owner == closing) unawaited(_reset());
      });
    } else if (widget.document != bound && oldWidget.document == bound) {
      final previous = owner;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (owner == previous && playback.owns(previous!)) {
          unawaited(playback.pause());
        }
      });
    }
  }

  Future<void> _reset() async {
    ++_version;
    _client?.close(force: true);
    _client = null;
    final pending = _downloading;
    _downloading = null;
    final streaming = _streaming;
    _streaming = null;
    final current = owner;
    owner = null;
    _boundDocument = null;
    _confirmed = false;
    final download = _downloaded;
    _downloaded = null;
    _retiring = _retiring.then((_) async {
      if (current != null) await playback.close(current);
      if (pending != null) {
        // The request owner handles its errors. Wait for the private partial
        // file to be closed and removed, including on cancellation.
        await pending.then<void>((_) {}, onError: (Object _, StackTrace _) {});
      }
      if (streaming != null) await streaming;
      if (download != null) await download.release();
    });
    await _retiring;
  }

  Future<void> cancel(
    Object key,
    ValueNotifier<AudioPlaybackState> status,
  ) async {
    if (owner != key) return;
    status.value = AudioPlaybackState.ready;
    await _reset();
  }

  @override
  void dispose() {
    unawaited(_reset().whenComplete(() => _documentAudioScopes.remove(this)));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _DocumentAudioContext(state: this, child: widget.child);

  Future<File?> _local(String destination, DocumentMediaContext? media) async {
    if (media != null) {
      final path = await media.resolve(busyMarkAudioResourcePath(destination));
      return path == null ? null : File(path);
    }
    final document = widget.document?.path;
    if (document == null || document.isEmpty) return null;
    final path = await resolveDocumentAudioPath(
      destination,
      documentPath: document,
      rootPath: widget.rootPath ?? p.dirname(document),
    );
    return path == null ? null : File(path);
  }

  Future<_RemoteAudio?> _remote(Uri source, int version) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 12)
      ..autoUncompress = false;
    _client = client;
    Directory? directory;
    var ownsRequest = true;
    try {
      var uri = source.replace(fragment: '');
      for (var redirects = 0; redirects < 5; redirects++) {
        if (_version != version) return null;
        final request = await client.getUrl(uri);
        request.followRedirects = false;
        request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
        final response = await request.close().timeout(_remoteAudioIdleTimeout);
        if (response.isRedirect) {
          final location = response.headers.value(HttpHeaders.locationHeader);
          if (location == null) return null;
          final target = uri.resolve(location);
          if (target.scheme != 'https' ||
              target.userInfo.isNotEmpty ||
              target.origin != source.origin) {
            return null;
          }
          uri = target;
          continue;
        }
        if (response.statusCode != HttpStatus.ok ||
            response.contentLength > maximumManagedAssetBytes ||
            _version != version) {
          return null;
        }
        if (response.contentLength < 0) {
          ownsRequest = false;
          return (download: null, stream: (client: client, response: response));
        }
        directory = await Directory.systemTemp.createTemp('busymark-media-');
        final file = File(p.join(directory.path, 'audio'));
        final handle = await file.open(mode: FileMode.write);
        try {
          var length = 0;
          final deadline = Stopwatch()..start();
          await for (final chunk in response.timeout(_remoteAudioIdleTimeout)) {
            length += chunk.length;
            if (_version != version ||
                deadline.elapsed > const Duration(minutes: 2) ||
                length > maximumManagedAssetBytes) {
              return null;
            }
            await handle.writeFrom(chunk);
          }
          if (length == 0 || response.contentLength != length) {
            return null;
          }
        } finally {
          await handle.close();
        }
        if (_version != version) return null;
        final download = _AudioDownload(directory, file);
        _downloaded = download;
        directory = null;
        return (download: download, stream: null);
      }
      return null;
    } finally {
      if (ownsRequest) _closeClient(client);
      if (directory != null) await _AudioDownload.delete(directory);
    }
  }

  void _closeClient(HttpClient client) {
    client.close(force: true);
    if (identical(client, _client)) _client = null;
  }

  Future<void> _pumpStream(
    Object key,
    int version,
    ({HttpClient client, HttpClientResponse response}) stream,
  ) async {
    final clock = Stopwatch()..start();
    final signature = BytesBuilder(copy: false);
    var accepted = false;
    var finished = false;
    var length = 0;
    bool current() => _version == version && playback.owns(key);
    Future<bool> push([Uint8List? bytes]) async {
      while (current() && clock.elapsed < _remoteAudioStreamLimit) {
        switch (await playback.feedStream(key, bytes)) {
          case AudioStreamFeed.accepted:
            return true;
          case AudioStreamFeed.failed:
            return false;
          case AudioStreamFeed.waiting:
            await Future<void>.delayed(const Duration(milliseconds: 25));
        }
      }
      return false;
    }

    try {
      await for (final chunk in stream.response.timeout(
        _remoteAudioIdleTimeout,
      )) {
        length += chunk.length;
        if (!current() ||
            length > maximumManagedAssetBytes ||
            clock.elapsed >= _remoteAudioStreamLimit) {
          return;
        }
        var offset = 0;
        if (!accepted) {
          offset = (64 - signature.length).clamp(0, chunk.length);
          signature.add(chunk.sublist(0, offset));
          if (signature.length < 64) continue;
          final header = signature.takeBytes();
          if (AudioAssetFormat.identify(header) == null ||
              !await push(header)) {
            return;
          }
          accepted = true;
        }
        while (offset < chunk.length) {
          final end = (offset + _remoteAudioChunkBytes).clamp(
            offset,
            chunk.length,
          );
          if (!await push(Uint8List.fromList(chunk.sublist(offset, end)))) {
            return;
          }
          offset = end;
        }
      }
      if (!accepted) {
        final header = signature.takeBytes();
        if (AudioAssetFormat.identify(header) == null || !await push(header)) {
          return;
        }
      }
      finished = await push();
    } on IOException {
      // A disconnected stream is retryable only by a new user action.
    } on TimeoutException {
      // The remote peer stopped delivering bytes within the idle limit.
    } finally {
      _closeClient(stream.client);
      if (!finished && current()) await playback.failStream(key);
    }
  }

  Future<void> start(
    BuildContext context,
    Object key,
    BusyAudio audio,
    ValueNotifier<AudioPlaybackState> status,
  ) async {
    final media = DocumentMediaScope.of(context);
    final document = widget.document;
    final reset = _reset();
    final version = _version;
    await reset;
    if (!mounted ||
        !context.mounted ||
        _version != version ||
        widget.document != document) {
      return;
    }
    owner = key;
    _boundDocument = document;
    status.value = AudioPlaybackState.opening;
    for (final candidate in audio.playbackSources) {
      if (_version != version || !context.mounted) break;
      final uri = Uri.tryParse(candidate.destination);
      _RemoteAudio? remote;
      Future<void>? feeding;
      var keep = false;
      try {
        File? target;
        if (uri?.scheme == 'https' &&
            uri!.hasAuthority &&
            uri.userInfo.isEmpty) {
          if (!approvedOrigins.contains(uri.origin)) {
            final allowed = await showBusyMarkModalDialog<bool>(
              context,
              builder: (context) => BusyMarkDialogShell(
                title: context.l10n.audioRemotePermission,
                maxWidth: BusyMarkSizes.dialogNarrow,
                actions: [
                  BusyMarkDialogButton(
                    label: context.l10n.cancel,
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  BusyMarkDialogButton(
                    label: context.l10n.audioAllowForDocument,
                    onPressed: () => Navigator.pop(context, true),
                    suggested: true,
                  ),
                ],
                children: [
                  SelectableText(uri.origin, textDirection: TextDirection.ltr),
                ],
              ),
            );
            if (_version != version) break;
            if (allowed != true) continue;
            approvedOrigins.add(uri.origin);
          }
          final pending = _remote(uri, version);
          _downloading = pending;
          try {
            remote = await pending;
            target = remote?.download?.file;
          } finally {
            if (identical(_downloading, pending)) _downloading = null;
          }
        } else {
          target = await _local(candidate.destination, media);
        }
        if (_version != version) break;
        final stream = remote?.stream;
        if (stream == null &&
            (target == null ||
                await AudioAssetFormat.inspect(target) == null)) {
          continue;
        }
        if (_version != version) break;
        final ready = Completer<bool>();
        void onPlayback() {
          if (!playback.owns(key) || _version != version) {
            if (!ready.isCompleted) ready.complete(false);
          } else if (playback.state == AudioPlaybackState.failed) {
            if (!ready.isCompleted) ready.complete(false);
          } else if (playback.state == AudioPlaybackState.playing ||
              playback.state == AudioPlaybackState.ended ||
              playback.state == AudioPlaybackState.paused) {
            if (!ready.isCompleted) ready.complete(true);
          }
        }

        playback.addListener(onPlayback);
        try {
          final opened = stream == null
              ? await playback.open(
                  key,
                  target!,
                  muted: audio.muted,
                  looping: audio.loop,
                )
              : await playback.openStream(key, muted: audio.muted);
          if (opened && stream != null && _version == version) {
            feeding = _pumpStream(key, version, stream);
            _streaming = feeding;
          }
          if (opened &&
              await ready.future.timeout(
                const Duration(seconds: 20),
                onTimeout: () => false,
              ) &&
              _version == version) {
            keep = true;
            _confirmed = true;
            status.value = AudioPlaybackState.ready;
            return;
          }
        } finally {
          playback.removeListener(onPlayback);
        }
      } on IOException {
        // An inaccessible source can fall through to another authored source.
      } on TimeoutException {
        // Retry requires a user action after the source list is exhausted.
      } on FormatException {
        // Invalid path escapes do not become filesystem paths.
      } finally {
        if (!keep) {
          if (remote?.stream case final stream?) _closeClient(stream.client);
          if (_version == version) await playback.close(key);
          if (feeding != null) {
            await feeding;
            if (identical(_streaming, feeding)) _streaming = null;
          }
          if (remote?.download case final downloaded?) {
            if (identical(_downloaded, downloaded)) _downloaded = null;
            await downloaded.release();
          }
        }
      }
    }
    status.value = _version == version
        ? AudioPlaybackState.failed
        : AudioPlaybackState.ready;
  }
}

class BusyMarkDocumentAudioView extends StatelessWidget {
  const BusyMarkDocumentAudioView({
    super.key,
    required this.audio,
    this.editable = false,
  });

  final BusyAudio audio;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    if (!audio.controls && !editable) return const SizedBox.shrink();
    final scope = DocumentAudioScope._of(context);
    final localized = context.l10n;
    final name = audio.accessibleName ?? localized.audio;
    final edit = editable ? scope?.widget.editAudio : null;
    Widget properties() => _audioControl(
      label: localized.audioProperties,
      onPressed: edit == null ? null : () => edit(audio),
      icon: BusyMarkGlyphs.audioFile,
    );
    if (!audio.controls || scope == null) return properties();
    final owner = (
      scope,
      scope.widget.document?.opening,
      audio.sourceSpan?.filePath,
      audio.sourceSpan?.startOffset,
      audio.rawSource,
    );
    // Keep failure state across a lazy-list rebuild, within a bounded cache.
    if (scope.states.length >= 64 && !scope.states.containsKey(owner)) {
      scope.states.remove(scope.states.keys.first);
    }
    final status = scope.states.putIfAbsent(
      owner,
      () => ValueNotifier(AudioPlaybackState.ready),
    );
    return ListenableBuilder(
      listenable: Listenable.merge([scope.playback, status]),
      builder: (context, _) => Wrap(
        spacing: BusyMarkSpacing.xs,
        runSpacing: BusyMarkSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          BusyMarkAudioTransport(
            owner: owner,
            label: name,
            inactiveState: status.value,
            start: () => scope.start(context, owner, audio, status),
            cancelOpening: () => scope.cancel(owner, status),
          ),
          if (edit != null) properties(),
        ],
      ),
    );
  }
}

Widget _audioControl({
  required String label,
  required IconData icon,
  required VoidCallback? onPressed,
  bool? selected,
}) => BusyMarkCompactIconButton(
  tooltip: label,
  semanticLabel: label,
  icon: icon,
  onPressed: onPressed,
  selected: selected,
);

class BusyMarkAudioTransport extends StatelessWidget {
  const BusyMarkAudioTransport({
    super.key,
    required this.owner,
    required this.label,
    required this.start,
    this.inactiveState = AudioPlaybackState.ready,
    this.cancelOpening,
  });

  final Object owner;
  final String label;
  final Future<void> Function() start;
  final Future<void> Function()? cancelOpening;
  final AudioPlaybackState inactiveState;

  static String _time(double value) {
    final seconds = value.floor();
    final minutes = seconds ~/ 60;
    return '$minutes:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final audio = AudioPlayback.shared;
    final localized = context.l10n;
    final current = audio.owns(owner);
    final running = current && audio.running;
    final state = current ? audio.state : inactiveState;
    final duration = current ? audio.duration : null;
    final busy =
        state == AudioPlaybackState.buffering ||
        state == AudioPlaybackState.opening;
    final failed = state == AudioPlaybackState.failed;
    return Semantics(
      container: true,
      label: label,
      child: Wrap(
        spacing: BusyMarkSpacing.xs,
        runSpacing: BusyMarkSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _audioControl(
            label: busy && cancelOpening != null
                ? localized.cancel
                : failed
                ? localized.audioRetry
                : running
                ? localized.audioPause
                : localized.audioPlay,
            onPressed: busy && cancelOpening != null
                ? () => unawaited(cancelOpening!())
                : busy && !current
                ? null
                : () {
                    unawaited(
                      current &&
                              !failed &&
                              !(audio.streamed &&
                                  state == AudioPlaybackState.ended)
                          ? audio.toggle(owner)
                          : start(),
                    );
                  },
            icon: busy && cancelOpening != null
                ? BusyMarkGlyphs.stopAudio
                : failed
                ? BusyMarkGlyphs.refresh
                : running
                ? BusyMarkGlyphs.pauseAudio
                : BusyMarkGlyphs.play,
          ),
          if (!busy &&
              current &&
              audio.streamed &&
              cancelOpening != null &&
              (running || state == AudioPlaybackState.paused))
            _audioControl(
              label: localized.cancel,
              icon: BusyMarkGlyphs.stopAudio,
              onPressed: () => unawaited(cancelOpening!()),
            ),
          if (busy)
            const Padding(
              padding: EdgeInsets.all(BusyMarkSpacing.xs),
              child: BusyMarkProgressIndicator(compact: true),
            ),
          if (failed)
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: BusyMarkSizes.dialogNarrow,
              ),
              child: Semantics(
                liveRegion: true,
                child: BusyMarkStatusBox(
                  message: localized.audioPlaybackFailure,
                  kind: BusyMarkStatusKind.error,
                ),
              ),
            )
          else ...[
            Text(
              '${_time(current ? audio.position : 0)} / ${duration == null ? '—' : _time(duration)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: BusyMarkSurfaceColors.of(context).mutedForeground,
              ),
            ),
            if (current && audio.seekable && duration != null && duration > 0)
              SizedBox(
                width: 120,
                child: BusyMarkRangeSlider(
                  label: localized.audioPosition,
                  compact: true,
                  value: audio.position.clamp(0, duration),
                  max: duration,
                  formatValue: _time,
                  onChanged: (value) => unawaited(audio.seek(owner, value)),
                ),
              ),
            if (current) ...[
              _audioControl(
                label: audio.mute ? localized.audioUnmute : localized.audioMute,
                icon: audio.mute
                    ? BusyMarkGlyphs.mutedSpeaker
                    : BusyMarkGlyphs.speaker,
                onPressed: () =>
                    unawaited(audio.configure(owner, muted: !audio.mute)),
              ),
              SizedBox(
                width: 86,
                child: BusyMarkRangeSlider(
                  label: localized.audioVolume,
                  compact: true,
                  value: audio.volume,
                  onChanged: (value) =>
                      unawaited(audio.configure(owner, level: value)),
                ),
              ),
              if (!audio.streamed)
                BusyMarkPopupSelector<double>(
                  value: audio.rate,
                  label: '${audio.rate}×',
                  tooltip: localized.audioPlaybackRate,
                  enabled: audio.seekable,
                  shrinkWrap: true,
                  popupMinWidth: BusyMarkSizes.popupMenuMinWidth,
                  onSelected: (value) => unawaited(
                    audio.seek(owner, audio.position, speed: value),
                  ),
                  options: [
                    for (final value in [0.5, 0.75, 1.0, 1.25, 1.5, 2.0])
                      BusyMarkPopupSelectorOption(
                        value: value,
                        label: '$value×',
                      ),
                  ],
                ),
              if (!audio.streamed)
                _audioControl(
                  label: localized.audioLoop,
                  selected: audio.loop,
                  icon: audio.loop
                      ? BusyMarkGlyphs.repeatAudioOnce
                      : BusyMarkGlyphs.repeatAudio,
                  onPressed: () =>
                      unawaited(audio.configure(owner, looping: !audio.loop)),
                ),
            ],
          ],
        ],
      ),
    );
  }
}
