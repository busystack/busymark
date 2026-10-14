import 'package:busymark/src/markdown/busymark_markdown_serializer.dart';
import 'dart:io';

import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:busymark/src/editor/wysiwyg/writerside_editing_adapter.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_inline_controller.dart';

BusyDocument parse(String source) => const MarkdownParser()
    .parse(
      filePath: 'properties.md',
      source: source,
      mode: MarkdownMode.writersideMarkdown,
    )
    .busyDocument;

void main() {
  test(
    'semantic text in a Markdown table preserves the pipe delimiter and offsets',
    () {
      const inline = BusyInline(
        kind: BusyInlineKind.writersideUiPath,
        text: 'File | Open',
      );
      final result = const BusyMarkMarkdownSerializer()
          .serializeInlineFragmentAtTextOffset(
            [inline],
            tableCell: true,
            textOffset: 6,
          );
      expect(result.source, '<ui-path>File &#124; Open</ui-path>');
      expect(result.sourceOffset, result.source.indexOf(' Open'));
    },
  );

  test('semantic XML escaping and mixed formatting retain source offsets', () {
    final inline = BusyInline(
      kind: BusyInlineKind.writersideControl,
      text: '',
      children: const [
        BusyInline(kind: BusyInlineKind.text, text: 'A & '),
        BusyInline(
          kind: BusyInlineKind.strong,
          text: '',
          children: [BusyInline(kind: BusyInlineKind.text, text: '<File>')],
        ),
      ],
    );
    final result = const BusyMarkMarkdownSerializer()
        .serializeInlineFragmentAtTextOffset([inline], textOffset: 5);
    expect(result.source, '<control>A &amp; <b>&lt;File&gt;</b></control>');
    expect(result.sourceOffset, result.source.indexOf('File'));
  });

  for (final image in [false, true]) {
    test(
      '${image ? 'Image attribute-like alt text' : 'Linked code example'} survives content edit save reopen',
      () async {
        final source = image
            ? 'See ![{id="literal"}](logo.png){id="reference" width="24"}\n'
            : 'See [`{id="literal"}`](guide.md){id="reference"}\n';
        final c = BusyMarkWysiwygDocumentController(document: parse(source));
        addTearDown(c.dispose);
        void verify(BusyBlock paragraph, String prefix) {
          expect(paragraph.attributes['id'], isNull);
          expect(paragraph.plainText, '$prefix {id="literal"}');
          final reference = paragraph.inlines.singleWhere(
            (i) =>
                i.kind == (image ? BusyInlineKind.image : BusyInlineKind.link),
          );
          expect(reference.attributes['id'], 'reference');
          expect(
            reference.attributes['busymark-writerside-attribute-token'],
            isNull,
          );
          expect(reference.destination, image ? 'logo.png' : 'guide.md');
          if (image) {
            expect(reference.text, '{id="literal"}');
            expect(reference.attributes['width'], '24');
          } else {
            expect(reference.children.single.kind, BusyInlineKind.code);
            expect(reference.children.single.text, '{id="literal"}');
          }
        }

        final paragraph = c.document.blocks.single;
        verify(paragraph, 'See');
        c.updateBlockText(paragraph.id, 'Read {id="literal"}');
        final directory = await Directory.systemTemp.createTemp(
          'reference-token-',
        );
        addTearDown(() => directory.delete(recursive: true));
        final file = File('${directory.path}/edited.md');
        await file.writeAsString(c.markdown);
        verify(parse(await file.readAsString()).blocks.single, 'Read');
        expect(
          c.markdown,
          contains(image ? '![\\{id="literal"}]' : '[`{id="literal"}`]'),
        );
        expect(c.markdown, contains('{id="reference"'));
      },
    );
  }
  for (final explicitStart in [false, true]) {
    test(
      'Ordered item conversion preserves ${explicitStart ? 'authored outer override' : 'native outer marker'} and nested start',
      () async {
        final source =
            '3. Parent\n   4. Nested first\n   5. Nested second\n4. Sibling\n'
            '${explicitStart ? '\n{start="10" id="numbered-list"}\n' : ''}';
        final c = BusyMarkWysiwygDocumentController(document: parse(source));
        addTearDown(c.dispose);
        final target = c.document.blocks.first.children.first;
        final identity = explicitStart ? 'numbered-parent' : 'marker-parent';
        expect(c.updateWritersideProperty(target.id, 'id', identity), isTrue);
        final directory = await Directory.systemTemp.createTemp(
          'numbered-list-',
        );
        addTearDown(() => directory.delete(recursive: true));
        final file = File('${directory.path}/edited.md');
        await file.writeAsString(c.markdown);
        final list = parse(await file.readAsString()).blocks.single;
        expect(list.attributes['start'], explicitStart ? '10' : '3');
        final item = list.children.firstWhere(
          (b) => b.attributes['element'] == 'li',
        );
        expect(item.attributes['id'], identity);
        final nested = item.children.singleWhere(
          (b) => b.attributes['element'] == 'list',
        );
        expect(nested.attributes['type'], 'decimal');
        expect(nested.attributes['start'], '4');
        expect(
          list.children.where((b) => b.attributes['element'] == 'li'),
          hasLength(2),
        );
        expect(
          nested.children.where((b) => b.attributes['element'] == 'li'),
          hasLength(2),
        );
        for (final fixture in [
          'property_conformance',
          'property_defaults_conformance',
        ]) {
          expect(
            File(
              'test/fixtures/writerside/$fixture/topics/properties-markdown.md',
            ).readAsStringSync(),
            contains(c.markdown.trim()),
            reason: 'The builder must check actual serialized conversion bytes',
          );
        }
      },
    );
  }
  test('nested authored list override survives parent item conversion', () async {
    const source =
        '3. Parent\n   4. Nested first\n   5. Nested second\n\n'
        '   {start="7" id="nested-list"}\n\n4. Sibling\n\n{start="10"}\n';
    final c = BusyMarkWysiwygDocumentController(document: parse(source));
    addTearDown(c.dispose);
    final parent = c.document.blocks.single.children.first;
    expect(
      c.updateWritersideProperty(parent.id, 'id', 'nested-parent'),
      isTrue,
    );
    final directory = await Directory.systemTemp.createTemp(
      'nested-list-override-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/edited.md');
    await file.writeAsString(c.markdown);
    final list = parse(await file.readAsString()).blocks.single;
    expect(list.attributes['start'], '10');
    final item = list.children.firstWhere(
      (b) => b.attributes['element'] == 'li',
    );
    final nested = item.children.singleWhere(
      (b) => b.attributes['element'] == 'list',
    );
    expect(nested.attributes['start'], '7');
    expect(nested.attributes['id'], 'nested-list');
    expect(c.markdown, isNot(contains('busymark-')));
    expect(
      File(
        'test/fixtures/writerside/property_conformance/topics/properties-markdown.md',
      ).readAsStringSync(),
      contains(c.markdown.trim()),
    );
  });
  test(
    'list-item properties under Markdown chapters use physical list ownership',
    () {
      const source =
          '# Topic\n\n## Chapter\n\n- First **item**\n- Second item\n\nAfter.\n';
      final c = BusyMarkWysiwygDocumentController(document: parse(source));
      addTearDown(c.dispose);
      final target = c.document.blocks
          .firstWhere((b) => b.attributes['element'] == 'list')
          .children
          .firstWhere((b) => b.plainText == 'Second item');
      expect(c.updateWritersideProperty(target.id, 'id', 'second'), isTrue);
      expect(c.markdown, startsWith('# Topic\n\n## Chapter\n\n'));
      expect(c.markdown, endsWith('\n\nAfter.\n'));
      final reopened = parse(c.markdown);
      final list = reopened.blocks.firstWhere(
        (b) => b.attributes['element'] == 'list',
      );
      final item = list.children
          .where((b) => b.attributes['element'] == 'li')
          .last;
      expect(item.attributes['id'], 'second');
      final next = BusyMarkWysiwygDocumentController(document: reopened);
      addTearDown(next.dispose);
      expect(
        next.elementPath(item.id).map((b) => b.plainText),
        contains('Chapter'),
      );
    },
  );
  test(
    'native list attribute line belongs to the list and remains native',
    () async {
      const source =
          '- One\n- Two\n\n{id="whole-list" instance="web"}\n\nAfter.\n';
      final c = BusyMarkWysiwygDocumentController(document: parse(source));
      addTearDown(c.dispose);
      final list = c.document.blocks.first;
      expect(list.attributes['element'], 'list');
      expect(list.attributes['id'], 'whole-list');
      expect(list.children, hasLength(2));
      expect(list.children.every((b) => b.attributes['id'] == null), isTrue);
      expect(c.markdown, source);
      expect(c.updateWritersideProperty(list.id, 'id', 'saved-list'), isTrue);
      expect(c.updateWritersideProperty(list.id, 'filter', 'release'), isTrue);
      expect(c.markdown, isNot(contains('<list')));
      final file = await File(
        '${(await Directory.systemTemp.createTemp('whole-list-')).path}/saved.md',
      ).writeAsString(c.markdown);
      addTearDown(() => file.parent.delete(recursive: true));
      final reopened = parse(await file.readAsString());
      expect(reopened.blocks.first.attributes['id'], 'saved-list');
      expect(reopened.blocks.first.attributes['filter'], 'release');
      expect(reopened.blocks.first.children, hasLength(2));
      expect(reopened.blocks.last.plainText, 'After.');
      expect(
        c.updateWritersideProperty(list.children.last.id, 'id', 'item-two'),
        isTrue,
      );
      final xmlList = parse(c.markdown).blocks.first;
      expect(xmlList.attributes['id'], 'saved-list');
      expect(xmlList.attributes['instance'], 'web');
      expect(
        xmlList.children
            .where((b) => b.attributes['element'] == 'li')
            .last
            .attributes['id'],
        'item-two',
      );
      expect(c.markdown, endsWith('After.\n'));
    },
  );
  test(
    'paragraph attribute ownership survives content editing and reopening',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'paragraph-ownership-',
      );
      addTearDown(() => directory.delete(recursive: true));
      for (final source in [
        'Use `{id="example"}`\n',
        'Use \\{id="example"\\}\n',
        'Use \\{id="example"}\n',
        'Use &#123;id="example"}\n',
        'Use \\{x.y="example"}\n',
        'Use [**link**](guide.md){id="example"}\n',
        'Use ![Logo](logo.png){id="example" width="24"}\n',
      ]) {
        final c = BusyMarkWysiwygDocumentController(document: parse(source));
        addTearDown(c.dispose);
        final paragraph = c.document.blocks.first;
        expect(paragraph.attributes['id'], isNull, reason: source);
        c.updateBlockText(
          paragraph.id,
          paragraph.plainText.replaceFirst('Use', 'Try'),
        );
        final file = File('${directory.path}/edited.md');
        await file.writeAsString(c.markdown);
        final reopened = parse(await file.readAsString()).blocks.first;
        expect(reopened.attributes['id'], isNull, reason: c.markdown);
        expect(
          reopened.plainText,
          paragraph.plainText.replaceFirst('Use', 'Try'),
        );
        if (source.contains('`')) {
          expect(reopened.inlines.last.kind, BusyInlineKind.code);
          expect(reopened.inlines.last.text, '{id="example"}');
        }
        if (source.contains('](')) {
          final reference = busyInlineReferenceRanges(reopened.inlines)
              .firstWhere(
                (r) =>
                    r.kind ==
                    (source.contains('![')
                        ? BusyInlineKind.image
                        : BusyInlineKind.link),
              );
          expect(reference.attributes['id'], 'example');
        }
      }
    },
  );
  test('native list item properties belong to the item after saving', () async {
    final directory = await Directory.systemTemp.createTemp('list-properties-');
    addTearDown(() => directory.delete(recursive: true));
    final c = BusyMarkWysiwygDocumentController(
      document: parse('- First **item**\n- Second item\n'),
    );
    addTearDown(c.dispose);
    final target = c.document.blocks.first.children[1];
    expect(c.updateWritersideProperty(target.id, 'id', 'second'), isTrue);
    expect(c.updateWritersideProperty(target.id, 'filter', 'release'), isTrue);
    final file = File('${directory.path}/list.md');
    await file.writeAsString(c.markdown);
    final reopened = parse(await file.readAsString());
    final list = reopened.blocks.first;
    expect(list.attributes['element'], 'list');
    expect(list.attributes['id'], isNull);
    final items = list.children
        .where((b) => b.attributes['element'] == 'li')
        .toList();
    expect(items.first.attributes['id'], isNull);
    expect(items[1].attributes['id'], 'second', reason: c.markdown);
    expect(items[1].attributes['filter'], 'release');
    expect(
      items.first.children.where((b) => !b.isSourceOnly).first.plainText,
      contains('First item'),
    );
    expect(c.updateWritersideProperty(target.id, 'id', null), isTrue);
    expect(
      parse(c.markdown).blocks.first.children
          .where((b) => b.attributes['element'] == 'li')
          .last
          .attributes['id'],
      isNull,
    );
  });
  test(
    'task item overrides preserve checks through XML and later edits',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'task-properties-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final c = BusyMarkWysiwygDocumentController(
        document: parse('- [x] Checked **item**\n- [ ] Unchecked item\n'),
      );
      addTearDown(c.dispose);
      final target = c.document.blocks.first.children.last;
      expect(c.updateWritersideProperty(target.id, 'id', 'task-item'), isTrue);
      expect(c.updateWritersideProperty(target.id, 'instance', 'web'), isTrue);
      final file = File('${directory.path}/tasks.md');
      await file.writeAsString(c.markdown);
      final reopened = parse(await file.readAsString());
      final items = reopened.blocks.first.children
          .where((b) => b.attributes['element'] == 'li')
          .toList();
      expect(
        items.map((b) => b.kind),
        everyElement(BusyBlockKind.taskListItem),
      );
      expect(items.first.attributes['task'], 'true');
      expect(items.last.attributes['task'], 'false');
      expect(items.last.attributes['id'], 'task-item');
      expect(items.last.attributes['instance'], 'web');
      expect(c.markdown, isNot(contains(' task=')));
      final next = BusyMarkWysiwygDocumentController(document: reopened);
      addTearDown(next.dispose);
      expect(
        next.updateWritersideProperty(items.last.id, 'id', 'updated-task'),
        isTrue,
      );
      next.toggleTaskChecked([items.last.id]);
      expect(
        parse(next.markdown).blocks.first.children
            .where((b) => b.attributes['element'] == 'li')
            .last
            .attributes['task'],
        'true',
      );
      expect(next.markdown, contains('id="updated-task"'));
      expect(
        next.updateWritersideProperty(items.last.id, 'checked', 'false'),
        isTrue,
      );
      expect(next.blockById(items.last.id)!.attributes['task'], 'false');
      expect(
        next.updateWritersideProperty(items.last.id, 'checked', 'invalid'),
        isFalse,
      );
      await file.writeAsString(next.markdown);
      expect(
        parse(await file.readAsString()).blocks.first.children
            .where((b) => b.attributes['element'] == 'li')
            .last
            .attributes['checked'],
        'false',
      );
    },
  );
  test('native admonition properties survive edits save and reopen', () async {
    final directory = await Directory.systemTemp.createTemp(
      'admonition-properties-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final c = BusyMarkWysiwygDocumentController(
      document: parse('> A **note**.\n{style="note"}\n'),
    );
    addTearDown(c.dispose);
    final block = c.document.blocks.first;
    expect(c.updateWritersideProperty(block.id, 'id', 'note-id'), isTrue);
    expect(c.updateWritersideProperty(block.id, 'filter', 'release'), isTrue);
    final file = File('${directory.path}/note.md');
    await file.writeAsString(c.markdown);
    final reopened = parse(await file.readAsString()).blocks.first;
    expect(reopened.attributes['id'], 'note-id');
    expect(reopened.attributes['filter'], 'release');
    expect(reopened.attributes['style'], 'note', reason: c.markdown);
    expect(c.updateWritersideProperty(block.id, 'id', null), isTrue);
    expect(parse(c.markdown).blocks.first.attributes['id'], isNull);
  });
  test(
    'native heading and paragraph attributes cannot replace projection metadata',
    () {
      for (final source in [
        '## Heading {level="6" element="topic" id="before"}\n',
        'Paragraph {element="topic" language="opaque" id="before"}\n',
        'Paragraph {x.y="opaque" id="before"}\n',
      ]) {
        final c = BusyMarkWysiwygDocumentController(document: parse(source));
        final block = c.document.blocks.first;
        expect(block.attributes['element'], isNull);
        if (block.kind == BusyBlockKind.heading) {
          expect(block.attributes['level'], '2');
        }
        expect(c.updateWritersideProperty(block.id, 'id', 'after'), isTrue);
        expect(c.markdown, source.replaceFirst('id="before"', 'id="after"'));
        c.updateBlockText(block.id, 'Changed');
        if (source.contains('element=')) {
          expect(c.markdown, contains('element="topic"'));
        }
        if (block.kind == BusyBlockKind.heading) {
          expect(c.markdown, startsWith('## Changed'));
          expect(c.markdown, contains('level="6"'));
        } else if (source.contains('language=')) {
          expect(c.markdown, contains('language="opaque"'));
        } else {
          expect(c.markdown, contains('x.y="opaque"'));
        }
      }
    },
  );
  test('native code attributes preserve authored projection names', () {
    const source =
        '```dart\nfinal answer = 42;\n```\n{language="opaque" element="p" level="9" id="before"}\n';
    final c = BusyMarkWysiwygDocumentController(document: parse(source));
    final block = c.document.blocks.first;
    expect(block.attributes['language'], 'dart');
    expect(block.attributes['element'], isNull);
    expect(c.updateWritersideProperty(block.id, 'id', 'after'), isTrue);
    expect(c.markdown, source.replaceFirst('id="before"', 'id="after"'));
    c.applyCodeBlockLanguage(block.id, 'java');
    final reopened = parse(c.markdown).blocks.first;
    expect(reopened.attributes['language'], 'java');
    expect(c.markdown, contains('language="opaque" element="p" level="9"'));
    expect(
      WritersideEditingAdapter.sourceAttributes(reopened)['language'],
      'opaque',
    );
    c.updateBlockText(block.id, 'final answer = 43;');
    expect(c.markdown, contains('language="opaque" element="p" level="9"'));
    expect(parse(c.markdown).blocks.first.attributes['language'], 'java');
  });
  test(
    'native language editing updates an authored override and resets it',
    () {
      const source = '```java\nhello\n```\n{id="code" lang="text"}\n';
      final c = BusyMarkWysiwygDocumentController(document: parse(source));
      final block = c.document.blocks.first;
      expect(block.attributes['language'], 'text');
      expect(c.updateWritersideProperty(block.id, 'language', 'dart'), isTrue);
      expect(c.markdown, source.replaceFirst('lang="text"', 'lang="dart"'));
      expect(parse(c.markdown).blocks.first.attributes['language'], 'dart');
      expect(c.updateWritersideProperty(block.id, 'language', null), isTrue);
      expect(parse(c.markdown).blocks.first.attributes['language'], 'java');
      expect(c.markdown, '```java\nhello\n```\n{id="code"}\n');
    },
  );
  test(
    'ignored native href is inspectable and a destination edit replaces it safely',
    () {
      const source =
          'Read [**one**][guide]{href="ignored.topic" id="link"}.\n\n[guide]: first.topic\n';
      final c = BusyMarkWysiwygDocumentController(document: parse(source));
      final block = c.document.blocks.first;
      final target = busyInlineReferenceRanges(block.inlines).first;
      expect(target.destination, 'first.topic');
      expect(target.attributes['busymark-ignored-href'], 'ignored.topic');
      expect(
        c.updateInlineReference(block.id, target, 'href', 'second.topic'),
        isTrue,
      );
      expect(
        c.markdown,
        source.replaceFirst(
          '[**one**][guide]{href="ignored.topic" id="link"}',
          '[**one**](second.topic){id="link"}',
        ),
      );
    },
  );
  test('explicit empty alternative text survives native and XML image edits', () {
    for (final xml in [false, true]) {
      final c = BusyMarkWysiwygDocumentController(
        document: xml
            ? const WritersideEditingAdapter().parseXml(
                filePath: 't.topic',
                source:
                    '<topic id="t" title="Title"><img src="logo.png" alt="Logo"/></topic>',
              )!
            : parse('![Logo](logo.png)\n'),
      );
      final image = xml
          ? c.document.blocks.first.children.single
          : c.document.blocks.first;
      expect(
        c.updateWritersideProperty(image.id, 'alt', ''),
        isTrue,
        reason:
            'xml=$xml kind=${image.kind} attrs=${image.attributes} protected=${image.isSourceProtected}',
      );
      expect(c.markdown, contains('alt=""'));
      final reopened = xml
          ? const WritersideEditingAdapter()
                .parseXml(filePath: 't.topic', source: c.markdown)!
                .blocks
                .first
                .children
                .single
          : parse(c.markdown).blocks.first;
      expect(reopened.attributes['alt'], '');
    }
  });
  test(
    'native image source and alt overrides keep reference definitions local',
    () {
      const source =
          'Before [![Logo][logo]](guide.md) after.\n\n[logo]: logo.png "Title"\n';
      final c = BusyMarkWysiwygDocumentController(document: parse(source));
      final block = c.document.blocks.first;
      BusyInlineStyleRange image() => busyInlineReferenceRanges(
        c.document.blocks.first.inlines,
      ).firstWhere((r) => r.kind == BusyInlineKind.image);
      expect(
        c.updateInlineReference(block.id, image(), 'src', 'other.png'),
        isTrue,
      );
      expect(
        c.updateInlineReference(block.id, image(), 'alt', 'Different'),
        isTrue,
      );
      expect(
        c.markdown,
        source.replaceFirst(
          '[logo]',
          '[logo]{src="other.png" alt="Different"}',
        ),
      );
      final actual = busyInlineReferenceRanges(
        parse(c.markdown).blocks.first.inlines,
      ).firstWhere((r) => r.kind == BusyInlineKind.image);
      expect(actual.destination, 'other.png');
      expect(actual.attributes['alt'], 'Different');
      expect(
        c.updateInlineReference(block.id, image(), 'src', ''),
        isFalse,
        reason:
            'src remains required; reset of a local source override must use its native source',
      );
    },
  );
  test(
    'native block image source and alt overrides preserve reference wrappers',
    () {
      const source = '[![Logo][logo]](guide.md)\n\n[logo]: logo.png\n';
      final c = BusyMarkWysiwygDocumentController(document: parse(source));
      final id = c.document.blocks.first.id;
      expect(c.updateWritersideProperty(id, 'src', 'other.png'), isTrue);
      expect(c.updateWritersideProperty(id, 'alt', 'Different'), isTrue);
      expect(
        c.markdown,
        source.replaceFirst(
          '](guide.md)',
          '{src="other.png" alt="Different"}](guide.md)',
        ),
      );
      final reopened = parse(c.markdown).blocks.first;
      expect(reopened.attributes['src'], 'other.png');
      expect(reopened.attributes['alt'], 'Different');
    },
  );
  test(
    'native link destination changes only one occurrence and keeps definitions',
    () {
      const source =
          'Read [one][guide] and [two][guide].\n\n[guide]: first.topic\n';
      final c = BusyMarkWysiwygDocumentController(document: parse(source));
      final block = c.document.blocks.first;
      final target = busyInlineReferenceRanges(block.inlines).first;
      expect(
        c.updateInlineReference(block.id, target, 'href', 'second.topic'),
        isTrue,
      );
      expect(
        c.markdown,
        source.replaceFirst('[one][guide]', '[one](second.topic)'),
      );
      final actual = busyInlineReferenceRanges(
        parse(c.markdown).blocks.first.inlines,
      );
      expect(actual.map((r) => r.destination), ['second.topic', 'first.topic']);
    },
  );
  test(
    'inline reference scalar edits retain authored syntax and unrelated bytes',
    () {
      const source =
          'Before [![Logo][logo]](guide.md) after.\r\n\r\n[logo]: logo.png "Logo title"\r\n';
      final c = BusyMarkWysiwygDocumentController(document: parse(source));
      final block = c.document.blocks.first;
      final range = busyInlineReferenceRanges(
        block.inlines,
      ).firstWhere((r) => r.kind == BusyInlineKind.image);
      expect(c.updateInlineReference(block.id, range, 'width', '80'), isTrue);
      expect(c.markdown, source.replaceFirst('[logo]', '[logo]{width="80"}'));
      final actual = busyInlineReferenceRanges(
        parse(c.markdown).blocks.first.inlines,
      ).firstWhere((r) => r.kind == BusyInlineKind.image);
      expect(actual.attributes['width'], '80');
    },
  );
  test('XML add and reset preserve whitespace before the closing delimiter', () {
    for (final closing in [' >', '  />', '\n  >']) {
      final content = closing.endsWith('/>') ? '' : 'code</code-block>';
      final source =
          '<topic id="t" title="Title"><code-block lang="text"$closing$content</topic>';
      BusyMarkWysiwygDocumentController editor(String text) =>
          BusyMarkWysiwygDocumentController(
            document: const WritersideEditingAdapter().parseXml(
              filePath: 't.topic',
              source: text,
            )!,
          );
      final first = editor(source);
      expect(
        first.updateWritersideProperty(
          first.document.blocks.first.children.single.id,
          'collapsible',
          'false',
        ),
        isTrue,
      );
      final reopened = editor(first.markdown);
      expect(
        reopened.updateWritersideProperty(
          reopened.document.blocks.first.children.single.id,
          'collapsible',
          null,
        ),
        isTrue,
      );
      expect(reopened.markdown, source);
      first.dispose();
      reopened.dispose();
    }
  });
  test(
    'embedded XML property edit preserves namespaces, quotes, comments and formatted title',
    () {
      const source =
          "Before.\n\n<chapter xmlns='https://writerside.jetbrains.com' id='c'><title>Install <b>now</b></title><!-- retain --><p>Body</p></chapter>\n\nAfter.\n";
      final c = BusyMarkWysiwygDocumentController(document: parse(source));
      final chapter = c.document.blocks.firstWhere(
        (b) => b.attributes['element'] == 'chapter',
      );
      expect(
        c.updateWritersideProperty(chapter.id, 'collapsible', 'false'),
        isTrue,
        reason:
            '${chapter.kind} raw=${chapter.preserveRaw} protected=${chapter.isSourceProtected} ${chapter.attributes}',
      );
      expect(
        c.markdown,
        contains(
          "<chapter xmlns='https://writerside.jetbrains.com' id='c' collapsible=\"false\"><title>Install <b>now</b></title><!-- retain --><p>Body</p></chapter>",
        ),
      );
      expect(c.markdown, startsWith('Before.\n\n'));
      expect(c.markdown, endsWith('After.\n'));
      expect(c.markdown, isNot(contains('title=""')));
      expect(
        parse(c.markdown).blocks
            .firstWhere((b) => b.attributes['element'] == 'chapter')
            .attributes['collapsible'],
        'false',
      );
    },
  );
  test(
    'inline Markdown images retain their own attributes and link wrappers',
    () {
      final c = BusyMarkWysiwygDocumentController(
        document: parse(
          'One ![first](one.png) then [![second](two.png){width="120"}](guide.md).\n',
        ),
      );
      final p = c.document.blocks.first;
      final images = busyInlineReferenceRanges(
        p.inlines,
      ).where((r) => r.kind == BusyInlineKind.image).toList();
      expect(images, hasLength(2));
      expect(images.first.attributes['width'], isNull);
      expect(images.last.attributes['width'], '120');
      expect(
        c.updateInlineReference(p.id, images.first, 'width', '80'),
        isTrue,
      );
      final reopened = parse(c.markdown);
      final actual = busyInlineReferenceRanges(
        reopened.blocks.first.inlines,
      ).where((r) => r.kind == BusyInlineKind.image).toList();
      expect(actual.map((r) => r.attributes['width']), ['80', '120']);
      expect(
        reopened.blocks.first.inlines.any((i) => i.kind == BusyInlineKind.link),
        isTrue,
      );
      expect(
        c.updateInlineReference(
          p.id,
          busyInlineReferenceRanges(
            c.document.blocks.first.inlines,
          ).firstWhere((r) => r.kind == BusyInlineKind.image),
          'width',
          '',
        ),
        isTrue,
      );
      expect(
        busyInlineReferenceRanges(
          parse(c.markdown).blocks.first.inlines,
        ).firstWhere((r) => r.kind == BusyInlineKind.image).attributes['width'],
        isNull,
      );
    },
  );
  test(
    'switching file source preserves inline code and rejects mismatched content',
    () {
      final c = BusyMarkWysiwygDocumentController(
        document: parse('```text\nkeep me\n```\n'),
      );
      final code = c.document.blocks.first;
      expect(c.updateWritersideProperty(code.id, 'src', 'sample.txt'), isFalse);
      expect(c.markdown, contains('keep me'));
      final f = BusyMarkWysiwygDocumentController(
        document: parse(
          '```text\n```\n{src="sample.txt" include-lines="1-2"}\n',
        ),
      );
      expect(
        f.updateWritersideProperty(f.document.blocks.first.id, 'src', null),
        isTrue,
      );
      expect(parse(f.markdown).blocks.first.attributes['src'], isNull);
      expect(parse(f.markdown).blocks.first.attributes['include-lines'], '1-2');
    },
  );
  test(
    'Topic navigation distinguishes absence, empty, none and scoped declarations',
    () {
      const source = '<topic id="t" title="Title"><p>Text</p></topic>';
      final c = BusyMarkWysiwygDocumentController(
        document: const WritersideEditingAdapter().parseXml(
          filePath: 't.topic',
          source: source,
        )!,
      );
      expect(c.updateTopicNavigation('for', ''), isTrue);
      expect(c.markdown, contains('<show-structure/>'));
      expect(c.updateTopicNavigation('for', 'none'), isTrue);
      expect(c.markdown, contains('for="none"'));
      expect(c.resetTopicNavigation(), isTrue);
      expect(c.markdown, source);
      const scoped =
          '<topic id="t" title="Title"><show-structure instance="a" for="chapter"/><show-structure instance="b" for="none"/><p>Text</p></topic>';
      final conditional = BusyMarkWysiwygDocumentController(
        document: const WritersideEditingAdapter().parseXml(
          filePath: 't.topic',
          source: scoped,
        )!,
      );
      expect(conditional.updateTopicNavigation('for', 'none'), isFalse);
      expect(conditional.markdown, scoped);
    },
  );

  test(
    'paragraph attribute edit preserves reference syntax, Unicode and CRLF',
    () {
      const source =
          'Read **caf\u00e9** [here][ref].\r\n\r\n[ref]: guide.md "Guide"\r\n';
      final editor = BusyMarkWysiwygDocumentController(document: parse(source));
      final paragraph = editor.document.blocks.first;
      expect(
        editor.updateWritersideProperty(paragraph.id, 'id', 'intro'),
        isTrue,
      );
      expect(
        editor.markdown,
        contains('Read **caf\u00e9** [here][ref].\r\n{id="intro"}'),
      );
      expect(editor.markdown, contains('[ref]: guide.md "Guide"\r\n'));
      expect(
        parse(
          editor.markdown,
        ).blocks.first.inlines.any((i) => i.kind == BusyInlineKind.strong),
        isTrue,
      );
      expect(editor.updateWritersideProperty(paragraph.id, 'id', null), isTrue);
      expect(editor.markdown, source);
    },
  );
  test(
    'native Markdown image scalar edits preserve link and reference syntax',
    () {
      const source = '[![Logo][logo]](guide.md)\n\n[logo]: logo.png\n';
      final editor = BusyMarkWysiwygDocumentController(document: parse(source));
      final image = editor.document.blocks.firstWhere(
        (b) => b.kind == BusyBlockKind.image,
      );
      expect(editor.updateWritersideProperty(image.id, 'width', '240'), isTrue);
      expect(
        editor.markdown,
        contains('[![Logo][logo]{width="240"}](guide.md)'),
      );
      final reopened = parse(
        editor.markdown,
      ).blocks.firstWhere((b) => b.kind == BusyBlockKind.image);
      expect(reopened.attributes['width'], '240');
      expect(reopened.inlines.first.kind, BusyInlineKind.link);
    },
  );
  test(
    'XML inline image edits preserve its link wrapper and surrounding source',
    () {
      const source =
          '<topic id="t" title="Title"><p>Before <a href="guide.topic"><img src="old.png" alt="Logo" width="100"/></a><!-- keep --> after.</p></topic>';
      final editor = BusyMarkWysiwygDocumentController(
        document: const WritersideEditingAdapter().parseXml(
          filePath: 't.topic',
          source: source,
        )!,
      );
      final paragraph = editor.document.blocks.first.children.first;
      final image = busyInlineReferenceRanges(
        paragraph.inlines,
      ).firstWhere((r) => r.kind == BusyInlineKind.image);
      expect(
        editor.updateInlineReference(paragraph.id, image, 'width', '240'),
        isTrue,
      );
      final saved = editor.markdown;
      expect(
        saved,
        contains(
          '<a href="guide.topic"><img src="old.png" alt="Logo" width="240"/></a>',
        ),
      );
      expect(saved, contains('<!-- keep --> after.'));
      final reopened = const WritersideEditingAdapter().parseXml(
        filePath: 't.topic',
        source: saved,
      )!;
      expect(
        busyInlineReferenceRanges(
          reopened.blocks.first.children.first.inlines,
        ).firstWhere((r) => r.kind == BusyInlineKind.image).attributes['width'],
        '240',
      );
    },
  );
  test('escaped scalar values decode after a native fence round trip', () {
    final editor = BusyMarkWysiwygDocumentController(
      document: parse('```text\ncode\n```\n'),
    );
    final code = editor.document.blocks.first;
    const title = 'A "title" & <details>';
    expect(
      editor.updateWritersideProperty(code.id, 'collapsed-title', title),
      isTrue,
    );
    expect(
      parse(editor.markdown).blocks.first.attributes['collapsed-title'],
      title,
    );
  });
  for (final property in {
    'id': 'sample',
    'switcher-key': 'linux',
    'collapsible': 'false',
    'include-lines': '1-2',
    'emphasize-lines': '1',
    'default-state': 'expanded',
  }.entries) {
    test('fenced code ${property.key} survives editing and reopening', () {
      final editor = BusyMarkWysiwygDocumentController(
        document: parse('```dart\na\nb\n```\n'),
      );
      final code = editor.document.blocks.firstWhere(
        (b) => b.kind == BusyBlockKind.codeBlock,
      );
      expect(
        editor.updateWritersideProperty(code.id, property.key, property.value),
        isTrue,
      );
      final reopened = parse(editor.markdown);
      expect(
        reopened.blocks.where((b) => b.kind == BusyBlockKind.codeBlock),
        hasLength(1),
      );
      expect(
        reopened.blocks
            .firstWhere((b) => b.kind == BusyBlockKind.codeBlock)
            .attributes[property.key],
        property.value,
      );
    });
  }
  test('a file-backed fence does not author collapse', () {
    final editor = BusyMarkWysiwygDocumentController(
      document: parse('```dart\n\n```\n'),
    );
    expect(
      editor.updateWritersideProperty(
        editor.document.blocks
            .firstWhere((b) => b.kind == BusyBlockKind.codeBlock)
            .id,
        'src',
        'sample.dart',
      ),
      isTrue,
    );
    final reopened = parse(editor.markdown);
    expect(
      reopened.blocks
          .firstWhere((b) => b.kind == BusyBlockKind.codeBlock)
          .attributes['src'],
      'sample.dart',
    );
    expect(
      reopened.blocks
          .firstWhere((b) => b.kind == BusyBlockKind.codeBlock)
          .attributes['collapsible'],
      isNull,
    );
  });
  test('paragraph ID preserves Markdown inline formatting', () {
    final editor = BusyMarkWysiwygDocumentController(
      document: parse('Hello **world**.\n'),
    );
    expect(
      editor.updateWritersideProperty(
        editor.document.blocks.single.id,
        'id',
        'intro',
      ),
      isTrue,
    );
    expect(editor.markdown, contains('Hello **world**.'));
    expect(parse(editor.markdown).blocks.single.attributes['id'], 'intro');
  });
  test('explicit false survives heading serialization', () {
    final editor = BusyMarkWysiwygDocumentController(
      document: parse('## Chapter\n'),
    );
    expect(
      editor.updateWritersideProperty(
        editor.document.blocks.single.id,
        'collapsible',
        'false',
      ),
      isTrue,
    );
    expect(
      parse(editor.markdown).blocks.single.attributes['collapsible'],
      'false',
    );
  });
  test('optional enum removal is separate from setting a value', () {
    final editor = BusyMarkWysiwygDocumentController(
      document: parse('## Chapter {default-state="expanded"}\n'),
    );
    expect(
      editor.updateWritersideProperty(
        editor.document.blocks.single.id,
        'default-state',
        '',
      ),
      isTrue,
    );
    expect(
      parse(editor.markdown).blocks.single.attributes['default-state'],
      isNull,
    );
  });
}
