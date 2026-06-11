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

    await tester.pumpWidget(
      MaterialApp(
        theme: buildBusyMarkTheme(
          brightness: Brightness.dark,
          accentColor: BusyMarkLinuxPalette.blueAccent,
        ),
        home: Builder(
          builder: (context) {
            foreground = BusyMarkSurfaceColors.of(context).foreground;
            final controller = BusyMarkSourceEditingController(
              text: '# Title\nText `code` [link](target.md)\n',
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

    expect(
      spans.any(
        (span) =>
            span.text == '# Title' && span.style?.fontWeight == FontWeight.w700,
      ),
      isTrue,
    );
    expect(_spanColor(spans, '`code`'), isNot(foreground));
    expect(_spanColor(spans, '[link](target.md)'), isNot(foreground));
  });

  testWidgets('xml source highlighter colors tags attributes and strings', (
    tester,
  ) async {
    late List<TextSpan> spans;
    late Color foreground;

    await tester.pumpWidget(
      MaterialApp(
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

  testWidgets('folded regions hide body lines without changing source text', (
    tester,
  ) async {
    const source = '# Title\nIntro.\nMore.\n';
    late List<TextSpan> spans;

    await tester.pumpWidget(
      MaterialApp(
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
}

Color? _spanColor(List<TextSpan> spans, String text) {
  return spans.firstWhere((span) => span.text == text).style?.color;
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
