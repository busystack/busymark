import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_commands.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = MarkdownParser();
  const source = '```javascript\nline();\n```\n';

  BusyMarkWysiwygDocumentController open([String markdown = source]) {
    return BusyMarkWysiwygDocumentController(
      document: parser
          .parse(filePath: 'code.md', source: markdown)
          .busyDocument,
    );
  }

  test('terminal code block gets a non-serializing trailing paragraph', () {
    for (final markdown in [source, source.trimRight()]) {
      final controller = open(markdown);

      expect(controller.document.blocks, hasLength(2));
      expect(controller.document.blocks.first.kind, BusyBlockKind.codeBlock);
      expect(controller.document.blocks.last.kind, BusyBlockKind.paragraph);
      expect(
        controller
            .document
            .blocks
            .last
            .attributes[busyMarkTransientTrailingParagraphAttribute],
        'true',
      );
      expect(controller.markdown, markdown);
    }
  });

  test('Enter inserts a newline within one code block', () {
    final controller = open();
    final code = controller.document.blocks.first;

    final result = controller.applyEnterAt(code.id, 4);

    expect(result?.blockId, code.id);
    expect(result?.offset, 5);
    expect(controller.blockText(code.id), 'line\n();');
    expect(
      controller.document.blocks.where(
        (block) => block.kind == BusyBlockKind.codeBlock,
      ),
      hasLength(1),
    );
    expect(controller.markdown, '```javascript\nline\n();\n```\n');
  });

  test('a code block created by editing also retains a trailing paragraph', () {
    final document = parser
        .parse(filePath: 'code.md', source: 'Paragraph\n')
        .busyDocument;
    final controller = BusyMarkWysiwygDocumentController(document: document);

    controller.applyBlockCommand(
      document.blocks.single.id,
      BusyWysiwygBlockCommand.codeBlock,
    );

    expect(controller.document.blocks, hasLength(2));
    expect(controller.document.blocks.first.kind, BusyBlockKind.codeBlock);
    expect(controller.document.blocks.last.kind, BusyBlockKind.paragraph);
    expect(
      controller
          .document
          .blocks
          .last
          .attributes[busyMarkTransientTrailingParagraphAttribute],
      'true',
    );
  });

  test('third terminal Enter exits code and removes the two empty lines', () {
    final controller = open();
    final code = controller.document.blocks.first;

    var result = controller.applyEnterAt(code.id, code.plainText.length);
    result = controller.applyEnterAt(
      code.id,
      controller.blockText(code.id).length,
    );
    result = controller.applyEnterAt(
      code.id,
      controller.blockText(code.id).length,
    );

    expect(result?.blockId, controller.document.blocks.last.id);
    expect(controller.blockText(code.id), 'line();');
    expect(controller.document.blocks, hasLength(2));
    expect(controller.markdown, source);
  });

  test('exiting before existing content inserts a transient paragraph', () {
    const withFollowingParagraph = '```javascript\nline();\n```\n\nFollowing\n';
    final controller = open(withFollowingParagraph);
    final code = controller.document.blocks.first;

    final paragraphId = controller.exitCodeBlock(code.id);

    expect(paragraphId, isNotNull);
    expect(controller.document.blocks, hasLength(3));
    expect(controller.markdown, withFollowingParagraph);

    controller.updateBlockText(paragraphId!, 'Inserted');

    expect(
      controller.markdown,
      '```javascript\nline();\n```\n\nInserted\n\nFollowing\n',
    );
  });

  test('Enter in the trailing paragraph records an intentional blank', () {
    final controller = open();
    final trailing = controller.document.blocks.last;

    final result = controller.applyEnterAt(trailing.id, 0);

    expect(controller.document.blocks, hasLength(3));
    expect(result?.blockId, controller.document.blocks.last.id);
    expect(
      controller.document.blocks
          .skip(1)
          .every(
            (block) =>
                block.attributes[busyMarkTransientTrailingParagraphAttribute] ==
                null,
          ),
      isTrue,
    );
    expect(controller.markdown, '$source\n\n');
  });

  testWidgets('code Enter stays in the multiline code field', (tester) async {
    final document = parser.parse(filePath: 'code.md', source: source);
    var markdown = source;

    await tester.pumpWidget(
      _app(
        BusyMarkWysiwygEditor(
          document: document.busyDocument,
          onSourceChanged: (_, value) => markdown = value,
        ),
      ),
    );
    await tester.pump();

    final codeField = tester.widget<TextField>(find.byType(TextField).first);
    codeField.focusNode!.requestFocus();
    codeField.controller!.selection = TextSelection.collapsed(
      offset: codeField.controller!.text.length,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(codeField.focusNode!.hasFocus, isTrue);
    expect(codeField.controller!.text, 'line();\n');
    expect(find.byType(TextField), findsNWidgets(2));
    expect(markdown, '```javascript\nline();\n\n```\n');
  });

  testWidgets('Ctrl+Enter exits into the trailing paragraph', (tester) async {
    final document = parser.parse(filePath: 'code.md', source: source);
    var markdown = source;

    await tester.pumpWidget(
      _app(
        BusyMarkWysiwygEditor(
          document: document.busyDocument,
          onSourceChanged: (_, value) => markdown = value,
        ),
      ),
    );
    await tester.pump();

    final fields = find.byType(TextField);
    final codeField = tester.widget<TextField>(fields.first);
    codeField.focusNode!.requestFocus();
    codeField.controller!.selection = TextSelection.collapsed(
      offset: codeField.controller!.text.length,
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    final trailingField = tester.widget<TextField>(fields.at(1));
    expect(trailingField.focusNode!.hasFocus, isTrue);
    expect(markdown, source);

    await tester.enterText(fields.at(1), 'Following');
    await tester.pump();

    expect(markdown, '```javascript\nline();\n```\n\nFollowing\n');
  });

  testWidgets('Arrow Down exits a terminal code block', (tester) async {
    final document = parser.parse(filePath: 'code.md', source: source);

    await tester.pumpWidget(
      _app(
        BusyMarkWysiwygEditor(
          document: document.busyDocument,
          onSourceChanged: (_, _) {},
        ),
      ),
    );
    await tester.pump();

    final fields = find.byType(TextField);
    final codeField = tester.widget<TextField>(fields.first);
    codeField.focusNode!.requestFocus();
    codeField.controller!.selection = TextSelection.collapsed(
      offset: codeField.controller!.text.length,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(tester.widget<TextField>(fields.at(1)).focusNode!.hasFocus, isTrue);
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SizedBox(width: 900, height: 640, child: child)),
  );
}
