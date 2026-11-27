import 'package:busymark/src/app/localization.dart';
import 'package:busymark/src/editor/document_audio_view.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/markdown/audio_media.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _file = '/documents/audio.md';
const _atom = busyMarkInlineAudioPlaceholder;
const _audio =
    "<AuDiO controls='false' src=clip.wav data-kept='yes'>"
    '<a href="clip.wav">Download &amp; listen</a></AuDiO>';

BusyDocument _parse(String markdown) => const MarkdownParser()
    .parse(
      filePath: _file,
      source: markdown,
      mode: MarkdownMode.gfm,
      validateLocalReferences: false,
    )
    .busyDocument;

Future<void> _mount(
  WidgetTester tester,
  BusyDocument document,
  ValueChanged<String> onChanged, {
  ValueChanged<BusyAudio>? onAudioProperties,
}) async {
  final opening = Object();
  final identity = (
    opening: opening,
    identity: _file,
    path: _file,
    revision: 0,
    mediaIdentity: null,
  );
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: busyMarkLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: DocumentAudioScope(
          document: identity,
          openDocuments: {opening: identity},
          rootPath: '/documents',
          editAudio: onAudioProperties,
          child: BusyMarkWysiwygEditor(
            document: document,
            onSourceChanged: (_, markdown) => onChanged(markdown),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _replace(
  WidgetTester tester,
  Finder field,
  int start,
  int end,
  String replacement,
) async {
  await tester.showKeyboard(field);
  final controller = tester.widget<TextField>(field).controller!;
  controller.selection = TextSelection(baseOffset: start, extentOffset: end);
  await tester.pump();
  tester.testTextInput.updateEditingValue(
    TextEditingValue(
      text: controller.text.replaceRange(start, end, replacement),
      selection: TextSelection.collapsed(offset: start + replacement.length),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('an HTML wrapper does not promote a Markdown code sample to audio', () {
    final document = _parse('Example <span>`$_audio`</span>.\n');
    expect(document.blocks.first.plainText, contains(_audio));
    expect(document.blocks.first.plainText, isNot(contains(_atom)));
  });

  testWidgets('edits on both sides of an interactive inline audio atom', (
    tester,
  ) async {
    const source = 'Before $_audio after.\n';
    final document = _parse(source);
    var markdown = source;
    BusyAudio? properties;
    await _mount(
      tester,
      document,
      (value) => markdown = value,
      onAudioProperties: (value) => properties = value,
    );
    final field = find.byKey(
      ValueKey('wysiwyg-field-$_file-${document.blocks.first.id}'),
    );
    expect(
      tester.widget<TextField>(field).controller!.text,
      'Before $_atom after.',
    );
    expect(
      find.descendant(
        of: field,
        matching: find.byType(BusyMarkDocumentAudioView),
      ),
      findsOneWidget,
    );
    expect(markdown, source);

    await _replace(tester, field, 0, 6, 'Edited before');
    expect(markdown, 'Edited before $_audio after.\n');
    final after = 'Edited before $_atom '.length;
    await _replace(tester, field, after, after + 5, 'edited after');
    expect(markdown, 'Edited before $_audio edited after.\n');

    tester.widget<TextField>(field).controller!.selection = TextSelection(
      baseOffset: after,
      extentOffset: after + 'edited after'.length,
    );
    await tester.pump();
    final snapshot = tester
        .state<BusyMarkWysiwygEditorState>(find.byType(BusyMarkWysiwygEditor))
        .narrationSelection()!;
    expect(
      snapshot.documentSource.substring(
        snapshot.selectionStart,
        snapshot.selectionEnd,
      ),
      'edited after',
    );

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is Icon && widget.semanticLabel == 'Audio properties',
      ),
    );
    await tester.pumpAndSettle();
    expect(properties?.rawSource, _audio);
    expect(properties?.sourceSpan?.startOffset, 'Edited before '.length);
    expect(properties?.sourceSpan?.endOffset, 'Edited before $_audio'.length);
    expect(markdown, 'Edited before $_audio edited after.\n');
  });

  testWidgets('one edited range can retain audio within an inline wrapper', (
    tester,
  ) async {
    const source = 'Prose <bdi dir="rtl">before $_audio after</bdi>.\n';
    final document = _parse(source);
    var markdown = source;
    await _mount(tester, document, (value) => markdown = value);
    final field = find.byKey(
      ValueKey('wysiwyg-field-$_file-${document.blocks.first.id}'),
    );
    final controller = tester.widget<TextField>(field).controller!;
    final start = controller.text.indexOf('before');
    final end = controller.text.indexOf('after') + 'after'.length;
    await _replace(tester, field, start, end, 'left $_atom right');
    expect(markdown, 'Prose <bdi dir="rtl">left $_audio right</bdi>.\n');
    expect(find.byType(BusyMarkDocumentAudioView), findsOneWidget);
  });

  testWidgets('selecting the first of two adjacent players removes only it', (
    tester,
  ) async {
    const first = '<audio controls src="one.wav"></audio>';
    const second = '<audio controls src="two.wav"></audio>';
    const source = 'Before $first$second after.\n';
    final document = _parse(source);
    var markdown = source;
    await _mount(tester, document, (value) => markdown = value);
    final field = find.byKey(
      ValueKey('wysiwyg-field-$_file-${document.blocks.first.id}'),
    );
    expect(find.byType(BusyMarkDocumentAudioView), findsNWidgets(2));
    final offset = 'Before '.length;
    await _replace(tester, field, offset, offset + 1, '');
    expect(markdown, 'Before $second after.\n');
    expect(find.byType(BusyMarkDocumentAudioView), findsOneWidget);
  });

  testWidgets('another cell and table operations stay available with audio', (
    tester,
  ) async {
    const source =
        'Introduction.\n\n'
        '| Player | Prose |\n'
        '| --- | --- |\n'
        '| Before $_audio after | Original |\n';
    final document = _parse(source);
    final table = document.blocks.singleWhere(
      (block) => block.kind == BusyBlockKind.table,
    );
    final audioCell = find.byKey(ValueKey(table.children[1].children[0].id));
    final proseCell = find.byKey(ValueKey(table.children[1].children[1].id));
    var markdown = source;
    await _mount(tester, document, (value) => markdown = value);
    expect(
      find.descendant(
        of: audioCell,
        matching: find.byType(BusyMarkDocumentAudioView),
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<TextField>(audioCell).controller!.text,
      'Before $_atom after',
    );
    await _replace(tester, proseCell, 0, 'Original'.length, 'Edited');
    await _replace(tester, audioCell, 0, 'Before'.length, 'Changed');
    expect(markdown, contains('| Changed $_audio after | Edited |'));

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(proseCell));
    await tester.pump();
    await tester.tap(find.byTooltip('Row 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Insert row below'));
    await tester.pumpAndSettle();

    await mouse.moveTo(const Offset(1, 1));
    await mouse.moveTo(tester.getCenter(proseCell));
    await tester.pump();
    await tester.tap(find.byTooltip('Column 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Insert column right'));
    await tester.pumpAndSettle();
    final rows = tester.widget<Table>(find.byType(Table)).children;
    expect(rows, hasLength(3));
    expect(rows.every((row) => row.children.length == 3), isTrue);
    expect(markdown, contains('| Changed $_audio after | Edited |  |'));
  });
}
