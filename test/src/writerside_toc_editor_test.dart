import 'dart:io';

import 'package:busymark/src/core/busymark_exception.dart';
import 'package:busymark/src/writerside/writerside_toc_editor.dart';
import 'package:busymark/src/writerside/writerside_topic_creator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

void main() {
  const editor = WritersideTocEditor();

  Future<Directory> tempModule() async {
    final root = await Directory.systemTemp.createTemp('busymark-toc-editor-');
    addTearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });
    File(p.join(root.path, 'guide.tree')).writeAsStringSync(_treeSource);
    return Directory(await root.resolveSymbolicLinks());
  }

  WritersideTocEditTarget targetFor(Directory root) => WritersideTocEditTarget(
    rootPath: root.path,
    treePath: p.join(root.path, 'guide.tree'),
  );

  XmlDocument readTree(Directory root) => XmlDocument.parse(
    File(p.join(root.path, 'guide.tree')).readAsStringSync(),
  );

  XmlElement byId(XmlDocument tree, String id) => tree
      .findAllElements('toc-element')
      .singleWhere((element) => element.getAttribute('id') == id);

  List<String?> childIds(XmlElement element) => element.childElements
      .where((child) => child.name.local == 'toc-element')
      .map((child) => child.getAttribute('id'))
      .toList();

  List<String?> rootIds(XmlDocument tree) => childIds(tree.rootElement);

  test('moves a complete subtree as the last child of an exact node', () async {
    final root = await tempModule();

    final result = await editor.moveSubtree(
      targetFor(root),
      const WritersideTocMoveRequest(
        sourcePath: [0, 0],
        placement: WritersideTopicCreatePlacement.child,
        referencePath: [1],
      ),
    );

    final tree = readTree(root);
    expect(childIds(byId(tree, 'a')), ['a2']);
    expect(childIds(byId(tree, 'b')), ['b1', 'a1']);
    expect(childIds(byId(tree, 'a1')), ['a1x']);
    expect(result.entryPath, [1, 1]);
    expect(result.treePath, p.join(root.path, 'guide.tree'));
  });

  test('moves a nested entry after a root sibling', () async {
    final root = await tempModule();

    final result = await editor.moveSubtree(
      targetFor(root),
      const WritersideTocMoveRequest(
        sourcePath: [0, 1],
        placement: WritersideTopicCreatePlacement.sibling,
        referencePath: [2],
      ),
    );

    final tree = readTree(root);
    expect(rootIds(tree), ['a', 'b', 'c', 'a2']);
    expect(childIds(byId(tree, 'a')), ['a1']);
    expect(result.entryPath, [3]);
  });

  test('moves a nested entry to the end of the TOC root', () async {
    final root = await tempModule();

    final result = await editor.moveSubtree(
      targetFor(root),
      const WritersideTocMoveRequest(
        sourcePath: [1, 0],
        placement: WritersideTopicCreatePlacement.root,
      ),
    );

    final tree = readTree(root);
    expect(rootIds(tree), ['a', 'b', 'c', 'b1']);
    expect(childIds(byId(tree, 'b')), isEmpty);
    expect(result.entryPath, [3]);
  });

  test('rejects moving an entry relative to itself without writing', () async {
    final root = await tempModule();
    final treeFile = File(p.join(root.path, 'guide.tree'));
    final original = treeFile.readAsStringSync();

    await expectLater(
      editor.moveSubtree(
        targetFor(root),
        const WritersideTocMoveRequest(
          sourcePath: [0, 0],
          placement: WritersideTopicCreatePlacement.sibling,
          referencePath: [0, 0],
        ),
      ),
      throwsA(
        isA<BusyMarkException>().having(
          (error) => error.code,
          'code',
          'writerside.toc.move-invalid-target',
        ),
      ),
    );

    expect(treeFile.readAsStringSync(), original);
  });

  test('rejects moving an entry into its descendant without writing', () async {
    final root = await tempModule();
    final treeFile = File(p.join(root.path, 'guide.tree'));
    final original = treeFile.readAsStringSync();

    await expectLater(
      editor.moveSubtree(
        targetFor(root),
        const WritersideTocMoveRequest(
          sourcePath: [0],
          placement: WritersideTopicCreatePlacement.child,
          referencePath: [0, 0, 0],
        ),
      ),
      throwsA(
        isA<BusyMarkException>().having(
          (error) => error.code,
          'code',
          'writerside.toc.move-invalid-target',
        ),
      ),
    );

    expect(treeFile.readAsStringSync(), original);
  });

  test('requires a destination for child and sibling placement', () async {
    final root = await tempModule();

    await expectLater(
      editor.moveSubtree(
        targetFor(root),
        const WritersideTocMoveRequest(
          sourcePath: [0],
          placement: WritersideTopicCreatePlacement.child,
        ),
      ),
      throwsA(
        isA<BusyMarkException>().having(
          (error) => error.code,
          'code',
          'writerside.toc.destination-required',
        ),
      ),
    );
  });

  test('rejects invalid structural paths without writing', () async {
    final root = await tempModule();
    final treeFile = File(p.join(root.path, 'guide.tree'));
    final original = treeFile.readAsStringSync();

    await expectLater(
      editor.moveSubtree(
        targetFor(root),
        const WritersideTocMoveRequest(
          sourcePath: [0, 7],
          placement: WritersideTopicCreatePlacement.root,
        ),
      ),
      throwsA(
        isA<BusyMarkException>().having(
          (error) => error.code,
          'code',
          'writerside.toc.path-invalid',
        ),
      ),
    );
    await expectLater(
      editor.removeEntry(targetFor(root), const []),
      throwsA(isA<BusyMarkException>()),
    );

    expect(treeFile.readAsStringSync(), original);
  });

  test('rejects stale paths whose expected TOC identities moved', () async {
    final root = await tempModule();
    final treeFile = File(p.join(root.path, 'guide.tree'));
    final original = treeFile.readAsStringSync();

    await expectLater(
      editor.moveSubtree(
        targetFor(root),
        const WritersideTocMoveRequest(
          sourcePath: [0],
          sourceIdentity: WritersideTocNodeIdentity(
            id: 'b',
            topicFileName: 'b.md',
            hidden: false,
          ),
          placement: WritersideTopicCreatePlacement.root,
        ),
      ),
      throwsA(
        isA<BusyMarkException>().having(
          (error) => error.code,
          'code',
          'writerside.toc.path-invalid',
        ),
      ),
    );
    await expectLater(
      editor.removeEntry(
        targetFor(root),
        const [0],
        expectedIdentity: const WritersideTocNodeIdentity(
          id: 'b',
          topicFileName: 'b.md',
          hidden: false,
        ),
      ),
      throwsA(isA<BusyMarkException>()),
    );

    expect(treeFile.readAsStringSync(), original);
  });

  test('removes a root entry and promotes its children in place', () async {
    final root = await tempModule();

    final result = await editor.removeEntry(targetFor(root), const [0]);

    final tree = readTree(root);
    expect(rootIds(tree), ['a1', 'a2', 'b', 'c']);
    expect(childIds(byId(tree, 'a1')), ['a1x']);
    expect(result.entryPath, isNull);
  });

  test(
    'removes a nested entry and promotes its child before its sibling',
    () async {
      final root = await tempModule();

      await editor.removeEntry(targetFor(root), const [0, 0]);

      final tree = readTree(root);
      expect(rootIds(tree), ['a', 'b', 'c']);
      expect(childIds(byId(tree, 'a')), ['a1x', 'a2']);
    },
  );

  test('rejects a tree outside the guarded module root', () async {
    final root = await tempModule();
    final outside = await Directory.systemTemp.createTemp(
      'busymark-toc-editor-outside-',
    );
    addTearDown(() async {
      if (await outside.exists()) {
        await outside.delete(recursive: true);
      }
    });
    final outsideTree = File(p.join(outside.path, 'outside.tree'))
      ..writeAsStringSync(_treeSource);
    final original = outsideTree.readAsStringSync();

    await expectLater(
      editor.removeEntry(
        WritersideTocEditTarget(
          rootPath: root.path,
          treePath: outsideTree.path,
        ),
        const [0],
      ),
      throwsA(
        isA<BusyMarkException>().having(
          (error) => error.code,
          'code',
          'writerside.topic.tree-file-missing',
        ),
      ),
    );

    expect(outsideTree.readAsStringSync(), original);
  });

  test(
    'rejects a symlinked tree without mutating its target',
    () async {
      final root = await tempModule();
      final outside = await Directory.systemTemp.createTemp(
        'busymark-toc-editor-link-target-',
      );
      addTearDown(() async {
        if (await outside.exists()) {
          await outside.delete(recursive: true);
        }
      });
      final outsideTree = File(p.join(outside.path, 'outside.tree'))
        ..writeAsStringSync(_treeSource);
      final original = outsideTree.readAsStringSync();
      final treePath = p.join(root.path, 'guide.tree');
      await File(treePath).delete();
      await Link(treePath).create(outsideTree.path);

      await expectLater(
        editor.removeEntry(targetFor(root), const [0]),
        throwsA(
          isA<BusyMarkException>().having(
            (error) => error.code,
            'code',
            'writerside.topic.tree-file-missing',
          ),
        ),
      );

      expect(outsideTree.readAsStringSync(), original);
    },
    skip: Platform.isWindows ? 'POSIX symlink behavior only.' : false,
  );

  test('does not overwrite a tree changed before atomic publication', () async {
    final root = await tempModule();
    final treeFile = File(p.join(root.path, 'guide.tree'));
    final externalSource = _treeSource.replaceFirst(
      'name="Guide"',
      'name="Externally changed"',
    );
    final racingEditor = WritersideTocEditor(
      beforeTreePublish: (treePath) async {
        expect(treePath, treeFile.path);
        await treeFile.writeAsString(externalSource, flush: true);
      },
    );

    await expectLater(
      racingEditor.removeEntry(targetFor(root), const [0]),
      throwsA(
        isA<BusyMarkException>().having(
          (error) => error.code,
          'code',
          'writerside.toc.tree-changed',
        ),
      ),
    );

    expect(await treeFile.readAsString(), externalSource);
    final temporaryFiles = await root
        .list()
        .where(
          (entity) => p
              .basename(entity.path)
              .startsWith('.guide.tree.busymark-toc-edit-'),
        )
        .toList();
    expect(temporaryFiles, isEmpty);
  });

  test(
    'atomic replacement preserves the tree POSIX mode',
    () async {
      final root = await tempModule();
      final treeFile = File(p.join(root.path, 'guide.tree'));
      final chmod = await Process.run('chmod', ['640', treeFile.path]);
      expect(chmod.exitCode, 0, reason: '${chmod.stderr}');
      final originalMode = (await treeFile.stat()).mode & 0xfff;

      await editor.removeEntry(targetFor(root), const [0]);

      expect((await treeFile.stat()).mode & 0xfff, originalMode);
    },
    skip: Platform.isWindows ? 'POSIX permissions only.' : false,
  );
}

const _treeSource = '''
<?xml version="1.0" encoding="UTF-8"?>
<instance-profile id="guide" name="Guide" start-page="a.md">
  <toc-element id="a" topic="a.md">
    <toc-element id="a1" topic="a1.md">
      <toc-element id="a1x" topic="a1x.md"/>
    </toc-element>
    <toc-element id="a2" topic="a2.md"/>
  </toc-element>
  <toc-element id="b" topic="b.md">
    <toc-element id="b1" topic="b1.md"/>
  </toc-element>
  <toc-element id="c" topic="c.md"/>
</instance-profile>
''';
