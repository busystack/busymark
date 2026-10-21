import 'dart:async';
import 'package:busymark/src/search/search_session.dart';
import 'package:busymark/src/search/search_sidebar.dart';
import 'package:busymark/src/search/welcome_notes_action.dart';
import 'package:busymark/src/app/command_registry.dart';
import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_api_client.dart';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/nextcloud_notes/domain/notes_conflict.dart';
import 'package:busymark/src/app/app_router.dart';
import 'package:busymark/src/app/busymark_app.dart';
import 'package:busymark/src/app/system_accent.dart';
import 'package:busymark/src/app/window_control_service.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_settings_controller.dart';
import 'package:window_manager/window_manager.dart';
import 'package:busymark/src/local_history/local_history_controller.dart';
import 'package:busymark/src/local_history/local_history_store.dart';
import 'package:busymark/src/nextcloud_notes/application/nextcloud_connection.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_navigation.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_repository.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_store.dart';
import 'package:busymark/src/nextcloud_notes/domain/notes_models.dart';
import 'package:busymark/src/nextcloud_notes/presentation/notes_sidebar.dart';
import 'package:busymark/src/nextcloud_notes/presentation/notes_workspace_ui.dart';
import 'package:busymark/src/workspace/presentation/settings_screen.dart';
import 'package:busymark/src/workspace/recovery_persistence.dart';
import 'package:busymark/src/workspace/session_persistence.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/workspace/workspace_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

Future<void> settleStorage(WidgetTester tester) async {
  // Give real history/attachment I/O a real async turn before settling frames.
  // Animating an indeterminate loader in fake time cannot complete that I/O.
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  var rounds = 0;
  bool loading() => find
      .byWidgetPredicate(
        (w) =>
            w is LinearProgressIndicator && w.value == null ||
            w is CircularProgressIndicator && w.value == null,
      )
      .evaluate()
      .isNotEmpty;
  do {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump(const Duration(milliseconds: 30));
    rounds++;
  } while ((rounds < 10 || loading()) && DateTime.now().isBefore(deadline));
  await tester.pumpAndSettle();
}

void main() {
  late Directory root;
  late NotesRepository repository;
  const accountId = '123e4567-e89b-42d3-a456-426614174000';
  setUp(() async {
    // Recovery dialogs also use Yaru's window state stream. Give every widget
    // test its own native boundary rather than inheriting a prior test's mock.
    for (final channelName in ['yaru_window', 'yaru_window/events']) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            MethodChannel(channelName),
            (call) async => call.method == 'state' ? <String, Object?>{} : null,
          );
    }
    root = await Directory.systemTemp.createTemp('notes-ui-test-');
    final store = await NotesStore.open(
      path: p.join(root.path, 'notes.sqlite3'),
    );
    await store.saveAccount(
      NextcloudAccount(
        id: accountId,
        server: Uri.parse('https://cloud.example/nextcloud/'),
        loginName: 'exact-user',
        appVersion: '6.1.0',
      ),
    );
    await store.saveNote(
      const NextcloudNote(
        localId: '223e4567-e89b-42d3-a456-426614174000',
        accountId: accountId,
        title: 'Personal note',
        content: 'private search text',
        category: 'Personal',
        favorite: true,
      ),
    );
    await store.saveAttachment(
      const NotesAttachment(
        id: '623e4567-e89b-42d3-a456-426614174000',
        noteId: '223e4567-e89b-42d3-a456-426614174000',
        filename: 'report.pdf',
        reference: 'busymark-attachment:account:note:attachment',
        remotePath: '.attachments.1/report.pdf',
        state: 'uploaded',
      ),
      Uint8List.fromList([1, 2, 3]),
    );
    await store.saveNote(
      const NextcloudNote(
        localId: '323e4567-e89b-42d3-a456-426614174000',
        accountId: accountId,
        title: 'Shared note',
        content: 'shared material',
        category: 'Projects/BusyMark',
        readonly: true,
      ),
    );
    await store.saveNote(
      const NextcloudNote(
        localId: '423e4567-e89b-42d3-a456-426614174000',
        accountId: accountId,
        title: 'Deleted note',
        content: '',
        syncState: NoteSyncState.deletedRemotely,
        revision: 1,
        ackRevision: 1,
      ),
    );
    await store.saveNote(
      const NextcloudNote(
        localId: '523e4567-e89b-42d3-a456-426614174000',
        accountId: accountId,
        serverId: 5,
        title: 'Recoverable edit',
        content: 'durable local work',
        revision: 2,
        ackRevision: 1,
        syncState: NoteSyncState.deletedRemotely,
      ),
    );
    for (final state in [NoteSyncState.forbidden, NoteSyncState.unavailable]) {
      await store.saveNote(
        NextcloudNote(
          localId: 'blocked-${state.name}',
          accountId: accountId,
          serverId: state == NoteSyncState.forbidden ? 6 : 7,
          title: 'Blocked durable note',
          content: 'durable pending content',
          readonly: true,
          revision: 2,
          ackRevision: 1,
          syncState: state,
          remote: NoteState(
            id: state == NoteSyncState.forbidden ? 6 : 7,
            etag: 'server-reference',
            content: 'server content',
            title: 'Blocked durable note',
            category: '',
            favorite: false,
            readonly: true,
            modified: 0,
            error: state == NoteSyncState.unavailable,
          ),
        ),
      );
    }
    await store.saveNote(
      const NextcloudNote(
        localId: '723e4567-e89b-42d3-a456-426614174000',
        accountId: accountId,
        serverId: 8,
        title: 'Uncertain attachment note',
        content: '[file](busymark-attachment:uncertain)',
        syncState: NoteSyncState.conflict,
        remote: NoteState(
          id: 8,
          etag: 'etag',
          content: '',
          title: 'Uncertain attachment note',
          category: '',
          favorite: false,
          readonly: false,
          modified: 0,
        ),
      ),
    );
    await store.saveAttachment(
      const NotesAttachment(
        id: '823e4567-e89b-42d3-a456-426614174000',
        noteId: '723e4567-e89b-42d3-a456-426614174000',
        filename: 'uncertain.pdf',
        reference: 'busymark-attachment:uncertain',
        state: 'uncertain',
      ),
      Uint8List.fromList([1, 2, 3]),
    );
    const readonlyBase = NoteState(
      id: 9,
      etag: 'readonly-base',
      content: 'base content',
      title: 'Read-only conflict',
      category: '',
      favorite: false,
      readonly: false,
      modified: 1,
    );
    const readonlyRemote = NoteState(
      id: 9,
      etag: 'readonly-fresh',
      content: 'remote content',
      title: 'Read-only conflict',
      category: '',
      favorite: false,
      readonly: true,
      modified: 2,
    );
    await store.saveNote(
      const NextcloudNote(
        localId: 'readonly-favorite-conflict',
        accountId: accountId,
        serverId: 9,
        title: 'Read-only conflict',
        content: 'base content',
        favorite: true,
        readonly: true,
        etag: 'readonly-base',
        base: readonlyBase,
        remote: readonlyRemote,
        revision: 2,
        ackRevision: 1,
        syncState: NoteSyncState.conflict,
      ),
    );
    final creationAttempt = NotesCreationAttempt(
      id: 'uncertain-attempt',
      revision: 1,
      localContent: 'possible content',
      wireBody:
          '{"content":"possible content","title":"Requested","category":"","favorite":false,"modified":3}',
      knownServerIds: const {},
      candidateServerIds: const {10, 11},
    );
    await store.saveNote(
      NextcloudNote(
        localId: 'uncertain-create',
        accountId: accountId,
        title: 'Requested',
        content: 'possible content',
        creationAttempt: creationAttempt,
        syncState: NoteSyncState.creationUncertain,
        errorMessage: 'Two possible server notes were found.',
      ),
    );
    for (final candidate in [
      const NoteState(
        id: 10,
        etag: 'candidate-10',
        content: 'possible content',
        title: 'Sanitized A',
        category: '',
        favorite: false,
        readonly: false,
        modified: 3,
      ),
      const NoteState(
        id: 11,
        etag: 'candidate-11',
        content: 'possible content',
        title: 'Sanitized B',
        category: 'Category',
        favorite: false,
        readonly: false,
        modified: 3,
      ),
    ]) {
      await store.saveNote(
        NextcloudNote(
          localId: 'creation-candidate-${candidate.id}',
          accountId: accountId,
          serverId: candidate.id,
          title: candidate.title,
          content: candidate.content,
          category: candidate.category,
          etag: candidate.etag,
          base: candidate,
          revision: 1,
          ackRevision: 1,
          syncState: NoteSyncState.synced,
        ),
      );
    }
    const metadataBase = NoteState(
      id: 12,
      etag: 'metadata-base',
      content: 'body',
      title: 'A',
      category: '',
      favorite: false,
      readonly: false,
      modified: 1,
    );
    await store.saveNote(
      const NextcloudNote(
        localId: 'metadata-server',
        accountId: accountId,
        serverId: 12,
        title: 'A',
        content: 'body',
        etag: 'metadata-base',
        base: metadataBase,
        revision: 1,
        ackRevision: 1,
        syncState: NoteSyncState.synced,
      ),
    );
    repository = _CachedNotesRepository(store: store);
    await repository.initialize();
  });
  tearDown(() async {
    await repository.dispose();
    await root.delete(recursive: true);
    for (final channelName in ['yaru_window', 'yaru_window/events']) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(channelName), null);
    }
  });

  Future<void> pump(
    WidgetTester tester, {
    double height = 1000,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nextcloudNotesRepositoryProvider.overrideWith(
            (ref) async => repository,
          ),
          localSettingsStoreProvider.overrideWithValue(_TabSettings()),
          localHistoryStoreProvider.overrideWithValue(
            MemoryLocalHistoryStore(),
          ),
          documentSessionStoreProvider.overrideWithValue(
            MemoryDocumentSessionStore(),
          ),
          documentRecoveryStoreProvider.overrideWithValue(
            MemoryDocumentRecoveryStore(),
          ),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: height,
              child: const _NotesSearchHarness(accountId: accountId),
            ),
          ),
        ),
      ),
    );
    final scope = ProviderScope.containerOf(
      tester.element(find.byType(_NotesSearchHarness)),
    );
    scope.read(appRouterProvider).go('/workspace');
    await tester.runAsync(
      () => scope
          .read(workspaceControllerProvider.notifier)
          .openNextcloudWorkspace(accountId),
    );
    await settleStorage(tester);
  }

  Future<ProviderContainer> pumpWelcome(
    WidgetTester tester, {
    NextcloudConnectionController? connection,
    LocalSettingsStore? settings,
    Future<NotesRepository> Function()? repositoryLoader,
    NativeWindowController? nativeWindow,
    NotesSettingsController? serverSettings,
  }) async {
    tester.view.physicalSize = const Size(1100, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        if (nativeWindow != null)
          nativeWindowControllerProvider.overrideWithValue(nativeWindow),
        if (serverSettings != null)
          notesSettingsProvider.overrideWith(() => serverSettings),
        if (connection != null)
          nextcloudConnectionProvider.overrideWith(() => connection),
        nextcloudNotesRepositoryProvider.overrideWith(
          (ref) async =>
              repositoryLoader == null ? repository : await repositoryLoader(),
        ),
        localSettingsStoreProvider.overrideWithValue(
          settings ?? _TabSettings(),
        ),
        linuxAccentPlatformProvider.overrideWithValue(false),
        localHistoryStoreProvider.overrideWithValue(MemoryLocalHistoryStore()),
        documentSessionStoreProvider.overrideWithValue(
          MemoryDocumentSessionStore(),
        ),
        documentRecoveryStoreProvider.overrideWithValue(
          MemoryDocumentRecoveryStore(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    await settleStorage(tester);
    return container;
  }

  testWidgets('native close protects a dirty or saving server settings draft', (
    tester,
  ) async {
    final nativeWindow = _NotesNativeWindow();
    final settings = _WindowDraftSettings();
    final container = await pumpWelcome(
      tester,
      nativeWindow: nativeWindow,
      serverSettings: settings,
    );
    container
        .read(appRouterProvider)
        .go('/settings?returnTo=welcome&page=nextcloudNotes');
    await settleStorage(tester);
    final original = container.read(notesSettingsProvider).original;
    nativeWindow.listeners.single.onWindowClose();
    nativeWindow.listeners.single.onWindowClose();
    await settleStorage(tester);
    expect(find.byType(BusyMarkDialogShell), findsOneWidget);
    expect(nativeWindow.closeCount, 0);
    await tester.tap(
      find.descendant(
        of: find.byType(BusyMarkDialogShell),
        matching: find.text('Cancel'),
      ),
    );
    await settleStorage(tester);
    expect(container.read(notesSettingsProvider).original, same(original));
    expect(
      container.read(notesSettingsProvider).draft!.notesPath,
      'Unsaved/Notes',
    );
    settings.setSaving(true);
    await tester.pump();
    nativeWindow.listeners.single.onWindowClose();
    await tester.pump(const Duration(milliseconds: 100));
    expect(nativeWindow.closeCount, 0);
    expect(find.byType(BusyMarkDialogShell), findsNothing);
    settings.setSaving(false);
    await tester.pump();
    nativeWindow.listeners.single.onWindowClose();
    await settleStorage(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(BusyMarkDialogShell),
        matching: find.text('Discard'),
      ),
    );
    await settleStorage(tester);
    expect(nativeWindow.closeCount, 1);
    expect(container.read(notesSettingsProvider).dirty, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('account settings can retry local repository initialization', (
    tester,
  ) async {
    var failed = true;
    var attempts = 0;
    final container = await pumpWelcome(
      tester,
      repositoryLoader: () async {
        attempts++;
        if (failed) throw const FileSystemException('controlled store failure');
        return repository;
      },
    );
    container
        .read(appRouterProvider)
        .go('/settings?returnTo=welcome&page=nextcloudNotes');
    await settleStorage(tester);
    expect(
      find.text(
        'BusyMark could not load the local Notes store. Retry to open your cached notes.',
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<BusyMarkActionRow>(
            find.byKey(const ValueKey('nextcloud-connect')),
          )
          .enabled,
      isFalse,
    );
    failed = false;
    final failedAttempts = attempts;
    await tester.tap(find.text('Retry'));
    await settleStorage(tester);
    expect(attempts, greaterThan(failedAttempts));
    expect(
      find.text(
        'BusyMark could not load the local Notes store. Retry to open your cached notes.',
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'Notes survives Outline and Search with category, sort, expansion and actual scroll geometry',
    (tester) async {
      await tester.runAsync(() async {
        for (var i = 0; i < 60; i++) {
          await repository.create(
            accountId,
            title: 'Project $i',
            category: 'Projects/BusyMark',
          );
        }
      });
      final container = await pumpWelcome(tester);
      await tester.runAsync(
        () => container
            .read(workspaceControllerProvider.notifier)
            .openNextcloudWorkspace(accountId),
      );
      container.read(appRouterProvider).go('/workspace');
      await settleStorage(tester);
      tester
          .widget<BusyMarkSidebarTreeRow>(
            find.byKey(const ValueKey('notes-category-Projects')),
          )
          .onTap!();
      await settleStorage(tester);
      tester
          .widget<BusyMarkPopupSelector<NotesSort>>(
            find.byType(BusyMarkPopupSelector<NotesSort>),
          )
          .onSelected(NotesSort.titleDescending);
      tester
          .widget<BusyMarkSidebarTreeRow>(
            find.byKey(const ValueKey('notes-category-Projects')),
          )
          .onToggle!();
      await settleStorage(tester);
      final list = tester.widget<ListView>(
        find.byKey(const ValueKey('nextcloud-notes-list')),
      );
      list.controller!.jumpTo(150);
      await tester.pump();
      final nav = container.read(notesNavigationProvider(accountId));
      final selected = nav.visible[4].localId;
      nav.select(selected);
      final registry = container.read(busyMarkCommandRegistryProvider);
      await registry.execute(BusyMarkCommandIds.sidebarOutline);
      await settleStorage(tester);
      expect(find.byType(NextcloudNotesSidebar), findsNothing);
      await registry.execute(BusyMarkCommandIds.sidebarFiles);
      await settleStorage(tester);
      expect(find.byType(NextcloudNotesSidebar), findsOneWidget);
      expect(container.read(notesNavigationProvider(accountId)), same(nav));
      expect(nav.destination, NotesDestination.category);
      expect(nav.category, 'Projects');
      expect(nav.sort, NotesSort.titleDescending);
      expect(nav.collapsed, contains('Projects'));
      expect(nav.selected, contains(selected));
      expect(
        tester
            .widget<BusyMarkSidebarRecordRow<String>>(
              find.byKey(ValueKey('nextcloud-note-$selected')),
            )
            .focusNode!
            .hasFocus,
        isTrue,
      );
      expect(list.controller!.offset, 150);
      container
          .read(searchSessionProvider.notifier)
          .open(category: SearchCategory.workspace);
      await settleStorage(tester);
      container.read(searchSessionProvider.notifier).close();
      await settleStorage(tester);
      expect(nav.destination, NotesDestination.category);
      expect(list.controller!.offset, 150);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final destination in [
    NotesDestination.favorites,
    NotesDestination.recovery,
  ]) {
    testWidgets(
      'creating through the command from $destination reveals a live selected note',
      (tester) async {
        await pump(tester);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(_NotesSearchHarness)),
        );
        final nav = container.read(notesNavigationProvider(accountId));
        tester
            .widget<BusyMarkSidebarTreeRow>(find.byKey(ValueKey(destination)))
            .onTap!();
        await settleStorage(tester);
        await tester.runAsync(
          () => container
              .read(workspaceControllerProvider.notifier)
              .createNextcloudNote(title: 'Created from filter'),
        );
        await settleStorage(tester);
        final id = container
            .read(workspaceControllerProvider)
            .activeBuffer!
            .remoteNote!
            .localId;
        expect(nav.destination, NotesDestination.all);
        expect(nav.selected, contains(id));
        expect(
          find.byKey(ValueKey('nextcloud-note-$id')).hitTestable(),
          findsOneWidget,
        );
        expect(repository.noteById(id)!.favorite, isFalse);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'Welcome retains a remote revocation warning without a phantom connected account',
    (tester) async {
      final container = await pumpWelcome(
        tester,
        connection: _RemovedConnection(),
      );
      container.read(nextcloudConnectionProvider);
      await container
          .read(appSettingsControllerProvider.notifier)
          .setThemeModePreference(BusyMarkThemeModePreference.dark);
      await settleStorage(tester);
      expect(container.read(nextcloudConnectionProvider).account, isNull);
      expect(
        find.textContaining('App-password revocation was not confirmed'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Nextcloud Security settings'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Page and End navigation reveal actual scaled note row geometry in a short sidebar',
    (tester) async {
      await tester.runAsync(() async {
        for (var i = 0; i < 50; i++) {
          await repository.create(
            accountId,
            title: 'Variable height note $i with a long title',
            category: '',
          );
        }
      });
      await pump(tester, height: 420, textScale: 1.6);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(_NotesSearchHarness)),
      );
      final nav = container.read(notesNavigationProvider(accountId));
      tester
          .widget<BusyMarkSidebarRecordRow<String>>(
            find.byKey(ValueKey('nextcloud-note-${nav.visible.first.localId}')),
          )
          .focusNode!
          .requestFocus();
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await settleStorage(tester);
      expect(nav.focused, nav.visible.first.localId);
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await settleStorage(tester);
      expect(
        nav.visible.indexWhere((n) => n.localId == nav.focused),
        greaterThan(1),
      );
      expect(
        find.byKey(ValueKey('nextcloud-note-${nav.focused}')).hitTestable(),
        findsOneWidget,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await settleStorage(tester);
      expect(nav.focused, nav.visible.last.localId);
      expect(
        find.byKey(ValueKey('nextcloud-note-${nav.focused}')).hitTestable(),
        findsOneWidget,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await settleStorage(tester);
      expect(nav.focused, nav.visible.first.localId);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final failSave in [false, true]) {
    testWidgets(
      'qualified Recent reopening keeps account identity when save fails=$failSave',
      (tester) async {
        const otherAccount = '923e4567-e89b-42d3-a456-426614174000';
        const localId = '223e4567-e89b-42d3-a456-426614174000';
        await tester.runAsync(
          () => repository.upsertAccount(
            NextcloudAccount(
              id: otherAccount,
              server: Uri.parse('https://other.example/'),
              loginName: 'other',
              appVersion: '6.1.0',
            ),
          ),
        );
        final settings = _RecentReopenSettings(
          failSave: failSave,
          value: AppSettings.defaults()
              .copyWith(
                autoSave: false,
                reopenPreviousWorkspaceOnStartup: false,
                recentWorkspaces: [
                  RecentResource(
                    path: '',
                    kind: 'nextcloudNote',
                    document: true,
                    accountId: otherAccount,
                    localId: localId,
                    title: 'Wrong account row',
                    lastOpenedAt: DateTime.utc(2026, 10, 21),
                  ),
                  RecentResource(
                    path: '',
                    kind: 'nextcloudNote',
                    document: true,
                    accountId: accountId,
                    accountLabel: 'Original account',
                    localId: localId,
                    title: 'Qualified reopen row',
                    lastOpenedAt: DateTime.utc(2026, 10, 20),
                  ),
                ],
              )
              .toJson(),
        );
        final container = await pumpWelcome(tester, settings: settings);
        await tester.tap(find.text('Wrong account row'));
        await settleStorage(tester);
        expect(container.read(workspaceControllerProvider).workspace, isNull);
        await tester.tap(find.text('Qualified reopen row'));
        await settleStorage(tester);
        final state = container.read(workspaceControllerProvider);
        expect(state.workspace!.nextcloudAccountId, accountId);
        expect(state.activeBuffer!.remoteNote!.accountId, accountId);
        expect(state.activeBuffer!.remoteNote!.localId, localId);
        expect(state.activeText, 'private search text');
        expect(
          container
              .read(appRouterProvider)
              .routeInformationProvider
              .value
              .uri
              .path,
          '/workspace',
        );
        expect(state.message?.code, isNot(WorkspaceMessageCode.openFailed));
        if (failSave) {
          expect(
            state.message?.code,
            WorkspaceMessageCode.recentWorkspaceUpdateFailed,
          );
        }
        await container
            .read(appSettingsControllerProvider.notifier)
            .flushPersistence();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        container.dispose();
      },
    );
  }

  testWidgets(
    'Welcome New Note without an account cancels on returning from settings',
    (tester) async {
      await tester.runAsync(() async {
        await repository.dispose();
        repository = _CachedNotesRepository(
          store: await NotesStore.open(path: '${root.path}/empty.sqlite3'),
        );
        await repository.initialize();
      });
      final container = await pumpWelcome(tester);
      await tester.tap(
        find.byKey(const ValueKey('welcome-new-nextcloud-note')),
      );
      await settleStorage(tester);
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/settings',
      );
      expect(
        container.read(welcomeNotesActionProvider),
        WelcomeNotesAction.create,
      );
      expect(repository.notes, isEmpty);
      container.read(appRouterProvider).go('/');
      await settleStorage(tester);
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/',
      );
      expect(container.read(welcomeNotesActionProvider), isNull);
      expect(repository.notes, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Welcome resumes exactly one requested note after successful connection',
    (tester) async {
      final connection = _ConnectingWelcomeAccount(repository.accounts.first);
      final container = await pumpWelcome(tester, connection: connection);
      final before = repository.notes.length;
      await tester.tap(
        find.byKey(const ValueKey('welcome-new-nextcloud-note')),
      );
      await settleStorage(tester);
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/settings',
      );
      expect(repository.notes.length, before);
      await tester.tap(find.text('Connect'));
      await settleStorage(tester);
      await tester.runAsync(() async {
        final deadline = DateTime.now().add(const Duration(seconds: 10));
        while (container.read(welcomeNotesActionProvider.notifier).busy &&
            DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      });
      await settleStorage(tester);
      expect(repository.notes.length, before + 1);
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/workspace',
      );
      expect(container.read(welcomeNotesActionProvider), isNull);
      expect(
        container
            .read(workspaceControllerProvider)
            .activeBuffer!
            .remoteNote!
            .accountId,
        accountId,
      );
      container.read(appRouterProvider).go('/');
      await settleStorage(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await tester.pump();
      // Settings created this stream inside FakeAsync. Flush its cancellation
      // while closing the fixture's real SQLite worker.
      var closed = false;
      await tester.runAsync(() async {
        unawaited(repository.dispose().then((_) => closed = true));
      });
      for (var i = 0; i < 100 && !closed; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(
        closed,
        isTrue,
        reason: 'Fixture storage and provider subscriptions must close.',
      );
    },
  );

  testWidgets(
    'Welcome New Note claims double activation once and records the individual note',
    (tester) async {
      final container = await pumpWelcome(tester);
      final navigation = container.read(notesNavigationProvider(accountId));
      navigation.destination = NotesDestination.favorites;
      navigation.update(repository.notes, accountId);
      final before = repository.notes.length;
      final registry = container.read(busyMarkCommandRegistryProvider);
      await tester.runAsync(() async {
        await Future.wait([
          registry.execute(BusyMarkCommandIds.newNote),
          registry.execute(BusyMarkCommandIds.newNote),
        ]);
        final deadline = DateTime.now().add(const Duration(seconds: 10));
        while (container.read(welcomeNotesActionProvider.notifier).busy &&
            DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      });
      await settleStorage(tester);
      expect(
        repository.notes.length,
        before + 1,
        reason:
            '${container.read(workspaceControllerProvider).message}; ${container.read(appRouterProvider).routeInformationProvider.value.uri}',
      );
      final active = container.read(workspaceControllerProvider).activeBuffer!;
      expect(active.remoteNote!.accountId, accountId);
      expect(
        navigation.visible.map((note) => note.localId),
        contains(active.remoteNote!.localId),
      );
      expect(navigation.selected, contains(active.remoteNote!.localId));
      expect(
        find
            .byKey(ValueKey('nextcloud-note-${active.remoteNote!.localId}'))
            .hitTestable(),
        findsOneWidget,
      );
      expect(
        container
            .read(appSettingsControllerProvider)
            .recentWorkspaces
            .where(
              (r) =>
                  r.accountId == accountId &&
                  r.localId == active.remoteNote!.localId,
            ),
        hasLength(1),
      );
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/workspace',
      );
      container.read(appRouterProvider).go('/');
      await settleStorage(tester);
      expect(container.read(searchSessionProvider.notifier).categories, [
        SearchCategory.recent,
        SearchCategory.actions,
      ]);
      expect(
        find.byKey(const ValueKey('welcome-new-nextcloud-note')),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'pending Welcome Notes operation is cancelled when leaving connection settings',
    (tester) async {
      final container = await pumpWelcome(tester);
      final pending = container.read(welcomeNotesActionProvider.notifier);
      final before = repository.notes.length;
      pending.request(WelcomeNotesAction.create);
      container
          .read(appRouterProvider)
          .go(
            '${settingsLocation(SettingsReturnTarget.welcome)}&page=nextcloudNotes',
          );
      await settleStorage(tester);
      expect(
        container.read(welcomeNotesActionProvider),
        WelcomeNotesAction.create,
      );
      container.read(appRouterProvider).go('/workspace');
      await settleStorage(tester);
      expect(container.read(welcomeNotesActionProvider), isNull);
      expect(repository.notes.length, before);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test('Nextcloud settings route selects its dedicated page', () {
    expect(
      settingsPageFromRouteValue('nextcloudNotes'),
      SettingsPage.nextcloudNotes,
    );
  });

  testWidgets(
    'correction: Recovery Search finds deleted records rather than live notes',
    (tester) async {
      await pump(tester);
      await tester.tap(find.text('Recovery').first);
      await settleStorage(tester);
      expect(find.text('Deleted note'), findsOneWidget);
      ProviderScope.containerOf(
            tester.element(find.byType(_NotesSearchHarness)),
          )
          .read(searchSessionProvider.notifier)
          .open(category: SearchCategory.workspace);
      await settleStorage(tester);
      final field = find.descendant(
        of: find.byKey(const ValueKey('shared-search-query')),
        matching: find.byType(TextField),
      );
      await tester.enterText(field, 'title:Deleted');
      await tester.pump(const Duration(milliseconds: 200));
      await settleStorage(tester);
      expect(
        find.descendant(
          of: find.byType(SearchSidebar),
          matching: find.text('Deleted note'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(SearchSidebar),
          matching: find.text('Personal note'),
        ),
        findsNothing,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleStorage(tester);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'correction: Show more reaches all 320 indexed occurrences through the shared sidebar',
    (tester) async {
      final expected = <Key>{};
      await tester.runAsync(() async {
        for (var n = 0; n < 10; n++) {
          final note = await repository.create(
            accountId,
            title: 'Page $n',
            content: List.filled(32, 'pagingneedle').join(' '),
          );
          expected.addAll([
            for (var i = 0; i < 32; i++)
              ValueKey<(String, String, int?, int?)>((
                'notes-search-hit',
                note.localId,
                i * 13,
                i * 13 + 12,
              )),
          ]);
        }
      });
      await pump(tester);
      ProviderScope.containerOf(
            tester.element(find.byType(_NotesSearchHarness)),
          )
          .read(searchSessionProvider.notifier)
          .open(category: SearchCategory.workspace);
      await settleStorage(tester);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('shared-search-query')),
          matching: find.byType(TextField),
        ),
        'pagingneedle',
      );
      await tester.pump(const Duration(milliseconds: 200));
      await settleStorage(tester);
      for (final count in [80, 160, 240, 320]) {
        final list = tester.widget<ListView>(
          find.byKey(const ValueKey('sidebar-search-results')),
        );
        final delegate = list.childrenDelegate as SliverChildBuilderDelegate;
        expect(delegate.estimatedChildCount, count);
        final context = tester.element(
          find.byKey(const ValueKey('sidebar-search-results')),
        );
        final keys = {
          for (var i = 0; i < count; i++) delegate.builder(context, i)!.key!,
        };
        expect(keys.length, count);
        expect(expected.containsAll(keys), true);
        if (count < 320) {
          expect(find.text('Show more results'), findsOneWidget);
          await tester.tap(find.text('Show more results'));
          await settleStorage(tester);
        } else {
          expect(keys, expected);
          expect(find.text('Show more results'), findsNothing);
        }
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleStorage(tester);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'correction: Recovery search activation opens preview and keeps the current document',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          nextcloudNotesRepositoryProvider.overrideWith(
            (ref) async => repository,
          ),
          localSettingsStoreProvider.overrideWithValue(_TabSettings()),
          linuxAccentPlatformProvider.overrideWithValue(false),
          localHistoryStoreProvider.overrideWithValue(
            MemoryLocalHistoryStore(),
          ),
          documentSessionStoreProvider.overrideWithValue(
            MemoryDocumentSessionStore(),
          ),
          documentRecoveryStoreProvider.overrideWithValue(
            MemoryDocumentRecoveryStore(),
          ),
        ],
      );
      addTearDown(container.dispose);
      const personalId = '223e4567-e89b-42d3-a456-426614174000';
      const deletedId = '423e4567-e89b-42d3-a456-426614174000';
      final controller = container.read(workspaceControllerProvider.notifier);
      await tester.runAsync(() async {
        await controller.openNextcloudWorkspace(accountId);
        await controller.openNextcloudNote(personalId);
      });
      container.read(appRouterProvider).go('/workspace');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SizedBox(
                width: 300,
                height: 1000,
                child: _NotesSearchHarness(accountId: accountId),
              ),
            ),
          ),
        ),
      );
      await settleStorage(tester);
      await tester.tap(find.text('Recovery').first);
      await settleStorage(tester);
      ProviderScope.containerOf(
            tester.element(find.byType(_NotesSearchHarness)),
          )
          .read(searchSessionProvider.notifier)
          .open(category: SearchCategory.workspace);
      await settleStorage(tester);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('shared-search-query')),
          matching: find.byType(TextField),
        ),
        'title:Deleted',
      );
      await tester.pump(const Duration(milliseconds: 200));
      await settleStorage(tester);
      expect(find.byTooltip('Source location'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settleStorage(tester);
      expect(find.byType(SearchSidebar), findsNothing);
      expect(find.byType(NotesRecoveryDialog), findsOneWidget);
      expect(
        tester
            .widget<NotesRecoveryDialog>(find.byType(NotesRecoveryDialog))
            .note
            .localId,
        deletedId,
      );
      expect(
        container
            .read(workspaceControllerProvider)
            .activeBuffer
            ?.remoteNote
            ?.localId,
        personalId,
      );
      expect(
        container
            .read(workspaceControllerProvider)
            .documentBuffers
            .any((b) => b.remoteNote?.localId == deletedId),
        false,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleStorage(tester);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('remote editor tabs retain note titles through metadata rename', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final channelName in ['yaru_window', 'yaru_window/events']) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            MethodChannel(channelName),
            (call) async => call.method == 'state' ? <String, Object?>{} : null,
          );
    }
    final container = ProviderContainer(
      overrides: [
        nextcloudNotesRepositoryProvider.overrideWith(
          (ref) async => repository,
        ),
        localSettingsStoreProvider.overrideWithValue(_TabSettings()),
        linuxAccentPlatformProvider.overrideWithValue(false),
        localHistoryStoreProvider.overrideWithValue(MemoryLocalHistoryStore()),
        documentSessionStoreProvider.overrideWithValue(
          MemoryDocumentSessionStore(),
        ),
        documentRecoveryStoreProvider.overrideWithValue(
          MemoryDocumentRecoveryStore(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(workspaceControllerProvider.notifier);
    const personalId = '223e4567-e89b-42d3-a456-426614174000';
    const sharedId = '323e4567-e89b-42d3-a456-426614174000';
    await tester.runAsync(() async {
      expect(await controller.openNextcloudWorkspace(accountId), isTrue);
      expect(await controller.openNextcloudNote(personalId), isTrue);
      expect(await controller.openNextcloudNote(sharedId), isTrue);
    });
    container.read(appRouterProvider).go('/workspace');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    await settleStorage(tester);
    final strip = find.byKey(const ValueKey('editor-tab-strip'));
    Finder tab(String title) =>
        find.descendant(of: strip, matching: find.text(title));
    expect(tab('Personal note'), findsOneWidget);
    expect(tab('Shared note'), findsOneWidget);
    final before = container
        .read(workspaceControllerProvider)
        .documentBuffers
        .firstWhere((buffer) => buffer.remoteNote?.localId == personalId);
    await tester.runAsync(
      () => controller.updateNextcloudNoteMetadata(
        personalId,
        title: 'Renamed personal note',
      ),
    );
    await settleStorage(tester);
    expect(tab('Personal note'), findsNothing);
    expect(tab('Renamed personal note'), findsOneWidget);
    expect(tab('Shared note'), findsOneWidget);
    final after = container
        .read(workspaceControllerProvider)
        .documentBuffers
        .firstWhere((buffer) => buffer.remoteNote?.localId == personalId);
    expect(after.identity, before.identity);
    expect(after.filePath, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final action in ['middle', 'other', 'all']) {
    testWidgets(
      'remote tab $action closing keeps notes and disables Copy path',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            nextcloudNotesRepositoryProvider.overrideWith(
              (ref) async => repository,
            ),
            localSettingsStoreProvider.overrideWithValue(_TabSettings()),
            linuxAccentPlatformProvider.overrideWithValue(false),
            localHistoryStoreProvider.overrideWithValue(
              MemoryLocalHistoryStore(),
            ),
            documentSessionStoreProvider.overrideWithValue(
              MemoryDocumentSessionStore(),
            ),
            documentRecoveryStoreProvider.overrideWithValue(
              MemoryDocumentRecoveryStore(),
            ),
          ],
        );
        addTearDown(container.dispose);
        final controller = container.read(workspaceControllerProvider.notifier);
        const personalId = '223e4567-e89b-42d3-a456-426614174000';
        const sharedId = '323e4567-e89b-42d3-a456-426614174000';
        await tester.runAsync(() async {
          await controller.openNextcloudWorkspace(accountId);
          await controller.openNextcloudNote(personalId);
          await controller.openNextcloudNote(sharedId);
        });
        container.read(appRouterProvider).go('/workspace');
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const BusyMarkApp(),
          ),
        );
        await settleStorage(tester);
        final target = container
            .read(workspaceControllerProvider)
            .documentBuffers
            .singleWhere((buffer) => buffer.remoteNote?.localId == personalId);
        final activeId = container
            .read(workspaceControllerProvider)
            .activeBufferId;
        Finder label() => find
            .descendant(
              of: find.byKey(ValueKey('file:${target.id}')),
              matching: find.byType(Text),
            )
            .first;
        Map? menu;
        var choice = 4; // Disabled Copy path must not dispatch or write.
        var clipboardWrites = 0;
        const channel = MethodChannel('busymark/native_menus');
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (call) async {
            if (call.method == 'show') {
              menu = call.arguments as Map;
              return choice;
            }
            return true;
          },
        );
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') clipboardWrites++;
            return null;
          },
        );
        addTearDown(() {
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            null,
          );
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          );
        });
        await tester.tap(label(), buttons: kSecondaryButton);
        await settleStorage(tester);
        final entries = menu!['entries'] as List;
        expect((entries[4] as Map)['enabled'], isFalse);
        expect(clipboardWrites, 0);
        expect(
          container.read(workspaceControllerProvider).activeBufferId,
          activeId,
        );
        if (action == 'middle') {
          await tester.tap(label(), buttons: kTertiaryButton);
        } else {
          choice = action == 'other' ? 1 : 2;
          await tester.tap(label(), buttons: kSecondaryButton);
        }
        for (var i = 0; i < 100; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await tester.pump(const Duration(milliseconds: 10));
          if (container
                  .read(workspaceControllerProvider)
                  .documentBuffers
                  .length ==
              (action == 'all' ? 0 : 1)) {
            break;
          }
        }
        await settleStorage(tester);
        final state = container.read(workspaceControllerProvider);
        expect(state.documentBuffers, hasLength(action == 'all' ? 0 : 1));
        if (action == 'other') expect(state.activeBufferId, target.id);
        if (action == 'middle') {
          expect(state.documentBuffers.single.remoteNote?.localId, sharedId);
        }
        expect(state.workspace!.kind, WorkspaceKind.nextcloudNotes);
        expect((repository as _CachedNotesRepository).deleteCalls, 0);
        expect(repository.noteById(personalId)?.content, 'private search text');
        expect(repository.noteById(sharedId)?.content, 'shared material');
        expect(clipboardWrites, 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'cached note list searches content and excludes clean deletion tombstones',
    (tester) async {
      await pump(tester);
      expect(find.text('Personal note'), findsOneWidget);
      expect(find.text('Shared note'), findsOneWidget);
      expect(find.text('Deleted note'), findsNothing);
      ProviderScope.containerOf(
            tester.element(find.byType(_NotesSearchHarness)),
          )
          .read(searchSessionProvider.notifier)
          .open(category: SearchCategory.workspace);
      await settleStorage(tester);
      final dialog = find.byType(SearchSidebar);
      final field = find.descendant(
        of: find.byKey(const ValueKey('shared-search-query')),
        matching: find.byType(TextField),
      );
      await tester.enterText(field, 'private search');
      await tester.pump(const Duration(milliseconds: 200));
      for (var i = 0; i < 30; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      expect(
        find.descendant(
          of: dialog,
          matching: find.textContaining('Personal note'),
        ),
        findsNWidgets(2),
      );
      expect(
        find.descendant(
          of: dialog,
          matching: find.textContaining('Shared note'),
        ),
        findsNothing,
      );
      final results = ProviderScope.containerOf(
        tester.element(dialog),
      ).read(searchSessionProvider).results.cast<NoteSearchResult>();
      expect(results, hasLength(2));
      expect(
        results.every(
          (r) =>
              r.accountId == accountId &&
              r.hit.localId == '223e4567-e89b-42d3-a456-426614174000',
        ),
        isTrue,
      );
      expect(results.map((r) => (r.hit.start, r.hit.end)), [(0, 7), (8, 14)]);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'pointer and keyboard multiselection preserves reviewed context targets after resorting',
    (tester) async {
      late NextcloudNote alpha, beta, gamma;
      await tester.runAsync(() async {
        final account = repository.accountById(accountId)!;
        await repository.removeAccount(accountId);
        await repository.upsertAccount(account);
        alpha = await repository.create(accountId, title: 'Alpha');
        beta = await repository.create(accountId, title: 'Beta');
        gamma = await repository.create(accountId, title: 'Gamma');
      });
      await pump(tester);
      final sort = tester.widget<BusyMarkPopupSelector<NotesSort>>(
        find.byType(BusyMarkPopupSelector<NotesSort>),
      );
      sort.onSelected(NotesSort.titleAscending);
      await tester.pumpAndSettle();
      Finder row(NextcloudNote note) =>
          find.byKey(ValueKey('nextcloud-note-${note.localId}'));
      bool selected(NextcloudNote note) =>
          tester.widget<BusyMarkSidebarRecordRow>(row(note)).selected;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(row(alpha));
      await tester.tap(row(gamma));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(selected(alpha), true);
      expect(selected(beta), false);
      expect(selected(gamma), true);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.tap(row(beta));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(selected(alpha), false);
      expect(selected(beta), true);
      expect(selected(gamma), true);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect([alpha, beta, gamma].every(selected), true);
      sort.onSelected(NotesSort.titleDescending);
      await tester.pumpAndSettle();
      expect([alpha, beta, gamma].every(selected), true);
      await tester.tap(row(beta), buttons: kSecondaryButton);
      await settleStorage(tester);
      expect(find.byTooltip('Selected notes (3)'), findsOneWidget);
      // The menu has captured the reviewed identities and metadata. A durable
      // update can reorder the list while the menu is open without retargeting.
      await tester.runAsync(
        () => repository.patchMetadata(
          repository.metadataSnapshot(beta.localId),
          title: 'Zeta',
        ),
      );
      await settleStorage(tester);
      await tester.tap(find.text('Move to category'));
      await settleStorage(tester);
      final review = find.byType(BusyMarkDialogShell);
      expect(review, findsOneWidget);
      for (final title in ['Alpha', 'Beta', 'Gamma']) {
        expect(
          find.descendant(of: review, matching: find.text(title)),
          findsOneWidget,
        );
      }
      expect(
        find.descendant(of: review, matching: find.text('Zeta')),
        findsNothing,
      );
      await tester.tap(
        find.descendant(of: review, matching: find.text('Cancel')),
      );
      await settleStorage(tester);
      expect(repository.noteById(beta.localId)!.title, 'Zeta');
      await tester.tap(find.text('Favorites').first);
      await settleStorage(tester);
      expect(find.text('Selected notes (3)'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'properties retain metadata across secondary actions and failed durable saves',
    (tester) async {
      await pump(tester);
      final row = tester.widget<BusyMarkSidebarRecordRow<String>>(
        find.byKey(
          const ValueKey('nextcloud-note-223e4567-e89b-42d3-a456-426614174000'),
        ),
      );
      row.onMenuOpening!();
      row.onMenuSelected!('properties');
      await settleStorage(tester);
      final title = find.descendant(
        of: find.byType(BusyMarkGroupedTextEntry).first,
        matching: find.byType(TextField),
      );
      await tester.enterText(title, 'Preserved metadata draft');
      const channel = MethodChannel('plugins.flutter.io/file_selector');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      for (final label in ['Add attachment…', 'Save local copy…']) {
        await tester.runAsync(
          () => tester.tap(find.widgetWithText(BusyMarkActionRow, label)),
        );
        await settleStorage(tester);
        expect(
          tester.widget<TextField>(title).controller!.text,
          'Preserved metadata draft',
        );
        expect(find.text('Note Properties'), findsOneWidget);
      }
      (repository as _CachedNotesRepository).failMetadata = true;
      await tester.runAsync(
        () => tester.tap(find.widgetWithText(BusyMarkDialogButton, 'Save')),
      );
      await settleStorage(tester);
      expect(find.textContaining('Your draft is retained'), findsOneWidget);
      expect(
        tester.widget<TextField>(title).controller!.text,
        'Preserved metadata draft',
      );
      expect(
        repository.noteById('223e4567-e89b-42d3-a456-426614174000')!.title,
        'Personal note',
      );
      (repository as _CachedNotesRepository).failMetadata = false;
      await tester.runAsync(
        () => tester.tap(find.widgetWithText(BusyMarkDialogButton, 'Save')),
      );
      await settleStorage(tester);
      expect(find.text('Note Properties'), findsNothing);
      expect(
        repository.noteById('223e4567-e89b-42d3-a456-426614174000')!.title,
        'Preserved metadata draft',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'unsupported remote attachment deletion is disabled with an explanation',
    (tester) async {
      await tester.runAsync(
        () => repository.upsertAccount(
          repository.accountById(accountId)!.copyWith(appVersion: '6.0.1'),
        ),
      );
      await pump(tester);
      final row = tester.widget<BusyMarkSidebarRecordRow<String>>(
        find.byKey(
          const ValueKey('nextcloud-note-223e4567-e89b-42d3-a456-426614174000'),
        ),
      );
      row.onMenuOpening!();
      row.onMenuSelected!('properties');
      await settleStorage(tester);
      final attachment = find.widgetWithText(BusyMarkActionRow, 'report.pdf');
      expect(
        find.text('This server does not support deleting remote attachments.'),
        findsOneWidget,
      );
      final button = tester.widget<BusyMarkCompactIconButton>(
        find.descendant(
          of: attachment,
          matching: find.byType(BusyMarkCompactIconButton),
        ),
      );
      expect(button.onPressed, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'favorites and ancestor category filtering operate on cached notes',
    (tester) async {
      await pump(tester);
      await tester.tap(find.text('Favorites').first);
      await settleStorage(tester);
      expect(find.text('Shared note'), findsNothing);
      expect(find.text('Personal note'), findsOneWidget);
      await tester.tap(find.text('All notes').first);
      await settleStorage(tester);
      await tester.ensureVisible(find.text('Projects').last);
      await settleStorage(tester);
      await tester.tap(find.text('Projects').last);
      await settleStorage(tester);
      expect(find.text('Shared note'), findsOneWidget);
      expect(find.text('Personal note'), findsNothing);
    },
  );

  testWidgets('moving the last selected category note clears its filter', (
    tester,
  ) async {
    await pump(tester);
    await tester.ensureVisible(find.text('Personal').last);
    await tester.tap(find.text('Personal').last);
    await settleStorage(tester);
    expect(find.text('Shared note'), findsNothing);
    await tester.runAsync(
      () => repository.save(
        '223e4567-e89b-42d3-a456-426614174000',
        content: 'private search text',
        category: '',
      ),
    );
    await settleStorage(tester);
    expect(find.text('Personal note'), findsOneWidget);
    expect(find.text('Shared note'), findsOneWidget);
    expect(
      tester
          .widget<BusyMarkSidebarTreeRow>(
            find.ancestor(
              of: find.text('All notes'),
              matching: find.byType(BusyMarkSidebarTreeRow),
            ),
          )
          .selected,
      isTrue,
    );
  });

  testWidgets(
    'the final category can disappear without hiding uncategorized notes',
    (tester) async {
      late NextcloudNote categorized;
      await tester.runAsync(() async {
        final account = repository.accountById(accountId)!;
        await repository.removeAccount(accountId);
        await repository.upsertAccount(account);
        categorized = await repository.create(
          accountId,
          title: 'Move me',
          category: 'Last',
        );
        await repository.create(accountId, title: 'Uncategorized draft');
      });
      await pump(tester);
      await tester.ensureVisible(find.text('Last').last);
      await tester.tap(find.text('Last').last);
      await settleStorage(tester);
      expect(find.text('Uncategorized draft'), findsNothing);
      await tester.runAsync(
        () => repository.save(categorized.localId, content: '', category: ''),
      );
      await settleStorage(tester);
      expect(find.text('Last'), findsNothing);
      expect(find.text('Move me'), findsOneWidget);
      expect(find.text('Uncategorized draft'), findsOneWidget);
    },
  );

  testWidgets(
    'uncertain attachment controls remain available with fetched remote state',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            nextcloudNotesRepositoryProvider.overrideWith(
              (ref) async => repository,
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: NextcloudNoteStatus(
                localId: '723e4567-e89b-42d3-a456-426614174000',
                unsaved: false,
              ),
            ),
          ),
        ),
      );
      await settleStorage(tester);
      await tester.tap(find.text('Compare'));
      await settleStorage(tester);
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await settleStorage(tester);
      expect(find.text('uncertain.pdf'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Attachment reference on server'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await settleStorage(tester);
    },
  );

  testWidgets(
    'read-only metadata stays read-only while favorite is writable and export is explicit',
    (tester) async {
      await pump(tester);
      await tester.tap(
        find.descendant(
          of: find.byKey(
            const ValueKey(
              'nextcloud-note-323e4567-e89b-42d3-a456-426614174000',
            ),
          ),
          matching: find.byTooltip('Note actions'),
        ),
      );
      await settleStorage(tester);
      await tester.tap(find.text('Note Properties'));
      await settleStorage(tester);
      final fields = tester
          .widgetList<TextField>(
            find.descendant(
              of: find.byType(Dialog),
              matching: find.byType(TextField),
            ),
          )
          .toList();
      expect(fields.where((field) => field.readOnly), hasLength(2));
      expect(find.text('Save local copy…'), findsOneWidget);
      expect(find.text('Copy Path'), findsNothing);
      expect(find.text('Open in Files'), findsNothing);
      final favorite = find.byType(BusyMarkSwitchRow).last;
      expect(tester.widget<BusyMarkSwitchRow>(favorite).enabled, isTrue);
    },
  );

  testWidgets(
    'attachment deletion warns about links and cancellation retains the file',
    (tester) async {
      await pump(tester);
      await tester.tap(
        find.descendant(
          of: find.byKey(
            const ValueKey(
              'nextcloud-note-223e4567-e89b-42d3-a456-426614174000',
            ),
          ),
          matching: find.byTooltip('Note actions'),
        ),
      );
      await settleStorage(tester);
      await tester.tap(find.text('Note Properties'));
      await settleStorage(tester);
      for (
        var attempt = 0;
        attempt < 20 && find.text('report.pdf').evaluate().isEmpty;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)),
        );
        await settleStorage(tester);
      }
      expect(find.text('Add attachment…'), findsOneWidget);
      expect(find.text('report.pdf'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Delete'));
      await settleStorage(tester);
      await tester.tap(find.byTooltip('Delete'));
      await settleStorage(tester);
      expect(
        find.text(
          'Deleting this attachment makes its links in the note unavailable. Retained bytes can be recovered through local history.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel').last);
      await settleStorage(tester);
      expect(find.text('report.pdf'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'remote deletion offers explicit discard with a second confirmation',
    (tester) async {
      const note = NextcloudNote(
        localId: '523e4567-e89b-42d3-a456-426614174000',
        accountId: accountId,
        serverId: 5,
        title: 'Recoverable edit',
        content: 'durable local work',
        revision: 2,
        ackRevision: 1,
        syncState: NoteSyncState.deletedRemotely,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            nextcloudNotesRepositoryProvider.overrideWith(
              (ref) async => repository,
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Consumer(
              builder: (context, ref, child) => Scaffold(
                body: TextButton(
                  onPressed: () => showNextcloudConflict(context, ref, note),
                  child: const Text('Resolve'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Resolve'));
      await settleStorage(tester);
      expect(find.text('New note'), findsOneWidget);
      await tester.tap(find.text('Discard'));
      await settleStorage(tester);
      expect(find.text('Discard'), findsNWidgets(3));
      expect(find.text('Recoverable edit'), findsOneWidget);
      await tester.tap(find.text('Cancel').last);
      await settleStorage(tester);
      expect(find.text('Resolve'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await settleStorage(tester);
      expect(find.text('Discard'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('merge requires explicit choices for divergent scalar metadata', (
    tester,
  ) async {
    const id = '723e4567-e89b-42d3-a456-426614174000';
    await tester.runAsync(
      () => repository.save(
        id,
        content: repository.noteById(id)!.content,
        title: 'Local title',
        category: 'Local category',
        favorite: true,
      ),
    );
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nextcloudNotesRepositoryProvider.overrideWith(
            (ref) async => repository,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: NextcloudNoteStatus(localId: id, unsaved: false),
          ),
        ),
      ),
    );
    await settleStorage(tester);
    await tester.tap(find.text('Compare'));
    await settleStorage(tester);
    final button = find.byWidgetPredicate(
      (w) => w is BusyMarkDialogButton && w.label == 'Merge',
    );
    expect(tester.widget<BusyMarkDialogButton>(button).onPressed, isNull);
    final dropdowns = find.byType(BusyMarkComboRow<NotesMergeChoice?>);
    expect(dropdowns, findsNWidgets(3));
    for (var i = 0; i < 3; i++) {
      final dropdown = tester.widget<BusyMarkComboRow<NotesMergeChoice?>>(
        dropdowns.at(i),
      );
      // Exercise the actual dialog state callback and verify Apply enablement.
      dropdown.onSelected(NotesMergeChoice.remote);
      await settleStorage(tester);
    }
    expect(tester.widget<BusyMarkDialogButton>(button).onPressed, isNotNull);
    await tester.tap(find.text('Cancel'));
    await settleStorage(tester);
    expect(repository.noteById(id)!.title, 'Local title');
    expect(tester.takeException(), isNull);
  });

  for (final draft in [false, true]) {
    for (final choice in [
      'Use previous edit',
      'Keep Mine',
      'Merge',
      'New note',
    ]) {
      testWidgets(
        'local metadata review applies the displayed choice: draft=$draft $choice',
        (tester) async {
          for (final channelName in ['yaru_window', 'yaru_window/events']) {
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
                .setMockMethodCallHandler(
                  MethodChannel(channelName),
                  (call) async =>
                      call.method == 'state' ? <String, Object?>{} : null,
                );
            addTearDown(
              () => TestDefaultBinaryMessengerBinding
                  .instance
                  .defaultBinaryMessenger
                  .setMockMethodCallHandler(MethodChannel(channelName), null),
            );
          }
          final id = draft
              ? '223e4567-e89b-42d3-a456-426614174000'
              : 'metadata-server';
          await tester.runAsync(() async {
            final snapshot = repository.metadataSnapshot(id);
            await repository.patchMetadata(snapshot, title: 'B');
            await repository.patchMetadata(snapshot, title: 'C');
          });
          tester.view.physicalSize = const Size(1200, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                nextcloudNotesRepositoryProvider.overrideWith(
                  (ref) async => repository,
                ),
                localSettingsStoreProvider.overrideWithValue(_TabSettings()),
                linuxAccentPlatformProvider.overrideWithValue(false),
                localHistoryStoreProvider.overrideWithValue(
                  MemoryLocalHistoryStore(),
                ),
                documentSessionStoreProvider.overrideWithValue(
                  MemoryDocumentSessionStore(),
                ),
                documentRecoveryStoreProvider.overrideWithValue(
                  MemoryDocumentRecoveryStore(),
                ),
              ],
              child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: NextcloudNoteStatus(localId: id, unsaved: false),
                ),
              ),
            ),
          );
          await settleStorage(tester);
          await tester.runAsync(() => tester.tap(find.text('Compare')));
          for (
            var i = 0;
            i < 100 && find.text('Use previous edit').evaluate().isEmpty;
            i++
          ) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 10)),
            );
            await tester.pump(const Duration(milliseconds: 50));
          }
          await settleStorage(tester);
          expect(find.text('Use previous edit'), findsOneWidget);
          expect(find.text('Take Remote'), findsNothing);
          await tester.tap(find.byType(BusyMarkComboRow<NotesMergeChoice?>));
          await settleStorage(tester);
          expect(find.text('Previous local edit: B'), findsOneWidget);
          expect(find.text('Keep Mine: C'), findsOneWidget);
          await tester.tap(find.text('Previous local edit: B'));
          await settleStorage(tester);
          await tester.runAsync(() async {
            await tester.tap(
              find.byWidgetPredicate(
                (w) => w is BusyMarkDialogButton && w.label == choice,
              ),
            );
          });
          final completion = Stopwatch()..start();
          bool finished() => choice == 'New note'
              ? repository.notes.any((n) => n.localId != id && n.title == 'C')
              : repository.noteById(id)!.metadataConflict == null;
          while (!finished() &&
              completion.elapsed < const Duration(seconds: 30)) {
            await tester.pump(const Duration(milliseconds: 50));
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 10)),
            );
          }
          await settleStorage(tester);
          expect(finished(), isTrue);
          final selected = choice == 'New note'
              ? repository.notes.singleWhere(
                  (n) => n.localId != id && n.title == 'C',
                )
              : repository.noteById(id)!;
          expect(
            selected.title,
            choice == 'Keep Mine' || choice == 'New note' ? 'C' : 'B',
          );
          expect(tester.takeException(), isNull);
          final container = ProviderScope.containerOf(
            tester.element(find.byType(NextcloudNoteStatus)),
          );
          await tester.runAsync(() async {
            container.dispose();
          });
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.runAsync(() => repository.dispose());
        },
      );
    }
  }

  for (final state in [NoteSyncState.pending, NoteSyncState.synced]) {
    testWidgets('persisted metadata review shows conflict rather than $state', (
      tester,
    ) async {
      const id = 'metadata-server';
      await tester.runAsync(() async {
        final snapshot = repository.metadataSnapshot(id);
        await repository.patchMetadata(snapshot, title: 'B');
        await repository.patchMetadata(snapshot, title: 'C');
        final note = repository.noteById(id)!;
        await repository.store.saveNote(note.copyWith(syncState: state));
        await repository.dispose();
        repository = _CachedNotesRepository(
          store: await NotesStore.open(
            path: p.join(root.path, 'notes.sqlite3'),
          ),
        );
        await repository.initialize();
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            nextcloudNotesRepositoryProvider.overrideWith(
              (ref) async => repository,
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: NextcloudNoteStatus(localId: id, unsaved: false),
            ),
          ),
        ),
      );
      await settleStorage(tester);
      expect(find.text('Conflicts'), findsOneWidget);
      expect(find.text('Compare'), findsOneWidget);
      expect(find.text('Synced'), findsNothing);
      expect(find.text('Saved locally'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('read-only favorite conflict offers a safe merge', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nextcloudNotesRepositoryProvider.overrideWith(
            (ref) async => repository,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: NextcloudNoteStatus(
              localId: 'readonly-favorite-conflict',
              unsaved: false,
            ),
          ),
        ),
      ),
    );
    await settleStorage(tester);
    await tester.tap(find.text('Compare'));
    await settleStorage(tester);
    final merge = find.byWidgetPredicate(
      (widget) => widget is BusyMarkDialogButton && widget.label == 'Merge',
    );
    expect(merge, findsOneWidget);
    expect(tester.widget<BusyMarkDialogButton>(merge).onPressed, isNotNull);
    expect(find.text('Keep Mine'), findsNothing);
    await tester.tap(find.text('Cancel'));
    await settleStorage(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uncertain creation lets the user select a candidate', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nextcloudNotesRepositoryProvider.overrideWith(
            (ref) async => repository,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: NextcloudNoteStatus(
              localId: 'uncertain-create',
              unsaved: false,
            ),
          ),
        ),
      ),
    );
    await settleStorage(tester);
    await tester.tap(find.text('Compare'));
    await settleStorage(tester);
    final takeRemote = find.byWidgetPredicate(
      (widget) =>
          widget is BusyMarkDialogButton &&
          widget.label == 'Use this server note',
    );
    expect(takeRemote, findsNothing);
    final candidates = find.byType(BusyMarkComboRow<int?>);
    expect(candidates, findsOneWidget);
    tester.widget<BusyMarkComboRow<int?>>(candidates).onSelected(10);
    await settleStorage(tester);
    expect(takeRemote, findsOneWidget);
    expect(find.textContaining('Sanitized A'), findsWidgets);
    await tester.tap(find.text('Cancel'));
    await settleStorage(tester);
    expect(repository.noteById('uncertain-create')!.serverId, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'selecting and confirming candidate binds draft and retains newer edits',
    (tester) async {
      for (final channelName in ['yaru_window', 'yaru_window/events']) {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              MethodChannel(channelName),
              (call) async =>
                  call.method == 'state' ? <String, Object?>{} : null,
            );
      }
      await tester.runAsync(
        () => repository.save(
          'uncertain-create',
          content: 'newer editor content',
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            nextcloudNotesRepositoryProvider.overrideWith(
              (ref) async => repository,
            ),
            localSettingsStoreProvider.overrideWithValue(_TabSettings()),
            localHistoryStoreProvider.overrideWithValue(
              MemoryLocalHistoryStore(),
            ),
            documentSessionStoreProvider.overrideWithValue(
              MemoryDocumentSessionStore(),
            ),
            documentRecoveryStoreProvider.overrideWithValue(
              MemoryDocumentRecoveryStore(),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: NextcloudNoteStatus(
                localId: 'uncertain-create',
                unsaved: false,
              ),
            ),
          ),
        ),
      );
      await settleStorage(tester);
      await tester.runAsync(() => tester.tap(find.text('Compare')));
      for (
        var i = 0;
        i < 100 && find.byType(BusyMarkComboRow<int?>).evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.tap(find.byType(BusyMarkComboRow<int?>));
      await settleStorage(tester);
      await tester.tap(find.text('Sanitized A (#10)').last);
      await settleStorage(tester);
      expect(find.textContaining('identity is unconfirmed'), findsOneWidget);
      expect(find.textContaining('#10'), findsWidgets);
      await tester.runAsync(
        () => tester.tap(find.text('Use this server note')),
      );
      final confirmationDeadline = Stopwatch()..start();
      while (repository.noteById('uncertain-create')!.serverId == null &&
          confirmationDeadline.elapsed < const Duration(seconds: 30)) {
        // Modal dismissal needs widget frames; SQLite needs real async time.
        await tester.pump(const Duration(milliseconds: 50));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
      }
      await tester.pump(const Duration(milliseconds: 250));
      final uiContainer = ProviderScope.containerOf(
        tester.element(find.byType(NextcloudNoteStatus)),
      );
      expect(
        repository.noteById('uncertain-create')!.serverId,
        10,
        reason:
            '${uiContainer.read(workspaceControllerProvider).message?.error}',
      );
      expect(
        repository.noteById('uncertain-create')!.content,
        'newer editor content',
      );
      expect(
        repository.noteById('uncertain-create')!.hasPendingChanges,
        isTrue,
      );
      expect(repository.noteById('creation-candidate-10'), isNull);
      expect(repository.noteById('creation-candidate-11'), isNotNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final state in [NoteSyncState.forbidden, NoteSyncState.unavailable]) {
    testWidgets(
      '${state.name} pending changes offer recovery without overwrite',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              nextcloudNotesRepositoryProvider.overrideWith(
                (ref) async => repository,
              ),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: NextcloudNoteStatus(
                  localId: 'blocked-${state.name}',
                  unsaved: false,
                ),
              ),
            ),
          ),
        );
        await settleStorage(tester);
        await tester.tap(find.text('Compare'));
        await settleStorage(tester);
        expect(find.text('New note'), findsOneWidget);
        expect(find.text('Merge'), findsNothing);
        expect(find.text('Keep Mine'), findsNothing);
        await tester.tap(find.text('Cancel'));
        await settleStorage(tester);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _ConnectingWelcomeAccount extends NextcloudConnectionController {
  _ConnectingWelcomeAccount(this.account);
  final NextcloudAccount account;
  bool connected = false;
  @override
  NextcloudConnectionState build() => const NextcloudConnectionState();
  @override
  Future<void> reload() async => state = NextcloudConnectionState(
    account: connected ? account : null,
    phase: connected
        ? NextcloudConnectionPhase.connected
        : NextcloudConnectionPhase.idle,
  );
  @override
  Future<bool> connect(String serverUrl) async {
    connected = true;
    await reload();
    return true;
  }
}

class _TabSettings implements LocalSettingsStore {
  @override
  Future<Map<String, Object?>> load() async => {'automaticSpelling': false};
  @override
  Future<void> save(Map<String, Object?> values) async {}
}

class _CachedNotesRepository extends NotesRepository {
  _CachedNotesRepository({required super.store})
    : super(
        clientForAccount: (account) async => NotesApiClient(
          client: MockClient((request) async {
            if (request.url.path.endsWith('/settings')) {
              return http.Response(
                jsonEncode({'notesPath': 'Notes', 'fileSuffix': '.md'}),
                200,
              );
            }
            final id = int.parse(request.url.pathSegments.last);
            final candidate = (await store.notes()).firstWhere(
              (n) => n.serverId == id,
            );
            return http.Response(jsonEncode(candidate.base!.toJson()), 200);
          }),
          account: account,
          appPassword: 'fixture',
        ),
      );

  bool failMetadata = false;
  @override
  Future<NextcloudNote> patchMetadata(
    NotesMetadataSnapshot snapshot, {
    String? title,
    String? category,
    bool? favorite,
  }) {
    if (failMetadata) {
      throw const FileSystemException('fixture storage failure');
    }
    return super.patchMetadata(
      snapshot,
      title: title,
      category: category,
      favorite: favorite,
    );
  }

  int deleteCalls = 0;
  @override
  Future<void> delete(String localId) {
    deleteCalls++;
    return super.delete(localId);
  }

  @override
  Future<void> synchronize(
    String accountId, {
    bool allowWrites = true,
    bool refreshCapabilities = false,
    bool onlyFreshWrites = false,
  }) async {}
}

class _NotesSearchHarness extends ConsumerWidget {
  const _NotesSearchHarness({required this.accountId});
  final String accountId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(searchSessionProvider);
    return Column(
      children: [
        if (search.active) const SearchHeaderField(),
        Expanded(
          child: IndexedStack(
            index: search.active ? 1 : 0,
            children: [
              NextcloudNotesSidebar(accountId: accountId),
              const SearchSidebar(),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentReopenSettings implements LocalSettingsStore {
  _RecentReopenSettings({required this.failSave, required this.value});
  final bool failSave;
  Map<String, Object?> value;
  @override
  Future<Map<String, Object?>> load() async => value;
  @override
  Future<void> save(Map<String, Object?> next) async {
    if (failSave) throw StateError('injected Recent persistence failure');
    value = next;
  }
}

class _RemovedConnection extends NextcloudConnectionController {
  @override
  NextcloudConnectionState build() => const NextcloudConnectionState(
    removedWithWarning: true,
    error: 'fixture remote revocation warning',
  );
}

class _NotesNativeWindow implements NativeWindowController {
  final listeners = <WindowListener>[];
  var closeCount = 0;
  @override
  Future<void> setPreventClose(bool value) async {}
  @override
  Future<bool> isFullScreen() async => false;
  @override
  Future<void> setFullScreen(bool value) async {}
  @override
  Future<void> close() async {
    closeCount++;
  }

  @override
  void addListener(WindowListener listener) => listeners.add(listener);
  @override
  void removeListener(WindowListener listener) => listeners.remove(listener);
}

class _WindowDraftSettings extends NotesSettingsController {
  @override
  NotesSettingsState build() => const NotesSettingsState(
    accountId: '123e4567-e89b-42d3-a456-426614174000',
    original: NotesSettings(notesPath: 'Notes', fileSuffix: '.md'),
    draft: NotesSettings(notesPath: 'Unsaved/Notes', fileSuffix: '.md'),
    phase: NotesSettingsPhase.ready,
  );
  @override
  Future<void> load(String id, {bool discard = false}) async {}
  void setSaving(bool saving) {
    state = NotesSettingsState(
      accountId: state.accountId,
      original: state.original,
      draft: state.draft,
      phase: saving ? NotesSettingsPhase.saving : NotesSettingsPhase.ready,
    );
  }
}
