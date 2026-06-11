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
      source: '# Title\n\n- Bullet\n1. Ordered\n* Star\n+ Plus\n- [x] Done\n',
    );
    final preview = previewBuilder.build(parsed);
    final lists = preview.blocks
        .where((block) => block.kind == PreviewBlockKind.list)
        .map((block) => block.text)
        .toList();
    final listBlocks = preview.blocks
        .where((block) => block.kind == PreviewBlockKind.list)
        .toList();
    final html = const MarkdownHtmlExporter().export(parsed);

    expect(lists, ['Bullet', 'Ordered', 'Star', 'Plus', 'Done']);
    expect(listBlocks[1].attributes['ordered'], 'true');
    expect(listBlocks[4].attributes['task'], 'true');
    expect(html, contains('<ul><li>Bullet</li></ul>'));
    expect(html, contains('<ol><li>Ordered</li></ol>'));
    expect(html, contains('<input type="checkbox" disabled checked> Done'));
    expect(html, isNot(contains('Compatibility level:')));
  });

  test('preview preserves inline Markdown semantics', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source:
          '# **Title**\n\nParagraph with **bold**, *italic*, ~~strike~~, '
          '`code`, [link](other.md), ![Logo](logo.png), '
          '<https://example.com>, and \\*escaped\\* text.\n',
    );
    final preview = previewBuilder.build(parsed);
    final paragraph = preview.blocks.singleWhere(
      (block) => block.kind == PreviewBlockKind.paragraph,
    );
    final html = const MarkdownHtmlExporter().export(parsed);

    expect(preview.blocks.first.text, 'Title');
    expect(
      paragraph.inlines.map((inline) => inline.kind),
      containsAll([
        PreviewInlineKind.strong,
        PreviewInlineKind.emphasis,
        PreviewInlineKind.strikethrough,
        PreviewInlineKind.code,
        PreviewInlineKind.link,
        PreviewInlineKind.image,
      ]),
    );
    expect(paragraph.text, contains('bold'));
    expect(paragraph.text, contains('*escaped* text'));
    expect(html, contains('<strong>bold</strong>'));
    expect(html, contains('<em>italic</em>'));
    expect(html, contains('<del>strike</del>'));
    expect(html, contains('<code>code</code>'));
    expect(html, contains('<a href="other.md">link</a>'));
    expect(html, contains('<img src="logo.png" alt="Logo">'));
  });

  test('preview treats single newlines inside paragraphs as soft breaks', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '''
The system follows a modular structure, where each module has its own subnetwork of accessory devices, such as sensors and
actuators, that autonomously monitor and control environmental conditions without relying on a central hub.
''',
    );
    final preview = previewBuilder.build(parsed);

    expect(preview.blocks, hasLength(1));
    expect(preview.blocks.single.kind, PreviewBlockKind.paragraph);
    expect(
      preview.blocks.single.text,
      'The system follows a modular structure, where each module has its own '
      'subnetwork of accessory devices, such as sensors and actuators, that '
      'autonomously monitor and control environmental conditions without '
      'relying on a central hub.',
    );
  });

  test('preview supports common Markdown block variants', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '''
Setext Title
===

---

~~~dart
void main() {}
~~~

> Quote with **strong** text.
''',
    );
    final preview = previewBuilder.build(parsed);

    expect(preview.blocks.map((block) => block.kind), [
      PreviewBlockKind.heading,
      PreviewBlockKind.thematicBreak,
      PreviewBlockKind.code,
      PreviewBlockKind.quote,
    ]);
    expect(preview.blocks.first.level, 1);
    expect(preview.blocks[2].language, 'dart');
    expect(
      preview.blocks[3].inlines.map((inline) => inline.kind),
      contains(PreviewInlineKind.strong),
    );
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
