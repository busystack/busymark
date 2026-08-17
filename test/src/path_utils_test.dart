import 'dart:io';

import 'package:busymark/src/core/path_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'maxTreeEntries cancels a wide directory listing at the limit',
    () async {
      final root = await Directory.systemTemp.createTemp('busymark-scan-wide-');
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      var yieldedEntries = 0;

      Stream<FileSystemEntity> listDirectory(
        Directory directory, {
        required bool followLinks,
      }) async* {
        expect(followLinks, isFalse);
        for (var index = 0; index < 100; index++) {
          yieldedEntries++;
          yield File(p.join(directory.path, '$index.unsupported'));
        }
      }

      final result = await scanWorkspaceEntities(
        root.path,
        options: const WorkspaceScanOptions(maxTreeEntries: 3),
        directoryLister: listDirectory,
      );

      expect(yieldedEntries, 3);
      expect(result.entities, isEmpty);
      expect(
        result.diagnostics.map((diagnostic) => diagnostic.code),
        contains('workspace.scan.skipped'),
      );
    },
  );

  test('maxTreeEntries counts directories against the scan budget', () async {
    final root = await Directory.systemTemp.createTemp('busymark-scan-deep-');
    addTearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });
    final nested = await Directory(
      p.join(root.path, 'level-one', 'level-two'),
    ).create(recursive: true);
    await File(p.join(nested.path, 'guide.md')).writeAsString('# Guide\n');

    final result = await scanWorkspaceEntities(
      root.path,
      options: const WorkspaceScanOptions(maxTreeEntries: 2),
    );

    expect(result.entities, isEmpty);
    expect(
      result.diagnostics.map((diagnostic) => diagnostic.code),
      contains('workspace.scan.skipped'),
    );
  });
}
