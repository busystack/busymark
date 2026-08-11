import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/busymark_dialogs.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/markdown/preview_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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
    final parsed = parser.parse(filePath: 'topic.md', source: 'مرحبا\n');
    await _pumpEditor(
      tester,
      parsed.busyDocument,
      locale: const Locale('ar'),
      textDirection: TextDirection.rtl,
    );

    await _pressEditorShortcut(
      tester,
      LogicalKeyboardKey.keyH,
      control: true,
      alt: true,
    );
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
      alt: true,
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
      LogicalKeyboardKey.keyG,
      control: true,
      alt: true,
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
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Directionality(
        textDirection: textDirection,
        child: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: document,
              onSourceChanged: (_, _) {},
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
}) async {
  if (control) {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  }
  if (alt) {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
  }
  await tester.sendKeyDownEvent(key);
  await tester.sendKeyUpEvent(key);
  if (alt) {
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
  }
  if (control) {
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  }
  await tester.pumpAndSettle();
}
