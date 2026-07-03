import 'dart:io';

import 'package:busymark/src/core/local_image_resolver.dart';
import 'package:busymark/src/core/path_utils.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_ast_adapter.dart';
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

  test('generates Unicode heading anchors for supported languages', () {
    final localizedHeadings = <String, ({String heading, String slug})>{
      'en': (heading: 'Getting Started', slug: 'getting-started'),
      'de': (heading: 'Überblick Änderungen', slug: 'überblick-änderungen'),
      'it': (heading: 'Novità rapide', slug: 'novità-rapide'),
      'no': (heading: 'Nøkkel område', slug: 'nøkkel-område'),
      'fr': (heading: 'État de l’art', slug: 'état-de-lart'),
      'ru': (heading: 'Быстрый старт', slug: 'быстрый-старт'),
      'uk': (heading: 'Швидкий старт', slug: 'швидкий-старт'),
      'pl': (heading: 'Zażółć gęślą jaźń', slug: 'zażółć-gęślą-jaźń'),
      'es': (heading: 'Guía rápida', slug: 'guía-rápida'),
      'pt': (heading: 'Visão geral', slug: 'visão-geral'),
      'ar': (heading: 'دليل البدء', slug: 'دليل-البدء'),
      'fa': (heading: 'راهنمای شروع', slug: 'راهنمای-شروع'),
      'hi': (heading: 'हिंदी दस्तावेज़', slug: 'हिंदी-दस्तावेज़'),
    };
    final source = localizedHeadings.entries
        .expand((entry) {
          final heading = entry.value.heading;
          final slug = entry.value.slug;
          return [
            '## $heading',
            '',
            '[${entry.key} raw](#$slug)',
            '[${entry.key} encoded](#${Uri.encodeComponent(slug)})',
            '',
          ];
        })
        .join('\n');

    final parsed = parser.parse(filePath: 'localized.md', source: source);
    final adapted = const MarkdownAstAdapter().parse(
      filePath: 'localized.md',
      source: source,
      mode: MarkdownMode.commonMark,
    );

    for (final MapEntry(key: locale, value: item)
        in localizedHeadings.entries) {
      expect(slugForHeading(item.heading), item.slug, reason: locale);
      expect(parsed.anchors, contains(item.slug), reason: locale);
      expect(
        adapted.blocks
            .where((block) => block.kind == BusyBlockKind.heading)
            .map((block) => block.attributes['id']),
        contains(item.slug),
        reason: locale,
      );
    }
    expect(
      parsed.diagnostics.map((item) => item.code),
      isNot(contains('markdown.link.unresolved-anchor')),
    );
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

  test('does not validate schemed URIs as local references', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source:
          '[Ftp](ftp://example.com/doc.md)\n'
          '[Tel](tel:+15551234567)\n'
          '[Custom](docs://topic/intro)\n'
          '[File](file:///tmp/topic.md)\n'
          '[Script](javascript:alert(1))\n'
          '![Remote](ftp://example.com/logo.png)\n'
          '![Inline](data:image/png;base64,AAAA)\n',
      workspaceRoot: '/tmp/busymark-workspace',
    );
    final codes = parsed.diagnostics.map((item) => item.code);

    expect(codes, isNot(contains('markdown.link.unresolved-target')));
    expect(codes, isNot(contains('markdown.image.missing-file')));
    expect(codes, contains('markdown.raw-html.unsafe'));
  });

  test('resolves home-relative local image references', () {
    final fakeHome = Directory.systemTemp.createTempSync(
      'busymark_home_image_',
    );
    try {
      final downloads = Directory(p.join(fakeHome.path, 'Downloads'))
        ..createSync();
      File(p.join(downloads.path, 'example.jpg')).writeAsBytesSync([0]);
      debugLocalImageHomeDirectoryOverride = fakeHome.path;
      addTearDown(() {
        debugLocalImageHomeDirectoryOverride = null;
      });

      final parsed = parser.parse(
        filePath: 'Untitled.md',
        source: '![Пример изображения](~/Downloads/example.jpg)\n',
      );

      expect(parsed.images.single.destination, '~/Downloads/example.jpg');
      expect(
        parsed.diagnostics.map((item) => item.code),
        isNot(contains('markdown.image.missing-file')),
      );
    } finally {
      debugLocalImageHomeDirectoryOverride = null;
      fakeHome.deleteSync(recursive: true);
    }
  });

  test(
    'derives diagnostic links and images from Markdown AST semantics',
    () async {
      final root = await Directory.systemTemp.createTemp('busymark_ast_links_');
      addTearDown(() => root.deleteSync(recursive: true));
      Directory(p.join(root.path, 'docs')).createSync();
      File(p.join(root.path, 'target.md')).writeAsStringSync('# Target\n');
      File(p.join(root.path, 'docs', 'a(b).md')).writeAsStringSync('# Paren\n');
      File(
        p.join(root.path, 'docs', 'angle target.md'),
      ).writeAsStringSync('# Angle\n');
      File(p.join(root.path, 'logo.png')).writeAsBytesSync([0]);
      final path = p.join(root.path, 'topic.md');

      final parsed = await parser.parseAsync(
        filePath: path,
        workspaceRoot: root.path,
        source:
            '# AST links\n\n'
            '[Nested [label]](target.md)\n'
            '[Titled](target.md "Existing target")\n'
            '[Paren](docs/a(b).md)\n'
            '[Angle](<docs/angle target.md> "Existing target")\n'
            '![Logo][logo-ref]\n'
            '[Missing][missing-ref]\n\n'
            '[logo-ref]: logo.png "Logo title"\n'
            '[missing-ref]: missing.md\n',
      );

      expect(
        parsed.links.map((item) => item.destination),
        containsAll([
          'target.md',
          'docs/a(b).md',
          'docs/angle%20target.md',
          'missing.md',
        ]),
      );
      expect(parsed.images.single.destination, 'logo.png');
      expect(
        parsed.diagnostics
            .where((item) => item.code == 'markdown.link.unresolved-target')
            .map((item) => item.args['targetPath']),
        ['missing.md'],
      );
      expect(
        parsed.diagnostics.map((item) => item.code),
        isNot(contains('markdown.image.missing-file')),
      );
    },
  );

  test(
    'normal Markdown image diagnostics stay within the workspace root',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'busymark_writerside_',
      );
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
        contains('markdown.image.missing-file'),
      );
    },
  );

  test(
    'local reference diagnostics allow absolute images but reject other escapes',
    () async {
      final workspace = await Directory.systemTemp.createTemp(
        'busymark-reference-root-',
      );
      final outside = await Directory.systemTemp.createTemp(
        'busymark-reference-outside-',
      );
      addTearDown(() => workspace.deleteSync(recursive: true));
      addTearDown(() => outside.deleteSync(recursive: true));
      final outsideMarkdown = File(p.join(outside.path, 'outside.md'))
        ..writeAsStringSync('# Secret\n');
      final outsideImage = File(p.join(outside.path, 'outside.png'))
        ..writeAsBytesSync([0]);
      await Link(p.join(workspace.path, 'linked')).create(outside.path);
      final active = File(p.join(workspace.path, 'index.md'));
      final source =
          '# Index\n\n'
          '[Parent](../${p.basename(outside.path)}/outside.md#secret)\n'
          '[Absolute](${outsideMarkdown.path}#secret)\n'
          '[Symlink](linked/outside.md#secret)\n'
          '![Parent](../${p.basename(outside.path)}/outside.png)\n'
          '![Absolute](${outsideImage.path})\n'
          '![Symlink](linked/outside.png)\n';

      final parsed = await parser.parseAsync(
        filePath: active.path,
        source: source,
        workspaceRoot: workspace.path,
      );
      final linkTargets = parsed.diagnostics
          .where((item) => item.code == 'markdown.link.unresolved-target')
          .map((item) => item.args['targetPath'])
          .toList();
      final missingImages = parsed.diagnostics
          .where((item) => item.code == 'markdown.image.missing-file')
          .map((item) => item.args['destination'])
          .toList();

      expect(
        linkTargets,
        containsAll([
          '../${p.basename(outside.path)}/outside.md',
          outsideMarkdown.path,
          'linked/outside.md',
        ]),
      );
      expect(
        missingImages,
        containsAll([
          '../${p.basename(outside.path)}/outside.png',
          'linked/outside.png',
        ]),
      );
      expect(missingImages, isNot(contains(outsideImage.path)));
    },
    skip: Platform.isWindows
        ? 'POSIX symlink behavior is required for this coverage.'
        : false,
  );

  test(
    'cross-linked Markdown anchor validation does not recurse forever',
    () async {
      final path = fixture('cycle_a.md');
      final parsed = await parser.parseAsync(
        filePath: path,
        source: File(path).readAsStringSync(),
        workspaceRoot: 'test/fixtures/markdown',
      );

      expect(
        parsed.diagnostics.map((item) => item.code),
        isNot(contains('markdown.link.unresolved-anchor')),
      );
    },
  );

  test('local link validation stays inside the workspace root', () async {
    final root = await Directory.systemTemp.createTemp('busymark-link-scope-');
    addTearDown(() => root.deleteSync(recursive: true));
    final workspace = Directory(p.join(root.path, 'workspace'))..createSync();
    final secret = File(p.join(root.path, 'secret.md'))
      ..writeAsStringSync('# Secret\n');
    final path = p.join(workspace.path, 'topic.md');

    final parsed = await parser.parseAsync(
      filePath: path,
      source: '[Secret](../${p.basename(secret.path)}#secret)\n',
      workspaceRoot: workspace.path,
    );

    expect(
      parsed.diagnostics.map((item) => item.code),
      contains('markdown.link.unresolved-target'),
    );
  });

  test(
    'local link validation does not read unsupported anchor targets',
    () async {
      final root = Directory.systemTemp.createTempSync('busymark-link-binary-');
      addTearDown(() => root.deleteSync(recursive: true));
      final binary = File(p.join(root.path, 'binary.bin'))
        ..writeAsBytesSync([0xff, 0xfe, 0xfd]);
      final path = p.join(root.path, 'topic.md');

      final parsed = await parser.parseAsync(
        filePath: path,
        source: '[Binary](${p.basename(binary.path)}#anchor)\n',
        workspaceRoot: root.path,
      );

      expect(
        parsed.diagnostics.map((item) => item.code),
        isNot(contains('markdown.link.unresolved-anchor')),
      );
    },
  );

  test(
    'local link validation does not read oversized Markdown targets',
    () async {
      final root = Directory.systemTemp.createTempSync('busymark-link-large-');
      addTearDown(() => root.deleteSync(recursive: true));
      final large = File(p.join(root.path, 'large.md'))
        ..writeAsBytesSync([0xff, ...List<int>.filled(2 * 1024 * 1024, 0x61)]);
      final path = p.join(root.path, 'topic.md');

      final parsed = await parser.parseAsync(
        filePath: path,
        source: '[Large](${p.basename(large.path)}#anchor)\n',
        workspaceRoot: root.path,
      );

      expect(
        parsed.diagnostics.map((item) => item.code),
        isNot(contains('markdown.link.unresolved-anchor')),
      );
    },
  );

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
