import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/editor/source_folding.dart';
import 'package:busymark/src/editor/source_highlighter.dart';
import 'package:busymark/src/editor/source/source_document.dart';
import 'package:busymark/src/editor/source/source_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('source highlighting bounds high-match span composition', (
    tester,
  ) async {
    final source = List.filled(
      sourceInteractiveSearchMatchLimit + 500,
      'a',
    ).join();
    late TextSpan span;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final controller = BusyMarkSourceEditingController(text: source)
              ..setSearchResult(
                searchSourceDocument(
                  SourceDocument(fullText: source),
                  const SourceSearchOptions(query: 'a'),
                ),
              );
            span = controller.buildSourceTextSpan(context: context);
            controller.dispose();
            return const SizedBox();
          },
        ),
      ),
    );

    expect(span.toPlainText(), source);
    expect(
      _flattenTextSpans(span),
      hasLength(lessThanOrEqualTo(sourceInteractiveSearchMatchLimit + 2)),
    );
  });

  testWidgets('markdown source highlighter colors editor syntax', (
    tester,
  ) async {
    late List<TextSpan> spans;
    late Color foreground;
    late BusyMarkSyntaxColors syntax;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildBusyMarkTheme(
          brightness: Brightness.dark,
          accentColor: BusyMarkLinuxPalette.blueAccent,
        ),
        home: Builder(
          builder: (context) {
            foreground = BusyMarkSurfaceColors.of(context).foreground;
            syntax = BusyMarkSyntaxColors.of(context);
            final controller = BusyMarkSourceEditingController(
              text:
                  '# Title\n'
                  'Text `code` [link](target.md) **bold** *italic* ~~done~~\n',
              language: SourceSyntaxLanguage.markdown,
            );
            spans = _flattenTextSpans(
              controller.buildTextSpan(
                context: context,
                style: const TextStyle(fontSize: 14),
                withComposing: false,
              ),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(_spanStyle(spans, '# ')?.color, syntax.keyword);
    expect(_spanStyle(spans, 'Title')?.fontSize, 14 * 1.55);
    expect(_spanStyle(spans, 'Title')?.fontWeight, FontWeight.w700);
    expect(_spanStyle(spans, 'Title')?.color, foreground);
    expect(_spanStyle(spans, '`')?.color, syntax.punctuation);
    expect(_spanStyle(spans, 'code')?.fontFamily, 'Ubuntu Mono');
    expect(_spanStyle(spans, 'code')?.color, foreground);
    expect(_spanStyle(spans, '[')?.color, syntax.punctuation);
    expect(_spanColor(spans, 'link'), isNot(foreground));
    expect(_spanStyle(spans, 'link')?.decoration, TextDecoration.underline);
    expect(_spanStyle(spans, '](')?.color, syntax.punctuation);
    expect(_spanStyle(spans, 'target.md')?.color, syntax.string);
    expect(_spanStyle(spans, ')')?.color, syntax.punctuation);
    expect(_spanStyle(spans, '**')?.color, syntax.punctuation);
    expect(_spanStyle(spans, 'bold')?.fontWeight, FontWeight.w700);
    expect(_spanStyle(spans, 'bold')?.color, foreground);
    expect(_spanStyle(spans, '*')?.color, syntax.punctuation);
    expect(_spanStyle(spans, 'italic')?.fontStyle, FontStyle.italic);
    expect(_spanStyle(spans, 'italic')?.color, foreground);
    expect(_spanStyle(spans, '~~')?.color, syntax.punctuation);
    expect(_spanStyle(spans, 'done')?.decoration, TextDecoration.lineThrough);
    expect(_spanStyle(spans, 'done')?.color, foreground);
  });

  testWidgets('markdown source highlighter formats fenced code', (
    tester,
  ) async {
    late List<TextSpan> spans;
    late Color foreground;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildBusyMarkTheme(
          brightness: Brightness.dark,
          accentColor: BusyMarkLinuxPalette.blueAccent,
        ),
        home: Builder(
          builder: (context) {
            foreground = BusyMarkSurfaceColors.of(context).foreground;
            final controller = BusyMarkSourceEditingController(
              text:
                  '```dart\n'
                  'final count = 42;\n'
                  'print("done"); // comment\n'
                  '```\n'
                  '```json\n'
                  '{ "name": "BusyMark", "enabled": true }\n'
                  '```\n',
              language: SourceSyntaxLanguage.markdown,
            );
            spans = _flattenTextSpans(
              controller.buildTextSpan(
                context: context,
                style: const TextStyle(fontSize: 14),
                withComposing: false,
              ),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(_spanColor(spans, 'final'), isNot(foreground));
    expect(_spanColor(spans, '42'), isNot(foreground));
    expect(_spanColor(spans, 'print'), isNot(foreground));
    expect(_spanColor(spans, '"done"'), isNot(foreground));
    expect(_spanColor(spans, 'comment'), isNot(foreground));
    expect(_spanColor(spans, '"name"'), isNot(foreground));
    expect(_spanColor(spans, 'BusyMark'), isNot(foreground));
    expect(_spanColor(spans, 'true'), isNot(foreground));
  });

  testWidgets('markdown highlighter tracks dynamic fence delimiters', (
    tester,
  ) async {
    const source =
        '````dart\n'
        'final value = 1;\n'
        '```\n'
        '# Still code\n'
        '`````\n'
        '# Heading\n';
    final spans = await _highlightMarkdown(tester, source);

    expect(_spanStyle(spans, 'final')?.color, isNotNull);
    expect(_spanStyle(spans, 'Still')?.fontSize, 14);
    expect(_spanStyle(spans, 'Heading')?.fontSize, greaterThan(14));
  });

  testWidgets('markdown highlighter does not open on indented code', (
    tester,
  ) async {
    final spans = await _highlightMarkdown(
      tester,
      '    ```\n# Heading\n    ```\n',
    );

    expect(_spanStyle(spans, 'Heading')?.fontSize, greaterThan(14));
  });

  testWidgets('xml source highlighter colors tags attributes and strings', (
    tester,
  ) async {
    late List<TextSpan> spans;
    late Color foreground;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildBusyMarkTheme(
          brightness: Brightness.dark,
          accentColor: BusyMarkLinuxPalette.blueAccent,
        ),
        home: Builder(
          builder: (context) {
            foreground = BusyMarkSurfaceColors.of(context).foreground;
            final controller = BusyMarkSourceEditingController(
              text: '<topic title="Install"><step>Run</step></topic>',
              language: SourceSyntaxLanguage.xml,
            );
            spans = _flattenTextSpans(
              controller.buildTextSpan(
                context: context,
                style: const TextStyle(fontSize: 14),
                withComposing: false,
              ),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(_spanColor(spans, 'topic'), isNot(foreground));
    expect(_spanColor(spans, 'title'), isNot(foreground));
    expect(_spanColor(spans, '"Install"'), isNot(foreground));
  });

  testWidgets('plain source highlighter keeps normal editor text color', (
    tester,
  ) async {
    late TextSpan span;
    late Color foreground;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildBusyMarkTheme(
          brightness: Brightness.dark,
          accentColor: BusyMarkLinuxPalette.blueAccent,
        ),
        home: Builder(
          builder: (context) {
            foreground = BusyMarkSurfaceColors.of(context).foreground;
            final controller = BusyMarkSourceEditingController(
              text: 'plain text',
              language: SourceSyntaxLanguage.plain,
            );
            span = controller.buildTextSpan(
              context: context,
              style: const TextStyle(fontSize: 14),
              withComposing: false,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(span.style?.color, foreground);
    expect(span.children, hasLength(1));
    expect((span.children!.single as TextSpan).text, 'plain text');
  });

  testWidgets(
    'controller can keep editable text transparent for custom render',
    (tester) async {
      late TextSpan root;
      late List<TextSpan> spans;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildBusyMarkTheme(
            brightness: Brightness.dark,
            accentColor: BusyMarkLinuxPalette.blueAccent,
          ),
          home: Builder(
            builder: (context) {
              final controller = BusyMarkSourceEditingController(
                text: '# Title\nText\n',
                language: SourceSyntaxLanguage.markdown,
              )..renderText = false;
              root = controller.buildTextSpan(
                context: context,
                style: const TextStyle(fontSize: 14),
                withComposing: false,
              );
              spans = _flattenTextSpans(root);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(root.style?.color, Colors.transparent);
      expect(spans.map((span) => span.text).join(), '# Title\nText\n');
    },
  );

  testWidgets('transparent editing layout matches rendered Markdown layout', (
    tester,
  ) async {
    const source =
        '# A wrapped heading with words\n'
        'Text with **strong words**, *emphasis*, and `inline code`.\n'
        '```dart\n'
        'final value = "**not emphasis**";\n'
        '```\n';
    const style = TextStyle(
      fontFamily: 'Ubuntu Mono',
      fontSize: 14,
      height: 1.45,
    );
    late TextPainter transparentPainter;
    late TextPainter renderedPainter;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildBusyMarkTheme(
          brightness: Brightness.dark,
          accentColor: BusyMarkLinuxPalette.blueAccent,
        ),
        home: Builder(
          builder: (context) {
            final controller = BusyMarkSourceEditingController(
              text: source,
              language: SourceSyntaxLanguage.markdown,
            )..renderText = false;
            transparentPainter = TextPainter(
              text: controller.buildTextSpan(
                context: context,
                style: style,
                withComposing: false,
              ),
              textDirection: TextDirection.ltr,
            )..layout(maxWidth: 180);
            renderedPainter = TextPainter(
              text: controller.buildSourceTextSpan(
                context: context,
                style: style,
              ),
              textDirection: TextDirection.ltr,
            )..layout(maxWidth: 180);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    addTearDown(transparentPainter.dispose);
    addTearDown(renderedPainter.dispose);

    final transparentMetrics = transparentPainter.computeLineMetrics();
    final renderedMetrics = renderedPainter.computeLineMetrics();
    expect(transparentMetrics, hasLength(renderedMetrics.length));
    for (var index = 0; index < renderedMetrics.length; index++) {
      expect(
        transparentMetrics[index].height,
        closeTo(renderedMetrics[index].height, 0.01),
      );
      expect(
        transparentMetrics[index].width,
        closeTo(renderedMetrics[index].width, 0.01),
      );
    }
    for (var offset = 0; offset <= source.length; offset++) {
      final transparentCaret = transparentPainter.getOffsetForCaret(
        TextPosition(offset: offset),
        Rect.zero,
      );
      final renderedCaret = renderedPainter.getOffsetForCaret(
        TextPosition(offset: offset),
        Rect.zero,
      );
      expect(transparentCaret.dx, closeTo(renderedCaret.dx, 0.01));
      expect(transparentCaret.dy, closeTo(renderedCaret.dy, 0.01));
    }
  });

  testWidgets('folded regions project body lines out of editable text', (
    tester,
  ) async {
    const source = '# Title\nIntro.\nMore.\n';
    late List<TextSpan> spans;
    late BusyMarkSourceEditingController controller;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildBusyMarkTheme(
          brightness: Brightness.dark,
          accentColor: BusyMarkLinuxPalette.blueAccent,
        ),
        home: Builder(
          builder: (context) {
            final region = sourceFoldRegions(
              source,
              SourceSyntaxLanguage.markdown,
            ).first;
            controller = BusyMarkSourceEditingController(
              text: source,
              language: SourceSyntaxLanguage.markdown,
            )..setFoldedRegions([region]);
            spans = _flattenTextSpans(
              controller.buildTextSpan(
                context: context,
                style: const TextStyle(fontSize: 14),
                withComposing: false,
              ),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(controller.fullText, source);
    expect(controller.text, '# Title\n');
    expect(spans.map((span) => span.text).join(), '# Title\n');
    expect(spans.map((span) => span.text).join(), isNot(contains('Intro.')));
  });

  testWidgets('rendered folded regions hide collapsed header text', (
    tester,
  ) async {
    const source = '# Title\nIntro.\nMore.\n# Next\n';
    late List<TextSpan> spans;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildBusyMarkTheme(
          brightness: Brightness.dark,
          accentColor: BusyMarkLinuxPalette.blueAccent,
        ),
        home: Builder(
          builder: (context) {
            final region = sourceFoldRegions(
              source,
              SourceSyntaxLanguage.markdown,
            ).firstWhere((region) => region.startLine == 1);
            final controller = BusyMarkSourceEditingController(
              text: source,
              language: SourceSyntaxLanguage.markdown,
            )..setFoldedRegions([region]);
            spans = _flattenTextSpans(
              controller.buildSourceTextSpan(
                context: context,
                style: const TextStyle(fontSize: 14),
                hideCollapsedStartLines: true,
              ),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(spans.map((span) => span.text).join(), '# Title\n# Next\n');
    expect(_spanStyle(spans, '# ')?.color, Colors.transparent);
    expect(_spanStyle(spans, 'Title')?.color, Colors.transparent);
    expect(_spanStyle(spans, '# ')?.fontSize, 14);
    expect(_spanStyle(spans, 'Title')?.fontSize, 14);
    expect(spans.map((span) => span.text).join(), isNot(contains('Intro.')));
    expect(_spanStyle(spans, 'Next')?.color, isNot(Colors.transparent));
  });

  testWidgets('folded regions collapse measured editor height', (tester) async {
    const source = '# Title\nIntro.\nMore.\n# Next\nDone.\n';
    const style = TextStyle(
      fontFamily: 'Ubuntu Mono',
      fontSize: 14,
      height: 1.45,
    );
    late double unfoldedHeight;
    late double foldedHeight;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildBusyMarkTheme(
          brightness: Brightness.dark,
          accentColor: BusyMarkLinuxPalette.blueAccent,
        ),
        home: Builder(
          builder: (context) {
            final region = sourceFoldRegions(
              source,
              SourceSyntaxLanguage.markdown,
            ).firstWhere((region) => region.startLine == 1);
            final unfolded = BusyMarkSourceEditingController(
              text: source,
              language: SourceSyntaxLanguage.markdown,
            );
            final folded = BusyMarkSourceEditingController(
              text: source,
              language: SourceSyntaxLanguage.markdown,
            )..setFoldedRegions([region]);

            unfoldedHeight = _layoutHeight(
              context,
              unfolded.buildTextSpan(
                context: context,
                style: style,
                withComposing: false,
              ),
            );
            foldedHeight = _layoutHeight(
              context,
              folded.buildTextSpan(
                context: context,
                style: style,
                withComposing: false,
              ),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(foldedHeight, lessThan(unfoldedHeight - 20));
  });

  testWidgets(
    'visual markdown editor keeps syntax markers visible while styling content',
    (tester) async {
      const source =
          '# **Title**\n'
          'Paragraph with [link](target.md) and `code`.\n';
      late TextSpan root;
      late List<TextSpan> spans;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildBusyMarkTheme(
            brightness: Brightness.dark,
            accentColor: BusyMarkLinuxPalette.blueAccent,
          ),
          home: Builder(
            builder: (context) {
              final controller = BusyMarkSourceEditingController(
                text: source,
                language: SourceSyntaxLanguage.markdown,
              )..visualMarkdown = true;
              root = controller.buildTextSpan(
                context: context,
                style: const TextStyle(fontSize: 14),
                withComposing: false,
              );
              spans = _flattenTextSpans(root);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(root.toPlainText(), source);
      expect(_spanStyle(spans, '# ')?.color, isNot(Colors.transparent));
      expect(_spanStyle(spans, '**')?.color, isNot(Colors.transparent));
      expect(_spanStyle(spans, 'Title')?.fontWeight, FontWeight.w700);
      expect(_spanStyle(spans, '[')?.color, isNot(Colors.transparent));
      expect(
        _spanStyle(spans, '](target.md)')?.color,
        isNot(Colors.transparent),
      );
      expect(_spanStyle(spans, 'link')?.decoration, TextDecoration.underline);
    },
  );

  testWidgets('visual markdown tracks dynamic fence delimiters', (
    tester,
  ) async {
    const source =
        '````dart\n'
        'final value = 1;\n'
        '```\n'
        '# Still code\n'
        '`````\n'
        '# Heading\n';
    late List<TextSpan> spans;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildBusyMarkTheme(
          brightness: Brightness.dark,
          accentColor: BusyMarkLinuxPalette.blueAccent,
        ),
        home: Builder(
          builder: (context) {
            final controller = BusyMarkSourceEditingController(
              text: source,
              language: SourceSyntaxLanguage.markdown,
            )..visualMarkdown = true;
            spans = _flattenTextSpans(
              controller.buildTextSpan(
                context: context,
                style: const TextStyle(fontSize: 14),
                withComposing: false,
              ),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(_spanStyle(spans, '```')?.fontFamily, 'Ubuntu Mono');
    expect(_spanStyle(spans, '# Still code')?.fontFamily, 'Ubuntu Mono');
    expect(_spanStyle(spans, 'Heading')?.fontSize, greaterThan(14));
  });

  testWidgets('markdown highlighter merges nested emphasis inside links', (
    tester,
  ) async {
    final spans = await _highlightMarkdown(
      tester,
      'Read [**bold**](target.md) now.\n',
    );

    final bold = _spanStyle(spans, 'bold');
    expect(bold?.fontWeight, FontWeight.w700);
    expect(bold?.decoration, TextDecoration.underline);
    expect(_spanStyle(spans, 'target.md')?.color, isNotNull);
  });

  testWidgets('markdown highlighter keeps inline code inside list items', (
    tester,
  ) async {
    final spans = await _highlightMarkdown(tester, '- run `busy` now\n');

    expect(_spanStyle(spans, '- ')?.color, isNotNull);
    expect(_spanStyle(spans, 'busy')?.fontFamily, 'Ubuntu Mono');
  });

  testWidgets('markdown highlighter merges bold and italic nesting', (
    tester,
  ) async {
    final spans = await _highlightMarkdown(tester, '__bold *italic*__\n');

    expect(_spanStyle(spans, 'bold ')?.fontWeight, FontWeight.w700);
    final italic = _spanStyle(spans, 'italic');
    expect(italic?.fontWeight, FontWeight.w700);
    expect(italic?.fontStyle, FontStyle.italic);
  });

  testWidgets('markdown highlighter merges links inside blockquotes', (
    tester,
  ) async {
    final spans = await _highlightMarkdown(tester, '> See [docs](docs.md)\n');

    expect(_spanStyle(spans, '> ')?.color, isNot(_spanColor(spans, 'See ')));
    expect(_spanStyle(spans, 'docs')?.decoration, TextDecoration.underline);
  });

  testWidgets('markdown highlighter keeps emphasis inside table cells', (
    tester,
  ) async {
    final spans = await _highlightMarkdown(
      tester,
      '| Column |\n| --- |\n| *value* |\n',
    );

    expect(_spanStyle(spans, 'value')?.fontStyle, FontStyle.italic);
  });

  testWidgets('markdown highlighter recognizes math without damaging code', (
    tester,
  ) async {
    final spans = await _highlightMarkdown(
      tester,
      r'Formula $x^2$ and $`a_b`$; code `$not$`; escaped \$5 and $5-$10.'
      '\n'
      r'$$'
      '\n'
      r'\int_0^1 x\,dx'
      '\n'
      r'$$'
      '\n',
    );

    final mathStyle = _spanStyle(spans, 'x^2');
    expect(mathStyle?.color, isNotNull);
    expect(_spanStyle(spans, 'a_b')?.color, mathStyle?.color);
    expect(_spanStyle(spans, r'$not$')?.fontFamily, 'Ubuntu Mono');
    expect(_spanStyle(spans, r'\int_0^1 x\,dx')?.color, mathStyle?.color);
  });
}

Future<List<TextSpan>> _highlightMarkdown(
  WidgetTester tester,
  String source,
) async {
  late List<TextSpan> spans;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildBusyMarkTheme(
        brightness: Brightness.dark,
        accentColor: BusyMarkLinuxPalette.blueAccent,
      ),
      home: Builder(
        builder: (context) {
          final controller = BusyMarkSourceEditingController(
            text: source,
            language: SourceSyntaxLanguage.markdown,
          );
          spans = _flattenTextSpans(
            controller.buildTextSpan(
              context: context,
              style: const TextStyle(fontSize: 14),
              withComposing: false,
            ),
          );
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return spans;
}

Color? _spanColor(List<TextSpan> spans, String text) {
  return _spanStyle(spans, text)?.color;
}

TextStyle? _spanStyle(List<TextSpan> spans, String text) {
  for (final span in spans) {
    if (span.text == text) {
      return span.style;
    }
  }
  for (final span in spans) {
    if (span.text?.contains(text) ?? false) {
      return span.style;
    }
  }
  throw StateError('No span contains "$text"');
}

List<TextSpan> _flattenTextSpans(InlineSpan span) {
  final result = <TextSpan>[];
  void visit(InlineSpan current) {
    if (current case final TextSpan textSpan) {
      if (textSpan.text != null) {
        result.add(textSpan);
      }
      for (final child in textSpan.children ?? const <InlineSpan>[]) {
        visit(child);
      }
    }
  }

  visit(span);
  return result;
}

double _layoutHeight(BuildContext context, InlineSpan span) {
  final painter = TextPainter(
    text: span,
    textDirection: TextDirection.ltr,
    textScaler: MediaQuery.textScalerOf(context),
  )..layout(maxWidth: 800);
  final height = painter.size.height;
  painter.dispose();
  return height;
}
