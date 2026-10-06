import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/local_history/local_history_controller.dart';
import 'package:busymark/src/local_history/local_history_models.dart';
import 'package:busymark/src/local_history/local_history_store.dart';
import 'package:busymark/src/nextcloud_notes/application/nextcloud_connection.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_repository.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_api_client.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_store.dart';
import 'package:busymark/src/nextcloud_notes/domain/notes_models.dart';
import 'package:busymark/src/workspace/recovery_persistence.dart';
import 'package:busymark/src/workspace/session_persistence.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/workspace/workspace_file_monitor.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;

import 'nextcloud_notes/notes_api_test.dart' show serverNote;

const _accountId = 'ba6d02cd-42fe-4e14-a577-3e2c13822459';

void main() {
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
            await harness.controller.deleteNextcloudNote(first.localId),
            isTrue,
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
        if (deferPersistence)
          documentPersistenceDelayProvider.overrideWithValue(
            const Duration(hours: 1),
          ),
        localSettingsStoreProvider.overrideWithValue(_Settings()),
        localHistoryStoreProvider.overrideWithValue(MemoryLocalHistoryStore()),
        nextcloudNotesRepositoryProvider.overrideWith(
          (ref) async => repository,
        ),
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

  Future<void> dispose() async {
    await controller.flushPersistence();
    await controller.refreshNextcloudNotes();
    container.dispose();
    await repository.dispose();
    await monitor.dispose();
    if (ownsRoot) await root.delete(recursive: true);
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
