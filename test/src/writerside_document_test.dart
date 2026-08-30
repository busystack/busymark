import 'dart:io';

import 'package:busymark/src/markdown/preview_model.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/writerside/writerside_document.dart';
import 'package:busymark/src/writerside/writerside_document_parser.dart';
import 'package:busymark/src/writerside/writerside_document_renderer.dart';
import 'package:busymark/src/writerside/writerside_document_resolver.dart';
import 'package:busymark/src/writerside/writerside_document_serializer.dart';
import 'package:busymark/src/writerside/writerside_module_service.dart';
import 'package:busymark/src/writerside/writerside_schema.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'lossless XML nodes preserve exact duplicate ranges and generic markup',
    () {
      const source = '''<?xml version="1.0"?>
<topic id="ranges" title="Ranges">
  <p data-custom="first">same</p>
  <p data-custom="second">same</p>
  <search-keyword custom="kept">semantic search</search-keyword>
</topic>''';
      final document = const WritersideDocumentParser().parseXml(
        filePath: '/tmp/ranges.topic',
        source: source,
      );
      final paragraphs = document.elements
          .where((element) => element.name == 'p')
          .toList();

      expect(document.isWellFormed, isTrue);
      expect(paragraphs, hasLength(2));
      expect(
        paragraphs[0].span.startOffset,
        isNot(paragraphs[1].span.startOffset),
      );
      expect(paragraphs[0].rawSource, '<p data-custom="first">same</p>');
      expect(paragraphs[1].attributes['data-custom'], 'second');
      final generic = document.elements.singleWhere(
        (element) => element.name == 'search-keyword',
      );
      expect(generic, isA<WritersideGenericElementNode>());
      expect(generic.schemaKnown, isTrue);
      expect(generic.attributes['custom'], 'kept');
      expect(const WritersideDocumentSerializer().serialize(document), source);
      expect(WritersideSchema.builderVersion, '2026.07.8925');
    },
  );

  test('Writerside Markdown round-trips native and generic markup', () {
    const source = '''# Semantic Markdown

<quote author="BusyMark">Known semantic markup.</quote>

<card custom="preserved">Generic schema content.</card>
''';
    final markdown = const MarkdownParser().parse(
      filePath: '/tmp/semantic.md',
      source: source,
      mode: MarkdownMode.writersideMarkdown,
      validateLocalReferences: false,
    );
    final document = const WritersideDocumentParser().parseMarkdown(
      filePath: markdown.filePath,
      source: source,
      markdown: markdown.busyDocument,
    );

    expect(document.format, WritersideDocumentFormat.markdown);
    expect(
      document.elements.singleWhere((element) => element.name == 'card'),
      isA<WritersideGenericElementNode>(),
    );
    expect(const WritersideDocumentSerializer().serialize(document), source);
  });

  test(
    'resolver applies includes, filters, groups, variables, and cycles',
    () async {
      final fixture = await _ResolvedFixture.create();
      addTearDown(fixture.dispose);
      final module = await const WritersideModuleService().load(fixture.path);
      final topic = module.topicByReference('main.topic')!;
      final instance = module.instances.single;

      final resolved = const WritersideDocumentResolver().resolve(
        topic.document,
        WritersideResolveContext(
          module: module,
          topic: topic,
          instance: instance,
        ),
      );
      final busy = const WritersideDocumentRenderer().toBusyDocument(
        resolved.document,
        title: resolved.title,
      );
      final text = _documentText(busy.blocks);
      final preview = const BusyMarkPreviewBuilder().build(busy);

      expect(text, contains('Hello BusyMark'));
      expect(text, contains('Linux only'));
      expect(text, contains('Nested content'));
      expect(text, isNot(contains('Windows only')));
      expect(text, isNot(contains('Excluded from guide')));
      expect(
        resolved.diagnostics.map((diagnostic) => diagnostic.code),
        contains('writerside.include.cycle'),
      );
      expect(_previewText(preview.blocks), contains('Hello BusyMark'));
    },
  );
}

String _documentText(Iterable<BusyBlock> blocks) {
  final buffer = StringBuffer();
  for (final block in blocks) {
    buffer.writeln(block.plainText);
    buffer.writeln(_documentText(block.children));
  }
  return buffer.toString();
}

String _previewText(Iterable<PreviewBlock> blocks) => [
  for (final block in blocks) ...[block.text, _previewText(block.children)],
].join('\n');

class _ResolvedFixture {
  const _ResolvedFixture(this.directory);

  final Directory directory;
  String get path => directory.path;

  static Future<_ResolvedFixture> create() async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-writerside-resolver-',
    );
    final topics = await Directory(p.join(directory.path, 'topics')).create();
    await File(p.join(directory.path, 'writerside.cfg')).writeAsString('''
<ihp version="2026.2">
  <module name="resolver-docs"/>
  <topics dir="topics"/>
  <vars src="v.list"/>
  <instance-groups src="groups.xml"/>
  <instance src="guide.tree"/>
</ihp>
''');
    await File(
      p.join(directory.path, 'v.list'),
    ).writeAsString('<vars><var name="product" value="Default"/></vars>');
    await File(p.join(directory.path, 'groups.xml')).writeAsString(
      '<instance-groups><group id="desktop" instances="guide"/>'
      '</instance-groups>',
    );
    await File(p.join(directory.path, 'guide.tree')).writeAsString('''
<instance-profile id="guide" name="Guide" start-page="main.topic">
  <toc-element topic="main.topic"/>
</instance-profile>
''');
    await File(p.join(topics.path, 'main.topic')).writeAsString('''
<topic id="main" title="Main">
  <include from="library.topic" element-id="shared" use-filter="linux">
    <var name="product" value="BusyMark"/>
  </include>
  <include from="library.topic" element-id="cycle"/>
</topic>
''');
    await File(p.join(topics.path, 'library.topic')).writeAsString('''
<topic id="library" title="Library">
  <snippet id="shared">
    <p>Hello %product%</p>
    <p filter="windows">Windows only</p>
    <p filter="linux" instance="@desktop">Linux only</p>
    <p instance="!guide">Excluded from guide</p>
    <include element-id="nested"/>
  </snippet>
  <snippet id="nested"><p>Nested content</p></snippet>
  <snippet id="cycle"><include element-id="cycle"/></snippet>
</topic>
''');
    return _ResolvedFixture(directory);
  }

  Future<void> dispose() => directory.delete(recursive: true);
}
