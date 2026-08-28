import 'dart:convert';
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

  test('session store keeps only tab identity and editor state', () async {
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
    final persisted =
        jsonDecode(
              await File(p.join(directory.path, 'session.json')).readAsString(),
            )
            as Map<String, Object?>;
    final firstTab = ((persisted['tabs'] as List).first as Map)
        .cast<String, Object?>();
    expect(firstTab, isNot(contains('lastKnownText')));
    expect(firstTab, isNot(contains('diskSnapshot')));
    expect(firstTab, isNot(contains('format')));
    expect(
      await File(p.join(directory.path, 'session.json')).readAsString(),
      isNot(contains('# First')),
    );
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
