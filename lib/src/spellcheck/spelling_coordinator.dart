import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:unorm_dart/unorm_dart.dart' as unicode;

import 'spelling_projection.dart';
import 'spelling_worker.dart';

enum SpellingPresentationStatus {
  languageRequired,
  checking,
  ready,
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
  SpellingCoordinator._(this._worker);

  static Future<SpellingCoordinator> start() async =>
      SpellingCoordinator._(await SpellingWorker.start());

  final SpellingWorker _worker;
  Timer? _debounce;
  SpellingCheckRequest? _pending;
  int _presentationGeneration = 0;
  bool _running = false;
  bool _closed = false;
  final List<_IgnoredOccurrence> _ignoredOccurrences = [];
  final Map<String, Set<String>> _ignoredDocumentWords = {};

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
      final sourceStart = occurrence.sourceStart;
      final sourceEnd = occurrence.sourceEnd;
      final fieldStart = occurrence.fieldStart;
      final fieldEnd = occurrence.fieldEnd;
      if (occurrence.run.target is SpellingSourceTarget &&
          sourceStart != null &&
          sourceEnd != null) {
        result.add(
          SpellingAnnotation(
            occurrenceId: occurrence.id,
            start: sourceStart,
            end: sourceEnd,
            target: occurrence.run.target,
          ),
        );
      } else if (fieldStart != null && fieldEnd != null) {
        result.add(
          SpellingAnnotation(
            occurrenceId: occurrence.id,
            start: fieldStart,
            end: fieldEnd,
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
    _pending = request;
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
    _pending = request;
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
    await _drain();
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
      final start = occurrence.sourceStart;
      final end = occurrence.sourceEnd;
      if (start != null && end != null && offset >= start && offset <= end) {
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
      final start = occurrence.fieldStart;
      final end = occurrence.fieldEnd;
      if (start != null && end != null && offset >= start && offset <= end) {
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
    return _worker.suggestions(context: context, word: occurrence.word);
  }

  Future<String> validateDictionary({
    required String affPath,
    required String dicPath,
  }) => _worker.validateDictionary(affPath: affPath, dicPath: dicPath);

  Future<SpellingProjectionResult> project(SpellingProjectionJob job) =>
      _worker.project(job);

  bool isCurrent(SpellingOccurrence occurrence) =>
      misspellings.any((candidate) => candidate.id == occurrence.id) &&
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
        final request = _pending!;
        _pending = null;
        final generation = _presentationGeneration;
        try {
          final projection = await request.project();
          if (_closed || generation != _presentationGeneration) continue;
          final result = await _worker.check(
            context: request.engineContext,
            runs: projection.runs,
          );
          if (_closed ||
              generation != _presentationGeneration ||
              result.cancelled) {
            continue;
          }
          final rejected = result.occurrences
              .where((item) => item.outcome == SpellingCheckOutcome.rejected)
              .toList(growable: false);
          final complete = projection.complete && result.complete;
          _setState(
            SpellingPresentationState(
              status: complete
                  ? SpellingPresentationStatus.ready
                  : SpellingPresentationStatus.incomplete,
              occurrences: rejected,
              complete: complete,
              message: result.error ?? projection.message,
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

  void _cancelPresentation() {
    _presentationGeneration++;
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
    _debounce?.cancel();
    _worker.cancelChecks();
    unawaited(_worker.close());
    super.dispose();
  }
}

String _temporaryWordKey(String word) => unicode.nfc(word).toLowerCase();

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
