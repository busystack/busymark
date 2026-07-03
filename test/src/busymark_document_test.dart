import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/l10n/generated/app_localizations_en.dart';
import 'package:busymark/src/app/busymark_glyphs.dart';
import 'package:busymark/src/app/busymark_shortcuts.dart';
import 'package:busymark/src/editor/markdown_image_view.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_commands.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_inline_controller.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/busymark_markdown_serializer.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/markdown/preview_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = MarkdownParser();

  test('package markdown AST imports into BusyDocument core blocks', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '''
# Title

Paragraph with **bold** and [link](docs.md).

![Logo](logo.png)

```dart
void main() {}
```

- Bullet
1. Ordered
- [x] Done

| Name | Value |
| --- | --- |
| A | B |
''',
    );
    final blocks = parsed.busyDocument.blocks;

    expect(blocks.any((block) => block.kind == BusyBlockKind.heading), isTrue);
    expect(
      blocks.any(
        (block) =>
            block.kind == BusyBlockKind.paragraph &&
            block.inlines.any((inline) => inline.kind == BusyInlineKind.strong),
      ),
      isTrue,
    );
    expect(blocks.any((block) => block.kind == BusyBlockKind.image), isTrue);
    expect(
      blocks.any((block) => block.kind == BusyBlockKind.codeBlock),
      isTrue,
    );
    expect(
      blocks.map((block) => block.kind),
      containsAll([
        BusyBlockKind.unorderedListItem,
        BusyBlockKind.orderedListItem,
        BusyBlockKind.taskListItem,
        BusyBlockKind.table,
      ]),
    );
  });

  test('linked remote image paragraphs import as editable image blocks', () {
    const imageUrl = 'https://snapcraft.io/busymark/badge.svg';
    const linkUrl = 'https://snapcraft.io/busymark';
    final parsed = parser.parse(
      filePath: 'README.md',
      source: '[![busymark]($imageUrl)]($linkUrl)\n',
    );
    final block = parsed.busyDocument.blocks.single;

    expect(block.kind, BusyBlockKind.image);
    expect(block.attributes['src'], imageUrl);
    expect(block.plainText, 'busymark');
    expect(block.inlines.single.kind, BusyInlineKind.link);
    expect(block.inlines.single.destination, linkUrl);
    expect(block.inlines.single.children.single.kind, BusyInlineKind.image);
    expect(parsed.images.single.destination, imageUrl);
    expect(parsed.links.single.destination, linkUrl);
  });

  test('serializer emits Markdown source for edited semantic blocks', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '# Title\n\nParagraph\n',
    );
    final markdown = const BusyMarkMarkdownSerializer().serialize(
      parsed.busyDocument.copyWith(
        blocks: [
          parsed.busyDocument.blocks.first.copyWith(
            inlines: const [
              BusyInline(kind: BusyInlineKind.text, text: 'Changed'),
            ],
            dirty: true,
          ),
        ],
      ),
    );

    expect(markdown, '# Changed\n');
  });

  test('serializer preserves unchanged raw blocks', () {
    const raw = '<custom attr="keep">Do not flatten</custom>';
    final document = BusyDocument(
      filePath: 'topic.md',
      mode: MarkdownMode.writersideMarkdown,
      blocks: const [
        BusyBlock(
          id: 'raw',
          kind: BusyBlockKind.writersideRawXml,
          rawSource: raw,
          preserveRaw: true,
        ),
      ],
    );

    expect(const BusyMarkMarkdownSerializer().serialize(document), '$raw\n');
  });

  test('serializer preserves safe raw HTML source byte for byte', () {
    const source =
        '<table>\n'
        '  <caption>Metrics</caption>\n'
        '  <tr><td>A</td></tr>\n'
        '</table>\n';
    final parsed = parser.parse(filePath: 'topic.md', source: source);
    final block = parsed.busyDocument.blocks.single;

    expect(block.kind, BusyBlockKind.htmlBlock);
    expect(block.preserveRaw, isTrue);
    expect(block.dirty, isFalse);
    expect(block.attributes['sourceFormat'], 'html');
    expect(
      const BusyMarkMarkdownSerializer().serialize(parsed.busyDocument),
      source,
    );
  });

  test(
    'serializer preserves unsafe raw HTML source while preview remains raw',
    () {
      const source = '<script>alert(1)</script>\n';
      final parsed = parser.parse(filePath: 'topic.md', source: source);
      final preview = const BusyMarkPreviewBuilder().build(parsed.busyDocument);

      expect(parsed.busyDocument.blocks.single.kind, BusyBlockKind.htmlBlock);
      expect(parsed.busyDocument.blocks.single.preserveRaw, isTrue);
      expect(preview.blocks.single.kind, PreviewBlockKind.raw);
      expect(
        const BusyMarkMarkdownSerializer().serialize(parsed.busyDocument),
        source,
      );
    },
  );

  test(
    'serializer patches dirty blocks without canonicalizing unchanged source',
    () {
      final parsed = parser.parse(
        filePath: 'topic.md',
        source: '# Title\n\nParagraph with   spacing\n\nSecond\n',
      );
      final controller = BusyMarkWysiwygDocumentController(
        document: parsed.busyDocument,
      );
      final secondBlockId = controller.document.blocks.last.id;

      controller.updateBlockText(secondBlockId, 'Changed');

      expect(
        controller.markdown,
        '# Title\n\nParagraph with   spacing\n\nChanged\n',
      );
    },
  );

  test('parser includes setext headings in heading metadata', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: 'Title\n=====\n\nSection\n-------\n',
    );

    expect(parsed.headings.map((heading) => (heading.level, heading.text)), [
      (1, 'Title'),
      (2, 'Section'),
    ]);
    expect(parsed.title, 'Title');
    expect(parsed.anchors, containsAll(['title', 'section']));
  });

  test('preview and WYSIWYG use the same semantic document', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '# Title\n\nParagraph with **bold**.\n',
    );
    final preview = const BusyMarkPreviewBuilder().build(parsed.busyDocument);

    expect(preview.blocks.first.text, 'Title');
    expect(
      preview.blocks.last.inlines.map((inline) => inline.kind),
      contains(PreviewInlineKind.strong),
    );
  });

  test('WYSIWYG text edit updates Markdown source', () {
    final parsed = parser.parse(filePath: 'topic.md', source: 'Original\n');
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final blockId = parsed.busyDocument.blocks.first.id;

    controller.updateBlockText(blockId, 'Changed');

    expect(controller.markdown, 'Changed\n');
  });

  test('WYSIWYG empty documents have one editable paragraph', () {
    final parsed = parser.parse(filePath: 'Untitled.md', source: '');
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final block = controller.document.blocks.single;

    expect(block.kind, BusyBlockKind.paragraph);

    controller.updateBlockText(block.id, 'First line');

    expect(controller.markdown, 'First line\n');
  });

  testWidgets('WYSIWYG editor accepts typing in an empty document', (
    tester,
  ) async {
    final parsed = parser.parse(filePath: 'Untitled.md', source: '');
    var markdown = '';
    String? sourceFilePath;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (filePath, value) {
                sourceFilePath = filePath;
                markdown = value;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      tester
          .widget<TextField>(find.byType(TextField).first)
          .focusNode
          ?.hasFocus,
      isTrue,
    );

    await tester.enterText(find.byType(TextField).first, 'Editable text');
    await tester.pump();

    expect(markdown, 'Editable text\n');
    expect(sourceFilePath, 'Untitled.md');
    expect(find.text('Editable text'), findsOneWidget);
  });

  testWidgets('WYSIWYG editor undo and redo restore document edits', (
    tester,
  ) async {
    final parsed = parser.parse(filePath: 'topic.md', source: 'Original\n');
    var markdown = parsed.source;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'Changed');
    await tester.pump();

    expect(markdown, 'Changed\n');
    final editedController = tester
        .widget<TextField>(find.byType(TextField).first)
        .controller!;
    editedController.selection = const TextSelection.collapsed(offset: 2);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(markdown, 'Original\n');
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller?.text,
      'Original',
    );
    expect(
      tester
          .widget<TextField>(find.byType(TextField).first)
          .controller
          ?.selection
          .extentOffset,
      2,
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(markdown, 'Changed\n');
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller?.text,
      'Changed',
    );
  });

  testWidgets('WYSIWYG editor replaces document when active file changes', (
    tester,
  ) async {
    final first = parser.parse(
      filePath: 'first.md',
      source: 'First original\n',
    );
    final second = parser.parse(
      filePath: 'second.md',
      source: 'Second original\n',
    );
    var activeDocument = first.busyDocument;

    Widget buildEditor() {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: activeDocument,
              onSourceChanged: (_, _) {},
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildEditor());
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'Unsaved first tab');
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller?.text,
      'Unsaved first tab',
    );

    activeDocument = second.busyDocument;
    await tester.pumpWidget(buildEditor());
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller?.text,
      'Second original',
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller?.text,
      'Second original',
    );
  });

  testWidgets('WYSIWYG editor applies heading keyboard shortcuts', (
    tester,
  ) async {
    final parsed = parser.parse(filePath: 'topic.md', source: 'Title\n');
    var markdown = parsed.source;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(markdown, '## Title\n');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.digit0);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.digit0);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(markdown, 'Title\n');
  });

  testWidgets('WYSIWYG arrow keys move focus between paragraphs', (
    tester,
  ) async {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: 'First\n\nSecond\n',
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    TextField fieldAt(int index) {
      return tester.widget<TextField>(find.byType(TextField).at(index));
    }

    expect(fieldAt(0).focusNode?.hasFocus, isTrue);
    expect(fieldAt(0).controller?.selection.extentOffset, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(fieldAt(1).focusNode?.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();

    expect(fieldAt(0).focusNode?.hasFocus, isTrue);
  });

  testWidgets('WYSIWYG drag selection can copy multiple paragraphs', (
    tester,
  ) async {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: 'First\n\nSecond\n\nThird\n',
    );
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final arguments = call.arguments as Map<Object?, Object?>;
          copiedText = arguments['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final firstFieldRect = tester.getRect(find.byType(TextField).at(0));
    final secondFieldRect = tester.getRect(find.byType(TextField).at(1));
    final gesture = await tester.startGesture(
      firstFieldRect.centerLeft + const Offset(1, 0),
    );
    await gesture.moveTo(secondFieldRect.centerLeft + const Offset(80, 0));
    await gesture.up();
    await tester.pump();

    Color? nativeSelectionColorAt(int index) {
      return TextSelectionTheme.of(
        tester.element(find.byType(TextField).at(index)),
      ).selectionColor;
    }

    expect(nativeSelectionColorAt(0), Colors.transparent);
    expect(nativeSelectionColorAt(1), Colors.transparent);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(copiedText, 'First\n\nSecond');
  });

  testWidgets('WYSIWYG click elsewhere clears previous block selection', (
    tester,
  ) async {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: 'First\n\nSecond\n\nThird\n',
    );
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final arguments = call.arguments as Map<Object?, Object?>;
          copiedText = arguments['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final firstFieldRect = tester.getRect(find.byType(TextField).at(0));
    final secondFieldRect = tester.getRect(find.byType(TextField).at(1));
    final thirdFieldRect = tester.getRect(find.byType(TextField).at(2));
    final gesture = await tester.startGesture(
      firstFieldRect.centerLeft + const Offset(1, 0),
    );
    await gesture.moveTo(secondFieldRect.centerLeft + const Offset(80, 0));
    await gesture.up();
    await tester.pump();

    await tester.tapAt(thirdFieldRect.centerLeft + const Offset(8, 0));
    await tester.pump();

    copiedText = null;
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(copiedText, isNull);
  });

  testWidgets('WYSIWYG Shift click selects text across paragraphs', (
    tester,
  ) async {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: 'First\n\nSecond\n\nThird\n',
    );
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final arguments = call.arguments as Map<Object?, Object?>;
          copiedText = arguments['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final firstField = tester.widget<TextField>(find.byType(TextField).first);
    firstField.controller!.selection = const TextSelection.collapsed(offset: 0);
    final secondFieldRect = tester.getRect(find.byType(TextField).at(1));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tapAt(secondFieldRect.centerLeft + const Offset(80, 0));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(copiedText, 'First\n\nSecond');
  });

  testWidgets('WYSIWYG Shift drag extends selection across paragraphs', (
    tester,
  ) async {
    const plannerParagraph =
        'Create a new service - planner-service. Spring Boot application. '
        'Use learner-model and other spring boot services as example.';
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '## Planner Service\n\n$plannerParagraph\n',
    );
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final arguments = call.arguments as Map<Object?, Object?>;
          copiedText = arguments['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final headingField = tester.widget<TextField>(find.byType(TextField).at(0));
    headingField.focusNode!.requestFocus();
    headingField.controller!.selection = const TextSelection.collapsed(
      offset: 0,
    );
    await tester.pump();

    final headingRect = tester.getRect(find.byType(TextField).at(0));
    final paragraphRect = tester.getRect(find.byType(TextField).at(1));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    final gesture = await tester.startGesture(
      headingRect.centerLeft + const Offset(2, 0),
    );
    await gesture.moveTo(paragraphRect.bottomRight - const Offset(2, 2));
    await gesture.up();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(copiedText, isNotNull);
    expect(copiedText, contains('Planner Service'));
    expect(copiedText, contains('as example.'));
  });

  testWidgets('WYSIWYG Shift drag from heading end hides native selection', (
    tester,
  ) async {
    const heading = 'Planner Service';
    const plannerParagraph =
        'Create a new service - planner-service. Spring Boot application. '
        'Use learner-model and other spring boot services as example.';
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '## $heading\n\n$plannerParagraph\n',
    );
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final arguments = call.arguments as Map<Object?, Object?>;
          copiedText = arguments['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final headingField = tester.widget<TextField>(find.byType(TextField).at(0));
    headingField.focusNode!.requestFocus();
    headingField.controller!.selection = TextSelection.collapsed(
      offset: heading.length,
    );
    await tester.pump();

    final headingRect = tester.getRect(find.byType(TextField).at(0));
    final paragraphRect = tester.getRect(find.byType(TextField).at(1));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    final gesture = await tester.startGesture(
      headingRect.centerRight - const Offset(2, 0),
    );
    await gesture.moveTo(paragraphRect.bottomRight - const Offset(2, 2));
    await gesture.up();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();

    Color? nativeSelectionColorAt(int index) {
      return TextSelectionTheme.of(
        tester.element(find.byType(TextField).at(index)),
      ).selectionColor;
    }

    expect(nativeSelectionColorAt(0), Colors.transparent);
    expect(nativeSelectionColorAt(1), Colors.transparent);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(copiedText, plannerParagraph);
  });

  testWidgets('WYSIWYG reverse drag updates selection on pointer up', (
    tester,
  ) async {
    const heading = 'Planner Service';
    const firstParagraph =
        'Create a new service - planner-service. Spring Boot application. '
        'Use learner-model and other spring boot services as example.';
    const secondParagraph =
        'It also has to call learner-model get all candos and to create '
        'schedulers for learner for each cando.';
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '## $heading\n\n$firstParagraph\n\n$secondParagraph\n',
    );
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final arguments = call.arguments as Map<Object?, Object?>;
          copiedText = arguments['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final headingRect = tester.getRect(find.byType(TextField).at(0));
    final firstParagraphRect = tester.getRect(find.byType(TextField).at(1));
    final secondParagraphRect = tester.getRect(find.byType(TextField).at(2));
    final gesture = await tester.createGesture(pointer: 42);
    await gesture.down(secondParagraphRect.bottomRight - const Offset(2, 2));
    await gesture.moveTo(firstParagraphRect.centerRight - const Offset(2, 0));
    await gesture.updateWithCustomEvent(
      PointerUpEvent(
        pointer: 42,
        position: headingRect.centerLeft + const Offset(2, 0),
      ),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(copiedText, contains(heading));
    expect(copiedText, contains('example.'));
    expect(copiedText, contains('cando.'));
  });

  testWidgets('WYSIWYG reverse drag aligns wrapped trailing word highlight', (
    tester,
  ) async {
    const heading = 'Planner Service';
    const firstParagraph =
        'Create a new service - planner-service. Spring Boot application. '
        'Use learner-model and other spring boot services as example.';
    const secondParagraph =
        'It also has to call learner-model get all candos and to create '
        'schedulers for learner for each cando.';
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '## $heading\n\n$firstParagraph\n\n$secondParagraph\n',
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(textScaler: const TextScaler.linear(1.35)),
            child: child!,
          );
        },
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final headingRect = tester.getRect(find.byType(TextField).at(0));
    final firstParagraphRect = tester.getRect(find.byType(TextField).at(1));
    final secondParagraphRect = tester.getRect(find.byType(TextField).at(2));
    final gesture = await tester.createGesture(pointer: 43);
    await gesture.down(secondParagraphRect.bottomRight - const Offset(2, 2));
    await gesture.moveTo(firstParagraphRect.centerRight - const Offset(2, 0));
    await gesture.updateWithCustomEvent(
      PointerUpEvent(
        pointer: 43,
        position: headingRect.centerLeft + const Offset(2, 0),
      ),
    );
    await tester.pump();

    final textFieldRender = tester.renderObject<RenderObject>(
      find.byType(TextField).at(1),
    );
    final renderEditable = _findRenderEditable(textFieldRender);
    expect(renderEditable, isNotNull);
    final exampleStart = firstParagraph.indexOf('example.');
    final exampleBoxes = renderEditable!.getBoxesForSelection(
      TextSelection(
        baseOffset: exampleStart,
        extentOffset: exampleStart + 'example.'.length,
      ),
    );
    expect(exampleBoxes, isNotEmpty);

    final painterFinder = find.byWidgetPredicate(
      (widget) =>
          widget is CustomPaint &&
          widget.painter.runtimeType.toString() == '_WysiwygSelectionPainter',
    );
    final customPaint = tester.widget<CustomPaint>(painterFinder.at(1));
    final painter = customPaint.painter! as dynamic;
    expect(painter.selectionRange.start, 0);
    expect(painter.selectionRange.end, firstParagraph.length);

    final paintBox = tester.renderObject<RenderBox>(painterFinder.at(1));
    final painterText =
        TextPainter(
          text: TextSpan(
            text: firstParagraph,
            style: painter.style as TextStyle,
          ),
          textDirection: painter.textDirection as TextDirection,
          textScaler: painter.textScaler as TextScaler,
          locale: painter.locale as Locale?,
        )..layout(
          maxWidth: paintBox.size.width - (painter.layoutWidthInset as double),
        );
    final highlightBoxes = painterText.getBoxesForSelection(
      TextSelection(
        baseOffset: exampleStart,
        extentOffset: exampleStart + 'example.'.length,
      ),
    );
    painterText.dispose();

    expect(highlightBoxes, hasLength(exampleBoxes.length));
    final lineTolerance =
        (exampleBoxes.last.bottom - exampleBoxes.last.top) / 3;
    expect(
      (highlightBoxes.last.top - exampleBoxes.last.top).abs(),
      lessThan(lineTolerance),
    );
    expect(
      (highlightBoxes.last.bottom - exampleBoxes.last.bottom).abs(),
      lessThan(lineTolerance),
    );
  });

  testWidgets('WYSIWYG Ctrl+X cuts block selection', (tester) async {
    const source = 'First\n\nSecond\n\nThird\n';
    final parsed = parser.parse(filePath: 'topic.md', source: source);
    var markdown = source;
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final arguments = call.arguments as Map<Object?, Object?>;
          copiedText = arguments['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final firstFieldRect = tester.getRect(find.byType(TextField).at(0));
    final secondFieldRect = tester.getRect(find.byType(TextField).at(1));
    final gesture = await tester.startGesture(
      firstFieldRect.centerLeft + const Offset(1, 0),
    );
    await gesture.moveTo(secondFieldRect.centerLeft + const Offset(80, 0));
    await gesture.up();
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyX);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyX);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(copiedText, 'First\n\nSecond');
    expect(markdown, contains('Third'));
    expect(markdown, isNot(contains('First')));
    expect(markdown, isNot(contains('Second')));
  });

  testWidgets('WYSIWYG cut paste preserves inline formatting', (tester) async {
    const source = 'Hello **bold** world\n\nTarget\n';
    final parsed = parser.parse(filePath: 'topic.md', source: source);
    var markdown = source;
    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final arguments = call.arguments as Map<Object?, Object?>;
          clipboardText = arguments['text'] as String?;
        }
        if (call.method == 'Clipboard.getData') {
          return {'text': clipboardText};
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final firstField = tester.widget<TextField>(find.byType(TextField).at(0));
    firstField.focusNode!.requestFocus();
    firstField.controller!.selection = const TextSelection(
      baseOffset: 6,
      extentOffset: 10,
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyX);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyX);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(clipboardText, 'bold');

    final secondField = tester.widget<TextField>(find.byType(TextField).at(1));
    secondField.focusNode!.requestFocus();
    secondField.controller!.selection = TextSelection.collapsed(
      offset: secondField.controller!.text.length,
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(markdown, 'Hello  world\n\nTarget**bold**\n');
  });

  testWidgets('WYSIWYG cut paste preserves whole block formatting', (
    tester,
  ) async {
    const source = '# Title\n\nPara with **bold** text\n\nTail\n';
    final parsed = parser.parse(filePath: 'topic.md', source: source);
    var markdown = source;
    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final arguments = call.arguments as Map<Object?, Object?>;
          clipboardText = arguments['text'] as String?;
        }
        if (call.method == 'Clipboard.getData') {
          return {'text': clipboardText};
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final titleField = tester.widget<TextField>(find.byType(TextField).at(0));
    titleField.focusNode!.requestFocus();
    titleField.controller!.selection = TextSelection(
      baseOffset: 0,
      extentOffset: titleField.controller!.text.length,
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyX);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyX);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(clipboardText, 'Title');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(markdown, source);
  });

  testWidgets('WYSIWYG drag selection preserves partial paragraph boundaries', (
    tester,
  ) async {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: 'Alpha first paragraph\n\nBeta second paragraph\n',
    );
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final arguments = call.arguments as Map<Object?, Object?>;
          copiedText = arguments['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final firstFieldRect = tester.getRect(find.byType(TextField).at(0));
    final secondFieldRect = tester.getRect(find.byType(TextField).at(1));
    final gesture = await tester.startGesture(
      firstFieldRect.centerLeft + const Offset(46, 0),
    );
    await gesture.moveTo(secondFieldRect.centerLeft + const Offset(42, 0));
    await gesture.up();
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(copiedText, isNotNull);
    expect(copiedText, isNot('Alpha first paragraph\n\nBeta second paragraph'));
    expect(copiedText, contains('\n\n'));
  });

  testWidgets('WYSIWYG toolbar bold applies to selected paragraphs', (
    tester,
  ) async {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: 'First\n\nSecond\n\nThird\n',
    );
    var markdown = '';

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final firstFieldRect = tester.getRect(find.byType(TextField).at(0));
    final secondFieldRect = tester.getRect(find.byType(TextField).at(1));
    final gesture = await tester.startGesture(
      firstFieldRect.centerLeft + const Offset(1, 0),
    );
    await gesture.moveTo(secondFieldRect.centerLeft + const Offset(80, 0));
    await gesture.up();
    await tester.pump();

    await tester.tap(find.byIcon(BusyMarkGlyphs.bold));
    await tester.pump();

    expect(markdown, '**First**\n\n**Second**\n\nThird\n');
  });

  testWidgets(
    'WYSIWYG toolbar toggle stays vertically aligned when collapsed',
    (tester) async {
      final parsed = parser.parse(filePath: 'topic.md', source: 'First\n');

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 900,
              height: 640,
              child: BusyMarkWysiwygEditor(
                document: parsed.busyDocument,
                onSourceChanged: (_, _) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final hideRect = tester.getRect(find.byTooltip('Hide editing buttons'));

      await tester.tap(find.byTooltip('Hide editing buttons'));
      await tester.pump();

      final showRect = tester.getRect(find.byTooltip('Show editing buttons'));

      expect(showRect.center.dy, closeTo(hideRect.center.dy, 0.1));
    },
  );

  testWidgets('WYSIWYG toolbar list applies to selected paragraphs', (
    tester,
  ) async {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: 'First\n\nSecond\n\nThird\n',
    );
    var markdown = '';

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final firstFieldRect = tester.getRect(find.byType(TextField).at(0));
    final secondFieldRect = tester.getRect(find.byType(TextField).at(1));
    final gesture = await tester.startGesture(
      firstFieldRect.centerLeft + const Offset(1, 0),
    );
    await gesture.moveTo(secondFieldRect.centerLeft + const Offset(80, 0));
    await gesture.up();
    await tester.pump();

    await tester.tap(find.byIcon(BusyMarkGlyphs.unorderedList));
    await tester.pump();

    expect(markdown, '- First\n\n- Second\n\nThird\n');
  });

  testWidgets('WYSIWYG renders safe HTML blocks and edits raw source', (
    tester,
  ) async {
    final l10n = AppLocalizationsEn();
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '<p>Hello <strong>HTML</strong></p>\n',
    );
    var markdown = '';

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.renderedHtml), findsOneWidget);
    expect(find.text('Hello HTML'), findsOneWidget);
    expect(find.textContaining('<p>'), findsNothing);

    await tester.tap(find.byIcon(BusyMarkGlyphs.edit));
    await tester.pumpAndSettle();

    expect(find.text(l10n.editHtml), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('wysiwyg-html-source-field')),
      '<p>Changed</p>',
    );
    await tester.tap(find.text(l10n.apply));
    await tester.pumpAndSettle();

    expect(markdown, '<p>Changed</p>\n');
    expect(find.text('Changed'), findsOneWidget);
  });

  testWidgets('WYSIWYG toolbar inserts an HTML block', (tester) async {
    final l10n = AppLocalizationsEn();
    final parsed = parser.parse(filePath: 'topic.md', source: 'Start\n');
    var markdown = '';

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    await tester.tap(
      find.byTooltip(
        '${l10n.htmlBlock} (${BusyMarkEditorShortcutLabels.htmlBlock})',
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('wysiwyg-html-source-field')),
      '<p>Inserted</p>',
    );
    await tester.tap(find.text(l10n.insert));
    await tester.pumpAndSettle();

    expect(markdown, 'Start\n\n<p>Inserted</p>\n');
    expect(find.text(l10n.renderedHtml), findsOneWidget);
    expect(find.text('Inserted'), findsOneWidget);
  });

  testWidgets('WYSIWYG typing preserves existing inline formatting', (
    tester,
  ) async {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: 'Hello **bold** world\n',
    );
    var markdown = '';

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'Hello bold! world');
    await tester.pump();

    expect(markdown, 'Hello **bold!** world\n');
  });

  testWidgets('WYSIWYG Backspace at block start merges with previous block', (
    tester,
  ) async {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: 'First\n\nSecond\n',
    );
    var markdown = '';

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final secondField = tester.widget<TextField>(find.byType(TextField).at(1));
    secondField.focusNode!.requestFocus();
    secondField.controller!.selection = const TextSelection.collapsed(
      offset: 0,
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();

    expect(markdown, 'FirstSecond\n');
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('WYSIWYG Ctrl+A twice selects all text for deletion', (
    tester,
  ) async {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: 'First\n\nSecond\n\nThird\n',
    );
    var markdown = '';

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    TextField fieldAt(int index) {
      return tester.widget<TextField>(find.byType(TextField).at(index));
    }

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(fieldAt(0).controller!.selection.start, 0);
    expect(fieldAt(0).controller!.selection.end, 'First'.length);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(
      TextSelectionTheme.of(
        tester.element(find.byType(TextField).at(0)),
      ).selectionColor,
      Colors.transparent,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();

    expect(markdown, isEmpty);
    expect(find.byType(TextField), findsOneWidget);
    expect(fieldAt(0).controller!.text, isEmpty);
  });

  test('WYSIWYG inline ranges do not duplicate formatted text', () {
    final parsed = parser.parse(filePath: 'topic.md', source: '**source**\n');
    final block = parsed.busyDocument.blocks.single;
    final ranges = busyInlineStyleRanges(block.inlines);

    expect(block.plainText, 'source');
    expect(ranges, hasLength(1));
    expect(ranges.single.start, 0);
    expect(ranges.single.end, 'source'.length);
    expect(ranges.single.kind, BusyInlineKind.strong);
  });

  test('WYSIWYG inline commands serialize bold italic and links', () {
    final parsed = parser.parse(filePath: 'topic.md', source: 'Alpha Beta\n');
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final blockId = parsed.busyDocument.blocks.first.id;

    controller.applyInlineCommand(blockId, BusyWysiwygInlineCommand.bold, 0, 5);
    expect(controller.markdown, '**Alpha** Beta\n');

    final reparsed = parser.parse(filePath: 'topic.md', source: 'Alpha Beta\n');
    final linkController = BusyMarkWysiwygDocumentController(
      document: reparsed.busyDocument,
    );
    final linkBlockId = reparsed.busyDocument.blocks.first.id;
    linkController.applyInlineCommand(
      linkBlockId,
      BusyWysiwygInlineCommand.link,
      6,
      10,
      destination: 'target.md',
    );

    expect(linkController.markdown, 'Alpha [Beta](target.md)\n');
  });

  test('WYSIWYG text edits preserve inline ranges where possible', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: 'Hello **bold** world\n',
    );
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final blockId = controller.document.blocks.first.id;

    controller.updateBlockText(blockId, 'Hello bold! world');

    expect(controller.markdown, 'Hello **bold!** world\n');
  });

  test(
    'WYSIWYG inline command toggles selected mark without dropping links',
    () {
      final parsed = parser.parse(
        filePath: 'topic.md',
        source: '**Alpha** [Beta](target.md)\n',
      );
      final controller = BusyMarkWysiwygDocumentController(
        document: parsed.busyDocument,
      );
      final blockId = controller.document.blocks.first.id;

      controller.applyInlineCommand(
        blockId,
        BusyWysiwygInlineCommand.italic,
        6,
        10,
      );
      controller.applyInlineCommand(
        blockId,
        BusyWysiwygInlineCommand.bold,
        0,
        5,
      );

      expect(controller.markdown, 'Alpha [*Beta*](target.md)\n');
    },
  );

  test('WYSIWYG inline code command serializes selected text', () {
    final parsed = parser.parse(filePath: 'topic.md', source: 'Alpha Beta\n');
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final blockId = parsed.busyDocument.blocks.first.id;

    controller.applyInlineCommand(
      blockId,
      BusyWysiwygInlineCommand.code,
      6,
      10,
    );

    expect(controller.markdown, 'Alpha `Beta`\n');
  });

  test('WYSIWYG inline commands preserve existing sibling formatting', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: 'Attached source archive\n',
    );
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final blockId = parsed.busyDocument.blocks.first.id;

    controller.applyInlineCommand(
      blockId,
      BusyWysiwygInlineCommand.bold,
      'Attached source '.length,
      'Attached source archive'.length,
    );
    controller.applyInlineCommand(
      blockId,
      BusyWysiwygInlineCommand.italic,
      'Attached '.length,
      'Attached source'.length,
    );

    expect(controller.markdown, 'Attached *source* **archive**\n');
  });

  test('WYSIWYG block commands apply to multiple selected blocks', () {
    final parsed = parser.parse(filePath: 'topic.md', source: 'One\n\nTwo\n');
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final blockIds = controller.document.blocks.map((block) => block.id);

    controller.applyBlockCommandToBlocks(
      blockIds,
      BusyWysiwygBlockCommand.orderedList,
    );

    expect(controller.document.blocks[0].attributes['marker'], '1.');
    expect(controller.document.blocks[1].attributes['marker'], '2.');
    expect(controller.markdown, '1. One\n\n2. Two\n');
  });

  test('WYSIWYG inline commands apply to multiple selected blocks', () {
    final parsed = parser.parse(filePath: 'topic.md', source: 'One\n\nTwo\n');
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final blockIds = controller.document.blocks.map((block) => block.id);

    controller.applyInlineCommandToBlocks(
      blockIds,
      BusyWysiwygInlineCommand.bold,
    );

    expect(controller.markdown, '**One**\n\n**Two**\n');
  });

  test('WYSIWYG image command serializes a real image block', () {
    final parsed = parser.parse(filePath: 'topic.md', source: 'Image here\n');
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final blockId = parsed.busyDocument.blocks.first.id;

    controller.applyImageBlock(
      blockId,
      source: 'images/example.png',
      alt: 'Example image',
    );

    expect(controller.markdown, '![Example image](images/example.png)\n');
  });

  testWidgets('WYSIWYG editor renders Writerside images by basename', (
    tester,
  ) async {
    final temp = Directory.systemTemp.createTempSync('busymark_wysiwyg_image_');
    var markdown = '';
    try {
      final topicsDir = Directory('${temp.path}/topics')..createSync();
      final imagesDir = Directory('${temp.path}/images')..createSync();
      File('${imagesDir.path}/rpi_1.jpg').writeAsBytesSync(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAFgwJ/l8Kz3wAAAABJRU5ErkJggg==',
        ),
      );
      final document = BusyDocument(
        filePath: '${topicsDir.path}/topic.md',
        mode: MarkdownMode.writersideMarkdown,
        blocks: const [
          BusyBlock(
            id: 'image',
            kind: BusyBlockKind.image,
            inlines: [
              BusyInline(
                kind: BusyInlineKind.image,
                text: 'Raspberry Pi',
                destination: 'rpi_1.jpg',
              ),
            ],
            attributes: {'src': 'rpi_1.jpg'},
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 900,
              height: 640,
              child: BusyMarkWysiwygEditor(
                document: document,
                workspaceRoot: topicsDir.path,
                writersideRoot: temp.path,
                imagesDir: 'images',
                onSourceChanged: (filePath, value) => markdown = value,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('rpi_1.jpg'), findsNothing);
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.byKey(const ValueKey('wysiwyg-image-block-image')));
      await tester.pumpAndSettle();

      expect(find.text('Image'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).at(0)).controller?.text,
        'rpi_1.jpg',
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).controller?.text,
        'Raspberry Pi',
      );

      await tester.enterText(
        find.byType(TextField).at(0),
        'images/updated.png',
      );
      await tester.enterText(find.byType(TextField).at(1), 'Updated alt');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(markdown, '![Updated alt](images/updated.png)\n');
    } finally {
      temp.deleteSync(recursive: true);
    }
  });

  testWidgets('WYSIWYG editor renders absolute local image paths', (
    tester,
  ) async {
    final workspace = Directory.systemTemp.createTempSync(
      'busymark_wysiwyg_image_workspace_',
    );
    final outside = Directory.systemTemp.createTempSync(
      'busymark_wysiwyg_image_outside_',
    );
    try {
      final image = File('${outside.path}/example.jpg')
        ..writeAsBytesSync(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAFgwJ/l8Kz3wAAAABJRU5ErkJggg==',
          ),
        );
      final documentPath = '${workspace.path}/topic.md';
      final parsed = parser.parse(
        filePath: documentPath,
        workspaceRoot: workspace.path,
        source: '![example.jpg](${image.path})\n',
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 900,
              height: 640,
              child: BusyMarkWysiwygEditor(
                document: parsed.busyDocument,
                workspaceRoot: workspace.path,
                onSourceChanged: (_, _) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
      expect(find.textContaining(image.path), findsNothing);
    } finally {
      workspace.deleteSync(recursive: true);
      outside.deleteSync(recursive: true);
    }
  });

  testWidgets('WYSIWYG editor renders linked remote image blocks', (
    tester,
  ) async {
    const imageUrl = 'https://example.com/remote.png';
    final previousHttpClientProvider = debugNetworkImageHttpClientProvider;
    final parsed = parser.parse(
      filePath: 'README.md',
      source: '[![busymark]($imageUrl)](https://snapcraft.io/busymark)\n',
    );

    try {
      debugNetworkImageHttpClientProvider = () => _FakeImageHttpClient();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 900,
              height: 640,
              child: BusyMarkWysiwygEditor(
                document: parsed.busyDocument,
                onSourceChanged: (_, _) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final imageView = tester.widget<MarkdownImageView>(
        find.byType(MarkdownImageView),
      );
      expect(imageView.source, imageUrl);
      expect(imageView.alt, 'busymark');
      expect(find.byType(Image), findsOneWidget);
      expect(find.text(imageUrl), findsNothing);
      expect(find.byType(TextField), findsNothing);
    } finally {
      debugNetworkImageHttpClientProvider = previousHttpClientProvider;
    }
  });

  test('WYSIWYG Enter splits one block into separate Markdown paragraphs', () {
    final parsed = parser.parse(filePath: 'topic.md', source: 'FirstSecond\n');
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final blockId = parsed.busyDocument.blocks.first.id;

    final nextBlockId = controller.splitBlockAt(blockId, 'First'.length);

    expect(nextBlockId, isNotNull);
    expect(controller.markdown, 'First\n\nSecond\n');
  });

  test('WYSIWYG Enter in unordered list creates next item then exits list', () {
    final parsed = parser.parse(filePath: 'topic.md', source: '- First\n');
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final blockId = parsed.busyDocument.blocks.first.id;

    final nextItem = controller.applyEnterAt(blockId, 'First'.length);

    expect(nextItem, isNotNull);
    expect(
      controller.document.blocks.map((block) => block.kind),
      containsAllInOrder([
        BusyBlockKind.unorderedListItem,
        BusyBlockKind.unorderedListItem,
      ]),
    );
    expect(controller.markdown, '- First\n\n-\n');

    final paragraph = controller.applyEnterAt(nextItem!.blockId, 0);

    expect(paragraph?.blockId, nextItem.blockId);
    expect(controller.document.blocks[1].kind, BusyBlockKind.paragraph);
    expect(controller.markdown, '- First\n');
  });

  test('WYSIWYG Enter in ordered list creates next numbered item', () {
    final parsed = parser.parse(filePath: 'topic.md', source: '1. First\n');
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final blockId = parsed.busyDocument.blocks.first.id;

    final nextItem = controller.applyEnterAt(blockId, 'First'.length);

    expect(nextItem, isNotNull);
    expect(controller.document.blocks[1].kind, BusyBlockKind.orderedListItem);
    expect(controller.document.blocks[1].attributes['marker'], '2.');
    expect(controller.markdown, '1. First\n\n2.\n');
  });

  test('WYSIWYG thematic break inserts after current block', () {
    final parsed = parser.parse(filePath: 'topic.md', source: 'Intro\n');
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final blockId = parsed.busyDocument.blocks.first.id;

    controller.insertThematicBreakAfter(blockId);

    expect(controller.markdown, 'Intro\n\n---\n');
  });

  testWidgets('WYSIWYG Enter key creates a new paragraph block', (
    tester,
  ) async {
    final parsed = parser.parse(filePath: 'topic.md', source: 'FirstSecond\n');
    var markdown = '';

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final firstField = tester.widget<TextField>(find.byType(TextField).first);
    firstField.controller!.selection = const TextSelection.collapsed(offset: 5);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(markdown, 'First\n\nSecond\n');
    expect(find.byType(TextField), findsNWidgets(2));
    expect(
      tester
          .widget<TextField>(find.byType(TextField).at(1))
          .focusNode
          ?.hasFocus,
      isTrue,
    );
  });

  testWidgets('WYSIWYG Enter carries active inline style to next paragraph', (
    tester,
  ) async {
    final parsed = parser.parse(filePath: 'topic.md', source: '**Bold**\n');
    var markdown = parsed.source;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final firstField = tester.widget<TextField>(find.byType(TextField).first);
    firstField.focusNode!.requestFocus();
    firstField.controller!.selection = const TextSelection.collapsed(offset: 4);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    await tester.enterText(find.byType(TextField).at(1), 'Next');
    await tester.pump();

    expect(markdown, '**Bold**\n\n**Next**\n');
  });

  testWidgets('WYSIWYG Enter at paragraph end preserves inner bold span', (
    tester,
  ) async {
    const sentence =
        'Users can do the following activities: input - reading, listening; '
        'output - writing, speaking, choosing (e.g. correct word for empty '
        'spot in a sentence). these activities should absolutely be mixed '
        '(interleaved), rather than strictly grouped (blocked).';
    final parsed = parser.parse(filePath: 'topic.md', source: '$sentence\n');
    var markdown = parsed.source;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField).first);
    final groupedStart = sentence.indexOf('grouped');
    final groupedEnd = groupedStart + 'grouped'.length;
    field.focusNode!.requestFocus();
    field.controller!.selection = TextSelection(
      baseOffset: groupedStart,
      extentOffset: groupedEnd,
    );

    await tester.tap(find.byIcon(BusyMarkGlyphs.bold));
    await tester.pump();

    field.controller!.selection = TextSelection.collapsed(
      offset: sentence.length,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(markdown, '${sentence.replaceFirst('grouped', '**grouped**')}\n');
    final context = tester.element(find.byType(TextField).first);
    final span = field.controller!.buildTextSpan(
      context: context,
      style: DefaultTextStyle.of(context).style,
      withComposing: false,
    );
    expect(_spanStyleForText(span, 'grouped')?.fontWeight, FontWeight.w700);
  });

  testWidgets('WYSIWYG newline text edit preserves inner bold span', (
    tester,
  ) async {
    const sentence =
        'Users can do the following activities: input - reading, listening; '
        'output - writing, speaking, choosing (e.g. correct word for empty '
        'spot in a sentence). these activities should absolutely be mixed '
        '(interleaved), rather than strictly grouped (blocked).';
    final parsed = parser.parse(filePath: 'topic.md', source: '$sentence\n');
    var markdown = parsed.source;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField).first);
    final groupedStart = sentence.indexOf('grouped');
    field.focusNode!.requestFocus();
    field.controller!.selection = TextSelection(
      baseOffset: groupedStart,
      extentOffset: groupedStart + 'grouped'.length,
    );

    await tester.tap(find.byIcon(BusyMarkGlyphs.bold));
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, '$sentence\n');
    await tester.pump();

    expect(markdown, '${sentence.replaceFirst('grouped', '**grouped**')}\n');
    final updatedField = tester.widget<TextField>(find.byType(TextField).first);
    final context = tester.element(find.byType(TextField).first);
    final span = updatedField.controller!.buildTextSpan(
      context: context,
      style: DefaultTextStyle.of(context).style,
      withComposing: false,
    );
    expect(_spanStyleForText(span, 'grouped')?.fontWeight, FontWeight.w700);
  });

  testWidgets('WYSIWYG text input newlines become Markdown paragraphs', (
    tester,
  ) async {
    final parsed = parser.parse(filePath: 'topic.md', source: 'First\n');
    var markdown = '';

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'First\nSecond');
    await tester.pump();

    expect(markdown, 'First\n\nSecond\n');
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('WYSIWYG editor lazily builds large documents', (tester) async {
    final source = List.generate(
      500,
      (index) => 'Paragraph ${index + 1}',
    ).join('\n\n');
    final parsed = parser.parse(filePath: 'topic.md', source: source);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(TextField).evaluate().length, lessThan(80));
  });

  test('WYSIWYG block commands serialize headings and lists', () {
    final parsed = parser.parse(filePath: 'topic.md', source: 'Title\n');
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final blockId = parsed.busyDocument.blocks.first.id;

    controller.applyBlockCommand(blockId, BusyWysiwygBlockCommand.heading2);
    expect(controller.markdown, '## Title\n');

    controller.applyBlockCommand(blockId, BusyWysiwygBlockCommand.heading6);
    expect(controller.markdown, '###### Title\n');

    controller.applyBlockCommand(blockId, BusyWysiwygBlockCommand.taskList);
    expect(controller.markdown, '- [ ] Title\n');
  });

  test('WYSIWYG extended toolbar commands serialize Markdown', () {
    final parsed = parser.parse(filePath: 'topic.md', source: 'Alpha Beta\n');
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final blockId = parsed.busyDocument.blocks.first.id;

    controller.insertInlineImage(
      blockId,
      selectionStart: 6,
      selectionEnd: 10,
      source: 'images/logo.png',
      alt: 'Logo',
      fallbackAltText: 'Image',
    );
    expect(controller.markdown, 'Alpha ![Logo](images/logo.png)\n');

    final hardBreakParsed = parser.parse(
      filePath: 'topic.md',
      source: 'Alpha Beta\n',
    );
    final hardBreakController = BusyMarkWysiwygDocumentController(
      document: hardBreakParsed.busyDocument,
    );
    final hardBreakBlockId = hardBreakParsed.busyDocument.blocks.first.id;

    hardBreakController.insertHardBreak(hardBreakBlockId, 5);
    expect(hardBreakController.markdown, 'Alpha  \n Beta\n');
  });

  test('WYSIWYG table and code language commands serialize Markdown', () {
    final parsed = parser.parse(filePath: 'topic.md', source: 'Intro\n');
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final blockId = parsed.busyDocument.blocks.first.id;

    controller.insertTableAfter(
      blockId,
      columns: 2,
      rows: 1,
      headerTextForColumn: (column) => 'Header $column',
      cellText: 'Cell',
    );

    expect(
      controller.markdown,
      'Intro\n\n'
      '| Header 1 | Header 2 |\n'
      '| --- | --- |\n'
      '| Cell | Cell |\n',
    );

    final tableId = controller.document.blocks
        .singleWhere((block) => block.kind == BusyBlockKind.table)
        .id;
    final table = controller.document.blocks.singleWhere(
      (block) => block.kind == BusyBlockKind.table,
    );
    controller.updateTableCellText(
      table.id,
      table.children.first.children.first.id,
      'Name',
    );
    expect(
      controller.markdown,
      'Intro\n\n'
      '| Name | Header 2 |\n'
      '| --- | --- |\n'
      '| Cell | Cell |\n',
    );
    controller.replaceTable(
      tableId,
      columns: 3,
      rows: 1,
      headerTextForColumn: (column) => 'Header $column',
      cellText: 'Cell',
    );
    expect(
      controller.markdown,
      'Intro\n\n'
      '| Name | Header 2 | Header 3 |\n'
      '| --- | --- | --- |\n'
      '| Cell | Cell | Cell |\n',
    );

    final parsedTable = parser.parse(
      filePath: 'topic.md',
      source:
          '| Header 1 | Header 2 |\n'
          '| --- | --- |\n'
          '| Cell | Cell |\n',
    );
    final parsedTableController = BusyMarkWysiwygDocumentController(
      document: parsedTable.busyDocument,
    );
    final parsedTableBlock = parsedTableController.document.blocks.singleWhere(
      (block) => block.kind == BusyBlockKind.table,
    );
    final parsedHeaderCellId =
        parsedTableBlock.children.first.children.first.id;
    parsedTableController.updateTableCellText(
      parsedTableBlock.id,
      parsedHeaderCellId,
      'Name',
    );
    expect(parsedTableController.blockText(parsedHeaderCellId), 'Name');
    expect(
      parsedTableController.markdown,
      '| Name | Header 2 |\n'
      '| --- | --- |\n'
      '| Cell | Cell |\n',
    );

    final codeParsed = parser.parse(
      filePath: 'topic.md',
      source: 'print(1);\n',
    );
    final codeController = BusyMarkWysiwygDocumentController(
      document: codeParsed.busyDocument,
    );
    final codeBlockId = codeParsed.busyDocument.blocks.first.id;

    codeController.applyCodeBlockLanguage(codeBlockId, 'dart');
    expect(codeController.markdown, '```dart\nprint(1);\n```\n');
  });

  test('WYSIWYG table row and column commands serialize Markdown', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source:
          '| Header 1 | Header 2 |\n'
          '| --- | --- |\n'
          '| Cell | Cell |\n',
    );
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    String tableId() => controller.document.blocks
        .singleWhere((block) => block.kind == BusyBlockKind.table)
        .id;

    controller.insertTableRow(tableId(), 1, after: false);
    expect(
      controller.markdown,
      '| Header 1 | Header 2 |\n'
      '| --- | --- |\n'
      '|  |  |\n'
      '| Cell | Cell |\n',
    );

    controller.insertTableColumn(tableId(), 0, after: true);
    expect(
      controller.markdown,
      '| Header 1 |  | Header 2 |\n'
      '| --- | --- | --- |\n'
      '|  |  |  |\n'
      '| Cell |  | Cell |\n',
    );

    controller.deleteTableColumn(tableId(), 1);
    expect(
      controller.markdown,
      '| Header 1 | Header 2 |\n'
      '| --- | --- |\n'
      '|  |  |\n'
      '| Cell | Cell |\n',
    );

    controller.deleteTableRow(tableId(), 1);
    expect(
      controller.markdown,
      '| Header 1 | Header 2 |\n'
      '| --- | --- |\n'
      '| Cell | Cell |\n',
    );

    controller.deleteTableRow(tableId(), 0);
    expect(
      controller.markdown,
      '| Cell | Cell |\n'
      '| --- | --- |\n',
    );

    controller.deleteTable(tableId());
    expect(controller.markdown, '');
  });

  testWidgets('WYSIWYG table cells are formatted and editable', (tester) async {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source:
          'Intro\n\n'
          '| Header 1 | Header 2 |\n'
          '| --- | --- |\n'
          '| Cell | Cell |\n',
    );
    var markdown = '';
    final widgetTable = parsed.busyDocument.blocks.singleWhere(
      (block) => block.kind == BusyBlockKind.table,
    );
    final headerCellId = widgetTable.children.first.children.first.id;
    final bodyCellId = widgetTable.children[1].children.first.id;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Table), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(5));
    expect(find.text('| Header 1 | Header 2 |'), findsNothing);
    expect(find.byTooltip('Delete table'), findsOneWidget);
    expect(find.byTooltip('Column 1'), findsOneWidget);
    expect(find.byTooltip('Column 2'), findsOneWidget);
    expect(find.byTooltip('Row 1'), findsOneWidget);
    expect(find.byTooltip('Row 2'), findsOneWidget);

    final headerField = tester.widget<TextField>(
      find.byKey(ValueKey(headerCellId)),
    );
    final bodyField = tester.widget<TextField>(
      find.byKey(ValueKey(bodyCellId)),
    );
    expect(headerField.onChanged, isNotNull);
    expect(bodyField.onChanged, isNotNull);

    headerField.onChanged!('Name');
    await tester.pump();
    bodyField.onChanged!('Alice');
    await tester.pump();

    expect(
      markdown,
      'Intro\n\n'
      '| Name | Header 2 |\n'
      '| --- | --- |\n'
      '| Alice | Cell |\n',
    );
  });

  test('WYSIWYG list indent outdent and task toggle commands serialize', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '- Parent\n- Child\n',
    );
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final childId = parsed.busyDocument.blocks[1].id;

    controller.indentListItems([childId]);
    expect(controller.markdown, '- Parent\n  - Child\n');

    controller.outdentListItems([childId]);
    expect(controller.markdown, '- Parent\n\n- Child\n');

    final taskParsed = parser.parse(
      filePath: 'topic.md',
      source: '- [ ] Todo\n',
    );
    final taskController = BusyMarkWysiwygDocumentController(
      document: taskParsed.busyDocument,
    );
    final taskId = taskParsed.busyDocument.blocks.first.id;

    taskController.toggleTaskChecked([taskId]);
    expect(taskController.markdown, '- [x] Todo\n');
  });
}

TextStyle? _spanStyleForText(InlineSpan span, String text) {
  if (span is TextSpan) {
    if ((span.text ?? '').contains(text)) {
      return span.style;
    }
    final children = span.children;
    if (children != null) {
      for (final child in children) {
        final style = _spanStyleForText(child, text);
        if (style != null) {
          return style;
        }
      }
    }
  }
  return null;
}

RenderEditable? _findRenderEditable(RenderObject root) {
  if (root is RenderEditable) {
    return root;
  }
  RenderEditable? result;
  root.visitChildren((child) {
    result ??= _findRenderEditable(child);
  });
  return result;
}

class _FakeImageHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeImageRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeImageRequest implements HttpClientRequest {
  @override
  HttpHeaders get headers => _FakeImageHeaders();

  @override
  Future<HttpClientResponse> close() async => _FakeImageResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeImageHeaders implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeImageResponse extends Stream<List<int>>
    implements HttpClientResponse {
  static final _bytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAFgwJ/l8Kz3wAAAABJRU5ErkJggg==',
  );

  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _bytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_bytes]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
