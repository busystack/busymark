import 'package:busymark/src/editor/source_folding.dart';
import 'package:busymark/src/editor/source_language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('markdown folding detects sections lists quotes and code blocks', () {
    const source = '''
# Title
Intro.

- One
- Two

> Quote
> More

```dart
void main() {}
```

# Next
Done.
''';

    final regions = sourceFoldRegions(source, SourceSyntaxLanguage.markdown);

    expect(
      regions.any(
        (region) =>
            region.kind == SourceFoldKind.section &&
            region.startLine == 1 &&
            region.endLine == 13,
      ),
      isTrue,
    );
    expect(
      regions.any(
        (region) =>
            region.kind == SourceFoldKind.list &&
            region.startLine == 4 &&
            region.endLine == 5,
      ),
      isTrue,
    );
    expect(
      regions.any(
        (region) =>
            region.kind == SourceFoldKind.blockquote &&
            region.startLine == 7 &&
            region.endLine == 8,
      ),
      isTrue,
    );
    expect(
      regions.any(
        (region) =>
            region.kind == SourceFoldKind.code &&
            region.startLine == 10 &&
            region.endLine == 12,
      ),
      isTrue,
    );
  });

  test('markdown folding keeps shorter fence runs inside dynamic fences', () {
    const source =
        '````dart\n'
        'final value = 1;\n'
        '```\n'
        '# Still code\n'
        '`````\n'
        '# Heading\n';

    final codeRegion = sourceFoldRegions(
      source,
      SourceSyntaxLanguage.markdown,
    ).singleWhere((region) => region.kind == SourceFoldKind.code);

    expect(codeRegion.startLine, 1);
    expect(codeRegion.endLine, 5);
  });

  test('markdown folding does not join separate indented code blocks', () {
    const source = '    ```\n# Heading\n    ```\n';

    final regions = sourceFoldRegions(source, SourceSyntaxLanguage.markdown);

    expect(
      regions.where((region) => region.kind == SourceFoldKind.code),
      isEmpty,
    );
  });

  test('collapsed gutter entries preserve source line numbers', () {
    const source = '# Title\nIntro.\nMore.\n# Next\nDone.\n';
    final section = sourceFoldRegions(
      source,
      SourceSyntaxLanguage.markdown,
    ).firstWhere((region) => region.startLine == 1);

    final entries = sourceGutterEntries(source, SourceSyntaxLanguage.markdown, {
      section.key,
    });

    expect(entries.map((entry) => entry.lineNumber), [1, 4, 5, 6]);
    expect(entries.first.collapsed, isTrue);
    expect(entries.first.region?.key, section.key);
  });

  test(
    'collapsing one repeated markdown subsection keeps peer sections visible',
    () {
      const source =
          '# Title\n'
          '\n'
          '## First\n'
          'First body.\n'
          '\n'
          '## Second\n'
          'Second body.\n'
          '\n'
          '## Third\n'
          'Third body.\n';

      final regions = sourceFoldRegions(source, SourceSyntaxLanguage.markdown);
      final second = regions.firstWhere(
        (region) =>
            region.kind == SourceFoldKind.section && region.startLine == 6,
      );

      final entries = sourceGutterEntries(
        source,
        SourceSyntaxLanguage.markdown,
        {second.key},
      );

      expect(entries.map((entry) => entry.lineNumber), [
        1,
        2,
        3,
        4,
        5,
        6,
        9,
        10,
        11,
      ]);
      expect(
        entries.firstWhere((entry) => entry.lineNumber == 6).collapsed,
        isTrue,
      );
      expect(
        entries.firstWhere((entry) => entry.lineNumber == 3).collapsed,
        isFalse,
      );
      expect(
        entries.firstWhere((entry) => entry.lineNumber == 9).collapsed,
        isFalse,
      );
    },
  );

  test('xml folding detects simple multiline tag blocks', () {
    const source = '''
<topic title="Install">
  <step>
    Run command.
  </step>
</topic>
''';

    final regions = sourceFoldRegions(source, SourceSyntaxLanguage.xml);

    expect(
      regions.any(
        (region) =>
            region.kind == SourceFoldKind.xml &&
            region.startLine == 1 &&
            region.endLine == 5,
      ),
      isTrue,
    );
    expect(
      regions.any(
        (region) =>
            region.kind == SourceFoldKind.xml &&
            region.startLine == 2 &&
            region.endLine == 4,
      ),
      isTrue,
    );
  });

  test(
    'markdown folding detects nested headings task lists and blockquotes',
    () {
      const source =
          '# A\n'
          'a\n'
          '## B\n'
          'b\n'
          '- [ ] task\n'
          '  continuation\n'
          '> quote\n'
          '> more\n'
          '# C\n';

      final regions = sourceFoldRegions(source, SourceSyntaxLanguage.markdown);

      expect(
        regions.any(
          (region) =>
              region.kind == SourceFoldKind.section &&
              region.startLine == 1 &&
              region.endLine == 8,
        ),
        isTrue,
      );
      expect(
        regions.any(
          (region) =>
              region.kind == SourceFoldKind.section &&
              region.startLine == 3 &&
              region.endLine == 8,
        ),
        isTrue,
      );
      expect(
        regions.any(
          (region) =>
              region.kind == SourceFoldKind.list &&
              region.startLine == 5 &&
              region.endLine == 6,
        ),
        isTrue,
      );
      expect(
        regions.any(
          (region) =>
              region.kind == SourceFoldKind.blockquote &&
              region.startLine == 7 &&
              region.endLine == 8,
        ),
        isTrue,
      );
    },
  );

  test('xml folding handles nested same-name tags with a stack', () {
    const source =
        '<topic>\n'
        '  <chapter>\n'
        '    <chapter>\n'
        '      <p>Nested</p>\n'
        '    </chapter>\n'
        '  </chapter>\n'
        '</topic>\n';

    final regions = sourceFoldRegions(source, SourceSyntaxLanguage.xml);

    expect(
      regions.any(
        (region) =>
            region.kind == SourceFoldKind.xml &&
            region.startLine == 3 &&
            region.endLine == 5,
      ),
      isTrue,
    );
    expect(
      regions.any(
        (region) =>
            region.kind == SourceFoldKind.xml &&
            region.startLine == 2 &&
            region.endLine == 6,
      ),
      isTrue,
    );
    expect(
      regions.any(
        (region) =>
            region.kind == SourceFoldKind.xml &&
            region.startLine == 1 &&
            region.endLine == 7,
      ),
      isTrue,
    );
  });

  test('malformed xml does not create unsafe fold ranges', () {
    const source =
        '<topic>\n'
        '  <chapter>\n'
        '</topic>\n';

    final regions = sourceFoldRegions(source, SourceSyntaxLanguage.xml);

    expect(regions, isEmpty);
  });

  test('line info supports CRLF endings', () {
    final lines = sourceLineInfos('a\r\nb\r\n');

    expect(lines.map((line) => line.text), ['a', 'b', '']);
    expect(lines[1].startOffset, 3);
  });
}
