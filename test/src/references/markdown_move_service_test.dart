import 'dart:convert';
import 'dart:io';

import 'package:busymark/src/references/markdown_move_service.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  const service = MarkdownMoveService();
  const workspaceService = WorkspaceService();
  setUp(() async {
    root = await Directory.systemTemp.createTemp('markdown-move-');
    await Directory('${root.path}/old').create();
    await Directory('${root.path}/new').create();
    await File('${root.path}/old/target.md').writeAsString(
      '# Heading\n[other](../other.md#id "title")\n![media](image.png)\n',
    );
    await File('${root.path}/old/image.png').writeAsBytes([1, 2, 3]);
    await File('${root.path}/other.md').writeAsString(
      '# Other\n[link][ref] [again][ref]\n\n[ref]: old/target.md#heading "title"\n\n`old/target.md`\n',
    );
  });
  tearDown(() async => root.delete(recursive: true));
  test(
    'file rename updates incoming definitions once and leaves code unchanged',
    () async {
      final workspace = await workspaceService.openPath(root.path);
      final old = '${root.path}/old/target.md',
          target = '${root.path}/old/café %.md';
      final plan = await service.prepare(workspace, old, target);
      expect(plan.files.length, 1);
      expect(plan.files.single.edits.length, 1);
      await service.apply(
        plan,
        validateBuffers: () {},
        move: () =>
            workspaceService.renameEntity(workspace, old, p.basename(target)),
      );
      final incoming = await File('${root.path}/other.md').readAsString();
      expect(
        incoming,
        contains('[ref]: old/caf%C3%A9%20%25.md#heading "title"'),
      );
      expect(incoming, contains('`old/target.md`'));
    },
  );
  test('cross-directory move updates incoming and outgoing media', () async {
    final workspace = await workspaceService.openPath(root.path);
    final old = '${root.path}/old/target.md',
        target = '${root.path}/new/target.md';
    final plan = await service.prepare(workspace, old, target);
    expect(plan.files.length, 2);
    await service.apply(
      plan,
      validateBuffers: () {},
      move: () =>
          workspaceService.moveEntity(workspace, old, '${root.path}/new'),
    );
    expect(
      await File(target).readAsString(),
      contains('![media](../old/image.png)'),
    );
    expect(
      await File('${root.path}/other.md').readAsString(),
      contains('new/target.md#heading'),
    );
  });
  test(
    'complete folder mapping preserves internal media and updates incoming paths',
    () async {
      final workspace = await workspaceService.openPath(root.path);
      final old = '${root.path}/old', target = '${root.path}/new/old';
      final plan = await service.prepare(workspace, old, target);
      expect(plan.mapping['$old/image.png'], '$target/image.png');
      await service.apply(
        plan,
        validateBuffers: () {},
        move: () =>
            workspaceService.moveEntity(workspace, old, '${root.path}/new'),
      );
      final source = await File('$target/target.md').readAsString();
      expect(source, contains('[other](../../other.md#id "title")'));
      expect(source, contains('![media](image.png)'));
      expect(
        await File('${root.path}/other.md').readAsString(),
        contains('new/old/target.md#heading'),
      );
    },
  );
  test(
    'external edits after review and new workspace members reject publication',
    () async {
      final workspace = await workspaceService.openPath(root.path);
      final old = '${root.path}/old/target.md';
      final plan = await service.prepare(
        workspace,
        old,
        '${root.path}/old/renamed.md',
      );
      await File('${root.path}/other.md').writeAsString('new external bytes');
      await expectLater(
        service.apply(
          plan,
          validateBuffers: () {},
          move: () =>
              workspaceService.renameEntity(workspace, old, 'renamed.md'),
        ),
        throwsStateError,
      );
      expect(await File(old).exists(), isTrue);
      final next = await service.prepare(
        workspace,
        old,
        '${root.path}/old/renamed.md',
      );
      await File('${root.path}/added.md').writeAsString('new source');
      await expectLater(service.validate(next), throwsStateError);
    },
  );
  test('collision and symlink paths fail before writes', () async {
    final workspace = await workspaceService.openPath(root.path);
    final old = '${root.path}/old/target.md';
    await expectLater(
      service.prepare(workspace, old, '${root.path}/other.md'),
      throwsStateError,
    );
    await Link('${root.path}/alias').create('${root.path}/old');
    await expectLater(
      service.prepare(
        workspace,
        '${root.path}/alias/target.md',
        '${root.path}/new/target.md',
      ),
      throwsA(anything),
    );
  });
  test('move failure rolls back reviewed edits and retains source', () async {
    final workspace = await workspaceService.openPath(root.path);
    final before = await File('${root.path}/other.md').readAsString();
    final plan = await service.prepare(
      workspace,
      '${root.path}/old/target.md',
      '${root.path}/old/renamed.md',
    );
    await expectLater(
      service.apply(
        plan,
        validateBuffers: () {},
        move: () async => throw const FileSystemException('injected denied'),
      ),
      throwsA(isA<FileSystemException>()),
    );
    expect(await File('${root.path}/other.md').readAsString(), before);
    expect(await File('${root.path}/old/target.md').exists(), isTrue);
  });
  test(
    'restart recovery restores exact BOM/CRLF bytes and refuses newer external data',
    () async {
      final original = File('${root.path}/other.md');
      await original.writeAsBytes([
        239,
        187,
        191,
        ...utf8.encode('[link](old/target.md#heading)\r\n'),
      ]);
      final workspace = await workspaceService.openPath(root.path);
      final plan = await service.prepare(
        workspace,
        '${root.path}/old/target.md',
        '${root.path}/new/target.md',
      );
      final folder = Directory('${root.path}/.busymark-refactoring');
      await folder.create();
      final journal = File('${folder.path}/interrupted.json');
      await journal.writeAsString(
        jsonEncode({
          'version': 1,
          'source': 'old/target.md',
          'destination': 'new/target.md',
          'files': [
            for (final file in plan.files)
              {
                'path': p.relative(file.path, from: root.path),
                'before': base64Encode(file.load.format.encode(file.load.text)),
                'after': base64Encode(file.load.format.encode(file.result)),
              },
          ],
        }),
        flush: true,
      );
      await workspaceService.saveFormattedTextBatch([
        for (final file in plan.files)
          WorkspaceBatchTextWrite(
            path: file.path,
            text: file.result,
            expectedSnapshot: file.load.snapshot,
            format: file.load.format,
          ),
      ]);
      await workspaceService.moveEntity(
        workspace,
        plan.source,
        '${root.path}/new',
      );
      const restarted = MarkdownMoveService();
      final review = await restarted.prepareRecovery(root.path, journal.path);
      await original.writeAsString('new external edit');
      await expectLater(restarted.recoverReviewed(review), throwsStateError);
      expect(await original.readAsString(), 'new external edit');
      expect(await journal.exists(), isTrue);
      final changedFile = plan.files.singleWhere(
        (f) => f.path == original.path,
      );
      await original.writeAsBytes(
        changedFile.load.format.encode(changedFile.result),
      );
      await restarted.recover(root.path, journal.path);
      expect(await File(plan.source).exists(), isTrue);
      expect(await File(plan.destination).exists(), isFalse);
      expect(
        await original.readAsBytes(),
        changedFile.load.format.encode(changedFile.load.text),
      );
      expect(await journal.exists(), isFalse);
    },
  );
  test(
    'changed non-Markdown folder membership and replacement identity require renewed review',
    () async {
      final workspace = await workspaceService.openPath(root.path);
      final plan = await service.prepare(
        workspace,
        '${root.path}/old',
        '${root.path}/new/old',
      );
      await File('${root.path}/old/new.png').writeAsBytes([9]);
      await expectLater(service.validate(plan), throwsStateError);
      final next = await service.prepare(
        workspace,
        '${root.path}/old/target.md',
        '${root.path}/old/renamed.md',
      );
      final file = File('${root.path}/other.md');
      final content = await file.readAsString();
      await file.delete();
      await file.writeAsString(content);
      await expectLater(service.validate(next), throwsStateError);
    },
  );
}
