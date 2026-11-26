import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/core/save_destination.dart';
import 'package:busymark/src/local_history/local_history_controller.dart';
import 'package:busymark/src/local_history/local_history_models.dart';
import 'package:busymark/src/local_history/local_history_store.dart';
import 'package:busymark/src/nextcloud_notes/application/nextcloud_connection.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_navigation.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_repository.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_api_client.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_store.dart';
import 'package:busymark/src/nextcloud_notes/domain/notes_models.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:busymark/src/workspace/recovery_persistence.dart';
import 'package:busymark/src/workspace/session_persistence.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/workspace/workspace_file_monitor.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import 'nextcloud_notes/notes_api_test.dart' show serverNote;

const _accountId = 'ba6d02cd-42fe-4e14-a577-3e2c13822459';

void main() {
  test(
    'follow-up remote restore rejects a read-only transition during protection',
    () async {
      var remote = serverNote(1, content: 'current source', etag: 'unchanged');
      var writes = 0;
      final store = _BlockingRestoreHistoryStore();
      addTearDown(() {
        if (!store.release.isCompleted) store.release.complete();
      });
      final h = await _Harness.create(
        seedLocal: false,
        historyStore: store,
        client: MockClient((request) async {
          if (request.method != 'GET') writes++;
          return http.Response(
            jsonEncode(request.url.path.endsWith('/1') ? remote : [remote]),
            200,
          );
        }),
      );
      addTearDown(h.dispose);
      await h.repository.synchronize(_accountId, allowWrites: false);
      await h.controller.openNextcloudWorkspace(_accountId);
      await h.controller.refreshNextcloudNotes();
      final before = h.state.activeBuffer!;
      final captured = await store.capture(
        LocalHistoryCaptureRequest(
          remoteNote: before.remoteNote,
          displayName: before.displayName,
          source: 'historical source',
          format: before.format,
          capturedAt: DateTime.now().toUtc(),
          reason: LocalHistoryCaptureReason.saved,
        ),
        const LocalHistoryPolicy(),
      );
      final revision = (await store.readRevision(captured.revision!.id))!;
      final restoring = h.controller.restoreLocalHistoryRevision(
        document: captured.document,
        revision: revision,
      );
      await store.started.future;
      remote = serverNote(
        1,
        content: 'current source',
        etag: 'unchanged',
        readonly: true,
      );
      await h.controller.refreshNextcloudNotes();
      expect(h.state.activeBuffer!.readonly, isTrue);
      expect(h.state.activeBuffer!.revision, before.revision);
      expect(h.state.activeText, before.text);
      store.release.complete();
      expect(await restoring, isFalse);
      expect(h.state.activeBuffer!.readonly, isTrue);
      expect(h.state.activeBuffer!.revision, before.revision);
      expect(h.state.activeText, before.text);
      expect(
        h.state.activeBuffer!.editorState.undoState,
        same(before.editorState.undoState),
      );
      expect(
        h.repository.noteById(before.remoteNote!.localId)!.content,
        before.text,
      );
      expect(writes, 0);
    },
  );

  for (final flushBetween in [false, true]) {
    test('remote refresh retains displaced and incoming versions after close '
        '(flushBetween=$flushBetween)', () async {
      var remote = serverNote(1, content: 'R0', etag: 'v0');
      final h = await _Harness.create(
        seedLocal: false,
        client: MockClient(
          (request) async => http.Response(
            jsonEncode(request.url.path.endsWith('/1') ? remote : [remote]),
            200,
          ),
        ),
      );
      addTearDown(h.dispose);
      await h.repository.synchronize(_accountId, allowWrites: false);
      await h.controller.openNextcloudWorkspace(_accountId);
      final history = h.container.read(localHistoryControllerProvider.notifier);
      expect(await history.flushAll(h.state.documentBuffers), isTrue);
      for (var version = 1; version <= 2; version++) {
        remote = serverNote(1, content: 'R$version', etag: 'v$version');
        await h.controller.refreshNextcloudNotes();
        expect(h.state.activeText, 'R$version');
        if (flushBetween) {
          expect(await history.flushAll(h.state.documentBuffers), isTrue);
        }
      }
      expect(
        await h.controller.closeDocumentBuffer(h.state.activeBuffer!.id),
        isTrue,
      );
      expect(await history.flushAll(h.state.documentBuffers), isTrue);
      final store = h.container.read(localHistoryStoreProvider);
      final snapshot = await store.load();
      final sources = await Future.wait(
        snapshot.revisions.map(
          (r) async => (await store.readRevision(r.id))!.source,
        ),
      );
      expect(sources, containsAll(['R0', 'R1', 'R2']));
      expect(snapshot.documents, hasLength(1));
    });
  }

  for (final dirty in [false, true]) {
    test('remote history restore navigates accounts safely from local workspace '
        '(dirty=$dirty)', () async {
      final service = _GatedLocalOpenService();
      final (:h, :server, :openingSync) = await _openNotesWithHeldSync(service);
      final buffer = h.state.activeBuffer!;
      final openedBase = buffer.remoteEditBase!;
      expect(openedBase.state, isNotNull);
      final store = h.container.read(localHistoryStoreProvider);
      final captured = await store.capture(
        LocalHistoryCaptureRequest(
          remoteNote: buffer.remoteNote,
          displayName: buffer.displayName,
          source: 'retained remote source\n',
          format: buffer.format,
          capturedAt: DateTime.now().toUtc(),
          reason: LocalHistoryCaptureReason.saved,
        ),
        const LocalHistoryPolicy(),
      );
      final revision = (await store.readRevision(captured.revision!.id))!;
      final local = File(p.join(h.root.path, 'local.md'));
      await local.writeAsString('local source');

      final opening = h.controller.openPath(local.path);
      try {
        await service.started.future;
        final before = h.state.activeBuffer!;
        final base = before.remoteEditBase!;
        final note = h.repository.noteById(before.remoteNote!.localId)!;
        expect(base.state, same(openedBase.state));
        expect(base.generation, openedBase.generation);
        expect(base.state, same(note.base));

        // Opening Sync remains blocked at the collection read. Updating
        // account metadata emits a real Notes change without touching the note.
        const refreshedVersion = '6.1.1';
        final after = await _observeBufferChange(
          h,
          () =>
              h.repository.accountById(_accountId)?.appVersion ==
              refreshedVersion,
          () => h.repository.upsertAccount(
            h.repository
                .accountById(_accountId)!
                .copyWith(appVersion: refreshedVersion),
          ),
        );
        expect(h.repository.isSynchronizing(_accountId), isTrue);
        expect(h.repository.noteById(note.localId), same(note));
        expect(after, isNot(same(before)));
        expect(after.remoteEditBase, isNot(same(base)));
        expect(after.remoteEditBase!.state, same(base.state));
        expect(after.remoteEditBase!.generation, base.generation);
        expect(after.id, before.id);
        expect(after.remoteNote, before.remoteNote);
        expect(after.text, before.text);
        expect(after.revision, before.revision);
        expect(after.readonly, before.readonly);
        expect(after.isDirty, isFalse);
        expect(h.state.workspace!.nextcloudAccountId, _accountId);
        expect(h.state.isLoading, isTrue);
      } finally {
        service.release.complete();
        await opening;
        server.release();
        await openingSync;
      }
      expect(h.state.activeBuffer?.filePath, local.path);
      expect(h.state.activeText, 'local source');
      expect(h.state.isLoading, isFalse);

      Future<bool> restore() => h.controller.restoreLocalHistoryRevision(
        document: captured.document,
        revision: revision,
      );

      if (dirty) {
        h.controller.updateActiveText('unsaved local source');
        await h.controller.flushPersistence();
      }
      final current = await h.controller.localHistoryCurrentSource(
        captured.document,
        revision,
      );
      expect(current.canRestore, isTrue);
      if (dirty) {
        expect(await restore(), isFalse);
        expect(h.state.activeBuffer!.filePath, local.path);
        expect(h.state.activeText, 'unsaved local source');
        expect(h.state.isDirty, isTrue);
        expect(h.recovery.value.entries.single.text, 'unsaved local source');
        expect(
          h.repository.noteById(buffer.remoteNote!.localId)!.content,
          buffer.text,
        );
        expect(await local.readAsString(), 'local source');
        expect(await h.controller.saveActive(), isTrue);
      }
      expect(await restore(), isTrue);
      expect(h.state.workspace!.nextcloudAccountId, _accountId);
      expect(h.state.activeBuffer!.remoteNote, buffer.remoteNote);
      expect(h.state.activeText, revision.source);
      expect(
        h.repository.noteById(buffer.remoteNote!.localId)!.content,
        revision.source,
      );
      expect(
        (await store.readRevision(revision.summary.id))!.source,
        revision.source,
      );
      await h.controller.flushPersistence();
      expect(h.recovery.value.entries, isEmpty);
      expect(
        await local.readAsString(),
        dirty ? 'unsaved local source' : 'local source',
      );
    });
  }

  for (final (change, remotePatch) in [
    ('server snapshot', {'favorite': true}),
    ('server generation', {'etag': 'new-server-version'}),
    ('permission', {'error': true}),
  ]) {
    test('pending local open rejects a changed Notes $change', () async {
      final service = _GatedLocalOpenService();
      final (:h, :server, :openingSync) = await _openNotesWithHeldSync(service);
      final local = File(p.join(h.root.path, 'local.md'));
      await local.writeAsString('local source');
      var published = false;
      final opening = h.controller.openPath(
        local.path,
        acceptNavigation: () => true,
        onOpened: () => published = true,
      );
      final DocumentBuffer updated;
      try {
        await service.started.future;
        final original = h.state.activeBuffer!;
        final base = original.remoteEditBase!;
        updated = await _observeBufferChange(
          h,
          () {
            final note = h.repository.noteById(original.remoteNote!.localId)!;
            return switch (change) {
              'server snapshot' => note.favorite,
              'server generation' => note.etag == 'new-server-version',
              _ => note.readonly,
            };
          },
          () async {
            server.note.addAll(remotePatch);
            server.release();
            await openingSync;
          },
        );
        expect(updated.id, original.id);
        expect(updated.text, original.text);
        expect(updated.revision, original.revision);
        expect(updated.isDirty, isFalse);
        expect(updated.readonly, change == 'permission');
        expect(
          updated.remoteEditBase!.state,
          change == 'permission' ? same(base.state) : isNot(same(base.state)),
        );
        expect(
          updated.remoteEditBase!.generation,
          base.generation + (change == 'server generation' ? 1 : 0),
        );
      } finally {
        service.release.complete();
        await opening;
      }
      expect(published, isFalse);
      expect(h.state.activeBuffer!.remoteNote, updated.remoteNote);
      expect(h.state.activeText, updated.text);
      expect(h.state.activeBuffer!.readonly, updated.readonly);
      expect(h.state.isLoading, isFalse);
      expect(await local.readAsString(), 'local source');
    });
  }

  for (final change in [
    'dirty edit',
    'revision',
    'note',
    'new open',
    'disposal',
  ]) {
    test('pending local open rejects Notes $change', () async {
      final service = _GatedLocalOpenService();
      final (:h, :server, :openingSync) = await _openNotesWithHeldSync(service);
      final controller = h.controller;
      final local = File(p.join(h.root.path, 'local.md'));
      await local.writeAsString('local source');
      final before = h.state.activeBuffer!;
      var published = false;
      final opening = controller.openPath(
        local.path,
        onOpened: () => published = true,
      );
      int? readsBeforeRelease;
      DocumentBuffer? kept;
      try {
        await service.started.future;
        switch (change) {
          case 'dirty edit':
            controller.updateActiveText('Keep this draft');
            expect(h.state.isDirty, isTrue);
          case 'revision':
            controller.updateActiveText(
              'Edit before returning to saved source',
            );
            expect(controller.undoActiveBuffer(), isTrue);
            expect(h.state.isDirty, isFalse);
            expect(h.state.activeText, before.text);
            expect(
              h.state.activeBuffer!.revision,
              greaterThan(before.revision),
            );
          case 'note':
            final other = h.repository.notes.singleWhere(
              (note) => note.serverId == 2,
            );
            expect(await controller.openNextcloudNote(other.localId), isTrue);
            expect(h.state.activeBuffer!.remoteNote!.localId, other.localId);
          case 'new open':
            final newer = File(p.join(h.root.path, 'newer.md'));
            await newer.writeAsString('New destination');
            await controller.openPath(newer.path);
            expect(h.state.activeBuffer!.filePath, newer.path);
          case 'disposal':
            server.release();
            await openingSync;
            await h.dispose();
        }
        readsBeforeRelease = service.reads;
        if (change != 'disposal') kept = h.state.activeBuffer!;
      } finally {
        service.release.complete();
        await opening;
      }
      expect(published, isFalse);
      if (change == 'disposal' || change == 'new open') {
        expect(service.reads, readsBeforeRelease);
      }
      if (kept != null) {
        expect(await local.readAsString(), 'local source');
        expect(h.state.activeBuffer!.id, kept.id);
        expect(h.state.activeText, kept.text);
        expect(h.state.isLoading, isFalse);
        if (change == 'dirty edit') {
          expect(h.state.activeText, 'Keep this draft');
          expect(h.state.activeBuffer!.id, before.id);
          await controller.flushPersistence();
          expect(
            h.repository.noteById(before.remoteNote!.localId)!.content,
            'Keep this draft',
          );
        }
      }
    });
  }

  test(
    'remote refresh is an undoable boundary with an existing redo branch',
    () async {
      var remote = serverNote(1, content: 'baseline', etag: 'base');
      final h = await _Harness.create(
        seedLocal: false,
        client: MockClient((request) async {
          if (request.method == 'PUT') {
            remote = serverNote(
              1,
              content: (jsonDecode(request.body) as Map)['content'] as String,
              etag: 'saved',
            );
            return http.Response(jsonEncode(remote), 200);
          }
          return http.Response(
            jsonEncode(request.url.path.endsWith('/1') ? remote : [remote]),
            200,
          );
        }),
      );
      addTearDown(h.dispose);
      await h.repository.synchronize(_accountId, allowWrites: false);
      await h.controller.openNextcloudWorkspace(_accountId);
      await h.controller.refreshNextcloudNotes();
      h.controller.updateActiveText('first');
      h.controller.updateActiveText('second');
      expect(h.controller.undoActiveBuffer(), isTrue);
      expect(await h.controller.saveActive(), isTrue);
      await h.repository.synchronize(_accountId);
      expect(h.state.activeText, 'first');
      expect(h.state.activeBuffer!.editorState.undoState.redo, isNotEmpty);
      remote = serverNote(
        1,
        content: 'server replacement',
        etag: 'replacement',
      );
      await h.controller.refreshNextcloudNotes();
      expect(h.state.activeText, 'server replacement');
      expect(h.controller.redoActiveBuffer(), isFalse);
      expect(h.controller.undoActiveBuffer(), isTrue);
      expect(h.state.activeText, 'first');
      expect(h.controller.redoActiveBuffer(), isTrue);
      expect(h.state.activeText, 'server replacement');
    },
  );

  test(
    'no-op properties Save preserves revision/time and schedules no server pass',
    () async {
      var gets = 0;
      final harness = await _Harness.create(
        seedLocal: false,
        deferPersistence: true,
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(
            request.url.path,
            '/nextcloud/index.php/apps/notes/api/v1/notes',
          );
          gets++;
          return http.Response(jsonEncode([serverNote(1)]), 200);
        }),
      );
      addTearDown(harness.dispose);
      await harness.repository.synchronize(_accountId, allowWrites: false);
      await harness.controller.openNextcloudWorkspace(_accountId);
      await harness.controller.refreshNextcloudNotes();
      final note = harness.repository.notes.single;
      final count = gets;
      await harness.controller.updateNextcloudNoteMetadata(
        note.localId,
        snapshot: harness.repository.metadataSnapshot(note.localId),
      );
      expect(gets, count);
      expect(harness.repository.isSynchronizing(_accountId), isFalse);
      expect(
        harness.repository.noteById(note.localId)!.revision,
        note.revision,
      );
      expect(
        harness.repository.noteById(note.localId)!.localActivityMicros,
        note.localActivityMicros,
      );
    },
  );
  test(
    'unsaved draft edits during confirmation require another review',
    () async {
      Map<String, dynamic>? remote;
      final started = Completer<void>();
      final release = Completer<void>();
      var confirming = false;
      final harness = await _Harness.create(
        seedLocal: false,
        deferPersistence: true,
        client: MockClient((request) async {
          if (request.method == 'POST') {
            remote = {...serverNote(1), ...jsonDecode(request.body) as Map};
            throw http.ClientException('lost response');
          }
          if (confirming && request.url.path.endsWith('/notes/1')) {
            started.complete();
            await release.future;
            confirming = false;
          }
          return http.Response(
            jsonEncode(
              request.url.path.endsWith('/notes')
                  ? [if (remote != null) remote]
                  : remote,
            ),
            200,
          );
        }),
      );
      addTearDown(harness.dispose);
      final repository = harness.repository;
      final draft = await repository.create(_accountId, content: 'submitted');
      await repository.synchronize(_accountId);
      await repository.synchronize(_accountId);
      await harness.controller.openNextcloudWorkspace(_accountId);
      await harness.controller.openNextcloudNote(draft.localId);
      await harness.container
          .read(appSettingsControllerProvider.notifier)
          .setAutoSave(false);
      final reviewed = repository.creationReview(
        draft.localId,
        repository.noteById(draft.localId)!.remote!,
      );
      confirming = true;
      final decision = harness.controller.resolveNextcloudConflict(
        draft.localId,
        NoteConflictResolution.useServerNote,
        expectedRevision: reviewed.revision,
        creationCandidateServerId: 1,
        creationReview: reviewed,
      );
      await started.future;
      harness.controller.updateActiveText('unsaved newer draft edit');
      release.complete();
      await decision;
      expect(repository.noteById(draft.localId)!.serverId, isNull);
      expect(repository.noteById(draft.localId)!.creationAttempt, isNotNull);
      expect(harness.state.activeBuffer!.text, 'unsaved newer draft edit');
      expect(harness.state.activeBuffer!.isDirty, isTrue);
      expect(harness.state.message, isNotNull);
    },
  );

  test(
    'an unsaved independently opened candidate blocks consolidation without orphaning its tab',
    () async {
      Map<String, dynamic>? remote;
      final harness = await _Harness.create(
        seedLocal: false,
        deferPersistence: true,
        client: MockClient((request) async {
          if (request.method == 'POST') {
            remote = {...serverNote(1), ...jsonDecode(request.body) as Map};
            throw http.ClientException('lost response');
          }
          return http.Response(
            jsonEncode(
              request.url.path.endsWith('/notes')
                  ? [if (remote != null) remote]
                  : remote,
            ),
            200,
          );
        }),
      );
      addTearDown(harness.dispose);
      final repository = harness.repository;
      final draft = await repository.create(
        _accountId,
        content: 'wire content',
      );
      await repository.synchronize(_accountId);
      await repository.synchronize(_accountId);
      final twin = repository.notes.firstWhere((n) => n.serverId == 1);
      final reviewed = repository.creationReview(
        draft.localId,
        repository.noteById(draft.localId)!.remote!,
      );
      expect(
        await harness.controller.openNextcloudWorkspace(_accountId),
        isTrue,
      );
      expect(await harness.controller.openNextcloudNote(twin.localId), isTrue);
      expect(harness.state.activeBuffer!.remoteNote!.localId, twin.localId);
      await harness.container
          .read(appSettingsControllerProvider.notifier)
          .setAutoSave(false);
      harness.controller.updateActiveText('unsaved candidate edit');
      expect(harness.state.activeBuffer!.text, 'unsaved candidate edit');
      await harness.controller.resolveNextcloudConflict(
        draft.localId,
        NoteConflictResolution.useServerNote,
        expectedRevision: reviewed.revision,
        creationCandidateServerId: 1,
        creationReview: reviewed,
      );
      expect(repository.noteById(draft.localId)!.serverId, isNull);
      expect(repository.noteById(twin.localId), isNotNull);
      final tab = harness.state.documentBuffers.firstWhere(
        (b) => b.remoteNote?.localId == twin.localId,
      );
      expect(tab.text, 'unsaved candidate edit');
      expect(tab.isDirty, isTrue);
      expect(harness.state.message, isNotNull);
      expect(await harness.controller.saveActive(), isTrue);
      expect(
        repository.noteById(twin.localId)!.content,
        'unsaved candidate edit',
      );
    },
  );

  test(
    'Save, Save All, autosave and shutdown durably retain offline notes',
    () async {
      final harness = await _Harness.create();
      addTearDown(harness.dispose);
      final controller = harness.controller;
      expect(await controller.openNextcloudWorkspace(_accountId), isTrue);
      expect(harness.monitor.starts, 0);
      expect(harness.state.workspace!.filesystemRootPath, isNull);
      final firstId = harness.state.activeBuffer!.remoteNote!.localId;
      controller.updateActiveText('# Saved offline');
      expect(await controller.saveActive(), isTrue);
      expect(harness.state.isDirty, isFalse);
      expect(
        (await harness.repository.store.notes()).single.content,
        '# Saved offline',
      );
      expect(harness.repository.noteById(firstId)!.hasPendingChanges, isTrue);
      expect(await controller.createNextcloudNote(title: 'Second'), isTrue);
      expect(harness.state.activeBuffer!.remoteNote!.localId, isNot(firstId));
      expect(harness.state.activeBuffer!.displayName, 'Second');
      controller.updateActiveText('Second offline revision');
      expect((await controller.saveAll()).succeeded, isTrue);
      expect(harness.repository.noteById(firstId)!.content, '# Saved offline');
      expect(harness.state.documentBuffers, hasLength(2));
      await harness.container
          .read(appSettingsControllerProvider.notifier)
          .setAutoSave(true);
      controller.updateActiveText('Autosaved offline revision');
      expect(await controller.autoSaveActiveIfNeeded(), isTrue);
      await controller.markCleanShutdown();
      expect(harness.recovery.value.cleanShutdown, isTrue);
      expect(harness.recovery.value.entries, isEmpty);
      expect(harness.session.value!.nextcloudAccountId, _accountId);
      expect(
        harness.session.value!.tabs.every(
          (tab) => tab.remoteNote != null && tab.filePath == null,
        ),
        isTrue,
      );
      expect(
        harness.repository.notes.any(
          (note) => note.content == 'Autosaved offline revision',
        ),
        isTrue,
      );
    },
  );

  test(
    'direct dirty remote close protects history without a queue cycle',
    () async {
      final h = await _Harness.create(deferPersistence: true);
      final controller = h.controller;
      expect(await controller.openNextcloudWorkspace(_accountId), isTrue);
      await controller.flushPersistence();
      final buffer = h.state.activeBuffer!;
      controller.updateActiveText('discardable edit');
      final closed = await controller
          .closeDocumentBuffer(buffer.id, discard: true)
          .timeout(const Duration(seconds: 4));
      expect(closed, isTrue);
      expect(h.state.documentBuffers, isEmpty);
      expect((await h.repository.store.notes()).single.content, buffer.text);
      final history = h.container.read(localHistoryStoreProvider);
      final revisions = (await history.load()).revisions;
      expect(
        await Future.wait(
          revisions.map(
            (r) async => (await history.readRevision(r.id))!.source,
          ),
        ),
        contains('discardable edit'),
      );
      await h.dispose();
    },
  );

  for (final baseChanged in [false, true]) {
    test(
      'window close authorization checks provenance of an identical saved edit (server change: $baseChanged)',
      () async {
        var remote = serverNote(1, content: 'Original', etag: 'base');
        final h = await _Harness.create(
          seedLocal: false,
          deferPersistence: true,
          client: MockClient(
            (_) async => http.Response(jsonEncode([remote]), 200),
          ),
        );
        addTearDown(h.dispose);
        await h.repository.synchronize(_accountId, allowWrites: false);
        final controller = h.controller;
        expect(await controller.openNextcloudWorkspace(_accountId), isTrue);
        await controller.refreshNextcloudNotes();
        final id = h.state.activeBuffer!.remoteNote!.localId;
        controller.updateActiveText('Reviewed edit');
        if (!baseChanged) {
          // A local metadata edit can advance the repository revision while
          // the editor still owns its original content revision.
          await h.repository.save(id, content: 'Original', favorite: true);
        }
        final before = h.state.activeBuffer!;
        final reviewed = controller.captureWindowCloseAuthorization();
        if (baseChanged) {
          remote = serverNote(1, content: 'Original', etag: 'changed');
          await controller.refreshNextcloudNotes();
        }
        await controller.markCleanShutdown();

        final live = h.state.activeBuffer!;
        expect(live.text, before.text);
        expect(live.isDirty, isFalse);
        if (!baseChanged) expect(live.revision, greaterThan(before.revision));
        expect(
          controller.isWindowCloseAuthorizationCurrent(reviewed),
          !baseChanged,
        );
      },
    );
  }

  for (final duringDiscard in [false, true]) {
    test(
      'remote discard adopts the current edit base (refresh during discard: $duringDiscard)',
      () async {
        var remote = serverNote(1, content: 'B', etag: 'base');
        final history = _BlockingRestoreHistoryStore(
          reason: LocalHistoryCaptureReason.beforeDiscard,
        );
        final h = await _Harness.create(
          seedLocal: false,
          deferPersistence: true,
          historyStore: history,
          client: MockClient(
            (request) async => http.Response(
              jsonEncode(request.url.path.endsWith('/1') ? remote : [remote]),
              200,
            ),
          ),
        );
        addTearDown(h.dispose);
        addTearDown(() {
          if (!history.release.isCompleted) history.release.complete();
        });
        // This scenario needs a dirty edit across the refresh. Autosave can
        // commit it while the refresh is pending, before discard is requested.
        await h.container
            .read(appSettingsControllerProvider.notifier)
            .setAutoSave(false);
        await h.repository.synchronize(_accountId, allowWrites: false);
        await h.controller.openNextcloudWorkspace(_accountId);
        await h.controller.refreshNextcloudNotes();
        final before = h.state.activeBuffer!;
        final id = before.remoteNote!.localId;
        h.controller.updateActiveText('discardable local edit');
        remote = serverNote(1, content: 'R', etag: 'refreshed');
        if (!duringDiscard) await h.controller.refreshNextcloudNotes();
        expect(h.state.activeBuffer!.isDirty, isTrue);
        final discard = h.controller.discardActiveChanges();
        expect(
          await Future.any([
            history.started.future.then((_) => true),
            discard.then((_) => false),
          ]),
          isTrue,
          reason: 'Discard must reach protective history capture',
        );
        if (duringDiscard) await h.controller.refreshNextcloudNotes();
        expect(h.state.activeText, 'discardable local edit');
        expect(h.repository.noteById(id)!.content, 'R');
        history.release.complete();
        expect(await discard, isTrue);
        final adopted = h.state.activeBuffer!;
        expect(adopted.opening, same(before.opening));
        expect(adopted.text, 'R');
        expect(adopted.remoteEditBase?.state?.etag, 'refreshed');
        expect(
          adopted.remoteEditBase?.generation,
          h.repository.editorBase(id).generation,
        );
        h.controller.updateActiveText('R with another edit');
        expect(await h.controller.saveActive(), isTrue);
        final saved = (await h.repository.store.notes()).single;
        expect(saved.syncState, NoteSyncState.pending);
        expect(saved.base?.etag, 'refreshed');
        expect(saved.content, 'R with another edit');
      },
    );
  }

  test('immediate persistence cannot deadlock a remote save', () async {
    final harness = await _Harness.create(persistenceDelay: Duration.zero);
    addTearDown(harness.dispose);
    final controller = harness.controller;
    expect(await controller.openNextcloudWorkspace(_accountId), isTrue);
    controller.updateActiveText('# Immediate durable edit');

    expect(
      await controller.saveActive().timeout(const Duration(seconds: 5)),
      isTrue,
    );
    await controller.flushPersistence().timeout(const Duration(seconds: 5));

    expect(
      (await harness.repository.store.notes()).single.content,
      '# Immediate durable edit',
    );
    expect(harness.session.value?.nextcloudAccountId, _accountId);
  });

  for (final duringRefresh in [false, true]) {
    test(
      'unsaved editor base survives refresh (in flight: $duringRefresh)',
      () async {
        var remote = serverNote(1, content: '# Base', etag: 'base');
        var puts = 0;
        Completer<void>? started;
        Completer<void>? release;
        final harness = await _Harness.create(
          seedLocal: false,
          deferPersistence: true,
          client: MockClient((request) async {
            if (request.method == 'PUT') puts++;
            started?.complete();
            started = null;
            await release?.future;
            return http.Response(jsonEncode([remote]), 200);
          }),
        );
        addTearDown(harness.dispose);
        await harness.repository.synchronize(_accountId);
        await harness.controller.openNextcloudWorkspace(_accountId);
        await harness.controller.refreshNextcloudNotes();
        final id = harness.state.activeBuffer!.remoteNote!.localId;
        Future<void>? refresh;
        if (duringRefresh) {
          final entered = Completer<void>();
          started = entered;
          release = Completer<void>();
          refresh = harness.controller.refreshNextcloudNotes();
          await entered.future;
        }
        harness.controller.updateActiveText('# My unsaved edit');
        remote = serverNote(
          1,
          content: '# Concurrent edit',
          etag: 'concurrent',
        );
        release?.complete();
        await (refresh ?? harness.controller.refreshNextcloudNotes());
        expect(harness.repository.noteById(id)!.content, '# Concurrent edit');
        expect(harness.state.activeBuffer!.lastSavedText, '# Base');
        expect(harness.state.activeText, '# My unsaved edit');
        expect(await harness.controller.saveActive(), isTrue);
        await harness.controller.refreshNextcloudNotes();
        final saved = harness.repository.noteById(id)!;
        expect(saved.syncState, NoteSyncState.conflict);
        expect(saved.base!.content, '# Base');
        expect(saved.etag, 'base');
        expect(saved.content, '# My unsaved edit');
        expect(saved.remote!.content, '# Concurrent edit');
        expect(puts, 0);
        final durable = (await harness.repository.store.notes()).single;
        expect(durable.base!.etag, 'base');
        expect(durable.remote!.etag, 'concurrent');
        expect(durable.hasPendingChanges, isTrue);
      },
    );
  }

  test(
    'batch deletion preserves each blocked, failed and uncertain note',
    () async {
      final notes = {
        for (var id = 1; id <= 8; id++)
          id: serverNote(id, content: 'server body $id', readonly: id == 3),
      };
      final started = Completer<void>();
      final release = Completer<void>();
      final deletes = <int>[];
      final history = _FailingDeleteHistoryStore();
      var deleting = false;
      final h = await _Harness.create(
        seedLocal: false,
        deferPersistence: true,
        historyStore: history,
        client: MockClient((request) async {
          final id = int.tryParse(request.url.pathSegments.last);
          if (request.method == 'DELETE') {
            deletes.add(id!);
            if (id == 5) throw http.ClientException('response lost');
            expect(id, 1);
            notes.remove(id);
            return http.Response('', 200);
          }
          expect(request.method, 'GET');
          if (deleting && id == 1) {
            started.complete();
            await release.future;
          }
          if (deleting && id == 2) {
            return http.Response(
              jsonEncode(
                serverNote(2, etag: 'changed', content: 'new server body'),
              ),
              200,
            );
          }
          if (deleting && id == 7) throw http.ClientException('offline');
          if (deleting && id == 8) {
            return http.Response(
              jsonEncode({...notes[8]!, 'readonly': true}),
              200,
            );
          }
          return http.Response(
            jsonEncode(id == null ? notes.values.toList() : notes[id]),
            200,
          );
        }),
      );
      addTearDown(h.dispose);
      addTearDown(() {
        if (!release.isCompleted) release.complete();
      });
      await h.repository.synchronize(_accountId, allowWrites: false);
      await h.controller.openNextcloudWorkspace(_accountId);
      await h.controller.refreshNextcloudNotes();
      final targets = [
        for (var id = 1; id <= 8; id++)
          h.repository.notes.singleWhere((note) => note.serverId == id),
      ];
      history.failId = targets[3].localId;
      await h.controller.openNextcloudNote(targets[0].localId);
      h.controller.updateActiveText('dirty content retained in history');
      await h.controller.openNextcloudNote(targets[5].localId);

      final database = sqlite3.open(h.repository.store.path);
      try {
        database.execute('''
        CREATE TRIGGER fail_fixture_delete_save BEFORE UPDATE ON notes
        WHEN NEW.id = '${targets[5].localId}'
         AND json_extract(NEW.data, '\$.content') = 'dirty content stays in editor'
        BEGIN SELECT RAISE(ABORT, 'fixture save failure'); END
      ''');
      } finally {
        database.close();
      }
      addTearDown(() {
        final cleanup = sqlite3.open(h.repository.store.path);
        try {
          cleanup.execute('DROP TRIGGER fail_fixture_delete_save');
        } finally {
          cleanup.close();
        }
      });
      h.controller.updateActiveText('dirty content stays in editor');
      final draft = await h.repository.create(
        _accountId,
        content: 'unsent draft',
      );
      // Refresh any revisions saved by opening another tab before making the review.
      final reviewed = [
        for (final target in targets) h.repository.noteById(target.localId)!,
        draft,
      ];
      final generation = h.repository.accountGeneration(_accountId);
      deleting = true;
      final progress = <String>[];
      final submission = h.controller.batchDeleteNextcloudNotes(
        reviewed,
        accountGeneration: generation,
        onOutcome: (outcome) => progress.add(outcome.localId),
      );
      await Future.any([
        started.future,
        submission.then<void>((outcomes) {
          throw StateError(
            'Deletion did not reach its fresh GET. '
            '${outcomes.map((o) => '${o.status}: ${o.reason}: ${o.detail}').join(', ')}',
          );
        }),
      ]).timeout(const Duration(seconds: 5));
      try {
        await expectLater(
          h.controller.batchDeleteNextcloudNotes(
            reviewed,
            accountGeneration: generation,
          ),
          throwsA(
            isA<NotesException>().having(
              (e) => e.code,
              'code',
              NotesFailureCode.conflict,
            ),
          ),
        );
        expect(progress, isEmpty);
        expect(deletes, isEmpty);
      } finally {
        release.complete();
      }
      final outcomes = await submission;
      expect(progress, reviewed.map((n) => n.localId).toList());
      expect(outcomes.map((value) => value.reason), [
        null,
        NotesBatchReason.reviewChanged,
        NotesBatchReason.readOnly,
        NotesBatchReason.historyNotSaved,
        NotesBatchReason.deletionUncertain,
        NotesBatchReason.editorNotSaved,
        NotesBatchReason.unavailable,
        NotesBatchReason.readOnly,
        null,
      ]);
      expect(deletes, [1, 5]);
      expect(
        outcomes
            .where((o) => o.status == NotesBatchStatus.changed)
            .map((o) => o.localId),
        [targets[0].localId, draft.localId],
      );
      expect(
        h.repository.noteById(targets[0].localId)!.syncState,
        NoteSyncState.deletedRemotely,
      );
      expect(h.repository.noteById(draft.localId)!.content, 'unsent draft');
      expect(
        h.repository.noteById(draft.localId)!.syncState,
        NoteSyncState.deletedRemotely,
      );
      expect(
        h.repository.noteById(targets[1].localId)!.remote!.content,
        'new server body',
      );
      for (final target in targets.skip(1)) {
        final current = h.repository.noteById(target.localId)!;
        expect(current.syncState, isNot(NoteSyncState.deletedRemotely));
        expect(current.content, target.content);
      }
      expect(
        history.beforeDelete[targets[0].localId],
        'dirty content retained in history',
      );
      expect(
        h.state.documentBuffers
            .singleWhere((b) => b.remoteNote?.localId == targets[5].localId)
            .text,
        'dirty content stays in editor',
      );
    },
  );

  for (final explicitDelete in [false, true]) {
    test(
      'removed active note activates remaining tab (explicit: $explicitDelete)',
      () async {
        final remote = {
          1: serverNote(1, content: '# First'),
          2: serverNote(2, content: '# Second'),
        };
        final harness = await _Harness.create(
          seedLocal: false,
          client: MockClient((request) async {
            final id = int.tryParse(request.url.pathSegments.last);
            if (request.method == 'DELETE') {
              remote.remove(id);
              return http.Response('', 200);
            }
            return http.Response(
              jsonEncode(id == null ? remote.values.toList() : remote[id]),
              200,
            );
          }),
        );
        addTearDown(harness.dispose);
        await harness.repository.synchronize(_accountId);
        await harness.controller.openNextcloudWorkspace(_accountId);
        await harness.controller.refreshNextcloudNotes();
        final first = harness.repository.notes.firstWhere(
          (n) => n.serverId == 1,
        );
        final second = harness.repository.notes.firstWhere(
          (n) => n.serverId == 2,
        );
        await harness.controller.openNextcloudNote(second.localId);
        await harness.controller.openNextcloudNote(first.localId);
        final activated = Completer<void>();
        final subscription = harness.container.listen(
          workspaceControllerProvider,
          (_, next) {
            if (next.workspace?.markdown?.source == '# Second' &&
                !activated.isCompleted) {
              activated.complete();
            }
          },
        );
        addTearDown(subscription.close);
        if (explicitDelete) {
          expect(
            (await harness.controller.deleteNextcloudNote(
              first.localId,
            )).status,
            NotesBatchStatus.changed,
          );
        } else {
          remote.remove(1);
          await harness.controller.refreshNextcloudNotes();
        }
        await activated.future.timeout(const Duration(seconds: 5));
        expect(harness.state.activeText, '# Second');
        expect(
          harness.state.workspace!.markdown!.headings.single.text,
          'Second',
        );
        expect(harness.state.preview!.title, 'Second');
        remote.clear();
        await harness.controller.refreshNextcloudNotes();
        await Future<void>.delayed(Duration.zero);
        expect(harness.state.activeBuffer, isNull);
        expect(harness.state.workspace!.markdown, isNull);
        expect(harness.state.preview, isNull);
        expect(harness.state.liveOutline, isNull);
      },
    );
  }

  test(
    'remote session restores content and pending sync from SQLite after restart',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'busymark-notes-restart-',
      );
      addTearDown(() => root.delete(recursive: true));
      final session = MemoryDocumentSessionStore();
      final recovery = MemoryDocumentRecoveryStore();
      final first = await _Harness.create(
        root: root,
        session: session,
        recovery: recovery,
      );
      await first.controller.openNextcloudWorkspace(_accountId);
      first.controller.updateActiveText('Durable pending content');
      await first.controller.saveActive();
      await first.controller.markCleanShutdown();
      final identity = first.state.activeBuffer!.identity;
      await first.dispose();
      final second = await _Harness.create(
        root: root,
        session: session,
        recovery: recovery,
      );
      addTearDown(second.dispose);
      expect(await second.controller.restorePreviousSession(), isTrue);
      expect(second.state.activeText, 'Durable pending content');
      expect(second.state.activeBuffer!.identity, identity);
      expect(second.state.activeBuffer!.isUntitled, isFalse);
      expect(second.state.isDirty, isFalse);
      expect(second.repository.notes.single.hasPendingChanges, isTrue);
      expect(second.monitor.starts, 0);
    },
  );

  test(
    'remote Save As keeps account, buffer identity and pending operation',
    () async {
      final harness = await _Harness.create();
      addTearDown(harness.dispose);
      await harness.controller.openNextcloudWorkspace(_accountId);
      harness.controller.updateActiveText('# Local export');
      await harness.controller.saveActive();
      final before = harness.state.activeBuffer!;
      final path = p.join(harness.root.path, 'export.md');
      expect(await harness.controller.saveActiveAs(path), isTrue);
      expect(await File(path).readAsString(), '# Local export');
      expect(harness.state.activeBuffer!.identity, before.identity);
      expect(harness.state.activeBuffer!.filePath, isNull);
      expect(harness.state.workspace!.kind, WorkspaceKind.nextcloudNotes);
      expect(harness.repository.notes.single.hasPendingChanges, isTrue);
    },
  );

  test(
    'public Save As exports a dirty offline note and its durable attachment',
    () async {
      final harness = await _Harness.create(deferPersistence: true);
      addTearDown(harness.dispose);
      await harness.controller.openNextcloudWorkspace(_accountId);
      final before = harness.state.activeBuffer!;
      final id = before.remoteNote!.localId;
      final cached = harness.repository.noteById(id)!;
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      final attachment = await harness.repository.addAttachment(
        id,
        filename: 'attachment.bin',
        bytes: bytes,
      );
      final draft =
          '# Offline draft\n\n[Attachment](${attachment.reference})\n';
      harness.controller.updateActiveText(draft);
      final editor = harness.state.activeBuffer!;
      expect(editor.isDirty, isTrue);

      final file = File(p.join(harness.root.path, 'offline.md'));
      expect(
        await harness.controller.saveActiveAs(
          file.path,
          authorization: SaveDestination.inspect(file.path),
          intent: SaveAsIntent.markdown,
        ),
        isTrue,
      );
      final output = await file.readAsString();
      final link = RegExp(r'\[Attachment\]\(([^)]+)\)').firstMatch(output)![1]!;
      expect(output, startsWith('# Offline draft'));
      expect(
        await File(
          p.join(file.parent.path, Uri.decodeFull(link)),
        ).readAsBytes(),
        bytes,
      );
      expect(harness.state.activeBuffer!.opening, same(before.opening));
      expect(harness.state.activeBuffer!.remoteNote, before.remoteNote);
      expect(
        harness.state.activeBuffer!.remoteEditBase,
        same(editor.remoteEditBase),
      );
      expect(harness.state.activeBuffer!.text, draft);
      expect(harness.state.activeBuffer!.isDirty, isTrue);
      expect(harness.repository.noteById(id)!.revision, cached.revision);
      expect(harness.repository.noteById(id)!.ackRevision, cached.ackRevision);
      expect(harness.repository.noteById(id)!.content, cached.content);
    },
  );

  test(
    'closing the final remote tab leaves its Notes workspace and outbox',
    () async {
      final harness = await _Harness.create();
      addTearDown(harness.dispose);
      await harness.controller.openNextcloudWorkspace(_accountId);
      final buffer = harness.state.activeBuffer!;
      expect(await harness.controller.closeDocumentBuffer(buffer.id), isTrue);
      expect(harness.state.workspace!.kind, WorkspaceKind.nextcloudNotes);
      expect(harness.state.documentBuffers, isEmpty);
      expect(harness.repository.notes.single.hasPendingChanges, isTrue);
    },
  );

  test('remote history restore is a durable new local edit', () async {
    final harness = await _Harness.create();
    addTearDown(harness.dispose);
    await harness.controller.openNextcloudWorkspace(_accountId);
    final buffer = harness.state.activeBuffer!;
    final history = harness.container.read(localHistoryStoreProvider);
    final capture = await history.capture(
      LocalHistoryCaptureRequest(
        remoteNote: buffer.remoteNote,
        displayName: buffer.displayName,
        source: 'Historical remote revision',
        format: buffer.format,
        capturedAt: DateTime.utc(2026, 10, 4),
        reason: LocalHistoryCaptureReason.saved,
      ),
      const LocalHistoryPolicy(),
    );
    final revision = (await history.readRevision(capture.revision!.id))!;
    expect(
      await harness.controller.restoreLocalHistoryRevision(
        document: capture.document,
        revision: revision,
      ),
      isTrue,
    );
    expect(harness.state.activeBuffer!.identity, buffer.identity);
    expect(harness.state.activeText, revision.source);
    final saved = harness.repository.noteById(buffer.remoteNote!.localId)!;
    expect(saved.content, revision.source);
    expect(saved.hasPendingChanges, isTrue);
    expect(harness.monitor.starts, 0);
  });

  test('removing an open remote account clears its session', () async {
    final harness = await _Harness.create();
    addTearDown(harness.dispose);
    await harness.controller.openNextcloudWorkspace(_accountId);
    await harness.controller.flushPersistence();
    expect(harness.session.value!.nextcloudAccountId, _accountId);
    await harness.repository.removeAccount(_accountId);
    await harness.controller.closeRemovedNextcloudWorkspace(_accountId);
    expect(harness.state.workspace, isNull);
    expect(harness.state.documentBuffers, isEmpty);
    expect(harness.session.value, isNull);
    expect(harness.recovery.value.entries, isEmpty);
  });
}

class _Harness {
  _Harness(
    this.root,
    this.ownsRoot,
    this.repository,
    this.container,
    this.session,
    this.recovery,
    this.monitor,
  );
  final Directory root;
  final bool ownsRoot;
  final NotesRepository repository;
  final ProviderContainer container;
  final MemoryDocumentSessionStore session;
  final MemoryDocumentRecoveryStore recovery;
  final _Monitor monitor;
  WorkspaceController get controller =>
      container.read(workspaceControllerProvider.notifier);
  WorkspaceState get state => container.read(workspaceControllerProvider);

  static Future<_Harness> create({
    Directory? root,
    MemoryDocumentSessionStore? session,
    MemoryDocumentRecoveryStore? recovery,
    http.Client? client,
    bool seedLocal = true,
    bool deferPersistence = false,
    Duration? persistenceDelay,
    LocalHistoryStore? historyStore,
    WorkspaceService? workspaceService,
  }) async {
    final directory =
        root ??
        await Directory.systemTemp.createTemp('busymark-notes-workspace-');
    final transport =
        client ??
        MockClient((request) async => throw http.ClientException('offline'));
    final repository = NotesRepository(
      store: await NotesStore.open(
        path: p.join(directory.path, 'db', 'notes.sqlite3'),
      ),
      clientForAccount: (account) async => NotesApiClient(
        client: transport,
        account: account,
        appPassword: 'test',
      ),
    );
    await repository.initialize();
    if (repository.accounts.isEmpty) {
      await repository.upsertAccount(
        NextcloudAccount(
          id: _accountId,
          server: Uri.parse('https://cloud.test/nextcloud'),
          loginName: 'exact.login',
          appVersion: '6.1.0',
        ),
      );
      if (seedLocal) {
        await repository.create(
          _accountId,
          title: 'First',
          content: '# Initial',
        );
      }
    }
    final sessionStore = session ?? MemoryDocumentSessionStore();
    final recoveryStore = recovery ?? MemoryDocumentRecoveryStore();
    final monitor = _Monitor();
    final container = ProviderContainer(
      overrides: [
        if (persistenceDelay != null)
          documentPersistenceDelayProvider.overrideWithValue(persistenceDelay)
        else if (deferPersistence)
          documentPersistenceDelayProvider.overrideWithValue(
            const Duration(hours: 1),
          ),
        localSettingsStoreProvider.overrideWithValue(_Settings()),
        localHistoryStoreProvider.overrideWithValue(
          historyStore ?? MemoryLocalHistoryStore(),
        ),
        nextcloudNotesRepositoryProvider.overrideWith(
          (ref) async => repository,
        ),
        if (workspaceService != null)
          workspaceServiceProvider.overrideWithValue(workspaceService),
        workspaceFileMonitorProvider.overrideWithValue(monitor),
        documentSessionStoreProvider.overrideWithValue(sessionStore),
        documentRecoveryStoreProvider.overrideWithValue(recoveryStore),
      ],
    );
    container.read(appSettingsControllerProvider.notifier);
    container.read(workspaceControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    return _Harness(
      directory,
      root == null,
      repository,
      container,
      sessionStore,
      recoveryStore,
      monitor,
    );
  }

  Future<void>? _disposal;

  Future<void> dispose() => _disposal ??= _dispose();

  Future<void> _dispose() async {
    await controller.flushPersistence();
    await controller.refreshNextcloudNotes();
    container.dispose();
    await repository.dispose();
    await monitor.dispose();
    if (ownsRoot) await root.delete(recursive: true);
  }
}

Future<({_Harness h, _GatedNotesCollection server, Future<void> openingSync})>
_openNotesWithHeldSync(_GatedLocalOpenService service) async {
  final server = _GatedNotesCollection();
  final h = await _Harness.create(
    seedLocal: false,
    deferPersistence: true,
    client: MockClient(server.respond),
    workspaceService: service,
  );
  addTearDown(h.dispose);
  addTearDown(server.release);
  await h.container
      .read(appSettingsControllerProvider.notifier)
      .setAutoSave(false);
  await h.repository.synchronize(_accountId, allowWrites: false);
  server.holdNextRead = true;
  expect(await h.controller.openNextcloudWorkspace(_accountId), isTrue);
  await server.started.future;
  expect(h.repository.isSynchronizing(_accountId), isTrue);
  final openingSync = h.repository.synchronize(_accountId);
  return (h: h, server: server, openingSync: openingSync);
}

Future<DocumentBuffer> _observeBufferChange(
  _Harness h,
  bool Function() expectedNotification,
  Future<void> Function() causeChange,
) async {
  final observed = Completer<DocumentBuffer>();
  final subscription = h.container.listen(workspaceControllerProvider, (
    _,
    next,
  ) {
    if (!observed.isCompleted && expectedNotification()) {
      observed.complete(next.activeBuffer!);
    }
  });
  try {
    await causeChange();
    return await observed.future;
  } finally {
    subscription.close();
  }
}

class _GatedNotesCollection {
  final note = serverNote(1, content: 'current server source', etag: 'base');
  final _otherNote = serverNote(2, content: 'Other source');
  final started = Completer<void>();
  final _released = Completer<void>();
  var holdNextRead = false;

  void release() {
    if (!_released.isCompleted) _released.complete();
  }

  Future<http.Response> respond(http.Request request) async {
    if (request.method == 'PUT') {
      note['content'] = (jsonDecode(request.body) as Map)['content'];
      note['etag'] = 'acknowledged';
      return http.Response(jsonEncode(note), 200);
    }
    expect(request.method, 'GET');
    if (request.url.path.endsWith('/notes')) {
      if (holdNextRead) {
        holdNextRead = false;
        started.complete();
        await _released.future;
      }
      return http.Response(jsonEncode([note, _otherNote]), 200);
    }
    expect(request.url.path, matches(RegExp(r'/notes/[12]$')));
    return http.Response(
      jsonEncode(request.url.path.endsWith('/1') ? note : _otherNote),
      200,
    );
  }
}

class _GatedLocalOpenService extends WorkspaceService {
  final started = Completer<void>();
  final release = Completer<void>();
  var reads = 0;

  @override
  Future<WorkspaceFileLoad> loadTextWithSnapshot(String path) {
    reads++;
    return super.loadTextWithSnapshot(path);
  }

  @override
  Future<Workspace> openPath(String path) async {
    final loaded = await super.openPath(path);
    if (!started.isCompleted) {
      started.complete();
      await release.future;
    }
    return loaded;
  }
}

class _BlockingRestoreHistoryStore extends MemoryLocalHistoryStore {
  _BlockingRestoreHistoryStore({
    this.reason = LocalHistoryCaptureReason.beforeRestore,
  });

  final LocalHistoryCaptureReason reason;
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<LocalHistoryCaptureResult> capture(
    LocalHistoryCaptureRequest request,
    LocalHistoryPolicy policy,
  ) async {
    if (request.reason == reason) {
      if (!started.isCompleted) started.complete();
      await release.future;
    }
    return super.capture(request, policy);
  }
}

class _FailingDeleteHistoryStore extends MemoryLocalHistoryStore {
  String? failId;
  final beforeDelete = <String, String>{};

  @override
  Future<LocalHistoryCaptureResult> capture(
    LocalHistoryCaptureRequest request,
    LocalHistoryPolicy policy,
  ) async {
    final note = request.remoteNote;
    if (request.reason == LocalHistoryCaptureReason.beforeDelete &&
        note != null) {
      if (note.localId == failId) {
        throw const FileSystemException('fixture history failure');
      }
      beforeDelete[note.localId] = request.source;
    }
    return super.capture(request, policy);
  }
}

class _Monitor extends WorkspaceFileMonitor {
  int starts = 0;
  @override
  Future<void> start({
    required String rootPath,
    required Iterable<String> openFilePaths,
  }) async {
    starts++;
  }
}

class _Settings implements LocalSettingsStore {
  @override
  Future<Map<String, Object?>> load() async => {};
  @override
  Future<void> save(Map<String, Object?> values) async {}
}
