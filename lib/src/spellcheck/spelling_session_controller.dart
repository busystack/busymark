import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../app/app_settings.dart';
import '../core/atomic_file_writer.dart';
import '../markdown/busymark_document.dart';
import '../markdown/markdown_model.dart';
import '../workspace/document_buffer.dart';
import '../workspace/workspace_model.dart';
import 'spelling_catalog.dart';
import 'spelling_coordinator.dart';
import 'spelling_dictionary_downloader.dart';
import 'spelling_dictionary_importer.dart';
import 'spelling_dictionary_installer.dart';
import 'spelling_language.dart';
import 'spelling_projection.dart';
import 'spelling_word_store.dart';
import 'spelling_worker.dart';

typedef SpellingCoordinatorStarter = Future<SpellingCoordinator> Function();
typedef SpellingWordStoreFactory =
    SpellingWordStore Function({
      required String filePath,
      required bool projectStore,
    });
typedef SpellingWordStoreReader =
    Future<SpellingWordStoreSnapshot> Function(SpellingWordStore store);

SpellingWordStore _createSpellingWordStore({
  required String filePath,
  required bool projectStore,
}) => SpellingWordStore(filePath: filePath, projectStore: projectStore);

Future<SpellingWordStoreSnapshot> _readSpellingWordStore(
  SpellingWordStore store,
) => store.read();

final spellingSessionControllerProvider =
    ChangeNotifierProvider<SpellingSessionController>((ref) {
      return SpellingSessionController(
        applicationSupportRoot: Platform.environment.containsKey('FLUTTER_TEST')
            ? p.join(Directory.systemTemp.path, 'busymark-spelling-tests-$pid')
            : null,
      );
    });

enum SpellingDictionaryInstallPhase { downloading, validating, failed }

final class SpellingDictionaryInstallStatus {
  const SpellingDictionaryInstallStatus({
    required this.resourceId,
    required this.phase,
    required this.receivedBytes,
    required this.totalBytes,
    this.error,
  });

  final String resourceId;
  final SpellingDictionaryInstallPhase phase;
  final int receivedBytes;
  final int totalBytes;
  final String? error;

  double? get progress =>
      totalBytes <= 0 ? null : (receivedBytes / totalBytes).clamp(0.0, 1.0);
}

/// Application-side owner for the one reusable native spelling worker.
///
/// This class deliberately owns presentation state rather than putting
/// annotations in [DocumentBuffer]. Checking therefore cannot dirty a buffer,
/// create history, serialize a rich document, or trigger autosave.
final class SpellingSessionController extends ChangeNotifier {
  SpellingSessionController({
    this.bundledRoot,
    this.applicationSupportRoot,
    this.dictionaryStorageRoot,
    this.environment,
    this.verifyDictionaryChecksums = true,
    this.dictionaryDownloader = const SpellingDictionaryDownloader(),
    this.dictionaryInstaller = const SpellingDictionaryPairInstaller(),
    SpellingCoordinatorStarter? coordinatorStarter,
    SpellingWordStoreFactory? wordStoreFactory,
    SpellingWordStoreReader? wordStoreReader,
  }) : coordinatorStarter = coordinatorStarter ?? SpellingCoordinator.start,
       wordStoreFactory = wordStoreFactory ?? _createSpellingWordStore,
       wordStoreReader = wordStoreReader ?? _readSpellingWordStore;

  final String? bundledRoot;
  final String? applicationSupportRoot;
  final String? dictionaryStorageRoot;
  final Map<String, String>? environment;
  final bool verifyDictionaryChecksums;
  final SpellingDictionaryDownloader dictionaryDownloader;
  final SpellingDictionaryPairInstaller dictionaryInstaller;
  final SpellingCoordinatorStarter coordinatorStarter;
  final SpellingWordStoreFactory wordStoreFactory;
  final SpellingWordStoreReader wordStoreReader;

  SpellingCoordinator? _coordinator;
  Future<SpellingCoordinator>? _coordinatorStartup;
  SpellingDictionaryCatalog? _catalog;
  SpellingWordStore? _personalStore;
  SpellingWordStore? _projectStore;
  SpellingWordStoreSnapshot _personalWords = const SpellingWordStoreSnapshot(
    revision: 0,
    wordsByLanguage: {},
  );
  SpellingWordStoreSnapshot _projectWords = const SpellingWordStoreSnapshot(
    revision: 0,
    wordsByLanguage: {},
  );
  SpellingPresentationState _localState =
      const SpellingPresentationState.languageRequired();
  SpellingEngineContext? _engineContext;
  SpellingSessionInput? _latestInput;
  String? _projectRoot;
  Workspace? _settingsWorkspace;
  String? _supportRoot;
  String? _resolvedDictionaryStorageRoot;
  bool _personalStorageInitialized = false;
  bool _projectStorageInitialized = false;
  Future<({SpellingWordStore store, SpellingWordStoreSnapshot snapshot})>?
  _personalStorageLoad;
  String? _requestedProjectRoot;
  int _projectStorageGeneration = 0;
  String _scheduledIdentity = '';
  String _contextIdentity = '';
  int _contextGeneration = 0;
  int _operation = 0;
  bool _disposed = false;
  bool _manualReviewActive = false;
  Set<String> _openBufferIds = const {};
  SpellingDictionaryDownloadCancellation? _dictionaryDownloadCancellation;
  SpellingDictionaryInstallStatus? _dictionaryInstallStatus;
  bool _presentationUsesLocalState = true;
  StreamSubscription<FileSystemEvent>? _projectStoreWatcher;
  Timer? _projectStoreReloadDebounce;
  String? _watchedProjectFile;
  String? _watchedProjectDirectory;
  int _projectWatcherGeneration = 0;

  SpellingPresentationState get state => _presentationUsesLocalState
      ? _localState
      : (_coordinator?.state ?? _localState);
  List<SpellingAnnotation> get annotations => _presentationUsesLocalState
      ? const []
      : _coordinator?.annotations ?? const [];
  List<SpellingOccurrence> get misspellings => _presentationUsesLocalState
      ? const []
      : _coordinator?.misspellings ?? const [];
  SpellingDictionaryCatalog? get catalog => _catalog;
  SpellingDictionaryInstallStatus? get dictionaryInstallStatus =>
      _dictionaryInstallStatus;
  String? get effectiveLanguage => _engineContext?.languageId;
  bool get hasProjectScope => _projectStore != null;
  SpellingWordStoreSnapshot get personalWords => _personalWords;
  SpellingWordStoreSnapshot get projectWords => _projectWords;

  Future<void> prepareSettings(Workspace? workspace) async {
    _settingsWorkspace = workspace;
    await _initializeStorage(workspace);
    if (!_disposed) notifyListeners();
  }

  void update(SpellingSessionInput input) {
    final identity = input.identity;
    if (identity == _scheduledIdentity) {
      // An equivalent rebuild must not replace the object tracked by an
      // in-flight initialization operation. Its immutable identity already
      // represents this snapshot.
      return;
    }
    _latestInput = input;
    _scheduledIdentity = identity;
    final operation = ++_operation;
    _invalidatePresentation();
    unawaited(
      _prepareAndSchedule(
        input,
        operation: operation,
        manual: _manualReviewActive,
      ),
    );
  }

  Future<void> checkNow(SpellingSessionInput input) async {
    _manualReviewActive = true;
    _latestInput = input;
    _scheduledIdentity = input.identity;
    final operation = ++_operation;
    _invalidatePresentation();
    await _prepareAndSchedule(input, operation: operation, manual: true);
  }

  void endManualReview() {
    if (!_manualReviewActive) return;
    _manualReviewActive = false;
    _scheduledIdentity = '';
    final input = _latestInput;
    if (input != null) update(input.refreshed());
  }

  Future<List<String>> suggestions(SpellingOccurrence occurrence) async {
    final coordinator = _coordinator;
    final context = _engineContext;
    if (coordinator == null || context == null) {
      throw StateError('Dictionary unavailable.');
    }
    if (!isCurrent(occurrence)) {
      throw StateError('The spelling occurrence is stale.');
    }
    final contextIdentity = context.identity;
    final result = await coordinator.suggestions(occurrence, context: context);
    if (!isCurrent(occurrence) || _engineContext?.identity != contextIdentity) {
      throw StateError('The spelling occurrence became stale.');
    }
    return result;
  }

  bool isCurrent(SpellingOccurrence occurrence) =>
      !_presentationUsesLocalState &&
      occurrence.run.snapshot.bufferId == _latestInput?.buffer.id &&
      occurrence.run.snapshot.contentRevision ==
          _latestInput?.buffer.revision &&
      occurrence.run.snapshot.documentKind == _latestInput?.documentKind &&
      occurrence.run.snapshot.contextGeneration == _contextGeneration &&
      occurrence.run.languageId == _engineContext?.languageId &&
      (_coordinator?.isCurrent(occurrence) ?? false);

  SpellingOccurrence? occurrenceAtSource(int offset) =>
      _presentationUsesLocalState
      ? null
      : _coordinator?.occurrenceAtSource(offset);

  SpellingOccurrence? occurrenceAtField({
    required SpellingEditorTarget target,
    required int offset,
  }) => _presentationUsesLocalState
      ? null
      : _coordinator?.occurrenceAtField(target: target, offset: offset);

  void ignoreOnce(SpellingOccurrence occurrence) {
    if (isCurrent(occurrence)) _coordinator?.ignoreOnce(occurrence);
  }

  void ignoreAllInDocument(SpellingOccurrence occurrence) {
    if (isCurrent(occurrence)) _coordinator?.ignoreAllInDocument(occurrence);
  }

  Future<void> addPersonalWord(SpellingOccurrence occurrence) async {
    _requireCurrent(occurrence);
    final store = _personalStore;
    if (store == null) throw StateError('Personal dictionary is unavailable.');
    late final SpellingWordStoreSnapshot updated;
    try {
      updated = await store.addWord(occurrence.run.languageId, occurrence.word);
    } on AtomicFileChangedException catch (error, stackTrace) {
      await _reconcilePersonalStoreConflict(store);
      Error.throwWithStackTrace(error, stackTrace);
    }
    if (!identical(store, _personalStore)) return;
    _personalWords = updated;
    await _refreshAfterPersistentChange();
  }

  Future<void> addProjectWord(SpellingOccurrence occurrence) async {
    _requireCurrent(occurrence);
    final store = _projectStore;
    if (store == null) {
      throw StateError('This document is not associated with a project.');
    }
    final projectRoot = _projectRoot;
    late final SpellingWordStoreSnapshot updated;
    try {
      updated = await store.addWord(occurrence.run.languageId, occurrence.word);
    } on AtomicFileChangedException catch (error, stackTrace) {
      await _reconcileProjectStoreConflict(store, projectRoot);
      Error.throwWithStackTrace(error, stackTrace);
    }
    if (!identical(store, _projectStore) || projectRoot != _projectRoot) return;
    _projectWords = updated;
    await _refreshAfterPersistentChange();
  }

  Future<void> removePersonalWord(String languageId, String word) async {
    final store = _personalStore;
    if (store == null) throw StateError('Personal dictionary is unavailable.');
    late final SpellingWordStoreSnapshot updated;
    try {
      updated = await store.removeWord(languageId, word);
    } on AtomicFileChangedException catch (error, stackTrace) {
      await _reconcilePersonalStoreConflict(store);
      Error.throwWithStackTrace(error, stackTrace);
    }
    if (!identical(store, _personalStore)) return;
    _personalWords = updated;
    await _refreshAfterPersistentChange();
  }

  Future<void> removeProjectWord(String languageId, String word) async {
    final store = _projectStore;
    if (store == null) throw StateError('Project dictionary is unavailable.');
    final projectRoot = _projectRoot;
    late final SpellingWordStoreSnapshot updated;
    try {
      updated = await store.removeWord(languageId, word);
    } on AtomicFileChangedException catch (error, stackTrace) {
      await _reconcileProjectStoreConflict(store, projectRoot);
      Error.throwWithStackTrace(error, stackTrace);
    }
    if (!identical(store, _projectStore) || projectRoot != _projectRoot) return;
    _projectWords = updated;
    await _refreshAfterPersistentChange();
  }

  Future<void> importDictionary({
    required String affPath,
    required String dicPath,
    required String languageId,
    required String displayLabel,
  }) async {
    await _ensureStorageRoot();
    await _initializeStorage(_latestInput?.workspace ?? _settingsWorkspace);
    final normalizedLanguage = normalizeSpellingLanguageId(languageId);
    if (normalizedLanguage == null) {
      throw const FormatException('Choose an explicit valid language tag.');
    }
    final collision =
        _catalog?.installations.any(
          (installation) => installation.resourceId == normalizedLanguage,
        ) ??
        false;
    final invalidCollision =
        _catalog?.invalidInstallations.any(
          (installation) =>
              installation.resourceId == normalizedLanguage ||
              installation.id == normalizedLanguage,
        ) ??
        false;
    if (collision || invalidCollision) {
      throw StateError(
        'A dictionary installation already uses $normalizedLanguage. '
        'Remove it before importing a replacement.',
      );
    }
    final dictionaryRoot = await _ensureDictionaryStorageRoot();
    await _ensureCoordinator();
    final coordinator = _coordinator;
    if (coordinator == null) {
      throw StateError('The spelling service is unavailable.');
    }
    await const SpellingDictionaryImporter().import(
      affPath: affPath,
      dicPath: dicPath,
      languageId: languageId,
      displayLabel: displayLabel,
      importedRoot: p.join(dictionaryRoot, 'imported'),
      validateNativePair: (aff, dic, probe) => coordinator.validateDictionary(
        affPath: aff,
        dicPath: dic,
        knownValidProbe: probe,
      ),
    );
    await _reloadCatalogAndRefresh();
  }

  Future<void> removeImportedDictionary(String languageId) async {
    await _initializeStorage(_latestInput?.workspace ?? _settingsWorkspace);
    final installation = _catalog?.installedById(languageId);
    if (installation != null && installation.imported) {
      await _releaseAndRemoveInstallation(installation);
      return;
    }
    final invalid = _catalog?.invalidById(languageId);
    if (invalid != null &&
        invalid.kind == SpellingDictionaryInstallationKind.imported) {
      await _releaseAndRemoveInvalidInstallation(invalid);
    }
  }

  Future<void> removeInvalidDictionary(
    SpellingInvalidDictionaryInstallation installation,
  ) async {
    await _initializeStorage(_latestInput?.workspace ?? _settingsWorkspace);
    final current =
        _catalog?.invalidInstallations.any(
          (candidate) =>
              candidate.directoryPath == installation.directoryPath &&
              candidate.kind == installation.kind,
        ) ??
        false;
    if (!current) return;
    await _releaseAndRemoveInvalidInstallation(installation);
  }

  Future<void> installDictionary(String languageId) async {
    await _initializeStorage(_latestInput?.workspace ?? _settingsWorkspace);
    final catalog = _catalog;
    final resource = catalog?.availableById(languageId);
    if (resource == null) {
      throw StateError('Dictionary resource is not in the shipped catalog.');
    }
    final existing = catalog!.installationForResource(resource.resourceId);
    if (existing != null) {
      if (existing.kind == SpellingDictionaryInstallationKind.downloaded) {
        return;
      }
      throw StateError(
        'Remove the local import before installing the catalog dictionary.',
      );
    }
    final invalidInstallation = catalog.invalidInstallations
        .where(
          (candidate) =>
              candidate.kind == SpellingDictionaryInstallationKind.downloaded &&
              (candidate.resourceId == resource.resourceId ||
                  candidate.matches(resource.resourceId)),
        )
        .firstOrNull;
    if (_dictionaryDownloadCancellation != null) {
      throw StateError('Another dictionary installation is in progress.');
    }
    final dictionaryRoot = await _ensureDictionaryStorageRoot();
    await _ensureCoordinator();
    final coordinator = _coordinator;
    if (coordinator == null) {
      throw StateError('The spelling service is unavailable.');
    }
    final cancellation = SpellingDictionaryDownloadCancellation();
    _dictionaryDownloadCancellation = cancellation;
    _dictionaryInstallStatus = SpellingDictionaryInstallStatus(
      resourceId: resource.resourceId,
      phase: SpellingDictionaryInstallPhase.downloading,
      receivedBytes: 0,
      totalBytes: resource.downloadSize,
    );
    notifyListeners();
    try {
      await dictionaryDownloader.install(
        resource: resource,
        downloadedRoot: p.join(dictionaryRoot, 'downloaded'),
        validateNativePair: (aff, dic, probe) => coordinator.validateDictionary(
          affPath: aff,
          dicPath: dic,
          knownValidProbe: probe,
        ),
        cancellation: cancellation,
        onProgress: (received, total) {
          if (_disposed ||
              !identical(_dictionaryDownloadCancellation, cancellation)) {
            return;
          }
          _dictionaryInstallStatus = SpellingDictionaryInstallStatus(
            resourceId: resource.resourceId,
            phase: received >= total
                ? SpellingDictionaryInstallPhase.validating
                : SpellingDictionaryInstallPhase.downloading,
            receivedBytes: received,
            totalBytes: total,
          );
          notifyListeners();
        },
        replaceExisting: invalidInstallation != null,
      );
      _dictionaryInstallStatus = null;
      await _reloadCatalogAndRefresh();
    } on SpellingDictionaryDownloadCancelled {
      _dictionaryInstallStatus = null;
      if (!_disposed) notifyListeners();
    } on Object catch (error) {
      _dictionaryInstallStatus = SpellingDictionaryInstallStatus(
        resourceId: resource.resourceId,
        phase: SpellingDictionaryInstallPhase.failed,
        receivedBytes: _dictionaryInstallStatus?.receivedBytes ?? 0,
        totalBytes: resource.downloadSize,
        error: error.toString(),
      );
      if (!_disposed) notifyListeners();
      rethrow;
    } finally {
      if (identical(_dictionaryDownloadCancellation, cancellation)) {
        _dictionaryDownloadCancellation = null;
      }
    }
  }

  void cancelDictionaryInstallation() {
    _dictionaryDownloadCancellation?.cancel();
  }

  Future<void> retryDictionaryInstallation() async {
    final status = _dictionaryInstallStatus;
    if (status == null ||
        status.phase != SpellingDictionaryInstallPhase.failed) {
      return;
    }
    _dictionaryInstallStatus = null;
    final resource = _catalog?.availableEntries
        .where((entry) => entry.resourceId == status.resourceId)
        .firstOrNull;
    if (resource == null) return;
    await installDictionary(resource.id);
  }

  Future<void> removeDownloadedDictionary(String languageId) async {
    await _initializeStorage(_latestInput?.workspace ?? _settingsWorkspace);
    final catalog = _catalog;
    final resource = catalog?.availableById(languageId);
    final installation = resource == null
        ? catalog?.installations
              .where(
                (candidate) =>
                    candidate.kind ==
                        SpellingDictionaryInstallationKind.downloaded &&
                    (candidate.id == languageId ||
                        candidate.locales.contains(languageId)),
              )
              .firstOrNull
        : catalog?.installationForResource(
            resource.resourceId,
            kind: SpellingDictionaryInstallationKind.downloaded,
          );
    if (installation != null) {
      await _releaseAndRemoveInstallation(installation);
      return;
    }
    final invalid = catalog?.invalidInstallations
        .where(
          (candidate) =>
              candidate.kind == SpellingDictionaryInstallationKind.downloaded &&
              (candidate.matches(languageId) ||
                  resource != null &&
                      candidate.resourceId == resource.resourceId),
        )
        .firstOrNull;
    if (invalid != null &&
        invalid.kind == SpellingDictionaryInstallationKind.downloaded) {
      await _releaseAndRemoveInvalidInstallation(invalid);
    }
  }

  Future<void> setProjectLanguage(String? languageId) async {
    final store = _projectStore;
    if (store == null) {
      throw StateError('This workspace has no project spelling scope.');
    }
    final projectRoot = _projectRoot;
    late final SpellingWordStoreSnapshot updated;
    try {
      updated = await store.setProjectLanguage(languageId);
    } on AtomicFileChangedException catch (error, stackTrace) {
      await _reconcileProjectStoreConflict(store, projectRoot);
      Error.throwWithStackTrace(error, stackTrace);
    }
    if (!identical(store, _projectStore) || projectRoot != _projectRoot) return;
    _projectWords = updated;
    await _refreshAfterPersistentChange();
  }

  Future<void> _reconcilePersonalStoreConflict(SpellingWordStore store) async {
    if (!identical(store, _personalStore)) return;
    try {
      final actual = await wordStoreReader(store);
      if (!identical(store, _personalStore)) return;
      _personalWords = actual;
      await _refreshAfterPersistentChange();
    } on Object {
      // Reconciliation is best effort; the publication conflict remains the
      // caller-visible failure and must retain its recovery-path detail.
    }
  }

  Future<void> _reconcileProjectStoreConflict(
    SpellingWordStore store,
    String? projectRoot,
  ) async {
    if (!identical(store, _projectStore) || projectRoot != _projectRoot) return;
    try {
      final actual = await wordStoreReader(store);
      if (!identical(store, _projectStore) || projectRoot != _projectRoot) {
        return;
      }
      _projectWords = actual;
      await _refreshAfterPersistentChange();
    } on Object {
      // Preserve the original typed conflict for the initiating UI.
    }
  }

  void closeBuffer(String bufferId) => _coordinator?.closeBuffer(bufferId);

  void invalidateBufferAnchors(String bufferId) =>
      _coordinator?.invalidateBufferAnchors(bufferId);

  /// Clears document-session ignores only for buffers that actually left the
  /// workspace. Merely activating another tab must retain them.
  void synchronizeOpenBuffers(Iterable<String> bufferIds) {
    final next = Set<String>.unmodifiable(bufferIds);
    for (final previous in _openBufferIds) {
      if (!next.contains(previous)) _coordinator?.closeBuffer(previous);
    }
    _openBufferIds = next;
  }

  void translateSourceEdit({
    required String bufferId,
    required int start,
    required int oldEnd,
    required int newEnd,
  }) => _coordinator?.translateSourceEdit(
    bufferId: bufferId,
    start: start,
    oldEnd: oldEnd,
    newEnd: newEnd,
  );

  Future<void> _prepareAndSchedule(
    SpellingSessionInput input, {
    required int operation,
    bool manual = false,
  }) async {
    final override = input.buffer.editorState.spellingLanguage;
    if (override.kind == SpellingLanguageOverrideKind.disabled) {
      _showDisabled();
      return;
    }
    if (!manual && !input.settings.automaticSpelling) {
      _showDisabled();
      return;
    }
    if (!input.documentKind.supportsSpelling) {
      _showDisabled();
      return;
    }
    try {
      await _initializeStorage(input.workspace);
      if (!_isOperationCurrent(operation, input)) return;
      final languageId = resolveSpellingLanguageId(
        override: override,
        projectLanguage: _projectWords.projectLanguage,
        defaultLanguage: input.settings.defaultSpellingLanguage,
      );
      if (languageId == null) {
        _showLanguageRequired();
        return;
      }
      final entry = _catalog?.byId(languageId);
      if (entry == null) {
        await _ensureCoordinator();
        if (!_isOperationCurrent(operation, input)) return;
        _presentationUsesLocalState = false;
        _coordinator!.showDictionaryUnavailable(languageId);
        return;
      }
      final installation = entry.installation;
      if (installation == null) {
        await _ensureCoordinator();
        if (!_isOperationCurrent(operation, input)) return;
        _engineContext = null;
        _presentationUsesLocalState = false;
        _coordinator!.showDictionaryNotInstalled(languageId);
        return;
      }
      final customWords = <String>{
        ..._personalWords.wordsFor(languageId),
        ..._projectWords.wordsFor(languageId),
      }.toList(growable: false);
      final nextEngineContext = SpellingEngineContext(
        languageId: languageId,
        affPath: installation.affPath,
        dicPath: installation.dicPath,
        baseFingerprint: installation.fingerprint,
        personalRevision: _personalWords.revision,
        projectIdentity: _projectRoot,
        projectRevision: _projectWords.revision,
        customWords: customWords,
      );
      if (nextEngineContext.identity != _contextIdentity) {
        _contextIdentity = nextEngineContext.identity;
        _contextGeneration++;
      }
      _engineContext = nextEngineContext;
      final snapshot = SpellingSnapshotIdentity(
        bufferId: input.buffer.id,
        contentRevision: input.buffer.revision,
        documentKind: input.documentKind,
        contextGeneration: _contextGeneration,
      );
      final request = SpellingCheckRequest(
        snapshot: snapshot,
        engineContext: _engineContext!,
        automatic: !manual,
        project: () => _projectOnWorker(input, languageId, snapshot),
      );
      await _ensureCoordinator();
      if (!_isOperationCurrent(operation, input)) return;
      if (manual) {
        _presentationUsesLocalState = false;
        await _coordinator!.checkNow(request);
      } else {
        _presentationUsesLocalState = false;
        _coordinator!.schedule(request);
      }
    } on Object catch (error) {
      if (!_isOperationCurrent(operation, input)) return;
      _localState = SpellingPresentationState(
        status: SpellingPresentationStatus.failure,
        occurrences: const [],
        complete: false,
        message: error.toString(),
      );
      _presentationUsesLocalState = true;
      notifyListeners();
    }
  }

  Future<SpellingProjectionResult> _projectOnWorker(
    SpellingSessionInput input,
    String languageId,
    SpellingSnapshotIdentity snapshot,
  ) {
    final coordinator = _coordinator;
    if (coordinator == null) {
      throw StateError('The spelling worker is unavailable.');
    }
    return coordinator.project(
      SpellingProjectionJob(
        filePath: input.buffer.filePath ?? input.buffer.id,
        source: input.buffer.text,
        documentKind: input.documentKind,
        markdownMode: input.markdownMode,
        languageId: languageId,
        snapshot: snapshot,
        richDocument: input.richDocument,
        richDocumentGeneration: input.richDocumentGeneration,
      ),
    );
  }

  Future<void> _initializeStorage(Workspace? workspace) async {
    final supportRoot = await _ensureStorageRoot();
    if (!_personalStorageInitialized) {
      final load = _personalStorageLoad ??= () async {
        final store = wordStoreFactory(
          filePath: p.join(supportRoot, 'spelling', 'personal.json'),
          projectStore: false,
        );
        return (store: store, snapshot: await wordStoreReader(store));
      }();
      final loaded = await load;
      if (!_disposed && !_personalStorageInitialized) {
        _personalStore = loaded.store;
        _personalWords = loaded.snapshot;
        _personalStorageInitialized = true;
      }
    }

    final nextProjectRoot = _projectScopeRoot(workspace);
    _requestedProjectRoot = nextProjectRoot;
    final projectGeneration = ++_projectStorageGeneration;
    final nextProjectStore = nextProjectRoot == null
        ? null
        : _projectStorageInitialized && _projectRoot == nextProjectRoot
        ? _projectStore
        : wordStoreFactory(
            filePath: p.join(nextProjectRoot, '.busymark', 'spelling.json'),
            projectStore: true,
          );
    final nextProjectWords =
        (nextProjectStore == null
            ? null
            : await wordStoreReader(nextProjectStore)) ??
        const SpellingWordStoreSnapshot(revision: 0, wordsByLanguage: {});
    if (!_disposed &&
        projectGeneration == _projectStorageGeneration &&
        _requestedProjectRoot == nextProjectRoot) {
      _projectRoot = nextProjectRoot;
      _projectStore = nextProjectStore;
      _projectWords = nextProjectWords;
      _projectStorageInitialized = true;
      _watchProjectStore(nextProjectRoot, nextProjectStore?.filePath);
    }

    // Available metadata is shipped with BusyMark. Only application-managed
    // installations are opened and checksum-verified.
    if (_catalog == null) {
      final resourceRoot =
          bundledRoot ?? const SpellingResourceLocator().locate();
      if (resourceRoot == null) {
        _catalog = const SpellingDictionaryCatalog(
          availableEntries: [],
          installations: [],
          unavailableEntries: {
            'bundle': 'Dictionary catalog metadata is unavailable.',
          },
        );
      } else {
        final dictionaryRoot = await _ensureDictionaryStorageRoot();
        _catalog = await SpellingDictionaryCatalog.load(
          bundledRoot: resourceRoot,
          downloadedRoot: p.join(dictionaryRoot, 'downloaded'),
          importedRoot: p.join(dictionaryRoot, 'imported'),
          verifyChecksums: verifyDictionaryChecksums,
        );
      }
    }
  }

  Future<String> _ensureStorageRoot() async {
    final existing = _supportRoot;
    if (existing != null) return existing;
    final resolved =
        applicationSupportRoot ?? (await getApplicationSupportDirectory()).path;
    _supportRoot = resolved;
    return resolved;
  }

  Future<String> _ensureDictionaryStorageRoot() async {
    final existing = _resolvedDictionaryStorageRoot;
    if (existing != null) return existing;
    _resolvedDictionaryStorageRoot = resolveSpellingDictionaryStorageRoot(
      applicationSupportRoot: await _ensureStorageRoot(),
      dictionaryStorageRoot: dictionaryStorageRoot,
      environment: environment,
    );
    return _resolvedDictionaryStorageRoot!;
  }

  Future<void> _releaseAndRemoveInstallation(
    SpellingDictionaryInstallation installation,
  ) async {
    final coordinator = _coordinator;
    if (coordinator != null) {
      coordinator.disablePresentation();
      await coordinator.releaseDictionary();
    }
    _engineContext = null;
    _contextIdentity = '';
    final dictionaryRoot = await _ensureDictionaryStorageRoot();
    final root = p.join(
      dictionaryRoot,
      installation.imported ? 'imported' : 'downloaded',
    );
    await dictionaryInstaller.remove(
      installation: installation,
      installationRoot: root,
    );
    await _reloadCatalogAndRefresh();
  }

  Future<void> _releaseAndRemoveInvalidInstallation(
    SpellingInvalidDictionaryInstallation installation,
  ) async {
    final coordinator = _coordinator;
    if (coordinator != null) {
      coordinator.disablePresentation();
      await coordinator.releaseDictionary();
    }
    _engineContext = null;
    _contextIdentity = '';
    final dictionaryRoot = await _ensureDictionaryStorageRoot();
    final root = p.join(
      dictionaryRoot,
      installation.kind == SpellingDictionaryInstallationKind.imported
          ? 'imported'
          : 'downloaded',
    );
    await dictionaryInstaller.removeInvalid(
      installation: installation,
      installationRoot: root,
    );
    await _reloadCatalogAndRefresh();
  }

  Future<void> _reloadCatalogAndRefresh() async {
    _catalog = null;
    await _initializeStorage(_latestInput?.workspace ?? _settingsWorkspace);
    if (!_disposed) notifyListeners();
    await _refreshAfterPersistentChange();
  }

  Future<void> _ensureCoordinator() async {
    if (_coordinator != null) return;
    final startup = _coordinatorStartup ??= coordinatorStarter();
    late final SpellingCoordinator coordinator;
    try {
      coordinator = await startup;
    } on Object {
      if (identical(_coordinatorStartup, startup)) _coordinatorStartup = null;
      rethrow;
    }
    if (_disposed) {
      coordinator.dispose();
      return;
    }
    if (_coordinator == null) {
      _coordinator = coordinator..addListener(_forwardCoordinatorChange);
    } else if (!identical(_coordinator, coordinator)) {
      coordinator.dispose();
    }
  }

  void _watchProjectStore(String? projectRoot, String? filePath) {
    final normalizedFile = filePath == null
        ? null
        : p.normalize(p.absolute(filePath));
    if (_watchedProjectFile == normalizedFile && _projectStoreWatcher != null) {
      return;
    }
    _watchedProjectFile = normalizedFile;
    _projectStoreReloadDebounce?.cancel();
    _projectStoreReloadDebounce = null;
    _installProjectStoreWatcher(projectRoot, normalizedFile);
  }

  void _installProjectStoreWatcher(
    String? projectRoot,
    String? normalizedFile,
  ) {
    final generation = ++_projectWatcherGeneration;
    unawaited(_projectStoreWatcher?.cancel());
    _projectStoreWatcher = null;
    _watchedProjectDirectory = null;
    if (projectRoot == null || normalizedFile == null || _disposed) return;

    final desiredParent = p.dirname(normalizedFile);
    var watchedDirectory = desiredParent;
    while (!Directory(watchedDirectory).existsSync()) {
      final parent = p.dirname(watchedDirectory);
      if (parent == watchedDirectory ||
          !p.isWithin(p.normalize(p.absolute(projectRoot)), parent) &&
              p.normalize(p.absolute(projectRoot)) != parent) {
        watchedDirectory = p.normalize(p.absolute(projectRoot));
        break;
      }
      watchedDirectory = parent;
    }
    if (!Directory(watchedDirectory).existsSync()) return;
    _watchedProjectDirectory = watchedDirectory;

    late final StreamSubscription<FileSystemEvent> subscription;
    var reattachRequired = false;
    void reinstallAndReload({bool forceReattach = false}) {
      if (_disposed ||
          generation != _projectWatcherGeneration ||
          _watchedProjectFile != normalizedFile) {
        return;
      }
      reattachRequired = reattachRequired || forceReattach;
      _projectStoreReloadDebounce?.cancel();
      _projectStoreReloadDebounce = Timer(
        const Duration(milliseconds: 100),
        () {
          if (_disposed || generation != _projectWatcherGeneration) return;
          final parentNowExists = Directory(desiredParent).existsSync();
          final shouldReattach =
              reattachRequired ||
              _projectStoreWatcher == null ||
              parentNowExists && _watchedProjectDirectory != desiredParent;
          reattachRequired = false;
          if (shouldReattach) {
            _installProjectStoreWatcher(projectRoot, normalizedFile);
          }
          unawaited(_reloadProjectWordsFromDisk());
        },
      );
    }

    subscription = Directory(watchedDirectory).watch().listen(
      (event) {
        bool touchesProjectStore(String rawPath) {
          final eventPath = p.normalize(p.absolute(rawPath));
          return eventPath == normalizedFile ||
              eventPath == desiredParent ||
              p.isWithin(eventPath, normalizedFile) ||
              p.isWithin(eventPath, desiredParent);
        }

        final relevant =
            touchesProjectStore(event.path) ||
            event is FileSystemMoveEvent &&
                event.destination != null &&
                touchesProjectStore(event.destination!);
        if (relevant) reinstallAndReload();
      },
      onError: (_) {
        if (identical(_projectStoreWatcher, subscription)) {
          _projectStoreWatcher = null;
          reinstallAndReload(forceReattach: true);
        }
      },
      onDone: () {
        if (identical(_projectStoreWatcher, subscription)) {
          _projectStoreWatcher = null;
          reinstallAndReload(forceReattach: true);
        }
      },
    );
    _projectStoreWatcher = subscription;
  }

  Future<void> _reloadProjectWordsFromDisk() async {
    final store = _projectStore;
    final root = _projectRoot;
    if (_disposed || store == null || root == null) return;
    try {
      final snapshot = await wordStoreReader(store);
      if (_disposed ||
          !identical(store, _projectStore) ||
          root != _projectRoot) {
        return;
      }
      if (_sameWordStoreSnapshot(snapshot, _projectWords)) return;
      _projectWords = snapshot;
      await _refreshAfterPersistentChange();
    } on Object catch (error) {
      if (_disposed ||
          !identical(store, _projectStore) ||
          root != _projectRoot) {
        return;
      }
      _localState = SpellingPresentationState(
        status: SpellingPresentationStatus.failure,
        occurrences: const [],
        complete: false,
        message: error.toString(),
      );
      _presentationUsesLocalState = true;
      notifyListeners();
    }
  }

  void _forwardCoordinatorChange() => notifyListeners();

  void _showLanguageRequired() {
    if (_coordinator case final coordinator?) {
      _presentationUsesLocalState = false;
      coordinator.showLanguageRequired();
    } else {
      _localState = const SpellingPresentationState.languageRequired();
      notifyListeners();
    }
  }

  void _showDisabled() {
    if (_coordinator case final coordinator?) {
      _presentationUsesLocalState = false;
      coordinator.disablePresentation();
    } else {
      _localState = const SpellingPresentationState(
        status: SpellingPresentationStatus.disabled,
        occurrences: [],
        complete: false,
      );
      notifyListeners();
    }
  }

  bool _isOperationCurrent(int operation, SpellingSessionInput input) =>
      !_disposed &&
      operation == _operation &&
      _latestInput?.identity == input.identity;

  void _requireCurrent(SpellingOccurrence occurrence) {
    if (!isCurrent(occurrence)) {
      throw StateError('The spelling occurrence is stale.');
    }
  }

  Future<void> _refreshAfterPersistentChange() async {
    _scheduledIdentity = '';
    final input = _latestInput;
    if (input == null) {
      if (!_disposed) notifyListeners();
      return;
    }
    final refreshed = input.refreshed();
    _latestInput = refreshed;
    if (_manualReviewActive) {
      _invalidatePresentation();
      final operation = ++_operation;
      await _prepareAndSchedule(refreshed, operation: operation, manual: true);
    } else {
      update(refreshed);
    }
  }

  void _invalidatePresentation() {
    _engineContext = null;
    _presentationUsesLocalState = true;
    _localState = const SpellingPresentationState(
      status: SpellingPresentationStatus.checking,
      occurrences: [],
      complete: false,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _operation++;
    _dictionaryDownloadCancellation?.cancel();
    _projectStoreReloadDebounce?.cancel();
    unawaited(_projectStoreWatcher?.cancel());
    final coordinator = _coordinator;
    if (coordinator != null) {
      coordinator.removeListener(_forwardCoordinatorChange);
      coordinator.dispose();
    }
    super.dispose();
  }
}

String resolveSpellingDictionaryStorageRoot({
  required String applicationSupportRoot,
  String? dictionaryStorageRoot,
  Map<String, String>? environment,
}) {
  final processEnvironment = environment ?? Platform.environment;
  final snapCommon = processEnvironment['SNAP_USER_COMMON']?.trim();
  final configuredRoot = processEnvironment['BUSYMARK_SPELLING_INSTALL_ROOT']
      ?.trim();
  final resolved =
      dictionaryStorageRoot ??
      (configuredRoot != null && configuredRoot.isNotEmpty
          ? configuredRoot
          : snapCommon != null && snapCommon.isNotEmpty
          ? p.join(snapCommon, 'spelling', 'dictionaries')
          : p.join(applicationSupportRoot, 'spelling', 'dictionaries'));
  return p.normalize(p.absolute(resolved));
}

final class SpellingSessionInput {
  const SpellingSessionInput({
    required this.buffer,
    required this.workspace,
    required this.settings,
    required this.documentKind,
    required this.markdownMode,
    this.richDocument,
    this.richDocumentGeneration = 0,
    this.refreshToken = 0,
  });

  final DocumentBuffer buffer;
  final Workspace? workspace;
  final AppSettings settings;
  final DocumentKind documentKind;
  final MarkdownMode markdownMode;
  final BusyDocument? richDocument;
  final int richDocumentGeneration;
  final int refreshToken;

  String get identity => [
    buffer.id,
    buffer.filePath ?? '',
    buffer.revision,
    buffer.editorState.spellingLanguage.kind.name,
    buffer.editorState.spellingLanguage.languageId ?? '',
    workspace?.id ?? '',
    settings.automaticSpelling,
    settings.defaultSpellingLanguage ?? '',
    documentKind.name,
    richDocument == null ? 'source' : 'rich',
    richDocumentGeneration,
    refreshToken,
  ].join('\u0000');

  SpellingSessionInput refreshed() => SpellingSessionInput(
    buffer: buffer,
    workspace: workspace,
    settings: settings,
    documentKind: documentKind,
    markdownMode: markdownMode,
    richDocument: richDocument,
    richDocumentGeneration: richDocumentGeneration,
    refreshToken: refreshToken + 1,
  );

  SpellingSessionInput withRichDocumentGeneration(int generation) =>
      SpellingSessionInput(
        buffer: buffer,
        workspace: workspace,
        settings: settings,
        documentKind: documentKind,
        markdownMode: markdownMode,
        richDocument: richDocument,
        richDocumentGeneration: generation,
        refreshToken: refreshToken,
      );
}

String? resolveSpellingLanguageId({
  required SpellingLanguageOverride override,
  required String? projectLanguage,
  required String? defaultLanguage,
}) {
  return switch (override.kind) {
    SpellingLanguageOverrideKind.selected => override.languageId,
    SpellingLanguageOverrideKind.inherit => projectLanguage ?? defaultLanguage,
    SpellingLanguageOverrideKind.disabled => null,
  };
}

bool _sameWordStoreSnapshot(
  SpellingWordStoreSnapshot left,
  SpellingWordStoreSnapshot right,
) {
  if (left.revision != right.revision ||
      left.projectLanguage != right.projectLanguage ||
      left.wordsByLanguage.length != right.wordsByLanguage.length) {
    return false;
  }
  for (final entry in left.wordsByLanguage.entries) {
    final other = right.wordsByLanguage[entry.key];
    if (other == null || other.length != entry.value.length) return false;
    for (var index = 0; index < other.length; index++) {
      if (entry.value[index].key != other[index].key ||
          entry.value[index].display != other[index].display) {
        return false;
      }
    }
  }
  return true;
}

String? _projectScopeRoot(Workspace? workspace) => switch (workspace?.kind) {
  WorkspaceKind.markdownFolder ||
  WorkspaceKind.writersideModule => workspace!.rootPath,
  _ => null,
};
