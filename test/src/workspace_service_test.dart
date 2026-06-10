import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = WorkspaceService();

  test('opens a single Markdown file workspace', () async {
    final workspace = await service.openPath('test/fixtures/markdown/basic.md');

    expect(workspace.kind, WorkspaceKind.singleMarkdown);
    expect(workspace.markdown?.title, 'Basic Markdown');
    expect(workspace.activeFilePath, isNotNull);
  });

  test('opens a generic Markdown folder workspace', () async {
    final workspace = await service.openPath('test/fixtures/markdown');

    expect(workspace.kind, WorkspaceKind.markdownFolder);
    expect(
      workspace.files.where((item) => item.relativePath.endsWith('.md')),
      isNotEmpty,
    );
  });

  test('opens a Writerside module workspace', () async {
    final workspace = await service.openPath(
      'test/fixtures/writerside/basic_project',
    );

    expect(workspace.kind, WorkspaceKind.writersideModule);
    expect(workspace.writersideModule?.instances.single.name, 'User Guide');
    expect(workspace.activeFilePath, endsWith('intro.md'));
  });
}
