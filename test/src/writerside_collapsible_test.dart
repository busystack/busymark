import 'dart:io';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/editor/document_collapsible.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/busymark_markdown_serializer.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/markdown/preview_model.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  const parser = MarkdownParser();
  const previewBuilder = BusyMarkPreviewBuilder();

  test('Writerside Markdown collapsible chapter owns its section', () {
    const source = '''## Advanced {collapsible="true"}

Hidden paragraph.

### Nested

Nested paragraph.

## Next

Visible paragraph.
''';
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: source,
      mode: MarkdownMode.writersideMarkdown,
      validateLocalReferences: false,
    );
    final heading = parsed.busyDocument.blocks.first;
    expect(busyMarkWritersideIsCollapsible(heading.attributes), isTrue);

    final preview = previewBuilder.build(parsed.busyDocument);
    expect(preview.blocks, hasLength(3));
    expect(preview.blocks.first.text, 'Advanced');
    expect(preview.blocks.first.children.map((block) => block.text), [
      'Hidden paragraph.',
      'Nested',
      'Nested paragraph.',
    ]);
    expect(preview.blocks[1].text, 'Next');
    expect(
      const BusyMarkMarkdownSerializer().serialize(parsed.busyDocument),
      source,
    );
  });

  test('ordinary Markdown keeps Writerside collapse syntax literal', () {
    const source = '''## Advanced {collapsible="true"}

Paragraph.
''';
    final parsed = parser.parse(
      filePath: 'README.md',
      source: source,
      mode: MarkdownMode.commonMark,
      validateLocalReferences: false,
    );
    final heading = parsed.busyDocument.blocks.first;
    expect(heading.plainText, 'Advanced {collapsible="true"}');
    expect(heading.attributes[busyMarkWritersideCollapsibleAttribute], isNull);
    expect(previewBuilder.build(parsed.busyDocument).blocks, hasLength(2));
  });

  test('ordinary Markdown does not assign semantic Writerside collapse', () {
    const source = '''<chapter title="Details" collapsible="true">
  <p>Body.</p>
</chapter>
''';
    final parsed = parser.parse(
      filePath: 'README.md',
      source: source,
      mode: MarkdownMode.commonMark,
      validateLocalReferences: false,
    );

    expect(
      parsed.busyDocument.blocks.any(
        (block) => busyMarkWritersideIsCollapsible(block.attributes),
      ),
      isFalse,
    );
    expect(
      previewBuilder
          .build(parsed.busyDocument)
          .blocks
          .any((block) => busyMarkWritersideIsCollapsible(block.attributes)),
      isFalse,
    );
  });

  test('Writerside fenced code consumes its collapsible attribute line', () {
    const source = '''```kotlin
data class Person(val name: String)
```
{collapsible="true" collapsed-title="Person.kt" default-state="expanded"}
''';
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: source,
      mode: MarkdownMode.writersideMarkdown,
      validateLocalReferences: false,
    );
    final block = parsed.busyDocument.blocks.single;
    expect(block.kind, BusyBlockKind.codeBlock);
    expect(busyMarkWritersideIsCollapsible(block.attributes), isTrue);
    expect(
      block.attributes[busyMarkWritersideCollapsedTitleAttribute],
      'Person.kt',
    );
    expect(busyMarkWritersideInitiallyExpanded(block.attributes), isTrue);
    expect(
      const BusyMarkMarkdownSerializer().serialize(parsed.busyDocument),
      source,
    );
  });

  test('edited collapsible blocks serialize valid Writerside attributes', () {
    final parsedHeading = parser.parse(
      filePath: 'topic.md',
      source: '## Before {collapsible="true" default-state="expanded"}\n',
      mode: MarkdownMode.writersideMarkdown,
      validateLocalReferences: false,
    );
    final heading = parsedHeading.busyDocument.blocks.single.copyWith(
      inlines: const [BusyInline(kind: BusyInlineKind.text, text: 'After')],
      preserveRaw: false,
      dirty: true,
    );
    expect(
      const BusyMarkMarkdownSerializer().serialize(
        parsedHeading.busyDocument.copyWith(blocks: [heading]),
      ),
      '## After {collapsible="true" default-state="expanded"}\n',
    );

    final parsedCode = parser.parse(
      filePath: 'topic.md',
      source: '''```text
before
```
{collapsible="true" collapsed-title="Output"}
''',
      mode: MarkdownMode.writersideMarkdown,
      validateLocalReferences: false,
    );
    final code = parsedCode.busyDocument.blocks.single.copyWith(
      inlines: const [BusyInline(kind: BusyInlineKind.text, text: 'after')],
      preserveRaw: false,
      dirty: true,
    );
    expect(
      const BusyMarkMarkdownSerializer().serialize(
        parsedCode.busyDocument.copyWith(blocks: [code]),
      ),
      '''```text
after
```
{collapsible="true" collapsed-title="Output"}
''',
    );
  });

  test('ordinary fenced code does not consume a collapse attribute line', () {
    const source = '''```text
value
```
{collapsible="true"}
''';
    final parsed = parser.parse(
      filePath: 'README.md',
      source: source,
      mode: MarkdownMode.commonMark,
      validateLocalReferences: false,
    );
    expect(parsed.busyDocument.blocks, hasLength(2));
    expect(parsed.busyDocument.blocks.last.plainText, '{collapsible="true"}');
  });

  test('semantic collapsible elements become structured preview content', () {
    const source =
        '''<chapter title="Details" collapsible="true" default-state="expanded">
  <p>Chapter body.</p>
</chapter>

<procedure title="Build" collapsible="true">
  <step><p>Compile.</p></step>
  <step><p>Package.</p></step>
</procedure>

<code-block lang="kotlin" collapsible="true" collapsed-title="Main.kt">
fun main() = Unit
</code-block>

<deflist collapsible="true">
  <def title="Expanded" default-state="expanded"><p>First.</p></def>
  <def title="Collapsed" default-state="collapsed"><p>Second.</p></def>
</deflist>
''';
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: source,
      mode: MarkdownMode.writersideMarkdown,
      validateLocalReferences: false,
    );
    final preview = previewBuilder.build(parsed.busyDocument).blocks;

    final chapterSpan = parsed.busyDocument.blocks.first.sourceSpan!;
    final chapterSource = source.substring(
      chapterSpan.startOffset,
      chapterSpan.endOffset,
    );
    expect(chapterSource, contains('<chapter title="Details"'));
    expect(chapterSource, contains('Chapter body.'));
    expect(preview.map((block) => block.kind), [
      PreviewBlockKind.heading,
      PreviewBlockKind.procedure,
      PreviewBlockKind.code,
      PreviewBlockKind.definitionList,
    ]);
    expect(preview[0].children.single.text, 'Chapter body.');
    expect(preview[1].children, hasLength(2));
    expect(preview[1].children.first.kind, PreviewBlockKind.list);
    expect(preview[2].language, 'kotlin');
    expect(preview[2].text, 'fun main() = Unit');
    expect(preview[3].children, hasLength(2));
    expect(
      busyMarkWritersideInitiallyExpanded(preview[3].children.first.attributes),
      isTrue,
    );
    expect(
      const BusyMarkMarkdownSerializer().serialize(parsed.busyDocument),
      source,
    );
  });

  test(
    'Writerside XML topic preview keeps collapsible content nested',
    () async {
      final root = Directory.systemTemp.createTempSync('busymark-collapse-');
      addTearDown(() => root.deleteSync(recursive: true));
      final topics = Directory(p.join(root.path, 'topics'))..createSync();
      File(p.join(root.path, 'writerside.cfg')).writeAsStringSync('''
<ihp>
  <module name="Collapse test"/>
  <topics dir="topics"/>
  <images dir="images"/>
  <instance src="guide.tree"/>
</ihp>
''');
      File(p.join(root.path, 'guide.tree')).writeAsStringSync('''
<instance-profile id="guide" name="Guide" start-page="collapse.topic">
  <toc-element topic="collapse.topic"/>
</instance-profile>
''');
      const source = '''<topic id="collapse" title="Collapse">
  <chapter title="Details" collapsible="true"><p>Chapter body.</p></chapter>
  <procedure title="Build" collapsible="true"><step><p>Compile.</p></step></procedure>
  <code-block lang="text" collapsible="true" collapsed-title="Output">value</code-block>
  <deflist collapsible="true"><def title="Term"><p>Meaning.</p></def></deflist>
</topic>''';
      final topicPath = p.join(topics.path, 'collapse.topic');
      File(topicPath).writeAsStringSync(source);

      const service = WorkspaceService();
      final workspace = await service.openPath(root.path);
      final preview = service.buildPreview(
        workspace.copyWith(activeFilePath: topicPath),
        source,
      )!;
      final collapsibles = preview.blocks.where(
        (block) => busyMarkWritersideIsCollapsible(block.attributes),
      );

      expect(collapsibles.map((block) => block.kind), [
        PreviewBlockKind.heading,
        PreviewBlockKind.procedure,
        PreviewBlockKind.code,
        PreviewBlockKind.definitionList,
      ]);
      expect(collapsibles.first.children.single.text, 'Chapter body.');
      expect(collapsibles.last.children.single.text, 'Term');
      expect(
        busyMarkWritersideIsCollapsible(
          collapsibles.last.children.single.attributes,
        ),
        isTrue,
      );
    },
  );

  testWidgets('shared collapse control honors default state and toggles', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: BusyMarkDocumentCollapsible(
            header: Text('Details'),
            kindLabel: 'Details',
            child: Text('Hidden body'),
          ),
        ),
      ),
    );

    expect(find.text('Hidden body'), findsNothing);
    await tester.tap(find.text('Details'));
    await tester.pump();
    expect(find.text('Hidden body'), findsOneWidget);
  });

  testWidgets('WYSIWYG collapses only Writerside chapter content', (
    tester,
  ) async {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '''## Details {collapsible="true"}

Hidden body.
''',
      mode: MarkdownMode.writersideMarkdown,
      validateLocalReferences: false,
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BusyMarkWysiwygEditor(
            document: parsed.busyDocument,
            onSourceChanged: (_, _) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Hidden body.'), findsNothing);
    await tester.tap(find.byType(IconButton).first);
    await tester.pump();
    expect(find.text('Hidden body.'), findsOneWidget);
  });
}
