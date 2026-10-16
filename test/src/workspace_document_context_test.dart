import 'package:busymark/src/markdown/document_outline.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'Outline filtering retains ancestors, document order and duplicate title identities',
    () {
      const headings = [
        DocumentOutlineHeading(level: 1, text: 'Root', id: 'root'),
        DocumentOutlineHeading(level: 2, text: 'First branch', id: 'first'),
        DocumentOutlineHeading(
          level: 3,
          text: 'Target',
          id: 'target',
          editorBlockId: 'live-a',
        ),
        DocumentOutlineHeading(level: 2, text: 'Unrelated', id: 'unrelated'),
        DocumentOutlineHeading(
          level: 2,
          text: 'Target',
          id: 'target-1',
          editorBlockId: 'live-b',
        ),
      ];
      expect(matchDocumentOutline(headings, ''), isEmpty);
      final filtered = matchDocumentOutline(headings, 'TARGET');
      expect(filtered.map((m) => m.heading.id), ['target', 'target-1']);
      expect(filtered.map((m) => m.heading.level), [3, 2]);
      expect(filtered.first.heading, same(headings[2]));
      expect(filtered.last.heading.editorBlockId, 'live-b');
      expect(filtered.first.ancestors.map((h) => h.id), ['root', 'first']);
      expect(filtered.last.ancestors.map((h) => h.id), ['root']);
      expect(
        matchDocumentOutline(headings, 'target', maximumResults: 1),
        hasLength(1),
      );
      expect(matchDocumentOutline(headings, 'missing'), isEmpty);
    },
  );
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
