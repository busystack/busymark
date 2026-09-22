import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  DocumentBuffer untitled(String id) =>
      DocumentBuffer.untitled(id: id, name: id);

  Workspace workspace(WorkspaceKind kind) => Workspace(
    id: 'workspace:${kind.name}',
    rootPath: '/workspace',
    kind: kind,
    openedAt: DateTime(2026),
    files: const [],
    diagnostics: const [],
  );

  for (final kind in WorkspaceKind.values) {
    test('untitled buffer is CommonMark in ${kind.name}', () {
      final resolved = resolveWorkspaceDocumentContext(
        workspace(kind),
        untitled('untitled:${kind.name}'),
      );

      expect(resolved.kind, DocumentKind.markdown);
      expect(resolved.markdownMode, MarkdownMode.commonMark);
      expect(resolved.diskPath, isNull);
      expect(resolved.parserPath, isEmpty);
    });
  }

  group('Writerside document resolution', () {
    late Workspace writerside;

    setUpAll(() async {
      writerside = await const WorkspaceService().openPath(
        'test/fixtures/writerside/basic_project',
      );
    });

    test('discovered Markdown topic wins over generic file inventory', () {
      final topic = writerside.writersideModule!.topics.singleWhere(
        (topic) => topic.filePath.endsWith('intro.md'),
      );
      final inventory = writerside.files.singleWhere(
        (file) => p.equals(file.absolutePath, topic.filePath),
      );
      final buffer = DocumentBuffer(
        id: 'intro',
        filePath: topic.filePath,
        text: topic.document.source,
        lastSavedText: topic.document.source,
        dirty: false,
      );

      expect(inventory.kind, DocumentKind.markdown);
      final resolved = resolveWorkspaceDocumentContext(writerside, buffer);
      expect(resolved.kind, DocumentKind.writersideMarkdownTopic);
      expect(resolved.markdownMode, MarkdownMode.writersideMarkdown);
      expect(resolved.writersideTopic, same(topic));
    });

    test('discovered XML topic resolves as a Writerside XML topic', () {
      final topic = writerside.writersideModule!.topics.singleWhere(
        (topic) => topic.filePath.endsWith('install.topic'),
      );
      final buffer = DocumentBuffer(
        id: 'install',
        filePath: topic.filePath,
        text: topic.document.source,
        lastSavedText: topic.document.source,
        dirty: false,
      );

      final resolved = resolveWorkspaceDocumentContext(writerside, buffer);
      expect(resolved.kind, DocumentKind.writersideXmlTopic);
      expect(resolved.writersideTopic, same(topic));
    });

    test('ordinary Markdown under the project is still CommonMark', () {
      final path = p.join(writerside.rootPath, 'notes', 'draft.md');
      final buffer = DocumentBuffer(
        id: 'ordinary',
        filePath: path,
        text: '# Notes\n',
        lastSavedText: '# Notes\n',
        dirty: false,
      );

      final resolved = resolveWorkspaceDocumentContext(writerside, buffer);
      expect(resolved.kind, DocumentKind.markdown);
      expect(resolved.markdownMode, MarkdownMode.commonMark);
      expect(resolved.writersideTopic, isNull);
    });

    test('path fallback does not depend on workspace file inventory', () {
      final path = p.join(writerside.rootPath, 'newly-saved.markdown');
      expect(
        writerside.files.any((file) => p.equals(file.absolutePath, path)),
        isFalse,
      );
      final buffer = DocumentBuffer(
        id: 'newly-saved',
        filePath: path,
        text: '# Saved\n',
        lastSavedText: '# Saved\n',
        dirty: false,
      );

      final resolved = resolveWorkspaceDocumentContext(writerside, buffer);
      expect(resolved.kind, DocumentKind.markdown);
      expect(resolved.markdownMode, MarkdownMode.commonMark);
    });
  });
}
