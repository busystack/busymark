import 'dart:io';
import 'package:busymark/src/writerside/writerside_source_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'chooser references resolve snippets, topic paths and shadowing safely',
    () async {
      final root = await Directory.systemTemp.createTemp('code-source-picker-');
      addTearDown(() => root.delete(recursive: true));
      for (final dir in ['topics', 'snippets', 'samples']) {
        await Directory(p.join(root.path, dir)).create();
      }
      final topic = p.join(root.path, 'topics/a.topic');
      await File(topic).writeAsString('<topic/>');
      Future<String?> select(String name) async {
        final file = File(p.join(root.path, name));
        await file.writeAsString('code');
        return const WritersideSourceLoader().referenceForFile(
          selectedPath: file.path,
          documentPath: topic,
          workspaceRoot: root.path,
          snippetsDirectory: 'snippets',
        );
      }

      expect(await select('snippets/sample.dart'), 'sample.dart');
      expect(
        await select('samples/Café sample.dart'),
        '../samples/Café sample.dart',
      );
      expect(await select('topics/local.dart'), 'local.dart');
      await File(
        p.join(root.path, 'topics/sample.dart'),
      ).writeAsString('other');
      expect(await select('snippets/sample.dart'), '../snippets/sample.dart');
      expect(
        await const WritersideSourceLoader().referenceForFile(
          selectedPath: root.path,
          documentPath: topic,
          workspaceRoot: root.path,
        ),
        isNull,
      );
      final outside = await File(
        p.join(root.parent.path, '${p.basename(root.path)}-outside'),
      ).writeAsString('outside');
      addTearDown(outside.delete);
      expect(
        await const WritersideSourceLoader().referenceForFile(
          selectedPath: outside.path,
          documentPath: topic,
          workspaceRoot: root.path,
        ),
        isNull,
      );
      final link = await Link(
        p.join(root.path, 'snippets/escape'),
      ).create(outside.path);
      expect(
        await const WritersideSourceLoader().referenceForFile(
          selectedPath: link.path,
          documentPath: topic,
          workspaceRoot: root.path,
          snippetsDirectory: 'snippets',
        ),
        isNull,
      );
    },
  );
}
