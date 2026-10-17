import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/l10n/generated/app_localizations_en.dart';
import 'package:busymark/src/app/quick_open.dart';
import 'package:busymark/src/search/search_sidebar.dart';
import 'package:busymark/src/search/search_result_presentation.dart';
import 'dart:collection';
import 'package:busymark/src/editor/source/source_document.dart';
import 'package:busymark/src/markdown/document_outline.dart';
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
    SourceSearchWorker? worker,
    LocalHistoryController? history,
  }) {
    final container = ProviderContainer(
      overrides: [
        if (worker != null)
          searchSessionProvider.overrideWith(
            () => SearchSessionController(worker: worker),
          ),
        if (history != null)
          localHistoryControllerProvider.overrideWith(() => history),
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

  test(
    'empty queries gate all seven waiting categories before provider work',
    () async {
      final fixture = await const WorkspaceService().openPath(
        'test/fixtures/writerside/basic_project',
      );
      final worker = _CountingWorker();
      final history = _CountingHistory();
      final files = _ReadCountingList(fixture.files);
      final module = fixture.writersideProject!.modules.first;
      final topics = _ReadCountingList(module.topics);
      final headings = _ReadCountingList([
        const DocumentOutlineHeading(level: 1, text: 'needle', id: 'needle'),
      ]);
      final initial = _state().copyWith(
        workspace: fixture.copyWith(
          files: files,
          writersideProject: null,
          writersideModule: module.copyWith(topics: topics),
        ),
      );
      final container = containerFor(
        initial.copyWith(
          liveOutline: ActiveDocumentOutline(
            workspaceId: fixture.id,
            bufferId: 'scratch-a',
            filePath: null,
            source: initial.activeText,
            headings: headings,
          ),
        ),
        worker: worker,
        history: history,
      );
      container.read(appRouterProvider).go('/workspace');
      await Future<void>.delayed(Duration.zero);
      final session = container.read(searchSessionProvider.notifier);
      // The expected categories are the agreed contract, not the production helper.
      for (final category in [
        SearchCategory.file,
        SearchCategory.workspace,
        SearchCategory.outline,
        SearchCategory.documents,
        SearchCategory.topics,
        SearchCategory.recent,
        SearchCategory.localHistory,
      ]) {
        files.reads = topics.reads = headings.reads = 0;
        session.open(category: category);
        expect(container.read(searchSessionProvider).waitingForInput, isTrue);
        expect(container.read(searchSessionProvider).searching, isFalse);
        await session.submit();
        session.showMore();
        session.refresh(container.read(workspaceControllerProvider));
        session.query('');
        await session.submit();
        await Future<void>.delayed(const Duration(milliseconds: 150));
        final state = container.read(searchSessionProvider);
        expect(
          state.results,
          isEmpty,
          reason: '$category must wait for a query',
        );
        expect(state.searching, isFalse);
        expect(state.truncated, isFalse);
        expect(state.skippedFiles, isEmpty);
        expect(state.error, isNull);
        expect(worker.requests, 0);
        expect(history.requests, 0);
        expect(
          history.builds,
          0,
          reason: 'Empty general History does not initialize its provider',
        );
        expect(
          files.reads,
          0,
          reason: 'No empty-query document inventory discovery',
        );
        expect(
          topics.reads,
          0,
          reason: 'No empty-query topic inventory discovery',
        );
        expect(headings.reads, 0, reason: 'No empty-query outline projection');
      }
      await container
          .read(appSettingsControllerProvider.notifier)
          .recordOpenedWorkspace(
            path: '/workspace/recent.md',
            kind: 'singleMarkdown',
          );
      session.open(category: SearchCategory.recent);
      await session.submit();
      expect(container.read(searchSessionProvider).waitingForInput, isTrue);
      expect(container.read(searchSessionProvider).results, isEmpty);
      session.query('recent');
      await session.submit();
      expect(
        container.read(searchSessionProvider).results.single,
        isA<RecentSearchResult>(),
      );
      session.query('');
      session.showMore();
      await session.submit();
      expect(container.read(searchSessionProvider).results, isEmpty);

      session.configureCommands([
        ActionSearchResult(
          BusyMarkCommand(
            id: 'test.action',
            label: (_) => 'Action',
            category: (_) => 'Test',
            scope: BusyMarkCommandScope.application,
            execute: () {},
          ),
          'Action',
          'Test',
          null,
        ),
      ]);
      session.open(category: SearchCategory.actions);
      await session.submit();
      expect(
        container.read(searchSessionProvider).results.single,
        isA<ActionSearchResult>(),
      );
    },
  );

  test(
    'clearing a query rejects delayed document work and empty submit never waits for it',
    () async {
      final worker = _CountingWorker()..gate = Completer<SourceSearchResult?>();
      final container = containerFor(_state(), worker: worker);
      container.read(appRouterProvider).go('/workspace');
      await Future<void>.delayed(Duration.zero);
      final session = container.read(searchSessionProvider.notifier);
      session.open(category: SearchCategory.file);
      session.query('needle');
      final running = session.submit();
      expect(worker.requests, 1);
      session.query('');
      await session.submit().timeout(const Duration(seconds: 1));
      worker.gate!.complete(
        searchSourceDocument(
          SourceDocument(fullText: 'prefix needle suffix'),
          const SourceSearchOptions(query: 'needle'),
        ),
      );
      await running;
      final state = container.read(searchSessionProvider);
      expect(state.results, isEmpty);
      expect(state.documentMatchCount, 0);
      expect(state.documentCurrentMatchIndex, isNull);
      expect(state.sourceNavigationRequest, 0);
      expect(state.waitingForInput, isTrue);
      expect(worker.requests, 1);
    },
  );

  test(
    'literal whitespace remains a document and local-workspace query',
    () async {
      final worker = _CountingWorker();
      final container = containerFor(
        _state(text: 'a  b\nc', files: []),
        worker: worker,
      );
      container.read(appRouterProvider).go('/workspace');
      await Future<void>.delayed(Duration.zero);
      final session = container.read(searchSessionProvider.notifier);
      session.open(category: SearchCategory.file);
      session.query('  ');
      await session.submit();
      final state = container.read(searchSessionProvider);
      expect(state.waitingForInput, isFalse);
      expect(worker.requests, 1);
      expect((state.results.single as TextSearchResult).match.startOffset, 1);
      session.open(category: SearchCategory.workspace);
      session.query(' ');
      expect(container.read(searchSessionProvider).waitingForInput, isFalse);
      await session.submit();
    },
  );

  test(
    'Outline search projects live heading identity, levels and duplicate ancestor context',
    () async {
      final initial = _state(text: '# A\n## Shared\n# B\n## Shared');
      final headings = [
        const DocumentOutlineHeading(
          level: 1,
          text: 'A',
          id: 'a',
          editorBlockId: 'a',
        ),
        const DocumentOutlineHeading(
          level: 2,
          text: 'Shared',
          id: 'shared',
          editorBlockId: 'first',
        ),
        const DocumentOutlineHeading(
          level: 1,
          text: 'B',
          id: 'b',
          editorBlockId: 'b',
        ),
        const DocumentOutlineHeading(
          level: 2,
          text: 'Shared',
          id: 'shared-1',
          editorBlockId: 'second',
        ),
      ];
      final container = containerFor(
        initial.copyWith(
          liveOutline: ActiveDocumentOutline(
            workspaceId: 'workspace',
            bufferId: 'scratch-a',
            filePath: null,
            source: initial.activeText,
            headings: headings,
          ),
        ),
      );
      container.read(appRouterProvider).go('/workspace');
      await Future<void>.delayed(Duration.zero);
      final session = container.read(searchSessionProvider.notifier);
      session.open(category: SearchCategory.outline);
      session.query('shared');
      await session.submit();
      final results = container
          .read(searchSessionProvider)
          .results
          .cast<OutlineSearchResult>();
      expect(results.map((r) => r.heading.editorBlockId), ['first', 'second']);
      expect(results.map((r) => r.heading.level), [2, 2]);
      expect(results.map((r) => r.ancestors.single), ['A', 'B']);
      expect(results.map((r) => r.identity).toSet(), hasLength(2));
      session.moveSelection(1);
      expect(container.read(searchSessionProvider).selected, 1);
      expect(
        container.read(workspaceControllerProvider).liveOutline!.headings,
        same(headings),
      );
      expect(
        container.read(workspaceControllerProvider).activeText,
        initial.activeText,
      );
    },
  );

  testWidgets(
    'Actions groups browsing by catalog category and ranks filtered matches before availability',
    (tester) async {
      final container = containerFor(_state());
      final session = container.read(searchSessionProvider.notifier);
      ActionSearchResult action(
        String id,
        String title,
        String category, {
        bool enabled = true,
      }) => ActionSearchResult(
        BusyMarkCommand(
          id: id,
          label: (_) => title,
          category: (_) => category,
          scope: BusyMarkCommandScope.application,
          execute: () => fail('Presentation cannot execute'),
        ),
        title,
        category,
        'Formatting command',
        enabled: enabled,
      );
      session.configureCommands(
        [
          action('app.other', 'Zebra', 'General'),
          action('edit.exact', 'Bold', 'Formatting', enabled: false),
          action('edit.prefix', 'Bold text', 'Formatting'),
          action('edit.token', 'Make Bold', 'Formatting'),
          action('edit.weak', 'Some Boldness', 'Formatting'),
          action('app.category', 'Bold settings', 'General'),
        ],
        categoryOrder: ['General', 'Formatting'],
      );
      session.open(category: SearchCategory.actions);
      await session.submit();
      expect(
        container.read(searchSessionProvider).results.map((r) => r.identity),
        [
          'app.category',
          'app.other',
          'edit.prefix',
          'edit.token',
          'edit.weak',
          'edit.exact',
        ],
      );
      session.select(3);
      session.query('Bold');
      await session.submit();
      var state = container.read(searchSessionProvider);
      expect(state.results.map((r) => r.identity), [
        'edit.exact',
        'app.category',
        'edit.prefix',
        'edit.token',
        'edit.weak',
      ]);
      expect(state.results[state.selected].identity, 'edit.token');
      session.select(0);
      session.query('');
      await session.submit();
      state = container.read(searchSessionProvider);
      expect(state.results[state.selected].identity, 'edit.exact');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SearchResultList(
                groupActions: true,
                results: state.results,
                selected: state.selected,
                onActivate: (_) async => fail('Disabled action'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('General'), findsOneWidget);
      expect(find.text('Formatting'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is BusyMarkSidebarRecordRow),
        findsNWidgets(6),
      );
      final disabled = tester.widget<BusyMarkSidebarRecordRow>(
        find.byKey(const ValueKey('edit.exact')),
      );
      expect(disabled.onTap, isNull);
      session.moveSelection(-1);
      expect(
        container.read(searchSessionProvider).selected,
        4,
        reason: 'Headings are not selection indices',
      );
    },
  );

  testWidgets(
    'search header uses one Settings selector and the eight agreed category labels',
    (tester) async {
      final container = containerFor(_state());
      container.read(appRouterProvider).go('/workspace');
      final session = container.read(searchSessionProvider.notifier);
      session.open(category: SearchCategory.file);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SizedBox(width: 250, height: 500, child: SearchSidebar()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(SearchSidebar));
      expect(
        SearchCategory.values.map((c) => searchCategoryLabel(context, c)),
        [
          'Document Text',
          'Workspace Text',
          'Headings',
          'Documents',
          'Topics',
          'Recent',
          'Local History',
          'Actions',
        ],
      );
      expect(find.text('Search:'), findsOneWidget);
      final selector = tester.widget<BusyMarkPopupSelector<SearchCategory>>(
        find.byKey(const ValueKey('search-category')),
      );
      expect(selector.fullWidth, isTrue);
      expect(selector.options.map((o) => o.value), session.categories);
      final shortcuts = {
        for (final option in selector.options) option.value: option.shortcut,
      };
      expect(shortcuts[SearchCategory.file], 'Ctrl+F');
      expect(shortcuts[SearchCategory.workspace], 'Ctrl+Shift+F');
      expect(shortcuts[SearchCategory.outline], 'Ctrl+Alt+H');
      expect(shortcuts[SearchCategory.documents], 'Ctrl+P');
      expect(shortcuts[SearchCategory.recent], 'Ctrl+Alt+O');
      expect(shortcuts[SearchCategory.localHistory], 'Ctrl+Alt+Y');
      expect(shortcuts[SearchCategory.actions], 'Ctrl+Shift+P');
      expect(
        selector.options
            .singleWhere((o) => o.value == SearchCategory.outline)
            .gtkAccelerator,
        '<Primary><Alt>h',
      );
      expect(find.byType(DropdownButton<SearchCategory>), findsNothing);
    },
  );

  testWidgets(
    'Actions sort available first by localized metadata and preserve selected identity on availability change',
    (tester) async {
      final container = containerFor(_state());
      final session = container.read(searchSessionProvider.notifier);
      ActionSearchResult command(
        String id,
        String name, {
        bool enabled = true,
      }) => ActionSearchResult(
        BusyMarkCommand(
          id: id,
          label: (_) => name,
          category: (_) => 'Test',
          scope: BusyMarkCommandScope.application,
          execute: () => fail('Sorting must never execute actions'),
        ),
        name,
        'Test',
        null,
        enabled: enabled,
      );
      session.configureCommands([
        command('z', 'Zulu'),
        command('a', 'Alpha', enabled: false),
        command('b', 'Beta'),
      ]);
      session.open(category: SearchCategory.actions);
      await session.submit();
      expect(
        container.read(searchSessionProvider).results.map((r) => r.identity),
        ['b', 'z', 'a'],
      );
      session.select(2);
      session.configureCommands([
        command('z', 'Zulu'),
        command('a', 'Alpha'),
        command('b', 'Beta'),
      ]);
      await tester.pump();
      final state = container.read(searchSessionProvider);
      expect(state.results.map((r) => r.identity), ['a', 'b', 'z']);
      expect(state.results[state.selected].identity, 'a');
    },
  );

  testWidgets(
    'Actions keep the focused command identity across availability reordering',
    (tester) async {
      final container = containerFor(_state());
      final session = container.read(searchSessionProvider.notifier);
      ActionSearchResult command(
        String id,
        String title, {
        bool enabled = true,
      }) => ActionSearchResult(
        BusyMarkCommand(
          id: id,
          label: (_) => title,
          category: (_) => 'Test',
          scope: BusyMarkCommandScope.application,
          execute: () {},
        ),
        title,
        'Test',
        null,
        enabled: enabled,
      );
      session.configureCommands([
        command('z', 'Zulu'),
        command('a', 'Alpha', enabled: false),
        command('b', 'Beta'),
      ]);
      session.open(category: SearchCategory.actions);
      await session.submit();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final state = ref.watch(searchSessionProvider);
                  return SearchResultList(
                    results: state.results,
                    selected: state.selected,
                    onActivate: (_) async {},
                  );
                },
              ),
            ),
          ),
        ),
      );
      final originalFocus = tester
          .widget<BusyMarkSidebarRecordRow>(find.byKey(const ValueKey('z')))
          .focusNode!;
      originalFocus.requestFocus();
      await tester.pump();
      expect(container.read(searchSessionProvider).selected, 1);
      session.configureCommands([
        command('z', 'Zulu'),
        command('a', 'Alpha'),
        command('b', 'Beta'),
      ]);
      await tester.pumpAndSettle();
      final state = container.read(searchSessionProvider);
      expect(state.results.map((r) => r.identity), ['a', 'b', 'z']);
      expect(state.results[state.selected].identity, 'z');
      expect(FocusManager.instance.primaryFocus, same(originalFocus));
      expect(
        tester
            .widget<BusyMarkSidebarRecordRow>(find.byKey(const ValueKey('z')))
            .focusNode,
        same(originalFocus),
      );
    },
  );

  testWidgets(
    'Recent waits for input and distinguishes a completed no-results query',
    (tester) async {
      final container = containerFor(_state());
      final session = container.read(searchSessionProvider.notifier);
      session.open(category: SearchCategory.recent);
      await session.submit();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SizedBox(width: 280, height: 400, child: SearchSidebar()),
            ),
          ),
        ),
      );
      await tester.runAsync(session.submit);
      await tester.pumpAndSettle();
      expect(find.text(AppLocalizationsEn().searchEnterText), findsOneWidget);
      expect(find.text(AppLocalizationsEn().noResults), findsNothing);
      session.query('missing');
      await tester.runAsync(session.submit);
      await tester.pump();
      expect(find.text(AppLocalizationsEn().noResults), findsOneWidget);
      session.query('');
      await tester.runAsync(session.submit);
      await tester.pump();
      expect(find.text(AppLocalizationsEn().searchEnterText), findsOneWidget);
      expect(find.text(AppLocalizationsEn().noResults), findsNothing);
    },
  );

  testWidgets(
    'result metadata stays concise and never exposes remote identities',
    (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (value) {
              context = value;
              return const SizedBox();
            },
          ),
        ),
      );
      final local = RecentResource(
        path: '/project/topics/a.topic',
        ownerRoot: '/project',
        kind: 'writersideModule',
        title: 'A topic',
        document: true,
        lastOpenedAt: DateTime(2026),
      );
      final recent = presentSearchResult(context, RecentSearchResult(local));
      expect(recent.subtitle, 'project · topics/a.topic');
      expect(recent.details, '/project/topics/a.topic');
      for (final label in [null, 'Alex · notes.example']) {
        final resource = RecentResource(
          path: '',
          kind: 'nextcloudNotes',
          title: 'A note',
          accountId: 'private-account-id',
          localId: 'private-local-id',
          accountLabel: label,
          document: true,
          lastOpenedAt: DateTime(2026),
        );
        final remote = presentSearchResult(
          context,
          RecentSearchResult(resource),
        );
        expect(
          remote.subtitle,
          label ?? AppLocalizationsEn().searchAccountUnavailable,
        );
        expect(remote.subtitle, isNot(contains('private-')));
        final cached = presentSearchResult(
          context,
          RecentSearchResult(resource),
          accountLabel: (_) => 'Cached user · notes.example',
        );
        expect(cached.subtitle, 'Cached user · notes.example');
      }
      final document = presentSearchResult(
        context,
        const DocumentSearchResult(
          'workspace',
          QuickOpenDocument(
            title: 'Same',
            path: 'folder/Same.md',
            filePath: '/project/folder/Same.md',
          ),
        ),
      );
      expect(document.title, 'Same.md');
      expect(document.subtitle, 'folder');
      expect(document.details, '/project/folder/Same.md');
      final topic = presentSearchResult(
        context,
        const TopicSearchResult(
          'workspace',
          '/project/a.topic',
          'Same title',
          'different-id',
          'module A',
          'topics/a.topic',
        ),
      );
      expect(topic.subtitle, contains('module A'));
      expect(topic.subtitle, contains('different-id'));
      final historical = LocalHistoryDocument(
        id: 'history-owner',
        displayName: 'Deleted.md',
        historicalPaths: const ['/old/Deleted.md'],
        deleted: true,
        updatedAt: DateTime(2026),
      );
      final history = presentSearchResult(
        context,
        HistorySearchResult(LocalHistoryDocumentMatch(historical)),
      );
      expect(history.title, 'Deleted.md');
      expect(history.subtitle, '/old');
      expect(history.subtitle, isNot(contains('Local History')));
    },
  );

  for (final scale in [1.0, 1.8]) {
    testWidgets('Recent uses uniform two-line identity rows at scale $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final resources = [
        RecentResource(
          path: '/',
          title: 'Root',
          kind: 'markdownFolder',
          lastOpenedAt: DateTime(2026),
        ),
        RecentResource(
          path: '/one/Same.md',
          kind: 'markdownFolder',
          document: true,
          lastOpenedAt: DateTime(2026),
        ),
        RecentResource(
          path: '/very/long/unique-parent/deep/Same.md',
          kind: 'markdownFolder',
          document: true,
          lastOpenedAt: DateTime(2026),
        ),
        RecentResource(
          path: '/projects/Guide/topics/a-very-long-topic-name.topic',
          ownerRoot: '/projects/Guide',
          title: 'A long Writerside title that must remain on one line',
          kind: 'writersideModule',
          document: true,
          lastOpenedAt: DateTime(2026),
        ),
        RecentResource(
          path: '',
          title: 'Same.md',
          kind: 'nextcloudNotes',
          document: true,
          accountId: 'account-one',
          localId: 'same-id',
          accountLabel: 'Alex · one.example',
          lastOpenedAt: DateTime(2026),
        ),
        RecentResource(
          path: '',
          title: 'Same.md',
          kind: 'nextcloudNotes',
          document: true,
          accountId: 'account-two',
          localId: 'same-id',
          accountLabel: 'Alex · two.example',
          lastOpenedAt: DateTime(2026),
        ),
      ];
      final rows = resources.map(RecentSearchResult.new).toList();
      final activated = <String>[];
      final container = containerFor(_state());
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: Scaffold(
                  body: SizedBox(
                    width: 250,
                    height: 1200,
                    child: SearchResultList(
                      results: rows,
                      onActivate: (r) async => activated.add(r.identity),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      double? height;
      final subtitles = <String>{};
      for (var i = 0; i < rows.length; i++) {
        final finder = find.byKey(ValueKey(rows[i].identity));
        final row = tester.widget<BusyMarkSidebarRecordRow>(finder);
        expect(row.content, isNull);
        expect(row.title, isNotEmpty);
        expect(row.subtitle, isNotEmpty);
        expect(subtitles.add(row.subtitle!), isTrue);
        final measured = tester.getSize(finder).height;
        height ??= measured;
        expect(measured, moreOrLessEquals(height));
        final full = resources[i].accountId == null
            ? resources[i].path
            : resources[i].accountLabel!;
        expect(row.tooltip, full);
        expect(row.semanticsLabel, contains(full));
        for (final text in tester.widgetList<Text>(
          find.descendant(of: finder, matching: find.byType(Text)),
        )) {
          expect(text.maxLines, 1);
        }
        await tester.tap(finder);
      }
      expect(activated, rows.map((r) => r.identity).toList());
      expect(resources[2].path, '/very/long/unique-parent/deep/Same.md');
    });
  }

  testWidgets(
    'shared result rows are compact, accessible and truly disable unavailable actions',
    (tester) async {
      final container = containerFor(_state());
      final disabled = ActionSearchResult(
        BusyMarkCommand(
          id: 'disabled',
          label: (_) => 'Unavailable action',
          category: (_) => 'Notes',
          scope: BusyMarkCommandScope.application,
          execute: () => fail('Disabled execution'),
        ),
        'Unavailable action',
        'Notes',
        null,
        enabled: false,
        disabledReason: 'Requires a Notes workspace',
      );
      final rows = <SidebarSearchResult>[
        const DocumentSearchResult(
          'workspace',
          QuickOpenDocument(
            title: 'Short',
            path: 'folder/Short.md',
            filePath: '/project/folder/Short.md',
          ),
        ),
        disabled,
      ];
      var activations = 0;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox(
                width: 280,
                height: 400,
                child: SearchResultList(
                  results: rows,
                  selected: 1,
                  onActivate: (_) async {
                    activations++;
                  },
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(ListTile), findsNothing);
      final short = find.byKey(ValueKey(rows.first.identity));
      expect(tester.getSize(short).height, lessThan(80));
      final unavailable = tester.widget<BusyMarkSidebarRecordRow>(
        find.byKey(const ValueKey('disabled')),
      );
      expect(unavailable.onTap, isNull);
      expect(unavailable.selected, isTrue);
      expect(
        unavailable.semanticsLabel,
        contains('Requires a Notes workspace'),
      );
      await tester.tap(find.byKey(const ValueKey('disabled')));
      expect(activations, 0);
      await tester.tap(short);
      expect(activations, 1);
    },
  );

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
            .read(searchSessionProvider)
            .sourceSnapshot(
              container.read(workspaceControllerProvider).activeBuffer,
            )
            .result
            .options,
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
        container.read(searchSessionProvider).copyWith(query: 'Needle'),
      );
      await session.submit();
      expect(container.read(searchSessionProvider).documentMatchCount, 2);
      session.open(category: SearchCategory.workspace);
      expect(container.read(searchSessionProvider).query, isEmpty);
      session.set(
        container
            .read(searchSessionProvider)
            .copyWith(query: 'workspace query'),
      );
      session.open(category: SearchCategory.file);
      expect(
        container.read(searchSessionProvider).options,
        const SourceSearchOptions(query: 'Needle'),
      );
      await session.submit();
      session.open(category: SearchCategory.workspace);
      expect(
        container.read(searchSessionProvider).options,
        const SourceSearchOptions(query: 'workspace query'),
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

class _CountingWorker extends SourceSearchWorker {
  int requests = 0;
  Completer<SourceSearchResult?>? gate;
  @override
  Future<SourceSearchResult?> search(
    SourceDocument document,
    SourceSearchOptions options, {
    int? currentMatchIndex,
    int firstMatchIndex = 0,
    int? minimumFullOffset,
    int maximumMatches = sourceInteractiveSearchMatchLimit,
    bool stopAfterMaximumMatches = false,
    bool reuseWorker = false,
  }) {
    requests++;
    return gate?.future ??
        super.search(
          document,
          options,
          currentMatchIndex: currentMatchIndex,
          firstMatchIndex: firstMatchIndex,
          minimumFullOffset: minimumFullOffset,
          maximumMatches: maximumMatches,
          stopAfterMaximumMatches: stopAfterMaximumMatches,
          reuseWorker: reuseWorker,
        );
  }
}

class _CountingHistory extends LocalHistoryController {
  int requests = 0, builds = 0;
  @override
  LocalHistoryState build() {
    builds++;
    return const LocalHistoryState();
  }

  @override
  Future<LocalHistorySearchPage?> findRetained({
    required String query,
    String? documentId,
    int maximumResults = 80,
    bool Function()? isCancelled,
    void Function(LocalHistorySearchPage)? onProgress,
  }) async {
    requests++;
    return const LocalHistorySearchPage([]);
  }
}

class _ReadCountingList<T> extends ListBase<T> {
  _ReadCountingList(this.values);
  final List<T> values;
  int reads = 0;
  @override
  int get length => values.length;
  @override
  set length(int value) => throw UnsupportedError('Read only');
  @override
  T operator [](int index) {
    reads++;
    return values[index];
  }

  @override
  void operator []=(int index, T value) => throw UnsupportedError('Read only');
}
