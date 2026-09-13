import 'dart:io';

import 'package:busymark/src/export/html_export_models.dart';
import 'package:busymark/src/export/html_export_service.dart';
import 'package:busymark/src/export/markdown_export_assets.dart';
import 'package:busymark/src/export/markdown_export_document.dart';
import 'package:busymark/src/export/markdown_export_mapper.dart';
import 'package:busymark/src/export/markdown_pdf_export_service.dart';
import 'package:busymark/src/export/markdown_pdf_models.dart';
import 'package:busymark/src/export/markdown_visualization_export.dart';
import 'package:busymark/src/export/typst_compiler.dart';
import 'package:busymark/src/export/writerside_pdf_export_service.dart';
import 'package:busymark/src/export/writerside_pdf_models.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/visualization/visualization_cache.dart';
import 'package:busymark/src/visualization/visualization_coordinator.dart';
import 'package:busymark/src/visualization/visualization_models.dart';
import 'package:busymark/src/visualization/visualization_renderer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late String module;
  final compiler = Platform.environment['BUSYMARK_TYPST_PATH'];
  final pdfAvailable =
      compiler != null &&
      File(compiler).existsSync() &&
      File('/usr/bin/pdftotext').existsSync();
  setUp(() async {
    root = await Directory.systemTemp.createTemp('export-review-');
    module = p.join(root.path, 'Writerside');
  });
  tearDown(() => root.delete(recursive: true));
  Future<void> put(String name, String source) async {
    final file = File(p.join(root.path, name));
    await file.parent.create(recursive: true);
    await file.writeAsString(source);
  }

  Future<void> configure(String nodes, {String extra = ''}) async {
    await put(
      'Writerside/writerside.cfg',
      '<ihp version="2.0"><module name="main"/><topics dir="topics"/><images dir="images"/><instance src="guide.tree"/>$extra</ihp>',
    );
    final start = RegExp(r'topic="([^"]+)"').firstMatch(nodes)?.group(1);
    await put(
      'Writerside/guide.tree',
      '<instance-profile id="guide" name="Guide" ${start == null ? '' : 'start-page="$start"'}>$nodes</instance-profile>',
    );
  }

  Future<BusyDocument> compose() async {
    final recording = _RecordingExporter();
    await WritersidePdfExportService(markdownExporter: recording).export(
      WritersidePdfExportRequest(
        moduleRoot: module,
        projectRoot: root.path,
        instanceId: 'guide',
        destinationPath: p.join(root.path, 'out.pdf'),
        overwrite: false,
      ),
    );
    return recording.document!;
  }

  final htmlService = HtmlExportService(
    stylesheetLoader: () => File('assets/export/html.css').readAsString(),
  );
  Future<HtmlExportResult> exportHtml(String source) =>
      htmlService.exportMarkdown(
        MarkdownHtmlExportRequest(
          source: source,
          filePath: p.join(root.path, 'source.md'),
          workspaceRoot: root.path,
          destinationPath: p.join(root.path, 'out.html'),
          options: const HtmlExportOptions(
            content: ExportContentOptions(includeToc: true),
          ),
        ),
      );

  for (final xml in [false, true]) {
    test(
      'Writerside diagram and paragraph collisions retain each occurrence (XML=$xml)',
      () async {
        final ext = xml ? 'topic' : 'md';
        await configure(
          '<toc-element topic="one.$ext"/><toc-element topic="two.$ext"/><toc-element topic="three.$ext"/>',
        );
        for (final name in ['one', 'two', 'three']) {
          final body = name == 'three'
              ? 'PARAGRAPH_SENTINEL'
              : 'graph LR; $name-->end';
          await put(
            'Writerside/topics/$name.$ext',
            xml
                ? '<topic id="$name" title="Topic">${name == 'three' ? '<p>$body</p>' : '<code-block lang="mermaid">$body</code-block>'}</topic>'
                : '# Topic\n\n${name == 'three' ? body : '```mermaid\n$body\n```'}',
          );
        }
        final document = await compose();
        final ids = _blocks(document.blocks).map((b) => b.id).toList();
        expect(ids.toSet(), hasLength(ids.length));
        final renderer = _DiagramRenderer();
        final coordinator = VisualizationCoordinator(
          renderers: [renderer],
          cache: VisualizationCache(
            diskRoot: Directory(p.join(root.path, 'cache')),
          ),
        );
        addTearDown(coordinator.dispose);
        final prepared =
            await MarkdownVisualizationExportRenderer(
              coordinator: coordinator,
            ).prepare(
              document: document,
              exportRoot: root,
              documentPath: document.filePath,
              workspaceRoot: module,
              cancellationToken: MarkdownPdfCancellationToken(),
            );
        expect(renderer.requests.map((r) => r.blockKey).toSet(), hasLength(2));
        expect(
          renderer.requests.map((r) => r.source),
          containsAll(['graph LR; one-->end', 'graph LR; two-->end']),
        );
        expect(prepared.blockOverrides, hasLength(2));
        expect(
          prepared.blockOverrides.values
              .map((b) => b.attributes['asset'])
              .toSet(),
          hasLength(2),
        );
        final mapped = const MarkdownExportMapper().map(
          document,
          blockOverrides: prepared.blockOverrides,
        );
        expect(
          mapped.blocks.where(
            (b) => b.kind == MarkdownExportBlockKind.visualization,
          ),
          hasLength(2),
        );
        expect(
          mapped.blocks.expand((b) => b.inlines).map((i) => i.text),
          contains('PARAGRAPH_SENTINEL'),
        );
      },
    );
  }
  test('repeated includes receive distinct nested occurrence IDs', () async {
    await configure('<toc-element topic="main.topic"/>');
    await put(
      'Writerside/topics/main.topic',
      '<topic id="main" title="Main"><include from="snippet.topic" element-id="s"/><include from="snippet.topic" element-id="s"/></topic>',
    );
    await put(
      'Writerside/topics/snippet.topic',
      '<topic id="snippet" title="Snippet"><snippet id="s"><list><li><p>Repeated</p></li></list></snippet></topic>',
    );
    final blocks = _blocks((await compose()).blocks).toList();
    expect(blocks.map((b) => b.id).toSet(), hasLength(blocks.length));
    expect(
      blocks.where((b) => b.plainText == 'Repeated').length,
      greaterThanOrEqualTo(2),
    );
  });
  test('mapper cannot substitute a diagram for a colliding paragraph', () {
    final result = const MarkdownExportMapper().map(
      BusyDocument(
        filePath: 'x',
        mode: MarkdownMode.commonMark,
        blocks: const [
          BusyBlock(
            id: 'b0',
            kind: BusyBlockKind.paragraph,
            inlines: [BusyInline(kind: BusyInlineKind.text, text: 'Keep me')],
          ),
        ],
      ),
      blockOverrides: const {
        'b0': MarkdownExportBlock(kind: MarkdownExportBlockKind.visualization),
      },
    );
    expect(result.blocks.single.kind, MarkdownExportBlockKind.paragraph);
    expect(result.blocks.single.inlines.single.text, 'Keep me');
  });

  test(
    'Writerside rejects outside file URIs and symlinks while staging shared-module images',
    () async {
      const outside =
          '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"><text>PRIVATE_SENTINEL</text></svg>';
      const safe =
          '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"><rect width="10" height="10"/></svg>';
      await put('private.svg', outside);
      await put('Writerside/images/safe.svg', safe);
      await Link(
        p.join(module, 'images/escape.svg'),
      ).create(p.join(root.path, 'private.svg'));
      await put(
        'Shared/writerside.cfg',
        '<ihp version="2.0"><module name="shared"/><topics dir="topics"/><images dir="images"/></ihp>',
      );
      await put('Shared/images/shared.svg', safe.replaceFirst('10', '20'));
      await put(
        'Shared/topics/library.topic',
        '<topic id="library" title="Library"><snippet id="s"><img src="${Uri.file(p.join(root.path, 'Shared/images/shared.svg'))}"/></snippet></topic>',
      );
      await configure('<toc-element topic="main.topic"/>');
      await put(
        'Writerside/topics/main.topic',
        '<topic id="main" title="Main"><img src="${Uri.file(p.join(root.path, 'private.svg'))}"/><img src="${Uri.file(p.join(module, 'images/escape.svg'))}"/><img src="${Uri.file(p.join(module, 'images/safe.svg'))}"/><include origin="shared" from="library.topic" element-id="s"/></topic>',
      );
      final document = const MarkdownExportMapper().map(await compose());
      final stage = await Directory(p.join(root.path, 'stage')).create();
      final assets = await const MarkdownExportAssetStager().stage(
        document: document,
        exportRoot: stage,
        activeFilePath: p.join(module, 'topics/main.topic'),
        workspaceRoot: module,
        cancellationToken: MarkdownPdfCancellationToken(),
      );
      expect(assets.assets, hasLength(2));
      expect(assets.warnings, hasLength(2));
      for (final path in assets.assets.values) {
        expect(
          await File(p.join(stage.path, path)).readAsString(),
          isNot(contains('PRIVATE_SENTINEL')),
        );
      }
    },
  );

  for (final onlyReference in [false, true]) {
    test(
      'cross-instance navigation is not published (reference only=$onlyReference)',
      () async {
        await configure(
          '${onlyReference ? '' : '<toc-element topic="own.topic"/>'}<toc-element ref="foreign.topic" in="other"/>',
          extra: '<instance src="other.tree"/>',
        );
        await put(
          'Writerside/other.tree',
          '<instance-profile id="other" name="Other" start-page="foreign.topic"><toc-element topic="foreign.topic"/></instance-profile>',
        );
        await put(
          'Writerside/topics/own.topic',
          '<topic id="own" title="Own"><p>OWN_CONTENT</p></topic>',
        );
        await put(
          'Writerside/topics/foreign.topic',
          '<topic id="foreign" title="Foreign"><p>FOREIGN_CONTENT</p></topic>',
        );
        if (onlyReference) {
          await expectLater(
            compose(),
            throwsA(
              isA<WritersidePdfExportException>().having(
                (e) => e.detail,
                'detail',
                contains('no exportable topics'),
              ),
            ),
          );
        } else {
          final text = _blocks(
            (await compose()).blocks,
          ).map((b) => b.plainText).join(' ');
          expect(text, contains('OWN_CONTENT'));
          expect(text, isNot(contains('FOREIGN_CONTENT')));
        }
      },
    );
  }

  for (final first in [true, false]) {
    for (final inline in [false, true]) {
      test(
        'explicit ${inline ? 'inline' : 'raw'} anchor is reserved (first=$first)',
        () async {
          final raw = inline
              ? 'Paragraph <code id="intro">Explicit target</code>.'
              : '<div id="intro">Explicit target</div>';
          final result = await exportHtml(
            '${first ? '$raw\n\n# Intro' : '# Intro\n\n$raw'}\n\n[Authored link](#intro)',
          );
          final doc = html.parse(
            await File(result.entryPointPath).readAsString(),
          );
          expect(
            doc.getElementById('intro')!.localName,
            inline ? 'code' : 'div',
          );
          final tocLink = doc.querySelector('.outline a')!;
          final target = doc.getElementById(
            tocLink.attributes['href']!.substring(1),
          )!;
          expect(target.localName, 'h1');
          expect(target.text, 'Intro');
          expect(doc.querySelector('article a')!.attributes['href'], '#intro');
        },
      );
    }
  }
  test('collapsible headings keep numbering and actual outline order', () async {
    await configure('<toc-element topic="main.topic"/>');
    await put(
      'Writerside/topics/main.topic',
      '<topic id="main" title="Main"><chapter id="before" title="Before"><p>Before text</p></chapter><chapter id="fold" title="Fold" collapsible="true"><p>Fold text</p></chapter><chapter id="after" title="After"><p>After text</p></chapter></topic>',
    );
    final result = await htmlService.exportWriterside(
      projectRoot: root.path,
      moduleRoot: module,
      instanceId: 'guide',
      destinationPath: p.join(root.path, 'site'),
      options: const HtmlExportOptions(
        content: ExportContentOptions(includeToc: true, numberHeadings: true),
      ),
    );
    final doc = html.parse(await File(result.entryPointPath).readAsString());
    expect(doc.querySelectorAll('.outline a').map((a) => a.text), [
      '1 Main',
      '1.1 Before',
      '1.2 Fold',
      '1.3 After',
    ]);
    expect(doc.getElementById('fold')!.localName, 'details');
    expect(doc.getElementById('fold')!.querySelector('h2')!.text, '1.2 Fold');
    expect(doc.querySelector('.outline a[href="#fold"]'), isNotNull);
  });
  for (final raw in [false, true]) {
    for (final destination in ['#%FF', '%FF.md', 'file%FF.txt']) {
      test(
        'malformed encoded link becomes a source warning ($raw $destination)',
        () async {
          final result = await exportHtml(
            '# Title\n\n${raw ? '<p><a href="$destination">Keep visible</a></p>' : '[Keep visible]($destination)'}',
          );
          final doc = html.parse(
            await File(result.entryPointPath).readAsString(),
          );
          expect(doc.querySelector('article')!.text, contains('Keep visible'));
          expect(doc.querySelectorAll('article a[href]'), isEmpty);
          expect(
            result.warnings,
            contains(
              isA<HtmlExportWarning>()
                  .having((w) => w.code, 'code', 'link.unresolved')
                  .having(
                    (w) => w.sourcePath,
                    'source',
                    p.join(root.path, 'source.md'),
                  )
                  .having((w) => w.line, 'line', 3),
            ),
          );
        },
      );
    }
  }

  test(
    'combined Writerside PDF keeps diagrams and scoped notes without reading an outside image',
    () async {
      await configure(
        '<toc-element topic="one.md"/><toc-element topic="two.md"/><toc-element topic="three.md"/>',
      );
      await put(
        'private.svg',
        '<svg xmlns="http://www.w3.org/2000/svg" width="120" height="20"><text y="15">PRIVATE_SENTINEL</text></svg>',
      );
      for (final name in ['one', 'two', 'three']) {
        await put(
          'Writerside/topics/$name.md',
          '# Topic $name\n\n${name == 'three' ? 'PARAGRAPH_SENTINEL' : '```mermaid\ngraph LR; $name-->end\n```'}\n\nReference[^note] and repeated[^note].\n\n[^note]: Definition for $name retained.\n\n${name == 'three' ? '![Private](${Uri.file(p.join(root.path, 'private.svg'))})' : ''}',
        );
      }
      final renderer = _DiagramRenderer();
      final coordinator = VisualizationCoordinator(
        renderers: [renderer],
        cache: VisualizationCache(
          diskRoot: Directory(p.join(root.path, 'cache')),
        ),
      );
      addTearDown(coordinator.dispose);
      final path = p.join(root.path, 'combined.pdf');
      final result =
          await WritersidePdfExportService(
            markdownExporter: MarkdownPdfExportService(
              compilerLocator: TypstCompilerLocator(
                environment: {'BUSYMARK_TYPST_PATH': compiler!},
              ),
              templateLoader: () =>
                  File('assets/export/markdown.typ').readAsString(),
              visualizationRenderer: MarkdownVisualizationExportRenderer(
                coordinator: coordinator,
              ),
            ),
          ).export(
            WritersidePdfExportRequest(
              moduleRoot: module,
              projectRoot: root.path,
              instanceId: 'guide',
              destinationPath: path,
              overwrite: false,
            ),
          );
      final extracted = await Process.run('/usr/bin/pdftotext', [
        '-layout',
        path,
        '-',
      ]);
      expect(extracted.exitCode, 0, reason: '${extracted.stderr}');
      final text = extracted.stdout as String;
      expect(text, contains('PARAGRAPH_SENTINEL'));
      expect(text, isNot(contains('PRIVATE_SENTINEL')));
      expect(
        renderer.requests.map((r) => r.source),
        containsAll(['graph LR; one-->end', 'graph LR; two-->end']),
      );
      for (final name in ['one', 'two', 'three']) {
        expect('Definition for $name retained.'.allMatches(text), hasLength(1));
      }
      expect(
        result.warnings.map((w) => w.code),
        contains(MarkdownPdfWarningCode.imageUnsupported),
      );
    },
    skip: !pdfAvailable,
  );

  test(
    'ordinary Markdown footnotes compile with retained definitions and repeated references',
    () async {
      final path = p.join(root.path, 'footnotes.pdf');
      final result =
          await MarkdownPdfExportService(
            compilerLocator: TypstCompilerLocator(
              environment: {'BUSYMARK_TYPST_PATH': compiler!},
            ),
            templateLoader: () =>
                File('assets/export/markdown.typ').readAsString(),
          ).export(
            MarkdownPdfExportRequest(
              source:
                  '# Notes\n\nFirst[^note], repeated[^note], and another[^other].\n\n[^note]: Complete **first definition** with `code`.\n\n    Second paragraph retained.\n\n[^other]: Other definition retained.\n',
              filePath: p.join(root.path, 'source.md'),
              workspaceRoot: root.path,
              destinationPath: path,
              mode: MarkdownMode.gfm,
              options: const PdfExportOptions(),
              overwrite: false,
            ),
          );
      final extracted = await Process.run('/usr/bin/pdftotext', [
        '-layout',
        path,
        '-',
      ]);
      expect(extracted.exitCode, 0, reason: '${extracted.stderr}');
      final text = extracted.stdout as String;
      for (final value in [
        'Complete first definition with code.',
        'Second paragraph retained.',
        'Other definition retained.',
      ]) {
        expect(text, contains(value));
      }
      expect('Complete first definition'.allMatches(text), hasLength(1));
      expect(
        text,
        matches(RegExp(r'First\s*1\s*,\s*repeated\s*1\s*,\s*and another\s*2')),
      );
      expect(result.pageCount, isNull);
    },
    skip: !pdfAvailable,
  );
}

Iterable<BusyBlock> _blocks(Iterable<BusyBlock> values) sync* {
  for (final b in values) {
    yield b;
    yield* _blocks(b.children);
  }
}

class _RecordingExporter extends MarkdownPdfExportService {
  BusyDocument? document;
  @override
  Future<MarkdownPdfExportResult> export(
    MarkdownPdfExportRequest request, {
    MarkdownPdfCancellationToken? cancellationToken,
  }) async {
    document = request.document;
    return MarkdownPdfExportResult(
      destinationPath: request.destinationPath,
      pageCount: null,
      warnings: const [],
    );
  }
}

class _DiagramRenderer implements VisualizationRenderer {
  final requests = <VisualizationRenderRequest>[];
  @override
  Set<VisualizationRendererKind> get supportedKinds => {
    VisualizationRendererKind.mermaid,
  };
  @override
  Future<VisualizationRenderRequest> prepare(
    VisualizationRenderRequest request,
    VisualizationCancellationToken token,
  ) async => request;
  @override
  Future<VisualizationRenderResult> render(
    VisualizationRenderRequest request,
    VisualizationCancellationToken token,
  ) async {
    requests.add(request);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return SvgVisualizationResult(
      svg:
          '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="10"><rect width="20" height="10" fill="${request.source.contains('one') ? 'red' : 'blue'}"/></svg>',
      width: 20,
      height: 10,
    );
  }
}
