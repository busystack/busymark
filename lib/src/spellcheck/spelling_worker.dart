import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

import 'package:busymark_spellcheck_native/busymark_spellcheck_native.dart';
import 'package:unorm_dart/unorm_dart.dart' as unicode;

import '../markdown/busymark_document.dart';
import '../markdown/markdown_model.dart';
import '../workspace/workspace_model.dart';
import 'markdown_spelling_projection.dart';
import 'spelling_projection.dart';
import 'writerside_spelling_projection.dart';
import 'wysiwyg_spelling_projection.dart';

final class SpellingProjectionJob {
  const SpellingProjectionJob({
    required this.filePath,
    required this.source,
    required this.documentKind,
    required this.markdownMode,
    required this.languageId,
    required this.snapshot,
    this.richDocument,
    this.richDocumentGeneration = 0,
  });

  final String filePath;
  final String source;
  final DocumentKind documentKind;
  final MarkdownMode markdownMode;
  final String languageId;
  final SpellingSnapshotIdentity snapshot;
  final BusyDocument? richDocument;
  final int richDocumentGeneration;

  Map<String, Object?> toMessage() => {
    'filePath': filePath,
    'source': source,
    'documentKind': documentKind.name,
    'markdownMode': markdownMode.name,
    'languageId': languageId,
    'snapshot': snapshot,
    'richDocument': richDocument,
    'richDocumentGeneration': richDocumentGeneration,
  };
}

final class SpellingEngineContext {
  const SpellingEngineContext({
    required this.languageId,
    required this.affPath,
    required this.dicPath,
    required this.baseFingerprint,
    required this.personalRevision,
    required this.projectIdentity,
    required this.projectRevision,
    required this.customWords,
  });

  final String languageId;
  final String affPath;
  final String dicPath;
  final String baseFingerprint;
  final int personalRevision;
  final String? projectIdentity;
  final int projectRevision;
  final List<String> customWords;

  String get identity {
    final effectiveWords = [...customWords]..sort();
    return [
      languageId,
      baseFingerprint,
      personalRevision,
      projectIdentity ?? '',
      projectRevision,
      for (final word in effectiveWords) '${word.length}:$word',
    ].join('\u0000');
  }

  Map<String, Object?> toMessage() => {
    'languageId': languageId,
    'affPath': affPath,
    'dicPath': dicPath,
    'baseFingerprint': baseFingerprint,
    'personalRevision': personalRevision,
    'projectIdentity': projectIdentity,
    'projectRevision': projectRevision,
    'customWords': customWords,
    'identity': identity,
  };
}

final class SpellingWorkerResult {
  const SpellingWorkerResult({
    required this.requestId,
    required this.occurrences,
    required this.cancelled,
    required this.complete,
    this.error,
  });

  final int requestId;
  final List<SpellingOccurrence> occurrences;
  final bool cancelled;
  final bool complete;
  final String? error;
}

/// One reusable spelling isolate. It owns the only active native handle and
/// keeps at most one running request plus the newest pending replacement.
final class SpellingWorker {
  SpellingWorker._(
    this._isolate,
    this._sendPort,
    this._receivePort,
    Stream<Object?> responses,
  ) {
    _subscription = responses.listen(_handleMessage);
  }

  final Isolate _isolate;
  final SendPort _sendPort;
  final ReceivePort _receivePort;
  late final StreamSubscription<Object?> _subscription;
  final Map<int, Completer<Map<Object?, Object?>>> _pending = {};
  int _nextRequest = 1;
  bool _closed = false;

  static Future<SpellingWorker> start() async {
    final receive = ReceivePort();
    final responses = receive.asBroadcastStream();
    final isolate = await Isolate.spawn(_spellingWorkerMain, receive.sendPort);
    final first = await responses.first;
    if (first is! SendPort) {
      receive.close();
      isolate.kill(priority: Isolate.immediate);
      throw StateError('Spelling worker did not initialize.');
    }
    return SpellingWorker._(isolate, first, receive, responses);
  }

  Future<SpellingWorkerResult> check({
    required SpellingEngineContext context,
    required List<SpellingProseRun> runs,
  }) async {
    _requireOpen();
    final requestId = _nextRequest++;
    final response = _request({
      'type': 'check',
      'requestId': requestId,
      'context': context.toMessage(),
      'runs': [
        for (var index = 0; index < runs.length; index++)
          {
            'index': index,
            'text': runs[index].text,
            'tokenizationContext': runs[index].tokenizationContext,
            'tokenizationContextStart': runs[index].tokenizationContextStart,
          },
      ],
    });
    final message = await response;
    final occurrences = <SpellingOccurrence>[];
    for (final value in (message['occurrences'] as List? ?? const [])) {
      if (value is! Map) continue;
      final data = value.cast<Object?, Object?>();
      final runIndex = data['runIndex'] as int;
      if (runIndex < 0 || runIndex >= runs.length) continue;
      final run = runs[runIndex];
      final start = data['start'] as int;
      final end = data['end'] as int;
      if (start < 0 || end < start || end > run.text.length) continue;
      final outcome = switch (data['outcome']) {
        'accepted' => SpellingCheckOutcome.accepted,
        'rejected' => SpellingCheckOutcome.rejected,
        _ => SpellingCheckOutcome.unchecked,
      };
      final word = run.text.substring(start, end);
      occurrences.add(
        SpellingOccurrence(
          id:
              '${run.snapshot.bufferId}:${run.snapshot.contentRevision}:'
              '${run.snapshot.documentKind.name}:'
              '${run.snapshot.contextGeneration}:${run.languageId}:'
              '${run.id}:$start:$end',
          run: run,
          logicalStart: start,
          logicalEnd: end,
          word: word,
          outcome: outcome,
          error: data['error']?.toString(),
        ),
      );
    }
    return SpellingWorkerResult(
      requestId: requestId,
      occurrences: List.unmodifiable(occurrences),
      cancelled: message['cancelled'] == true,
      complete: message['complete'] == true,
      error: message['error']?.toString(),
    );
  }

  Future<SpellingProjectionResult> project(SpellingProjectionJob job) async {
    _requireOpen();
    final message = await _request({
      'type': 'project',
      'requestId': _nextRequest++,
      'job': job.toMessage(),
    });
    final projection = message['projection'];
    if (projection is! SpellingProjectionResult) {
      throw StateError('Spelling worker returned an invalid projection.');
    }
    return projection;
  }

  Future<List<String>> suggestions({
    required SpellingEngineContext context,
    required String word,
  }) async {
    _requireOpen();
    final message = await _request({
      'type': 'suggest',
      'requestId': _nextRequest++,
      'context': context.toMessage(),
      'word': word,
    });
    final values = message['suggestions'];
    if (values is! List) return const [];
    return List.unmodifiable(values.map((value) => value.toString()));
  }

  Future<String> validateDictionary({
    required String affPath,
    required String dicPath,
    String? knownValidProbe,
  }) async {
    _requireOpen();
    final message = await _request({
      'type': 'validate',
      'requestId': _nextRequest++,
      'affPath': affPath,
      'dicPath': dicPath,
      if (knownValidProbe != null) 'knownValidProbe': knownValidProbe,
    });
    return message['encoding']?.toString() ?? '';
  }

  /// Releases the active native handle before an installed pair is removed.
  Future<void> releaseDictionary() async {
    _requireOpen();
    await _request({'type': 'releaseDictionary'});
  }

  void cancelChecks() {
    if (!_closed) _sendPort.send({'type': 'cancel'});
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    final response = _request({'type': 'close'}, allowClosed: true);
    try {
      await response.timeout(const Duration(seconds: 2));
    } finally {
      for (final completer in _pending.values) {
        if (!completer.isCompleted) {
          completer.completeError(StateError('Spelling worker closed.'));
        }
      }
      _pending.clear();
      await _subscription.cancel();
      _receivePort.close();
      _isolate.kill(priority: Isolate.immediate);
    }
  }

  Future<Map<Object?, Object?>> _request(
    Map<String, Object?> message, {
    bool allowClosed = false,
  }) {
    if (!allowClosed) _requireOpen();
    final requestId = message['requestId'] as int? ?? _nextRequest++;
    message['requestId'] = requestId;
    final completer = Completer<Map<Object?, Object?>>();
    _pending[requestId] = completer;
    _sendPort.send(message);
    return completer.future;
  }

  void _handleMessage(Object? value) {
    if (value is! Map) return;
    final message = value.cast<Object?, Object?>();
    final requestId = message['requestId'];
    if (requestId is! int) return;
    final completer = _pending.remove(requestId);
    if (completer == null || completer.isCompleted) return;
    if (message['fatal'] == true) {
      completer.completeError(
        StateError(message['error']?.toString() ?? 'Spelling worker failed.'),
      );
    } else {
      completer.complete(message);
    }
  }

  void _requireOpen() {
    if (_closed) throw StateError('Spelling worker is closed.');
  }
}

void _spellingWorkerMain(SendPort mainPort) {
  final commands = ReceivePort();
  mainPort.send(commands.sendPort);
  final runtime = _WorkerRuntime(mainPort);
  commands.listen(runtime.receive);
}

final class _WorkerRuntime {
  _WorkerRuntime(this.mainPort);

  final SendPort mainPort;
  NativeSpellDictionary? _dictionary;
  String? _contextIdentity;
  final LinkedHashMap<String, String> _wordCache = LinkedHashMap();
  Map<Object?, Object?>? _newestCheck;
  final List<Map<Object?, Object?>> _sideRequestQueue = [];
  final LinkedHashMap<String, _ProjectionCacheEntry> _projectionCache =
      LinkedHashMap();
  bool _busy = false;
  int _cancelGeneration = 0;

  void receive(Object? value) {
    if (value is! Map) return;
    final message = value.cast<Object?, Object?>();
    switch (message['type']) {
      case 'check':
        _cancelGeneration++;
        final replaced = _newestCheck;
        if (replaced != null) {
          mainPort.send({
            'requestId': replaced['requestId'],
            'occurrences': const [],
            'cancelled': true,
            'complete': false,
          });
        }
        _newestCheck = message;
        if (!_busy) unawaited(_drain());
        return;
      case 'suggest':
        while (_sideRequestQueue
                .where((item) => item['type'] == 'suggest')
                .length >=
            _maximumPendingSuggestions) {
          final index = _sideRequestQueue.indexWhere(
            (item) => item['type'] == 'suggest',
          );
          if (index < 0) break;
          final obsolete = _sideRequestQueue.removeAt(index);
          mainPort.send({
            'requestId': obsolete['requestId'],
            'fatal': true,
            'error': 'The pending spelling suggestion became obsolete.',
          });
        }
        _sideRequestQueue.add(message);
        if (!_busy) unawaited(_drain());
        return;
      case 'validate':
      case 'project':
      case 'releaseDictionary':
        _sideRequestQueue.add(message);
        if (!_busy) unawaited(_drain());
        return;
      case 'cancel':
        _cancelGeneration++;
        final pending = _newestCheck;
        _newestCheck = null;
        if (pending != null) {
          mainPort.send({
            'requestId': pending['requestId'],
            'occurrences': const [],
            'cancelled': true,
            'complete': false,
          });
        }
        return;
      case 'close':
        _cancelGeneration++;
        _newestCheck = null;
        _disposeDictionary();
        mainPort.send({'requestId': message['requestId'], 'closed': true});
        Isolate.exit();
    }
  }

  Future<void> _drain() async {
    _busy = true;
    try {
      while (_newestCheck != null || _sideRequestQueue.isNotEmpty) {
        if (_newestCheck case final request?) {
          _newestCheck = null;
          final generation = _cancelGeneration;
          await _check(request, generation);
        } else {
          final request = _sideRequestQueue.removeAt(0);
          if (request['type'] == 'validate') {
            await _validateDictionary(request);
          } else if (request['type'] == 'project') {
            await _project(request);
          } else if (request['type'] == 'releaseDictionary') {
            _disposeDictionary();
            mainPort.send({
              'requestId': request['requestId'],
              'released': true,
            });
          } else {
            await _suggest(request);
          }
        }
      }
    } finally {
      _busy = false;
      if ((_newestCheck != null || _sideRequestQueue.isNotEmpty) && !_busy) {
        unawaited(_drain());
      }
    }
  }

  Future<void> _check(Map<Object?, Object?> request, int generation) async {
    final requestId = request['requestId'] as int;
    final occurrences = <Map<String, Object?>>[];
    var complete = true;
    String? firstError;
    try {
      final context = (request['context'] as Map).cast<Object?, Object?>();
      final dictionary = _ensureDictionary(context);
      final language = context['languageId'].toString();
      final runs = request['runs'] as List;
      var wordsSinceYield = 0;
      for (var runCursor = 0; runCursor < runs.length; runCursor++) {
        if (generation != _cancelGeneration) {
          mainPort.send({
            'requestId': requestId,
            'occurrences': occurrences,
            'cancelled': true,
            'complete': false,
          });
          return;
        }
        final run = (runs[runCursor] as Map).cast<Object?, Object?>();
        final runIndex = run['index'] as int;
        final text = run['text'].toString();
        final tokenizationContext = run['tokenizationContext'].toString();
        final tokenizationContextStart = run['tokenizationContextStart'] as int;
        final quotationPunctuation = _quotationPunctuationOffsets(
          tokenizationContext,
        );
        try {
          for (final chunk in _boundedProseChunks(
            text,
            dictionary: dictionary,
            language: language,
          )) {
            if (chunk.error case final error?) {
              complete = false;
              firstError ??= error;
              occurrences.add({
                'runIndex': runIndex,
                'start': chunk.utf16Start,
                'end': chunk.utf16Start + chunk.text.length,
                'outcome': 'unchecked',
                'error': error,
              });
              continue;
            }
            final utf16Boundaries = _codePointToUtf16Boundaries(chunk.text);
            late final List<NativeWordRange> tokens;
            try {
              tokens = dictionary.tokenize(chunk.text, language: language);
            } on Object catch (error) {
              complete = false;
              firstError ??= error.toString();
              occurrences.add({
                'runIndex': runIndex,
                'start': chunk.utf16Start,
                'end': chunk.utf16Start + chunk.text.length,
                'outcome': 'unchecked',
                'error': error.toString(),
              });
              continue;
            }
            for (final token in tokens) {
              if (generation != _cancelGeneration) {
                mainPort.send({
                  'requestId': requestId,
                  'occurrences': occurrences,
                  'cancelled': true,
                  'complete': false,
                });
                return;
              }
              if (token.characterStart >= utf16Boundaries.length ||
                  token.characterEnd >= utf16Boundaries.length) {
                complete = false;
                const error = 'Native token boundary is invalid.';
                firstError ??= error;
                occurrences.add({
                  'runIndex': runIndex,
                  'start': chunk.utf16Start,
                  'end': chunk.utf16Start + chunk.text.length,
                  'outcome': 'unchecked',
                  'error': error,
                });
                continue;
              }
              var start =
                  chunk.utf16Start + utf16Boundaries[token.characterStart];
              var end = chunk.utf16Start + utf16Boundaries[token.characterEnd];
              while (start < end &&
                  quotationPunctuation.contains(
                    tokenizationContextStart + start,
                  )) {
                start += _utf16WidthAt(text, start);
              }
              while (end > start) {
                final edge = _previousCodePointStart(text, end);
                if (!quotationPunctuation.contains(
                  tokenizationContextStart + edge,
                )) {
                  break;
                }
                end = edge;
              }
              if (end <= start) continue;
              final word = text.substring(start, end);
              final cacheKey =
                  '${context['identity'] ?? _contextIdentity}\u0000${unicode.nfc(word)}';
              var outcome = _wordCache.remove(cacheKey);
              if (outcome == null) {
                try {
                  outcome = dictionary.check(word) == NativeSpellResult.accepted
                      ? 'accepted'
                      : 'rejected';
                } on Object catch (error) {
                  complete = false;
                  firstError ??= error.toString();
                  occurrences.add({
                    'runIndex': runIndex,
                    'start': start,
                    'end': end,
                    'outcome': 'unchecked',
                    'error': error.toString(),
                  });
                  continue;
                }
              }
              _wordCache[cacheKey] = outcome;
              while (_wordCache.length > _maximumCachedWords) {
                _wordCache.remove(_wordCache.keys.first);
              }
              if (outcome == 'rejected') {
                occurrences.add({
                  'runIndex': runIndex,
                  'start': start,
                  'end': end,
                  'outcome': outcome,
                });
              }
              wordsSinceYield++;
              if (wordsSinceYield >= _wordBatchSize) {
                wordsSinceYield = 0;
                await Future<void>.delayed(Duration.zero);
                await _serviceSuggestionsDuringCheck();
              }
            }
          }
        } on Object catch (error) {
          complete = false;
          firstError ??= error.toString();
          occurrences.add({
            'runIndex': runIndex,
            'start': 0,
            'end': 0,
            'outcome': 'unchecked',
            'error': error.toString(),
          });
        }
        if (runCursor % 8 == 7) {
          await Future<void>.delayed(Duration.zero);
        }
      }
      mainPort.send({
        'requestId': requestId,
        'occurrences': occurrences,
        'cancelled': false,
        'complete': complete,
        if (firstError != null) 'error': firstError,
      });
    } on Object catch (error) {
      mainPort.send({
        'requestId': requestId,
        'occurrences': occurrences,
        'cancelled': false,
        'complete': false,
        'error': error.toString(),
      });
    }
  }

  Future<void> _suggest(Map<Object?, Object?> request) async {
    try {
      final context = (request['context'] as Map).cast<Object?, Object?>();
      final dictionary = _ensureDictionary(context);
      final suggestions = dictionary.suggest(request['word'].toString());
      mainPort.send({
        'requestId': request['requestId'],
        'suggestions': suggestions,
      });
    } on Object catch (error) {
      mainPort.send({
        'requestId': request['requestId'],
        'fatal': true,
        'error': error.toString(),
      });
    }
  }

  Future<void> _serviceSuggestionsDuringCheck() async {
    while (true) {
      final index = _sideRequestQueue.indexWhere(
        (request) => request['type'] == 'suggest',
      );
      if (index < 0) return;
      final request = _sideRequestQueue.removeAt(index);
      final context = (request['context'] as Map).cast<Object?, Object?>();
      if (context['identity'] != _contextIdentity) {
        mainPort.send({
          'requestId': request['requestId'],
          'fatal': true,
          'error': 'The spelling suggestion context became obsolete.',
        });
        continue;
      }
      await _suggest(request);
    }
  }

  Future<void> _project(Map<Object?, Object?> request) async {
    try {
      final job = (request['job'] as Map).cast<Object?, Object?>();
      final snapshot = job['snapshot'];
      if (snapshot is! SpellingSnapshotIdentity) {
        throw const FormatException('Projection snapshot is unavailable.');
      }
      final documentKind = DocumentKind.values.byName(
        job['documentKind'].toString(),
      );
      final markdownMode = MarkdownMode.values.byName(
        job['markdownMode'].toString(),
      );
      final filePath = job['filePath'].toString();
      final source = job['source'].toString();
      final languageId = job['languageId'].toString();
      final richDocument = job['richDocument'];
      final cacheKey =
          '${snapshot.bufferId}\u0000$filePath\u0000${documentKind.name}\u0000'
          '${richDocument == null ? 'source' : 'rich'}';
      final previous = _projectionCache.remove(cacheKey);
      SpellingProjectionResult projection;
      if (previous != null &&
          previous.source == source &&
          previous.filePath == filePath &&
          previous.markdownMode == markdownMode &&
          previous.languageId == languageId &&
          previous.richDocumentGeneration ==
              (job['richDocumentGeneration'] as int)) {
        projection = _rebindProjection(
          previous.projection,
          snapshot,
          filePath: filePath,
        );
      } else if (richDocument == null &&
          previous != null &&
          (documentKind == DocumentKind.markdown ||
              documentKind == DocumentKind.writersideMarkdownTopic) &&
          previous.markdownMode == markdownMode &&
          previous.languageId == languageId) {
        projection =
            _incrementalPlainMarkdownProjection(
              previous: previous,
              source: source,
              filePath: filePath,
              mode: markdownMode,
              languageId: languageId,
              snapshot: snapshot,
            ) ??
            const MarkdownSpellingProjector().project(
              filePath: filePath,
              source: source,
              mode: markdownMode,
              languageId: languageId,
              snapshot: snapshot,
            );
      } else {
        projection = richDocument is BusyDocument
            ? const WysiwygSpellingProjector().project(
                document: richDocument,
                languageId: languageId,
                snapshot: snapshot,
                documentGeneration: job['richDocumentGeneration'] as int,
              )
            : switch (documentKind) {
                DocumentKind.markdown || DocumentKind.writersideMarkdownTopic =>
                  const MarkdownSpellingProjector().project(
                    filePath: filePath,
                    source: source,
                    mode: markdownMode,
                    languageId: languageId,
                    snapshot: snapshot,
                  ),
                DocumentKind.writersideXmlTopic =>
                  const WritersideXmlSpellingProjector().project(
                    filePath: filePath,
                    source: source,
                    languageId: languageId,
                    snapshot: snapshot,
                  ),
                _ => const SpellingProjectionResult(runs: [], complete: true),
              };
      }
      _projectionCache[cacheKey] = _ProjectionCacheEntry(
        source: source,
        filePath: filePath,
        markdownMode: markdownMode,
        languageId: languageId,
        richDocumentGeneration: job['richDocumentGeneration'] as int,
        projection: projection,
      );
      while (_projectionCache.length > 8) {
        _projectionCache.remove(_projectionCache.keys.first);
      }
      mainPort.send({
        'requestId': request['requestId'],
        'projection': projection,
      });
    } on Object catch (error) {
      mainPort.send({
        'requestId': request['requestId'],
        'fatal': true,
        'error': error.toString(),
      });
    }
  }

  Future<void> _validateDictionary(Map<Object?, Object?> request) async {
    _disposeDictionary();
    try {
      final dictionary = NativeSpellDictionary.open(
        affPath: request['affPath'].toString(),
        dicPath: request['dicPath'].toString(),
      );
      try {
        final encoding = dictionary.encoding.trim();
        if (encoding.isEmpty) {
          throw const FormatException(
            'Dictionary declares no usable encoding.',
          );
        }
        final knownValidProbe = request['knownValidProbe']?.toString();
        if (knownValidProbe != null &&
            knownValidProbe.isNotEmpty &&
            dictionary.check(knownValidProbe) != NativeSpellResult.accepted) {
          throw FormatException(
            'Dictionary rejected its catalog validation probe.',
          );
        }
        mainPort.send({
          'requestId': request['requestId'],
          'encoding': encoding,
        });
      } finally {
        dictionary.close();
      }
    } on Object catch (error) {
      mainPort.send({
        'requestId': request['requestId'],
        'fatal': true,
        'error': error.toString(),
      });
    }
  }

  NativeSpellDictionary _ensureDictionary(Map<Object?, Object?> context) {
    final identity = context['identity'].toString();
    if (_dictionary != null && _contextIdentity == identity) {
      return _dictionary!;
    }
    _disposeDictionary();
    final dictionary = NativeSpellDictionary.open(
      affPath: context['affPath'].toString(),
      dicPath: context['dicPath'].toString(),
    );
    try {
      for (final word in (context['customWords'] as List? ?? const [])) {
        dictionary.add(word.toString());
      }
    } on Object {
      dictionary.close();
      rethrow;
    }
    _dictionary = dictionary;
    _contextIdentity = identity;
    _wordCache.clear();
    return dictionary;
  }

  void _disposeDictionary() {
    _dictionary?.close();
    _dictionary = null;
    _contextIdentity = null;
    _wordCache.clear();
  }
}

final class _ProjectionCacheEntry {
  const _ProjectionCacheEntry({
    required this.source,
    required this.filePath,
    required this.markdownMode,
    required this.languageId,
    required this.richDocumentGeneration,
    required this.projection,
  });

  final String source;
  final String filePath;
  final MarkdownMode markdownMode;
  final String languageId;
  final int richDocumentGeneration;
  final SpellingProjectionResult projection;
}

SpellingProjectionResult _rebindProjection(
  SpellingProjectionResult projection,
  SpellingSnapshotIdentity snapshot, {
  required String filePath,
}) => SpellingProjectionResult(
  runs: List.unmodifiable([
    for (final (index, run) in projection.runs.indexed)
      _copyProjectedRun(
        run,
        id: 'cached:$index',
        snapshot: snapshot,
        sourceDelta: 0,
        filePath: filePath,
      ),
  ]),
  complete: projection.complete,
  message: projection.message,
);

SpellingProjectionResult? _incrementalPlainMarkdownProjection({
  required _ProjectionCacheEntry previous,
  required String source,
  required String filePath,
  required MarkdownMode mode,
  required String languageId,
  required SpellingSnapshotIdentity snapshot,
}) {
  final oldSource = previous.source;
  var prefix = 0;
  final shared = oldSource.length < source.length
      ? oldSource.length
      : source.length;
  while (prefix < shared &&
      oldSource.codeUnitAt(prefix) == source.codeUnitAt(prefix)) {
    prefix++;
  }
  var oldSuffix = oldSource.length;
  var newSuffix = source.length;
  while (oldSuffix > prefix &&
      newSuffix > prefix &&
      oldSource.codeUnitAt(oldSuffix - 1) == source.codeUnitAt(newSuffix - 1)) {
    oldSuffix--;
    newSuffix--;
  }
  final oldRegion = _singleLineParagraphRegion(oldSource, prefix, oldSuffix);
  final newRegion = _singleLineParagraphRegion(source, prefix, newSuffix);
  if (oldRegion == null || newRegion == null) return null;
  final oldFragment = oldSource.substring(oldRegion.start, oldRegion.end);
  final newFragment = source.substring(newRegion.start, newRegion.end);
  if (!_plainMarkdownParagraph(oldFragment) ||
      !_plainMarkdownParagraph(newFragment)) {
    return null;
  }
  final owners = <({SpellingProseRun run, int start, int end})>[];
  for (final run in previous.projection.runs) {
    final bounds = _projectedRunSourceBounds(run);
    if (bounds == null) return null;
    final ownsChange = oldSuffix == prefix
        ? bounds.start <= prefix && prefix <= bounds.end
        : bounds.start <= prefix && bounds.end >= oldSuffix;
    if (ownsChange) {
      owners.add((run: run, start: bounds.start, end: bounds.end));
    }
  }
  // Parsing an isolated line is safe only when the prior full projection says
  // the edit belongs to one eligible prose leaf. An excluded or ambiguous
  // region (fences, comments, front matter, HTML, or nested containers) must
  // be projected with its complete parser context.
  if (owners.length != 1 ||
      owners.single.start < oldRegion.start ||
      owners.single.end > oldRegion.end) {
    return null;
  }
  final delta = newRegion.end - oldRegion.end;
  final before = <SpellingProseRun>[];
  final after = <SpellingProseRun>[];
  for (final run in previous.projection.runs) {
    final bounds = _projectedRunSourceBounds(run);
    if (bounds == null) return null;
    if (bounds.end <= oldRegion.start) {
      before.add(run);
    } else if (bounds.start >= oldRegion.end) {
      after.add(run);
    } else if (bounds.start < oldRegion.start || bounds.end > oldRegion.end) {
      return null;
    }
  }
  final changed = const MarkdownSpellingProjector().project(
    filePath: filePath,
    source: newFragment,
    mode: mode,
    languageId: languageId,
    snapshot: snapshot,
  );
  if (!changed.complete) return null;
  final combined = <SpellingProseRun>[
    for (final run in before)
      _copyProjectedRun(
        run,
        id: '',
        snapshot: snapshot,
        sourceDelta: 0,
        filePath: filePath,
      ),
    for (final run in changed.runs)
      _copyProjectedRun(
        run,
        id: '',
        snapshot: snapshot,
        sourceDelta: newRegion.start,
        filePath: filePath,
      ),
    for (final run in after)
      _copyProjectedRun(
        run,
        id: '',
        snapshot: snapshot,
        sourceDelta: delta,
        filePath: filePath,
      ),
  ];
  return SpellingProjectionResult(
    runs: List.unmodifiable([
      for (final (index, run) in combined.indexed)
        SpellingProseRun(
          id: 'incremental:$index',
          text: run.text,
          languageId: run.languageId,
          atoms: run.atoms,
          target: run.target,
          snapshot: run.snapshot,
          formattingWrappers: run.formattingWrappers,
          complete: run.complete,
          tokenizationContext: run.tokenizationContext,
          tokenizationContextStart: run.tokenizationContextStart,
        ),
    ]),
    complete: previous.projection.complete,
    message: previous.projection.message,
  );
}

({int start, int end})? _singleLineParagraphRegion(
  String source,
  int changedStart,
  int changedEnd,
) {
  var start = 0;
  var end = source.length;
  for (final separator in RegExp(r'\r?\n[ \t]*\r?\n').allMatches(source)) {
    if (separator.end <= changedStart) {
      start = separator.end;
    } else if (separator.start >= changedEnd) {
      end = separator.start;
      break;
    }
  }
  if (source.substring(start, end).contains(RegExp(r'[\r\n]'))) return null;
  return (start: start, end: end);
}

bool _plainMarkdownParagraph(String value) {
  if (RegExp(r'[`~$<>{}\[\]\\*_#|%&]').hasMatch(value)) return false;
  if (RegExp(r'^(?: {4}|\t)').hasMatch(value)) return false;
  if (RegExp(r'^\s*(?:>|[-+*]\s|\d+[.)]\s|---(?:\s|$))').hasMatch(value)) {
    return false;
  }
  return true;
}

({int start, int end})? _projectedRunSourceBounds(SpellingProseRun run) {
  final atoms = run.atoms.where((atom) => atom.sourceStart >= 0).toList();
  if (atoms.length != run.atoms.length || atoms.isEmpty) return null;
  var start = atoms.first.sourceStart;
  var end = atoms.first.sourceEnd;
  for (final atom in atoms.skip(1)) {
    if (atom.sourceStart < start) start = atom.sourceStart;
    if (atom.sourceEnd > end) end = atom.sourceEnd;
  }
  return (start: start, end: end);
}

SpellingProseRun _copyProjectedRun(
  SpellingProseRun run, {
  required String id,
  required SpellingSnapshotIdentity snapshot,
  required int sourceDelta,
  String? filePath,
}) => SpellingProseRun(
  id: id.isEmpty ? run.id : id,
  text: run.text,
  languageId: run.languageId,
  atoms: List.unmodifiable([
    for (final atom in run.atoms)
      SpellingSourceAtom(
        logicalText: atom.logicalText,
        logicalStart: atom.logicalStart,
        logicalEnd: atom.logicalEnd,
        sourceStart: atom.sourceStart < 0
            ? atom.sourceStart
            : atom.sourceStart + sourceDelta,
        sourceEnd: atom.sourceEnd < 0
            ? atom.sourceEnd
            : atom.sourceEnd + sourceDelta,
        transformation: atom.transformation,
        context: atom.context,
        fieldStart: atom.fieldStart,
        fieldEnd: atom.fieldEnd,
        richLeafPath: atom.richLeafPath,
      ),
  ]),
  target: switch (run.target) {
    SpellingSourceTarget() when filePath != null => SpellingSourceTarget(
      filePath: filePath,
    ),
    final target => target,
  },
  snapshot: snapshot,
  formattingWrappers: List.unmodifiable([
    for (final wrapper in run.formattingWrappers)
      SpellingFormattingWrapper(
        logicalStart: wrapper.logicalStart,
        logicalEnd: wrapper.logicalEnd,
        openingStart: wrapper.openingStart < 0
            ? wrapper.openingStart
            : wrapper.openingStart + sourceDelta,
        openingEnd: wrapper.openingEnd < 0
            ? wrapper.openingEnd
            : wrapper.openingEnd + sourceDelta,
        closingStart: wrapper.closingStart < 0
            ? wrapper.closingStart
            : wrapper.closingStart + sourceDelta,
        closingEnd: wrapper.closingEnd < 0
            ? wrapper.closingEnd
            : wrapper.closingEnd + sourceDelta,
        removableWhenLogicallyEmpty: wrapper.removableWhenLogicallyEmpty,
        fieldOpeningStart: wrapper.fieldOpeningStart,
        fieldOpeningEnd: wrapper.fieldOpeningEnd,
        fieldClosingStart: wrapper.fieldClosingStart,
        fieldClosingEnd: wrapper.fieldClosingEnd,
        structuralKind: wrapper.structuralKind,
      ),
  ]),
  complete: run.complete,
  tokenizationContext: run.tokenizationContext,
  tokenizationContextStart: run.tokenizationContextStart,
);

const _maximumProseChunkBytes = 48 * 1024;
const _maximumCachedWords = 8192;
const _wordBatchSize = 256;
const _maximumPendingSuggestions = 32;

Set<int> _quotationPunctuationOffsets(String text) {
  final result = <int>{};
  int? straightOpening;
  int? curlyOpening;
  var offset = 0;
  while (offset < text.length) {
    final rune = _codePointAtUtf16(text, offset);
    final width = rune > 0xffff ? 2 : 1;
    if (rune == 0x0a || rune == 0x0d) {
      straightOpening = null;
      curlyOpening = null;
      offset += width;
      continue;
    }
    if (rune != 0x27 && rune != 0x2018 && rune != 0x2019) {
      offset += width;
      continue;
    }
    final previousWord = _wordCharacterBefore(text, offset);
    final nextWord = _wordCharacterAt(text, offset + width);
    if (rune != 0x2018 && previousWord && nextWord) {
      offset += width;
      continue;
    }
    if (rune == 0x2018) {
      result.add(offset);
      curlyOpening = offset;
    } else if (rune == 0x2019) {
      if (curlyOpening != null) {
        result.add(curlyOpening);
        result.add(offset);
        curlyOpening = null;
      }
    } else {
      final opens = !previousWord && nextWord;
      final closes = previousWord && !nextWord;
      if (straightOpening != null && closes) {
        result.add(straightOpening);
        result.add(offset);
        straightOpening = null;
      } else {
        straightOpening = opens ? offset : null;
      }
    }
    offset += width;
  }
  return result;
}

bool _wordCharacterBefore(String text, int offset) =>
    offset > 0 &&
    _isWordCharacter(
      _codePointAtUtf16(text, _previousCodePointStart(text, offset)),
    );

bool _wordCharacterAt(String text, int offset) =>
    offset < text.length && _isWordCharacter(_codePointAtUtf16(text, offset));

bool _isWordCharacter(int rune) {
  if ((rune >= 0x41 && rune <= 0x5a) ||
      (rune >= 0x61 && rune <= 0x7a) ||
      _isCombiningMark(rune)) {
    return true;
  }
  final character = String.fromCharCode(rune);
  return character.toLowerCase() != character.toUpperCase();
}

bool _isCombiningMark(int rune) =>
    (rune >= 0x0300 && rune <= 0x036f) ||
    (rune >= 0x1ab0 && rune <= 0x1aff) ||
    (rune >= 0x1dc0 && rune <= 0x1dff) ||
    (rune >= 0x20d0 && rune <= 0x20ff) ||
    (rune >= 0xfe20 && rune <= 0xfe2f);

int _utf16WidthAt(String text, int offset) =>
    _codePointAtUtf16(text, offset) > 0xffff ? 2 : 1;

int _previousCodePointStart(String text, int offset) {
  var start = offset - 1;
  if (start > 0) {
    final unit = text.codeUnitAt(start);
    final previous = text.codeUnitAt(start - 1);
    if (unit >= 0xdc00 &&
        unit <= 0xdfff &&
        previous >= 0xd800 &&
        previous <= 0xdbff) {
      start--;
    }
  }
  return start;
}

final class _ProseChunk {
  const _ProseChunk({required this.text, required this.utf16Start, this.error});

  final String text;
  final int utf16Start;
  final String? error;
}

Iterable<_ProseChunk> _boundedProseChunks(
  String text, {
  required NativeSpellDictionary dictionary,
  required String language,
}) sync* {
  var start = 0;
  while (start < text.length) {
    var cursor = start;
    var bytes = 0;
    int? lastWhitespaceBoundary;
    while (cursor < text.length) {
      final rune = _codePointAtUtf16(text, cursor);
      final width = rune > 0xffff ? 2 : 1;
      final encodedWidth = rune <= 0x7f
          ? 1
          : rune <= 0x7ff
          ? 2
          : rune <= 0xffff
          ? 3
          : 4;
      if (bytes + encodedWidth > _maximumProseChunkBytes) break;
      bytes += encodedWidth;
      cursor += width;
      if (_unicodeWhitespace.hasMatch(String.fromCharCode(rune))) {
        lastWhitespaceBoundary = cursor;
      }
    }
    if (cursor >= text.length) {
      yield _ProseChunk(text: text.substring(start), utf16Start: start);
      break;
    }
    var end = lastWhitespaceBoundary != null && lastWhitespaceBoundary > start
        ? lastWhitespaceBoundary
        : null;
    if (end == null) {
      // Ask the same Pango-backed tokenizer used for checking where the last
      // complete candidate begins. Ending immediately before that candidate
      // is safe even for scripts that do not separate words with spaces. An
      // artificial end-of-probe word boundary is deliberately not trusted.
      final probe = text.substring(start, cursor);
      final boundaries = _codePointToUtf16Boundaries(probe);
      final tokens = dictionary.tokenize(probe, language: language);
      for (final token in tokens.reversed) {
        if (token.characterStart > 0 &&
            token.characterStart < boundaries.length) {
          end = start + boundaries[token.characterStart];
          break;
        }
      }
      if (end == null) {
        for (final token in tokens.reversed) {
          if (token.characterEnd > 0 &&
              token.characterEnd < boundaries.length - 1) {
            end = start + boundaries[token.characterEnd];
            break;
          }
        }
      }
      // Pango found no candidate at all, so the probe cannot cut a spelling
      // token even though it contains no whitespace (for example a long run
      // of non-word punctuation).
      if (end == null && tokens.isEmpty) end = cursor;
    }
    end ??= start;
    if (end <= start) {
      final tokenEnd = _oversizedTokenEnd(
        text,
        start: start,
        firstProbeEnd: cursor,
        dictionary: dictionary,
        language: language,
      );
      yield _ProseChunk(
        text: text.substring(start, tokenEnd),
        utf16Start: start,
        error: 'A spelling token exceeds the bounded native input size.',
      );
      start = tokenEnd;
      continue;
    }
    yield _ProseChunk(text: text.substring(start, end), utf16Start: start);
    start = end;
  }
}

int _oversizedTokenEnd(
  String text, {
  required int start,
  required int firstProbeEnd,
  required NativeSpellDictionary dictionary,
  required String language,
}) {
  var probeStart = firstProbeEnd;
  while (probeStart < text.length) {
    var probeEnd = probeStart;
    var bytes = 0;
    while (probeEnd < text.length) {
      final rune = _codePointAtUtf16(text, probeEnd);
      final width = rune > 0xffff ? 2 : 1;
      final encodedWidth = rune <= 0x7f
          ? 1
          : rune <= 0x7ff
          ? 2
          : rune <= 0xffff
          ? 3
          : 4;
      if (bytes + encodedWidth > _maximumProseChunkBytes) break;
      bytes += encodedWidth;
      probeEnd += width;
    }
    if (probeEnd <= probeStart) break;
    final probe = text.substring(probeStart, probeEnd);
    final boundaries = _codePointToUtf16Boundaries(probe);
    final tokens = dictionary.tokenize(probe, language: language);
    if (tokens.isEmpty || tokens.first.characterStart > 0) {
      return probeStart;
    }
    final first = tokens.first;
    if (first.characterEnd < boundaries.length - 1) {
      return probeStart + boundaries[first.characterEnd];
    }
    if (probeEnd == text.length) return text.length;
    probeStart = probeEnd;
  }
  // Defensive progress for an invalid tokenizer response. This remains
  // bounded to the first native-safe probe rather than consuming a complete
  // whitespace-delimited segment and hiding later punctuation-separated words.
  return firstProbeEnd > start ? firstProbeEnd : text.length;
}

final RegExp _unicodeWhitespace = RegExp(r'^\s$', unicode: true);

int _codePointAtUtf16(String text, int offset) {
  final first = text.codeUnitAt(offset);
  if (first >= 0xd800 && first <= 0xdbff && offset + 1 < text.length) {
    final second = text.codeUnitAt(offset + 1);
    if (second >= 0xdc00 && second <= 0xdfff) {
      return 0x10000 + ((first - 0xd800) << 10) + (second - 0xdc00);
    }
  }
  return first;
}

List<int> _codePointToUtf16Boundaries(String text) {
  final boundaries = <int>[0];
  var offset = 0;
  for (final rune in text.runes) {
    offset += rune > 0xffff ? 2 : 1;
    boundaries.add(offset);
  }
  return boundaries;
}
