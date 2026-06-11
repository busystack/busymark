import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:busymark/src/core/path_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

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

  test(
    'folder scan skips generated directories and binary resources',
    () async {
      final directory = await Directory.systemTemp.createTemp('busymark-scan-');
      await File('${directory.path}/README.md').writeAsString('# Readme\n');
      await Directory('${directory.path}/node_modules').create();
      await File(
        '${directory.path}/node_modules/ignored.md',
      ).writeAsString('# Ignored\n');
      await File('${directory.path}/binary.bin').writeAsBytes([0, 1, 2, 3]);

      final workspace = await service.openPath(directory.path);

      expect(
        workspace.files.map((file) => file.relativePath),
        contains('README.md'),
      );
      expect(
        workspace.files.map((file) => file.relativePath),
        isNot(contains('node_modules/ignored.md')),
      );
      expect(
        workspace.files.map((file) => file.relativePath),
        isNot(contains('binary.bin')),
      );

      await directory.delete(recursive: true);
    },
  );

  test('invalid UTF-8 Markdown does not fail the whole workspace', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-invalid-',
    );
    await File('${directory.path}/good.md').writeAsString('# Good\n');
    await File('${directory.path}/bad.md').writeAsBytes([0xff, 0xfe, 0xfd]);

    final workspace = await service.openPath(directory.path);

    expect(
      workspace.files.map((file) => file.relativePath),
      contains('bad.md'),
    );
    expect(
      workspace.diagnostics.map((diagnostic) => diagnostic.code),
      contains('workspace.file.read-failed'),
    );

    await directory.delete(recursive: true);
  });

  test(
    'large Markdown files are listed but not parsed automatically',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-large-',
      );
      await File(
        '${directory.path}/large.md',
      ).writeAsString('# Large\n\nBody\n');
      final limitedService = WorkspaceService(
        scanOptions: const WorkspaceScanOptions(maxParsedFileBytes: 8),
      );

      final workspace = await limitedService.openPath(directory.path);

      expect(
        workspace.files.map((file) => file.relativePath),
        contains('large.md'),
      );
      expect(
        workspace.diagnostics.map((diagnostic) => diagnostic.code),
        contains('workspace.file.too-large'),
      );
      expect(workspace.markdown, isNull);

      await directory.delete(recursive: true);
    },
  );
}
