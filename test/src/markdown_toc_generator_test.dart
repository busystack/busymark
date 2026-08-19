import 'package:busymark/src/core/diagnostic.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/markdown/markdown_toc_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const generator = MarkdownTocGenerator();

  test('generates and updates a parser-derived marker-delimited TOC', () {
    const source = '''---
title: Product guide
---

# Product guide

## Install {id="installation"}

### Linux [setup]

## Install
''';
    final generated = generator.generate(
      source: source,
      filePath: 'guide.md',
      mode: MarkdownMode.writersideMarkdown,
      title: 'Table of contents',
    );

    expect(generated.updated, isFalse);
    expect(generated.entryCount, 3);
    expect(
      generated.source,
      contains('''# Product guide

<!-- busymark:toc:start -->
## Table of contents

- [Install](#installation)
  - [Linux \\[setup\\]](#linux-setup)
- [Install](#install)
<!-- busymark:toc:end -->
'''),
    );

    final renamed = generated.source.replaceFirst(
      '### Linux [setup]',
      '### Linux desktop',
    );
    final updated = generator.generate(
      source: renamed,
      filePath: 'guide.md',
      mode: MarkdownMode.writersideMarkdown,
      title: 'Table of contents',
    );
    expect(updated.updated, isTrue);
    expect(updated.source, contains('[Linux desktop](#linux-desktop)'));
    expect(busyMarkTocStartMarker.allMatches(updated.source), hasLength(1));
  });

  test('ignores marker text inside fenced code', () {
    const source = '''# Guide

```html
<!-- busymark:toc:start -->
<!-- busymark:toc:end -->
```

## Usage
''';
    final result = generator.generate(
      source: source,
      filePath: 'guide.md',
      mode: MarkdownMode.gfm,
      title: 'Table of contents',
    );

    expect(busyMarkTocStartMarker.allMatches(result.source), hasLength(2));
    expect(result.entryCount, 1);
  });

  test('refuses malformed markers and documents without sections', () {
    expect(
      () => generator.generate(
        source: '$busyMarkTocStartMarker\n# Guide\n',
        filePath: 'guide.md',
        mode: MarkdownMode.gfm,
        title: 'Table of contents',
      ),
      throwsA(
        isA<MarkdownTocException>().having(
          (error) => error.failure,
          'failure',
          MarkdownTocFailure.malformedMarkers,
        ),
      ),
    );
    expect(
      () => generator.generate(
        source: '# Guide\n',
        filePath: 'guide.md',
        mode: MarkdownMode.gfm,
        title: 'Table of contents',
      ),
      throwsA(
        isA<MarkdownTocException>().having(
          (error) => error.failure,
          'failure',
          MarkdownTocFailure.noHeadings,
        ),
      ),
    );
  });

  test('emits deterministic Markdown accessibility diagnostics', () {
    final parsed = const MarkdownParser().parse(
      filePath: 'accessibility.md',
      source: '''# Guide

### Skipped level

[](empty.md)

[Click here](details.md)

| Name | |
| --- | --- |
| BusyMark | Editor |
''',
      mode: MarkdownMode.gfm,
      validateLocalReferences: false,
    );
    final byCode = {for (final item in parsed.diagnostics) item.code: item};

    expect(byCode, contains('markdown.heading.skipped-level'));
    expect(byCode, contains('markdown.link.empty-text'));
    expect(byCode, contains('markdown.link.review-text'));
    expect(
      byCode['markdown.link.review-text']?.severity,
      DiagnosticSeverity.hint,
    );
    expect(byCode, contains('markdown.table.empty-header'));
  });
}
