import 'dart:io';

import 'package:busymark/src/writerside/writerside_input_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late List<File> files;
  late WritersideInputRecorder recorder;
  setUp(() async {
    root = await Directory.systemTemp.createTemp(
      'busymark-directory-observations-',
    );
    files = [
      for (final name in ['a', 'b', 'c']) File(p.join(root.path, name)),
    ];
    for (final file in files) {
      await file.writeAsString('fixture');
    }
    recorder = WritersideInputRecorder(root.path, treeEntryLimit: 3);
  });
  tearDown(() => root.delete(recursive: true));

  test('remaining observations partial prefix grows compatibly', () async {
    recorder.directory(root.path, files.take(1), complete: false);
    recorder.incomplete();
    recorder.directory(root.path, files.take(2), complete: false);
    expect(recorder.snapshot.consistent, isTrue);
    expect(recorder.snapshot.incompleteDirectories[root.path]!.count, 2);
    expect(
      recorder.snapshot.directories[root.path],
      inputDirectoryEntries(files.take(2)),
    );
  });
  test(
    'remaining observations partial becomes complete and clears marker',
    () async {
      recorder.directory(root.path, files.take(1), complete: false);
      recorder.incomplete();
      recorder.directory(root.path, files);
      expect(recorder.snapshot.consistent, isTrue);
      expect(recorder.snapshot.incompleteDirectories, isEmpty);
      expect(await recorder.snapshot.observedInputsCurrent(), isTrue);
      expect(await recorder.snapshot.isCurrent(), isFalse);
    },
  );
  test(
    'remaining observations identical complete listings remain consistent',
    () async {
      recorder.directory(root.path, files);
      recorder.directory(root.path, files.reversed);
      expect(recorder.snapshot.consistent, isTrue);
      expect(await recorder.snapshot.isCurrent(), isTrue);
    },
  );
  test(
    'remaining observations incompatible repeated listing rejects',
    () async {
      recorder.directory(root.path, files.take(2), complete: false);
      recorder.directory(root.path, [files.first, files.last], complete: false);
      expect(recorder.snapshot.consistent, isFalse);
      expect(await recorder.snapshot.observedInputsCurrent(), isFalse);
    },
  );
  test(
    'remaining observations known failed prefix recovers completely',
    () async {
      recorder.directory(
        root.path,
        files.take(1),
        complete: false,
        failed: true,
      );
      recorder.incomplete();
      recorder.directory(root.path, files);
      expect(recorder.snapshot.consistent, isTrue);
      expect(recorder.snapshot.incompleteDirectories, isEmpty);
      expect(await recorder.snapshot.observedInputsCurrent(), isTrue);
      expect(await recorder.snapshot.isCurrent(), isFalse);
    },
  );
  test(
    'remaining observations failure without a known prefix cannot prove recovery',
    () async {
      recorder.directory(root.path, [], complete: false, failed: true);
      recorder.directory(root.path, []);
      expect(recorder.snapshot.consistent, isFalse);
      expect(await recorder.snapshot.observedInputsCurrent(), isFalse);
    },
  );
  test(
    'remaining observations successful listing followed by failure rejects',
    () async {
      recorder.directory(root.path, files);
      recorder.directory(root.path, files, complete: false, failed: true);
      recorder.incomplete();
      expect(recorder.snapshot.consistent, isFalse);
      expect(await recorder.snapshot.observedInputsCurrent(), isFalse);
    },
  );
  for (final change in ['replacement', 'removal']) {
    test(
      'remaining observations real entry $change between complete reads rejects',
      () async {
        recorder.directory(root.path, files);
        await files.last.delete();
        if (change == 'replacement') {
          await Directory(files.last.path).create();
        }
        recorder.directory(
          root.path,
          await root.list(followLinks: false).toList(),
        );
        expect(recorder.snapshot.consistent, isFalse);
        expect(await recorder.snapshot.observedInputsCurrent(), isFalse);
      },
    );
  }
  test(
    'remaining observations shorter compatible scan keeps stronger proof',
    () async {
      recorder.directory(root.path, files, complete: false);
      recorder.incomplete();
      recorder.directory(root.path, files.take(1), complete: false);
      expect(recorder.snapshot.consistent, isTrue);
      expect(recorder.snapshot.incompleteDirectories[root.path]!.count, 3);
      await files.last.delete();
      expect(await recorder.snapshot.observedInputsCurrent(), isFalse);
    },
  );
  test(
    'remaining observations complete proof survives compatible limited rescan',
    () async {
      recorder.directory(root.path, files);
      recorder.directory(root.path, files.take(1), complete: false);
      recorder.incomplete();
      expect(recorder.snapshot.consistent, isTrue);
      expect(recorder.snapshot.incompleteDirectories, isEmpty);
      expect(await recorder.snapshot.observedInputsCurrent(), isTrue);
      expect(await recorder.snapshot.isCurrent(), isFalse);
    },
  );
  test(
    'remaining observations partial rescan cannot erase a previous failure',
    () async {
      recorder.directory(
        root.path,
        files.take(1),
        complete: false,
        failed: true,
      );
      recorder.incomplete();
      recorder.directory(root.path, files.take(2), complete: false);
      expect(recorder.snapshot.consistent, isFalse);
      expect(
        recorder.snapshot.incompleteDirectories[root.path]!.failed,
        isTrue,
      );
      expect(await recorder.snapshot.observedInputsCurrent(), isFalse);
    },
  );
  test(
    'remaining observations complete recovery must retain failed-prefix entries',
    () async {
      recorder.directory(
        root.path,
        files.take(1),
        complete: false,
        failed: true,
      );
      recorder.incomplete();
      recorder.directory(root.path, files.skip(1));
      expect(recorder.snapshot.consistent, isFalse);
      expect(await recorder.snapshot.observedInputsCurrent(), isFalse);
    },
  );
  test(
    'remaining observations shorter failed retry retains its consumed prefix',
    () async {
      recorder.directory(
        root.path,
        files.take(2),
        complete: false,
        failed: true,
      );
      recorder.directory(
        root.path,
        files.take(1),
        complete: false,
        failed: true,
      );
      expect(recorder.snapshot.consistent, isTrue);
      expect(recorder.snapshot.incompleteDirectories[root.path]!.count, 2);
      recorder.directory(root.path, files.take(1));
      expect(recorder.snapshot.consistent, isFalse);
      expect(await recorder.snapshot.observedInputsCurrent(), isFalse);
    },
  );
}
