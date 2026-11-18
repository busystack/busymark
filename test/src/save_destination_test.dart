import 'dart:convert';
import 'dart:io';

import 'package:busymark/src/core/atomic_file_writer.dart';
import 'package:busymark/src/core/save_destination.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('busymark-save-destination-');
  });
  tearDown(() => root.deleteSync(recursive: true));

  test(
    'suffix finalization handles correct, missing, different and uppercase',
    () {
      for (final (name, expected) in [
        ('export.pdf', 'export.pdf'),
        ('export', 'export.pdf'),
        ('export.txt', 'export.txt.pdf'),
        ('export.PDF', 'export.PDF'),
      ]) {
        expect(SaveDestination.withSuffix(name, '.pdf'), expected);
      }
      expect(
        SaveDestination.withSuffix('topic.xml', '.md', onlyWhenMissing: true),
        'topic.xml',
      );
      expect(SaveDestination.withSuffix('site', null), 'site');
    },
  );

  test(
    'a new final path refuses a file appearing while bytes are staged',
    () async {
      final file = File(p.join(root.path, 'diagram.png'));
      final newFile = SaveDestination.inspect(file.path);
      await expectLater(
        const AtomicFileWriter().writeBytes(
          file.path,
          [1, 2, 3],
          overwrite: false,
          authorization: newFile,
          beforePublish: () => file.writeAsStringSync('late entrant'),
        ),
        throwsA(isA<AtomicFileChangedException>()),
      );
      expect(file.readAsStringSync(), 'late entrant');
      expect(root.listSync().map((entry) => entry.path), [file.path]);
    },
  );

  test(
    'authorization binds the entry and never crosses a suffix change',
    () async {
      final chosen = File(p.join(root.path, 'diagram'))
        ..writeAsStringSync('first');
      final finalFile = File(SaveDestination.withSuffix(chosen.path, '.svg'))
        ..writeAsStringSync('protected');
      final approval = SaveDestination.inspect(chosen.path);
      await expectLater(
        const AtomicFileWriter().writeBytes(
          finalFile.path,
          utf8.encode('<svg/>'),
          overwrite: true,
          authorization: approval,
        ),
        throwsA(isA<AtomicFileChangedException>()),
      );
      expect(finalFile.readAsStringSync(), 'protected');
      expect(chosen.readAsStringSync(), 'first');
    },
  );

  test(
    'diagram bytes publish to a new or explicitly reviewed final file',
    () async {
      final file = File(p.join(root.path, 'diagram.png'));
      for (final bytes in [
        [1, 2, 3],
        [4, 5, 6],
      ]) {
        final authorization = SaveDestination.inspect(file.path);
        await const AtomicFileWriter().writeBytes(
          file.path,
          bytes,
          overwrite: authorization.replacesExisting,
          authorization: authorization,
        );
        expect(file.readAsBytesSync(), bytes);
      }
      expect(root.listSync().map((entry) => entry.path), [file.path]);
    },
  );

  test(
    'an identical-looking replacement inode still invalidates consent',
    () async {
      final file = File(p.join(root.path, 'same.md'))
        ..writeAsStringSync('same');
      final authorization = SaveDestination.inspect(file.path);
      final other = File(p.join(root.path, 'other'))
        ..writeAsStringSync('same')
        ..setLastModifiedSync(file.lastModifiedSync());
      final service = WorkspaceService(
        beforeNewFilePublish: (_) async {
          other.renameSync(file.path);
        },
      );
      final expected = await service.fileSnapshot(file.path);
      await expectLater(
        service.saveFormattedTextReplacingPath(
          file.path,
          'new',
          expectedSnapshot: expected,
          authorization: authorization,
        ),
        throwsA(isA<AtomicFileChangedException>()),
      );
      expect(file.readAsStringSync(), 'same');
    },
  );

  test(
    'file and directory workflows preserve their symlink policies',
    () async {
      final file = File(p.join(root.path, 'target.md'))
        ..writeAsStringSync('old');
      final link = Link(p.join(root.path, 'alias.md'))..createSync('target.md');
      expect(
        () => SaveDestination.inspect(link.path),
        throwsA(isA<FileSystemException>()),
      );
      expect(
        () => SaveDestination.inspect(root.path),
        throwsA(isA<FileSystemException>()),
      );
      expect(
        SaveDestination.inspect(
          root.path,
          kind: SaveDestinationKind.directory,
        ).replacesExisting,
        isTrue,
      );
      final authorization = SaveDestination.inspect(
        link.path,
        kind: SaveDestinationKind.fileOrSymbolicLink,
      );
      final service = const WorkspaceService();
      await service.saveFormattedTextReplacingPath(
        link.path,
        'new copy',
        expectedSnapshot: await service.fileSnapshot(link.path),
        authorization: authorization,
      );
      expect(File(link.path).readAsStringSync(), 'new copy');
      expect(file.readAsStringSync(), 'old');
      expect(link.existsSync(), isFalse);
    },
  );
}
