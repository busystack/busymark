import 'package:busymark/src/local_history/local_history_models.dart';
import 'package:busymark/src/local_history/local_history_store.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:busymark/src/workspace/session_persistence.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const reference = NextcloudNoteReference(
    accountId: 'account',
    localId: 'note',
  );

  test('remote identity is independent of paths, title and publication', () {
    final remote = DocumentBuffer.nextcloud(
      reference: reference,
      title: 'Title',
      content: '# Note',
      revision: 10,
    );
    expect(remote.origin, DocumentOrigin.nextcloudNote);
    expect(remote.filePath, isNull);
    expect(remote.isUntitled, isFalse);
    expect(remote.isDirty, isFalse);
    expect(remote.copyWith(remoteTitle: 'Renamed').identity, remote.identity);
    final edited = remote.edited('# Offline edit');
    expect(edited.revision, 11);
    expect(edited.isDirty, isTrue);
    expect(edited.lastSavedText, '# Note');
    expect(edited.remoteNote, reference);
    expect(
      DocumentBuffer.untitled(id: 'draft', name: 'Untitled').isUntitled,
      isTrue,
    );
  });

  test('remote context stays Markdown and has no disk root or disk path', () {
    final workspace = Workspace.nextcloudNotes(reference.accountId);
    final buffer = DocumentBuffer.nextcloud(
      reference: reference,
      title: 'Note',
      content: 'Text',
    );
    final context = resolveWorkspaceDocumentContext(workspace, buffer);
    expect(workspace.filesystemRootPath, isNull);
    expect(() => workspace.rootPath, throwsStateError);
    expect(workspace.copyWith().nextcloudAccountId, reference.accountId);
    expect(context.diskPath, isNull);
    expect(context.kind, DocumentKind.markdown);
    expect(context.remoteNote, reference);
    expect(
      buffer
          .edited('blocked')
          .copyWith(readonly: true)
          .edited('forbidden')
          .text,
      'blocked',
    );
  });

  test(
    'session v2 stores remote identity and editor state without content',
    () {
      final session = WorkspaceSessionSnapshot(
        workspacePath: null,
        nextcloudAccountId: reference.accountId,
        activeBufferId: reference.identity,
        tabs: [
          DocumentSessionEntry(
            id: reference.identity,
            filePath: null,
            untitledName: null,
            remoteNote: reference,
            editorState: const DocumentEditorState(scrollOffset: 42),
          ),
        ],
      );
      final json = session.toJson();
      expect(json['version'], 2);
      expect(json.toString(), isNot(contains('content')));
      final restored = WorkspaceSessionSnapshot.fromJson(json);
      expect(restored.nextcloudAccountId, reference.accountId);
      expect(restored.tabs.single.remoteNote, reference);
      expect(restored.tabs.single.editorState.scrollOffset, 42);
      final legacy = WorkspaceSessionSnapshot.fromJson({
        'version': 1,
        'workspacePath': '/old',
        'activeBufferId': 'local',
        'tabs': [
          {
            'id': 'local',
            'filePath': '/old/note.md',
            'editorState': <String, Object?>{},
          },
        ],
      });
      expect(legacy.nextcloudAccountId, isNull);
      expect(legacy.tabs.single.filePath, '/old/note.md');
      expect(legacy.tabs.single.remoteNote, isNull);
    },
  );

  test(
    'remote history binds reopened and renamed notes to one logical document',
    () async {
      final store = MemoryLocalHistoryStore();
      final buffer = DocumentBuffer.nextcloud(
        reference: reference,
        title: 'First',
        content: 'Initial',
      );
      LocalHistoryCaptureRequest request(DocumentBuffer value) =>
          LocalHistoryCaptureRequest(
            remoteNote: value.remoteNote,
            displayName: value.displayName,
            source: value.text,
            format: value.format,
            capturedAt: DateTime.utc(2026, 10, 4),
            reason: LocalHistoryCaptureReason.saved,
          );
      final first = await store.capture(
        request(buffer),
        const LocalHistoryPolicy(),
      );
      final renamed = await store.capture(
        request(buffer.copyWith(remoteTitle: 'Renamed', text: 'New')),
        const LocalHistoryPolicy(),
      );
      expect(first.document.id, renamed.document.id);
      expect((await store.load()).documents, hasLength(1));
      expect(renamed.document.currentPath, isNull);
      expect(renamed.document.historicalPaths, isEmpty);
      expect(renamed.document.remoteNote, reference);
      expect(
        LocalHistoryDocument.fromJson(renamed.document.toJson()).remoteNote,
        reference,
      );
    },
  );
}
