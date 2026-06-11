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
}
