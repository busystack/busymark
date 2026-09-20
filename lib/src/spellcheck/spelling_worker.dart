import 'dart:async';
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

  String get identity => [
    languageId,
    baseFingerprint,
    personalRevision,
    projectIdentity ?? '',
    projectRevision,
  ].join('\u0000');

  Map<String, Object?> toMessage() => {
    'languageId': languageId,
    'affPath': affPath,
    'dicPath': dicPath,
    'baseFingerprint': baseFingerprint,
    'personalRevision': personalRevision,
    'projectIdentity': projectIdentity,
    'projectRevision': projectRevision,
    'customWords': customWords,
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
          {'index': index, 'text': runs[index].text},
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
          id: '${run.snapshot.bufferId}:${run.snapshot.contentRevision}:${run.id}:$start:$end',
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
  }) async {
    _requireOpen();
    final message = await _request({
      'type': 'validate',
      'requestId': _nextRequest++,
      'affPath': affPath,
      'dicPath': dicPath,
    });
    return message['encoding']?.toString() ?? '';
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
  final Map<String, String> _wordCache = {};
  Map<Object?, Object?>? _newestCheck;
  final List<Map<Object?, Object?>> _sideRequestQueue = [];
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
      case 'validate':
      case 'project':
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
        try {
          final utf16Boundaries = _codePointToUtf16Boundaries(text);
          final tokens = dictionary.tokenize(text, language: language);
          for (final token in tokens) {
            if (token.characterStart >= utf16Boundaries.length ||
                token.characterEnd >= utf16Boundaries.length) {
              throw const FormatException('Native token boundary is invalid.');
            }
            final start = utf16Boundaries[token.characterStart];
            final end = utf16Boundaries[token.characterEnd];
            if (end <= start) continue;
            final word = text.substring(start, end);
            final cacheKey =
                '${context['identity'] ?? _contextIdentity}\u0000${unicode.nfc(word)}';
            var outcome = _wordCache[cacheKey];
            if (outcome == null) {
              outcome = dictionary.check(word) == NativeSpellResult.accepted
                  ? 'accepted'
                  : 'rejected';
              _wordCache[cacheKey] = outcome;
            }
            occurrences.add({
              'runIndex': runIndex,
              'start': start,
              'end': end,
              'outcome': outcome,
            });
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
      final projection = richDocument is BusyDocument
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
        dictionary.check('BusyMark');
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
    final identity = [
      context['languageId'],
      context['baseFingerprint'],
      context['personalRevision'],
      context['projectIdentity'] ?? '',
      context['projectRevision'],
    ].join('\u0000');
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

List<int> _codePointToUtf16Boundaries(String text) {
  final boundaries = <int>[0];
  var offset = 0;
  for (final rune in text.runes) {
    offset += rune > 0xffff ? 2 : 1;
    boundaries.add(offset);
  }
  return boundaries;
}
