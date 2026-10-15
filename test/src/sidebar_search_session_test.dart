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
  }) {
    final container = ProviderContainer(
      overrides: [
        workspaceControllerProvider.overrideWith(() => _Workspace(state)),
        localSettingsStoreProvider.overrideWithValue(_Settings()),
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
    session.open(
      category: SearchCategory.text,
      location: SearchLocation.document,
    );
    expect(
      container.read(searchSessionProvider).category,
      SearchCategory.actions,
    );
  });

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
        SearchCategory.text,
        SearchCategory.outline,
        SearchCategory.documents,
        SearchCategory.topics,
        SearchCategory.recent,
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
        SearchCategory.text,
        SearchCategory.outline,
        SearchCategory.documents,
        SearchCategory.recent,
        SearchCategory.actions,
      ]);
      session.open(
        category: SearchCategory.text,
        location: SearchLocation.document,
      );
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
      session.open(
        category: SearchCategory.text,
        location: SearchLocation.document,
      );
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

  test('late workspace text cannot publish into another category', () async {
    final service = _GatedService();
    final container = containerFor(
      _state(files: [_file('unopened.md')]),
      service: service,
    );
    container.read(appRouterProvider).go('/workspace');
    await Future<void>.delayed(Duration.zero);
    final session = container.read(searchSessionProvider.notifier);
    session.open(
      category: SearchCategory.text,
      location: SearchLocation.workspace,
    );
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
      session.open(
        category: SearchCategory.text,
        location: SearchLocation.workspace,
      );
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

class _Settings implements LocalSettingsStore {
  @override
  Future<Map<String, Object?>> load() async => AppSettings.defaults().toJson();
  @override
  Future<void> save(Map<String, Object?> json) async {}
}
