import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/busymark_glyphs.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_commands.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_session_state.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = MarkdownParser();

  test(
    'generic block commands cannot convert tables or preserved raw blocks',
    () {
      final parsed = parser.parse(
        filePath: 'topic.md',
        source:
            '| A | B |\n| --- | --- |\n| one | two |\n\n<script>x</script>\n',
      );
      final table = parsed.busyDocument.blocks.firstWhere(
        (block) => block.kind == BusyBlockKind.table,
      );
      final raw = parsed.busyDocument.blocks.firstWhere(
        (block) => block.preserveRaw,
      );
      final controller = BusyMarkWysiwygDocumentController(
        document: parsed.busyDocument,
      );
      final original = controller.markdown;

      for (final command in BusyWysiwygBlockCommand.values) {
        expect(busyMarkWysiwygCanApplyBlockCommand(table, command), isFalse);
        expect(busyMarkWysiwygCanApplyBlockCommand(raw, command), isFalse);
        controller.applyBlockCommand(table.id, command);
        controller.applyBlockCommand(raw.id, command);
        expect(controller.markdown, original, reason: command.name);
      }
      controller.applyAdmonitionStyle(table.id, BusyAdmonitionStyle.warning);
      controller.applyAdmonitionStyle(raw.id, BusyAdmonitionStyle.warning);
      expect(controller.markdown, original);
    },
  );

  test('nested list-to-blockquote conversion preserves parent text', () {
    final document = parser
        .parse(filePath: 'topic.md', source: '- parent\n  - child\n')
        .busyDocument;
    final parent = document.blocks.single;
    expect(parent.children, isNotEmpty);
    final controller = BusyMarkWysiwygDocumentController(document: document);

    expect(
      busyMarkWysiwygCanApplyBlockCommand(
        parent,
        BusyWysiwygBlockCommand.heading1,
      ),
      isFalse,
    );
    expect(
      busyMarkWysiwygCanApplyBlockCommand(
        parent,
        BusyWysiwygBlockCommand.orderedList,
      ),
      isTrue,
    );
    controller.applyBlockCommand(parent.id, BusyWysiwygBlockCommand.blockquote);

    final quote = controller.blockById(parent.id)!;
    expect(quote.kind, BusyBlockKind.blockquote);
    expect(quote.inlines, isEmpty);
    expect(quote.children.first.kind, BusyBlockKind.paragraph);
    expect(quote.children.first.plainText, 'parent');
    expect(quote.children.last.plainText, 'child');
    expect(controller.markdown, '> parent\n>\n> - child\n');

    controller.applyBlockCommand(
      parent.id,
      BusyWysiwygBlockCommand.unorderedList,
    );
    final restoredList = controller.blockById(parent.id)!;
    expect(restoredList.plainText, 'parent');
    expect(restoredList.children.single.plainText, 'child');
    expect(controller.markdown, '- parent\n  - child\n');
  });

  test('every admonition style preserves nested list parent text', () {
    for (final style in BusyAdmonitionStyle.values) {
      final document = parser
          .parse(filePath: 'topic.md', source: '- parent\n  - child\n')
          .busyDocument;
      final parent = document.blocks.single;
      final controller = BusyMarkWysiwygDocumentController(document: document);

      controller.applyAdmonitionStyle(parent.id, style);

      final admonition = controller.blockById(parent.id)!;
      expect(admonition.kind, BusyBlockKind.blockquote, reason: style.name);
      expect(admonition.attributes['style'], style.name, reason: style.name);
      expect(admonition.children.first.plainText, 'parent', reason: style.name);
      expect(admonition.children.last.plainText, 'child', reason: style.name);
      expect(controller.markdown, contains('> parent'), reason: style.name);
      expect(controller.markdown, contains('child'), reason: style.name);
    }
  });

  test('complete clipboard snapshots reconstruct a table transactionally', () {
    final tableDocument = parser
        .parse(
          filePath: 'table.md',
          source: '| A | B |\n| --- | --- |\n| one | **two** |\n',
        )
        .busyDocument;
    final table = tableDocument.blocks.single;
    final targetDocument = parser
        .parse(filePath: 'target.md', source: 'Target\n')
        .busyDocument;
    final controller = BusyMarkWysiwygDocumentController(
      document: targetDocument,
    );
    final target = controller.document.blocks.single;
    final snapshot = busyMarkWysiwygImmutableBlockSnapshot(table);
    final result = controller.insertStyledBlocksAtSelection(
      blockId: target.id,
      selectionStart: 0,
      selectionEnd: target.plainText.length,
      blocks: [
        BusyWysiwygStyledBlock(
          kind: table.kind,
          text: table.plainText,
          ranges: const [],
          attributes: table.attributes,
          completeBlock: snapshot,
        ),
      ],
    );

    expect(result, isNotNull);
    final pasted = controller.document.blocks.first;
    expect(pasted.kind, BusyBlockKind.table);
    expect(pasted.children, hasLength(2));
    expect(pasted.children.last.children.last.plainText, 'two');
    expect(controller.markdown, contains('| one | **two** |'));
    expect(() => snapshot.children.add(table), throwsUnsupportedError);
    expect(() => snapshot.attributes['bad'] = 'value', throwsUnsupportedError);
  });

  testWidgets('same-editor cut and paste preserves complete tables', (
    tester,
  ) async {
    const source =
        'Before\n\n| A | B |\n| --- | --- |\n| one | **two** |\n\nAfter\n';
    final document = parser
        .parse(filePath: 'topic.md', source: source)
        .busyDocument;
    var markdown = source;
    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardText =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
        } else if (call.method == 'Clipboard.getData') {
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
      _app(
        BusyMarkWysiwygEditor(
          document: document,
          onSourceChanged: (_, value) => markdown = value,
        ),
      ),
    );
    await tester.pump();
    final first = tester.widget<TextField>(find.byType(TextField).first);
    first.focusNode!.requestFocus();
    await tester.pump();

    Future<void> shortcut(LogicalKeyboardKey key) async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(key);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
    }

    await shortcut(LogicalKeyboardKey.keyA);
    await shortcut(LogicalKeyboardKey.keyA);
    await shortcut(LogicalKeyboardKey.keyX);
    expect(markdown, isNot(contains('| one |')));
    await shortcut(LogicalKeyboardKey.keyV);
    await tester.pump();

    expect(markdown, contains('| A | B |'));
    expect(markdown, contains('| one | **two** |'));
    expect(markdown, contains('Before'));
    expect(markdown, contains('After'));
  });

  test('table cell edits normalize every newline form before parsing', () {
    final document = parser
        .parse(filePath: 'topic.md', source: '| A |\n| --- |\n| value |\n')
        .busyDocument;
    final controller = BusyMarkWysiwygDocumentController(document: document);
    final table = document.blocks.single;
    final cell = table.children.last.children.single;

    controller.updateTableCellText(table.id, cell.id, 'A\n\nB\r\nC\rD');

    expect(controller.blockById(cell.id)?.plainText, 'A  B C D');
    expect(controller.markdown, contains('| A  B C D |'));
  });

  test('table cell edits parse block-marker prefixes as inline text', () {
    for (final value in const ['# title', '- item', '1. item', '> quote']) {
      final document = parser
          .parse(filePath: 'topic.md', source: '| A |\n| --- |\n| value |\n')
          .busyDocument;
      final controller = BusyMarkWysiwygDocumentController(document: document);
      final table = document.blocks.single;
      final cell = table.children.last.children.single;

      controller.updateTableCellText(table.id, cell.id, value);

      expect(controller.blockById(cell.id)?.plainText, value, reason: value);
      expect(controller.markdown, contains('| $value |'), reason: value);
    }
  });

  testWidgets('table fields reject multiline input and reconcile the model', (
    tester,
  ) async {
    final document = parser
        .parse(filePath: 'topic.md', source: '| A |\n| --- |\n| value |\n')
        .busyDocument;
    final table = document.blocks.single;
    final cell = table.children.last.children.single;
    var markdown = '';
    await tester.pumpWidget(
      _app(
        BusyMarkWysiwygEditor(
          document: document,
          onSourceChanged: (_, value) => markdown = value,
        ),
      ),
    );
    await tester.pump();

    final finder = find.byKey(ValueKey(cell.id));
    await tester.enterText(finder, 'A\n\nB');
    await tester.pump();
    final field = tester.widget<TextField>(finder);

    expect(field.maxLines, 1);
    expect(field.controller?.text, 'AB');
    expect(markdown, contains('| AB |'));
  });

  testWidgets('table fields preserve block-marker-prefixed cell values', (
    tester,
  ) async {
    final document = parser
        .parse(filePath: 'topic.md', source: '| A |\n| --- |\n| value |\n')
        .busyDocument;
    final table = document.blocks.single;
    final cell = table.children.last.children.single;
    var markdown = '';
    await tester.pumpWidget(
      _app(
        BusyMarkWysiwygEditor(
          document: document,
          onSourceChanged: (_, value) => markdown = value,
        ),
      ),
    );
    await tester.pump();

    final finder = find.byKey(ValueKey(cell.id));
    for (final value in const ['# title', '- item', '1. item', '> quote']) {
      await tester.enterText(finder, value);
      await tester.pump();

      expect(
        tester.widget<TextField>(finder).controller?.text,
        value,
        reason: value,
      );
      expect(markdown, contains('| $value |'), reason: value);
    }
  });

  testWidgets('exact source ranges select repeated text and table cells', (
    tester,
  ) async {
    const source =
        'same same Case case cat scatter cat a1 a222\n\n'
        '| A | B |\n| --- | --- |\n| first | needle |\n';
    final document = parser
        .parse(filePath: 'topic.md', source: source)
        .busyDocument;
    final table = document.blocks.last;
    final needleCell = table.children.last.children.last;
    var request = 1;

    Widget editor(BusyMarkWysiwygSourceRange range) => _app(
      BusyMarkWysiwygEditor(
        document: document,
        scrollRequest: request,
        scrollToSourceRange: range,
        onSourceChanged: (_, _) {},
      ),
    );

    Future<void> expectParagraphRange(int start, int end) async {
      await tester.pumpWidget(
        editor(BusyMarkWysiwygSourceRange(startOffset: start, endOffset: end)),
      );
      await tester.pump();
      await tester.pump();
      final paragraph = tester.widget<TextField>(find.byType(TextField).first);
      expect(
        paragraph.controller?.selection,
        TextSelection(baseOffset: start, extentOffset: end),
      );
      request++;
    }

    // Repeated literal: navigate to the second occurrence.
    await expectParagraphRange(5, 9);
    // Case-sensitive result: preserve the exact uppercase occurrence.
    final uppercaseStart = source.indexOf('Case');
    await expectParagraphRange(uppercaseStart, uppercaseStart + 4);
    // Whole-word result: skip "cat" inside "scatter".
    final wholeWordStart = source.lastIndexOf('cat', source.indexOf(' a1'));
    await expectParagraphRange(wholeWordStart, wholeWordStart + 3);
    // Regex result: use the actual match length, not the pattern length.
    final regexStart = source.indexOf('a222');
    await expectParagraphRange(regexStart, regexStart + 4);

    final needleStart = source.indexOf('needle');
    await tester.pumpWidget(
      editor(
        BusyMarkWysiwygSourceRange(
          startOffset: needleStart,
          endOffset: needleStart + 'needle'.length,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    final cellField = tester.widget<TextField>(
      find.byKey(ValueKey(needleCell.id)),
    );
    expect(
      cellField.controller?.selection,
      const TextSelection(baseOffset: 0, extentOffset: 6),
    );
  });

  testWidgets('exact source navigation rebases spans after earlier edits', (
    tester,
  ) async {
    const source = 'alpha\n\nneedle\n';
    final document = parser
        .parse(filePath: 'topic.md', source: source)
        .busyDocument;
    late StateSetter rebuild;
    var markdown = source;
    var request = 0;
    BusyMarkWysiwygSourceRange? range;

    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return BusyMarkWysiwygEditor(
              document: document,
              scrollRequest: request,
              scrollToSourceRange: range,
              onSourceChanged: (_, value) => markdown = value,
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'alpha expanded');
    await tester.pump();

    final needleStart = markdown.indexOf('needle');
    rebuild(() {
      request++;
      range = BusyMarkWysiwygSourceRange(
        startOffset: needleStart,
        endOffset: needleStart + 6,
      );
    });
    await tester.pump();
    await tester.pump();

    final needle = tester.widget<TextField>(find.byType(TextField).at(1));
    expect(
      needle.controller?.selection,
      const TextSelection(baseOffset: 0, extentOffset: 6),
    );
  });

  testWidgets('source navigation expands collapsed Writerside ancestors', (
    tester,
  ) async {
    const source = '''## Details {collapsible="true"}

Hidden needle.
''';
    final document = parser
        .parse(
          filePath: 'topic.md',
          source: source,
          mode: MarkdownMode.writersideMarkdown,
          validateLocalReferences: false,
        )
        .busyDocument;
    final start = source.indexOf('needle');

    await tester.pumpWidget(
      _app(
        BusyMarkWysiwygEditor(
          document: document,
          scrollRequest: 1,
          scrollToSourceRange: BusyMarkWysiwygSourceRange(
            startOffset: start,
            endOffset: start + 6,
          ),
          onSourceChanged: (_, _) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('Hidden needle.'), findsOneWidget);
    final hiddenField = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Hidden needle.'),
    );
    expect(
      hiddenField.controller?.selection,
      const TextSelection(baseOffset: 7, extentOffset: 13),
    );
  });

  testWidgets('outline navigation expands a collapsed heading ancestor', (
    tester,
  ) async {
    const source = '''## Details {collapsible="true"}

### Hidden heading

Body.
''';
    final document = parser
        .parse(
          filePath: 'topic.md',
          source: source,
          mode: MarkdownMode.writersideMarkdown,
          validateLocalReferences: false,
        )
        .busyDocument;
    final hiddenHeading = document.blocks.firstWhere(
      (block) => block.plainText == 'Hidden heading',
    );

    await tester.pumpWidget(
      _app(
        BusyMarkWysiwygEditor(
          document: document,
          scrollRequest: 1,
          scrollToBlockId: hiddenHeading.id,
          onSourceChanged: (_, _) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('Hidden heading'), findsOneWidget);
  });

  testWidgets('table cells own shortcuts, formatting, and restored selection', (
    tester,
  ) async {
    final document = parser
        .parse(filePath: 'topic.md', source: '| A |\n| --- |\n| cell |\n')
        .busyDocument;
    final table = document.blocks.single;
    final cell = table.children.last.children.single;
    var markdown = '';
    WysiwygEditorSessionState? session;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async =>
          call.method == 'Clipboard.getData' ? {'text': 'new\nline'} : null,
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await tester.pumpWidget(
      _app(
        BusyMarkWysiwygEditor(
          document: document,
          initialSessionState: WysiwygEditorSessionState(
            activeBlockId: table.id,
            activeCellId: cell.id,
            anchorBlockId: cell.id,
            anchorOffset: 0,
            extentBlockId: cell.id,
            extentOffset: 4,
          ),
          onSessionChanged: (_, value) => session = value,
          onSourceChanged: (_, value) => markdown = value,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final finder = find.byKey(ValueKey(cell.id));
    var field = tester.widget<TextField>(finder);
    expect(
      field.controller?.selection,
      const TextSelection(baseOffset: 0, extentOffset: 4),
    );
    final blockquoteButton = tester
        .widgetList<BusyMarkHeaderIconButton>(
          find.byType(BusyMarkHeaderIconButton),
        )
        .firstWhere((button) => button.icon == BusyMarkGlyphs.blockquote);
    expect(blockquoteButton.onPressed, isNull);
    await tester.tap(find.byIcon(BusyMarkGlyphs.bold));
    await tester.pump();
    expect(markdown, contains('**cell**'));

    field = tester.widget<TextField>(finder);
    field.focusNode!.requestFocus();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(
      field.controller?.selection,
      const TextSelection(baseOffset: 0, extentOffset: 4),
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    await tester.pump();
    expect(markdown, contains('| new line |'));
    expect(session?.activeBlockId, table.id);
    expect(session?.activeCellId, cell.id);
    expect(session?.anchorBlockId, cell.id);
    expect(session?.extentBlockId, cell.id);
  });

  test('external undo groups continuous typing but not transactions', () {
    final initial = DocumentBuffer.untitled(id: 'one', name: 'one.md');
    final first = initial.edited('a', undoGroup: 'typing-1');
    final second = first.edited('ab', undoGroup: 'typing-1');
    final transaction = second.edited('ab\n', undoGroup: null);

    expect(first.editorState.undoState.undo, ['']);
    expect(second.editorState.undoState.undo, ['']);
    expect(transaction.editorState.undoState.undo, ['', 'ab']);
  });

  testWidgets('external history coalesces editor typing without local copies', (
    tester,
  ) async {
    final document = parser
        .parse(filePath: 'topic.md', source: 'a\n')
        .busyDocument;
    final key = GlobalKey();
    var buffer = DocumentBuffer.untitled(
      id: 'one',
      name: 'one.md',
      text: 'a\n',
    );
    final groups = <String?>[];

    await tester.pumpWidget(
      _app(
        BusyMarkWysiwygEditor(
          key: key,
          document: document,
          useExternalUndoHistory: true,
          onSourceChanged: (_, _) {},
          onTransactionalSourceChanged: (_, value, group) {
            groups.add(group);
            buffer = buffer.edited(value, undoGroup: group);
          },
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'ab');
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'abc');
    await tester.pump();

    expect(groups, hasLength(2));
    expect(groups.first, isNotNull);
    expect(groups.last, groups.first);
    expect(buffer.editorState.undoState.undo, ['a\n']);
    final dynamic state = tester.state(find.byType(BusyMarkWysiwygEditor));
    expect(state.debugUndoSnapshotCount, 0);
  });

  testWidgets('undo controllers are disposed when blocks disappear', (
    tester,
  ) async {
    final key = GlobalKey();
    final first = parser
        .parse(filePath: 'topic.md', source: 'One\n\nTwo\n')
        .busyDocument;
    final second = parser
        .parse(filePath: 'topic.md', source: 'One\n')
        .busyDocument;

    Widget editor(BusyDocument document) => _app(
      BusyMarkWysiwygEditor(
        key: key,
        document: document,
        onSourceChanged: (_, _) {},
      ),
    );

    await tester.pumpWidget(editor(first));
    await tester.pump();
    final dynamic state = tester.state(find.byType(BusyMarkWysiwygEditor));
    expect(state.debugUndoControllerCount, 2);

    await tester.pumpWidget(editor(second));
    await tester.pump();
    expect(state.debugUndoControllerCount, 1);
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SizedBox(width: 900, height: 640, child: child)),
  );
}
