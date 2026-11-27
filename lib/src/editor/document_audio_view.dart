import 'dart:async';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

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
  Directory? _downloaded;
  Object? owner;
  AudioDocumentIdentity? _boundDocument;
  bool _confirmed = false;
  int _version = 0;

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
    final current = owner;
    owner = null;
    _boundDocument = null;
    _confirmed = false;
    final download = _downloaded;
    _downloaded = null;
    if (current != null) await playback.close(current);
    if (download != null) await _deleteDownload(download);
  }

  Future<void> cancel(
    Object key,
    ValueNotifier<AudioPlaybackState> status,
  ) async {
    if (owner != key) return;
    status.value = AudioPlaybackState.ready;
    await _reset();
  }

  static Future<void> _deleteDownload(Directory directory) async {
    try {
      await directory.delete(recursive: true);
    } on FileSystemException {
      // The temporary directory may already have been removed.
    }
  }

  @override
  void dispose() {
    unawaited(_reset());
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

  Future<File?> _remote(Uri source, int version) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 12)
      ..autoUncompress = false;
    _client = client;
    Directory? directory;
    try {
      var uri = source.replace(fragment: '');
      for (var redirects = 0; redirects < 5; redirects++) {
        if (_version != version) return null;
        final request = await client.getUrl(uri);
        request.followRedirects = false;
        final response = await request.close().timeout(
          const Duration(seconds: 15),
        );
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
            response.contentLength > maximumManagedAssetBytes) {
          return null;
        }
        directory = await Directory.systemTemp.createTemp('busymark-media-');
        final file = File(p.join(directory.path, 'audio'));
        final handle = await file.open(mode: FileMode.write);
        try {
          var length = 0;
          final deadline = Stopwatch()..start();
          await for (final chunk in response.timeout(
            const Duration(seconds: 15),
          )) {
            length += chunk.length;
            if (_version != version ||
                deadline.elapsed > const Duration(minutes: 2) ||
                length > maximumManagedAssetBytes) {
              return null;
            }
            await handle.writeFrom(chunk);
          }
          if (length == 0 ||
              response.contentLength >= 0 && response.contentLength != length) {
            return null;
          }
        } finally {
          await handle.close();
        }
        if (_version != version) return null;
        _downloaded = directory;
        directory = null;
        return file;
      }
      return null;
    } finally {
      client.close(force: true);
      if (identical(client, _client)) _client = null;
      if (directory != null) await _deleteDownload(directory);
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
      try {
        File? target;
        if (uri?.scheme == 'https' &&
            uri!.hasAuthority &&
            uri.userInfo.isEmpty) {
          if (!approvedOrigins.contains(uri.origin)) {
            final allowed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(context.l10n.audioRemotePermission),
                content: Text(uri.origin),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(context.l10n.cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(context.l10n.audioAllowForDocument),
                  ),
                ],
              ),
            );
            if (_version != version) break;
            if (allowed != true) continue;
            approvedOrigins.add(uri.origin);
          }
          target = await _remote(uri, version);
        } else {
          target = await _local(candidate.destination, media);
        }
        if (_version != version) break;
        if (target == null || await AudioAssetFormat.inspect(target) == null) {
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

        try {
          final opening = playback.open(
            key,
            target,
            muted: audio.muted,
            looping: audio.loop,
          );
          playback.addListener(onPlayback);
          if (await opening &&
              await ready.future.timeout(
                const Duration(seconds: 20),
                onTimeout: () => false,
              ) &&
              _version == version) {
            _confirmed = true;
            status.value = AudioPlaybackState.ready;
            return;
          }
          if (_version == version) await playback.close(key);
        } finally {
          playback.removeListener(onPlayback);
        }
      } on IOException {
        // An inaccessible source can fall through to another authored source.
      } on TimeoutException {
        // Retry requires a user action after the source list is exhausted.
      } on FormatException {
        // Invalid path escapes do not become filesystem paths.
      }
      final downloaded = _downloaded;
      if (_version == version && downloaded != null) {
        _downloaded = null;
        await _deleteDownload(downloaded);
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
    Widget properties() => IconButton(
      tooltip: localized.audioProperties,
      onPressed: edit == null ? null : () => edit(audio),
      icon: const Icon(Icons.audio_file_outlined),
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
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          IconButton(
            tooltip: busy && cancelOpening != null
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
                      current && !failed ? audio.toggle(owner) : start(),
                    );
                  },
            icon: Icon(
              busy && cancelOpening != null
                  ? Icons.stop
                  : failed
                  ? Icons.refresh
                  : running
                  ? Icons.pause
                  : Icons.play_arrow,
            ),
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.all(6),
              child: SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          if (failed)
            Text(
              localized.audioPlaybackFailure,
              style: Theme.of(context).textTheme.bodySmall,
            )
          else ...[
            Text(
              '${_time(current ? audio.position : 0)} / ${duration == null ? '—' : _time(duration)}',
            ),
            if (current && audio.seekable && duration != null && duration > 0)
              SizedBox(
                width: 120,
                child: Semantics(
                  label: localized.audioPosition,
                  child: Slider(
                    value: audio.position.clamp(0, duration),
                    max: duration,
                    onChanged: (value) => unawaited(audio.seek(owner, value)),
                  ),
                ),
              ),
            if (current) ...[
              IconButton(
                tooltip: audio.mute
                    ? localized.audioUnmute
                    : localized.audioMute,
                icon: Icon(audio.mute ? Icons.volume_off : Icons.volume_up),
                onPressed: () =>
                    unawaited(audio.configure(owner, muted: !audio.mute)),
              ),
              SizedBox(
                width: 86,
                child: Semantics(
                  label: localized.audioVolume,
                  child: Slider(
                    value: audio.volume,
                    onChanged: (value) =>
                        unawaited(audio.configure(owner, level: value)),
                  ),
                ),
              ),
              PopupMenuButton<double>(
                tooltip: localized.audioPlaybackRate,
                enabled: audio.seekable,
                onSelected: (value) =>
                    unawaited(audio.seek(owner, audio.position, speed: value)),
                itemBuilder: (context) => [
                  for (final value in [0.5, 0.75, 1.0, 1.25, 1.5, 2.0])
                    CheckedPopupMenuItem(
                      value: value,
                      checked: audio.rate == value,
                      child: Text('$value×'),
                    ),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text('${audio.rate}×'),
                ),
              ),
              IconButton(
                tooltip: localized.audioLoop,
                isSelected: audio.loop,
                icon: const Icon(Icons.repeat),
                selectedIcon: const Icon(Icons.repeat_one),
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
