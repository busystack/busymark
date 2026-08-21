import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/editor/document_list_marker.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_inline_controller.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/visualization/visualization_providers.dart';
import 'package:busymark/src/visualization/visualization_renderer.dart';
import 'package:busymark/src/visualization/web_render_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('inline math insertion preserves structural block kinds', () {
    const cases = <(String, String, BusyBlockKind, String)>[
      (
        '# Energy\n',
        r'$Energy$',
        BusyBlockKind.heading,
        r'# $Energy$'
            '\n',
      ),
      (
        '- Item\n',
        r'$Item$',
        BusyBlockKind.unorderedListItem,
        r'- $Item$'
            '\n',
      ),
      (
        '3. Item\n',
        r'$Item$',
        BusyBlockKind.orderedListItem,
        r'3. $Item$'
            '\n',
      ),
      (
        '- [ ] Task\n',
        r'$Task$',
        BusyBlockKind.taskListItem,
        r'- [ ] $Task$'
            '\n',
      ),
    ];

    for (final (source, edit, kind, expected) in cases) {
      final document = const MarkdownParser()
          .parse(filePath: 'math.md', source: source)
          .busyDocument;
      final controller = BusyMarkWysiwygDocumentController(document: document);

      controller.updateMathSource(document.blocks.single.id, edit);

      expect(controller.document.blocks.single.kind, kind, reason: source);
      expect(controller.markdown, expected, reason: source);
    }
  });

  test('removing final formula leaves normal editing mode', () {
    final document = const MarkdownParser()
        .parse(
          filePath: 'math.md',
          source:
              r'# Energy $E$'
              '\n',
        )
        .busyDocument;
    final controller = BusyMarkWysiwygDocumentController(document: document);

    expect(controller.blockText(document.blocks.single.id), r'Energy $E$');
    controller.updateMathSource(document.blocks.single.id, 'Energy');

    final block = controller.document.blocks.single;
    expect(block.kind, BusyBlockKind.heading);
    expect(busyMarkWysiwygBlockContainsMath(block), isFalse);
    expect(controller.blockText(block.id), 'Energy');
    expect(block.attributes, isNot(contains('wysiwygMathSource')));
  });

  test('table-cell source editing retains and removes semantic math', () {
    final document = const MarkdownParser()
        .parse(
          filePath: 'math.md',
          source:
              '| Formula |\n| --- |\n'
              r'| before $x$ after |'
              '\n',
        )
        .busyDocument;
    final controller = BusyMarkWysiwygDocumentController(document: document);
    final table = controller.document.blocks.single;
    final cell = table.children[1].children.single;

    controller.updateTableCellText(table.id, cell.id, r'before $y^2$ after');
    var edited = controller.blockById(cell.id)!;
    expect(busyMarkWysiwygBlockContainsMath(edited), isTrue);
    expect(controller.markdown, contains(r'before $y^2$ after'));

    controller.updateTableCellText(table.id, cell.id, 'plain text');
    edited = controller.blockById(cell.id)!;
    expect(busyMarkWysiwygBlockContainsMath(edited), isFalse);
    expect(controller.markdown, contains('| plain text |'));
  });

  test('math source edits cannot discard additional Markdown blocks', () {
    final document = const MarkdownParser()
        .parse(
          filePath: 'math.md',
          source:
              r'Before $x$ after.'
              '\n',
        )
        .busyDocument;
    final controller = BusyMarkWysiwygDocumentController(document: document);

    controller.updateMathSource(
      document.blocks.single.id,
      r'Before $y$ after.'
      '\n\n'
      'A second paragraph.',
    );

    expect(controller.document.blocks, hasLength(2));
    expect(controller.markdown, contains(r'Before $y$ after.'));
    expect(controller.markdown, contains('A second paragraph.'));
    expect(
      busyMarkWysiwygBlockContainsMath(controller.document.blocks.last),
      isFalse,
    );
  });

  testWidgets(
    'WYSIWYG renders math, edits exact source, and reparses without corruption',
    (tester) async {
      const original =
          r'Text before $x^2$ and text after.'
          '\n';
      final document = const MarkdownParser()
          .parse(filePath: 'math.md', source: original)
          .busyDocument;
      var markdown = original;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            webRenderHostProvider.overrideWithValue(_WysiwygMathHost()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox(
                width: 900,
                height: 600,
                child: BusyMarkWysiwygEditor(
                  document: document,
                  onSourceChanged: (_, source) => markdown = source,
                ),
              ),
            ),
          ),
        ),
      );
      await _pumpMath(tester);

      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      await tester.tap(
        find.byKey(
          ValueKey('wysiwyg-rendered-math-${document.blocks.single.id}'),
        ),
      );
      await tester.pump();
      final sourceField = tester.widget<TextField>(find.byType(TextField));
      expect(sourceField.controller?.text, original.trimRight());

      const edited = r'Changed before $\frac{a}{b}$ and after.';
      await tester.enterText(find.byType(TextField), edited);
      await tester.pump();
      expect(markdown, '$edited\n');

      await _sendUndo(tester);
      expect(markdown, original);
      await _sendRedo(tester);
      expect(markdown, '$edited\n');

      tester.widget<TextField>(find.byType(TextField)).focusNode?.unfocus();
      await _pumpMath(tester);
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.textContaining(r'\frac{a}{b}'), findsNothing);

      await tester.tap(
        find.byKey(
          ValueKey('wysiwyg-rendered-math-${document.blocks.single.id}'),
        ),
      );
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        edited,
      );
    },
  );

  testWidgets('WYSIWYG toolbar inserts inline and display math source', (
    tester,
  ) async {
    final document = const MarkdownParser()
        .parse(filePath: 'math.md', source: 'Velocity\n')
        .busyDocument;
    var markdown = document.source;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          webRenderHostProvider.overrideWithValue(_WysiwygMathHost()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 1100,
              height: 600,
              child: BusyMarkWysiwygEditor(
                document: document,
                onSourceChanged: (_, source) => markdown = source,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final controller = tester
        .widget<TextField>(find.byType(TextField))
        .controller!;
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 8);

    await tester.ensureVisible(find.byTooltip('Inline math'));
    await tester.tap(find.byTooltip('Inline math'));
    await tester.pump();
    expect(
      markdown,
      r'$Velocity$'
      '\n',
    );

    await tester.ensureVisible(find.byTooltip('Display math'));
    await tester.tap(find.byTooltip('Display math'));
    await tester.pump();
    expect(markdown, contains('\$\$\nx\n\$\$'));
  });

  testWidgets('rendered and focused math list items keep one marker', (
    tester,
  ) async {
    final document = const MarkdownParser()
        .parse(
          filePath: 'math.md',
          source:
              r'- Item $x$'
              '\n',
        )
        .busyDocument;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          webRenderHostProvider.overrideWithValue(_WysiwygMathHost()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BusyMarkWysiwygEditor(
              document: document,
              onSourceChanged: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await _pumpMath(tester);
    expect(find.byType(BusyMarkDocumentListMarker), findsOneWidget);

    await tester.tap(
      find.byKey(
        ValueKey('wysiwyg-rendered-math-${document.blocks.single.id}'),
      ),
    );
    await tester.pump();

    expect(find.byType(BusyMarkDocumentListMarker), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      r'Item $x$',
    );
  });

  testWidgets('table math renders unfocused and edits delimiter source', (
    tester,
  ) async {
    final document = const MarkdownParser()
        .parse(
          filePath: 'math.md',
          source:
              '| Formula |\n| --- |\n'
              r'| before $x$ after |'
              '\n',
        )
        .busyDocument;
    final cell = document.blocks.single.children[1].children.single;
    var markdown = document.source!;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          webRenderHostProvider.overrideWithValue(_WysiwygMathHost()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BusyMarkWysiwygEditor(
              document: document,
              onSourceChanged: (_, source) => markdown = source,
            ),
          ),
        ),
      ),
    );
    await _pumpMath(tester);
    final rendered = find.byKey(ValueKey('wysiwyg-rendered-math-${cell.id}'));
    expect(rendered, findsOneWidget);

    await tester.tap(rendered);
    await tester.pump();
    final field = find.byKey(ValueKey(cell.id));
    expect(
      tester.widget<TextField>(field).controller?.text,
      r'before $x$ after',
    );

    await tester.enterText(field, r'before $y^2$ after');
    await tester.pump();
    expect(markdown, contains(r'| before $y^2$ after |'));
  });
}

Future<void> _sendUndo(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();
}

Future<void> _sendRedo(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();
}

Future<void> _pumpMath(WidgetTester tester) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    await tester.pump(const Duration(milliseconds: 10));
    if (find.byType(SvgPicture).evaluate().isNotEmpty) return;
  }
}

class _WysiwygMathHost implements WebRenderHost {
  @override
  Future<Map<Object?, Object?>> renderMathBatch({
    required List<Map<String, Object?>> expressions,
    required VisualizationCancellationToken cancellationToken,
  }) async {
    cancellationToken.throwIfCancelled();
    return {
      'results': [
        for (final item in expressions)
          {
            'id': item['id'],
            'svg': '''<svg xmlns="http://www.w3.org/2000/svg"
              viewBox="0 -10 20 14" style="vertical-align:-0.25ex">
              <defs><path id="glyph" d="M0 0L10 10"/></defs>
              <use href="#glyph" fill="currentColor"/>
            </svg>''',
            'width': 20,
            'height': 14,
            'depth': 2,
          },
      ],
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
