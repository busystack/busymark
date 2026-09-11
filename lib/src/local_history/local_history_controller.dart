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
  var _loadGeneration = 0;
  var _searchGeneration = 0;
  var _scopeGeneration = 0;

  @override
  LocalHistoryState build() {
    _store = ref.read(localHistoryStoreProvider);
    _clock = ref.read(localHistoryClockProvider);
    _timerFactory = ref.read(localHistoryTimerFactoryProvider);
    ref.listen<AppSettings>(appSettingsControllerProvider, (previous, next) {
      if (!next.localHistoryRecordingEnabled) _cancelCheckpoints();
    });
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

  Future<void> refresh() async {
    final generation = ++_loadGeneration;
    if (ref.mounted) state = state.copyWith(loading: true);
    try {
      await _store.prune(policy, _clock());
      final snapshot = await _store.load();
      if (!ref.mounted || generation != _loadGeneration) return;
      final selectedDocumentId = state.selectedDocumentId;
      state = state.copyWith(
        snapshot: snapshot,
        loading: false,
        selectedDocumentId:
            selectedDocumentId != null &&
                snapshot.documents.any(
                  (document) => document.id == selectedDocumentId,
                )
            ? selectedDocumentId
            : null,
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
    await _enqueue(snapshot.bufferId, () async {
      final promotion = _pendingUntitledPromotions[snapshot.bufferId];
      if (promotion != null) {
        if (!_sameOptionalPath(snapshot.path, promotion.destinationPath)) {
          _setWarning(LocalHistoryWarningKind.pathChange);
          return;
        }
        if (!await _completePendingUntitledPromotion(snapshot.bufferId)) {
          return;
        }
        final pending = _pending.remove(snapshot.bufferId);
        _checkpointTimers.remove(snapshot.bufferId)?.cancel();
        if (pending != null) {
          await _capture(
            pending,
            LocalHistoryCaptureReason.automaticCheckpoint,
          );
        }
        await _capture(snapshot, LocalHistoryCaptureReason.baseline);
        return;
      }
      if (adoptedPromotion != null) return;
      if (_documentIdsByBuffer.containsKey(snapshot.bufferId)) return;
      await _capture(snapshot, LocalHistoryCaptureReason.baseline);
    });
  }

  void observeEdit(DocumentBuffer previous, DocumentBuffer current) {
    if (!policy.recordingEnabled || policy.excludes(current.filePath)) return;
    final previousSnapshot = LocalHistoryBufferSnapshot.fromBuffer(previous);
    final currentSnapshot = LocalHistoryBufferSnapshot.fromBuffer(current);
    unawaited(
      _enqueue(current.id, () async {
        if (!ref.mounted) return;
        if (!_documentIdsByBuffer.containsKey(current.id) &&
            !(previousSnapshot.untitled && previousSnapshot.text.isEmpty)) {
          await _capture(previousSnapshot, LocalHistoryCaptureReason.baseline);
        }
        if (!ref.mounted) return;
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
    return _enqueue(
      snapshot.bufferId,
      () => _capture(snapshot, LocalHistoryCaptureReason.saved),
    );
  }

  Future<bool> captureProtective(
    LocalHistoryBufferSnapshot snapshot,
    LocalHistoryCaptureReason reason,
  ) async {
    if (!policy.recordingEnabled || policy.excludes(snapshot.path)) {
      _setWarning(LocalHistoryWarningKind.recordingDisabled);
      return false;
    }
    return _enqueue(
      snapshot.bufferId,
      () => _capture(snapshot, reason, force: true),
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
    return _enqueue(
      snapshot.bufferId,
      () => _capture(snapshot, reason, force: true),
    );
  }

  Future<bool> captureSavedAs(
    LocalHistoryBufferSnapshot source,
    String destinationPath, {
    required bool destinationExisted,
  }) async {
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
          );
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
        _pending.remove(source.bufferId);
        _checkpointTimers.remove(source.bufferId)?.cancel();
        final pendingCaptured = await _capture(
          pending,
          LocalHistoryCaptureReason.automaticCheckpoint,
          allowDuringPathTransition: true,
        );
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
        );
        if (!promotionCompleted) return false;
      }

      if (!policy.recordingEnabled || policy.excludes(destination.path)) {
        return source.untitled && !destinationExisted && promotionCompleted;
      }
      return _capture(
        destination,
        LocalHistoryCaptureReason.saved,
        ignoreBinding: !source.untitled || destinationExisted,
      );
    });
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
    return _capture(
      LocalHistoryBufferSnapshot(
        bufferId: 'path:${p.normalize(path)}',
        displayName: p.basename(path),
        text: text,
        format: format,
        revision: 0,
        path: path,
      ),
      reason,
      force: force,
      ignoreBinding: true,
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
    final pending = _pending.remove(buffer.id);
    if (pending != null) {
      await _enqueue(
        buffer.id,
        () => _capture(
          LocalHistoryBufferSnapshot.fromBuffer(buffer),
          LocalHistoryCaptureReason.automaticCheckpoint,
        ),
      );
    }
    if (_pendingUntitledPromotions.containsKey(buffer.id)) {
      return _enqueue(
        buffer.id,
        () => _completePendingUntitledPromotion(buffer.id),
      );
    }
    return true;
  }

  Future<bool> flushPendingIdentityPromotions() async {
    var succeeded = true;
    for (final bufferId in _pendingUntitledPromotions.keys.toList()) {
      if (!await _enqueue(bufferId, () async {
        if (!await _completePendingUntitledPromotion(bufferId)) return false;
        final pending = _pending.remove(bufferId);
        _checkpointTimers.remove(bufferId)?.cancel();
        if (pending == null) return true;
        await _capture(pending, LocalHistoryCaptureReason.automaticCheckpoint);
        return true;
      })) {
        succeeded = false;
      }
    }
    return succeeded && _pendingUntitledPromotions.isEmpty;
  }

  Future<bool> flushAll(Iterable<DocumentBuffer> buffers) async {
    var succeeded = true;
    for (final buffer in buffers) {
      if (!await flushBuffer(buffer)) succeeded = false;
    }
    if (!await flushPendingIdentityPromotions()) succeeded = false;
    while (_bufferQueues.isNotEmpty) {
      await Future.wait(_bufferQueues.values.toList(growable: false));
    }
    return succeeded && _pendingUntitledPromotions.isEmpty;
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
        _pending.remove(entry.key);
        _checkpointTimers.remove(entry.key)?.cancel();
        await _enqueue(
          entry.key,
          () => _capture(
            entry.value,
            LocalHistoryCaptureReason.automaticCheckpoint,
          ),
        );
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
    final normalized = query;
    final generation = ++_searchGeneration;
    state = state.copyWith(
      searchQuery: normalized,
      searching: normalized.isNotEmpty,
      searchMatches: const {},
      documentSearchMatches: const {},
    );
    if (normalized.isEmpty) return;
    final documentId = state.selectedDocumentId;
    final summaries = state.findingDocuments
        ? state.snapshot.revisions
        : documentId == null
        ? const <LocalHistoryRevisionSummary>[]
        : state.snapshot.revisionsFor(documentId);
    final matches = <String>{};
    final documentMatches = <String>{};
    final needle = normalized.toLowerCase();
    if (state.findingDocuments) {
      for (final document in state.snapshot.documents) {
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
      if (!ref.mounted || generation != _searchGeneration) return;
      if (revision?.source.toLowerCase().contains(needle) == true) {
        matches.add(summary.id);
        documentMatches.add(summary.documentId);
      }
    }
    if (!ref.mounted || generation != _searchGeneration) return;
    state = state.copyWith(
      searching: false,
      searchMatches: matches,
      documentSearchMatches: documentMatches,
    );
  }

  Future<void> clearDocument(String documentId) async {
    await _store.clearDocument(documentId);
    _documentIdsByBuffer.removeWhere((_, value) => value == documentId);
    _pendingUntitledPromotions.removeWhere(
      (_, promotion) => promotion.documentId == documentId,
    );
    await refresh();
  }

  Future<void> clearAll() async {
    _cancelCheckpoints();
    _documentIdsByBuffer.clear();
    _pendingUntitledPromotions.clear();
    await _store.clearAll();
    await refresh();
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
  }) async {
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
      if (!await _completePendingUntitledPromotion(snapshot.bufferId)) {
        return false;
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
      if (!ignoreBinding) {
        _documentIdsByBuffer[snapshot.bufferId] = result.document.id;
      }
      if (ref.mounted) {
        final loaded = await _store.load();
        if (ref.mounted) {
          state = state.copyWith(snapshot: loaded, warning: null);
        }
      }
      return true;
    } on Object catch (error) {
      _setWarning(LocalHistoryWarningKind.capture, error.toString());
      return false;
    }
  }

  Future<bool> _completePendingUntitledPromotion(String bufferId) async {
    final promotion = _pendingUntitledPromotions[bufferId];
    if (promotion == null) return true;
    try {
      final document = await _store.promoteUntitledDocument(
        documentId: promotion.documentId,
        destinationPath: promotion.destinationPath,
        displayName: promotion.displayName,
        updatedAt: _clock().toUtc(),
      );
      if (document == null) {
        _setWarning(LocalHistoryWarningKind.pathChange);
        return false;
      }
      _documentIdsByBuffer[bufferId] = document.id;
      _pendingUntitledPromotions.remove(bufferId);
      if (ref.mounted) {
        final loaded = await _store.load();
        if (ref.mounted) {
          state = state.copyWith(snapshot: loaded, warning: null);
        }
      }
      return true;
    } on Object catch (error) {
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

  void _cancelCheckpoints() {
    for (final timer in _checkpointTimers.values) {
      timer.cancel();
    }
    _checkpointTimers.clear();
    _pending.clear();
    _pathTransitions.clear();
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
        final latest = _pending.remove(bufferId);
        if (latest != null) {
          unawaited(
            _enqueue(
              bufferId,
              () => _capture(
                latest,
                LocalHistoryCaptureReason.automaticCheckpoint,
              ),
            ),
          );
        }
      }),
    );
  }

  void _setWarning(LocalHistoryWarningKind kind, [String? detail]) {
    if (ref.mounted) {
      state = state.copyWith(
        warning: LocalHistoryWarning(kind, detail: detail),
      );
    }
  }
}

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
