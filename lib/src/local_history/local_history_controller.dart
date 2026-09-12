import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../app/app_settings.dart';
import '../workspace/document_buffer.dart';
import '../workspace/text_format_metadata.dart';
import 'local_history_models.dart';
import 'local_history_store.dart';

typedef LocalHistoryClock = DateTime Function();
typedef LocalHistoryTimerFactory =
    Timer Function(Duration delay, void Function() callback);

final localHistoryClockProvider = Provider<LocalHistoryClock>(
  (ref) => DateTime.now,
);

final localHistoryTimerFactoryProvider = Provider<LocalHistoryTimerFactory>(
  (ref) => Platform.environment.containsKey('FLUTTER_TEST')
      ? (delay, callback) => _InactiveLocalHistoryTimer()
      : (delay, callback) => Timer(delay, callback),
);

class _InactiveLocalHistoryTimer implements Timer {
  @override
  void cancel() {}

  @override
  bool get isActive => false;

  @override
  int get tick => 0;
}

final localHistoryStoreProvider = Provider<LocalHistoryStore>(
  (ref) => Platform.environment.containsKey('FLUTTER_TEST')
      ? MemoryLocalHistoryStore()
      : FileLocalHistoryStore(),
);

final localHistoryControllerProvider =
    NotifierProvider<LocalHistoryController, LocalHistoryState>(
      LocalHistoryController.new,
    );

final localHistoryOpenRequestProvider =
    NotifierProvider<LocalHistoryOpenRequestController, int>(
      LocalHistoryOpenRequestController.new,
    );

final localHistoryFindRequestProvider =
    NotifierProvider<LocalHistoryOpenRequestController, int>(
      LocalHistoryOpenRequestController.new,
    );

class LocalHistoryOpenRequestController extends Notifier<int> {
  @override
  int build() => 0;

  void request() => state++;
}

class LocalHistoryState {
  const LocalHistoryState({
    this.snapshot = const LocalHistorySnapshot(),
    this.loading = false,
    this.selectedDocumentId,
    this.selectedRevisionId,
    this.selectedRevision,
    this.searchQuery = '',
    this.searching = false,
    this.searchMatches = const {},
    this.documentSearchMatches = const {},
    this.findingDocuments = false,
    this.inspectingRetainedDocument = false,
    this.warning,
  });

  final LocalHistorySnapshot snapshot;
  final bool loading;
  final String? selectedDocumentId;
  final String? selectedRevisionId;
  final LocalHistoryRevision? selectedRevision;
  final String searchQuery;
  final bool searching;
  final Set<String> searchMatches;
  final Set<String> documentSearchMatches;
  final bool findingDocuments;
  final bool inspectingRetainedDocument;
  final LocalHistoryWarning? warning;

  LocalHistoryDocument? get selectedDocument => snapshot.documents
      .where((document) => document.id == selectedDocumentId)
      .firstOrNull;

  List<LocalHistoryRevisionSummary> get selectedRevisions =>
      selectedDocumentId == null
      ? const []
      : snapshot.revisionsFor(selectedDocumentId!);

  bool revisionVisible(LocalHistoryRevisionSummary revision) =>
      searchQuery.isEmpty || searchMatches.contains(revision.id);

  LocalHistoryState copyWith({
    LocalHistorySnapshot? snapshot,
    bool? loading,
    Object? selectedDocumentId = _unset,
    Object? selectedRevisionId = _unset,
    Object? selectedRevision = _unset,
    String? searchQuery,
    bool? searching,
    Set<String>? searchMatches,
    Set<String>? documentSearchMatches,
    bool? findingDocuments,
    bool? inspectingRetainedDocument,
    Object? warning = _unset,
  }) => LocalHistoryState(
    snapshot: snapshot ?? this.snapshot,
    loading: loading ?? this.loading,
    selectedDocumentId: identical(selectedDocumentId, _unset)
        ? this.selectedDocumentId
        : selectedDocumentId as String?,
    selectedRevisionId: identical(selectedRevisionId, _unset)
        ? this.selectedRevisionId
        : selectedRevisionId as String?,
    selectedRevision: identical(selectedRevision, _unset)
        ? this.selectedRevision
        : selectedRevision as LocalHistoryRevision?,
    searchQuery: searchQuery ?? this.searchQuery,
    searching: searching ?? this.searching,
    searchMatches: searchMatches ?? this.searchMatches,
    documentSearchMatches: documentSearchMatches ?? this.documentSearchMatches,
    findingDocuments: findingDocuments ?? this.findingDocuments,
    inspectingRetainedDocument:
        inspectingRetainedDocument ?? this.inspectingRetainedDocument,
    warning: identical(warning, _unset)
        ? this.warning
        : warning as LocalHistoryWarning?,
  );
}

enum LocalHistoryWarningKind {
  indexRebuilt,
  unsupportedFormat,
  unavailable,
  recordingDisabled,
  pathChange,
  deletedPath,
  revisionMissing,
  revisionRead,
  capture,
}

class LocalHistoryWarning {
  const LocalHistoryWarning(this.kind, {this.detail});

  final LocalHistoryWarningKind kind;
  final String? detail;
}

const Object _unset = Object();

class LocalHistoryBufferSnapshot {
  const LocalHistoryBufferSnapshot({
    required this.bufferId,
    required this.displayName,
    required this.text,
    required this.format,
    required this.revision,
    this.path,
    this.untitled = false,
  });

  factory LocalHistoryBufferSnapshot.fromBuffer(DocumentBuffer buffer) =>
      LocalHistoryBufferSnapshot(
        bufferId: buffer.id,
        displayName: buffer.displayName,
        text: buffer.text,
        format: buffer.format,
        revision: buffer.revision,
        path: buffer.filePath,
        untitled: buffer.isUntitled,
      );

  final String bufferId;
  final String displayName;
  final String text;
  final TextFormatMetadata format;
  final int revision;
  final String? path;
  final bool untitled;

  LocalHistoryBufferSnapshot atPath(String destinationPath) =>
      LocalHistoryBufferSnapshot(
        bufferId: bufferId,
        displayName: p.basename(destinationPath),
        text: text,
        format: format,
        revision: revision,
        path: destinationPath,
      );

  LocalHistoryBufferSnapshot forBuffer(String id) => LocalHistoryBufferSnapshot(
    bufferId: id,
    displayName: displayName,
    text: text,
    format: format,
    revision: revision,
    path: path,
    untitled: untitled,
  );
}

enum LocalHistoryBufferPathTransitionKind { move, saveAs }

class LocalHistoryBufferPathTransition {
  const LocalHistoryBufferPathTransition._({
    required this.bufferId,
    required this.sourcePath,
    required this.destinationPath,
    required this.kind,
  });

  final String bufferId;
  final String? sourcePath;
  final String destinationPath;
  final LocalHistoryBufferPathTransitionKind kind;
}

class LocalHistoryPendingIdentityPromotion {
  const LocalHistoryPendingIdentityPromotion({
    required this.bufferId,
    required this.documentId,
    required this.destinationPath,
    required this.displayName,
  });

  final String bufferId;
  final String documentId;
  final String destinationPath;
  final String displayName;

  LocalHistoryPendingIdentityPromotion atPath(String path) =>
      LocalHistoryPendingIdentityPromotion(
        bufferId: bufferId,
        documentId: documentId,
        destinationPath: p.normalize(path),
        displayName: p.basename(path),
      );

  LocalHistoryPendingIdentityPromotion forBuffer(String id) =>
      LocalHistoryPendingIdentityPromotion(
        bufferId: id,
        documentId: documentId,
        destinationPath: destinationPath,
        displayName: displayName,
      );
}

class LocalHistoryController extends Notifier<LocalHistoryState> {
  late LocalHistoryStore _store;
  late LocalHistoryClock _clock;
  late LocalHistoryTimerFactory _timerFactory;
  final _documentIdsByBuffer = <String, String>{};
  final _pending = <String, LocalHistoryBufferSnapshot>{};
  final _checkpointTimers = <String, Timer>{};
  final _bufferQueues = <String, Future<void>>{};
  final _pathTransitions = <String, LocalHistoryBufferPathTransition>{};
  final _pendingUntitledPromotions =
      <String, LocalHistoryPendingIdentityPromotion>{};
  final _bufferGenerations = <String, int>{};
  final _captureFailures = <String, _LocalHistoryCaptureFailure>{};
  LocalHistoryBufferSnapshot? _normalBrowsingScope;
  var _historyGeneration = 0;
  var _snapshotGeneration = 0;
  var _loadGeneration = 0;
  var _searchGeneration = 0;
  var _scopeGeneration = 0;

  @override
  LocalHistoryState build() {
    _store = ref.read(localHistoryStoreProvider);
    _clock = ref.read(localHistoryClockProvider);
    _timerFactory = ref.read(localHistoryTimerFactoryProvider);
    ref.listen<AppSettings>(
      appSettingsControllerProvider,
      (previous, next) => _applyRecordingPolicy(next),
    );
    ref.onDispose(_cancelCheckpoints);
    Future<void>.microtask(refresh);
    return const LocalHistoryState(loading: true);
  }

  LocalHistoryPolicy get policy {
    final settings = ref.read(appSettingsControllerProvider);
    return LocalHistoryPolicy(
      recordingEnabled: settings.localHistoryRecordingEnabled,
      checkpointInterval: Duration(
        seconds: settings.localHistoryCheckpointSeconds,
      ),
      retentionAge: Duration(days: settings.localHistoryRetentionDays),
      maximumBytes: settings.localHistoryMaximumStorageMiB * 1024 * 1024,
      excludedPaths: settings.localHistoryExcludedPaths,
    );
  }

  LocalHistoryBufferSnapshot? pendingSnapshotForBuffer(String bufferId) =>
      _pending[bufferId];

  Future<void> refresh() async {
    final generation = ++_loadGeneration;
    if (ref.mounted) state = state.copyWith(loading: true);
    try {
      await _store.prune(policy, _clock());
      final snapshot = await _store.load();
      if (!ref.mounted || generation != _loadGeneration) return;
      await _publishSnapshot(
        snapshot,
        warning: snapshot.warning == null
            ? null
            : const LocalHistoryWarning(LocalHistoryWarningKind.indexRebuilt),
      );
    } on UnsupportedLocalHistoryFormat catch (error) {
      if (!ref.mounted || generation != _loadGeneration) return;
      state = state.copyWith(
        loading: false,
        warning: LocalHistoryWarning(
          LocalHistoryWarningKind.unsupportedFormat,
          detail: error.version?.toString(),
        ),
      );
    } on Object catch (error) {
      if (!ref.mounted || generation != _loadGeneration) return;
      state = state.copyWith(
        loading: false,
        warning: LocalHistoryWarning(
          LocalHistoryWarningKind.unavailable,
          detail: error.toString(),
        ),
      );
    }
  }

  Future<void> observeOpened(DocumentBuffer buffer) async {
    final snapshot = LocalHistoryBufferSnapshot.fromBuffer(buffer);
    if (snapshot.untitled && snapshot.text.isEmpty) return;
    final adoptedPromotion = _adoptPendingPromotionForOpenedBuffer(snapshot);
    final historyGeneration = _historyGeneration;
    final bufferGeneration = _bufferGeneration(snapshot.bufferId);
    await _enqueue(snapshot.bufferId, () async {
      if (!_operationIsCurrent(
        snapshot.bufferId,
        historyGeneration,
        bufferGeneration,
      )) {
        return;
      }
      final promotion = _pendingUntitledPromotions[snapshot.bufferId];
      if (promotion != null) {
        if (!_sameOptionalPath(snapshot.path, promotion.destinationPath)) {
          _setWarning(LocalHistoryWarningKind.pathChange);
          return;
        }
        if (!await _completePendingUntitledPromotion(
          snapshot.bufferId,
          acceptedHistoryGeneration: historyGeneration,
          acceptedBufferGeneration: bufferGeneration,
        )) {
          return;
        }
        if (!_operationIsCurrent(
          snapshot.bufferId,
          historyGeneration,
          bufferGeneration,
        )) {
          return;
        }
        final pending = _pending[snapshot.bufferId];
        _checkpointTimers.remove(snapshot.bufferId)?.cancel();
        if (pending != null) {
          await _capturePending(
            snapshot.bufferId,
            pending,
            acceptedHistoryGeneration: historyGeneration,
            acceptedBufferGeneration: bufferGeneration,
          );
        }
        if (!_operationIsCurrent(
          snapshot.bufferId,
          historyGeneration,
          bufferGeneration,
        )) {
          return;
        }
        await _capture(
          snapshot,
          LocalHistoryCaptureReason.baseline,
          acceptedHistoryGeneration: historyGeneration,
          acceptedBufferGeneration: bufferGeneration,
        );
        return;
      }
      if (adoptedPromotion != null) return;
      if (_documentIdsByBuffer.containsKey(snapshot.bufferId)) return;
      await _capture(
        snapshot,
        LocalHistoryCaptureReason.baseline,
        acceptedHistoryGeneration: historyGeneration,
        acceptedBufferGeneration: bufferGeneration,
      );
    });
  }

  void observeEdit(DocumentBuffer previous, DocumentBuffer current) {
    if (!policy.recordingEnabled || policy.excludes(current.filePath)) return;
    final previousSnapshot = LocalHistoryBufferSnapshot.fromBuffer(previous);
    final currentSnapshot = LocalHistoryBufferSnapshot.fromBuffer(current);
    final historyGeneration = _historyGeneration;
    final bufferGeneration = _bufferGeneration(current.id);
    unawaited(
      _enqueue(current.id, () async {
        if (!_operationIsCurrent(
          current.id,
          historyGeneration,
          bufferGeneration,
        )) {
          return;
        }
        if (!_documentIdsByBuffer.containsKey(current.id) &&
            !(previousSnapshot.untitled && previousSnapshot.text.isEmpty)) {
          await _capture(
            previousSnapshot,
            LocalHistoryCaptureReason.baseline,
            acceptedHistoryGeneration: historyGeneration,
            acceptedBufferGeneration: bufferGeneration,
          );
        }
        if (!_operationIsCurrent(
          current.id,
          historyGeneration,
          bufferGeneration,
        )) {
          return;
        }
        if (!_pendingIsEligible(currentSnapshot)) return;
        _pending[current.id] = currentSnapshot;
        _scheduleCheckpoint(current.id);
      }),
    );
  }

  /// Suspends automatic captures while a workspace buffer and its stable
  /// history identity move between paths. Callers must finish the returned
  /// transition after publishing (or abandoning) the buffer path change.
  LocalHistoryBufferPathTransition beginBufferPathTransition({
    required String bufferId,
    required String? sourcePath,
    required String destinationPath,
    LocalHistoryBufferPathTransitionKind kind =
        LocalHistoryBufferPathTransitionKind.move,
  }) {
    final transition = LocalHistoryBufferPathTransition._(
      bufferId: bufferId,
      sourcePath: sourcePath,
      destinationPath: p.normalize(destinationPath),
      kind: kind,
    );
    _pathTransitions[bufferId] = transition;
    _checkpointTimers.remove(bufferId)?.cancel();
    return transition;
  }

  Future<void> finishBufferPathTransition(
    LocalHistoryBufferPathTransition transition, {
    required bool committed,
  }) async {
    while (identical(_pathTransitions[transition.bufferId], transition)) {
      final queued = _bufferQueues[transition.bufferId];
      if (queued == null) break;
      await queued;
    }
    if (!identical(_pathTransitions[transition.bufferId], transition)) return;
    _pathTransitions.remove(transition.bufferId);
    final pending = _pending[transition.bufferId];
    if (committed &&
        pending != null &&
        _sameOptionalPath(pending.path, transition.sourcePath)) {
      _pending[transition.bufferId] = pending.atPath(
        transition.destinationPath,
      );
    }
    final promotion = _pendingUntitledPromotions[transition.bufferId];
    if (committed &&
        transition.kind == LocalHistoryBufferPathTransitionKind.move &&
        promotion != null &&
        _sameOptionalPath(promotion.destinationPath, transition.sourcePath)) {
      _pendingUntitledPromotions[transition.bufferId] = promotion.atPath(
        transition.destinationPath,
      );
    }
    _scheduleCheckpoint(transition.bufferId);
  }

  Future<bool> captureSaved(LocalHistoryBufferSnapshot snapshot) async {
    final historyGeneration = _historyGeneration;
    final bufferGeneration = _bufferGeneration(snapshot.bufferId);
    return _enqueue(snapshot.bufferId, () async {
      if (!_operationIsCurrent(
        snapshot.bufferId,
        historyGeneration,
        bufferGeneration,
      )) {
        return true;
      }
      final captured = await _capture(
        snapshot,
        LocalHistoryCaptureReason.saved,
        acceptedHistoryGeneration: historyGeneration,
        acceptedBufferGeneration: bufferGeneration,
      );
      if (!_operationIsCurrent(
        snapshot.bufferId,
        historyGeneration,
        bufferGeneration,
      )) {
        return true;
      }
      if (captured) {
        _acknowledgePending(snapshot.bufferId, snapshot.revision);
      } else {
        _retainPending(snapshot);
      }
      return captured;
    });
  }

  Future<bool> captureProtective(
    LocalHistoryBufferSnapshot snapshot,
    LocalHistoryCaptureReason reason,
  ) async {
    if (!policy.recordingEnabled || policy.excludes(snapshot.path)) {
      _setWarning(LocalHistoryWarningKind.recordingDisabled);
      return false;
    }
    final historyGeneration = _historyGeneration;
    final bufferGeneration = _bufferGeneration(snapshot.bufferId);
    return _enqueue(
      snapshot.bufferId,
      () => _capture(
        snapshot,
        reason,
        force: true,
        acceptedHistoryGeneration: historyGeneration,
        acceptedBufferGeneration: bufferGeneration,
      ),
    );
  }

  /// Lifecycle replacements remain usable when recording was deliberately
  /// disabled or excluded. When recording applies, a failed protective write
  /// blocks the destructive replacement.
  Future<bool> captureBeforeLoss(
    LocalHistoryBufferSnapshot snapshot,
    LocalHistoryCaptureReason reason,
  ) async {
    if (!policy.recordingEnabled || policy.excludes(snapshot.path)) return true;
    final historyGeneration = _historyGeneration;
    final bufferGeneration = _bufferGeneration(snapshot.bufferId);
    return _enqueue(
      snapshot.bufferId,
      () => _capture(
        snapshot,
        reason,
        force: true,
        acceptedHistoryGeneration: historyGeneration,
        acceptedBufferGeneration: bufferGeneration,
      ),
    );
  }

  Future<bool> captureSavedAs(
    LocalHistoryBufferSnapshot source,
    String destinationPath, {
    required bool destinationExisted,
  }) async {
    final historyGeneration = _historyGeneration;
    final bufferGeneration = _bufferGeneration(source.bufferId);
    final destination = LocalHistoryBufferSnapshot(
      bufferId: source.bufferId,
      displayName: p.basename(destinationPath),
      text: source.text,
      format: source.format,
      revision: source.revision,
      path: destinationPath,
    );
    var promotionCompleted = false;
    var retainedSourcePromotion = false;
    final captured = await _enqueue(source.bufferId, () async {
      if (!_operationIsCurrent(
        source.bufferId,
        historyGeneration,
        bufferGeneration,
      )) {
        return true;
      }
      // A named-file Save As is a fork. Resolve an earlier untitled-to-source
      // promotion before recording the destination. If storage is still
      // unavailable, detach that source association from the buffer so it can
      // be retried independently without being retargeted to the copy.
      if (!source.untitled &&
          _pendingUntitledPromotions.containsKey(source.bufferId)) {
        final promotion = _pendingUntitledPromotions[source.bufferId]!;
        if (_sameOptionalPath(source.path, promotion.destinationPath)) {
          promotionCompleted = await _completePendingUntitledPromotion(
            source.bufferId,
            acceptedHistoryGeneration: historyGeneration,
            acceptedBufferGeneration: bufferGeneration,
          );
          if (!_operationIsCurrent(
            source.bufferId,
            historyGeneration,
            bufferGeneration,
          )) {
            return true;
          }
        }
        if (_pendingUntitledPromotions.containsKey(source.bufferId)) {
          _detachPendingUntitledPromotion(source.bufferId);
          retainedSourcePromotion = true;
        }
      }

      // A checkpoint included in the Save As target belongs to the source
      // lineage. Newer edits remain suspended until the caller publishes the
      // destination path and finishes the path transition.
      final pending = _pending[source.bufferId];
      if (pending != null &&
          pending.revision <= source.revision &&
          _sameOptionalPath(pending.path, source.path)) {
        _checkpointTimers.remove(source.bufferId)?.cancel();
        final pendingCaptured = await _capture(
          pending,
          LocalHistoryCaptureReason.automaticCheckpoint,
          allowDuringPathTransition: true,
          acceptedHistoryGeneration: historyGeneration,
          acceptedBufferGeneration: bufferGeneration,
        );
        if (!_operationIsCurrent(
          source.bufferId,
          historyGeneration,
          bufferGeneration,
        )) {
          return true;
        }
        if (pendingCaptured) {
          _acknowledgePending(source.bufferId, pending.revision);
        } else {
          _retainPending(pending);
        }
        if (!pendingCaptured &&
            policy.recordingEnabled &&
            !policy.excludes(pending.path) &&
            !source.untitled) {
          return false;
        }
      }

      final sourceDocumentId = _documentIdsByBuffer[source.bufferId];
      if (source.untitled && !destinationExisted && sourceDocumentId != null) {
        _pendingUntitledPromotions[source.bufferId] =
            LocalHistoryPendingIdentityPromotion(
              bufferId: source.bufferId,
              documentId: sourceDocumentId,
              destinationPath: p.normalize(destinationPath),
              displayName: p.basename(destinationPath),
            );
        promotionCompleted = await _completePendingUntitledPromotion(
          source.bufferId,
          acceptedHistoryGeneration: historyGeneration,
          acceptedBufferGeneration: bufferGeneration,
        );
        if (!_operationIsCurrent(
          source.bufferId,
          historyGeneration,
          bufferGeneration,
        )) {
          return true;
        }
        if (!promotionCompleted) return false;
      }

      if (!policy.recordingEnabled || policy.excludes(destination.path)) {
        return source.untitled && !destinationExisted && promotionCompleted;
      }
      final savedCaptured = await _capture(
        destination,
        LocalHistoryCaptureReason.saved,
        ignoreBinding: !source.untitled || destinationExisted,
        acceptedHistoryGeneration: historyGeneration,
        acceptedBufferGeneration: bufferGeneration,
      );
      if (!_operationIsCurrent(
        source.bufferId,
        historyGeneration,
        bufferGeneration,
      )) {
        return true;
      }
      if (savedCaptured) {
        _acknowledgePending(destination.bufferId, destination.revision);
      } else {
        _retainPending(destination);
      }
      return savedCaptured;
    });
    if (!_operationIsCurrent(
      source.bufferId,
      historyGeneration,
      bufferGeneration,
    )) {
      return true;
    }
    if (captured) {
      final document = state.snapshot.documents
          .where(
            (candidate) =>
                candidate.currentPath != null &&
                p.equals(candidate.currentPath!, destinationPath),
          )
          .firstOrNull;
      if (document != null) _documentIdsByBuffer[source.bufferId] = document.id;
    } else if (!source.untitled || destinationExisted) {
      // The filesystem transition already succeeded. Do not let a later
      // checkpoint reuse the source document identity if history was disabled,
      // excluded, or temporarily unavailable during this Save As.
      _documentIdsByBuffer.remove(source.bufferId);
    }
    if (retainedSourcePromotion) {
      _setWarning(LocalHistoryWarningKind.pathChange);
    }
    return captured;
  }

  Future<bool> capturePath({
    required String path,
    required String text,
    required TextFormatMetadata format,
    required LocalHistoryCaptureReason reason,
    bool force = true,
  }) {
    final snapshot = LocalHistoryBufferSnapshot(
      bufferId: 'path:${p.normalize(path)}',
      displayName: p.basename(path),
      text: text,
      format: format,
      revision: 0,
      path: path,
    );
    final historyGeneration = _historyGeneration;
    final bufferGeneration = _bufferGeneration(snapshot.bufferId);
    return _enqueue(
      snapshot.bufferId,
      () => _capture(
        snapshot,
        reason,
        force: force,
        ignoreBinding: true,
        acceptedHistoryGeneration: historyGeneration,
        acceptedBufferGeneration: bufferGeneration,
      ),
    );
  }

  Future<bool> capturePathBeforeLoss({
    required String path,
    required String text,
    required TextFormatMetadata format,
    required LocalHistoryCaptureReason reason,
  }) {
    if (!policy.recordingEnabled || policy.excludes(path)) {
      return Future.value(true);
    }
    return capturePath(
      path: path,
      text: text,
      format: format,
      reason: reason,
      force: true,
    );
  }

  List<LocalHistoryPendingIdentityPromotion> get pendingIdentityPromotions =>
      List.unmodifiable(_pendingUntitledPromotions.values);

  bool hasPendingIdentityPromotion(String bufferId) =>
      _pendingUntitledPromotions.containsKey(bufferId);

  void restorePendingIdentityPromotion(
    LocalHistoryPendingIdentityPromotion promotion,
  ) {
    _documentIdsByBuffer[promotion.bufferId] = promotion.documentId;
    _pendingUntitledPromotions[promotion.bufferId] = promotion;
  }

  Future<bool> flushBuffer(DocumentBuffer buffer) async {
    _checkpointTimers.remove(buffer.id)?.cancel();
    return _enqueue(buffer.id, () async {
      _checkpointTimers.remove(buffer.id)?.cancel();
      var pending = _pending[buffer.id];
      if (pending != null) {
        final current = LocalHistoryBufferSnapshot.fromBuffer(buffer);
        if (current.revision >= pending.revision) pending = current;
        if (!await _capturePending(buffer.id, pending)) return false;
      }
      if (_pendingUntitledPromotions.containsKey(buffer.id) &&
          !await _completePendingUntitledPromotion(buffer.id)) {
        return false;
      }
      return !_pending.containsKey(buffer.id);
    });
  }

  Future<bool> flushPendingIdentityPromotions() async {
    var succeeded = true;
    for (final bufferId in _pendingUntitledPromotions.keys.toList()) {
      if (!await _enqueue(bufferId, () async {
        if (!await _completePendingUntitledPromotion(bufferId)) return false;
        final pending = _pending[bufferId];
        _checkpointTimers.remove(bufferId)?.cancel();
        if (pending == null) return true;
        return _capturePending(bufferId, pending);
      })) {
        succeeded = false;
      }
    }
    return succeeded && _pendingUntitledPromotions.isEmpty;
  }

  Future<bool> flushAll(Iterable<DocumentBuffer> buffers) async {
    final bufferList = buffers.toList(growable: false);
    for (final buffer in bufferList) {
      await flushBuffer(buffer);
    }
    await flushPendingIdentityPromotions();
    while (_bufferQueues.isNotEmpty) {
      await Future.wait(_bufferQueues.values.toList(growable: false));
    }
    for (final bufferId in _pending.keys.toList(growable: false)) {
      _checkpointTimers.remove(bufferId)?.cancel();
      await _enqueue<bool>(bufferId, () async {
        final pending = _pending[bufferId];
        return pending == null
            ? true
            : await _capturePending(bufferId, pending);
      });
    }
    while (_bufferQueues.isNotEmpty) {
      await Future.wait(_bufferQueues.values.toList(growable: false));
    }
    return _pendingUntitledPromotions.isEmpty && _pending.isEmpty;
  }

  /// Keeps unresolved history work owned by this session after its editor tab
  /// closes. Retryable work continues on the checkpoint cadence; all pending
  /// work remains part of [flushAll] shutdown settlement.
  void handleBufferClosed(String bufferId, {required bool historySettled}) {
    if (historySettled) return;
    final pending = _pending[bufferId];
    if (pending != null && _captureFailures[bufferId]?.retryable != false) {
      _scheduleCheckpoint(bufferId);
    }
  }

  Future<void> remapPath(String sourcePath, String destinationPath) async {
    try {
      // Observe-edit callbacks are queued per buffer. Drain them, then capture
      // pending source-path snapshots before the store remaps their stable
      // document identities. New edits already see the remapped workspace
      // buffer path and remain pending for the destination.
      while (_bufferQueues.isNotEmpty) {
        await Future.wait(_bufferQueues.values.toList(growable: false));
      }
      final affected = <MapEntry<String, LocalHistoryBufferSnapshot>>[];
      for (final entry in _pending.entries) {
        if (_pathTransitions.containsKey(entry.key)) continue;
        final path = entry.value.path;
        if (path != null &&
            (p.equals(path, sourcePath) || p.isWithin(sourcePath, path))) {
          affected.add(entry);
        }
      }
      for (final entry in affected) {
        _checkpointTimers.remove(entry.key)?.cancel();
        final captured = await _enqueue(
          entry.key,
          () => _capture(
            entry.value,
            LocalHistoryCaptureReason.automaticCheckpoint,
          ),
        );
        if (captured) {
          _acknowledgePending(entry.key, entry.value.revision);
        }
      }
      final affectedPromotions = _pendingUntitledPromotions.entries
          .where(
            (entry) =>
                p.equals(entry.value.destinationPath, sourcePath) ||
                p.isWithin(sourcePath, entry.value.destinationPath),
          )
          .toList(growable: false);
      for (final entry in affectedPromotions) {
        final completed = await _enqueue(
          entry.key,
          () => _completePendingUntitledPromotion(entry.key),
        );
        if (!completed) {
          final pendingPromotion = _pendingUntitledPromotions[entry.key];
          if (pendingPromotion != null) {
            final remapped = _remapHistoryPath(
              pendingPromotion.destinationPath,
              sourcePath,
              destinationPath,
            );
            if (remapped != null) {
              _pendingUntitledPromotions[entry.key] = pendingPromotion.atPath(
                remapped,
              );
            }
          }
        }
      }
      await _store.remapPath(sourcePath, destinationPath);
      for (final entry in affected) {
        final pending = _pending[entry.key];
        final pendingPath = pending?.path;
        if (pending == null || pendingPath == null) continue;
        final remapped = _remapHistoryPath(
          pendingPath,
          sourcePath,
          destinationPath,
        );
        if (remapped != null) {
          _pending[entry.key] = pending.atPath(remapped);
          _scheduleCheckpoint(entry.key);
        }
      }
      await refresh();
    } on Object catch (error) {
      _setWarning(LocalHistoryWarningKind.pathChange, error.toString());
    }
  }

  Future<void> markDeleted(String path, {required bool recursive}) async {
    try {
      await _store.markDeleted(path, recursive: recursive);
      await refresh();
    } on Object catch (error) {
      _setWarning(LocalHistoryWarningKind.deletedPath, error.toString());
    }
  }

  Future<void> selectDocumentForBuffer(DocumentBuffer buffer) async {
    final generation = ++_scopeGeneration;
    _normalBrowsingScope = LocalHistoryBufferSnapshot.fromBuffer(buffer);
    _loadGeneration++;
    _searchGeneration++;
    state = state.copyWith(
      loading: true,
      selectedDocumentId: null,
      selectedRevisionId: null,
      selectedRevision: null,
      searchQuery: '',
      searching: false,
      searchMatches: const {},
      documentSearchMatches: const {},
      findingDocuments: false,
      inspectingRetainedDocument: false,
    );
    await observeOpened(buffer);
    if (!ref.mounted || generation != _scopeGeneration) return;
    final documentId = _documentIdsByBuffer[buffer.id];
    if (documentId == null) {
      await refresh();
      if (!ref.mounted || generation != _scopeGeneration) return;
      final byPath = state.snapshot.documents
          .where(
            (document) =>
                buffer.filePath != null &&
                document.currentPath != null &&
                p.equals(document.currentPath!, buffer.filePath!),
          )
          .firstOrNull;
      if (byPath != null) {
        _selectDocument(byPath.id, inspectingRetainedDocument: false);
      } else {
        state = state.copyWith(
          loading: false,
          findingDocuments: false,
          inspectingRetainedDocument: false,
        );
      }
    } else {
      if (!state.snapshot.documents.any(
        (document) => document.id == documentId,
      )) {
        await refresh();
        if (!ref.mounted || generation != _scopeGeneration) return;
      }
      _selectDocument(documentId, inspectingRetainedDocument: false);
    }
  }

  void selectDocument(String documentId) {
    _selectDocument(documentId, inspectingRetainedDocument: false);
  }

  void clearDocumentScope() {
    _scopeGeneration++;
    _normalBrowsingScope = null;
    _loadGeneration++;
    _searchGeneration++;
    state = state.copyWith(
      loading: false,
      selectedDocumentId: null,
      selectedRevisionId: null,
      selectedRevision: null,
      searchQuery: '',
      searching: false,
      searchMatches: const {},
      documentSearchMatches: const {},
      findingDocuments: false,
      inspectingRetainedDocument: false,
    );
  }

  void inspectRetainedDocument(String documentId) {
    _scopeGeneration++;
    _selectDocument(documentId, inspectingRetainedDocument: true);
  }

  void _selectDocument(
    String documentId, {
    required bool inspectingRetainedDocument,
  }) {
    if (!state.snapshot.documents.any(
      (document) => document.id == documentId,
    )) {
      return;
    }
    _loadGeneration++;
    _searchGeneration++;
    state = state.copyWith(
      loading: false,
      selectedDocumentId: documentId,
      selectedRevisionId: null,
      selectedRevision: null,
      searchQuery: '',
      searching: false,
      searchMatches: const {},
      documentSearchMatches: const {},
      findingDocuments: false,
      inspectingRetainedDocument: inspectingRetainedDocument,
    );
  }

  /// Opens the store-wide discovery surface used by Find in Local History.
  /// No current editor is implied: closed, renamed, untitled, and deleted
  /// documents remain first-class results.
  void beginDocumentSearch() {
    _scopeGeneration++;
    _loadGeneration++;
    _searchGeneration++;
    state = state.copyWith(
      loading: false,
      selectedDocumentId: null,
      selectedRevisionId: null,
      selectedRevision: null,
      searchQuery: '',
      searching: false,
      searchMatches: const {},
      documentSearchMatches: const {},
      findingDocuments: true,
      inspectingRetainedDocument: false,
    );
  }

  Future<void> selectDocumentForPath(String path) async {
    await refresh();
    if (!ref.mounted) return;
    final normalized = p.normalize(path);
    final document = state.snapshot.documents.where((candidate) {
      final current = candidate.currentPath;
      return (current != null && p.equals(current, normalized)) ||
          candidate.historicalPaths.any(
            (historical) => p.equals(historical, normalized),
          );
    }).firstOrNull;
    if (document != null) selectDocument(document.id);
  }

  Future<void> selectRevision(String revisionId) async {
    final documentId = state.selectedDocumentId;
    final summary = state.snapshot.revisions
        .where((revision) => revision.id == revisionId)
        .firstOrNull;
    if (documentId == null || summary?.documentId != documentId) return;
    final generation = ++_loadGeneration;
    state = state.copyWith(
      selectedRevisionId: revisionId,
      selectedRevision: null,
      loading: true,
    );
    try {
      final revision = await _store.readRevision(revisionId);
      if (!ref.mounted ||
          generation != _loadGeneration ||
          state.selectedDocumentId != documentId ||
          state.selectedRevisionId != revisionId ||
          (revision != null && revision.summary.documentId != documentId)) {
        return;
      }
      state = state.copyWith(
        selectedRevision: revision,
        loading: false,
        warning: revision == null
            ? const LocalHistoryWarning(LocalHistoryWarningKind.revisionMissing)
            : null,
      );
    } on Object catch (error) {
      if (!ref.mounted ||
          generation != _loadGeneration ||
          state.selectedDocumentId != documentId ||
          state.selectedRevisionId != revisionId) {
        return;
      }
      state = state.copyWith(
        loading: false,
        warning: LocalHistoryWarning(
          LocalHistoryWarningKind.revisionRead,
          detail: error.toString(),
        ),
      );
    }
  }

  void clearComparison() {
    _loadGeneration++;
    state = state.copyWith(
      loading: false,
      selectedRevisionId: null,
      selectedRevision: null,
    );
  }

  String? bufferIdForDocument(String documentId) => _documentIdsByBuffer.entries
      .where((entry) => entry.value == documentId)
      .map((entry) => entry.key)
      .firstOrNull;

  String? documentIdForBuffer(String bufferId) =>
      _documentIdsByBuffer[bufferId];

  Future<void> search(String query) async {
    await _runSearch(query, clearMatches: true);
  }

  Future<void> clearDocument(String documentId) async {
    final document = state.snapshot.documents
        .where((candidate) => candidate.id == documentId)
        .firstOrNull;
    final documentPaths = <String>{
      if (document?.currentPath case final path?) p.normalize(path),
      for (final path in document?.historicalPaths ?? const <String>[])
        p.normalize(path),
    };
    final affectedBuffers = <String>{
      ..._documentIdsByBuffer.entries
          .where((entry) => entry.value == documentId)
          .map((entry) => entry.key),
      ..._pending.entries
          .where(
            (entry) =>
                entry.value.path != null &&
                documentPaths.any((path) => p.equals(path, entry.value.path!)),
          )
          .map((entry) => entry.key),
      for (final path in documentPaths)
        if (_bufferQueues.containsKey('path:$path')) 'path:$path',
      if (_normalBrowsingScope case final scope?
          when scope.path != null &&
              documentPaths.any((path) => p.equals(path, scope.path!)))
        scope.bufferId,
    }.toList(growable: false);
    for (final bufferId in affectedBuffers) {
      _invalidateBufferWork(bufferId);
    }
    _loadGeneration++;
    _searchGeneration++;
    _documentIdsByBuffer.removeWhere((_, value) => value == documentId);
    _pendingUntitledPromotions.removeWhere(
      (_, promotion) => promotion.documentId == documentId,
    );
    await _runWithBlockedBufferQueues(
      affectedBuffers,
      () => _store.clearDocument(documentId),
    );
    if (!ref.mounted) return;
    final snapshot = await _store.load();
    if (!ref.mounted) return;
    await _publishSnapshot(snapshot, explicitlyClearedDocumentId: documentId);
  }

  Future<void> clearAll() async {
    final affectedBuffers = <String>{
      ..._documentIdsByBuffer.keys,
      ..._pending.keys,
      ..._bufferQueues.keys,
    };
    _historyGeneration++;
    _loadGeneration++;
    _searchGeneration++;
    _cancelCheckpoints(clearTransitions: false);
    _captureFailures.clear();
    _documentIdsByBuffer.clear();
    _pendingUntitledPromotions.clear();
    await _runWithBlockedBufferQueues(affectedBuffers, _store.clearAll);
    if (!ref.mounted) return;
    final snapshot = await _store.load();
    if (!ref.mounted) return;
    await _publishSnapshot(snapshot, clearAllComparisons: true);
  }

  LocalHistoryPendingIdentityPromotion? _adoptPendingPromotionForOpenedBuffer(
    LocalHistoryBufferSnapshot snapshot,
  ) {
    final path = snapshot.path;
    if (path == null) return null;
    final match = _pendingUntitledPromotions.entries
        .where((entry) => p.equals(entry.value.destinationPath, path))
        .firstOrNull;
    if (match == null) return null;
    if (match.key == snapshot.bufferId) {
      _documentIdsByBuffer[snapshot.bufferId] = match.value.documentId;
      return match.value;
    }

    // Re-key synchronously, before the first await in observeOpened(). This
    // prevents a fast edit from scheduling a baseline under a competing file
    // identity while the promotion retry is still in progress.
    _pendingUntitledPromotions.remove(match.key);
    final adopted = match.value.forBuffer(snapshot.bufferId);
    _pendingUntitledPromotions[snapshot.bufferId] = adopted;
    final pending = _pending.remove(match.key);
    _checkpointTimers.remove(match.key)?.cancel();
    if (pending != null) {
      _pending[snapshot.bufferId] = pending.forBuffer(snapshot.bufferId);
    }
    _documentIdsByBuffer.remove(match.key);
    _documentIdsByBuffer[snapshot.bufferId] = adopted.documentId;
    return adopted;
  }

  void _detachPendingUntitledPromotion(String bufferId) {
    final promotion = _pendingUntitledPromotions.remove(bufferId);
    if (promotion == null) return;
    final detachedBufferId = 'history-promotion:${promotion.documentId}';
    _pendingUntitledPromotions[detachedBufferId] = promotion.forBuffer(
      detachedBufferId,
    );
    final pending = _pending.remove(bufferId);
    _checkpointTimers.remove(bufferId)?.cancel();
    if (pending != null) {
      _pending[detachedBufferId] = pending.forBuffer(detachedBufferId);
    }
    _documentIdsByBuffer.remove(bufferId);
    _documentIdsByBuffer[detachedBufferId] = promotion.documentId;
  }

  Future<bool> _capture(
    LocalHistoryBufferSnapshot snapshot,
    LocalHistoryCaptureReason reason, {
    bool force = false,
    bool ignoreBinding = false,
    bool allowPathChange = false,
    bool allowDuringPathTransition = false,
    int? acceptedHistoryGeneration,
    int? acceptedBufferGeneration,
  }) async {
    final captureHistoryGeneration =
        acceptedHistoryGeneration ?? _historyGeneration;
    final captureBufferGeneration =
        acceptedBufferGeneration ?? _bufferGeneration(snapshot.bufferId);
    if (!_operationIsCurrent(
      snapshot.bufferId,
      captureHistoryGeneration,
      captureBufferGeneration,
    )) {
      return true;
    }
    if (reason == LocalHistoryCaptureReason.automaticCheckpoint &&
        !allowDuringPathTransition &&
        _pathTransitions.containsKey(snapshot.bufferId)) {
      final pending = _pending[snapshot.bufferId];
      if (pending == null || pending.revision <= snapshot.revision) {
        _pending[snapshot.bufferId] = snapshot;
      }
      return true;
    }
    final promotion = _pendingUntitledPromotions[snapshot.bufferId];
    if (promotion != null) {
      if (!_sameOptionalPath(snapshot.path, promotion.destinationPath)) {
        _setWarning(LocalHistoryWarningKind.pathChange);
        return false;
      }
      if (!await _completePendingUntitledPromotion(
        snapshot.bufferId,
        acceptedHistoryGeneration: captureHistoryGeneration,
        acceptedBufferGeneration: captureBufferGeneration,
      )) {
        return false;
      }
      if (!_operationIsCurrent(
        snapshot.bufferId,
        captureHistoryGeneration,
        captureBufferGeneration,
      )) {
        return true;
      }
    }
    final currentPolicy = policy;
    if (!currentPolicy.recordingEnabled ||
        currentPolicy.excludes(snapshot.path)) {
      return false;
    }
    if (snapshot.untitled &&
        snapshot.text.isEmpty &&
        reason == LocalHistoryCaptureReason.baseline) {
      return true;
    }
    try {
      final result = await _store.capture(
        LocalHistoryCaptureRequest(
          documentId: ignoreBinding
              ? null
              : _documentIdsByBuffer[snapshot.bufferId],
          path: snapshot.path,
          displayName: snapshot.displayName,
          source: snapshot.text,
          format: snapshot.format,
          capturedAt: _clock().toUtc(),
          reason: reason,
          untitled: snapshot.untitled,
          force: force,
          allowPathChange: allowPathChange,
        ),
        currentPolicy,
      );
      if (!_operationIsCurrent(
        snapshot.bufferId,
        captureHistoryGeneration,
        captureBufferGeneration,
      )) {
        return true;
      }
      if (!ignoreBinding) {
        _documentIdsByBuffer[snapshot.bufferId] = result.document.id;
      }
      _captureFailures.remove(snapshot.bufferId);
      if (ref.mounted) {
        final loaded = await _store.load();
        if (_operationIsCurrent(
          snapshot.bufferId,
          captureHistoryGeneration,
          captureBufferGeneration,
        )) {
          await _publishSnapshot(
            loaded,
            capturedBufferId: ignoreBinding ? null : snapshot.bufferId,
            capturedSnapshot: ignoreBinding ? null : snapshot,
          );
        }
      }
      return true;
    } on Object catch (error) {
      if (_operationIsCurrent(
        snapshot.bufferId,
        captureHistoryGeneration,
        captureBufferGeneration,
      )) {
        _captureFailures[snapshot.bufferId] = _LocalHistoryCaptureFailure(
          detail: error.toString(),
          retryable: _captureErrorIsRetryable(error),
          stage: _LocalHistoryFailureStage.capture,
        );
        _showCaptureFailure();
      }
      return false;
    }
  }

  Future<bool> _completePendingUntitledPromotion(
    String bufferId, {
    int? acceptedHistoryGeneration,
    int? acceptedBufferGeneration,
  }) async {
    final promotion = _pendingUntitledPromotions[bufferId];
    if (promotion == null) return true;
    final promotionHistoryGeneration =
        acceptedHistoryGeneration ?? _historyGeneration;
    final promotionBufferGeneration =
        acceptedBufferGeneration ?? _bufferGeneration(bufferId);
    if (!_operationIsCurrent(
      bufferId,
      promotionHistoryGeneration,
      promotionBufferGeneration,
    )) {
      return true;
    }
    try {
      final document = await _store.promoteUntitledDocument(
        documentId: promotion.documentId,
        destinationPath: promotion.destinationPath,
        displayName: promotion.displayName,
        updatedAt: _clock().toUtc(),
      );
      if (!_operationIsCurrent(
            bufferId,
            promotionHistoryGeneration,
            promotionBufferGeneration,
          ) ||
          !identical(_pendingUntitledPromotions[bufferId], promotion)) {
        return true;
      }
      if (document == null) {
        _captureFailures[bufferId] = const _LocalHistoryCaptureFailure(
          retryable: false,
          stage: _LocalHistoryFailureStage.promotion,
        );
        _setWarning(LocalHistoryWarningKind.pathChange);
        return false;
      }
      _documentIdsByBuffer[bufferId] = document.id;
      _pendingUntitledPromotions.remove(bufferId);
      if (_captureFailures[bufferId]?.stage ==
          _LocalHistoryFailureStage.promotion) {
        _captureFailures.remove(bufferId);
      }
      if (ref.mounted) {
        final loaded = await _store.load();
        if (_operationIsCurrent(
          bufferId,
          promotionHistoryGeneration,
          promotionBufferGeneration,
        )) {
          await _publishSnapshot(loaded, capturedBufferId: bufferId);
        }
      }
      return true;
    } on Object catch (error) {
      if (!_operationIsCurrent(
        bufferId,
        promotionHistoryGeneration,
        promotionBufferGeneration,
      )) {
        return true;
      }
      _captureFailures[bufferId] = _LocalHistoryCaptureFailure(
        detail: error.toString(),
        retryable: _captureErrorIsRetryable(error),
        stage: _LocalHistoryFailureStage.promotion,
      );
      _setWarning(LocalHistoryWarningKind.pathChange, error.toString());
      return false;
    }
  }

  Future<T> _enqueue<T>(String bufferId, Future<T> Function() operation) {
    final prior = _bufferQueues[bufferId] ?? Future<void>.value();
    final result = prior.then((_) => operation());
    late final Future<void> tail;
    tail = result.then<void>((_) {}, onError: (_, _) {}).whenComplete(() {
      if (identical(_bufferQueues[bufferId], tail)) {
        _bufferQueues.remove(bufferId);
      }
    });
    _bufferQueues[bufferId] = tail;
    return result;
  }

  Future<void> _runWithBlockedBufferQueues(
    Iterable<String> bufferIds,
    Future<void> Function() operation,
  ) async {
    final entered = <Future<void>>[];
    final gates = <Completer<void>>[];
    final barriers = <Future<void>>[];
    for (final bufferId in bufferIds.toSet()) {
      final didEnter = Completer<void>();
      final gate = Completer<void>();
      entered.add(didEnter.future);
      gates.add(gate);
      barriers.add(
        _enqueue(bufferId, () async {
          didEnter.complete();
          await gate.future;
        }),
      );
    }
    try {
      await Future.wait(entered);
      await operation();
    } finally {
      for (final gate in gates) {
        if (!gate.isCompleted) gate.complete();
      }
      await Future.wait(barriers);
    }
  }

  void _cancelCheckpoints({bool clearTransitions = true}) {
    for (final timer in _checkpointTimers.values) {
      timer.cancel();
    }
    _checkpointTimers.clear();
    _pending.clear();
    if (clearTransitions) _pathTransitions.clear();
  }

  void _scheduleCheckpoint(String bufferId) {
    if (_pathTransitions.containsKey(bufferId) ||
        !_pending.containsKey(bufferId)) {
      return;
    }
    _checkpointTimers.putIfAbsent(
      bufferId,
      () => _timerFactory(policy.checkpointInterval, () {
        _checkpointTimers.remove(bufferId);
        if (!ref.mounted || _pathTransitions.containsKey(bufferId)) return;
        final latest = _pending[bufferId];
        if (latest != null) {
          final acceptedHistoryGeneration = _historyGeneration;
          final acceptedBufferGeneration = _bufferGeneration(bufferId);
          unawaited(
            _enqueue(
              bufferId,
              () => _capturePending(
                bufferId,
                latest,
                acceptedHistoryGeneration: acceptedHistoryGeneration,
                acceptedBufferGeneration: acceptedBufferGeneration,
              ),
            ),
          );
        }
      }),
    );
  }

  Future<bool> _capturePending(
    String bufferId,
    LocalHistoryBufferSnapshot snapshot, {
    int? acceptedHistoryGeneration,
    int? acceptedBufferGeneration,
  }) async {
    final captureHistoryGeneration =
        acceptedHistoryGeneration ?? _historyGeneration;
    final captureBufferGeneration =
        acceptedBufferGeneration ?? _bufferGeneration(bufferId);
    if (!_operationIsCurrent(
      bufferId,
      captureHistoryGeneration,
      captureBufferGeneration,
    )) {
      return true;
    }
    if (!_pendingIsEligible(snapshot)) {
      _pending.remove(bufferId);
      _checkpointTimers.remove(bufferId)?.cancel();
      _captureFailures.remove(bufferId);
      return true;
    }
    final captured = await _capture(
      snapshot,
      LocalHistoryCaptureReason.automaticCheckpoint,
      acceptedHistoryGeneration: captureHistoryGeneration,
      acceptedBufferGeneration: captureBufferGeneration,
    );
    if (!_operationIsCurrent(
      bufferId,
      captureHistoryGeneration,
      captureBufferGeneration,
    )) {
      return true;
    }
    if (captured && !_pathTransitions.containsKey(bufferId)) {
      _acknowledgePending(bufferId, snapshot.revision);
    }
    final remaining = _pending[bufferId];
    if (remaining != null) {
      final failure = _captureFailures[bufferId];
      if (captured || failure?.retryable == true) {
        _scheduleCheckpoint(bufferId);
      }
    }
    return captured && !_pending.containsKey(bufferId);
  }

  void _retainPending(LocalHistoryBufferSnapshot snapshot) {
    if (!_pendingIsEligible(snapshot)) return;
    final current = _pending[snapshot.bufferId];
    if (current == null || current.revision <= snapshot.revision) {
      _pending[snapshot.bufferId] = snapshot;
    }
    if (_captureFailures[snapshot.bufferId]?.retryable != false) {
      _scheduleCheckpoint(snapshot.bufferId);
    }
  }

  void _acknowledgePending(String bufferId, int capturedRevision) {
    final pending = _pending[bufferId];
    if (pending != null && pending.revision <= capturedRevision) {
      _pending.remove(bufferId);
      _checkpointTimers.remove(bufferId)?.cancel();
    }
  }

  bool _pendingIsEligible(LocalHistoryBufferSnapshot snapshot) {
    final currentPolicy = policy;
    return currentPolicy.recordingEnabled &&
        !currentPolicy.excludes(snapshot.path);
  }

  int _bufferGeneration(String bufferId) => _bufferGenerations[bufferId] ?? 0;

  bool _operationIsCurrent(
    String bufferId,
    int historyGeneration,
    int bufferGeneration,
  ) =>
      ref.mounted &&
      historyGeneration == _historyGeneration &&
      bufferGeneration == _bufferGeneration(bufferId);

  void _invalidateBufferWork(String bufferId) {
    _bufferGenerations[bufferId] = _bufferGeneration(bufferId) + 1;
    _checkpointTimers.remove(bufferId)?.cancel();
    _pending.remove(bufferId);
    _captureFailures.remove(bufferId);
  }

  void _applyRecordingPolicy(AppSettings settings) {
    if (!settings.localHistoryRecordingEnabled) {
      _historyGeneration++;
      _cancelCheckpoints(clearTransitions: false);
      _captureFailures.clear();
      return;
    }
    for (final entry in _pending.entries.toList(growable: false)) {
      if (policy.excludes(entry.value.path)) {
        _invalidateBufferWork(entry.key);
      }
    }
  }

  bool _captureErrorIsRetryable(Object error) {
    if (error is UnsupportedLocalHistoryFormat) return false;
    if (error is LocalHistoryStorageException &&
        error.message.contains('larger than the Local History storage limit')) {
      return false;
    }
    return true;
  }

  void _showCaptureFailure() {
    final failure = _captureFailures.values.firstOrNull;
    if (failure != null) {
      _setWarning(LocalHistoryWarningKind.capture, failure.detail);
    }
  }

  Future<void> _publishSnapshot(
    LocalHistorySnapshot snapshot, {
    String? capturedBufferId,
    LocalHistoryBufferSnapshot? capturedSnapshot,
    LocalHistoryWarning? warning,
    String? explicitlyClearedDocumentId,
    bool clearAllComparisons = false,
  }) async {
    if (!ref.mounted) return;
    _snapshotGeneration++;
    _searchGeneration++;
    if (capturedBufferId != null &&
        _normalBrowsingScope?.bufferId == capturedBufferId &&
        capturedSnapshot != null &&
        capturedSnapshot.revision >= _normalBrowsingScope!.revision) {
      _normalBrowsingScope = capturedSnapshot;
    }

    var selectedDocumentId = state.selectedDocumentId;
    if (!state.findingDocuments && !state.inspectingRetainedDocument) {
      final scope = _normalBrowsingScope;
      if (scope != null) {
        selectedDocumentId = _documentIdsByBuffer[scope.bufferId];
        if (selectedDocumentId != null &&
            !snapshot.documents.any(
              (document) => document.id == selectedDocumentId,
            )) {
          selectedDocumentId = null;
        }
        if (selectedDocumentId == null && scope.path != null) {
          final byPath = snapshot.documents
              .where(
                (document) =>
                    document.currentPath != null &&
                    p.equals(document.currentPath!, scope.path!),
              )
              .firstOrNull;
          if (byPath != null) {
            selectedDocumentId = byPath.id;
            _documentIdsByBuffer[scope.bufferId] = byPath.id;
          }
        }
      }
    }
    if (selectedDocumentId != null &&
        !snapshot.documents.any(
          (document) => document.id == selectedDocumentId,
        )) {
      selectedDocumentId = null;
    }

    var selectedRevisionId = state.selectedRevisionId;
    var selectedRevision = state.selectedRevision;
    var effectiveWarning = _captureFailures.isNotEmpty
        ? LocalHistoryWarning(
            LocalHistoryWarningKind.capture,
            detail: _captureFailures.values.first.detail,
          )
        : warning;
    final selectedSummary = selectedRevisionId == null
        ? null
        : snapshot.revisions
              .where((revision) => revision.id == selectedRevisionId)
              .firstOrNull;
    final comparisonWasExplicitlyCleared =
        clearAllComparisons ||
        (explicitlyClearedDocumentId != null &&
            ((state.selectedDocumentId == explicitlyClearedDocumentId &&
                    selectedRevisionId != null) ||
                selectedRevision?.summary.documentId ==
                    explicitlyClearedDocumentId ||
                selectedSummary?.documentId == explicitlyClearedDocumentId));
    if (selectedRevisionId != null &&
        (selectedSummary == null ||
            selectedSummary.documentId != selectedDocumentId)) {
      selectedRevisionId = null;
      selectedRevision = null;
      if (!comparisonWasExplicitlyCleared && effectiveWarning == null) {
        effectiveWarning = const LocalHistoryWarning(
          LocalHistoryWarningKind.revisionMissing,
        );
      }
    }
    if (comparisonWasExplicitlyCleared) {
      selectedRevisionId = null;
      selectedRevision = null;
    }

    final query = state.searchQuery;
    state = state.copyWith(
      snapshot: snapshot,
      loading: false,
      selectedDocumentId: selectedDocumentId,
      selectedRevisionId: selectedRevisionId,
      selectedRevision: selectedRevision,
      warning: effectiveWarning,
    );
    if (query.isNotEmpty) {
      await _runSearch(query, clearMatches: false);
    } else {
      final revisionIds = snapshot.revisions
          .map((revision) => revision.id)
          .toSet();
      final documentIds = snapshot.documents
          .map((document) => document.id)
          .toSet();
      state = state.copyWith(
        searchMatches: state.searchMatches.intersection(revisionIds),
        documentSearchMatches: state.documentSearchMatches.intersection(
          documentIds,
        ),
      );
    }
  }

  Future<void> _runSearch(String query, {required bool clearMatches}) async {
    final generation = ++_searchGeneration;
    final snapshotGeneration = _snapshotGeneration;
    final documentId = state.selectedDocumentId;
    final findingDocuments = state.findingDocuments;
    state = state.copyWith(
      searchQuery: query,
      searching: query.isNotEmpty,
      searchMatches: clearMatches ? const {} : state.searchMatches,
      documentSearchMatches: clearMatches
          ? const {}
          : state.documentSearchMatches,
    );
    if (query.isEmpty) {
      state = state.copyWith(
        searching: false,
        searchMatches: const {},
        documentSearchMatches: const {},
      );
      return;
    }
    final snapshot = state.snapshot;
    final summaries = findingDocuments
        ? snapshot.revisions
        : documentId == null
        ? const <LocalHistoryRevisionSummary>[]
        : snapshot.revisionsFor(documentId);
    final matches = <String>{};
    final documentMatches = <String>{};
    final needle = query.toLowerCase();
    bool current() =>
        ref.mounted &&
        generation == _searchGeneration &&
        snapshotGeneration == _snapshotGeneration &&
        state.searchQuery == query &&
        state.selectedDocumentId == documentId &&
        state.findingDocuments == findingDocuments;
    try {
      if (findingDocuments) {
        for (final document in snapshot.documents) {
          if (document.displayName.toLowerCase().contains(needle) ||
              (document.currentPath?.toLowerCase().contains(needle) ?? false) ||
              document.historicalPaths.any(
                (path) => path.toLowerCase().contains(needle),
              )) {
            documentMatches.add(document.id);
          }
        }
      }
      for (final summary in summaries) {
        final revision = await _store.readRevision(summary.id);
        if (!current()) return;
        if (revision?.source.toLowerCase().contains(needle) == true) {
          matches.add(summary.id);
          documentMatches.add(summary.documentId);
        }
      }
      if (!current()) return;
      state = state.copyWith(
        searching: false,
        searchMatches: matches,
        documentSearchMatches: documentMatches,
      );
    } on Object catch (error) {
      if (!current()) return;
      state = state.copyWith(
        searching: false,
        warning: LocalHistoryWarning(
          LocalHistoryWarningKind.revisionRead,
          detail: error.toString(),
        ),
      );
    }
  }

  void _setWarning(LocalHistoryWarningKind kind, [String? detail]) {
    if (ref.mounted) {
      state = state.copyWith(
        warning: LocalHistoryWarning(kind, detail: detail),
      );
    }
  }
}

class _LocalHistoryCaptureFailure {
  const _LocalHistoryCaptureFailure({
    this.detail,
    required this.retryable,
    required this.stage,
  });

  final String? detail;
  final bool retryable;
  final _LocalHistoryFailureStage stage;
}

enum _LocalHistoryFailureStage { capture, promotion }

bool _sameOptionalPath(String? first, String? second) {
  if (first == null || second == null) return first == second;
  return p.equals(first, second);
}

String? _remapHistoryPath(String path, String source, String destination) {
  final normalizedPath = p.normalize(path);
  final normalizedSource = p.normalize(source);
  final normalizedDestination = p.normalize(destination);
  if (p.equals(normalizedPath, normalizedSource)) {
    return normalizedDestination;
  }
  if (!p.isWithin(normalizedSource, normalizedPath)) return null;
  return p.normalize(
    p.join(
      normalizedDestination,
      p.relative(normalizedPath, from: normalizedSource),
    ),
  );
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
