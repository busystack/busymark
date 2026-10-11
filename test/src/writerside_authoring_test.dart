import 'dart:io';

import 'package:busymark/src/editor/wysiwyg/writerside_editing_adapter.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_commands.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_inline_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_clipboard_fragment.dart';
import 'package:busymark/src/core/source_span.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/writerside/writerside_document_parser.dart';
import 'package:busymark/src/writerside/writerside_project.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

Iterable<BusyBlock> walk(Iterable<BusyBlock> blocks) sync* {
  for (final b in blocks) {
    yield b;
    yield* walk(b.children);
  }
}

void main() {
  const adapter = WritersideEditingAdapter();
  const xml =
      '<?xml version="1.0"?>\n<!-- before -->\n<ws:topic xmlns:ws="urn:sample" xmlns:ext="urn:extension" ext:mode="kept" id="demo" title="A &amp; B">\n<ws:p id="intro">Click <ws:control role="button">Save</ws:control> &amp; continue.</ws:p>\n<!-- between -->\n<ws:chapter title="Chapter" id="section"><ws:p>Content.</ws:p><ext:unknown value="keep">Protected</ext:unknown></ws:chapter>\n<ws:include from="lib.topic" element-id="snippet"/>\n</ws:topic>\n';
  test('visual capability is independent of AI capability', () {
    expect(DocumentKind.writersideXmlTopic.supportsVisualEditing, isTrue);
    expect(DocumentKind.writersideXmlTopic.supportsAiMarkdownEditing, isFalse);
    expect(DocumentKind.config.supportsVisualEditing, isFalse);
  });
  test(
    'Markdown variable references retain their editable type after reopening',
    () {
      const parser = MarkdownParser();
      final c = BusyMarkWysiwygDocumentController(
        document: parser
            .parse(
              filePath: 'a.md',
              source: '# A\n\nText\n',
              mode: MarkdownMode.writersideMarkdown,
            )
            .busyDocument,
      );
      final p = walk(
        c.document.blocks,
      ).firstWhere((b) => b.kind == BusyBlockKind.paragraph);
      c.insertVariableReference(p.id, 'product', 4, 4);
      final source = c.markdown;
      final reopened = parser
          .parse(
            filePath: 'a.md',
            source: source,
            mode: MarkdownMode.writersideMarkdown,
          )
          .busyDocument;
      final editor = BusyMarkWysiwygDocumentController(document: reopened);
      final paragraph = walk(
        editor.document.blocks,
      ).firstWhere((b) => b.kind == BusyBlockKind.paragraph);
      expect(paragraph.plainText, 'Textproduct');
      final reference = busyInlineReferenceRanges(paragraph.inlines).single;
      expect(reference.kind, BusyInlineKind.writersideVariable);
      expect(reference.attributes['reference'], 'product');
      expect(editor.markdown, source);
      expect(
        editor.updateInlineReference(
          paragraph.id,
          reference,
          'reference',
          'version',
        ),
        isTrue,
      );
      expect(editor.markdown, contains('Text%version%'));
      final ordinary = parser
          .parse(
            filePath: 'a.md',
            source: source,
            mode: MarkdownMode.commonMark,
          )
          .busyDocument;
      expect(
        walk(
          ordinary.blocks,
        ).firstWhere((b) => b.kind == BusyBlockKind.paragraph).plainText,
        'Text%product%',
      );
    },
  );
  test(
    'Markdown reference binding preserves formatting and literal contexts',
    () {
      const source = r'''# A

%product% **%version%** [more %product%](guide.topic) \%product% &#37;product&#37; `%product%` $x%product%$

<extension>%product%</extension>
''';
      final document = const MarkdownParser()
          .parse(
            filePath: 'a.md',
            source: source,
            mode: MarkdownMode.writersideMarkdown,
          )
          .busyDocument;
      final c = BusyMarkWysiwygDocumentController(document: document);
      final paragraph = walk(
        c.document.blocks,
      ).firstWhere((b) => b.kind == BusyBlockKind.paragraph);
      expect(
        busyInlineReferenceRanges(paragraph.inlines)
            .where((r) => r.kind == BusyInlineKind.writersideVariable)
            .map((r) => r.attributes['reference']),
        ['product', 'version', 'product'],
      );
      expect(c.markdown, source);
      expect(walk(c.document.blocks).every((b) => !b.dirty), isTrue);
      c.replaceDocument(document);
      expect(c.markdown, source);
      expect(
        busyInlineReferenceRanges(
          walk(
            c.document.blocks,
          ).firstWhere((b) => b.kind == BusyBlockKind.paragraph).inlines,
        ).where((r) => r.kind == BusyInlineKind.writersideVariable),
        hasLength(3),
      );
    },
  );
  test(
    'Markdown switcher labels preserve literal metadata through reopening',
    () {
      for (final entry in {
        'Operating System': 'Operating System',
        'النظام': 'النظام',
        'Platform: Choice': 'Platform: Choice',
        r'Platform: "Desktop" \ Keys': r'Platform: "Desktop" \ Keys',
        "Author's platform": "Author's platform",
        'true': 'true',
        'Leading\nline': r'"Leading\nline"',
        ' padded ': '" padded "',
      }.entries) {
        final c = BusyMarkWysiwygDocumentController(
          document: const MarkdownParser()
              .parse(
                filePath: 'a.md',
                source: '# A\n\nText\n',
                mode: MarkdownMode.writersideMarkdown,
              )
              .busyDocument,
        );
        expect(c.updateTopicSwitcherLabel(entry.key), isTrue);
        expect(
          c.markdown,
          startsWith('---\nswitcher-label: ${entry.value}\n---\n'),
        );
        expect(c.document.frontMatter['switcher-label'], entry.key);
        expect(c.markdown, contains('# A'));
        final reopened = const MarkdownParser()
            .parse(
              filePath: 'a.md',
              source: c.markdown,
              mode: MarkdownMode.writersideMarkdown,
            )
            .busyDocument;
        expect(reopened.frontMatter['switcher-label'], entry.key);
        expect(
          BusyMarkWysiwygDocumentController(document: reopened).markdown,
          c.markdown,
        );
      }
    },
  );
  test(
    'existing double-quoted switcher labels decode without changing source',
    () {
      const source = r'''---
switcher-label: "Platform: \"Desktop\" \\ Keys"
custom: "kept\\raw"
---

# A

Text
''';
      final parser = const MarkdownParser();
      final document = parser
          .parse(
            filePath: 'a.md',
            source: source,
            mode: MarkdownMode.writersideMarkdown,
          )
          .busyDocument;
      expect(
        document.frontMatter['switcher-label'],
        r'Platform: "Desktop" \ Keys',
      );
      expect(document.frontMatter['custom'], r'kept\\raw');
      final c = BusyMarkWysiwygDocumentController(document: document);
      expect(c.markdown, source);
      expect(c.updateTopicSwitcherLabel("Author's: \"Desktop\""), isTrue);
      expect(c.markdown, contains("switcher-label: Author's: \"Desktop\""));
      expect(c.markdown, contains(r'custom: "kept\\raw"'));
      final ordinary = parser
          .parse(
            filePath: 'a.md',
            source: source,
            mode: MarkdownMode.commonMark,
          )
          .busyDocument;
      expect(
        ordinary.frontMatter['switcher-label'],
        r'Platform: \"Desktop\" \\ Keys',
      );
    },
  );
  test(
    'clearing the topic switcher label restores the default without changing other metadata',
    () {
      final c = BusyMarkWysiwygDocumentController(
        document: const MarkdownParser()
            .parse(
              filePath: 'a.md',
              source: '---\ncustom: kept\n---\n\n# A\n\nText\n',
              mode: MarkdownMode.writersideMarkdown,
            )
            .busyDocument,
      );
      final original = c.markdown;
      expect(c.updateTopicSwitcherLabel(''), isFalse);
      expect(c.markdown, original);
      expect(c.updateTopicSwitcherLabel("Author's: Platform"), isTrue);
      expect(c.updateTopicSwitcherLabel(''), isTrue);
      expect(c.markdown, original);
      expect(c.document.frontMatter.containsKey('switcher-label'), isFalse);
    },
  );
  test('XML no-edit round trip preserves all source exactly', () {
    final c = BusyMarkWysiwygDocumentController(
      document: adapter.parseXml(filePath: 'demo.topic', source: xml)!,
    );
    expect(c.markdown, xml);
  });
  test(
    'XML changed leaves preserve qualified names and rebase for repeated edits',
    () {
      final c = BusyMarkWysiwygDocumentController(
        document: adapter.parseXml(filePath: 'demo.topic', source: xml)!,
      );
      final p = walk(
        c.document.blocks,
      ).firstWhere((b) => b.attributes['id'] == 'intro');
      c.updateBlockText(p.id, 'Click Save now & continue.');
      final first = c.markdown;
      expect(
        first,
        contains(
          '<ws:topic xmlns:ws="urn:sample" xmlns:ext="urn:extension" ext:mode="kept" id="demo" title="A &amp; B">',
        ),
      );
      expect(
        first,
        contains('<ext:unknown value="keep">Protected</ext:unknown>'),
      );
      expect(first, contains('<!-- between -->'));
      c.rebaseCommittedSource(first);
      expect(
        c.blockById(p.id)!.sourceSpan!.endOffset,
        greaterThan(p.sourceSpan!.endOffset),
      );
      c.updateBlockText(p.id, 'Click Save now & continue again.');
      final second = c.markdown;
      expect(second, contains('<ws:control role="button">Save</ws:control>'));
      expect(
        second,
        contains('<ws:include from="lib.topic" element-id="snippet"/>'),
      );
      expect(
        const WritersideDocumentParser()
            .parseXml(filePath: 'demo.topic', source: second)
            .isWellFormed,
        isTrue,
      );
    },
  );
  test('XML title edits update root attribute', () {
    final c = BusyMarkWysiwygDocumentController(
      document: adapter.parseXml(filePath: 'demo.topic', source: xml)!,
    );
    final root = c.document.blocks.firstWhere(
      (b) => b.attributes['element'] == 'topic',
    );
    c.updateBlockText(root.id, 'New title');
    expect(c.markdown, contains('title="New title"'));
    expect(c.markdown, startsWith('<?xml'));
    c.rebaseCommittedSource(c.markdown);
    c.updateBlockText(root.id, '');
    c.rebaseCommittedSource(c.markdown);
    expect(c.blockById(root.id)!.preserveRaw, isFalse);
    c.updateBlockText(root.id, 'Replacement title');
    expect(c.markdown, contains('title="Replacement title"'));
    expect(
      c.markdown,
      contains('<ext:unknown value="keep">Protected</ext:unknown>'),
    );
  });
  test('XML insertion and formatting inherit the authored namespace', () {
    final c = BusyMarkWysiwygDocumentController(
      document: adapter.parseXml(
        filePath: 't.topic',
        source:
            '<ws:topic xmlns:ws="urn:topic" id="t" title="Title"><ws:p>Text</ws:p></ws:topic>',
      )!,
    );
    final p = walk(
      c.document.blocks,
    ).firstWhere((b) => b.kind == BusyBlockKind.paragraph);
    c.applyInlineCommand(p.id, BusyWysiwygInlineCommand.uiControl, 0, 4);
    c.insertWriterside(
      BusyWritersideInsertCommand.procedure,
      p.id,
      title: 'Procedure',
    );
    final source = c.markdown;
    expect(source, contains('<ws:control>Text</ws:control>'));
    expect(source, contains('<ws:procedure'));
    expect(source, contains('<ws:step>'));
    expect(source, contains('xmlns:ws="urn:topic"'));
    c.rebaseCommittedSource(source);
    c.updateBlockText(p.id, 'Texxt');
    expect(c.markdown, contains('<ws:control>Texxt</ws:control>'));
  });
  for (final context in [
    (
      name: 'different namespace',
      prefix: 'nested:',
      declaration: 'xmlns:nested="urn:nested"',
      uri: 'urn:nested',
    ),
    (
      name: 'namespace alias',
      prefix: 'nested:',
      declaration: 'xmlns:nested="urn:topic"',
      uri: 'urn:topic',
    ),
    (
      name: 'rebound root prefix',
      prefix: 'nested:',
      declaration: 'xmlns:nested="urn:nested" xmlns:ws="urn:rebound"',
      uri: 'urn:nested',
    ),
    (
      name: 'locally rebound parent prefix',
      prefix: 'ws:',
      declaration: 'xmlns:ws="urn:nested"',
      uri: 'urn:nested',
    ),
    (
      name: 'default namespace',
      prefix: '',
      declaration: 'xmlns="urn:nested"',
      uri: 'urn:nested',
    ),
  ]) {
    test('XML editing inherits the parent ${context.name}', () {
      final prefix = context.prefix;
      final source =
          '<?xml version="1.0"?>\n<!--before-->\n'
          '<ws:topic xmlns:ws="urn:topic" xmlns:ext="urn:extension" id="t" title="Title">'
          '<${prefix}chapter ${context.declaration} ext:mode="kept" title="Chapter" id="nested">'
          '<${prefix}p id="text">Text &amp; more</${prefix}p>'
          '<!--inside--><ext:unknown ext:flag="yes">Protected</ext:unknown>'
          '</${prefix}chapter></ws:topic>';
      final c = BusyMarkWysiwygDocumentController(
        document: adapter.parseXml(filePath: 't.topic', source: source)!,
      );
      expect(c.markdown, source);
      final paragraph = walk(
        c.document.blocks,
      ).firstWhere((b) => b.attributes['id'] == 'text');
      final chapter = walk(
        c.document.blocks,
      ).firstWhere((b) => b.attributes['id'] == 'nested');
      c.applyInlineCommand(
        paragraph.id,
        BusyWysiwygInlineCommand.uiControl,
        0,
        4,
      );
      final procedure = c.insertWriterside(
        BusyWritersideInsertCommand.procedure,
        paragraph.id,
        title: 'Procedure',
      )!;
      final tabs = c.insertWriterside(
        BusyWritersideInsertCommand.tabs,
        paragraph.id,
        title: 'Tab',
      )!;
      for (final id in [procedure, tabs]) {
        final leaf = walk(
          c.blockById(id)!.children,
        ).firstWhere((b) => b.kind == BusyBlockKind.paragraph);
        c.updateBlockText(leaf.id, 'Inserted content');
      }
      c.updateBlockText(chapter.id, 'Edited chapter');
      void verify(String saved) {
        expect(
          const WritersideDocumentParser()
              .parseXml(filePath: 't.topic', source: saved)
              .isWellFormed,
          isTrue,
        );
        final xmlDocument = XmlDocument.parse(saved);
        for (final element in xmlDocument.descendants.whereType<XmlElement>()) {
          if (element.name.prefix != null) {
            expect(element.namespaceUri, isNotNull);
          }
          for (final attribute in element.attributes) {
            if (attribute.name.prefix != null &&
                attribute.name.prefix != 'xmlns') {
              expect(attribute.namespaceUri, isNotNull);
            }
          }
        }
        final parent = xmlDocument.descendants
            .whereType<XmlElement>()
            .firstWhere((e) => e.getAttribute('id') == 'nested');
        expect(parent.name.qualified, '${prefix}chapter');
        expect(parent.getAttribute('title'), 'Edited chapter');
        expect(
          parent.attributes
              .firstWhere((a) => a.name.qualified == 'ext:mode')
              .namespaceUri,
          'urn:extension',
        );
        for (final element in parent.descendants.whereType<XmlElement>().where(
          (e) => e.name.prefix != 'ext',
        )) {
          expect(
            element.namespaceUri,
            context.uri,
            reason: element.toXmlString(),
          );
          expect(element.name.qualified, '$prefix${element.name.local}');
        }
        expect(
          parent.descendants.whereType<XmlElement>().map((e) => e.name.local),
          containsAll(['procedure', 'step', 'tabs', 'tab', 'control']),
        );
        expect(saved, startsWith('<?xml version="1.0"?>\n<!--before-->\n'));
        expect(
          saved,
          contains(
            '<!--inside--><ext:unknown ext:flag="yes">Protected</ext:unknown>',
          ),
        );
        expect(
          RegExp(r'xmlns[:=]').allMatches(saved).length,
          RegExp(r'xmlns[:=]').allMatches(source).length,
        );
      }

      final saved = c.markdown;
      verify(saved);
      c.rebaseCommittedSource(saved);
      expect(c.blockById(paragraph.id), isNotNull);
      c.updateBlockText(paragraph.id, 'Texxt & more');
      verify(c.markdown);
      final reopened = BusyMarkWysiwygDocumentController(
        document: adapter.parseXml(filePath: 't.topic', source: c.markdown)!,
      );
      final p = walk(
        reopened.document.blocks,
      ).firstWhere((b) => b.attributes['id'] == 'text');
      reopened.applyInlineCommand(
        p.id,
        BusyWysiwygInlineCommand.filePath,
        8,
        12,
      );
      verify(reopened.markdown);
    });
  }
  test('XML formatting inherits declarations on existing inline elements', () {
    const source =
        '<ws:topic xmlns:ws="urn:topic" id="t" title="Title">'
        '<ws:p><n:b xmlns:n="urn:inline" xmlns:ws="urn:rebound" n:role="button">Save</n:b></ws:p></ws:topic>';
    final c = BusyMarkWysiwygDocumentController(
      document: adapter.parseXml(filePath: 't.topic', source: source)!,
    );
    expect(c.markdown, source);
    final p = walk(
      c.document.blocks,
    ).firstWhere((b) => b.kind == BusyBlockKind.paragraph);
    c.applyInlineCommand(p.id, BusyWysiwygInlineCommand.uiControl, 0, 4);
    final saved = c.markdown;
    final elements = XmlDocument.parse(
      saved,
    ).descendants.whereType<XmlElement>().toList();
    final control = elements.firstWhere((e) => e.name.local == 'control');
    expect(control.name.qualified, 'n:control');
    final bold = elements.firstWhere((e) => e.name.local == 'b');
    expect(bold.name.qualified, 'n:b');
    expect(
      bold.attributes
          .firstWhere((a) => a.name.qualified == 'n:role')
          .namespaceUri,
      'urn:inline',
    );
    expect(control.namespaceUri, 'urn:inline');
    c.rebaseCommittedSource(saved);
    c.updateBlockText(p.id, 'Saved');
    c.applyInlineCommand(p.id, BusyWysiwygInlineCommand.filePath, 0, 5);
    final edited = XmlDocument.parse(c.markdown).descendants
        .whereType<XmlElement>()
        .where((e) => {'b', 'control', 'path'}.contains(e.name.local))
        .toList();
    expect(
      edited.map((e) => e.name.local),
      containsAll(['b', 'control', 'path']),
    );
    for (final element in edited) {
      expect(element.namespaceUri, 'urn:inline');
      expect(element.name.prefix, 'n');
    }
  });
  test(
    'XML ordinary inline and image edits serialize as XML, unsupported insertions are inert',
    () {
      final c = BusyMarkWysiwygDocumentController(
        document: adapter.parseXml(
          filePath: 't.topic',
          source:
              '<topic id="t" title="Title"><p>Text</p><img src="old.png" alt="Old" width="400"/></topic>',
        )!,
      );
      final p = walk(
        c.document.blocks,
      ).firstWhere((b) => b.kind == BusyBlockKind.paragraph);
      c.applyInlineCommand(p.id, BusyWysiwygInlineCommand.underline, 0, 4);
      c.applyInlineCommand(p.id, BusyWysiwygInlineCommand.strikethrough, 0, 4);
      c.insertHardBreak(p.id, 4);
      final source = c.markdown;
      expect(source, contains('<u>'));
      expect(source, contains('<s>'));
      expect(source, contains('<br/>'));
      c.rebaseCommittedSource(source);
      expect(c.blockById(p.id)!.preserveRaw, isFalse);
      final img = walk(
        c.document.blocks,
      ).firstWhere((b) => b.kind == BusyBlockKind.image);
      c.applyImageBlock(img.id, source: 'new.png', alt: 'New');
      expect(
        c.markdown,
        contains('<img src="new.png" alt="New" width="400"/>'),
      );
      final before = c.markdown;
      expect(
        c.insertTableAfter(
          p.id,
          columns: 2,
          rows: 2,
          headerTextForColumn: (n) => '$n',
          cellText: 'Cell',
        ),
        isNull,
      );
      expect(c.insertDisplayMathAfter(p.id), isNull);
      expect(c.insertRawHtmlBlockAfter(p.id, '<div>HTML</div>'), isNull);
      c.applyInlineCommand(
        c.document.blocks.first.id,
        BusyWysiwygInlineCommand.uiControl,
        0,
        4,
      );
      expect(c.markdown, before);
    },
  );
  test('malformed XML has no writable visual projection', () {
    expect(
      adapter.parseXml(filePath: 'bad.topic', source: '<topic><p>Oops</topic>'),
      isNull,
    );
  });
  test('XML text navigation binds titles, entities, repeated text and CDATA', () {
    const source =
        '<topic id="t" title="A &amp; B"><p>Save<!-- Save --> <control>Save</control> &amp; %product%</p><code-block><![CDATA[a < b]]></code-block></topic>';
    final document = adapter.parseXml(filePath: 't.topic', source: source)!;
    final blocks = walk(document.blocks).toList();
    final title = blocks.firstWhere((b) => b.attributes['element'] == 'topic');
    expect(
      adapter.xmlTextSourceOffset(document, title, 2, endBoundary: false),
      source.indexOf('&amp;'),
    );
    final paragraph = blocks.firstWhere(
      (b) => b.kind == BusyBlockKind.paragraph,
    );
    expect(
      adapter.xmlTextSourceOffset(document, paragraph, 5, endBoundary: false),
      source.indexOf('<control>') + 9,
    );
    expect(
      adapter.xmlTextSourceOffset(document, paragraph, 12, endBoundary: false),
      source.indexOf('%product%') + 1,
    );
    final code = blocks.firstWhere((b) => b.kind == BusyBlockKind.codeBlock);
    expect(
      adapter.xmlTextSourceOffset(document, code, 2, endBoundary: false),
      source.indexOf('a < b') + 2,
    );
  });
  test('Markdown structured descendants bind to the full source file', () {
    const source =
        '# Title\n\nBefore\n\n<tabs><tab title="First"><p>Nested</p></tab></tabs>\n';
    final document = const MarkdownParser()
        .parse(
          filePath: 'scope.md',
          source: source,
          mode: MarkdownMode.writersideMarkdown,
          validateLocalReferences: false,
        )
        .busyDocument;
    final nested = walk(
      document.blocks,
    ).firstWhere((b) => b.plainText == 'Nested');
    expect(nested.sourceSpan!.filePath, 'scope.md');
    expect(nested.sourceSpan!.startOffset, source.indexOf('<p>'));
    expect(
      source.substring(
        nested.sourceSpan!.startOffset,
        nested.sourceSpan!.endOffset,
      ),
      '<p>Nested</p>',
    );
  });
  test('variable selection follows live XML lexical parents and module', () {
    const source =
        '<topic id="t" title="Title"><var name="root" value="R"/><chapter title="A"><var name="local" value="L"/><p>Here</p></chapter><chapter title="B"><var name="sibling" value="S"/><p>Other</p></chapter></topic>';
    final c = BusyMarkWysiwygDocumentController(
      document: adapter.parseXml(filePath: 't.topic', source: source)!,
    );
    final index = WritersideProjectIndex(
      symbols: [
        const WritersideSymbol(
          name: 'global',
          qualifiedName: 'm:global',
          kind: WritersideSymbolKind.variable,
          moduleId: 'm',
          filePath: 'v.list',
        ),
        const WritersideSymbol(
          name: 'wrong',
          qualifiedName: 'other:wrong',
          kind: WritersideSymbolKind.variable,
          moduleId: 'other',
          filePath: 'v.list',
        ),
        WritersideSymbol(
          name: 'stale-local',
          qualifiedName: 'm:stale-local',
          kind: WritersideSymbolKind.variable,
          moduleId: 'm',
          filePath: 't.topic',
          scopeSpan: SourceSpan.entireFile('t.topic', source),
        ),
      ],
      references: [],
      diagnostics: [],
    );
    final paragraph = walk(
      c.document.blocks,
    ).firstWhere((b) => b.plainText == 'Here');
    expect(c.availableVariableReferences(index, 'm', paragraph.id), [
      'global',
      'local',
      'root',
    ]);
    c.updateBlockText(
      paragraph.id,
      'A longer paragraph shifts all later spans',
    );
    c.rebaseCommittedSource(c.markdown);
    expect(c.availableVariableReferences(index, 'm', paragraph.id), [
      'global',
      'local',
      'root',
    ]);
    final other = walk(
      c.document.blocks,
    ).firstWhere((b) => b.plainText == 'Other');
    expect(c.availableVariableReferences(index, 'm', other.id), [
      'global',
      'root',
      'sibling',
    ]);
  });
  test('topic H1 cannot acquire chapter collapse properties', () {
    final c = BusyMarkWysiwygDocumentController(
      document: const MarkdownParser()
          .parse(
            filePath: 't.md',
            source: '# Title\n\nText\n',
            mode: MarkdownMode.writersideMarkdown,
            validateLocalReferences: false,
          )
          .busyDocument,
    );
    final before = c.markdown;
    expect(
      c.updateWritersideProperty(
        c.document.blocks.first.id,
        'collapsible',
        'true',
      ),
      isFalse,
    );
    expect(c.markdown, before);
  });
  test(
    'XML clipboard retains copied structure identity and rejects Markdown-only payloads',
    () {
      final c = BusyMarkWysiwygDocumentController(
        document: adapter.parseXml(
          filePath: 't.topic',
          source:
              '<topic id="t" title="Title"><tabs><tab title="One"><p>Original</p><!-- keep --><table><tr><td>Protected</td></tr></table></tab></tabs><p>Target</p></topic>',
        )!,
      );
      final tabs = walk(
        c.document.blocks,
      ).firstWhere((b) => b.attributes['element'] == 'tabs');
      final target = walk(
        c.document.blocks,
      ).firstWhere((b) => b.plainText == 'Target');
      final pasted = c.insertStyledBlocksAtSelection(
        blockId: target.id,
        selectionStart: 0,
        selectionEnd: 6,
        blocks: [
          BusyWysiwygStyledBlock(
            kind: tabs.kind,
            text: '',
            ranges: const [],
            completeBlock: tabs,
          ),
        ],
      );
      expect(pasted, isNotNull);
      c.rebaseCommittedSource(c.markdown);
      final copies = walk(
        c.document.blocks,
      ).where((b) => b.plainText == 'Original').toList();
      expect(copies, hasLength(2));
      expect(copies[0].id, isNot(copies[1].id));
      c.updateBlockText(copies[1].id, 'Copied edit');
      c.rebaseCommittedSource(c.markdown);
      expect(c.blockById(copies[0].id)!.plainText, 'Original');
      expect(c.blockById(copies[1].id)!.plainText, 'Copied edit');
      expect(RegExp('<!-- keep -->').allMatches(c.markdown), hasLength(2));
      expect(RegExp('<table>').allMatches(c.markdown), hasLength(2));
      final before = c.markdown;
      expect(
        c.insertStyledBlocksAtSelection(
          blockId: copies[0].id,
          selectionStart: 0,
          selectionEnd: 0,
          blocks: [
            const BusyWysiwygStyledBlock(
              kind: BusyBlockKind.table,
              text: 'Cell',
              ranges: [],
            ),
          ],
        ),
        isNull,
      );
      expect(c.markdown, before);
    },
  );
  test('Markdown variable selection follows authored topic and tab scope', () {
    const source =
        '# Title\n\n<var name="root" value="R"/>\n\nText\n\n<tabs><tab title="A"><var name="local" value="L"/><p>Here</p></tab><tab title="B"><var name="sibling" value="S"/><p>Other</p></tab></tabs>\n';
    final c = BusyMarkWysiwygDocumentController(
      document: const MarkdownParser()
          .parse(
            filePath: 't.md',
            source: source,
            mode: MarkdownMode.writersideMarkdown,
            validateLocalReferences: false,
          )
          .busyDocument,
    );
    const index = WritersideProjectIndex(
      symbols: [
        WritersideSymbol(
          name: 'global',
          qualifiedName: 'm:global',
          kind: WritersideSymbolKind.variable,
          moduleId: 'm',
          filePath: 'v.list',
        ),
      ],
      references: [],
      diagnostics: [],
    );
    final p = walk(c.document.blocks).firstWhere((b) => b.plainText == 'Here');
    expect(c.availableVariableReferences(index, 'm', p.id), [
      'global',
      'local',
      'root',
    ]);
    final other = walk(
      c.document.blocks,
    ).firstWhere((b) => b.plainText == 'Other');
    expect(c.availableVariableReferences(index, 'm', other.id), [
      'global',
      'root',
      'sibling',
    ]);
  });
  for (final xmlFormat in [false, true]) {
    test(
      '${xmlFormat ? 'XML' : 'Markdown'} semantic clipboard keeps mixed formatting, links and reference attributes',
      () {
        const fragment =
            '<control instance="web">Save <b>now</b></control> <shortcut key="\$Copy" from-keymap-of="IntelliJ IDEA"/> <path><a href="other.topic">file</a></path>';
        final document = xmlFormat
            ? adapter.parseXml(
                filePath: 't.topic',
                source:
                    '<topic id="t" title="Title"><p>$fragment</p><p>Target</p></topic>',
              )!
            : const MarkdownParser()
                  .parse(
                    filePath: 't.md',
                    source: '# Title\n\n$fragment\n\nTarget\n',
                    mode: MarkdownMode.writersideMarkdown,
                    validateLocalReferences: false,
                  )
                  .busyDocument;
        final c = BusyMarkWysiwygDocumentController(document: document);
        final paragraph = walk(c.document.blocks).firstWhere(
          (b) =>
              b.kind == BusyBlockKind.paragraph && b.plainText.contains('Save'),
        );
        final copied = WysiwygClipboardFragment(
          blocks: [
            BusyWysiwygStyledBlock(
              kind: BusyBlockKind.paragraph,
              text: paragraph.plainText,
              ranges: const [],
              completeBlock: paragraph.copyWith(
                inlines: busyMarkWysiwygClipboardInlineSlice(
                  paragraph.inlines,
                  0,
                  paragraph.plainText.length,
                ),
                dirty: true,
              ),
            ),
          ],
          mode: MarkdownMode.writersideMarkdown,
        );
        final decoded = WysiwygClipboardFragment.decode(copied.encode())!;
        final target = walk(
          c.document.blocks,
        ).firstWhere((b) => b.plainText == 'Target');
        c.insertStyledBlocksAtSelection(
          blockId: target.id,
          selectionStart: 0,
          selectionEnd: 6,
          blocks: decoded.blocks,
        );
        c.updateBlockText(target.id, 'Save soon  file');
        final saved = c.markdown;
        expect(saved, contains('<control instance="web">'));
        expect(saved, contains('key="\$Copy"'));
        expect(saved, contains('from-keymap-of="IntelliJ IDEA"'));
        expect(saved, contains('<path>'));
        expect(saved, contains('other.topic'));
      },
    );
  }
  test(
    'changed XML preserves colliding namespaced attributes and lexical inline source',
    () {
      const source =
          '''<topic xmlns:e="urn:extension" id="root" e:id="external" title='A > B'><p id='leaf' e:id="other">A <control instance='a'>Save &amp; close</control><!-- anchor --> Z</p></topic>''';
      final c = BusyMarkWysiwygDocumentController(
        document: adapter.parseXml(filePath: 'a.topic', source: source)!,
      );
      final p = walk(
        c.document.blocks,
      ).firstWhere((b) => b.attributes['id'] == 'leaf');
      c.updateBlockText(p.id, 'A Save & close Z!');
      final saved = c.markdown;
      expect(saved, contains('title=\'A > B\''));
      expect(saved, contains('id="root" e:id="external"'));
      expect(
        saved,
        contains('<control instance=\'a\'>Save &amp; close</control>'),
      );
      expect(saved, contains('<!-- anchor -->'));
      c.rebaseCommittedSource(saved);
      expect(c.blockById(p.id)!.attributes['e:id'], 'other');
      c.updateWritersideProperty(p.id, 'id', 'new');
      expect(c.markdown, contains('id="new" e:id="other"'));
    },
  );
  test(
    'authored style and attributes that share projection names survive real edits',
    () {
      const source =
          '<topic id="x" title="X" level="extension"><deflist style="compact"><def title="Term"><p>Definition</p></def></deflist><img src="image.png" alt="Alt" style="inline"/></topic>';
      final c = BusyMarkWysiwygDocumentController(
        document: adapter.parseXml(filePath: 'a.topic', source: source)!,
      );
      final list = walk(
        c.document.blocks,
      ).firstWhere((b) => b.attributes['element'] == 'deflist');
      expect(c.updateWritersideProperty(list.id, 'type', 'medium'), isTrue);
      final saved = c.markdown;
      expect(saved, contains('style="compact"'));
      expect(saved, contains('level="extension"'));
      c.rebaseCommittedSource(saved);
      final image = walk(
        c.document.blocks,
      ).firstWhere((b) => b.kind == BusyBlockKind.image);
      c.updateBlockText(image.id, 'Changed');
      expect(c.markdown, contains('style="inline"'));
      final md = BusyMarkWysiwygDocumentController(
        document: const MarkdownParser()
            .parse(
              filePath: 'a.md',
              source:
                  '# Title\n\n<deflist style="compact"><def title="Term"><p>Definition</p></def></deflist>\n',
              mode: MarkdownMode.writersideMarkdown,
            )
            .busyDocument,
      );
      final mdList = walk(
        md.document.blocks,
      ).firstWhere((b) => b.attributes['element'] == 'deflist');
      md.updateWritersideProperty(mdList.id, 'type', 'medium');
      expect(md.markdown, contains('style="compact"'));
    },
  );
  test(
    'reference and media property edits keep authored leaf comments and children',
    () {
      const source =
          '<topic id="x" title="X"><video src="before.mp4"><!-- video --></video><img src="before.png" alt="Alt"><!-- image --></img><show-structure for="chapter"><!-- navigation --></show-structure><include from="library.topic" element-id="shared"><var name="argument" value="kept"/><!-- include --></include></topic>';
      final c = BusyMarkWysiwygDocumentController(
        document: adapter.parseXml(filePath: 'a.topic', source: source)!,
      );
      for (final (tag, name, value) in [
        ('video', 'src', 'after.mp4'),
        ('img', 'id', 'image'),
        ('show-structure', 'depth', '2'),
        ('include', 'use-filter', 'true'),
      ]) {
        final block = walk(
          c.document.blocks,
        ).firstWhere((b) => b.attributes['element'] == tag);
        expect(
          c.updateWritersideProperty(block.id, name, value),
          isTrue,
          reason: '$tag.$name',
        );
      }
      final saved = c.markdown;
      for (final tag in ['video', 'image', 'navigation', 'include']) {
        expect(saved, contains('<!-- $tag -->'));
      }
      expect(saved, contains('<var name="argument" value="kept"/>'));
      c.rebaseCommittedSource(saved);
      final video = walk(
        c.document.blocks,
      ).firstWhere((b) => b.attributes['element'] == 'video');
      c.updateWritersideProperty(video.id, 'src', 'final.mp4');
      expect(c.markdown, contains('<!-- video -->'));
    },
  );
  test(
    'Markdown reference property edits preserve authored arguments, comments and qualified names',
    () {
      const source =
          '# Title\n\n<ws:include xmlns:ws="urn:sample" from="library.topic" element-id="shared"><ws:var name="argument" value="kept"/><!-- include --></ws:include>\n\n<video src="before.mp4"><!-- video --></video>\n';
      final c = BusyMarkWysiwygDocumentController(
        document: const MarkdownParser()
            .parse(
              filePath: 'a.md',
              source: source,
              mode: MarkdownMode.writersideMarkdown,
            )
            .busyDocument,
      );
      final reference = walk(
        c.document.blocks,
      ).firstWhere((b) => b.attributes['element'] == 'include');
      expect(
        c.updateWritersideProperty(reference.id, 'from', 'other.topic'),
        isTrue,
      );
      final video = walk(
        c.document.blocks,
      ).firstWhere((b) => b.attributes['element'] == 'video');
      expect(c.updateWritersideProperty(video.id, 'src', 'after.mp4'), isTrue);
      final saved = c.markdown;
      expect(saved, contains('<ws:include'));
      expect(saved, contains('</ws:include>'));
      expect(
        saved,
        contains('<ws:var name="argument" value="kept"/><!-- include -->'),
      );
      expect(saved, contains('<!-- video -->'));
      expect(
        const MarkdownParser()
            .parse(
              filePath: 'a.md',
              source: saved,
              mode: MarkdownMode.writersideMarkdown,
            )
            .busyDocument
            .mode,
        MarkdownMode.writersideMarkdown,
      );
    },
  );
  test('an unknown inline protects its paragraph rather than the topic', () {
    final c = BusyMarkWysiwygDocumentController(
      document: adapter.parseXml(
        filePath: 'a.topic',
        source:
            '<topic id="x" title="X"><p>Protected <unknown>special</unknown></p><p>Editable</p></topic>',
      )!,
    );
    final ps = walk(
      c.document.blocks,
    ).where((b) => b.kind == BusyBlockKind.paragraph).toList();
    expect(ps.first.preserveRaw, isTrue);
    expect(ps.last.preserveRaw, isFalse);
    c.updateBlockText(ps.last.id, 'Changed');
    expect(
      c.markdown,
      contains('<p>Protected <unknown>special</unknown></p><p>Changed</p>'),
    );
  });
  test(
    'empty shortcut references retain their attributes through surrounding edits',
    () {
      final c = BusyMarkWysiwygDocumentController(
        document: adapter.parseXml(
          filePath: 'a.topic',
          source:
              '<topic id="x" title="X"><p>Copy <shortcut key="\$Copy" from-keymap-of="IJ" force-layout="Windows"/> here.</p></topic>',
        )!,
      );
      final p = walk(
        c.document.blocks,
      ).firstWhere((b) => b.kind == BusyBlockKind.paragraph);
      c.updateBlockText(p.id, 'Copy  here again.');
      expect(
        c.markdown,
        contains(
          '<shortcut key="\$Copy" from-keymap-of="IJ" force-layout="Windows"/>',
        ),
      );
      final reference = busyInlineReferenceRanges(
        c.blockById(p.id)!.inlines,
      ).firstWhere((r) => r.kind == BusyInlineKind.writersideShortcut);
      expect(
        c.updateInlineReference(p.id, reference, 'key', '\$Paste'),
        isTrue,
      );
      expect(c.markdown, contains('key="\$Paste"'));
      expect(
        c.markdown,
        contains('from-keymap-of="IJ" force-layout="Windows"'),
      );
      expect(
        c.updateInlineReference(p.id, reference, 'key', '\$Delete'),
        isFalse,
      );
      final updated = busyInlineReferenceRanges(
        c.blockById(p.id)!.inlines,
      ).firstWhere((r) => r.kind == BusyInlineKind.writersideShortcut);
      expect(c.updateInlineReference(p.id, updated, 'key', ''), isFalse);
      expect(
        c.updateInlineReference(p.id, updated, 'force-layout', ''),
        isTrue,
      );
      expect(c.markdown, contains('key="\$Paste" from-keymap-of="IJ"'));
      expect(c.markdown, isNot(contains('force-layout=')));
    },
  );
  test('Markdown definition form retains layout and definition content', () {
    const source =
        '{type="medium" collapsible="true" sorted="true"}\nFirst term\n: First **definition**.\n\nSecond term\n: Second definition.\n';
    final doc = const MarkdownParser()
        .parse(
          filePath: 'a.md',
          source: source,
          mode: MarkdownMode.writersideMarkdown,
          validateLocalReferences: false,
        )
        .busyDocument;
    final c = BusyMarkWysiwygDocumentController(document: doc);
    final list = walk(
      doc.blocks,
    ).firstWhere((b) => b.attributes['element'] == 'deflist');
    expect(list.attributes['type'], 'medium');
    expect(list.preserveRaw, isFalse);
    final first = list.children.first;
    c.updateBlockText(first.children.first.id, 'Changed definition.');
    expect(
      c.markdown,
      contains('{type="medium" collapsible="true" sorted="true"}'),
    );
    expect(c.markdown, contains('First term\n: Changed **definition**.'));
    c.updateWritersideProperty(first.id, 'default-state', 'expanded');
    final saved = c.markdown;
    expect(
      saved,
      contains('<deflist type="medium" collapsible="true" sorted="true">'),
    );
    expect(saved, contains('default-state="expanded"'));
    expect(saved, contains('Second definition.'));
    expect(
      walk(
        const MarkdownParser()
            .parse(
              filePath: 'a.md',
              source: saved,
              mode: MarkdownMode.writersideMarkdown,
            )
            .busyDocument
            .blocks,
      ).where((b) => b.attributes['element'] == 'def'),
      hasLength(2),
    );
  });
  test(
    'XML list conversion preserves hierarchy and ordered versus choice semantics',
    () {
      for (final type in ['decimal', 'bullet']) {
        final c = BusyMarkWysiwygDocumentController(
          document: adapter.parseXml(
            filePath: 'a.topic',
            source:
                '<topic id="x" title="X"><list type="$type" id="list"><li><p>First <control>item</control></p><list><li>Nested</li></list></li><li><p>Second</p></li></list></topic>',
          )!,
        );
        final p = walk(
          c.document.blocks,
        ).firstWhere((b) => b.kind == BusyBlockKind.paragraph);
        expect(
          c.canInsertWriterside(
            BusyWritersideInsertCommand.convertListToProcedure,
            p.id,
          ),
          isTrue,
        );
        final id = c.convertListToProcedure(p.id, title: 'Procedure')!;
        expect(c.blockById(id)!.children, hasLength(2));
        final saved = c.markdown;
        expect(
          saved,
          contains('type="${type == 'decimal' ? 'steps' : 'choices'}"'),
        );
        expect(saved, contains('<control>item</control>'));
        expect(saved, contains('<list><li>Nested</li></list>'));
        c.rebaseCommittedSource(saved);
        expect(c.manageWritersideItem(id, title: 'Step'), isTrue);
        expect(
          c
              .blockById(id)!
              .children
              .where((b) => b.attributes['element'] == 'step'),
          hasLength(3),
        );
      }
    },
  );
  test(
    'list conversion retains comments and step identities, and refuses lossy attributes',
    () {
      final c = BusyMarkWysiwygDocumentController(
        document: adapter.parseXml(
          filePath: 'a.topic',
          source:
              '<topic id="x" title="X"><list type="decimal" id="list">\n<!-- before --><li id="first" instance="web"><p>First</p></li><!-- between --><li id="second"><p>Second</p></li>\n</list></topic>',
        )!,
      );
      final first = walk(
        c.document.blocks,
      ).firstWhere((b) => b.plainText == 'First');
      expect(c.convertListToProcedure(first.id, title: 'Procedure'), isNotNull);
      final saved = c.markdown;
      expect(
        saved,
        contains('<!-- before --><step id="first" instance="web">'),
      );
      expect(saved, contains('<!-- between --><step id="second">'));
      expect(saved, contains('id="list"'));
      for (final attributes in ['columns="2"', 'type="bullet"']) {
        final source =
            '<topic id="x" title="X"><list $attributes><li checked="true"><p>Checked</p></li></list></topic>';
        final protected = BusyMarkWysiwygDocumentController(
          document: adapter.parseXml(filePath: 'a.topic', source: source)!,
        );
        final p = walk(
          protected.document.blocks,
        ).firstWhere((b) => b.kind == BusyBlockKind.paragraph);
        expect(
          protected.canInsertWriterside(
            BusyWritersideInsertCommand.convertListToProcedure,
            p.id,
          ),
          isFalse,
        );
        expect(
          protected.convertListToProcedure(p.id, title: 'Procedure'),
          isNull,
        );
        expect(protected.markdown, source);
      }
    },
  );
  test('XML paragraph list commands create an actual list wrapper', () {
    final c = BusyMarkWysiwygDocumentController(
      document: adapter.parseXml(
        filePath: 'a.topic',
        source: '<topic id="x" title="X"><p>Content</p></topic>',
      )!,
    );
    final p = walk(
      c.document.blocks,
    ).firstWhere((b) => b.kind == BusyBlockKind.paragraph);
    c.applyBlockCommand(p.id, BusyWysiwygBlockCommand.orderedList);
    expect(
      c.markdown,
      contains('<list type="decimal"><li><p>Content</p></li></list>'),
    );
    expect(
      c.canApplyBlockCommand(
        c.blockById(p.id)!,
        BusyWysiwygBlockCommand.thematicBreak,
      ),
      isFalse,
    );
  });
  for (final xmlFormat in [false, true]) {
    test(
      '${xmlFormat ? 'XML' : 'Markdown'} manages tabs and definitions without losing nested content',
      () {
        final c = BusyMarkWysiwygDocumentController(
          document: xmlFormat
              ? adapter.parseXml(
                  filePath: 'a.topic',
                  source:
                      '<topic id="a" title="A"><tabs group="sync"><tab title="First" group-key="one"><p><control>Keep</control></p><code-block lang="dart" src="sample.dart"/></tab><tab title="Second"><p>Two</p></tab></tabs><deflist type="narrow" collapsible="true"><def title="Term" default-state="expanded"><p>Meaning</p></def></deflist></topic>',
                )!
              : const MarkdownParser()
                    .parse(
                      filePath: 'a.md',
                      source:
                          '# A\n\n<tabs group="sync">\n<tab title="First" group-key="one">\n\n<control>Keep</control>\n\n```dart\ncode\n```\n\n</tab>\n<tab title="Second">\nTwo\n</tab>\n</tabs>\n\n<deflist type="narrow" collapsible="true"><def title="Term" default-state="expanded"><p>Meaning</p></def></deflist>\n',
                      mode: MarkdownMode.writersideMarkdown,
                    )
                    .busyDocument,
        );
        final tabs = walk(
          c.document.blocks,
        ).firstWhere((b) => b.attributes['element'] == 'tabs');
        final first = tabs.children.firstWhere(
          (b) => b.attributes['element'] == 'tab',
        );
        expect(
          c.manageWritersideItem(
            tabs.id,
            itemId: first.id,
            direction: 1,
            title: 'Tab',
          ),
          isTrue,
        );
        expect(
          c.updateWritersideProperty(first.id, 'title', 'Renamed'),
          isTrue,
        );
        expect(
          c.updateWritersideProperty(tabs.id, 'group', 'new-sync'),
          isTrue,
        );
        expect(c.manageWritersideItem(tabs.id, title: 'Third'), isTrue);
        final list = walk(
          c.document.blocks,
        ).firstWhere((b) => b.attributes['element'] == 'deflist');
        final item = list.children.firstWhere(
          (b) => b.attributes['element'] == 'def',
        );
        c.updateWritersideProperty(list.id, 'type', 'medium');
        c.updateWritersideProperty(item.id, 'default-state', 'collapsed');
        final source = c.markdown;
        expect(source, contains('group="new-sync"'));
        expect(source, contains('group-key="one"'));
        expect(source, contains('<control>Keep</control>'));
        expect(
          source.indexOf('title="Second"'),
          lessThan(source.indexOf('title="Renamed"')),
        );
        expect(source, contains('title="Third"'));
        expect(source, contains('type="medium" collapsible="true"'));
        expect(source, contains('title="Term" default-state="collapsed"'));
        c.rebaseCommittedSource(source);
        expect(
          c.manageWritersideItem(
            tabs.id,
            itemId: first.id,
            remove: true,
            title: 'Tab',
          ),
          isTrue,
        );
        expect(c.markdown, isNot(contains('title="Renamed"')));
        if (xmlFormat) expect(source, contains('src="sample.dart"'));
      },
    );
    test(
      '${xmlFormat ? 'XML' : 'Markdown'} topic properties keep their source location over subsequent edits',
      () {
        final c = BusyMarkWysiwygDocumentController(
          document: xmlFormat
              ? adapter.parseXml(
                  filePath: 'a.topic',
                  source:
                      '<topic id="a" title="A"><chapter title="Section"><p>Content</p></chapter></topic>',
                )!
              : const MarkdownParser()
                    .parse(
                      filePath: 'a.md',
                      source:
                          '---\ncustom: kept\n---\n\n# A\n\n## Section\n\nContent\n',
                      mode: MarkdownMode.writersideMarkdown,
                    )
                    .busyDocument,
        );
        final p = walk(
          c.document.blocks,
        ).firstWhere((b) => b.kind == BusyBlockKind.paragraph);
        expect(c.updateTopicSwitcherLabel('Platform'), isTrue);
        expect(c.updateTopicNavigation('for', 'chapter,procedure'), isTrue);
        expect(c.updateTopicNavigation('depth', '2'), isTrue);
        c.updateBlockText(p.id, 'Content edited');
        final source = c.markdown;
        if (xmlFormat) {
          final parsed = const WritersideDocumentParser().parseXml(
            filePath: 'a.topic',
            source: source,
          );
          expect(parsed.rootElement!.attributes['switcher-label'], 'Platform');
          expect(
            parsed.elements.where((n) => n.name == 'show-structure'),
            hasLength(1),
          );
          expect(
            source.indexOf('<show-structure'),
            lessThan(source.indexOf('<chapter')),
          );
        } else {
          expect(source, startsWith('---\n'));
          expect(source, contains('custom: kept'));
          expect(source, contains('switcher-label: Platform\n'));
          expect(
            source.indexOf('<show-structure'),
            lessThan(source.indexOf('## Section')),
          );
        }
        expect(source, contains('Content edited'));
        c.rebaseCommittedSource(source);
        c.updateBlockText(p.id, 'Content twice');
        expect(c.markdown, contains('Content twice'));
      },
    );
    test(
      '${xmlFormat ? 'XML' : 'Markdown'} TLDR is unique per topic or chapter and inserted first',
      () {
        final c = BusyMarkWysiwygDocumentController(
          document: xmlFormat
              ? adapter.parseXml(
                  filePath: 'a.topic',
                  source:
                      '<topic id="a" title="A"><p>Intro</p><chapter title="Section"><p>Content</p></chapter></topic>',
                )!
              : const MarkdownParser()
                    .parse(
                      filePath: 'a.md',
                      source: '# A\n\nIntro\n\n## Section\n\nContent\n',
                      mode: MarkdownMode.writersideMarkdown,
                    )
                    .busyDocument,
        );
        final ps = walk(
          c.document.blocks,
        ).where((b) => b.kind == BusyBlockKind.paragraph).toList();
        expect(
          c.insertWriterside(
            BusyWritersideInsertCommand.tldr,
            ps[1].id,
            title: 'TLDR',
          ),
          isNotNull,
        );
        expect(
          c.canInsertWriterside(BusyWritersideInsertCommand.tldr, ps[1].id),
          isFalse,
        );
        expect(
          c.canInsertWriterside(BusyWritersideInsertCommand.tldr, ps[0].id),
          isTrue,
        );
        expect(
          c.insertWriterside(
            BusyWritersideInsertCommand.tldr,
            ps[0].id,
            title: 'TLDR',
          ),
          isNotNull,
        );
        expect(
          c.markdown.indexOf('<tldr>'),
          lessThan(c.markdown.indexOf('Intro')),
        );
        final group = c.insertWriterside(
          BusyWritersideInsertCommand.tabs,
          ps[0].id,
          title: 'Tabs',
        )!;
        final inner = walk(
          c.blockById(group)!.children,
        ).firstWhere((b) => b.kind == BusyBlockKind.paragraph);
        expect(
          c.canInsertWriterside(BusyWritersideInsertCommand.tldr, inner.id),
          isFalse,
        );
      },
    );
  }
  test(
    'Markdown heading insertion keeps TLDR in the selected chapter scope',
    () {
      final c = BusyMarkWysiwygDocumentController(
        document: const MarkdownParser()
            .parse(
              filePath: 'a.md',
              source: '# Title\n\nIntro\n\n## Chapter\n\nContent\n',
              mode: MarkdownMode.writersideMarkdown,
            )
            .busyDocument,
      );
      final heading = c.document.blocks.firstWhere(
        (b) => b.kind == BusyBlockKind.heading && b.attributes['level'] == '2',
      );
      expect(
        c.insertWriterside(
          BusyWritersideInsertCommand.tldr,
          heading.id,
          title: 'TLDR',
        ),
        isNotNull,
      );
      expect(
        c.markdown.indexOf('<tldr>'),
        greaterThan(c.markdown.indexOf('## Chapter')),
      );
      expect(
        c.markdown.indexOf('<tldr>'),
        lessThan(c.markdown.indexOf('Content')),
      );
      expect(
        c.canInsertWriterside(BusyWritersideInsertCommand.tldr, heading.id),
        isFalse,
      );
      final root = c.document.blocks.firstWhere(
        (b) => b.kind == BusyBlockKind.heading && b.attributes['level'] == '1',
      );
      expect(
        c.canInsertWriterside(BusyWritersideInsertCommand.tldr, root.id),
        isTrue,
      );
    },
  );
  test('representative command output for the pinned official builder', () async {
    final output =
        Platform.environment['BUSYMARK_AUTHORING_CONFORMANCE_OUTPUT'];
    if (output == null) return;
    final directory = Directory(output);
    await directory.create(recursive: true);
    const fixture = 'test/fixtures/writerside/conformance_project';
    await for (final entity in Directory(fixture).list(recursive: true)) {
      final dest = '$output/${entity.path.substring(fixture.length + 1)}';
      if (entity is Directory) await Directory(dest).create(recursive: true);
      if (entity is File) {
        await File(dest).parent.create(recursive: true);
        await entity.copy(dest);
      }
    }
    for (final xmlFormat in [false, true]) {
      final c = BusyMarkWysiwygDocumentController(
        document: xmlFormat
            ? adapter.parseXml(
                filePath: 'authored-xml.topic',
                source:
                    '<topic id="authored-xml" title="Authored XML"><p>Text path UI Ctrl+S</p><chapter title="Desktop"><p>Desktop content</p></chapter><chapter title="Terminal"><p>Terminal content</p></chapter></topic>',
              )!
            : const MarkdownParser()
                  .parse(
                    filePath: 'authored-markdown.md',
                    source:
                        '# Authored Markdown\n\nText path UI Ctrl+S\n\n## Desktop\n\nDesktop content\n\n## Terminal\n\nTerminal content\n',
                    mode: MarkdownMode.writersideMarkdown,
                  )
                  .busyDocument,
      );
      final p = walk(
        c.document.blocks,
      ).firstWhere((b) => b.kind == BusyBlockKind.paragraph);
      for (final command in [
        BusyWritersideInsertCommand.procedure,
        BusyWritersideInsertCommand.tabs,
        BusyWritersideInsertCommand.definitionList,
        BusyWritersideInsertCommand.tldr,
        BusyWritersideInsertCommand.include,
      ]) {
        final id = c.insertWriterside(
          command,
          p.id,
          title: 'Authored',
          attributes: switch (command) {
            BusyWritersideInsertCommand.include => {
              'from': 'features.topic',
              'element-id': 'shared-conformance',
            },
            BusyWritersideInsertCommand.video => {
              'src': 'https://youtu.be/BeJu9bMPLGU',
            },
            _ => {},
          },
        );
        expect(id, isNotNull);
        final leaf = walk(
          c.blockById(id!)!.children,
        ).where((b) => b.kind == BusyBlockKind.paragraph).firstOrNull;
        if (leaf != null) c.updateBlockText(leaf.id, 'Authored content');
        if (command == BusyWritersideInsertCommand.procedure) {
          c.updateWritersideProperty(id, 'collapsible', 'true');
          c.updateWritersideProperty(id, 'default-state', 'expanded');
        } else if (command == BusyWritersideInsertCommand.tabs) {
          c.updateWritersideProperty(id, 'group', 'authoring');
          c.updateWritersideProperty(
            c.blockById(id)!.children.first.id,
            'group-key',
            'first',
          );
        } else if (command == BusyWritersideInsertCommand.definitionList) {
          c.updateWritersideProperty(id, 'type', 'medium');
          c.updateWritersideProperty(id, 'collapsible', 'true');
          c.updateWritersideProperty(
            c.blockById(id)!.children.first.id,
            'default-state',
            'expanded',
          );
        }
      }
      c.applyInlineCommand(p.id, BusyWysiwygInlineCommand.uiControl, 0, 4);
      c.applyInlineCommand(p.id, BusyWysiwygInlineCommand.filePath, 5, 9);
      c.applyInlineCommand(p.id, BusyWysiwygInlineCommand.uiPath, 10, 12);
      c.applyInlineCommand(p.id, BusyWysiwygInlineCommand.shortcut, 13, 19);
      // The fixture defines $Save. Exercise the authored-reference property
      // path as well as literal formatting without a hard-coded-shortcut
      // warning from the official builder.
      final shortcut = busyInlineReferenceRanges(
        c.blockById(p.id)!.inlines,
      ).firstWhere((range) => range.kind == BusyInlineKind.writersideShortcut);
      expect(c.updateInlineReference(p.id, shortcut, 'key', r'$Save'), isTrue);
      c.insertVariableReference(p.id, 'product', 19, 19);
      for (final title in ['Desktop', 'Terminal']) {
        final chapter = walk(c.document.blocks).firstWhere(
          (b) => b.kind == BusyBlockKind.heading && b.plainText == title,
        );
        expect(
          c.updateWritersideProperty(
            chapter.id,
            'switcher-key',
            title.toLowerCase(),
          ),
          isTrue,
        );
      }
      c.updateTopicSwitcherLabel('Platform');
      c.updateTopicNavigation('for', 'chapter,procedure,def');
      final name = xmlFormat ? 'authored-xml.topic' : 'authored-markdown.md';
      await File('$output/topics/$name').writeAsString(c.markdown);
    }
    final tree = File('$output/conformance.tree');
    await tree.writeAsString(
      (await tree.readAsString()).replaceFirst(
        '</instance-profile>',
        '<toc-element topic="authored-xml.topic"/><toc-element topic="authored-markdown.md"/></instance-profile>',
      ),
    );
  });
  for (final isXml in [false, true]) {
    BusyMarkWysiwygDocumentController controller() =>
        BusyMarkWysiwygDocumentController(
          document: isXml
              ? adapter.parseXml(
                  filePath: 'x.topic',
                  source: '<topic id="x" title="Title"><p>Text</p></topic>',
                )!
              : const MarkdownParser()
                    .parse(
                      filePath: 'x.md',
                      source: '# Title\n\nText\n',
                      mode: MarkdownMode.writersideMarkdown,
                      validateLocalReferences: false,
                    )
                    .busyDocument,
        );
    for (final command in [
      BusyWritersideInsertCommand.procedure,
      BusyWritersideInsertCommand.tabs,
      BusyWritersideInsertCommand.definitionList,
      BusyWritersideInsertCommand.tldr,
      BusyWritersideInsertCommand.include,
      BusyWritersideInsertCommand.video,
    ]) {
      test(
        '${isXml ? 'XML' : 'Markdown'} $command inserts editable authored structure',
        () {
          final c = controller();
          final p = walk(
            c.document.blocks,
          ).lastWhere((b) => b.kind == BusyBlockKind.paragraph);
          final id = c.insertWriterside(
            command,
            p.id,
            title: 'New',
            attributes: switch (command) {
              BusyWritersideInsertCommand.include => {
                'from': 'lib.topic',
                'element-id': 'snippet',
              },
              BusyWritersideInsertCommand.video => {'src': 'video.mp4'},
              _ => {},
            },
          );
          expect(id, isNotNull);
          final inserted = c.blockById(id!)!;
          expect(inserted.preserveRaw, isFalse);
          final content = walk(
            inserted.children,
          ).where((b) => b.kind == BusyBlockKind.paragraph).firstOrNull;
          if (content != null) {
            c.updateBlockText(content.id, 'Authored content');
          }
          final source = c.markdown;
          if (content != null) expect(source, contains('Authored content'));
          final reopened = isXml
              ? adapter.parseXml(filePath: 'x.topic', source: source)!
              : const MarkdownParser()
                    .parse(
                      filePath: 'x.md',
                      source: source,
                      mode: MarkdownMode.writersideMarkdown,
                      validateLocalReferences: false,
                    )
                    .busyDocument;
          expect(
            walk(reopened.blocks).any(
              (b) => b.attributes['element'] == inserted.attributes['element'],
            ),
            isTrue,
          );
        },
      );
    }
    for (final command in [
      BusyWysiwygInlineCommand.uiControl,
      BusyWysiwygInlineCommand.filePath,
      BusyWysiwygInlineCommand.uiPath,
      BusyWysiwygInlineCommand.shortcut,
    ]) {
      test(
        '${isXml ? 'XML' : 'Markdown'} $command keeps semantic type through typing',
        () {
          final c = controller();
          final p = walk(
            c.document.blocks,
          ).lastWhere((b) => b.kind == BusyBlockKind.paragraph);
          c.applyInlineCommand(p.id, command, 0, 4);
          c.updateBlockText(p.id, 'Texxt');
          final source = c.markdown;
          expect(
            source,
            contains(
              '<${busyMarkSemanticInlineTag(inlineKindForCommand(command))}>Texxt</',
            ),
          );
          final reopened = isXml
              ? adapter.parseXml(filePath: 'x.topic', source: source)!
              : const MarkdownParser()
                    .parse(
                      filePath: 'x.md',
                      source: source,
                      mode: MarkdownMode.writersideMarkdown,
                      validateLocalReferences: false,
                    )
                    .busyDocument;
          final paragraph = walk(
            reopened.blocks,
          ).lastWhere((b) => b.kind == BusyBlockKind.paragraph);
          expect(paragraph.inlines.single.kind, inlineKindForCommand(command));
        },
      );
    }
  }
}
