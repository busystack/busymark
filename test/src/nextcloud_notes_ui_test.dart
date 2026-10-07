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
import 'package:busymark/src/nextcloud_notes/application/notes_repository.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_store.dart';
import 'package:busymark/src/nextcloud_notes/domain/notes_models.dart';
import 'package:busymark/src/nextcloud_notes/presentation/notes_sidebar.dart';
import 'package:busymark/src/workspace/presentation/settings_screen.dart';
import 'package:busymark/src/workspace/recovery_persistence.dart';
import 'package:busymark/src/workspace/session_persistence.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

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
    repository = _CachedNotesRepository(store: store);
    await repository.initialize();
  });
  tearDown(() async {
    await repository.dispose();
    await root.delete(recursive: true);
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 600);
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
              height: 700,
              child: NextcloudNotesSidebar(accountId: accountId),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
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
    await tester.pumpAndSettle();
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
    await tester.pumpAndSettle();
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

  testWidgets(
    'cached note list searches content and excludes clean deletion tombstones',
    (tester) async {
      await pump(tester);
      expect(find.text('Personal note'), findsOneWidget);
      expect(find.text('Shared note'), findsOneWidget);
      expect(find.text('Deleted note'), findsNothing);
      await tester.enterText(find.byType(TextField), 'private search');
      await tester.pumpAndSettle();
      expect(find.text('Personal note'), findsOneWidget);
      expect(find.text('Shared note'), findsNothing);
    },
  );

  testWidgets(
    'favorites and ancestor category filtering operate on cached notes',
    (tester) async {
      await pump(tester);
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();
      expect(find.text('Shared note'), findsNothing);
      expect(find.text('Personal note'), findsOneWidget);
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Projects').last);
      await tester.pumpAndSettle();
      expect(find.text('Shared note'), findsOneWidget);
      expect(find.text('Personal note'), findsNothing);
    },
  );

  testWidgets('moving the last selected category note clears its filter', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Personal').last);
    await tester.pumpAndSettle();
    expect(find.text('Shared note'), findsNothing);
    await tester.runAsync(
      () => repository.save(
        '223e4567-e89b-42d3-a456-426614174000',
        content: 'private search text',
        category: '',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Personal note'), findsOneWidget);
    expect(find.text('Shared note'), findsOneWidget);
    expect(
      tester
          .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
          .value,
      isNull,
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
        await repository.create(accountId, title: 'Uncategorized');
      });
      await pump(tester);
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last').last);
      await tester.pumpAndSettle();
      expect(find.text('Uncategorized'), findsNothing);
      await tester.runAsync(
        () => repository.save(categorized.localId, content: '', category: ''),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DropdownButton<String>), findsNothing);
      expect(find.text('Move me'), findsOneWidget);
      expect(find.text('Uncategorized'), findsOneWidget);
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
      await tester.pumpAndSettle();
      await tester.tap(find.text('Compare'));
      await tester.pumpAndSettle();
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(find.text('uncertain.pdf'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Attachment reference on server'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
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
          matching: find.byType(IconButton),
        ),
      );
      await tester.pumpAndSettle();
      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
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
          matching: find.byType(IconButton),
        ),
      );
      await tester.pumpAndSettle();
      for (
        var attempt = 0;
        attempt < 20 && find.text('report.pdf').evaluate().isEmpty;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)),
        );
        await tester.pumpAndSettle();
      }
      expect(find.text('Add attachment…'), findsOneWidget);
      expect(find.text('report.pdf'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Deleting this attachment makes its links in the note unavailable. Retained bytes can be recovered through local history.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();
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
      await tester.pumpAndSettle();
      expect(find.text('New note'), findsOneWidget);
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('Discard'), findsNWidgets(2));
      expect(find.text('Recoverable edit'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
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
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compare'));
    await tester.pumpAndSettle();
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
      await tester.pumpAndSettle();
    }
    expect(tester.widget<BusyMarkDialogButton>(button).onPressed, isNotNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repository.noteById(id)!.title, 'Local title');
    expect(tester.takeException(), isNull);
  });

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
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compare'));
    await tester.pumpAndSettle();
    final merge = find.byWidgetPredicate(
      (widget) => widget is BusyMarkDialogButton && widget.label == 'Merge',
    );
    expect(merge, findsOneWidget);
    expect(tester.widget<BusyMarkDialogButton>(merge).onPressed, isNotNull);
    expect(find.text('Keep Mine'), findsNothing);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
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
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compare'));
    await tester.pumpAndSettle();
    final takeRemote = find.byWidgetPredicate(
      (widget) =>
          widget is BusyMarkDialogButton &&
          widget.label == 'Use this server note',
    );
    expect(takeRemote, findsNothing);
    final candidates = find.byType(DropdownButton<int>);
    expect(candidates, findsOneWidget);
    tester.widget<DropdownButton<int>>(candidates).onChanged!(10);
    await tester.pumpAndSettle();
    expect(takeRemote, findsOneWidget);
    expect(find.textContaining('Sanitized A'), findsWidgets);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
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
      await tester.pumpAndSettle();
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
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sanitized A (#10)').last);
      await tester.pumpAndSettle();
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
        await tester.pumpAndSettle();
        await tester.tap(find.text('Compare'));
        await tester.pumpAndSettle();
        expect(find.text('New note'), findsOneWidget);
        expect(find.text('Merge'), findsNothing);
        expect(find.text('Keep Mine'), findsNothing);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
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

  @override
  Future<void> synchronize(String accountId) async {}
}
