import 'dart:io';
import 'dart:async';

import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/comparison/source_comparison.dart';
import 'package:busymark/src/local_history/local_history_controller.dart';
import 'package:busymark/src/local_history/local_history_comparison_view.dart';
import 'package:busymark/src/local_history/local_history_models.dart';
import 'package:busymark/src/local_history/local_history_store.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:busymark/src/workspace/recovery_persistence.dart';
import 'package:busymark/src/workspace/session_persistence.dart';
import 'package:busymark/src/workspace/text_format_metadata.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/workspace/workspace_file_monitor.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp(
      'busymark-local-history-workspace-',
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test(
    'comparison uses unsaved editor source and whole restore is one undo step',
    () async {
      final path = p.join(root.path, 'guide.md');
      await File(path).writeAsString('Disk version\n');
      final store = MemoryLocalHistoryStore();
      final captured = await _capture(store, path, 'Historical version\n');
      final harness = await _harness(store);
      await harness.controller.openPath(path);
      harness.controller.updateActiveText('Unsaved editor version\n');
      await Future<void>.delayed(Duration.zero);
      final revision = (await store.readRevision(captured.revision!.id))!;
      final document = (await store.load()).documents.single;

      final current = await harness.controller.localHistoryCurrentSource(
        document,
        revision,
      );
      expect(current.kind, LocalHistoryCurrentSourceKind.editor);
      expect(current.source, 'Unsaved editor version\n');
      final before = harness.state.activeBuffer!;
      final undoLength = before.editorState.undoState.undo.length;
      final format = before.format;

      expect(
        await harness.controller.restoreLocalHistoryRevision(
          document: document,
          revision: revision,
        ),
        isTrue,
      );
      var restored = harness.state.activeBuffer!;
      expect(restored.text, 'Historical version\n');
      expect(restored.editorState.undoState.undo, hasLength(undoLength + 1));
      expect(restored.format.hasUtf8Bom, format.hasUtf8Bom);
      expect(restored.format.lineEnding, format.lineEnding);
      expect(harness.controller.undoActiveBuffer(), isTrue);
      expect(harness.state.activeText, 'Unsaved editor version\n');
      expect(harness.controller.redoActiveBuffer(), isTrue);
      expect(harness.state.activeText, 'Historical version\n');
    },
  );

  test('region restore is exact, undoable, and rejects stale ranges', () async {
    final path = p.join(root.path, 'regions.md');
    await File(path).writeAsString('alpha\nnew phrase\nomega\n');
    final store = MemoryLocalHistoryStore();
    final captured = await _capture(store, path, 'alpha\nold phrase\nomega\n');
    final harness = await _harness(store);
    await harness.controller.openPath(path);
    final revision = (await store.readRevision(captured.revision!.id))!;
    final document = (await store.load()).documents.single;
    var buffer = harness.state.activeBuffer!;
    final comparison = _comparison(revision, buffer);
    expect(comparison.changes, hasLength(1));
    final change = comparison.changes.single;

    expect(
      await harness.controller.restoreLocalHistoryRevision(
        document: document,
        revision: revision,
        comparison: comparison,
        change: change,
      ),
      isTrue,
    );
    expect(harness.state.activeText, 'alpha\nold phrase\nomega\n');
    expect(harness.controller.undoActiveBuffer(), isTrue);
    expect(harness.state.activeText, 'alpha\nnew phrase\nomega\n');

    harness.controller.updateActiveText('alpha\nnewer phrase\nomega\n');
    buffer = harness.state.activeBuffer!;
    final undoLength = buffer.editorState.undoState.undo.length;
    expect(
      await harness.controller.restoreLocalHistoryRevision(
        document: document,
        revision: revision,
        comparison: comparison,
        change: change,
      ),
      isFalse,
    );
    expect(harness.state.activeText, 'alpha\nnewer phrase\nomega\n');
    expect(
      harness.state.activeBuffer!.editorState.undoState.undo,
      hasLength(undoLength),
    );
  });

  test('failed protective capture leaves current document unchanged', () async {
    final path = p.join(root.path, 'protected.md');
    await File(path).writeAsString('Current disk\n');
    final memory = MemoryLocalHistoryStore();
    final captured = await _capture(memory, path, 'Old history\n');
    final store = _FailingProtectiveStore(memory);
    final harness = await _harness(store);
    await harness.controller.openPath(path);
    harness.controller.updateActiveText('Precious unsaved work\n');
    await Future<void>.delayed(Duration.zero);
    final revision = (await memory.readRevision(captured.revision!.id))!;
    final document = (await memory.load()).documents.single;
    final before = harness.state.activeBuffer!;

    expect(
      await harness.controller.restoreLocalHistoryRevision(
        document: document,
        revision: revision,
      ),
      isFalse,
    );
    expect(harness.state.activeText, before.text);
    expect(harness.state.activeBuffer!.revision, before.revision);
    expect(
      harness.state.activeBuffer!.editorState.undoState.undo,
      before.editorState.undoState.undo,
    );
    expect(
      harness.container.read(localHistoryControllerProvider).warning?.kind,
      LocalHistoryWarningKind.capture,
    );
  });

  test(
    'restoration rejects a revision from another history document',
    () async {
      final aPath = p.join(root.path, 'a.md');
      final bPath = p.join(root.path, 'b.md');
      await File(aPath).writeAsString('A on disk\n');
      await File(bPath).writeAsString('B on disk\n');
      final store = MemoryLocalHistoryStore();
      final capturedA = await _capture(store, aPath, 'A history\n');
      final capturedB = await _capture(store, bPath, 'B history\n');
      final harness = await _harness(store);
      await harness.controller.openPath(bPath);
      final revisionA = (await store.readRevision(capturedA.revision!.id))!;
      final snapshot = await store.load();
      final documentB = snapshot.documents.singleWhere(
        (document) => document.id == capturedB.document.id,
      );

      expect(
        await harness.controller.restoreLocalHistoryRevision(
          document: documentB,
          revision: revisionA,
        ),
        isFalse,
      );
      expect(harness.state.activeText, 'B on disk\n');
    },
  );

  test(
    'untitled history compares and restores through stable identity',
    () async {
      final store = MemoryLocalHistoryStore();
      final harness = await _harness(store);
      await harness.controller.createMarkdownFile();
      harness.controller.updateActiveText('Older untitled draft\n');
      await Future<void>.delayed(Duration.zero);
      await harness.container
          .read(localHistoryControllerProvider.notifier)
          .flushBuffer(harness.state.activeBuffer!);
      final snapshot = await store.load();
      final document = snapshot.documents.single;
      final revision = (await store.readRevision(
        snapshot.revisionsFor(document.id).single.id,
      ))!;
      harness.controller.updateActiveText('Newer untitled draft\n');

      final current = await harness.controller.localHistoryCurrentSource(
        document,
        revision,
      );
      expect(current.kind, LocalHistoryCurrentSourceKind.editor);
      expect(current.source, 'Newer untitled draft\n');
      expect(
        await harness.controller.restoreLocalHistoryRevision(
          document: document,
          revision: revision,
        ),
        isTrue,
      );
      expect(harness.state.activeText, 'Older untitled draft\n');
      expect(harness.state.activeBuffer!.isUntitled, isTrue);
    },
  );

  test(
    'editing during a delayed reload cancels the stale replacement',
    () async {
      final path = p.join(root.path, 'reload.md');
      await File(path).writeAsString('Disk version\n');
      final store = _BlockingBeforeReloadStore(MemoryLocalHistoryStore());
      final harness = await _harness(store);
      await harness.controller.openPath(path);
      harness.controller.updateActiveText('Edit before reload\n');
      await Future<void>.delayed(Duration.zero);

      final reload = harness.controller.reloadBufferFromDisk(
        harness.state.activeBuffer!.id,
      );
      await store.started.future;
      harness.controller.updateActiveText('Edit made while reload waited\n');
      store.release.complete();

      expect(await reload, isFalse);
      expect(harness.state.activeText, 'Edit made while reload waited\n');
      expect(harness.state.activeBuffer!.isDirty, isTrue);
    },
  );

  test(
    'reload reparse cannot publish after another buffer becomes active',
    () async {
      final aPath = p.join(root.path, 'A.md');
      final bPath = p.join(root.path, 'B.md');
      await File(aPath).writeAsString('# A before reload\n');
      await File(bPath).writeAsString('# B active\n');
      final service = _BlockingNextReparseWorkspaceService();
      final harness = await _harness(
        MemoryLocalHistoryStore(),
        service: service,
      );
      await harness.controller.openPath(root.path);
      expect(await harness.controller.openActiveFile(bPath), isTrue);
      expect(await harness.controller.openActiveFile(aPath), isTrue);
      final aId = harness.state.activeBuffer!.id;
      await File(aPath).writeAsString('# A reloaded\n');

      service.pauseNext();
      final reload = harness.controller.reloadBufferFromDisk(aId);
      await service.started.future;
      expect(await harness.controller.openActiveFile(bPath), isTrue);
      final bWorkspace = harness.state.workspace;
      final bPreview = harness.state.preview;

      service.release();
      expect(await reload, isTrue);
      expect(harness.state.activeBuffer!.filePath, bPath);
      expect(harness.state.workspace?.activeFilePath, bPath);
      expect(harness.state.workspace?.markdown?.filePath, bPath);
      expect(harness.state.workspace, same(bWorkspace));
      expect(harness.state.preview, same(bPreview));
      expect(
        harness.state.documentBuffers
            .singleWhere((buffer) => buffer.id == aId)
            .text,
        '# A reloaded\n',
      );
    },
  );

  test('delete skips binary and excluded history descendants', () async {
    final image = File(p.join(root.path, 'image.png'));
    final imageFolder = Directory(p.join(root.path, 'image-folder'));
    final excludedFolder = Directory(p.join(root.path, 'excluded-folder'));
    await image.writeAsBytes([0x89, 0x50, 0x4e, 0x47, 0xff, 0x00]);
    await imageFolder.create();
    await File(
      p.join(imageFolder.path, 'nested.png'),
    ).writeAsBytes([0xff, 0xfe, 0xfd]);
    await excludedFolder.create();
    await File(
      p.join(excludedFolder.path, 'secret.md'),
    ).writeAsString('Excluded source\n');
    final harness = await _harness(MemoryLocalHistoryStore());
    await harness.controller.openPath(root.path);
    await harness.container
        .read(appSettingsControllerProvider.notifier)
        .setLocalHistoryExcludedPaths([excludedFolder.path]);

    expect(await harness.controller.deleteWorkspaceEntity(image.path), isTrue);
    expect(await image.exists(), isFalse);
    expect(
      await harness.controller.deleteWorkspaceEntity(imageFolder.path),
      isTrue,
    );
    expect(await imageFolder.exists(), isFalse);
    expect(
      await harness.controller.deleteWorkspaceEntity(excludedFolder.path),
      isTrue,
    );
    expect(await excludedFolder.exists(), isFalse);
  });

  test(
    'deleted document restores through normal create flow without overwriting',
    () async {
      final anchor = p.join(root.path, 'anchor.md');
      final missing = p.join(root.path, 'deleted.md');
      await File(anchor).writeAsString('# Anchor\n');
      final store = MemoryLocalHistoryStore();
      final captured = await _capture(
        store,
        missing,
        '# Recovered\n\nSubstantial deleted content.\n',
        reason: LocalHistoryCaptureReason.beforeDelete,
      );
      await store.markDeleted(missing, recursive: false);
      final harness = await _harness(store);
      await harness.controller.openPath(root.path);
      final revision = (await store.readRevision(captured.revision!.id))!;
      final document = (await store.load()).documents.singleWhere(
        (candidate) => candidate.id == captured.document.id,
      );
      expect(
        (await harness.controller.localHistoryCurrentSource(
          document,
          revision,
        )).kind,
        LocalHistoryCurrentSourceKind.missing,
      );

      expect(
        await harness.controller.restoreMissingLocalHistoryRevision(
          document: document,
          revision: revision,
          destinationPath: missing,
          overwriteExisting: false,
        ),
        isTrue,
      );
      expect(harness.state.activeBuffer!.filePath, missing);
      expect(harness.state.activeText, revision.source);
      expect(harness.state.activeBuffer!.isDirty, isTrue);
      expect(await File(missing).readAsString(), '');
      expect(harness.controller.undoActiveBuffer(), isTrue);
      expect(harness.state.activeText, '');

      final occupied = p.join(root.path, 'occupied.md');
      await File(occupied).writeAsString('Do not replace\n');
      expect(
        await harness.controller.restoreMissingLocalHistoryRevision(
          document: document,
          revision: revision,
          destinationPath: occupied,
          overwriteExisting: false,
        ),
        isFalse,
      );
      expect(await File(occupied).readAsString(), 'Do not replace\n');
    },
  );

  test(
    'delayed explicit save records exactly the source that was written',
    () async {
      final path = p.join(root.path, 'delayed-save.md');
      await File(path).writeAsString('# Initial\n');
      final store = MemoryLocalHistoryStore();
      final service = _DelayedSaveWorkspaceService();
      final harness = await _harness(store, service: service);
      await harness.controller.openPath(path);
      harness.controller.updateActiveText('# First requested revision\n');
      final save = harness.controller.saveActive();
      await service.started.future;
      harness.controller.updateActiveText('# Newer unsaved revision\n');
      service.release();

      expect(await save, isTrue);
      final snapshot = await store.load();
      final saved = <LocalHistoryRevision>[];
      for (final summary in snapshot.revisions.where(
        (candidate) => candidate.reason == LocalHistoryCaptureReason.saved,
      )) {
        saved.add((await store.readRevision(summary.id))!);
      }
      expect(saved.map((entry) => entry.source), [
        '# First requested revision\n',
      ]);
      expect(harness.state.activeText, '# Newer unsaved revision\n');
      expect(harness.state.activeBuffer!.isDirty, isTrue);
    },
  );

  test(
    'history failure cannot turn a successful save into a failure',
    () async {
      final path = p.join(root.path, 'save-warning.md');
      await File(path).writeAsString('# Initial\n');
      final memory = MemoryLocalHistoryStore();
      final store = _FailingSavedStore(memory);
      final harness = await _harness(store);
      await harness.controller.openPath(path);
      harness.controller.updateActiveText('# Successfully saved\n');

      expect(await harness.controller.saveActive(), isTrue);
      expect(await File(path).readAsString(), '# Successfully saved\n');
      expect(harness.state.activeBuffer!.isDirty, isFalse);
      expect(
        harness.container.read(localHistoryControllerProvider).warning?.kind,
        LocalHistoryWarningKind.capture,
      );
    },
  );

  test(
    'external move keeps edits made during history remap on the destination',
    () async {
      final sourcePath = p.join(root.path, 'A.md');
      final destinationPath = p.join(root.path, 'B.md');
      await File(sourcePath).writeAsString('Original\n');
      final memory = MemoryLocalHistoryStore();
      final store = _BlockingRemapStore(memory);
      final monitor = _ControlledFileMonitor();
      final timers = <_FakeTimer>[];
      final harness = await _harness(
        store,
        fileMonitor: monitor,
        timerFactory: (delay, callback) {
          final timer = _FakeTimer(delay, callback);
          timers.add(timer);
          return timer;
        },
      );
      await harness.controller.openPath(sourcePath);
      harness.controller.updateActiveText('Edit before move\n');
      await Future<void>.delayed(Duration.zero);

      await File(sourcePath).rename(destinationPath);
      monitor.emitMove(sourcePath, destinationPath);
      await store.started.future;
      expect(harness.state.activeBuffer!.filePath, sourcePath);
      harness.controller.updateActiveText('Edit while remap is paused\n');
      await Future<void>.delayed(Duration.zero);
      for (final timer in timers) {
        timer.fire();
      }

      store.release.complete();
      await _waitFor(
        () =>
            harness.state.activeBuffer?.filePath == destinationPath &&
            timers.any((timer) => timer.isActive),
      );
      for (final timer in List<_FakeTimer>.of(timers)) {
        timer.fire();
      }
      await harness.container
          .read(localHistoryControllerProvider.notifier)
          .flushBuffer(harness.state.activeBuffer!);

      final snapshot = await memory.load();
      expect(snapshot.documents.map((document) => document.currentPath), [
        destinationPath,
      ]);
      final destination = snapshot.documents.single;
      expect(
        await _revisionSources(memory, snapshot.revisionsFor(destination.id)),
        contains('Edit while remap is paused\n'),
      );
    },
  );

  test('external move reparse cannot publish after a newer edit', () async {
    final sourcePath = p.join(root.path, 'A.md');
    final destinationPath = p.join(root.path, 'B.md');
    await File(sourcePath).writeAsString('# Before move\n');
    final monitor = _ControlledFileMonitor();
    final service = _BlockingNextReparseWorkspaceService();
    final harness = await _harness(
      MemoryLocalHistoryStore(),
      service: service,
      fileMonitor: monitor,
    );
    await harness.controller.openPath(sourcePath);
    harness.controller.updateActiveEditorMode(
      DocumentViewModePreference.source,
    );

    service.pauseNext();
    await File(sourcePath).rename(destinationPath);
    monitor.emitMove(sourcePath, destinationPath);
    await service.started.future;
    expect(harness.state.activeBuffer!.filePath, destinationPath);
    final revisionBeforeEdit = harness.state.activeBuffer!.revision;
    harness.controller.updateActiveText('# Edited during reparse\n');
    await Future<void>.delayed(Duration.zero);
    final workspaceAfterEdit = harness.state.workspace;
    final previewAfterEdit = harness.state.preview;

    service.release();
    await service.finished.future;
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(harness.state.activeBuffer!.filePath, destinationPath);
    expect(harness.state.activeText, '# Edited during reparse\n');
    expect(
      harness.state.activeBuffer!.revision,
      greaterThan(revisionBeforeEdit),
    );
    expect(harness.state.workspace, same(workspaceAfterEdit));
    expect(harness.state.preview, same(previewAfterEdit));
  });

  test(
    'Save As keeps edits made during destination capture out of source history',
    () async {
      final sourcePath = p.join(root.path, 'A.md');
      final destinationPath = p.join(root.path, 'B.md');
      await File(sourcePath).writeAsString('Original\n');
      final memory = MemoryLocalHistoryStore();
      final store = _BlockingSaveAsStore(memory, destinationPath);
      final timers = <_FakeTimer>[];
      final harness = await _harness(
        store,
        timerFactory: (delay, callback) {
          final timer = _FakeTimer(delay, callback);
          timers.add(timer);
          return timer;
        },
      );
      await harness.controller.openPath(sourcePath);
      harness.controller.updateActiveText('Save target\n');
      await Future<void>.delayed(Duration.zero);

      final save = harness.controller.saveActiveAs(destinationPath);
      await store.started.future;
      expect(harness.state.activeBuffer!.filePath, destinationPath);
      harness.controller.updateActiveText('Newer destination edit\n');
      await Future<void>.delayed(Duration.zero);
      for (final timer in timers) {
        timer.fire();
      }

      store.release.complete();
      expect(await save, isTrue);
      for (final timer in List<_FakeTimer>.of(timers)) {
        timer.fire();
      }
      await harness.container
          .read(localHistoryControllerProvider.notifier)
          .flushBuffer(harness.state.activeBuffer!);

      final snapshot = await memory.load();
      final source = snapshot.documents.singleWhere(
        (document) => document.currentPath == sourcePath,
      );
      final destination = snapshot.documents.singleWhere(
        (document) => document.currentPath == destinationPath,
      );
      expect(source.id, isNot(destination.id));
      expect(
        await _revisionSources(memory, snapshot.revisionsFor(source.id)),
        isNot(contains('Newer destination edit\n')),
      );
      expect(
        await _revisionSources(memory, snapshot.revisionsFor(destination.id)),
        containsAll(['Save target\n', 'Newer destination edit\n']),
      );
    },
  );

  test(
    'shutdown retries first-save promotion without requiring another edit',
    () async {
      final memory = MemoryLocalHistoryStore();
      final store = _FailingFirstPromotionStore(memory);
      final harness = await _harness(store);
      await harness.controller.createMarkdownFile();
      harness.controller.updateActiveText('Untitled lineage before save\n');
      await Future<void>.delayed(Duration.zero);
      await harness.container
          .read(localHistoryControllerProvider.notifier)
          .flushBuffer(harness.state.activeBuffer!);
      final originalDocument = (await memory.load()).documents.single;
      final destination = p.join(root.path, 'Guide.md');

      expect(await harness.controller.saveActiveAs(destination), isTrue);
      expect(harness.state.activeBuffer!.isDirty, isFalse);
      expect((await memory.load()).documents.single.currentPath, isNull);

      await harness.controller.markCleanShutdown();
      final afterShutdown = await memory.load();
      expect(afterShutdown.documents, hasLength(1));
      expect(afterShutdown.documents.single.id, originalDocument.id);
      expect(afterShutdown.documents.single.currentPath, destination);
      expect(
        await _revisionSources(
          memory,
          afterShutdown.revisionsFor(originalDocument.id),
        ),
        contains('Untitled lineage before save\n'),
      );

      final reopened = await _harness(store);
      await reopened.controller.openPath(destination);
      await reopened.container
          .read(localHistoryControllerProvider.notifier)
          .selectDocumentForBuffer(reopened.state.activeBuffer!);
      expect(
        reopened.container
            .read(localHistoryControllerProvider.notifier)
            .bufferIdForDocument(originalDocument.id),
        reopened.state.activeBuffer!.id,
      );
    },
  );

  test(
    'unresolved shutdown promotion survives in session and retries on startup',
    () async {
      final memory = MemoryLocalHistoryStore();
      final store = _FailingFirstPromotionStore(memory, failures: 20);
      final sessions = MemoryDocumentSessionStore();
      final recovery = MemoryDocumentRecoveryStore();
      final harness = await _harness(
        store,
        sessionStore: sessions,
        recoveryStore: recovery,
      );
      await harness.controller.createMarkdownFile();
      harness.controller.updateActiveText('Lineage needing recovery\n');
      await Future<void>.delayed(Duration.zero);
      await harness.container
          .read(localHistoryControllerProvider.notifier)
          .flushBuffer(harness.state.activeBuffer!);
      final originalDocument = (await memory.load()).documents.single;
      final destination = p.join(root.path, 'Recovered-guide.md');
      expect(await harness.controller.saveActiveAs(destination), isTrue);

      await harness.controller.markCleanShutdown();
      expect(recovery.value.cleanShutdown, isFalse);
      expect(
        sessions.value?.pendingLocalHistoryAssociations.single.documentId,
        originalDocument.id,
      );

      final reopened = await _harness(
        store,
        sessionStore: sessions,
        recoveryStore: recovery,
      );
      expect(
        await reopened.controller.restoreStartupSession(
          reopenCleanSession: false,
        ),
        isTrue,
      );
      expect((await memory.load()).documents.single.currentPath, isNull);
      expect(reopened.state.activeBuffer!.id, sessions.value!.tabs.single.id);

      store.remainingPromotionFailures = 0;
      expect(
        await reopened.container
            .read(localHistoryControllerProvider.notifier)
            .flushAll(reopened.state.documentBuffers),
        isTrue,
      );
      final restoredHistory = await memory.load();
      expect(restoredHistory.documents, hasLength(1));
      expect(restoredHistory.documents.single.id, originalDocument.id);
      expect(restoredHistory.documents.single.currentPath, destination);
      expect(
        reopened.container
            .read(localHistoryControllerProvider.notifier)
            .pendingIdentityPromotions,
        isEmpty,
      );
    },
  );

  test('workspace rename settles a failed first-save promotion', () async {
    final memory = MemoryLocalHistoryStore();
    final store = _FailingFirstPromotionStore(memory);
    final harness = await _harness(store);
    await harness.controller.createMarkdownFile();
    harness.controller.updateActiveText('Untitled before rename\n');
    await Future<void>.delayed(Duration.zero);
    await harness.container
        .read(localHistoryControllerProvider.notifier)
        .flushBuffer(harness.state.activeBuffer!);
    final originalDocument = (await memory.load()).documents.single;
    final firstPath = p.join(root.path, 'A.md');
    final finalPath = p.join(root.path, 'B.md');
    expect(await harness.controller.saveActiveAs(firstPath), isTrue);
    expect((await memory.load()).documents.single.currentPath, isNull);

    expect(
      await harness.controller.renameWorkspaceEntity(firstPath, 'B.md'),
      isTrue,
    );
    expect(harness.state.activeBuffer!.filePath, finalPath);
    harness.controller.updateActiveText('Saved after rename\n');
    expect(await harness.controller.saveActive(), isTrue);

    final snapshot = await memory.load();
    expect(snapshot.documents, hasLength(1));
    expect(snapshot.documents.single.id, originalDocument.id);
    expect(snapshot.documents.single.currentPath, finalPath);
    expect(
      await _revisionSources(
        memory,
        snapshot.revisionsFor(originalDocument.id),
      ),
      containsAll(['Untitled before rename\n', 'Saved after rename\n']),
    );
  });

  test(
    'workspace directory move settles a nested failed first-save promotion',
    () async {
      final drafts = Directory(p.join(root.path, 'drafts'));
      final archive = Directory(p.join(root.path, 'archive'));
      await drafts.create();
      await archive.create();
      final memory = MemoryLocalHistoryStore();
      final store = _FailingFirstPromotionStore(memory);
      final harness = await _harness(store);
      await harness.controller.openPath(root.path);
      await harness.controller.createMarkdownFile();
      harness.controller.updateActiveText('Untitled before directory move\n');
      await Future<void>.delayed(Duration.zero);
      await harness.container
          .read(localHistoryControllerProvider.notifier)
          .flushBuffer(harness.state.activeBuffer!);
      final originalDocument = (await memory.load()).documents.single;
      final firstPath = p.join(drafts.path, 'A.md');
      final movedDirectory = p.join(archive.path, 'drafts');
      final finalPath = p.join(movedDirectory, 'A.md');
      expect(await harness.controller.saveActiveAs(firstPath), isTrue);
      expect((await memory.load()).documents.single.currentPath, isNull);

      expect(
        await harness.controller.moveWorkspaceEntity(drafts.path, archive.path),
        isTrue,
      );
      expect(harness.state.activeBuffer!.filePath, finalPath);
      harness.controller.updateActiveText('Saved after directory move\n');
      expect(await harness.controller.saveActive(), isTrue);

      final snapshot = await memory.load();
      expect(snapshot.documents, hasLength(1));
      expect(snapshot.documents.single.id, originalDocument.id);
      expect(snapshot.documents.single.currentPath, finalPath);
      expect(
        await _revisionSources(
          memory,
          snapshot.revisionsFor(originalDocument.id),
        ),
        containsAll([
          'Untitled before directory move\n',
          'Saved after directory move\n',
        ]),
      );
    },
  );

  testWidgets(
    'comparison renders styled intraline spans without framework errors',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final path = p.join(root.path, 'render.md');
      final harness = (await tester.runAsync(() async {
        await File(
          path,
        ).writeAsString('# Current title\n\nCurrent paragraph.\n');
        final store = MemoryLocalHistoryStore();
        final captured = await _capture(
          store,
          path,
          '# Historical title\n\nHistorical paragraph.\n',
        );
        final harness = await _harness(store);
        await harness.controller.openPath(path);
        final history = harness.container.read(
          localHistoryControllerProvider.notifier,
        );
        await history.refresh();
        history.selectDocument(captured.document.id);
        await history.selectRevision(captured.revision!.id);
        return harness;
      }))!;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: harness.container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildBusyMarkTheme(
              brightness: Brightness.light,
              accentColor: Colors.blue,
            ),
            home: const Scaffold(body: LocalHistoryComparisonView()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      expect(find.byType(SelectableText), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'comparison restore actions wait for the current replacement result',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final path = p.join(root.path, 'pending-comparison.md');
      final computer = _BlockingReplacementComparisonComputer();
      final harness = (await tester.runAsync(() async {
        await File(path).writeAsString('Current line\n');
        final store = MemoryLocalHistoryStore();
        final captured = await _capture(store, path, 'Historical line\n');
        final harness = await _harness(
          store,
          comparisonComputer: computer.call,
        );
        await harness.controller.openPath(path);
        final history = harness.container.read(
          localHistoryControllerProvider.notifier,
        );
        await history.refresh();
        history.selectDocument(captured.document.id);
        await history.selectRevision(captured.revision!.id);
        return harness;
      }))!;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: harness.container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildBusyMarkTheme(
              brightness: Brightness.light,
              accentColor: Colors.blue,
            ),
            home: const Scaffold(body: LocalHistoryComparisonView()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(LocalHistoryComparisonView));
      final l10n = AppLocalizations.of(context);
      final restoreAll = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.tooltip == l10n.localHistoryRestoreRevision,
      );
      final restoreChange = find.ancestor(
        of: find.text('${l10n.localHistoryRestoreChange} 1'),
        matching: find.byType(OutlinedButton),
      );
      expect(tester.widget<IconButton>(restoreAll).onPressed, isNotNull);
      expect(tester.widget<OutlinedButton>(restoreChange).onPressed, isNotNull);

      harness.controller.updateActiveText('Replacement current line\n');
      await tester.pump();
      await tester.runAsync(() => computer.replacementStarted.future);
      await tester.pump();

      expect(tester.widget<IconButton>(restoreAll).onPressed, isNull);
      expect(tester.widget<OutlinedButton>(restoreChange).onPressed, isNull);

      computer.completeReplacement();
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(restoreAll).onPressed, isNotNull);
      expect(tester.widget<OutlinedButton>(restoreChange).onPressed, isNotNull);
    },
  );

  testWidgets(
    'workspace refresh invalidates a completed comparison by source content',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final path = p.join(root.path, 'refreshed-comparison.md');
      final computer = _BlockingReplacementComparisonComputer();
      final monitor = _ControlledFileMonitor();
      final harness = (await tester.runAsync(() async {
        await File(path).writeAsString('Current before refresh\n');
        final store = MemoryLocalHistoryStore();
        final captured = await _capture(
          store,
          path,
          'Historical comparison text\n',
        );
        final harness = await _harness(
          store,
          fileMonitor: monitor,
          comparisonComputer: computer.call,
        );
        await harness.controller.openPath(path);
        final history = harness.container.read(
          localHistoryControllerProvider.notifier,
        );
        await history.refresh();
        history.selectDocument(captured.document.id);
        await history.selectRevision(captured.revision!.id);
        return harness;
      }))!;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: harness.container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildBusyMarkTheme(
              brightness: Brightness.light,
              accentColor: Colors.blue,
            ),
            home: const Scaffold(body: LocalHistoryComparisonView()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final initialRevision = harness.state.activeBuffer!.revision;
      final context = tester.element(find.byType(LocalHistoryComparisonView));
      final l10n = AppLocalizations.of(context);
      final restoreAll = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.tooltip == l10n.localHistoryRestoreRevision,
      );
      expect(tester.widget<IconButton>(restoreAll).onPressed, isNotNull);

      await tester.runAsync(() async {
        await File(path).writeAsString('Current after refresh\n');
        expect(
          await harness.controller.refreshWorkspaceFromDiskPreservingOpenTabs(),
          isTrue,
        );
      });
      expect(harness.state.activeBuffer!.revision, initialRevision + 1);
      expect(harness.state.activeText, 'Current after refresh\n');
      await tester.pump();
      await tester.runAsync(() => computer.replacementStarted.future);
      await tester.pump();

      expect(tester.widget<IconButton>(restoreAll).onPressed, isNull);

      computer.completeReplacement();
      await tester.pumpAndSettle();
      expect(computer.replacementCurrent.source, 'Current after refresh\n');
      expect(find.textContaining('Current after refresh'), findsWidgets);
      expect(tester.widget<IconButton>(restoreAll).onPressed, isNotNull);
    },
  );
}

SourceComparison _comparison(
  LocalHistoryRevision revision,
  DocumentBuffer buffer,
) => compareSource(
  SourceComparisonInput(
    id: revision.summary.id,
    version: revision.summary.capturedAt.microsecondsSinceEpoch,
    label: 'Selected revision',
    source: revision.source,
  ),
  SourceComparisonInput(
    id: buffer.id,
    version: buffer.revision,
    label: 'Current editor content',
    source: buffer.text,
  ),
);

Future<List<String>> _revisionSources(
  LocalHistoryStore store,
  Iterable<LocalHistoryRevisionSummary> summaries,
) async {
  final sources = <String>[];
  for (final summary in summaries) {
    final revision = await store.readRevision(summary.id);
    if (revision != null) sources.add(revision.source);
  }
  return sources;
}

Future<void> _waitFor(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 3));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for workspace state');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

Future<LocalHistoryCaptureResult> _capture(
  LocalHistoryStore store,
  String path,
  String source, {
  LocalHistoryCaptureReason reason = LocalHistoryCaptureReason.saved,
}) => store.capture(
  LocalHistoryCaptureRequest(
    path: path,
    displayName: p.basename(path),
    source: source,
    format: TextFormatMetadata.utf8Lf,
    capturedAt: DateTime.utc(2026, 1, 1),
    reason: reason,
  ),
  const LocalHistoryPolicy(),
);

Future<_Harness> _harness(
  LocalHistoryStore store, {
  WorkspaceService service = const WorkspaceService(),
  WorkspaceFileMonitor? fileMonitor,
  LocalHistoryTimerFactory? timerFactory,
  LocalHistoryComparisonComputer? comparisonComputer,
  DocumentSessionStore? sessionStore,
  DocumentRecoveryStore? recoveryStore,
}) async {
  final container = ProviderContainer(
    overrides: [
      localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
      localHistoryStoreProvider.overrideWithValue(store),
      localHistoryClockProvider.overrideWithValue(
        () => DateTime.utc(2026, 1, 1, 0, 1),
      ),
      workspaceServiceProvider.overrideWithValue(service),
      if (sessionStore != null)
        documentSessionStoreProvider.overrideWithValue(sessionStore),
      if (recoveryStore != null)
        documentRecoveryStoreProvider.overrideWithValue(recoveryStore),
      if (fileMonitor != null)
        workspaceFileMonitorProvider.overrideWithValue(fileMonitor),
      if (timerFactory != null)
        localHistoryTimerFactoryProvider.overrideWithValue(timerFactory),
      if (comparisonComputer != null)
        localHistoryComparisonComputerProvider.overrideWithValue(
          comparisonComputer,
        ),
    ],
  );
  addTearDown(container.dispose);
  final settings = container.read(appSettingsControllerProvider.notifier);
  final controller = container.read(workspaceControllerProvider.notifier);
  await Future<void>.delayed(Duration.zero);
  await settings.setAutoSave(false);
  return _Harness(container, controller);
}

class _Harness {
  const _Harness(this.container, this.controller);

  final ProviderContainer container;
  final WorkspaceController controller;

  WorkspaceState get state => container.read(workspaceControllerProvider);
}

class _MemorySettingsStore implements LocalSettingsStore {
  Map<String, Object?> value = {};

  @override
  Future<Map<String, Object?>> load() async => value;

  @override
  Future<void> save(Map<String, Object?> json) async => value = json;
}

class _FailingProtectiveStore implements LocalHistoryStore {
  const _FailingProtectiveStore(this.delegate);

  final LocalHistoryStore delegate;

  @override
  Future<LocalHistoryCaptureResult> capture(
    LocalHistoryCaptureRequest request,
    LocalHistoryPolicy policy,
  ) {
    if (request.reason == LocalHistoryCaptureReason.beforeRestore) {
      throw const LocalHistoryStorageException('Injected capture failure');
    }
    return delegate.capture(request, policy);
  }

  @override
  Future<void> clearAll() => delegate.clearAll();

  @override
  Future<void> clearDocument(String documentId) =>
      delegate.clearDocument(documentId);

  @override
  Future<LocalHistorySnapshot> load() => delegate.load();

  @override
  Future<void> markDeleted(String path, {required bool recursive}) =>
      delegate.markDeleted(path, recursive: recursive);

  @override
  Future<LocalHistoryRevision?> readRevision(String revisionId) =>
      delegate.readRevision(revisionId);

  @override
  Future<void> prune(LocalHistoryPolicy policy, DateTime now) =>
      delegate.prune(policy, now);

  @override
  Future<LocalHistoryDocument?> promoteUntitledDocument({
    required String documentId,
    required String destinationPath,
    required String displayName,
    required DateTime updatedAt,
  }) => delegate.promoteUntitledDocument(
    documentId: documentId,
    destinationPath: destinationPath,
    displayName: displayName,
    updatedAt: updatedAt,
  );

  @override
  Future<void> remapPath(String sourcePath, String destinationPath) =>
      delegate.remapPath(sourcePath, destinationPath);
}

class _FailingSavedStore extends _FailingProtectiveStore {
  const _FailingSavedStore(super.delegate);

  @override
  Future<LocalHistoryCaptureResult> capture(
    LocalHistoryCaptureRequest request,
    LocalHistoryPolicy policy,
  ) {
    if (request.reason == LocalHistoryCaptureReason.saved) {
      throw const LocalHistoryStorageException('Injected saved failure');
    }
    return delegate.capture(request, policy);
  }
}

class _FailingFirstPromotionStore extends _FailingProtectiveStore {
  _FailingFirstPromotionStore(super.delegate, {int failures = 1})
    : remainingPromotionFailures = failures;

  int remainingPromotionFailures;

  @override
  Future<LocalHistoryDocument?> promoteUntitledDocument({
    required String documentId,
    required String destinationPath,
    required String displayName,
    required DateTime updatedAt,
  }) {
    if (remainingPromotionFailures > 0) {
      remainingPromotionFailures--;
      throw const LocalHistoryStorageException('Injected promotion failure');
    }
    return delegate.promoteUntitledDocument(
      documentId: documentId,
      destinationPath: destinationPath,
      displayName: displayName,
      updatedAt: updatedAt,
    );
  }
}

class _BlockingBeforeReloadStore extends _FailingProtectiveStore {
  _BlockingBeforeReloadStore(super.delegate);

  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<LocalHistoryCaptureResult> capture(
    LocalHistoryCaptureRequest request,
    LocalHistoryPolicy policy,
  ) async {
    if (request.reason == LocalHistoryCaptureReason.beforeReload) {
      if (!started.isCompleted) started.complete();
      await release.future;
    }
    return delegate.capture(request, policy);
  }
}

class _BlockingNextReparseWorkspaceService extends WorkspaceService {
  var _pauseNext = false;
  final started = Completer<void>();
  final finished = Completer<void>();
  final _release = Completer<void>();

  void pauseNext() => _pauseNext = true;

  void release() {
    if (!_release.isCompleted) _release.complete();
  }

  @override
  Future<Workspace> reparseActive(Workspace workspace, String source) async {
    final reparsed = await super.reparseActive(workspace, source);
    if (!_pauseNext) return reparsed;
    _pauseNext = false;
    if (!started.isCompleted) started.complete();
    await _release.future;
    if (!finished.isCompleted) finished.complete();
    return reparsed;
  }
}

class _BlockingReplacementComparisonComputer {
  var _calls = 0;
  final replacementStarted = Completer<void>();
  final _replacement = Completer<SourceComparison>();
  late SourceComparisonInput _replacementOld;
  late SourceComparisonInput _replacementCurrent;

  SourceComparisonInput get replacementCurrent => _replacementCurrent;

  Future<SourceComparison> call(
    SourceComparisonInput oldInput,
    SourceComparisonInput currentInput,
  ) {
    if (_calls++ == 0) {
      return Future.value(compareSource(oldInput, currentInput));
    }
    _replacementOld = oldInput;
    _replacementCurrent = currentInput;
    if (!replacementStarted.isCompleted) replacementStarted.complete();
    return _replacement.future;
  }

  void completeReplacement() {
    if (_replacement.isCompleted) return;
    _replacement.complete(compareSource(_replacementOld, _replacementCurrent));
  }
}

class _BlockingRemapStore extends _FailingProtectiveStore {
  _BlockingRemapStore(super.delegate);

  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<void> remapPath(String sourcePath, String destinationPath) async {
    if (!started.isCompleted) started.complete();
    await release.future;
    await delegate.remapPath(sourcePath, destinationPath);
  }
}

class _BlockingSaveAsStore extends _FailingProtectiveStore {
  _BlockingSaveAsStore(super.delegate, this.destinationPath);

  final String destinationPath;
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<LocalHistoryCaptureResult> capture(
    LocalHistoryCaptureRequest request,
    LocalHistoryPolicy policy,
  ) async {
    if (request.reason == LocalHistoryCaptureReason.saved &&
        request.path != null &&
        p.equals(request.path!, destinationPath)) {
      if (!started.isCompleted) started.complete();
      await release.future;
    }
    return delegate.capture(request, policy);
  }
}

class _ControlledFileMonitor extends WorkspaceFileMonitor {
  final _events = StreamController<WorkspaceFileMonitorEvent>.broadcast();

  @override
  Stream<WorkspaceFileMonitorEvent> get events => _events.stream;

  void emitMove(String sourcePath, String destinationPath) {
    _events.add(
      WorkspaceFileMonitorEvent(
        kind: WorkspaceFileEventKind.moved,
        path: sourcePath,
        destinationPath: destinationPath,
      ),
    );
  }

  @override
  Future<void> start({
    required String rootPath,
    required Iterable<String> openFilePaths,
  }) async {}

  @override
  void updateOpenFilePaths(Iterable<String> paths) {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() => _events.close();
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

class _DelayedSaveWorkspaceService extends WorkspaceService {
  final started = Completer<void>();
  final _release = Completer<void>();

  void release() => _release.complete();

  @override
  Future<WorkspaceFileSnapshot> saveText(String path, String text) async {
    started.complete();
    await _release.future;
    return super.saveText(path, text);
  }
}
