import 'dart:io';

import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/writerside/writerside_code_selection.dart';
import 'package:busymark/src/writerside/writerside_document.dart';
import 'package:busymark/src/writerside/writerside_document_renderer.dart';
import 'package:busymark/src/writerside/writerside_document_resolver.dart';
import 'package:busymark/src/writerside/writerside_document_serializer.dart';
import 'package:busymark/src/writerside/writerside_module_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

Iterable<BusyBlock> walk(List<BusyBlock> blocks) sync* {
  for (final block in blocks) {
    yield block;
    yield* walk(block.children);
  }
}

void main() {
  late Directory root;
  Future<void> write(String path, String text) async {
    final file = File(p.join(root.path, path));
    await file.parent.create(recursive: true);
    await file.writeAsString(text);
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('busymark-resolution-');
    await write(
      'writerside.cfg',
      '<ihp><topics dir="topics"/><snippets src="samples"/><vars src="v.list"/><instance src="web.tree"/><instance src="mobile.tree"/></ihp>',
    );
    await write(
      'v.list',
      '<vars><var name="product" value="Web" instance="web"/><var name="product" value="Mobile" instance="mobile"/></vars>',
    );
    for (final instance in ['web', 'mobile']) {
      await write(
        '$instance.tree',
        '<instance-profile id="$instance" name="$instance" start-page="main.topic"><toc-element topic="main.topic"/><toc-element topic="target.topic"/></instance-profile>',
      );
    }
    await write(
      'topics/target.topic',
      '<topic id="target" title="Target title"><chapter id="intro" title="Introduction"><p>Target summary</p></chapter></topic>',
    );
  });
  tearDown(() => root.delete(recursive: true));

  Future<BusyDocument> render({
    String instance = 'web',
    Map<String, String> overrides = const {},
  }) async {
    final module = await const WritersideModuleService().load(
      root.path,
      sourceOverrides: overrides,
    );
    final topic = module.topicByReference('main.topic')!;
    final resolved = const WritersideDocumentResolver().resolve(
      topic.document,
      WritersideResolveContext(
        module: module,
        topic: topic,
        instance: module.instances.singleWhere((value) => value.id == instance),
      ),
    );
    expect(resolved.diagnostics, isEmpty);
    return const WritersideDocumentRenderer().toBusyDocument(resolved.document);
  }

  test(
    'Markdown IDs include whole chapters and retain mixed-content spans',
    () async {
      const library = '''# Library

## Reused {id="section"}

A **bold** paragraph.

### Nested

Nested body.

## Next

Excluded body.

<snippet id="mixed">

A *formatted* paragraph.

<tabs>
<tab title="First">

Nested **tab** content.

</tab>
</tabs>

</snippet>
''';
      await write('topics/library.md', library);
      await write(
        'topics/main.topic',
        '<topic id="main"><include from="library.md" element-id="section"/><include from="library.md" element-id="mixed"/></topic>',
      );
      final blocks = walk((await render()).blocks).toList();
      final text = blocks.map((block) => block.plainText).join('\n');
      expect(text, contains('Nested body.'));
      expect(text, isNot(contains('Excluded body.')));
      expect(text, contains('A formatted paragraph.'));
      expect(text, contains('Nested tab content.'));
      final formatted = blocks.singleWhere(
        (block) => block.plainText == 'A formatted paragraph.',
      );
      expect(
        formatted.inlines.any(
          (inline) => inline.kind == BusyInlineKind.emphasis,
        ),
        isTrue,
      );
      expect(
        library.substring(
          formatted.sourceSpan!.startOffset,
          formatted.sourceSpan!.endOffset,
        ),
        contains('A *formatted* paragraph.'),
      );
      final module = await const WritersideModuleService().load(root.path);
      expect(
        const WritersideDocumentSerializer().serialize(
          module.topicByReference('library.md')!.document,
        ),
        library,
      );
    },
  );

  test(
    'conditional globals and include arguments override snippet defaults',
    () async {
      await write(
        'topics/library.topic',
        '<topic id="lib"><snippet id="s"><var name="button" value="Default"/><p>%product%: %button%</p><code-block ignore-vars="true">%button%</code-block></snippet></topic>',
      );
      await write(
        'topics/main.topic',
        '<topic id="main"><include from="library.topic" element-id="s"><var name="button" value="Save"/></include><include from="library.topic" element-id="s"/></topic>',
      );
      for (final instance in ['web', 'mobile']) {
        final text = walk(
          (await render(instance: instance)).blocks,
        ).map((block) => block.plainText).join('\n');
        final product = instance == 'web' ? 'Web' : 'Mobile';
        expect(text, contains('$product: Save'));
        expect(text, contains('$product: Default'));
        expect(text, contains('%button%'));
      }
    },
  );

  test(
    'links resolve labels, separate anchors and nullable availability',
    () async {
      await write('topics/absent.topic', '<topic id="absent" title="Absent"/>');
      await write(
        'topics/main.topic',
        '<topic id="main"><chapter id="here" title="Here"/><p><a href="target.topic"/><a href="target.topic" anchor="intro"/><a anchor="here"/><a href="https://example.com"/><a href="absent.topic" nullable="true"/></p></topic>',
      );
      final links = walk((await render()).blocks)
          .expand((block) => block.inlines)
          .where((inline) => inline.attributes['element'] == 'a')
          .toList();
      expect(links.map((link) => link.plainText), [
        'Target title',
        'Introduction',
        'Here',
        'https://example.com',
        'Absent',
      ]);
      expect(links[1].destination, endsWith('target.topic#intro'));
      expect(links[2].destination, '#here');
      expect(links.last.kind, BusyInlineKind.text);
    },
  );

  test(
    'included code uses its source topic and unsaved source overrides',
    () async {
      await write(
        'samples/sample.kt',
        '@Test\nfun chosen() {\n  println("}")\n}\nfun ignored() {}\n',
      );
      await write(
        'topics/nested/lib.topic',
        '<topic id="lib"><snippet id="s"><code-block lang="kotlin" src="sample.kt" include-symbol="chosen"/><code-block src="../../samples/sample.kt" include-lines="2-3"/></snippet></topic>',
      );
      await write(
        'topics/main.topic',
        '<topic id="main"><include from="nested/lib.topic" element-id="s"/></topic>',
      );
      final blocks = walk(
        (await render()).blocks,
      ).where((block) => block.kind == BusyBlockKind.codeBlock).toList();
      expect(
        blocks.first.plainText,
        '@Test\nfun chosen() {\n  println("}")\n}',
      );
      expect(blocks.last.plainText, 'fun chosen() {\n  println("}")');
      final updated = await render(
        overrides: {
          p.join(root.path, 'samples/sample.kt'):
              '@Test\nfun chosen() {\n  println("unsaved")\n}\n',
        },
      );
      expect(walk(updated.blocks).first.plainText, contains('unsaved'));
      expect(
        blocks.first.attributes[writersideSourceTopicPathAttribute],
        endsWith('nested/lib.topic'),
      );
    },
  );

  test(
    'summaries stay metadata and starting pages suppress outside content',
    () async {
      await write(
        'topics/main.topic',
        '<topic id="main"><link-summary>Hidden summary</link-summary><p>Outside body</p><section-starting-page><title>Start here</title><description>Visible intro</description><primary><title>Guides</title><card href="target.topic" summary="Card description"/></primary></section-starting-page></topic>',
      );
      final rendered = await render();
      final text = walk(
        rendered.blocks,
      ).map((block) => block.plainText).join(' ');
      expect(text, isNot(contains('Outside body')));
      expect(text, isNot(contains('Hidden summary')));
      expect(rendered.frontMatter['link-summary'], 'Hidden summary');
      expect(text, contains('Start here'));
      expect(text, contains('Target title'));
      expect(text, contains('Card description'));
    },
  );

  test(
    'configured shortcuts, glossary and binary resources have visible references',
    () async {
      await write(
        'cfg/buildprofiles.xml',
        '<buildprofiles><shortcuts><src>keymap.xml</src><layout name="Linux"/><layout name="macOS"/></shortcuts></buildprofiles>',
      );
      await write(
        'cfg/glossary.xml',
        '<terms><term name="HTTP">Hypertext Transfer Protocol</term></terms>',
      );
      await write(
        'keymap.xml',
        '<keymap><actions><action id="copy"><shortcut layout="Linux">Ctrl+C</shortcut><shortcut layout="macOS">Cmd+C</shortcut></action></actions></keymap>',
      );
      await write('resources/example.zip', 'binary placeholder');
      await write(
        'topics/main.topic',
        '<topic id="main"><p><shortcut key="copy"/> <tooltip term="HTTP"/> <resource src="example.zip"/></p></topic>',
      );
      final inlines = (await render()).blocks.single.inlines;
      expect(inlines.first.text, 'Ctrl+C');
      expect(
        inlines
            .singleWhere((inline) => inline.attributes['element'] == 'tooltip')
            .attributes['summary'],
        'Hypertext Transfer Protocol',
      );
      final resource = inlines.singleWhere(
        (inline) => inline.attributes['element'] == 'resource',
      );
      expect(resource.text, 'example.zip');
      expect(resource.destination, endsWith('/resources/example.zip'));
    },
  );

  test('line and symbol selectors reject invalid selections', () {
    const selection = WritersideCodeSelection();
    expect(selection.select('a\nb\nc\n', {'include-lines': '1,3'}), 'a\nc');
    expect(
      () => selection.select('a\n', {'include-lines': '0-4'}),
      throwsFormatException,
    );
    expect(
      selection.select(
        '@decorator\ndef chosen():\n    return 42\ndef other():\n    pass\n',
        {'lang': 'python', 'include-symbol': 'chosen'},
      ),
      '@decorator\ndef chosen():\n    return 42',
    );
  });
}
