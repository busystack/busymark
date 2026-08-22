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

  test('math source edits preserve nested list children', () {
    const sources = [
      '- Parent \$p\$\n  - Child \$x\$\n',
      '1. Parent \$p\$\n   1. Child \$x\$\n',
      '- [ ] Parent \$p\$\n  - [x] Child \$x\$\n',
    ];

    for (final source in sources) {
      final document = const MarkdownParser()
          .parse(filePath: 'math.md', source: source)
          .busyDocument;
      final parent = document.blocks.single;
      final child = parent.children.single;
      final controller = BusyMarkWysiwygDocumentController(document: document);

      expect(busyMarkWysiwygBlockContainsMath(parent), isTrue, reason: source);
      controller.updateMathSource(parent.id, r'Changed $q$');

      final edited = controller.blockById(parent.id)!;
      expect(edited.children, hasLength(1), reason: source);
      expect(edited.children.single.id, child.id, reason: source);
      expect(edited.children.single.plainText, child.plainText, reason: source);
      expect(controller.markdown, contains(r'Child $x$'), reason: source);
    }
  });

  test('descendant math does not put a plain list parent in source mode', () {
    const sources = [
      '- Parent\n  - Child \$x\$\n',
      '1. Parent\n   1. Child \$x\$\n',
      '- [ ] Parent\n  - [x] Child \$x\$\n',
    ];

    for (final source in sources) {
      final document = const MarkdownParser()
          .parse(filePath: 'math.md', source: source)
          .busyDocument;
      final parent = document.blocks.single;
      final child = parent.children.single;
      final controller = BusyMarkWysiwygDocumentController(document: document);

      expect(busyMarkWysiwygBlockContainsMath(parent), isFalse, reason: source);
      expect(
        busyMarkWysiwygBlockDescendantsContainMath(parent),
        isTrue,
        reason: source,
      );
      expect(controller.blockText(parent.id), 'Parent', reason: source);
      controller.updateBlockText(parent.id, 'Changed parent');

      final edited = controller.blockById(parent.id)!;
      expect(edited.children.single.id, child.id, reason: source);
      expect(edited.children.single.plainText, child.plainText, reason: source);
      expect(controller.markdown, contains(r'Child $x$'), reason: source);
    }
  });

  test('first inline math insertion preserves unaffected inline AST', () {
    const source =
        '**Important** [documentation](docs.md) `code` '
        '***nested*** velocity *after* ![diagram](image.png)\n';
    final document = const MarkdownParser()
        .parse(filePath: 'math.md', source: source)
        .busyDocument;
    final controller = BusyMarkWysiwygDocumentController(document: document);
    final block = document.blocks.single;
    final start = block.plainText.indexOf('velocity');

    controller.insertInlineMath(block.id, start, start + 'velocity'.length);

    final edited = controller.blockById(block.id)!;
    final inlines = _flattenInlines(edited.inlines).toList();
    expect(inlines.any((inline) => inline.kind == BusyInlineKind.strong), true);
    expect(
      inlines.any(
        (inline) =>
            inline.kind == BusyInlineKind.link &&
            inline.destination == 'docs.md',
      ),
      true,
    );
    expect(
      inlines.any(
        (inline) => inline.kind == BusyInlineKind.code && inline.text == 'code',
      ),
      true,
    );
    expect(
      inlines.any(
        (inline) =>
            inline.kind == BusyInlineKind.image &&
            inline.destination == 'image.png',
      ),
      true,
    );
    expect(
      inlines.any((inline) => inline.kind == BusyInlineKind.emphasis),
      true,
    );
    expect(
      _containsNestedKinds(
            edited.inlines,
            BusyInlineKind.strong,
            BusyInlineKind.emphasis,
          ) ||
          _containsNestedKinds(
            edited.inlines,
            BusyInlineKind.emphasis,
            BusyInlineKind.strong,
          ),
      true,
    );
    expect(
      inlines.singleWhere((inline) => inline.kind == BusyInlineKind.math).text,
      'velocity',
    );
    expect(controller.markdown, contains(r'$velocity$'));
    expect(controller.markdown, contains('[documentation](docs.md)'));
    expect(controller.markdown, contains('![diagram](image.png)'));
  });

  test('math edits retain explicit heading IDs', () {
    const existingMath = '# Energy \$E=mc^2\$ {id="energy-equation"}\n';
    final existingDocument = const MarkdownParser()
        .parse(filePath: 'math.md', source: existingMath)
        .busyDocument;
    final existing = BusyMarkWysiwygDocumentController(
      document: existingDocument,
    );
    existing.updateMathSource(
      existingDocument.blocks.single.id,
      r'Changed $E=mc^2$',
    );
    _expectExplicitHeadingId(existing, 'energy-equation');

    const firstMath = '# Energy formula {id="energy-equation"}\n';
    final firstDocument = const MarkdownParser()
        .parse(filePath: 'math.md', source: firstMath)
        .busyDocument;
    final first = BusyMarkWysiwygDocumentController(document: firstDocument);
    final firstBlock = firstDocument.blocks.single;
    final formulaStart = firstBlock.plainText.indexOf('formula');
    first.insertInlineMath(
      firstBlock.id,
      formulaStart,
      formulaStart + 'formula'.length,
    );
    _expectExplicitHeadingId(first, 'energy-equation');

    final removed = BusyMarkWysiwygDocumentController(
      document: existingDocument,
    );
    removed.updateMathSource(existingDocument.blocks.single.id, 'Energy');
    _expectExplicitHeadingId(removed, 'energy-equation');
  });

  test('first math insertion recalculates a generated heading ID', () {
    final document = const MarkdownParser()
        .parse(filePath: 'math.md', source: '# Old heading\n')
        .busyDocument;
    final controller = BusyMarkWysiwygDocumentController(document: document);
    final heading = document.blocks.single;

    controller.insertInlineMath(
      heading.id,
      heading.plainText.length,
      heading.plainText.length,
      fallbackExpression: ' New',
    );

    final edited = controller.document.blocks.single;
    expect(edited.attributes['generatedId'], 'true');
    expect(edited.attributes['id'], 'old-heading-new');
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

  testWidgets('inline math toolbar preserves existing inline structure', (
    tester,
  ) async {
    const source =
        '**Important** [documentation](docs.md) `code` '
        '***nested*** velocity *after* ![diagram](image.png)\n';
    final document = const MarkdownParser()
        .parse(filePath: 'math.md', source: source)
        .busyDocument;
    var markdown = source;

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
    final field = find.byType(TextField);
    final textController = tester.widget<TextField>(field).controller!;
    final start = textController.text.indexOf('velocity');
    textController.selection = TextSelection(
      baseOffset: start,
      extentOffset: start + 'velocity'.length,
    );

    await tester.ensureVisible(find.byTooltip('Inline math'));
    await tester.tap(find.byTooltip('Inline math'));
    await tester.pump();

    expect(markdown, contains('**Important**'));
    expect(markdown, contains('[documentation](docs.md)'));
    expect(markdown, contains('`code`'));
    expect(markdown, contains(r'$velocity$'));
    expect(markdown, contains('*after*'));
    expect(markdown, contains('![diagram](image.png)'));
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

  testWidgets('focused plain table cell stays editable after math is typed', (
    tester,
  ) async {
    final document = const MarkdownParser()
        .parse(
          filePath: 'math.md',
          source: '| Formula |\n| --- |\n| before |\n',
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
    await tester.pump();
    final field = find.byKey(ValueKey(cell.id));
    await tester.tap(field);
    await tester.enterText(field, r'before $x$');
    await tester.pump();

    expect(field, findsOneWidget);
    expect(tester.widget<TextField>(field).focusNode?.hasFocus, isTrue);
    await tester.enterText(field, r'before $x$ after');
    await tester.pump();
    expect(markdown, contains(r'| before $x$ after |'));

    tester.widget<TextField>(field).focusNode?.unfocus();
    await _pumpMath(tester);
    expect(
      find.byKey(ValueKey('wysiwyg-rendered-math-${cell.id}')),
      findsOneWidget,
    );
  });
}

Iterable<BusyInline> _flattenInlines(List<BusyInline> inlines) sync* {
  for (final inline in inlines) {
    yield inline;
    yield* _flattenInlines(inline.children);
  }
}

bool _containsNestedKinds(
  List<BusyInline> inlines,
  BusyInlineKind outer,
  BusyInlineKind inner,
) {
  for (final inline in inlines) {
    if (inline.kind == outer &&
        _flattenInlines(inline.children).any((child) => child.kind == inner)) {
      return true;
    }
    if (_containsNestedKinds(inline.children, outer, inner)) {
      return true;
    }
  }
  return false;
}

void _expectExplicitHeadingId(
  BusyMarkWysiwygDocumentController controller,
  String id,
) {
  final heading = controller.document.blocks.single;
  expect(heading.kind, BusyBlockKind.heading);
  expect(heading.attributes['id'], id);
  expect(heading.attributes['generatedId'], 'false');
  expect(controller.markdown, contains('{id="$id"}'));
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
