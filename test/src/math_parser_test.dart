import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/busymark_markdown_serializer.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/markdown/math_syntax.dart';
import 'package:busymark/src/markdown/preview_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = MarkdownParser();
  const serializer = BusyMarkMarkdownSerializer();

  BusyDocument parse(String source, {bool writerside = false}) {
    return parser
        .parse(
          filePath: writerside ? 'topic.md' : 'document.md',
          source: source,
          mode: writerside
              ? MarkdownMode.writersideMarkdown
              : MarkdownMode.commonMark,
          validateLocalReferences: false,
        )
        .busyDocument;
  }

  test('parses several dollar formulas as semantic inline math', () {
    final document = parse(r'Text $x$ then $\frac{a}{b}$ and **$z^2$**.');
    final math = document.blocks
        .expand(allInlines)
        .where((inline) => inline.kind == BusyInlineKind.math)
        .toList();

    expect(math.map((inline) => inline.text), ['x', r'\frac{a}{b}', 'z^2']);
    expect(
      math.map((inline) => inline.attributes[busyMarkMathSourceFormAttribute]),
      everyElement(BusyMathSourceForm.dollarInline.name),
    );
  });

  test('parses the GitHub dollar-backtick form without delimiters', () {
    final document = parse(r'Before $`\sqrt{x}`$ after.');
    final math = document.blocks.single.inlines.singleWhere(
      (inline) => inline.kind == BusyInlineKind.math,
    );

    expect(math.text, r'\sqrt{x}');
    expect(
      math.attributes[busyMarkMathSourceFormAttribute],
      BusyMathSourceForm.githubDollarBacktick.name,
    );
  });

  test('parses single-line and multiline display math as blocks', () {
    final document = parse(r'''
Paragraph before.

$$x^2 + y^2$$

$$
\begin{aligned}
a &= b \\
c &= d
\end{aligned}
$$

Paragraph after.
''');
    final math = document.blocks
        .where((block) => block.kind == BusyBlockKind.math)
        .toList();

    expect(math, hasLength(2));
    expect(math.first.plainText, 'x^2 + y^2');
    expect(math.last.plainText, contains(r'\begin{aligned}'));
    expect(math.every((block) => block.sourceSpan != null), isTrue);
  });

  test('math scanner stays aligned around every neighboring block kind', () {
    final source = '''
Paragraph.

\$\$x\$\$

# Heading

- List

> Quote

```dart
code();
```

---

\$\$y\$\$

Final paragraph.
''';
    final document = parse(source);

    expect(
      document.blocks.where((b) => b.kind == BusyBlockKind.math),
      hasLength(2),
    );
    expect(document.blocks.every((block) => block.sourceSpan != null), isTrue);
    expect(serializer.serialize(document), source);
  });

  test('math and Writerside tex fences follow document compatibility', () {
    const source = '''
```math
E = mc^2
```

```tex
F = ma
```
''';
    final markdown = parse(source);
    final writerside = parse(source, writerside: true);

    expect(markdown.blocks.map((block) => block.kind), [
      BusyBlockKind.math,
      BusyBlockKind.codeBlock,
    ]);
    expect(writerside.blocks.map((block) => block.kind), [
      BusyBlockKind.math,
      BusyBlockKind.math,
    ]);
    expect(serializer.serialize(markdown), source);
    expect(serializer.serialize(writerside), source);
  });

  test('Writerside semantic math is inline and remains source-preserving', () {
    const source = 'The result is <math>\\mathbb{R}</math> here.\n';
    final document = parse(source, writerside: true);
    final math = document.blocks.single.inlines.singleWhere(
      (inline) => inline.kind == BusyInlineKind.math,
    );

    expect(math.text, r'\mathbb{R}');
    expect(
      math.attributes[busyMarkMathSourceFormAttribute],
      BusyMathSourceForm.writersideElement.name,
    );
    expect(serializer.serialize(document), source);
  });

  test(
    'escaped dollars, code, currency, empty and malformed forms stay text',
    () {
      final document = parse(
        r'Cost is \$5, range $5-$10, code `$x$`, empty $$, and open $x.',
      );

      expect(
        document.blocks
            .expand(allInlines)
            .where((inline) => inline.kind == BusyInlineKind.math),
        isEmpty,
      );
      expect(serializer.serialize(document), contains(r'open $x'));

      final emptyDisplay = parse(r'''$$

$$
''');
      expect(
        emptyDisplay.blocks.where((block) => block.kind == BusyBlockKind.math),
        isEmpty,
      );

      final mixedCurrency = parse(
        r'It costs $5 and the variable is $x$; another price is US$10.00.',
      );
      final math = mixedCurrency.blocks
          .expand(allInlines)
          .where((inline) => inline.kind == BusyInlineKind.math)
          .toList();
      expect(math.map((inline) => inline.text), ['x']);
      expect(
        serializer.serialize(mixedCurrency),
        r'It costs $5 and the variable is $x$; another price is US$10.00.',
      );
    },
  );

  test('inline math survives list, blockquote, and table structure', () {
    final document = parse(r'''
- Item $x$

> Quote $y$

| Value |
| --- |
| $z$ |
''');
    final expressions = document.blocks
        .expand(allInlines)
        .where((inline) => inline.kind == BusyInlineKind.math)
        .map((inline) => inline.text);

    expect(expressions, containsAll(['x', 'y', 'z']));
  });

  test('CRLF math input and every original form round-trip untouched', () {
    const source =
        'Inline \$x\$ and \$`y`\$.\r\n\r\n\$\$\r\nz^2\r\n\$\$\r\n\r\n```math\r\na+b\r\n```\r\n';
    final document = parse(source);

    expect(serializer.serialize(document), source);
  });

  test('preview builder creates first-class inline and display math nodes', () {
    final preview = const BusyMarkPreviewBuilder().build(
      parse('Inline \$x\$ and another \$x\$.\n\n\$\$y\$\$\n'),
    );

    expect(preview.blocks.last.kind, PreviewBlockKind.math);
    final inlineMath = preview.blocks.first.inlines
        .where((inline) => inline.kind == PreviewInlineKind.math)
        .toList();
    expect(inlineMath, hasLength(2));
    expect(
      inlineMath.map((inline) => inline.attributes['expressionId']).toSet(),
      hasLength(2),
    );
  });
}

Iterable<BusyInline> descendants(BusyInline inline) sync* {
  for (final child in inline.children) {
    yield child;
    yield* descendants(child);
  }
}

Iterable<BusyInline> allInlines(BusyBlock block) sync* {
  yield* block.inlines;
  for (final inline in block.inlines) {
    yield* descendants(inline);
  }
  for (final child in block.children) {
    yield* allInlines(child);
  }
}
