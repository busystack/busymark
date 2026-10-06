import 'dart:convert';
import 'dart:io';

import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/local_history/local_history_models.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:busymark/src/workspace/recovery_persistence.dart';
import 'package:busymark/src/workspace/session_persistence.dart';
import 'package:busymark/src/workspace/text_format_metadata.dart';
import 'package:busymark/src/workspace/workspace_file_snapshot.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('file-backed edits update final-newline metadata', () {
    final buffer = DocumentBuffer.file(
      id: 'file:note',
      filePath: '/workspace/note.md',
      text: 'Saved\n',
      snapshot: WorkspaceFileSnapshot(
        modifiedAt: DateTime.utc(2026),
        size: 6,
        contentHash: 'saved',
      ),
      format: const TextFormatMetadata(
        hasUtf8Bom: false,
        lineEnding: DocumentLineEnding.lf,
        hasFinalNewline: true,
      ),
    );

    final removed = buffer.edited('Saved');
    final restored = removed.edited('Saved\n');

    expect(removed.format.hasFinalNewline, isFalse);
    expect(removed.format.formattedText(removed.text), 'Saved');
    expect(restored.format.hasFinalNewline, isTrue);
    expect(restored.format.formattedText(restored.text), 'Saved\n');
  });

  test(
    'session store keeps tab state and pending history identity without text',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-session-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final store = JsonDocumentSessionStore(
        filePathOverride: p.join(directory.path, 'session.json'),
      );
      final snapshot = WorkspaceSessionSnapshot(
        workspacePath: '/workspace',
        activeBufferId: 'second',
        tabs: [
          DocumentSessionEntry(
            id: 'first',
            filePath: '/workspace/first.md',
            untitledName: null,
            editorState: const DocumentEditorState(
              mode: DocumentViewModePreference.split,
              selection: TextSelection(baseOffset: 2, extentOffset: 8),
              scrollOffset: 42,
              foldedRegionKeys: {'heading:2'},
            ),
          ),
          const DocumentSessionEntry(
            id: 'second',
            filePath: null,
            untitledName: 'Untitled 2',
            editorState: DocumentEditorState(),
          ),
        ],
        pendingLocalHistoryAssociations: const [
          PendingLocalHistoryAssociation(
            bufferId: 'first',
            documentId: 'history-document',
            destinationPath: '/workspace/first.md',
            displayName: 'first.md',
          ),
        ],
        pendingLocalHistoryClears: const [
          LocalHistoryPendingClear(
            operationId: 'history-clear-pending',
            documentId: 'history-document',
          ),
        ],
        pendingLocalHistoryReconciliations: const [
          LocalHistoryPathReconciliation.remap(
            operationId: 'prepared-remap',
            sourcePath: '/workspace/old.md',
            destinationPath: '/workspace/new.md',
            phase: LocalHistoryPathReconciliationPhase.prepared,
            targets: [
              LocalHistoryPathTarget(
                documentId: 'history-document',
                expectedPath: '/workspace/old.md',
                versionToken: 'old-version',
              ),
            ],
          ),
          LocalHistoryPathReconciliation.deletion(
            sourcePath: '/workspace/removed',
            recursive: true,
            targets: [
              LocalHistoryPathTarget(
                documentId: 'nested-history-document',
                expectedPath: '/workspace/removed/nested.md',
                versionToken: 'nested-version',
              ),
            ],
          ),
        ],
        retainedLocalHistoryCaptures: const [
          LocalHistoryRetainedCapture(
            ownerId: 'history-capture:first:1',
            documentId: 'history-document',
            pending: LocalHistoryRetainedSnapshot(
              displayName: 'old.md',
              source: 'retained source',
              format: TextFormatMetadata.utf8Lf,
              revision: 7,
              path: '/workspace/old.md',
            ),
          ),
          LocalHistoryRetainedCapture(
            ownerId: 'history-promotion:history-document',
            documentId: 'history-document',
            pending: LocalHistoryRetainedSnapshot(
              displayName: 'first.md',
              source: 'retained promotion source',
              format: TextFormatMetadata.utf8Lf,
              revision: 8,
              path: '/workspace/first.md',
            ),
          ),
        ],
      );

      await store.save(snapshot);
      final restored = await store.load();

      expect(restored?.workspacePath, '/workspace');
      expect(restored?.activeBufferId, 'second');
      expect(restored?.tabs.map((entry) => entry.id), ['first', 'second']);
      expect(
        restored?.pendingLocalHistoryAssociations.single.documentId,
        'history-document',
      );
      expect(restored?.pendingLocalHistoryReconciliations, hasLength(2));
      expect(
        restored?.pendingLocalHistoryClears.single.documentId,
        'history-document',
      );
      expect(
        restored?.pendingLocalHistoryReconciliations.first.phase,
        LocalHistoryPathReconciliationPhase.prepared,
      );
      expect(
        restored?.pendingLocalHistoryReconciliations.first.operationId,
        'prepared-remap',
      );
      expect(restored?.retainedLocalHistoryCaptures, hasLength(2));
      expect(
        restored?.retainedLocalHistoryCaptures.first.pending?.source,
        'retained source',
      );
      expect(
        restored?.retainedLocalHistoryCaptures.last.ownerId,
        'history-promotion:history-document',
      );
      expect(restored?.pendingLocalHistoryReconciliations.first.documentIds, [
        'history-document',
      ]);
      expect(
        restored?.pendingLocalHistoryReconciliations.last.recursive,
        isTrue,
      );
      expect(
        restored?.tabs.first.editorState.mode,
        DocumentViewModePreference.split,
      );
      expect(
        restored?.tabs.first.editorState.selection,
        const TextSelection(baseOffset: 2, extentOffset: 8),
      );
      expect(restored?.tabs.first.editorState.scrollOffset, 42);
      expect(restored?.tabs.first.editorState.foldedRegionKeys, {'heading:2'});
      final persisted =
          jsonDecode(
                await File(
                  p.join(directory.path, 'session.json'),
                ).readAsString(),
              )
              as Map<String, Object?>;
      final firstTab = ((persisted['tabs'] as List).first as Map)
          .cast<String, Object?>();
      expect(firstTab, isNot(contains('lastKnownText')));
      expect(firstTab, isNot(contains('diskSnapshot')));
      expect(firstTab, isNot(contains('format')));
      expect(firstTab, isNot(contains('searchCurrentMatchIndex')));
      expect(
        await File(p.join(directory.path, 'session.json')).readAsString(),
        isNot(contains('# First')),
      );
    },
  );

  test(
    'session merge keys first-save promotions by durable operation owner',
    () async {
      final store = MemoryDocumentSessionStore();
      const first = PendingLocalHistoryAssociation(
        bufferId: 'shared-buffer',
        documentId: 'document-a',
        destinationPath: '/workspace/A.md',
        displayName: 'A.md',
        operationOwnerId: 'history-promotion:owner-a:1',
      );
      const second = PendingLocalHistoryAssociation(
        bufferId: 'shared-buffer',
        documentId: 'document-b',
        destinationPath: '/workspace/B.md',
        displayName: 'B.md',
        operationOwnerId: 'history-promotion:owner-b:1',
      );
      await store.save(
        const WorkspaceSessionSnapshot(
          workspacePath: null,
          tabs: [],
          activeBufferId: null,
          pendingLocalHistoryAssociations: [first],
        ),
      );
      await store.save(
        const WorkspaceSessionSnapshot(
          workspacePath: null,
          tabs: [],
          activeBufferId: null,
          pendingLocalHistoryAssociations: [second],
        ),
      );

      expect(
        store.value?.pendingLocalHistoryAssociations
            .map((association) => association.operationOwnerId)
            .toSet(),
        {first.operationOwnerId, second.operationOwnerId},
      );

      await store.save(
        const WorkspaceSessionSnapshot(
          workspacePath: null,
          tabs: [],
          activeBufferId: null,
          retiredLocalHistoryWorkOwnerIds: ['history-promotion:owner-a:1'],
        ),
      );
      expect(store.value?.pendingLocalHistoryAssociations, [second]);
    },
  );

  test('recovery store distinguishes clean and unclean runs', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-recovery-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final path = p.join(directory.path, 'recovery.json');
    final store = JsonDocumentRecoveryStore(filePathOverride: path);
    final buffer = DocumentBuffer(
      id: 'file:note',
      filePath: '/workspace/note.md',
      text: '# Unsaved\n',
      lastSavedText: '# Saved\n',
      dirty: true,
      diskSnapshot: WorkspaceFileSnapshot(
        modifiedAt: DateTime.utc(2026),
        size: 8,
        contentHash: 'saved',
      ),
      format: const TextFormatMetadata(
        hasUtf8Bom: true,
        lineEnding: DocumentLineEnding.crlf,
        hasFinalNewline: true,
      ),
    );

    expect((await store.beginRun()).cleanShutdown, isTrue);
    await store.writeEntries([
      DocumentRecoveryEntry.fromBuffer(buffer, workspacePath: '/workspace'),
    ]);

    final afterCrash = JsonDocumentRecoveryStore(filePathOverride: path);
    final recovered = await afterCrash.beginRun();
    expect(recovered.cleanShutdown, isFalse);
    expect(recovered.entries.single.text, '# Unsaved\n');
    expect(recovered.entries.single.diskSnapshot?.contentHash, 'saved');
    expect(recovered.entries.single.format.hasUtf8Bom, isTrue);

    await afterCrash.markCleanShutdown();
    final normalStart = JsonDocumentRecoveryStore(filePathOverride: path);
    final cleanRecovery = await normalStart.beginRun();
    expect(cleanRecovery.cleanShutdown, isTrue);
    expect(cleanRecovery.entries.single.text, '# Unsaved\n');
  });

  test(
    'recovery keeps valid entries when another record is malformed',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-recovery-partial-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final path = p.join(directory.path, 'recovery.json');
      final store = JsonDocumentRecoveryStore(filePathOverride: path);
      final buffer = DocumentBuffer.untitled(
        id: 'untitled:1',
        name: 'Untitled 1',
        text: 'Keep me',
      );
      await store.writeEntries([
        DocumentRecoveryEntry.fromBuffer(buffer, workspacePath: null),
      ]);
      final decoded = jsonDecode(await File(path).readAsString()) as Map;
      (decoded['entries'] as List).add({'id': 'broken', 'text': 42});
      await File(path).writeAsString(jsonEncode(decoded));

      final recovered = await store.beginRun();

      expect(recovered.entries.single.id, 'untitled:1');
      expect(recovered.entries.single.text, 'Keep me');
      expect(recovered.readErrors, 1);
    },
  );

  test(
    'recovery ownership keeps same buffer IDs isolated by process',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-recovery-owners-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final path = p.join(directory.path, 'recovery.json');
      final first = JsonDocumentRecoveryStore(filePathOverride: path);
      final second = JsonDocumentRecoveryStore(filePathOverride: path);
      final firstBuffer = DocumentBuffer.untitled(
        id: 'untitled:shared',
        name: 'First',
        text: 'first process',
      );
      final secondBuffer = DocumentBuffer.untitled(
        id: 'untitled:shared',
        name: 'Second',
        text: 'second process',
      );

      await first.writeEntries([
        DocumentRecoveryEntry.fromBuffer(firstBuffer, workspacePath: null),
      ]);
      await second.writeEntries([
        DocumentRecoveryEntry.fromBuffer(secondBuffer, workspacePath: null),
      ]);
      var recovered = await JsonDocumentRecoveryStore(
        filePathOverride: path,
      ).beginRun();
      expect(recovered.entries.map((entry) => entry.text).toSet(), {
        'first process',
        'second process',
      });
      expect(
        recovered.entries.map((entry) => entry.ownerId).toSet(),
        hasLength(2),
      );

      // A subsequent write by the second process owns only its entry. It must
      // not claim and then remove the first process's recovery record merely
      // because both were present in an earlier merged read/write.
      await second.writeEntries([
        DocumentRecoveryEntry.fromBuffer(
          secondBuffer.edited('second process updated'),
          workspacePath: null,
        ),
      ]);
      recovered = await JsonDocumentRecoveryStore(
        filePathOverride: path,
      ).beginRun();
      expect(recovered.entries.map((entry) => entry.text).toSet(), {
        'first process',
        'second process updated',
      });

      await first.writeEntries(const []);
      recovered = await JsonDocumentRecoveryStore(
        filePathOverride: path,
      ).beginRun();
      expect(recovered.entries.map((entry) => entry.text), [
        'second process updated',
      ]);
    },
  );

  test('restored dead-owner recovery is adopted and can be retired', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-recovery-adoption-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final path = p.join(directory.path, 'recovery.json');
    final crashed = JsonDocumentRecoveryStore(filePathOverride: path);
    final buffer = DocumentBuffer.untitled(
      id: 'untitled:adopted',
      name: 'Recovered',
      text: 'unsaved work',
    );
    await crashed.writeEntries([
      DocumentRecoveryEntry.fromBuffer(buffer, workspacePath: null),
    ]);

    final restarted = JsonDocumentRecoveryStore(filePathOverride: path);
    final previous = await restarted.beginRun();
    final adopted = await restarted.adoptEntries(previous.entries);
    expect(adopted, hasLength(1));
    expect(adopted.single.sourceOwnerId, crashed.ownerId);
    expect(adopted.single.entry.ownerId, restarted.ownerId);

    await restarted.writeEntries([adopted.single.entry]);
    await restarted.writeEntries(const []);
    final nextRun = JsonDocumentRecoveryStore(filePathOverride: path);
    expect((await nextRun.beginRun()).entries, isEmpty);
  });

  test('recovery state is written with private POSIX permissions', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-recovery-permissions-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final path = p.join(directory.path, 'recovery.json');
    final store = JsonDocumentRecoveryStore(filePathOverride: path);

    await store.writeEntries(const []);

    expect((await File(path).stat()).mode & 0x1ff, 0x180);
    expect((await directory.stat()).mode & 0x1ff, 0x1c0);
  }, skip: Platform.isWindows ? 'POSIX permissions only.' : false);
}
