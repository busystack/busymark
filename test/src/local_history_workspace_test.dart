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
import 'package:busymark/src/workspace/workspace_message.dart';
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

  test('pristine empty draft discards without protective storage', () async {
    final store = _UnavailableCaptureStore();
    final harness = await _harness(store);
    expect(await harness.controller.createMarkdownWorkspace(), isTrue);
    final buffer = harness.state.activeBuffer!;
    expect(buffer.isDirty, isTrue);
    expect(
      await harness.controller.closeDocumentBuffer(buffer.id, discard: true),
      isTrue,
    );
    expect(store.protectiveAttempts, 0);
    expect(harness.state.activeBuffer, isNull);
  });

  test(
    'workspace replacement retires settled bindings and retains failed baselines',
    () async {
      final first = p.join(root.path, 'first.md');
      final second = p.join(root.path, 'second.md');
      await File(first).writeAsString('first original');
      await File(second).writeAsString('second original');
      final store = _UnavailableCaptureStore();
      final harness = await _harness(store);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      await harness.controller.openPath(first);
      final oldId = harness.state.activeBuffer!.id;
      expect(await history.flushBuffer(harness.state.activeBuffer!), isFalse);
      await harness.controller.openPath(second);
      final secondId = harness.state.activeBuffer!.id;
      expect(secondId, isNot(oldId));
      expect(await history.flushAll(harness.state.documentBuffers), isFalse);
      store.available = true;
      expect(await history.flushAll(harness.state.documentBuffers), isTrue);
      expect(history.documentIdForBuffer(oldId), isNull);
      expect(
        await _revisionSources(store, (await store.load()).revisions),
        containsAll(['first original', 'second original']),
      );
      await harness.controller.openPath(first);
      expect(history.documentIdForBuffer(secondId), isNull);
      expect(history.warningForBuffer(harness.state.activeBuffer!.id), isNull);
    },
  );

  for (final scenario in [
    'nonempty',
    'whitespace',
    'edited-empty',
    'recovered',
    'file',
  ]) {
    test(
      'discard still protects $scenario content when history is unavailable',
      () async {
        final store = _UnavailableCaptureStore();
        final recovery = MemoryDocumentRecoveryStore();
        if (scenario == 'recovered') {
          await recovery.writeEntries([
            DocumentRecoveryEntry.fromBuffer(
              DocumentBuffer.untitled(
                id: 'recovered-empty',
                name: 'Recovered.md',
              ),
              workspacePath: null,
            ),
          ]);
        }
        final harness = await _harness(store, recoveryStore: recovery);
        if (scenario == 'recovered') {
          expect(await harness.controller.restorePreviousSession(), isTrue);
          expect(harness.state.activeBuffer!.recovered, isTrue);
        } else if (scenario == 'file') {
          final path = p.join(root.path, 'file.md');
          await File(path).writeAsString('saved content');
          await harness.controller.openPath(path);
          harness.controller.updateActiveText('');
        } else {
          await harness.controller.createMarkdownWorkspace();
          harness.controller.updateActiveText(
            scenario == 'whitespace' ? ' \n\t' : 'valuable content',
          );
          if (scenario == 'edited-empty') {
            harness.controller.updateActiveText('');
          }
        }
        final before = harness.state.activeBuffer!;
        expect(
          await harness.controller.closeDocumentBuffer(
            before.id,
            discard: true,
          ),
          isFalse,
        );
        expect(store.protectiveAttempts, 1);
        expect(harness.state.activeBuffer, same(before));
        expect(harness.state.activeText, before.text);
      },
    );
  }

  test(
    'background protective retry cannot execute a previously rejected discard',
    () async {
      final store = _UnavailableCaptureStore();
      final timers = <_FakeTimer>[];
      final harness = await _harness(
        store,
        timerFactory: (delay, callback) {
          final timer = _FakeTimer(delay, callback);
          timers.add(timer);
          return timer;
        },
      );
      await harness.controller.createMarkdownWorkspace();
      harness.controller.updateActiveText('keep this document');
      final before = harness.state.activeBuffer!;
      expect(
        await harness.controller.closeDocumentBuffer(before.id, discard: true),
        isFalse,
      );
      store.available = true;
      for (final timer in timers.toList()) {
        timer.fire();
      }
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(await history.flushAll(harness.state.documentBuffers), isTrue);
      expect(harness.state.activeBuffer, same(before));
      expect(harness.state.activeText, 'keep this document');
      final snapshot = await store.load();
      expect(
        await _revisionSources(store, snapshot.revisions),
        contains('keep this document'),
      );
    },
  );

  for (final fileStore in [false, true]) {
    for (final externalChange in [false, true]) {
      test('restored promotion reconciles only the saved lineage '
          '(file=$fileStore external=$externalChange)', () async {
        final LocalHistoryStore store = fileStore
            ? FileLocalHistoryStore(
                rootDirectory: () async =>
                    Directory(p.join(root.path, 'history')),
              )
            : MemoryLocalHistoryStore();
        final destination = p.join(root.path, 'Untitled.md');
        final old = await _capture(
          store,
          destination,
          'Old retained contents\n',
        );
        final saved = await store.capture(
          LocalHistoryCaptureRequest(
            displayName: 'Untitled 1',
            untitled: true,
            source: 'Recovered lineage\n',
            format: TextFormatMetadata.utf8Lf.copyWith(hasFinalNewline: true),
            capturedAt: DateTime.utc(2026, 1, 1, 0, 0, 10),
            reason: LocalHistoryCaptureReason.automaticCheckpoint,
          ),
          const LocalHistoryPolicy(),
        );
        await File(destination).writeAsString(
          externalChange ? 'External replacement\n' : 'Recovered lineage\n',
        );
        final sessions = MemoryDocumentSessionStore()
          ..value = WorkspaceSessionSnapshot(
            workspacePath: null,
            tabs: const [],
            activeBufferId: null,
            pendingLocalHistoryAssociations: [
              PendingLocalHistoryAssociation(
                bufferId: 'old-closed-buffer',
                documentId: saved.document.id,
                destinationPath: destination,
                displayName: 'Untitled.md',
              ),
            ],
          );
        final harness = await _harness(
          store,
          sessionStore: sessions,
          recoveryStore: MemoryDocumentRecoveryStore(),
        );
        await harness.controller.restorePreviousSession();
        final history = harness.container.read(
          localHistoryControllerProvider.notifier,
        );
        var snapshot = await store.load();
        expect(
          snapshot.documents
              .singleWhere((d) => d.id == old.document.id)
              .deleted,
          !externalChange,
          reason:
              'warning=${harness.container.read(localHistoryControllerProvider).warning?.detail}; pending=${history.pendingIdentityPromotions.length}; docs=${snapshot.documents.map((d) => '${d.id}:${d.untitled}:${d.updatedAt}').toList()}',
        );
        expect(
          snapshot.documents
              .singleWhere((d) => d.id == saved.document.id)
              .currentPath,
          externalChange ? isNull : destination,
        );
        expect(
          (await store.readRevision(old.revision!.id))!.source,
          'Old retained contents\n',
        );
        expect(
          (await store.readRevision(saved.revision!.id))!.source,
          'Recovered lineage\n',
        );
        expect(
          history.pendingIdentityPromotions,
          externalChange ? hasLength(1) : isEmpty,
        );
        await harness.controller.createMarkdownFile();
        harness.controller.updateActiveText('New unrelated document\n');
        await history.flushBuffer(harness.state.activeBuffer!);
        final warning = harness.container
            .read(localHistoryControllerProvider)
            .warning;
        if (externalChange) {
          expect(warning?.kind, LocalHistoryWarningKind.pathChange);
          expect(warning?.detail, destination);
        } else {
          expect(warning, isNull);
          await harness.controller.flushPersistence();
          expect(sessions.value!.pendingLocalHistoryAssociations, isEmpty);
        }
        snapshot = await store.load();
        expect(snapshot.documents, hasLength(3));
        expect(
          await File(destination).readAsString(),
          externalChange ? 'External replacement\n' : 'Recovered lineage\n',
        );
      });
    }
  }

  test('first save cannot adopt a deleted path lineage', () async {
    final store = MemoryLocalHistoryStore();
    final destination = p.join(root.path, 'Note.md');
    final old = await _capture(store, destination, 'Old retained history\n');
    await store.markDeleted(destination, recursive: false);
    final harness = await _harness(store);

    await harness.controller.createMarkdownFile();
    harness.controller.updateActiveText('New file contents\n');
    expect(await harness.controller.saveActiveAs(destination), isTrue);

    final snapshot = await store.load();
    final oldDocument = snapshot.documents.singleWhere(
      (document) => document.id == old.document.id,
    );
    final active = snapshot.documents.singleWhere(
      (document) => !document.deleted && document.currentPath == destination,
    );
    expect(active.id, isNot(oldDocument.id));
    expect(oldDocument.deleted, isTrue);
    expect(
      await _revisionSources(store, snapshot.revisionsFor(oldDocument.id)),
      ['Old retained history\n'],
    );
    expect(await File(destination).readAsString(), 'New file contents\n');
    expect(harness.state.activeBuffer!.isDirty, isFalse);
    expect(
      harness.container.read(localHistoryControllerProvider).warning?.kind,
      isNot(LocalHistoryWarningKind.pathChange),
    );
  });

  test('vacant first save retires a stale active history owner', () async {
    final store = MemoryLocalHistoryStore();
    final destination = p.join(root.path, 'Note.md');
    final stale = await _capture(store, destination, 'Stale owner\n');
    expect(await File(destination).exists(), isFalse);
    final harness = await _harness(store);

    await harness.controller.createMarkdownFile();
    harness.controller.updateActiveText('Created after vacancy check\n');
    expect(await harness.controller.saveActiveAs(destination), isTrue);

    final snapshot = await store.load();
    final retired = snapshot.documents.singleWhere(
      (document) => document.id == stale.document.id,
    );
    final active = snapshot.documents.singleWhere(
      (document) => !document.deleted && document.currentPath == destination,
    );
    expect(retired.deleted, isTrue);
    expect(active.id, isNot(retired.id));
    expect(
      harness.container.read(localHistoryControllerProvider).warning?.kind,
      isNot(LocalHistoryWarningKind.pathChange),
    );
  });

  test(
    'first save promotes an established untitled lineage over deleted history',
    () async {
      final store = MemoryLocalHistoryStore();
      final destination = p.join(root.path, 'Note.md');
      final old = await _capture(store, destination, 'Deleted revision\n');
      await store.markDeleted(destination, recursive: false);
      final harness = await _harness(store);
      await harness.controller.createMarkdownFile();
      harness.controller.updateActiveText('Established untitled revision\n');
      await Future<void>.delayed(Duration.zero);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
      final untitledId = history.documentIdForBuffer(
        harness.state.activeBuffer!.id,
      );

      expect(await harness.controller.saveActiveAs(destination), isTrue);
      final snapshot = await store.load();
      expect(
        snapshot.documents.singleWhere((document) => !document.deleted).id,
        untitledId,
      );
      expect(
        snapshot.documents
            .singleWhere((document) => document.id == old.document.id)
            .deleted,
        isTrue,
      );
    },
  );

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

  for (final clearAll in [false, true]) {
    test(
      'Clear ${clearAll ? "All" : "Document"} cancels queued restore protection',
      () async {
        final path = p.join(root.path, 'protected.md');
        await File(path).writeAsString('Original disk\n');
        final diskStore = FileLocalHistoryStore(
          rootDirectory: () async => Directory(p.join(root.path, 'history')),
        );
        final store = _BlockingSaveAsStore(diskStore, path);
        final harness = await _harness(store);
        await harness.controller.openPath(path);
        final history = harness.container.read(
          localHistoryControllerProvider.notifier,
        );
        final baseline = await diskStore.load();
        final document = baseline.documents.single;
        final revision = (await diskStore.readRevision(
          baseline.revisions.single.id,
        ))!;
        harness.controller.updateActiveText('Current work to protect\n');
        final before = harness.state.activeBuffer!;

        // A real explicit save holds the per-buffer history queue. Restore
        // must not treat its later, invalidated protection as a stored copy.
        final save = harness.controller.saveActive();
        await store.started.future;
        final restore = harness.controller.restoreLocalHistoryRevision(
          document: document,
          revision: revision,
        );
        final clear = clearAll
            ? history.clearAll()
            : history.clearDocument(document.id);
        store.release.complete();
        expect(await save, isTrue);
        expect(await restore, isFalse);
        await clear;

        final current = harness.state.activeBuffer!;
        expect(current.text, before.text);
        expect(current.revision, before.revision);
        expect(current.editorState.selection, before.editorState.selection);
        expect(
          current.editorState.undoState,
          same(before.editorState.undoState),
        );
        expect(await File(path).readAsString(), before.text);
        expect((await diskStore.load()).revisions, isEmpty);
      },
    );
  }

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
    'missing history restores over an existing file without touching disk and undoes to its real source',
    () async {
      final anchor = p.join(root.path, 'anchor.md');
      final destination = p.join(root.path, 'destination.md');
      await File(anchor).writeAsString('# Anchor\n');
      final originalBytes = <int>[
        0xef,
        0xbb,
        0xbf,
        ...'Original destination\r\nSecond line'.codeUnits,
      ];
      await File(destination).writeAsBytes(originalBytes);
      final store = MemoryLocalHistoryStore();
      final captured = await _capture(
        store,
        p.join(root.path, 'deleted.md'),
        '# Recovered\n\nHistorical content.\n',
        reason: LocalHistoryCaptureReason.beforeDelete,
      );
      final harness = await _harness(store);
      await harness.controller.openPath(root.path);
      final revision = (await store.readRevision(captured.revision!.id))!;

      expect(
        await harness.controller.restoreMissingLocalHistoryRevision(
          document: captured.document,
          revision: revision,
          destinationPath: destination,
          overwriteExisting: true,
        ),
        isTrue,
      );
      final restored = harness.state.activeBuffer!;
      expect(restored.filePath, destination);
      expect(restored.text, revision.source);
      expect(restored.isDirty, isTrue);
      expect(restored.format.hasUtf8Bom, isTrue);
      expect(restored.format.lineEnding, DocumentLineEnding.crlf);
      expect(restored.format.hasFinalNewline, isFalse);
      expect(await File(destination).readAsBytes(), originalBytes);

      expect(harness.controller.undoActiveBuffer(), isTrue);
      expect(harness.state.activeText, 'Original destination\nSecond line');
      expect(harness.controller.redoActiveBuffer(), isTrue);
      expect(harness.state.activeText, revision.source);
    },
  );

  test(
    'existing open destination protects unsaved source as the restore undo baseline',
    () async {
      final sourcePath = p.join(root.path, 'deleted.md');
      final destination = p.join(root.path, 'open.md');
      final anchor = p.join(root.path, 'anchor.md');
      await File(destination).writeAsString('Disk destination\n');
      await File(anchor).writeAsString('Anchor\n');
      final store = MemoryLocalHistoryStore();
      final captured = await _capture(store, sourcePath, 'Recovered source\n');
      final harness = await _harness(store);
      await harness.controller.openPath(root.path);
      await harness.controller.openActiveFile(destination);
      harness.controller.updateActiveText('Unsaved destination\n');
      expect(await harness.controller.openActiveFile(anchor), isTrue);
      final revision = (await store.readRevision(captured.revision!.id))!;

      expect(
        await harness.controller.restoreMissingLocalHistoryRevision(
          document: captured.document,
          revision: revision,
          destinationPath: destination,
          overwriteExisting: true,
        ),
        isTrue,
      );
      expect(harness.state.activeBuffer?.filePath, destination);
      expect(harness.state.activeText, 'Recovered source\n');
      expect(await File(destination).readAsString(), 'Disk destination\n');
      expect(harness.controller.undoActiveBuffer(), isTrue);
      expect(harness.state.activeText, 'Unsaved destination\n');
    },
  );

  test(
    'existing destination restore stops when protection fails or the target changes',
    () async {
      final sourcePath = p.join(root.path, 'deleted.md');
      final destination = p.join(root.path, 'protected.md');
      await File(destination).writeAsString('Protected destination\n');
      final memory = MemoryLocalHistoryStore();
      final captured = await _capture(memory, sourcePath, 'Recovered source\n');
      final revision = (await memory.readRevision(captured.revision!.id))!;

      final failing = await _harness(_FailingProtectiveStore(memory));
      await failing.controller.openPath(destination);
      expect(
        await failing.controller.restoreMissingLocalHistoryRevision(
          document: captured.document,
          revision: revision,
          destinationPath: destination,
          overwriteExisting: true,
        ),
        isFalse,
      );
      expect(failing.state.activeText, 'Protected destination\n');
      expect(await File(destination).readAsString(), 'Protected destination\n');

      final blockingStore = _BlockingProtectiveStore(memory);
      final changing = await _harness(blockingStore);
      await changing.controller.openPath(destination);
      final restore = changing.controller.restoreMissingLocalHistoryRevision(
        document: captured.document,
        revision: revision,
        destinationPath: destination,
        overwriteExisting: true,
      );
      await blockingStore.started.future;
      changing.controller.updateActiveText('Newer destination edit\n');
      blockingStore.release.complete();
      expect(await restore, isFalse);
      expect(changing.state.activeText, 'Newer destination edit\n');
      expect(await File(destination).readAsString(), 'Protected destination\n');
    },
  );

  test(
    'autosaved existing-destination recovery never publishes an empty file',
    () async {
      final sourcePath = p.join(root.path, 'deleted.md');
      final destination = p.join(root.path, 'autosave.md');
      await File(destination).writeAsString('Original destination\n');
      final store = MemoryLocalHistoryStore();
      final captured = await _capture(store, sourcePath, 'Recovered source\n');
      final service = _RecordingRestoreWorkspaceService();
      final harness = await _harness(store, service: service);
      await harness.container
          .read(appSettingsControllerProvider.notifier)
          .setAutoSave(true);
      await harness.controller.openPath(destination);
      service.writes.clear();
      final revision = (await store.readRevision(captured.revision!.id))!;

      expect(
        await harness.controller.restoreMissingLocalHistoryRevision(
          document: captured.document,
          revision: revision,
          destinationPath: destination,
          overwriteExisting: true,
        ),
        isTrue,
      );
      expect(service.writes, isEmpty);
      expect(await harness.controller.autoSaveActiveIfNeeded(), isTrue);
      expect(service.writes, [revision.source]);
      expect(service.writes, isNot(contains('')));
      expect(await File(destination).readAsString(), revision.source);
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
    'external move cannot remap a replacement created while loading target',
    () async {
      final source = p.join(root.path, 'external-source.md');
      final destination = p.join(root.path, 'external-destination.md');
      await File(source).writeAsString('old external lineage\n');
      final memory = MemoryLocalHistoryStore();
      final service = _BlockingTargetLoadWorkspaceService(destination);
      final monitor = _ControlledFileMonitor();
      final harness = await _harness(
        memory,
        service: service,
        fileMonitor: monitor,
      );
      await harness.controller.openPath(source);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
      final oldId = history.documentIdForBuffer(
        harness.state.activeBuffer!.id,
      )!;
      await File(source).rename(destination);

      monitor.emitMove(source, destination);
      await service.started.future;
      await memory.clearDocument(oldId);
      final replacement = await _capture(
        memory,
        source,
        'replacement external lineage\n',
      );
      service.release.complete();
      await _waitFor(
        () => harness.state.activeBuffer?.filePath == destination,
        operation: 'external move completion',
      );

      final snapshot = await memory.load();
      final retained = snapshot.documents.singleWhere(
        (document) => document.id == replacement.document.id,
      );
      expect(retained.deleted, isFalse);
      expect(retained.currentPath, source);
      expect(
        snapshot.documents.where(
          (document) => document.currentPath == destination,
        ),
        isEmpty,
      );
    },
  );

  test(
    'external move completion cannot publish into a replacement workspace',
    () async {
      final source = p.join(root.path, 'stale-monitor-source.md');
      final destination = p.join(root.path, 'stale-monitor-destination.md');
      const contents = 'same bytes across workspace replacement\n';
      await File(source).writeAsString(contents);
      final memory = MemoryLocalHistoryStore();
      final service = _BlockingTargetLoadWorkspaceService(destination);
      final monitor = _ControlledFileMonitor();
      final harness = await _harness(
        memory,
        service: service,
        fileMonitor: monitor,
      );
      await harness.controller.openPath(source);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
      final originalHistoryId = history.documentIdForBuffer(
        harness.state.activeBuffer!.id,
      )!;

      await File(source).rename(destination);
      monitor.emitMove(source, destination);
      await service.started.future;
      await File(source).writeAsString(contents);
      await harness.controller.openPath(source);
      final replacement = harness.state.activeBuffer!;
      expect(replacement.filePath, source);
      expect(replacement.text, contents);

      service.release.complete();
      await _waitFor(
        () => history.pendingPathReconciliations.isEmpty,
        operation: 'stale external move cancellation',
      );
      expect(harness.state.activeBuffer, same(replacement));
      expect(harness.state.activeBuffer!.filePath, source);
      expect(harness.state.workspace!.activeFilePath, source);
      expect(
        harness.state.documentBuffers.where(
          (buffer) => buffer.filePath == destination,
        ),
        isEmpty,
      );
      expect(
        history.documentIdForBuffer(replacement.id),
        isNot(originalHistoryId),
      );
    },
  );

  test(
    'monitor event emitted after invalidation cannot enter reopened workspace',
    () async {
      final source = p.join(root.path, 'invalidated-monitor-source.md');
      final destination = p.join(
        root.path,
        'invalidated-monitor-destination.md',
      );
      const contents = 'same bytes in reopened workspace\n';
      await File(source).writeAsString(contents);
      final memory = MemoryLocalHistoryStore();
      final service = _BlockingReplacementOpenAndTargetLoadService(
        sourcePath: source,
        targetPath: destination,
      );
      final monitor = _ControlledFileMonitor();
      final harness = await _harness(
        memory,
        service: service,
        fileMonitor: monitor,
      );
      await harness.controller.openPath(source);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
      final originalHistoryId = history.documentIdForBuffer(
        harness.state.activeBuffer!.id,
      )!;

      await File(source).rename(destination);
      await File(source).writeAsString(contents);
      service.blockNextSourceOpen = true;
      final reopen = harness.controller.openPath(source);
      await service.sourceOpenStarted.future;

      // This notification belongs to the monitor that was invalidated when
      // the reopen began. It must be rejected at enqueue time rather than
      // inheriting the replacement workspace's generation during draining.
      monitor.emitMove(source, destination);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(service.targetLoadStarted.isCompleted, isFalse);

      service.releaseSourceOpen.complete();
      await reopen;
      service.releaseTargetLoad.complete();
      await Future<void>.delayed(Duration.zero);
      expect(harness.state.activeBuffer?.filePath, source);
      expect(harness.state.activeBuffer?.text, contents);
      expect(
        harness.state.documentBuffers.where(
          (buffer) => buffer.filePath == destination,
        ),
        isEmpty,
      );
      final snapshot = await memory.load();
      final original = snapshot.documents.singleWhere(
        (document) => document.id == originalHistoryId,
      );
      expect(original.currentPath, source);
    },
  );

  test('file monitor lifecycle recovers after a failed stop', () async {
    final first = p.join(root.path, 'monitor-stop-first.md');
    final second = p.join(root.path, 'monitor-stop-second.md');
    final moved = p.join(root.path, 'monitor-stop-moved.md');
    await File(first).writeAsString('first\n');
    await File(second).writeAsString('second\n');
    final monitor = _FailingStopFileMonitor();
    final harness = await _harness(
      MemoryLocalHistoryStore(),
      fileMonitor: monitor,
    );
    await harness.controller.openPath(first);
    expect(monitor.startAttempts, 1);

    monitor.failNextStop = true;
    await harness.controller.openPath(second);
    expect(harness.state.activeBuffer?.filePath, second);
    expect(monitor.startAttempts, 2);

    await harness.controller.openPath(first);
    expect(harness.state.activeBuffer?.filePath, first);
    expect(monitor.startAttempts, 3);
    await File(first).rename(moved);
    monitor.emitMove(first, moved);
    await _waitFor(
      () => harness.state.activeBuffer?.filePath == moved,
      operation: 'monitor recovery after failed stop',
    );
  });

  test(
    'editing while monitor start is pending still enables workspace events',
    () async {
      final source = p.join(root.path, 'monitor-start-source.md');
      final destination = p.join(root.path, 'monitor-start-destination.md');
      await File(source).writeAsString('opened source\n');
      final monitor = _BlockingStartFileMonitor();
      final harness = await _harness(
        MemoryLocalHistoryStore(),
        fileMonitor: monitor,
      );

      final open = harness.controller.openPath(source);
      await monitor.startStarted.future;
      expect(harness.state.activeBuffer?.filePath, source);
      harness.controller.updateActiveText(
        'edit accepted during monitor start\n',
      );
      monitor.releaseStart.complete();
      await open;

      await File(source).rename(destination);
      monitor.emitMove(source, destination);
      await _waitFor(
        () => harness.state.activeBuffer?.filePath == destination,
        operation: 'monitor event after edit during delayed start',
      );
      expect(
        harness.state.activeBuffer?.text,
        'edit accepted during monitor start\n',
      );
    },
  );

  test(
    'folder refresh while monitor start is pending still enables events',
    () async {
      final source = p.join(root.path, 'monitor-refresh-source.md');
      final destination = p.join(root.path, 'monitor-refresh-destination.md');
      await File(source).writeAsString('folder source\n');
      final monitor = _BlockingStartFileMonitor();
      final harness = await _harness(
        MemoryLocalHistoryStore(),
        fileMonitor: monitor,
      );

      final open = harness.controller.openPath(root.path);
      await monitor.startStarted.future;
      expect(harness.state.workspace?.kind, WorkspaceKind.markdownFolder);
      expect(
        await harness.controller.refreshWorkspaceFromDiskPreservingOpenTabs(),
        isTrue,
      );
      monitor.releaseStart.complete();
      await open;

      await File(source).rename(destination);
      monitor.emitMove(source, destination);
      await _waitFor(
        () => harness.state.activeBuffer?.filePath == destination,
        operation: 'monitor event after refresh during delayed start',
      );
    },
  );

  test(
    'disposed workspace ignores a delayed monitor start completion',
    () async {
      final source = p.join(root.path, 'monitor-disposal-source.md');
      await File(source).writeAsString('disk source\n');
      final monitor = _BlockingStartFileMonitor();
      final harness = await _harness(
        MemoryLocalHistoryStore(),
        fileMonitor: monitor,
      );

      final open = harness.controller.openPath(source);
      await monitor.startStarted.future;
      monitor.releaseStart.complete();
      await open;

      monitor.blockNextStart();
      final create = harness.controller.createMarkdownFile();
      await monitor.startStarted.future;
      harness.container.dispose();
      monitor.releaseStart.complete();

      await expectLater(create, completes);
    },
  );

  test('disposed file monitor cannot resume an overtaken start', () async {
    final monitor = _DisposeDuringStartFileMonitor();
    final start = monitor.start(
      rootPath: root.path,
      openFilePaths: const <String>[],
    );
    await monitor.firstStopStarted.future;

    await monitor.dispose();
    monitor.releaseFirstStop.complete();
    await start;

    expect(monitor.isRunning, isFalse);
  });

  test('deferred monitor move cannot enter a replacement workspace', () async {
    final operationPath = p.join(root.path, 'operation.md');
    final source = p.join(root.path, 'deferred-source.md');
    final destination = p.join(root.path, 'deferred-destination.md');
    const contents = 'replacement bytes match the deferred source\n';
    await File(operationPath).writeAsString('workspace operation\n');
    await File(source).writeAsString(contents);
    final store = MemoryLocalHistoryStore();
    final service = _BlockAfterRenameWorkspaceService();
    final monitor = _ControlledFileMonitor();
    final harness = await _harness(
      store,
      service: service,
      fileMonitor: monitor,
    );
    await harness.controller.openPath(root.path);
    expect(await harness.controller.openActiveFile(source), isTrue);
    final history = harness.container.read(
      localHistoryControllerProvider.notifier,
    );
    expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
    final originalHistoryId = history.documentIdForBuffer(
      harness.state.activeBuffer!.id,
    )!;

    final workspaceRename = harness.controller.renameWorkspaceEntity(
      operationPath,
      'operation-renamed.md',
    );
    await service.renamed.future;
    await File(source).rename(destination);
    monitor.emitMove(source, destination);
    await Future<void>.delayed(Duration.zero);
    await File(source).writeAsString(contents);
    await harness.controller.openPath(source);
    final replacement = harness.state.activeBuffer!;

    service.release.complete();
    expect(await workspaceRename, isFalse);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(harness.state.activeBuffer, same(replacement));
    expect(harness.state.activeBuffer?.filePath, source);
    expect(harness.state.activeBuffer?.text, contents);
    expect(
      harness.state.documentBuffers.where(
        (buffer) => buffer.filePath == destination,
      ),
      isEmpty,
    );
    final snapshot = await store.load();
    final original = snapshot.documents.singleWhere(
      (document) => document.id == originalHistoryId,
    );
    expect(original.currentPath, source);
    expect(original.currentPath, isNot(destination));
  });

  test(
    'external move retains reconciliation when another process checkpoints the old identity',
    () async {
      final source = p.join(root.path, 'external-same-id-source.md');
      final destination = p.join(root.path, 'external-same-id-destination.md');
      await File(source).writeAsString('old external identity\n');
      final memory = MemoryLocalHistoryStore();
      final store = _BlockingRemapStore(memory);
      final monitor = _ControlledFileMonitor();
      final harness = await _harness(store, fileMonitor: monitor);
      await harness.controller.openPath(source);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
      final originalId = history.documentIdForBuffer(
        harness.state.activeBuffer!.id,
      )!;
      await File(source).rename(destination);

      monitor.emitMove(source, destination);
      await store.started.future;
      await memory.capture(
        LocalHistoryCaptureRequest(
          documentId: originalId,
          path: source,
          displayName: p.basename(source),
          source: 'replacement checkpoint after move\n',
          format: TextFormatMetadata.utf8Lf.copyWith(hasFinalNewline: true),
          capturedAt: DateTime.utc(2026, 2),
          reason: LocalHistoryCaptureReason.saved,
        ),
        const LocalHistoryPolicy(),
      );
      store.release.complete();
      await _waitFor(
        () => harness.state.activeBuffer?.filePath == destination,
        operation: 'same-identity external move completion',
      );

      final snapshot = await memory.load();
      final original = snapshot.documents.singleWhere(
        (document) => document.id == originalId,
      );
      expect(original.currentPath, source);
      expect(original.deleted, isFalse);
      expect(
        await _revisionSources(memory, snapshot.revisionsFor(originalId)),
        contains('replacement checkpoint after move\n'),
      );
      expect(history.pendingPathReconciliations, hasLength(1));
      expect(await history.flushAll(harness.state.documentBuffers), isFalse);
      expect((await memory.load()).documents.single.currentPath, source);
    },
  );

  test(
    'external move with no bound identity cannot remap replacement history',
    () async {
      final source = p.join(root.path, 'unbound-external-source.md');
      final destination = p.join(root.path, 'unbound-external-target.md');
      await File(source).writeAsString('unbound external source\n');
      final store = MemoryLocalHistoryStore();
      final monitor = _ControlledFileMonitor();
      final harness = await _harness(store, fileMonitor: monitor);
      final settings = harness.container.read(
        appSettingsControllerProvider.notifier,
      );
      await settings.setLocalHistoryRecordingEnabled(false);
      await harness.controller.openPath(source);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(
        history.documentIdForBuffer(harness.state.activeBuffer!.id),
        isNull,
      );
      await File(source).rename(destination);
      final replacement = await _capture(
        store,
        source,
        'independent replacement history\n',
      );

      monitor.emitMove(source, destination);
      await _waitFor(
        () => harness.state.activeBuffer?.filePath == destination,
        operation: 'unbound external move completion',
      );

      final snapshot = await store.load();
      final retained = snapshot.documents.singleWhere(
        (document) => document.id == replacement.document.id,
      );
      expect(retained.currentPath, source);
      expect(retained.deleted, isFalse);
      expect(history.pendingPathReconciliations, isEmpty);
    },
  );

  test(
    'external deletion with no bound identity cannot delete replacement history',
    () async {
      final path = p.join(root.path, 'unbound-external-deletion.md');
      await File(path).writeAsString('unbound deletion source\n');
      final store = MemoryLocalHistoryStore();
      final monitor = _ControlledFileMonitor();
      final harness = await _harness(store, fileMonitor: monitor);
      final settings = harness.container.read(
        appSettingsControllerProvider.notifier,
      );
      await settings.setLocalHistoryRecordingEnabled(false);
      await harness.controller.openPath(path);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(
        history.documentIdForBuffer(harness.state.activeBuffer!.id),
        isNull,
      );
      await File(path).delete();
      final replacement = await _capture(
        store,
        path,
        'independent deletion replacement\n',
      );

      monitor.emitDeletion(path);
      await _waitFor(
        () =>
            harness.state.activeBuffer?.diskState == DocumentDiskState.deleted,
        operation: 'unbound external deletion completion',
      );

      final snapshot = await store.load();
      final retained = snapshot.documents.singleWhere(
        (document) => document.id == replacement.document.id,
      );
      expect(retained.currentPath, path);
      expect(retained.deleted, isFalse);
      expect(history.pendingPathReconciliations, isEmpty);
    },
  );

  test(
    'failed external-delete protection retries into the deleted lineage',
    () async {
      final path = p.join(root.path, 'protected-external-deletion.md');
      await File(path).writeAsString('saved source\n');
      final memory = MemoryLocalHistoryStore();
      final store = _ControllableHistoryStore(memory);
      final monitor = _ControlledFileMonitor();
      final harness = await _harness(store, fileMonitor: monitor);
      await harness.controller.openPath(path);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
      final documentId = history.documentIdForBuffer(
        harness.state.activeBuffer!.id,
      )!;
      harness.controller.updateActiveText('unsaved before deletion\n');
      store.capturesAvailable = false;
      await File(path).delete();

      monitor.emitDeletion(path);
      await _waitFor(
        () =>
            harness.state.activeBuffer?.diskState == DocumentDiskState.deleted,
        operation: 'external deletion after failed protection',
      );
      expect((await memory.load()).documents.single.deleted, isTrue);

      store.capturesAvailable = true;
      expect(await history.flushAll(harness.state.documentBuffers), isTrue);
      final snapshot = await memory.load();
      expect(snapshot.documents, hasLength(1));
      expect(snapshot.documents.single.id, documentId);
      expect(snapshot.documents.single.deleted, isTrue);
      expect(
        await _revisionSources(memory, snapshot.revisionsFor(documentId)),
        contains('unsaved before deletion\n'),
      );
    },
  );

  test(
    'failed external-delete protection survives restart as detached work',
    () async {
      final path = p.join(root.path, 'restart-protected-deletion.md');
      await File(path).writeAsString('saved source\n');
      final memory = MemoryLocalHistoryStore();
      final store = _ControllableHistoryStore(memory);
      final sessions = MemoryDocumentSessionStore();
      final recovery = MemoryDocumentRecoveryStore();
      final monitor = _ControlledFileMonitor();
      final harness = await _harness(
        store,
        sessionStore: sessions,
        recoveryStore: recovery,
        fileMonitor: monitor,
      );
      await harness.controller.openPath(path);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
      final documentId = history.documentIdForBuffer(
        harness.state.activeBuffer!.id,
      )!;
      harness.controller.updateActiveText('dirty recovery before deletion\n');
      await harness.controller.flushPersistence();
      store.capturesAvailable = false;
      await File(path).delete();

      monitor.emitDeletion(path);
      await _waitFor(
        () =>
            harness.state.activeBuffer?.diskState ==
                DocumentDiskState.deleted &&
            sessions.value?.retainedLocalHistoryCaptures.isNotEmpty == true,
        operation: 'committed deletion protection persistence',
      );
      await harness.controller.flushPersistence();
      expect(
        recovery.value.entries.map((entry) => entry.text),
        contains('dirty recovery before deletion\n'),
      );
      harness.container.dispose();

      store.capturesAvailable = true;
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
      final restoredHistory = reopened.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(
        await restoredHistory.flushAll(reopened.state.documentBuffers),
        isTrue,
      );
      final snapshot = await memory.load();
      final original = snapshot.documents.singleWhere(
        (document) => document.id == documentId,
      );
      expect(original.deleted, isTrue);
      expect(
        await _revisionSources(memory, snapshot.revisionsFor(documentId)),
        contains('dirty recovery before deletion\n'),
      );
      expect(
        snapshot.documents.where(
          (document) => !document.deleted && document.currentPath == path,
        ),
        isEmpty,
      );
    },
  );

  test('external directory move remaps nested open history', () async {
    final sourceDirectory = Directory(p.join(root.path, 'folder'));
    final destinationDirectory = p.join(root.path, 'moved');
    await sourceDirectory.create();
    final source = p.join(sourceDirectory.path, 'a.md');
    final destination = p.join(destinationDirectory, 'a.md');
    await File(source).writeAsString('nested move\n');
    final store = MemoryLocalHistoryStore();
    final monitor = _ControlledFileMonitor();
    final harness = await _harness(store, fileMonitor: monitor);
    await harness.controller.openPath(source);
    final history = harness.container.read(
      localHistoryControllerProvider.notifier,
    );
    expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
    final documentId = history.documentIdForBuffer(
      harness.state.activeBuffer!.id,
    )!;
    harness.controller.updateActiveText('dirty nested move\n');
    await sourceDirectory.rename(destinationDirectory);

    monitor.emitMove(
      sourceDirectory.path,
      destinationDirectory,
      isDirectory: true,
    );
    await _waitFor(
      () => harness.state.activeBuffer?.filePath == destination,
      operation: 'external directory move completion',
    );

    final snapshot = await store.load();
    expect(
      snapshot.documents
          .singleWhere((document) => document.id == documentId)
          .currentPath,
      destination,
    );
    expect(
      await _revisionSources(store, snapshot.revisionsFor(documentId)),
      contains('dirty nested move\n'),
    );
    expect(history.pendingPathReconciliations, isEmpty);
  });

  test(
    'external directory move publishes every buffer after one decode failure',
    () async {
      final sourceDirectory = Directory(p.join(root.path, 'partial-folder'));
      final destinationDirectory = p.join(root.path, 'partial-moved');
      await sourceDirectory.create();
      final firstSource = p.join(sourceDirectory.path, 'one.md');
      final secondSource = p.join(sourceDirectory.path, 'two.md');
      final firstDestination = p.join(destinationDirectory, 'one.md');
      final secondDestination = p.join(destinationDirectory, 'two.md');
      await File(firstSource).writeAsString('first source\n');
      await File(secondSource).writeAsString('second source\n');
      final store = MemoryLocalHistoryStore();
      final monitor = _ControlledFileMonitor();
      final service = _FailOncePathLoadWorkspaceService(secondDestination);
      final harness = await _harness(
        store,
        service: service,
        fileMonitor: monitor,
      );
      await harness.controller.openPath(root.path);
      expect(await harness.controller.openActiveFile(firstSource), isTrue);
      expect(await harness.controller.openActiveFile(secondSource), isTrue);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(await history.flushAll(harness.state.documentBuffers), isTrue);
      final secondBuffer = harness.state.documentBuffers.singleWhere(
        (buffer) => buffer.filePath == secondSource,
      );
      final secondDocumentId = history.documentIdForBuffer(secondBuffer.id)!;
      await sourceDirectory.rename(destinationDirectory);

      monitor.emitMove(
        sourceDirectory.path,
        destinationDirectory,
        isDirectory: true,
      );
      await _waitFor(
        () =>
            harness.state.documentBuffers.any(
              (buffer) => buffer.filePath == firstDestination,
            ) &&
            harness.state.documentBuffers.any(
              (buffer) => buffer.filePath == secondDestination,
            ),
        operation: 'partial external directory move publication',
      );
      expect(history.pendingPathReconciliations, isEmpty);
      final movedSecond = harness.state.documentBuffers.singleWhere(
        (buffer) => buffer.filePath == secondDestination,
      );
      expect(service.failedLoads, 1);
      expect(
        await harness.controller.activateDocumentBuffer(movedSecond.id),
        isTrue,
      );
      harness.controller.updateActiveText('edited after partial move\n');
      expect(await history.flushAll(harness.state.documentBuffers), isTrue);

      final snapshot = await store.load();
      final secondDocument = snapshot.documents.singleWhere(
        (document) => document.id == secondDocumentId,
      );
      expect(secondDocument.currentPath, secondDestination);
      expect(
        await _revisionSources(store, snapshot.revisionsFor(secondDocumentId)),
        contains('edited after partial move\n'),
      );
    },
  );

  test(
    'closing a tab during an external directory move settles its journal',
    () async {
      final sourceDirectory = Directory(p.join(root.path, 'closing-folder'));
      final destinationDirectory = p.join(root.path, 'closing-moved');
      await sourceDirectory.create();
      final firstSource = p.join(sourceDirectory.path, 'one.md');
      final secondSource = p.join(sourceDirectory.path, 'two.md');
      final secondDestination = p.join(destinationDirectory, 'two.md');
      await File(firstSource).writeAsString('first source\n');
      await File(secondSource).writeAsString('second source\n');
      final store = MemoryLocalHistoryStore();
      final monitor = _ControlledFileMonitor();
      final service = _BlockingTargetLoadWorkspaceService(secondDestination);
      final harness = await _harness(
        store,
        service: service,
        fileMonitor: monitor,
      );
      await harness.controller.openPath(root.path);
      expect(await harness.controller.openActiveFile(firstSource), isTrue);
      expect(await harness.controller.openActiveFile(secondSource), isTrue);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(await history.flushAll(harness.state.documentBuffers), isTrue);
      final closing = harness.state.documentBuffers.singleWhere(
        (buffer) => buffer.filePath == secondSource,
      );
      await sourceDirectory.rename(destinationDirectory);

      monitor.emitMove(
        sourceDirectory.path,
        destinationDirectory,
        isDirectory: true,
      );
      await service.started.future;
      final close = harness.controller.closeDocumentBuffer(closing.id);
      await _waitFor(
        () => harness.state.documentBuffers.every(
          (buffer) => buffer.id != closing.id,
        ),
        operation: 'close tab during directory move',
      );
      service.release.complete();
      expect(await close, isTrue);
      await _waitFor(
        () => history.pendingPathReconciliations.isEmpty,
        operation: 'directory move acknowledgement after tab close',
      );
      expect(await history.flushAll(harness.state.documentBuffers), isTrue);
      final snapshot = await store.load();
      expect(
        snapshot.documents
            .singleWhere(
              (document) => document.historicalPaths.contains(secondSource),
            )
            .currentPath,
        secondDestination,
      );
    },
  );

  test(
    'external directory deletion marks nested open history deleted',
    () async {
      final directory = Directory(p.join(root.path, 'deleted-folder'));
      await directory.create();
      final path = p.join(directory.path, 'a.md');
      await File(path).writeAsString('nested deletion\n');
      final store = MemoryLocalHistoryStore();
      final monitor = _ControlledFileMonitor();
      final harness = await _harness(store, fileMonitor: monitor);
      await harness.controller.openPath(path);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
      final documentId = history.documentIdForBuffer(
        harness.state.activeBuffer!.id,
      )!;
      harness.controller.updateActiveText('dirty nested deletion\n');
      await directory.delete(recursive: true);

      monitor.emitDeletion(directory.path, isDirectory: true);
      await _waitFor(
        () =>
            harness.state.activeBuffer?.diskState == DocumentDiskState.deleted,
        operation: 'external directory deletion completion',
      );

      final snapshot = await store.load();
      expect(
        snapshot.documents
            .singleWhere((document) => document.id == documentId)
            .deleted,
        isTrue,
      );
      expect(
        await _revisionSources(store, snapshot.revisionsFor(documentId)),
        contains('dirty nested deletion\n'),
      );
      expect(history.pendingPathReconciliations, isEmpty);
    },
  );

  test(
    'failed recursive-delete protection survives restart on its lineage',
    () async {
      final directory = Directory(p.join(root.path, 'restart-deleted-folder'));
      await directory.create();
      final path = p.join(directory.path, 'a.md');
      await File(path).writeAsString('saved nested source\n');
      final memory = MemoryLocalHistoryStore();
      final store = _ControllableHistoryStore(memory);
      final sessions = MemoryDocumentSessionStore();
      final recovery = MemoryDocumentRecoveryStore();
      final monitor = _ControlledFileMonitor();
      final harness = await _harness(
        store,
        sessionStore: sessions,
        recoveryStore: recovery,
        fileMonitor: monitor,
      );
      await harness.controller.openPath(path);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
      final documentId = history.documentIdForBuffer(
        harness.state.activeBuffer!.id,
      )!;
      harness.controller.updateActiveText('dirty nested recovery\n');
      await harness.controller.flushPersistence();
      store.capturesAvailable = false;
      await directory.delete(recursive: true);

      monitor.emitDeletion(directory.path, isDirectory: true);
      await _waitFor(
        () =>
            harness.state.activeBuffer?.diskState ==
                DocumentDiskState.deleted &&
            sessions.value?.retainedLocalHistoryCaptures.isNotEmpty == true,
        operation: 'recursive deletion protection persistence',
      );
      await harness.controller.flushPersistence();
      harness.container.dispose();

      store.capturesAvailable = true;
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
      final restoredHistory = reopened.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(
        await restoredHistory.flushAll(reopened.state.documentBuffers),
        isTrue,
      );
      final snapshot = await memory.load();
      final original = snapshot.documents.singleWhere(
        (document) => document.id == documentId,
      );
      expect(original.deleted, isTrue);
      expect(
        await _revisionSources(memory, snapshot.revisionsFor(documentId)),
        contains('dirty nested recovery\n'),
      );
      expect(
        snapshot.documents.where(
          (document) => !document.deleted && document.currentPath == path,
        ),
        isEmpty,
      );
    },
  );

  for (final delete in [false, true]) {
    test(
      'external ${delete ? "deletion" : "move"} reconciles closed file history',
      () async {
        final source = p.join(root.path, 'closed-source.md');
        final destination = p.join(root.path, 'closed-destination.md');
        final other = p.join(root.path, 'still-open.md');
        await File(source).writeAsString('closed lineage\n');
        await File(other).writeAsString('open lineage\n');
        final store = MemoryLocalHistoryStore();
        final monitor = _ControlledFileMonitor();
        final harness = await _harness(store, fileMonitor: monitor);
        await harness.controller.openPath(root.path);
        expect(await harness.controller.openActiveFile(source), isTrue);
        final history = harness.container.read(
          localHistoryControllerProvider.notifier,
        );
        expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
        final sourceId = history.documentIdForBuffer(
          harness.state.activeBuffer!.id,
        )!;
        expect(await harness.controller.openActiveFile(other), isTrue);
        final sourceBuffer = harness.state.documentBuffers.singleWhere(
          (buffer) => buffer.filePath == source,
        );
        expect(
          await harness.controller.closeDocumentBuffer(sourceBuffer.id),
          isTrue,
        );

        if (delete) {
          await File(source).delete();
          monitor.emitDeletion(source);
        } else {
          await File(source).rename(destination);
          monitor.emitMove(source, destination);
        }
        await _waitFor(() {
          final document = harness.container
              .read(localHistoryControllerProvider)
              .snapshot
              .documents
              .where((candidate) => candidate.id == sourceId)
              .firstOrNull;
          return document != null &&
              (delete ? document.deleted : document.currentPath == destination);
        }, operation: 'closed file history reconciliation');

        final snapshot = await store.load();
        final document = snapshot.documents.singleWhere(
          (candidate) => candidate.id == sourceId,
        );
        expect(document.deleted, delete);
        expect(document.currentPath, delete ? source : destination);
        expect(history.pendingPathReconciliations, isEmpty);
      },
    );
  }

  test(
    'external chained moves coalesce before history reconciliation',
    () async {
      final source = p.join(root.path, 'chain-a.md');
      final middle = p.join(root.path, 'chain-b.md');
      final destination = p.join(root.path, 'chain-c.md');
      await File(source).writeAsString('chained lineage\n');
      final store = MemoryLocalHistoryStore();
      final monitor = _ControlledFileMonitor();
      final harness = await _harness(store, fileMonitor: monitor);
      await harness.controller.openPath(source);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
      final documentId = history.documentIdForBuffer(
        harness.state.activeBuffer!.id,
      )!;

      await File(source).rename(middle);
      await File(middle).rename(destination);
      monitor.emitMove(source, middle);
      monitor.emitMove(middle, destination);
      await _waitFor(
        () => harness.state.activeBuffer?.filePath == destination,
        operation: 'chained external move completion',
      );

      final snapshot = await store.load();
      expect(
        snapshot.documents
            .singleWhere((document) => document.id == documentId)
            .currentPath,
        destination,
      );
      expect(history.pendingPathReconciliations, isEmpty);
    },
  );

  test(
    'external chained moves coalesce across an unrelated queued event',
    () async {
      final source = p.join(root.path, 'interleaved-chain-a.md');
      final middle = p.join(root.path, 'interleaved-chain-b.md');
      final destination = p.join(root.path, 'interleaved-chain-c.md');
      final unrelated = p.join(root.path, 'interleaved-unrelated.md');
      await File(source).writeAsString('interleaved chained lineage\n');
      await File(unrelated).writeAsString('unrelated\n');
      final store = MemoryLocalHistoryStore();
      final monitor = _ControlledFileMonitor();
      final harness = await _harness(store, fileMonitor: monitor);
      await harness.controller.openPath(source);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
      final documentId = history.documentIdForBuffer(
        harness.state.activeBuffer!.id,
      )!;

      await File(source).rename(middle);
      await File(middle).rename(destination);
      await File(unrelated).delete();
      monitor.emitMove(source, middle);
      monitor.emitDeletion(unrelated);
      monitor.emitMove(middle, destination);
      await _waitFor(
        () => harness.state.activeBuffer?.filePath == destination,
        operation: 'interleaved chained external move completion',
      );

      final snapshot = await store.load();
      final original = snapshot.documents.singleWhere(
        (document) => document.id == documentId,
      );
      expect(original.currentPath, destination);
      expect(original.deleted, isFalse);
      expect(harness.state.activeBuffer?.diskState, DocumentDiskState.present);
      expect(history.pendingPathReconciliations, isEmpty);
    },
  );

  test('closed source move cannot steal an open destination lineage', () async {
    final source = p.join(root.path, 'closed-a.md');
    final destination = p.join(root.path, 'open-b.md');
    await File(source).writeAsString('source contents\n');
    await File(destination).writeAsString('destination contents\n');
    final store = MemoryLocalHistoryStore();
    final monitor = _ControlledFileMonitor();
    final harness = await _harness(store, fileMonitor: monitor);
    await harness.controller.openPath(root.path);
    expect(await harness.controller.openActiveFile(source), isTrue);
    final history = harness.container.read(
      localHistoryControllerProvider.notifier,
    );
    expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
    final sourceId = history.documentIdForBuffer(
      harness.state.activeBuffer!.id,
    )!;
    expect(await harness.controller.openActiveFile(destination), isTrue);
    expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
    final destinationId = history.documentIdForBuffer(
      harness.state.activeBuffer!.id,
    )!;
    final sourceBuffer = harness.state.documentBuffers.singleWhere(
      (buffer) => buffer.filePath == source,
    );
    expect(
      await harness.controller.closeDocumentBuffer(sourceBuffer.id),
      isTrue,
    );

    await File(source).rename(destination);
    monitor.emitMove(source, destination);
    await _waitFor(
      () => history.pendingPathReconciliations.isNotEmpty,
      operation: 'identity conflict for closed source move',
    );

    final snapshot = await store.load();
    expect(
      snapshot.documents
          .singleWhere((document) => document.id == sourceId)
          .currentPath,
      source,
    );
    expect(
      snapshot.documents
          .singleWhere((document) => document.id == destinationId)
          .currentPath,
      destination,
    );
    expect(
      history.pendingPathReconciliations.single.documentIds,
      contains(sourceId),
    );
  });

  test(
    'external file move includes identity established by source settlement',
    () async {
      final source = p.join(root.path, 'unbound-file.md');
      final destination = p.join(root.path, 'settled-file.md');
      await File(source).writeAsString('baseline unavailable\n');
      final store = _UnavailableCaptureStore();
      final monitor = _ControlledFileMonitor();
      final harness = await _harness(store, fileMonitor: monitor);
      await harness.controller.openPath(source);
      harness.controller.updateActiveText('file checkpoint creates identity\n');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(
        history.documentIdForBuffer(harness.state.activeBuffer!.id),
        isNull,
      );
      store.available = true;
      await File(source).rename(destination);

      monitor.emitMove(source, destination);
      await _waitFor(
        () => harness.state.activeBuffer?.filePath == destination,
        operation: 'settled file identity move',
      );

      final snapshot = await store.load();
      expect(snapshot.documents, hasLength(1));
      expect(snapshot.documents.single.currentPath, destination);
      expect(
        await _revisionSources(store, snapshot.revisions),
        contains('file checkpoint creates identity\n'),
      );
      expect(history.pendingPathReconciliations, isEmpty);
    },
  );

  test(
    'external directory move includes identity established by source settlement',
    () async {
      final sourceDirectory = Directory(p.join(root.path, 'unbound-folder'));
      final destinationDirectory = p.join(root.path, 'settled-folder');
      await sourceDirectory.create();
      final source = p.join(sourceDirectory.path, 'a.md');
      final destination = p.join(destinationDirectory, 'a.md');
      await File(source).writeAsString('baseline unavailable\n');
      final store = _UnavailableCaptureStore();
      final monitor = _ControlledFileMonitor();
      final harness = await _harness(store, fileMonitor: monitor);
      await harness.controller.openPath(source);
      harness.controller.updateActiveText('checkpoint creates identity\n');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(
        history.documentIdForBuffer(harness.state.activeBuffer!.id),
        isNull,
      );
      store.available = true;
      await sourceDirectory.rename(destinationDirectory);

      monitor.emitMove(
        sourceDirectory.path,
        destinationDirectory,
        isDirectory: true,
      );
      await _waitFor(
        () => harness.state.activeBuffer?.filePath == destination,
        operation: 'settled directory identity move',
      );

      final snapshot = await store.load();
      expect(snapshot.documents, hasLength(1));
      expect(snapshot.documents.single.currentPath, destination);
      expect(
        await _revisionSources(store, snapshot.revisions),
        contains('checkpoint creates identity\n'),
      );
      expect(history.pendingPathReconciliations, isEmpty);
    },
  );

  test(
    'cancelled named Save As detaches source history and reopens separately',
    () async {
      final sourcePath = p.join(root.path, 'A.md');
      final destinationPath = p.join(root.path, 'B.md');
      await File(sourcePath).writeAsString('Original A\n');
      final historyRoot = Directory(p.join(root.path, 'history'));
      final diskStore = FileLocalHistoryStore(
        rootDirectory: () async => historyRoot,
      );
      final store = _BlockingSaveAsStore(diskStore, destinationPath);
      final timers = <_FakeTimer>[];
      final harness = await _harness(
        store,
        timerFactory: (delay, callback) {
          final timer = _FakeTimer(delay, callback);
          timers.add(timer);
          return timer;
        },
      );
      final settings = harness.container.read(
        appSettingsControllerProvider.notifier,
      );
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      await harness.controller.openPath(sourcePath);
      final sourceId = (await diskStore.load()).documents.single.id;
      harness.controller.updateActiveText('Save As B\n');
      final save = harness.controller.saveActiveAs(destinationPath);
      await store.started.future;
      expect(harness.state.activeBuffer!.filePath, destinationPath);
      await settings.setLocalHistoryRecordingEnabled(false);
      store.release.complete();
      expect(await save, isTrue);
      expect(
        history.documentIdForBuffer(harness.state.activeBuffer!.id),
        isNot(sourceId),
      );
      expect(await File(sourcePath).readAsString(), 'Original A\n');
      expect(await File(destinationPath).readAsString(), 'Save As B\n');

      await settings.setLocalHistoryRecordingEnabled(true);
      harness.controller.updateActiveText('Only B after cancellation\n');
      await _waitFor(
        () => timers.any((timer) => timer.isActive),
        operation: 'Save As checkpoint timer',
      );
      for (final timer in List<_FakeTimer>.of(timers)) {
        timer.fire();
      }
      await _waitFor(
        () => harness.container
            .read(localHistoryControllerProvider)
            .snapshot
            .revisions
            .any(
              (revision) =>
                  revision.reason ==
                      LocalHistoryCaptureReason.automaticCheckpoint &&
                  revision.historicalPath == destinationPath,
            ),
        timeout: const Duration(seconds: 10),
        operation: 'Save As automatic checkpoint',
        diagnostics: () {
          final snapshot = harness.container
              .read(localHistoryControllerProvider)
              .snapshot;
          return 'active=${harness.state.activeBuffer?.filePath}, '
              'revision count=${snapshot.revisions.length}, '
              'active timers=${timers.where((timer) => timer.isActive).length}';
        },
      );
      final snapshot = await diskStore.load();
      final destination = snapshot.documents.singleWhere(
        (document) => document.currentPath == destinationPath,
      );
      expect(destination.id, isNot(sourceId));
      expect(
        await _revisionSources(diskStore, snapshot.revisionsFor(sourceId)),
        isNot(contains('Only B after cancellation\n')),
      );
      expect(
        await _revisionSources(
          diskStore,
          snapshot.revisionsFor(destination.id),
        ),
        contains('Only B after cancellation\n'),
      );
      expect(
        history.documentIdForBuffer(harness.state.activeBuffer!.id),
        destination.id,
      );

      final reopenedStore = FileLocalHistoryStore(
        rootDirectory: () async => historyRoot,
      );
      final reopened = await _harness(reopenedStore);
      final reopenedHistory = reopened.container.read(
        localHistoryControllerProvider.notifier,
      );
      await reopened.controller.openPath(sourcePath);
      await _waitFor(
        () =>
            reopenedHistory.documentIdForBuffer(
              reopened.state.activeBuffer!.id,
            ) !=
            null,
      );
      expect(
        reopenedHistory.documentIdForBuffer(reopened.state.activeBuffer!.id),
        sourceId,
      );
      expect(await reopened.controller.openActiveFile(destinationPath), isTrue);
      await _waitFor(
        () =>
            reopenedHistory.documentIdForBuffer(
              reopened.state.activeBuffer!.id,
            ) !=
            null,
      );
      expect(
        reopenedHistory.documentIdForBuffer(reopened.state.activeBuffer!.id),
        destination.id,
      );
    },
  );

  test(
    'recording disabled after first-save publication preserves untitled lineage',
    () async {
      final destination = p.join(root.path, 'first-save-policy-race.md');
      final store = MemoryLocalHistoryStore();
      final service = _BlockingFirstSaveOpenWorkspaceService(destination);
      final harness = await _harness(store, service: service);
      final settings = harness.container.read(
        appSettingsControllerProvider.notifier,
      );
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      await harness.controller.createMarkdownFile();
      harness.controller.updateActiveText('Established untitled lineage\n');
      expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
      final documentId = history.documentIdForBuffer(
        harness.state.activeBuffer!.id,
      );
      expect(documentId, isNotNull);

      final save = harness.controller.saveActiveAs(destination);
      await service.openStarted.future;
      await settings.setLocalHistoryRecordingEnabled(false);
      service.release.complete();
      expect(await save, isTrue);
      expect(
        history.documentIdForBuffer(harness.state.activeBuffer!.id),
        documentId,
      );
      expect(history.pendingIdentityPromotions, hasLength(1));

      await settings.setLocalHistoryRecordingEnabled(true);
      expect(await history.flushPendingIdentityPromotions(), isTrue);
      final snapshot = await store.load();
      expect(snapshot.documents, hasLength(1));
      expect(snapshot.documents.single.id, documentId);
      expect(snapshot.documents.single.currentPath, destination);
    },
  );

  for (final cancellation in ['disable', 'clear document', 'clear all']) {
    for (final failCapture in [false, true]) {
      test('first-save pre-promotion cancellation: $cancellation, '
          '${failCapture ? "failed" : "completed"} pending capture', () async {
        final historyRoot = Directory(p.join(root.path, 'history'));
        final diskStore = FileLocalHistoryStore(
          rootDirectory: () async => historyRoot,
        );
        final store = _BlockingPrePromotionCaptureStore(
          diskStore,
          failCapture: failCapture,
        );
        var now = DateTime.utc(2026, 1, 1);
        final timers = <_FakeTimer>[];
        final sessions = MemoryDocumentSessionStore();
        final harness = await _harness(
          store,
          sessionStore: sessions,
          clock: () => now,
          timerFactory: (delay, callback) {
            final timer = _FakeTimer(delay, callback);
            timers.add(timer);
            return timer;
          },
        );
        final history = harness.container.read(
          localHistoryControllerProvider.notifier,
        );
        final settings = harness.container.read(
          appSettingsControllerProvider.notifier,
        );
        await harness.controller.createMarkdownFile();
        final bufferId = harness.state.activeBuffer!.id;

        // Establish history through an editor mutation and its real-policy
        // checkpoint, without manually observing or storing the edit.
        harness.controller.updateActiveText('Original retained draft\n');
        await _waitFor(
          () => timers.any((timer) => timer.isActive),
          operation: 'first-save checkpoint timer',
        );
        final firstTimer = timers.singleWhere((timer) => timer.isActive);
        expect(firstTimer.duration, const Duration(seconds: 60));
        now = now.add(firstTimer.duration);
        firstTimer.fire();
        await _waitFor(
          () =>
              history.documentIdForBuffer(bufferId) != null &&
              history.pendingSnapshotForBuffer(bufferId) == null,
          timeout: const Duration(seconds: 10),
          operation: 'first-save disk checkpoint',
          diagnostics: () =>
              'document id=${history.documentIdForBuffer(bufferId)}, '
              'pending snapshot=${history.pendingSnapshotForBuffer(bufferId) != null}',
        );
        final original = (await diskStore.load()).documents.single;
        final originalRevisionIds = (await diskStore.load()).revisions
            .map((revision) => revision.id)
            .toSet();
        expect(original.currentPath, isNull);

        harness.controller.updateActiveText('Pending at first save\n');
        await _waitFor(
          () =>
              history.pendingSnapshotForBuffer(bufferId)?.text ==
              'Pending at first save\n',
        );
        store.blockNextUntitledCheckpoint = true;
        final destination = p.join(root.path, 'Guide.md');
        final save = harness.controller.saveActiveAs(destination);
        final blocked = await store.started.future;
        expect(harness.state.activeBuffer!.filePath, destination);
        expect(
          await File(destination).readAsString(),
          'Pending at first save\n',
        );
        expect(blocked.path, isNull);
        expect(blocked.documentId, original.id);
        expect(blocked.source, 'Pending at first save\n');
        expect(blocked.reason, LocalHistoryCaptureReason.automaticCheckpoint);
        expect(history.pendingIdentityPromotions, isEmpty);
        expect(store.promotionAttempts, 0);

        Future<void>? clear;
        if (cancellation == 'disable') {
          await settings.setLocalHistoryRecordingEnabled(false);
        } else {
          clear = cancellation == 'clear all'
              ? history.clearAll()
              : history.clearDocument(original.id);
        }
        store.release.complete();
        expect(await save, isTrue);
        if (clear != null) await clear;
        expect(harness.state.activeBuffer!.isDirty, isFalse);
        expect(harness.state.activeText, 'Pending at first save\n');
        expect(history.pendingSnapshotForBuffer(bufferId), isNull);
        expect(timers.where((timer) => timer.isActive), isEmpty);
        await harness.controller.flushPersistence();

        if (cancellation == 'disable') {
          expect(history.documentIdForBuffer(bufferId), original.id);
          expect(history.pendingIdentityPromotions, hasLength(1));
          final promotion = history.pendingIdentityPromotions.single;
          expect(promotion.bufferId, bufferId);
          expect(promotion.documentId, original.id);
          expect(promotion.destinationPath, destination);
          expect(
            sessions.value!.pendingLocalHistoryAssociations.single.documentId,
            original.id,
          );
          final retained = await diskStore.load();
          expect(retained.documents.single.id, original.id);
          expect(retained.documents.single.currentPath, isNull);
          expect(
            retained.revisions.map((revision) => revision.id),
            containsAll(originalRevisionIds),
          );
          await settings.setLocalHistoryRecordingEnabled(true);
        } else {
          expect(history.documentIdForBuffer(bufferId), isNull);
          expect(history.pendingIdentityPromotions, isEmpty);
          expect(sessions.value!.pendingLocalHistoryAssociations, isEmpty);
          now = now.add(const Duration(seconds: 60));
          for (final timer in List<_FakeTimer>.of(timers)) {
            timer.fire();
          }
          final cleared = await diskStore.load();
          expect(cleared.documents, isEmpty);
          expect(cleared.revisions, isEmpty);
        }

        // Only a new editor mutation and checkpoint may resume recording.
        harness.controller.updateActiveText(
          'Named checkpoint after cancellation\n',
        );
        await _waitFor(() => timers.any((timer) => timer.isActive));
        final namedTimer = timers.singleWhere((timer) => timer.isActive);
        expect(namedTimer.duration, const Duration(seconds: 60));
        now = now.add(namedTimer.duration);
        namedTimer.fire();
        await _waitFor(
          () => history.pendingSnapshotForBuffer(bufferId) == null,
        );
        final captured = await diskStore.load();
        final document = captured.documents.single;
        expect(document.currentPath, destination);
        expect(document.untitled, isFalse);
        expect(history.documentIdForBuffer(bufferId), document.id);
        expect(history.pendingIdentityPromotions, isEmpty);
        final sources = await _revisionSources(diskStore, captured.revisions);
        expect(sources, contains('Named checkpoint after cancellation\n'));
        if (cancellation == 'disable') {
          expect(document.id, original.id);
          expect(store.promotionAttempts, 1);
          expect(
            captured.revisions.map((revision) => revision.id),
            containsAll(originalRevisionIds),
          );
          expect(sources, contains('Original retained draft\n'));
        } else {
          expect(document.id, isNot(original.id));
          expect(store.promotionAttempts, 0);
          expect(sources, isNot(contains('Original retained draft\n')));
        }
        expect(
          captured.revisions.every(
            (revision) => revision.documentId == document.id,
          ),
          isTrue,
        );
        expect(
          harness.container
              .read(localHistoryControllerProvider)
              .snapshot
              .documents
              .single
              .currentPath,
          destination,
        );

        final reopenedStore = FileLocalHistoryStore(
          rootDirectory: () async => historyRoot,
        );
        final reopened = await _harness(reopenedStore, clock: () => now);
        final reopenedHistory = reopened.container.read(
          localHistoryControllerProvider.notifier,
        );
        await reopened.controller.openPath(destination);
        await _waitFor(
          () =>
              reopenedHistory.documentIdForBuffer(
                reopened.state.activeBuffer!.id,
              ) !=
              null,
        );
        expect(
          reopenedHistory.documentIdForBuffer(reopened.state.activeBuffer!.id),
          document.id,
        );
        final reopenedSnapshot = await reopenedStore.load();
        expect(reopenedSnapshot.documents.single.id, document.id);
        expect(
          reopenedSnapshot.revisions.map((revision) => revision.id),
          containsAll(captured.revisions.map((revision) => revision.id)),
        );
      });
    }
  }

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
    'Save As cannot claim a dirty open buffer at a missing destination',
    () async {
      final sourcePath = p.join(root.path, 'save-as-source.md');
      final destinationPath = p.join(root.path, 'missing-open-destination.md');
      await File(sourcePath).writeAsString('source file\n');
      await File(destinationPath).writeAsString('destination file\n');
      final memory = MemoryLocalHistoryStore();
      final store = _ControllableHistoryStore(memory);
      final sessions = MemoryDocumentSessionStore();
      final recovery = MemoryDocumentRecoveryStore();
      final monitor = _ControlledFileMonitor();
      final harness = await _harness(
        store,
        sessionStore: sessions,
        recoveryStore: recovery,
        fileMonitor: monitor,
      );
      await harness.controller.openPath(root.path);
      expect(await harness.controller.openActiveFile(sourcePath), isTrue);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
      final sourceId = history.documentIdForBuffer(
        harness.state.activeBuffer!.id,
      )!;
      expect(await harness.controller.openActiveFile(destinationPath), isTrue);
      expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
      final destinationBufferId = harness.state.activeBuffer!.id;
      final destinationId = history.documentIdForBuffer(destinationBufferId)!;
      await File(destinationPath).delete();
      monitor.emitDeletion(destinationPath);
      await _waitFor(
        () =>
            harness.state.activeBuffer?.diskState == DocumentDiskState.deleted,
        operation: 'open destination deletion',
      );
      store.capturesAvailable = false;
      harness.controller.updateActiveText('unsaved missing destination\n');
      await harness.controller.flushPersistence();
      expect(await harness.controller.openActiveFile(sourcePath), isTrue);

      expect(
        await harness.controller.saveActiveAs(
          destinationPath,
          overwriteExisting: false,
        ),
        isFalse,
      );
      expect(harness.state.activeBuffer?.filePath, sourcePath);
      expect(await File(destinationPath).exists(), isFalse);
      final destinationBuffer = harness.state.documentBuffers.singleWhere(
        (buffer) => buffer.id == destinationBufferId,
      );
      expect(destinationBuffer.text, 'unsaved missing destination\n');
      expect(destinationBuffer.isDirty, isTrue);
      expect(
        recovery.value.entries.map((entry) => entry.text),
        contains('unsaved missing destination\n'),
      );
      expect(history.pendingPathReconciliations, isEmpty);
      expect(history.documentIdForBuffer(destinationBufferId), destinationId);
      expect(
        history.documentIdForBuffer(harness.state.activeBuffer!.id),
        sourceId,
      );
    },
  );

  for (final destinationExisted in [false, true]) {
    test('rejected Discard protection remains with the Save As source '
        '(existing=$destinationExisted)', () async {
      final sourcePath = p.join(root.path, 'A.md');
      final destinationPath = p.join(root.path, 'B.md');
      await File(sourcePath).writeAsString('Original A\n');
      if (destinationExisted) {
        await File(destinationPath).writeAsString('Original B\n');
      }
      final historyRoot = Directory(p.join(root.path, 'history'));
      final diskStore = FileLocalHistoryStore(
        rootDirectory: () async => historyRoot,
      );
      if (destinationExisted) {
        await _capture(diskStore, destinationPath, 'Original B history\n');
      }
      final store = _ControllableHistoryStore(diskStore)
        ..failBeforeDiscardPath = sourcePath;
      final harness = await _harness(store);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      await harness.controller.openPath(sourcePath);
      final sourceId = (await diskStore.load()).documents
          .singleWhere((document) => document.currentPath == sourcePath)
          .id;

      harness.controller.updateActiveText('Source-only protected text\n');
      expect(await harness.controller.discardActiveChanges(), isFalse);
      expect(harness.state.activeText, 'Source-only protected text\n');
      harness.controller.updateActiveText('Fork point text\n');
      expect(
        await harness.controller.saveActiveAs(
          destinationPath,
          overwriteExisting: destinationExisted,
        ),
        isTrue,
      );
      expect(harness.state.activeBuffer!.filePath, destinationPath);

      store.failBeforeDiscardPath = null;
      expect(await history.flushAll(harness.state.documentBuffers), isTrue);
      harness.controller.updateActiveText('Destination-only text\n');
      expect(await harness.controller.saveActive(), isTrue);
      expect(harness.state.activeBuffer!.filePath, destinationPath);

      final reopenedStore = FileLocalHistoryStore(
        rootDirectory: () async => historyRoot,
      );
      final snapshot = await reopenedStore.load();
      final source = snapshot.documents.singleWhere(
        (document) => document.currentPath == sourcePath,
      );
      final destination = snapshot.documents.singleWhere(
        (document) => document.currentPath == destinationPath,
      );
      expect(source.id, sourceId);
      expect(destination.id, isNot(sourceId));
      expect(
        await _revisionSources(reopenedStore, snapshot.revisionsFor(source.id)),
        contains('Source-only protected text\n'),
      );
      expect(
        await _revisionSources(
          reopenedStore,
          snapshot.revisionsFor(destination.id),
        ),
        allOf(
          containsAll(['Fork point text\n', 'Destination-only text\n']),
          isNot(contains('Source-only protected text\n')),
        ),
      );
      expect(
        history.documentIdForBuffer(harness.state.activeBuffer!.id),
        destination.id,
      );
    });
  }

  test(
    'rename remaps a failed unbound baseline to the committed destination',
    () async {
      final sourcePath = p.join(root.path, 'a.md');
      final destinationPath = p.join(root.path, 'b.md');
      await File(sourcePath).writeAsString('Original unbound baseline\n');
      final historyRoot = Directory(p.join(root.path, 'history'));
      final diskStore = FileLocalHistoryStore(
        rootDirectory: () async => historyRoot,
      );
      final store = _ControllableHistoryStore(diskStore)
        ..capturesAvailable = false;
      final harness = await _harness(store);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      await harness.controller.openPath(sourcePath);
      expect(
        history.documentIdForBuffer(harness.state.activeBuffer!.id),
        isNull,
      );

      expect(
        await harness.controller.renameWorkspaceEntity(sourcePath, 'b.md'),
        isTrue,
      );
      expect(harness.state.activeBuffer!.filePath, destinationPath);
      store.capturesAvailable = true;
      expect(await history.flushAll(harness.state.documentBuffers), isTrue);
      harness.controller.updateActiveText('Saved after rename\n');
      expect(await harness.controller.saveActive(), isTrue);

      final reopenedStore = FileLocalHistoryStore(
        rootDirectory: () async => historyRoot,
      );
      final snapshot = await reopenedStore.load();
      expect(snapshot.documents, hasLength(1));
      expect(snapshot.documents.single.currentPath, destinationPath);
      expect(
        await _revisionSources(
          reopenedStore,
          snapshot.revisionsFor(snapshot.documents.single.id),
        ),
        containsAll(['Original unbound baseline\n', 'Saved after rename\n']),
      );
    },
  );

  test(
    'disposed prepared rename never reaches the filesystem without an execution journal',
    () async {
      final sourcePath = p.join(root.path, 'disposed-rename-a.md');
      final destinationPath = p.join(root.path, 'disposed-rename-b.md');
      await File(sourcePath).writeAsString('rename must remain at A\n');
      final store = MemoryLocalHistoryStore();
      final sessions = _BlockingPreparedPathSessionStore();
      final recovery = MemoryDocumentRecoveryStore();
      final harness = await _harness(
        store,
        sessionStore: sessions,
        recoveryStore: recovery,
      );
      await harness.controller.openPath(sourcePath);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
      final documentId = history.documentIdForBuffer(
        harness.state.activeBuffer!.id,
      )!;
      await harness.controller.flushPersistence();
      sessions.blockNextPreparedPathWrite = true;

      final rename = harness.controller.renameWorkspaceEntity(
        sourcePath,
        p.basename(destinationPath),
      );
      await sessions.preparedWriteStarted.future;
      harness.container.dispose();
      sessions.releasePreparedWrite.complete();

      expect(await rename, isFalse);
      expect(await File(sourcePath).exists(), isTrue);
      expect(await File(destinationPath).exists(), isFalse);
      expect(
        sessions.value?.pendingLocalHistoryReconciliations.single.phase,
        LocalHistoryPathReconciliationPhase.prepared,
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
      final reopenedHistory = reopened.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(
        await reopenedHistory.flushAll(reopened.state.documentBuffers),
        isTrue,
      );
      final fresh = await store.load();
      final original = fresh.documents.singleWhere(
        (document) => document.id == documentId,
      );
      expect(original.currentPath, sourcePath);
      expect(original.deleted, isFalse);
      expect(
        fresh.documents.where(
          (document) => document.currentPath == destinationPath,
        ),
        isEmpty,
      );
      expect(reopened.state.activeBuffer?.filePath, sourcePath);
      expect(reopenedHistory.pendingPathReconciliations, isEmpty);
    },
  );

  test(
    'Clear Document cancels a prepared rename before filesystem publication',
    () async {
      final sourcePath = p.join(root.path, 'cleared-rename-a.md');
      final destinationPath = p.join(root.path, 'cleared-rename-b.md');
      await File(sourcePath).writeAsString('clear cancels staged rename\n');
      final store = MemoryLocalHistoryStore();
      final sessions = _BlockingPreparedPathSessionStore();
      final harness = await _harness(store, sessionStore: sessions);
      await harness.controller.openPath(sourcePath);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
      final documentId = history.documentIdForBuffer(
        harness.state.activeBuffer!.id,
      )!;
      await harness.controller.flushPersistence();
      sessions.blockNextPreparedPathWrite = true;

      final rename = harness.controller.renameWorkspaceEntity(
        sourcePath,
        p.basename(destinationPath),
      );
      await sessions.preparedWriteStarted.future;
      final clear = history.clearDocument(documentId);
      sessions.releasePreparedWrite.complete();

      expect(await rename, isFalse);
      await clear;
      expect(await File(sourcePath).exists(), isTrue);
      expect(await File(destinationPath).exists(), isFalse);
      final fresh = await store.load();
      expect(
        fresh.documents.where((document) => document.id == documentId),
        isEmpty,
      );
      expect(history.pendingPathReconciliations, isEmpty);
      expect(sessions.value?.pendingLocalHistoryReconciliations, isEmpty);
    },
  );

  for (final clearAll in [false, true]) {
    test('Clear ${clearAll ? "All" : "Document"} retains an executing rename '
        'journal across a crash', () async {
      final sourcePath = p.join(root.path, 'executing-clear-a.md');
      final destinationPath = p.join(root.path, 'executing-clear-b.md');
      await File(sourcePath).writeAsString('executing clear lineage\n');
      final store = MemoryLocalHistoryStore();
      final sessions = MemoryDocumentSessionStore();
      final recovery = MemoryDocumentRecoveryStore();
      final service = _BlockAfterRenameWorkspaceService();
      final harness = await _harness(
        store,
        service: service,
        sessionStore: sessions,
        recoveryStore: recovery,
      );
      await harness.controller.openPath(sourcePath);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
      final documentId = history.documentIdForBuffer(
        harness.state.activeBuffer!.id,
      )!;
      await harness.controller.flushPersistence();

      final rename = harness.controller.renameWorkspaceEntity(
        sourcePath,
        p.basename(destinationPath),
      );
      await service.renamed.future;
      expect(await File(sourcePath).exists(), isFalse);
      expect(await File(destinationPath).exists(), isTrue);
      final clear = clearAll
          ? history.clearAll()
          : history.clearDocument(documentId);
      await _waitFor(() {
        final pending =
            sessions.value?.pendingLocalHistoryReconciliations.singleOrNull;
        return pending?.phase ==
                LocalHistoryPathReconciliationPhase.executing &&
            pending!.targets.isEmpty &&
            pending.ownerIds.contains(harness.state.activeBuffer!.id);
      }, operation: 'executing rename journal narrowed by clear');

      // Freeze the durable state at the simulated crash boundary. The old
      // async callers are then allowed to unwind against their disposed
      // container, while the restarted app reads only the crash snapshot.
      final crashSession = sessions.value!;
      final crashRecovery = recovery.value;
      harness.container.dispose();
      service.release.complete();
      await rename;
      await clear;

      final restartedSessions = MemoryDocumentSessionStore()
        ..value = crashSession;
      final restartedRecovery = MemoryDocumentRecoveryStore()
        ..value = crashRecovery;
      final reopened = await _harness(
        store,
        sessionStore: restartedSessions,
        recoveryStore: restartedRecovery,
      );
      expect(
        await reopened.controller.restoreStartupSession(
          reopenCleanSession: false,
        ),
        isTrue,
      );
      final reopenedHistory = reopened.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(reopened.state.activeBuffer?.filePath, destinationPath);
      expect(
        await reopenedHistory.flushAll(reopened.state.documentBuffers),
        isTrue,
      );
      expect(reopenedHistory.pendingPathReconciliations, isEmpty);
      expect(
        restartedSessions.value?.pendingLocalHistoryReconciliations,
        isEmpty,
      );
    });
  }

  test(
    'targetless executing rename owner survives an ambiguous restart',
    () async {
      final sourcePath = p.join(root.path, 'ambiguous-owner-a.md');
      final destinationPath = p.join(root.path, 'ambiguous-owner-b.md');
      await File(destinationPath).writeAsString('committed destination\n');
      const bufferId = 'ambiguous-owner-buffer';
      const recoveryOwner = 'dead-ambiguous-owner';
      final operation = LocalHistoryPathReconciliation.remap(
        operationId: 'lh999999_123456789_902',
        sourcePath: sourcePath,
        destinationPath: destinationPath,
        targets: const [],
        ownerIds: const [bufferId],
        phase: LocalHistoryPathReconciliationPhase.executing,
      );
      final sessions = MemoryDocumentSessionStore()
        ..value = WorkspaceSessionSnapshot(
          workspacePath: null,
          tabs: [
            DocumentSessionEntry(
              id: bufferId,
              filePath: sourcePath,
              untitledName: null,
              editorState: const DocumentEditorState(),
              localHistoryPathReconciliationIds: [operation.operationId],
              recoveryOwnerId: recoveryOwner,
            ),
          ],
          activeBufferId: bufferId,
          pendingLocalHistoryReconciliations: [operation],
        );
      final recovery = MemoryDocumentRecoveryStore()
        ..value = RecoverySnapshot(
          cleanShutdown: false,
          entries: [
            DocumentRecoveryEntry(
              id: bufferId,
              workspacePath: null,
              filePath: sourcePath,
              untitledName: null,
              text: 'recovered editor text\n',
              lastSavedText: 'committed destination\n',
              diskSnapshot: null,
              format: TextFormatMetadata.utf8Lf,
              editorState: const DocumentEditorState(),
              revision: 1,
              ownerId: recoveryOwner,
            ),
          ],
        );
      final first = await _harness(
        MemoryLocalHistoryStore(),
        service: _FailFirstPathExistsWorkspaceService(),
        sessionStore: sessions,
        recoveryStore: recovery,
      );
      expect(
        await first.controller.restoreStartupSession(reopenCleanSession: false),
        isTrue,
      );
      await first.controller.flushPersistence();
      expect(
        sessions.value!.pendingLocalHistoryReconciliations.single.ownerIds,
        contains(bufferId),
      );
      expect(
        sessions.value!.tabs.single.localHistoryPathReconciliationIds,
        contains(operation.operationId),
      );
      first.container.dispose();

      final second = await _harness(
        MemoryLocalHistoryStore(),
        sessionStore: sessions,
        recoveryStore: recovery,
      );
      expect(
        await second.controller.restoreStartupSession(
          reopenCleanSession: false,
        ),
        isTrue,
      );
      expect(second.state.activeBuffer?.filePath, destinationPath);
      expect(sessions.value?.pendingLocalHistoryReconciliations, isEmpty);
    },
  );

  test(
    'move remaps a deferred first-save destination before baseline recovery',
    () async {
      final firstPath = p.join(root.path, 'A.md');
      final finalPath = p.join(root.path, 'B.md');
      final historyRoot = Directory(p.join(root.path, 'history'));
      final diskStore = FileLocalHistoryStore(
        rootDirectory: () async => historyRoot,
      );
      final store = _ControllableHistoryStore(diskStore)
        ..capturesAvailable = false;
      final harness = await _harness(store);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      await harness.controller.createMarkdownFile();
      harness.controller.updateActiveText('Original untitled baseline\n');
      harness.controller.updateActiveText('First saved contents\n');
      await Future<void>.delayed(Duration.zero);

      expect(await harness.controller.saveActiveAs(firstPath), isTrue);
      expect(await File(firstPath).exists(), isTrue);
      expect(
        await harness.controller.renameWorkspaceEntity(firstPath, 'B.md'),
        isTrue,
      );
      expect(harness.state.activeBuffer!.filePath, finalPath);

      store.capturesAvailable = true;
      expect(await history.flushAll(harness.state.documentBuffers), isTrue);
      harness.controller.updateActiveText('Saved after deferred move\n');
      expect(await harness.controller.saveActive(), isTrue);

      final reopenedStore = FileLocalHistoryStore(
        rootDirectory: () async => historyRoot,
      );
      final snapshot = await reopenedStore.load();
      expect(snapshot.documents, hasLength(1));
      expect(snapshot.documents.single.currentPath, finalPath);
      expect(
        await _revisionSources(
          reopenedStore,
          snapshot.revisionsFor(snapshot.documents.single.id),
        ),
        containsAll([
          'Original untitled baseline\n',
          'First saved contents\n',
          'Saved after deferred move\n',
        ]),
      );
    },
  );

  test(
    'recursive folder move remaps retained baselines for every open descendant',
    () async {
      final drafts = Directory(p.join(root.path, 'drafts'));
      final archive = Directory(p.join(root.path, 'archive'));
      await drafts.create();
      await archive.create();
      final firstPath = p.join(drafts.path, 'first.md');
      final secondPath = p.join(drafts.path, 'nested', 'second.md');
      await Directory(p.dirname(secondPath)).create(recursive: true);
      await File(firstPath).writeAsString('First baseline\n');
      await File(secondPath).writeAsString('Second baseline\n');
      final historyRoot = Directory(p.join(root.path, 'history'));
      final diskStore = FileLocalHistoryStore(
        rootDirectory: () async => historyRoot,
      );
      final store = _ControllableHistoryStore(diskStore)
        ..capturesAvailable = false;
      final harness = await _harness(store);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      await harness.controller.openPath(root.path);
      expect(await harness.controller.openActiveFile(firstPath), isTrue);
      expect(await harness.controller.openActiveFile(secondPath), isTrue);

      expect(
        await harness.controller.moveWorkspaceEntity(drafts.path, archive.path),
        isTrue,
      );
      store.capturesAvailable = true;
      expect(await history.flushAll(harness.state.documentBuffers), isTrue);

      final movedRoot = p.join(archive.path, 'drafts');
      final reopenedStore = FileLocalHistoryStore(
        rootDirectory: () async => historyRoot,
      );
      final snapshot = await reopenedStore.load();
      expect(
        snapshot.documents.map((document) => document.currentPath),
        containsAll([
          p.join(movedRoot, 'first.md'),
          p.join(movedRoot, 'nested', 'second.md'),
        ]),
      );
      expect(
        snapshot.documents.map((document) => document.currentPath),
        isNot(contains(firstPath)),
      );
      expect(
        await _revisionSources(reopenedStore, snapshot.revisions),
        containsAll(['First baseline\n', 'Second baseline\n']),
      );
    },
  );

  for (final existingDestination in [false, true]) {
    test('pending unrelated remap permits workspace Save As '
        '(existing=$existingDestination)', () async {
      final source = p.join(root.path, 'A.md');
      final moved = p.join(root.path, 'B.md');
      final destination = p.join(root.path, 'C.md');
      const sourceText = 'History belonging only to A/B\n';
      const destinationText = 'Existing history belonging only to C\n';
      const newText = 'Distinctive newly created C contents\n';
      await File(source).writeAsString(sourceText);
      final historyRoot = Directory(p.join(root.path, 'history'));
      FileLocalHistoryStore freshStore() =>
          FileLocalHistoryStore(rootDirectory: () async => historyRoot);
      final diskStore = freshStore();
      final existing = existingDestination
          ? await _capture(diskStore, destination, destinationText)
          : null;
      if (existingDestination) {
        await File(destination).writeAsString(destinationText);
      }
      final store = _ControllableHistoryStore(diskStore);
      final sessions = MemoryDocumentSessionStore();
      final harness = await _harness(
        store,
        sessionStore: sessions,
        recoveryStore: MemoryDocumentRecoveryStore(),
        fileMonitor: _ControlledFileMonitor(),
        timerFactory: (delay, callback) => _FakeTimer(delay, callback),
      );
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      await harness.controller.openPath(source);
      expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
      final sourceId = history.documentIdForBuffer(
        harness.state.activeBuffer!.id,
      )!;
      store.remapsAvailable = false;
      expect(
        await harness.controller.renameWorkspaceEntity(source, 'B.md'),
        isTrue,
      );
      expect(await File(source).exists(), isFalse);
      expect(await File(moved).readAsString(), sourceText);
      var pending = history.pendingPathReconciliations.single;
      expect(pending.sourcePath, source);
      expect(pending.destinationPath, moved);
      expect(pending.documentIds, [sourceId]);
      expect(pending.phase, LocalHistoryPathReconciliationPhase.committed);

      expect(await harness.controller.createMarkdownWorkspace(), isTrue);
      harness.controller.updateActiveText(newText);
      final newBufferId = harness.state.activeBuffer!.id;
      expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
      final untitledId = history.documentIdForBuffer(newBufferId)!;
      expect(untitledId, isNot(sourceId));
      // Closing A transfers its retained work to a detached owner.
      pending = history.pendingPathReconciliations.single;
      expect(
        await harness.controller.saveActiveAs(
          destination,
          overwriteExisting: existingDestination,
        ),
        isTrue,
      );
      expect(await File(destination).readAsString(), newText);
      expect(harness.state.activeBuffer!.filePath, destination);
      expect(harness.state.activeBuffer!.isUntitled, isFalse);
      expect(harness.state.activeBuffer!.isDirty, isFalse);
      expect(
        harness.state.message?.code,
        isNot(WorkspaceMessageCode.saveFailed),
      );
      final destinationId = history.documentIdForBuffer(newBufferId)!;
      expect(destinationId, existing?.document.id ?? untitledId);
      expect(destinationId, isNot(sourceId));
      if (existingDestination) expect(destinationId, isNot(untitledId));
      expect(history.warningForBuffer(newBufferId), isNull);
      expect(
        history.pendingPathReconciliations.single.toJson(),
        pending.toJson(),
      );
      await harness.controller.flushPersistence();
      expect(
        sessions.value!.pendingLocalHistoryReconciliations.single.toJson(),
        pending.toJson(),
      );

      final beforeRecoveryStore = freshStore();
      final beforeRecovery = await beforeRecoveryStore.load();
      expect(
        beforeRecovery.documents
            .singleWhere((d) => d.id == sourceId)
            .currentPath,
        source,
      );
      expect(
        beforeRecovery.documents
            .singleWhere((d) => d.id == destinationId)
            .currentPath,
        destination,
      );
      final destinationRevisions = beforeRecovery.revisionsFor(destinationId);
      expect(
        await _revisionSources(beforeRecoveryStore, destinationRevisions),
        existingDestination
            ? containsAll([destinationText, newText])
            : everyElement(newText),
      );
      expect(destinationRevisions, isNotEmpty);
      expect(
        await _revisionSources(
          beforeRecoveryStore,
          beforeRecovery.revisionsFor(sourceId),
        ),
        [sourceText],
      );
      if (existingDestination) {
        expect(
          beforeRecovery.documents
              .singleWhere((d) => d.id == untitledId)
              .untitled,
          isTrue,
        );
        expect(
          await _revisionSources(
            beforeRecoveryStore,
            beforeRecovery.revisionsFor(untitledId),
          ),
          [newText],
        );
      }

      store.remapsAvailable = true;
      expect(await history.flushAll(harness.state.documentBuffers), isTrue);
      expect(history.pendingPathReconciliations, isEmpty);
      final afterRecoveryStore = freshStore();
      final afterRecovery = await afterRecoveryStore.load();
      expect(
        afterRecovery.documents
            .singleWhere((d) => d.id == sourceId)
            .currentPath,
        moved,
      );
      expect(
        afterRecovery.documents
            .singleWhere((d) => d.id == destinationId)
            .toJson(),
        beforeRecovery.documents
            .singleWhere((d) => d.id == destinationId)
            .toJson(),
      );
      expect(
        afterRecovery.revisionsFor(destinationId).map((r) => r.toJson()),
        destinationRevisions.map((r) => r.toJson()),
      );
      expect(history.documentIdForBuffer(newBufferId), destinationId);
      expect(harness.state.activeBuffer!.filePath, destination);
      expect(await File(destination).readAsString(), newText);
      expect(history.warningForBuffer(newBufferId), isNull);
    });
  }

  test('committed move retries a failed history path reconciliation', () async {
    final sourcePath = p.join(root.path, 'remap-a.md');
    final destinationPath = p.join(root.path, 'remap-b.md');
    await File(sourcePath).writeAsString('Before remap failure\n');
    final historyRoot = Directory(p.join(root.path, 'history'));
    final diskStore = FileLocalHistoryStore(
      rootDirectory: () async => historyRoot,
    );
    final store = _ControllableHistoryStore(diskStore);
    final harness = await _harness(store);
    final history = harness.container.read(
      localHistoryControllerProvider.notifier,
    );
    await harness.controller.openPath(sourcePath);
    store.remapsAvailable = false;

    expect(
      await harness.controller.renameWorkspaceEntity(sourcePath, 'remap-b.md'),
      isTrue,
    );
    expect(harness.state.activeBuffer!.filePath, destinationPath);
    store.remapsAvailable = true;
    expect(await history.flushAll(harness.state.documentBuffers), isTrue);
    harness.controller.updateActiveText('After remap recovery\n');
    expect(await harness.controller.saveActive(), isTrue);

    final reopenedStore = FileLocalHistoryStore(
      rootDirectory: () async => historyRoot,
    );
    final snapshot = await reopenedStore.load();
    expect(snapshot.documents, hasLength(1));
    expect(snapshot.documents.single.currentPath, destinationPath);
    expect(
      await _revisionSources(
        reopenedStore,
        snapshot.revisionsFor(snapshot.documents.single.id),
      ),
      containsAll(['Before remap failure\n', 'After remap recovery\n']),
    );
  });

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
      final beforePromotionRetry = await memory.load();
      expect(
        beforePromotionRetry.documents,
        hasLength(1),
        reason: beforePromotionRetry.documents
            .map(
              (document) =>
                  '${document.id}|${document.currentPath}|${document.deleted}|'
                  '${beforePromotionRetry.revisionsFor(document.id).map((revision) => '${revision.reason}:${revision.historicalPath}').join(',')}',
            )
            .join(' ; '),
      );
      expect(beforePromotionRetry.documents.single.currentPath, isNull);

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
    'second Save As preserves a failed first-save association as the source',
    () async {
      final memory = MemoryLocalHistoryStore();
      final store = _FailingFirstPromotionStore(memory);
      final harness = await _harness(store);
      await harness.controller.createMarkdownFile();
      harness.controller.updateActiveText('Original untitled lineage\n');
      await Future<void>.delayed(Duration.zero);
      await harness.container
          .read(localHistoryControllerProvider.notifier)
          .flushBuffer(harness.state.activeBuffer!);
      final originalDocument = (await memory.load()).documents.single;
      final firstPath = p.join(root.path, 'A.md');
      final copyPath = p.join(root.path, 'B.md');

      expect(await harness.controller.saveActiveAs(firstPath), isTrue);
      expect((await memory.load()).documents.single.currentPath, isNull);
      expect(await harness.controller.saveActiveAs(copyPath), isTrue);
      expect(
        await harness.container
            .read(localHistoryControllerProvider.notifier)
            .flushAll(harness.state.documentBuffers),
        isTrue,
      );

      final snapshot = await memory.load();
      expect(snapshot.documents, hasLength(2));
      final source = snapshot.documents.singleWhere(
        (document) => document.currentPath == firstPath,
      );
      final copy = snapshot.documents.singleWhere(
        (document) => document.currentPath == copyPath,
      );
      expect(source.id, originalDocument.id);
      expect(copy.id, isNot(originalDocument.id));
      expect(
        await _revisionSources(memory, snapshot.revisionsFor(source.id)),
        contains('Original untitled lineage\n'),
      );
      expect(
        await _revisionSources(memory, snapshot.revisionsFor(copy.id)),
        contains('Original untitled lineage\n'),
      );

      for (final expected in [(firstPath, source.id), (copyPath, copy.id)]) {
        final reopened = await _harness(store);
        await reopened.controller.openPath(expected.$1);
        final history = reopened.container.read(
          localHistoryControllerProvider.notifier,
        );
        await history.selectDocumentForBuffer(reopened.state.activeBuffer!);
        expect(
          reopened.container
              .read(localHistoryControllerProvider)
              .selectedDocument
              ?.id,
          expected.$2,
        );
      }
    },
  );

  test(
    'untitled overwrite Save As partitions a failed source checkpoint',
    () async {
      final memory = MemoryLocalHistoryStore();
      const forkPoint = 'untitled overwrite fork point\n';
      final store = _FailingExactSourceStore(memory, forkPoint);
      final destination = p.join(root.path, 'B.md');
      await File(destination).writeAsString('existing B\n');
      final existing = await _capture(memory, destination, 'existing B\n');
      final harness = await _harness(store);
      await harness.controller.createMarkdownFile();
      harness.controller.updateActiveText('source baseline\n');
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
      final sourceId = history.documentIdForBuffer(
        harness.state.activeBuffer!.id,
      )!;
      expect(sourceId, isNot(existing.document.id));

      harness.controller.updateActiveText(forkPoint);
      await Future<void>.delayed(Duration.zero);
      expect(
        await harness.controller.saveActiveAs(
          destination,
          overwriteExisting: true,
        ),
        isTrue,
      );
      expect(harness.state.activeBuffer!.filePath, destination);
      expect(await history.flushAll(harness.state.documentBuffers), isTrue);

      final reloaded = await memory.load();
      expect(
        await _revisionSources(memory, reloaded.revisionsFor(sourceId)),
        contains(forkPoint),
      );
      expect(
        await _revisionSources(
          memory,
          reloaded.revisionsFor(existing.document.id),
        ),
        containsAll(['existing B\n', forkPoint]),
      );
      expect(
        history.documentIdForBuffer(harness.state.activeBuffer!.id),
        existing.document.id,
      );
    },
  );

  test(
    'untitled overwrite Save As source checkpoint survives process restart',
    () async {
      final memory = MemoryLocalHistoryStore();
      const forkPoint = 'durable untitled overwrite fork point\n';
      final store = _FailingExactSourceStore(memory, forkPoint);
      final sessions = MemoryDocumentSessionStore();
      final recovery = MemoryDocumentRecoveryStore();
      final destination = p.join(root.path, 'durable-B.md');
      await File(destination).writeAsString('existing durable B\n');
      final existing = await _capture(
        memory,
        destination,
        'existing durable B\n',
      );
      final harness = await _harness(
        store,
        sessionStore: sessions,
        recoveryStore: recovery,
      );
      await harness.controller.createMarkdownFile();
      harness.controller.updateActiveText('durable source baseline\n');
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
      final sourceId = history.documentIdForBuffer(
        harness.state.activeBuffer!.id,
      )!;

      harness.controller.updateActiveText(forkPoint);
      await Future<void>.delayed(Duration.zero);
      expect(
        await harness.controller.saveActiveAs(
          destination,
          overwriteExisting: true,
        ),
        isTrue,
      );
      expect(sessions.value?.retainedLocalHistoryCaptures, hasLength(1));
      expect(
        sessions.value?.retainedLocalHistoryCaptures.single.pending?.source,
        forkPoint,
      );
      expect(
        sessions.value?.retainedLocalHistoryCaptures.single.documentId,
        sourceId,
      );
      harness.container.dispose();

      final reopened = await _harness(
        store,
        sessionStore: sessions,
        recoveryStore: recovery,
      );
      expect(sessions.value?.retainedLocalHistoryCaptures, hasLength(1));
      expect(
        await reopened.controller.restoreStartupSession(
          reopenCleanSession: false,
        ),
        isTrue,
      );
      final restoredHistory = reopened.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(
        await restoredHistory.flushAll(reopened.state.documentBuffers),
        isTrue,
      );
      await reopened.controller.flushPersistence();
      expect(sessions.value?.retainedLocalHistoryCaptures, isEmpty);

      final snapshot = await memory.load();
      expect(
        await _revisionSources(memory, snapshot.revisionsFor(sourceId)),
        contains(forkPoint),
      );
      final sourceForks = <String>[];
      for (final revision in snapshot.revisionsFor(sourceId)) {
        if ((await memory.readRevision(revision.id))?.source == forkPoint) {
          sourceForks.add(revision.id);
        }
      }
      expect(sourceForks, hasLength(1));
      expect(
        await _revisionSources(
          memory,
          snapshot.revisionsFor(existing.document.id),
        ),
        containsAll(['existing durable B\n', forkPoint]),
      );
      expect(sourceId, isNot(existing.document.id));
    },
  );

  test(
    'Save As journals its source before the filesystem commit returns',
    () async {
      final source = p.join(root.path, 'journal-source.md');
      final destination = p.join(root.path, 'journal-destination.md');
      await File(source).writeAsString('source baseline\n');
      await File(destination).writeAsString('destination baseline\n');
      final memory = MemoryLocalHistoryStore();
      final sessions = MemoryDocumentSessionStore();
      final service = _BlockingSaveAsCommitWorkspaceService(destination);
      final harness = await _harness(
        memory,
        service: service,
        sessionStore: sessions,
      );
      await harness.controller.openPath(source);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
      final sourceId = history.documentIdForBuffer(
        harness.state.activeBuffer!.id,
      )!;
      harness.controller.updateActiveText('source fork point\n');

      final save = harness.controller.saveActiveAs(
        destination,
        overwriteExisting: true,
      );
      await service.committed.future;
      expect(await File(destination).readAsString(), 'source fork point\n');
      expect(sessions.value?.pendingLocalHistorySaveAs, hasLength(1));
      expect(
        sessions.value?.pendingLocalHistorySaveAs.single.sourceDocumentId,
        sourceId,
      );
      expect(
        sessions.value?.pendingLocalHistorySaveAs.single.source.source,
        'source fork point\n',
      );

      service.release.complete();
      expect(await save, isTrue);
      expect(sessions.value?.pendingLocalHistorySaveAs, isEmpty);
    },
  );

  test(
    'Save As cannot publish a second owner when its destination opens in flight',
    () async {
      final source = p.join(root.path, 'racing-source.md');
      final destination = p.join(root.path, 'z-racing-destination.md');
      await File(source).writeAsString('source baseline\n');
      await File(destination).writeAsString('destination baseline\n');
      final memory = MemoryLocalHistoryStore();
      final service = _BlockingBeforeSaveAsCommitWorkspaceService(destination);
      final harness = await _harness(memory, service: service);
      await harness.controller.openPath(root.path);
      expect(await harness.controller.openActiveFile(source), isTrue);
      final sourceBufferId = harness.state.activeBuffer!.id;
      harness.controller.updateActiveText('published destination bytes\n');

      final save = harness.controller.saveActiveAs(
        destination,
        overwriteExisting: true,
      );
      await service.writeStarted.future.timeout(const Duration(seconds: 5));
      expect(
        await harness.controller
            .openActiveFile(destination)
            .timeout(const Duration(seconds: 5)),
        isTrue,
      );
      final destinationBufferId = harness.state.activeBuffer!.id;
      expect(destinationBufferId, isNot(sourceBufferId));

      service.release.complete();
      expect(await save.timeout(const Duration(seconds: 5)), isFalse);
      expect(
        harness.state.documentBuffers
            .singleWhere((buffer) => buffer.id == sourceBufferId)
            .filePath,
        source,
      );
      expect(
        harness.state.documentBuffers.where(
          (buffer) => buffer.filePath == destination,
        ),
        hasLength(1),
      );
      expect(
        harness.state.documentBuffers
            .singleWhere((buffer) => buffer.id == destinationBufferId)
            .text,
        'destination baseline\n',
      );
      expect(
        await File(destination).readAsString(),
        'published destination bytes\n',
      );
    },
  );

  test(
    'first Save As rechecks destination ownership after opening its workspace',
    () async {
      final destination = p.join(root.path, 'first-save-racing-owner.md');
      final service = _BlockingFirstSaveOpenWorkspaceService(destination);
      final memory = MemoryLocalHistoryStore();
      final harness = await _harness(memory, service: service);
      await harness.controller.createMarkdownFile();
      final sourceBufferId = harness.state.activeBuffer!.id;
      harness.controller.updateActiveText('first-save published bytes\n');
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
      final originalSourceHistoryId = history.documentIdForBuffer(
        sourceBufferId,
      )!;

      final save = harness.controller.saveActiveAs(destination);
      await service.openStarted.future;
      expect(await harness.controller.openActiveFile(destination), isTrue);
      final destinationBufferId = harness.state.activeBuffer!.id;
      expect(destinationBufferId, isNot(sourceBufferId));

      service.release.complete();
      expect(await save, isFalse);
      final sourceBuffer = harness.state.documentBuffers.singleWhere(
        (buffer) => buffer.id == sourceBufferId,
      );
      expect(sourceBuffer.isUntitled, isTrue);
      expect(
        harness.state.documentBuffers.where(
          (buffer) => buffer.filePath == destination,
        ),
        hasLength(1),
      );
      expect(
        harness.state.documentBuffers
            .singleWhere((buffer) => buffer.id == destinationBufferId)
            .text,
        'first-save published bytes\n',
      );
      expect(
        await File(destination).readAsString(),
        'first-save published bytes\n',
      );

      await harness.controller.activateDocumentBuffer(sourceBufferId);
      harness.controller.updateActiveText('later untitled-only edit\n');
      expect(
        await history.flushBuffer(harness.state.activeBuffer!),
        isTrue,
        reason:
            'pending=${history.pendingSaveAsOperations.length} '
            'warning=${history.warningForBuffer(sourceBufferId)?.detail}',
      );
      expect(
        await history.flushAll(harness.state.documentBuffers),
        isTrue,
        reason:
            'pendingSaveAs=${history.pendingSaveAsOperations.length} '
            'pendingPromotions=${history.pendingIdentityPromotions.length} '
            'warning=${history.state.warning?.detail}',
      );
      final laterSourceHistoryId = history.documentIdForBuffer(sourceBufferId);
      expect(laterSourceHistoryId, originalSourceHistoryId);

      final snapshot = await memory.load();
      final sourceDocument = snapshot.documents.singleWhere(
        (document) => document.id == originalSourceHistoryId,
      );
      expect(sourceDocument.currentPath, isNull);
      final destinationDocument = snapshot.documents.singleWhere(
        (document) => document.currentPath == destination,
      );
      expect(destinationDocument.id, isNot(sourceDocument.id));
      expect(destinationDocument.currentPath, destination);
      expect(
        await _revisionSources(
          memory,
          snapshot.revisionsFor(destinationDocument.id),
        ),
        allOf(
          contains('first-save published bytes\n'),
          isNot(contains('later untitled-only edit\n')),
        ),
      );
      expect(
        await _revisionSources(
          memory,
          snapshot.revisionsFor(sourceDocument.id),
        ),
        contains('later untitled-only edit\n'),
      );
    },
  );

  test(
    'first Save As waits for an unbound live destination history owner',
    () async {
      final destination = p.join(
        root.path,
        'first-save-blocked-destination-owner.md',
      );
      final memory = MemoryLocalHistoryStore();
      final store = _BlockingPathBaselineStore(memory, destination);
      final service = _BlockingFirstSaveOpenWorkspaceService(destination);
      final harness = await _harness(store, service: service);
      await harness.controller.createMarkdownFile();
      final sourceBufferId = harness.state.activeBuffer!.id;
      harness.controller.updateActiveText('published first-save bytes\n');
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
      final sourceHistoryId = history.documentIdForBuffer(sourceBufferId)!;

      var saveCompleted = false;
      final save = harness.controller.saveActiveAs(destination).then((value) {
        saveCompleted = true;
        return value;
      });
      await service.openStarted.future;
      expect(await harness.controller.openActiveFile(destination), isTrue);
      final destinationBufferId = harness.state.activeBuffer!.id;
      expect(destinationBufferId, isNot(sourceBufferId));
      await store.started.future;

      service.release.complete();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(saveCompleted, isFalse);

      store.release.complete();
      expect(await save, isFalse);
      expect(await history.flushAll(harness.state.documentBuffers), isTrue);
      final source = harness.state.documentBuffers.singleWhere(
        (buffer) => buffer.id == sourceBufferId,
      );
      expect(source.filePath, isNull);
      expect(
        harness.state.documentBuffers
            .singleWhere((buffer) => buffer.id == destinationBufferId)
            .filePath,
        destination,
      );

      final snapshot = await memory.load();
      final sourceDocument = snapshot.documents.singleWhere(
        (document) => document.id == sourceHistoryId,
      );
      expect(sourceDocument.currentPath, isNull);
      final destinationDocument = snapshot.documents.singleWhere(
        (document) => document.currentPath == destination,
      );
      expect(destinationDocument.id, isNot(sourceHistoryId));

      await harness.controller.activateDocumentBuffer(destinationBufferId);
      harness.controller.updateActiveText('later destination-only edit\n');
      expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
      final settled = await memory.load();
      expect(
        await _revisionSources(memory, settled.revisionsFor(sourceHistoryId)),
        isNot(contains('later destination-only edit\n')),
      );
      expect(
        await _revisionSources(
          memory,
          settled.revisionsFor(destinationDocument.id),
        ),
        contains('later destination-only edit\n'),
      );
    },
  );

  test(
    'disposed Save As cannot publish after losing its prepared journal owner',
    () async {
      final source = p.join(root.path, 'disposed-save-as-source.md');
      final destination = p.join(root.path, 'disposed-save-as-destination.md');
      await File(source).writeAsString('source before disposal\n');
      final sessions = _BlockingRepeatedSaveAsSessionStore();
      final harness = await _harness(
        MemoryLocalHistoryStore(),
        sessionStore: sessions,
      );
      await harness.controller.openPath(source);
      harness.controller.updateActiveText('must not publish after disposal\n');

      final save = harness.controller.saveActiveAs(destination);
      await sessions.secondJournalWriteStarted.future;
      expect(sessions.value?.pendingLocalHistorySaveAs, hasLength(1));
      expect(
        sessions.value?.pendingLocalHistorySaveAs.single.phase,
        LocalHistoryPathReconciliationPhase.prepared,
      );

      harness.container.dispose();
      sessions.releaseSecondJournalWrite.complete();
      expect(await save, isFalse);
      expect(await File(destination).exists(), isFalse);
      expect(
        sessions.value?.pendingLocalHistorySaveAs.single.phase,
        LocalHistoryPathReconciliationPhase.prepared,
      );
    },
  );

  test(
    'Save As published after disposal leaves a committed recoverable journal',
    () async {
      final source = p.join(root.path, 'dispose-executing-source.md');
      final destination = p.join(root.path, 'dispose-executing-target.md');
      await File(source).writeAsString('source before executing\n');
      await File(destination).writeAsString('target before executing\n');
      final service = _BlockBeforeSaveAsPublishWorkspaceService();
      final sessions = MemoryDocumentSessionStore();
      final recovery = MemoryDocumentRecoveryStore();
      final memory = MemoryLocalHistoryStore();
      final harness = await _harness(
        memory,
        service: service,
        sessionStore: sessions,
        recoveryStore: recovery,
      );
      await harness.controller.openPath(source);
      harness.controller.updateActiveText('published after disposal\n');

      final save = harness.controller.saveActiveAs(
        destination,
        overwriteExisting: true,
      );
      await service.entered.future;
      expect(
        sessions.value?.pendingLocalHistorySaveAs.single.phase,
        LocalHistoryPathReconciliationPhase.executing,
      );
      harness.container.dispose();
      service.release.complete();
      expect(await save, isFalse);
      expect(
        await File(destination).readAsString(),
        'published after disposal\n',
      );
      expect(
        sessions.value?.pendingLocalHistorySaveAs.single.phase,
        LocalHistoryPathReconciliationPhase.committed,
      );

      final reopened = await _harness(
        memory,
        sessionStore: sessions,
        recoveryStore: recovery,
      );
      await reopened.controller.restorePreviousSession();
      final reopenedHistory = reopened.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(
        await reopenedHistory.flushAll(reopened.state.documentBuffers),
        isTrue,
      );
      final snapshot = await memory.load();
      expect(
        snapshot.documents.any(
          (document) => document.currentPath == destination,
        ),
        isTrue,
      );
      expect(sessions.value?.pendingLocalHistorySaveAs, isEmpty);
    },
  );

  test(
    'Save As commit write failure after disposal uses the session fallback',
    () async {
      final source = p.join(root.path, 'commit-failure-source.md');
      final destination = p.join(root.path, 'commit-failure-target.md');
      await File(source).writeAsString('source before commit failure\n');
      await File(destination).writeAsString('target before commit failure\n');
      final sessions = _BlockingFailingCommittedSaveAsSessionStore();
      final harness = await _harness(
        MemoryLocalHistoryStore(),
        sessionStore: sessions,
      );
      await harness.controller.openPath(source);
      harness.controller.updateActiveText('published before failed journal\n');

      final save = harness.controller.saveActiveAs(
        destination,
        overwriteExisting: true,
      );
      await sessions.committedWriteStarted.future;
      expect(
        await File(destination).readAsString(),
        'published before failed journal\n',
      );
      harness.container.dispose();
      sessions.releaseCommittedWrite.complete();

      expect(await save, isFalse);
      expect(sessions.commitFallbacks, 1);
      expect(
        sessions.value?.pendingLocalHistorySaveAs.single.phase,
        LocalHistoryPathReconciliationPhase.committed,
      );
    },
  );

  test(
    'Save As publishes destination after a post-publish callback failure',
    () async {
      final source = p.join(root.path, 'callback-source.md');
      final destination = p.join(root.path, 'callback-destination.md');
      await File(source).writeAsString('source before callback\n');
      await File(destination).writeAsString('destination before callback\n');
      final memory = MemoryLocalHistoryStore();
      final sessions = MemoryDocumentSessionStore();
      final harness = await _harness(
        memory,
        service: _FailAfterPublishedSaveAsWorkspaceService(),
        sessionStore: sessions,
      );
      await harness.controller.openPath(source);
      harness.controller.updateActiveText('published despite callback\n');

      expect(
        await harness.controller.saveActiveAs(
          destination,
          overwriteExisting: true,
        ),
        isTrue,
      );
      expect(
        await File(destination).readAsString(),
        'published despite callback\n',
      );
      expect(harness.state.activeBuffer?.filePath, destination);
      expect(harness.state.activeBuffer?.dirty, isFalse);
      expect(sessions.value?.pendingLocalHistorySaveAs, isEmpty);
      expect(
        (await memory.load()).documents.any(
          (document) => document.currentPath == destination,
        ),
        isTrue,
      );
    },
  );

  test('failed rename reconciliation survives shutdown and restart', () async {
    final source = p.join(root.path, 'A.md');
    final destination = p.join(root.path, 'B.md');
    await File(source).writeAsString('original A\n');
    final memory = MemoryLocalHistoryStore();
    final store = _ControllableHistoryStore(memory)..remapsAvailable = false;
    final sessions = MemoryDocumentSessionStore();
    final recovery = MemoryDocumentRecoveryStore();
    final harness = await _harness(
      store,
      sessionStore: sessions,
      recoveryStore: recovery,
    );
    await harness.controller.openPath(source);
    final history = harness.container.read(
      localHistoryControllerProvider.notifier,
    );
    expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
    final originalId = history.documentIdForBuffer(
      harness.state.activeBuffer!.id,
    )!;
    expect(
      await harness.controller.renameWorkspaceEntity(source, 'B.md'),
      isTrue,
    );
    expect(await File(destination).exists(), isTrue);
    await harness.controller.markCleanShutdown();
    expect(recovery.value.cleanShutdown, isFalse);
    expect(sessions.value?.pendingLocalHistoryReconciliations, hasLength(1));
    harness.container.dispose();

    store.remapsAvailable = true;
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
    final restoredHistory = reopened.container.read(
      localHistoryControllerProvider.notifier,
    );
    expect(
      await restoredHistory.flushAll(reopened.state.documentBuffers),
      isTrue,
    );
    final snapshot = await memory.load();
    final moved = snapshot.documents.singleWhere(
      (document) => document.id == originalId,
    );
    expect(moved.currentPath, destination);
    expect(
      snapshot.documents.where(
        (document) => document.currentPath == destination,
      ),
      hasLength(1),
    );
    expect(
      await _revisionSources(memory, snapshot.revisionsFor(originalId)),
      contains('original A\n'),
    );
  });

  test(
    'live owner keeps committed remap journal until its recovery can follow',
    () async {
      final source = p.join(root.path, 'live-remap-owner-a.md');
      final destination = p.join(root.path, 'live-remap-owner-b.md');
      final recoveryFile = p.join(root.path, 'live-remap-recovery.json');
      await File(source).writeAsString('saved before live remap\n');
      final store = MemoryLocalHistoryStore();
      final sessions = MemoryDocumentSessionStore();
      final ownerRecovery = JsonDocumentRecoveryStore(
        filePathOverride: recoveryFile,
      );
      final owner = await _harness(
        store,
        sessionStore: sessions,
        recoveryStore: ownerRecovery,
      );
      await owner.controller.openPath(source);
      final ownerHistory = owner.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(await ownerHistory.flushBuffer(owner.state.activeBuffer!), isTrue);
      owner.controller.updateActiveText('dirty before committed remap\n');
      await owner.controller.flushPersistence();

      String? operationId;
      await ownerHistory.runStagedPathRemap<File>(
        sourcePath: source,
        destinationPath: destination,
        boundBufferId: owner.state.activeBuffer!.id,
        filesystemOperation: () => File(source).rename(destination),
        didCommit: (_) => true,
        onOperationStaged: (value) => operationId = value,
      );
      expect(operationId, isNotNull);
      owner.controller.updateActiveText('newer recovery after remap commit\n');
      await owner.controller.flushPersistence();
      expect(
        sessions.value?.pendingLocalHistoryReconciliations.single.phase,
        LocalHistoryPathReconciliationPhase.committed,
      );

      final observerRecovery = _ExternallyOwnedJsonRecoveryStore(
        filePathOverride: recoveryFile,
        externallyLiveOwnerId: ownerRecovery.ownerId,
      );
      final observer = await _harness(
        store,
        sessionStore: sessions,
        recoveryStore: observerRecovery,
      );
      await observer.controller.restoreStartupSession(
        reopenCleanSession: false,
      );
      expect(
        sessions.value?.pendingLocalHistoryReconciliations.map(
          (operation) => operation.operationId,
        ),
        contains(operationId),
      );
      expect(
        sessions.value?.retiredLocalHistoryReconciliationIds,
        isNot(contains(operationId)),
      );
      observer.container.dispose();
      owner.container.dispose();

      final restarted = await _harness(
        store,
        sessionStore: sessions,
        recoveryStore: JsonDocumentRecoveryStore(
          filePathOverride: recoveryFile,
        ),
      );
      expect(
        await restarted.controller.restoreStartupSession(
          reopenCleanSession: false,
        ),
        isTrue,
      );
      final restoredDirty = restarted.state.documentBuffers.singleWhere(
        (buffer) => buffer.text == 'newer recovery after remap commit\n',
      );
      expect(restoredDirty.filePath, destination);
      expect(sessions.value?.pendingLocalHistoryReconciliations, isEmpty);
      final snapshot = await store.load();
      expect(snapshot.documents, hasLength(1));
      expect(snapshot.documents.single.currentPath, destination);
    },
  );

  test(
    'prepared rename journal repairs a crash after filesystem commit',
    () async {
      final source = p.join(root.path, 'prepared-A.md');
      final destination = p.join(root.path, 'prepared-B.md');
      await File(source).writeAsString('prepared crash lineage\n');
      final memory = MemoryLocalHistoryStore();
      final store = _ControllableHistoryStore(memory)..remapsAvailable = false;
      final sessions = MemoryDocumentSessionStore();
      final recovery = MemoryDocumentRecoveryStore();
      final harness = await _harness(
        store,
        sessionStore: sessions,
        recoveryStore: recovery,
      );
      await harness.controller.openPath(source);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
      final originalId = history.documentIdForBuffer(
        harness.state.activeBuffer!.id,
      )!;
      final targets = await history.preparePathReconciliation(
        source,
        recursive: false,
      );
      final operationId = await history.stagePathRemap(
        source,
        destination,
        targets: targets,
      );
      expect(
        sessions.value?.pendingLocalHistoryReconciliations.single.phase,
        LocalHistoryPathReconciliationPhase.prepared,
      );
      await File(source).rename(destination);
      await history.commitStagedPathOperation(operationId);
      harness.container.dispose();
      store.remapsAvailable = true;

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
      final snapshot = await memory.load();
      expect(snapshot.documents, hasLength(1));
      expect(snapshot.documents.single.id, originalId);
      expect(snapshot.documents.single.currentPath, destination);
      expect(
        await _revisionSources(memory, snapshot.revisionsFor(originalId)),
        contains('prepared crash lineage\n'),
      );
    },
  );

  test(
    'committed deletion detaches recovery newer than stored history',
    () async {
      final path = p.join(root.path, 'deleted-with-newer-recovery.md');
      const bufferId = 'file:deleted-with-newer-recovery';
      const previousOwner = 'dead-recovery-owner';
      final memory = MemoryLocalHistoryStore();
      final captured = await _capture(
        memory,
        path,
        'captured before deletion\n',
      );
      final target = (await memory.resolvePathTargets(
        path,
        recursive: false,
      )).single;
      final operation = LocalHistoryPathReconciliation.deletion(
        operationId: 'lh${pid}_123456789_301',
        sourcePath: path,
        recursive: false,
        targets: [target],
        ownerIds: const [bufferId],
        phase: LocalHistoryPathReconciliationPhase.committed,
      );
      final sessions = MemoryDocumentSessionStore()
        ..value = WorkspaceSessionSnapshot(
          workspacePath: null,
          tabs: [
            DocumentSessionEntry(
              id: bufferId,
              filePath: path,
              untitledName: null,
              editorState: const DocumentEditorState(),
              localHistoryDocumentId: captured.document.id,
              localHistoryPathReconciliationIds: [operation.operationId],
              recoveryOwnerId: previousOwner,
            ),
          ],
          activeBufferId: bufferId,
          pendingLocalHistoryReconciliations: [operation],
        );
      final recovery = MemoryDocumentRecoveryStore()
        ..value = RecoverySnapshot(
          cleanShutdown: false,
          entries: [
            DocumentRecoveryEntry(
              id: bufferId,
              workspacePath: null,
              filePath: path,
              untitledName: null,
              text: 'newer editor text never captured\n',
              lastSavedText: 'captured before deletion\n',
              diskSnapshot: null,
              format: TextFormatMetadata.utf8Lf,
              editorState: DocumentEditorState(),
              revision: 2,
              ownerId: previousOwner,
            ),
          ],
        );
      final harness = await _harness(
        memory,
        sessionStore: sessions,
        recoveryStore: recovery,
      );

      expect(
        await harness.controller.restoreStartupSession(
          reopenCleanSession: false,
        ),
        isTrue,
      );

      final restored = harness.state.activeBuffer!;
      expect(restored.text, 'newer editor text never captured\n');
      expect(restored.filePath, isNull);
      expect(
        restored.displayName,
        'deleted-with-newer-recovery.md (Recovered)',
      );
      expect(restored.isDirty, isTrue);
      final fresh = await memory.load();
      final original = fresh.documents.singleWhere(
        (document) => document.id == captured.document.id,
      );
      expect(original.deleted, isTrue);
      expect(await _revisionSources(memory, fresh.revisionsFor(original.id)), [
        'captured before deletion\n',
      ]);
      expect(sessions.value?.pendingLocalHistoryReconciliations, isEmpty);
      expect(recovery.value.entries.single.text, restored.text);
      expect(recovery.value.entries.single.filePath, isNull);
    },
  );

  test(
    'recursive deletion evidence cannot consume a sibling recovery',
    () async {
      final directory = p.join(root.path, 'deleted-collision');
      final firstPath = p.join(directory, 'a.md');
      final secondPath = p.join(directory, 'b.md');
      const bufferId = 'file:deleted-collision-a';
      const recoveryOwner = 'deleted-collision-owner';
      final memory = MemoryLocalHistoryStore();
      final first = await _capture(memory, firstPath, 'older first text\n');
      final second = await _capture(memory, secondPath, 'same recovery text\n');
      final targets = await memory.resolvePathTargets(
        directory,
        recursive: true,
      );
      final operation = LocalHistoryPathReconciliation.deletion(
        operationId: 'lh${pid}_123456789_302',
        sourcePath: directory,
        recursive: true,
        targets: targets,
        ownerIds: const [bufferId],
        phase: LocalHistoryPathReconciliationPhase.committed,
      );
      final sessions = MemoryDocumentSessionStore()
        ..value = WorkspaceSessionSnapshot(
          workspacePath: null,
          tabs: [
            DocumentSessionEntry(
              id: bufferId,
              filePath: firstPath,
              untitledName: null,
              editorState: const DocumentEditorState(),
              localHistoryDocumentId: first.document.id,
              localHistoryPathReconciliationIds: [operation.operationId],
              recoveryOwnerId: recoveryOwner,
            ),
          ],
          activeBufferId: bufferId,
          pendingLocalHistoryReconciliations: [operation],
        );
      final recovery = MemoryDocumentRecoveryStore()
        ..value = RecoverySnapshot(
          cleanShutdown: false,
          entries: [
            DocumentRecoveryEntry(
              id: bufferId,
              workspacePath: null,
              filePath: firstPath,
              untitledName: null,
              text: 'same recovery text\n',
              lastSavedText: 'older first text\n',
              diskSnapshot: null,
              format: TextFormatMetadata.utf8Lf.copyWith(hasFinalNewline: true),
              editorState: const DocumentEditorState(),
              revision: 2,
              ownerId: recoveryOwner,
            ),
          ],
        );
      final harness = await _harness(
        memory,
        sessionStore: sessions,
        recoveryStore: recovery,
      );

      expect(
        await harness.controller.restoreStartupSession(
          reopenCleanSession: false,
        ),
        isTrue,
      );
      final restored = harness.state.activeBuffer!;
      expect(restored.text, 'same recovery text\n');
      expect(restored.filePath, isNull);
      expect(restored.isDirty, isTrue);
      final snapshot = await memory.load();
      expect(
        snapshot.documents
            .singleWhere((document) => document.id == first.document.id)
            .deleted,
        isTrue,
      );
      expect(
        snapshot.documents
            .singleWhere((document) => document.id == second.document.id)
            .deleted,
        isTrue,
      );
    },
  );

  test(
    'Clear All durably removes a previously persisted path journal',
    () async {
      final source = p.join(root.path, 'clear-journal.md');
      final destination = p.join(root.path, 'clear-journal-moved.md');
      await File(source).writeAsString('clear journal lineage\n');
      final memory = MemoryLocalHistoryStore();
      final sessions = MemoryDocumentSessionStore();
      final harness = await _harness(memory, sessionStore: sessions);
      await harness.controller.openPath(source);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
      final targets = await history.preparePathReconciliation(
        source,
        recursive: false,
      );
      await history.stagePathRemap(source, destination, targets: targets);
      expect(sessions.value?.pendingLocalHistoryReconciliations, hasLength(1));

      await history.clearAll();

      expect(sessions.value?.pendingLocalHistoryReconciliations, isEmpty);
      expect(sessions.value?.retainedLocalHistoryCaptures, isEmpty);
      harness.container.dispose();
      final reopened = await _harness(memory, sessionStore: sessions);
      await reopened.controller.restoreStartupSession(
        reopenCleanSession: false,
      );
      final restoredHistory = reopened.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(restoredHistory.pendingPathReconciliations, isEmpty);
      expect((await memory.load()).documents, isEmpty);
    },
  );

  test(
    'startup applies committed destination cleanup before Save As recovery',
    () async {
      final destination = p.join(root.path, 'cleanup-before-save-as.md');
      await File(destination).writeAsString('published save as source\n');
      final memory = MemoryLocalHistoryStore();
      final stale = await _capture(
        memory,
        destination,
        'stale destination history\n',
      );
      final target = (await memory.resolvePathTargets(
        destination,
        recursive: false,
      )).single;
      final saveAsOperationId = 'history-save-as:$pid:123456789:1';
      final sessions = MemoryDocumentSessionStore()
        ..value = WorkspaceSessionSnapshot(
          workspacePath: null,
          tabs: const [],
          activeBufferId: null,
          pendingLocalHistorySaveAs: [
            LocalHistoryPendingSaveAs(
              operationId: saveAsOperationId,
              bufferId: 'restored-save-as',
              sourceDocumentId: null,
              destinationDocumentId: null,
              source: const LocalHistoryRetainedSnapshot(
                displayName: 'Untitled.md',
                source: 'published save as source\n',
                format: TextFormatMetadata.utf8Lf,
                revision: 1,
                untitled: true,
                captureId: 'source_capture_00000001',
              ),
              destination: LocalHistoryRetainedSnapshot(
                displayName: p.basename(destination),
                source: 'published save as source\n',
                format: TextFormatMetadata.utf8Lf,
                revision: 1,
                path: destination,
                captureId: 'destination_capture_0001',
              ),
              destinationExisted: false,
              phase: LocalHistoryPathReconciliationPhase.committed,
            ),
          ],
          pendingLocalHistoryReconciliations: [
            LocalHistoryPathReconciliation.deletion(
              operationId: 'lh${pid}_123456789_1-1',
              sourcePath: destination,
              recursive: false,
              targets: [target],
              commitEvidenceOperationId: saveAsOperationId,
              phase: LocalHistoryPathReconciliationPhase.committed,
            ),
          ],
        );
      final harness = await _harness(memory, sessionStore: sessions);

      await harness.controller.restorePreviousSession();
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(await history.flushAll(const []), isTrue);

      final snapshot = await memory.load();
      expect(
        snapshot.documents
            .singleWhere((document) => document.id == stale.document.id)
            .deleted,
        isTrue,
      );
      final live = snapshot.documents.singleWhere(
        (document) => !document.deleted && document.currentPath == destination,
      );
      expect(live.id, isNot(stale.document.id));
      expect(
        await _revisionSources(memory, snapshot.revisionsFor(live.id)),
        contains('published save as source\n'),
      );
      expect(history.pendingPathReconciliations, isEmpty);
      expect(history.pendingSaveAsOperations, isEmpty);
    },
  );

  test(
    'startup keeps untitled first-save source when another tab owns destination',
    () async {
      final destination = p.join(root.path, 'startup-first-save-owner.md');
      await File(destination).writeAsString('published first-save bytes\n');
      final memory = MemoryLocalHistoryStore();
      final sourceCapture = await memory.capture(
        LocalHistoryCaptureRequest(
          path: null,
          displayName: 'Untitled 1',
          source: 'published first-save bytes\n',
          format: TextFormatMetadata.utf8Lf,
          capturedAt: DateTime.utc(2026, 1, 1),
          reason: LocalHistoryCaptureReason.baseline,
          untitled: true,
        ),
        const LocalHistoryPolicy(),
      );
      const sourceBufferId = 'untitled:startup-first-save';
      const destinationBufferId = 'file:startup-first-save-owner';
      const recoveryOwner = 'startup-first-save-recovery';
      const operationId = 'history-save-as:12345:67890:startup';
      final operation = LocalHistoryPendingSaveAs(
        operationId: operationId,
        bufferId: sourceBufferId,
        sourceDocumentId: sourceCapture.document.id,
        destinationDocumentId: null,
        source: const LocalHistoryRetainedSnapshot(
          displayName: 'Untitled 1',
          source: 'published first-save bytes\n',
          format: TextFormatMetadata.utf8Lf,
          revision: 1,
          untitled: true,
          captureId: 'startup_first_save_source',
        ),
        destination: LocalHistoryRetainedSnapshot(
          displayName: p.basename(destination),
          source: 'published first-save bytes\n',
          format: TextFormatMetadata.utf8Lf,
          revision: 1,
          path: destination,
          captureId: 'startup_first_save_destination',
        ),
        destinationExisted: false,
        phase: LocalHistoryPathReconciliationPhase.committed,
        recoveryOwnerId: recoveryOwner,
        firstSaveLineageTransition: true,
      );
      final sessions = MemoryDocumentSessionStore()
        ..value = WorkspaceSessionSnapshot(
          workspacePath: destination,
          tabs: [
            DocumentSessionEntry(
              id: sourceBufferId,
              filePath: null,
              untitledName: 'Untitled 1',
              editorState: const DocumentEditorState(),
              localHistoryDocumentId: sourceCapture.document.id,
              pendingLocalHistorySaveAsOperationId: operationId,
              recoveryOwnerId: recoveryOwner,
            ),
            DocumentSessionEntry(
              id: destinationBufferId,
              filePath: destination,
              untitledName: null,
              editorState: const DocumentEditorState(),
            ),
          ],
          activeBufferId: destinationBufferId,
          pendingLocalHistorySaveAs: [operation],
        );
      final recovery = MemoryDocumentRecoveryStore()
        ..value = RecoverySnapshot(
          cleanShutdown: false,
          entries: [
            DocumentRecoveryEntry(
              id: sourceBufferId,
              workspacePath: null,
              filePath: null,
              untitledName: 'Untitled 1',
              text: 'later untitled recovery\n',
              lastSavedText: '',
              diskSnapshot: null,
              format: TextFormatMetadata.utf8Lf,
              editorState: const DocumentEditorState(),
              revision: 2,
              ownerId: recoveryOwner,
            ),
          ],
        );
      final harness = await _harness(
        memory,
        sessionStore: sessions,
        recoveryStore: recovery,
      );

      expect(
        await harness.controller.restoreStartupSession(
          reopenCleanSession: false,
        ),
        isTrue,
      );
      final untitled = harness.state.documentBuffers.singleWhere(
        (buffer) => buffer.text == 'later untitled recovery\n',
      );
      expect(untitled.filePath, isNull);
      expect(untitled.untitledName, 'Untitled 1');
      expect(
        harness.state.documentBuffers.where(
          (buffer) => buffer.filePath == destination,
        ),
        hasLength(1),
      );
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(await history.flushAll(harness.state.documentBuffers), isTrue);
      final snapshot = await memory.load();
      expect(
        snapshot.documents
            .singleWhere((document) => document.id == sourceCapture.document.id)
            .currentPath,
        isNull,
      );
      expect(
        snapshot.documents.where(
          (document) => document.currentPath == destination,
        ),
        hasLength(1),
      );
    },
  );

  test(
    'committed Save As recovery cannot claim another process tab with the same buffer id',
    () async {
      final source = p.join(root.path, 'shared-source.md');
      final destination = p.join(root.path, 'owner-a-destination.md');
      await File(source).writeAsString('shared disk\n');
      await File(destination).writeAsString('owner A saved\n');
      const sharedBufferId = 'file:shared-buffer-id';
      const ownerA = 'recovery-owner-a';
      const ownerB = 'recovery-owner-b';
      final operationId = 'history-save-as:$pid:123456789:91';
      final operation = LocalHistoryPendingSaveAs(
        operationId: operationId,
        bufferId: sharedBufferId,
        sourceDocumentId: null,
        destinationDocumentId: null,
        source: LocalHistoryRetainedSnapshot(
          displayName: p.basename(source),
          source: 'owner A saved\n',
          format: TextFormatMetadata.utf8Lf.copyWith(hasFinalNewline: true),
          revision: 2,
          path: source,
          captureId: 'owner_a_source_capture',
        ),
        destination: LocalHistoryRetainedSnapshot(
          displayName: p.basename(destination),
          source: 'owner A saved\n',
          format: TextFormatMetadata.utf8Lf.copyWith(hasFinalNewline: true),
          revision: 2,
          path: destination,
          captureId: 'owner_a_destination_capture',
        ),
        destinationExisted: false,
        phase: LocalHistoryPathReconciliationPhase.committed,
        recoveryOwnerId: ownerA,
      );
      final sessions = MemoryDocumentSessionStore()
        ..value = WorkspaceSessionSnapshot(
          workspacePath: source,
          tabs: [
            DocumentSessionEntry(
              id: sharedBufferId,
              filePath: source,
              untitledName: null,
              editorState: DocumentEditorState(),
              recoveryOwnerId: ownerB,
            ),
          ],
          activeBufferId: sharedBufferId,
          pendingLocalHistorySaveAs: [operation],
        );
      final recovery = MemoryDocumentRecoveryStore()
        ..value = RecoverySnapshot(
          cleanShutdown: false,
          entries: [
            DocumentRecoveryEntry(
              id: sharedBufferId,
              workspacePath: source,
              filePath: source,
              untitledName: null,
              text: 'owner A saved\n',
              lastSavedText: 'owner A before save\n',
              diskSnapshot: null,
              format: TextFormatMetadata.utf8Lf,
              editorState: const DocumentEditorState(),
              revision: 2,
              ownerId: ownerA,
            ),
            DocumentRecoveryEntry(
              id: sharedBufferId,
              workspacePath: source,
              filePath: source,
              untitledName: null,
              text: 'owner B dirty\n',
              lastSavedText: 'shared disk\n',
              diskSnapshot: null,
              format: TextFormatMetadata.utf8Lf,
              editorState: const DocumentEditorState(),
              revision: 7,
              ownerId: ownerB,
            ),
          ],
        );
      final memory = MemoryLocalHistoryStore();
      final harness = await _harness(
        memory,
        sessionStore: sessions,
        recoveryStore: recovery,
      );

      expect(
        await harness.controller.restoreStartupSession(
          reopenCleanSession: false,
        ),
        isTrue,
      );

      expect(
        harness.state.documentBuffers,
        hasLength(1),
        reason: harness.state.documentBuffers
            .map(
              (buffer) =>
                  '${buffer.id}|${buffer.filePath}|${buffer.text}|${buffer.lastSavedText}',
            )
            .join(' ; '),
      );
      expect(harness.state.activeBuffer?.id, sharedBufferId);
      expect(harness.state.activeBuffer?.filePath, source);
      expect(harness.state.activeBuffer?.text, 'owner B dirty\n');
      expect(sessions.value?.workspacePath, source);
      expect(
        sessions.value?.tabs.single.pendingLocalHistorySaveAsOperationId,
        isNull,
      );
      expect(sessions.value?.pendingLocalHistorySaveAs, isEmpty);
    },
  );

  test(
    'session restore selects recovery by process owner before shared buffer id',
    () async {
      final path = p.join(root.path, 'shared-recovery.md');
      await File(path).writeAsString('disk version\n');
      const sharedBufferId = 'file:shared-recovery';
      const ownerA = 'owner-a';
      const ownerB = 'owner-b';
      final sessions = MemoryDocumentSessionStore()
        ..value = WorkspaceSessionSnapshot(
          workspacePath: path,
          tabs: [
            DocumentSessionEntry(
              id: sharedBufferId,
              filePath: path,
              untitledName: null,
              editorState: const DocumentEditorState(),
              recoveryOwnerId: ownerA,
            ),
          ],
          activeBufferId: sharedBufferId,
        );
      final recovery = MemoryDocumentRecoveryStore()
        ..value = RecoverySnapshot(
          cleanShutdown: false,
          entries: [
            DocumentRecoveryEntry(
              id: sharedBufferId,
              workspacePath: path,
              filePath: path,
              untitledName: null,
              text: 'owner A dirty\n',
              lastSavedText: 'disk version\n',
              diskSnapshot: null,
              format: TextFormatMetadata.utf8Lf,
              editorState: const DocumentEditorState(),
              revision: 2,
              ownerId: ownerA,
            ),
            DocumentRecoveryEntry(
              id: sharedBufferId,
              workspacePath: path,
              filePath: path,
              untitledName: null,
              text: 'owner B dirty\n',
              lastSavedText: 'disk version\n',
              diskSnapshot: null,
              format: TextFormatMetadata.utf8Lf,
              editorState: const DocumentEditorState(),
              revision: 3,
              ownerId: ownerB,
            ),
          ],
        );
      final harness = await _harness(
        MemoryLocalHistoryStore(),
        sessionStore: sessions,
        recoveryStore: recovery,
      );

      expect(
        await harness.controller.restoreStartupSession(
          reopenCleanSession: false,
        ),
        isTrue,
      );

      expect(harness.state.documentBuffers, hasLength(2));
      expect(
        harness.state.documentBuffers
            .singleWhere((buffer) => buffer.id == sharedBufferId)
            .text,
        'owner A dirty\n',
      );
      expect(
        harness.state.documentBuffers
            .singleWhere((buffer) => buffer.id != sharedBufferId)
            .text,
        'owner B dirty\n',
      );
      expect(
        harness.state.documentBuffers
            .singleWhere((buffer) => buffer.id != sharedBufferId)
            .filePath,
        isNull,
      );
    },
  );

  test(
    'failed startup reconstruction releases adopted recovery ownership',
    () async {
      final path = p.join(root.path, 'transient-restore.md');
      await File(path).writeAsString('disk version\n');
      final recoveryFile = p.join(root.path, 'recovery.json');
      final previousRecovery = JsonDocumentRecoveryStore(
        filePathOverride: recoveryFile,
      );
      await previousRecovery.beginRun();
      const bufferId = 'file:transient-restore';
      await previousRecovery.writeEntries([
        DocumentRecoveryEntry(
          id: bufferId,
          workspacePath: path,
          filePath: path,
          untitledName: null,
          text: 'irreplaceable dirty recovery\n',
          lastSavedText: 'disk version\n',
          diskSnapshot: null,
          format: TextFormatMetadata.utf8Lf.copyWith(hasFinalNewline: true),
          editorState: const DocumentEditorState(),
          revision: 2,
          ownerId: previousRecovery.ownerId,
        ),
      ]);
      final sessions = MemoryDocumentSessionStore()
        ..value = WorkspaceSessionSnapshot(
          workspacePath: path,
          tabs: [
            DocumentSessionEntry(
              id: bufferId,
              filePath: path,
              untitledName: null,
              editorState: const DocumentEditorState(),
              recoveryOwnerId: previousRecovery.ownerId,
            ),
          ],
          activeBufferId: bufferId,
        );
      final recovery = JsonDocumentRecoveryStore(
        filePathOverride: recoveryFile,
      );
      final harness = await _harness(
        MemoryLocalHistoryStore(),
        service: _FailOnceOpenWorkspaceService(path),
        sessionStore: sessions,
        recoveryStore: recovery,
      );

      expect(
        await harness.controller.restoreStartupSession(
          reopenCleanSession: false,
        ),
        isFalse,
      );
      await harness.controller.createMarkdownFile();
      await harness.controller.flushPersistence();

      final fresh = JsonDocumentRecoveryStore(filePathOverride: recoveryFile);
      final snapshot = await fresh.beginRun();
      expect(
        snapshot.entries.map((entry) => entry.text),
        contains('irreplaceable dirty recovery\n'),
      );
    },
  );

  test(
    'history retry during slow failed startup cannot erase adopted recovery',
    () async {
      final path = p.join(root.path, 'slow-failed-restore.md');
      await File(path).writeAsString('disk version\n');
      final recoveryFile = p.join(root.path, 'slow-recovery.json');
      final previousRecovery = JsonDocumentRecoveryStore(
        filePathOverride: recoveryFile,
      );
      await previousRecovery.beginRun();
      const bufferId = 'file:slow-failed-restore';
      await previousRecovery.writeEntries([
        DocumentRecoveryEntry(
          id: bufferId,
          workspacePath: path,
          filePath: path,
          untitledName: null,
          text: 'dirty recovery must survive slow restore\n',
          lastSavedText: 'disk version\n',
          diskSnapshot: null,
          format: TextFormatMetadata.utf8Lf.copyWith(hasFinalNewline: true),
          editorState: const DocumentEditorState(),
          revision: 2,
          ownerId: previousRecovery.ownerId,
        ),
      ]);
      final sessions = MemoryDocumentSessionStore()
        ..value = WorkspaceSessionSnapshot(
          workspacePath: path,
          tabs: [
            DocumentSessionEntry(
              id: bufferId,
              filePath: path,
              untitledName: null,
              editorState: const DocumentEditorState(),
              recoveryOwnerId: previousRecovery.ownerId,
            ),
          ],
          activeBufferId: bufferId,
          retainedLocalHistoryCaptures: [
            LocalHistoryRetainedCapture(
              ownerId: 'history-capture:slow-restore-owner',
              pending: LocalHistoryRetainedSnapshot(
                displayName: 'slow-failed-restore.md',
                source: 'retained history retry\n',
                format: TextFormatMetadata.utf8Lf,
                revision: 1,
                path: path,
                captureId: 'slow_restore_capture_01',
              ),
            ),
          ],
        );
      final memory = MemoryLocalHistoryStore();
      final store = _ControllableHistoryStore(memory)
        ..capturesAvailable = false;
      final service = _BlockingFailOpenWorkspaceService(path);
      final timers = <_FakeTimer>[];
      final recovery = JsonDocumentRecoveryStore(
        filePathOverride: recoveryFile,
      );
      final harness = await _harness(
        store,
        service: service,
        sessionStore: sessions,
        recoveryStore: recovery,
        timerFactory: (delay, callback) {
          final timer = _FakeTimer(delay, callback);
          timers.add(timer);
          return timer;
        },
      );

      final restore = harness.controller.restoreStartupSession(
        reopenCleanSession: false,
      );
      await service.started.future;
      expect(timers.any((timer) => timer.isActive), isTrue);
      store.capturesAvailable = true;
      for (final timer in timers.where((timer) => timer.isActive).toList()) {
        timer.fire();
      }
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      await history.flushAll(const []);
      expect((await memory.load()).revisions, isNotEmpty);

      service.release.complete();
      expect(await restore, isFalse);
      final fresh = JsonDocumentRecoveryStore(filePathOverride: recoveryFile);
      final snapshot = await fresh.beginRun();
      expect(
        snapshot.entries.map((entry) => entry.text),
        contains('dirty recovery must survive slow restore\n'),
      );
    },
  );

  test(
    'session identity restore waits for the authoritative history snapshot',
    () async {
      final path = p.join(root.path, 'deleted-session-identity.md');
      final memory = MemoryLocalHistoryStore();
      final captured = await _capture(memory, path, 'historical source\n');
      await memory.markDeleted(path, recursive: false);
      final sessions = MemoryDocumentSessionStore()
        ..value = WorkspaceSessionSnapshot(
          workspacePath: path,
          tabs: [
            DocumentSessionEntry(
              id: 'file:deleted-session-identity',
              filePath: path,
              untitledName: null,
              editorState: const DocumentEditorState(),
              localHistoryDocumentId: captured.document.id,
            ),
          ],
          activeBufferId: 'file:deleted-session-identity',
        );
      final store = _BlockingHistoryLoadStore(memory);
      final harness = await _harness(
        store,
        sessionStore: sessions,
        recoveryStore: MemoryDocumentRecoveryStore(),
      );
      await store.started.future;

      var completed = false;
      final restore = harness.controller
          .restoreStartupSession(reopenCleanSession: true)
          .whenComplete(() => completed = true);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);

      store.release.complete();
      expect(await restore, isTrue);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(
        history.documentIdForBuffer(harness.state.activeBuffer!.id),
        captured.document.id,
      );
      expect(await history.flushAll(harness.state.documentBuffers), isTrue);
      final snapshot = await memory.load();
      expect(snapshot.documents, hasLength(1));
      expect(snapshot.documents.single.id, captured.document.id);
    },
  );

  test(
    'renamed adopted recovery still honors its original path-operation owner',
    () async {
      final deletedPath = p.join(root.path, 'deleted-owner-a.md');
      final livePath = p.join(root.path, 'live-owner-b.md');
      await File(livePath).writeAsString('owner B disk\n');
      const sharedId = 'file:shared-adoption';
      const ownerA = 'dead-owner-a';
      const ownerB = 'dead-owner-b';
      final operation = LocalHistoryPathReconciliation.deletion(
        operationId: 'lh${pid}_123456789_201',
        sourcePath: deletedPath,
        recursive: false,
        targets: const [],
        ownerIds: const [sharedId],
        phase: LocalHistoryPathReconciliationPhase.committed,
      );
      final sessions = MemoryDocumentSessionStore()
        ..value = WorkspaceSessionSnapshot(
          workspacePath: livePath,
          tabs: [
            DocumentSessionEntry(
              id: sharedId,
              filePath: livePath,
              untitledName: null,
              editorState: const DocumentEditorState(),
              recoveryOwnerId: ownerB,
            ),
          ],
          activeBufferId: sharedId,
          pendingLocalHistoryReconciliations: [operation],
        );
      final recovery = MemoryDocumentRecoveryStore()
        ..value = RecoverySnapshot(
          cleanShutdown: false,
          entries: [
            DocumentRecoveryEntry(
              id: sharedId,
              workspacePath: deletedPath,
              filePath: deletedPath,
              untitledName: null,
              text: 'owner A deleted recovery\n',
              lastSavedText: 'owner A disk\n',
              diskSnapshot: null,
              format: TextFormatMetadata.utf8Lf,
              editorState: const DocumentEditorState(),
              revision: 2,
              ownerId: ownerA,
            ),
            DocumentRecoveryEntry(
              id: sharedId,
              workspacePath: livePath,
              filePath: livePath,
              untitledName: null,
              text: 'owner B dirty\n',
              lastSavedText: 'owner B disk\n',
              diskSnapshot: null,
              format: TextFormatMetadata.utf8Lf,
              editorState: const DocumentEditorState(),
              revision: 3,
              ownerId: ownerB,
            ),
          ],
        );
      final harness = await _harness(
        MemoryLocalHistoryStore(),
        sessionStore: sessions,
        recoveryStore: recovery,
      );

      expect(
        await harness.controller.restoreStartupSession(
          reopenCleanSession: false,
        ),
        isTrue,
      );
      expect(harness.state.documentBuffers, hasLength(2));
      expect(harness.state.activeBuffer?.id, sharedId);
      expect(harness.state.activeBuffer?.filePath, livePath);
      expect(harness.state.activeBuffer?.text, 'owner B dirty\n');
      final deletedRecovery = harness.state.documentBuffers.singleWhere(
        (buffer) => buffer.text == 'owner A deleted recovery\n',
      );
      expect(deletedRecovery.filePath, isNull);
      expect(deletedRecovery.isDirty, isTrue);
      expect(deletedRecovery.id, isNot(sharedId));
    },
  );

  test('replayed durable Clear All preserves newer history', () async {
    const clearId = 'clear_operation_restart_001';
    final store = FileLocalHistoryStore(rootDirectory: () async => root);
    await _capture(store, '/workspace/old.md', 'old history\n');
    await store.clearAllOnce(operationId: clearId);
    final replacement = await _capture(
      store,
      '/workspace/replacement.md',
      'new history\n',
    );
    final sessions = MemoryDocumentSessionStore()
      ..value = const WorkspaceSessionSnapshot(
        workspacePath: null,
        tabs: [],
        activeBufferId: null,
        pendingLocalHistoryClears: [
          LocalHistoryPendingClear(operationId: clearId),
        ],
      );
    final harness = await _harness(store, sessionStore: sessions);

    await harness.controller.restorePreviousSession();

    final snapshot = await store.load();
    expect(snapshot.documents, hasLength(1));
    expect(snapshot.documents.single.id, replacement.document.id);
    expect(sessions.value?.pendingLocalHistoryClears, isEmpty);
  });

  test(
    'startup aborts until replayed clear refresh is authoritative',
    () async {
      final path = p.join(root.path, 'clear-refresh-startup.md');
      await File(path).writeAsString('disk after clear\n');
      final memory = MemoryLocalHistoryStore();
      final captured = await _capture(memory, path, 'old history\n');
      final pending = LocalHistoryPendingClear(
        operationId: 'clear_refresh_startup_001',
        documentId: captured.document.id,
      );
      final sessions = MemoryDocumentSessionStore()
        ..value = WorkspaceSessionSnapshot(
          workspacePath: path,
          tabs: [
            DocumentSessionEntry(
              id: 'file:clear-refresh-startup',
              filePath: path,
              untitledName: null,
              editorState: const DocumentEditorState(),
              localHistoryDocumentId: captured.document.id,
            ),
          ],
          activeBufferId: 'file:clear-refresh-startup',
          pendingLocalHistoryClears: [pending],
        );
      final store = _FailingPostClearRefreshStore(memory);
      final first = await _harness(store, sessionStore: sessions);

      expect(await first.controller.restorePreviousSession(), isFalse);
      expect(first.state.documentBuffers, isEmpty);
      expect(sessions.value?.pendingLocalHistoryClears, hasLength(1));
      first.container.dispose();

      final reopened = await _harness(store, sessionStore: sessions);
      expect(await reopened.controller.restorePreviousSession(), isTrue);
      final history = reopened.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(await history.flushAll(reopened.state.documentBuffers), isTrue);
      expect(
        history.documentIdForBuffer(reopened.state.activeBuffer!.id),
        isNot(captured.document.id),
      );
      final snapshot = await memory.load();
      expect(
        snapshot.documents.where(
          (document) => document.id == captured.document.id,
        ),
        isEmpty,
      );
      expect(sessions.value?.pendingLocalHistoryClears, isEmpty);
    },
  );

  test(
    'prepared deletion journal repairs a crash after filesystem commit',
    () async {
      final path = p.join(root.path, 'prepared-delete.md');
      await File(path).writeAsString('prepared deletion lineage\n');
      final memory = MemoryLocalHistoryStore();
      final store = _ControllableHistoryStore(memory)
        ..deletionsAvailable = false;
      final sessions = MemoryDocumentSessionStore();
      final recovery = MemoryDocumentRecoveryStore();
      final harness = await _harness(
        store,
        sessionStore: sessions,
        recoveryStore: recovery,
      );
      await harness.controller.openPath(root.path);
      expect(await harness.controller.openActiveFile(path), isTrue);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
      final originalId = history.documentIdForBuffer(
        harness.state.activeBuffer!.id,
      )!;
      final targets = await history.preparePathReconciliation(
        path,
        recursive: false,
      );
      final operationId = await history.stagePathDeletion(
        path,
        recursive: false,
        targets: targets,
      );
      await File(path).delete();
      await history.commitStagedPathOperation(operationId);
      harness.container.dispose();
      store.deletionsAvailable = true;

      final reopened = await _harness(
        store,
        sessionStore: sessions,
        recoveryStore: recovery,
      );
      await reopened.controller.restoreStartupSession(
        reopenCleanSession: false,
      );
      final snapshot = await memory.load();
      final deleted = snapshot.documents.singleWhere(
        (document) => document.id == originalId,
      );
      expect(deleted.deleted, isTrue);
      expect(deleted.currentPath, path);
      expect(
        snapshot.documents.where(
          (document) => !document.deleted && document.currentPath == path,
        ),
        isEmpty,
      );
    },
  );

  test(
    'failed deletion reconciliation survives shutdown and restart',
    () async {
      final path = p.join(root.path, 'deleted.md');
      await File(path).writeAsString('old deleted lineage\n');
      final memory = MemoryLocalHistoryStore();
      final store = _ControllableHistoryStore(memory)
        ..deletionsAvailable = false;
      final sessions = MemoryDocumentSessionStore();
      final recovery = MemoryDocumentRecoveryStore();
      final harness = await _harness(
        store,
        sessionStore: sessions,
        recoveryStore: recovery,
      );
      await harness.controller.openPath(root.path);
      expect(await harness.controller.openActiveFile(path), isTrue);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(await history.flushBuffer(harness.state.activeBuffer!), isTrue);
      final originalId = history.documentIdForBuffer(
        harness.state.activeBuffer!.id,
      )!;
      expect(await harness.controller.deleteWorkspaceEntity(path), isTrue);
      expect(await File(path).exists(), isFalse);
      await harness.controller.markCleanShutdown();
      expect(recovery.value.cleanShutdown, isFalse);
      expect(sessions.value?.pendingLocalHistoryReconciliations, hasLength(1));
      harness.container.dispose();

      store.deletionsAvailable = true;
      final reopened = await _harness(
        store,
        sessionStore: sessions,
        recoveryStore: recovery,
      );
      await reopened.controller.restoreStartupSession(
        reopenCleanSession: false,
      );
      var snapshot = await memory.load();
      final deleted = snapshot.documents.singleWhere(
        (document) => document.id == originalId,
      );
      expect(deleted.deleted, isTrue);

      await File(path).writeAsString('replacement lineage\n');
      if (reopened.state.workspace == null) {
        await reopened.controller.openPath(root.path);
      }
      expect(await reopened.controller.openActiveFile(path), isTrue);
      final restoredHistory = reopened.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(
        await restoredHistory.flushAll(reopened.state.documentBuffers),
        isTrue,
      );
      snapshot = await memory.load();
      final replacement = snapshot.documents.singleWhere(
        (document) => !document.deleted && document.currentPath == path,
      );
      expect(replacement.id, isNot(originalId));
      expect(
        await _revisionSources(memory, snapshot.revisionsFor(replacement.id)),
        contains('replacement lineage\n'),
      );
    },
  );

  test(
    'reopened tab adopts its unresolved first-save history association',
    () async {
      final memory = MemoryLocalHistoryStore();
      final store = _FailingFirstPromotionStore(memory, failures: 20);
      final harness = await _harness(store);
      await harness.controller.openPath(root.path);
      await harness.controller.createMarkdownFile();
      harness.controller.updateActiveText('Lineage before closing the tab\n');
      await Future<void>.delayed(Duration.zero);
      await harness.container
          .read(localHistoryControllerProvider.notifier)
          .flushBuffer(harness.state.activeBuffer!);
      final originalDocument = (await memory.load()).documents.single;
      final destination = p.join(root.path, 'A.md');
      expect(await harness.controller.saveActiveAs(destination), isTrue);
      final oldBufferId = harness.state.activeBuffer!.id;

      expect(await harness.controller.closeDocumentBuffer(oldBufferId), isTrue);
      final history = harness.container.read(
        localHistoryControllerProvider.notifier,
      );
      expect(history.pendingIdentityPromotions, hasLength(1));
      expect(
        history.pendingIdentityPromotions.single.bufferId,
        isNot(oldBufferId),
      );
      store.remainingPromotionFailures = 0;

      expect(await harness.controller.openActiveFile(destination), isTrue);
      final reopenedBuffer = harness.state.activeBuffer!;
      expect(reopenedBuffer.id, isNot(oldBufferId));
      await history.selectDocumentForBuffer(reopenedBuffer);
      expect(await history.flushAll(harness.state.documentBuffers), isTrue);

      final snapshot = await memory.load();
      expect(snapshot.documents, hasLength(1));
      expect(snapshot.documents.single.id, originalDocument.id);
      expect(snapshot.documents.single.currentPath, destination);
      expect(
        history.bufferIdForDocument(originalDocument.id),
        reopenedBuffer.id,
      );
      expect(history.pendingIdentityPromotions, isEmpty);
      expect(
        await _revisionSources(
          memory,
          snapshot.revisionsFor(originalDocument.id),
        ),
        contains('Lineage before closing the tab\n'),
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
      expect(sessions.value?.pendingLocalHistorySaveAs, isEmpty);
      expect(sessions.value?.retainedLocalHistoryCaptures, hasLength(1));
      harness.container.dispose();

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
      final beforePromotionRetry = await memory.load();
      expect(
        beforePromotionRetry.documents,
        hasLength(1),
        reason: beforePromotionRetry.documents
            .map(
              (document) =>
                  '${document.id}|${document.currentPath}|${document.deleted}|'
                  '${beforePromotionRetry.revisionsFor(document.id).map((revision) => '${revision.reason}:${revision.historicalPath}').join(',')}',
            )
            .join(' ; '),
      );
      expect(beforePromotionRetry.documents.single.currentPath, isNull);
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

Future<void> _waitFor(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 3),
  String operation = 'workspace state',
  String Function()? diagnostics,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('$operation did not complete. ${diagnostics?.call() ?? ''}');
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
  LocalHistoryClock? clock,
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
        clock ?? () => DateTime.utc(2026, 1, 1, 0, 1),
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

class _UnavailableCaptureStore extends MemoryLocalHistoryStore {
  var available = false;
  var protectiveAttempts = 0;
  @override
  Future<LocalHistoryCaptureResult> capture(
    LocalHistoryCaptureRequest request,
    LocalHistoryPolicy policy,
  ) async {
    if (request.force) protectiveAttempts++;
    if (!available) {
      throw const FileSystemException(
        'History temporarily unavailable',
        '',
        OSError('', 11),
      );
    }
    return super.capture(request, policy);
  }
}

class _ControllableHistoryStore extends _FailingProtectiveStore {
  _ControllableHistoryStore(super.delegate);

  var capturesAvailable = true;
  var remapsAvailable = true;
  var deletionsAvailable = true;
  String? failBeforeDiscardPath;

  @override
  Future<T> runPathReconciliation<T>({
    required LocalHistoryPathReconciliationKind kind,
    required String sourcePath,
    String? destinationPath,
    required bool recursive,
    Iterable<LocalHistoryPathTarget>? preparedTargets,
    required Future<T> Function(List<LocalHistoryPathTarget> targets) operation,
    required bool Function(T result) didCommit,
  }) async {
    final targets = List<LocalHistoryPathTarget>.unmodifiable(
      preparedTargets ??
          await delegate.resolvePathTargets(sourcePath, recursive: recursive),
    );
    final result = await operation(targets);
    if (!didCommit(result)) return result;
    if ((kind == LocalHistoryPathReconciliationKind.remap &&
            !remapsAvailable) ||
        (kind == LocalHistoryPathReconciliationKind.deletion &&
            !deletionsAvailable)) {
      throw LocalHistoryStorageException(
        kind == LocalHistoryPathReconciliationKind.remap
            ? 'Injected transient remap failure'
            : 'Injected transient deletion failure',
      );
    }
    await delegate.reconcilePath(switch (kind) {
      LocalHistoryPathReconciliationKind.remap =>
        LocalHistoryPathReconciliation.remap(
          sourcePath: sourcePath,
          destinationPath: destinationPath!,
          targets: targets,
        ),
      LocalHistoryPathReconciliationKind.deletion =>
        LocalHistoryPathReconciliation.deletion(
          sourcePath: sourcePath,
          recursive: recursive,
          targets: targets,
        ),
    });
    return result;
  }

  @override
  Future<void> reconcilePath(LocalHistoryPathReconciliation reconciliation) {
    if (reconciliation.kind == LocalHistoryPathReconciliationKind.remap &&
        !remapsAvailable) {
      throw const LocalHistoryStorageException(
        'Injected transient remap failure',
      );
    }
    if (reconciliation.kind == LocalHistoryPathReconciliationKind.deletion &&
        !deletionsAvailable) {
      throw const LocalHistoryStorageException(
        'Injected transient deletion failure',
      );
    }
    return delegate.reconcilePath(reconciliation);
  }

  @override
  Future<LocalHistoryCaptureResult> capture(
    LocalHistoryCaptureRequest request,
    LocalHistoryPolicy policy,
  ) {
    if (!capturesAvailable ||
        (request.reason == LocalHistoryCaptureReason.beforeDiscard &&
            request.path == failBeforeDiscardPath)) {
      throw const LocalHistoryStorageException(
        'Injected transient capture failure',
      );
    }
    return delegate.capture(request, policy);
  }

  @override
  Future<void> remapPath(String sourcePath, String destinationPath) {
    if (!remapsAvailable) {
      throw const LocalHistoryStorageException(
        'Injected transient remap failure',
      );
    }
    return delegate.remapPath(sourcePath, destinationPath);
  }

  @override
  Future<void> markDeleted(String path, {required bool recursive}) {
    if (!deletionsAvailable) {
      throw const LocalHistoryStorageException(
        'Injected transient deletion failure',
      );
    }
    return delegate.markDeleted(path, recursive: recursive);
  }
}

class _FailingPostClearRefreshStore extends _FailingProtectiveStore {
  _FailingPostClearRefreshStore(super.delegate);

  var _remainingRefreshFailures = 1;
  var _failNextLoad = false;

  @override
  Future<void> clearDocumentOnce({
    required String operationId,
    required String documentId,
  }) async {
    await delegate.clearDocumentOnce(
      operationId: operationId,
      documentId: documentId,
    );
    if (_remainingRefreshFailures > 0) _failNextLoad = true;
  }

  @override
  Future<LocalHistorySnapshot> load() {
    if (_failNextLoad) {
      _failNextLoad = false;
      _remainingRefreshFailures--;
      throw const LocalHistoryStorageException(
        'Injected post-clear startup refresh failure',
      );
    }
    return delegate.load();
  }
}

class _FailingExactSourceStore extends _FailingProtectiveStore {
  _FailingExactSourceStore(super.delegate, this.source);

  final String source;
  var failed = false;

  @override
  Future<LocalHistoryCaptureResult> capture(
    LocalHistoryCaptureRequest request,
    LocalHistoryPolicy policy,
  ) {
    if (!failed && request.source == source) {
      failed = true;
      throw const LocalHistoryStorageException(
        'Injected source checkpoint failure',
      );
    }
    return delegate.capture(request, policy);
  }
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
    LocalHistoryDocument? staleDestinationOwner,
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
      staleDestinationOwner: staleDestinationOwner,
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

class _BlockingHistoryLoadStore extends _FailingProtectiveStore {
  _BlockingHistoryLoadStore(super.delegate);

  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<LocalHistorySnapshot> load() async {
    if (!started.isCompleted) started.complete();
    await release.future;
    return delegate.load();
  }
}

class _FailOncePathLoadWorkspaceService extends WorkspaceService {
  _FailOncePathLoadWorkspaceService(this.targetPath);

  final String targetPath;
  var failedLoads = 0;

  @override
  Future<WorkspaceFileLoad> loadTextWithSnapshot(String path) {
    if (failedLoads == 0 && p.equals(path, targetPath)) {
      failedLoads++;
      throw const FormatException('Injected invalid UTF-8');
    }
    return super.loadTextWithSnapshot(path);
  }
}

class _FailFirstPathExistsWorkspaceService extends WorkspaceService {
  var _failed = false;

  @override
  Future<bool> pathExists(String path) {
    if (!_failed) {
      _failed = true;
      throw StateError('Injected transient path observation failure');
    }
    return super.pathExists(path);
  }
}

class _BlockingTargetLoadWorkspaceService extends WorkspaceService {
  _BlockingTargetLoadWorkspaceService(this.targetPath);

  final String targetPath;
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<WorkspaceFileLoad> loadTextWithSnapshot(String path) async {
    if (p.equals(path, targetPath)) {
      if (!started.isCompleted) started.complete();
      await release.future;
    }
    return super.loadTextWithSnapshot(path);
  }
}

class _BlockingReplacementOpenAndTargetLoadService extends WorkspaceService {
  _BlockingReplacementOpenAndTargetLoadService({
    required this.sourcePath,
    required this.targetPath,
  });

  final String sourcePath;
  final String targetPath;
  var blockNextSourceOpen = false;
  final sourceOpenStarted = Completer<void>();
  final releaseSourceOpen = Completer<void>();
  final targetLoadStarted = Completer<void>();
  final releaseTargetLoad = Completer<void>();

  @override
  Future<Workspace> openPath(String path) async {
    if (blockNextSourceOpen && p.equals(path, sourcePath)) {
      blockNextSourceOpen = false;
      sourceOpenStarted.complete();
      await releaseSourceOpen.future;
    }
    return super.openPath(path);
  }

  @override
  Future<WorkspaceFileLoad> loadTextWithSnapshot(String path) async {
    if (p.equals(path, targetPath)) {
      if (!targetLoadStarted.isCompleted) targetLoadStarted.complete();
      await releaseTargetLoad.future;
    }
    return super.loadTextWithSnapshot(path);
  }
}

class _BlockingFirstSaveOpenWorkspaceService extends WorkspaceService {
  _BlockingFirstSaveOpenWorkspaceService(this.targetPath);

  final String targetPath;
  final openStarted = Completer<void>();
  final release = Completer<void>();

  @override
  Future<Workspace> openPath(String path) async {
    if (p.equals(path, targetPath)) {
      if (!openStarted.isCompleted) openStarted.complete();
      await release.future;
    }
    return super.openPath(path);
  }
}

class _FailOnceOpenWorkspaceService extends WorkspaceService {
  _FailOnceOpenWorkspaceService(this.targetPath);

  final String targetPath;
  var _failed = false;

  @override
  Future<Workspace> openPath(String path) {
    if (!_failed && p.equals(path, targetPath)) {
      _failed = true;
      throw StateError('Injected transient workspace restore failure');
    }
    return super.openPath(path);
  }
}

class _BlockingFailOpenWorkspaceService extends WorkspaceService {
  _BlockingFailOpenWorkspaceService(this.targetPath);

  final String targetPath;
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<Workspace> openPath(String path) async {
    if (!p.equals(path, targetPath)) return super.openPath(path);
    if (!started.isCompleted) started.complete();
    await release.future;
    throw StateError('Injected delayed workspace restore failure');
  }
}

class _ExternallyOwnedJsonRecoveryStore extends JsonDocumentRecoveryStore {
  _ExternallyOwnedJsonRecoveryStore({
    required super.filePathOverride,
    required this.externallyLiveOwnerId,
  });

  final String externallyLiveOwnerId;

  @override
  bool ownerIsLiveOtherProcess(String? candidateOwnerId) =>
      candidateOwnerId == externallyLiveOwnerId ||
      super.ownerIsLiveOtherProcess(candidateOwnerId);
}

class _BlockingSaveAsCommitWorkspaceService extends WorkspaceService {
  _BlockingSaveAsCommitWorkspaceService(this.targetPath);

  final String targetPath;
  final committed = Completer<void>();
  final release = Completer<void>();

  @override
  Future<WorkspaceFileSnapshot> saveTextReplacingPathIfUnchanged(
    String path,
    String text, {
    required WorkspaceFileSnapshot expectedSnapshot,
    Future<void> Function()? onPublished,
  }) async {
    final snapshot = await super.saveTextReplacingPathIfUnchanged(
      path,
      text,
      expectedSnapshot: expectedSnapshot,
      onPublished: onPublished,
    );
    if (p.equals(path, targetPath)) {
      if (!committed.isCompleted) committed.complete();
      await release.future;
    }
    return snapshot;
  }
}

class _BlockingBeforeSaveAsCommitWorkspaceService extends WorkspaceService {
  _BlockingBeforeSaveAsCommitWorkspaceService(this.targetPath);

  final String targetPath;
  final writeStarted = Completer<void>();
  final release = Completer<void>();

  @override
  Future<WorkspaceFileSnapshot> saveTextReplacingPathIfUnchanged(
    String path,
    String text, {
    required WorkspaceFileSnapshot expectedSnapshot,
    Future<void> Function()? onPublished,
  }) async {
    if (p.equals(path, targetPath)) {
      if (!writeStarted.isCompleted) writeStarted.complete();
      await release.future;
    }
    return super.saveTextReplacingPathIfUnchanged(
      path,
      text,
      expectedSnapshot: expectedSnapshot,
      onPublished: onPublished,
    );
  }
}

class _FailAfterPublishedSaveAsWorkspaceService extends WorkspaceService {
  @override
  Future<WorkspaceFileSnapshot> saveTextReplacingPathIfUnchanged(
    String path,
    String text, {
    required WorkspaceFileSnapshot expectedSnapshot,
    Future<void> Function()? onPublished,
  }) => super.saveTextReplacingPathIfUnchanged(
    path,
    text,
    expectedSnapshot: expectedSnapshot,
    onPublished: () async {
      await onPublished?.call();
      throw StateError('Injected failure after file publication');
    },
  );
}

class _BlockingProtectiveStore extends _FailingProtectiveStore {
  _BlockingProtectiveStore(super.delegate);

  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<LocalHistoryCaptureResult> capture(
    LocalHistoryCaptureRequest request,
    LocalHistoryPolicy policy,
  ) async {
    if (request.reason == LocalHistoryCaptureReason.beforeRestore) {
      if (!started.isCompleted) started.complete();
      await release.future;
    }
    return delegate.capture(request, policy);
  }
}

class _RecordingRestoreWorkspaceService extends WorkspaceService {
  final writes = <String>[];

  @override
  Future<WorkspaceFileSnapshot> saveText(String path, String text) async {
    writes.add(text);
    return super.saveText(path, text);
  }

  @override
  Future<WorkspaceFileSnapshot> saveNewFormattedText(
    String path,
    String text, {
    TextFormatMetadata? format,
    LineEndingNormalization? mixedNormalization,
    Future<void> Function()? onPublished,
  }) async {
    writes.add(text);
    return super.saveNewFormattedText(
      path,
      text,
      format: format,
      mixedNormalization: mixedNormalization,
      onPublished: onPublished,
    );
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
  Future<Workspace> reparseDocument(
    Workspace workspace,
    DocumentBuffer buffer,
  ) async {
    final reparsed = await super.reparseDocument(workspace, buffer);
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
  Future<T> runPathReconciliation<T>({
    required LocalHistoryPathReconciliationKind kind,
    required String sourcePath,
    String? destinationPath,
    required bool recursive,
    Iterable<LocalHistoryPathTarget>? preparedTargets,
    required Future<T> Function(List<LocalHistoryPathTarget> targets) operation,
    required bool Function(T result) didCommit,
  }) async {
    if (kind == LocalHistoryPathReconciliationKind.remap) {
      if (!started.isCompleted) started.complete();
      await release.future;
    }
    return delegate.runPathReconciliation(
      kind: kind,
      sourcePath: sourcePath,
      destinationPath: destinationPath,
      recursive: recursive,
      preparedTargets: preparedTargets,
      operation: operation,
      didCommit: didCommit,
    );
  }

  @override
  Future<void> remapPath(String sourcePath, String destinationPath) async {
    if (!started.isCompleted) started.complete();
    await release.future;
    await delegate.remapPath(sourcePath, destinationPath);
  }

  @override
  Future<void> reconcilePath(
    LocalHistoryPathReconciliation reconciliation,
  ) async {
    if (reconciliation.kind == LocalHistoryPathReconciliationKind.remap) {
      if (!started.isCompleted) started.complete();
      await release.future;
    }
    await delegate.reconcilePath(reconciliation);
  }
}

class _BlockingPrePromotionCaptureStore extends _FailingProtectiveStore {
  _BlockingPrePromotionCaptureStore(
    super.delegate, {
    required this.failCapture,
  });

  final bool failCapture;
  var blockNextUntitledCheckpoint = false;
  var promotionAttempts = 0;
  final started = Completer<LocalHistoryCaptureRequest>();
  final release = Completer<void>();

  @override
  Future<LocalHistoryCaptureResult> capture(
    LocalHistoryCaptureRequest request,
    LocalHistoryPolicy policy,
  ) async {
    if (blockNextUntitledCheckpoint &&
        request.path == null &&
        request.reason == LocalHistoryCaptureReason.automaticCheckpoint) {
      blockNextUntitledCheckpoint = false;
      started.complete(request);
      await release.future;
      if (failCapture) {
        throw const LocalHistoryStorageException(
          'Injected pre-promotion capture failure',
        );
      }
    }
    return delegate.capture(request, policy);
  }

  @override
  Future<LocalHistoryDocument?> promoteUntitledDocument({
    required String documentId,
    required String destinationPath,
    required String displayName,
    required DateTime updatedAt,
    LocalHistoryDocument? staleDestinationOwner,
  }) {
    promotionAttempts++;
    return super.promoteUntitledDocument(
      documentId: documentId,
      destinationPath: destinationPath,
      displayName: displayName,
      updatedAt: updatedAt,
      staleDestinationOwner: staleDestinationOwner,
    );
  }
}

class _BlockingPathBaselineStore extends _FailingProtectiveStore {
  _BlockingPathBaselineStore(super.delegate, this.targetPath);

  final String targetPath;
  final started = Completer<void>();
  final release = Completer<void>();
  var _blocked = false;

  @override
  Future<LocalHistoryCaptureResult> capture(
    LocalHistoryCaptureRequest request,
    LocalHistoryPolicy policy,
  ) async {
    if (!_blocked &&
        request.reason == LocalHistoryCaptureReason.baseline &&
        request.path != null &&
        p.equals(request.path!, targetPath)) {
      _blocked = true;
      started.complete();
      await release.future;
    }
    return delegate.capture(request, policy);
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

class _BlockingRepeatedSaveAsSessionStore extends MemoryDocumentSessionStore {
  var _journalWrites = 0;
  final secondJournalWriteStarted = Completer<void>();
  final releaseSecondJournalWrite = Completer<void>();

  @override
  Future<void> save(WorkspaceSessionSnapshot snapshot) async {
    if (snapshot.pendingLocalHistorySaveAs.isNotEmpty) {
      _journalWrites++;
      if (_journalWrites == 2) {
        secondJournalWriteStarted.complete();
        await releaseSecondJournalWrite.future;
      }
    }
    await super.save(snapshot);
  }
}

class _BlockingFailingCommittedSaveAsSessionStore
    extends MemoryDocumentSessionStore {
  final committedWriteStarted = Completer<void>();
  final releaseCommittedWrite = Completer<void>();
  var _failedCommittedWrite = false;
  var commitFallbacks = 0;

  @override
  Future<void> save(WorkspaceSessionSnapshot snapshot) async {
    if (!_failedCommittedWrite &&
        snapshot.pendingLocalHistorySaveAs.any(
          (operation) =>
              operation.phase == LocalHistoryPathReconciliationPhase.committed,
        )) {
      _failedCommittedWrite = true;
      committedWriteStarted.complete();
      await releaseCommittedWrite.future;
      throw StateError('Injected committed Save As journal failure');
    }
    await super.save(snapshot);
  }

  @override
  Future<bool> markPendingLocalHistorySaveAsCommitted(
    String operationId,
  ) async {
    commitFallbacks++;
    return super.markPendingLocalHistorySaveAsCommitted(operationId);
  }
}

class _BlockingPreparedPathSessionStore extends MemoryDocumentSessionStore {
  var blockNextPreparedPathWrite = false;
  final preparedWriteStarted = Completer<void>();
  final releasePreparedWrite = Completer<void>();

  @override
  Future<void> save(WorkspaceSessionSnapshot snapshot) async {
    if (blockNextPreparedPathWrite &&
        snapshot.pendingLocalHistoryReconciliations.any(
          (operation) =>
              operation.phase == LocalHistoryPathReconciliationPhase.prepared,
        )) {
      blockNextPreparedPathWrite = false;
      if (!preparedWriteStarted.isCompleted) preparedWriteStarted.complete();
      await releasePreparedWrite.future;
    }
    await super.save(snapshot);
  }
}

class _BlockAfterRenameWorkspaceService extends WorkspaceService {
  final renamed = Completer<void>();
  final release = Completer<void>();

  @override
  Future<String> renameEntity(
    Workspace workspace,
    String sourcePath,
    String newName,
  ) async {
    final result = await super.renameEntity(workspace, sourcePath, newName);
    if (!renamed.isCompleted) renamed.complete();
    await release.future;
    return result;
  }
}

class _BlockBeforeSaveAsPublishWorkspaceService extends WorkspaceService {
  final entered = Completer<void>();
  final release = Completer<void>();

  @override
  Future<WorkspaceFileSnapshot> saveTextReplacingPathIfUnchanged(
    String path,
    String text, {
    required WorkspaceFileSnapshot expectedSnapshot,
    Future<void> Function()? onPublished,
  }) async {
    entered.complete();
    await release.future;
    return super.saveTextReplacingPathIfUnchanged(
      path,
      text,
      expectedSnapshot: expectedSnapshot,
      onPublished: onPublished,
    );
  }
}

class _ControlledFileMonitor extends WorkspaceFileMonitor {
  final _events = StreamController<WorkspaceFileMonitorEvent>.broadcast();

  @override
  Stream<WorkspaceFileMonitorEvent> get events => _events.stream;

  void emitMove(
    String sourcePath,
    String destinationPath, {
    bool isDirectory = false,
  }) {
    _events.add(
      WorkspaceFileMonitorEvent(
        kind: WorkspaceFileEventKind.moved,
        path: sourcePath,
        destinationPath: destinationPath,
        isDirectory: isDirectory,
      ),
    );
  }

  void emitDeletion(String path, {bool isDirectory = false}) {
    _events.add(
      WorkspaceFileMonitorEvent(
        kind: WorkspaceFileEventKind.deleted,
        path: path,
        isDirectory: isDirectory,
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

class _FailingStopFileMonitor extends _ControlledFileMonitor {
  var failNextStop = false;
  var startAttempts = 0;

  @override
  Future<void> start({
    required String rootPath,
    required Iterable<String> openFilePaths,
  }) async {
    startAttempts++;
  }

  @override
  Future<void> stop() async {
    if (failNextStop) {
      failNextStop = false;
      throw const FileSystemException('Injected monitor stop failure');
    }
  }
}

class _BlockingStartFileMonitor extends _ControlledFileMonitor {
  var startStarted = Completer<void>();
  var releaseStart = Completer<void>();
  var _blockNextStart = true;

  void blockNextStart() {
    _blockNextStart = true;
    startStarted = Completer<void>();
    releaseStart = Completer<void>();
  }

  @override
  Future<void> start({
    required String rootPath,
    required Iterable<String> openFilePaths,
  }) async {
    if (!_blockNextStart) return;
    _blockNextStart = false;
    startStarted.complete();
    await releaseStart.future;
  }
}

class _DisposeDuringStartFileMonitor extends WorkspaceFileMonitor {
  final firstStopStarted = Completer<void>();
  final releaseFirstStop = Completer<void>();
  var _stopCount = 0;

  @override
  Future<void> stop() async {
    _stopCount++;
    if (_stopCount == 1) {
      firstStopStarted.complete();
      await releaseFirstStop.future;
    }
    await super.stop();
  }
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
  Future<WorkspaceFileSnapshot> saveTextIfUnchanged(
    String path,
    String text, {
    required WorkspaceFileSnapshot expectedSnapshot,
  }) async {
    started.complete();
    await _release.future;
    return super.saveTextIfUnchanged(
      path,
      text,
      expectedSnapshot: expectedSnapshot,
    );
  }
}
