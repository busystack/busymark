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
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

Future<void> settleStorage(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  late Directory root;
  late NotesRepository repository;
  const accountId = '123e4567-e89b-42d3-a456-426614174000';
  setUp(() async {
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
  });

  Future<void> pump(WidgetTester tester) async {
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
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SizedBox(
              width: 500,
              height: 1000,
              child: NextcloudNotesSidebar(accountId: accountId),
            ),
          ),
        ),
      ),
    );
    await settleStorage(tester);
  }

  test('Nextcloud settings route selects its dedicated page', () {
    expect(
      settingsPageFromRouteValue('nextcloudNotes'),
      SettingsPage.nextcloudNotes,
    );
  });

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
      await tester.tap(find.byType(TextField));
      await settleStorage(tester);
      final dialog = find.byType(NotesSearchDialog);
      final field = find.descendant(
        of: dialog,
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
        find.descendant(of: dialog, matching: find.text('Personal note')),
        findsNWidgets(2),
      );
      expect(
        find.descendant(of: dialog, matching: find.text('Shared note')),
        findsNothing,
      );
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
      final sort = tester.widget<DropdownButton<NotesSort>>(
        find.byType(DropdownButton<NotesSort>),
      );
      sort.onChanged!(NotesSort.titleAscending);
      await tester.pumpAndSettle();
      Finder row(NextcloudNote note) =>
          find.byKey(ValueKey('nextcloud-note-${note.localId}'));
      bool selected(NextcloudNote note) =>
          tester.widget<ListTile>(row(note)).selected;
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
      sort.onChanged!(NotesSort.titleDescending);
      await tester.pumpAndSettle();
      expect([alpha, beta, gamma].every(selected), true);
      await tester.tap(row(beta), buttons: kSecondaryButton);
      await settleStorage(tester);
      expect(find.text('Selected notes (3)'), findsNWidgets(2));
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
          .widget<ListTile>(
            find.ancestor(
              of: find.text('All notes'),
              matching: find.byType(ListTile),
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
          matching: find.byTooltip('Main menu'),
        ),
      );
      await settleStorage(tester);
      await tester.tap(find.text('Rename'));
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
      final favorite = find.byType(CheckboxListTile).last;
      expect(tester.widget<CheckboxListTile>(favorite).onChanged, isNotNull);
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
          matching: find.byTooltip('Main menu'),
        ),
      );
      await settleStorage(tester);
      await tester.tap(find.text('Rename'));
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
      expect(find.text('Discard'), findsNWidgets(2));
      expect(find.text('Recoverable edit'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await settleStorage(tester);
      expect(find.text('Resolve'), findsOneWidget);
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
    final dropdowns = find.byType(DropdownButton<NotesMergeChoice>);
    expect(dropdowns, findsNWidgets(3));
    for (var i = 0; i < 3; i++) {
      final dropdown = tester.widget<DropdownButton<NotesMergeChoice>>(
        dropdowns.at(i),
      );
      // Exercise the actual dialog state callback and verify Apply enablement.
      dropdown.onChanged!(NotesMergeChoice.remote);
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
          await tester.tap(find.byType(DropdownButton<NotesMergeChoice>));
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
    final candidates = find.byType(DropdownButton<int>);
    expect(candidates, findsOneWidget);
    tester.widget<DropdownButton<int>>(candidates).onChanged!(10);
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
        i < 100 && find.byType(DropdownButton<int>).evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.tap(find.byType(DropdownButton<int>));
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
