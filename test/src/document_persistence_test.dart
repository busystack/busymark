import 'dart:io';

import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:busymark/src/workspace/recovery_persistence.dart';
import 'package:busymark/src/workspace/session_persistence.dart';
import 'package:busymark/src/workspace/text_format_metadata.dart';
import 'package:busymark/src/workspace/workspace_file_snapshot.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('session store round-trips ordered tabs and editor state', () async {
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
    );

    await store.save(snapshot);
    final restored = await store.load();

    expect(restored?.workspacePath, '/workspace');
    expect(restored?.activeBufferId, 'second');
    expect(restored?.tabs.map((entry) => entry.id), ['first', 'second']);
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
  });

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
    expect((await normalStart.beginRun()).cleanShutdown, isTrue);
  });
}
