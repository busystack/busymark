import 'dart:convert';
import 'dart:io';
import 'package:busymark/src/export/html_export_models.dart';
import 'package:busymark/src/export/html_export_service.dart';
import 'package:busymark/src/export/html_export_styles.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  final service = HtmlExportService(
    stylesheetLoader: () => File('assets/export/html.css').readAsString(),
  );
  setUp(() async {
    root = await Directory.systemTemp.createTemp('html-options-');
  });
  tearDown(() => root.delete(recursive: true));
  Future<HtmlExportResult> export(
    HtmlExportOptions options, {
    String source = '# Title\n\n## One\n\n### Child\n\n## Two',
    bool overwrite = false,
  }) => service.exportMarkdown(
    MarkdownHtmlExportRequest(
      source: source,
      filePath: p.join(root.path, 'source.md'),
      workspaceRoot: root.path,
      destinationPath: p.join(root.path, 'output.html'),
      options: options,
      overwrite: overwrite,
    ),
  );

  test(
    'TOC and numbering use the semantic hierarchy and preserve anchor IDs',
    () async {
      final result = await export(
        const HtmlExportOptions(
          content: ExportContentOptions(
            includeToc: true,
            tocDepth: 2,
            numberHeadings: true,
          ),
        ),
      );
      final doc = html.parse(await File(result.entryPointPath).readAsString());
      expect(
        doc
            .querySelectorAll('article h1, article h2, article h3')
            .map((e) => e.text),
        ['1 Title', '1.1 One', '1.1.1 Child', '1.2 Two'],
      );
      expect(doc.querySelectorAll('.outline a').map((e) => e.text), [
        '1 Title',
        '1.1 One',
        '1.2 Two',
      ]);
      expect(
        doc.querySelectorAll('.outline > details > ul > li > ul > li'),
        hasLength(2),
      );
      expect(doc.getElementById('one')!.localName, 'h2');
      final no = await export(
        const HtmlExportOptions(content: ExportContentOptions()),
        overwrite: true,
      );
      final none = html.parse(await File(no.entryPointPath).readAsString());
      expect(none.querySelector('.outline'), isNull);
      expect(none.querySelector('.heading-number'), isNull);
    },
  );

  for (final theme in HtmlExportTheme.values) {
    test(
      '$theme emits complete color variables, responsive width and metadata',
      () async {
        final result = await export(
          HtmlExportOptions(
            theme: theme,
            bodyTypography: ExportBodyTypography.serif,
            baseFontSize: 21,
            contentMaxWidth: 1050,
            accentColor: '#123456',
          ),
          source:
              '---\ntitle: "Safe <title>"\nauthors: "A & B"\ndescription: "An <example>"\nlang: fr-CA\n---\n# Content',
        );
        final doc = html.parse(
          await File(result.entryPointPath).readAsString(),
        );
        expect(doc.querySelector('title')!.text, 'Safe <title>');
        expect(doc.documentElement!.attributes['lang'], 'fr-CA');
        expect(
          doc.querySelector('meta[name="author"]')!.attributes['content'],
          'A & B',
        );
        expect(
          doc.querySelector('meta[name="description"]')!.attributes['content'],
          'An <example>',
        );
        expect(doc.querySelector('meta[name="viewport"]'), isNotNull);
        final css = doc.querySelector('style')!.text;
        expect(css, contains('--body-size:21.0px'));
        expect(css, contains('--content-width:1050.0px'));
        expect(css, contains('max-width:var(--content-width'));
        expect(css, contains('--accent:#123456'));
        expect(css, contains('"Noto Serif",Georgia,serif'));
        expect(
          css.contains('@media(prefers-color-scheme:dark)'),
          theme == HtmlExportTheme.automatic,
        );
        expect(
          css,
          contains(
            'color-scheme:${theme == HtmlExportTheme.dark ? 'dark' : 'light'}',
          ),
        );
      },
    );
  }

  test(
    'custom CSS follows generated rules and is captured before processing',
    () async {
      final css = File(p.join(root.path, 'custom.css'));
      await css.writeAsString(
        'h1 { color: #665544; } @media print { p { font-size: 12pt; } }',
      );
      final result = await service.exportMarkdown(
        MarkdownHtmlExportRequest(
          source: '# Styled',
          filePath: p.join(root.path, 'source.md'),
          workspaceRoot: root.path,
          destinationPath: p.join(root.path, 'output.html'),
          options: HtmlExportOptions(customCssPath: css.path),
        ),
        onProgress: (_, _) {
          css.writeAsStringSync('h1 { color: red; }');
        },
      );
      final doc = html.parse(await File(result.entryPointPath).readAsString());
      expect(
        doc.querySelector('style')!.text.trim(),
        endsWith(
          'h1 { color: #665544; } @media print { p { font-size: 12pt; } }',
        ),
      );
      expect(
        doc.querySelector('meta[http-equiv]')!.attributes['content'],
        contains("style-src 'sha256-"),
      );
      expect(
        await File(result.entryPointPath).readAsString(),
        isNot(contains(css.path)),
      );
    },
  );

  test(
    'CSS rejects unsafe URLs, imports, HTML, unreadable and oversized files',
    () async {
      for (final css in [
        '@import "https://example.com/a.css";',
        'p { background: url(https://example.com/a.png) }',
        'p { background: url(local.png) }',
        '</style><script>alert(1)</script>',
        r'p { background: u\72l(https://example.com) }',
        'p { width: expression(alert(1)); }',
        'p { background: image-set("https://example.com/a.png" 1x); }',
      ]) {
        expect(
          () => HtmlExportStyles.validateCss(css),
          throwsA(isA<ExportOptionsException>()),
          reason: css,
        );
      }
      final path = p.join(root.path, 'missing.css');
      await expectLater(
        export(HtmlExportOptions(customCssPath: path)),
        throwsA(isA<ExportOptionsException>()),
      );
      await File(
        path,
      ).writeAsString('/*${'é' * HtmlExportOptions.maximumCssBytes}*/');
      await expectLater(
        export(HtmlExportOptions(customCssPath: path)),
        throwsA(isA<ExportOptionsException>()),
      );
      expect(await File(p.join(root.path, 'output.html')).exists(), false);
    },
  );

  test(
    'repeated embedded assets are bounded before publication and keep old output',
    () async {
      final asset = File(p.join(root.path, 'large.svg'));
      await asset.writeAsString(
        '<svg xmlns="http://www.w3.org/2000/svg" width="50" height="50">${List.filled(200, '<rect width="1" height="1"/>').join()}</svg>',
      );
      final destination = File(p.join(root.path, 'old.html'));
      await destination.writeAsString('Previous export');
      await expectLater(
        HtmlExportService(
          limits: const HtmlExportLimits(sourceBytes: 4096),
          stylesheetLoader: () async => '',
        ).exportMarkdown(
          MarkdownHtmlExportRequest(
            source:
                '# Images\n\n${List.filled(30, '![Image](large.svg)').join('\n\n')}',
            filePath: p.join(root.path, 'source.md'),
            workspaceRoot: root.path,
            destinationPath: destination.path,
            overwrite: true,
            options: const HtmlExportOptions(
              packaging: HtmlPackaging.singleFile,
            ),
          ),
        ),
        throwsA(
          isA<HtmlExportException>().having(
            (e) => e.message,
            'diagnostic',
            contains('output byte limit'),
          ),
        ),
      );
      expect(await destination.readAsString(), 'Previous export');
      expect(
        await root
            .list()
            .where((e) => p.basename(e.path).startsWith('.busymark-html-'))
            .length,
        0,
      );
    },
  );

  for (final packaging in HtmlPackaging.values) {
    test(
      '$packaging packages validated assets without source paths or fetching',
      () async {
        const svg =
            '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20"><rect width="20" height="20" fill="red"/></svg>';
        await File(p.join(root.path, 'image.svg')).writeAsString(svg);
        final result = await export(
          HtmlExportOptions(packaging: packaging),
          source:
              '# Assets\n\n![Local](image.svg)\n\n![Remote](https://example.invalid/image.png)',
        );
        final text = await File(result.entryPointPath).readAsString();
        final doc = html.parse(text);
        final url = doc.querySelector('img')!.attributes['src']!;
        if (packaging == HtmlPackaging.singleFile) {
          expect(url, startsWith('data:image/svg+xml;base64,'));
          expect(
            utf8.decode(base64.decode(url.split(',').last)),
            contains('<rect'),
          );
          expect(result.assetsPath, isNull);
          expect(
            await Directory(p.join(root.path, 'output.assets')).exists(),
            false,
          );
        } else {
          expect(url, startsWith('output.assets/'));
          expect(await File(p.join(root.path, url)).exists(), true);
          expect(result.assetsPath, isNotNull);
        }
        expect(text, isNot(contains(root.path)));
        expect(doc.querySelectorAll('img'), hasLength(1));
        expect(
          result.warnings.map((w) => w.code),
          contains('asset.unavailable'),
        );
        expect(doc.querySelector('script'), isNull);
      },
    );
  }
}
