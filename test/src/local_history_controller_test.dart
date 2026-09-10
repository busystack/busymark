import 'dart:async';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/local_history/local_history_controller.dart';
import 'package:busymark/src/local_history/local_history_models.dart';
import 'package:busymark/src/local_history/local_history_panel.dart';
import 'package:busymark/src/local_history/local_history_store.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:busymark/src/workspace/text_format_metadata.dart';
import 'package:busymark/src/workspace/workspace_file_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'continuous typing captures latest text at fixed checkpoint interval',
    () async {
      var now = DateTime.utc(2026, 1, 1);
      final timers = <_FakeTimer>[];
      final store = MemoryLocalHistoryStore();
      final container = ProviderContainer(
        overrides: [
          localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
          localHistoryStoreProvider.overrideWithValue(store),
          localHistoryClockProvider.overrideWithValue(() => now),
          localHistoryTimerFactoryProvider.overrideWithValue((delay, callback) {
            final timer = _FakeTimer(delay, callback);
            timers.add(timer);
            return timer;
          }),
        ],
      );
      addTearDown(container.dispose);
      await Future<void>.delayed(Duration.zero);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      final opened = DocumentBuffer.untitled(
        id: 'buffer-one',
        name: 'Draft.md',
        text: 'A',
      );
      await controller.observeOpened(opened);
      final firstEdit = opened.edited('B');
      controller.observeEdit(opened, firstEdit);
      await Future<void>.delayed(Duration.zero);
      final secondEdit = firstEdit.edited('C');
      controller.observeEdit(firstEdit, secondEdit);
      await Future<void>.delayed(Duration.zero);

      expect(timers, hasLength(1));
      expect(timers.single.duration, const Duration(seconds: 60));
      now = now.add(const Duration(seconds: 60));
      timers.single.fire();
      await controller.flushAll([secondEdit]);
      final snapshot = await store.load();
      final revisions = snapshot.revisionsFor(snapshot.documents.single.id);

      expect(revisions, hasLength(2));
      expect(revisions.map((entry) => entry.reason), [
        LocalHistoryCaptureReason.automaticCheckpoint,
        LocalHistoryCaptureReason.baseline,
      ]);
      expect((await store.readRevision(revisions.first.id))!.source, 'C');
    },
  );

  test('inactive buffers receive independent checkpoint timers', () async {
    final timers = <_FakeTimer>[];
    final store = MemoryLocalHistoryStore();
    final container = ProviderContainer(
      overrides: [
        localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
        localHistoryStoreProvider.overrideWithValue(store),
        localHistoryTimerFactoryProvider.overrideWithValue((delay, callback) {
          final timer = _FakeTimer(delay, callback);
          timers.add(timer);
          return timer;
        }),
      ],
    );
    addTearDown(container.dispose);
    await Future<void>.delayed(Duration.zero);
    final controller = container.read(localHistoryControllerProvider.notifier);
    final first = DocumentBuffer.untitled(
      id: 'buffer-first',
      name: 'First.md',
      text: 'one',
    );
    final second = DocumentBuffer.untitled(
      id: 'buffer-second',
      name: 'Second.md',
      text: 'two',
    );
    await controller.observeOpened(first);
    await controller.observeOpened(second);
    final firstEdit = first.edited('one changed');
    final secondEdit = second.edited('two changed');
    controller.observeEdit(first, firstEdit);
    controller.observeEdit(second, secondEdit);
    await Future<void>.delayed(Duration.zero);

    expect(timers, hasLength(2));
    for (final timer in timers) {
      timer.fire();
    }
    await controller.flushAll([firstEdit, secondEdit]);
    final snapshot = await store.load();
    expect(snapshot.documents, hasLength(2));
    expect(snapshot.revisions, hasLength(4));
  });

  test(
    'recording off prevents baseline and checkpoints without deleting history',
    () async {
      final settingsStore = _MemorySettingsStore();
      final store = MemoryLocalHistoryStore();
      final container = ProviderContainer(
        overrides: [
          localSettingsStoreProvider.overrideWithValue(settingsStore),
          localHistoryStoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(container.dispose);
      await Future<void>.delayed(Duration.zero);
      final settings = container.read(appSettingsControllerProvider.notifier);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      final buffer = DocumentBuffer.untitled(
        id: 'buffer-one',
        name: 'Draft.md',
        text: 'text',
      );
      await controller.observeOpened(buffer);
      expect((await store.load()).revisions, hasLength(1));
      await settings.setLocalHistoryRecordingEnabled(false);
      final edited = buffer.edited('changed');
      controller.observeEdit(buffer, edited);
      await controller.flushAll([edited]);
      expect((await store.load()).revisions, hasLength(1));
    },
  );

  test(
    'store-wide find locates closed and deleted documents by path or content',
    () async {
      final store = MemoryLocalHistoryStore();
      await store.capture(
        LocalHistoryCaptureRequest(
          path: '/retired/guides/removed.md',
          displayName: 'removed.md',
          source: 'A vanished authentication phrase',
          format: TextFormatMetadata.utf8Lf,
          capturedAt: DateTime.utc(2026, 1, 1),
          reason: LocalHistoryCaptureReason.beforeDelete,
        ),
        const LocalHistoryPolicy(),
      );
      await store.markDeleted('/retired/guides/removed.md', recursive: false);
      final container = ProviderContainer(
        overrides: [
          localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
          localHistoryStoreProvider.overrideWithValue(store),
          localHistoryClockProvider.overrideWithValue(
            () => DateTime.utc(2026, 1, 2),
          ),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      await controller.refresh();
      expect(
        container.read(localHistoryControllerProvider).snapshot.revisions,
        hasLength(1),
      );
      expect(
        (await store.readRevision(
          container
              .read(localHistoryControllerProvider)
              .snapshot
              .revisions
              .single
              .id,
        ))!.source,
        contains('authentication'),
      );

      controller.beginDocumentSearch();
      await controller.search('authentication');
      var state = container.read(localHistoryControllerProvider);
      expect(state.findingDocuments, isTrue);
      expect(state.documentSearchMatches, {state.snapshot.documents.single.id});

      await controller.search('/retired/guides');
      state = container.read(localHistoryControllerProvider);
      expect(state.documentSearchMatches, {state.snapshot.documents.single.id});
      expect(state.snapshot.documents.single.deleted, isTrue);
    },
  );

  testWidgets(
    'a delayed revision read cannot cross the selected document or leave loading stuck',
    (tester) async {
      late ProviderContainer container;
      final state = (await tester.runAsync(() async {
        final memory = MemoryLocalHistoryStore();
        await _capturePath(memory, '/workspace/a.md', 'revision A');
        await _capturePath(memory, '/workspace/b.md', 'revision B');
        final initial = await memory.load();
        final documentA = initial.documents.singleWhere(
          (document) => document.currentPath == '/workspace/a.md',
        );
        final documentB = initial.documents.singleWhere(
          (document) => document.currentPath == '/workspace/b.md',
        );
        final revisionA = initial.revisionsFor(documentA.id).single;
        final store = _BlockingRevisionReadStore(memory, revisionA.id);
        container = ProviderContainer(
          overrides: [
            localSettingsStoreProvider.overrideWithValue(
              _MemorySettingsStore(),
            ),
            localHistoryStoreProvider.overrideWithValue(store),
            localHistoryClockProvider.overrideWithValue(
              () => DateTime.utc(2026, 1, 2),
            ),
          ],
        );
        final controller = container.read(
          localHistoryControllerProvider.notifier,
        );
        await Future<void>.delayed(Duration.zero);
        await controller.refresh();

        expect(
          container.read(localHistoryControllerProvider).snapshot.revisions,
          hasLength(2),
        );
        controller.selectDocument(documentA.id);
        expect(
          container.read(localHistoryControllerProvider).selectedDocumentId,
          documentA.id,
        );
        final selection = controller.selectRevision(revisionA.id);
        await store.started.future;
        controller.selectDocument(documentB.id);
        expect(container.read(localHistoryControllerProvider).loading, isFalse);
        store.release.complete();
        await selection;
        return container.read(localHistoryControllerProvider);
      }))!;
      addTearDown(container.dispose);

      expect(state.selectedDocument?.currentPath, '/workspace/b.md');
      expect(state.selectedRevisionId, isNull);
      expect(state.selectedRevision, isNull);
      expect(state.loading, isFalse);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: LocalHistoryPanel()),
          ),
        ),
      );
      await tester.pump();
      final context = tester.element(find.byType(LocalHistoryPanel));
      final refreshLabel = MaterialLocalizations.of(
        context,
      ).refreshIndicatorSemanticLabel;
      final refresh = find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == refreshLabel,
      );
      expect(tester.widget<IconButton>(refresh).onPressed, isNotNull);
    },
  );

  test(
    'Save As settles pending named and untitled checkpoints safely',
    () async {
      final timers = <_FakeTimer>[];
      final store = MemoryLocalHistoryStore();
      final container = _historyContainer(store, timers);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      await controller.refresh();

      final named = _fileBuffer('named', '/workspace/A.md', 'before');
      await controller.observeOpened(named);
      final namedEdit = named.edited('pending A edit');
      controller.observeEdit(named, namedEdit);
      await Future<void>.delayed(Duration.zero);
      expect(
        await controller.captureSavedAs(
          LocalHistoryBufferSnapshot.fromBuffer(namedEdit),
          '/workspace/B.md',
          destinationExisted: false,
        ),
        isTrue,
      );

      final untitled = DocumentBuffer.untitled(
        id: 'draft',
        name: 'Draft.md',
        text: 'draft before',
      );
      await controller.observeOpened(untitled);
      final draftEdit = untitled.edited('pending draft edit');
      controller.observeEdit(untitled, draftEdit);
      await Future<void>.delayed(Duration.zero);
      expect(
        await controller.captureSavedAs(
          LocalHistoryBufferSnapshot.fromBuffer(draftEdit),
          '/workspace/First.md',
          destinationExisted: false,
        ),
        isTrue,
      );
      for (final timer in timers) {
        timer.fire();
      }
      await controller.flushAll(const []);

      final snapshot = await store.load();
      final a = snapshot.documents.singleWhere(
        (document) => document.currentPath == '/workspace/A.md',
      );
      final b = snapshot.documents.singleWhere(
        (document) => document.currentPath == '/workspace/B.md',
      );
      expect(a.id, isNot(b.id));
      expect(
        await _revisionSources(store, snapshot.revisionsFor(a.id)),
        contains('pending A edit'),
      );
      expect(
        (await store.readRevision(
          snapshot.revisionsFor(b.id).single.id,
        ))!.source,
        'pending A edit',
      );
      final first = snapshot.documents.singleWhere(
        (document) => document.currentPath == '/workspace/First.md',
      );
      expect(first.untitled, isFalse);
      expect(
        await _revisionSources(store, snapshot.revisionsFor(first.id)),
        contains('pending draft edit'),
      );
    },
  );

  test(
    'recording-disabled first save promotes untitled history identity',
    () async {
      final timers = <_FakeTimer>[];
      final store = MemoryLocalHistoryStore();
      final container = _historyContainer(store, timers);
      addTearDown(container.dispose);
      final settings = container.read(appSettingsControllerProvider.notifier);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      await controller.refresh();

      final untitled = DocumentBuffer.untitled(
        id: 'draft-first-save',
        name: 'Draft.md',
        text: 'Untitled history\n',
      );
      await controller.observeOpened(untitled);
      final originalDocument = (await store.load()).documents.single;

      await settings.setLocalHistoryRecordingEnabled(false);
      expect(
        await controller.captureSavedAs(
          LocalHistoryBufferSnapshot.fromBuffer(untitled),
          '/workspace/Guide.md',
          destinationExisted: false,
        ),
        isTrue,
      );
      var snapshot = await store.load();
      expect(snapshot.documents, hasLength(1));
      expect(snapshot.documents.single.id, originalDocument.id);
      expect(snapshot.documents.single.currentPath, '/workspace/Guide.md');
      expect(snapshot.documents.single.untitled, isFalse);
      expect(snapshot.revisionsFor(originalDocument.id), hasLength(1));

      await settings.setLocalHistoryRecordingEnabled(true);
      final saved = untitled.copyWith(
        filePath: '/workspace/Guide.md',
        untitledName: null,
        lastSavedText: untitled.text,
        dirty: false,
      );
      expect(
        await controller.captureSaved(
          LocalHistoryBufferSnapshot.fromBuffer(
            saved.edited('Named history\n'),
          ),
        ),
        isTrue,
      );
      snapshot = await store.load();
      expect(snapshot.documents, hasLength(1));
      expect(snapshot.documents.single.id, originalDocument.id);
      expect(
        await _revisionSources(
          store,
          snapshot.revisionsFor(originalDocument.id),
        ),
        containsAll(['Untitled history\n', 'Named history\n']),
      );

      final reopenedContainer = _historyContainer(store, <_FakeTimer>[]);
      addTearDown(reopenedContainer.dispose);
      final reopenedController = reopenedContainer.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      await reopenedController.refresh();
      await reopenedController.observeOpened(
        _fileBuffer('reopened-guide', '/workspace/Guide.md', 'Named history\n'),
      );
      expect(
        reopenedController.bufferIdForDocument(originalDocument.id),
        'reopened-guide',
      );
    },
  );

  test(
    'failed first-save promotion is retried before a later capture',
    () async {
      final store = _FailingFirstPromotionStore();
      final container = _historyContainer(store, <_FakeTimer>[]);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      await controller.refresh();

      final untitled = DocumentBuffer.untitled(
        id: 'draft-retry',
        name: 'Draft.md',
        text: 'Original untitled revision\n',
      );
      await controller.observeOpened(untitled);
      final originalDocument = (await store.load()).documents.single;
      expect(
        await controller.captureSavedAs(
          LocalHistoryBufferSnapshot.fromBuffer(untitled),
          '/workspace/Recovered.md',
          destinationExisted: false,
        ),
        isFalse,
      );
      expect((await store.load()).documents.single.currentPath, isNull);

      final saved = untitled.copyWith(
        filePath: '/workspace/Recovered.md',
        untitledName: null,
        lastSavedText: untitled.text,
        dirty: false,
      );
      expect(
        await controller.captureSaved(
          LocalHistoryBufferSnapshot.fromBuffer(
            saved.edited('Revision after recovery\n'),
          ),
        ),
        isTrue,
      );
      final snapshot = await store.load();
      expect(snapshot.documents, hasLength(1));
      expect(snapshot.documents.single.id, originalDocument.id);
      expect(snapshot.documents.single.currentPath, '/workspace/Recovered.md');
      expect(snapshot.documents.single.untitled, isFalse);
      expect(
        await _revisionSources(
          store,
          snapshot.revisionsFor(originalDocument.id),
        ),
        containsAll([
          'Original untitled revision\n',
          'Revision after recovery\n',
        ]),
      );

      final reopenedContainer = _historyContainer(store, <_FakeTimer>[]);
      addTearDown(reopenedContainer.dispose);
      final reopenedController = reopenedContainer.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      await reopenedController.refresh();
      await reopenedController.observeOpened(
        _fileBuffer(
          'reopened-recovered',
          '/workspace/Recovered.md',
          'Revision after recovery\n',
        ),
      );
      expect(
        reopenedController.bufferIdForDocument(originalDocument.id),
        'reopened-recovered',
      );
    },
  );

  test(
    'file and directory moves settle pending checkpoints before remap',
    () async {
      final timers = <_FakeTimer>[];
      final store = MemoryLocalHistoryStore();
      final container = _historyContainer(store, timers);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      await controller.refresh();

      final file = _fileBuffer('file', '/workspace/file.md', 'file before');
      await controller.observeOpened(file);
      controller.observeEdit(file, file.edited('file pending'));
      await Future<void>.delayed(Duration.zero);
      await controller.remapPath('/workspace/file.md', '/workspace/renamed.md');

      final nested = _fileBuffer(
        'nested',
        '/workspace/folder/nested.md',
        'nested before',
      );
      await controller.observeOpened(nested);
      controller.observeEdit(nested, nested.edited('nested pending'));
      await Future<void>.delayed(Duration.zero);
      await controller.remapPath('/workspace/folder', '/workspace/moved');
      for (final timer in timers) {
        timer.fire();
      }
      await controller.flushAll(const []);

      final snapshot = await store.load();
      expect(
        snapshot.documents.map((document) => document.currentPath),
        containsAll(['/workspace/renamed.md', '/workspace/moved/nested.md']),
      );
      expect(
        snapshot.documents.map((document) => document.currentPath),
        isNot(contains('/workspace/file.md')),
      );
      expect(
        snapshot.documents.map((document) => document.currentPath),
        isNot(contains('/workspace/folder/nested.md')),
      );
    },
  );
}

ProviderContainer _historyContainer(
  LocalHistoryStore store,
  List<_FakeTimer> timers,
) => ProviderContainer(
  overrides: [
    localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
    localHistoryStoreProvider.overrideWithValue(store),
    localHistoryTimerFactoryProvider.overrideWithValue((delay, callback) {
      final timer = _FakeTimer(delay, callback);
      timers.add(timer);
      return timer;
    }),
  ],
);

DocumentBuffer _fileBuffer(String id, String path, String text) =>
    DocumentBuffer.file(
      id: id,
      filePath: path,
      text: text,
      snapshot: WorkspaceFileSnapshot(
        modifiedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        size: 0,
        contentHash: '',
      ),
      format: TextFormatMetadata.utf8Lf,
    );

Future<LocalHistoryCaptureResult> _capturePath(
  LocalHistoryStore store,
  String path,
  String source,
) => store.capture(
  LocalHistoryCaptureRequest(
    path: path,
    displayName: path.split('/').last,
    source: source,
    format: TextFormatMetadata.utf8Lf,
    capturedAt: DateTime.utc(2026, 1, 1),
    reason: LocalHistoryCaptureReason.saved,
  ),
  const LocalHistoryPolicy(),
);

Future<List<String>> _revisionSources(
  LocalHistoryStore store,
  Iterable<LocalHistoryRevisionSummary> revisions,
) async {
  final sources = <String>[];
  for (final revision in revisions) {
    sources.add((await store.readRevision(revision.id))!.source);
  }
  return sources;
}

class _BlockingRevisionReadStore implements LocalHistoryStore {
  _BlockingRevisionReadStore(this.delegate, this.blockedRevisionId);

  final LocalHistoryStore delegate;
  final String blockedRevisionId;
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<LocalHistoryRevision?> readRevision(String revisionId) async {
    if (revisionId == blockedRevisionId) {
      if (!started.isCompleted) started.complete();
      await release.future;
    }
    return delegate.readRevision(revisionId);
  }

  @override
  Future<LocalHistoryCaptureResult> capture(
    LocalHistoryCaptureRequest request,
    LocalHistoryPolicy policy,
  ) => delegate.capture(request, policy);

  @override
  Future<void> clearAll() => delegate.clearAll();

  @override
  Future<void> clearDocument(String documentId) =>
      delegate.clearDocument(documentId);

  @override
  Future<LocalHistorySnapshot> load() => delegate.load();

  @override
  Future<void> markDeleted(String path, {required bool recursive}) =>
      delegate.markDeleted(path, recursive: recursive);

  @override
  Future<void> prune(LocalHistoryPolicy policy, DateTime now) =>
      delegate.prune(policy, now);

  @override
  Future<LocalHistoryDocument?> promoteUntitledDocument({
    required String documentId,
    required String destinationPath,
    required String displayName,
    required DateTime updatedAt,
  }) => delegate.promoteUntitledDocument(
    documentId: documentId,
    destinationPath: destinationPath,
    displayName: displayName,
    updatedAt: updatedAt,
  );

  @override
  Future<void> remapPath(String sourcePath, String destinationPath) =>
      delegate.remapPath(sourcePath, destinationPath);
}

class _FailingFirstPromotionStore extends MemoryLocalHistoryStore {
  var _failNextPromotion = true;

  @override
  Future<LocalHistoryDocument?> promoteUntitledDocument({
    required String documentId,
    required String destinationPath,
    required String displayName,
    required DateTime updatedAt,
  }) {
    if (_failNextPromotion) {
      _failNextPromotion = false;
      throw const LocalHistoryStorageException('Injected promotion failure');
    }
    return super.promoteUntitledDocument(
      documentId: documentId,
      destinationPath: destinationPath,
      displayName: displayName,
      updatedAt: updatedAt,
    );
  }
}

class _MemorySettingsStore implements LocalSettingsStore {
  Map<String, Object?> value = {};

  @override
  Future<Map<String, Object?>> load() async => value;

  @override
  Future<void> save(Map<String, Object?> json) async => value = json;
}

class _FakeTimer implements Timer {
  _FakeTimer(this.duration, this.callback);

  final Duration duration;
  final void Function() callback;
  var _active = true;

  void fire() {
    if (!_active) return;
    _active = false;
    callback();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => _active ? 0 : 1;
}
