import 'dart:io';

import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/markdown/preview_export.dart';
import 'package:flutter_test/flutter_test.dart';

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

  test('exports deterministic sanitized HTML', () {
    final path = fixture('unsafe_html.md');
    final parsed = parser.parse(
      filePath: path,
      source: File(path).readAsStringSync(),
    );
    final html = const MarkdownHtmlExporter().export(parsed);

    expect(html, contains('<title>Unsafe</title>'));
    expect(html, isNot(contains('<script>')));
    expect(html, contains('Unsafe'));
  });
}
