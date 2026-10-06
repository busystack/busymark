import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:busymark/src/local_history/local_history_models.dart';
import 'package:busymark/src/local_history/local_history_controller.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:busymark/src/local_history/local_history_store.dart';
import 'package:busymark/src/workspace/text_format_metadata.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late int ids;
  late FileLocalHistoryStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp(
      'busymark-local-history-test-',
    );
    ids = 0;
    store = FileLocalHistoryStore(
      rootDirectory: () async => root,
      createId: () => 'identity_${(++ids).toString().padLeft(12, '0')}',
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  LocalHistoryCaptureRequest request(
    String source,
    DateTime time, {
    String path = '/workspace/guide.md',
    LocalHistoryCaptureReason reason = LocalHistoryCaptureReason.saved,
    bool force = false,
    bool Function()? commitGuard,
  }) => LocalHistoryCaptureRequest(
    path: path,
    displayName: p.basename(path),
    source: source,
    format: TextFormatMetadata.utf8Lf,
    capturedAt: time,
    reason: reason,
    force: force,
    commitGuard: commitGuard,
  );

  const policy = LocalHistoryPolicy(
    retentionAge: Duration(days: 30),
    maximumBytes: 16 * 1024 * 1024,
  );

  for (final memory in [false, true]) {
    test(
      'capture commit guard rejects stale policy (memory=$memory)',
      () async {
        final target = memory ? MemoryLocalHistoryStore() : store;

        await expectLater(
          target.capture(
            request(
              'excluded before commit',
              DateTime.utc(2026, 1, 1),
              commitGuard: () => false,
            ),
            policy,
          ),
          throwsA(isA<LocalHistoryCaptureCancelled>()),
        );

        final snapshot = await target.load();
        expect(snapshot.documents, isEmpty);
        expect(snapshot.revisions, isEmpty);
      },
    );
  }

  test(
    'real process contention waits and captures without a warning',
    () async {
      final holder = await _HistoryProcess.start(root, 'hold', 'holder');
      addTearDown(holder.close);
      await holder.ready();
      final contended = Completer<void>();
      final realStore = FileLocalHistoryStore.testing(
        rootDirectory: () async => root,
        acquireLock: (handle) async {
          try {
            await handle.lock(FileLock.exclusive);
          } on FileSystemException {
            if (!contended.isCompleted) contended.complete();
            rethrow;
          }
        },
      );
      final container = ProviderContainer(
        overrides: [
          localHistoryStoreProvider.overrideWithValue(realStore),
          localSettingsStoreProvider.overrideWithValue(_LockSettingsStore()),
          localHistoryTimerFactoryProvider.overrideWithValue(
            (delay, callback) => Timer(delay, callback),
          ),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      var completed = false;
      final capture = controller
          .observeOpened(
            DocumentBuffer.untitled(
              id: 'contended',
              name: 'Draft.md',
              text: 'retained across contention',
            ),
          )
          .then((_) => completed = true);
      // Drain accepted storage work before the fixture directory is removed,
      // including when a bounded assertion above fails under runner load.
      addTearDown(() async {
        await holder.close();
        await capture;
      });
      await contended.future.timeout(const Duration(seconds: 5));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(completed, isFalse);
      expect(container.read(localHistoryControllerProvider).warning, isNull);
      await holder.release();
      await capture.timeout(const Duration(seconds: 30));
      expect(container.read(localHistoryControllerProvider).warning, isNull);
      final snapshot = await realStore.load();
      expect(snapshot.revisions, hasLength(1));
      expect(
        (await realStore.readRevision(snapshot.revisions.single.id))!.source,
        'retained across contention',
      );
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );

  test(
    'lock timeout closes acquisition and queues recover without late capture',
    () async {
      final holder = await _HistoryProcess.start(root, 'hold', 'timeout');
      addTearDown(holder.close);
      await holder.ready();
      var bodyCalls = 0;
      final handles = <RandomAccessFile>[];
      final timedStore = FileLocalHistoryStore.testing(
        rootDirectory: () async => root,
        lockBudget: const Duration(milliseconds: 60),
        lockDelay: const Duration(milliseconds: 5),
        createId: () => 'timeout_identity_${++bodyCalls}',
        acquireLock: (handle) async {
          if (!handles.contains(handle)) handles.add(handle);
          await handle.lock(FileLock.exclusive);
        },
      );
      await expectLater(
        timedStore.capture(
          request('must never execute', DateTime.utc(2026)),
          policy,
        ),
        throwsA(isA<FileSystemException>()),
      );
      expect(bodyCalls, 0);
      expect(handles, hasLength(1));
      await expectLater(
        handles.single.length(),
        throwsA(isA<FileSystemException>()),
      );
      await holder.release();
      final recovery = timedStore.capture(
        request('later succeeds', DateTime.utc(2026)),
        policy,
      );
      addTearDown(() async => recovery);
      // This includes disk publication under full-suite CPU/IO load, not
      // acquisition waiting; the injected contention budget stays 60ms.
      await recovery.timeout(const Duration(seconds: 30));
      final snapshot = await timedStore.load();
      expect(snapshot.revisions, hasLength(1));
      expect(
        (await timedStore.readRevision(snapshot.revisions.single.id))!.source,
        'later succeeds',
      );
      expect(bodyCalls, greaterThan(0));
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );

  test(
    'non-contention acquisition failure is prompt and closes the handle',
    () async {
      var attempts = 0;
      RandomAccessFile? handle;
      var fail = true;
      final target = FileLocalHistoryStore.testing(
        rootDirectory: () async => root,
        acquireLock: (file) async {
          attempts++;
          handle = file;
          if (fail) {
            throw const FileSystemException(
              'injected permission failure',
              '',
              OSError('', 1),
            );
          }
          await file.lock(FileLock.exclusive);
        },
      );
      final clock = Stopwatch()..start();
      await expectLater(
        target.load(),
        throwsA(
          isA<FileSystemException>().having(
            (e) => e.osError?.errorCode,
            'code',
            1,
          ),
        ),
      );
      expect(clock.elapsed, lessThan(const Duration(seconds: 1)));
      expect(attempts, 1);
      await expectLater(handle!.length(), throwsA(isA<FileSystemException>()));
      fail = false;
      expect((await target.load()).revisions, isEmpty);
    },
  );

  test('body contention-shaped error never replays the transaction', () async {
    var calls = 0;
    var fail = true;
    final target = FileLocalHistoryStore(
      rootDirectory: () async => root,
      createId: () {
        calls++;
        if (fail) {
          throw const FileSystemException('body failure', '', OSError('', 11));
        }
        return 'body_identity_$calls';
      },
    );
    await expectLater(
      target.capture(request('first', DateTime.utc(2026)), policy),
      throwsA(isA<FileSystemException>()),
    );
    expect(calls, 1);
    fail = false;
    await target.capture(request('second', DateTime.utc(2026)), policy);
    expect((await target.load()).revisions, hasLength(1));
    expect(calls, greaterThan(1));
  });

  test(
    'independent production writers preserve both identities and revisions',
    () async {
      final first = await _HistoryProcess.start(root, 'write', 'first');
      addTearDown(first.close);
      final second = await _HistoryProcess.start(root, 'write', 'second');
      addTearDown(second.close);
      await Future.wait([first.ready(), second.ready()]);
      await Future.wait([first.release(), second.release()]);
      final snapshot = await store.load();
      expect(snapshot.documents, hasLength(2));
      expect(snapshot.documents.map((d) => d.id).toSet(), hasLength(2));
      expect(snapshot.warning, isNull);
      expect(snapshot.revisions, hasLength(16));
      for (final owner in ['first', 'second']) {
        final document = snapshot.documents.singleWhere(
          (d) => d.currentPath == '/workspace/$owner.md',
        );
        final revisions = snapshot.revisionsFor(document.id);
        expect(revisions, hasLength(8));
        final sources = await Future.wait(
          revisions.map((r) async => (await store.readRevision(r.id))!.source),
        );
        expect(sources.toSet(), {
          for (var i = 0; i < 8; i++) '$owner revision $i',
        });
      }
      final index =
          jsonDecode(await File(p.join(root.path, 'index.json')).readAsString())
              as Map;
      expect(index['documents'], hasLength(2));
    },
    timeout: const Timeout(Duration(seconds: 120)),
  );

  test(
    'identity-targeted reconciliation cannot mutate process replacements',
    () async {
      final oldRemap = await store.capture(
        request(
          'old remap',
          DateTime.utc(2026),
          path: '/workspace/reconcile-a.md',
        ),
        policy,
      );
      await store.capture(
        request(
          'old delete',
          DateTime.utc(2026),
          path: '/workspace/reconcile-d.md',
        ),
        policy,
      );
      final remapTargets = await store.resolvePathTargets(
        '/workspace/reconcile-a.md',
        recursive: false,
      );
      final deleteTargets = await store.resolvePathTargets(
        '/workspace/reconcile-d.md',
        recursive: false,
      );
      final replacer = await _HistoryProcess.start(
        root,
        'replace-paths',
        'reconciler',
      );
      addTearDown(replacer.close);
      await replacer.ready();
      final replacementIds = (await File(
        '${replacer.signal}.result',
      ).readAsLines()).toSet();
      expect(replacementIds, hasLength(2));

      await expectLater(
        store.reconcilePath(
          LocalHistoryPathReconciliation.remap(
            sourcePath: '/workspace/reconcile-a.md',
            destinationPath: '/workspace/reconcile-b.md',
            targets: remapTargets,
          ),
        ),
        throwsA(isA<LocalHistoryReconciliationConflict>()),
      );
      await store.reconcilePath(
        LocalHistoryPathReconciliation.deletion(
          sourcePath: '/workspace/reconcile-d.md',
          recursive: false,
          targets: deleteTargets,
        ),
      );
      final snapshot = await store.load();
      final replacements = snapshot.documents.where(
        (document) => replacementIds.contains(document.id),
      );
      expect(replacements, hasLength(2));
      expect(
        replacements
            .singleWhere(
              (document) => document.currentPath == '/workspace/reconcile-b.md',
            )
            .deleted,
        isFalse,
      );
      expect(
        replacements
            .singleWhere(
              (document) => document.currentPath == '/workspace/reconcile-d.md',
            )
            .deleted,
        isFalse,
      );
      expect(
        snapshot.documents
            .singleWhere((document) => document.id == oldRemap.document.id)
            .currentPath,
        '/workspace/reconcile-a.md',
      );
      await replacer.release();
    },
    timeout: const Timeout(Duration(seconds: 120)),
  );

  test(
    'identity-targeted reconciliation rejects an intervening process checkpoint',
    () async {
      final original = await store.capture(
        request(
          'original same identity',
          DateTime.utc(2026),
          path: '/workspace/reconcile-same-id.md',
        ),
        policy,
      );
      final targets = await store.resolvePathTargets(
        '/workspace/reconcile-same-id.md',
        recursive: false,
      );
      final replacer = await _HistoryProcess.start(
        root,
        'recapture-id',
        original.document.id,
      );
      addTearDown(replacer.close);
      await replacer.ready();

      await expectLater(
        store.reconcilePath(
          LocalHistoryPathReconciliation.deletion(
            sourcePath: '/workspace/reconcile-same-id.md',
            recursive: false,
            targets: targets,
          ),
        ),
        throwsA(isA<LocalHistoryReconciliationConflict>()),
      );
      final snapshot = await store.load();
      final document = snapshot.documents.singleWhere(
        (candidate) => candidate.id == original.document.id,
      );
      expect(document.deleted, isFalse);
      expect(document.currentPath, '/workspace/reconcile-same-id.md');
      final sources = await Future.wait([
        for (final revision in snapshot.revisionsFor(document.id))
          store.readRevision(revision.id).then((value) => value!.source),
      ]);
      expect(sources, contains('replacement under reused identity'));
    },
    timeout: const Timeout(Duration(seconds: 120)),
  );

  for (final inMemory in [false, true]) {
    test(
      'promotion repair rechecks the stale owner atomically (memory=$inMemory)',
      () async {
        final LocalHistoryStore target = inMemory
            ? MemoryLocalHistoryStore()
            : store;
        final time = DateTime.utc(2026, 1, 1);
        final old = await target.capture(request('Old', time), policy);
        final draft = await target.capture(
          LocalHistoryCaptureRequest(
            displayName: 'Draft',
            source: 'New',
            untitled: true,
            format: TextFormatMetadata.utf8Lf,
            capturedAt: time.add(const Duration(minutes: 1)),
            reason: LocalHistoryCaptureReason.baseline,
          ),
          policy,
        );
        await target.capture(
          request('Another owner update', time.add(const Duration(minutes: 2))),
          policy,
        );
        expect(
          await target.promoteUntitledDocument(
            documentId: draft.document.id,
            destinationPath: '/workspace/guide.md',
            displayName: 'guide.md',
            updatedAt: time.add(const Duration(minutes: 3)),
            staleDestinationOwner: old.document,
          ),
          isNull,
        );
        final snapshot = await target.load();
        expect(
          snapshot.documents
              .singleWhere((d) => d.id == old.document.id)
              .deleted,
          isFalse,
        );
        expect(
          snapshot.documents
              .singleWhere((d) => d.id == draft.document.id)
              .currentPath,
          isNull,
        );
      },
    );
  }

  test(
    'persists full revisions and stable document identity across restart',
    () async {
      final time = DateTime.utc(2026, 1, 1);
      final first = await store.capture(request('A', time), policy);
      final second = await store.capture(
        request('B', time.add(const Duration(minutes: 1))),
        policy,
      );
      final reopened = FileLocalHistoryStore(rootDirectory: () async => root);
      final snapshot = await reopened.load();

      expect(snapshot.documents, hasLength(1));
      expect(snapshot.documents.single.id, first.document.id);
      expect(second.document.id, first.document.id);
      expect(snapshot.revisions, hasLength(2));
      expect((await reopened.readRevision(second.revision!.id))!.source, 'B');
    },
  );

  test(
    'persists untitled first-save promotion without a new revision',
    () async {
      final time = DateTime.utc(2026, 1, 1);
      final untitled = await store.capture(
        LocalHistoryCaptureRequest(
          displayName: 'Draft.md',
          source: 'Draft content',
          format: TextFormatMetadata.utf8Lf,
          capturedAt: time,
          reason: LocalHistoryCaptureReason.baseline,
          untitled: true,
        ),
        policy,
      );

      final promoted = await store.promoteUntitledDocument(
        documentId: untitled.document.id,
        destinationPath: '/workspace/Guide.md',
        displayName: 'Guide.md',
        updatedAt: time.add(const Duration(seconds: 1)),
      );
      expect(promoted?.id, untitled.document.id);

      final reopened = FileLocalHistoryStore(rootDirectory: () async => root);
      var snapshot = await reopened.load();
      expect(snapshot.documents, hasLength(1));
      expect(snapshot.documents.single.id, untitled.document.id);
      expect(snapshot.documents.single.currentPath, '/workspace/Guide.md');
      expect(snapshot.documents.single.untitled, isFalse);
      expect(snapshot.revisions, hasLength(1));

      final later = await reopened.capture(
        LocalHistoryCaptureRequest(
          documentId: untitled.document.id,
          path: '/workspace/Guide.md',
          displayName: 'Guide.md',
          source: 'Named content',
          format: TextFormatMetadata.utf8Lf,
          capturedAt: time.add(const Duration(seconds: 2)),
          reason: LocalHistoryCaptureReason.saved,
        ),
        policy,
      );
      snapshot = await reopened.load();
      expect(later.document.id, untitled.document.id);
      expect(snapshot.documents, hasLength(1));
      expect(snapshot.revisionsFor(untitled.document.id), hasLength(2));
    },
  );

  test(
    'untitled promotion refuses an already-owned destination path',
    () async {
      final time = DateTime.utc(2026, 1, 1);
      final untitled = await store.capture(
        LocalHistoryCaptureRequest(
          displayName: 'Draft.md',
          source: 'Original untitled history',
          format: TextFormatMetadata.utf8Lf,
          capturedAt: time,
          reason: LocalHistoryCaptureReason.baseline,
          untitled: true,
        ),
        policy,
      );
      final destination = await store.capture(
        request(
          'Existing destination history',
          time.add(const Duration(seconds: 1)),
          path: '/workspace/Guide.md',
        ),
        policy,
      );

      expect(
        await store.promoteUntitledDocument(
          documentId: untitled.document.id,
          destinationPath: '/workspace/Guide.md',
          displayName: 'Guide.md',
          updatedAt: time.add(const Duration(seconds: 2)),
        ),
        isNull,
      );

      final snapshot = await store.load();
      expect(snapshot.documents, hasLength(2));
      expect(
        snapshot.documents
            .singleWhere((document) => document.id == untitled.document.id)
            .currentPath,
        isNull,
      );
      expect(
        snapshot.documents
            .singleWhere((document) => document.id == destination.document.id)
            .currentPath,
        '/workspace/Guide.md',
      );
    },
  );

  test('deleted paths never own promotion, lookup, or remap', () async {
    for (final entry in <({String name, LocalHistoryStore store})>[
      (name: 'file', store: store),
      (name: 'memory', store: MemoryLocalHistoryStore()),
    ]) {
      final path = '/workspace/${entry.name}-Note.md';
      final moved = '/archive/${entry.name}-Note.md';
      final time = DateTime.utc(2026, 1, 1);
      final old = await entry.store.capture(
        LocalHistoryCaptureRequest(
          path: path,
          displayName: 'Note.md',
          source: 'old revision',
          format: TextFormatMetadata.utf8Lf,
          capturedAt: time,
          reason: LocalHistoryCaptureReason.saved,
        ),
        policy,
      );
      await entry.store.markDeleted(path, recursive: false);
      final untitled = await entry.store.capture(
        LocalHistoryCaptureRequest(
          displayName: 'Draft.md',
          source: 'new untitled revision',
          format: TextFormatMetadata.utf8Lf,
          capturedAt: time.add(const Duration(seconds: 1)),
          reason: LocalHistoryCaptureReason.automaticCheckpoint,
          untitled: true,
        ),
        policy,
      );
      final promoted = await entry.store.promoteUntitledDocument(
        documentId: untitled.document.id,
        destinationPath: path,
        displayName: 'Note.md',
        updatedAt: time.add(const Duration(seconds: 2)),
      );
      expect(promoted?.id, untitled.document.id, reason: entry.name);

      var snapshot = await entry.store.load();
      final oldDocument = snapshot.documents.singleWhere(
        (document) => document.id == old.document.id,
      );
      final active = snapshot.documents.singleWhere(
        (document) => document.id == untitled.document.id,
      );
      expect(oldDocument.deleted, isTrue, reason: entry.name);
      expect(oldDocument.currentPath, path, reason: entry.name);
      expect(active.deleted, isFalse, reason: entry.name);
      expect(active.currentPath, path, reason: entry.name);
      expect(
        (await entry.store.readRevision(old.revision!.id))?.source,
        'old revision',
        reason: entry.name,
      );

      await entry.store.remapPath(path, moved);
      snapshot = await entry.store.load();
      expect(
        snapshot.documents
            .singleWhere((document) => document.id == old.document.id)
            .currentPath,
        path,
        reason: entry.name,
      );
      expect(
        snapshot.documents
            .singleWhere((document) => document.id == active.id)
            .currentPath,
        moved,
        reason: entry.name,
      );

      await entry.store.markDeleted(moved, recursive: false);
      final reused = await entry.store.capture(
        LocalHistoryCaptureRequest(
          path: moved,
          displayName: 'Note.md',
          source: 'fresh named revision',
          format: TextFormatMetadata.utf8Lf,
          capturedAt: time.add(const Duration(seconds: 3)),
          reason: LocalHistoryCaptureReason.saved,
        ),
        policy,
      );
      expect(reused.document.id, isNot(active.id), reason: entry.name);
    }
  });

  test(
    'deduplicates only adjacent ordinary captures and preserves A-B-A',
    () async {
      final time = DateTime.utc(2026, 1, 1);
      final a = await store.capture(request('A', time), policy);
      final duplicate = await store.capture(
        request('A', time.add(const Duration(seconds: 1))),
        policy,
      );
      await store.capture(
        request('B', time.add(const Duration(seconds: 2))),
        policy,
      );
      await store.capture(
        request('A', time.add(const Duration(seconds: 3))),
        policy,
      );

      expect(duplicate.deduplicated, isTrue);
      expect(duplicate.revision!.id, a.revision!.id);
      expect((await store.load()).revisions, hasLength(3));
    },
  );

  test('forced protective capture preserves an identical revision', () async {
    final time = DateTime.utc(2026, 1, 1);
    await store.capture(request('same', time), policy);
    await store.capture(
      request(
        'same',
        time.add(const Duration(seconds: 1)),
        reason: LocalHistoryCaptureReason.beforeRestore,
        force: true,
      ),
      policy,
    );
    expect((await store.load()).revisions, hasLength(2));
  });

  test('stable capture identity makes a protective retry idempotent', () async {
    final time = DateTime.utc(2026, 1, 1);
    const captureId = 'capture_retry_00000001';
    final first = await store.capture(
      LocalHistoryCaptureRequest(
        path: '/workspace/protected.md',
        displayName: 'protected.md',
        source: 'protected source',
        format: TextFormatMetadata.utf8Lf,
        capturedAt: time,
        reason: LocalHistoryCaptureReason.beforeDiscard,
        force: true,
        captureId: captureId,
      ),
      policy,
    );
    final retry = await store.capture(
      LocalHistoryCaptureRequest(
        documentId: first.document.id,
        path: '/workspace/protected.md',
        displayName: 'protected.md',
        source: 'protected source',
        format: TextFormatMetadata.utf8Lf,
        capturedAt: time.add(const Duration(seconds: 1)),
        reason: LocalHistoryCaptureReason.beforeDiscard,
        force: true,
        captureId: captureId,
      ),
      policy,
    );

    expect(retry.deduplicated, isTrue);
    expect(retry.revision?.id, captureId);
    expect((await store.load()).revisions, hasLength(1));
  });

  test(
    'idempotent capture stays complete after its lineage advances',
    () async {
      for (final entry in <({String name, LocalHistoryStore store})>[
        (name: 'file', store: store),
        (name: 'memory', store: MemoryLocalHistoryStore()),
      ]) {
        final initial = await entry.store.capture(
          request(
            'initial',
            DateTime.utc(2026),
            path: '/workspace/${entry.name}-capture-b.md',
          ),
          policy,
        );
        final target = (await entry.store.resolvePathTargets(
          initial.document.currentPath!,
          recursive: false,
        )).single;
        const captureId = 'advanced_capture_retry_0001';
        final capture = LocalHistoryCaptureRequest(
          documentId: initial.document.id,
          path: initial.document.currentPath,
          displayName: '${entry.name}-capture-b.md',
          source: 'durably captured',
          format: TextFormatMetadata.utf8Lf,
          capturedAt: DateTime.utc(2026, 1, 2),
          reason: LocalHistoryCaptureReason.saved,
          captureId: captureId,
          expectedTarget: target,
        );
        await entry.store.capture(capture, policy);
        await entry.store.remapPath(
          initial.document.currentPath!,
          '/workspace/${entry.name}-capture-c.md',
        );

        final retried = await entry.store.capture(capture, policy);
        expect(retried.deduplicated, isTrue, reason: entry.name);
        expect(retried.revision?.id, captureId, reason: entry.name);
      }
    },
  );

  test('promotion retry accepts the same lineage after a later move', () async {
    for (final entry in <({String name, LocalHistoryStore store})>[
      (name: 'file', store: store),
      (name: 'memory', store: MemoryLocalHistoryStore()),
    ]) {
      final draft = await entry.store.capture(
        LocalHistoryCaptureRequest(
          displayName: 'Draft.md',
          source: 'draft',
          format: TextFormatMetadata.utf8Lf,
          capturedAt: DateTime.utc(2026),
          reason: LocalHistoryCaptureReason.baseline,
          untitled: true,
        ),
        policy,
      );
      final firstPath = '/workspace/${entry.name}-promoted-b.md';
      final laterPath = '/workspace/${entry.name}-promoted-c.md';
      await entry.store.promoteUntitledDocument(
        documentId: draft.document.id,
        destinationPath: firstPath,
        displayName: p.basename(firstPath),
        updatedAt: DateTime.utc(2026, 1, 2),
      );
      await entry.store.remapPath(firstPath, laterPath);

      final retried = await entry.store.promoteUntitledDocument(
        documentId: draft.document.id,
        destinationPath: firstPath,
        displayName: p.basename(firstPath),
        updatedAt: DateTime.utc(2026, 1, 3),
      );
      expect(retried?.id, draft.document.id, reason: entry.name);
      expect(retried?.currentPath, laterPath, reason: entry.name);
    }
  });

  test(
    'atomic path preflight accepts the same target already reconciled elsewhere',
    () async {
      for (final entry in <({String name, LocalHistoryStore store})>[
        (name: 'file', store: store),
        (name: 'memory', store: MemoryLocalHistoryStore()),
      ]) {
        final source = '/workspace/${entry.name}-concurrent-a.md';
        final destination = '/workspace/${entry.name}-concurrent-b.md';
        await entry.store.capture(
          request('shared lineage', DateTime.utc(2026), path: source),
          policy,
        );
        final targets = await entry.store.resolvePathTargets(
          source,
          recursive: false,
        );
        Future<bool> apply() => entry.store.runPathReconciliation(
          kind: LocalHistoryPathReconciliationKind.remap,
          sourcePath: source,
          destinationPath: destination,
          recursive: false,
          preparedTargets: targets,
          operation: (_) async => true,
          didCommit: (value) => value,
        );

        expect(await apply(), isTrue, reason: entry.name);
        expect(await apply(), isTrue, reason: entry.name);
        final snapshot = await entry.store.load();
        expect(snapshot.documents.single.currentPath, destination);
      }
    },
  );

  test(
    'clearing one identity does not poison another identity capture',
    () async {
      final first = await store.capture(
        request('first', DateTime.utc(2026), path: '/workspace/first.md'),
        policy,
      );
      final second = await store.capture(
        request('second', DateTime.utc(2026), path: '/workspace/second.md'),
        policy,
      );
      final clearer = FileLocalHistoryStore(rootDirectory: () async => root);
      await clearer.clearDocument(first.document.id);

      await store.capture(
        LocalHistoryCaptureRequest(
          documentId: second.document.id,
          path: '/workspace/second.md',
          displayName: 'second.md',
          source: 'second after unrelated clear',
          format: TextFormatMetadata.utf8Lf,
          capturedAt: DateTime.utc(2026, 1, 2),
          reason: LocalHistoryCaptureReason.saved,
        ),
        policy,
      );

      final snapshot = await store.load();
      expect(snapshot.documents.map((document) => document.id), [
        second.document.id,
      ]);
      final sources = <String?>[
        for (final revision in snapshot.revisions)
          (await store.readRevision(revision.id))?.source,
      ];
      expect(sources, contains('second after unrelated clear'));
    },
  );

  test(
    'repairs a damaged index from intact independently checksummed records',
    () async {
      final result = await store.capture(
        request('recover me', DateTime.utc(2026, 1, 1)),
        policy,
      );
      await File(p.join(root.path, 'index.json')).writeAsString('{damaged');

      final snapshot = await store.load();

      expect(snapshot.warning, isNotNull);
      expect(snapshot.revisions.single.id, result.revision!.id);
      expect(
        (await store.readRevision(result.revision!.id))!.source,
        'recover me',
      );
    },
  );

  test(
    'repair rejects a record associated with a different document',
    () async {
      final result = await store.capture(
        request('unaltered source', DateTime.utc(2026, 1, 1)),
        policy,
      );
      final revisionFile = File(
        p.join(
          root.path,
          'revisions',
          result.document.id,
          '${result.revision!.id}.json',
        ),
      );
      final record = (jsonDecode(await revisionFile.readAsString()) as Map)
          .cast<String, Object?>();
      final revision = (record['revision'] as Map).cast<String, Object?>();
      revision['documentId'] = 'identity_999999999999';
      record['revision'] = revision;
      await revisionFile.writeAsString(jsonEncode(record));
      await File(p.join(root.path, 'index.json')).writeAsString('{damaged');

      final snapshot = await store.load();

      expect(snapshot.documents, isEmpty);
      expect(snapshot.revisions, isEmpty);
    },
  );

  test(
    'does not resurrect explicitly cleared revisions during repair',
    () async {
      final result = await store.capture(
        request('remove me', DateTime.utc(2026, 1, 1)),
        policy,
      );
      final revisionFile = File(
        p.join(
          root.path,
          'revisions',
          result.document.id,
          '${result.revision!.id}.json',
        ),
      );
      final retainedBytes = await revisionFile.readAsBytes();
      await store.clearDocument(result.document.id);
      await revisionFile.parent.create(recursive: true);
      await revisionFile.writeAsBytes(retainedBytes);
      await File(p.join(root.path, 'index.json')).writeAsString('{damaged');

      final snapshot = await store.load();
      expect(snapshot.revisions, isEmpty);
      expect(snapshot.documents, isEmpty);
    },
  );

  test('rejects an unknown future index format without rewriting it', () async {
    final file = File(p.join(root.path, 'index.json'));
    await file.writeAsString(jsonEncode({'version': 999}));

    await expectLater(
      store.load(),
      throwsA(isA<UnsupportedLocalHistoryFormat>()),
    );
    expect(jsonDecode(await file.readAsString()), {'version': 999});
  });

  test(
    'age retention uses the injected capture time deterministically',
    () async {
      final old = DateTime.utc(2020, 1, 1);
      await store.capture(request('old', old), policy);
      await store.capture(
        request('new', old.add(const Duration(days: 31))),
        policy,
      );

      final revisions = (await store.load()).revisions;
      expect(revisions, hasLength(1));
      expect((await store.readRevision(revisions.single.id))!.source, 'new');
    },
  );

  test('age retention is enforced when an idle store is reopened', () async {
    await store.capture(request('expired', DateTime.utc(2020, 1, 1)), policy);

    await store.prune(policy, DateTime.utc(2020, 2, 1));

    final snapshot = await store.load();
    expect(snapshot.revisions, isEmpty);
    expect(snapshot.documents, isEmpty);
  });

  test(
    'rename, directory move, delete, and per-document clearing retain lineage',
    () async {
      final result = await store.capture(
        request('text', DateTime.utc(2026, 1, 1), path: '/old/docs/a.md'),
        policy,
      );
      await store.remapPath('/old', '/new');
      var document = (await store.load()).documents.single;
      expect(document.currentPath, '/new/docs/a.md');
      expect(document.historicalPaths, contains('/old/docs/a.md'));
      await store.markDeleted('/new/docs', recursive: true);
      document = (await store.load()).documents.single;
      expect(document.deleted, isTrue);
      await store.clearDocument(result.document.id);
      expect((await store.load()).documents, isEmpty);
    },
  );

  test('ID-bound captures cannot implicitly move document paths', () async {
    final first = await store.capture(
      request('before move', DateTime.utc(2026, 1, 1), path: '/old/A.md'),
      policy,
    );
    await store.remapPath('/old/A.md', '/new/B.md');

    final lateCheckpoint = await store.capture(
      LocalHistoryCaptureRequest(
        documentId: first.document.id,
        path: '/old/A.md',
        displayName: 'A.md',
        source: 'edit queued before remap completed',
        format: TextFormatMetadata.utf8Lf,
        capturedAt: DateTime.utc(2026, 1, 1, 0, 1),
        reason: LocalHistoryCaptureReason.automaticCheckpoint,
      ),
      policy,
    );

    final snapshot = await store.load();
    expect(snapshot.documents, hasLength(1));
    expect(snapshot.documents.single.currentPath, '/new/B.md');
    expect(lateCheckpoint.document.currentPath, '/new/B.md');
    expect(lateCheckpoint.revision!.historicalPath, '/new/B.md');
  });

  test('serializes concurrent captures without losing index entries', () async {
    final time = DateTime.utc(2026, 1, 1);
    await Future.wait([
      for (var index = 0; index < 12; index++)
        store.capture(
          request('version $index', time.add(Duration(seconds: index))),
          policy,
        ),
    ]);
    expect((await store.load()).revisions, hasLength(12));
  });

  test('oversized capture cannot evict the previous revision', () async {
    final smallPolicy = LocalHistoryPolicy(
      maximumBytes: 16 * 1024 * 1024,
      retentionAge: const Duration(days: 30),
    );
    await store.capture(request('safe', DateTime.utc(2026, 1, 1)), smallPolicy);
    final huge = List.filled(17 * 1024 * 1024, 65);

    await expectLater(
      store.capture(
        request(utf8.decode(huge), DateTime.utc(2026, 1, 2)),
        smallPolicy,
      ),
      throwsA(isA<LocalHistoryStorageException>()),
    );
    final revision = (await store.load()).revisions.single;
    expect((await store.readRevision(revision.id))!.source, 'safe');
  });

  test(
    'different paths with the same basename keep separate identities',
    () async {
      final time = DateTime.utc(2026, 1, 1);
      final first = await store.capture(
        request('first', time, path: '/one/readme.md'),
        policy,
      );
      final second = await store.capture(
        request('second', time, path: '/two/readme.md'),
        policy,
      );

      expect(first.document.id, isNot(second.document.id));
      expect((await store.load()).documents, hasLength(2));
    },
  );

  test('an intentional empty revision after content is retained', () async {
    final time = DateTime.utc(2026, 1, 1);
    await store.capture(request('content', time), policy);
    final emptied = await store.capture(
      request('', time.add(const Duration(seconds: 1))),
      policy,
    );

    expect((await store.load()).revisions, hasLength(2));
    expect((await store.readRevision(emptied.revision!.id))!.source, isEmpty);
  });

  test(
    'missing and corrupt revision records do not damage intact entries',
    () async {
      final time = DateTime.utc(2026, 1, 1);
      final first = await store.capture(request('first', time), policy);
      final second = await store.capture(
        request('second', time.add(const Duration(seconds: 1))),
        policy,
      );
      final firstFile = File(
        p.join(
          root.path,
          'revisions',
          first.document.id,
          '${first.revision!.id}.json',
        ),
      );
      await firstFile.delete();
      final secondFile = File(
        p.join(
          root.path,
          'revisions',
          second.document.id,
          '${second.revision!.id}.json',
        ),
      );
      await secondFile.writeAsString('{corrupt');

      expect(await store.readRevision(first.revision!.id), isNull);
      expect(await store.readRevision(second.revision!.id), isNull);
      expect((await store.load()).documents, hasLength(1));
    },
  );

  test(
    'incomplete staging artifacts are never discovered as revisions',
    () async {
      await store.capture(
        request('complete', DateTime.utc(2026, 1, 1)),
        policy,
      );
      final artifact = File(
        p.join(
          root.path,
          'revisions',
          'escaped_identity',
          'partial.json.staging',
        ),
      );
      await artifact.parent.create(recursive: true);
      await artifact.writeAsString('{"source":"partial"}');
      await File(p.join(root.path, 'index.json')).writeAsString('{damaged');

      final repaired = await store.load();
      expect(repaired.revisions, hasLength(1));
      expect(
        (await store.readRevision(repaired.revisions.single.id))!.source,
        'complete',
      );
    },
  );

  test('global clear tombstones prevent repair resurrection', () async {
    final result = await store.capture(
      request('remove globally', DateTime.utc(2026, 1, 1)),
      policy,
    );
    final revisionFile = File(
      p.join(
        root.path,
        'revisions',
        result.document.id,
        '${result.revision!.id}.json',
      ),
    );
    final retainedBytes = await revisionFile.readAsBytes();
    await store.clearAll();
    await revisionFile.parent.create(recursive: true);
    await revisionFile.writeAsBytes(retainedBytes);
    await File(p.join(root.path, 'index.json')).writeAsString('{damaged');

    final repaired = await store.load();
    expect(repaired.documents, isEmpty);
    expect(repaired.revisions, isEmpty);
  });

  test('durable Clear All replay cannot erase post-clear history', () async {
    const operationId = 'clear_operation_00000001';
    await store.capture(
      request('before clear', DateTime.utc(2026, 1, 1)),
      policy,
    );
    await store.clearAllOnce(operationId: operationId);
    final replacement = await store.capture(
      request(
        'after clear',
        DateTime.utc(2026, 1, 2),
        path: '/workspace/replacement.md',
      ),
      policy,
    );

    final reopened = FileLocalHistoryStore(
      rootDirectory: () async => root,
      createId: () => 'reopened_${(++ids).toString().padLeft(12, '0')}',
    );
    await reopened.clearAllOnce(operationId: operationId);

    final snapshot = await reopened.load();
    expect(snapshot.documents, hasLength(1));
    expect(snapshot.documents.single.id, replacement.document.id);
    expect(
      (await reopened.readRevision(snapshot.revisions.single.id))?.source,
      'after clear',
    );
  });

  test(
    'durable Clear Document replay cannot erase replacement history',
    () async {
      const operationId = 'clear_document_operation_01';
      final original = await store.capture(
        request('original', DateTime.utc(2026, 1, 1)),
        policy,
      );
      await store.clearDocumentOnce(
        operationId: operationId,
        documentId: original.document.id,
      );
      final replacement = await store.capture(
        request('replacement', DateTime.utc(2026, 1, 2)),
        policy,
      );

      final reopened = FileLocalHistoryStore(rootDirectory: () async => root);
      await reopened.clearDocumentOnce(
        operationId: operationId,
        documentId: original.document.id,
      );

      final snapshot = await reopened.load();
      expect(snapshot.documents, hasLength(1));
      expect(snapshot.documents.single.id, replacement.document.id);
    },
  );

  for (final memory in [false, true]) {
    test('clear barrier rejects accepted pathless work from its lineage '
        '(memory=$memory)', () async {
      final targetStore = memory ? MemoryLocalHistoryStore() : store;
      final original = await targetStore.capture(
        LocalHistoryCaptureRequest(
          displayName: 'Untitled',
          source: 'before clear',
          format: TextFormatMetadata.utf8Lf,
          capturedAt: DateTime.utc(2026, 1, 1),
          reason: LocalHistoryCaptureReason.baseline,
          untitled: true,
        ),
        policy,
      );
      final acceptedEpoch = (await targetStore.load()).clearEpoch;
      final acceptedAt = DateTime.now().toUtc();
      await targetStore.clearDocument(original.document.id);

      await expectLater(
        targetStore.capture(
          LocalHistoryCaptureRequest(
            displayName: 'Untitled',
            source: 'queued during clear',
            format: TextFormatMetadata.utf8Lf,
            capturedAt: DateTime.utc(2026, 1, 2),
            reason: LocalHistoryCaptureReason.automaticCheckpoint,
            untitled: true,
            acceptedClearEpoch: acceptedEpoch,
            acceptedAt: acceptedAt,
            acceptedDocumentId: original.document.id,
          ),
          policy,
        ),
        throwsA(isA<LocalHistoryClearConflict>()),
      );
      expect((await targetStore.load()).documents, isEmpty);
    });

    test('clear barrier retains a deleted document path without a replacement '
        '(memory=$memory)', () async {
      final targetStore = memory ? MemoryLocalHistoryStore() : store;
      const path = '/workspace/deleted.md';
      final original = await targetStore.capture(
        request('before deletion', DateTime.utc(2026, 1, 1), path: path),
        policy,
      );
      final acceptedEpoch = (await targetStore.load()).clearEpoch;
      final acceptedAt = DateTime.now().toUtc();
      final targets = await targetStore.resolvePathTargets(
        path,
        recursive: false,
      );
      await targetStore.reconcilePath(
        LocalHistoryPathReconciliation.deletion(
          sourcePath: path,
          recursive: false,
          targets: targets,
        ),
      );
      await targetStore.clearDocument(original.document.id);

      await expectLater(
        targetStore.capture(
          LocalHistoryCaptureRequest(
            path: path,
            displayName: 'deleted.md',
            source: 'stale queued work',
            format: TextFormatMetadata.utf8Lf,
            capturedAt: DateTime.utc(2026, 1, 2),
            reason: LocalHistoryCaptureReason.automaticCheckpoint,
            acceptedClearEpoch: acceptedEpoch,
            acceptedAt: acceptedAt,
          ),
          policy,
        ),
        throwsA(isA<LocalHistoryClearConflict>()),
      );
      expect((await targetStore.load()).documents, isEmpty);
    });
  }

  for (final memory in [false, true]) {
    test('stable capture replay resolves identity before path checks '
        '(memory=$memory)', () async {
      final targetStore = memory ? MemoryLocalHistoryStore() : store;
      const captureId = 'capture_operation_000001';
      final original = await targetStore.capture(
        LocalHistoryCaptureRequest(
          path: '/workspace/source.md',
          displayName: 'source.md',
          source: 'fork source',
          format: TextFormatMetadata.utf8Lf,
          capturedAt: DateTime.utc(2026, 1, 1),
          reason: LocalHistoryCaptureReason.automaticCheckpoint,
          force: true,
          createDetachedLineage: true,
          captureId: captureId,
        ),
        policy,
      );
      await targetStore.capture(
        request(
          'replacement owner',
          DateTime.utc(2026, 1, 2),
          path: '/workspace/source.md',
        ),
        policy,
      );

      final replay = await targetStore.capture(
        LocalHistoryCaptureRequest(
          path: '/workspace/source.md',
          displayName: 'source.md',
          source: 'fork source',
          format: TextFormatMetadata.utf8Lf,
          capturedAt: DateTime.utc(2026, 1, 1),
          reason: LocalHistoryCaptureReason.automaticCheckpoint,
          force: true,
          requireVacantPath: true,
          createDetachedLineage: true,
          captureId: captureId,
        ),
        policy,
      );

      expect(replay.deduplicated, isTrue);
      expect(replay.document.id, original.document.id);
      final snapshot = await targetStore.load();
      expect(
        snapshot.revisions.where((revision) => revision.id == captureId),
        hasLength(1),
      );
    });
  }

  test(
    'file capture rolls back cancellation during revision publication',
    () async {
      var guardChecks = 0;

      await expectLater(
        store.capture(
          request(
            'cancel during revision publication',
            DateTime.utc(2026, 1, 1),
            commitGuard: () => ++guardChecks < 3,
          ),
          policy,
        ),
        throwsA(isA<LocalHistoryCaptureCancelled>()),
      );

      final reopened = FileLocalHistoryStore(rootDirectory: () async => root);
      final snapshot = await reopened.load();
      expect(snapshot.documents, isEmpty);
      expect(snapshot.revisions, isEmpty);
    },
  );

  test(
    'file dedup capture rolls back cancellation during index publication',
    () async {
      final initial = await store.capture(
        request('same source', DateTime.utc(2026, 1, 1)),
        policy,
      );
      var guardChecks = 0;

      await expectLater(
        store.capture(
          LocalHistoryCaptureRequest(
            documentId: initial.document.id,
            path: '/workspace/guide.md',
            displayName: 'Changed.md',
            source: 'same source',
            format: TextFormatMetadata.utf8Lf,
            capturedAt: DateTime.utc(2026, 1, 1, 0, 1),
            reason: LocalHistoryCaptureReason.saved,
            commitGuard: () => ++guardChecks < 3,
          ),
          policy,
        ),
        throwsA(isA<LocalHistoryCaptureCancelled>()),
      );

      final reopened = FileLocalHistoryStore(rootDirectory: () async => root);
      final snapshot = await reopened.load();
      expect(snapshot.documents.single.displayName, 'guide.md');
      expect(snapshot.revisions, hasLength(1));
    },
  );

  test(
    'multiple store instances coordinate concurrent index publication',
    () async {
      var sharedIds = 1000;
      String createSharedId() =>
          'shared_${(++sharedIds).toString().padLeft(12, '0')}';
      final firstStore = FileLocalHistoryStore(
        rootDirectory: () async => root,
        createId: createSharedId,
      );
      final secondStore = FileLocalHistoryStore(
        rootDirectory: () async => root,
        createId: createSharedId,
      );
      final time = DateTime.utc(2026, 1, 1);

      await Future.wait([
        firstStore.capture(request('one', time, path: '/one.md'), policy),
        secondStore.capture(request('two', time, path: '/two.md'), policy),
      ]);

      final snapshot = await firstStore.load();
      expect(snapshot.documents, hasLength(2));
      expect(snapshot.revisions, hasLength(2));
    },
  );

  test(
    'storage permission failures surface without touching document data',
    () async {
      final unavailable = FileLocalHistoryStore(
        rootDirectory: () async =>
            throw const FileSystemException('permission denied'),
      );

      await expectLater(
        unavailable.capture(
          request('never stored', DateTime.utc(2026, 1, 1)),
          policy,
        ),
        throwsA(isA<FileSystemException>()),
      );
      expect((await store.load()).revisions, isEmpty);
    },
  );

  test('path exclusions use injected Windows path semantics', () {
    final windows = p.Context(style: p.Style.windows, current: r'C:\workspace');
    final windowsPolicy = LocalHistoryPolicy(
      excludedPaths: const [r'C:\workspace\private'],
      pathContext: windows,
    );

    expect(windowsPolicy.excludes(r'c:\WORKSPACE\PRIVATE\secret.md'), isTrue);
    expect(windowsPolicy.excludes(r'C:\workspace\public\guide.md'), isFalse);
  });
}

class _LockSettingsStore implements LocalSettingsStore {
  @override
  Future<Map<String, Object?>> load() async => {};
  @override
  Future<void> save(Map<String, Object?> json) async {}
}

class _HistoryProcess {
  _HistoryProcess(this.process, this.signal, this.output);
  final Process process;
  final String signal;
  final Future<List<String>> output;
  bool exited = false;

  static Future<_HistoryProcess> start(
    Directory root,
    String mode,
    String owner,
  ) async {
    final config =
        jsonDecode(await File('.dart_tool/package_config.json').readAsString())
            as Map;
    final packages = config['packages'] as List;
    final flutter = packages.cast<Map>().singleWhere(
      (entry) => entry['name'] == 'flutter',
    );
    final packageRoot = File(
      '.dart_tool/package_config.json',
    ).absolute.uri.resolve(flutter['rootUri'] as String).toFilePath();
    final sdk = p.dirname(p.dirname(p.normalize(packageRoot)));
    final signal = p.join(root.path, 'process-$owner');
    final process = await Process.start(
      p.join(
        sdk,
        'bin',
        'cache',
        'dart-sdk',
        'bin',
        Platform.isWindows ? 'dart.exe' : 'dart',
      ),
      [
        p.join(sdk, 'bin', 'cache', 'flutter_tools.snapshot'),
        'test',
        '--no-pub',
        '--concurrency=1',
        '--reporter=expanded',
        'test/support/local_history_store_process.dart',
      ],
      workingDirectory: Directory.current.path,
      environment: {
        'BUSYMARK_HISTORY_PROCESS_ROOT': root.path,
        'BUSYMARK_HISTORY_PROCESS_SIGNAL': signal,
        'BUSYMARK_HISTORY_PROCESS_MODE': mode,
        'BUSYMARK_HISTORY_PROCESS_OWNER': owner,
      },
    );
    final output = Future.wait([
      process.stdout.transform(utf8.decoder).join(),
      process.stderr.transform(utf8.decoder).join(),
    ]);
    return _HistoryProcess(process, signal, output);
  }

  Future<void> ready() async {
    final deadline = Stopwatch()..start();
    while (!await File('$signal.ready').exists()) {
      if (deadline.elapsed > const Duration(seconds: 60)) {
        throw TimeoutException('History child was not ready');
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  Future<void> release() async {
    await File('$signal.release').writeAsString('release');
    final code = await process.exitCode.timeout(const Duration(seconds: 30));
    exited = true;
    expect(code, 0, reason: (await output).join('\n'));
  }

  Future<void> close() async {
    if (exited) return;
    await File('$signal.release').writeAsString('cleanup');
    try {
      await process.exitCode.timeout(const Duration(seconds: 10));
    } on TimeoutException {
      // Only this helper's recorded runtime and launcher are targets.
      final pidFile = File('$signal.pid');
      if (await pidFile.exists()) {
        Process.killPid(int.parse(await pidFile.readAsString()));
      }
      process.kill();
      await process.exitCode.timeout(const Duration(seconds: 5));
    }
    await output;
    exited = true;
  }
}
