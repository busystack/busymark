import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:unorm_dart/unorm_dart.dart' as unicode;

import 'spelling_projection.dart';
import 'spelling_worker.dart';

typedef SpellingSuggestionLookup =
    Future<List<String>> Function(SpellingEngineContext context, String word);

enum SpellingPresentationStatus {
  languageRequired,
  checking,
  ready,
  dictionaryNotInstalled,
  dictionaryUnavailable,
  failure,
  incomplete,
  disabled,
}

final class SpellingPresentationState {
  const SpellingPresentationState({
    required this.status,
    required this.occurrences,
    required this.complete,
    this.message,
  });

  const SpellingPresentationState.languageRequired()
    : this(
        status: SpellingPresentationStatus.languageRequired,
        occurrences: const [],
        complete: false,
      );

  final SpellingPresentationStatus status;
  final List<SpellingOccurrence> occurrences;
  final bool complete;
  final String? message;
}

final class SpellingAnnotation {
  const SpellingAnnotation({
    required this.occurrenceId,
    required this.start,
    required this.end,
    required this.target,
  });

  final String occurrenceId;
  final int start;
  final int end;
  final SpellingEditorTarget target;
}

final class SpellingCheckRequest {
  const SpellingCheckRequest({
    required this.snapshot,
    required this.engineContext,
    required this.project,
    this.automatic = true,
  });

  final SpellingSnapshotIdentity snapshot;
  final SpellingEngineContext engineContext;
  final Future<SpellingProjectionResult> Function() project;
  final bool automatic;
}

/// Coordinates a reusable worker with one running check and only the newest
/// pending snapshot. Results live outside document state and never dirty it.
final class SpellingCoordinator extends ChangeNotifier {
  SpellingCoordinator._(this._worker, this._suggestionLookup);

  static Future<SpellingCoordinator> start({
    SpellingSuggestionLookup? suggestionLookup,
  }) async =>
      SpellingCoordinator._(await SpellingWorker.start(), suggestionLookup);

  final SpellingWorker _worker;
  final SpellingSuggestionLookup? _suggestionLookup;
  Timer? _debounce;
  _PendingSpellingCheck? _pending;
  int _presentationGeneration = 0;
  bool _running = false;
  bool _closed = false;
  final List<_IgnoredOccurrence> _ignoredOccurrences = [];
  final Map<String, Set<String>> _ignoredDocumentWords = {};
  final LinkedHashMap<String, List<_CachedRunOccurrence>> _runResultCache =
      LinkedHashMap();

  SpellingPresentationState _state =
      const SpellingPresentationState.languageRequired();
  SpellingPresentationState get state => _state;

  List<SpellingOccurrence> get misspellings => _state.occurrences
      .where((item) => item.outcome == SpellingCheckOutcome.rejected)
      .toList(growable: false);

  List<SpellingAnnotation> get annotations {
    final result = <SpellingAnnotation>[];
    for (final occurrence in misspellings) {
      if (_suppressed(occurrence)) continue;
      final intervals = occurrence.run.target is SpellingSourceTarget
          ? occurrence.sourceIntervals
          : occurrence.fieldIntervals;
      for (final interval in intervals) {
        result.add(
          SpellingAnnotation(
            occurrenceId: occurrence.id,
            start: interval.start,
            end: interval.end,
            target: occurrence.run.target,
          ),
        );
      }
    }
    return List.unmodifiable(result);
  }

  void schedule(
    SpellingCheckRequest request, {
    Duration debounce = const Duration(milliseconds: 250),
  }) {
    if (_closed) return;
    _pending?.complete();
    _pending = _PendingSpellingCheck(request);
    _presentationGeneration++;
    _worker.cancelChecks();
    _debounce?.cancel();
    _setState(
      SpellingPresentationState(
        status: SpellingPresentationStatus.checking,
        occurrences: const [],
        complete: false,
        message: _state.message,
      ),
    );
    _debounce = Timer(debounce, _drain);
  }

  Future<void> checkNow(SpellingCheckRequest request) async {
    if (_closed) return;
    _pending?.complete();
    final pending = _PendingSpellingCheck(request, waitForCompletion: true);
    _pending = pending;
    _presentationGeneration++;
    _worker.cancelChecks();
    _debounce?.cancel();
    _setState(
      const SpellingPresentationState(
        status: SpellingPresentationStatus.checking,
        occurrences: [],
        complete: false,
      ),
    );
    unawaited(_drain());
    await pending.completed;
  }

  void showLanguageRequired() {
    _cancelPresentation();
    _setState(const SpellingPresentationState.languageRequired());
  }

  void showDictionaryUnavailable(String languageId) {
    _cancelPresentation();
    _setState(
      SpellingPresentationState(
        status: SpellingPresentationStatus.dictionaryUnavailable,
        occurrences: const [],
        complete: false,
        message: languageId,
      ),
    );
  }

  void showDictionaryNotInstalled(String languageId) {
    _cancelPresentation();
    _setState(
      SpellingPresentationState(
        status: SpellingPresentationStatus.dictionaryNotInstalled,
        occurrences: const [],
        complete: false,
        message: languageId,
      ),
    );
  }

  void disablePresentation() {
    _cancelPresentation();
    _setState(
      const SpellingPresentationState(
        status: SpellingPresentationStatus.disabled,
        occurrences: [],
        complete: false,
      ),
    );
  }

  SpellingOccurrence? occurrenceAtSource(int offset) {
    for (final occurrence in misspellings) {
      if (_suppressed(occurrence)) continue;
      if (occurrence.sourceIntervals.any((range) => range.contains(offset))) {
        return occurrence;
      }
    }
    return null;
  }

  SpellingOccurrence? occurrenceAtField({
    required SpellingEditorTarget target,
    required int offset,
  }) {
    for (final occurrence in misspellings) {
      if (_suppressed(occurrence) ||
          !_sameTarget(occurrence.run.target, target)) {
        continue;
      }
      if (occurrence.fieldIntervals.any((range) => range.contains(offset))) {
        return occurrence;
      }
    }
    return null;
  }

  Future<List<String>> suggestions(
    SpellingOccurrence occurrence, {
    required SpellingEngineContext context,
  }) async {
    if (!isCurrent(occurrence)) {
      throw StateError('The spelling occurrence is stale.');
    }
    if (context.languageId != occurrence.run.languageId) {
      throw StateError('The spelling dictionary context changed.');
    }
    final result =
        await (_suggestionLookup?.call(context, occurrence.word) ??
            _worker.suggestions(context: context, word: occurrence.word));
    if (!isCurrent(occurrence)) {
      throw StateError('The spelling occurrence became stale.');
    }
    return result;
  }

  Future<String> validateDictionary({
    required String affPath,
    required String dicPath,
    String? knownValidProbe,
  }) => _worker.validateDictionary(
    affPath: affPath,
    dicPath: dicPath,
    knownValidProbe: knownValidProbe,
  );

  Future<void> releaseDictionary() => _worker.releaseDictionary();

  Future<SpellingProjectionResult> project(SpellingProjectionJob job) =>
      _worker.project(job);

  bool isCurrent(SpellingOccurrence occurrence) =>
      misspellings.any(
        (candidate) =>
            candidate.id == occurrence.id &&
            candidate.run.snapshot == occurrence.run.snapshot &&
            candidate.run.languageId == occurrence.run.languageId &&
            candidate.word == occurrence.word,
      ) &&
      !_suppressed(occurrence);

  void ignoreOnce(SpellingOccurrence occurrence) {
    if (!isCurrent(occurrence)) return;
    _ignoredOccurrences.removeWhere((item) => item.matches(occurrence));
    _ignoredOccurrences.add(_IgnoredOccurrence.fromOccurrence(occurrence));
    notifyListeners();
  }

  void ignoreAllInDocument(SpellingOccurrence occurrence) {
    if (!isCurrent(occurrence)) return;
    _ignoredDocumentWords
        .putIfAbsent(
          '${occurrence.run.snapshot.bufferId}\u0000${occurrence.run.languageId}',
          () => {},
        )
        .add(_temporaryWordKey(occurrence.word));
    notifyListeners();
  }

  void closeBuffer(String bufferId) {
    _ignoredDocumentWords.removeWhere(
      (key, _) => key.startsWith('$bufferId\u0000'),
    );
    _ignoredOccurrences.removeWhere((item) => item.bufferId == bufferId);
  }

  /// Drops position-bound suppressions when document contents are replaced
  /// without an exact edit transaction (for example, a disk reload).
  void invalidateBufferAnchors(String bufferId) {
    _ignoredOccurrences.removeWhere((item) => item.bufferId == bufferId);
  }

  /// Translates source anchors across a known exact edit. An overlapping edit
  /// invalidates Ignore Once instead of guessing a new occurrence.
  void translateSourceEdit({
    required String bufferId,
    required int start,
    required int oldEnd,
    required int newEnd,
  }) {
    final delta = newEnd - oldEnd;
    for (var index = _ignoredOccurrences.length - 1; index >= 0; index--) {
      final item = _ignoredOccurrences[index];
      if (item.bufferId != bufferId || item.sourceStart == null) continue;
      if (item.sourceEnd! > start && item.sourceStart! < oldEnd) {
        _ignoredOccurrences.removeAt(index);
      } else if (item.sourceStart! >= oldEnd) {
        _ignoredOccurrences[index] = item.shifted(delta);
      }
    }
  }

  Future<void> _drain() async {
    if (_running || _closed) return;
    _running = true;
    try {
      while (_pending != null) {
        final pending = _pending!;
        final request = pending.request;
        _pending = null;
        final generation = _presentationGeneration;
        try {
          final projection = await request.project();
          if (_closed || generation != _presentationGeneration) continue;
          final occurrences = <SpellingOccurrence>[];
          final uncheckedRuns = <SpellingProseRun>[];
          for (final run in projection.runs) {
            final cached = _takeCachedRun(request.engineContext, run);
            if (cached == null) {
              uncheckedRuns.add(run);
            } else {
              occurrences.addAll(
                cached
                    .map((item) => item.bind(run))
                    .whereType<SpellingOccurrence>(),
              );
            }
          }
          if (_closed || generation != _presentationGeneration) continue;
          if (occurrences.isNotEmpty) {
            _publishProgress(occurrences, projection.message);
          }
          var nativeComplete = true;
          String? nativeError;
          const batchSize = 12;
          for (
            var start = 0;
            start < uncheckedRuns.length;
            start += batchSize
          ) {
            final end = (start + batchSize)
                .clamp(0, uncheckedRuns.length)
                .toInt();
            final batch = uncheckedRuns.sublist(start, end);
            final result = await _worker.check(
              context: request.engineContext,
              runs: batch,
            );
            if (_closed ||
                generation != _presentationGeneration ||
                result.cancelled) {
              break;
            }
            occurrences.addAll(result.occurrences);
            nativeComplete = nativeComplete && result.complete;
            nativeError ??= result.error;
            if (result.complete) {
              for (final run in batch) {
                _cacheRunResult(
                  request.engineContext,
                  run,
                  result.occurrences.where(
                    (occurrence) => identical(occurrence.run, run),
                  ),
                );
              }
            }
            _publishProgress(occurrences, nativeError ?? projection.message);
          }
          if (_closed || generation != _presentationGeneration) continue;
          final rejected = _orderedRejected(occurrences, projection.runs);
          final complete = projection.complete && nativeComplete;
          _setState(
            SpellingPresentationState(
              status: complete
                  ? SpellingPresentationStatus.ready
                  : SpellingPresentationStatus.incomplete,
              occurrences: rejected,
              complete: complete,
              message: nativeError ?? projection.message,
            ),
          );
        } on Object catch (error) {
          if (!_closed && generation == _presentationGeneration) {
            _setState(
              SpellingPresentationState(
                status: SpellingPresentationStatus.failure,
                occurrences: const [],
                complete: false,
                message: error.toString(),
              ),
            );
          }
        } finally {
          pending.complete();
        }
      }
    } finally {
      _running = false;
      if (_pending != null && !_closed) unawaited(_drain());
    }
  }

  bool _suppressed(SpellingOccurrence occurrence) {
    if (_ignoredOccurrences.any((item) => item.matches(occurrence))) {
      return true;
    }
    final words =
        _ignoredDocumentWords['${occurrence.run.snapshot.bufferId}\u0000${occurrence.run.languageId}'];
    return words?.contains(_temporaryWordKey(occurrence.word)) ?? false;
  }

  void _publishProgress(List<SpellingOccurrence> occurrences, String? message) {
    _setState(
      SpellingPresentationState(
        status: SpellingPresentationStatus.checking,
        occurrences: _orderedRejected(
          occurrences,
          occurrences.map((occurrence) => occurrence.run).toList(),
        ),
        complete: false,
        message: message,
      ),
    );
  }

  List<SpellingOccurrence> _orderedRejected(
    Iterable<SpellingOccurrence> occurrences,
    List<SpellingProseRun> runs,
  ) {
    final order = <SpellingProseRun, int>{
      for (final (index, run) in runs.indexed) run: index,
    };
    final rejected = occurrences
        .where((item) => item.outcome == SpellingCheckOutcome.rejected)
        .toList();
    rejected.sort((left, right) {
      final byRun = (order[left.run] ?? 0).compareTo(order[right.run] ?? 0);
      return byRun != 0
          ? byRun
          : left.logicalStart.compareTo(right.logicalStart);
    });
    return List.unmodifiable(rejected);
  }

  List<_CachedRunOccurrence>? _takeCachedRun(
    SpellingEngineContext context,
    SpellingProseRun run,
  ) {
    final key = _runCacheKey(context, run);
    final cached = _runResultCache.remove(key);
    if (cached == null) return null;
    _runResultCache[key] = cached;
    return cached;
  }

  void _cacheRunResult(
    SpellingEngineContext context,
    SpellingProseRun run,
    Iterable<SpellingOccurrence> occurrences,
  ) {
    final key = _runCacheKey(context, run);
    _runResultCache.remove(key);
    _runResultCache[key] = List.unmodifiable(
      occurrences.map(_CachedRunOccurrence.fromOccurrence),
    );
    while (_runResultCache.length > 512) {
      _runResultCache.remove(_runResultCache.keys.first);
    }
  }

  void _cancelPresentation() {
    _presentationGeneration++;
    _pending?.complete();
    _pending = null;
    _debounce?.cancel();
    _worker.cancelChecks();
  }

  void _setState(SpellingPresentationState state) {
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_closed) return;
    _closed = true;
    _pending?.complete();
    _pending = null;
    _debounce?.cancel();
    _worker.cancelChecks();
    unawaited(_worker.close());
    super.dispose();
  }
}

final class _PendingSpellingCheck {
  _PendingSpellingCheck(this.request, {bool waitForCompletion = false})
    : _completer = waitForCompletion ? Completer<void>() : null;

  final SpellingCheckRequest request;
  final Completer<void>? _completer;

  Future<void> get completed => _completer?.future ?? Future<void>.value();

  void complete() {
    if (!(_completer?.isCompleted ?? true)) _completer!.complete();
  }
}

String _temporaryWordKey(String word) => unicode.nfc(word).toLowerCase();

String _runCacheKey(SpellingEngineContext context, SpellingProseRun run) =>
    '${context.identity}\u0000${run.languageId}\u0000${run.text}';

final class _CachedRunOccurrence {
  const _CachedRunOccurrence({
    required this.logicalStart,
    required this.logicalEnd,
    required this.outcome,
  });

  factory _CachedRunOccurrence.fromOccurrence(SpellingOccurrence occurrence) =>
      _CachedRunOccurrence(
        logicalStart: occurrence.logicalStart,
        logicalEnd: occurrence.logicalEnd,
        outcome: occurrence.outcome,
      );

  final int logicalStart;
  final int logicalEnd;
  final SpellingCheckOutcome outcome;

  SpellingOccurrence? bind(SpellingProseRun run) {
    if (logicalStart < 0 ||
        logicalEnd <= logicalStart ||
        logicalEnd > run.text.length) {
      return null;
    }
    final word = run.text.substring(logicalStart, logicalEnd);
    return SpellingOccurrence(
      id:
          '${run.snapshot.bufferId}:${run.snapshot.contentRevision}:'
          '${run.snapshot.documentKind.name}:'
          '${run.snapshot.contextGeneration}:${run.languageId}:'
          '${run.id}:$logicalStart:$logicalEnd',
      run: run,
      logicalStart: logicalStart,
      logicalEnd: logicalEnd,
      word: word,
      outcome: outcome,
    );
  }
}

final class _IgnoredOccurrence {
  const _IgnoredOccurrence({
    required this.bufferId,
    required this.languageId,
    required this.word,
    required this.target,
    required this.sourceStart,
    required this.sourceEnd,
    required this.fieldStart,
    required this.fieldEnd,
  });

  factory _IgnoredOccurrence.fromOccurrence(SpellingOccurrence occurrence) =>
      _IgnoredOccurrence(
        bufferId: occurrence.run.snapshot.bufferId,
        languageId: occurrence.run.languageId,
        word: occurrence.word,
        target: occurrence.run.target,
        sourceStart: occurrence.sourceStart,
        sourceEnd: occurrence.sourceEnd,
        fieldStart: occurrence.fieldStart,
        fieldEnd: occurrence.fieldEnd,
      );

  final String bufferId;
  final String languageId;
  final String word;
  final SpellingEditorTarget target;
  final int? sourceStart;
  final int? sourceEnd;
  final int? fieldStart;
  final int? fieldEnd;

  bool matches(SpellingOccurrence occurrence) {
    if (bufferId != occurrence.run.snapshot.bufferId ||
        languageId != occurrence.run.languageId ||
        word != occurrence.word) {
      return false;
    }
    if (sourceStart != null && sourceEnd != null) {
      return sourceStart == occurrence.sourceStart &&
          sourceEnd == occurrence.sourceEnd;
    }
    return _sameTarget(target, occurrence.run.target) &&
        fieldStart == occurrence.fieldStart &&
        fieldEnd == occurrence.fieldEnd;
  }

  _IgnoredOccurrence shifted(int delta) => _IgnoredOccurrence(
    bufferId: bufferId,
    languageId: languageId,
    word: word,
    target: target,
    sourceStart: sourceStart == null ? null : sourceStart! + delta,
    sourceEnd: sourceEnd == null ? null : sourceEnd! + delta,
    fieldStart: fieldStart,
    fieldEnd: fieldEnd,
  );
}

bool _sameTarget(SpellingEditorTarget left, SpellingEditorTarget right) {
  return switch ((left, right)) {
    (
      SpellingSourceTarget(:final filePath),
      SpellingSourceTarget(filePath: final other),
    ) =>
      filePath == other,
    (
      SpellingRichBlockTarget(:final blockId, :final documentGeneration),
      SpellingRichBlockTarget(
        blockId: final otherBlock,
        documentGeneration: final otherGeneration,
      ),
    ) =>
      blockId == otherBlock && documentGeneration == otherGeneration,
    (
      SpellingRichTableCellTarget(
        :final tableBlockId,
        :final cellId,
        :final documentGeneration,
      ),
      SpellingRichTableCellTarget(
        tableBlockId: final otherTable,
        cellId: final otherCell,
        documentGeneration: final otherGeneration,
      ),
    ) =>
      tableBlockId == otherTable &&
          cellId == otherCell &&
          documentGeneration == otherGeneration,
    _ => false,
  };
}
