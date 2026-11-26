import 'dart:io';

import 'package:busymark/src/app/localization.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/busymark_dialogs.dart';
import 'package:busymark/src/editor/document_list_marker.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/markdown/preview_model.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/document_history_harness.dart';

void main() {
  const parser = MarkdownParser();

  test('raw HTML preserves inherited and overridden block directions', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '''
<section dir="RTL">
  <p>مرحبا</p>
  <p dir="ltr">BusyMark</p>
  <table>
    <tbody dir="rtl"><tr><td>خلية</td><td dir="ltr">Cell</td></tr></tbody>
  </table>
</section>
''',
    );

    final htmlBlock = parsed.busyDocument.blocks.single;
    expect(htmlBlock.kind, BusyBlockKind.htmlBlock);
    final arabicParagraph = htmlBlock.children.first;
    final englishParagraph = htmlBlock.children[1];
    final table = htmlBlock.children[2];
    final row = table.children.single;

    expect(arabicParagraph.attributes['dir'], 'rtl');
    expect(englishParagraph.attributes['dir'], 'ltr');
    expect(row.attributes['dir'], 'rtl');
    expect(row.children.first.attributes['dir'], 'rtl');
    expect(row.children.last.attributes['dir'], 'ltr');
  });

  test('preview model retains HTML direction for code and quotes', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '''
<section dir="rtl">
  <blockquote><p>اقتباس</p></blockquote>
  <pre dir="ltr"><code>const value = 1;</code></pre>
</section>
''',
    );

    final blocks = const BusyMarkPreviewBuilder().buildBlocks(
      parsed.busyDocument,
    );
    final flattened = _flattenPreviewBlocks(blocks);
    final quote = flattened.singleWhere(
      (block) => block.kind == PreviewBlockKind.quote,
    );
    final code = flattened.singleWhere(
      (block) => block.kind == PreviewBlockKind.code,
    );

    expect(quote.attributes['dir'], 'rtl');
    expect(code.attributes['dir'], 'ltr');
  });

  testWidgets('rendered HTML honors rtl, ltr, and auto directions', (
    tester,
  ) async {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '''
<section dir="rtl">
  <p>مرحبا</p>
  <p dir="ltr">BusyMark</p>
  <p dir="auto">فارسی</p>
</section>
''',
    );

    await _pumpEditor(tester, parsed.busyDocument);

    expect(
      Directionality.of(tester.element(find.text('مرحبا'))),
      TextDirection.rtl,
    );
    expect(
      Directionality.of(tester.element(find.text('BusyMark'))),
      TextDirection.ltr,
    );
    final autoText = tester.widget<Text>(find.text('فارسی'));
    expect(autoText.textDirection, TextDirection.rtl);
  });

  testWidgets('raw HTML list text and markers render in DOM order', (
    tester,
  ) async {
    final document = parser
        .parse(
          filePath: 'topic.md',
          source:
              '<ul dir="auto"><li>Before<ul><li>Nested</li></ul>After</li></ul>'
              '\n\n<ol type="A" reversed start="5"><li>Fifth</li>'
              '<li value="2">Second</li><li>First</li></ol>',
        )
        .busyDocument;
    final preview = const BusyMarkPreviewBuilder().buildBlocks(document);
    expect(preview.first.children.single.children.map((b) => b.text), [
      'Nested',
      'After',
    ]);
    expect(preview.last.children.map((b) => b.attributes['marker']), [
      'E.',
      'B.',
      'A.',
    ]);
    await _pumpEditor(tester, document);
    final before = tester.getTopLeft(find.text('Before')).dy;
    final nested = tester.getTopLeft(find.text('Nested')).dy;
    final after = tester.getTopLeft(find.text('After')).dy;
    expect(before, lessThan(nested));
    expect(nested, lessThan(after));
    for (final marker in ['E.', 'B.', 'A.']) {
      expect(find.text(marker), findsOneWidget);
    }
  });

  testWidgets('raw HTML table spans keep visible cell associations', (
    tester,
  ) async {
    final document = parser
        .parse(
          filePath: 'topic.md',
          source:
              '<table><tr><th colspan="2">Both</th></tr>'
              '<tr><td rowspan="2">A</td><td>B</td></tr>'
              '<tr><td>C</td></tr></table>',
        )
        .busyDocument;
    await _pumpEditor(tester, document);
    final both = tester.getRect(find.text('Both'));
    final a = tester.getRect(find.text('A'));
    final b = tester.getRect(find.text('B'));
    final c = tester.getRect(find.text('C'));
    expect(b.left, c.left);
    expect(a.left, lessThan(c.left));
    expect(b.top, lessThan(c.top));
    expect(both.width, greaterThan(b.width));
  });

  testWidgets('neutral auto and isolated inline scope override inherited RTL', (
    tester,
  ) async {
    final document = parser
        .parse(
          filePath: 'topic.md',
          source:
              '<div dir="rtl"><p dir="auto">123</p>'
              '<p><span dir="ltr">ABC !</span> אבג</p></div>',
        )
        .busyDocument;
    await _pumpEditor(tester, document);
    expect(
      tester.widget<Text>(find.text('123')).textDirection,
      TextDirection.ltr,
    );
    final inline = tester.widget<Text>(find.text('\u2066ABC !\u2069 אבג'));
    expect(inline.textDirection, TextDirection.rtl);
  });

  testWidgets('ordinary editable paragraph paints a bidi override', (
    tester,
  ) async {
    const source =
        'Before <bdo dir="rtl">ABC</bdo> <span dir="rtl">ABC !</span> '
        '<bdi>אבג !</bdi> after.';
    var edited = source;
    String? copied;
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });
    final document = parser
        .parse(filePath: 'topic.md', mode: MarkdownMode.gfm, source: source)
        .busyDocument;
    expect(document.blocks.single.kind, BusyBlockKind.paragraph);
    await _pumpEditor(
      tester,
      document,
      onSourceChanged: (value) => edited = value,
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    final controller = field.controller!;
    final widget = tester.state<EditableTextState>(find.byType(EditableText));
    final offset = controller.text.indexOf('ABC');
    double left(int index) => widget.renderEditable
        .getBoxesForSelection(
          TextSelection(baseOffset: index, extentOffset: index + 1),
        )
        .single
        .left;
    expect(left(offset), greaterThan(left(offset + 2)));
    final isolated = controller.text.indexOf('ABC !');
    expect(left(isolated), lessThan(left(isolated + 2)));
    expect(left(isolated + 4), lessThan(left(isolated)));
    final auto = controller.text.indexOf('אבג !');
    expect(left(auto), greaterThan(left(auto + 4)));
    field.focusNode!.requestFocus();
    controller.selection = TextSelection.collapsed(offset: offset + 1);
    await tester.pump();
    await _pressEditorShortcut(
      tester,
      LogicalKeyboardKey.arrowLeft,
      shift: true,
    );
    expect(controller.selection.end - controller.selection.start, 1);
    controller.selection = TextSelection(
      baseOffset: offset,
      extentOffset: offset + 3,
    );
    await _pressEditorShortcut(tester, LogicalKeyboardKey.keyC, control: true);
    expect(copied, 'ABC');

    controller.selection = TextSelection(
      baseOffset: offset + 1,
      extentOffset: offset + 2,
    );
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: controller.text.replaceRange(offset + 1, offset + 2, 'YZ'),
        selection: TextSelection.collapsed(offset: offset + 3),
      ),
    );
    await tester.pumpAndSettle();
    expect(edited, contains('<bdo dir="rtl">AYZC</bdo>'));
    expect(edited, isNot(contains(RegExp(r'[\u202c-\u202e\u2066-\u2069]'))));
    expect(controller.selection.extentOffset, offset + 3);
    final reopened = parser.parse(
      filePath: 'topic.md',
      mode: MarkdownMode.gfm,
      source: edited,
    );
    expect(
      reopened.busyDocument.blocks.single.plainText,
      'Before AYZC ABC ! אבג ! after.',
    );
    await _pumpEditor(tester, reopened.busyDocument);
    expect(left(offset), greaterThan(left(offset + 3)));

    final reopenedField = tester.widget<TextField>(find.byType(TextField));
    final reopenedController = reopenedField.controller!;
    // The caret sits beyond the invisible closing controls. A physical
    // Backspace must also remove the preceding authored grapheme.
    reopenedField.focusNode!.requestFocus();
    reopenedController.selection = TextSelection.collapsed(offset: offset + 6);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();
    expect(reopenedController.text, contains('AYZ\u202c\u2069'));
    expect(reopenedController.text, isNot(contains('AYZC')));
  });

  testWidgets('editable Markdown table cell retains inline direction', (
    tester,
  ) async {
    const source = '| Value |\n| --- |\n| <bdo dir="rtl">ABC</bdo> |\n';
    final directory = Directory.systemTemp.createTempSync(
      'busymark-directed-cell-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/table.md')..writeAsStringSync(source);
    BusyDocument parse(String text) => parser
        .parse(filePath: file.path, mode: MarkdownMode.gfm, source: text)
        .busyDocument;
    String? copied;
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    var edited = source;
    await _pumpEditor(
      tester,
      parse(source),
      onSourceChanged: (value) => edited = value,
    );
    final field = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          (widget.controller?.text.contains('ABC') ?? false),
    );
    final state = tester.state<EditableTextState>(
      find.descendant(of: field, matching: find.byType(EditableText)),
    );
    double left(int offset) => state.renderEditable
        .getBoxesForSelection(
          TextSelection(baseOffset: offset, extentOffset: offset + 1),
        )
        .single
        .left;
    final controller = state.widget.controller;
    final offset = controller.text.indexOf('ABC');
    expect(left(offset), greaterThan(left(offset + 2)));

    await tester.tapAt(
      state.renderEditable.localToGlobal(
        state.renderEditable
            .getLocalRectForCaret(TextPosition(offset: offset + 1))
            .center,
      ),
    );
    await tester.pump();
    expect(controller.selection.extentOffset, offset + 1);
    await _pressEditorShortcut(
      tester,
      LogicalKeyboardKey.arrowRight,
      shift: true,
    );
    expect(controller.selection.end - controller.selection.start, 1);

    await _pressEditorShortcut(tester, LogicalKeyboardKey.keyA, control: true);
    await _pressEditorShortcut(tester, LogicalKeyboardKey.keyC, control: true);
    expect(copied, 'ABC');
    controller.selection = TextSelection(
      baseOffset: offset + 1,
      extentOffset: offset + 2,
    );
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: controller.text.replaceRange(offset + 1, offset + 2, 'YZ'),
        selection: TextSelection.collapsed(offset: offset + 3),
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.selection.extentOffset, offset + 3);
    expect(edited, contains('<bdo dir="rtl">AYZC</bdo>'));
    expect(edited, isNot(contains(RegExp(r'[\u202c-\u202e\u2066-\u2069]'))));

    final reopened = await tester.runAsync(() async {
      final writer = await DocumentHistoryHarness.create(path: file.path);
      try {
        writer.controller.updateActiveText(edited);
        expect(await writer.controller.saveActive(), isTrue);
      } finally {
        writer.dispose();
      }
      final reader = await DocumentHistoryHarness.create(path: file.path);
      try {
        return reader.buffer.text;
      } finally {
        reader.dispose();
      }
    });
    expect(reopened, edited);
    await _pumpEditor(tester, parse(reopened!));
    final reopenedState = tester.state<EditableTextState>(
      find.descendant(
        of: find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              (widget.controller?.text.contains('AYZC') ?? false),
        ),
        matching: find.byType(EditableText),
      ),
    );
    final boxes = [offset, offset + 3]
        .map(
          (index) => reopenedState.renderEditable
              .getBoxesForSelection(
                TextSelection(baseOffset: index, extentOffset: index + 1),
              )
              .single
              .left,
        )
        .toList();
    expect(boxes.first, greaterThan(boxes.last));
  });

  testWidgets('links retain lists and headings in rendered HTML table cells', (
    tester,
  ) async {
    const url = 'https://example.test/items';
    final document = parser
        .parse(
          filePath: 'topic.md',
          mode: MarkdownMode.gfm,
          source:
              '<a href="$url" dir="rtl">\n<p>Linked flow !</p>\n'
              '<p dir="ltr">Flow override !</p>\n</a>\n\n'
              '<table><tr><th>Items</th></tr>'
              '<tr><td><a href="$url"><ul><li>One</li><li>Two</li></ul></a></td></tr>'
              '<tr><td><a href="$url" dir="rtl"><h3>Heading</h3>'
              '<p dir="ltr">Cell override !</p></a></td></tr></table>',
        )
        .busyDocument;
    final table = document.blocks.last.children.single;
    final cells = table.children
        .skip(1)
        .map((row) => row.children.single)
        .toList();
    expect(cells.first.children.map((b) => b.kind), [
      BusyBlockKind.unorderedListItem,
      BusyBlockKind.unorderedListItem,
    ]);
    final cellLink = cells.last.children.single;
    expect(cellLink.children.first.kind, BusyBlockKind.heading);
    expect(
      [
        ...cells.first.children,
        ...cellLink.children,
      ].map((b) => b.inlines.single.destination),
      everyElement(url),
    );
    await _pumpEditor(tester, document);
    for (final (label, direction) in [
      ('Heading', TextDirection.rtl),
      ('Cell override !', TextDirection.ltr),
      ('Linked flow !', TextDirection.rtl),
      ('Flow override !', TextDirection.ltr),
    ]) {
      expect(
        tester.widget<Text>(find.text(label)).textDirection,
        direction,
        reason: label,
      );
    }
    expect(find.text('One'), findsOneWidget);
    expect(find.text('Two'), findsOneWidget);
    final markers = tester.widgetList<BusyMarkDocumentListMarker>(
      find.byType(BusyMarkDocumentListMarker),
    );
    expect(markers, hasLength(2));
    expect(
      markers.every((marker) => !marker.ordered && !marker.hidden),
      isTrue,
    );
    final heading = tester.widget<Text>(find.text('Heading'));
    final label = tester.widget<Text>(find.text('One'));
    expect(
      (heading.textSpan as TextSpan).style!.fontSize,
      greaterThan((label.textSpan as TextSpan).style!.fontSize!),
    );
  });

  testWidgets('raw list marker shares the attributed first paragraph row', (
    tester,
  ) async {
    final document = parser
        .parse(
          filePath: 'topic.md',
          source:
              '<ol start="5"><li><p dir="rtl" title="Kept">First paragraph</p>'
              '<p>Second paragraph</p></li></ol>',
        )
        .busyDocument;
    await _pumpEditor(tester, document);
    final marker = tester.getRect(find.text('5.'));
    final caption = tester.getRect(find.text('First paragraph'));
    expect(caption.top, closeTo(marker.top, 3));
    expect(
      tester.widget<Text>(find.text('First paragraph')).textDirection,
      TextDirection.rtl,
    );
    expect(
      tester.getTopLeft(find.text('Second paragraph')).dy,
      greaterThanOrEqualTo(caption.bottom),
    );
  });

  testWidgets('nested WYSIWYG blocks indent from the RTL start edge', (
    tester,
  ) async {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '- الأصل\n  - الفرع\n',
    );

    await _pumpEditor(
      tester,
      parsed.busyDocument,
      locale: const Locale('ar'),
      textDirection: TextDirection.rtl,
    );

    final parentRect = tester.getRect(find.byType(TextField).at(0));
    final childRect = tester.getRect(find.byType(TextField).at(1));
    expect(childRect.right, lessThan(parentRect.right));
  });

  testWidgets('English prose stays LTR in a Persian RTL UI and navigates LTR', (
    tester,
  ) async {
    const firstText = 'First paragraph';
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '$firstText\n\nSecond paragraph\n',
    );
    await _pumpEditor(
      tester,
      parsed.busyDocument,
      locale: const Locale('fa'),
      textDirection: TextDirection.rtl,
    );

    TextField fieldAt(int index) =>
        tester.widget<TextField>(find.byType(TextField).at(index));
    expect(fieldAt(0).textDirection, TextDirection.ltr);

    fieldAt(0).focusNode!.requestFocus();
    fieldAt(0).controller!.selection = const TextSelection.collapsed(
      offset: firstText.length,
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(fieldAt(1).focusNode!.hasFocus, isTrue);
    expect(fieldAt(1).controller!.selection.extentOffset, 0);
  });

  testWidgets('Arabic prose stays RTL in an English UI and navigates RTL', (
    tester,
  ) async {
    const firstText = 'الفقرة الأولى';
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '$firstText\n\nالفقرة الثانية\n',
    );
    await _pumpEditor(
      tester,
      parsed.busyDocument,
      locale: const Locale('en'),
      textDirection: TextDirection.ltr,
    );

    TextField fieldAt(int index) =>
        tester.widget<TextField>(find.byType(TextField).at(index));
    expect(fieldAt(0).textDirection, TextDirection.rtl);

    fieldAt(0).focusNode!.requestFocus();
    fieldAt(0).controller!.selection = const TextSelection.collapsed(
      offset: firstText.length,
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();

    expect(fieldAt(1).focusNode!.hasFocus, isTrue);
    expect(fieldAt(1).controller!.selection.extentOffset, 0);
  });

  testWidgets('raw Writerside technical blocks stay LTR with Arabic content', (
    tester,
  ) async {
    final parsed = parser.parse(
      filePath: 'topic.topic',
      source: '<chapter>محتوى تقني</chapter>\n',
      mode: MarkdownMode.writersideMarkdown,
    );
    expect(
      parsed.busyDocument.blocks.single.kind,
      BusyBlockKind.writersideRawXml,
    );

    await _pumpEditor(
      tester,
      parsed.busyDocument,
      locale: const Locale('fa'),
      textDirection: TextDirection.rtl,
    );

    final rawField = tester.widget<SelectableText>(find.byType(SelectableText));
    expect(rawField.textDirection, TextDirection.ltr);
  });

  testWidgets('rendered Arabic HTML without dir follows its content', (
    tester,
  ) async {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '<p>مرحبا بدون اتجاه</p>\n',
    );
    await _pumpEditor(
      tester,
      parsed.busyDocument,
      locale: const Locale('en'),
      textDirection: TextDirection.ltr,
    );

    expect(
      Directionality.of(tester.element(find.text('مرحبا بدون اتجاه'))),
      TextDirection.rtl,
    );
  });

  testWidgets('WYSIWYG technical dialog inputs stay LTR in an RTL UI', (
    tester,
  ) async {
    final l10n = lookupAppLocalizations(const Locale('ar'));
    final parsed = parser.parse(filePath: 'topic.md', source: 'مرحبا\n');
    await _pumpEditor(
      tester,
      parsed.busyDocument,
      locale: const Locale('ar'),
      textDirection: TextDirection.rtl,
    );

    final htmlButton = find.byTooltip(l10n.htmlBlock);
    await tester.ensureVisible(htmlButton);
    await tester.tap(htmlButton);
    await tester.pumpAndSettle();
    final htmlField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const ValueKey('wysiwyg-html-source-field')),
        matching: find.byType(TextField),
      ),
    );
    expect(htmlField.textDirection, TextDirection.ltr);
    expect(
      htmlField.style?.fontFamilyFallback,
      BusyMarkTypography.monoFontFamilyFallback,
    );
    Navigator.of(
      tester.element(find.byKey(const ValueKey('wysiwyg-html-source-field'))),
    ).pop();
    await tester.pumpAndSettle();

    await _pressEditorShortcut(
      tester,
      LogicalKeyboardKey.keyI,
      control: true,
      shift: true,
    );
    final imageFieldFinder = find.descendant(
      of: find.byKey(BusyMarkImageDialogKeys.source),
      matching: find.byType(EditableText),
    );
    final imageField = tester.widget<EditableText>(imageFieldFinder);
    expect(imageField.textDirection, TextDirection.ltr);
    expect(
      imageField.style.fontFamilyFallback,
      BusyMarkTypography.monoFontFamilyFallback,
    );
    expect(
      tester
          .widget<ElevatedButton>(find.byKey(BusyMarkImageDialogKeys.submit))
          .onPressed,
      isNull,
    );
    await tester.enterText(imageFieldFinder, 'images/example.png');
    await tester.pump();
    expect(
      tester
          .widget<ElevatedButton>(find.byKey(BusyMarkImageDialogKeys.submit))
          .onPressed,
      isNotNull,
    );
    final altFieldFinder = find.descendant(
      of: find.byKey(BusyMarkImageDialogKeys.alt),
      matching: find.byType(EditableText),
    );
    final altField = tester.widget<EditableText>(altFieldFinder);
    expect(altField.textDirection, isNull);
    expect(
      Directionality.of(tester.element(altFieldFinder)),
      TextDirection.rtl,
    );
    Navigator.of(
      tester.element(find.byKey(BusyMarkImageDialogKeys.source)),
    ).pop();
    await tester.pumpAndSettle();

    await _pressEditorShortcut(
      tester,
      LogicalKeyboardKey.keyK,
      control: true,
      shift: true,
    );
    await _pressEditorShortcut(
      tester,
      LogicalKeyboardKey.keyK,
      control: true,
      shift: true,
    );
    final languageField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const ValueKey('wysiwyg-code-language-field')),
        matching: find.byType(TextField),
      ),
    );
    expect(find.byType(BusyMarkModalEditorSurface), findsOneWidget);
    expect(find.byType(BusyMarkModalEditorScaffold), findsOneWidget);
    expect(find.byType(BusyMarkEditorHeader), findsOneWidget);
    expect(find.byType(BusyMarkGroupedList), findsOneWidget);
    expect(find.byType(BusyMarkGroupedTextEntry), findsOneWidget);
    expect(find.byType(BusyMarkDialogShell), findsNothing);
    expect(find.byType(BusyMarkDialogButton), findsNothing);
    expect(languageField.textDirection, TextDirection.ltr);
    expect(languageField.decoration?.hintText, isNull);
    Navigator.of(
      tester.element(find.byKey(const ValueKey('wysiwyg-code-language-field'))),
    ).pop();
    await tester.pumpAndSettle();

    final editorField = tester.widget<TextField>(find.byType(TextField).first);
    editorField.focusNode!.requestFocus();
    editorField.controller!.selection = TextSelection(
      baseOffset: 0,
      extentOffset: editorField.controller!.text.length,
    );
    await tester.pump();
    await _pressEditorShortcut(tester, LogicalKeyboardKey.keyK, control: true);
    final linkField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const ValueKey('wysiwyg-link-destination-field')),
        matching: find.byType(TextField),
      ),
    );
    expect(linkField.textDirection, TextDirection.ltr);
  });

  testWidgets('RTL horizontal arrows cross paragraph boundaries visually', (
    tester,
  ) async {
    const firstText = 'الأول';
    const secondText = 'الثاني';
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '$firstText\n\n$secondText\n',
    );

    await _pumpEditor(
      tester,
      parsed.busyDocument,
      textDirection: TextDirection.rtl,
    );

    TextField fieldAt(int index) =>
        tester.widget<TextField>(find.byType(TextField).at(index));

    fieldAt(0).focusNode!.requestFocus();
    fieldAt(0).controller!.selection = const TextSelection.collapsed(
      offset: firstText.length,
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();

    expect(fieldAt(1).focusNode!.hasFocus, isTrue);
    expect(fieldAt(1).controller!.selection.extentOffset, 0);

    fieldAt(1).controller!.selection = const TextSelection.collapsed(offset: 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(fieldAt(0).focusNode!.hasFocus, isTrue);
    expect(fieldAt(0).controller!.selection.extentOffset, firstText.length);

    await _pressEditorShortcut(
      tester,
      LogicalKeyboardKey.arrowLeft,
      control: true,
    );
    expect(fieldAt(1).focusNode!.hasFocus, isTrue);
    expect(fieldAt(1).controller!.selection.extentOffset, 0);

    await _pressEditorShortcut(
      tester,
      LogicalKeyboardKey.arrowRight,
      control: true,
    );
    expect(fieldAt(0).focusNode!.hasFocus, isTrue);
    expect(fieldAt(0).controller!.selection.extentOffset, firstText.length);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();

    expect(fieldAt(1).focusNode!.hasFocus, isTrue);
    expect(fieldAt(1).controller!.selection.extentOffset, 0);
  });

  testWidgets('RTL Ctrl+Shift+Arrow extends word selection across paragraphs', (
    tester,
  ) async {
    const firstText = 'الفقرة الأولى';
    const secondText = 'الفقرة الثانية';
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '$firstText\n\n$secondText\n',
    );

    await _pumpEditor(
      tester,
      parsed.busyDocument,
      textDirection: TextDirection.rtl,
    );

    TextField fieldAt(int index) =>
        tester.widget<TextField>(find.byType(TextField).at(index));

    fieldAt(0).controller!.selection = const TextSelection.collapsed(
      offset: firstText.length,
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();

    expect(fieldAt(1).focusNode!.hasFocus, isTrue);
    expect(fieldAt(1).controller!.selection.extentOffset, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(fieldAt(1).controller!.selection.extentOffset, greaterThan(0));
  });

  testWidgets('code blocks stay LTR and use LTR boundary arrows in RTL UI', (
    tester,
  ) async {
    const code = 'print("hello");';
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '```dart\n$code\n```\n\nمرحبا\n',
    );
    await _pumpEditor(
      tester,
      parsed.busyDocument,
      textDirection: TextDirection.rtl,
    );

    TextField fieldAt(int index) =>
        tester.widget<TextField>(find.byType(TextField).at(index));

    expect(fieldAt(0).textDirection, TextDirection.ltr);
    expect(fieldAt(1).textDirection, TextDirection.rtl);

    fieldAt(0).focusNode!.requestFocus();
    fieldAt(0).controller!.selection = const TextSelection.collapsed(
      offset: code.length,
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(fieldAt(1).focusNode!.hasFocus, isTrue);
    expect(fieldAt(1).controller!.selection.extentOffset, 0);
  });

  testWidgets('rendered HTML pre is LTR unless dir overrides it', (
    tester,
  ) async {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '''
<pre><code>const value = 1;</code></pre>

<pre dir="rtl"><code>مقدار = ۱</code></pre>
''',
    );
    await _pumpEditor(
      tester,
      parsed.busyDocument,
      textDirection: TextDirection.rtl,
    );

    expect(
      Directionality.of(tester.element(find.text('const value = 1;'))),
      TextDirection.ltr,
    );
    expect(
      Directionality.of(tester.element(find.text('مقدار = ۱'))),
      TextDirection.rtl,
    );
  });

  testWidgets('RTL prefix hit testing maps the text start at the right edge', (
    tester,
  ) async {
    const firstText = 'الأول';
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '1. $firstText\n2. الثاني\n',
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

    await _pumpEditor(
      tester,
      parsed.busyDocument,
      textDirection: TextDirection.rtl,
    );

    final fields = find.byType(TextField);
    final firstField = tester.widget<TextField>(fields.at(0));
    firstField.focusNode!.requestFocus();
    firstField.controller!.selection = const TextSelection.collapsed(offset: 0);
    await tester.pump();

    final secondRect = tester.getRect(fields.at(1));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tapAt(secondRect.centerRight - const Offset(1, 0));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(copiedText, '1. $firstText');
  });
}

List<PreviewBlock> _flattenPreviewBlocks(List<PreviewBlock> blocks) {
  return [
    for (final block in blocks) ...[
      block,
      ..._flattenPreviewBlocks(block.children),
    ],
  ];
}

Future<void> _pumpEditor(
  WidgetTester tester,
  BusyDocument document, {
  Locale? locale,
  TextDirection textDirection = TextDirection.ltr,
  ValueChanged<String>? onSourceChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: busyMarkLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Directionality(
        textDirection: textDirection,
        child: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: document,
              onSourceChanged: (_, source) => onSourceChanged?.call(source),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pressEditorShortcut(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool control = false,
  bool alt = false,
  bool shift = false,
}) async {
  if (control) {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  }
  if (alt) {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
  }
  if (shift) {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  }
  await tester.sendKeyDownEvent(key);
  await tester.sendKeyUpEvent(key);
  if (shift) {
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  }
  if (alt) {
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
  }
  if (control) {
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  }
  await tester.pumpAndSettle();
}
