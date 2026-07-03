import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/editor/source_folding.dart';
import 'package:busymark/src/editor/source_highlighter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
    expect(_spanColor(spans, '// comment'), isNot(foreground));
    expect(_spanColor(spans, '"name"'), isNot(foreground));
    expect(_spanColor(spans, '"BusyMark"'), isNot(foreground));
    expect(_spanColor(spans, 'true'), isNot(foreground));
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

  testWidgets('folded regions hide body lines without changing source text', (
    tester,
  ) async {
    const source = '# Title\nIntro.\nMore.\n';
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
            ).first;
            final controller = BusyMarkSourceEditingController(
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

    expect(spans.map((span) => span.text).join(), source);
    expect(
      spans.any(
        (span) =>
            span.text == 'Intro.\nMore.\n' &&
            span.style?.color == Colors.transparent &&
            span.style?.fontSize == 0.01,
      ),
      isTrue,
    );
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

    expect(spans.map((span) => span.text).join(), source);
    expect(_spanStyle(spans, '# ')?.color, Colors.transparent);
    expect(_spanStyle(spans, 'Title')?.color, Colors.transparent);
    expect(_spanStyle(spans, '# ')?.fontSize, 14);
    expect(_spanStyle(spans, 'Title')?.fontSize, 14);
    expect(
      spans.any(
        (span) =>
            span.text == 'Intro.\nMore.\n' &&
            span.style?.color == Colors.transparent &&
            span.style?.fontSize == 0.01,
      ),
      isTrue,
    );
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
}

Color? _spanColor(List<TextSpan> spans, String text) {
  return spans.firstWhere((span) => span.text == text).style?.color;
}

TextStyle? _spanStyle(List<TextSpan> spans, String text) {
  return spans.firstWhere((span) => span.text == text).style;
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
