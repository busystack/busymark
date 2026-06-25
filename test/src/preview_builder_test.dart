import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/markdown/preview_model.dart';
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

  test('preview blocks carry source locations for search navigation', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '# Title\n\nIntro text.\n\nSecond paragraph.\n',
    );
    final preview = previewBuilder.build(parsed);

    expect(preview.blocks.map((block) => block.sourceStartLine), [1, 3, 5]);
    expect(preview.blocks.map((block) => block.sourceEndLine), [1, 3, 5]);
    expect(preview.blocks.first.sourceStartOffset, 0);
    expect(preview.blocks[1].sourceStartOffset, greaterThan(0));
    expect(
      preview.blocks[1].sourceEndOffset,
      greaterThan(preview.blocks[1].sourceStartOffset ?? 0),
    );
  });

  test('preview source locations survive adjacent list items and code fences', () {
    final parsed = parser.parse(
      filePath: 'README.md',
      source: [
        '# FSRS Service',
        '',
        'Stateless FastAPI microservice exposing the **py-fsrs (FSRS 6.x)** scheduling algorithm via a strict OpenAPI contract.',
        '',
        'This service performs **pure computation only**.',
        'Persistence, authentication, authorization, and rate-limiting are expected to be handled by an upstream service (e.g.',
        'Spring Boot).',
        '',
        'This service is designed to be deployed:',
        '',
        '* Behind an API gateway or Spring Boot service',
        '* Without direct public exposure',
        '* Without authentication logic',
        '',
        '---',
        '',
        '## Conda Environment Setup',
        '',
        '```bash',
        'conda create -n fsrs-service python=3.11',
        'conda activate fsrs-service',
        'python -m pip install -e .',
        '```',
        '',
        'Install test dependencies:',
        '',
        '```bash',
        'conda install -n fsrs-service pytest',
        '```',
        '',
        '---',
        '',
        '## Run the Service',
        '',
        '```bash',
        'uvicorn fsrs_service.main:app --host 127.0.0.1 --port 8000',
        '```',
        '',
        'An application factory is also available:',
        '',
        '```python',
        'from fsrs_service.main import create_app',
        '',
        'app = create_app()',
        '```',
        '',
        for (var index = 0; index < 50; index += 1) ...[
          'Trailing content $index keeps the preview scrollable.',
          '',
        ],
      ].join('\n'),
    );
    final preview = previewBuilder.build(parsed);
    final paragraph = preview.blocks.singleWhere(
      (block) => block.text == 'An application factory is also available:',
    );
    final listBlocks = preview.blocks.where(
      (block) => block.kind == PreviewBlockKind.list,
    );

    expect(listBlocks.map((block) => block.sourceStartLine), [11, 12, 13]);
    expect(paragraph.sourceStartLine, 39);
    expect(paragraph.sourceEndLine, 39);
    expect(paragraph.sourceStartOffset, isNotNull);
    expect(
      preview.blocks.every((block) => block.sourceStartLine != null),
      true,
    );
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

    expect(lists, ['Bullet', 'Ordered', 'Star', 'Plus', 'Done']);
    expect(listBlocks[1].attributes['ordered'], 'true');
    expect(listBlocks[4].attributes['task'], 'true');
  });

  test('preview preserves links inside list items', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source:
          '- [How to Install Matter on RPi](https://mattercoder.com/'
          'codelabs/how-to-install-matter-on-rpi/)\n',
    );
    final preview = previewBuilder.build(parsed);
    final list = preview.blocks.singleWhere(
      (block) => block.kind == PreviewBlockKind.list,
    );

    expect(list.text, 'How to Install Matter on RPi');
    expect(list.inlines.single.kind, PreviewInlineKind.link);
    expect(
      list.inlines.single.destination,
      'https://mattercoder.com/codelabs/how-to-install-matter-on-rpi/',
    );
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
  });

  test('preview renders quote characters as text instead of HTML entities', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: 'Use "group" here.\n',
    );
    final preview = previewBuilder.build(parsed);
    final paragraph = preview.blocks.single;

    expect(paragraph.text, 'Use "group" here.');
    expect(paragraph.inlines.single.text, 'Use "group" here.');
  });

  test('preview preserves pasted local image destinations with spaces', () {
    const destination =
        '/tmp/busymark-fixtures/Screenshots/'
        'Screenshot From 2026-06-15 03-27-53.png';
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '![Screenshot From 2026-06-15 03-27-53.png]($destination)\n',
      validateLocalReferences: false,
    );
    final preview = previewBuilder.build(parsed);
    final image = preview.blocks.singleWhere(
      (block) => block.kind == PreviewBlockKind.image,
    );

    expect(image.text, 'Screenshot From 2026-06-15 03-27-53.png');
    expect(Uri.decodeComponent(image.attributes['src']!), destination);
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

  test('preview parses Writerside image attributes', () {
    final parsed = parser.parse(
      filePath: 'System-Design.md',
      source: '''
# System Design

![Architecture Diagram](architecture.png){ thumbnail="true" width="500" }
''',
    );
    final preview = previewBuilder.build(parsed);
    final image = preview.blocks.singleWhere(
      (block) => block.kind == PreviewBlockKind.image,
    );

    expect(image.text, 'Architecture Diagram');
    expect(image.attributes['src'], 'architecture.png');
    expect(image.attributes['thumbnail'], 'true');
    expect(image.attributes['width'], '500');
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
