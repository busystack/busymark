import 'package:busymark/src/local_history/local_history_controller.dart';
import 'package:busymark/src/local_history/local_history_models.dart';
import 'package:busymark/src/local_history/local_history_store.dart';
import 'package:busymark/src/workspace/text_format_metadata.dart';
import 'dart:async';

import 'package:busymark/src/app/app_router.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/command_registry.dart';
import 'package:busymark/src/editor/source/source_search.dart';
import 'package:busymark/src/search/search_session.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer containerFor(
    WorkspaceState state, {
    _GatedService? service,
    LocalHistoryStore? historyStore,
  }) {
    final container = ProviderContainer(
      overrides: [
        workspaceControllerProvider.overrideWith(() => _Workspace(state)),
        localSettingsStoreProvider.overrideWithValue(_Settings()),
        if (historyStore != null)
          localHistoryStoreProvider.overrideWithValue(historyStore),
        if (service != null)
          workspaceServiceProvider.overrideWithValue(service),
      ],
    );
    final router = container.read(appRouterProvider);
    addTearDown(() {
      container.dispose();
      router.dispose();
    });
    return container;
  }

  test('Welcome omits hidden document categories and command targets', () {
    final container = containerFor(_state());
    final session = container.read(searchSessionProvider.notifier);
    expect(session.categories, [SearchCategory.recent, SearchCategory.actions]);
    session.open();
    expect(
      container.read(searchSessionProvider).category,
      SearchCategory.recent,
    );
    session.open(category: SearchCategory.actions);
    expect(session.commandTarget, isNull);
    session.open(category: SearchCategory.file);
    expect(
      container.read(searchSessionProvider).category,
      SearchCategory.actions,
    );
  });

  test(
    'a visible workspace without a buffer retains general History search',
    () async {
      final container = containerFor(
        _state().copyWith(documentBuffers: []),
        historyStore: MemoryLocalHistoryStore(),
      );
      container.read(appRouterProvider).go('/workspace');
      await Future<void>.delayed(Duration.zero);
      final session = container.read(searchSessionProvider.notifier);
      expect(session.categories, [
        SearchCategory.workspace,
        SearchCategory.documents,
        SearchCategory.recent,
        SearchCategory.localHistory,
        SearchCategory.actions,
      ]);
      session.openHistory();
      await session.submit();
      expect(
        container.read(searchSessionProvider).category,
        SearchCategory.localHistory,
      );
      expect(container.read(searchSessionProvider).error, isNull);
      expect(container.read(workspaceControllerProvider).activeBuffer, isNull);
    },
  );

  test('settings cannot retain an invisible search presentation', () async {
    final container = containerFor(_state());
    final session = container.read(searchSessionProvider.notifier);
    session.open(category: SearchCategory.actions);
    container
        .read(appRouterProvider)
        .go(settingsLocation(SettingsReturnTarget.welcome));
    await Future<void>.delayed(Duration.zero);
    expect(session.categories, isEmpty);
    expect(container.read(searchSessionProvider).active, isFalse);
    session.open(category: SearchCategory.actions);
    expect(container.read(searchSessionProvider).active, isFalse);
    expect(session.commandTarget, isNull);
  });

  test(
    'Writerside categories retain the agreed order and use source topic identity',
    () async {
      final workspace = await const WorkspaceService().openPath(
        'test/fixtures/writerside/basic_project',
      );
      final container = containerFor(_state().copyWith(workspace: workspace));
      container.read(appRouterProvider).go('/workspace');
      await Future<void>.delayed(Duration.zero);
      final session = container.read(searchSessionProvider.notifier);
      expect(session.categories, [
        SearchCategory.file,
        SearchCategory.workspace,
        SearchCategory.outline,
        SearchCategory.documents,
        SearchCategory.topics,
        SearchCategory.recent,
        SearchCategory.localHistory,
        SearchCategory.actions,
      ]);
      session.open(category: SearchCategory.topics);
      session.query('install.topic');
      await session.submit();
      final result =
          container.read(searchSessionProvider).results.single
              as TopicSearchResult;
      expect(result.topicId, 'install');
      expect(result.title, 'Install');
      expect(result.path, endsWith('/topics/install.topic'));
    },
  );

  testWidgets(
    'header search preserves a sidebar origin and restores its focus',
    (tester) async {
      final container = containerFor(_state());
      container.read(appRouterProvider).go('/workspace');
      await tester.pump();
      final session = container.read(searchSessionProvider.notifier);
      final editor = FocusNode(),
          navigation = FocusNode(),
          header = FocusNode();
      addTearDown(() {
        editor.dispose();
        navigation.dispose();
        header.dispose();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Actions(
                  actions: {
                    BusyMarkContextCommandIntent: BusyMarkContextCommandAction(
                      isCommandEnabled: (_) => true,
                      onCommand: (_) {},
                    ),
                  },
                  child: Focus(focusNode: editor, child: const Text('Editor')),
                ),
                BusyMarkSidebarSurface(
                  child: Focus(
                    focusNode: navigation,
                    child: const Text('Files'),
                  ),
                ),
                Focus(focusNode: header, child: const Text('Search')),
              ],
            ),
          ),
        ),
      );
      editor.requestFocus();
      await tester.pump();
      navigation.requestFocus();
      await tester.pump();
      header.requestFocus();
      await tester.pump();
      session.open(category: SearchCategory.actions);
      expect(session.commandTarget!.focus, same(navigation));
      session.close();
      // This focus-only harness has no search widget to schedule its frame.
      tester.binding.scheduleFrame();
      await tester.pump();
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, same(navigation));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test(
    'untitled Text uses its buffer and rebinds positions after a tab change',
    () async {
      final container = containerFor(_state());
      container.read(appRouterProvider).go('/workspace');
      await Future<void>.delayed(Duration.zero);
      final session = container.read(searchSessionProvider.notifier);
      expect(session.categories, [
        SearchCategory.file,
        SearchCategory.workspace,
        SearchCategory.outline,
        SearchCategory.documents,
        SearchCategory.recent,
        SearchCategory.localHistory,
        SearchCategory.actions,
      ]);
      session.open(category: SearchCategory.file);
      session.query('needle');
      await session.submit();
      final first =
          container.read(searchSessionProvider).results.single
              as TextSearchResult;
      expect(first.match.bufferId, 'scratch-a');
      expect(first.match.filePath, isNull);
      expect(first.match.startOffset, 7);
      expect(first.match.endOffset, 13);
      session.open(category: SearchCategory.actions);
      session.query('Bold');
      await session.submit();
      expect(
        container
            .read(workspaceControllerProvider)
            .activeBuffer!
            .editorState
            .searchOptions,
        const SourceSearchOptions(),
      );
      session.open(category: SearchCategory.file);
      expect(container.read(searchSessionProvider).query, 'needle');
      final next = _state(text: 'needle at the start', id: 'scratch-b');
      (container.read(workspaceControllerProvider.notifier) as _Workspace)
          .replace(next);
      expect(container.read(searchSessionProvider).results, isEmpty);
      await session.submit();
      final second =
          container.read(searchSessionProvider).results.single
              as TextSearchResult;
      expect(second.match.bufferId, 'scratch-b');
      expect(second.match.startOffset, 0);
      expect(second.match.digest, isNot(first.match.digest));
    },
  );

  for (final count in [81, 3000]) {
    test(
      'document navigation counts $count matches with bounded pages',
      () async {
        final source = 'cat\n' * count;
        final container = containerFor(_state(text: source));
        container.read(appRouterProvider).go('/workspace');
        await Future<void>.delayed(Duration.zero);
        final session = container.read(searchSessionProvider.notifier);
        session.open(category: SearchCategory.file);
        session.query('cat');
        await session.submit();
        var result = container.read(searchSessionProvider);
        expect(result.results, hasLength(80));
        expect(result.documentMatchCount, count);
        expect(result.documentCurrentMatchIndex, isNull);
        expect(
          result
              .sourceSnapshot(
                container.read(workspaceControllerProvider).activeBuffer,
              )
              .result
              .totalMatchCount,
          count,
        );
        for (final index in [79, 80, count - 1, 0]) {
          final id = session.navigateSource(
            SourceSearchNavigationRequest(
              documentId: 'scratch-a',
              source: source,
              options: const SourceSearchOptions(query: 'cat'),
              matchIndex: index,
            ),
          );
          expect(id, isNotNull);
          await session.submit();
          result = container.read(searchSessionProvider);
          final snapshot = result.sourceSnapshot(
            container.read(workspaceControllerProvider).activeBuffer,
          );
          expect(result.results.length, lessThanOrEqualTo(80));
          expect(snapshot.result.totalMatchCount, count);
          expect(snapshot.result.currentMatchIndex, index);
          expect(snapshot.result.currentMatch!.fullStart, index * 4);
          expect(result.selected, index - result.documentFirstMatchIndex);
          expect(
            (result.results[result.selected] as TextSearchResult)
                .match
                .startOffset,
            index * 4,
          );
          expect(result.appliedSourceNavigation, id);
        }
      },
    );
  }

  test(
    'post-edit navigation retains its revision and cancels across queries and buffers',
    () async {
      final container = containerFor(_state(text: 'cat${'\n' * 200}cat'));
      container.read(appRouterProvider).go('/workspace');
      await Future<void>.delayed(Duration.zero);
      final session = container.read(searchSessionProvider.notifier);
      session.open(category: SearchCategory.file);
      session.query('cat');
      await session.submit();
      final workspace = container.read(workspaceControllerProvider);
      final changed = workspace.activeBuffer!.copyWith(
        text: 'dog${'\n' * 200}cat',
        revision: 1,
      );
      (container.read(workspaceControllerProvider.notifier) as _Workspace)
          .replace(workspace.copyWith(documentBuffers: [changed]));
      final id = session.navigateSource(
        SourceSearchNavigationRequest(
          documentId: changed.id,
          source: changed.text,
          options: const SourceSearchOptions(query: 'cat'),
          minimumFullOffset: 3,
        ),
      );
      await session.submit();
      var result = container.read(searchSessionProvider);
      expect(result.appliedSourceNavigation, id);
      expect(
        (result.results[result.selected] as TextSearchResult).match.startOffset,
        203,
      );
      session.navigateSource(
        SourceSearchNavigationRequest(
          documentId: changed.id,
          source: changed.text,
          options: const SourceSearchOptions(query: 'cat'),
          minimumFullOffset: 206,
        ),
      );
      final pending = session.submit();
      session.query('dog');
      session.query('cat');
      (container.read(workspaceControllerProvider.notifier) as _Workspace)
          .replace(_state(text: 'cat in another buffer', id: 'scratch-b'));
      await pending;
      await session.submit();
      result = container.read(searchSessionProvider);
      expect(result.sourceNavigationRequest, 0);
      expect(result.appliedSourceNavigation, 0);
      expect(result.documentCurrentMatchIndex, isNull);
      expect(
        (result.results.single as TextSearchResult).match.bufferId,
        'scratch-b',
      );
    },
  );

  test(
    'file and workspace categories own independent queries and supported options',
    () async {
      final container = containerFor(_state(text: 'Needle needle'));
      container.read(appRouterProvider).go('/workspace');
      await Future<void>.delayed(Duration.zero);
      final session = container.read(searchSessionProvider.notifier);
      expect(
        searchCommandDestinations[BusyMarkCommandIds.search],
        SearchCategory.file,
      );
      expect(
        searchCommandDestinations[BusyMarkCommandIds.searchWorkspace],
        SearchCategory.workspace,
      );
      expect(
        searchCommandDestinations.containsKey(
          BusyMarkCommandIds.sidebarOutline,
        ),
        isFalse,
      );
      session.open(category: SearchCategory.file);
      session.set(
        container
            .read(searchSessionProvider)
            .copyWith(query: 'Needle', caseSensitive: true, regex: true),
      );
      await session.submit();
      expect(container.read(searchSessionProvider).documentMatchCount, 1);
      session.open(category: SearchCategory.workspace);
      expect(container.read(searchSessionProvider).query, isEmpty);
      expect(container.read(searchSessionProvider).caseSensitive, isFalse);
      expect(container.read(searchSessionProvider).regex, isFalse);
      session.set(
        container
            .read(searchSessionProvider)
            .copyWith(query: 'workspace query', wholeWord: true),
      );
      session.open(category: SearchCategory.file);
      expect(
        container.read(searchSessionProvider).options,
        const SourceSearchOptions(
          query: 'Needle',
          caseSensitive: true,
          regex: true,
        ),
      );
      await session.submit();
      session.open(category: SearchCategory.workspace);
      expect(
        container.read(searchSessionProvider).options,
        const SourceSearchOptions(query: 'workspace query', wholeWord: true),
      );
      expect(
        container.read(workspaceControllerProvider).activeText,
        'Needle needle',
      );
    },
  );

  test(
    'shared History finds historical paths and revision bodies without changing comparison or source',
    () async {
      final store = MemoryLocalHistoryStore();
      final now = DateTime.now().toUtc();
      for (final (path, source) in [
        ('/retired/old.md', 'retained needle'),
        ('/current/b.md', 'another revision'),
      ]) {
        await store.capture(
          LocalHistoryCaptureRequest(
            path: path,
            displayName: path.split('/').last,
            source: source,
            format: TextFormatMetadata.utf8Lf,
            capturedAt: now,
            reason: LocalHistoryCaptureReason.saved,
          ),
          const LocalHistoryPolicy(),
        );
      }
      await store.remapPath('/retired/old.md', '/renamed/new.md');
      await store.markDeleted('/renamed/new.md', recursive: false);
      final container = containerFor(_state(), historyStore: store);
      container.read(appRouterProvider).go('/workspace');
      await Future<void>.delayed(Duration.zero);
      final history = container.read(localHistoryControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      await history.refresh();
      final retained = container.read(localHistoryControllerProvider).snapshot;
      final deleted = retained.documents.singleWhere((d) => d.deleted);
      final other = retained.documents.singleWhere((d) => !d.deleted);
      history.inspectRetainedDocument(other.id);
      await history.selectRevision(retained.revisionsFor(other.id).single.id);
      final before = container.read(localHistoryControllerProvider);
      final live = container.read(workspaceControllerProvider).activeBuffer;
      final session = container.read(searchSessionProvider.notifier);
      session.openHistory();
      session.query('needle');
      await session.submit();
      var result =
          (container.read(searchSessionProvider).results.single
                  as HistorySearchResult)
              .match;
      expect(result, isA<LocalHistoryRevisionMatch>());
      expect(result.document.id, deleted.id);
      expect(
        (result as LocalHistoryRevisionMatch).revision.id,
        retained.revisionsFor(deleted.id).single.id,
      );
      expect(
        container.read(localHistoryControllerProvider).selectedRevision,
        same(before.selectedRevision),
      );
      expect(
        container.read(workspaceControllerProvider).activeBuffer,
        same(live),
      );
      expect((await store.load()).revisions, hasLength(2));
      session.query('/retired/old.md');
      await session.submit();
      result =
          (container.read(searchSessionProvider).results.single
                  as HistorySearchResult)
              .match;
      expect(result, isA<LocalHistoryDocumentMatch>());
      expect(result.document.id, deleted.id);
      session.openHistory(documentId: other.id);
      session.query('needle');
      await session.submit();
      expect(container.read(searchSessionProvider).results, isEmpty);
      session.clearHistoryScope();
      await session.submit();
      expect(container.read(searchSessionProvider).results, hasLength(1));
      final id = container.read(searchSessionProvider).results.single.identity;
      session.select(0);
      session.open(category: SearchCategory.actions);
      session.query('Bold');
      session.open(category: SearchCategory.localHistory);
      await session.submit();
      expect(container.read(searchSessionProvider).query, 'needle');
      expect(
        container
            .read(searchSessionProvider)
            .results[container.read(searchSessionProvider).selected]
            .identity,
        id,
      );
      await history.clearDocument(deleted.id);
      expect(container.read(searchSessionProvider).results, isEmpty);
      await session.submit();
      expect(container.read(searchSessionProvider).results, isEmpty);
      expect(
        container.read(localHistoryControllerProvider).selectedRevision,
        same(before.selectedRevision),
      );
    },
  );

  test(
    'obsolete History reads cannot publish after category, scope or snapshot changes',
    () async {
      final store = _SlowHistoryStore();
      await store.capture(
        LocalHistoryCaptureRequest(
          path: '/past/a.md',
          displayName: 'a.md',
          source: 'retained needle',
          format: TextFormatMetadata.utf8Lf,
          capturedAt: DateTime.now().toUtc(),
          reason: LocalHistoryCaptureReason.saved,
        ),
        const LocalHistoryPolicy(),
      );
      final container = containerFor(_state(), historyStore: store);
      container.read(appRouterProvider).go('/workspace');
      await Future<void>.delayed(Duration.zero);
      final history = container.read(localHistoryControllerProvider.notifier);
      await history.refresh();
      final session = container.read(searchSessionProvider.notifier);
      store.block = true;
      session.openHistory();
      session.query('needle');
      final old = session.submit();
      await store.started.future;
      session.open(category: SearchCategory.actions);
      session.query('Bold');
      await session.submit();
      store.release.complete();
      await old;
      expect(
        container.read(searchSessionProvider).category,
        SearchCategory.actions,
      );
      expect(
        container
            .read(searchSessionProvider)
            .results
            .whereType<HistorySearchResult>(),
        isEmpty,
      );
      session.openHistory(documentId: 'missing-owner');
      session.query('needle');
      await session.submit();
      expect(container.read(searchSessionProvider).results, isEmpty);
      session.clearHistoryScope();
      await session.submit();
      expect(container.read(searchSessionProvider).results, hasLength(1));
      await history.clearAll();
      await session.submit();
      expect(container.read(searchSessionProvider).results, isEmpty);
    },
  );

  test('late workspace text cannot publish into another category', () async {
    final service = _GatedService();
    final container = containerFor(
      _state(files: [_file('unopened.md')]),
      service: service,
    );
    container.read(appRouterProvider).go('/workspace');
    await Future<void>.delayed(Duration.zero);
    final session = container.read(searchSessionProvider.notifier);
    session.open(category: SearchCategory.workspace);
    session.query('needle');
    final oldSearch = session.submit();
    await service.started.future;
    session.open(category: SearchCategory.actions);
    session.query('Bold');
    await session.submit();
    service.release.complete('old needle result');
    await oldSearch;
    final current = container.read(searchSessionProvider);
    expect(current.category, SearchCategory.actions);
    expect(current.query, 'Bold');
    expect(current.results, isEmpty);
    expect(current.searching, isFalse);
    expect(current.error, isNull);
  });

  test(
    'workspace publishes useful bounded results before scanning completes',
    () async {
      final service = _ProgressService();
      final container = containerFor(
        _state(files: [_file('a.md'), _file('z.md')]),
        service: service,
      );
      container.read(appRouterProvider).go('/workspace');
      await Future<void>.delayed(Duration.zero);
      final first = Completer<void>();
      final subscription = container.listen(searchSessionProvider, (_, state) {
        if (state.searching && state.results.isNotEmpty && !first.isCompleted) {
          first.complete();
        }
      });
      addTearDown(subscription.close);
      final session = container.read(searchSessionProvider.notifier);
      session.open(category: SearchCategory.workspace);
      session.query('needle');
      final running = session.submit();
      await first.future;
      expect(container.read(searchSessionProvider).searching, isTrue);
      expect(container.read(searchSessionProvider).results, hasLength(1));
      session.open(category: SearchCategory.actions);
      service.release.complete('needle stale');
      await running;
      await session.submit();
      expect(
        container.read(searchSessionProvider).category,
        SearchCategory.actions,
      );
      expect(container.read(searchSessionProvider).results, isEmpty);
    },
  );

  test(
    'workspace queries do not rescan for unrelated editor state changes',
    () async {
      final service = _ReadAheadService();
      final initial = _state(files: [_file('unopened.md')]);
      final container = containerFor(initial, service: service);
      container.read(appRouterProvider).go('/workspace');
      await Future<void>.delayed(Duration.zero);
      final session = container.read(searchSessionProvider.notifier);
      session.open(category: SearchCategory.workspace);
      session.query('needle');
      final running = session.submit();
      await Future<void>.delayed(Duration.zero);
      service.release.complete('needle');
      await running;
      expect(service.reads, 1);
      final revision = container.read(searchSessionProvider).requestRevision;
      final controller =
          container.read(workspaceControllerProvider.notifier) as _Workspace;
      // An unrelated scratch tab does not belong to the workspace inventory.
      controller.replace(
        initial.copyWith(
          documentBuffers: [
            ...initial.documentBuffers,
            const DocumentBuffer(
              id: 'outside',
              text: 'needle outside',
              lastSavedText: '',
              dirty: true,
              untitledName: 'External scratch',
            ),
          ],
          activeBufferId: 'outside',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 160));
      expect(service.reads, 1);
      expect(container.read(searchSessionProvider).requestRevision, revision);
      expect(container.read(searchSessionProvider).results, hasLength(1));
    },
  );

  test(
    'workspace read-ahead remains bounded and stops after cancellation',
    () async {
      final service = _ReadAheadService();
      final container = containerFor(
        _state(files: [for (var i = 0; i < 50; i++) _file('file-$i.md')]),
        service: service,
      );
      container.read(appRouterProvider).go('/workspace');
      await Future<void>.delayed(Duration.zero);
      final session = container.read(searchSessionProvider.notifier);
      session.open(category: SearchCategory.workspace);
      session.query('needle');
      final opening = session.submit();
      await service.windowStarted.future;
      expect(service.reads, 8);
      session.open(category: SearchCategory.actions);
      await session.submit();
      service.release.complete('needle');
      await opening;
      expect(service.reads, 8);
      expect(container.read(searchSessionProvider).results, isEmpty);
      expect(
        container.read(searchSessionProvider).category,
        SearchCategory.actions,
      );
    },
  );

  test(
    'Documents retains configuration and resource inventory without body search',
    () async {
      final container = containerFor(
        _state(
          files: [
            _file('writerside.cfg', kind: DocumentKind.config),
            _file('resources/terms.txt', kind: DocumentKind.resource),
            _file('other.md'),
          ],
        ),
      );
      container.read(appRouterProvider).go('/workspace');
      await Future<void>.delayed(Duration.zero);
      final session = container.read(searchSessionProvider.notifier);
      session.open(category: SearchCategory.documents);
      session.query('writerside');
      await session.submit();
      expect(
        (container.read(searchSessionProvider).results.single
                as DocumentSearchResult)
            .document
            .filePath,
        '/workspace/writerside.cfg',
      );
      session.query('terms');
      await session.submit();
      expect(
        (container.read(searchSessionProvider).results.single
                as DocumentSearchResult)
            .document
            .filePath,
        '/workspace/resources/terms.txt',
      );
      session.query('needle');
      await session.submit();
      expect(container.read(searchSessionProvider).results, isEmpty);
    },
  );
}

DocumentFile _file(String path, {DocumentKind kind = DocumentKind.markdown}) =>
    DocumentFile(
      absolutePath: '/workspace/$path',
      relativePath: path,
      kind: kind,
      size: 32,
      lastModified: DateTime(2026),
    );

WorkspaceState _state({
  String text = 'prefix needle suffix',
  String id = 'scratch-a',
  List<DocumentFile> files = const [],
}) => WorkspaceState(
  workspace: Workspace(
    id: 'workspace',
    rootPath: '/workspace',
    kind: WorkspaceKind.markdownFolder,
    openedAt: DateTime(2026),
    files: files,
    diagnostics: const [],
  ),
  documentBuffers: [
    DocumentBuffer(
      id: id,
      text: text,
      lastSavedText: '',
      dirty: true,
      untitledName: 'Untitled',
    ),
  ],
  activeBufferId: id,
);

class _Workspace extends WorkspaceController {
  _Workspace(this.initial);
  final WorkspaceState initial;
  @override
  WorkspaceState build() => initial;
  void replace(WorkspaceState next) => state = next;
}

class _GatedService extends WorkspaceService {
  final started = Completer<void>();
  final release = Completer<String>();
  @override
  Future<String> loadText(String path) {
    started.complete();
    return release.future;
  }
}

class _ReadAheadService extends _GatedService {
  int reads = 0;
  final windowStarted = Completer<void>();
  @override
  Future<String> loadText(String path) {
    reads++;
    if (reads == 8) windowStarted.complete();
    return release.future;
  }
}

class _ProgressService extends _GatedService {
  @override
  Future<String> loadText(String path) =>
      path.endsWith('/a.md') ? Future.value('needle') : release.future;
}

class _Settings implements LocalSettingsStore {
  @override
  Future<Map<String, Object?>> load() async => AppSettings.defaults().toJson();
  @override
  Future<void> save(Map<String, Object?> json) async {}
}

class _SlowHistoryStore extends MemoryLocalHistoryStore {
  bool block = false;
  final started = Completer<void>();
  final release = Completer<void>();
  @override
  Future<LocalHistoryRevision?> readRevision(String id) async {
    if (block) {
      if (!started.isCompleted) started.complete();
      await release.future;
    }
    return super.readRevision(id);
  }
}
