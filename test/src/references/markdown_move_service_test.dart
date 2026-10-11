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
  // Capture the actual durable pre-rename journal, then restore it after the
  // successful operation to model process death immediately before deletion.
  Future<File> interruptedMove(MarkdownMovePlan plan) async {
    final workspace = await workspaceService.openPath(root.path);
    late File journal;
    late List<int> evidence;
    await service.apply(
      plan,
      validateBuffers: () {},
      move: () async {
        journal =
            (await Directory(
                  '${root.path}/.busymark-refactoring',
                ).list().where((e) => e.path.endsWith('.json')).toList()).single
                as File;
        evidence = await journal.readAsBytes();
        return p.equals(p.dirname(plan.source), p.dirname(plan.destination))
            ? workspaceService.renameEntity(
                workspace,
                plan.source,
                p.basename(plan.destination),
              )
            : workspaceService.moveEntity(
                workspace,
                plan.source,
                p.dirname(plan.destination),
              );
      },
    );
    await journal.writeAsBytes(evidence, flush: true);
    return journal;
  }

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
    'hidden authored sources participate in reviewed incoming links',
    () async {
      final hidden = File('${root.path}/.guides/.source.md');
      await hidden.parent.create();
      await hidden.writeAsString('[Target](../old/target.md#heading)\n');
      final workspace = await workspaceService.openPath(root.path);
      final plan = await service.prepare(
        workspace,
        '${root.path}/old/target.md',
        '${root.path}/old/renamed.md',
      );
      expect(plan.files.any((f) => f.path == hidden.path), isTrue);
      await service.apply(
        plan,
        validateBuffers: () {},
        move: () => workspaceService.renameEntity(
          workspace,
          '${root.path}/old/target.md',
          'renamed.md',
        ),
      );
      expect(
        await hidden.readAsString(),
        '[Target](../old/renamed.md#heading)\n',
      );
      final reviewed = await service.prepare(
        workspace,
        '${root.path}/old/renamed.md',
        '${root.path}/old/final.md',
      );
      await File('${root.path}/.guides/new.md').writeAsString('new member');
      await expectLater(service.validate(reviewed), throwsStateError);
    },
  );
  test(
    'folder moves maintain outgoing references in hidden descendants',
    () async {
      final hidden = File('${root.path}/old/.drafts/.source.md');
      await hidden.parent.create();
      await hidden.writeAsString(
        '[Other](../../other.md)\n![Media](../image.png)\n',
      );
      final workspace = await workspaceService.openPath(root.path);
      final plan = await service.prepare(
        workspace,
        '${root.path}/old',
        '${root.path}/new/old',
      );
      await service.apply(
        plan,
        validateBuffers: () {},
        move: () => workspaceService.moveEntity(
          workspace,
          '${root.path}/old',
          '${root.path}/new',
        ),
      );
      expect(
        await File('${root.path}/new/old/.drafts/.source.md').readAsString(),
        '[Other](../../../other.md)\n![Media](../image.png)\n',
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
      final journal = await interruptedMove(plan);
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
  for (final change in [
    'recreated source',
    'replaced destination',
    'identical-byte destination replacement',
  ]) {
    for (final afterReview in [false, true]) {
      test(
        'restart recovery retains evidence for $change (after review: $afterReview)',
        () async {
          final source = File('${root.path}/old/target.md');
          await source.writeAsString('# Target without outgoing references\n');
          final incoming = File('${root.path}/other.md');
          final workspace = await workspaceService.openPath(root.path);
          final plan = await service.prepare(
            workspace,
            source.path,
            '${root.path}/old/renamed.md',
          );
          expect(plan.files.any((f) => f.path == source.path), isFalse);
          final journal = await interruptedMove(plan);
          final reviewed = afterReview
              ? await const MarkdownMoveService().prepareRecovery(
                  root.path,
                  journal.path,
                )
              : null;
          final evidence = await journal.readAsBytes();
          final linked = await incoming.readAsBytes();
          final destination = File(plan.destination);
          if (change == 'recreated source') {
            await source.writeAsString('# Unrelated newly created source\n');
          } else {
            final bytes = await destination.readAsBytes();
            await destination.rename('${plan.destination}.original');
            await destination.writeAsBytes(
              change == 'replaced destination'
                  ? utf8.encode('# Unrelated replacement destination\n')
                  : bytes,
            );
          }
          final destinationBytes = await destination.readAsBytes();
          final sourceBytes = await source.exists()
              ? await source.readAsBytes()
              : null;
          if (reviewed == null) {
            await expectLater(
              const MarkdownMoveService().recover(root.path, journal.path),
              throwsStateError,
            );
          } else {
            await expectLater(
              const MarkdownMoveService().recoverReviewed(reviewed),
              throwsStateError,
            );
          }
          expect(await incoming.readAsBytes(), linked);
          expect(await destination.readAsBytes(), destinationBytes);
          if (sourceBytes != null) {
            expect(await source.readAsBytes(), sourceBytes);
          } else {
            expect(await source.exists(), isFalse);
          }
          expect(await journal.readAsBytes(), evidence);
        },
      );
    }
  }
  test(
    'legacy identity-free recovery evidence is kept for manual review',
    () async {
      final journal = File('${root.path}/.busymark-refactoring/legacy.json');
      await journal.parent.create();
      await journal.writeAsString(
        jsonEncode({
          'version': 1,
          'source': 'old/target.md',
          'destination': 'old/renamed.md',
          'files': [],
        }),
      );
      final before = await journal.readAsString();
      await expectLater(
        service.recover(root.path, journal.path),
        throwsStateError,
      );
      expect(await journal.readAsString(), before);
    },
  );
  test(
    'replaced folder identity and added membership retain restart evidence',
    () async {
      final workspace = await workspaceService.openPath(root.path);
      final plan = await service.prepare(
        workspace,
        '${root.path}/old',
        '${root.path}/new/old',
      );
      final journal = await interruptedMove(plan);
      final incoming = await File('${root.path}/other.md').readAsBytes();
      await File('${plan.destination}/unreviewed.png').writeAsBytes([9]);
      await expectLater(
        service.recover(root.path, journal.path),
        throwsStateError,
      );
      expect(await File('${root.path}/other.md').readAsBytes(), incoming);
      expect(await journal.exists(), isTrue);
      await File('${plan.destination}/unreviewed.png').delete();
      // Retain all original child identities but replace the containing directory.
      await Directory(plan.destination).rename('${plan.destination}.original');
      await Directory(plan.destination).create();
      await for (final entry in Directory(
        '${plan.destination}.original',
      ).list()) {
        await File(
          entry.path,
        ).rename(p.join(plan.destination, p.basename(entry.path)));
      }
      await expectLater(
        service.recover(root.path, journal.path),
        throwsStateError,
      );
      expect(await File('${root.path}/other.md').readAsBytes(), incoming);
      expect(await journal.exists(), isTrue);
    },
  );
  test(
    'recreated source during publication prevents journal deletion and reference rollback',
    () async {
      final workspace = await workspaceService.openPath(root.path);
      final source = File('${root.path}/old/target.md');
      final plan = await service.prepare(
        workspace,
        source.path,
        '${root.path}/old/renamed.md',
      );
      await expectLater(
        service.apply(
          plan,
          validateBuffers: () {},
          move: () async {
            final moved = await workspaceService.renameEntity(
              workspace,
              source.path,
              'renamed.md',
            );
            await source.writeAsString('# Unrelated recreated source');
            return moved;
          },
        ),
        throwsStateError,
      );
      expect(await source.readAsString(), '# Unrelated recreated source');
      expect(await File(plan.destination).exists(), isTrue);
      expect(
        await File('${root.path}/other.md').readAsString(),
        contains('old/renamed.md#heading'),
      );
      expect(
        await Directory(
          '${root.path}/.busymark-refactoring',
        ).list().where((e) => e.path.endsWith('.json')).length,
        1,
      );
    },
  );
  test(
    'valid code-formatted labels update through ordinary rename and move',
    () async {
      final file = File('${root.path}/other.md');
      const before =
          '[`API`](old/target.md "title") [`API`][ref]\n\n'
          '[ref]: old/target.md#heading "definition title"\n\n'
          '`[example](old/target.md)`\n<!-- [`hidden`](old/target.md) -->\n';
      await file.writeAsString(before);
      final workspace = await workspaceService.openPath(root.path);
      final rename = await service.prepare(
        workspace,
        '${root.path}/old/target.md',
        '${root.path}/old/renamed.md',
      );
      await service.apply(
        rename,
        validateBuffers: () {},
        move: () => workspaceService.renameEntity(
          workspace,
          rename.source,
          'renamed.md',
        ),
      );
      final move = await service.prepare(
        workspace,
        rename.destination,
        '${root.path}/new/renamed.md',
      );
      await service.apply(
        move,
        validateBuffers: () {},
        move: () => workspaceService.moveEntity(
          workspace,
          move.source,
          '${root.path}/new',
        ),
      );
      expect(
        await file.readAsString(),
        '[`API`](new/renamed.md "title") [`API`][ref]\n\n'
        '[ref]: new/renamed.md#heading "definition title"\n\n'
        '`[example](old/target.md)`\n<!-- [`hidden`](old/target.md) -->\n',
      );
    },
  );
  test(
    'replacement during recovery writes rolls references back and retains evidence',
    () async {
      final source = File('${root.path}/old/target.md');
      await source.writeAsString('# Target without internal links');
      final workspace = await workspaceService.openPath(root.path);
      final plan = await service.prepare(
        workspace,
        source.path,
        '${root.path}/old/renamed.md',
      );
      final journal = await interruptedMove(plan);
      final incoming = File('${root.path}/other.md');
      final linked = await incoming.readAsBytes();
      final evidence = await journal.readAsBytes();
      final restarted = MarkdownMoveService(
        workspaceService: WorkspaceService(
          afterBatchFileCommit: (_, _) async {
            await source.rename('${source.path}.original');
            await source.writeAsString('# Unrelated concurrent replacement');
          },
        ),
      );
      await expectLater(
        restarted.recover(root.path, journal.path),
        throwsStateError,
      );
      expect(await incoming.readAsBytes(), linked);
      expect(await source.readAsString(), '# Unrelated concurrent replacement');
      expect(await journal.readAsBytes(), evidence);
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
