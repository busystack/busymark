import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../app/app_settings.dart';
import '../markdown/busymark_document.dart';
import '../markdown/markdown_model.dart';
import '../workspace/document_buffer.dart';
import '../workspace/workspace_model.dart';
import 'spelling_catalog.dart';
import 'spelling_coordinator.dart';
import 'spelling_dictionary_importer.dart';
import 'spelling_language.dart';
import 'spelling_projection.dart';
import 'spelling_word_store.dart';
import 'spelling_worker.dart';

final spellingSessionControllerProvider =
    ChangeNotifierProvider<SpellingSessionController>((ref) {
      return SpellingSessionController(
        applicationSupportRoot: Platform.environment.containsKey('FLUTTER_TEST')
            ? p.join(Directory.systemTemp.path, 'busymark-spelling-tests-$pid')
            : null,
      );
    });

/// Application-side owner for the one reusable native spelling worker.
///
/// This class deliberately owns presentation state rather than putting
/// annotations in [DocumentBuffer]. Checking therefore cannot dirty a buffer,
/// create history, serialize a rich document, or trigger autosave.
final class SpellingSessionController extends ChangeNotifier {
  SpellingSessionController({
    this.bundledRoot,
    this.applicationSupportRoot,
    this.verifyDictionaryChecksums = true,
  });

  final String? bundledRoot;
  final String? applicationSupportRoot;
  final bool verifyDictionaryChecksums;

  SpellingCoordinator? _coordinator;
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
  bool _personalStorageInitialized = false;
  bool _projectStorageInitialized = false;
  String _scheduledIdentity = '';
  String _contextIdentity = '';
  int _contextGeneration = 0;
  int _operation = 0;
  bool _disposed = false;
  bool _manualReviewActive = false;

  SpellingPresentationState get state => _coordinator?.state ?? _localState;
  List<SpellingAnnotation> get annotations =>
      _coordinator?.annotations ?? const [];
  List<SpellingOccurrence> get misspellings =>
      _coordinator?.misspellings ?? const [];
  SpellingDictionaryCatalog? get catalog => _catalog;
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
    _latestInput = input;
    final identity = input.identity;
    if (identity == _scheduledIdentity) return;
    _scheduledIdentity = identity;
    final operation = ++_operation;
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
    final operation = ++_operation;
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
    return coordinator.suggestions(occurrence, context: context);
  }

  bool isCurrent(SpellingOccurrence occurrence) =>
      _coordinator?.isCurrent(occurrence) ?? false;

  SpellingOccurrence? occurrenceAtSource(int offset) =>
      _coordinator?.occurrenceAtSource(offset);

  SpellingOccurrence? occurrenceAtField({
    required SpellingEditorTarget target,
    required int offset,
  }) => _coordinator?.occurrenceAtField(target: target, offset: offset);

  void ignoreOnce(SpellingOccurrence occurrence) =>
      _coordinator?.ignoreOnce(occurrence);

  void ignoreAllInDocument(SpellingOccurrence occurrence) =>
      _coordinator?.ignoreAllInDocument(occurrence);

  Future<void> addPersonalWord(SpellingOccurrence occurrence) async {
    _requireCurrent(occurrence);
    final store = _personalStore;
    if (store == null) throw StateError('Personal dictionary is unavailable.');
    _personalWords = await store.addWord(
      occurrence.run.languageId,
      occurrence.word,
    );
    await _refreshAfterPersistentChange();
  }

  Future<void> addProjectWord(SpellingOccurrence occurrence) async {
    _requireCurrent(occurrence);
    final store = _projectStore;
    if (store == null) {
      throw StateError('This document is not associated with a project.');
    }
    _projectWords = await store.addWord(
      occurrence.run.languageId,
      occurrence.word,
    );
    await _refreshAfterPersistentChange();
  }

  Future<void> removePersonalWord(String languageId, String word) async {
    final store = _personalStore;
    if (store == null) throw StateError('Personal dictionary is unavailable.');
    _personalWords = await store.removeWord(languageId, word);
    await _refreshAfterPersistentChange();
  }

  Future<void> removeProjectWord(String languageId, String word) async {
    final store = _projectStore;
    if (store == null) throw StateError('Project dictionary is unavailable.');
    _projectWords = await store.removeWord(languageId, word);
    await _refreshAfterPersistentChange();
  }

  Future<void> importDictionary({
    required String affPath,
    required String dicPath,
    required String languageId,
    required String displayLabel,
  }) async {
    await _ensureStorageRoot();
    await _ensureCoordinator();
    final coordinator = _coordinator;
    final supportRoot = _supportRoot;
    if (coordinator == null || supportRoot == null) {
      throw StateError('The spelling service is unavailable.');
    }
    await const SpellingDictionaryImporter().import(
      affPath: affPath,
      dicPath: dicPath,
      languageId: languageId,
      displayLabel: displayLabel,
      importedRoot: p.join(supportRoot, 'spelling', 'dictionaries'),
      validateNativePair: (aff, dic) =>
          coordinator.validateDictionary(affPath: aff, dicPath: dic),
    );
    _catalog = null;
    await _initializeStorage(_latestInput?.workspace ?? _settingsWorkspace);
    await _refreshAfterPersistentChange();
  }

  Future<void> removeImportedDictionary(String languageId) async {
    await _ensureStorageRoot();
    final supportRoot = _supportRoot;
    if (supportRoot == null) {
      throw StateError('Application support storage is unavailable.');
    }
    await const SpellingDictionaryImporter().remove(
      languageId: languageId,
      importedRoot: p.join(supportRoot, 'spelling', 'dictionaries'),
    );
    _catalog = null;
    await _initializeStorage(_latestInput?.workspace ?? _settingsWorkspace);
    await _refreshAfterPersistentChange();
  }

  Future<void> setProjectLanguage(String? languageId) async {
    final store = _projectStore;
    if (store == null) {
      throw StateError('This workspace has no project spelling scope.');
    }
    _projectWords = await store.setProjectLanguage(languageId);
    await _refreshAfterPersistentChange();
  }

  void closeBuffer(String bufferId) => _coordinator?.closeBuffer(bufferId);

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
    if (!_isEligible(input.documentKind)) {
      _showDisabled();
      return;
    }
    try {
      await _initializeStorage(input.workspace);
      if (!_isOperationCurrent(operation, input)) return;
      final languageId = switch (override.kind) {
        SpellingLanguageOverrideKind.selected => override.languageId,
        SpellingLanguageOverrideKind.inherit =>
          _projectWords.projectLanguage ??
              input.settings.defaultSpellingLanguage,
        SpellingLanguageOverrideKind.disabled => null,
      };
      if (languageId == null) {
        _showLanguageRequired();
        return;
      }
      final entry = _catalog?.byId(languageId);
      if (entry == null) {
        await _ensureCoordinator();
        if (!_isOperationCurrent(operation, input)) return;
        _coordinator!.showDictionaryUnavailable(languageId);
        return;
      }
      final contextIdentity = [
        languageId,
        entry.fingerprint,
        _personalWords.revision,
        _projectRoot ?? '',
        _projectWords.revision,
      ].join('\u0000');
      if (contextIdentity != _contextIdentity) {
        _contextIdentity = contextIdentity;
        _contextGeneration++;
      }
      final customWords = <String>{
        ..._personalWords.wordsFor(languageId),
        ..._projectWords.wordsFor(languageId),
      }.toList(growable: false);
      _engineContext = SpellingEngineContext(
        languageId: languageId,
        affPath: entry.affPath,
        dicPath: entry.dicPath,
        baseFingerprint: entry.fingerprint,
        personalRevision: _personalWords.revision,
        projectIdentity: _projectRoot,
        projectRevision: _projectWords.revision,
        customWords: customWords,
      );
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
        await _coordinator!.checkNow(request);
      } else {
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
      _personalStore = SpellingWordStore(
        filePath: p.join(supportRoot, 'spelling', 'personal.json'),
      );
      _personalWords = await _personalStore!.read();
      _personalStorageInitialized = true;
    }

    final nextProjectRoot = _projectScopeRoot(workspace);
    if (!_projectStorageInitialized || _projectRoot != nextProjectRoot) {
      _projectRoot = nextProjectRoot;
      _projectStore = nextProjectRoot == null
          ? null
          : SpellingWordStore(
              filePath: p.join(nextProjectRoot, '.busymark', 'spelling.json'),
              projectStore: true,
            );
      _projectWords =
          await _projectStore?.read() ??
          const SpellingWordStoreSnapshot(revision: 0, wordsByLanguage: {});
      _projectStorageInitialized = true;
    }

    // The bundled catalog can be large. Its pair checksums are verified once
    // per application session, never again on each keystroke.
    if (_catalog == null) {
      final resourceRoot =
          bundledRoot ?? const SpellingResourceLocator().locate();
      if (resourceRoot == null) {
        _catalog = const SpellingDictionaryCatalog(
          entries: [],
          unavailableEntries: {
            'bundle': 'Bundled dictionary resources are unavailable.',
          },
        );
      } else {
        _catalog = await SpellingDictionaryCatalog.load(
          bundledRoot: resourceRoot,
          importedRoot: p.join(supportRoot, 'spelling', 'dictionaries'),
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

  Future<void> _ensureCoordinator() async {
    if (_coordinator != null) return;
    final coordinator = await SpellingCoordinator.start();
    if (_disposed) {
      coordinator.dispose();
      return;
    }
    _coordinator = coordinator..addListener(_forwardCoordinatorChange);
  }

  void _forwardCoordinatorChange() => notifyListeners();

  void _showLanguageRequired() {
    if (_coordinator case final coordinator?) {
      coordinator.showLanguageRequired();
    } else {
      _localState = const SpellingPresentationState.languageRequired();
      notifyListeners();
    }
  }

  void _showDisabled() {
    if (_coordinator case final coordinator?) {
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
      !_disposed && operation == _operation && identical(_latestInput, input);

  void _requireCurrent(SpellingOccurrence occurrence) {
    if (!isCurrent(occurrence)) {
      throw StateError('The spelling occurrence is stale.');
    }
  }

  Future<void> _refreshAfterPersistentChange() async {
    _scheduledIdentity = '';
    final input = _latestInput;
    if (input == null) return;
    final refreshed = input.refreshed();
    _latestInput = refreshed;
    if (_manualReviewActive) {
      final operation = ++_operation;
      await _prepareAndSchedule(refreshed, operation: operation, manual: true);
    } else {
      update(refreshed);
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _operation++;
    final coordinator = _coordinator;
    if (coordinator != null) {
      coordinator.removeListener(_forwardCoordinatorChange);
      coordinator.dispose();
    }
    super.dispose();
  }
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

bool _isEligible(DocumentKind kind) => switch (kind) {
  DocumentKind.markdown ||
  DocumentKind.writersideMarkdownTopic ||
  DocumentKind.writersideXmlTopic => true,
  _ => false,
};

String? _projectScopeRoot(Workspace? workspace) => switch (workspace?.kind) {
  WorkspaceKind.markdownFolder ||
  WorkspaceKind.writersideModule => workspace!.rootPath,
  _ => null,
};
