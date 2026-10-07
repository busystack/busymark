import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show listEquals;
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
  const LocalHistoryWarning(
    this.kind, {
    this.detail,
    this.ownerBufferId,
    this.ownerDisplayName,
  });

  final LocalHistoryWarningKind kind;
  final String? detail;
  final String? ownerBufferId;
  final String? ownerDisplayName;
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
    this.captureId,
    this.acceptedClearEpoch,
    this.acceptedAt,
    this.acceptedDocumentId,
    this.remoteNote,
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
        remoteNote: buffer.remoteNote,
      );

  final String bufferId;
  final String displayName;
  final String text;
  final TextFormatMetadata format;
  final int revision;
  final String? path;
  final bool untitled;
  final String? captureId;
  final String? acceptedClearEpoch;
  final DateTime? acceptedAt;
  final String? acceptedDocumentId;
  final NextcloudNoteReference? remoteNote;

  LocalHistoryBufferSnapshot atPath(String destinationPath) =>
      LocalHistoryBufferSnapshot(
        bufferId: bufferId,
        displayName: p.basename(destinationPath),
        text: text,
        format: format,
        revision: revision,
        path: destinationPath,
        captureId: captureId,
        acceptedClearEpoch: acceptedClearEpoch,
        acceptedAt: acceptedAt,
        acceptedDocumentId: acceptedDocumentId,
        remoteNote: remoteNote,
      );

  LocalHistoryBufferSnapshot forBuffer(String id) => LocalHistoryBufferSnapshot(
    bufferId: id,
    displayName: displayName,
    text: text,
    format: format,
    revision: revision,
    path: path,
    untitled: untitled,
    captureId: captureId,
    acceptedClearEpoch: acceptedClearEpoch,
    acceptedAt: acceptedAt,
    acceptedDocumentId: acceptedDocumentId,
    remoteNote: remoteNote,
  );

  LocalHistoryBufferSnapshot withCaptureId(String? id) =>
      LocalHistoryBufferSnapshot(
        bufferId: bufferId,
        displayName: displayName,
        text: text,
        format: format,
        revision: revision,
        path: path,
        untitled: untitled,
        captureId: id,
        acceptedClearEpoch: acceptedClearEpoch,
        acceptedAt: acceptedAt,
        acceptedDocumentId: acceptedDocumentId,
        remoteNote: remoteNote,
      );

  LocalHistoryBufferSnapshot withAcceptedDocumentId(String? id) =>
      LocalHistoryBufferSnapshot(
        bufferId: bufferId,
        displayName: displayName,
        text: text,
        format: format,
        revision: revision,
        path: path,
        untitled: untitled,
        captureId: captureId,
        acceptedClearEpoch: acceptedClearEpoch,
        acceptedAt: acceptedAt,
        acceptedDocumentId: id,
        remoteNote: remoteNote,
      );

  LocalHistoryBufferSnapshot atClearAcceptance(
    String? epoch,
    DateTime accepted,
    String? documentId,
  ) => LocalHistoryBufferSnapshot(
    bufferId: bufferId,
    displayName: displayName,
    text: text,
    format: format,
    revision: revision,
    path: path,
    untitled: untitled,
    captureId: captureId,
    acceptedClearEpoch: epoch,
    acceptedAt: accepted.toUtc(),
    acceptedDocumentId: documentId,
    remoteNote: remoteNote,
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
    this.acceptedClearEpoch,
    this.operationOwnerId,
  });

  final String bufferId;
  final String documentId;
  final String destinationPath;
  final String displayName;
  final String? acceptedClearEpoch;
  final String? operationOwnerId;

  LocalHistoryPendingIdentityPromotion atPath(String path) =>
      LocalHistoryPendingIdentityPromotion(
        bufferId: bufferId,
        documentId: documentId,
        destinationPath: p.normalize(path),
        displayName: p.basename(path),
        acceptedClearEpoch: acceptedClearEpoch,
        operationOwnerId: operationOwnerId,
      );

  LocalHistoryPendingIdentityPromotion forBuffer(String id) =>
      LocalHistoryPendingIdentityPromotion(
        bufferId: id,
        documentId: documentId,
        destinationPath: destinationPath,
        displayName: displayName,
        acceptedClearEpoch: acceptedClearEpoch,
        operationOwnerId: operationOwnerId,
      );

  LocalHistoryPendingIdentityPromotion atClearEpoch(String epoch) =>
      LocalHistoryPendingIdentityPromotion(
        bufferId: bufferId,
        documentId: documentId,
        destinationPath: destinationPath,
        displayName: displayName,
        acceptedClearEpoch: epoch,
        operationOwnerId: operationOwnerId,
      );
}

class LocalHistoryController extends Notifier<LocalHistoryState> {
  static const _pathRemapOwner = 'history-path-remaps';
  static var _operationOwnerSerial = 0;
  static final _liveOperationOwners = <String>{};

  late LocalHistoryStore _store;
  late LocalHistoryClock _clock;
  late LocalHistoryTimerFactory _timerFactory;
  final _documentIdsByBuffer = <String, String>{};
  final _clearingDocumentIdsByBuffer = <String, String>{};
  final _pending = <String, LocalHistoryBufferSnapshot>{};
  // A baseline cannot coalesce with edited text: both snapshots are needed.
  final _baselines = <String, LocalHistoryBufferSnapshot>{};
  final _baselinesRequiringVacantPath = <String>{};
  final _baselineSaveDestinations = <String, LocalHistoryBufferSnapshot>{};
  var _detachedCaptureOwner = 0;
  final _protections =
      <
        String,
        ({
          LocalHistoryBufferSnapshot snapshot,
          LocalHistoryCaptureReason reason,
          bool force,
          bool ignoreBinding,
          bool allowPathChange,
          bool bindResult,
          bool requireVacantPath,
          LocalHistoryPathTarget? expectedTarget,
          String? captureId,
        })
      >{};
  final _checkpointTimers = <String, Timer>{};
  final _bufferQueues = <String, Future<void>>{};
  final _pathTransitions = <String, LocalHistoryBufferPathTransition>{};
  final _pendingPathOperations = <_LocalHistoryPathOperation>[];
  final _retiredPathOperationIds = <String>{};
  final _retiredDurableWorkOwnerIds = <String>{};
  final _pendingClearOperations = <String, LocalHistoryPendingClear>{};
  final _pendingSaveAsOperations = <String, LocalHistoryPendingSaveAs>{};
  final _externallyOwnedRetainedCaptures =
      <String, LocalHistoryRetainedCapture>{};
  final _externallyOwnedPromotions =
      <String, LocalHistoryPendingIdentityPromotion>{};
  final _externallyOwnedSaveAsOperations =
      <String, LocalHistoryPendingSaveAs>{};
  final _pendingUntitledPromotions =
      <String, LocalHistoryPendingIdentityPromotion>{};
  final _bufferGenerations = <String, int>{};
  final _captureFailures =
      <String, Map<_LocalHistoryFailureStage, _LocalHistoryCaptureFailure>>{};
  final _closedBuffers = <String>{};
  final _inFlightSnapshots = <String, LocalHistoryBufferSnapshot>{};
  var _settling = 0;
  LocalHistoryWarning? _storeWarning;
  LocalHistoryBufferSnapshot? _normalBrowsingScope;
  bool _clearEpochLoaded = false;
  var _historyGeneration = 0;
  var _snapshotGeneration = 0;
  var _loadGeneration = 0;
  var _searchGeneration = 0;
  var _scopeGeneration = 0;
  var _pathOperationSerial = 0;
  Future<bool> Function()? _persistDurableState;
  bool _durableStateDirty = false;
  late final String _operationOwnerToken;
  late final int _processStartIdentity;

  @override
  LocalHistoryState build() {
    _processStartIdentity =
        _readLinuxProcessStartIdentity(pid) ??
        DateTime.now().toUtc().microsecondsSinceEpoch;
    _operationOwnerToken =
        'lh${pid}_${_processStartIdentity}_${++_operationOwnerSerial}';
    _liveOperationOwners.add(_operationOwnerToken);
    _store = ref.read(localHistoryStoreProvider);
    _clock = ref.read(localHistoryClockProvider);
    _timerFactory = ref.read(localHistoryTimerFactoryProvider);
    ref.listen<AppSettings>(
      appSettingsControllerProvider,
      (previous, next) => unawaited(_applyRecordingPolicy(next)),
    );
    ref.onDispose(() {
      _liveOperationOwners.remove(_operationOwnerToken);
      _historyGeneration++;
      _cancelCheckpoints();
      _pendingUntitledPromotions.clear();
      _pendingPathOperations.clear();
      _pendingSaveAsOperations.clear();
      _pendingClearOperations.clear();
      _externallyOwnedRetainedCaptures.clear();
      _externallyOwnedPromotions.clear();
      _externallyOwnedSaveAsOperations.clear();
      _captureFailures.clear();
      _documentIdsByBuffer.clear();
      _clearingDocumentIdsByBuffer.clear();
    });
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

  LocalHistoryBufferSnapshot _acceptAtCurrentClearEpoch(
    LocalHistoryBufferSnapshot snapshot,
  ) {
    if (snapshot.acceptedAt != null) return snapshot;
    final clearingDocumentId = _clearingDocumentIdsByBuffer[snapshot.bufferId];
    final pendingClear = _pendingClearOperations.values
        .where(
          (operation) =>
              operation.clearAll ||
              clearingDocumentId != null &&
                  operation.documentId == clearingDocumentId,
        )
        .lastOrNull;
    return snapshot.atClearAcceptance(
      pendingClear?.operationId ??
          (_clearEpochLoaded ? state.snapshot.clearEpoch : null),
      DateTime.now().toUtc(),
      pendingClear == null
          ? _documentIdsByBuffer[snapshot.bufferId] ?? clearingDocumentId
          : null,
    );
  }

  void setDurableStatePersistence(Future<bool> Function()? persist) {
    _persistDurableState = persist;
  }

  String _durableStateFingerprint() => jsonEncode({
    'promotions': [
      for (final promotion in pendingIdentityPromotions)
        {
          'owner': promotion.bufferId,
          'document': promotion.documentId,
          'destination': promotion.destinationPath,
          'displayName': promotion.displayName,
        },
    ],
    'paths': [
      for (final reconciliation in pendingPathReconciliations)
        reconciliation.toJson(),
    ],
    'retiredPaths': retiredPathReconciliationIds,
    'retiredWorkOwners': retiredDurableWorkOwnerIds,
    'clears': [
      for (final operation in pendingClearOperations) operation.toJson(),
    ],
    'saveAs': [
      for (final operation in pendingSaveAsOperations) operation.toJson(),
    ],
    'captures': [
      for (final capture in retainedDetachedCaptures) capture.toJson(),
    ],
  });

  Future<void> _persistDurableStateIfChanged(String before) async {
    if (before != _durableStateFingerprint()) _durableStateDirty = true;
    if (_durableStateDirty) await _persistDurableStateNow();
  }

  Future<bool> _persistDurableStateNow() async {
    _durableStateDirty = true;
    final persist = _persistDurableState;
    if (persist == null) return true;
    final intended = _durableStateFingerprint();
    final persisted = await persist.call();
    _durableStateDirty = !persisted || _durableStateFingerprint() != intended;
    return persisted;
  }

  LocalHistoryBufferSnapshot? pendingSnapshotForBuffer(String bufferId) =>
      _pending[bufferId] ??
      _pending.entries
          .where((entry) => _detachedClosedSourceId(entry.key) == bufferId)
          .map((entry) => entry.value)
          .firstOrNull;

  bool canDiscardPristineDraft(DocumentBuffer buffer) =>
      buffer.isUntitled &&
      buffer.text.isEmpty &&
      buffer.lastSavedText.isEmpty &&
      buffer.revision == 0 &&
      !buffer.recovered &&
      buffer.diskSnapshot == null &&
      !_documentIdsByBuffer.containsKey(buffer.id) &&
      !_hasOutstandingWork(buffer.id);

  /// Workspace banners use the editor's actual buffer, independently of the
  /// retained document selected in the history browser.
  LocalHistoryWarning? warningForBuffer(String? bufferId) {
    final failure = _ownerFailure(bufferId);
    if (failure != null) {
      return _failureWarning(bufferId!, failure);
    }
    final pathWarning = _pathWarningForOwner(bufferId);
    if (pathWarning != null) return pathWarning;
    final documentWarning = _pathWarningForDocument(
      bufferId == null ? null : _documentIdsByBuffer[bufferId],
    );
    if (documentWarning != null) return documentWarning;
    if (bufferId != null) {
      final binding = _documentIdsByBuffer[bufferId];
      final unresolvedSaveAs = _pendingSaveAsOperations.values
          .where(
            (operation) =>
                operation.bufferId == bufferId &&
                operation.phase ==
                    LocalHistoryPathReconciliationPhase.executing &&
                (operation.sourceDocumentId == null ||
                    operation.sourceDocumentId == binding),
          )
          .firstOrNull;
      if (unresolvedSaveAs != null) {
        return LocalHistoryWarning(
          LocalHistoryWarningKind.pathChange,
          ownerDisplayName: unresolvedSaveAs.destination.path,
          detail: 'The interrupted Save As outcome needs resolution.',
        );
      }
    }
    return _storeWarning ??
        switch (state.warning?.kind) {
          LocalHistoryWarningKind.indexRebuilt ||
          LocalHistoryWarningKind.unsupportedFormat ||
          LocalHistoryWarningKind.unavailable ||
          LocalHistoryWarningKind.recordingDisabled => state.warning,
          _ => null,
        };
  }

  Future<bool> refresh() async {
    final generation = ++_loadGeneration;
    if (ref.mounted) state = state.copyWith(loading: true);
    try {
      await _store.prune(policy, _clock());
      final snapshot = await _store.load();
      if (!ref.mounted || generation != _loadGeneration) return false;
      await _publishSnapshot(
        snapshot,
        warning: snapshot.warning == null
            ? null
            : const LocalHistoryWarning(LocalHistoryWarningKind.indexRebuilt),
      );
      return true;
    } on UnsupportedLocalHistoryFormat catch (error) {
      if (!ref.mounted || generation != _loadGeneration) return false;
      _storeWarning = LocalHistoryWarning(
        LocalHistoryWarningKind.unsupportedFormat,
        detail: error.version?.toString(),
      );
      state = state.copyWith(loading: false, warning: _presentationWarning());
      return false;
    } on Object catch (error) {
      if (!ref.mounted || generation != _loadGeneration) return false;
      _storeWarning = LocalHistoryWarning(
        LocalHistoryWarningKind.unavailable,
        detail: error.toString(),
      );
      state = state.copyWith(loading: false, warning: _presentationWarning());
      return false;
    }
  }

  Future<void> observeOpened(DocumentBuffer buffer) async {
    _closedBuffers.remove(buffer.id);
    final snapshot = _acceptAtCurrentClearEpoch(
      LocalHistoryBufferSnapshot.fromBuffer(buffer),
    );
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
          _setWarning(
            LocalHistoryWarningKind.pathChange,
            promotion.destinationPath,
          );
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
        await _captureBaseline(
          snapshot,
          LocalHistoryCaptureReason.baseline,
          acceptedHistoryGeneration: historyGeneration,
          acceptedBufferGeneration: bufferGeneration,
        );
        return;
      }
      if (adoptedPromotion != null) return;
      if (_documentIdsByBuffer.containsKey(snapshot.bufferId)) return;
      if (_baselines.containsKey(snapshot.bufferId)) {
        _scheduleCheckpoint(snapshot.bufferId);
        return;
      }
      await _captureBaseline(
        snapshot,
        LocalHistoryCaptureReason.baseline,
        acceptedHistoryGeneration: historyGeneration,
        acceptedBufferGeneration: bufferGeneration,
      );
    });
  }

  void observeEdit(DocumentBuffer previous, DocumentBuffer current) {
    if (!policy.recordingEnabled || policy.excludes(current.filePath)) return;
    final previousSnapshot = _acceptAtCurrentClearEpoch(
      LocalHistoryBufferSnapshot.fromBuffer(previous),
    );
    final currentSnapshot = _acceptAtCurrentClearEpoch(
      LocalHistoryBufferSnapshot.fromBuffer(current),
    );
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
            !_baselines.containsKey(current.id) &&
            !(previousSnapshot.untitled && previousSnapshot.text.isEmpty)) {
          await _captureBaseline(
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
    if (committed &&
        transition.kind == LocalHistoryBufferPathTransitionKind.move &&
        transition.sourcePath != null) {
      _remapRetainedAssociations(
        transition.sourcePath!,
        transition.destinationPath,
        owners: {transition.bufferId},
      );
    }
    final pending = _pending[transition.bufferId];
    if (committed &&
        transition.kind == LocalHistoryBufferPathTransitionKind.saveAs &&
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
    snapshot = _acceptAtCurrentClearEpoch(snapshot);
    if (snapshot.captureId == null) {
      snapshot = snapshot.withCaptureId(_newPathOperationId());
    }
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
      _retainPending(snapshot);
      await _persistDurableStateNow();
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
    snapshot = _acceptAtCurrentClearEpoch(snapshot);
    if (!policy.recordingEnabled || policy.excludes(snapshot.path)) {
      _setWarning(LocalHistoryWarningKind.recordingDisabled);
      return false;
    }
    snapshot = snapshot.withCaptureId(
      snapshot.captureId ?? _newPathOperationId(),
    );
    final historyGeneration = _historyGeneration;
    final bufferGeneration = _bufferGeneration(snapshot.bufferId);
    _protections[snapshot.bufferId] = (
      snapshot: snapshot,
      reason: reason,
      force: true,
      ignoreBinding: false,
      allowPathChange: false,
      bindResult: false,
      requireVacantPath: false,
      expectedTarget: null,
      captureId: snapshot.captureId,
    );
    await _persistDurableStateNow();
    return _enqueue(
      snapshot.bufferId,
      () => _capture(
        snapshot,
        reason,
        force: true,
        requireProtection: true,
        retainedProtection: true,
        captureId: snapshot.captureId,
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
    snapshot = _acceptAtCurrentClearEpoch(snapshot);
    if (!policy.recordingEnabled || policy.excludes(snapshot.path)) return true;
    snapshot = snapshot.withCaptureId(
      snapshot.captureId ?? _newPathOperationId(),
    );
    final historyGeneration = _historyGeneration;
    final bufferGeneration = _bufferGeneration(snapshot.bufferId);
    _protections[snapshot.bufferId] = (
      snapshot: snapshot,
      reason: reason,
      force: true,
      ignoreBinding: false,
      allowPathChange: false,
      bindResult: false,
      requireVacantPath: false,
      expectedTarget: null,
      captureId: snapshot.captureId,
    );
    await _persistDurableStateNow();
    return _enqueue(
      snapshot.bufferId,
      () => _capture(
        snapshot,
        reason,
        force: true,
        requireProtection: true,
        retainedProtection: true,
        captureId: snapshot.captureId,
        acceptedHistoryGeneration: historyGeneration,
        acceptedBufferGeneration: bufferGeneration,
      ),
    );
  }

  Future<bool> captureSavedAs(
    LocalHistoryBufferSnapshot source,
    String destinationPath, {
    required bool destinationExisted,
    TextFormatMetadata? destinationFormat,
    bool? recordSourceHistory,
    bool? recordDestinationHistory,
    String? destinationDocumentId,
    LocalHistoryPathTarget? destinationTarget,
    String? sourceCaptureId,
    String? destinationCaptureId,
    String? sourceAcceptedClearEpoch,
    String? destinationAcceptedClearEpoch,
    DateTime? sourceAcceptedAt,
    DateTime? destinationAcceptedAt,
    String? sourceAcceptedDocumentId,
    String? destinationAcceptedDocumentId,
    String? saveAsOperationId,
    bool? firstSaveLineageTransition,
  }) async {
    source =
        (sourceAcceptedClearEpoch == null && sourceAcceptedAt == null
                ? _acceptAtCurrentClearEpoch(source)
                : source.atClearAcceptance(
                    sourceAcceptedClearEpoch,
                    sourceAcceptedAt ??
                        source.acceptedAt ??
                        DateTime.now().toUtc(),
                    sourceAcceptedDocumentId ??
                        source.acceptedDocumentId ??
                        _documentIdsByBuffer[source.bufferId],
                  ))
            .withCaptureId(sourceCaptureId);
    final currentPolicy = policy;
    final frozenSideSelection =
        recordSourceHistory != null || recordDestinationHistory != null;
    final recordSource =
        recordSourceHistory ??
        (currentPolicy.recordingEnabled &&
            !currentPolicy.excludes(source.path));
    final recordDestination =
        recordDestinationHistory ??
        (currentPolicy.recordingEnabled &&
            !currentPolicy.excludes(destinationPath));
    final historyGeneration = _historyGeneration;
    final bufferGeneration = _bufferGeneration(source.bufferId);
    final destination = LocalHistoryBufferSnapshot(
      bufferId: source.bufferId,
      displayName: p.basename(destinationPath),
      text: source.text,
      format: destinationFormat ?? source.format,
      revision: source.revision,
      path: destinationPath,
      captureId: destinationCaptureId,
      acceptedClearEpoch:
          destinationAcceptedClearEpoch ?? source.acceptedClearEpoch,
      acceptedAt: destinationAcceptedAt ?? source.acceptedAt,
      acceptedDocumentId:
          destinationAcceptedDocumentId ??
          (source.untitled && !destinationExisted
              ? source.acceptedDocumentId
              : null),
    );
    final preserveFirstSaveLineage =
        firstSaveLineageTransition ?? source.untitled && !destinationExisted;
    bool sideRemainsEnabled({required bool sourceSide}) {
      final initiallyEnabled = sourceSide ? recordSource : recordDestination;
      if (!initiallyEnabled ||
          !policy.recordingEnabled ||
          policy.excludes(sourceSide ? source.path : destination.path)) {
        return false;
      }
      if (saveAsOperationId == null) return true;
      final operation = _pendingSaveAsOperations[saveAsOperationId];
      if (operation == null || operation.historyCancelled) return false;
      return sourceSide
          ? operation.recordSourceHistory
          : operation.recordDestinationHistory;
    }

    var promotionCompleted = false;
    var retainedSourcePromotion = false;
    var destinationCaptured = false;
    var sourceWorkDetached = false;
    _SaveAsDestinationBinding? destinationBinding;
    final captured = await _enqueue(source.bufferId, () async {
      final sourceDocumentIdAtStart = _documentIdsByBuffer[source.bufferId];
      var sourceDocumentIdForFork = sourceDocumentIdAtStart;
      try {
        if (!_operationIsCurrent(
          source.bufferId,
          historyGeneration,
          bufferGeneration,
        )) {
          return true;
        }
        if (source.untitled && !destinationExisted) {
          final existingSourceId = _documentIdsByBuffer[source.bufferId];
          // Save As freezes and retires any stale destination owner under the
          // shared store lock before writing the new file.
          if (!await _settlePromotionPathDependencies(
            source.bufferId,
            existingSourceId,
            destinationPath,
          )) {
            if (ref.mounted &&
                existingSourceId != null &&
                _documentIdsByBuffer[source.bufferId] == existingSourceId &&
                !_baselines.containsKey(source.bufferId)) {
              _pendingUntitledPromotions.putIfAbsent(
                source.bufferId,
                () => LocalHistoryPendingIdentityPromotion(
                  bufferId: source.bufferId,
                  documentId: existingSourceId,
                  destinationPath: p.normalize(destinationPath),
                  displayName: p.basename(destinationPath),
                  acceptedClearEpoch: source.acceptedClearEpoch,
                  operationOwnerId: _newDetachedOwner('history-promotion'),
                ),
              );
            }
            return false;
          }
          if (!_operationIsCurrent(
            source.bufferId,
            historyGeneration,
            bufferGeneration,
          )) {
            return true;
          }
        }
        final baseline = sideRemainsEnabled(sourceSide: true)
            ? _baselines[source.bufferId]
            : null;
        if (baseline != null &&
            !await _capture(
              baseline,
              LocalHistoryCaptureReason.baseline,
              acceptedHistoryGeneration: historyGeneration,
              acceptedBufferGeneration: bufferGeneration,
            )) {
          return false;
        }
        // Source settlement may have created the stable identity after this
        // Save As began. Remember it before any later source checkpoint can
        // stop the operation; the live binding will eventually belong to the
        // destination.
        sourceDocumentIdForFork = _documentIdsByBuffer[source.bufferId];
        if (sideRemainsEnabled(sourceSide: true) &&
            sourceDocumentIdForFork == null) {
          _baselines.putIfAbsent(source.bufferId, () => source);
          if (!await _capture(
            _baselines[source.bufferId]!,
            LocalHistoryCaptureReason.baseline,
            allowDuringPathTransition: true,
            acceptedHistoryGeneration: historyGeneration,
            acceptedBufferGeneration: bufferGeneration,
          )) {
            return false;
          }
          sourceDocumentIdForFork = _documentIdsByBuffer[source.bufferId];
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
        final pending = sideRemainsEnabled(sourceSide: true)
            ? _pending[source.bufferId]
            : null;
        if (pending != null &&
            pending.revision <= source.revision &&
            _sameOptionalPath(pending.path, source.path)) {
          _checkpointTimers.remove(source.bufferId)?.cancel();
          final transactionalPending = pending.withCaptureId(source.captureId);
          _pending[source.bufferId] = transactionalPending;
          await _persistDurableStateNow();
          final pendingCaptured = await _capture(
            transactionalPending,
            LocalHistoryCaptureReason.automaticCheckpoint,
            force: source.captureId != null,
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
            _retainPending(transactionalPending);
          }
          if (!pendingCaptured &&
              policy.recordingEnabled &&
              !policy.excludes(pending.path)) {
            if (!source.untitled || destinationExisted) {
              _detachFailedCapturesForFork(
                source,
                sourceDocumentId: sourceDocumentIdForFork,
              );
              sourceWorkDetached = true;
            }
          }
        }

        if ((!source.untitled || destinationExisted) && !sourceWorkDetached) {
          _detachFailedCapturesForFork(
            source,
            sourceDocumentId: sourceDocumentIdForFork,
          );
          sourceWorkDetached = true;
        }

        final sourceDocumentId = _documentIdsByBuffer[source.bufferId];
        if (source.untitled &&
            !destinationExisted &&
            (!frozenSideSelection ||
                sideRemainsEnabled(sourceSide: true) &&
                    sideRemainsEnabled(sourceSide: false)) &&
            sourceDocumentId != null) {
          _pendingUntitledPromotions[source.bufferId] =
              LocalHistoryPendingIdentityPromotion(
                bufferId: source.bufferId,
                documentId: sourceDocumentId,
                destinationPath: p.normalize(destinationPath),
                displayName: p.basename(destinationPath),
                acceptedClearEpoch: source.acceptedClearEpoch,
                operationOwnerId: _newDetachedOwner('history-promotion'),
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
          if (!promotionCompleted) {
            if (saveAsOperationId != null) {
              if (sideRemainsEnabled(sourceSide: false)) {
                _protections[source.bufferId] = (
                  snapshot: destination,
                  reason: LocalHistoryCaptureReason.saved,
                  force: false,
                  ignoreBinding: false,
                  allowPathChange: false,
                  bindResult: true,
                  requireVacantPath: false,
                  expectedTarget: null,
                  captureId: destination.captureId ?? _newPathOperationId(),
                );
              }
              _detachPendingUntitledPromotion(
                source.bufferId,
                retainLiveBinding: true,
              );
              retainedSourcePromotion = true;
            }
            return false;
          }
        }

        if (!sideRemainsEnabled(sourceSide: false)) {
          return true;
        }
        destinationBinding = await _resolveSaveAsDestinationBinding(
          destination,
          stagedTarget: destinationTarget,
          allowedDocumentId: _documentIdsByBuffer[source.bufferId],
        );
        if (destinationBinding!.documentId case final documentId?) {
          _documentIdsByBuffer[source.bufferId] = documentId;
        } else {
          _documentIdsByBuffer.remove(source.bufferId);
        }
        final savedCaptured = await _capture(
          destination,
          LocalHistoryCaptureReason.saved,
          force: destination.captureId != null,
          ignoreBinding: destinationBinding!.documentId == null,
          bindResult: true,
          requireVacantPath: destinationBinding!.requireVacantPath,
          expectedTarget: destinationBinding!.expectedTarget,
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
          destinationCaptured = true;
          _acknowledgePending(destination.bufferId, destination.revision);
        }
        return savedCaptured;
      } on Object {
        // The filesystem Save As has already committed before this callback.
        // Source and destination work are handed to detached durable owners in
        // finally, so a transient target-resolution/store failure must not
        // strand the workspace Save As journal or retarget either lineage.
        return false;
      } finally {
        if (_operationIsCurrent(
          source.bufferId,
          historyGeneration,
          bufferGeneration,
        )) {
          final retainedBaseline = _baselines.containsKey(source.bufferId);
          if (source.untitled && !destinationExisted && retainedBaseline) {
            // The first save already succeeded on disk, but the original
            // baseline has no store identity yet. Promote that identity as
            // soon as its original source can be persisted.
            if (sideRemainsEnabled(sourceSide: false)) {
              _baselineSaveDestinations[source.bufferId] = destination;
            }
            _detachFailedCapturesForFork(
              source,
              sourceDocumentId: sourceDocumentIdForFork,
            );
            sourceWorkDetached = true;
          } else if ((!source.untitled || destinationExisted) &&
              !sourceWorkDetached) {
            _detachFailedCapturesForFork(
              source,
              sourceDocumentId: sourceDocumentIdForFork,
            );
          }
          // The filesystem copy already succeeded. If source settlement
          // stopped before the destination capture, keep that destination
          // checkpoint on the live buffer after source-owned work detaches.
          final destinationOwnedByPendingPromotion =
              source.untitled &&
              !destinationExisted &&
              (retainedSourcePromotion ||
                  _pendingUntitledPromotions.containsKey(source.bufferId) ||
                  retainedBaseline);
          if (!destinationCaptured &&
              sideRemainsEnabled(sourceSide: false) &&
              !destinationOwnedByPendingPromotion) {
            _detachSaveAsDestination(
              destination,
              documentId:
                  destinationBinding?.documentId ?? destinationDocumentId,
              expectedTarget:
                  destinationBinding?.expectedTarget ?? destinationTarget,
            );
          }
        }
        // Save As has already changed the filesystem and buffer path. A named
        // copy (or an overwrite) must detach from its source even if recording
        // was cancelled. Do this inside the queue, before later edits can use
        // the old binding, without removing a newly established association.
        if ((!source.untitled || destinationExisted) &&
            sourceDocumentIdAtStart != null &&
            _documentIdsByBuffer[source.bufferId] == sourceDocumentIdAtStart) {
          if (_pendingUntitledPromotions[source.bufferId]?.documentId ==
              sourceDocumentIdAtStart) {
            _detachPendingUntitledPromotion(source.bufferId);
            retainedSourcePromotion = true;
          } else {
            _documentIdsByBuffer.remove(source.bufferId);
          }
        } else if (ref.mounted &&
            source.untitled &&
            !destinationExisted &&
            !retainedSourcePromotion &&
            preserveFirstSaveLineage &&
            !policy.excludes(destination.path) &&
            !promotionCompleted &&
            sourceDocumentIdAtStart != null &&
            _documentIdsByBuffer[source.bufferId] == sourceDocumentIdAtStart) {
          // First save commits an identity transition even if optional source
          // capture was cancelled before promotion registration. Keep it for
          // the existing retry/session path. Unlike disabling recording, Clear
          // removes the binding, so it must never reinstall this association.
          _pendingUntitledPromotions.putIfAbsent(
            source.bufferId,
            () => LocalHistoryPendingIdentityPromotion(
              bufferId: source.bufferId,
              documentId: sourceDocumentIdAtStart,
              destinationPath: p.normalize(destinationPath),
              displayName: p.basename(destinationPath),
              acceptedClearEpoch: source.acceptedClearEpoch,
              operationOwnerId: _newDetachedOwner('history-promotion'),
            ),
          );
        }
      }
    });
    if (!_operationIsCurrent(
      source.bufferId,
      historyGeneration,
      bufferGeneration,
    )) {
      final operation = _pendingSaveAsOperations[saveAsOperationId];
      if (operation != null &&
          operation.phase == LocalHistoryPathReconciliationPhase.committed) {
        final promotion = _pendingUntitledPromotions[source.bufferId];
        final livePromotionOwnsTransition =
            operation.firstSaveLineageTransition &&
            promotion != null &&
            promotion.documentId == operation.sourceDocumentId &&
            p.equals(promotion.destinationPath, destinationPath);
        if (livePromotionOwnsTransition) {
          // The live Save As path already installed the durable promotion.
          // A simultaneous policy generation change must not recover the same
          // journal into a second detached promotion owner.
          await completeSavedAsSourceRecovery(operation.operationId);
        } else {
          // A clear or policy change may cancel only one side while this
          // post-filesystem capture is waiting. Transfer the journal's current,
          // narrowed obligations before the workspace retires that journal.
          await recoverCommittedSaveAs(operation);
        }
      }
      return true;
    }
    if (destinationCaptured) {
      final document = state.snapshot.documents
          .where(
            (candidate) =>
                !candidate.deleted &&
                candidate.currentPath != null &&
                p.equals(candidate.currentPath!, destinationPath),
          )
          .firstOrNull;
      if (document != null) _documentIdsByBuffer[source.bufferId] = document.id;
    } else if (!source.untitled ||
        destinationExisted ||
        (!sideRemainsEnabled(sourceSide: false) &&
            !_pendingUntitledPromotions.containsKey(source.bufferId))) {
      // The filesystem transition already succeeded. Do not let a later
      // checkpoint reuse the source document identity if history was disabled,
      // excluded, or temporarily unavailable during this Save As.
      _documentIdsByBuffer.remove(source.bufferId);
    }
    if (retainedSourcePromotion) {
      _setWarning(LocalHistoryWarningKind.pathChange, source.path);
    }
    return captured;
  }

  void _detachSaveAsDestination(
    LocalHistoryBufferSnapshot destination, {
    required String? documentId,
    required LocalHistoryPathTarget? expectedTarget,
  }) {
    final livePending = _pending[destination.bufferId];
    if (livePending != null &&
        livePending.revision <= destination.revision &&
        _sameOptionalPath(livePending.path, destination.path)) {
      _pending.remove(destination.bufferId);
    }
    final owner = _newDetachedOwner('history-capture:save-as-destination');
    if (documentId != null) _documentIdsByBuffer[owner] = documentId;
    _protections[owner] = (
      snapshot: destination.forBuffer(owner),
      reason: LocalHistoryCaptureReason.saved,
      force: false,
      ignoreBinding: documentId == null,
      allowPathChange: false,
      bindResult: true,
      requireVacantPath: documentId == null,
      expectedTarget: expectedTarget,
      captureId: destination.captureId ?? _newPathOperationId(),
    );
    _closedBuffers.add(owner);
    _scheduleCheckpoint(owner);
  }

  Future<_SaveAsDestinationBinding> _resolveSaveAsDestinationBinding(
    LocalHistoryBufferSnapshot destination, {
    required LocalHistoryPathTarget? stagedTarget,
    String? allowedDocumentId,
  }) async {
    final path = destination.path!;
    final targets = await _store.resolvePathTargets(path, recursive: false);
    if (targets.isEmpty) {
      return const _SaveAsDestinationBinding(requireVacantPath: true);
    }
    if (targets.length != 1) {
      throw const LocalHistoryReconciliationConflict();
    }
    final target = targets.single;
    if (target.documentId == allowedDocumentId ||
        (stagedTarget != null &&
            target.documentId == stagedTarget.documentId &&
            p.equals(target.expectedPath, stagedTarget.expectedPath))) {
      return _SaveAsDestinationBinding(
        documentId: target.documentId,
        expectedTarget: target,
      );
    }
    final captureId = destination.captureId;
    final revision = captureId == null
        ? null
        : await _store.readRevision(captureId);
    if (revision == null ||
        revision.summary.documentId != target.documentId ||
        revision.source != destination.text ||
        !_sameHistoryFormat(revision.format, destination.format)) {
      throw const LocalHistoryReconciliationConflict();
    }
    return _SaveAsDestinationBinding(
      documentId: target.documentId,
      expectedTarget: target,
    );
  }

  Future<String?> stageSavedAsSourceRecovery(
    LocalHistoryBufferSnapshot source, {
    required bool destinationExisted,
    LocalHistoryBufferSnapshot? destination,
    String? recoveryOwnerId,
  }) async {
    source = _acceptAtCurrentClearEpoch(source);
    destination = destination == null
        ? null
        : _acceptAtCurrentClearEpoch(destination);
    final acceptedHistoryGeneration = _historyGeneration;
    final acceptedBufferGeneration = _bufferGeneration(source.bufferId);
    if (destination == null) {
      // Compatibility for focused controller tests that only exercise source
      // partitioning. Workspace Save As always supplies the destination.
      if (source.untitled && !destinationExisted) return null;
      final owner = _newDetachedOwner('history-capture:save-as');
      _pending[owner] = source.forBuffer(owner);
      if (_documentIdsByBuffer[source.bufferId] case final documentId?) {
        _documentIdsByBuffer[owner] = documentId;
      }
      _closedBuffers.add(owner);
      await _persistDurableStateNow();
      return owner;
    }
    final currentPolicy = policy;
    var recordSource =
        currentPolicy.recordingEnabled && !currentPolicy.excludes(source.path);
    var recordDestination =
        currentPolicy.recordingEnabled &&
        !currentPolicy.excludes(destination.path);
    final currentSourceDocumentId = _documentIdsByBuffer[source.bufferId];
    final prior = _pendingSaveAsOperations.values
        .where(
          (operation) =>
              operation.bufferId == source.bufferId &&
              _sameOptionalPath(operation.source.path, source.path) &&
              _sameOptionalPath(
                operation.destination.path,
                destination!.path,
              ) &&
              operation.sourceDocumentId == currentSourceDocumentId,
        )
        .firstOrNull;
    if (prior != null) {
      if (prior.phase == LocalHistoryPathReconciliationPhase.executing &&
          _operationOwnerIsDefinitelyDead(prior.operationId)) {
        _pendingSaveAsOperations.remove(prior.operationId);
        _retiredDurableWorkOwnerIds.add(prior.operationId);
      } else {
        throw const LocalHistoryStorageException(
          'A Local History Save As reconciliation is still pending.',
        );
      }
    }
    // Freeze the source lineage before the durable fork journal is written.
    // A path-only retained capture could otherwise bind to a replacement
    // document after a restart.
    await _bufferQueues[source.bufferId];
    if (!_documentIdsByBuffer.containsKey(source.bufferId) &&
        (source.path != null || source.text.isNotEmpty)) {
      await _enqueue(
        source.bufferId,
        () =>
            _settleBufferWork(source.bufferId, allowDuringPathTransition: true),
      );
      await _bufferQueues[source.bufferId];
    }
    final settledSourceDocumentId = _documentIdsByBuffer[source.bufferId];
    if (settledSourceDocumentId != null) {
      source = source.withAcceptedDocumentId(
        source.acceptedDocumentId ?? settledSourceDocumentId,
      );
    }
    String? destinationDocumentId;
    LocalHistoryPathTarget? destinationTarget;
    if (destinationExisted && recordDestination) {
      final targets = await _store.resolvePathTargets(
        destination.path!,
        recursive: false,
      );
      if (targets.length != 1) {
        throw const LocalHistoryReconciliationConflict();
      }
      destinationTarget = targets.single;
      destinationDocumentId = destinationTarget.documentId;
    }
    destination = destination.withAcceptedDocumentId(
      source.untitled && !destinationExisted
          ? settledSourceDocumentId
          : destinationDocumentId,
    );
    final latestPolicy = policy;
    recordSource =
        recordSource &&
        latestPolicy.recordingEnabled &&
        !latestPolicy.excludes(source.path);
    recordDestination =
        recordDestination &&
        latestPolicy.recordingEnabled &&
        !latestPolicy.excludes(destination.path);
    final cancelledWhileStaging = !_operationIsCurrent(
      source.bufferId,
      acceptedHistoryGeneration,
      acceptedBufferGeneration,
    );
    if (cancelledWhileStaging) {
      recordSource = false;
      recordDestination = false;
    }
    final operationId = _newDetachedOwner('history-save-as');
    final sourceCaptureId = recordSource ? _newPathOperationId() : null;
    final destinationCaptureId = recordDestination
        ? _newPathOperationId()
        : null;
    _pendingSaveAsOperations[operationId] = LocalHistoryPendingSaveAs(
      operationId: operationId,
      bufferId: source.bufferId,
      sourceDocumentId: _documentIdsByBuffer[source.bufferId],
      source: _retainedSnapshot(source.withCaptureId(sourceCaptureId))!,
      destination: _retainedSnapshot(
        destination.withCaptureId(destinationCaptureId),
      )!,
      destinationExisted: destinationExisted,
      destinationDocumentId: destinationDocumentId,
      destinationTarget: destinationTarget,
      phase: LocalHistoryPathReconciliationPhase.prepared,
      recoveryOwnerId: recoveryOwnerId,
      recordSourceHistory: recordSource,
      recordDestinationHistory: recordDestination,
      historyCancelled: cancelledWhileStaging,
      firstSaveLineageTransition:
          source.untitled &&
          !destinationExisted &&
          !latestPolicy.excludes(destination.path),
    );
    try {
      await _persistDurableStateNow();
    } on Object {
      _pendingSaveAsOperations.remove(operationId);
      rethrow;
    }
    return operationId;
  }

  Future<bool> beginSavedAsSourceRecovery(String? operationId) async {
    final operation = _pendingSaveAsOperations[operationId];
    if (operation == null) return false;
    final executing = operation.withPhase(
      LocalHistoryPathReconciliationPhase.executing,
    );
    _pendingSaveAsOperations[operation.operationId] = executing;
    try {
      await _persistDurableStateNow();
    } on Object {
      if (identical(
        _pendingSaveAsOperations[operation.operationId],
        executing,
      )) {
        _pendingSaveAsOperations[operation.operationId] = operation;
      }
      rethrow;
    }
    return identical(
      _pendingSaveAsOperations[operation.operationId],
      executing,
    );
  }

  Future<bool> commitSavedAsSourceRecovery(String? operationId) async {
    final operation = _pendingSaveAsOperations[operationId];
    if (operation == null) return false;
    _pendingSaveAsOperations[operation.operationId] = operation.withPhase(
      LocalHistoryPathReconciliationPhase.committed,
    );
    final persisted = await _persistDurableStateNow();
    final current = _pendingSaveAsOperations[operation.operationId];
    return persisted &&
        current?.phase == LocalHistoryPathReconciliationPhase.committed &&
        (current!.firstSaveLineageTransition ||
            !current.historyCancelled &&
                (current.recordSourceHistory ||
                    current.recordDestinationHistory));
  }

  LocalHistoryPendingSaveAs? pendingSaveAsOperation(String? operationId) =>
      operationId == null ? null : _pendingSaveAsOperations[operationId];

  Future<void> cancelSavedAsSourceRecovery(String? owner) async {
    if (owner == null) return;
    final saveAs = _pendingSaveAsOperations[owner];
    if (saveAs != null) {
      if (saveAs.phase == LocalHistoryPathReconciliationPhase.committed &&
          !saveAs.historyCancelled) {
        return;
      }
      _pendingSaveAsOperations.remove(owner);
      _retiredDurableWorkOwnerIds.add(owner);
      await _persistDurableStateNow();
      return;
    }
    _checkpointTimers.remove(owner)?.cancel();
    _pending.remove(owner);
    _baselines.remove(owner);
    _baselinesRequiringVacantPath.remove(owner);
    _baselineSaveDestinations.remove(owner);
    _protections.remove(owner);
    _captureFailures.remove(owner);
    _documentIdsByBuffer.remove(owner);
    _closedBuffers.remove(owner);
    _retiredDurableWorkOwnerIds.add(owner);
    await _persistDurableStateNow();
  }

  Future<void> completeSavedAsSourceRecovery(String? operationId) async {
    if (operationId == null) return;
    if (_pendingSaveAsOperations.remove(operationId) != null) {
      _retiredDurableWorkOwnerIds.add(operationId);
      await _persistDurableStateNow();
      return;
    }
    await cancelSavedAsSourceRecovery(operationId);
  }

  Future<void> discardPendingSaveAsRecovery(String operationId) async {
    if (_pendingSaveAsOperations.remove(operationId) != null) {
      _retiredDurableWorkOwnerIds.add(operationId);
      await _persistDurableStateNow();
    }
  }

  Future<bool> capturePath({
    required String path,
    required String text,
    required TextFormatMetadata format,
    required LocalHistoryCaptureReason reason,
    bool force = true,
    bool requireProtection = false,
  }) async {
    var snapshot = _acceptAtCurrentClearEpoch(
      LocalHistoryBufferSnapshot(
        bufferId: 'path:${p.normalize(path)}',
        displayName: p.basename(path),
        text: text,
        format: format,
        revision: 0,
        path: path,
      ),
    );
    if (requireProtection) {
      snapshot = snapshot.withCaptureId(_newPathOperationId());
      final historyGeneration = _historyGeneration;
      final bufferGeneration = _bufferGeneration(snapshot.bufferId);
      _protections[snapshot.bufferId] = (
        snapshot: snapshot,
        reason: reason,
        force: force,
        ignoreBinding: true,
        allowPathChange: false,
        bindResult: false,
        requireVacantPath: false,
        expectedTarget: null,
        captureId: snapshot.captureId,
      );
      await _persistDurableStateNow();
      return _enqueue(
        snapshot.bufferId,
        () => _capture(
          snapshot,
          reason,
          force: force,
          ignoreBinding: true,
          requireProtection: true,
          retainedProtection: true,
          captureId: snapshot.captureId,
          acceptedHistoryGeneration: historyGeneration,
          acceptedBufferGeneration: bufferGeneration,
        ),
      );
    }
    final historyGeneration = _historyGeneration;
    final bufferGeneration = _bufferGeneration(snapshot.bufferId);
    return _enqueue(
      snapshot.bufferId,
      () => _capture(
        snapshot,
        reason,
        force: force,
        ignoreBinding: true,
        requireProtection: requireProtection,
        retainedProtection: requireProtection,
        captureId: snapshot.captureId,
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
      requireProtection: true,
    );
  }

  List<LocalHistoryPendingIdentityPromotion> get pendingIdentityPromotions =>
      List.unmodifiable(_pendingUntitledPromotions.values);

  List<LocalHistoryPathReconciliation> get pendingPathReconciliations =>
      List.unmodifiable(
        _pendingPathOperations.map((operation) => operation.reconciliation),
      );

  List<String> get retiredPathReconciliationIds =>
      List.unmodifiable(_retiredPathOperationIds.toList()..sort());

  List<String> get retiredDurableWorkOwnerIds =>
      List.unmodifiable(_retiredDurableWorkOwnerIds.toList()..sort());

  List<LocalHistoryPendingSaveAs> get pendingSaveAsOperations =>
      List.unmodifiable([
        ..._pendingSaveAsOperations.values,
        ..._externallyOwnedSaveAsOperations.values,
      ]);

  List<LocalHistoryPendingClear> get pendingClearOperations =>
      List.unmodifiable(_pendingClearOperations.values);

  void restoreRetiredPathReconciliationIds(Iterable<String> operationIds) {
    _retiredPathOperationIds.addAll(operationIds.where((id) => id.isNotEmpty));
  }

  Future<void> retirePreparedPathReconciliation(String operationId) async {
    if (operationId.isEmpty) return;
    _rememberRetiredPathOperation(operationId);
    await _persistDurableStateNow();
  }

  void restoreRetiredDurableWorkOwnerIds(Iterable<String> ownerIds) {
    _retiredDurableWorkOwnerIds.addAll(ownerIds.where((id) => id.isNotEmpty));
  }

  Future<bool> restorePendingClearOperations(
    Iterable<LocalHistoryPendingClear> operations,
  ) async {
    for (final operation in operations) {
      if (!_retiredDurableWorkOwnerIds.contains(operation.operationId)) {
        _pendingClearOperations[operation.operationId] = operation;
      }
    }
    return _settlePendingClearOperations();
  }

  Future<bool> _settlePendingClearOperations() async {
    for (final operation in _pendingClearOperations.values.toList()) {
      try {
        if (operation.clearAll) {
          await _store.clearAllOnce(operationId: operation.operationId);
        } else {
          await _store.clearDocumentOnce(
            operationId: operation.operationId,
            documentId: operation.documentId!,
          );
        }
        _publishCommittedClearEpoch(operation.operationId);
        if (!ref.mounted || !await refresh()) return false;
        _pendingClearOperations.remove(operation.operationId);
        _retiredDurableWorkOwnerIds.add(operation.operationId);
        await _persistDurableStateNow();
      } on Object catch (error) {
        _storeWarning = LocalHistoryWarning(
          LocalHistoryWarningKind.unavailable,
          detail: error.toString(),
        );
        _showCaptureFailure();
        return false;
      }
    }
    return true;
  }

  void restorePendingSaveAsOperations(
    Iterable<LocalHistoryPendingSaveAs> operations,
  ) {
    for (final operation in operations) {
      if (!_retiredDurableWorkOwnerIds.contains(operation.operationId)) {
        final prior = _pendingSaveAsOperations[operation.operationId];
        if (prior == null || operation.phase.index >= prior.phase.index) {
          _pendingSaveAsOperations[operation.operationId] = operation;
        }
      }
    }
  }

  void leavePendingSaveAsOwnedExternally(String operationId) {
    final operation = _pendingSaveAsOperations.remove(operationId);
    if (operation != null) {
      _externallyOwnedSaveAsOperations[operationId] = operation;
    }
  }

  Future<void> recoverCommittedSaveAs(
    LocalHistoryPendingSaveAs operation, {
    bool sourceRetainsUntitledLineage = false,
  }) async {
    while (true) {
      final current = _pendingSaveAsOperations[operation.operationId];
      if (current == null) return;
      operation = current;
      final destinationPath = operation.destination.path;
      if (operation.firstSaveLineageTransition &&
          destinationPath != null &&
          policy.excludes(destinationPath)) {
        final narrowed = operation
            .withRecordedSides(
              source: operation.recordSourceHistory,
              destination: false,
            )
            .withoutFirstSaveLineageTransition();
        _pendingSaveAsOperations[operation.operationId] = narrowed;
        await _persistDurableStateNow();
        continue;
      }
      if (!operation.firstSaveLineageTransition &&
          (operation.historyCancelled ||
              !operation.recordSourceHistory &&
                  !operation.recordDestinationHistory)) {
        _pendingSaveAsOperations.remove(operation.operationId);
        _retiredDurableWorkOwnerIds.add(operation.operationId);
        await _persistDurableStateNow();
        return;
      }
      final source = _restoreRetainedSnapshot(
        operation.bufferId,
        operation.source,
      );
      final destination = _restoreRetainedSnapshot(
        operation.bufferId,
        operation.destination,
      );
      final firstSave = source.untitled && !operation.destinationExisted;
      final continueFirstSaveLineage =
          firstSave &&
          operation.firstSaveLineageTransition &&
          !sourceRetainsUntitledLineage;
      final promotableDocumentId = continueFirstSaveLineage
          ? operation.sourceDocumentId
          : null;
      final liveDestinationOwners = sourceRetainsUntitledLineage
          ? _ownersAssociatedWithPath(
              destination.path!,
            ).where((owner) => owner != operation.bufferId).toSet()
          : const <String>{};
      // A destination tab is published before observeOpened necessarily binds
      // its history identity. Drain that owner's accepted baseline first so
      // Save As recovery cannot race it with a stale vacant-path decision.
      for (final owner in liveDestinationOwners) {
        _checkpointTimers.remove(owner)?.cancel();
        await _enqueue(owner, () => _settleBufferWork(owner));
        await _bufferQueues[owner];
      }
      final liveDestinationDocumentIds = liveDestinationOwners
          .map((owner) => _documentIdsByBuffer[owner])
          .whereType<String>()
          .where((documentId) => documentId != operation.sourceDocumentId)
          .toSet();
      final liveDestinationDocumentId = liveDestinationDocumentIds.length == 1
          ? liveDestinationDocumentIds.single
          : null;
      final pendingLiveDestinationOwner =
          liveDestinationOwners.length == 1 &&
              liveDestinationDocumentIds.isEmpty
          ? liveDestinationOwners.single
          : null;
      _SaveAsDestinationBinding? resolvedDestination;
      if (operation.recordDestinationHistory) {
        resolvedDestination = pendingLiveDestinationOwner != null
            ? null
            : promotableDocumentId != null
            ? _SaveAsDestinationBinding(documentId: promotableDocumentId)
            : await _resolveSaveAsDestinationBinding(
                destination,
                stagedTarget: operation.destinationTarget,
                allowedDocumentId:
                    operation.destinationDocumentId ??
                    liveDestinationDocumentId,
              );
      }
      // A clear or policy change may narrow the durable journal while path
      // resolution is awaiting the shared store. Resolve again from that
      // narrowed operation before installing any detached owners.
      if (!identical(
        _pendingSaveAsOperations[operation.operationId],
        operation,
      )) {
        continue;
      }

      if (continueFirstSaveLineage) {
        final owner = _newDetachedOwner('history-promotion:save-as');
        if (promotableDocumentId case final documentId?) {
          // The filesystem first save committed, but the editor did not adopt
          // the destination (for example, another tab claimed it while the
          // workspace open was awaiting). Recovery now transfers this lineage
          // to a detached promotion owner. Keep a still-untitled live buffer
          // from appending later edits to the document being promoted to B.
          if (_documentIdsByBuffer[operation.bufferId] == documentId) {
            _documentIdsByBuffer.remove(operation.bufferId);
          }
          _documentIdsByBuffer[owner] = documentId;
          _pendingUntitledPromotions[owner] =
              LocalHistoryPendingIdentityPromotion(
                bufferId: owner,
                documentId: documentId,
                destinationPath: destination.path!,
                displayName: destination.displayName,
                acceptedClearEpoch: source.acceptedClearEpoch,
                operationOwnerId: owner,
              );
        } else if (operation.recordSourceHistory && source.text.isNotEmpty) {
          _baselines[owner] = source.forBuffer(owner);
          if (operation.recordDestinationHistory) {
            _baselineSaveDestinations[owner] = destination.forBuffer(owner);
          }
        }
        if (resolvedDestination != null) {
          if (resolvedDestination.documentId case final destinationId?) {
            _documentIdsByBuffer[owner] = destinationId;
          }
          _protections[owner] = (
            snapshot: destination.forBuffer(owner),
            reason: LocalHistoryCaptureReason.saved,
            force: false,
            ignoreBinding: resolvedDestination.documentId == null,
            allowPathChange: operation.recordSourceHistory,
            bindResult: true,
            requireVacantPath: resolvedDestination.requireVacantPath,
            expectedTarget: resolvedDestination.expectedTarget,
            captureId: destination.captureId ?? _newPathOperationId(),
          );
        }
        if (_ownerHasRetainedCaptureWork(owner)) {
          _closedBuffers.add(owner);
          _scheduleCheckpoint(owner);
        }
      } else {
        if (operation.recordSourceHistory) {
          final sourceOwner = _newDetachedOwner(
            'history-capture:save-as-source',
          );
          _pending[sourceOwner] = source.forBuffer(sourceOwner);
          if (operation.sourceDocumentId case final documentId?) {
            _documentIdsByBuffer[sourceOwner] = documentId;
          }
          _closedBuffers.add(sourceOwner);
          _scheduleCheckpoint(sourceOwner);
        }
        if (pendingLiveDestinationOwner != null) {
          final destinationOwner = _newDetachedOwner(
            'history-capture:save-as-destination',
          );
          _protections[destinationOwner] = (
            snapshot: destination.forBuffer(destinationOwner),
            reason: LocalHistoryCaptureReason.saved,
            force: false,
            ignoreBinding: true,
            allowPathChange: false,
            bindResult: true,
            requireVacantPath: false,
            expectedTarget: null,
            captureId: destination.captureId ?? _newPathOperationId(),
          );
          _closedBuffers.add(destinationOwner);
          _scheduleCheckpoint(destinationOwner);
        } else if (resolvedDestination != null) {
          final destinationOwner = _newDetachedOwner(
            'history-capture:save-as-destination',
          );
          if (resolvedDestination.documentId case final destinationId?) {
            _documentIdsByBuffer[destinationOwner] = destinationId;
          }
          _protections[destinationOwner] = (
            snapshot: destination.forBuffer(destinationOwner),
            reason: LocalHistoryCaptureReason.saved,
            force: false,
            ignoreBinding: resolvedDestination.documentId == null,
            allowPathChange: false,
            bindResult: true,
            requireVacantPath: resolvedDestination.requireVacantPath,
            expectedTarget: resolvedDestination.expectedTarget,
            captureId: destination.captureId ?? _newPathOperationId(),
          );
          _closedBuffers.add(destinationOwner);
          _scheduleCheckpoint(destinationOwner);
        }
      }
      _pendingSaveAsOperations.remove(operation.operationId);
      _retiredDurableWorkOwnerIds.add(operation.operationId);
      await _persistDurableStateNow();
      return;
    }
  }

  LocalHistoryRetainedSnapshot? _retainedSnapshot(
    LocalHistoryBufferSnapshot? snapshot,
  ) => snapshot == null
      ? null
      : LocalHistoryRetainedSnapshot(
          displayName: snapshot.displayName,
          source: snapshot.text,
          format: snapshot.format,
          revision: snapshot.revision,
          path: snapshot.path,
          untitled: snapshot.untitled,
          captureId: snapshot.captureId,
          acceptedClearEpoch: snapshot.acceptedClearEpoch,
          acceptedAt: snapshot.acceptedAt,
          acceptedDocumentId: snapshot.acceptedDocumentId,
          remoteNote: snapshot.remoteNote,
        );

  LocalHistoryBufferSnapshot _restoreRetainedSnapshot(
    String owner,
    LocalHistoryRetainedSnapshot snapshot,
  ) => LocalHistoryBufferSnapshot(
    bufferId: owner,
    displayName: snapshot.displayName,
    text: snapshot.source,
    format: snapshot.format,
    revision: snapshot.revision,
    path: snapshot.path,
    untitled: snapshot.untitled,
    captureId: snapshot.captureId,
    acceptedClearEpoch: snapshot.acceptedClearEpoch,
    acceptedAt: snapshot.acceptedAt,
    acceptedDocumentId: snapshot.acceptedDocumentId,
    remoteNote: snapshot.remoteNote,
  );

  LocalHistoryRetainedProtection? _retainedProtection(
    ({
      LocalHistoryBufferSnapshot snapshot,
      LocalHistoryCaptureReason reason,
      bool force,
      bool ignoreBinding,
      bool allowPathChange,
      bool bindResult,
      bool requireVacantPath,
      LocalHistoryPathTarget? expectedTarget,
      String? captureId,
    })?
    protection,
  ) => protection == null
      ? null
      : LocalHistoryRetainedProtection(
          snapshot: _retainedSnapshot(protection.snapshot)!,
          reason: protection.reason,
          force: protection.force,
          ignoreBinding: protection.ignoreBinding,
          allowPathChange: protection.allowPathChange,
          bindResult: protection.bindResult,
          requireVacantPath: protection.requireVacantPath,
          expectedTarget: protection.expectedTarget,
          captureId: protection.captureId,
        );

  List<LocalHistoryRetainedCapture> get retainedDetachedCaptures =>
      List.unmodifiable([
        for (final owner in _workOwners)
          if (owner.startsWith('history-capture:') ||
              owner.startsWith('history-promotion:'))
            LocalHistoryRetainedCapture(
              ownerId: owner,
              documentId: _documentIdsByBuffer[owner],
              baseline: _retainedSnapshot(_baselines[owner]),
              pending: _retainedSnapshot(_pending[owner]),
              baselineSaveDestination: _retainedSnapshot(
                _baselineSaveDestinations[owner],
              ),
              protection: _retainedProtection(_protections[owner]),
              baselineRequiresVacantPath: _baselinesRequiringVacantPath
                  .contains(owner),
            ),
      ]);

  void restoreRetainedDetachedCaptures(
    Iterable<LocalHistoryRetainedCapture> captures,
  ) {
    final currentPolicy = policy;
    for (final capture in captures) {
      final owner = capture.ownerId;
      if (_retiredDurableWorkOwnerIds.contains(owner)) continue;
      if (operationOwnerIsLiveOtherProcess(owner)) {
        _externallyOwnedRetainedCaptures[owner] = capture;
        continue;
      }
      if (!currentPolicy.recordingEnabled) {
        _retiredDurableWorkOwnerIds.add(owner);
        continue;
      }
      if (_hasOutstandingWork(owner)) continue;
      if (capture.documentId case final documentId?) {
        _documentIdsByBuffer[owner] = documentId;
      }
      if (capture.baseline case final snapshot?) {
        _baselines[owner] = _restoreRetainedSnapshot(owner, snapshot);
        if (capture.baselineRequiresVacantPath) {
          _baselinesRequiringVacantPath.add(owner);
        }
      }
      if (capture.pending case final snapshot?) {
        _pending[owner] = _restoreRetainedSnapshot(owner, snapshot);
      }
      if (capture.baselineSaveDestination case final snapshot?) {
        _baselineSaveDestinations[owner] = _restoreRetainedSnapshot(
          owner,
          snapshot,
        );
      }
      if (capture.protection case final protection?) {
        _protections[owner] = (
          snapshot: _restoreRetainedSnapshot(owner, protection.snapshot),
          reason: protection.reason,
          force: protection.force,
          ignoreBinding: protection.ignoreBinding,
          allowPathChange: protection.allowPathChange,
          bindResult: protection.bindResult,
          requireVacantPath: protection.requireVacantPath,
          expectedTarget: protection.expectedTarget,
          captureId: protection.captureId,
        );
      }
      _removeExcludedCaptureSides(owner);
      if (_hasOutstandingWork(owner)) {
        _closedBuffers.add(owner);
        _scheduleCheckpoint(owner);
      }
    }
  }

  bool hasPendingIdentityPromotion(String bufferId) =>
      _pendingUntitledPromotions.containsKey(bufferId);

  void restorePendingIdentityPromotion(
    LocalHistoryPendingIdentityPromotion promotion,
  ) {
    final durableOwner = _promotionDurableOwner(promotion);
    if (_retiredDurableWorkOwnerIds.contains(durableOwner)) return;
    if (operationOwnerIsLiveOtherProcess(durableOwner)) {
      _externallyOwnedPromotions[durableOwner] = promotion;
      return;
    }
    var owner = promotion.bufferId;
    final existing = _pendingUntitledPromotions[owner];
    if (existing != null && _promotionDurableOwner(existing) != durableOwner) {
      owner = durableOwner;
      promotion = promotion.forBuffer(owner);
    }
    _documentIdsByBuffer[owner] = promotion.documentId;
    _pendingUntitledPromotions[owner] = promotion;
  }

  String _promotionDurableOwner(
    LocalHistoryPendingIdentityPromotion promotion,
  ) => promotion.operationOwnerId ?? promotion.bufferId;

  Future<bool> restorePendingPathReconciliations(
    Iterable<LocalHistoryPathReconciliation> reconciliations,
  ) async {
    for (final reconciliation in reconciliations) {
      if (_pendingPathOperations.any(
        (operation) => operation.matches(reconciliation),
      )) {
        continue;
      }
      if (_retiredPathOperationIds.contains(reconciliation.operationId)) {
        continue;
      }
      _pendingPathOperations.add(
        _LocalHistoryPathOperation.fromReconciliation(reconciliation),
      );
      if (reconciliation.phase ==
          LocalHistoryPathReconciliationPhase.committed) {
        final operation = _pendingPathOperations.last;
        if (operation case final _LocalHistoryPathRemap remap) {
          final owners = _ownersAssociatedWithPath(remap.sourcePath);
          operation.affectedOwners.addAll(owners);
          _remapRetainedAssociations(
            remap.sourcePath,
            remap.destinationPath,
            owners: owners,
          );
        }
      }
    }
    if (_pendingPathOperations.isEmpty) return true;
    for (final operation in _pendingPathOperations.where(
      (op) => !op.committed,
    )) {
      operation
        ..retryable = false
        ..errorDetail = 'Filesystem outcome requires reconciliation.';
    }
    _showCaptureFailure();
    final settled = await _enqueue(
      _pathRemapOwner,
      _settlePendingPathOperations,
    );
    if (!settled) _scheduleCheckpoint(_pathRemapOwner);
    return settled;
  }

  Future<bool> flushBuffer(DocumentBuffer buffer) async {
    _settling++;
    try {
      _checkpointTimers.remove(buffer.id)?.cancel();
      await _enqueue(buffer.id, () => _settleBufferWork(buffer.id));
      // Include work accepted while settlement was awaiting storage. It is
      // owned by the queue even before observeEdit installs its checkpoint.
      await _bufferQueues[buffer.id];
      return !_hasOutstandingWork(buffer.id);
    } finally {
      _settling--;
      for (final id in _workOwners) {
        _scheduleCheckpoint(id);
      }
    }
  }

  Future<bool> flushPendingIdentityPromotions() async {
    _settling++;
    try {
      await _drainQueues();
      final owners = {
        ..._pendingUntitledPromotions.keys,
        ..._baselineSaveDestinations.keys,
      };
      for (final bufferId in owners) {
        _checkpointTimers.remove(bufferId)?.cancel();
        await _enqueue(bufferId, () => _settleBufferWork(bufferId));
        await _bufferQueues[bufferId];
      }
      await _drainQueues();
      return owners.every((id) => !_hasOutstandingWork(id)) &&
          _pendingUntitledPromotions.isEmpty &&
          _baselineSaveDestinations.isEmpty;
    } finally {
      _settling--;
      for (final id in _workOwners) {
        _scheduleCheckpoint(id);
      }
    }
  }

  Future<bool> flushAll(Iterable<DocumentBuffer> buffers) async {
    _settling++;
    try {
      for (final timer in _checkpointTimers.values) {
        timer.cancel();
      }
      _checkpointTimers.clear();
      if (!await _settlePendingClearOperations()) return false;
      // Drain accepted work once; timers are suspended for the entire flush.
      await _drainQueues();
      final owners = {...buffers.map((b) => b.id), ..._workOwners};
      for (final id in owners) {
        await _enqueue(id, () => _settleBufferWork(id));
      }
      await _drainQueues();
      return _workOwners.isEmpty &&
          _pendingSaveAsOperations.isEmpty &&
          _pendingClearOperations.isEmpty;
    } finally {
      _settling--;
      for (final id in _workOwners) {
        _scheduleCheckpoint(id);
      }
    }
  }

  Set<String> get _workOwners => {
    ..._baselines.keys,
    ..._baselineSaveDestinations.keys,
    ..._pending.keys,
    ..._protections.keys,
    ..._pendingUntitledPromotions.keys,
    ..._bufferQueues.keys,
    if (_pendingPathOperations.isNotEmpty) _pathRemapOwner,
    for (final operation in _pendingPathOperations) ...operation.affectedOwners,
  };

  bool _hasOutstandingWork(String id) => _workOwners.contains(id);

  Future<void> _drainQueues() async {
    while (ref.mounted && _bufferQueues.isNotEmpty) {
      await Future.wait(_bufferQueues.values.toList());
    }
  }

  Future<void> _settleBufferWork(
    String id, {
    bool automatic = false,
    bool allowDuringPathTransition = false,
  }) async {
    if (id == _pathRemapOwner) {
      if (!automatic || _hasRetryableWork(id)) {
        await _settlePendingPathOperations(automatic: automatic);
      }
      return;
    }
    if (_pathOperationBlocksOwner(id) &&
        !await _enqueue(_pathRemapOwner, _settlePendingPathOperations)) {
      return;
    }
    final historyGeneration = _historyGeneration;
    final bufferGeneration = _bufferGeneration(id);
    bool current() =>
        _operationIsCurrent(id, historyGeneration, bufferGeneration);
    final baseline = _baselines[id];
    if (automatic && !_hasRetryableWork(id)) return;
    if (baseline != null &&
        !await _capture(
          baseline,
          LocalHistoryCaptureReason.baseline,
          acceptedHistoryGeneration: historyGeneration,
          acceptedBufferGeneration: bufferGeneration,
        )) {
      return;
    }
    if (!current()) return;
    if (!await _completePendingUntitledPromotion(
      id,
      acceptedHistoryGeneration: historyGeneration,
      acceptedBufferGeneration: bufferGeneration,
    )) {
      return;
    }
    if (!current()) return;
    var protection = _protections[id];
    if (protection != null &&
        protection.reason == LocalHistoryCaptureReason.saved &&
        id.startsWith('history-capture:save-as-destination')) {
      try {
        final binding = await _resolveSaveAsDestinationBinding(
          protection.snapshot,
          stagedTarget: protection.expectedTarget,
          allowedDocumentId: _documentIdsByBuffer[id],
        );
        if (binding.documentId case final documentId?) {
          _documentIdsByBuffer[id] = documentId;
        } else {
          _documentIdsByBuffer.remove(id);
        }
        protection = (
          snapshot: protection.snapshot,
          reason: protection.reason,
          force: protection.force,
          ignoreBinding: binding.documentId == null,
          allowPathChange: protection.allowPathChange,
          bindResult: protection.bindResult,
          requireVacantPath: binding.requireVacantPath,
          expectedTarget: binding.expectedTarget,
          captureId: protection.captureId,
        );
        _protections[id] = protection;
      } on Object {
        // The normal capture path records and owns the reconciliation warning.
      }
    }
    if (protection != null &&
        (!automatic ||
            _failure(id, _LocalHistoryFailureStage.protection)?.retryable !=
                false) &&
        !await _capture(
          protection.snapshot,
          protection.reason,
          force: protection.force,
          ignoreBinding: protection.ignoreBinding,
          allowPathChange: protection.allowPathChange,
          bindResult: protection.bindResult,
          requireVacantPath: protection.requireVacantPath,
          expectedTarget: protection.expectedTarget,
          retainedProtection: true,
          captureId: protection.captureId,
          acceptedHistoryGeneration: historyGeneration,
          acceptedBufferGeneration: bufferGeneration,
        )) {
      return;
    }
    if (!current()) return;
    final pending = _pending[id];
    if (pending != null &&
        (!automatic ||
            _failure(id, _LocalHistoryFailureStage.checkpoint)?.retryable !=
                false)) {
      await _capturePending(
        id,
        pending,
        allowDuringPathTransition: allowDuringPathTransition,
        acceptedHistoryGeneration: historyGeneration,
        acceptedBufferGeneration: bufferGeneration,
      );
    }
  }

  /// Keeps unresolved history work owned by this session after its editor tab
  /// closes. Retryable work continues on the checkpoint cadence; all pending
  /// work remains part of [flushAll] shutdown settlement.
  Future<void> handleBufferClosed(
    String bufferId, {
    required bool historySettled,
  }) async {
    final durableBefore = _durableStateFingerprint();
    _closedBuffers.add(bufferId);
    // The caller's result describes an earlier instant. Accepted work may
    // have arrived since then, so retirement uses the actual owned work.
    if (!_hasOutstandingWork(bufferId)) {
      _retireClosedBuffer(bufferId);
    } else {
      final detached = _detachClosedBufferWork(bufferId);
      _scheduleCheckpoint(detached);
    }
    _showCaptureFailure();
    await _persistDurableStateIfChanged(durableBefore);
  }

  String _detachClosedBufferWork(String bufferId) {
    final detached = _newDetachedOwner('history-capture:closed:$bufferId');
    void moveSnapshot(Map<String, LocalHistoryBufferSnapshot> values) {
      final snapshot = values.remove(bufferId);
      if (snapshot != null) values[detached] = snapshot.forBuffer(detached);
    }

    moveSnapshot(_pending);
    moveSnapshot(_baselines);
    if (_baselinesRequiringVacantPath.remove(bufferId)) {
      _baselinesRequiringVacantPath.add(detached);
    }
    moveSnapshot(_baselineSaveDestinations);
    final protection = _protections.remove(bufferId);
    if (protection != null) {
      _protections[detached] = (
        snapshot: protection.snapshot.forBuffer(detached),
        reason: protection.reason,
        force: protection.force,
        ignoreBinding: protection.ignoreBinding,
        allowPathChange: protection.allowPathChange,
        bindResult: protection.bindResult,
        requireVacantPath: protection.requireVacantPath,
        expectedTarget: protection.expectedTarget,
        captureId: protection.captureId,
      );
    }
    final promotion = _pendingUntitledPromotions.remove(bufferId);
    if (promotion != null) {
      _pendingUntitledPromotions[detached] = promotion.forBuffer(detached);
      _retiredDurableWorkOwnerIds.add(bufferId);
    }
    final failures = _captureFailures.remove(bufferId);
    if (failures != null) _captureFailures[detached] = failures;
    final documentId = _documentIdsByBuffer.remove(bufferId);
    if (documentId != null) _documentIdsByBuffer[detached] = documentId;
    _transferPathOperationOwner(bufferId, detached);
    _checkpointTimers.remove(bufferId)?.cancel();
    _closedBuffers
      ..remove(bufferId)
      ..add(detached);
    return detached;
  }

  /// Transfers already-accepted work away from a live editor owner after the
  /// filesystem path has disappeared. The detached owner is session-durable,
  /// so a crash between path reconciliation and retry cannot discard the only
  /// protective copy.
  void retainBufferWorkAfterCommittedPathLoss(String bufferId) {
    if (_ownerHasRetainedCaptureWork(bufferId)) {
      final documentId = _documentIdsByBuffer[bufferId];
      _detachClosedBufferWork(bufferId);
      // The retained protection needs an independent retry owner, but the
      // still-open recovery editor continues to represent the same deleted
      // lineage. Keep that stable identity in its session entry so a restart
      // cannot create a second live history owner for the missing pathname.
      if (documentId != null) _documentIdsByBuffer[bufferId] = documentId;
    }
  }

  void _retireClosedBuffer(String id) {
    _invalidateBufferWork(id);
    _documentIdsByBuffer.remove(id);
    _closedBuffers.remove(id);
    if (id.startsWith('history-capture:') ||
        id.startsWith('history-promotion:')) {
      _retiredDurableWorkOwnerIds.add(id);
    }
  }

  Future<List<LocalHistoryPathTarget>> preparePathReconciliation(
    String path, {
    required bool recursive,
  }) async {
    await _settlePathSourceWork(path, allowDuringPathTransition: true);
    return _targetsAtProjectedPath(path, recursive: recursive);
  }

  String _newPathOperationId() =>
      '$_operationOwnerToken-${++_pathOperationSerial}';

  String _newDetachedOwner(String prefix) =>
      '$prefix:$_operationOwnerToken:${++_detachedCaptureOwner}';

  bool _operationOwnerIsDefinitelyDead(String operationId) =>
      operationOwnerIsDefinitelyDead(operationId);

  bool operationOwnerIsDefinitelyDead(String operationId) {
    final token = _operationToken(operationId);
    if (token != null && _liveOperationOwners.contains(token)) return false;
    final ownerPid = _operationPid(operationId);
    if (ownerPid == null) return false;
    if (ownerPid == pid) return token != null;
    if (!_processIsLive(ownerPid)) return true;
    if (!Platform.isLinux) return false;
    final expectedStart = _operationProcessStartIdentity(operationId);
    if (expectedStart == null || expectedStart == 0) return true;
    return _readLinuxProcessStartIdentity(ownerPid) != expectedStart;
  }

  bool operationOwnerIsLiveOtherProcess(String operationId) {
    final token = _operationToken(operationId);
    if (token == _operationOwnerToken) return false;
    if (token != null && _liveOperationOwners.contains(token)) return true;
    final ownerPid = _operationPid(operationId);
    if (ownerPid == null || ownerPid == pid || !_processIsLive(ownerPid)) {
      return false;
    }
    if (!Platform.isLinux) return true;
    final expectedStart = _operationProcessStartIdentity(operationId);
    return expectedStart != null &&
        expectedStart != 0 &&
        _readLinuxProcessStartIdentity(ownerPid) == expectedStart;
  }

  String? _operationToken(String operationId) => RegExp(
    r'(?:^|:)(lh[0-9]+_[0-9]+_[0-9]+)(?=[:-])',
  ).firstMatch(operationId)?.group(1);

  int? _operationPid(String operationId) {
    final modern = RegExp(
      r'(?:^|:)(?:lh)([0-9]+)_[0-9]+_[0-9]+(?:-|:)',
    ).firstMatch(operationId);
    if (modern != null) return int.tryParse(modern.group(1)!);
    final colonParts = operationId.split(':');
    if (colonParts.length >= 3) {
      return int.tryParse(colonParts[colonParts.length - 3]);
    }
    return int.tryParse(operationId.split('-').first);
  }

  int? _operationProcessStartIdentity(String operationId) {
    final token = _operationToken(operationId);
    if (token == null) return null;
    return int.tryParse(token.split('_')[1]);
  }

  int? _readLinuxProcessStartIdentity(int processId) {
    if (!Platform.isLinux) return null;
    try {
      final stat = File('/proc/$processId/stat').readAsStringSync();
      final commandEnd = stat.lastIndexOf(') ');
      if (commandEnd < 0) return null;
      final fields = stat.substring(commandEnd + 2).trim().split(' ');
      // The suffix begins with field 3 (`state`); process start time is field
      // 22, expressed as clock ticks since boot.
      return fields.length > 19 ? int.tryParse(fields[19]) : null;
    } on Object {
      return null;
    }
  }

  bool _processIsLive(int processId) {
    if (Platform.isLinux) return Directory('/proc/$processId').existsSync();
    if (Platform.isMacOS) {
      return Process.runSync('kill', ['-0', '$processId']).exitCode == 0;
    }
    if (Platform.isWindows) {
      final result = Process.runSync('tasklist', [
        '/FI',
        'PID eq $processId',
        '/NH',
      ]);
      return result.exitCode == 0 &&
          result.stdout.toString().contains('$processId');
    }
    return false;
  }

  Future<T> runStagedPathRemap<T>({
    required String sourcePath,
    required String destinationPath,
    Iterable<LocalHistoryPathTarget>? preparedTargets,
    String? boundBufferId,
    required Future<T> Function() filesystemOperation,
    required bool Function(T result) didCommit,
    Future<bool> Function()? committedAfterError,
    void Function(String? operationId)? onOperationStaged,
    bool filesystemAlreadyCommitted = false,
  }) => _runStagedPathOperation(
    kind: LocalHistoryPathReconciliationKind.remap,
    sourcePath: sourcePath,
    destinationPath: destinationPath,
    recursive: true,
    preparedTargets: preparedTargets,
    boundBufferId: boundBufferId,
    filesystemOperation: filesystemOperation,
    didCommit: didCommit,
    committedAfterError: committedAfterError,
    onOperationStaged: onOperationStaged,
    filesystemAlreadyCommitted: filesystemAlreadyCommitted,
  );

  Future<T> runStagedPathDeletion<T>({
    required String path,
    required bool recursive,
    Iterable<LocalHistoryPathTarget>? preparedTargets,
    String? boundBufferId,
    required Future<T> Function() filesystemOperation,
    required bool Function(T result) didCommit,
    Future<bool> Function()? committedAfterError,
    String? commitEvidenceOperationId,
    void Function(String? operationId)? onOperationStaged,
    bool filesystemAlreadyCommitted = false,
  }) => _runStagedPathOperation(
    kind: LocalHistoryPathReconciliationKind.deletion,
    sourcePath: path,
    recursive: recursive,
    preparedTargets: preparedTargets,
    boundBufferId: boundBufferId,
    filesystemOperation: filesystemOperation,
    didCommit: didCommit,
    committedAfterError: committedAfterError,
    commitEvidenceOperationId: commitEvidenceOperationId,
    onOperationStaged: onOperationStaged,
    filesystemAlreadyCommitted: filesystemAlreadyCommitted,
  );

  Future<T> _runStagedPathOperation<T>({
    required LocalHistoryPathReconciliationKind kind,
    required String sourcePath,
    String? destinationPath,
    required bool recursive,
    Iterable<LocalHistoryPathTarget>? preparedTargets,
    String? boundBufferId,
    required Future<T> Function() filesystemOperation,
    required bool Function(T result) didCommit,
    Future<bool> Function()? committedAfterError,
    String? commitEvidenceOperationId,
    void Function(String? operationId)? onOperationStaged,
    bool filesystemAlreadyCommitted = false,
    bool retryAfterPreflightRefresh = true,
  }) async {
    final normalizedSource = p.normalize(sourcePath);
    final normalizedDestination = destinationPath == null
        ? null
        : p.normalize(destinationPath);
    final frozenPreparedTargets = preparedTargets?.toList(growable: false);
    // Settle namespace and explicitly frozen identity dependencies before
    // resolving current path owners. Those predecessors can move an identity
    // away from this path, making a later operation on it independent.
    if (!await _settlePathOperationDependencies(
      _LocalHistoryPathScope(
        kind: kind,
        sourcePath: normalizedSource,
        destinationPath: normalizedDestination,
        recursive: recursive,
        targets: frozenPreparedTargets ?? const [],
        documentIds: {
          if (boundBufferId != null)
            if (_documentIdsByBuffer[boundBufferId] case final documentId?)
              documentId,
        },
        ownerIds: {if (boundBufferId != null) boundBufferId},
      ),
    )) {
      throw const LocalHistoryStorageException(
        'An earlier Local History path reconciliation is still pending.',
      );
    }
    final dependencyOwners = <String>{
      ..._ownersAssociatedWithPath(normalizedSource),
      if (normalizedDestination != null)
        ..._ownersAssociatedWithPath(normalizedDestination),
      if (boundBufferId != null) boundBufferId,
    };
    final dependencyTargets = <LocalHistoryPathTarget>[
      ...?frozenPreparedTargets,
      ...await _store.resolvePathTargets(
        normalizedSource,
        recursive: recursive,
      ),
      if (normalizedDestination != null)
        ...await _store.resolvePathTargets(
          normalizedDestination,
          recursive: recursive,
        ),
    ];
    final dependencyScope = _LocalHistoryPathScope(
      kind: kind,
      sourcePath: normalizedSource,
      destinationPath: normalizedDestination,
      recursive: recursive,
      targets: dependencyTargets,
      documentIds: {
        for (final owner in dependencyOwners)
          if (_documentIdsByBuffer[owner] case final documentId?) documentId,
      },
      ownerIds: dependencyOwners,
    );
    if (!await _settlePathOperationDependencies(dependencyScope)) {
      throw const LocalHistoryStorageException(
        'An earlier Local History path reconciliation is still pending.',
      );
    }
    final boundDocumentIdAtEntry = boundBufferId == null
        ? null
        : _documentIdsByBuffer[boundBufferId];
    final settlementOwners = <String>{
      ..._ownersAssociatedWithPath(normalizedSource),
      if (boundBufferId != null) boundBufferId,
    };
    final ownerBindingsAtEntry = {
      for (final owner in settlementOwners) owner: _documentIdsByBuffer[owner],
    };
    await _settlePathSourceWork(
      normalizedSource,
      allowDuringPathTransition: true,
    );
    final newlyBoundDocumentIds = <String>{};
    for (final owner in settlementOwners) {
      final documentId = _documentIdsByBuffer[owner];
      if (ownerBindingsAtEntry[owner] == null && documentId != null) {
        newlyBoundDocumentIds.add(documentId);
      }
    }
    final boundDocumentIdAfterSettlement = boundBufferId == null
        ? null
        : _documentIdsByBuffer[boundBufferId];
    final boundTargetsAfterSettlement = boundBufferId == null
        ? null
        : boundDocumentIdAtEntry == null &&
              boundDocumentIdAfterSettlement == null &&
              filesystemAlreadyCommitted
        ? const <LocalHistoryPathTarget>[]
        : boundDocumentIdAtEntry == null &&
              boundDocumentIdAfterSettlement == null
        ? null
        : boundPathReconciliationTargets(
                boundBufferId,
                normalizedSource,
                recursive: recursive,
              )
              .where(
                (target) =>
                    target.documentId ==
                    (boundDocumentIdAtEntry ?? boundDocumentIdAfterSettlement),
              )
              .toList(growable: false);
    var effectiveTargets = boundTargetsAfterSettlement ?? frozenPreparedTargets;
    if (frozenPreparedTargets != null &&
        (boundBufferId == null || boundDocumentIdAtEntry == null)) {
      final prepared = frozenPreparedTargets;
      final current = await _store.resolvePathTargets(
        normalizedSource,
        recursive: recursive,
      );
      final preparedById = {
        for (final target in prepared) target.documentId: target,
      };
      if (current.every((target) {
        final prior = preparedById[target.documentId];
        return (prior != null &&
                p.equals(prior.expectedPath, target.expectedPath)) ||
            newlyBoundDocumentIds.contains(target.documentId);
      })) {
        // Source settlement may advance the exact lineage that was frozen at
        // the filesystem event boundary. Rebase those same IDs and paths,
        // retaining absent targets so an operation already applied by another
        // process remains idempotent. A replacement has a different ID and
        // therefore still conflicts atomically in the store.
        final currentById = {
          for (final target in current) target.documentId: target,
        };
        effectiveTargets = [
          for (final prior in prepared) currentById[prior.documentId] ?? prior,
          for (final target in current)
            if (!preparedById.containsKey(target.documentId) &&
                newlyBoundDocumentIds.contains(target.documentId))
              target,
        ];
      }
    }
    _LocalHistoryPathOperation? staged;
    var filesystemCallStarted = false;
    var filesystemCommitted = false;
    late T result;
    try {
      result = await _store.runPathReconciliation<T>(
        kind: kind,
        sourcePath: normalizedSource,
        destinationPath: normalizedDestination,
        recursive: recursive,
        preparedTargets: effectiveTargets,
        operation: (targets) async {
          final owners = _ownersAssociatedWithPath(normalizedSource);
          // Source settlement can bind a previously unknown identity, and
          // another caller can queue work while the store lock is awaited.
          // Recheck the actual frozen targets before publishing filesystem
          // changes; reconciliation cannot be retried inside the store lock.
          final actualScope = _LocalHistoryPathScope(
            kind: kind,
            sourcePath: normalizedSource,
            destinationPath: normalizedDestination,
            recursive: recursive,
            targets: [...dependencyTargets, ...targets],
            documentIds: {
              ...dependencyScope.documentIds,
              if (boundBufferId != null)
                if (_documentIdsByBuffer[boundBufferId] case final documentId?)
                  documentId,
            },
            ownerIds: {...dependencyOwners, ...owners},
          );
          if (_pendingPathOperations.any(
            (operation) =>
                !operation.settled &&
                operation.scope.conflictsWith(actualScope),
          )) {
            throw const LocalHistoryStorageException(
              'An earlier Local History path reconciliation is still pending.',
            );
          }
          staged = switch (kind) {
            LocalHistoryPathReconciliationKind.remap => _LocalHistoryPathRemap(
              operationId: _newPathOperationId(),
              committed: false,
              retainUntilAcknowledged: true,
              sourcePath: normalizedSource,
              destinationPath: normalizedDestination!,
              affectedOwners: owners,
              targets: targets,
            ),
            LocalHistoryPathReconciliationKind.deletion =>
              _LocalHistoryPathDeletion(
                operationId: _newPathOperationId(),
                committed: false,
                retainUntilAcknowledged: true,
                path: normalizedSource,
                recursive: recursive,
                affectedOwners: owners,
                targets: targets,
                commitEvidenceOperationId: commitEvidenceOperationId,
              ),
          };
          if (staged!.targets.isEmpty && owners.isEmpty) {
            staged = null;
          } else {
            _pendingPathOperations.add(staged!);
            final preparedPersisted = await _persistDurableStateNow();
            final operation = staged!;
            final stillPrepared =
                _pendingPathOperations.any(
                  (candidate) => identical(candidate, operation),
                ) &&
                operation.phase == LocalHistoryPathReconciliationPhase.prepared;
            if (!preparedPersisted || !stillPrepared) {
              throw const LocalHistoryStorageException(
                'Local History path reconciliation could not be journaled.',
              );
            }
          }
          onOperationStaged?.call(staged?.operationId);
          if (staged case final operation?) {
            operation.phase = LocalHistoryPathReconciliationPhase.executing;
            final executingPersisted = await _persistDurableStateNow();
            final stillExecuting =
                _pendingPathOperations.any(
                  (candidate) => identical(candidate, operation),
                ) &&
                operation.phase ==
                    LocalHistoryPathReconciliationPhase.executing;
            if (!executingPersisted || !stillExecuting) {
              throw const LocalHistoryStorageException(
                'Local History path operation did not start because its '
                'execution journal could not be persisted.',
              );
            }
          }
          filesystemCallStarted = true;
          final value = await filesystemOperation();
          result = value;
          filesystemCommitted = didCommit(value);
          if (filesystemCommitted) {
            final operation = staged;
            if (operation == null) return value;
            if (operation case final _LocalHistoryPathRemap remap) {
              final currentOwners = _ownersAssociatedWithPath(remap.sourcePath);
              operation.affectedOwners.addAll(currentOwners);
              _remapRetainedAssociations(
                remap.sourcePath,
                remap.destinationPath,
                owners: currentOwners,
              );
            }
            operation
              ..phase = LocalHistoryPathReconciliationPhase.committed
              ..retryable = true
              ..errorDetail = null;
            await _persistDurableStateNow();
          }
          return value;
        },
        didCommit: didCommit,
      );
      final operation = staged;
      if (didCommit(result)) {
        if (operation != null) {
          operation.applied = true;
          if (!await refresh()) {
            operation
              ..retryable = true
              ..errorDetail =
                  'Committed Local History reconciliation refresh pending.';
            await _persistDurableStateNow();
            _scheduleCheckpoint(_pathRemapOwner);
            _showCaptureFailure();
          }
        }
      } else if (operation != null) {
        if (_pendingPathOperations.remove(operation)) {
          _rememberRetiredPathOperation(operation.operationId);
          await _persistDurableStateNow();
        }
      }
      return result;
    } on Object catch (error) {
      final operation = staged;
      if (operation != null) {
        var confirmedCommit = filesystemCommitted;
        if (!confirmedCommit && filesystemCallStarted) {
          try {
            confirmedCommit = await committedAfterError?.call() ?? false;
          } on Object {
            confirmedCommit = false;
          }
        }
        final ambiguousRecursiveDeletion =
            !confirmedCommit &&
            filesystemCallStarted &&
            kind == LocalHistoryPathReconciliationKind.deletion &&
            recursive;
        if (confirmedCommit) {
          operation
            ..phase = LocalHistoryPathReconciliationPhase.committed
            ..retryable = true
            ..errorDetail = 'Committed Local History reconciliation pending.';
          try {
            await _persistDurableStateNow();
          } on Object {
            // The earlier prepared/executing journal still preserves recovery.
          }
          final settled = await _enqueue(
            _pathRemapOwner,
            _settlePendingPathOperations,
          );
          if (!settled) _scheduleCheckpoint(_pathRemapOwner);
        } else if (ambiguousRecursiveDeletion) {
          operation
            ..phase = LocalHistoryPathReconciliationPhase.executing
            ..retryable = false
            ..errorDetail =
                'A recursive filesystem deletion stopped before its outcome '
                'could be established.';
          try {
            await _persistDurableStateNow();
          } on Object {
            // The already-persisted executing record retains the ambiguity.
          }
        } else {
          _pendingPathOperations.remove(operation);
          _rememberRetiredPathOperation(operation.operationId);
          try {
            await _persistDurableStateNow();
          } on Object {
            // A persisted prepared record is harmless and cancels on restart.
          }
        }
        if (confirmedCommit || ambiguousRecursiveDeletion) {
          _scheduleCheckpoint(_pathRemapOwner);
          _showCaptureFailure();
        }
        if (confirmedCommit) return result;
      }
      if (operation == null &&
          error is LocalHistoryReconciliationConflict &&
          filesystemAlreadyCommitted) {
        final value = await filesystemOperation();
        if (!didCommit(value)) return value;
        final owners = _ownersAssociatedWithPath(normalizedSource);
        final targets = List<LocalHistoryPathTarget>.unmodifiable(
          effectiveTargets ?? const <LocalHistoryPathTarget>[],
        );
        final retained = switch (kind) {
          LocalHistoryPathReconciliationKind.remap => _LocalHistoryPathRemap(
            operationId: _newPathOperationId(),
            committed: true,
            retainUntilAcknowledged: true,
            sourcePath: normalizedSource,
            destinationPath: normalizedDestination!,
            affectedOwners: owners,
            targets: targets,
          ),
          LocalHistoryPathReconciliationKind.deletion =>
            _LocalHistoryPathDeletion(
              operationId: _newPathOperationId(),
              committed: true,
              retainUntilAcknowledged: true,
              path: normalizedSource,
              recursive: recursive,
              affectedOwners: owners,
              targets: targets,
              commitEvidenceOperationId: commitEvidenceOperationId,
            ),
        };
        retained
          ..phase = LocalHistoryPathReconciliationPhase.committed
          ..retryable = false
          ..errorDetail =
              'Committed Local History reconciliation conflicts with newer '
              'history at the original path.';
        if (retained case final _LocalHistoryPathRemap remap) {
          _remapRetainedAssociations(
            remap.sourcePath,
            remap.destinationPath,
            owners: owners,
          );
        }
        _pendingPathOperations.add(retained);
        onOperationStaged?.call(retained.operationId);
        await _persistDurableStateNow();
        _showCaptureFailure();
        return value;
      }
      if (operation == null &&
          error is LocalHistoryReconciliationConflict &&
          retryAfterPreflightRefresh &&
          boundBufferId != null &&
          preparedTargets == null) {
        await refresh();
        return _runStagedPathOperation(
          kind: kind,
          sourcePath: sourcePath,
          destinationPath: destinationPath,
          recursive: recursive,
          preparedTargets: effectiveTargets,
          boundBufferId: boundBufferId,
          filesystemOperation: filesystemOperation,
          didCommit: didCommit,
          committedAfterError: committedAfterError,
          commitEvidenceOperationId: commitEvidenceOperationId,
          onOperationStaged: onOperationStaged,
          filesystemAlreadyCommitted: filesystemAlreadyCommitted,
          retryAfterPreflightRefresh: false,
        );
      }
      rethrow;
    }
  }

  Future<String?> stagePathRemap(
    String sourcePath,
    String destinationPath, {
    required Iterable<LocalHistoryPathTarget> targets,
  }) async {
    final owners = _ownersAssociatedWithPath(sourcePath);
    final operation = _LocalHistoryPathRemap(
      operationId: _newPathOperationId(),
      committed: false,
      retainUntilAcknowledged: true,
      sourcePath: p.normalize(sourcePath),
      destinationPath: p.normalize(destinationPath),
      affectedOwners: owners,
      targets: targets,
    );
    if (operation.targets.isEmpty && owners.isEmpty) return null;
    _pendingPathOperations.add(operation);
    await _persistDurableStateNow();
    return operation.operationId;
  }

  Future<String?> stagePathDeletion(
    String path, {
    required bool recursive,
    required Iterable<LocalHistoryPathTarget> targets,
  }) async {
    final normalized = p.normalize(path);
    final owners = _ownersAssociatedWithPath(normalized);
    final operation = _LocalHistoryPathDeletion(
      operationId: _newPathOperationId(),
      committed: false,
      retainUntilAcknowledged: true,
      path: normalized,
      recursive: recursive,
      affectedOwners: owners,
      targets: targets,
    );
    if (operation.targets.isEmpty && owners.isEmpty) return null;
    _pendingPathOperations.add(operation);
    await _persistDurableStateNow();
    return operation.operationId;
  }

  Future<void> commitStagedPathOperation(String? operationId) async {
    if (operationId == null) return;
    final operation = _pendingPathOperations
        .where((candidate) => candidate.operationId == operationId)
        .firstOrNull;
    if (operation == null || operation.committed) return;
    if (operation case final _LocalHistoryPathRemap remap) {
      final owners = _ownersAssociatedWithPath(remap.sourcePath);
      operation.affectedOwners.addAll(owners);
      _remapRetainedAssociations(
        remap.sourcePath,
        remap.destinationPath,
        owners: owners,
      );
    }
    operation
      ..phase = LocalHistoryPathReconciliationPhase.committed
      ..retryable = true
      ..errorDetail = null;
    // The committed intent reaches the session before store reconciliation.
    await _persistDurableStateNow();
    final settled = await _enqueue(
      _pathRemapOwner,
      _settlePendingPathOperations,
    );
    if (!settled) _scheduleCheckpoint(_pathRemapOwner);
  }

  Future<void> acknowledgeStagedPathOperation(String? operationId) async {
    if (operationId == null) return;
    final operation = _pendingPathOperations
        .where((candidate) => candidate.operationId == operationId)
        .firstOrNull;
    if (operation == null) return;
    operation.acknowledgementRequested = true;
    if (!operation.applied || operation.errorDetail != null) {
      await _persistDurableStateNow();
      if (operation.retryable) _scheduleCheckpoint(_pathRemapOwner);
      return;
    }
    _pendingPathOperations.remove(operation);
    _rememberRetiredPathOperation(operation.operationId);
    for (final owner in operation.affectedOwners) {
      if (_closedBuffers.contains(owner) && !_hasOutstandingWork(owner)) {
        _retireClosedBuffer(owner);
      } else {
        _scheduleCheckpoint(owner);
      }
    }
    _showCaptureFailure();
    await _persistDurableStateNow();
  }

  Future<void> cancelStagedPathOperation(String? operationId) async {
    if (operationId == null) return;
    final before = _pendingPathOperations.length;
    final removed = _pendingPathOperations
        .where(
          (operation) =>
              operation.operationId == operationId &&
              operation.phase == LocalHistoryPathReconciliationPhase.prepared,
        )
        .toList(growable: false);
    _pendingPathOperations.removeWhere(removed.contains);
    for (final operation in removed) {
      _rememberRetiredPathOperation(operation.operationId);
    }
    if (_pendingPathOperations.length != before) {
      _showCaptureFailure();
      await _persistDurableStateNow();
    }
  }

  List<LocalHistoryPathTarget> boundPathReconciliationTargets(
    String bufferId,
    String path, {
    required bool recursive,
  }) {
    final documentId = _documentIdsByBuffer[bufferId];
    if (documentId == null) return const [];
    final document = state.snapshot.documents
        .where((candidate) => candidate.id == documentId)
        .firstOrNull;
    final currentPath = document?.currentPath;
    if (document == null ||
        document.deleted ||
        currentPath == null ||
        !(p.equals(currentPath, path) ||
            recursive && p.isWithin(path, currentPath))) {
      return const [];
    }
    return [
      LocalHistoryPathTarget(
        documentId: document.id,
        expectedPath: currentPath,
        versionToken: localHistoryDocumentVersionToken(
          document,
          state.snapshot.revisions,
        ),
      ),
    ];
  }

  List<LocalHistoryPathTarget> snapshotPathReconciliationTargets(
    String path, {
    required bool recursive,
  }) => List.unmodifiable([
    for (final document in state.snapshot.documents)
      if (!document.deleted &&
          document.currentPath != null &&
          (p.equals(document.currentPath!, path) ||
              recursive && p.isWithin(path, document.currentPath!)))
        LocalHistoryPathTarget(
          documentId: document.id,
          expectedPath: document.currentPath!,
          versionToken: localHistoryDocumentVersionToken(
            document,
            state.snapshot.revisions,
          ),
        ),
  ]);

  Future<void> _settlePathSourceWork(
    String sourcePath, {
    required bool allowDuringPathTransition,
  }) async {
    while (_bufferQueues.isNotEmpty) {
      await Future.wait(_bufferQueues.values.toList(growable: false));
    }
    final affected = <MapEntry<String, LocalHistoryBufferSnapshot>>[];
    for (final entry in _pending.entries) {
      if (!allowDuringPathTransition &&
          _pathTransitions.containsKey(entry.key)) {
        continue;
      }
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
          allowDuringPathTransition: allowDuringPathTransition,
        ),
      );
      if (captured) _acknowledgePending(entry.key, entry.value.revision);
    }
    final affectedPromotions = _pendingUntitledPromotions.entries
        .where(
          (entry) =>
              p.equals(entry.value.destinationPath, sourcePath) ||
              p.isWithin(sourcePath, entry.value.destinationPath),
        )
        .toList(growable: false);
    for (final entry in affectedPromotions) {
      if (_pathOperationBlocksOwner(entry.key)) continue;
      await _enqueue(
        entry.key,
        () => _completePendingUntitledPromotion(entry.key),
      );
    }
  }

  Future<void> remapPath(
    String sourcePath,
    String destinationPath, {
    Iterable<LocalHistoryPathTarget>? preparedTargets,
    Future<void> Function()? onQueued,
  }) async {
    try {
      // Observe-edit callbacks are queued per buffer. Drain them, then capture
      // pending source-path snapshots before the store remaps their stable
      // document identities. New edits already see the remapped workspace
      // buffer path and remain pending for the destination.
      if (preparedTargets == null) {
        await _settlePathSourceWork(
          sourcePath,
          allowDuringPathTransition: false,
        );
      }
      final affectedOwners = _ownersAssociatedWithPath(sourcePath);
      _remapRetainedAssociations(
        sourcePath,
        destinationPath,
        owners: affectedOwners,
      );
      // Prepared targets describe the exact store owners at the filesystem
      // commit boundary. Never refresh their version tokens afterwards: a
      // replacement capture must conflict instead of being folded into this
      // older move.
      final operationTargets = preparedTargets == null
          ? {
              for (final target in await _targetsAtProjectedPath(
                sourcePath,
                recursive: true,
              ))
                target.documentId: target,
            }
          : {for (final target in preparedTargets) target.documentId: target};
      _queuePathOperation(
        _LocalHistoryPathRemap(
          sourcePath: p.normalize(sourcePath),
          destinationPath: p.normalize(destinationPath),
          affectedOwners: affectedOwners,
          targets: operationTargets.values,
        ),
      );
      await onQueued?.call();
      final settled = await _enqueue(
        _pathRemapOwner,
        _settlePendingPathOperations,
      );
      if (!settled) _scheduleCheckpoint(_pathRemapOwner);
    } on Object catch (error) {
      _setWarning(LocalHistoryWarningKind.pathChange, error.toString());
    }
  }

  Set<String> _ownersAssociatedWithPath(String sourcePath) {
    final owners = <String>{};
    void include(String owner, String? path) {
      if (path != null && _historyPathIsAtOrWithin(path, sourcePath)) {
        owners.add(owner);
      }
    }

    for (final entry in _pending.entries) {
      include(entry.key, entry.value.path);
    }
    for (final entry in _baselines.entries) {
      include(entry.key, entry.value.path);
    }
    for (final entry in _baselineSaveDestinations.entries) {
      include(entry.key, entry.value.path);
    }
    for (final entry in _protections.entries) {
      include(entry.key, entry.value.snapshot.path);
    }
    for (final entry in _pendingUntitledPromotions.entries) {
      include(entry.key, entry.value.destinationPath);
    }
    for (final entry in _inFlightSnapshots.entries) {
      include(entry.key, entry.value.path);
    }
    for (final entry in _pathTransitions.entries) {
      include(entry.key, entry.value.sourcePath);
    }
    for (final entry in _documentIdsByBuffer.entries) {
      final document = state.snapshot.documents
          .where((candidate) => candidate.id == entry.value)
          .firstOrNull;
      include(entry.key, document?.currentPath);
    }
    final scope = _normalBrowsingScope;
    if (scope != null) include(scope.bufferId, scope.path);
    return owners;
  }

  void _remapRetainedAssociations(
    String sourcePath,
    String destinationPath, {
    required Set<String> owners,
  }) {
    LocalHistoryBufferSnapshot? remapSnapshot(
      String owner,
      LocalHistoryBufferSnapshot? snapshot, {
      bool preserveUntitled = false,
    }) {
      if (snapshot == null || !owners.contains(owner)) return snapshot;
      if (preserveUntitled && snapshot.untitled) return snapshot;
      final path = snapshot.path;
      if (path == null) return snapshot;
      final remapped = _remapHistoryPath(path, sourcePath, destinationPath);
      return remapped == null ? snapshot : snapshot.atPath(remapped);
    }

    for (final owner in owners) {
      final pending = remapSnapshot(owner, _pending[owner]);
      if (pending != null) _pending[owner] = pending;
      final baseline = remapSnapshot(
        owner,
        _baselines[owner],
        preserveUntitled: true,
      );
      if (baseline != null) _baselines[owner] = baseline;
      final destination = remapSnapshot(
        owner,
        _baselineSaveDestinations[owner],
      );
      if (destination != null) {
        _baselineSaveDestinations[owner] = destination;
      }
      final protection = _protections[owner];
      final protectedSnapshot = remapSnapshot(
        owner,
        protection?.snapshot,
        preserveUntitled: true,
      );
      if (protection != null && protectedSnapshot != null) {
        _protections[owner] = (
          snapshot: protectedSnapshot,
          reason: protection.reason,
          force: protection.force,
          ignoreBinding: protection.ignoreBinding,
          allowPathChange: protection.allowPathChange,
          bindResult: protection.bindResult,
          requireVacantPath: protection.requireVacantPath,
          expectedTarget: protection.expectedTarget,
          captureId: protection.captureId,
        );
      }
      final promotion = _pendingUntitledPromotions[owner];
      if (promotion != null) {
        final remapped = _remapHistoryPath(
          promotion.destinationPath,
          sourcePath,
          destinationPath,
        );
        if (remapped != null) {
          _pendingUntitledPromotions[owner] = promotion.atPath(remapped);
        }
      }
      final failures = _captureFailures[owner];
      if (failures != null) {
        for (final entry in failures.entries.toList(growable: false)) {
          final displayName = entry.value.displayName;
          if (displayName == null) continue;
          final remapped = _remapHistoryPath(
            displayName,
            sourcePath,
            destinationPath,
          );
          if (remapped != null) {
            failures[entry.key] = entry.value.copyWithDisplayName(remapped);
          }
        }
      }
    }
    final scope = _normalBrowsingScope;
    if (scope != null && owners.contains(scope.bufferId) && !scope.untitled) {
      final remapped = scope.path == null
          ? null
          : _remapHistoryPath(scope.path!, sourcePath, destinationPath);
      if (remapped != null) _normalBrowsingScope = scope.atPath(remapped);
    }
  }

  bool _pathOperationBlocksOwner(String owner, [String? path]) {
    final retainedPaths = <String>{
      if (path != null) path,
      if (_pending[owner]?.path case final value?) value,
      if (_baselines[owner]?.path case final value?) value,
      if (_baselineSaveDestinations[owner]?.path case final value?) value,
      if (_protections[owner]?.snapshot.path case final value?) value,
      if (_pendingUntitledPromotions[owner]?.destinationPath case final value?)
        value,
      if (_inFlightSnapshots[owner]?.path case final value?) value,
    };
    var blocked = false;
    for (final operation in _pendingPathOperations) {
      if (operation.applied) continue;
      if (operation.affectedOwners.contains(owner) ||
          retainedPaths.any(operation.blocksPath)) {
        operation.affectedOwners.add(owner);
        blocked = true;
      }
    }
    return blocked;
  }

  Future<List<LocalHistoryPathTarget>> _targetsAtProjectedPath(
    String path, {
    required bool recursive,
  }) async {
    final normalized = p.normalize(path);
    final candidates = <String, LocalHistoryPathTarget>{
      for (final target in await _store.resolvePathTargets(
        normalized,
        recursive: recursive,
      ))
        target.documentId: target,
      for (final operation in _pendingPathOperations)
        for (final target in operation.targets.values)
          target.documentId: target,
    };
    final result = <String, LocalHistoryPathTarget>{};
    for (final target in candidates.values) {
      var projectedPath = target.expectedPath;
      var projectedDeleted = false;
      for (final operation in _pendingPathOperations) {
        if (!operation.documentIds.contains(target.documentId)) continue;
        switch (operation) {
          case _LocalHistoryPathRemap():
            projectedPath =
                _remapHistoryPath(
                  projectedPath,
                  operation.sourcePath,
                  operation.destinationPath,
                ) ??
                projectedPath;
          case _LocalHistoryPathDeletion():
            if (operation.blocksPath(projectedPath)) projectedDeleted = true;
        }
      }
      if (!projectedDeleted &&
          (p.equals(projectedPath, normalized) ||
              recursive && p.isWithin(normalized, projectedPath))) {
        result[target.documentId] = target.atPath(projectedPath);
      }
    }
    return List.unmodifiable(result.values);
  }

  void _queuePathOperation(_LocalHistoryPathOperation operation) {
    if (operation.targets.isNotEmpty || operation.affectedOwners.isNotEmpty) {
      _pendingPathOperations.add(operation);
    }
  }

  void _rememberRetiredPathOperation(String operationId) {
    if (operationId.isNotEmpty) _retiredPathOperationIds.add(operationId);
  }

  Future<bool> _settlePathOperationDependencies(_LocalHistoryPathScope scope) {
    if (_pendingPathOperations.isEmpty) return Future.value(true);
    return _enqueue(
      _pathRemapOwner,
      () => _settlePendingPathOperations(requiredBy: scope),
    );
  }

  Future<bool> _settlePromotionPathDependencies(
    String bufferId,
    String? documentId,
    String destinationPath,
  ) async {
    if (_pendingPathOperations.isEmpty) return true;
    if (!await _settlePathOperationDependencies(
      _LocalHistoryPathScope(
        kind: LocalHistoryPathReconciliationKind.deletion,
        sourcePath: destinationPath,
        recursive: false,
        documentIds: {if (documentId != null) documentId},
        ownerIds: {bufferId},
      ),
    )) {
      return false;
    }
    if (_pendingPathOperations.isEmpty) return true;
    return _settlePathOperationDependencies(
      _LocalHistoryPathScope(
        kind: LocalHistoryPathReconciliationKind.deletion,
        sourcePath: destinationPath,
        recursive: false,
        targets: await _store.resolvePathTargets(
          destinationPath,
          recursive: false,
        ),
        documentIds: {if (documentId != null) documentId},
        ownerIds: {bufferId},
      ),
    );
  }

  Future<bool> _settlePendingPathOperations({
    _LocalHistoryPathScope? requiredBy,
    bool automatic = false,
  }) async {
    final queued = _pendingPathOperations.toList(growable: false);
    final required = <_LocalHistoryPathOperation>{};
    if (requiredBy != null) {
      // Include transitive prerequisites, in reverse queue order. A later
      // operation must never overtake an unresolved predecessor on which it
      // depends, even when that predecessor does not touch the new operation.
      final scopes = [requiredBy];
      for (final operation in queued.reversed) {
        if (!operation.settled && scopes.any(operation.scope.conflictsWith)) {
          required.add(operation);
          scopes.add(operation.scope);
        }
      }
    }
    for (final operation in queued) {
      if (requiredBy != null && !required.contains(operation)) continue;
      final index = _pendingPathOperations.indexOf(operation);
      if (index < 0) continue;
      if (automatic && !operation.retryable) continue;
      if (_pendingPathOperations
          .take(index)
          .any(
            (earlier) =>
                !earlier.settled &&
                earlier.scope.conflictsWith(operation.scope),
          )) {
        continue;
      }
      if (!operation.committed) continue;
      if (operation.settled &&
          operation.retainUntilAcknowledged &&
          !operation.acknowledgementRequested) {
        continue;
      }
      if (!operation.applied) {
        try {
          await operation.apply(_store);
        } on Object catch (error) {
          if (_pendingPathOperations.contains(operation)) {
            operation.retryable = _captureErrorIsRetryable(error);
            operation.errorDetail = error.toString();
            _showCaptureFailure();
            if (operation.retryable) _scheduleCheckpoint(_pathRemapOwner);
          }
          continue;
        }
      }
      if (!_pendingPathOperations.contains(operation)) continue;
      operation
        ..applied = true
        ..retryable = true
        ..errorDetail = null;
      _showCaptureFailure();
      if (!await refresh()) {
        if (_pendingPathOperations.contains(operation)) {
          operation.errorDetail =
              'Committed Local History reconciliation refresh pending.';
          _scheduleCheckpoint(_pathRemapOwner);
        }
        continue;
      }
      _rebaseQueuedPathTargetsAfter(operation);
      if (operation is _LocalHistoryPathDeletion) {
        for (final owner in operation.affectedOwners.toList(growable: false)) {
          if (_documentIdsByBuffer[owner] == null &&
              _ownerHasRetainedCaptureWork(owner)) {
            _detachClosedBufferWork(owner);
          }
        }
      }
      if (operation.retainUntilAcknowledged &&
          !operation.acknowledgementRequested) {
        continue;
      }
      _pendingPathOperations.remove(operation);
      _rememberRetiredPathOperation(operation.operationId);
      for (final owner in operation.affectedOwners) {
        if (_closedBuffers.contains(owner) && !_hasOutstandingWork(owner)) {
          _retireClosedBuffer(owner);
        } else {
          _scheduleCheckpoint(owner);
        }
      }
    }
    return (requiredBy == null ? _pendingPathOperations : required).every(
      (operation) =>
          !_pendingPathOperations.contains(operation) || operation.settled,
    );
  }

  void _rebaseQueuedPathTargetsAfter(_LocalHistoryPathOperation committed) {
    final index = _pendingPathOperations.indexOf(committed);
    if (index < 0 || index + 1 >= _pendingPathOperations.length) return;
    final documents = {
      for (final document in state.snapshot.documents) document.id: document,
    };
    for (final operation in _pendingPathOperations.skip(index + 1)) {
      for (final documentId in committed.documentIds) {
        final target = operation.targets[documentId];
        final document = documents[documentId];
        if (target == null ||
            document == null ||
            document.deleted ||
            document.currentPath == null ||
            !p.equals(document.currentPath!, target.expectedPath)) {
          continue;
        }
        operation.targets[documentId] = LocalHistoryPathTarget(
          documentId: documentId,
          expectedPath: target.expectedPath,
          versionToken: localHistoryDocumentVersionToken(
            document,
            state.snapshot.revisions,
          ),
        );
      }
    }
  }

  Future<void> markDeleted(
    String path, {
    required bool recursive,
    Iterable<LocalHistoryPathTarget>? preparedTargets,
    Future<void> Function()? onQueued,
  }) async {
    final normalized = p.normalize(path);
    _queuePathOperation(
      _LocalHistoryPathDeletion(
        path: normalized,
        recursive: recursive,
        affectedOwners: _ownersAssociatedWithPath(normalized),
        targets:
            preparedTargets ??
            await _targetsAtProjectedPath(normalized, recursive: recursive),
      ),
    );
    await onQueued?.call();
    final settled = await _enqueue(
      _pathRemapOwner,
      _settlePendingPathOperations,
    );
    if (!settled) _scheduleCheckpoint(_pathRemapOwner);
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
    _showCaptureFailure();
    await observeOpened(buffer);
    if (!ref.mounted || generation != _scopeGeneration) return;
    final documentId = _documentIdsByBuffer[buffer.id];
    if (documentId == null) {
      await refresh();
      if (!ref.mounted || generation != _scopeGeneration) return;
      final byPath = state.snapshot.documents
          .where(
            (document) =>
                !document.deleted &&
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
    _showCaptureFailure();
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
    _showCaptureFailure();
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
    _showCaptureFailure();
  }

  Future<void> selectDocumentForPath(String path) async {
    await refresh();
    if (!ref.mounted) return;
    final normalized = p.normalize(path);
    final activeDocument = state.snapshot.documents
        .where(
          (candidate) =>
              !candidate.deleted &&
              candidate.currentPath != null &&
              p.equals(candidate.currentPath!, normalized),
        )
        .firstOrNull;
    final document =
        activeDocument ??
        state.snapshot.documents.where((candidate) {
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

  /// Restores the stable history identity recorded with an editor session.
  ///
  /// The store snapshot is authoritative: stale session metadata cannot bind
  /// a buffer to a cleared or path-incompatible replacement document. Deleted
  /// documents remain valid bindings for recovery editors whose file vanished.
  bool restoreBufferDocumentIdentity({
    required String bufferId,
    required String documentId,
    required String? path,
  }) {
    final document = state.snapshot.documents
        .where((candidate) => candidate.id == documentId)
        .firstOrNull;
    if (document == null) return false;
    final normalizedPath = path == null ? null : p.normalize(path);
    final compatible = normalizedPath == null
        ? document.currentPath == null || document.untitled
        : document.currentPath != null &&
                  p.equals(document.currentPath!, normalizedPath) ||
              document.deleted &&
                  document.historicalPaths.any(
                    (historical) => p.equals(historical, normalizedPath),
                  );
    if (!compatible) return false;
    _documentIdsByBuffer[bufferId] = documentId;
    return true;
  }

  /// Confirms that a crash-recovery payload is already represented by one of
  /// the stable lineages targeted by a committed path operation.
  ///
  /// Startup uses this before dropping recovery for a committed deletion. A
  /// newer editor revision accepted while deletion was in flight must remain
  /// recoverable unless its exact source and text format reached the store.
  Future<bool> hasExactStoredRevision({
    required Iterable<String> documentIds,
    required String source,
    required TextFormatMetadata format,
  }) async {
    final ids = documentIds.toSet();
    if (ids.isEmpty) return false;
    try {
      final snapshot = await _store.load();
      final checksum = sourceChecksum(source);
      for (final summary in snapshot.revisions) {
        if (!ids.contains(summary.documentId) || summary.checksum != checksum) {
          continue;
        }
        final revision = await _store.readRevision(summary.id);
        if (revision != null &&
            revision.source == source &&
            _sameHistoryFormat(revision.format, format)) {
          return true;
        }
      }
    } on Object {
      // Recovery is the conservative authority while storage is unavailable.
    }
    return false;
  }

  Future<void> search(String query) async {
    await _runSearch(query, clearMatches: true);
  }

  Future<void> clearDocument(String documentId) async {
    final durableBeforeClear = _durableStateFingerprint();
    final document = state.snapshot.documents
        .where((candidate) => candidate.id == documentId)
        .firstOrNull;
    final currentDocumentPaths = <String>{
      if (document?.currentPath case final path?
          when !state.snapshot.documents.any(
            (candidate) =>
                candidate.id != documentId &&
                !candidate.deleted &&
                candidate.currentPath != null &&
                p.equals(candidate.currentPath!, path),
          ))
        p.normalize(path),
    };
    final externalCaptureOwners = _externallyOwnedRetainedCaptures.entries
        .where(
          (entry) =>
              entry.value.documentId == documentId ||
              <String?>[
                entry.value.baseline?.path,
                entry.value.pending?.path,
                entry.value.baselineSaveDestination?.path,
                entry.value.protection?.snapshot.path,
              ].whereType<String>().any(
                (path) => currentDocumentPaths.any(
                  (current) => p.equals(current, path),
                ),
              ),
        )
        .map((entry) => entry.key)
        .toSet();
    final externalPromotionOwners = _externallyOwnedPromotions.entries
        .where(
          (entry) =>
              entry.value.documentId == documentId ||
              currentDocumentPaths.any(
                (path) => p.equals(path, entry.value.destinationPath),
              ),
        )
        .map((entry) => entry.key)
        .toSet();
    final retiredExternalSaveAsOwners = <String>{};
    for (final entry in _externallyOwnedSaveAsOperations.entries.toList()) {
      final operation = entry.value;
      final sourceMatches =
          operation.sourceDocumentId == documentId ||
          (operation.source.path != null &&
              currentDocumentPaths.any(
                (path) => p.equals(path, operation.source.path!),
              ));
      final destinationMatches =
          operation.destinationDocumentId == documentId ||
          (operation.destination.path != null &&
              currentDocumentPaths.any(
                (path) => p.equals(path, operation.destination.path!),
              ));
      if (!sourceMatches && !destinationMatches) continue;
      final firstSaveLineage =
          operation.source.untitled && !operation.destinationExisted;
      var narrowed = operation.withRecordedSides(
        source: !sourceMatches,
        destination: !(destinationMatches || firstSaveLineage && sourceMatches),
      );
      if (firstSaveLineage && sourceMatches) {
        narrowed = narrowed.withoutFirstSaveLineageTransition();
      }
      if (!narrowed.firstSaveLineageTransition &&
          !narrowed.recordSourceHistory &&
          !narrowed.recordDestinationHistory) {
        _externallyOwnedSaveAsOperations.remove(entry.key);
        retiredExternalSaveAsOwners.add(entry.key);
      } else {
        _externallyOwnedSaveAsOperations[entry.key] = narrowed;
      }
    }
    final affectedBuffers = <String>{
      ..._documentIdsByBuffer.entries
          .where((entry) => entry.value == documentId)
          .map((entry) => entry.key),
      ...{
            ..._pending,
            ..._baselines,
            ..._inFlightSnapshots,
            for (final entry in _protections.entries)
              entry.key: entry.value.snapshot,
          }.entries
          .where((entry) {
            final boundDocumentId = _documentIdsByBuffer[entry.key];
            if (boundDocumentId != null) {
              return boundDocumentId == documentId;
            }
            return entry.value.path != null &&
                currentDocumentPaths.any(
                  (path) => p.equals(path, entry.value.path!),
                );
          })
          .map((entry) => entry.key),
      for (final path in currentDocumentPaths)
        if (_bufferQueues.containsKey('path:$path')) 'path:$path',
      if (_normalBrowsingScope case final scope?
          when _documentIdsByBuffer[scope.bufferId] == documentId ||
              (_documentIdsByBuffer[scope.bufferId] == null &&
                  scope.path != null &&
                  currentDocumentPaths.any(
                    (path) => p.equals(path, scope.path!),
                  )))
        scope.bufferId,
      for (final operation in _pendingPathOperations)
        if (operation.documentIds.contains(documentId))
          ...operation.affectedOwners,
      if (_pendingPathOperations.any(
        (operation) => operation.documentIds.contains(documentId),
      ))
        _pathRemapOwner,
    }.toList(growable: false);
    final clearedOwners = _documentIdsByBuffer.entries
        .where((entry) => entry.value == documentId)
        .map((entry) => entry.key)
        .toSet();
    for (final owner in affectedBuffers) {
      if (owner != _pathRemapOwner) {
        _clearingDocumentIdsByBuffer[owner] = documentId;
      }
    }
    _retiredDurableWorkOwnerIds.addAll(
      affectedBuffers.where(
        (owner) =>
            owner.startsWith('history-capture:') ||
            owner.startsWith('history-promotion:'),
      ),
    );
    _retiredDurableWorkOwnerIds.addAll(externalCaptureOwners);
    _retiredDurableWorkOwnerIds.addAll(externalPromotionOwners);
    _retiredDurableWorkOwnerIds.addAll(retiredExternalSaveAsOwners);
    _externallyOwnedRetainedCaptures.removeWhere(
      (owner, _) => externalCaptureOwners.contains(owner),
    );
    _externallyOwnedPromotions.removeWhere(
      (owner, _) => externalPromotionOwners.contains(owner),
    );
    for (final bufferId in affectedBuffers.where(
      (bufferId) => bufferId != _pathRemapOwner,
    )) {
      _invalidateBufferWork(bufferId);
    }
    _checkpointTimers.remove(_pathRemapOwner)?.cancel();
    _loadGeneration++;
    _searchGeneration++;
    _documentIdsByBuffer.removeWhere((_, value) => value == documentId);
    final retiredPromotions = _pendingUntitledPromotions.values
        .where((promotion) => promotion.documentId == documentId)
        .map(_promotionDurableOwner)
        .toList(growable: false);
    _pendingUntitledPromotions.removeWhere(
      (_, promotion) => promotion.documentId == documentId,
    );
    _retiredDurableWorkOwnerIds.addAll(retiredPromotions);
    final affectedSaveAs = _pendingSaveAsOperations.values
        .where(
          (operation) =>
              operation.sourceDocumentId == documentId ||
              operation.destinationDocumentId == documentId ||
              <String?>[
                operation.source.path,
                operation.destination.path,
              ].whereType<String>().any(
                (path) => currentDocumentPaths.any(
                  (current) => p.equals(current, path),
                ),
              ),
        )
        .toList(growable: false);
    for (final operation in affectedSaveAs) {
      final sourceMatches =
          operation.sourceDocumentId == documentId ||
          (operation.source.path != null &&
              currentDocumentPaths.any(
                (path) => p.equals(path, operation.source.path!),
              ));
      final destinationMatches =
          operation.destinationDocumentId == documentId ||
          (operation.destination.path != null &&
              currentDocumentPaths.any(
                (path) => p.equals(path, operation.destination.path!),
              ));
      final firstSaveLineage =
          operation.source.untitled && !operation.destinationExisted;
      var narrowed = operation.withRecordedSides(
        source: !sourceMatches,
        destination: !(destinationMatches || firstSaveLineage && sourceMatches),
      );
      if (firstSaveLineage && sourceMatches) {
        narrowed = narrowed.withoutFirstSaveLineageTransition();
      }
      _pendingSaveAsOperations[operation.operationId] = narrowed;
    }
    for (final operation in _pendingPathOperations) {
      operation.removeDocumentId(documentId);
      final filesystemOutcomeStillRequired =
          operation.phase == LocalHistoryPathReconciliationPhase.executing;
      final awaitingWorkspaceAcknowledgement =
          operation.committed &&
          operation.retainUntilAcknowledged &&
          !operation.acknowledgementRequested;
      if (!filesystemOutcomeStillRequired &&
          !awaitingWorkspaceAcknowledgement) {
        operation.affectedOwners.removeAll(clearedOwners);
      }
      operation.retryable = true;
      operation.errorDetail = null;
    }
    final retiredOperations = _pendingPathOperations
        .where(_shouldRetireEmptyPathOperation)
        .toList(growable: false);
    _pendingPathOperations.removeWhere(_shouldRetireEmptyPathOperation);
    for (final operation in retiredOperations) {
      _rememberRetiredPathOperation(operation.operationId);
    }
    _showCaptureFailure();
    final clearOperation = LocalHistoryPendingClear(
      operationId: _newDetachedOwner('history-clear'),
      documentId: documentId,
    );
    _pendingClearOperations[clearOperation.operationId] = clearOperation;
    await _runWithBlockedBufferQueues(affectedBuffers, () async {
      // Install the queue barriers before the first durable await. Edits are
      // accepted into the replacement clear epoch while its journal is
      // being written, but their captures must remain behind the clear that
      // establishes that epoch in the store.
      await _persistDurableStateNow();
      await _store.clearDocumentOnce(
        operationId: clearOperation.operationId,
        documentId: documentId,
      );
    });
    _pendingClearOperations.remove(clearOperation.operationId);
    _retiredDurableWorkOwnerIds.add(clearOperation.operationId);
    await _persistDurableStateNow();
    if (!ref.mounted) return;
    final snapshot = await _store.load();
    if (!ref.mounted) return;
    await _publishSnapshot(snapshot, explicitlyClearedDocumentId: documentId);
    _clearingDocumentIdsByBuffer.removeWhere((_, value) => value == documentId);
    if (_pendingPathOperations.isNotEmpty) {
      _scheduleCheckpoint(_pathRemapOwner);
    }
    await _persistDurableStateIfChanged(durableBeforeClear);
  }

  bool _shouldRetireEmptyPathOperation(_LocalHistoryPathOperation operation) {
    if (operation.targets.isNotEmpty) return false;
    // An executing record is the durable proof that the filesystem call was
    // entered. Even with no remaining history targets, its owner/path mapping
    // must survive until the caller publishes the outcome (or startup infers
    // it after a crash).
    if (operation.phase == LocalHistoryPathReconciliationPhase.executing) {
      return false;
    }
    final awaitingWorkspaceAcknowledgement =
        operation.committed &&
        operation.retainUntilAcknowledged &&
        !operation.acknowledgementRequested;
    if (awaitingWorkspaceAcknowledgement) return false;
    return operation.committed ||
        !operation.affectedOwners.any(_ownerHasRetainedCaptureWork);
  }

  Future<void> clearAll() async {
    final durableBeforeClear = _durableStateFingerprint();
    final affectedBuffers = <String>{
      ..._documentIdsByBuffer.keys,
      ..._workOwners,
    };
    _historyGeneration++;
    _loadGeneration++;
    _searchGeneration++;
    _cancelCheckpoints(clearTransitions: false);
    _captureFailures.clear();
    _documentIdsByBuffer.clear();
    _retiredDurableWorkOwnerIds.addAll(
      _pendingUntitledPromotions.values.map(_promotionDurableOwner),
    );
    _retiredDurableWorkOwnerIds.addAll(
      affectedBuffers.where(
        (owner) =>
            owner.startsWith('history-capture:') ||
            owner.startsWith('history-promotion:'),
      ),
    );
    _retiredDurableWorkOwnerIds.addAll(_externallyOwnedRetainedCaptures.keys);
    _retiredDurableWorkOwnerIds.addAll(_externallyOwnedPromotions.keys);
    _retiredDurableWorkOwnerIds.addAll(_externallyOwnedSaveAsOperations.keys);
    _externallyOwnedRetainedCaptures.clear();
    _externallyOwnedPromotions.clear();
    _externallyOwnedSaveAsOperations.clear();
    _pendingUntitledPromotions.clear();
    for (final operation in _pendingSaveAsOperations.values.toList()) {
      _pendingSaveAsOperations[operation.operationId] = operation.cancelHistory(
        cancelLineageTransition: true,
      );
    }
    final retainedPathOperations = <_LocalHistoryPathOperation>[];
    for (final operation in _pendingPathOperations) {
      final filesystemOutcomeStillRequired =
          operation.phase == LocalHistoryPathReconciliationPhase.executing;
      final awaitingWorkspaceAcknowledgement =
          operation.committed &&
          operation.retainUntilAcknowledged &&
          !operation.acknowledgementRequested;
      if (filesystemOutcomeStillRequired || awaitingWorkspaceAcknowledgement) {
        operation.targets.clear();
        operation
          ..retryable = true
          ..errorDetail = null;
        retainedPathOperations.add(operation);
      } else {
        _rememberRetiredPathOperation(operation.operationId);
      }
    }
    _pendingPathOperations
      ..clear()
      ..addAll(retainedPathOperations);
    final clearOperation = LocalHistoryPendingClear(
      operationId: _newDetachedOwner('history-clear-all'),
    );
    _pendingClearOperations[clearOperation.operationId] = clearOperation;
    await _runWithBlockedBufferQueues(affectedBuffers, () async {
      // Keep replacement-epoch captures behind both journal persistence and
      // the store mutation, matching the document-clear ordering above.
      await _persistDurableStateNow();
      await _store.clearAllOnce(operationId: clearOperation.operationId);
    });
    _pendingClearOperations.remove(clearOperation.operationId);
    _retiredDurableWorkOwnerIds.add(clearOperation.operationId);
    await _persistDurableStateNow();
    if (!ref.mounted) return;
    final snapshot = await _store.load();
    if (!ref.mounted) return;
    await _publishSnapshot(snapshot, clearAllComparisons: true);
    await _persistDurableStateIfChanged(durableBeforeClear);
  }

  bool _ownerHasRetainedCaptureWork(String owner) =>
      _pending.containsKey(owner) ||
      _baselines.containsKey(owner) ||
      _baselineSaveDestinations.containsKey(owner) ||
      _protections.containsKey(owner) ||
      _pendingUntitledPromotions.containsKey(owner) ||
      _inFlightSnapshots.containsKey(owner);

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
    _retiredDurableWorkOwnerIds.add(match.key);
    final failure = _captureFailures.remove(match.key);
    if (failure != null) _captureFailures[snapshot.bufferId] = failure;
    final adopted = match.value.forBuffer(snapshot.bufferId);
    _pendingUntitledPromotions[snapshot.bufferId] = adopted;
    final pending = _pending.remove(match.key);
    _checkpointTimers.remove(match.key)?.cancel();
    if (pending != null) {
      _pending[snapshot.bufferId] = pending.forBuffer(snapshot.bufferId);
    }
    final baseline = _baselines.remove(match.key);
    if (baseline != null) {
      _baselines[snapshot.bufferId] = baseline.forBuffer(snapshot.bufferId);
    }
    if (_baselinesRequiringVacantPath.remove(match.key)) {
      _baselinesRequiringVacantPath.add(snapshot.bufferId);
    }
    final destination = _baselineSaveDestinations.remove(match.key);
    if (destination != null) {
      _baselineSaveDestinations[snapshot.bufferId] = destination.forBuffer(
        snapshot.bufferId,
      );
    }
    final protection = _protections.remove(match.key);
    if (protection != null) {
      _protections[snapshot.bufferId] = (
        snapshot: protection.snapshot.forBuffer(snapshot.bufferId),
        reason: protection.reason,
        force: protection.force,
        ignoreBinding: protection.ignoreBinding,
        allowPathChange: protection.allowPathChange,
        bindResult: protection.bindResult,
        requireVacantPath: protection.requireVacantPath,
        expectedTarget: protection.expectedTarget,
        captureId: protection.captureId,
      );
    }
    _documentIdsByBuffer.remove(match.key);
    _documentIdsByBuffer[snapshot.bufferId] = adopted.documentId;
    _transferPathOperationOwner(match.key, snapshot.bufferId);
    return adopted;
  }

  void _detachPendingUntitledPromotion(
    String bufferId, {
    bool retainLiveBinding = false,
  }) {
    final promotion = _pendingUntitledPromotions.remove(bufferId);
    if (promotion == null) return;
    _retiredDurableWorkOwnerIds.add(bufferId);
    final detachedBufferId = _newDetachedOwner(
      'history-promotion:${promotion.documentId}',
    );
    final failure = _captureFailures.remove(bufferId);
    if (failure != null) _captureFailures[detachedBufferId] = failure;
    _pendingUntitledPromotions[detachedBufferId] = promotion.forBuffer(
      detachedBufferId,
    );
    final pending = _pending.remove(bufferId);
    _checkpointTimers.remove(bufferId)?.cancel();
    if (pending != null) {
      _pending[detachedBufferId] = pending.forBuffer(detachedBufferId);
    }
    if (!retainLiveBinding) _documentIdsByBuffer.remove(bufferId);
    _documentIdsByBuffer[detachedBufferId] = promotion.documentId;
    final baseline = _baselines.remove(bufferId);
    if (baseline != null) {
      _baselines[detachedBufferId] = baseline.forBuffer(detachedBufferId);
    }
    if (_baselinesRequiringVacantPath.remove(bufferId)) {
      _baselinesRequiringVacantPath.add(detachedBufferId);
    }
    final destination = _baselineSaveDestinations.remove(bufferId);
    if (destination != null) {
      _baselineSaveDestinations[detachedBufferId] = destination.forBuffer(
        detachedBufferId,
      );
    }
    final protection = _protections.remove(bufferId);
    if (protection != null) {
      _protections[detachedBufferId] = (
        snapshot: protection.snapshot.forBuffer(detachedBufferId),
        reason: protection.reason,
        force: protection.force,
        ignoreBinding: protection.ignoreBinding,
        allowPathChange: protection.allowPathChange,
        bindResult: protection.bindResult,
        requireVacantPath: protection.requireVacantPath,
        expectedTarget: protection.expectedTarget,
        captureId: protection.captureId,
      );
    }
    _transferPathOperationOwner(bufferId, detachedBufferId);
    _scheduleCheckpoint(detachedBufferId);
  }

  void _detachFailedCapturesForFork(
    LocalHistoryBufferSnapshot source, {
    required String? sourceDocumentId,
  }) {
    final bufferId = source.bufferId;
    final pending = _pending[bufferId];
    final sourcePending =
        pending != null &&
        pending.revision <= source.revision &&
        _sameOptionalPath(pending.path, source.path);
    if (!_baselines.containsKey(bufferId) &&
        !_protections.containsKey(bufferId) &&
        !sourcePending) {
      _transferPathOperationOwner(bufferId, null);
      return;
    }
    late String detached;
    do {
      detached = _newDetachedOwner('history-capture:$bufferId');
    } while (_hasOutstandingWork(detached) ||
        _documentIdsByBuffer.containsKey(detached));
    _checkpointTimers.remove(bufferId)?.cancel();
    final baseline = _baselines.remove(bufferId);
    LocalHistoryBufferSnapshot detachedSource(
      LocalHistoryBufferSnapshot snapshot,
    ) => snapshot.forBuffer(detached);
    if (baseline != null) _baselines[detached] = detachedSource(baseline);
    if (_baselinesRequiringVacantPath.remove(bufferId)) {
      _baselinesRequiringVacantPath.add(detached);
    }
    if (baseline != null && sourceDocumentId == null && baseline.path != null) {
      _baselinesRequiringVacantPath.add(detached);
    }
    final destination = _baselineSaveDestinations.remove(bufferId);
    if (destination != null) {
      _baselineSaveDestinations[detached] = destination.forBuffer(detached);
    }
    final protection = _protections.remove(bufferId);
    if (protection != null) {
      _protections[detached] = (
        snapshot: detachedSource(protection.snapshot),
        reason: protection.reason,
        force: protection.force,
        ignoreBinding: protection.ignoreBinding,
        allowPathChange: protection.allowPathChange,
        bindResult: protection.bindResult,
        requireVacantPath: protection.requireVacantPath,
        expectedTarget: protection.expectedTarget,
        captureId: protection.captureId,
      );
    }
    if (sourcePending) {
      _pending.remove(bufferId);
      _pending[detached] = detachedSource(pending);
    }
    final transferredStages = <_LocalHistoryFailureStage>{
      if (baseline != null) _LocalHistoryFailureStage.baseline,
      if (protection != null) _LocalHistoryFailureStage.protection,
      if (sourcePending) _LocalHistoryFailureStage.checkpoint,
    };
    for (final stage in transferredStages) {
      final failure = _captureFailures[bufferId]?.remove(stage);
      if (failure != null) (_captureFailures[detached] ??= {})[stage] = failure;
    }
    if (_captureFailures[bufferId]?.isEmpty == true) {
      _captureFailures.remove(bufferId);
    }
    if (sourceDocumentId != null) {
      _documentIdsByBuffer[detached] = sourceDocumentId;
    }
    _transferPathOperationOwner(bufferId, detached);
    _closedBuffers.add(detached);
    _scheduleCheckpoint(detached);
    _scheduleCheckpoint(bufferId);
  }

  void _transferPathOperationOwner(String source, String? destination) {
    for (final operation in _pendingPathOperations) {
      if (operation.affectedOwners.remove(source) && destination != null) {
        operation.affectedOwners.add(destination);
      }
    }
  }

  Future<bool> _captureBaseline(
    LocalHistoryBufferSnapshot snapshot,
    LocalHistoryCaptureReason reason, {
    required int acceptedHistoryGeneration,
    required int acceptedBufferGeneration,
  }) async {
    if (!_operationIsCurrent(
          snapshot.bufferId,
          acceptedHistoryGeneration,
          acceptedBufferGeneration,
        ) ||
        !_pendingIsEligible(snapshot)) {
      return true;
    }
    var original = _baselines.putIfAbsent(snapshot.bufferId, () => snapshot);
    if (original.captureId == null) {
      original = original.withCaptureId(_newPathOperationId());
      _baselines[snapshot.bufferId] = original;
    }
    if (_failure(
          snapshot.bufferId,
          _LocalHistoryFailureStage.baseline,
        )?.retryable ==
        false) {
      return false;
    }
    return _capture(
      original,
      reason,
      acceptedHistoryGeneration: acceptedHistoryGeneration,
      acceptedBufferGeneration: acceptedBufferGeneration,
    );
  }

  Future<bool> _capture(
    LocalHistoryBufferSnapshot snapshot,
    LocalHistoryCaptureReason reason, {
    bool force = false,
    bool ignoreBinding = false,
    bool bindResult = false,
    bool requireVacantPath = false,
    bool allowPathChange = false,
    bool allowDuringPathTransition = false,
    bool requireProtection = false,
    LocalHistoryPathTarget? expectedTarget,
    bool retainedProtection = false,
    String? captureId,
    int? acceptedHistoryGeneration,
    int? acceptedBufferGeneration,
  }) async {
    final captureHistoryGeneration =
        acceptedHistoryGeneration ?? _historyGeneration;
    final captureBufferGeneration =
        acceptedBufferGeneration ?? _bufferGeneration(snapshot.bufferId);
    final effectiveCaptureId =
        captureId ??
        snapshot.captureId ??
        (requireProtection || retainedProtection
            ? _newPathOperationId()
            : null);
    if (!_operationIsCurrent(
      snapshot.bufferId,
      captureHistoryGeneration,
      captureBufferGeneration,
    )) {
      return !requireProtection;
    }
    if (_pendingClearOperations.isNotEmpty) {
      if (!await _settlePendingClearOperations()) return false;
      if (!_operationIsCurrent(
        snapshot.bufferId,
        captureHistoryGeneration,
        captureBufferGeneration,
      )) {
        return !requireProtection;
      }
      // Work accepted after the user initiated Clear belongs to the new
      // lineage. The failed clear still exposed the prior store epoch when the
      // edit was queued, so adopt the epoch published by the successful replay
      // before capturing it.
      snapshot = _rebaseCaptureWorkAfterClear(snapshot);
    }
    if (_pathOperationBlocksOwner(snapshot.bufferId, snapshot.path)) {
      final remapped = await _enqueue(
        _pathRemapOwner,
        _settlePendingPathOperations,
      );
      if (!remapped) {
        if (_operationIsCurrent(
          snapshot.bufferId,
          captureHistoryGeneration,
          captureBufferGeneration,
        )) {
          final stage = retainedProtection
              ? _LocalHistoryFailureStage.protection
              : _stageForReason(reason);
          if (stage == _LocalHistoryFailureStage.baseline) {
            _baselines.putIfAbsent(snapshot.bufferId, () => snapshot);
          } else if (stage == _LocalHistoryFailureStage.protection) {
            _protections[snapshot.bufferId] = (
              snapshot: snapshot,
              reason: reason,
              force: force,
              ignoreBinding: ignoreBinding,
              allowPathChange: allowPathChange,
              bindResult: bindResult,
              requireVacantPath: requireVacantPath,
              expectedTarget: expectedTarget,
              captureId: effectiveCaptureId,
            );
          }
          _scheduleCheckpoint(_pathRemapOwner);
        }
        return false;
      }
      if (!_operationIsCurrent(
        snapshot.bufferId,
        captureHistoryGeneration,
        captureBufferGeneration,
      )) {
        return !requireProtection;
      }
    }
    if (reason == LocalHistoryCaptureReason.automaticCheckpoint &&
        !allowDuringPathTransition &&
        _pathTransitions.containsKey(snapshot.bufferId)) {
      final pending = _pending[snapshot.bufferId];
      if (pending == null || pending.revision <= snapshot.revision) {
        _pending[snapshot.bufferId] = snapshot;
      }
      return !requireProtection;
    }
    final promotion = _pendingUntitledPromotions[snapshot.bufferId];
    if (promotion != null) {
      if (!_sameOptionalPath(snapshot.path, promotion.destinationPath)) {
        _setWarning(
          LocalHistoryWarningKind.pathChange,
          promotion.destinationPath,
        );
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
        return !requireProtection;
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
      return !requireProtection;
    }
    final stage = retainedProtection
        ? _LocalHistoryFailureStage.protection
        : _stageForReason(reason);
    final captureRequiresVacantPath =
        requireVacantPath ||
        (stage == _LocalHistoryFailureStage.baseline &&
            _baselinesRequiringVacantPath.contains(snapshot.bufferId));
    _inFlightSnapshots[snapshot.bufferId] = snapshot;
    try {
      LocalHistoryCaptureResult result;
      try {
        result = await _store.capture(
          LocalHistoryCaptureRequest(
            documentId: ignoreBinding
                ? null
                : _documentIdsByBuffer[snapshot.bufferId],
            remoteNote: snapshot.remoteNote,
            path: snapshot.path,
            displayName: snapshot.displayName,
            source: snapshot.text,
            format: snapshot.format,
            capturedAt: _clock().toUtc(),
            reason: reason,
            untitled: snapshot.untitled,
            force: force,
            allowPathChange: allowPathChange,
            requireVacantPath: captureRequiresVacantPath,
            expectedTarget: expectedTarget,
            captureId: effectiveCaptureId,
            acceptedClearEpoch: snapshot.acceptedClearEpoch,
            acceptedAt: snapshot.acceptedAt,
            acceptedDocumentId: snapshot.acceptedDocumentId,
            commitGuard: () =>
                _operationIsCurrent(
                  snapshot.bufferId,
                  captureHistoryGeneration,
                  captureBufferGeneration,
                ) &&
                policy.recordingEnabled &&
                !policy.excludes(snapshot.path),
            createDetachedLineage:
                !ignoreBinding &&
                _documentIdsByBuffer[snapshot.bufferId] == null &&
                snapshot.path != null &&
                !_baselinesRequiringVacantPath.contains(snapshot.bufferId) &&
                (snapshot.bufferId.startsWith('history-capture:') ||
                    snapshot.bufferId.startsWith('history-promotion:')),
          ),
          currentPolicy,
        );
      } on Object catch (error) {
        final rejectedDocumentId = ignoreBinding
            ? null
            : _documentIdsByBuffer[snapshot.bufferId];
        if (error is LocalHistoryCaptureCancelled) {
          if (_sameCapturedSnapshot(_baselines[snapshot.bufferId], snapshot)) {
            _baselines.remove(snapshot.bufferId);
            _baselinesRequiringVacantPath.remove(snapshot.bufferId);
            _baselineSaveDestinations.remove(snapshot.bufferId);
          }
          if (_sameCapturedSnapshot(_pending[snapshot.bufferId], snapshot)) {
            _pending.remove(snapshot.bufferId);
          }
          final protection = _protections[snapshot.bufferId];
          if (_sameCapturedSnapshot(protection?.snapshot, snapshot)) {
            _protections.remove(snapshot.bufferId);
          }
          _clearFailure(snapshot.bufferId, stage, snapshot.revision);
          _showCaptureFailure();
          return !requireProtection;
        }
        if (error is LocalHistoryClearConflict) {
          final baseline = _baselines[snapshot.bufferId];
          if (_sameCapturedSnapshot(baseline, snapshot)) {
            _baselines.remove(snapshot.bufferId);
            _baselinesRequiringVacantPath.remove(snapshot.bufferId);
            _baselineSaveDestinations.remove(snapshot.bufferId);
          }
          final pending = _pending[snapshot.bufferId];
          if (_sameCapturedSnapshot(pending, snapshot)) {
            _pending.remove(snapshot.bufferId);
          }
          final protection = _protections[snapshot.bufferId];
          if (_sameCapturedSnapshot(protection?.snapshot, snapshot)) {
            _protections.remove(snapshot.bufferId);
          }
          _clearFailure(snapshot.bufferId, stage, snapshot.revision);
          _showCaptureFailure();
          return !requireProtection;
        }
        if (error is LocalHistoryReconciliationConflict &&
            rejectedDocumentId != null) {
          try {
            final loaded = await _store.load();
            if (!loaded.documents.any(
              (document) => document.id == rejectedDocumentId,
            )) {
              if (_documentIdsByBuffer[snapshot.bufferId] ==
                  rejectedDocumentId) {
                _documentIdsByBuffer.remove(snapshot.bufferId);
              }
              if (!ignoreBinding &&
                  expectedTarget == null &&
                  !requireVacantPath) {
                await _publishSnapshot(loaded);
                // The snapshot was accepted after the shared clear (an older
                // accepted snapshot is rejected by the clear barrier before
                // identity resolution). Retry this current edit against the
                // now-unbound path so the first post-clear edit establishes
                // the replacement lineage instead of being acknowledged and
                // dropped with the stale controller binding.
                return await _capture(
                  snapshot,
                  reason,
                  force: force,
                  allowPathChange: allowPathChange,
                  allowDuringPathTransition: allowDuringPathTransition,
                  requireProtection: requireProtection,
                  retainedProtection: retainedProtection,
                  captureId: effectiveCaptureId,
                  acceptedHistoryGeneration: captureHistoryGeneration,
                  acceptedBufferGeneration: captureBufferGeneration,
                );
              }
              if (identical(_baselines[snapshot.bufferId], snapshot)) {
                _baselines.remove(snapshot.bufferId);
                _baselinesRequiringVacantPath.remove(snapshot.bufferId);
                _baselineSaveDestinations.remove(snapshot.bufferId);
              }
              if (identical(_pending[snapshot.bufferId], snapshot)) {
                _pending.remove(snapshot.bufferId);
              }
              final protection = _protections[snapshot.bufferId];
              if (identical(protection?.snapshot, snapshot)) {
                _protections.remove(snapshot.bufferId);
              }
              _clearFailure(snapshot.bufferId, stage, snapshot.revision);
              await _publishSnapshot(loaded);
              _showCaptureFailure();
              return !requireProtection;
            }
          } on Object {
            // Preserve the original conflict when current identity cannot be
            // established safely.
          }
        }
        if (_operationIsCurrent(
          snapshot.bufferId,
          captureHistoryGeneration,
          captureBufferGeneration,
        )) {
          if (stage == _LocalHistoryFailureStage.baseline) {
            _baselines.putIfAbsent(snapshot.bufferId, () => snapshot);
          } else if (stage == _LocalHistoryFailureStage.protection) {
            _protections[snapshot.bufferId] = (
              snapshot: snapshot,
              reason: reason,
              force: force,
              ignoreBinding: ignoreBinding,
              allowPathChange: allowPathChange,
              bindResult: bindResult,
              requireVacantPath: requireVacantPath,
              expectedTarget: expectedTarget,
              captureId: effectiveCaptureId,
            );
          }
          _recordFailure(
            snapshot.bufferId,
            _LocalHistoryCaptureFailure(
              detail: error.toString(),
              displayName: snapshot.path ?? snapshot.displayName,
              revision: snapshot.revision,
              retryable:
                  error is LocalHistoryReconciliationConflict &&
                      snapshot.bufferId.startsWith(
                        'history-capture:save-as-destination',
                      )
                  ? true
                  : _captureErrorIsRetryable(error),
              stage: stage,
            ),
          );
          _scheduleCheckpoint(snapshot.bufferId);
        }
        return false;
      }
      if (!_operationIsCurrent(
        snapshot.bufferId,
        captureHistoryGeneration,
        captureBufferGeneration,
      )) {
        return !requireProtection;
      }
      if (!ignoreBinding || bindResult) {
        _documentIdsByBuffer[snapshot.bufferId] = result.document.id;
      }
      _clearFailure(snapshot.bufferId, stage, snapshot.revision);
      if (stage == _LocalHistoryFailureStage.baseline &&
          identical(_baselines[snapshot.bufferId], snapshot)) {
        _baselines.remove(snapshot.bufferId);
        _baselinesRequiringVacantPath.remove(snapshot.bufferId);
        final destination = _baselineSaveDestinations.remove(snapshot.bufferId);
        if (destination != null) {
          _pendingUntitledPromotions[snapshot.bufferId] =
              LocalHistoryPendingIdentityPromotion(
                bufferId: snapshot.bufferId,
                documentId: result.document.id,
                destinationPath: destination.path!,
                displayName: destination.displayName,
                acceptedClearEpoch: snapshot.acceptedClearEpoch,
                operationOwnerId: snapshot.bufferId.startsWith('history-')
                    ? snapshot.bufferId
                    : _newDetachedOwner('history-promotion'),
              );
          _protections.putIfAbsent(
            snapshot.bufferId,
            () => (
              snapshot: destination,
              reason: LocalHistoryCaptureReason.saved,
              force: false,
              ignoreBinding: false,
              allowPathChange: false,
              bindResult: true,
              requireVacantPath: false,
              expectedTarget: null,
              captureId: destination.captureId ?? _newPathOperationId(),
            ),
          );
        }
      }
      final protection = _protections[snapshot.bufferId];
      if (stage == _LocalHistoryFailureStage.protection &&
          protection?.snapshot.revision == snapshot.revision &&
          protection?.snapshot.text == snapshot.text) {
        _protections.remove(snapshot.bufferId);
      }
      if (stage != _LocalHistoryFailureStage.baseline &&
          !_pathTransitions.containsKey(snapshot.bufferId)) {
        _acknowledgePending(snapshot.bufferId, snapshot.revision);
      }
      _showCaptureFailure();
      await _refreshAfterCommit(
        snapshot.bufferId,
        captureHistoryGeneration,
        captureBufferGeneration,
        capturedSnapshot: ignoreBinding && !bindResult ? null : snapshot,
        publishBinding: !ignoreBinding || bindResult,
      );
      // Optional recording may settle by cancellation; protection must still
      // be valid after storage, snapshot loading, and any scoped search await.
      return !requireProtection ||
          _operationIsCurrent(
            snapshot.bufferId,
            captureHistoryGeneration,
            captureBufferGeneration,
          );
    } finally {
      if (identical(_inFlightSnapshots[snapshot.bufferId], snapshot)) {
        _inFlightSnapshots.remove(snapshot.bufferId);
      }
    }
  }

  LocalHistoryBufferSnapshot _rebaseCaptureWorkAfterClear(
    LocalHistoryBufferSnapshot current,
  ) {
    LocalHistoryBufferSnapshot rebase(LocalHistoryBufferSnapshot snapshot) =>
        snapshot.atClearAcceptance(
          state.snapshot.clearEpoch,
          snapshot.acceptedAt ?? _clock().toUtc(),
          null,
        );

    final rebasedCurrent = rebase(current);
    bool isCurrentWork(LocalHistoryBufferSnapshot snapshot) =>
        snapshot.revision == current.revision &&
        snapshot.text == current.text &&
        _sameOptionalPath(snapshot.path, current.path) &&
        _sameHistoryFormat(snapshot.format, current.format) &&
        snapshot.captureId == current.captureId;
    LocalHistoryBufferSnapshot rebaseRetained(
      LocalHistoryBufferSnapshot snapshot,
    ) => isCurrentWork(snapshot) ? rebasedCurrent : rebase(snapshot);

    final owner = current.bufferId;
    if (_baselines[owner] case final snapshot?) {
      _baselines[owner] = rebaseRetained(snapshot);
    }
    if (_pending[owner] case final snapshot?) {
      _pending[owner] = rebaseRetained(snapshot);
    }
    if (_protections[owner] case final protection?) {
      _protections[owner] = (
        snapshot: rebaseRetained(protection.snapshot),
        reason: protection.reason,
        force: protection.force,
        ignoreBinding: protection.ignoreBinding,
        allowPathChange: protection.allowPathChange,
        bindResult: protection.bindResult,
        requireVacantPath: protection.requireVacantPath,
        expectedTarget: protection.expectedTarget,
        captureId: protection.captureId,
      );
    }
    return rebasedCurrent;
  }

  void _publishCommittedClearEpoch(String epoch) {
    LocalHistoryBufferSnapshot rebase(LocalHistoryBufferSnapshot snapshot) =>
        snapshot.atClearAcceptance(
          epoch,
          snapshot.acceptedAt ?? _clock().toUtc(),
          null,
        );

    _baselines.updateAll((_, snapshot) => rebase(snapshot));
    _pending.updateAll((_, snapshot) => rebase(snapshot));
    _baselineSaveDestinations.updateAll((_, snapshot) => rebase(snapshot));
    _protections.updateAll(
      (_, protection) => (
        snapshot: rebase(protection.snapshot),
        reason: protection.reason,
        force: protection.force,
        ignoreBinding: protection.ignoreBinding,
        allowPathChange: protection.allowPathChange,
        bindResult: protection.bindResult,
        requireVacantPath: protection.requireVacantPath,
        expectedTarget: protection.expectedTarget,
        captureId: protection.captureId,
      ),
    );
    _pendingUntitledPromotions.updateAll(
      (_, promotion) => promotion.atClearEpoch(epoch),
    );
    final current = state.snapshot;
    state = state.copyWith(
      snapshot: LocalHistorySnapshot(
        documents: current.documents,
        revisions: current.revisions,
        warning: current.warning,
        clearEpoch: epoch,
      ),
    );
  }

  Future<void> _refreshAfterCommit(
    String bufferId,
    int historyGeneration,
    int bufferGeneration, {
    LocalHistoryBufferSnapshot? capturedSnapshot,
    bool publishBinding = true,
  }) async {
    final generation = ++_loadGeneration;
    bool current() =>
        generation == _loadGeneration &&
        _operationIsCurrent(bufferId, historyGeneration, bufferGeneration);
    try {
      final loaded = await _store.load();
      if (!current()) return;
      await _publishSnapshot(
        loaded,
        capturedBufferId: publishBinding ? bufferId : null,
        capturedSnapshot: capturedSnapshot,
      );
    } on Object catch (error) {
      if (!current()) return;
      _storeWarning = LocalHistoryWarning(
        error is UnsupportedLocalHistoryFormat
            ? LocalHistoryWarningKind.unsupportedFormat
            : LocalHistoryWarningKind.unavailable,
        detail: error is UnsupportedLocalHistoryFormat
            ? error.version?.toString()
            : error.toString(),
      );
      state = state.copyWith(loading: false, warning: _presentationWarning());
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
    _pathOperationBlocksOwner(bufferId, promotion.destinationPath);
    if (!await _settlePromotionPathDependencies(
      bufferId,
      promotion.documentId,
      promotion.destinationPath,
    )) {
      return false;
    }
    if (!_operationIsCurrent(
          bufferId,
          promotionHistoryGeneration,
          promotionBufferGeneration,
        ) ||
        !identical(_pendingUntitledPromotions[bufferId], promotion)) {
      return true;
    }
    try {
      final staleOwner = await _stalePromotionOwner(promotion);
      if (!_operationIsCurrent(
            bufferId,
            promotionHistoryGeneration,
            promotionBufferGeneration,
          ) ||
          !identical(_pendingUntitledPromotions[bufferId], promotion)) {
        return true;
      }
      final document = await _store.promoteUntitledDocument(
        documentId: promotion.documentId,
        destinationPath: promotion.destinationPath,
        displayName: promotion.displayName,
        updatedAt: _clock().toUtc(),
        staleDestinationOwner: staleOwner,
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
        final current = await _store.load();
        if (promotion.acceptedClearEpoch case final accepted?
            when accepted != current.clearEpoch) {
          _pendingUntitledPromotions.remove(bufferId);
          if (_documentIdsByBuffer[bufferId] == promotion.documentId) {
            _documentIdsByBuffer.remove(bufferId);
          }
          _clearFailure(bufferId, _LocalHistoryFailureStage.promotion);
          _retiredDurableWorkOwnerIds.add(_promotionDurableOwner(promotion));
          await _publishSnapshot(current);
          _showCaptureFailure();
          return true;
        }
        _recordFailure(
          bufferId,
          _LocalHistoryCaptureFailure(
            detail: promotion.destinationPath,
            displayName: promotion.displayName,
            retryable: false,
            stage: _LocalHistoryFailureStage.promotion,
          ),
        );
        return false;
      }
      _documentIdsByBuffer[bufferId] = document.id;
      _pendingUntitledPromotions.remove(bufferId);
      final protection = _protections[bufferId];
      if (protection != null &&
          protection.reason == LocalHistoryCaptureReason.saved &&
          protection.snapshot.path != null &&
          p.equals(protection.snapshot.path!, promotion.destinationPath)) {
        // The first-save promotion now owns the destination. A protection
        // staged while that path was vacant must bind to this identity rather
        // than repeating its obsolete vacancy check against itself.
        _protections[bufferId] = (
          snapshot: protection.snapshot,
          reason: protection.reason,
          force: protection.force,
          ignoreBinding: false,
          allowPathChange: false,
          bindResult: true,
          requireVacantPath: false,
          expectedTarget: null,
          captureId: protection.captureId,
        );
      }
      if (!_ownerHasRetainedCaptureWork(bufferId)) {
        _retiredDurableWorkOwnerIds.add(_promotionDurableOwner(promotion));
      }
      _clearFailure(bufferId, _LocalHistoryFailureStage.promotion);
      _showCaptureFailure();
      await _refreshAfterCommit(
        bufferId,
        promotionHistoryGeneration,
        promotionBufferGeneration,
      );
      return true;
    } on Object catch (error) {
      if (!_operationIsCurrent(
        bufferId,
        promotionHistoryGeneration,
        promotionBufferGeneration,
      )) {
        return true;
      }
      _recordFailure(
        bufferId,
        _LocalHistoryCaptureFailure(
          detail: error.toString(),
          displayName: promotion.destinationPath,
          retryable: _captureErrorIsRetryable(error),
          stage: _LocalHistoryFailureStage.promotion,
        ),
      );
      _scheduleCheckpoint(bufferId);
      return false;
    }
  }

  Future<LocalHistoryDocument?> _stalePromotionOwner(
    LocalHistoryPendingIdentityPromotion promotion,
  ) async {
    // Pending promotions are recorded only after a successful first save to a
    // vacant pathname. Older versions did not retire stale pathname owners.
    // Recover those sessions only with evidence that the saved file is still
    // this lineage; never claim a replacement written since that save.
    final snapshot = await _store.load();
    final document = snapshot.documents
        .where((d) => d.id == promotion.documentId)
        .firstOrNull;
    if (document == null ||
        !document.untitled ||
        document.currentPath != null) {
      return null;
    }
    final owner = snapshot.documents
        .where(
          (d) =>
              !d.deleted &&
              d.id != document.id &&
              d.currentPath != null &&
              p.equals(d.currentPath!, promotion.destinationPath),
        )
        .firstOrNull;
    if (owner == null || !owner.updatedAt.isBefore(document.updatedAt)) {
      return null;
    }
    final summary = snapshot.revisionsFor(document.id).firstOrNull;
    if (summary == null) return null;
    final revision = await _store.readRevision(summary.id);
    if (revision == null) return null;
    try {
      final bytes = await File(promotion.destinationPath).readAsBytes();
      return listEquals(bytes, revision.format.encode(revision.source))
          ? owner
          : null;
    } on FileSystemException {
      return null;
    }
  }

  Future<T> _enqueue<T>(String bufferId, Future<T> Function() operation) {
    final prior = _bufferQueues[bufferId] ?? Future<void>.value();
    final result = prior.then((_) async {
      final durableBefore = _durableStateFingerprint();
      try {
        return await operation();
      } finally {
        if (_closedBuffers.contains(bufferId) &&
            (bufferId.startsWith('history-capture:') ||
                bufferId.startsWith('history-promotion:')) &&
            !_ownerHasRetainedCaptureWork(bufferId) &&
            !_pendingPathOperations.any(
              (pathOperation) =>
                  pathOperation.affectedOwners.contains(bufferId),
            )) {
          _retiredDurableWorkOwnerIds.add(bufferId);
        }
        await _persistDurableStateIfChanged(durableBefore);
      }
    });
    late final Future<void> tail;
    tail = result.then<void>((_) {}, onError: (_, _) {}).whenComplete(() {
      if (identical(_bufferQueues[bufferId], tail)) {
        _bufferQueues.remove(bufferId);
        if (_closedBuffers.contains(bufferId) &&
            !_hasOutstandingWork(bufferId)) {
          _retireClosedBuffer(bufferId);
          _showCaptureFailure();
        }
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
    _baselines.clear();
    _baselinesRequiringVacantPath.clear();
    _baselineSaveDestinations.clear();
    _protections.clear();
    if (clearTransitions) _pathTransitions.clear();
  }

  void _scheduleCheckpoint(String bufferId) {
    if (bufferId != _pathRemapOwner && _pathOperationBlocksOwner(bufferId)) {
      _scheduleCheckpoint(_pathRemapOwner);
      return;
    }
    if (!ref.mounted ||
        _settling > 0 ||
        _pathTransitions.containsKey(bufferId) ||
        !_hasRetryableWork(bufferId)) {
      return;
    }
    _checkpointTimers.putIfAbsent(
      bufferId,
      () => _timerFactory(policy.checkpointInterval, () {
        _checkpointTimers.remove(bufferId);
        if (!ref.mounted || _pathTransitions.containsKey(bufferId)) return;
        final historyGeneration = _historyGeneration;
        final bufferGeneration = _bufferGeneration(bufferId);
        unawaited(
          _enqueue(bufferId, () async {
            if (!_operationIsCurrent(
              bufferId,
              historyGeneration,
              bufferGeneration,
            )) {
              return;
            }
            await _settleBufferWork(bufferId, automatic: true);
            _scheduleCheckpoint(bufferId);
          }),
        );
      }),
    );
  }

  Future<bool> _capturePending(
    String bufferId,
    LocalHistoryBufferSnapshot snapshot, {
    bool allowDuringPathTransition = false,
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
      _clearFailure(bufferId, _LocalHistoryFailureStage.checkpoint);
      _showCaptureFailure();
      return true;
    }
    if (snapshot.captureId == null) {
      snapshot = snapshot.withCaptureId(_newPathOperationId());
      if (_pending[bufferId]?.revision == snapshot.revision) {
        _pending[bufferId] = snapshot;
      }
      await _persistDurableStateNow();
    }
    final captured = await _capture(
      snapshot,
      LocalHistoryCaptureReason.automaticCheckpoint,
      allowDuringPathTransition: allowDuringPathTransition,
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
      final failure = _failure(bufferId, _LocalHistoryFailureStage.checkpoint);
      if (captured || failure?.retryable == true) {
        _scheduleCheckpoint(bufferId);
      }
    }
    return captured && !_pending.containsKey(bufferId);
  }

  void _retainPending(LocalHistoryBufferSnapshot snapshot) {
    if (!_pendingIsEligible(snapshot)) return;
    final current = _pending[snapshot.bufferId];
    if (current != null &&
        current.revision == snapshot.revision &&
        current.captureId != null &&
        snapshot.captureId == null) {
      snapshot = snapshot.withCaptureId(current.captureId);
    }
    if (current == null || current.revision <= snapshot.revision) {
      _pending[snapshot.bufferId] = snapshot;
    }
    if (_failure(
          snapshot.bufferId,
          _LocalHistoryFailureStage.checkpoint,
        )?.retryable !=
        false) {
      _scheduleCheckpoint(snapshot.bufferId);
    }
  }

  void _acknowledgePending(String bufferId, int capturedRevision) {
    final pending = _pending[bufferId];
    if (pending != null && pending.revision <= capturedRevision) {
      _pending.remove(bufferId);
      _checkpointTimers.remove(bufferId)?.cancel();
      _clearFailure(
        bufferId,
        _LocalHistoryFailureStage.checkpoint,
        capturedRevision,
      );
      _scheduleCheckpoint(bufferId);
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
    _baselines.remove(bufferId);
    _baselinesRequiringVacantPath.remove(bufferId);
    _baselineSaveDestinations.remove(bufferId);
    _protections.remove(bufferId);
    _captureFailures.remove(bufferId);
  }

  void _removeExcludedCaptureSides(String owner) {
    final excludedPending = policy.excludes(_pending[owner]?.path);
    final excludedBaseline = policy.excludes(_baselines[owner]?.path);
    final excludedDestination = policy.excludes(
      _baselineSaveDestinations[owner]?.path,
    );
    final excludedProtection = policy.excludes(
      _protections[owner]?.snapshot.path,
    );
    final excludedInFlight = policy.excludes(_inFlightSnapshots[owner]?.path);
    if (!excludedPending &&
        !excludedBaseline &&
        !excludedDestination &&
        !excludedProtection &&
        !excludedInFlight) {
      return;
    }

    // Reject an async completion accepted under the previous policy, then
    // remove only the excluded side. A first-save recovery can intentionally
    // carry an untitled source baseline and a named destination obligation on
    // one owner until the source identity is established.
    _bufferGenerations[owner] = _bufferGeneration(owner) + 1;
    _checkpointTimers.remove(owner)?.cancel();
    if (excludedPending) {
      _pending.remove(owner);
      _clearFailure(owner, _LocalHistoryFailureStage.checkpoint);
    }
    if (excludedBaseline) {
      _baselines.remove(owner);
      _baselinesRequiringVacantPath.remove(owner);
      _baselineSaveDestinations.remove(owner);
      _clearFailure(owner, _LocalHistoryFailureStage.baseline);
    } else if (excludedDestination) {
      _baselineSaveDestinations.remove(owner);
    }
    if (excludedProtection) {
      _protections.remove(owner);
      _clearFailure(owner, _LocalHistoryFailureStage.protection);
    }
    if (_ownerHasRetainedCaptureWork(owner)) {
      _scheduleCheckpoint(owner);
    } else if (owner.startsWith('history-capture:') ||
        owner.startsWith('history-promotion:')) {
      _retiredDurableWorkOwnerIds.add(owner);
    }
  }

  Future<void> _applyRecordingPolicy(AppSettings settings) async {
    final durableBefore = _durableStateFingerprint();
    if (!settings.localHistoryRecordingEnabled) {
      final cancelledDetachedOwners = _workOwners.where(
        (owner) =>
            (owner.startsWith('history-capture:') ||
                owner.startsWith('history-promotion:')) &&
            !_pendingUntitledPromotions.containsKey(owner),
      );
      _historyGeneration++;
      _cancelCheckpoints(clearTransitions: false);
      _captureFailures.clear();
      _retiredDurableWorkOwnerIds.addAll(cancelledDetachedOwners);
      for (final operation in _pendingSaveAsOperations.values.toList()) {
        _pendingSaveAsOperations[operation.operationId] = operation
            .cancelHistory();
      }
      _showCaptureFailure();
      _scheduleCheckpoint(_pathRemapOwner);
      await _persistPolicyCancellation(durableBefore);
      return;
    }
    final captureOwners = <String>{
      ..._pending.keys,
      ..._baselines.keys,
      ..._baselineSaveDestinations.keys,
      ..._protections.keys,
      ..._inFlightSnapshots.keys,
    };
    for (final owner in captureOwners) {
      _removeExcludedCaptureSides(owner);
    }
    final excludedPromotions = _pendingUntitledPromotions.values
        .where((promotion) => policy.excludes(promotion.destinationPath))
        .map(
          (promotion) =>
              (promotion.bufferId, _promotionDurableOwner(promotion)),
        )
        .toList(growable: false);
    for (final entry in excludedPromotions) {
      _pendingUntitledPromotions.remove(entry.$1);
      _retiredDurableWorkOwnerIds.add(entry.$2);
    }
    for (final operation in _pendingSaveAsOperations.values.toList()) {
      var narrowed = operation.withRecordedSides(
        source: !policy.excludes(operation.source.path),
        destination: !policy.excludes(operation.destination.path),
      );
      if (policy.excludes(operation.destination.path)) {
        narrowed = narrowed.withoutFirstSaveLineageTransition();
      }
      _pendingSaveAsOperations[operation.operationId] = narrowed;
    }
    _showCaptureFailure();
    await _persistPolicyCancellation(durableBefore);
  }

  Future<void> _persistPolicyCancellation(String durableBefore) async {
    try {
      await _persistDurableStateIfChanged(durableBefore);
    } on Object catch (error) {
      _storeWarning = LocalHistoryWarning(
        LocalHistoryWarningKind.unavailable,
        detail: error.toString(),
      );
      _showCaptureFailure();
    }
  }

  bool _captureErrorIsRetryable(Object error) {
    if (error is LocalHistoryLockTimeout) return true;
    if (error is UnsupportedLocalHistoryFormat) return false;
    if (error is LocalHistoryReconciliationConflict) return false;
    if (error is LocalHistoryStorageException &&
        error.message.contains('larger than the Local History storage limit')) {
      return false;
    }
    if (error is FileSystemException) {
      final code = error.osError?.errorCode;
      if (Platform.isLinux && (code == 1 || code == 13 || code == 20)) {
        return false;
      }
      if (Platform.isWindows && (code == 5 || code == 3 || code == 267)) {
        return false;
      }
    }
    return true;
  }

  bool _sameCapturedSnapshot(
    LocalHistoryBufferSnapshot? left,
    LocalHistoryBufferSnapshot right,
  ) =>
      left != null &&
      left.revision == right.revision &&
      left.text == right.text &&
      _sameOptionalPath(left.path, right.path) &&
      _sameHistoryFormat(left.format, right.format) &&
      left.captureId == right.captureId &&
      left.acceptedClearEpoch == right.acceptedClearEpoch &&
      left.acceptedAt == right.acceptedAt &&
      left.acceptedDocumentId == right.acceptedDocumentId &&
      left.remoteNote == right.remoteNote;

  bool _hasRetryableWork(String id) {
    if (id == _pathRemapOwner) {
      for (var index = 0; index < _pendingPathOperations.length; index++) {
        final operation = _pendingPathOperations[index];
        if (operation.settled || !operation.retryable || !operation.committed) {
          continue;
        }
        if (!_pendingPathOperations
            .take(index)
            .any(
              (earlier) =>
                  !earlier.settled &&
                  earlier.scope.conflictsWith(operation.scope),
            )) {
          return true;
        }
      }
      return false;
    }
    bool retryable(_LocalHistoryFailureStage stage) =>
        _failure(id, stage)?.retryable != false;
    // A failed prerequisite prevents later automatic work from cycling on it.
    if (_baselines.containsKey(id) &&
        !retryable(_LocalHistoryFailureStage.baseline)) {
      return false;
    }
    if (_pendingUntitledPromotions.containsKey(id) &&
        !retryable(_LocalHistoryFailureStage.promotion)) {
      return false;
    }
    return (_baselines.containsKey(id) &&
            retryable(_LocalHistoryFailureStage.baseline)) ||
        (_pending.containsKey(id) &&
            retryable(_LocalHistoryFailureStage.checkpoint)) ||
        (_protections.containsKey(id) &&
            retryable(_LocalHistoryFailureStage.protection)) ||
        (_pendingUntitledPromotions.containsKey(id) &&
            retryable(_LocalHistoryFailureStage.promotion));
  }

  _LocalHistoryCaptureFailure? _failure(
    String id,
    _LocalHistoryFailureStage stage,
  ) => _captureFailures[id]?[stage];

  _LocalHistoryCaptureFailure? _ownerFailure(String? id) {
    final failures = _captureFailures[id];
    // Prefer the operation preventing an explicit protective action, followed
    // by identity and original-source obligations, then coalesced checkpoints.
    return failures?[_LocalHistoryFailureStage.protection] ??
        failures?[_LocalHistoryFailureStage.promotion] ??
        failures?[_LocalHistoryFailureStage.baseline] ??
        failures?[_LocalHistoryFailureStage.checkpoint];
  }

  void _recordFailure(String id, _LocalHistoryCaptureFailure failure) {
    (_captureFailures[id] ??= {})[failure.stage] = failure;
    _showCaptureFailure();
  }

  void _clearFailure(
    String id,
    _LocalHistoryFailureStage stage, [
    int? revision,
  ]) {
    final failure = _failure(id, stage);
    if (failure != null &&
        (revision == null ||
            (stage == _LocalHistoryFailureStage.protection
                ? failure.revision == revision
                : (failure.revision ?? -1) <= revision))) {
      _captureFailures[id]?.remove(stage);
      if (_captureFailures[id]?.isEmpty == true) _captureFailures.remove(id);
    }
  }

  LocalHistoryWarning _failureWarning(
    String id,
    _LocalHistoryCaptureFailure failure,
  ) => LocalHistoryWarning(
    failure.warningKind,
    ownerBufferId: _detachedClosedSourceId(id) ?? id,
    ownerDisplayName: failure.displayName ?? id,
    detail: failure.detail,
  );

  String? _detachedClosedSourceId(String owner) {
    const prefix = 'history-capture:closed:';
    if (!owner.startsWith(prefix)) return null;
    var sourceAndSuffix = owner.substring(prefix.length);
    // _newDetachedOwner appends one process token and one sequence field.
    // Strip exactly those fields so buffer IDs containing ':' remain intact.
    for (var field = 0; field < 2; field++) {
      final separator = sourceAndSuffix.lastIndexOf(':');
      if (separator <= 0) return null;
      sourceAndSuffix = sourceAndSuffix.substring(0, separator);
    }
    return sourceAndSuffix;
  }

  LocalHistoryWarning? _pathWarningForOwner(String? owner) {
    if (owner == null) return null;
    final operation = _pendingPathOperations
        .where(
          (candidate) =>
              candidate.errorDetail != null &&
              candidate.affectedOwners.contains(owner),
        )
        .firstOrNull;
    if (operation == null) return null;
    return LocalHistoryWarning(
      operation.warningKind,
      ownerBufferId: owner,
      ownerDisplayName: operation.warningPath,
      detail: operation.errorDetail,
    );
  }

  LocalHistoryWarning? _pathWarningForDocument(String? documentId) {
    if (documentId == null) return null;
    final operation = _pendingPathOperations
        .where(
          (candidate) =>
              candidate.errorDetail != null &&
              candidate.documentIds.contains(documentId),
        )
        .firstOrNull;
    if (operation == null) return null;
    return LocalHistoryWarning(
      operation.warningKind,
      ownerDisplayName: operation.warningPath,
      detail: operation.errorDetail,
    );
  }

  LocalHistoryWarning? _presentationWarning() {
    final selectedId = state.selectedDocumentId;
    final selectedOwner = _documentIdsByBuffer.entries
        .where(
          (entry) =>
              entry.value == selectedId &&
              _captureFailures.containsKey(entry.key),
        )
        .firstOrNull
        ?.key;
    final scopedOwner = selectedOwner ?? _normalBrowsingScope?.bufferId;
    final scopedFailure = _ownerFailure(scopedOwner);
    if (scopedFailure != null) {
      return _failureWarning(scopedOwner!, scopedFailure);
    }
    final pathWarning =
        _pathWarningForOwner(scopedOwner) ??
        _pathWarningForDocument(state.selectedDocumentId);
    if (pathWarning != null) return pathWarning;
    if (_storeWarning != null) return _storeWarning;
    final retainedPathOperation = _pendingPathOperations
        .where((operation) => operation.errorDetail != null)
        .firstOrNull;
    if (retainedPathOperation != null) {
      return LocalHistoryWarning(
        retainedPathOperation.warningKind,
        ownerDisplayName: retainedPathOperation.warningPath,
        detail: retainedPathOperation.errorDetail,
      );
    }
    final retained = _captureFailures.entries.firstOrNull;
    return retained == null
        ? null
        : _failureWarning(retained.key, _ownerFailure(retained.key)!);
  }

  void _showCaptureFailure() {
    if (ref.mounted) state = state.copyWith(warning: _presentationWarning());
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
    _clearEpochLoaded = true;
    _storeWarning = warning;
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
                    !document.deleted &&
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
    var effectiveWarning = _presentationWarning();
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
    this.displayName,
    this.revision,
    required this.retryable,
    required this.stage,
  });

  final String? detail;
  final String? displayName;
  final int? revision;
  final bool retryable;
  final _LocalHistoryFailureStage stage;

  _LocalHistoryCaptureFailure copyWithDisplayName(String value) =>
      _LocalHistoryCaptureFailure(
        detail: detail,
        displayName: value,
        revision: revision,
        retryable: retryable,
        stage: stage,
      );

  LocalHistoryWarningKind get warningKind => switch (stage) {
    _LocalHistoryFailureStage.baseline ||
    _LocalHistoryFailureStage.checkpoint ||
    _LocalHistoryFailureStage.protection => LocalHistoryWarningKind.capture,
    _LocalHistoryFailureStage.promotion => LocalHistoryWarningKind.pathChange,
  };
}

/// The namespaces reserved by a reconciliation and the stable identities it
/// can change. Remaps always include descendants, regardless of the serialized
/// `recursive` flag (which is only used by deletions).
class _LocalHistoryPathScope {
  _LocalHistoryPathScope({
    required LocalHistoryPathReconciliationKind kind,
    required String sourcePath,
    String? destinationPath,
    required bool recursive,
    Iterable<LocalHistoryPathTarget> targets = const [],
    Set<String> documentIds = const {},
    this.ownerIds = const {},
  }) : documentIds = {
         ...documentIds,
         for (final target in targets) target.documentId,
       },
       namespaces = [
         (
           path: p.normalize(sourcePath),
           recursive:
               kind == LocalHistoryPathReconciliationKind.remap || recursive,
         ),
         if (destinationPath != null)
           (
             path: p.normalize(destinationPath),
             recursive: kind == LocalHistoryPathReconciliationKind.remap,
           ),
         for (final target in targets)
           (path: p.normalize(target.expectedPath), recursive: false),
       ];

  final Set<String> documentIds;
  final Set<String> ownerIds;
  final List<({String path, bool recursive})> namespaces;

  bool conflictsWith(_LocalHistoryPathScope other) =>
      documentIds.any(other.documentIds.contains) ||
      ownerIds.any(other.ownerIds.contains) ||
      namespaces.any(
        (left) => other.namespaces.any(
          (right) =>
              p.equals(left.path, right.path) ||
              left.recursive && p.isWithin(left.path, right.path) ||
              right.recursive && p.isWithin(right.path, left.path),
        ),
      );
}

abstract class _LocalHistoryPathOperation {
  _LocalHistoryPathOperation(
    Set<String> affectedOwners,
    Iterable<LocalHistoryPathTarget> targets, {
    required this.operationId,
    required this.phase,
    this.retainUntilAcknowledged = false,
    this.commitEvidenceOperationId,
  }) : affectedOwners = {...affectedOwners},
       targets = {for (final target in targets) target.documentId: target};

  factory _LocalHistoryPathOperation.fromReconciliation(
    LocalHistoryPathReconciliation reconciliation,
  ) => switch (reconciliation.kind) {
    LocalHistoryPathReconciliationKind.remap => _LocalHistoryPathRemap(
      operationId: reconciliation.operationId,
      phase: reconciliation.phase,
      sourcePath: p.normalize(reconciliation.sourcePath),
      destinationPath: p.normalize(reconciliation.destinationPath!),
      affectedOwners: reconciliation.ownerIds.toSet(),
      targets: reconciliation.targets,
      commitEvidenceOperationId: reconciliation.commitEvidenceOperationId,
    ),
    LocalHistoryPathReconciliationKind.deletion => _LocalHistoryPathDeletion(
      operationId: reconciliation.operationId,
      phase: reconciliation.phase,
      path: p.normalize(reconciliation.sourcePath),
      recursive: reconciliation.recursive,
      affectedOwners: reconciliation.ownerIds.toSet(),
      targets: reconciliation.targets,
      commitEvidenceOperationId: reconciliation.commitEvidenceOperationId,
    ),
  };

  final Set<String> affectedOwners;
  final Map<String, LocalHistoryPathTarget> targets;
  final String operationId;
  LocalHistoryPathReconciliationPhase phase;
  bool get committed => phase == LocalHistoryPathReconciliationPhase.committed;
  set committed(bool value) => phase = value
      ? LocalHistoryPathReconciliationPhase.committed
      : LocalHistoryPathReconciliationPhase.prepared;
  final bool retainUntilAcknowledged;
  final String? commitEvidenceOperationId;
  bool applied = false;
  bool get settled => applied && errorDetail == null;
  bool acknowledgementRequested = false;
  Set<String> get documentIds => targets.keys.toSet();
  bool retryable = true;
  String? errorDetail;

  LocalHistoryWarningKind get warningKind;
  String get warningPath;
  LocalHistoryPathReconciliation get reconciliation;
  _LocalHistoryPathScope get scope {
    final value = reconciliation;
    return _LocalHistoryPathScope(
      kind: value.kind,
      sourcePath: value.sourcePath,
      destinationPath: value.destinationPath,
      recursive: value.recursive,
      targets: targets.values,
      ownerIds: affectedOwners,
    );
  }

  bool blocksPath(String path);
  Future<void> apply(LocalHistoryStore store) =>
      store.reconcilePath(reconciliation);
  void removeDocumentId(String documentId) => targets.remove(documentId);

  bool matches(LocalHistoryPathReconciliation other) =>
      reconciliation.kind == other.kind &&
      p.equals(reconciliation.sourcePath, other.sourcePath) &&
      _sameOptionalPath(
        reconciliation.destinationPath,
        other.destinationPath,
      ) &&
      reconciliation.recursive == other.recursive &&
      targets.length == other.targets.length &&
      other.targets.every((target) {
        final existing = targets[target.documentId];
        return existing != null &&
            p.equals(existing.expectedPath, target.expectedPath) &&
            existing.versionToken == target.versionToken;
      });
}

class _LocalHistoryPathRemap extends _LocalHistoryPathOperation {
  _LocalHistoryPathRemap({
    String operationId = '',
    bool committed = true,
    LocalHistoryPathReconciliationPhase? phase,
    bool retainUntilAcknowledged = false,
    String? commitEvidenceOperationId,
    required this.sourcePath,
    required this.destinationPath,
    required Set<String> affectedOwners,
    required Iterable<LocalHistoryPathTarget> targets,
  }) : super(
         affectedOwners,
         targets,
         operationId: operationId,
         phase:
             phase ??
             (committed
                 ? LocalHistoryPathReconciliationPhase.committed
                 : LocalHistoryPathReconciliationPhase.prepared),
         retainUntilAcknowledged: retainUntilAcknowledged,
         commitEvidenceOperationId: commitEvidenceOperationId,
       );

  final String sourcePath;
  final String destinationPath;

  @override
  LocalHistoryWarningKind get warningKind => LocalHistoryWarningKind.pathChange;

  @override
  String get warningPath => destinationPath;

  @override
  LocalHistoryPathReconciliation get reconciliation =>
      LocalHistoryPathReconciliation.remap(
        operationId: operationId,
        sourcePath: sourcePath,
        destinationPath: destinationPath,
        targets: List.unmodifiable(targets.values),
        ownerIds: List.unmodifiable(affectedOwners),
        commitEvidenceOperationId: commitEvidenceOperationId,
        phase: phase,
      );

  @override
  bool blocksPath(String path) =>
      _historyPathIsAtOrWithin(path, sourcePath) ||
      _historyPathIsAtOrWithin(path, destinationPath);
}

class _LocalHistoryPathDeletion extends _LocalHistoryPathOperation {
  _LocalHistoryPathDeletion({
    String operationId = '',
    bool committed = true,
    LocalHistoryPathReconciliationPhase? phase,
    bool retainUntilAcknowledged = false,
    String? commitEvidenceOperationId,
    required this.path,
    required this.recursive,
    required Set<String> affectedOwners,
    required Iterable<LocalHistoryPathTarget> targets,
  }) : super(
         affectedOwners,
         targets,
         operationId: operationId,
         phase:
             phase ??
             (committed
                 ? LocalHistoryPathReconciliationPhase.committed
                 : LocalHistoryPathReconciliationPhase.prepared),
         retainUntilAcknowledged: retainUntilAcknowledged,
         commitEvidenceOperationId: commitEvidenceOperationId,
       );

  final String path;
  final bool recursive;

  @override
  LocalHistoryWarningKind get warningKind =>
      LocalHistoryWarningKind.deletedPath;

  @override
  String get warningPath => path;

  @override
  LocalHistoryPathReconciliation get reconciliation =>
      LocalHistoryPathReconciliation.deletion(
        operationId: operationId,
        sourcePath: path,
        recursive: recursive,
        targets: List.unmodifiable(targets.values),
        ownerIds: List.unmodifiable(affectedOwners),
        commitEvidenceOperationId: commitEvidenceOperationId,
        phase: phase,
      );

  @override
  bool blocksPath(String candidate) =>
      p.equals(p.normalize(candidate), path) ||
      recursive && p.isWithin(path, p.normalize(candidate));
}

class _SaveAsDestinationBinding {
  const _SaveAsDestinationBinding({
    this.documentId,
    this.expectedTarget,
    this.requireVacantPath = false,
  });

  final String? documentId;
  final LocalHistoryPathTarget? expectedTarget;
  final bool requireVacantPath;
}

bool _sameHistoryFormat(TextFormatMetadata left, TextFormatMetadata right) =>
    left.hasUtf8Bom == right.hasUtf8Bom &&
    left.lineEnding == right.lineEnding &&
    left.hasFinalNewline == right.hasFinalNewline &&
    left.lfCount == right.lfCount &&
    left.crlfCount == right.crlfCount &&
    left.crCount == right.crCount;

enum _LocalHistoryFailureStage { baseline, checkpoint, protection, promotion }

_LocalHistoryFailureStage _stageForReason(LocalHistoryCaptureReason reason) =>
    switch (reason) {
      LocalHistoryCaptureReason.baseline => _LocalHistoryFailureStage.baseline,
      LocalHistoryCaptureReason.saved ||
      LocalHistoryCaptureReason.automaticCheckpoint =>
        _LocalHistoryFailureStage.checkpoint,
      _ => _LocalHistoryFailureStage.protection,
    };

bool _sameOptionalPath(String? first, String? second) {
  if (first == null || second == null) return first == second;
  return p.equals(first, second);
}

bool _historyPathIsAtOrWithin(String path, String root) {
  final normalizedPath = p.normalize(path);
  final normalizedRoot = p.normalize(root);
  return p.equals(normalizedPath, normalizedRoot) ||
      p.isWithin(normalizedRoot, normalizedPath);
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
