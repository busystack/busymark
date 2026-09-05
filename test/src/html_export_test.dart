import 'dart:io';
import 'package:busymark/src/export/html_export_models.dart';
import 'package:busymark/src/export/html_export_service.dart';
import 'package:busymark/src/export/html_export_assets.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late HtmlExportService service;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('busymark-html-test-');
    service = HtmlExportService(
      stylesheetLoader: () => File('assets/export/html.css').readAsString(),
    );
  });
  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });
  Future<HtmlExportResult> export(
    String source, {
    String name = 'document',
    bool overwrite = false,
    HtmlExportCancellationToken? token,
    HtmlExportService? exporter,
  }) => (exporter ?? service).exportMarkdown(
    MarkdownHtmlExportRequest(
      source: source,
      filePath: p.join(root.path, 'source.md'),
      workspaceRoot: root.path,
      destinationPath: p.join(root.path, '$name.html'),
      mode: MarkdownMode.gfm,
      overwrite: overwrite,
    ),
    cancellationToken: token,
  );

  test(
    'unsaved Markdown is a complete styled document with stable semantic anchors',
    () async {
      await File(
        p.join(root.path, 'source.md'),
      ).writeAsString('# Old disk text');
      const source = '''# Current title

## 日本語

[Jump](#日本語)

## Repeat

## Repeat

3. Outer
   - Nested **strong** and *emphasis*
4. Next

- [x] Done
- [ ] Pending

| Header | Number |
| :--- | ---: |
| Value | 10 |

```dart
<script>alert("x")</script>
  preserved
```

Footnote[^note] and again[^note].

<details><summary>Between notes</summary><p>Body</p></details>

[^note]: **Nested** note text.

[Outside](other.md)
''';
      final result = await export(source);
      final text = await File(result.entryPointPath).readAsString();
      final doc = html.parse(text);
      expect(text, startsWith('<!DOCTYPE html>'));
      expect(
        doc.querySelector('meta[charset]')!.attributes['charset'],
        'utf-8',
      );
      expect(doc.querySelectorAll('h1').length, 1);
      expect(doc.querySelector('title')!.text, 'Current title');
      expect(
        doc.querySelector('ol[start="3"] ul li')!.text,
        contains('Nested'),
      );
      expect(doc.querySelectorAll('input[disabled]').length, 2);
      expect(doc.querySelectorAll('input[checked]').length, 1);
      expect(doc.querySelectorAll('table thead th').length, 2);
      expect(
        doc.querySelector('pre code')!.text,
        contains('<script>alert("x")</script>\n  preserved'),
      );
      expect(doc.querySelectorAll('script'), isEmpty);
      expect(doc.getElementById('日本語'), isNotNull);
      expect(doc.getElementById('repeat-1'), isNotNull);
      expect(doc.querySelector('.footnotes strong')!.text, 'Nested');
      for (final a in doc.querySelectorAll('a[href^="#"]')) {
        expect(
          doc.getElementById(
            Uri.decodeComponent(a.attributes['href']!.substring(1)),
          ),
          isNotNull,
          reason: a.outerHtml,
        );
      }
      expect(
        result.warnings.any((w) => w.message.contains('outside this export')),
        isTrue,
      );
      expect(text, isNot(contains(root.path)));
      expect(result.assetsPath, isNull);
      expect(
        await File(p.join(root.path, 'source.md')).readAsString(),
        '# Old disk text',
      );
    },
  );

  test(
    'raw disclosures, definitions and spans survive with structural sanitization',
    () async {
      final result = await export('''# HTML

<details open><summary>More &amp; less</summary><p>Body <strong>bold</strong></p><dl><dt>Term</dt><dd><p>Description</p></dd></dl></details>

<table><caption>Values</caption><tr><th colspan="2">Group</th></tr><tr><td rowspan="2">A</td><td>B</td></tr><tr><td>C</td></tr></table>

<script>window.evil = true</script>

<p onclick="alert(1)"><a href="javascript:alert(2)">Unsafe</a></p>
''');
      final doc = html.parse(await File(result.entryPointPath).readAsString());
      expect(
        doc.querySelector('article details[open] > summary')!.text,
        'More & less',
      );
      expect(doc.querySelector('dl dd p')!.text, 'Description');
      expect(doc.querySelector('th[colspan="2"]'), isNotNull);
      expect(doc.querySelector('td[rowspan="2"]'), isNotNull);
      expect(doc.querySelector('script'), isNull);
      expect(doc.querySelector('[onclick]'), isNull);
      expect(doc.querySelector('a[href^="javascript"]'), isNull);
      expect(doc.body!.text, contains('window.evil'));
      expect(result.warnings, isNotEmpty);
    },
  );

  test(
    'content-addressed assets relocate, deduplicate and reject symlink escapes',
    () async {
      const svg =
          '<svg xmlns="http://www.w3.org/2000/svg" width="30" height="20"><rect width="30" height="20" fill="blue"/></svg>';
      await File(p.join(root.path, 'one.svg')).writeAsString(svg);
      await File(p.join(root.path, 'two.svg')).writeAsString(svg);
      final outside = await Directory.systemTemp.createTemp(
        'busymark-html-outside-',
      );
      addTearDown(() => outside.delete(recursive: true));
      await File(p.join(outside.path, 'secret.svg')).writeAsString(svg);
      await Link(
        p.join(root.path, 'escape.svg'),
      ).create(p.join(outside.path, 'secret.svg'));
      final result = await export(
        '# Assets\n\n![One](one.svg) ![Two](two.svg) ![Escape](escape.svg) ![Remote](https://example.com/x.png)',
      );
      final doc = html.parse(await File(result.entryPointPath).readAsString());
      final images = doc.querySelectorAll('img');
      expect(images.length, 2);
      expect(images[0].attributes['src'], images[1].attributes['src']);
      expect(
        result.warnings.where((w) => w.code == 'asset.unavailable').length,
        2,
      );
      expect(
        await Directory(
          result.assetsPath!,
        ).list().where((f) => f.path.endsWith('.svg')).length,
        1,
      );
      final relocated = await Directory.systemTemp.createTemp(
        'busymark-html-relocated-',
      );
      addTearDown(() => relocated.delete(recursive: true));
      await File(
        result.entryPointPath,
      ).rename(p.join(relocated.path, 'document.html'));
      await Directory(
        result.assetsPath!,
      ).rename(p.join(relocated.path, 'document.assets'));
      expect(
        await File(
          p.join(
            relocated.path,
            Uri.decodeComponent(images.first.attributes['src']!),
          ),
        ).exists(),
        isTrue,
      );
    },
  );

  test('untrusted metadata and data URLs cannot create active HTML', () async {
    final result = await export('''---
title: <img src=x onerror=alert(1)>
lang: en-US
dir: rtl
head: <script>alert(2)</script>
css: https://evil.invalid/style.css
---
# Safe heading

[Unsafe](javascript:alert(1))

<img src="data:image/svg+xml,evil" onerror="alert(2)">

<form action="https://evil.invalid"><input name="secret"></form>
''');
    final text = await File(result.entryPointPath).readAsString();
    final doc = html.parse(text);
    expect(doc.querySelector('title')!.text, '<img src=x onerror=alert(1)>');
    expect(doc.documentElement!.attributes['dir'], 'rtl');
    expect(
      doc.querySelectorAll('script,form,input,head img,head link,[onerror]'),
      isEmpty,
    );
    expect(
      doc
          .querySelectorAll('[href],[src]')
          .any(
            (e) => (e.attributes['href'] ?? e.attributes['src']!).startsWith(
              'data:',
            ),
          ),
      isFalse,
    );
    expect(doc.querySelector('style')!.text, isNot(contains('evil.invalid')));
    expect(
      doc.querySelector('meta[http-equiv]')!.attributes['content'],
      contains("script-src 'none'"),
    );
    expect(result.warnings, isNotEmpty);
  });

  test('unsafe SVG and CSS never reach exported assets', () {
    for (final inner in [
      '<script>alert(1)</script>',
      '<use href="https://evil/x.svg"/>',
      '<style>path{fill:url(https://evil/x)}</style>',
      '<rect onload="alert(1)"/>',
      '<animate attributeName="href" to="https://evil"/>',
    ]) {
      expect(
        () => HtmlExportAssets.safeSvg(
          '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10">$inner</svg>',
        ),
        throwsA(isA<HtmlExportException>()),
      );
    }
  });

  test(
    'overwrite refusal, cancellation and rendering failure preserve previous HTML',
    () async {
      final result = await export('# Previous');
      final previous = await File(result.entryPointPath).readAsBytes();
      await expectLater(
        export('# Replacement'),
        throwsA(isA<HtmlExportException>()),
      );
      final token = HtmlExportCancellationToken()..cancel();
      await expectLater(
        export('# Replacement', overwrite: true, token: token),
        throwsA(isA<HtmlExportException>()),
      );
      expect(await File(result.entryPointPath).readAsBytes(), previous);
      final failed = await export(
        '# Fallback\n\n```mermaid\ngraph LR; A-->B\n```\n\n\$x^2\$',
        name: 'failed',
      );
      expect(failed.warnings.any((w) => w.code == 'render.failed'), isTrue);
      final doc = html.parse(await File(failed.entryPointPath).readAsString());
      expect(doc.querySelector('pre code')!.text, contains('graph LR'));
      expect(
        await root
            .list()
            .where((f) => p.basename(f.path).startsWith('.busymark-html-'))
            .length,
        0,
      );
    },
  );

  test(
    'metadata title remains separate from a formatted Markdown title heading',
    () async {
      final result = await export(
        '---\ntitle: Page metadata\n---\n# Visible *heading*',
      );
      final doc = html.parse(await File(result.entryPointPath).readAsString());
      expect(doc.querySelector('title')!.text, 'Page metadata');
      expect(doc.querySelectorAll('h1').length, 1);
      expect(doc.querySelector('h1 em')!.text, 'heading');
    },
  );

  test('UTF-8 byte limits are enforced', () async {
    final limited = HtmlExportService(
      limits: const HtmlExportLimits(sourceBytes: 8),
    );
    await expectLater(
      export('日本語', exporter: limited),
      throwsA(isA<HtmlExportException>()),
    );
  });

  test('Writerside produces linked pages, hidden topics, WIP and start copy', () async {
    Future<void> put(String name, String source) async {
      final f = File(p.join(root.path, name));
      await f.parent.create(recursive: true);
      await f.writeAsString(source);
    }

    await put(
      'writerside.cfg',
      '<ihp version="2.0"><topics dir="topics"/><images dir="images"/><instance src="guide.tree"/></ihp>',
    );
    await put(
      'guide.tree',
      '<instance-profile id="guide" name="Guide" start-page="Start.topic"><toc-element topic="Start.topic" toc-title="Home"><toc-element topic="Hidden.topic" hidden="true"/><toc-element topic="Draft.topic" wip="true"/></toc-element><toc-element topic="Draft.topic"/></instance-profile>',
    );
    await put(
      'topics/Start.topic',
      '<topic id="Start" title="Start"><title instance="guide">Selected title</title><web-file-name>Start Here.html</web-file-name><p>Welcome</p><a href="Hidden.topic" anchor="same"/><a href="Draft.topic"/><tabs><tab title="A"><p>Alpha</p></tab><tab title="B"><p>Beta</p></tab></tabs><chapter title="Section" id="same"><p>Own anchor</p></chapter></topic>',
    );
    await put(
      'topics/Hidden.topic',
      '<topic id="Hidden" title="Hidden"><chapter id="same" title="Hidden section"><p>Secret content</p></chapter></topic>',
    );
    await put(
      'topics/Draft.topic',
      '<topic id="Draft" title="Draft"><p>Draft content</p></topic>',
    );
    final destination = p.join(root.path, 'site');
    final result = await service.exportWriterside(
      projectRoot: root.path,
      moduleRoot: root.path,
      instanceId: 'guide',
      destinationPath: destination,
    );
    expect(result.pageCount, 3);
    final index = await File(result.entryPointPath).readAsString();
    expect(
      index,
      await File(p.join(destination, 'Start Here.html')).readAsString(),
    );
    final doc = html.parse(index);
    expect(doc.querySelector('h1')!.text, 'Selected title');
    expect(doc.querySelector('a[href="hidden.html#same"]'), isNotNull);
    expect(
      doc.querySelectorAll('.instance-nav a').map((a) => a.text).join(' '),
      isNot(contains('Hidden')),
    );
    expect(doc.querySelectorAll('.tab-panel').length, 2);
    expect(
      await File(p.join(destination, 'draft.html')).readAsString(),
      contains('Work in progress'),
    );
    await service.exportWriterside(
      projectRoot: root.path,
      moduleRoot: root.path,
      instanceId: 'guide',
      destinationPath: destination,
      overwrite: true,
    );
    await File(p.join(destination, 'mine.txt')).writeAsString('keep');
    await expectLater(
      service.exportWriterside(
        projectRoot: root.path,
        moduleRoot: root.path,
        instanceId: 'guide',
        destinationPath: destination,
        overwrite: true,
      ),
      throwsA(isA<HtmlExportException>()),
    );
    expect(await File(p.join(destination, 'mine.txt')).readAsString(), 'keep');
    expect(await File(result.entryPointPath).readAsString(), index);
  });

  test('official conformance fixture exports as individual pages', () async {
    final source = p.absolute('test/fixtures/writerside/conformance_project');
    final cfg = await File(p.join(source, 'conformance.tree')).exists();
    expect(cfg, isTrue);
    final result = await service.exportWriterside(
      projectRoot: source,
      moduleRoot: source,
      instanceId: 'conformance',
      destinationPath: p.join(root.path, 'official'),
    );
    expect(result.pageCount, greaterThan(1));
    expect(await File(result.entryPointPath).exists(), isTrue);
  });
}
