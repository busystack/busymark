import 'dart:io';

import 'package:busymark/src/core/diagnostic.dart';
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
import 'package:busymark/src/workspace/workspace_service.dart';
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

  test('modified semantic XML reconstructs equivalent escaped markup', () {
    const source = '''<?xml version="1.0"?>
<topic id="modified" title="Before"><p data-custom="kept">Before</p></topic>''';
    final document = const WritersideDocumentParser().parseXml(
      filePath: '/tmp/modified.topic',
      source: source,
    );
    final root = document.rootElement!;
    final paragraph = root.children.whereType<WritersideElementNode>().single;
    final text = paragraph.children.whereType<WritersideTextNode>().single;
    final changedParagraph = paragraph.copyWith(
      attributes: {...paragraph.attributes, 'data-added': 'A & B'},
      children: [text.copyWith(text: 'After & <safe>')],
    );
    final changedRoot = root.copyWith(children: [changedParagraph]);
    final changed = document.copyWith(
      nodes: [document.nodes.first, changedRoot],
    );

    final serialized = const WritersideDocumentSerializer().serialize(changed);
    final reparsed = const WritersideDocumentParser().parseXml(
      filePath: document.filePath,
      source: serialized,
    );

    expect(serialized, contains('data-custom="kept"'));
    expect(serialized, contains('data-added="A &amp; B"'));
    expect(reparsed.isWellFormed, isTrue);
    expect(reparsed.rootElement!.plainText, 'After & <safe>');
  });

  test(
    'resolver applies includes, filters, groups, variables, and cycles',
    () async {
      final fixture = await _ResolvedFixture.create();
      addTearDown(fixture.dispose);
      final module = await const WritersideModuleService().load(fixture.path);
      final topic = module.topicByReference('main.topic')!;
      final instance = module.instances.singleWhere(
        (instance) => instance.id == 'guide',
      );

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
      expect(text, contains('Filtered only'));
      expect(text, isNot(contains('Unfiltered should be absent')));
      expect(text, isNot(contains('Windows only')));
      expect(text, isNot(contains('Excluded from guide')));
      expect(text, contains('guide|main|%escaped%'));
      expect(
        resolved.diagnostics.map((diagnostic) => diagnostic.code),
        contains('writerside.include.cycle'),
      );
      expect(_previewText(preview.blocks), contains('Hello BusyMark'));
    },
  );

  test('resolver negates the complete instance list', () async {
    final fixture = await _ResolvedFixture.create();
    addTearDown(fixture.dispose);
    final module = await const WritersideModuleService().load(fixture.path);
    final topic = module.topicByReference('main.topic')!;

    String resolveFor(String instanceId) {
      final resolved = const WritersideDocumentResolver().resolve(
        topic.document,
        WritersideResolveContext(
          module: module,
          topic: topic,
          instance: module.instances.singleWhere(
            (instance) => instance.id == instanceId,
          ),
        ),
      );
      return _documentText(
        const WritersideDocumentRenderer()
            .toBusyDocument(resolved.document)
            .blocks,
      );
    }

    expect(resolveFor('foo'), isNot(contains('Not foo or bar')));
    expect(resolveFor('bar'), isNot(contains('Not foo or bar')));
    expect(resolveFor('other'), contains('Not foo or bar'));
  });

  test('XML list type is inherited by every list item', () {
    const source = '''<topic id="lists" title="Lists">
  <list type="decimal" start="2"><li>Two</li><li>Three</li></list>
  <list type="alpha-lower"><li>Alpha</li></list>
  <list type="checkbox"><li checked="true">Done</li><li>Open</li></list>
  <list type="none"><li>Plain</li></list>
</topic>''';
    final document = const WritersideDocumentParser().parseXml(
      filePath: '/tmp/lists.topic',
      source: source,
    );
    final blocks = const WritersideDocumentRenderer()
        .toBusyDocument(document)
        .blocks;

    expect(blocks.map((block) => block.attributes['marker']), [
      '2.',
      '3.',
      'a.',
      '-',
      '-',
      '',
    ]);
    expect(blocks[2].attributes['listType'], 'alpha-lower');
    expect(blocks[3].kind, BusyBlockKind.taskListItem);
    expect(blocks[3].attributes['task'], 'true');
    expect(blocks[4].attributes['task'], 'false');
    expect(blocks[5].attributes['markerHidden'], 'true');
  });

  test('workspace exposes resolver errors with exact source spans', () async {
    final fixture = await _ResolvedFixture.create();
    addTearDown(fixture.dispose);

    final workspace = await const WorkspaceService().openPath(fixture.path);
    final cycle = workspace.diagnostics.singleWhere(
      (diagnostic) => diagnostic.code == 'writerside.include.cycle',
    );

    expect(cycle.severity, DiagnosticSeverity.error);
    expect(cycle.sourceSpan, isNotNull);
    expect(cycle.sourceSpan!.filePath, endsWith('library.topic'));
  });
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
  <instance src="foo.tree"/>
  <instance src="bar.tree"/>
  <instance src="other.tree"/>
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
    for (final id in ['foo', 'bar', 'other']) {
      await File(p.join(directory.path, '$id.tree')).writeAsString('''
<instance-profile id="$id" name="$id" start-page="main.topic">
  <toc-element topic="main.topic"/>
</instance-profile>
''');
    }
    await File(p.join(topics.path, 'main.topic')).writeAsString('''
<topic id="main" title="Main">
  <include from="library.topic" element-id="shared" use-filter="empty,linux">
    <var name="product" value="BusyMark"/>
  </include>
  <include from="library.topic" element-id="filtered-only" use-filter="linux"/>
  <include from="library.topic" element-id="cycle"/>
  <p>%currentId%|%thisTopic%|%\\escaped%</p>
</topic>
''');
    await File(p.join(topics.path, 'library.topic')).writeAsString('''
<topic id="library" title="Library">
  <snippet id="shared">
    <p>Hello %product%</p>
    <p filter="windows">Windows only</p>
    <p filter="linux" instance="@desktop">Linux only</p>
    <p instance="!guide">Excluded from guide</p>
    <p instance="!foo,bar">Not foo or bar</p>
    <include element-id="nested"/>
  </snippet>
  <snippet id="filtered-only">
    <p>Unfiltered should be absent</p>
    <p filter="linux">Filtered only</p>
  </snippet>
  <snippet id="nested"><p>Nested content</p></snippet>
  <snippet id="cycle"><include element-id="cycle"/></snippet>
</topic>
''');
    return _ResolvedFixture(directory);
  }

  Future<void> dispose() => directory.delete(recursive: true);
}
