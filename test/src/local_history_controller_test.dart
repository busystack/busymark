import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/local_history/local_history_controller.dart';
import 'package:busymark/src/local_history/local_history_models.dart';
import 'package:busymark/src/local_history/local_history_panel.dart';
import 'package:busymark/src/local_history/local_history_store.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:busymark/src/workspace/recovery_persistence.dart';
import 'package:busymark/src/workspace/session_persistence.dart';
import 'package:busymark/src/workspace/text_format_metadata.dart';
import 'package:busymark/src/workspace/workspace_file_snapshot.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:path/path.dart' as p;

void main() {
  test(
    'failed opened baseline retries its original source without an edit',
    () async {
      final store = _RepairStore()
        ..captureErrors['original'] = StateError('offline');
      final timers = <_FakeTimer>[];
      final container = _historyContainer(store, timers);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final opened = _fileBuffer(
        'baseline',
        '/workspace/baseline.md',
        'original',
      );
      await controller.observeOpened(opened);
      expect(await controller.flushBuffer(opened), isFalse);
      expect(await controller.flushAll([]), isFalse);
      expect(
        controller.warningForBuffer(opened.id)?.kind,
        LocalHistoryWarningKind.capture,
      );
      store.captureErrors.clear();
      timers.lastWhere((timer) => timer.isActive).fire();
      await _waitForHistory(container, (_) => store.commits.length == 1);
      expect(await controller.flushAll([]), isTrue);
      expect(store.commits.single.source, 'original');
      expect(store.commits.single.reason, LocalHistoryCaptureReason.baseline);
      expect(controller.warningForBuffer(opened.id), isNull);
    },
  );

  test(
    'baseline before edit preserves original and coalesces latest edit',
    () async {
      final store = _RepairStore()
        ..captureErrors['original'] = StateError('offline');
      final timers = <_FakeTimer>[];
      final container = _historyContainer(store, timers);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final original = _fileBuffer(
        'edited-baseline',
        '/workspace/edited.md',
        'original',
      );
      final first = original.edited('intermediate');
      final latest = first.edited('latest');
      controller.observeEdit(original, first);
      controller.observeEdit(first, latest);
      expect(await controller.flushBuffer(latest), isFalse);
      expect(controller.pendingSnapshotForBuffer(latest.id)?.text, 'latest');
      store.captureErrors.clear();
      timers.lastWhere((timer) => timer.isActive).fire();
      await _waitForHistory(container, (_) => store.commits.length == 2);
      expect(await controller.flushBuffer(latest), isTrue);
      expect(store.commits.map((request) => (request.reason, request.source)), [
        (LocalHistoryCaptureReason.baseline, 'original'),
        (LocalHistoryCaptureReason.automaticCheckpoint, 'latest'),
      ]);
    },
  );

  test(
    'closed failures keep ownership and stale settlement cannot drop newer work',
    () async {
      final store = _RepairStore()
        ..captureErrors['old source'] = StateError('offline');
      final timers = <_FakeTimer>[];
      final container = _historyContainer(store, timers);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final old = _fileBuffer('closed', '/workspace/old.md', 'old source');
      await controller.observeOpened(old);
      await controller.handleBufferClosed(old.id, historySettled: true);
      final fresh = DocumentBuffer.untitled(id: 'new', name: 'New.md');
      await controller.selectDocumentForBuffer(fresh);
      expect(controller.warningForBuffer(fresh.id), isNull);
      expect(
        container
            .read(localHistoryControllerProvider)
            .warning
            ?.ownerDisplayName,
        '/workspace/old.md',
      );
      expect(await controller.flushAll([fresh]), isFalse);
      store.captureErrors.clear();
      timers.lastWhere((timer) => timer.isActive).fire();
      await _waitForHistory(container, (_) => store.commits.isNotEmpty);
      expect(await controller.flushAll([fresh]), isTrue);
      expect(container.read(localHistoryControllerProvider).warning, isNull);
      expect(store.commits.single.source, 'old source');

      final settled = _fileBuffer('settled', '/workspace/settled.md', 'base');
      await controller.observeOpened(settled);
      expect(await controller.flushBuffer(settled), isTrue);
      final changed = settled.edited('new accepted source');
      controller.observeEdit(settled, changed);
      await controller.handleBufferClosed(settled.id, historySettled: true);
      expect(await controller.flushAll([]), isTrue);
      expect(
        store.commits.map((r) => r.source),
        contains('new accepted source'),
      );
    },
  );

  test(
    'committed protective capture survives refresh failure without recapture',
    () async {
      final store = _RepairStore();
      final timers = <_FakeTimer>[];
      final container = _historyContainer(store, timers);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final opened = _fileBuffer(
        'protected',
        '/workspace/protected.md',
        'base',
      );
      await controller.selectDocumentForBuffer(opened);
      final previous = container.read(localHistoryControllerProvider).snapshot;
      final changed = opened.edited('precious');
      controller.observeEdit(opened, changed);
      await Future<void>.delayed(Duration.zero);
      store.failRefreshAfterCapture = true;
      expect(
        await controller.captureBeforeLoss(
          LocalHistoryBufferSnapshot.fromBuffer(changed),
          LocalHistoryCaptureReason.beforeDiscard,
        ),
        isTrue,
      );
      expect(store.commits.where((r) => r.force), hasLength(1));
      expect(
        container.read(localHistoryControllerProvider).snapshot,
        same(previous),
      );
      expect(
        container.read(localHistoryControllerProvider).warning?.kind,
        LocalHistoryWarningKind.unavailable,
      );
      expect(controller.pendingSnapshotForBuffer(changed.id), isNull);
      expect(await controller.flushBuffer(changed), isTrue);
      expect(await controller.flushAll([]), isTrue);
      await controller.refresh();
      expect(container.read(localHistoryControllerProvider).warning, isNull);
      expect(store.commits.where((r) => r.force), hasLength(1));
      final snapshot = await store.load();
      expect(
        await _revisionSources(store, snapshot.revisions),
        contains('precious'),
      );
    },
  );

  test(
    'protective authorization is invalidated while committed refresh awaits',
    () async {
      for (final cancellation in ['disable', 'exclude', 'clear', 'dispose']) {
        final store = _RepairStore();
        final container = _historyContainer(store, <_FakeTimer>[]);
        final controller = container.read(
          localHistoryControllerProvider.notifier,
        );
        await Future<void>.delayed(Duration.zero);
        final opened = _fileBuffer(
          'awaiting',
          '/workspace/awaiting.md',
          'base',
        );
        await controller.observeOpened(opened);
        store.blockRefreshAfterCapture = true;
        final protecting = controller.captureBeforeLoss(
          LocalHistoryBufferSnapshot.fromBuffer(opened.edited('precious')),
          LocalHistoryCaptureReason.beforeDiscard,
        );
        await store.refreshEntered.future;
        Future<void>? clearing;
        switch (cancellation) {
          case 'disable':
            await container
                .read(appSettingsControllerProvider.notifier)
                .setLocalHistoryRecordingEnabled(false);
          case 'exclude':
            await container
                .read(appSettingsControllerProvider.notifier)
                .setLocalHistoryExcludedPaths(['/workspace']);
          case 'clear':
            clearing = controller.clearAll();
          case 'dispose':
            container.dispose();
        }
        store.releaseRefresh.complete();
        expect(await protecting, isFalse, reason: cancellation);
        if (clearing != null) await clearing;
        expect(store.commits.where((r) => r.force), hasLength(1));
        if (cancellation != 'dispose') {
          expect(controller.pendingSnapshotForBuffer(opened.id), isNull);
          container.dispose();
        }
      }
    },
  );

  for (final cancellation in ['disable', 'exclude']) {
    test(
      '$cancellation cancels an in-flight baseline at the store boundary',
      () async {
        final memory = MemoryLocalHistoryStore();
        final store = _BlockingNextCaptureStore(memory)
          ..blockNextCapture = true;
        final container = _historyContainer(store, <_FakeTimer>[]);
        addTearDown(container.dispose);
        final controller = container.read(
          localHistoryControllerProvider.notifier,
        );
        final settings = container.read(appSettingsControllerProvider.notifier);
        await Future<void>.delayed(Duration.zero);
        final opened = _fileBuffer(
          'policy-cancelled',
          '/workspace/policy-cancelled.md',
          'must not be retained',
        );

        final observing = controller.observeOpened(opened);
        await store.captureStarted.future;
        if (cancellation == 'disable') {
          await settings.setLocalHistoryRecordingEnabled(false);
        } else {
          await settings.setLocalHistoryExcludedPaths(['/workspace']);
        }
        store.releaseCapture.complete();
        await observing;

        final snapshot = await memory.load();
        expect(snapshot.documents, isEmpty, reason: cancellation);
        expect(snapshot.revisions, isEmpty, reason: cancellation);
        expect(controller.pendingSnapshotForBuffer(opened.id), isNull);
        expect(controller.warningForBuffer(opened.id), isNull);
      },
    );
  }

  test('committed promotion stays associated when refresh fails', () async {
    final store = _RepairStore();
    final container = _historyContainer(store, <_FakeTimer>[]);
    addTearDown(container.dispose);
    final controller = container.read(localHistoryControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    final draft = DocumentBuffer.untitled(
      id: 'promotion-refresh',
      name: 'Draft.md',
      text: 'saved source',
    );
    await controller.observeOpened(draft);
    final id = controller.documentIdForBuffer(draft.id);
    store.failRefreshAfterPromotion = true;
    controller.restorePendingIdentityPromotion(
      LocalHistoryPendingIdentityPromotion(
        bufferId: draft.id,
        documentId: id!,
        destinationPath: '/workspace/saved.md',
        displayName: 'saved.md',
      ),
    );
    expect(await controller.flushPendingIdentityPromotions(), isTrue);
    expect(controller.hasPendingIdentityPromotion(draft.id), isFalse);
    expect(controller.documentIdForBuffer(draft.id), id);
    expect(store.promotions, 1);
    expect(
      container.read(localHistoryControllerProvider).warning?.kind,
      LocalHistoryWarningKind.unavailable,
    );
    expect(store.commits, hasLength(1));
    expect(await controller.flushAll([]), isTrue);
    await controller.refresh();
    expect(store.promotions, 1);
    expect(
      (await store.load()).documents.single.currentPath,
      '/workspace/saved.md',
    );
    expect(container.read(localHistoryControllerProvider).warning, isNull);
  });

  test(
    'committed Save As binds destination even when list refresh fails',
    () async {
      final store = _RepairStore();
      final container = _historyContainer(store, <_FakeTimer>[]);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final source = _fileBuffer(
        'fork-refresh',
        '/workspace/source.md',
        'source',
      );
      await controller.observeOpened(source);
      final oldId = controller.documentIdForBuffer(source.id);
      store.failRefreshAfterCapture = true;
      expect(
        await controller.captureSavedAs(
          LocalHistoryBufferSnapshot.fromBuffer(source),
          '/workspace/copy.md',
          destinationExisted: false,
        ),
        isTrue,
      );
      final newId = controller.documentIdForBuffer(source.id);
      expect(newId, isNotNull);
      expect(newId, isNot(oldId));
      expect(controller.pendingSnapshotForBuffer(source.id), isNull);
      expect(await controller.flushAll([]), isTrue);
      expect(store.commits, hasLength(2));
      expect(
        (await store.load()).documents
            .singleWhere((d) => d.id == newId)
            .currentPath,
        '/workspace/copy.md',
      );
    },
  );

  test(
    'settling one buffer resumes retries accepted by another buffer',
    () async {
      final memory = MemoryLocalHistoryStore();
      final store = _BlockingNextCaptureStore(memory);
      final timers = <_FakeTimer>[];
      final container = _historyContainer(store, timers);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final a = _fileBuffer('settle-a', '/workspace/a.md', 'a');
      final b = _fileBuffer('settle-b', '/workspace/b.md', 'b');
      await controller.observeOpened(a);
      await controller.observeOpened(b);
      final editedA = a.edited('edited a');
      controller.observeEdit(a, editedA);
      await Future<void>.delayed(Duration.zero);
      store.blockNextCapture = true;
      final settling = controller.flushBuffer(editedA);
      await store.captureStarted.future;
      final editedB = b.edited('edited b');
      controller.observeEdit(b, editedB);
      await Future<void>.delayed(Duration.zero);
      store.releaseCapture.complete();
      expect(await settling, isTrue);
      expect(timers.where((timer) => timer.isActive), hasLength(1));
      timers.lastWhere((timer) => timer.isActive).fire();
      await _waitForHistory(
        container,
        (_) => controller.pendingSnapshotForBuffer(b.id) == null,
      );
      expect(
        await _revisionSources(memory, (await memory.load()).revisions),
        contains('edited b'),
      );
    },
  );

  test('clear document cancels its failed unbound baseline', () async {
    final store = _RepairStore();
    final retained = await _capturePath(
      store,
      '/workspace/clear.md',
      'persisted',
    );
    final timers = <_FakeTimer>[];
    final container = _historyContainer(store, timers);
    addTearDown(container.dispose);
    final controller = container.read(localHistoryControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    store.captureErrors['failed baseline'] = StateError('offline');
    final buffer = _fileBuffer(
      'unbound',
      '/workspace/clear.md',
      'failed baseline',
    );
    await controller.observeOpened(buffer);
    expect(controller.documentIdForBuffer(buffer.id), isNull);
    await controller.clearDocument(retained.document.id);
    store.captureErrors.clear();
    for (final timer in timers) {
      timer.fire();
    }
    expect(await controller.flushAll([]), isTrue);
    expect(controller.warningForBuffer(buffer.id), isNull);
    expect((await store.load()).revisions, isEmpty);
    expect(store.commits.map((r) => r.source), ['persisted']);
  });

  for (final firstSave in [true, false]) {
    test(
      'Save As retains failed original baseline through recovery (first=$firstSave)',
      () async {
        final store = _RepairStore()
          ..captureErrors['original'] = StateError('offline');
        final container = _historyContainer(store, <_FakeTimer>[]);
        addTearDown(container.dispose);
        final controller = container.read(
          localHistoryControllerProvider.notifier,
        );
        await Future<void>.delayed(Duration.zero);
        final original = firstSave
            ? DocumentBuffer.untitled(
                id: 'failed-save-baseline',
                name: 'Draft',
                text: 'original',
              )
            : _fileBuffer(
                'failed-save-baseline',
                '/workspace/original.md',
                'original',
              );
        await controller.observeOpened(original);
        final edited = original.edited('edited destination');
        controller.observeEdit(original, edited);
        expect(
          await controller.captureSavedAs(
            LocalHistoryBufferSnapshot.fromBuffer(edited),
            '/workspace/destination.md',
            destinationExisted: false,
            destinationFormat: firstSave
                ? const TextFormatMetadata(
                    hasUtf8Bom: false,
                    lineEnding: DocumentLineEnding.crlf,
                    hasFinalNewline: false,
                  )
                : null,
          ),
          isFalse,
        );
        expect(
          await controller.flushPendingIdentityPromotions(),
          firstSave ? isFalse : isTrue,
        );
        store.captureErrors.clear();
        final named = edited.copyWith(
          filePath: '/workspace/destination.md',
          untitledName: null,
          dirty: false,
          lastSavedText: edited.text,
        );
        expect(await controller.flushAll([named]), isTrue);
        final snapshot = await store.load();
        expect(snapshot.documents, hasLength(firstSave ? 1 : 2));
        final destination = snapshot.documents.singleWhere(
          (d) => d.currentPath == '/workspace/destination.md',
        );
        expect(
          await _revisionSources(store, snapshot.revisionsFor(destination.id)),
          contains('edited destination'),
        );
        if (firstSave) {
          final destinationRevisions = <LocalHistoryRevision?>[
            for (final revision in snapshot.revisionsFor(destination.id))
              await store.readRevision(revision.id),
          ];
          expect(
            destinationRevisions.any(
              (revision) =>
                  revision?.source == 'edited destination' &&
                  revision?.format.lineEnding == DocumentLineEnding.crlf,
            ),
            isTrue,
          );
        }
        expect(
          await _revisionSources(store, snapshot.revisions),
          contains('original'),
        );
        if (!firstSave) {
          final source = snapshot.documents.singleWhere(
            (document) => document.currentPath == '/workspace/original.md',
          );
          expect(
            await _revisionSources(store, snapshot.revisionsFor(source.id)),
            contains('edited destination'),
          );
        }
        expect(controller.warningForBuffer(named.id), isNull);
      },
    );
  }

  for (final destinationExisted in [false, true]) {
    test(
      'Save As keeps retained source protection with a source identity '
      'established during settlement (existing=$destinationExisted)',
      () async {
        final store = _RepairStore();
        if (destinationExisted) {
          await _capturePath(
            store,
            '/workspace/destination.md',
            'existing destination',
          );
        }
        store.captureErrors
          ..['original source'] = StateError('baseline unavailable')
          ..['source-only protection'] = StateError('protection unavailable');
        final timers = <_FakeTimer>[];
        final container = _historyContainer(store, timers);
        addTearDown(container.dispose);
        final controller = container.read(
          localHistoryControllerProvider.notifier,
        );
        await Future<void>.delayed(Duration.zero);
        final original = _fileBuffer(
          'save-as-source-owner',
          '/workspace/source.md',
          'original source',
        );
        await controller.observeOpened(original);
        expect(controller.documentIdForBuffer(original.id), isNull);

        final protected = original.edited('source-only protection');
        expect(
          await controller.captureBeforeLoss(
            LocalHistoryBufferSnapshot.fromBuffer(protected),
            LocalHistoryCaptureReason.beforeDiscard,
          ),
          isFalse,
        );
        final forkPoint = protected.edited('fork point');
        controller.observeEdit(protected, forkPoint);
        await Future<void>.delayed(Duration.zero);

        store.captureErrors.remove('original source');
        final destinationTarget = destinationExisted
            ? (await store.resolvePathTargets(
                '/workspace/destination.md',
                recursive: false,
              )).single
            : null;
        expect(
          await controller.captureSavedAs(
            LocalHistoryBufferSnapshot.fromBuffer(forkPoint),
            '/workspace/destination.md',
            destinationExisted: destinationExisted,
            destinationTarget: destinationTarget,
          ),
          isTrue,
        );
        final destinationId = controller.documentIdForBuffer(original.id);
        expect(destinationId, isNotNull);

        store.captureErrors.clear();
        final destination = forkPoint.copyWith(
          filePath: '/workspace/destination.md',
          lastSavedText: forkPoint.text,
          dirty: false,
        );
        expect(await controller.flushAll([destination]), isTrue);
        final furtherEdit = destination.edited('destination-only edit');
        expect(
          await controller.captureSaved(
            LocalHistoryBufferSnapshot.fromBuffer(furtherEdit),
          ),
          isTrue,
        );

        final snapshot = await store.load();
        final sourceDocument = snapshot.documents.singleWhere(
          (document) => document.currentPath == '/workspace/source.md',
        );
        final destinationDocument = snapshot.documents.singleWhere(
          (document) => document.currentPath == '/workspace/destination.md',
        );
        expect(destinationDocument.id, destinationId);
        expect(sourceDocument.id, isNot(destinationDocument.id));
        expect(
          await _revisionSources(
            store,
            snapshot.revisionsFor(sourceDocument.id),
          ),
          contains('source-only protection'),
        );
        expect(
          await _revisionSources(
            store,
            snapshot.revisionsFor(destinationDocument.id),
          ),
          allOf(
            contains('fork point'),
            contains('destination-only edit'),
            isNot(contains('source-only protection')),
          ),
        );
        expect(controller.documentIdForBuffer(original.id), destinationId);
      },
    );
  }

  test(
    'Save As retains a source identity established before later settlement fails',
    () async {
      final store = _RepairStore()
        ..captureErrors['original source'] = StateError('baseline unavailable')
        ..captureErrors['source-only protection'] = StateError(
          'protection unavailable',
        );
      final timers = <_FakeTimer>[];
      final container = _historyContainer(store, timers);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final original = _fileBuffer(
        'save-as-mid-settlement-owner',
        '/workspace/source.md',
        'original source',
      );
      await controller.observeOpened(original);
      final protected = original.edited('source-only protection');
      expect(
        await controller.captureBeforeLoss(
          LocalHistoryBufferSnapshot.fromBuffer(protected),
          LocalHistoryCaptureReason.beforeDiscard,
        ),
        isFalse,
      );
      final forkPoint = protected.edited('fork point');
      controller.observeEdit(protected, forkPoint);
      await Future<void>.delayed(Duration.zero);
      store.captureErrors
        ..remove('original source')
        ..['fork point'] = StateError('checkpoint unavailable');

      expect(
        await controller.captureSavedAs(
          LocalHistoryBufferSnapshot.fromBuffer(forkPoint),
          '/workspace/destination.md',
          destinationExisted: false,
        ),
        isFalse,
      );
      final sourceBeforeRetry = (await store.load()).documents.singleWhere(
        (document) => document.currentPath == '/workspace/source.md',
      );
      expect(controller.documentIdForBuffer(original.id), isNull);

      store.captureErrors.clear();
      final destination = forkPoint.copyWith(
        filePath: '/workspace/destination.md',
        lastSavedText: forkPoint.text,
        dirty: false,
      );
      expect(await controller.flushAll([destination]), isTrue);
      final sourceProtectionAttempts = store.attempts
          .where((request) => request.source == 'source-only protection')
          .toList();
      expect(sourceProtectionAttempts, hasLength(2));
      expect(sourceProtectionAttempts.last.documentId, sourceBeforeRetry.id);

      final snapshot = await store.load();
      final source = snapshot.documents.singleWhere(
        (document) => document.id == sourceBeforeRetry.id,
      );
      final destinationDocument = snapshot.documents.singleWhere(
        (document) => document.currentPath == '/workspace/destination.md',
      );
      expect(source.currentPath, '/workspace/source.md');
      expect(destinationDocument.id, isNot(source.id));
      expect(
        await _revisionSources(store, snapshot.revisionsFor(source.id)),
        containsAll(['source-only protection', 'fork point']),
      );
      expect(
        await _revisionSources(
          store,
          snapshot.revisionsFor(destinationDocument.id),
        ),
        allOf(
          contains('fork point'),
          isNot(contains('source-only protection')),
        ),
      );
    },
  );

  test(
    'Save As refreshes a staged destination after its concurrent checkpoint',
    () async {
      final store = MemoryLocalHistoryStore();
      final destination = await store.capture(
        LocalHistoryCaptureRequest(
          path: '/workspace/destination.md',
          displayName: 'destination.md',
          source: 'destination on disk',
          format: TextFormatMetadata.utf8Lf,
          capturedAt: DateTime.utc(2026),
          reason: LocalHistoryCaptureReason.saved,
        ),
        const LocalHistoryPolicy(),
      );
      final target = (await store.resolvePathTargets(
        '/workspace/destination.md',
        recursive: false,
      )).single;
      await store.capture(
        LocalHistoryCaptureRequest(
          documentId: destination.document.id,
          path: '/workspace/destination.md',
          displayName: 'destination.md',
          source: 'concurrent destination checkpoint',
          format: TextFormatMetadata.utf8Lf,
          capturedAt: DateTime.utc(2026, 1, 1, 0, 0, 1),
          reason: LocalHistoryCaptureReason.automaticCheckpoint,
        ),
        const LocalHistoryPolicy(),
      );
      final container = _historyContainer(store, <_FakeTimer>[]);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final source = _fileBuffer(
        'concurrent-destination-save-as',
        '/workspace/source.md',
        'source fork',
      );
      await controller.observeOpened(source);

      expect(
        await controller.captureSavedAs(
          LocalHistoryBufferSnapshot.fromBuffer(source),
          '/workspace/destination.md',
          destinationExisted: true,
          destinationDocumentId: destination.document.id,
          destinationTarget: target,
        ),
        isTrue,
      );
      final snapshot = await store.load();
      final destinationSources = await _revisionSources(
        store,
        snapshot.revisionsFor(destination.document.id),
      );
      expect(
        destinationSources,
        containsAll([
          'destination on disk',
          'concurrent destination checkpoint',
          'source fork',
        ]),
      );
      expect(
        controller.documentIdForBuffer(source.id),
        destination.document.id,
      );
    },
  );

  test(
    'abandoned and superseded moves retain the newest committed association',
    () async {
      final store = _RepairStore()
        ..captureErrors['original'] = StateError('offline');
      final timers = <_FakeTimer>[];
      final container = _historyContainer(store, timers);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final buffer = _fileBuffer(
        'transition-owner',
        '/workspace/a.md',
        'original',
      );
      await controller.observeOpened(buffer);

      final abandoned = controller.beginBufferPathTransition(
        bufferId: buffer.id,
        sourcePath: '/workspace/a.md',
        destinationPath: '/workspace/abandoned.md',
      );
      await controller.finishBufferPathTransition(abandoned, committed: false);
      final superseded = controller.beginBufferPathTransition(
        bufferId: buffer.id,
        sourcePath: '/workspace/a.md',
        destinationPath: '/workspace/stale.md',
      );
      final committed = controller.beginBufferPathTransition(
        bufferId: buffer.id,
        sourcePath: '/workspace/a.md',
        destinationPath: '/workspace/current.md',
      );
      await controller.finishBufferPathTransition(superseded, committed: true);
      await controller.finishBufferPathTransition(committed, committed: true);

      store.captureErrors.clear();
      final moved = buffer.copyWith(filePath: '/workspace/current.md');
      expect(await controller.flushBuffer(moved), isTrue);
      final snapshot = await store.load();
      expect(snapshot.documents, hasLength(1));
      expect(snapshot.documents.single.currentPath, '/workspace/current.md');
      expect(
        await _revisionSources(
          store,
          snapshot.revisionsFor(snapshot.documents.single.id),
        ),
        contains('original'),
      );
    },
  );

  test('queued edits share one retained baseline retry owner', () async {
    for (final editCount in [2, 8]) {
      final memory = _RepairStore()
        ..captureErrors['original'] = StateError('contended');
      final store = _BlockingNextCaptureStore(memory)
        ..blockNextCapture = true
        ..failBlockedCapture = true;
      final timers = <_FakeTimer>[];
      final container = _historyContainer(store, timers);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      var previous = _fileBuffer(
        'coalesced-$editCount',
        '/workspace/coalesced-$editCount.md',
        'original',
      );
      var latest = previous.edited('edit 1');
      controller.observeEdit(previous, latest);
      previous = latest;
      await store.captureStarted.future;
      for (var index = 2; index <= editCount; index++) {
        latest = previous.edited('edit $index');
        controller.observeEdit(previous, latest);
        previous = latest;
      }
      store.releaseCapture.complete();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      int baselineAttempts() => store.attempts
          .where(
            (request) =>
                request.reason == LocalHistoryCaptureReason.baseline &&
                request.source == 'original',
          )
          .length;
      expect(baselineAttempts(), 1, reason: 'edit count $editCount');
      expect(
        controller.pendingSnapshotForBuffer(latest.id)?.text,
        'edit $editCount',
      );

      timers.lastWhere((timer) => timer.isActive).fire();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(baselineAttempts(), 2, reason: 'timer retry $editCount');
      expect(await controller.flushBuffer(latest), isFalse);
      expect(baselineAttempts(), 3, reason: 'explicit retry $editCount');

      memory.captureErrors.clear();
      timers.lastWhere((timer) => timer.isActive).fire();
      await _waitForHistory(container, (_) => memory.commits.length == 2);
      expect(await controller.flushBuffer(latest), isTrue);
      expect(baselineAttempts(), 4, reason: 'recovery $editCount');
      final snapshot = await store.load();
      expect(snapshot.documents, hasLength(1));
      expect(
        await _revisionSources(
          store,
          snapshot.revisionsFor(snapshot.documents.single.id),
        ),
        containsAll(['original', 'edit $editCount']),
      );
      container.dispose();
    }
  });

  test(
    'independent failures, permanent baselines and policy cancellation remain isolated',
    () async {
      final store = _RepairStore()
        ..captureErrors['a'] = const UnsupportedLocalHistoryFormat(99)
        ..captureErrors['b'] = StateError('offline');
      final timers = <_FakeTimer>[];
      final container = _historyContainer(store, timers);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final a = _fileBuffer('a', '/workspace/a.md', 'a');
      final b = _fileBuffer('b', '/elsewhere/b.md', 'b');
      await controller.observeOpened(a);
      await controller.observeOpened(b);
      expect(timers.where((t) => t.isActive), hasLength(1));
      expect(await controller.flushBuffer(a), isFalse);
      store.captureErrors.remove('b');
      expect(await controller.flushBuffer(b), isTrue);
      expect(controller.warningForBuffer(b.id), isNull);
      expect(
        controller.warningForBuffer(a.id)?.kind,
        LocalHistoryWarningKind.capture,
      );
      expect(await controller.flushAll([]), isFalse);
      await container
          .read(appSettingsControllerProvider.notifier)
          .setLocalHistoryExcludedPaths(['/workspace']);
      expect(await controller.flushAll([]), isTrue);
      expect(controller.warningForBuffer(a.id), isNull);
    },
  );

  test(
    'cancelled failed baselines cannot be restored by delayed callbacks',
    () async {
      for (final cancellation in ['disable', 'exclude', 'clear', 'dispose']) {
        final store = _RepairStore()
          ..captureErrors['base'] = StateError('offline');
        final timers = <_FakeTimer>[];
        final container = _historyContainer(store, timers);
        final controller = container.read(
          localHistoryControllerProvider.notifier,
        );
        await Future<void>.delayed(Duration.zero);
        final buffer = _fileBuffer(
          'cancelled',
          '/workspace/cancelled.md',
          'base',
        );
        await controller.observeOpened(buffer);
        final queued = controller.flushBuffer(buffer);
        switch (cancellation) {
          case 'disable':
            await container
                .read(appSettingsControllerProvider.notifier)
                .setLocalHistoryRecordingEnabled(false);
          case 'exclude':
            await container
                .read(appSettingsControllerProvider.notifier)
                .setLocalHistoryExcludedPaths(['/workspace']);
          case 'clear':
            await controller.clearAll();
          case 'dispose':
            container.dispose();
        }
        await queued;
        store.captureErrors.clear();
        for (final timer in timers) {
          timer.fire();
        }
        if (cancellation != 'dispose') {
          expect(await controller.flushAll([]), isTrue);
          expect(controller.warningForBuffer(buffer.id), isNull);
          container.dispose();
        }
        expect(store.commits, isEmpty, reason: cancellation);
      }
    },
  );

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
    'first checkpoint attaches an empty untitled browsing scope and publishes it',
    () async {
      final timers = <_FakeTimer>[];
      final store = MemoryLocalHistoryStore();
      final container = _historyContainer(store, timers);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final empty = DocumentBuffer.untitled(
        id: 'empty-draft',
        name: 'Draft.md',
      );

      await controller.selectDocumentForBuffer(empty);
      expect(
        container.read(localHistoryControllerProvider).selectedDocumentId,
        isNull,
      );
      final edited = empty.edited('First retained source');
      controller.observeEdit(empty, edited);
      await Future<void>.delayed(Duration.zero);
      expect(controller.pendingSnapshotForBuffer(empty.id)?.text, edited.text);
      expect(timers, hasLength(1));

      timers.single.fire();
      await _waitForHistory(
        container,
        (state) => state.selectedRevisions.length == 1,
      );

      final state = container.read(localHistoryControllerProvider);
      expect(state.selectedDocument?.displayName, 'Draft.md');
      expect(state.selectedDocument?.untitled, isTrue);
      expect(
        state.selectedRevisions.single.reason,
        LocalHistoryCaptureReason.automaticCheckpoint,
      );
      expect(
        (await store.readRevision(state.selectedRevisions.single.id))!.source,
        edited.text,
      );
      expect(controller.pendingSnapshotForBuffer(empty.id), isNull);
    },
  );

  test(
    'file store checkpoint persists across reopen and clear stays authoritative',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'busymark-history-controller-file-',
      );
      addTearDown(() => root.delete(recursive: true));
      final documentFile = File(p.join(root.path, 'workspace', 'guide.md'));
      await documentFile.parent.create(recursive: true);
      await documentFile.writeAsString('baseline');
      final historyRoot = Directory(p.join(root.path, 'history'));
      final store = FileLocalHistoryStore(
        rootDirectory: () async => historyRoot,
      );
      final timers = <_FakeTimer>[];
      final container = _historyContainer(store, timers);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final opened = _fileBuffer(
        'file-store-buffer',
        documentFile.path,
        'baseline',
      );
      await controller.selectDocumentForBuffer(opened);
      final edited = opened.edited('persisted checkpoint');
      controller.observeEdit(opened, edited);
      await Future<void>.delayed(Duration.zero);
      timers.single.fire();
      await _waitForHistory(
        container,
        (state) => state.selectedRevisions.length == 2,
        timeout: const Duration(seconds: 10),
      );

      final reopened = FileLocalHistoryStore(
        rootDirectory: () async => historyRoot,
      );
      var diskSnapshot = await reopened.load();
      expect(diskSnapshot.documents, hasLength(1));
      expect(
        await _revisionSources(
          reopened,
          diskSnapshot.revisionsFor(diskSnapshot.documents.single.id),
        ),
        contains('persisted checkpoint'),
      );

      await controller.clearDocument(diskSnapshot.documents.single.id);
      diskSnapshot = await reopened.load();
      expect(diskSnapshot.documents, isEmpty);
      expect(diskSnapshot.revisions, isEmpty);
    },
  );

  test(
    'active revision search follows matching and nonmatching captures',
    () async {
      final timers = <_FakeTimer>[];
      final store = MemoryLocalHistoryStore();
      final container = _historyContainer(store, timers);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final opened = _fileBuffer(
        'search-buffer',
        '/workspace/search.md',
        'base',
      );
      await controller.selectDocumentForBuffer(opened);
      await controller.search('needle');
      expect(
        container.read(localHistoryControllerProvider).searchMatches,
        isEmpty,
      );

      final matching = opened.edited('base with needle');
      controller.observeEdit(opened, matching);
      await Future<void>.delayed(Duration.zero);
      timers.last.fire();
      await _waitForHistory(
        container,
        (state) =>
            !state.searching &&
            state.searchQuery == 'needle' &&
            state.searchMatches.isNotEmpty,
      );
      var state = container.read(localHistoryControllerProvider);
      expect(
        state.selectedRevisions.where(state.revisionVisible),
        hasLength(1),
      );

      final nonmatching = matching.edited('different content');
      controller.observeEdit(matching, nonmatching);
      await Future<void>.delayed(Duration.zero);
      timers.last.fire();
      await _waitForHistory(
        container,
        (value) => !value.searching && value.selectedRevisions.length == 3,
      );
      state = container.read(localHistoryControllerProvider);
      expect(state.searchQuery, 'needle');
      expect(
        state.selectedRevisions.where(state.revisionVisible),
        hasLength(1),
      );
    },
  );

  test(
    'failed automatic capture keeps pending source and retries without another edit',
    () async {
      final timers = <_FakeTimer>[];
      final memory = MemoryLocalHistoryStore();
      final store = _FailingSourceCaptureStore(memory, 'retry source');
      final container = _historyContainer(store, timers);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final opened = _fileBuffer('retry-buffer', '/workspace/retry.md', 'base');
      await controller.selectDocumentForBuffer(opened);
      final edited = opened.edited('retry source');
      controller.observeEdit(opened, edited);
      await Future<void>.delayed(Duration.zero);

      timers.single.fire();
      await _waitForHistory(
        container,
        (state) => state.warning?.kind == LocalHistoryWarningKind.capture,
      );
      expect(controller.pendingSnapshotForBuffer(opened.id)?.text, edited.text);
      expect(timers, hasLength(2));

      timers.last.fire();
      await _waitForHistory(
        container,
        (state) => state.selectedRevisions.length == 2,
      );
      final state = container.read(localHistoryControllerProvider);
      expect(state.warning, isNull);
      expect(controller.pendingSnapshotForBuffer(opened.id), isNull);
      expect(
        await _revisionSources(store, state.selectedRevisions),
        contains(edited.text),
      );
    },
  );

  test('a newer edit accepted during a failed write wins the retry', () async {
    final timers = <_FakeTimer>[];
    final memory = MemoryLocalHistoryStore();
    final store = _BlockingNextCaptureStore(memory);
    final container = _historyContainer(store, timers);
    addTearDown(container.dispose);
    final controller = container.read(localHistoryControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    final opened = _fileBuffer('newest-buffer', '/workspace/newest.md', 'base');
    await controller.selectDocumentForBuffer(opened);
    final older = opened.edited('older pending source');
    controller.observeEdit(opened, older);
    await Future<void>.delayed(Duration.zero);
    store.blockNextCapture = true;
    store.failBlockedCapture = true;
    timers.single.fire();
    await store.captureStarted.future;

    final newer = older.edited('newest pending source');
    controller.observeEdit(older, newer);
    store.releaseCapture.complete();
    await _waitForHistory(
      container,
      (state) =>
          state.warning?.kind == LocalHistoryWarningKind.capture &&
          controller.pendingSnapshotForBuffer(opened.id)?.text == newer.text,
    );

    timers.lastWhere((timer) => timer.isActive).fire();
    await _waitForHistory(
      container,
      (state) =>
          state.warning == null &&
          controller.pendingSnapshotForBuffer(opened.id) == null,
    );
    final snapshot = await memory.load();
    final sources = await _revisionSources(
      memory,
      snapshot.revisionsFor(snapshot.documents.single.id),
    );
    expect(sources, contains(newer.text));
    expect(sources, isNot(contains(older.text)));
  });

  test(
    'automatic checkpoint retries a transient first-save promotion failure',
    () async {
      final timers = <_FakeTimer>[];
      final store = _ControllablePromotionStore();
      final container = _historyContainer(store, timers);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final untitled = DocumentBuffer.untitled(
        id: 'promotion-retry-buffer',
        name: 'Draft.md',
        text: 'initial source',
      );
      await controller.observeOpened(untitled);
      final originalDocumentId = (await store.load()).documents.single.id;
      const destination = '/workspace/Promoted.md';
      expect(
        await controller.captureSavedAs(
          LocalHistoryBufferSnapshot.fromBuffer(untitled),
          destination,
          destinationExisted: false,
        ),
        isFalse,
      );
      expect(store.promotionAttempts, 1);
      expect(controller.hasPendingIdentityPromotion(untitled.id), isTrue);

      final named = untitled.copyWith(
        filePath: destination,
        untitledName: null,
        lastSavedText: untitled.text,
        dirty: false,
      );
      final edited = named.edited('latest named source');
      controller.observeEdit(named, edited);
      await Future<void>.delayed(Duration.zero);
      expect(timers, hasLength(1));

      timers.single.fire();
      await _waitForHistory(
        container,
        (_) => store.promotionAttempts == 2 && timers.length == 2,
      );
      expect(controller.pendingSnapshotForBuffer(edited.id)?.text, edited.text);

      store.failPromotions = false;
      timers.last.fire();
      await _waitForHistory(
        container,
        (_) =>
            !controller.hasPendingIdentityPromotion(edited.id) &&
            controller.pendingSnapshotForBuffer(edited.id) == null,
      );

      final snapshot = await store.load();
      expect(snapshot.documents, hasLength(1));
      expect(snapshot.documents.single.id, originalDocumentId);
      expect(snapshot.documents.single.currentPath, destination);
      expect(
        await _revisionSources(
          store,
          snapshot.revisionsFor(originalDocumentId),
        ),
        contains(edited.text),
      );
    },
  );

  test(
    'flush waits behind queued observation and captures its latest source',
    () async {
      final memory = MemoryLocalHistoryStore();
      final store = _BlockingNextCaptureStore(memory);
      final container = _historyContainer(store, <_FakeTimer>[]);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final opened = _fileBuffer('flush-buffer', '/workspace/flush.md', 'base');
      await controller.observeOpened(opened);

      store.blockNextCapture = true;
      final intermediate = opened.edited('intermediate');
      final blockedSave = controller.captureSaved(
        LocalHistoryBufferSnapshot.fromBuffer(intermediate),
      );
      await store.captureStarted.future;
      final latest = intermediate.edited('accepted latest source');
      controller.observeEdit(intermediate, latest);
      final flush = controller.flushBuffer(latest);
      var flushCompleted = false;
      unawaited(flush.then((_) => flushCompleted = true));
      await Future<void>.delayed(Duration.zero);
      expect(flushCompleted, isFalse);

      store.releaseCapture.complete();
      expect(await blockedSave, isTrue);
      expect(await flush, isTrue);
      final snapshot = await memory.load();
      expect(
        await _revisionSources(
          memory,
          snapshot.revisionsFor(snapshot.documents.single.id),
        ),
        contains('accepted latest source'),
      );
    },
  );

  test(
    'clear wins over an in-flight capture and later edits record normally',
    () async {
      final timers = <_FakeTimer>[];
      final memory = MemoryLocalHistoryStore();
      final store = _BlockingNextCaptureStore(memory);
      final container = _historyContainer(store, timers);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final opened = _fileBuffer('clear-buffer', '/workspace/clear.md', 'base');
      await controller.selectDocumentForBuffer(opened);
      final documentId = container
          .read(localHistoryControllerProvider)
          .selectedDocumentId!;
      store.blockNextCapture = true;
      final firstEdit = opened.edited('must stay cleared');
      controller.observeEdit(opened, firstEdit);
      await Future<void>.delayed(Duration.zero);
      timers.single.fire();
      await store.captureStarted.future;

      final clear = controller.clearDocument(documentId);
      store.releaseCapture.complete();
      await clear;
      expect((await memory.load()).revisions, isEmpty);
      expect(
        container.read(localHistoryControllerProvider).selectedRevision,
        isNull,
      );

      final laterEdit = firstEdit.edited('new history after clear');
      controller.observeEdit(firstEdit, laterEdit);
      await Future<void>.delayed(Duration.zero);
      timers.last.fire();
      await _waitForHistory(
        container,
        (state) => state.selectedRevisions.length >= 2,
      );
      final state = container.read(localHistoryControllerProvider);
      expect(state.selectedDocument?.currentPath, opened.filePath);
      expect(
        await _revisionSources(store, state.selectedRevisions),
        contains('new history after clear'),
      );
    },
  );

  for (final clearAll in [false, true]) {
    test(
      'edit accepted during ${clearAll ? "Clear All" : "Clear Document"} records in the replacement lineage',
      () async {
        final store = _BlockingClearStore();
        final container = _historyContainer(store, <_FakeTimer>[]);
        addTearDown(container.dispose);
        final controller = container.read(
          localHistoryControllerProvider.notifier,
        );
        await Future<void>.delayed(Duration.zero);
        final opened = _fileBuffer(
          'during-clear',
          '/workspace/during-clear.md',
          'before clear',
        );
        await controller.observeOpened(opened);
        final oldDocumentId = controller.documentIdForBuffer(opened.id)!;

        final clear = clearAll
            ? controller.clearAll()
            : controller.clearDocument(oldDocumentId);
        await store.clearStarted.future;
        final edited = opened.edited('accepted while clear was blocked');
        controller.observeEdit(opened, edited);
        store.releaseClear.complete();
        await clear;
        await Future<void>.delayed(Duration.zero);

        expect(await controller.flushBuffer(edited), isTrue);
        final snapshot = await store.load();
        expect(
          snapshot.documents.where((document) => document.id == oldDocumentId),
          isEmpty,
        );
        final replacement = snapshot.documents.singleWhere(
          (document) => document.currentPath == '/workspace/during-clear.md',
        );
        expect(replacement.id, isNot(oldDocumentId));
        expect(
          await _revisionSources(store, snapshot.revisionsFor(replacement.id)),
          contains('accepted while clear was blocked'),
        );
      },
    );

    test(
      '${clearAll ? "Clear All" : "Clear Document"} blocks replacement capture while its journal is pending',
      () async {
        final store = MemoryLocalHistoryStore();
        final container = _historyContainer(store, <_FakeTimer>[]);
        addTearDown(container.dispose);
        final controller = container.read(
          localHistoryControllerProvider.notifier,
        );
        await Future<void>.delayed(Duration.zero);
        final opened = _fileBuffer(
          'journal-blocked-clear',
          '/workspace/journal-blocked-clear.md',
          'before clear',
        );
        await controller.observeOpened(opened);
        final oldDocumentId = controller.documentIdForBuffer(opened.id)!;

        final journalStarted = Completer<void>();
        final releaseJournal = Completer<void>();
        var persistenceCalls = 0;
        controller.setDurableStatePersistence(() async {
          persistenceCalls++;
          if (persistenceCalls == 1) {
            journalStarted.complete();
            await releaseJournal.future;
          }
          return true;
        });

        final clear = clearAll
            ? controller.clearAll()
            : controller.clearDocument(oldDocumentId);
        await journalStarted.future;
        final edited = opened.edited('accepted during journal write');
        final capture = controller.captureSaved(
          LocalHistoryBufferSnapshot.fromBuffer(edited),
        );
        var captureCompleted = false;
        unawaited(capture.then((_) => captureCompleted = true));
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(captureCompleted, isFalse);
        releaseJournal.complete();
        await clear;
        expect(await capture, isTrue);

        final snapshot = await store.load();
        expect(
          snapshot.documents.where((document) => document.id == oldDocumentId),
          isEmpty,
        );
        final replacement = snapshot.documents.singleWhere(
          (document) =>
              document.currentPath == '/workspace/journal-blocked-clear.md',
        );
        expect(replacement.id, isNot(oldDocumentId));
        expect(
          await _revisionSources(store, snapshot.revisionsFor(replacement.id)),
          contains('accepted during journal write'),
        );
      },
    );
  }

  test(
    'clear invalidates an automatic checkpoint queued for an untitled draft',
    () async {
      final timers = <_FakeTimer>[];
      final memory = MemoryLocalHistoryStore();
      final store = _BlockingNextCaptureStore(memory);
      final container = _historyContainer(store, timers);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final opened = DocumentBuffer.untitled(
        id: 'queued-clear-draft',
        name: 'Draft.md',
        text: 'retained baseline',
      );
      await controller.observeOpened(opened);
      final originalDocumentId = (await memory.load()).documents.single.id;
      final edited = opened.edited('must remain cleared');
      controller.observeEdit(opened, edited);
      await Future<void>.delayed(Duration.zero);
      expect(timers, hasLength(1));

      store.blockNextCapture = true;
      final precedingCapture = controller.captureSaved(
        LocalHistoryBufferSnapshot.fromBuffer(opened),
      );
      await store.captureStarted.future;
      timers.single.fire();
      final clear = controller.clearDocument(originalDocumentId);
      await Future<void>.delayed(Duration.zero);

      store.releaseCapture.complete();
      expect(await precedingCapture, isTrue);
      await clear;

      final snapshot = await memory.load();
      expect(snapshot.documents, isEmpty);
      expect(snapshot.revisions, isEmpty);
      expect(controller.documentIdForBuffer(opened.id), isNull);
      expect(controller.pendingSnapshotForBuffer(opened.id), isNull);
    },
  );

  for (final clearAll in [false, true]) {
    test('failed explicit save cannot recreate history after '
        '${clearAll ? 'Clear All' : 'Clear Document'}', () async {
      final timers = <_FakeTimer>[];
      final memory = MemoryLocalHistoryStore();
      final store = _BlockingNextCaptureStore(memory);
      final container = _historyContainer(store, timers);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final opened = _fileBuffer(
        'saved-clear-buffer',
        '/workspace/saved-clear.md',
        'retained baseline',
      );
      await controller.selectDocumentForBuffer(opened);
      final documentId = controller.documentIdForBuffer(opened.id)!;
      final saved = opened.edited('saved before clear');

      store.blockNextCapture = true;
      store.failBlockedCapture = true;
      final capture = controller.captureSaved(
        LocalHistoryBufferSnapshot.fromBuffer(saved),
      );
      await store.captureStarted.future;
      final clear = clearAll
          ? controller.clearAll()
          : controller.clearDocument(documentId);
      await Future<void>.delayed(Duration.zero);

      store.releaseCapture.complete();
      expect(await capture, isTrue);
      await clear;
      for (final timer in timers) {
        timer.fire();
      }
      await Future<void>.delayed(Duration.zero);

      final snapshot = await memory.load();
      expect(snapshot.documents, isEmpty);
      expect(snapshot.revisions, isEmpty);
      expect(controller.documentIdForBuffer(opened.id), isNull);
      expect(controller.pendingSnapshotForBuffer(opened.id), isNull);
      expect(timers.where((timer) => timer.isActive), isEmpty);
    });
  }

  test(
    'clearing the displayed comparison closes it without a missing warning',
    () async {
      final store = MemoryLocalHistoryStore();
      await _capturePath(store, '/workspace/compare.md', 'older source');
      final container = _historyContainer(store, <_FakeTimer>[]);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final buffer = _fileBuffer(
        'comparison-buffer',
        '/workspace/compare.md',
        'current source',
      );
      await controller.selectDocumentForBuffer(buffer);
      final before = container.read(localHistoryControllerProvider);
      final documentId = before.selectedDocumentId!;
      final revisionId = before.selectedRevisions.first.id;
      await controller.selectRevision(revisionId);
      expect(
        container.read(localHistoryControllerProvider).selectedRevision,
        isNotNull,
      );

      await controller.clearDocument(documentId);

      final state = container.read(localHistoryControllerProvider);
      expect(state.selectedDocumentId, isNull);
      expect(state.selectedRevisionId, isNull);
      expect(state.selectedRevision, isNull);
      expect(
        state.warning?.kind,
        isNot(LocalHistoryWarningKind.revisionMissing),
      );
    },
  );

  test(
    'clear invalidates an in-flight path capture for the same document',
    () async {
      final memory = MemoryLocalHistoryStore();
      const path = '/workspace/path-clear.md';
      await _capturePath(memory, path, 'retained source');
      final store = _BlockingNextCaptureStore(memory);
      final container = _historyContainer(store, <_FakeTimer>[]);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final documentId = container
          .read(localHistoryControllerProvider)
          .snapshot
          .documents
          .single
          .id;

      store.blockNextCapture = true;
      final capture = controller.capturePath(
        path: path,
        text: 'must not return after clear',
        format: TextFormatMetadata.utf8Lf,
        reason: LocalHistoryCaptureReason.beforeDelete,
      );
      await store.captureStarted.future;

      final clear = controller.clearDocument(documentId);
      store.releaseCapture.complete();
      expect(await capture, isTrue);
      await clear;

      expect((await memory.load()).revisions, isEmpty);
      expect(
        container.read(localHistoryControllerProvider).snapshot.revisions,
        isEmpty,
      );
    },
  );

  test(
    'first edit after another controller clears a stale binding starts a new lineage',
    () async {
      final store = MemoryLocalHistoryStore();
      final first = _historyContainer(store, <_FakeTimer>[]);
      final second = _historyContainer(store, <_FakeTimer>[]);
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      final clearing = first.read(localHistoryControllerProvider.notifier);
      final editing = second.read(localHistoryControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      await clearing.refresh();
      await editing.refresh();
      final opened = _fileBuffer(
        'shared-buffer',
        '/workspace/shared.md',
        'before clear',
      );
      await clearing.observeOpened(opened);
      await editing.observeOpened(opened);
      final originalId = (await store.load()).documents.single.id;

      await clearing.clearDocument(originalId);
      final edited = opened.edited('first edit after clear');
      editing.observeEdit(opened, edited);
      await Future<void>.delayed(Duration.zero);
      expect(await editing.flushBuffer(edited), isTrue);

      final snapshot = await store.load();
      expect(snapshot.documents, hasLength(1));
      expect(snapshot.documents.single.id, isNot(originalId));
      final revision = await store.readRevision(snapshot.revisions.single.id);
      expect(revision?.source, 'first edit after clear');
    },
  );

  for (final clearAll in [false, true]) {
    for (final pathProtection in [false, true]) {
      for (final queued in [false, true]) {
        test(
          '${clearAll ? "Clear All" : "Clear Document"} rejects '
          '${queued ? "queued" : "in-flight"} '
          '${pathProtection ? "path" : "buffer"} replacement protection',
          () async {
            final memory = MemoryLocalHistoryStore();
            final store = _BlockingNextCaptureStore(memory);
            final container = _historyContainer(store, <_FakeTimer>[]);
            addTearDown(container.dispose);
            final controller = container.read(
              localHistoryControllerProvider.notifier,
            );
            await Future<void>.delayed(Duration.zero);
            final buffer = _fileBuffer(
              'protected',
              '/workspace/protected.md',
              'current source',
            );
            await controller.observeOpened(buffer);
            final documentId = controller.documentIdForBuffer(buffer.id)!;
            final snapshot = LocalHistoryBufferSnapshot.fromBuffer(buffer);
            store.blockNextCapture = true;
            Future<bool>? preceding;
            if (queued) {
              preceding = pathProtection
                  ? controller.capturePath(
                      path: buffer.filePath!,
                      text: buffer.text,
                      format: buffer.format,
                      reason: LocalHistoryCaptureReason.externalChange,
                    )
                  : controller.captureSaved(snapshot);
              await store.captureStarted.future;
            }
            final protection = pathProtection
                ? controller.capturePathBeforeLoss(
                    path: buffer.filePath!,
                    text: buffer.text,
                    format: buffer.format,
                    reason: LocalHistoryCaptureReason.beforeDiscard,
                  )
                : controller.captureBeforeLoss(
                    snapshot,
                    LocalHistoryCaptureReason.beforeReload,
                  );
            if (!queued) await store.captureStarted.future;
            final clear = clearAll
                ? controller.clearAll()
                : controller.clearDocument(documentId);
            store.releaseCapture.complete();
            if (preceding != null) expect(await preceding, isTrue);
            expect(await protection, isFalse);
            await clear;
            expect((await memory.load()).revisions, isEmpty);
          },
        );
      }
    }
  }

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

  test(
    'retained-document lookup is temporary and normal document selection resumes following',
    () async {
      final store = MemoryLocalHistoryStore();
      await _capturePath(store, '/workspace/current.md', 'Current source');
      await _capturePath(
        store,
        '/retired/deleted.md',
        'Unique retained content',
      );
      await store.markDeleted('/retired/deleted.md', recursive: false);
      final container = _historyContainer(store, <_FakeTimer>[]);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      await controller.refresh();
      final current = _fileBuffer(
        'current-buffer',
        '/workspace/current.md',
        'Current source',
      );
      await controller.selectDocumentForBuffer(current);
      final currentId = container
          .read(localHistoryControllerProvider)
          .selectedDocumentId;

      controller.beginDocumentSearch();
      await controller.search('Unique retained');
      var state = container.read(localHistoryControllerProvider);
      final deleted = state.snapshot.documents.singleWhere(
        (document) =>
            document.currentPath == '/retired/deleted.md' ||
            document.historicalPaths.contains('/retired/deleted.md'),
      );
      expect(state.documentSearchMatches, {deleted.id});
      controller.inspectRetainedDocument(deleted.id);
      state = container.read(localHistoryControllerProvider);
      expect(state.inspectingRetainedDocument, isTrue);
      expect(state.selectedDocumentId, deleted.id);
      expect(state.selectedDocument?.deleted, isTrue);
      expect(state.searchQuery, isEmpty);

      await controller.selectDocumentForBuffer(current);
      state = container.read(localHistoryControllerProvider);
      expect(state.inspectingRetainedDocument, isFalse);
      expect(state.findingDocuments, isFalse);
      expect(state.selectedDocumentId, currentId);
      expect(state.searchQuery, isEmpty);
    },
  );

  testWidgets(
    'panel construction preserves an explicit retained-document inspection',
    (tester) async {
      final directory = await tester.runAsync(
        () => Directory.systemTemp.createTemp('busymark-history-inspect-'),
      );
      final root = directory!;
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      final currentPath = p.join(root.path, 'current.md');
      await tester.runAsync(
        () => File(currentPath).writeAsString('Current source'),
      );
      final store = MemoryLocalHistoryStore();
      await tester.runAsync(
        () => _capturePath(
          store,
          '/retired/deleted.md',
          'Unique retained content',
        ),
      );
      await tester.runAsync(
        () => store.markDeleted('/retired/deleted.md', recursive: false),
      );
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
      final workspace = container.read(workspaceControllerProvider.notifier);
      await tester.runAsync(() => workspace.openPath(currentPath));
      final history = container.read(localHistoryControllerProvider.notifier);
      await tester.runAsync(history.refresh);
      history.beginDocumentSearch();
      await tester.runAsync(() => history.search('Unique retained'));
      final retained = container
          .read(localHistoryControllerProvider)
          .snapshot
          .documents
          .singleWhere((document) => document.deleted);
      history.inspectRetainedDocument(retained.id);
      await tester.runAsync(() => history.search('Unique retained'));

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
      await tester.pumpAndSettle();

      final state = container.read(localHistoryControllerProvider);
      expect(state.inspectingRetainedDocument, isTrue);
      expect(state.selectedDocumentId, retained.id);
      expect(state.searchQuery, 'Unique retained');
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Unique retained',
      );
      expect(
        find.byKey(const ValueKey('local-history-context-header')),
        findsOneWidget,
      );
      expect(find.text('deleted.md'), findsOneWidget);
    },
  );

  test(
    'delayed revision search cannot repopulate a newly selected document scope',
    () async {
      final memory = MemoryLocalHistoryStore();
      await _capturePath(memory, '/workspace/a.md', 'Only A matches');
      await _capturePath(memory, '/workspace/b.md', 'Only B matches');
      final snapshot = await memory.load();
      final documentA = snapshot.documents.singleWhere(
        (document) => document.currentPath == '/workspace/a.md',
      );
      final documentB = snapshot.documents.singleWhere(
        (document) => document.currentPath == '/workspace/b.md',
      );
      final revisionA = snapshot.revisionsFor(documentA.id).single;
      final store = _BlockingRevisionReadStore(memory, revisionA.id);
      final container = _historyContainer(store, <_FakeTimer>[]);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      await controller.refresh();
      controller.selectDocument(documentA.id);

      final search = controller.search('Only A');
      await store.started.future;
      controller.selectDocument(documentB.id);
      expect(container.read(localHistoryControllerProvider).loading, isFalse);
      expect(
        container.read(localHistoryControllerProvider).selectedDocumentId,
        documentB.id,
      );
      store.release.complete();
      await search;

      final state = container.read(localHistoryControllerProvider);
      expect(state.selectedDocument?.currentPath, '/workspace/b.md');
      expect(state.searchQuery, isEmpty);
      expect(state.searchMatches, isEmpty);
      expect(state.documentSearchMatches, isEmpty);
      expect(state.loading, isFalse);
    },
  );

  test(
    'revision search failure finishes searching and remains in scope',
    () async {
      final store = _FailingRevisionReadStore();
      await _capturePath(store, '/workspace/failure.md', 'matching source');
      final container = _historyContainer(store, <_FakeTimer>[]);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      await controller.refresh();
      final document = container
          .read(localHistoryControllerProvider)
          .snapshot
          .documents
          .single;
      controller.selectDocument(document.id);

      store.failReads = true;
      await controller.search('matching');

      final state = container.read(localHistoryControllerProvider);
      expect(state.searching, isFalse);
      expect(state.searchQuery, 'matching');
      expect(state.selectedDocumentId, document.id);
      expect(state.searchMatches, isEmpty);
      expect(state.warning?.kind, LocalHistoryWarningKind.revisionRead);
    },
  );

  testWidgets(
    'Local History follows active tabs and clears the visible query without a document dropdown',
    (tester) async {
      final directory = await tester.runAsync(
        () => Directory.systemTemp.createTemp('busymark-history-follow-'),
      );
      final root = directory!;
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      final aPath = p.join(root.path, 'A.md');
      final bPath = p.join(root.path, 'B.md');
      await tester.runAsync(() async {
        await File(aPath).writeAsString('# Unique A\n');
        await File(bPath).writeAsString('# Unique B\n');
      });
      final store = MemoryLocalHistoryStore();
      final container = ProviderContainer(
        overrides: [
          localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
          localHistoryStoreProvider.overrideWithValue(store),
          documentSessionStoreProvider.overrideWithValue(
            MemoryDocumentSessionStore(),
          ),
          documentRecoveryStoreProvider.overrideWithValue(
            MemoryDocumentRecoveryStore(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final workspace = container.read(workspaceControllerProvider.notifier);
      await tester.runAsync(() => workspace.openPath(root.path));
      await tester.runAsync(() => workspace.openActiveFile(bPath));

      tester.view.physicalSize = const Size(300, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
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
      await tester.runAsync(
        () => _waitForHistory(
          container,
          (state) => state.selectedDocument?.currentPath == bPath,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('local-history-context-header')),
        findsNothing,
      );
      expect(find.text('B.md'), findsNothing);
      expect(find.byType(DropdownButton<String>), findsNothing);

      final searchField = find.byType(TextField);
      final actionsMenu = find.byKey(
        const ValueKey('local-history-actions-menu'),
      );
      expect(
        tester.getCenter(actionsMenu).dx,
        greaterThan(tester.getTopRight(searchField).dx),
      );
      expect(searchField, findsOneWidget);
      expect(
        tester.widget<TextField>(searchField).decoration?.hintText,
        'Search local history',
      );
      await tester.enterText(searchField, 'Unique B');
      await tester.runAsync(
        () => _waitForHistory(
          container,
          (state) => !state.searching && state.searchQuery == 'Unique B',
        ),
      );
      final selectedBeforeFocus = container
          .read(localHistoryControllerProvider)
          .selectedDocumentId;
      await tester.tap(searchField);
      await tester.pump();
      expect(
        container.read(localHistoryControllerProvider).selectedDocumentId,
        selectedBeforeFocus,
      );

      await tester.runAsync(() => workspace.openActiveFile(aPath));
      await tester.runAsync(
        () => _waitForHistory(
          container,
          (state) => state.selectedDocument?.currentPath == aPath,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('local-history-context-header')),
        findsNothing,
      );
      expect(find.text('A.md'), findsNothing);
      expect(
        container.read(localHistoryControllerProvider).searchQuery,
        isEmpty,
      );
      expect(tester.widget<TextField>(searchField).controller!.text, isEmpty);

      final panelContext = tester.element(find.byType(LocalHistoryPanel));
      final refreshLabel = MaterialLocalizations.of(
        panelContext,
      ).refreshIndicatorSemanticLabel;
      expect(
        tester.getCenter(actionsMenu).dx,
        greaterThan(tester.getTopRight(searchField).dx),
      );
      expect(find.byTooltip(refreshLabel), findsNothing);
      await tester.tap(actionsMenu);
      await tester.pumpAndSettle();
      expect(find.text(refreshLabel), findsOneWidget);
      expect(find.text('Find in Local History…'), findsOneWidget);
      expect(find.text('Clear This Document’s History'), findsOneWidget);
      expect(find.text('Clear All Local History'), findsOneWidget);
    },
  );

  testWidgets(
    'revision rows use local second-precision time, date groups, event metadata, and RTL',
    (tester) async {
      final directory = await tester.runAsync(
        () => Directory.systemTemp.createTemp('busymark-history-rows-'),
      );
      final root = directory!;
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      final path = p.join(root.path, 'versions.md');
      await tester.runAsync(() => File(path).writeAsString('Disk source\n'));
      final store = MemoryLocalHistoryStore();
      final beforeMidnight = DateTime(2026, 1, 1, 23, 59, 58);
      final afterMidnight = DateTime(2026, 1, 2, 0, 0, 2);
      await tester.runAsync(() async {
        await store.capture(
          LocalHistoryCaptureRequest(
            path: path,
            displayName: 'versions.md',
            source: 'Automatic source',
            format: TextFormatMetadata.utf8Lf,
            capturedAt: beforeMidnight.toUtc(),
            reason: LocalHistoryCaptureReason.automaticCheckpoint,
          ),
          const LocalHistoryPolicy(),
        );
        await store.capture(
          LocalHistoryCaptureRequest(
            path: path,
            displayName: 'versions.md',
            source: 'Saved source',
            format: TextFormatMetadata.utf8Lf,
            capturedAt: afterMidnight.toUtc(),
            reason: LocalHistoryCaptureReason.saved,
          ),
          const LocalHistoryPolicy(),
        );
      });
      final container = ProviderContainer(
        overrides: [
          localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
          localHistoryStoreProvider.overrideWithValue(store),
          localHistoryClockProvider.overrideWithValue(
            () => DateTime.utc(2026, 1, 3),
          ),
        ],
      );
      addTearDown(container.dispose);
      final workspace = container.read(workspaceControllerProvider.notifier);
      await tester.runAsync(() => workspace.openPath(path));

      tester.view.physicalSize = const Size(300, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: LocalHistoryPanel()),
          ),
        ),
      );
      await tester.pump();
      await tester.runAsync(
        () => _waitForHistory(
          container,
          (state) => state.selectedDocument?.currentPath == path,
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(LocalHistoryPanel));
      final l10n = AppLocalizations.of(context);
      final locale = Localizations.localeOf(context).toLanguageTag();
      final beforeLabel = DateFormat.Hms(locale).format(beforeMidnight);
      final afterLabel = DateFormat.Hms(locale).format(afterMidnight);
      expect(Directionality.of(context), TextDirection.rtl);
      final searchField = find.byType(TextField);
      final actionsMenu = find.byKey(
        const ValueKey('local-history-actions-menu'),
      );
      expect(actionsMenu, findsOneWidget);
      expect(searchField, findsOneWidget);
      expect(
        tester.getCenter(actionsMenu).dx,
        greaterThan(tester.getTopRight(searchField).dx),
      );
      expect(find.text(beforeLabel), findsOneWidget);
      expect(find.text(afterLabel), findsOneWidget);
      expect(
        find.byWidgetPredicate((widget) => widget is BusyMarkSidebarRecordRow),
        findsWidgets,
      );
      expect(find.byType(ListTile), findsNothing);
      expect(find.text(l10n.localHistoryReasonSaved), findsOneWidget);
      expect(
        find.text(l10n.localHistoryReasonAutomaticCheckpoint),
        findsNothing,
      );
      expect(find.text(l10n.localHistoryReasonBaseline), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Tooltip &&
              widget.message?.contains(
                    l10n.localHistoryReasonAutomaticCheckpoint,
                  ) ==
                  true,
        ),
        findsOneWidget,
      );
      final revisionSemantics = tester.getSemantics(find.text(afterLabel));
      expect(
        revisionSemantics.label.contains(l10n.localHistoryReasonSaved),
        isTrue,
      );
      expect(
        revisionSemantics.getSemanticsData().hasAction(ui.SemanticsAction.tap),
        isTrue,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
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
      expect(refresh, findsNothing);
      await tester.tap(
        find.byKey(const ValueKey('local-history-actions-menu')),
      );
      await tester.pumpAndSettle();
      final refreshItem = find.byWidgetPredicate(
        (widget) =>
            widget is BusyMarkPopupMenuItem && widget.label == refreshLabel,
      );
      expect(
        tester.widget<BusyMarkPopupMenuItem<dynamic>>(refreshItem).enabled,
        isTrue,
      );
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
    'untitled overwrite Save As retains a failed source checkpoint',
    () async {
      final memory = MemoryLocalHistoryStore();
      const forkPoint = 'untitled source fork point';
      final store = _FailingSourceCaptureStore(memory, forkPoint);
      final controllerContainer = _historyContainer(store, <_FakeTimer>[]);
      addTearDown(controllerContainer.dispose);
      final controller = controllerContainer.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      await controller.refresh();

      final destination = await memory.capture(
        LocalHistoryCaptureRequest(
          path: '/workspace/B.md',
          displayName: 'B.md',
          source: 'existing destination history',
          format: TextFormatMetadata.utf8Lf,
          capturedAt: DateTime.utc(2026),
          reason: LocalHistoryCaptureReason.saved,
        ),
        const LocalHistoryPolicy(),
      );
      final draft = DocumentBuffer.untitled(
        id: 'untitled-overwrite',
        name: 'Draft.md',
        text: 'source baseline',
      );
      await controller.observeOpened(draft);
      final sourceId = controller.documentIdForBuffer(draft.id)!;
      expect(sourceId, isNot(destination.document.id));
      final edited = draft.edited(forkPoint);
      controller.observeEdit(draft, edited);
      await Future<void>.delayed(Duration.zero);
      final destinationTarget = (await store.resolvePathTargets(
        '/workspace/B.md',
        recursive: false,
      )).single;

      expect(
        await controller.captureSavedAs(
          LocalHistoryBufferSnapshot.fromBuffer(edited),
          '/workspace/B.md',
          destinationExisted: true,
          destinationTarget: destinationTarget,
        ),
        isTrue,
      );
      final saved = edited.copyWith(
        filePath: '/workspace/B.md',
        untitledName: null,
        lastSavedText: edited.text,
        dirty: false,
      );
      expect(await controller.flushAll([saved]), isTrue);

      final snapshot = await memory.load();
      final source = snapshot.documents.singleWhere((d) => d.id == sourceId);
      final b = snapshot.documents.singleWhere(
        (d) => d.id == destination.document.id,
      );
      expect(source.currentPath, isNull);
      expect(
        await _revisionSources(memory, snapshot.revisionsFor(source.id)),
        contains(forkPoint),
      );
      expect(
        await _revisionSources(memory, snapshot.revisionsFor(b.id)),
        containsAll(['existing destination history', forkPoint]),
      );
      expect(controller.documentIdForBuffer(saved.id), b.id);
    },
  );

  test(
    'committed Save As source capture is idempotent after a lost result',
    () async {
      final memory = MemoryLocalHistoryStore();
      const sourceText = 'source captured before process loss';
      final failing = _FailingSourceCaptureStore(memory, sourceText);
      final firstContainer = _historyContainer(failing, <_FakeTimer>[]);
      final first = firstContainer.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      const destinationPath = '/workspace/existing.md';
      final destination = await memory.capture(
        LocalHistoryCaptureRequest(
          path: destinationPath,
          displayName: 'existing.md',
          source: 'existing destination',
          format: TextFormatMetadata.utf8Lf,
          capturedAt: DateTime.utc(2026, 1, 1),
          reason: LocalHistoryCaptureReason.saved,
        ),
        const LocalHistoryPolicy(),
      );
      const source = LocalHistoryBufferSnapshot(
        bufferId: 'uncertain-save-as-source',
        displayName: 'Untitled.md',
        text: sourceText,
        format: TextFormatMetadata.utf8Lf,
        revision: 1,
        untitled: true,
      );
      final operationId = await first.stageSavedAsSourceRecovery(
        source,
        destinationExisted: true,
        destination: const LocalHistoryBufferSnapshot(
          bufferId: 'uncertain-save-as-source',
          displayName: 'existing.md',
          text: sourceText,
          format: TextFormatMetadata.utf8Lf,
          revision: 1,
          path: destinationPath,
        ),
      );
      expect(operationId, isNotNull);
      expect(await first.commitSavedAsSourceRecovery(operationId), isTrue);
      final operation = first.pendingSaveAsOperation(operationId)!;
      expect(operation.sourceDocumentId, isNull);
      final captureId = operation.source.captureId!;

      final committedSource = await memory.capture(
        LocalHistoryCaptureRequest(
          displayName: operation.source.displayName,
          source: operation.source.source,
          format: operation.source.format,
          capturedAt: DateTime.utc(2026, 1, 1, 0, 1),
          reason: LocalHistoryCaptureReason.automaticCheckpoint,
          untitled: true,
          force: true,
          captureId: captureId,
        ),
        const LocalHistoryPolicy(),
      );
      // The injected staging failure has already served its purpose; recovery
      // now exercises the lost-result replay against the committed capture.
      failing.failed = true;
      firstContainer.dispose();

      final restoredContainer = _historyContainer(failing, <_FakeTimer>[]);
      addTearDown(restoredContainer.dispose);
      final restored = restoredContainer.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      restored.restorePendingSaveAsOperations([operation]);
      await restored.recoverCommittedSaveAs(operation);
      expect(await restored.flushAll(const []), isTrue);

      final snapshot = await memory.load();
      expect(
        snapshot.revisions.where((revision) => revision.id == captureId),
        hasLength(1),
      );
      expect(
        snapshot.documents
            .singleWhere(
              (document) => document.id == committedSource.document.id,
            )
            .id,
        isNot(destination.document.id),
      );
      expect(
        await _revisionSources(
          memory,
          snapshot.revisionsFor(committedSource.document.id),
        ),
        [sourceText],
      );
    },
  );

  test(
    'Save As recovery never adopts unrelated same-content destination history',
    () async {
      final store = MemoryLocalHistoryStore();
      final container = _historyContainer(store, <_FakeTimer>[]);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final source = _fileBuffer(
        'same-content-save-as',
        '/workspace/a.md',
        'identical saved text',
      );
      await controller.observeOpened(source);
      final sourceId = controller.documentIdForBuffer(source.id)!;
      const destinationCaptureId = 'save_as_destination_capture_01';
      final unrelated = await store.capture(
        LocalHistoryCaptureRequest(
          path: '/workspace/b.md',
          displayName: 'b.md',
          source: source.text,
          format: source.format,
          capturedAt: DateTime.utc(2026, 1, 2),
          reason: LocalHistoryCaptureReason.saved,
        ),
        const LocalHistoryPolicy(),
      );

      expect(
        await controller.captureSavedAs(
          LocalHistoryBufferSnapshot.fromBuffer(source),
          '/workspace/b.md',
          destinationExisted: false,
          destinationCaptureId: destinationCaptureId,
        ),
        isFalse,
      );
      final snapshot = await store.load();
      expect(
        snapshot.revisions.any(
          (revision) => revision.id == destinationCaptureId,
        ),
        isFalse,
      );
      expect(snapshot.revisionsFor(unrelated.document.id), hasLength(1));
      expect(unrelated.document.id, isNot(sourceId));
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
    'excluding a recovered first-save destination preserves its untitled source baseline',
    () async {
      final container = _historyContainer(
        MemoryLocalHistoryStore(),
        <_FakeTimer>[],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      const owner = 'history-promotion:policy:424242:1';
      const source = LocalHistoryRetainedSnapshot(
        displayName: 'Untitled',
        source: 'source baseline',
        format: TextFormatMetadata.utf8Lf,
        revision: 1,
        untitled: true,
        captureId: 'source_capture_000001',
      );
      const destination = LocalHistoryRetainedSnapshot(
        displayName: 'Q.md',
        source: 'saved destination',
        format: TextFormatMetadata.utf8Lf,
        revision: 1,
        path: '/excluded/Q.md',
        captureId: 'destination_capture_01',
      );
      controller.restoreRetainedDetachedCaptures(const [
        LocalHistoryRetainedCapture(
          ownerId: owner,
          baseline: source,
          baselineSaveDestination: destination,
          protection: LocalHistoryRetainedProtection(
            snapshot: destination,
            reason: LocalHistoryCaptureReason.saved,
            force: false,
            ignoreBinding: true,
            allowPathChange: true,
            bindResult: true,
            requireVacantPath: true,
            captureId: 'destination_capture_01',
          ),
        ),
      ]);

      await container
          .read(appSettingsControllerProvider.notifier)
          .setLocalHistoryExcludedPaths(['/excluded']);
      await Future<void>.delayed(Duration.zero);

      final retained = controller.retainedDetachedCaptures.single;
      expect(retained.ownerId, owner);
      expect(retained.baseline?.source, 'source baseline');
      expect(retained.baselineSaveDestination, isNull);
      expect(retained.protection, isNull);
      expect(await controller.flushAll(const []), isTrue);
      final snapshot = await container.read(localHistoryStoreProvider).load();
      expect(snapshot.documents, hasLength(1));
      final revision = await container
          .read(localHistoryStoreProvider)
          .readRevision(snapshot.revisions.single.id);
      expect(revision?.source, 'source baseline');
    },
  );

  test(
    'queued committed Save As cannot recreate a newly excluded destination side',
    () async {
      final memory = MemoryLocalHistoryStore();
      final store = _BlockingNextCaptureStore(memory);
      final container = _historyContainer(store, <_FakeTimer>[]);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final opened = DocumentBuffer.untitled(
        id: 'policy-save-as',
        name: 'Untitled',
        text: 'source baseline',
      );
      await controller.observeOpened(opened);
      final saved = opened.edited('saved first-save text');
      const destinationPath = '/excluded/Q.md';
      final source = LocalHistoryBufferSnapshot.fromBuffer(saved);
      final destination = LocalHistoryBufferSnapshot(
        bufferId: saved.id,
        displayName: 'Q.md',
        text: saved.text,
        format: saved.format,
        revision: saved.revision,
        path: destinationPath,
      );
      final operationId = await controller.stageSavedAsSourceRecovery(
        source,
        destinationExisted: false,
        destination: destination,
      );
      expect(operationId, isNotNull);
      expect(await controller.beginSavedAsSourceRecovery(operationId), isTrue);
      expect(await controller.commitSavedAsSourceRecovery(operationId), isTrue);
      final operation = controller.pendingSaveAsOperation(operationId)!;

      store.blockNextCapture = true;
      final blocker = controller.captureBeforeLoss(
        LocalHistoryBufferSnapshot.fromBuffer(opened.edited('queue blocker')),
        LocalHistoryCaptureReason.beforeDiscard,
      );
      await store.captureStarted.future;
      final saveCapture = controller.captureSavedAs(
        source,
        destinationPath,
        destinationExisted: false,
        recordSourceHistory: operation.recordSourceHistory,
        recordDestinationHistory: operation.recordDestinationHistory,
        sourceCaptureId: operation.source.captureId,
        destinationCaptureId: operation.destination.captureId,
        sourceAcceptedClearEpoch: operation.source.acceptedClearEpoch,
        destinationAcceptedClearEpoch: operation.destination.acceptedClearEpoch,
        sourceAcceptedAt: operation.source.acceptedAt,
        destinationAcceptedAt: operation.destination.acceptedAt,
        sourceAcceptedDocumentId: operation.source.acceptedDocumentId,
        destinationAcceptedDocumentId: operation.destination.acceptedDocumentId,
        saveAsOperationId: operationId,
      );

      await container
          .read(appSettingsControllerProvider.notifier)
          .setLocalHistoryExcludedPaths(['/excluded']);
      await Future<void>.delayed(Duration.zero);
      store.releaseCapture.complete();
      await blocker;
      await saveCapture;

      expect(
        controller
            .pendingSaveAsOperation(operationId)
            ?.recordDestinationHistory,
        isFalse,
      );
      expect(
        controller.pendingIdentityPromotions.where(
          (promotion) => promotion.destinationPath == destinationPath,
        ),
        isEmpty,
      );
      expect(
        controller.retainedDetachedCaptures.where(
          (capture) =>
              capture.baselineSaveDestination?.path == destinationPath ||
              capture.protection?.snapshot.path == destinationPath,
        ),
        isEmpty,
      );
      expect(
        (await memory.load()).documents.where(
          (document) => document.currentPath == destinationPath,
        ),
        isEmpty,
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
    'flush retries a failed first-save promotion without another edit',
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
        id: 'draft-flush-retry',
        name: 'Draft.md',
        text: 'Retained before first save\n',
      );
      await controller.observeOpened(untitled);
      final originalDocument = (await store.load()).documents.single;
      expect(
        await controller.captureSavedAs(
          LocalHistoryBufferSnapshot.fromBuffer(untitled),
          '/workspace/Guide.md',
          destinationExisted: false,
        ),
        isFalse,
      );
      final saved = untitled.copyWith(
        filePath: '/workspace/Guide.md',
        untitledName: null,
        lastSavedText: untitled.text,
        dirty: false,
      );

      expect(await controller.flushAll([saved]), isTrue);
      final snapshot = await store.load();
      expect(snapshot.documents, hasLength(1));
      expect(snapshot.documents.single.id, originalDocument.id);
      expect(snapshot.documents.single.currentPath, '/workspace/Guide.md');
      expect(snapshot.revisionsFor(originalDocument.id), hasLength(1));
    },
  );

  test(
    'flush reports a content failure after successfully retrying promotion',
    () async {
      final store = _FailingPromotionThenCaptureStore('pending named source');
      final container = _historyContainer(store, <_FakeTimer>[]);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final untitled = DocumentBuffer.untitled(
        id: 'promotion-content-failure',
        name: 'Draft.md',
        text: 'initial source',
      );
      await controller.observeOpened(untitled);
      final pending = untitled.edited('pending named source');
      controller.observeEdit(untitled, pending);
      await Future<void>.delayed(Duration.zero);
      expect(
        await controller.captureSavedAs(
          LocalHistoryBufferSnapshot.fromBuffer(pending),
          '/workspace/Promoted.md',
          destinationExisted: false,
        ),
        isFalse,
      );
      expect(controller.hasPendingIdentityPromotion(untitled.id), isTrue);
      final named = pending.copyWith(
        filePath: '/workspace/Promoted.md',
        untitledName: null,
        lastSavedText: pending.text,
        dirty: false,
      );

      expect(await controller.flushBuffer(named), isFalse);
      expect(controller.hasPendingIdentityPromotion(named.id), isFalse);
      expect(controller.pendingSnapshotForBuffer(named.id), isNotNull);
      expect(
        container.read(localHistoryControllerProvider).warning?.kind,
        LocalHistoryWarningKind.capture,
      );

      expect(await controller.flushBuffer(named), isTrue);
      expect(controller.pendingSnapshotForBuffer(named.id), isNull);
      final snapshot = await store.load();
      expect(snapshot.documents.single.currentPath, '/workspace/Promoted.md');
      expect(
        await _revisionSources(
          store,
          snapshot.revisionsFor(snapshot.documents.single.id),
        ),
        contains(pending.text),
      );
    },
  );

  test(
    'remap settles pending first-save promotions for files and directories',
    () async {
      final scenarios = [
        (
          initialPath: '/workspace/A.md',
          sourcePath: '/workspace/A.md',
          destinationPath: '/workspace/B.md',
          finalPath: '/workspace/B.md',
        ),
        (
          initialPath: '/workspace/drafts/A.md',
          sourcePath: '/workspace/drafts',
          destinationPath: '/workspace/archive/drafts',
          finalPath: '/workspace/archive/drafts/A.md',
        ),
      ];
      for (var index = 0; index < scenarios.length; index += 1) {
        final scenario = scenarios[index];
        final store = _FailingFirstPromotionStore();
        final container = _historyContainer(store, <_FakeTimer>[]);
        addTearDown(container.dispose);
        final controller = container.read(
          localHistoryControllerProvider.notifier,
        );
        await Future<void>.delayed(Duration.zero);
        await controller.refresh();
        final untitled = DocumentBuffer.untitled(
          id: 'draft-remap-$index',
          name: 'Draft.md',
          text: 'Original lineage $index\n',
        );
        await controller.observeOpened(untitled);
        final originalDocument = (await store.load()).documents.single;
        expect(
          await controller.captureSavedAs(
            LocalHistoryBufferSnapshot.fromBuffer(untitled),
            scenario.initialPath,
            destinationExisted: false,
          ),
          isFalse,
        );

        await controller.remapPath(
          scenario.sourcePath,
          scenario.destinationPath,
        );
        final moved = untitled.copyWith(
          filePath: scenario.finalPath,
          untitledName: null,
          lastSavedText: untitled.text,
          dirty: false,
        );
        expect(
          await controller.captureSaved(
            LocalHistoryBufferSnapshot.fromBuffer(
              moved.edited('Recorded after remap $index\n'),
            ),
          ),
          isTrue,
        );

        final snapshot = await store.load();
        expect(snapshot.documents, hasLength(1));
        expect(snapshot.documents.single.id, originalDocument.id);
        expect(snapshot.documents.single.currentPath, scenario.finalPath);
        expect(
          await _revisionSources(
            store,
            snapshot.revisionsFor(originalDocument.id),
          ),
          containsAll([
            'Original lineage $index\n',
            'Recorded after remap $index\n',
          ]),
        );
      }
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

  test(
    'failed path reconciliation blocks affected captures but not unrelated documents',
    () async {
      final store = _ControllableRemapStore()..failRemaps = true;
      final timers = <_FakeTimer>[];
      final container = _historyContainer(store, timers);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final moved = _fileBuffer('moved', '/workspace/a.md', 'A baseline');
      final unrelated = _fileBuffer(
        'unrelated',
        '/workspace/unrelated.md',
        'unrelated baseline',
      );
      await controller.observeOpened(moved);
      await controller.observeOpened(unrelated);

      await controller.remapPath('/workspace/a.md', '/workspace/b.md');
      expect(
        controller.warningForBuffer(moved.id)?.kind,
        LocalHistoryWarningKind.pathChange,
      );
      expect(controller.warningForBuffer(unrelated.id), isNull);
      expect(
        await controller.captureSaved(
          LocalHistoryBufferSnapshot.fromBuffer(
            unrelated.edited('unrelated saved while remap failed'),
          ),
        ),
        isTrue,
      );
      expect(
        await controller.captureSaved(
          LocalHistoryBufferSnapshot.fromBuffer(
            moved
                .copyWith(filePath: '/workspace/b.md')
                .edited('affected save waits'),
          ),
        ),
        isFalse,
      );

      store.failRemaps = false;
      expect(
        await controller.flushAll([
          moved.copyWith(filePath: '/workspace/b.md'),
          unrelated,
        ]),
        isTrue,
      );
      final snapshot = await store.load();
      final movedDocument = snapshot.documents.singleWhere(
        (document) => document.currentPath == '/workspace/b.md',
      );
      final unrelatedDocument = snapshot.documents.singleWhere(
        (document) => document.currentPath == '/workspace/unrelated.md',
      );
      expect(
        await _revisionSources(store, snapshot.revisionsFor(movedDocument.id)),
        contains('affected save waits'),
      );
      expect(
        await _revisionSources(
          store,
          snapshot.revisionsFor(unrelatedDocument.id),
        ),
        contains('unrelated saved while remap failed'),
      );
    },
  );

  test(
    'successful path queue prefix is published before a later failure',
    () async {
      final store = _ControllableRemapStore()..failRemaps = true;
      final container = _historyContainer(store, <_FakeTimer>[]);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final original = _fileBuffer('prefix-owner', '/workspace/a.md', 'A');
      await controller.observeOpened(original);
      await controller.remapPath('/workspace/a.md', '/workspace/b.md');
      await controller.markDeleted('/workspace/b.md', recursive: false);

      store
        ..failRemaps = false
        ..failDeletions = true;
      expect(
        await controller.flushAll([
          original.copyWith(filePath: '/workspace/b.md'),
        ]),
        isFalse,
      );
      expect(
        (await store.load()).documents.single.currentPath,
        '/workspace/b.md',
      );
      expect(
        container
            .read(localHistoryControllerProvider)
            .snapshot
            .documents
            .single
            .currentPath,
        '/workspace/b.md',
      );
      final attempts = store.remapAttempts;
      store.failDeletions = false;
      expect(await controller.flushAll(const []), isTrue);
      expect(store.remapAttempts, attempts);
      expect((await store.load()).documents.single.deleted, isTrue);
    },
  );

  test('path deletion warnings remain scoped to affected owners', () async {
    final store = _ControllableRemapStore()..failDeletions = true;
    final container = _historyContainer(store, <_FakeTimer>[]);
    addTearDown(container.dispose);
    final controller = container.read(localHistoryControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    final deleted = _fileBuffer('delete-owner', '/workspace/a.md', 'A');
    final unrelated = _fileBuffer('delete-unrelated', '/workspace/c.md', 'C');
    await controller.observeOpened(deleted);
    await controller.observeOpened(unrelated);

    await controller.markDeleted('/workspace/a.md', recursive: false);
    expect(
      controller.warningForBuffer(deleted.id)?.kind,
      LocalHistoryWarningKind.deletedPath,
    );
    expect(controller.warningForBuffer(unrelated.id), isNull);

    store.failDeletions = false;
    expect(await controller.flushAll([deleted, unrelated]), isTrue);
    expect(controller.warningForBuffer(deleted.id), isNull);
    expect(
      (await store.load()).documents
          .singleWhere((document) => document.currentPath == '/workspace/a.md')
          .deleted,
      isTrue,
    );
  });

  test(
    'committed path operation is not replayed after refresh failure',
    () async {
      final store = _ControllableRemapStore()..failRemaps = true;
      final container = _historyContainer(store, <_FakeTimer>[]);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final original = _fileBuffer('refresh-failure', '/workspace/a.md', 'A');
      await controller.observeOpened(original);
      await controller.remapPath('/workspace/a.md', '/workspace/b.md');

      store
        ..failRemaps = false
        ..failNextLoad = true;
      expect(
        await controller.flushAll([
          original.copyWith(filePath: '/workspace/b.md'),
        ]),
        isTrue,
      );
      final attempts = store.remapAttempts;
      expect(
        (await store.load()).documents.single.currentPath,
        '/workspace/b.md',
      );
      expect(await controller.flushAll(const []), isTrue);
      expect(store.remapAttempts, attempts);
      await controller.refresh();
      expect(
        container
            .read(localHistoryControllerProvider)
            .snapshot
            .documents
            .single
            .currentPath,
        '/workspace/b.md',
      );
    },
  );

  test(
    'restored targetless executing reconciliation preserves its owner',
    () async {
      final container = _historyContainer(
        MemoryLocalHistoryStore(),
        <_FakeTimer>[],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final reconciliation = LocalHistoryPathReconciliation.remap(
        operationId: 'lh${pid}_123456789_901',
        sourcePath: '/workspace/cleared-a.md',
        destinationPath: '/workspace/cleared-b.md',
        targets: const [],
        ownerIds: const ['restored-buffer'],
        phase: LocalHistoryPathReconciliationPhase.executing,
      );

      expect(
        await controller.restorePendingPathReconciliations([reconciliation]),
        isFalse,
      );
      expect(controller.pendingPathReconciliations.single.ownerIds, [
        'restored-buffer',
      ]);
    },
  );

  test(
    'staged path commit survives refresh failure until workspace acknowledgement',
    () async {
      final store = _ControllableRemapStore();
      final container = _historyContainer(store, <_FakeTimer>[]);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final original = _fileBuffer(
        'staged-refresh',
        '/workspace/staged-a.md',
        'A',
      );
      await controller.observeOpened(original);
      store.failNextLoad = true;
      String? operationId;
      expect(
        await controller.runStagedPathRemap(
          sourcePath: '/workspace/staged-a.md',
          destinationPath: '/workspace/staged-b.md',
          boundBufferId: original.id,
          filesystemOperation: () async => true,
          didCommit: (value) => value,
          onOperationStaged: (value) => operationId = value,
        ),
        isTrue,
      );
      final attempts = store.remapAttempts;
      expect(controller.pendingPathReconciliations, hasLength(1));
      await controller.acknowledgeStagedPathOperation(operationId);
      expect(controller.pendingPathReconciliations, hasLength(1));
      expect(
        controller.state.snapshot.documents.single.currentPath,
        '/workspace/staged-a.md',
      );

      expect(await controller.flushAll(const []), isTrue);
      expect(store.remapAttempts, attempts);
      expect(controller.pendingPathReconciliations, isEmpty);
      expect(
        controller.state.snapshot.documents.single.currentPath,
        '/workspace/staged-b.md',
      );
    },
  );

  test(
    'external staged remap refreshes its bound target after checkpoint settlement',
    () async {
      final store = MemoryLocalHistoryStore();
      final container = _historyContainer(store, <_FakeTimer>[]);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final original = _fileBuffer(
        'dirty-external-remap',
        '/workspace/dirty-a.md',
        'A',
      );
      await controller.observeOpened(original);
      final edited = original.edited('dirty edit before external move');
      controller.observeEdit(original, edited);
      await Future<void>.delayed(Duration.zero);

      expect(
        await controller.runStagedPathRemap(
          sourcePath: '/workspace/dirty-a.md',
          destinationPath: '/workspace/dirty-b.md',
          boundBufferId: original.id,
          filesystemAlreadyCommitted: true,
          filesystemOperation: () async => true,
          didCommit: (value) => value,
        ),
        isTrue,
      );
      expect(controller.pendingPathReconciliations, hasLength(1));
      final snapshot = await store.load();
      expect(snapshot.documents.single.currentPath, '/workspace/dirty-b.md');
      expect(
        await _revisionSources(
          store,
          snapshot.revisionsFor(snapshot.documents.single.id),
        ),
        contains('dirty edit before external move'),
      );
    },
  );

  test(
    'definitive false staged result retires its executing journal',
    () async {
      final store = MemoryLocalHistoryStore();
      final container = _historyContainer(store, <_FakeTimer>[]);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final original = _fileBuffer(
        'false-staged-remap',
        '/workspace/false-a.md',
        'A',
      );
      await controller.observeOpened(original);
      String? operationId;

      expect(
        await controller.runStagedPathRemap(
          sourcePath: '/workspace/false-a.md',
          destinationPath: '/workspace/false-b.md',
          boundBufferId: original.id,
          filesystemAlreadyCommitted: true,
          filesystemOperation: () async => false,
          didCommit: (value) => value,
          onOperationStaged: (value) => operationId = value,
        ),
        isFalse,
      );
      expect(operationId, isNotNull);
      expect(controller.pendingPathReconciliations, isEmpty);
      expect(controller.retiredPathReconciliationIds, contains(operationId));
      expect(
        (await store.load()).documents.single.currentPath,
        original.filePath,
      );
    },
  );

  test('deferred deletion cannot delete replacement path history', () async {
    final store = _ControllableRemapStore()..failDeletions = true;
    final container = _historyContainer(store, <_FakeTimer>[]);
    addTearDown(container.dispose);
    final controller = container.read(localHistoryControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    final original = _fileBuffer('stale-delete', '/workspace/b.md', 'old B');
    await controller.observeOpened(original);
    final originalId = controller.documentIdForBuffer(original.id)!;
    await controller.markDeleted('/workspace/b.md', recursive: false);

    await store.clearDocument(originalId);
    final replacement = await store.capture(
      LocalHistoryCaptureRequest(
        path: '/workspace/b.md',
        displayName: 'b.md',
        source: 'replacement B',
        format: TextFormatMetadata.utf8Lf,
        capturedAt: DateTime.utc(2026),
        reason: LocalHistoryCaptureReason.saved,
      ),
      const LocalHistoryPolicy(),
    );
    store.failDeletions = false;
    expect(await controller.flushAll(const []), isTrue);
    final snapshot = await store.load();
    final retained = snapshot.documents.singleWhere(
      (document) => document.id == replacement.document.id,
    );
    expect(retained.currentPath, '/workspace/b.md');
    expect(retained.deleted, isFalse);
  });

  test(
    'Clear Document removes only its recursive reconciliation target',
    () async {
      final store = _ControllableRemapStore()..failRemaps = true;
      final container = _historyContainer(store, <_FakeTimer>[]);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final first = _fileBuffer('recursive-first', '/workspace/old/a.md', 'A');
      final second = _fileBuffer(
        'recursive-second',
        '/workspace/old/c.md',
        'C',
      );
      await controller.observeOpened(first);
      await controller.observeOpened(second);
      final firstId = controller.documentIdForBuffer(first.id)!;
      final secondId = controller.documentIdForBuffer(second.id)!;
      await controller.remapPath('/workspace/old', '/workspace/new');

      await controller.clearDocument(firstId);
      store.failRemaps = false;
      expect(await controller.flushAll(const []), isTrue);
      final snapshot = await store.load();
      expect(
        snapshot.documents.any((document) => document.id == firstId),
        isFalse,
      );
      final retained = snapshot.documents.singleWhere(
        (document) => document.id == secondId,
      );
      expect(retained.currentPath, '/workspace/new/c.md');
    },
  );

  test(
    'Clear Document preserves timer retry for remaining recursive target',
    () async {
      final store = _ControllableRemapStore()..failRemaps = true;
      final timers = <_FakeTimer>[];
      final container = _historyContainer(store, timers);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final first = _fileBuffer('timer-first', '/workspace/old/a.md', 'A');
      final second = _fileBuffer('timer-second', '/workspace/old/c.md', 'C');
      await controller.observeOpened(first);
      await controller.observeOpened(second);
      final firstId = controller.documentIdForBuffer(first.id)!;
      final secondId = controller.documentIdForBuffer(second.id)!;

      await controller.remapPath('/workspace/old', '/workspace/new');
      await controller.clearDocument(firstId);
      store.failRemaps = false;
      timers.lastWhere((timer) => timer.isActive).fire();
      await _waitForHistory(container, (state) {
        final retained = state.snapshot.documents
            .where((document) => document.id == secondId)
            .firstOrNull;
        return retained?.currentPath == '/workspace/new/c.md';
      });

      final snapshot = await store.load();
      expect(
        snapshot.documents
            .singleWhere((document) => document.id == secondId)
            .currentPath,
        '/workspace/new/c.md',
      );
      expect(controller.pendingPathReconciliations, isEmpty);
    },
  );

  test(
    'prepared remap rejects a checkpoint that changed its frozen target',
    () async {
      final store = _ControllableRemapStore();
      final container = _historyContainer(store, <_FakeTimer>[]);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final original = _fileBuffer('prepared-owner', '/workspace/a.md', 'A');
      await controller.observeOpened(original);
      final originalId = controller.documentIdForBuffer(original.id)!;
      final prepared = await controller.preparePathReconciliation(
        '/workspace/a.md',
        recursive: false,
      );

      await store.capture(
        LocalHistoryCaptureRequest(
          documentId: originalId,
          path: '/workspace/a.md',
          displayName: 'a.md',
          source: 'replacement revision',
          format: TextFormatMetadata.utf8Lf,
          capturedAt: DateTime.utc(2026, 2),
          reason: LocalHistoryCaptureReason.saved,
        ),
        const LocalHistoryPolicy(),
      );
      await controller.remapPath(
        '/workspace/a.md',
        '/workspace/b.md',
        preparedTargets: prepared,
      );

      final snapshot = await store.load();
      expect(
        snapshot.documents
            .singleWhere((document) => document.id == originalId)
            .currentPath,
        '/workspace/a.md',
      );
      expect(controller.pendingPathReconciliations, hasLength(1));
      expect(
        controller.warningForBuffer(original.id)?.kind,
        LocalHistoryWarningKind.pathChange,
      );
      expect(await controller.flushAll(<DocumentBuffer>[original]), isFalse);
    },
  );

  test(
    'ownerless path failure is visible only in history presentation',
    () async {
      final store = _ControllableRemapStore()..failRemaps = true;
      final container = _historyContainer(store, <_FakeTimer>[]);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      await controller.capturePath(
        path: '/workspace/closed.md',
        text: 'closed',
        format: TextFormatMetadata.utf8Lf,
        reason: LocalHistoryCaptureReason.saved,
      );
      final unrelated = _fileBuffer(
        'warning-unrelated',
        '/workspace/c.md',
        'C',
      );
      await controller.observeOpened(unrelated);

      await controller.remapPath('/workspace/closed.md', '/workspace/moved.md');

      expect(controller.warningForBuffer(unrelated.id), isNull);
      expect(
        container.read(localHistoryControllerProvider).warning?.kind,
        LocalHistoryWarningKind.pathChange,
      );
    },
  );

  test(
    'detached promotion capture is included in durable retained work',
    () async {
      final store = MemoryLocalHistoryStore();
      final container = _historyContainer(store, <_FakeTimer>[]);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      controller.restoreRetainedDetachedCaptures([
        LocalHistoryRetainedCapture(
          ownerId: 'history-promotion:source-id',
          documentId: 'source-id',
          pending: const LocalHistoryRetainedSnapshot(
            displayName: 'A.md',
            source: 'pending A',
            format: TextFormatMetadata.utf8Lf,
            revision: 3,
            path: '/workspace/A.md',
          ),
        ),
      ]);

      expect(controller.retainedDetachedCaptures, hasLength(1));
      expect(
        controller.retainedDetachedCaptures.single.pending?.source,
        'pending A',
      );
    },
  );

  test(
    'live external retained owner is not replayed and Clear All retires it',
    () async {
      if (!Platform.isLinux) return;
      final ownerProcess = await Process.start('sleep', ['30']);
      addTearDown(() async {
        ownerProcess.kill();
        await ownerProcess.exitCode;
      });
      final store = MemoryLocalHistoryStore();
      final container = _historyContainer(store, <_FakeTimer>[]);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final processStart = _linuxProcessStartIdentity(ownerProcess.pid);
      final operationToken = 'lh${ownerProcess.pid}_${processStart}_999';
      final owner = 'history-capture:$operationToken:1';
      final saveAsOwner = 'history-save-as:$operationToken:2';
      final promotionOwner = 'history-promotion:$operationToken:3';
      final unverifiedOwner =
          'history-capture:external:${ownerProcess.pid}:123456789:1';
      expect(controller.operationOwnerIsLiveOtherProcess(owner), isTrue);
      expect(
        controller.operationOwnerIsLiveOtherProcess(unverifiedOwner),
        isFalse,
      );
      expect(
        controller.operationOwnerIsDefinitelyDead(unverifiedOwner),
        isTrue,
      );

      controller.restoreRetainedDetachedCaptures([
        LocalHistoryRetainedCapture(
          ownerId: owner,
          baseline: const LocalHistoryRetainedSnapshot(
            displayName: 'External.md',
            source: 'owned by the live process',
            format: TextFormatMetadata.utf8Lf,
            revision: 0,
          ),
        ),
      ]);

      expect(controller.retainedDetachedCaptures, isEmpty);
      expect((await store.load()).documents, isEmpty);
      controller.restorePendingSaveAsOperations([
        LocalHistoryPendingSaveAs(
          operationId: saveAsOwner,
          bufferId: 'external-buffer',
          sourceDocumentId: null,
          destinationDocumentId: null,
          source: const LocalHistoryRetainedSnapshot(
            displayName: 'External.md',
            source: 'source',
            format: TextFormatMetadata.utf8Lf,
            revision: 1,
          ),
          destination: const LocalHistoryRetainedSnapshot(
            displayName: 'Destination.md',
            source: 'source',
            format: TextFormatMetadata.utf8Lf,
            revision: 1,
            path: '/workspace/Destination.md',
          ),
          destinationExisted: false,
          phase: LocalHistoryPathReconciliationPhase.committed,
        ),
      ]);
      controller.leavePendingSaveAsOwnedExternally(saveAsOwner);
      controller.restorePendingIdentityPromotion(
        LocalHistoryPendingIdentityPromotion(
          bufferId: promotionOwner,
          documentId: 'document_000000000001',
          destinationPath: '/workspace/Promoted.md',
          displayName: 'Promoted.md',
        ),
      );
      await controller.clearAll();
      expect(
        controller.retiredDurableWorkOwnerIds,
        containsAll([owner, saveAsOwner, promotionOwner]),
      );
    },
  );

  test('a clear conflict cancels the old baseline retry owner', () async {
    final store = _ClearConflictOnceStore();
    final timers = <_FakeTimer>[];
    final container = _historyContainer(store, timers);
    addTearDown(container.dispose);
    final controller = container.read(localHistoryControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    final opened = _fileBuffer(
      'clear-conflict',
      '/workspace/clear-conflict.md',
      'pre-clear baseline',
    );

    await controller.observeOpened(opened);
    expect(controller.pendingSnapshotForBuffer(opened.id), isNull);
    final edited = opened.edited('post-clear edit');
    controller.observeEdit(opened, edited);
    await Future<void>.delayed(Duration.zero);
    timers.lastWhere((timer) => timer.isActive).fire();
    await _waitForHistory(
      container,
      (state) => state.snapshot.revisions.length == 2,
    );

    expect(await controller.flushBuffer(edited), isTrue);
    expect(
      await _revisionSources(store, (await store.load()).revisions),
      containsAll(['pre-clear baseline', 'post-clear edit']),
    );
    expect(controller.warningForBuffer(opened.id), isNull);
  });

  test(
    'edit after failed Clear waits and persists in the replacement lineage',
    () async {
      final store = _FailingClearOnceStore();
      final container = _historyContainer(store, <_FakeTimer>[]);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final opened = _fileBuffer(
        'failed-clear-edit',
        '/workspace/failed-clear.md',
        'before clear',
      );
      await controller.observeOpened(opened);
      final oldDocumentId = controller.documentIdForBuffer(opened.id)!;
      await expectLater(
        controller.clearDocument(oldDocumentId),
        throwsA(isA<LocalHistoryStorageException>()),
      );

      final edited = opened.edited('edit after failed clear');
      controller.observeEdit(opened, edited);
      await Future<void>.delayed(Duration.zero);
      expect(await controller.flushBuffer(edited), isFalse);
      expect(controller.pendingSnapshotForBuffer(opened.id), isNotNull);

      store.clearsAvailable = true;
      expect(await controller.flushBuffer(edited), isTrue);
      final snapshot = await store.load();
      expect(
        snapshot.documents.where((document) => document.id == oldDocumentId),
        isEmpty,
      );
      final replacement = snapshot.documents.singleWhere(
        (document) => document.currentPath == '/workspace/failed-clear.md',
      );
      expect(replacement.id, isNot(oldDocumentId));
      expect(
        await _revisionSources(store, snapshot.revisionsFor(replacement.id)),
        contains('edit after failed clear'),
      );
    },
  );

  test(
    'post-Clear edit uses committed epoch when reconciliation refresh fails',
    () async {
      final store = _FailingClearOnceStore();
      final container = _historyContainer(store, <_FakeTimer>[]);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final opened = _fileBuffer(
        'clear-refresh-edit',
        '/workspace/clear-refresh.md',
        'before clear',
      );
      await controller.observeOpened(opened);
      final oldDocumentId = controller.documentIdForBuffer(opened.id)!;
      await expectLater(
        controller.clearDocument(oldDocumentId),
        throwsA(isA<LocalHistoryStorageException>()),
      );
      final edited = opened.edited('retained after clear refresh failure');
      controller.observeEdit(opened, edited);
      await Future<void>.delayed(Duration.zero);

      store
        ..clearsAvailable = true
        ..failLoadAfterClear = true;
      expect(await controller.flushBuffer(edited), isFalse);
      expect(controller.pendingClearOperations, hasLength(1));
      store.failLoadAfterClear = false;
      expect(await controller.flushBuffer(edited), isTrue);
      expect(controller.pendingClearOperations, isEmpty);
      final snapshot = await store.load();
      final replacement = snapshot.documents.singleWhere(
        (document) => document.currentPath == '/workspace/clear-refresh.md',
      );
      expect(replacement.id, isNot(oldDocumentId));
      expect(
        await _revisionSources(store, snapshot.revisionsFor(replacement.id)),
        contains('retained after clear refresh failure'),
      );
      expect(controller.pendingSnapshotForBuffer(opened.id), isNull);
    },
  );

  test('deferred remap cannot mutate replacement path history', () async {
    final store = _ControllableRemapStore()..failRemaps = true;
    final container = _historyContainer(store, <_FakeTimer>[]);
    addTearDown(container.dispose);
    final controller = container.read(localHistoryControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    final original = _fileBuffer('stale-remap', '/workspace/a.md', 'old A');
    await controller.observeOpened(original);
    final originalId = controller.documentIdForBuffer(original.id)!;
    await controller.remapPath('/workspace/a.md', '/workspace/b.md');
    await controller.clearDocument(originalId);

    final independentContainer = _historyContainer(store, <_FakeTimer>[]);
    addTearDown(independentContainer.dispose);
    final independent = independentContainer.read(
      localHistoryControllerProvider.notifier,
    );
    await Future<void>.delayed(Duration.zero);
    await independent.refresh();
    final replacement = _fileBuffer(
      'replacement-after-clear',
      '/workspace/a.md',
      'replacement A',
    );
    await independent.observeOpened(replacement);
    final replacementId = independent.documentIdForBuffer(replacement.id)!;
    expect(replacementId, isNot(originalId));

    store.failRemaps = false;
    expect(await controller.flushAll(const []), isTrue);
    final snapshot = await store.load();
    final retained = snapshot.documents.singleWhere(
      (document) => document.id == replacementId,
    );
    expect(retained.currentPath, '/workspace/a.md');
    expect(
      snapshot.documents.where((d) => d.currentPath == '/workspace/b.md'),
      isEmpty,
    );
  });

  test(
    'failed remap reserves source and destination paths until reconciliation',
    () async {
      final store = _ControllableRemapStore()..failRemaps = true;
      final timers = <_FakeTimer>[];
      final container = _historyContainer(store, timers);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final original = _fileBuffer(
        'remap-original',
        '/workspace/a.md',
        'original A',
      );
      await controller.observeOpened(original);
      final originalId = controller.documentIdForBuffer(original.id);
      expect(originalId, isNotNull);

      await controller.remapPath('/workspace/a.md', '/workspace/b.md');
      final replacement = _fileBuffer(
        'replacement-a',
        '/workspace/a.md',
        'replacement A',
      );
      await controller.observeOpened(replacement);
      expect(controller.documentIdForBuffer(replacement.id), isNull);

      store.failRemaps = false;
      final moved = original.copyWith(filePath: '/workspace/b.md');
      expect(await controller.flushAll([moved, replacement]), isTrue);
      final snapshot = await store.load();
      final movedDocument = snapshot.documents.singleWhere(
        (document) => document.currentPath == '/workspace/b.md',
      );
      final replacementDocument = snapshot.documents.singleWhere(
        (document) => document.currentPath == '/workspace/a.md',
      );
      expect(movedDocument.id, originalId);
      expect(replacementDocument.id, isNot(originalId));
      expect(
        await _revisionSources(store, snapshot.revisionsFor(movedDocument.id)),
        contains('original A'),
      );
      expect(
        await _revisionSources(
          store,
          snapshot.revisionsFor(replacementDocument.id),
        ),
        contains('replacement A'),
      );
    },
  );

  test('deletion remains ordered behind a retained path remap', () async {
    final store = _ControllableRemapStore()..failRemaps = true;
    final timers = <_FakeTimer>[];
    final container = _historyContainer(store, timers);
    addTearDown(container.dispose);
    final controller = container.read(localHistoryControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    final original = _fileBuffer(
      'delete-after-remap',
      '/workspace/a.md',
      'original A',
    );
    await controller.observeOpened(original);
    final originalId = controller.documentIdForBuffer(original.id)!;

    await controller.remapPath('/workspace/a.md', '/workspace/b.md');
    await controller.markDeleted('/workspace/b.md', recursive: false);
    store.failRemaps = false;
    expect(
      await controller.flushAll([
        original.copyWith(filePath: '/workspace/b.md'),
      ]),
      isTrue,
    );

    var snapshot = await store.load();
    final deleted = snapshot.documents.singleWhere(
      (document) => document.id == originalId,
    );
    expect(deleted.currentPath, '/workspace/b.md');
    expect(deleted.deleted, isTrue);

    final replacement = _fileBuffer(
      'replacement-b',
      '/workspace/b.md',
      'new B',
    );
    await controller.observeOpened(replacement);
    snapshot = await store.load();
    final active = snapshot.documents.singleWhere(
      (document) => !document.deleted,
    );
    expect(active.currentPath, '/workspace/b.md');
    expect(active.id, isNot(originalId));
    expect(
      await _revisionSources(store, snapshot.revisionsFor(active.id)),
      contains('new B'),
    );
  });

  test(
    'first save waits for a reserved source path before promoting its history',
    () async {
      final store = _ControllableRemapStore()..failRemaps = true;
      final timers = <_FakeTimer>[];
      final container = _historyContainer(store, timers);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final original = _fileBuffer(
        'first-save-remap-source',
        '/workspace/a.md',
        'original A',
      );
      await controller.observeOpened(original);
      final originalId = controller.documentIdForBuffer(original.id)!;
      await controller.remapPath('/workspace/a.md', '/workspace/b.md');

      final draft = DocumentBuffer.untitled(
        id: 'first-save-remap-draft',
        name: 'Draft.md',
        text: 'replacement A',
      );
      await controller.observeOpened(draft);
      final draftId = controller.documentIdForBuffer(draft.id)!;
      expect(
        await controller.captureSavedAs(
          LocalHistoryBufferSnapshot.fromBuffer(draft),
          '/workspace/a.md',
          destinationExisted: false,
        ),
        isFalse,
      );
      var snapshot = await store.load();
      expect(
        snapshot.documents.singleWhere((document) => document.id == originalId),
        isA<LocalHistoryDocument>()
            .having(
              (document) => document.currentPath,
              'path',
              '/workspace/a.md',
            )
            .having((document) => document.deleted, 'deleted', isFalse),
      );
      expect(
        snapshot.documents.singleWhere((document) => document.id == draftId),
        isA<LocalHistoryDocument>()
            .having((document) => document.currentPath, 'path', isNull)
            .having((document) => document.untitled, 'untitled', isTrue),
      );

      store.failRemaps = false;
      final savedDraft = draft.copyWith(
        filePath: '/workspace/a.md',
        untitledName: null,
        lastSavedText: draft.text,
        dirty: false,
      );
      expect(await controller.flushBuffer(savedDraft), isTrue);
      snapshot = await store.load();
      final moved = snapshot.documents.singleWhere(
        (document) => document.id == originalId,
      );
      final replacement = snapshot.documents.singleWhere(
        (document) => document.id == draftId,
      );
      expect(moved.currentPath, '/workspace/b.md');
      expect(moved.deleted, isFalse);
      expect(replacement.currentPath, '/workspace/a.md');
      expect(replacement.deleted, isFalse);
      expect(
        await _revisionSources(store, snapshot.revisionsFor(moved.id)),
        contains('original A'),
      );
      expect(
        await _revisionSources(store, snapshot.revisionsFor(replacement.id)),
        contains('replacement A'),
      );
    },
  );

  test(
    'path target discovery observes history written after cached load',
    () async {
      final store = MemoryLocalHistoryStore();
      final container = _historyContainer(store, <_FakeTimer>[]);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);

      final external = await store.capture(
        LocalHistoryCaptureRequest(
          path: '/workspace/late-a.md',
          displayName: 'late-a.md',
          source: 'captured by another client',
          format: TextFormatMetadata.utf8Lf,
          capturedAt: DateTime.utc(2026, 1, 2),
          reason: LocalHistoryCaptureReason.saved,
        ),
        const LocalHistoryPolicy(),
      );
      expect(controller.state.snapshot.documents, isEmpty);

      await controller.remapPath(
        '/workspace/late-a.md',
        '/workspace/late-b.md',
      );
      final snapshot = await store.load();
      expect(snapshot.documents.single.id, external.document.id);
      expect(snapshot.documents.single.currentPath, '/workspace/late-b.md');
    },
  );

  for (final clearMode in ['document', 'all']) {
    test(
      'first-save cleanup cannot restore promotion after Clear $clearMode',
      () async {
        final store = _ControllableRemapStore()..blockNextPromotion = true;
        final timers = <_FakeTimer>[];
        final container = _historyContainer(store, timers);
        addTearDown(container.dispose);
        final controller = container.read(
          localHistoryControllerProvider.notifier,
        );
        await Future<void>.delayed(Duration.zero);
        final stale = await store.capture(
          LocalHistoryCaptureRequest(
            path: '/workspace/a.md',
            displayName: 'a.md',
            source: 'stale destination',
            format: TextFormatMetadata.utf8Lf,
            capturedAt: DateTime.utc(2026),
            reason: LocalHistoryCaptureReason.saved,
          ),
          const LocalHistoryPolicy(),
        );
        await controller.refresh();
        final draft = DocumentBuffer.untitled(
          id: 'clear-first-save-$clearMode',
          name: 'Draft.md',
          text: 'retained draft',
        );
        await controller.observeOpened(draft);
        final documentId = controller.documentIdForBuffer(draft.id)!;

        final save = controller.captureSavedAs(
          LocalHistoryBufferSnapshot.fromBuffer(draft),
          '/workspace/a.md',
          destinationExisted: false,
        );
        await store.promotionStarted.future;
        final clear = clearMode == 'all'
            ? controller.clearAll()
            : controller.clearDocument(documentId);
        store.releasePromotion.complete();
        await save;
        await clear;

        expect(controller.documentIdForBuffer(draft.id), isNull);
        expect(controller.pendingIdentityPromotions, isEmpty);
        expect(await controller.flushAll(const []), isTrue);
        final snapshot = await store.load();
        if (clearMode == 'all') {
          expect(snapshot.documents, isEmpty);
          expect(snapshot.revisions, isEmpty);
        } else {
          expect(snapshot.documents, hasLength(1));
          expect(snapshot.documents.single.id, stale.document.id);
          expect(snapshot.documents.single.deleted, isFalse);
        }
      },
    );
  }

  test('first-save cleanup cannot restore promotion after disposal', () async {
    final store = _ControllableRemapStore()..blockNextPromotion = true;
    final container = _historyContainer(store, <_FakeTimer>[]);
    final controller = container.read(localHistoryControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    await store.capture(
      LocalHistoryCaptureRequest(
        path: '/workspace/a.md',
        displayName: 'a.md',
        source: 'stale destination',
        format: TextFormatMetadata.utf8Lf,
        capturedAt: DateTime.utc(2026),
        reason: LocalHistoryCaptureReason.saved,
      ),
      const LocalHistoryPolicy(),
    );
    await controller.refresh();
    final draft = DocumentBuffer.untitled(
      id: 'dispose-first-save',
      name: 'Draft.md',
      text: 'retained draft',
    );
    await controller.observeOpened(draft);
    expect(controller.documentIdForBuffer(draft.id), isNotNull);

    final save = controller.captureSavedAs(
      LocalHistoryBufferSnapshot.fromBuffer(draft),
      '/workspace/a.md',
      destinationExisted: false,
    );
    await store.promotionStarted.future;
    container.dispose();
    store.releasePromotion.complete();
    await save;

    expect(controller.pendingIdentityPromotions, isEmpty);
  });

  test('Save As transfers retained remap ownership with source work', () async {
    final store = _ControllableRemapStore()..failRemaps = true;
    final timers = <_FakeTimer>[];
    final container = _historyContainer(store, timers);
    addTearDown(container.dispose);
    final controller = container.read(localHistoryControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    final original = _fileBuffer(
      'remap-save-as',
      '/workspace/a.md',
      'original A',
    );
    await controller.observeOpened(original);
    final sourceId = controller.documentIdForBuffer(original.id)!;
    await controller.remapPath('/workspace/a.md', '/workspace/b.md');

    final moved = original.copyWith(filePath: '/workspace/b.md');
    final protected = moved.edited('source-only protection');
    expect(
      await controller.captureBeforeLoss(
        LocalHistoryBufferSnapshot.fromBuffer(protected),
        LocalHistoryCaptureReason.beforeDiscard,
      ),
      isFalse,
    );
    final forkPoint = protected.edited('fork point');
    controller.observeEdit(protected, forkPoint);
    await Future<void>.delayed(Duration.zero);
    expect(
      await controller.captureSavedAs(
        LocalHistoryBufferSnapshot.fromBuffer(forkPoint),
        '/workspace/c.md',
        destinationExisted: false,
      ),
      isTrue,
    );

    final destination = forkPoint.copyWith(
      filePath: '/workspace/c.md',
      lastSavedText: forkPoint.text,
      dirty: false,
    );
    expect(await controller.flushBuffer(destination), isTrue);
    var snapshot = await store.load();
    final destinationDocument = snapshot.documents.singleWhere(
      (document) => document.currentPath == '/workspace/c.md',
    );
    expect(destinationDocument.id, isNot(sourceId));
    expect(
      await _revisionSources(
        store,
        snapshot.revisionsFor(destinationDocument.id),
      ),
      allOf(contains('fork point'), isNot(contains('source-only protection'))),
    );

    store.failRemaps = false;
    expect(await controller.flushAll([destination]), isTrue);
    snapshot = await store.load();
    final sourceDocument = snapshot.documents.singleWhere(
      (document) => document.currentPath == '/workspace/b.md',
    );
    expect(sourceDocument.id, sourceId);
    expect(
      await _revisionSources(store, snapshot.revisionsFor(sourceDocument.id)),
      containsAll(['source-only protection', 'fork point']),
    );
    expect(
      controller.documentIdForBuffer(destination.id),
      destinationDocument.id,
    );
  });

  test(
    'flushBuffer reports retained remap work and retires closed owner',
    () async {
      final store = _ControllableRemapStore()..failRemaps = true;
      final timers = <_FakeTimer>[];
      final container = _historyContainer(store, timers);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final original = _fileBuffer(
        'flush-remap',
        '/workspace/a.md',
        'original A',
      );
      await controller.observeOpened(original);
      await controller.remapPath('/workspace/a.md', '/workspace/b.md');
      final attempts = store.remapAttempts;
      final moved = original.copyWith(filePath: '/workspace/b.md');

      expect(await controller.flushBuffer(moved), isFalse);
      expect(store.remapAttempts, greaterThan(attempts));
      await controller.handleBufferClosed(original.id, historySettled: false);
      expect(controller.documentIdForBuffer(original.id), isNull);
      expect(
        controller.retainedDetachedCaptures.any(
          (capture) => capture.documentId != null,
        ),
        isTrue,
      );

      store.failRemaps = false;
      expect(await controller.flushAll([moved]), isTrue);
      expect(controller.documentIdForBuffer(original.id), isNull);
      expect(controller.warningForBuffer(original.id), isNull);
      expect(
        container
            .read(localHistoryControllerProvider)
            .snapshot
            .documents
            .single
            .currentPath,
        '/workspace/b.md',
      );
      final snapshot = await store.load();
      expect(snapshot.documents.single.currentPath, '/workspace/b.md');
    },
  );

  test('Clear All cannot be undone by an in-flight path remap', () async {
    final store = _ControllableRemapStore()..blockNextRemap = true;
    final timers = <_FakeTimer>[];
    final container = _historyContainer(store, timers);
    addTearDown(container.dispose);
    final controller = container.read(localHistoryControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    final buffer = _fileBuffer('clear-remap', '/workspace/a.md', 'baseline');
    await controller.observeOpened(buffer);

    final remap = controller.remapPath('/workspace/a.md', '/workspace/b.md');
    await store.remapStarted.future;
    final clear = controller.clearAll();
    store.releaseRemap.complete();
    await remap;
    await clear;
    for (final timer in timers) {
      timer.fire();
    }

    expect(await controller.flushAll(const []), isTrue);
    expect((await store.load()).documents, isEmpty);
    expect((await store.load()).revisions, isEmpty);
  });

  test(
    'path reconciliation resumes a newly opened destination owner',
    () async {
      final store = _ControllableRemapStore()..failRemaps = true;
      final timers = <_FakeTimer>[];
      final container = _historyContainer(store, timers);
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      final original = _fileBuffer('old-owner', '/workspace/a.md', 'original');
      await controller.observeOpened(original);
      await controller.handleBufferClosed(original.id, historySettled: true);
      await controller.remapPath('/workspace/a.md', '/workspace/b.md');

      final reopened = _fileBuffer(
        'new-owner',
        '/workspace/b.md',
        'opened while reconciliation is pending',
      );
      await controller.observeOpened(reopened);
      expect(controller.documentIdForBuffer(reopened.id), isNull);
      final attemptsBeforeRecovery = store.remapAttempts;

      store.failRemaps = false;
      timers.lastWhere((timer) => timer.isActive).fire();
      await _waitForHistory(
        container,
        (_) => store.remapAttempts > attemptsBeforeRecovery,
      );
      final ownerTimer = timers.lastWhere((timer) => timer.isActive);
      ownerTimer.fire();
      await _waitForHistory(
        container,
        (_) => controller.documentIdForBuffer(reopened.id) != null,
      );

      final snapshot = await store.load();
      expect(snapshot.documents, hasLength(1));
      expect(snapshot.documents.single.currentPath, '/workspace/b.md');
      expect(
        await _revisionSources(
          store,
          snapshot.revisionsFor(snapshot.documents.single.id),
        ),
        contains('opened while reconciliation is pending'),
      );
    },
  );
}

int _linuxProcessStartIdentity(int processId) {
  final stat = File('/proc/$processId/stat').readAsStringSync();
  final commandEnd = stat.lastIndexOf(') ');
  final fields = stat.substring(commandEnd + 2).trim().split(' ');
  return int.parse(fields[19]);
}

ProviderContainer _historyContainer(
  LocalHistoryStore store,
  List<_FakeTimer> timers,
) => ProviderContainer(
  overrides: [
    localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
    localHistoryStoreProvider.overrideWithValue(store),
    localHistoryClockProvider.overrideWithValue(() => DateTime.utc(2026, 1, 2)),
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

Future<void> _waitForHistory(
  ProviderContainer container,
  bool Function(LocalHistoryState state) condition, {
  Duration timeout = const Duration(seconds: 3),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition(container.read(localHistoryControllerProvider))) {
    if (DateTime.now().isAfter(deadline)) {
      final state = container.read(localHistoryControllerProvider);
      throw StateError(
        'Local History state did not complete: '
        'selected revisions=${state.selectedRevisions.length}; '
        'documents=${state.snapshot.documents.map((d) => '${d.id}:${d.currentPath}').toList()}; '
        'selected=${state.selectedDocumentId}; warning=${state.warning}',
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
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
  Future<void> clearAllOnce({required String operationId}) =>
      delegate.clearAllOnce(operationId: operationId);

  @override
  Future<void> clearDocumentOnce({
    required String operationId,
    required String documentId,
  }) => delegate.clearDocumentOnce(
    operationId: operationId,
    documentId: documentId,
  );

  @override
  Future<LocalHistorySnapshot> load() => delegate.load();

  @override
  Future<void> markDeleted(String path, {required bool recursive}) =>
      delegate.markDeleted(path, recursive: recursive);

  @override
  Future<List<LocalHistoryPathTarget>> resolvePathTargets(
    String path, {
    required bool recursive,
  }) => delegate.resolvePathTargets(path, recursive: recursive);

  @override
  Future<void> reconcilePath(LocalHistoryPathReconciliation reconciliation) =>
      delegate.reconcilePath(reconciliation);

  @override
  Future<T> runPathReconciliation<T>({
    required LocalHistoryPathReconciliationKind kind,
    required String sourcePath,
    String? destinationPath,
    required bool recursive,
    Iterable<LocalHistoryPathTarget>? preparedTargets,
    required Future<T> Function(List<LocalHistoryPathTarget> targets) operation,
    required bool Function(T result) didCommit,
  }) => delegate.runPathReconciliation(
    kind: kind,
    sourcePath: sourcePath,
    destinationPath: destinationPath,
    recursive: recursive,
    preparedTargets: preparedTargets,
    operation: operation,
    didCommit: didCommit,
  );

  @override
  Future<void> prune(LocalHistoryPolicy policy, DateTime now) =>
      delegate.prune(policy, now);

  @override
  Future<LocalHistoryDocument?> promoteUntitledDocument({
    required String documentId,
    required String destinationPath,
    required String displayName,
    required DateTime updatedAt,
    LocalHistoryDocument? staleDestinationOwner,
  }) => delegate.promoteUntitledDocument(
    documentId: documentId,
    destinationPath: destinationPath,
    displayName: displayName,
    updatedAt: updatedAt,
    staleDestinationOwner: staleDestinationOwner,
  );

  @override
  Future<void> remapPath(String sourcePath, String destinationPath) =>
      delegate.remapPath(sourcePath, destinationPath);
}

class _FailingSourceCaptureStore implements LocalHistoryStore {
  _FailingSourceCaptureStore(this.delegate, this.source);

  final LocalHistoryStore delegate;
  final String source;
  var failed = false;

  @override
  Future<LocalHistoryCaptureResult> capture(
    LocalHistoryCaptureRequest request,
    LocalHistoryPolicy policy,
  ) {
    if (!failed && request.source == source) {
      failed = true;
      throw const LocalHistoryStorageException('Injected transient failure');
    }
    return delegate.capture(request, policy);
  }

  @override
  Future<void> clearAll() => delegate.clearAll();

  @override
  Future<void> clearDocument(String documentId) =>
      delegate.clearDocument(documentId);

  @override
  Future<void> clearAllOnce({required String operationId}) =>
      delegate.clearAllOnce(operationId: operationId);

  @override
  Future<void> clearDocumentOnce({
    required String operationId,
    required String documentId,
  }) => delegate.clearDocumentOnce(
    operationId: operationId,
    documentId: documentId,
  );

  @override
  Future<LocalHistorySnapshot> load() => delegate.load();

  @override
  Future<void> markDeleted(String path, {required bool recursive}) =>
      delegate.markDeleted(path, recursive: recursive);

  @override
  Future<List<LocalHistoryPathTarget>> resolvePathTargets(
    String path, {
    required bool recursive,
  }) => delegate.resolvePathTargets(path, recursive: recursive);

  @override
  Future<void> reconcilePath(LocalHistoryPathReconciliation reconciliation) =>
      delegate.reconcilePath(reconciliation);

  @override
  Future<T> runPathReconciliation<T>({
    required LocalHistoryPathReconciliationKind kind,
    required String sourcePath,
    String? destinationPath,
    required bool recursive,
    Iterable<LocalHistoryPathTarget>? preparedTargets,
    required Future<T> Function(List<LocalHistoryPathTarget> targets) operation,
    required bool Function(T result) didCommit,
  }) => delegate.runPathReconciliation(
    kind: kind,
    sourcePath: sourcePath,
    destinationPath: destinationPath,
    recursive: recursive,
    preparedTargets: preparedTargets,
    operation: operation,
    didCommit: didCommit,
  );

  @override
  Future<void> prune(LocalHistoryPolicy policy, DateTime now) =>
      delegate.prune(policy, now);

  @override
  Future<LocalHistoryDocument?> promoteUntitledDocument({
    required String documentId,
    required String destinationPath,
    required String displayName,
    required DateTime updatedAt,
    LocalHistoryDocument? staleDestinationOwner,
  }) => delegate.promoteUntitledDocument(
    documentId: documentId,
    destinationPath: destinationPath,
    displayName: displayName,
    updatedAt: updatedAt,
    staleDestinationOwner: staleDestinationOwner,
  );

  @override
  Future<LocalHistoryRevision?> readRevision(String revisionId) =>
      delegate.readRevision(revisionId);

  @override
  Future<void> remapPath(String sourcePath, String destinationPath) =>
      delegate.remapPath(sourcePath, destinationPath);
}

class _FailingRevisionReadStore extends MemoryLocalHistoryStore {
  var failReads = false;

  @override
  Future<LocalHistoryRevision?> readRevision(String revisionId) {
    if (failReads) throw StateError('Injected revision read failure');
    return super.readRevision(revisionId);
  }
}

class _ClearConflictOnceStore extends MemoryLocalHistoryStore {
  var _rejected = false;

  @override
  Future<LocalHistoryCaptureResult> capture(
    LocalHistoryCaptureRequest request,
    LocalHistoryPolicy policy,
  ) {
    if (!_rejected) {
      _rejected = true;
      throw const LocalHistoryClearConflict();
    }
    return super.capture(request, policy);
  }
}

class _BlockingClearStore extends MemoryLocalHistoryStore {
  final clearStarted = Completer<void>();
  final releaseClear = Completer<void>();

  Future<void> _block() async {
    if (!clearStarted.isCompleted) clearStarted.complete();
    await releaseClear.future;
  }

  @override
  Future<void> clearDocumentOnce({
    required String operationId,
    required String documentId,
  }) async {
    await _block();
    await super.clearDocumentOnce(
      operationId: operationId,
      documentId: documentId,
    );
  }

  @override
  Future<void> clearAllOnce({required String operationId}) async {
    await _block();
    await super.clearAllOnce(operationId: operationId);
  }
}

class _FailingClearOnceStore extends MemoryLocalHistoryStore {
  var clearsAvailable = false;
  var failLoadAfterClear = false;
  var _failNextLoad = false;

  @override
  Future<void> clearDocumentOnce({
    required String operationId,
    required String documentId,
  }) async {
    if (!clearsAvailable) {
      throw const LocalHistoryStorageException(
        'Injected transient clear failure',
      );
    }
    await super.clearDocumentOnce(
      operationId: operationId,
      documentId: documentId,
    );
    _failNextLoad = failLoadAfterClear;
  }

  @override
  Future<LocalHistorySnapshot> load() {
    if (_failNextLoad) {
      _failNextLoad = false;
      throw const LocalHistoryStorageException(
        'Injected refresh failure after clear commit',
      );
    }
    return super.load();
  }
}

class _BlockingNextCaptureStore implements LocalHistoryStore {
  _BlockingNextCaptureStore(this.delegate);

  final LocalHistoryStore delegate;
  var blockNextCapture = false;
  var failBlockedCapture = false;
  final attempts = <LocalHistoryCaptureRequest>[];
  var captureStarted = Completer<void>();
  var releaseCapture = Completer<void>();

  @override
  Future<LocalHistoryCaptureResult> capture(
    LocalHistoryCaptureRequest request,
    LocalHistoryPolicy policy,
  ) async {
    attempts.add(request);
    if (blockNextCapture) {
      blockNextCapture = false;
      if (!captureStarted.isCompleted) captureStarted.complete();
      await releaseCapture.future;
      if (failBlockedCapture) {
        failBlockedCapture = false;
        throw const LocalHistoryStorageException(
          'Injected blocked capture failure',
        );
      }
    }
    return delegate.capture(request, policy);
  }

  @override
  Future<void> clearAll() => delegate.clearAll();

  @override
  Future<void> clearDocument(String documentId) =>
      delegate.clearDocument(documentId);

  @override
  Future<void> clearAllOnce({required String operationId}) =>
      delegate.clearAllOnce(operationId: operationId);

  @override
  Future<void> clearDocumentOnce({
    required String operationId,
    required String documentId,
  }) => delegate.clearDocumentOnce(
    operationId: operationId,
    documentId: documentId,
  );

  @override
  Future<LocalHistorySnapshot> load() => delegate.load();

  @override
  Future<void> markDeleted(String path, {required bool recursive}) =>
      delegate.markDeleted(path, recursive: recursive);

  @override
  Future<List<LocalHistoryPathTarget>> resolvePathTargets(
    String path, {
    required bool recursive,
  }) => delegate.resolvePathTargets(path, recursive: recursive);

  @override
  Future<void> reconcilePath(LocalHistoryPathReconciliation reconciliation) =>
      delegate.reconcilePath(reconciliation);

  @override
  Future<T> runPathReconciliation<T>({
    required LocalHistoryPathReconciliationKind kind,
    required String sourcePath,
    String? destinationPath,
    required bool recursive,
    Iterable<LocalHistoryPathTarget>? preparedTargets,
    required Future<T> Function(List<LocalHistoryPathTarget> targets) operation,
    required bool Function(T result) didCommit,
  }) => delegate.runPathReconciliation(
    kind: kind,
    sourcePath: sourcePath,
    destinationPath: destinationPath,
    recursive: recursive,
    preparedTargets: preparedTargets,
    operation: operation,
    didCommit: didCommit,
  );

  @override
  Future<void> prune(LocalHistoryPolicy policy, DateTime now) =>
      delegate.prune(policy, now);

  @override
  Future<LocalHistoryDocument?> promoteUntitledDocument({
    required String documentId,
    required String destinationPath,
    required String displayName,
    required DateTime updatedAt,
    LocalHistoryDocument? staleDestinationOwner,
  }) => delegate.promoteUntitledDocument(
    documentId: documentId,
    destinationPath: destinationPath,
    displayName: displayName,
    updatedAt: updatedAt,
    staleDestinationOwner: staleDestinationOwner,
  );

  @override
  Future<LocalHistoryRevision?> readRevision(String revisionId) =>
      delegate.readRevision(revisionId);

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
    LocalHistoryDocument? staleDestinationOwner,
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
      staleDestinationOwner: staleDestinationOwner,
    );
  }
}

class _ControllablePromotionStore extends MemoryLocalHistoryStore {
  var failPromotions = true;
  var promotionAttempts = 0;

  @override
  Future<LocalHistoryDocument?> promoteUntitledDocument({
    required String documentId,
    required String destinationPath,
    required String displayName,
    required DateTime updatedAt,
    LocalHistoryDocument? staleDestinationOwner,
  }) {
    promotionAttempts++;
    if (failPromotions) {
      throw const LocalHistoryStorageException(
        'Injected transient promotion failure',
      );
    }
    return super.promoteUntitledDocument(
      documentId: documentId,
      destinationPath: destinationPath,
      displayName: displayName,
      updatedAt: updatedAt,
      staleDestinationOwner: staleDestinationOwner,
    );
  }
}

class _FailingPromotionThenCaptureStore extends MemoryLocalHistoryStore {
  _FailingPromotionThenCaptureStore(this.failingSource);

  final String failingSource;
  var _failPromotion = true;
  var _matchingCaptureCount = 0;

  @override
  Future<LocalHistoryDocument?> promoteUntitledDocument({
    required String documentId,
    required String destinationPath,
    required String displayName,
    required DateTime updatedAt,
    LocalHistoryDocument? staleDestinationOwner,
  }) {
    if (_failPromotion) {
      _failPromotion = false;
      throw const LocalHistoryStorageException('Injected promotion failure');
    }
    return super.promoteUntitledDocument(
      documentId: documentId,
      destinationPath: destinationPath,
      displayName: displayName,
      updatedAt: updatedAt,
      staleDestinationOwner: staleDestinationOwner,
    );
  }

  @override
  Future<LocalHistoryCaptureResult> capture(
    LocalHistoryCaptureRequest request,
    LocalHistoryPolicy policy,
  ) {
    if (request.source == failingSource) {
      _matchingCaptureCount++;
    }
    if (_matchingCaptureCount <= 2 && request.source == failingSource) {
      throw const LocalHistoryStorageException('Injected capture failure');
    }
    return super.capture(request, policy);
  }
}

class _RepairStore extends MemoryLocalHistoryStore {
  final captureErrors = <String, Object>{};
  final attempts = <LocalHistoryCaptureRequest>[];
  final commits = <LocalHistoryCaptureRequest>[];
  var failRefreshAfterCapture = false;
  var failRefreshAfterPromotion = false;
  var blockRefreshAfterCapture = false;
  var _failLoad = false;
  var _blockLoad = false;
  final refreshEntered = Completer<void>();
  final releaseRefresh = Completer<void>();
  var promotions = 0;

  @override
  Future<LocalHistoryCaptureResult> capture(
    LocalHistoryCaptureRequest request,
    LocalHistoryPolicy policy,
  ) async {
    attempts.add(request);
    final error = captureErrors[request.source];
    if (error != null) throw error;
    final result = await super.capture(request, policy);
    commits.add(request);
    _failLoad = failRefreshAfterCapture;
    _blockLoad = blockRefreshAfterCapture;
    return result;
  }

  @override
  Future<LocalHistorySnapshot> load() async {
    if (_blockLoad) {
      _blockLoad = false;
      refreshEntered.complete();
      await releaseRefresh.future;
    }
    if (_failLoad) {
      _failLoad = false;
      throw StateError('History refresh unavailable');
    }
    return super.load();
  }

  @override
  Future<LocalHistoryDocument?> promoteUntitledDocument({
    required String documentId,
    required String destinationPath,
    required String displayName,
    required DateTime updatedAt,
    LocalHistoryDocument? staleDestinationOwner,
  }) async {
    final result = await super.promoteUntitledDocument(
      documentId: documentId,
      destinationPath: destinationPath,
      displayName: displayName,
      updatedAt: updatedAt,
      staleDestinationOwner: staleDestinationOwner,
    );
    promotions++;
    _failLoad = failRefreshAfterPromotion;
    return result;
  }
}

class _ControllableRemapStore extends MemoryLocalHistoryStore {
  var failRemaps = false;
  var blockNextRemap = false;
  var failDeletions = false;
  var blockNextDeletion = false;
  var blockNextPromotion = false;
  var remapAttempts = 0;
  var failNextLoad = false;
  final remapStarted = Completer<void>();
  final releaseRemap = Completer<void>();
  final deletionStarted = Completer<void>();
  final releaseDeletion = Completer<void>();
  final promotionStarted = Completer<void>();
  final releasePromotion = Completer<void>();

  @override
  Future<LocalHistoryDocument?> promoteUntitledDocument({
    required String documentId,
    required String destinationPath,
    required String displayName,
    required DateTime updatedAt,
    LocalHistoryDocument? staleDestinationOwner,
  }) async {
    if (blockNextPromotion) {
      blockNextPromotion = false;
      if (!promotionStarted.isCompleted) promotionStarted.complete();
      await releasePromotion.future;
    }
    return super.promoteUntitledDocument(
      documentId: documentId,
      destinationPath: destinationPath,
      displayName: displayName,
      updatedAt: updatedAt,
      staleDestinationOwner: staleDestinationOwner,
    );
  }

  @override
  Future<LocalHistorySnapshot> load() {
    if (failNextLoad) {
      failNextLoad = false;
      throw const LocalHistoryStorageException('Injected refresh failure');
    }
    return super.load();
  }

  @override
  Future<void> reconcilePath(
    LocalHistoryPathReconciliation reconciliation,
  ) async {
    if (reconciliation.kind == LocalHistoryPathReconciliationKind.remap) {
      remapAttempts++;
      if (blockNextRemap) {
        blockNextRemap = false;
        if (!remapStarted.isCompleted) remapStarted.complete();
        await releaseRemap.future;
      }
      if (failRemaps) {
        throw const LocalHistoryStorageException(
          'Injected transient remap failure',
        );
      }
    } else {
      if (blockNextDeletion) {
        blockNextDeletion = false;
        if (!deletionStarted.isCompleted) deletionStarted.complete();
        await releaseDeletion.future;
      }
      if (failDeletions) {
        throw const LocalHistoryStorageException(
          'Injected transient deletion failure',
        );
      }
    }
    await super.reconcilePath(reconciliation);
  }

  @override
  Future<void> markDeleted(String path, {required bool recursive}) async {
    if (blockNextDeletion) {
      blockNextDeletion = false;
      if (!deletionStarted.isCompleted) deletionStarted.complete();
      await releaseDeletion.future;
    }
    if (failDeletions) {
      throw const LocalHistoryStorageException(
        'Injected transient deletion failure',
      );
    }
    await super.markDeleted(path, recursive: recursive);
  }

  @override
  Future<void> remapPath(String sourcePath, String destinationPath) async {
    remapAttempts++;
    if (blockNextRemap) {
      blockNextRemap = false;
      if (!remapStarted.isCompleted) remapStarted.complete();
      await releaseRemap.future;
    }
    if (failRemaps) {
      throw const LocalHistoryStorageException(
        'Injected transient remap failure',
      );
    }
    await super.remapPath(sourcePath, destinationPath);
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
