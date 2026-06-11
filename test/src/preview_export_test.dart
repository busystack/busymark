import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/markdown/preview_export.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = MarkdownParser();
  const previewBuilder = MarkdownPreviewBuilder();

  test('preview uses one generic label and no compatibility banner', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '# Title\n\n- First\n1. Second\n',
    );
    final preview = previewBuilder.build(parsed);

    expect(preview.modeLabel, 'Preview');
    expect(preview.compatibility, isEmpty);
  });

  test('preview headings carry parser anchors for outline navigation', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '# Title\n\n## Details {id="details"}\n',
    );
    final preview = previewBuilder.build(parsed);
    final headings = preview.blocks.where(
      (block) => block.kind == PreviewBlockKind.heading,
    );

    expect(headings.map((block) => block.attributes['id']), [
      parsed.headings[0].id,
      'details',
    ]);
  });

  test('preview list text removes Markdown markers', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '# Title\n\n- Bullet\n1. Ordered\n',
    );
    final preview = previewBuilder.build(parsed);
    final lists = preview.blocks
        .where((block) => block.kind == PreviewBlockKind.list)
        .map((block) => block.text)
        .toList();
    final html = const MarkdownHtmlExporter().export(parsed);

    expect(lists, ['Bullet', 'Ordered']);
    expect(html, contains('<ul><li>Bullet</li></ul>'));
    expect(html, isNot(contains('Compatibility level:')));
  });

  test('preview preserves source order for code and images', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '''
# Title

Intro text.

```dart
void main() {}
```

![Logo](images/logo.png)

Conclusion.
''',
    );
    final preview = previewBuilder.build(parsed);

    expect(preview.blocks.map((block) => block.kind), [
      PreviewBlockKind.heading,
      PreviewBlockKind.paragraph,
      PreviewBlockKind.code,
      PreviewBlockKind.image,
      PreviewBlockKind.paragraph,
    ]);
    expect(preview.blocks.last.text, 'Conclusion.');
  });

  test('front matter is skipped only at the top of the document', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '''
# Notes

Note: this line must remain visible.
---
Also visible.
''',
    );
    final preview = previewBuilder.build(parsed);

    expect(
      preview.blocks.map((block) => block.text),
      containsAll([
        'Note: this line must remain visible.',
        '---',
        'Also visible.',
      ]),
    );
  });
}
