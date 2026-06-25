import 'dart:io';

import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  const parser = MarkdownParser();

  String fixture(String name) => 'test/fixtures/markdown/$name';

  test('extracts title, outline, links, images, and code fences', () {
    final path = fixture('basic.md');
    final parsed = parser.parse(
      filePath: path,
      source: File(path).readAsStringSync(),
      workspaceRoot: 'test/fixtures/markdown',
    );

    expect(parsed.title, 'Basic Markdown');
    expect(parsed.headings.map((item) => item.text), contains('Steps'));
    expect(
      parsed.headings.singleWhere((item) => item.text == 'Steps').id,
      'steps',
    );
    expect(parsed.links.single.destination, 'other.md');
    expect(parsed.images.single.destination, 'logo.png');
    expect(parsed.codeBlocks.single.language, 'dart');
  });

  test('extracts front matter title', () {
    final path = fixture('front_matter.md');
    final parsed = parser.parse(
      filePath: path,
      source: File(path).readAsStringSync(),
    );

    expect(parsed.title, 'Front Matter Title');
  });

  test('detects unresolved links, missing images, and missing alt text', () {
    final path = fixture('links_images.md');
    final parsed = parser.parse(
      filePath: path,
      source: File(path).readAsStringSync(),
      workspaceRoot: 'test/fixtures/markdown',
    );

    expect(
      parsed.diagnostics.map((item) => item.code),
      containsAll([
        'markdown.link.unresolved-target',
        'markdown.image.missing-file',
        'markdown.image.missing-alt',
      ]),
    );
  });

  test('resolves Writerside topic-specific image directories', () async {
    final root = await Directory.systemTemp.createTemp('busymark_writerside_');
    addTearDown(() => root.deleteSync(recursive: true));
    final topics = Directory(p.join(root.path, 'topics'))..createSync();
    final images = Directory(p.join(root.path, 'images', 'system-design'))
      ..createSync(recursive: true);
    final nestedImages = Directory(
      p.join(root.path, 'images', 'methodology', 'orchestrator-devices'),
    )..createSync(recursive: true);
    File(p.join(images.path, 'architecture.png')).writeAsBytesSync([0]);
    File(p.join(nestedImages.path, 'rpi_1.jpg')).writeAsBytesSync([0]);
    final topicPath = p.join(topics.path, 'System-Design.md');
    final parsed = parser.parse(
      filePath: topicPath,
      workspaceRoot: topics.path,
      source:
          '# System Design\n\n'
          '![Architecture Diagram](architecture.png){ width="500" }\n'
          '![Raspberry Pi Imager](rpi_1.jpg){ width="500" }\n',
    );

    expect(
      parsed.diagnostics.map((item) => item.code),
      isNot(contains('markdown.image.missing-file')),
    );
  });

  test('cross-linked Markdown anchor validation does not recurse forever', () {
    final path = fixture('cycle_a.md');
    final parsed = parser.parse(
      filePath: path,
      source: File(path).readAsStringSync(),
      workspaceRoot: 'test/fixtures/markdown',
    );

    expect(
      parsed.diagnostics.map((item) => item.code),
      isNot(contains('markdown.link.unresolved-anchor')),
    );
  });

  test('detects unsafe raw HTML', () {
    final path = fixture('unsafe_html.md');
    final parsed = parser.parse(
      filePath: path,
      source: File(path).readAsStringSync(),
    );

    expect(
      parsed.diagnostics.map((item) => item.code),
      contains('markdown.raw-html.unsafe'),
    );
  });

  test('extracts Writerside Markdown XML blocks and variables', () {
    final path = fixture('writerside_markdown.md');
    final parsed = parser.parse(
      filePath: path,
      source: File(path).readAsStringSync(),
      mode: MarkdownMode.writersideMarkdown,
    );

    expect(
      parsed.xmlBlocks.map((item) => item.elementName),
      containsAll(['var', 'tabs']),
    );
    expect(parsed.variables.map((item) => item.name), contains('product'));
  });
}
