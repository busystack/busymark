import 'dart:io';
import 'dart:convert';

import 'package:busymark/src/export/markdown_pdf_export_service.dart';
import 'package:busymark/src/export/markdown_pdf_models.dart';
import 'package:busymark/src/export/markdown_export_mapper.dart';
import 'package:busymark/src/export/markdown_export_document.dart';
import 'package:busymark/src/export/typst_compiler.dart';
import 'package:busymark/src/export/typst_payload_builder.dart';
import 'package:busymark/src/export/writerside_pdf_export_service.dart';
import 'package:busymark/src/export/writerside_pdf_models.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  final compiler = _bundledTypstCompiler();
  test(
    'bundled Typst compiles semantic tables, anchors and glossary footnotes',
    () async {
      final fixture = await _WritersideFixture.create();
      addTearDown(fixture.dispose);
      final glossary = File(p.join(fixture.module.path, 'cfg/glossary.xml'));
      await glossary.parent.create(recursive: true);
      await glossary.writeAsString(
        '<terms><term name="term">Glossary definition</term></terms>',
      );
      await File(
        p.join(fixture.module.path, 'topics/advanced.topic'),
      ).writeAsString(
        '<topic id="advanced" title="Advanced"><chapter id="chapter" title="Chapter"><p id="body">Body <tooltip term="term"/></p><a anchor="body"/><table><tr><td colspan="2">Header</td></tr><tr><td rowspan="2"><code-block>Nested code</code-block></td><td>A</td></tr><tr><td>B</td></tr></table></chapter></topic>',
      );
      final recording = _RecordingMarkdownExporter();
      await WritersidePdfExportService(markdownExporter: recording).export(
        WritersidePdfExportRequest(
          moduleRoot: fixture.module.path,
          projectRoot: fixture.root.path,
          instanceId: 'guide',
          destinationPath: p.join(fixture.root.path, 'recording.pdf'),
          overwrite: false,
        ),
      );
      final payload = const TypstPayloadBuilder().build(
        document: const MarkdownExportMapper().map(
          recording.request!.document!,
        ),
        options: const PdfExportOptions(),
        assets: {},
      );
      await File(
        p.join(fixture.root.path, 'document.json'),
      ).writeAsString(jsonEncode(payload));
      await File(
        'assets/export/markdown.typ',
      ).copy(p.join(fixture.root.path, 'main.typ'));
      final pdf = p.join(fixture.root.path, 'semantic.pdf');
      final result = await Process.run(compiler!, [
        'compile',
        p.join(fixture.root.path, 'main.typ'),
        pdf,
      ]);
      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(await File(pdf).length(), greaterThan(1000));
    },
    skip: compiler == null,
  );

  test(
    'PDF retains nested chapter bodies and resolves unique internal destinations',
    () async {
      final fixture = await _WritersideFixture.create();
      addTearDown(fixture.dispose);
      await File(
        p.join(fixture.module.path, 'topics/advanced.topic'),
      ).writeAsString(
        '<topic id="advanced" title="Advanced"><chapter id="nested" title="Nested"><p id="body">Nested body</p><a anchor="body"/></chapter></topic>',
      );
      final exporter = _RecordingMarkdownExporter();
      await WritersidePdfExportService(markdownExporter: exporter).export(
        WritersidePdfExportRequest(
          moduleRoot: fixture.module.path,
          projectRoot: fixture.root.path,
          instanceId: 'guide',
          destinationPath: p.join(fixture.root.path, 'anchors.pdf'),
          overwrite: false,
        ),
      );
      final document = const MarkdownExportMapper().map(
        exporter.request!.document!,
      );
      Iterable<MarkdownExportBlock> walk(
        List<MarkdownExportBlock> blocks,
      ) sync* {
        for (final block in blocks) {
          yield block;
          yield* walk(block.children);
        }
      }

      final blocks = walk(document.blocks).toList();
      expect(
        blocks.expand((block) => block.inlines).map((inline) => inline.text),
        contains('Nested body'),
      );
      final anchors = blocks
          .map((block) => block.attributes['anchor'])
          .whereType<String>()
          .toList();
      expect(anchors.toSet(), hasLength(anchors.length));
      final destination = blocks
          .expand((block) => block.inlines)
          .singleWhere(
            (inline) =>
                inline.text == 'Nested body' &&
                inline.kind == MarkdownExportInlineKind.link,
          )
          .destination!;
      expect(destination, startsWith('#ws-'));
      expect(anchors, contains(destination.substring(1)));
    },
  );

  test('Markdown topic links retain their PDF destinations', () async {
    final fixture = await _WritersideFixture.create();
    addTearDown(fixture.dispose);
    await File(p.join(fixture.module.path, 'topics', 'intro.md')).writeAsString(
      '# Introduction\n\n[Advanced details](advanced.topic#details)\n',
    );
    await File(
      p.join(fixture.module.path, 'topics', 'advanced.topic'),
    ).writeAsString(
      '<topic id="advanced" title="Advanced">'
      '<p id="details">Detailed instructions.</p>'
      '</topic>',
    );
    final exporter = _RecordingMarkdownExporter();

    await WritersidePdfExportService(markdownExporter: exporter).export(
      WritersidePdfExportRequest(
        moduleRoot: fixture.module.path,
        projectRoot: fixture.root.path,
        instanceId: 'guide',
        destinationPath: p.join(fixture.root.path, 'markdown-link.pdf'),
        overwrite: false,
      ),
    );

    final document = const MarkdownExportMapper().map(
      exporter.request!.document!,
    );
    final blocks = _allExportBlocks(document.blocks).toList();
    final link = blocks
        .expand((block) => block.inlines)
        .singleWhere((inline) => inline.text == 'Advanced details');
    expect(link.kind, MarkdownExportInlineKind.link);
    expect(link.destination, startsWith('#ws-'));
    expect(
      blocks.map((block) => block.attributes['anchor']),
      contains(link.destination!.substring(1)),
    );
  });

  test(
    'Markdown topic blank lines remain explicit in Writerside PDF',
    () async {
      final fixture = await _WritersideFixture.create();
      addTearDown(fixture.dispose);
      await File(
        p.join(fixture.module.path, 'topics', 'intro.md'),
      ).writeAsString('# Introduction\n\nBefore<br><br>After\n');
      final exporter = _RecordingMarkdownExporter();

      await WritersidePdfExportService(markdownExporter: exporter).export(
        WritersidePdfExportRequest(
          moduleRoot: fixture.module.path,
          projectRoot: fixture.root.path,
          instanceId: 'guide',
          destinationPath: p.join(fixture.root.path, 'blank-line.pdf'),
          overwrite: false,
        ),
      );

      final paragraph = _allBlocks(
        exporter.request!.document!.blocks,
      ).singleWhere((block) => block.plainText == 'Before\n\nAfter');
      expect(
        paragraph.inlines.where(
          (inline) => inline.kind == BusyInlineKind.hardBreak,
        ),
        hasLength(2),
      );
    },
  );

  test(
    'native export composes the selected instance without a container runtime',
    () async {
      final fixture = await _WritersideFixture.create();
      addTearDown(fixture.dispose);
      final exporter = _RecordingMarkdownExporter();
      final service = WritersidePdfExportService(markdownExporter: exporter);
      final destination = p.join(fixture.root.path, 'guide.pdf');

      final result = await service.export(
        WritersidePdfExportRequest(
          moduleRoot: fixture.module.path,
          projectRoot: fixture.root.path,
          instanceId: 'guide',
          destinationPath: destination,
          overwrite: false,
          options: const PdfExportOptions(
            pageSize: PdfPageSize.letter,
            orientation: PdfOrientation.landscape,
            content: ExportContentOptions(
              includeToc: true,
              tocDepth: 3,
              numberHeadings: true,
            ),
            bodyTypography: ExportBodyTypography.sansSerif,
            bodyFontSize: 15,
            codeFontSize: 12,
            accentColor: '#247550',
            header: PdfRunningText.documentTitle,
            pageNumbers: PdfPageNumberPosition.bottomRight,
          ),
        ),
      );

      final request = exporter.request!;
      expect(result.destinationPath, destination);
      expect(result.pageCount, 3);
      expect(request.mode, MarkdownMode.writersideMarkdown);
      expect(request.workspaceRoot, fixture.module.path);
      expect(request.options.pageSize, PdfPageSize.letter);
      expect(request.options.orientation, PdfOrientation.landscape);
      expect(request.options.bodyFontSize, 15);
      expect(request.options.codeFontSize, 12);
      expect(request.options.bodyFont, 'Noto Sans');
      expect(
        request.options.content.toJson(),
        const ExportContentOptions(
          includeToc: true,
          tocDepth: 3,
          numberHeadings: true,
        ).toJson(),
      );
      expect(request.options.header, PdfRunningText.documentTitle);
      expect(request.options.accentColor, '#247550');
      expect(request.options.pageNumbers, PdfPageNumberPosition.bottomRight);
      expect(request.source, isEmpty);
      expect(request.document, isNotNull);
      final blocks = _allBlocks(request.document!.blocks).toList();
      final text = blocks.map((block) => block.plainText).join('\n');
      final headings = blocks
          .where((block) => block.kind == BusyBlockKind.heading)
          .map((block) => block.plainText)
          .toList();
      expect(headings, containsAllInOrder(['BusyMark Guide', 'Advanced']));
      expect(text, contains('XML topic content.'));
      expect(text, contains('Resolved include content.'));
      expect(text, contains('Cross-module include content.'));
      expect(text, isNot(contains('Included content:')));
      expect(text, contains('x < y'));
      expect(blocks.map((block) => block.kind), contains(BusyBlockKind.math));
      expect(
        blocks
            .expand((block) => _allInlines(block.inlines))
            .map((inline) => inline.destination),
        contains(startsWith('file://')),
      );
      final imageDestinations = blocks
          .expand((block) => _allInlines(block.inlines))
          .where((inline) => inline.kind == BusyInlineKind.image)
          .map((inline) => inline.destination)
          .whereType<String>();
      expect(
        imageDestinations,
        contains(
          allOf(startsWith('file://'), contains('/Shared/images/shared.png')),
        ),
      );
    },
  );

  test(
    'hidden topics remain content and toc-title stays navigation-only',
    () async {
      final fixture = await _WritersideFixture.create();
      addTearDown(fixture.dispose);
      await File(p.join(fixture.module.path, 'guide.tree')).writeAsString('''
<instance-profile id="guide" name="Guide" start-page="intro.md">
  <toc-element topic="intro.md" toc-title="Short navigation title"/>
  <toc-element topic="hidden.md" hidden="true"/>
  <toc-element topic="draft.md" wip="true"/>
</instance-profile>
''');
      await File(
        p.join(fixture.module.path, 'topics', 'hidden.md'),
      ).writeAsString('# Legal information\n\nRequired legal notice.\n');
      await File(
        p.join(fixture.module.path, 'topics', 'draft.md'),
      ).writeAsString('# Draft\n\nUnreleased instructions.\n');
      final exporter = _RecordingMarkdownExporter();

      await WritersidePdfExportService(markdownExporter: exporter).export(
        WritersidePdfExportRequest(
          moduleRoot: fixture.module.path,
          projectRoot: fixture.root.path,
          instanceId: 'guide',
          destinationPath: p.join(fixture.root.path, 'hidden.pdf'),
          overwrite: false,
        ),
      );

      final blocks = _allBlocks(exporter.request!.document!.blocks).toList();
      final headings = blocks
          .where((block) => block.kind == BusyBlockKind.heading)
          .map((block) => block.plainText)
          .toList();
      final text = blocks.map((block) => block.plainText).join('\n');
      expect(
        headings,
        containsAllInOrder(['BusyMark Guide', 'Legal information']),
      );
      expect(headings, isNot(contains('Short navigation title')));
      expect(text, contains('Required legal notice.'));
      expect(text, isNot(contains('Unreleased instructions.')));
      final mapped = const MarkdownExportMapper().map(
        exporter.request!.document!,
      );
      final legalHeading = mapped.blocks.singleWhere(
        (block) =>
            block.kind == MarkdownExportBlockKind.heading &&
            block.inlines.any((inline) => inline.text == 'Legal information'),
      );
      expect(legalHeading.attributes['outlined'], isFalse);
    },
  );

  test(
    'referenced diagrams keep resolved source and all tab panels reach PDF',
    () async {
      final fixture = await _WritersideFixture.create();
      addTearDown(fixture.dispose);
      await File(
        p.join(fixture.module.path, 'topics', 'graph.mmd'),
      ).writeAsString('flowchart LR\nA --> B');
      await File(
        p.join(fixture.module.path, 'topics', 'advanced.topic'),
      ).writeAsString(
        '<topic id="advanced"><tabs><tab title="Linux"><code-block lang="mermaid" src="graph.mmd"/></tab><tab title="Windows"><p>Windows instructions</p></tab></tabs></topic>',
      );
      final exporter = _RecordingMarkdownExporter();
      await WritersidePdfExportService(markdownExporter: exporter).export(
        WritersidePdfExportRequest(
          moduleRoot: fixture.module.path,
          projectRoot: fixture.root.path,
          instanceId: 'guide',
          destinationPath: p.join(fixture.root.path, 'tabs.pdf'),
          overwrite: false,
        ),
      );
      final blocks = _allBlocks(exporter.request!.document!.blocks).toList();
      final code = blocks.singleWhere(
        (block) => block.kind == BusyBlockKind.codeBlock,
      );
      expect(code.plainText, 'flowchart LR\nA --> B');
      expect(code.attributes['src'], 'graph.mmd');
      expect(
        blocks.map((block) => block.plainText),
        containsAll(['Linux', 'Windows', 'Windows instructions']),
      );
    },
  );

  test('pre-cancelled native export never starts PDF compilation', () async {
    final fixture = await _WritersideFixture.create();
    addTearDown(fixture.dispose);
    final exporter = _RecordingMarkdownExporter();
    final service = WritersidePdfExportService(markdownExporter: exporter);
    final token = WritersidePdfCancellationToken()..cancel();

    await expectLater(
      service.export(
        WritersidePdfExportRequest(
          moduleRoot: fixture.module.path,
          projectRoot: fixture.root.path,
          instanceId: 'guide',
          destinationPath: p.join(fixture.root.path, 'cancelled.pdf'),
          overwrite: false,
        ),
        cancellationToken: token,
      ),
      throwsA(
        isA<WritersidePdfExportException>().having(
          (error) => error.code,
          'code',
          WritersidePdfFailureCode.cancelled,
        ),
      ),
    );
    expect(exporter.request, isNull);
  });

  test('unknown Writerside instance is rejected before compilation', () async {
    final fixture = await _WritersideFixture.create();
    addTearDown(fixture.dispose);
    final exporter = _RecordingMarkdownExporter();
    final service = WritersidePdfExportService(markdownExporter: exporter);

    await expectLater(
      service.export(
        WritersidePdfExportRequest(
          moduleRoot: fixture.module.path,
          instanceId: 'missing',
          destinationPath: p.join(fixture.root.path, 'missing.pdf'),
          overwrite: false,
        ),
      ),
      throwsA(
        isA<WritersidePdfExportException>().having(
          (error) => error.code,
          'code',
          WritersidePdfFailureCode.invalidRequest,
        ),
      ),
    );
    expect(exporter.request, isNull);
  });

  test('resolution errors prevent PDF compilation', () async {
    final fixture = await _WritersideFixture.create();
    addTearDown(fixture.dispose);
    final advanced = File(
      p.join(fixture.module.path, 'topics', 'advanced.topic'),
    );
    await advanced.writeAsString(
      (await advanced.readAsString()).replaceFirst(
        '</topic>',
        '<include from="missing.topic"/></topic>',
      ),
    );
    final exporter = _RecordingMarkdownExporter();
    final service = WritersidePdfExportService(markdownExporter: exporter);

    await expectLater(
      service.export(
        WritersidePdfExportRequest(
          moduleRoot: fixture.module.path,
          projectRoot: fixture.root.path,
          instanceId: 'guide',
          destinationPath: p.join(fixture.root.path, 'failed.pdf'),
          overwrite: false,
        ),
      ),
      throwsA(
        isA<WritersidePdfExportException>()
            .having(
              (error) => error.code,
              'code',
              WritersidePdfFailureCode.invalidRequest,
            )
            .having(
              (error) => error.detail,
              'detail',
              contains('writerside.include.unresolved-source'),
            ),
      ),
    );
    expect(exporter.request, isNull);
  });

  test('module validation errors prevent PDF compilation', () async {
    final fixture = await _WritersideFixture.create();
    addTearDown(fixture.dispose);
    await File(p.join(fixture.module.path, 'guide.tree')).writeAsString('''
<instance-profile id="guide" name="Guide" start-page="intro.md">
  <toc-element topic="intro.md"/>
  <toc-element topic="missing.topic"/>
</instance-profile>
''');
    final exporter = _RecordingMarkdownExporter();

    await expectLater(
      WritersidePdfExportService(markdownExporter: exporter).export(
        WritersidePdfExportRequest(
          moduleRoot: fixture.module.path,
          projectRoot: fixture.root.path,
          instanceId: 'guide',
          destinationPath: p.join(fixture.root.path, 'invalid-module.pdf'),
          overwrite: false,
        ),
      ),
      throwsA(
        isA<WritersidePdfExportException>()
            .having(
              (error) => error.code,
              'code',
              WritersidePdfFailureCode.invalidRequest,
            )
            .having(
              (error) => error.detail,
              'detail',
              contains('writerside.tree.missing-topic'),
            ),
      ),
    );
    expect(exporter.request, isNull);
  });

  test('module validation warnings are returned to the caller', () async {
    final fixture = await _WritersideFixture.create();
    addTearDown(fixture.dispose);
    await File(
      p.join(fixture.module.path, 'topics', 'unused.topic'),
    ).writeAsString('<topic id="unused"><p>Untitled topic.</p></topic>');
    final exporter = _RecordingMarkdownExporter();

    final result = await WritersidePdfExportService(markdownExporter: exporter)
        .export(
          WritersidePdfExportRequest(
            moduleRoot: fixture.module.path,
            projectRoot: fixture.root.path,
            instanceId: 'guide',
            destinationPath: p.join(fixture.root.path, 'module-warning.pdf'),
            overwrite: false,
          ),
        );

    expect(
      result.warnings,
      contains(
        isA<MarkdownPdfWarning>()
            .having(
              (warning) => warning.code,
              'code',
              MarkdownPdfWarningCode.writersideResolution,
            )
            .having(
              (warning) => warning.destination,
              'diagnostic',
              'writerside.topic.missing-title',
            ),
      ),
    );
  });

  test(
    'nonfatal resolution diagnostics are returned as PDF warnings',
    () async {
      final fixture = await _WritersideFixture.create();
      addTearDown(fixture.dispose);
      final advanced = File(
        p.join(fixture.module.path, 'topics', 'advanced.topic'),
      );
      await advanced.writeAsString(
        (await advanced.readAsString()).replaceFirst(
          '</topic>',
          '<p>%missing-variable%</p></topic>',
        ),
      );
      final exporter = _RecordingMarkdownExporter();
      final service = WritersidePdfExportService(markdownExporter: exporter);

      final result = await service.export(
        WritersidePdfExportRequest(
          moduleRoot: fixture.module.path,
          projectRoot: fixture.root.path,
          instanceId: 'guide',
          destinationPath: p.join(fixture.root.path, 'warning.pdf'),
          overwrite: false,
        ),
      );

      expect(
        result.warnings,
        contains(
          isA<MarkdownPdfWarning>()
              .having(
                (warning) => warning.code,
                'code',
                MarkdownPdfWarningCode.writersideResolution,
              )
              .having(
                (warning) => warning.destination,
                'diagnostic',
                'writerside.variable.unresolved',
              ),
        ),
      );
    },
  );

  test('native exporter failures use Writerside failure codes', () async {
    final fixture = await _WritersideFixture.create();
    addTearDown(fixture.dispose);
    final service = WritersidePdfExportService(
      markdownExporter: _RecordingMarkdownExporter(
        failure: const MarkdownPdfExportException(
          MarkdownPdfFailureCode.compilerUnavailable,
        ),
      ),
    );

    await expectLater(
      service.export(
        WritersidePdfExportRequest(
          moduleRoot: fixture.module.path,
          projectRoot: fixture.root.path,
          instanceId: 'guide',
          destinationPath: p.join(fixture.root.path, 'unavailable.pdf'),
          overwrite: false,
        ),
      ),
      throwsA(
        isA<WritersidePdfExportException>().having(
          (error) => error.code,
          'code',
          WritersidePdfFailureCode.exporterUnavailable,
        ),
      ),
    );
  });

  test(
    'native Writerside fixture compiles end to end with bundled Typst',
    () async {
      final output = await Directory.systemTemp.createTemp(
        'busymark-writerside-native-pdf-',
      );
      addTearDown(() => output.delete(recursive: true));
      final module = Directory(
        'test/fixtures/writerside/conformance_project',
      ).absolute;
      final destination = p.join(output.path, 'writerside-conformance.pdf');
      final service = WritersidePdfExportService(
        markdownExporter: MarkdownPdfExportService(
          compilerLocator: TypstCompilerLocator(
            environment: {'BUSYMARK_TYPST_PATH': compiler!},
          ),
        ),
      );

      final result = await service.export(
        WritersidePdfExportRequest(
          moduleRoot: module.path,
          instanceId: 'conformance',
          destinationPath: destination,
          overwrite: false,
        ),
      );

      expect(await File(destination).length(), greaterThan(1024));
      expect(result.destinationPath, p.normalize(p.absolute(destination)));
    },
    skip: compiler == null,
  );
}

String? _bundledTypstCompiler() {
  for (final candidate in [
    'build/linux/x64/release/bundle/libexec/busymark/typst',
    'build/linux/x64/debug/bundle/libexec/busymark/typst',
  ]) {
    final absolute = p.absolute(candidate);
    if (File(absolute).existsSync()) return absolute;
  }
  return null;
}

Iterable<BusyBlock> _allBlocks(Iterable<BusyBlock> blocks) sync* {
  for (final block in blocks) {
    yield block;
    yield* _allBlocks(block.children);
  }
}

Iterable<MarkdownExportBlock> _allExportBlocks(
  Iterable<MarkdownExportBlock> blocks,
) sync* {
  for (final block in blocks) {
    yield block;
    yield* _allExportBlocks(block.children);
  }
}

Iterable<BusyInline> _allInlines(Iterable<BusyInline> inlines) sync* {
  for (final inline in inlines) {
    yield inline;
    yield* _allInlines(inline.children);
  }
}

class _WritersideFixture {
  const _WritersideFixture({required this.root, required this.module});

  final Directory root;
  final Directory module;

  static Future<_WritersideFixture> create() async {
    final root = await Directory.systemTemp.createTemp(
      'busymark-writerside-native-service-',
    );
    final module = await Directory(p.join(root.path, 'Writerside')).create();
    await Directory(p.join(module.path, 'topics')).create();
    await Directory(p.join(module.path, 'images')).create();
    await File(p.join(module.path, 'writerside.cfg')).writeAsString('''
<ihp version="2026.2">
  <module name="Native export test"/>
  <topics dir="topics"/>
  <images dir="images"/>
  <vars src="v.list"/>
  <instance src="guide.tree"/>
</ihp>
''');
    await File(p.join(module.path, 'guide.tree')).writeAsString('''
<instance-profile id="guide" name="Guide" start-page="intro.md">
  <toc-element topic="intro.md"/>
  <toc-element topic="advanced.topic"/>
</instance-profile>
''');
    await File(p.join(module.path, 'v.list')).writeAsString('''
<vars><var name="product" value="BusyMark Guide"/></vars>
''');
    await File(p.join(module.path, 'topics', 'intro.md')).writeAsString('''
# %product%

![Logo](logo.png)

Inline math: \$x^2\$.
''');
    await File(p.join(module.path, 'topics', 'advanced.topic')).writeAsString(
      '''
<topic id="advanced" title="Advanced">
  <p>XML topic content.</p>
  <include from="shared.topic" element-id="pdf-snippet"/>
  <include origin="shared-pdf" from="library.topic"
           element-id="cross-module-snippet"/>
  <math>x &lt; y</math>
</topic>
''',
    );
    await File(p.join(module.path, 'topics', 'shared.topic')).writeAsString('''
<topic id="shared" title="Shared">
  <snippet id="pdf-snippet"><p>Resolved include content.</p></snippet>
</topic>
''');
    await File(
      p.join(module.path, 'images', 'logo.png'),
    ).writeAsBytes(const [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
    final shared = await Directory(p.join(root.path, 'Shared')).create();
    await Directory(p.join(shared.path, 'topics')).create();
    await Directory(p.join(shared.path, 'images')).create();
    await File(p.join(shared.path, 'writerside.cfg')).writeAsString('''
<ihp version="2026.2">
  <module name="shared-pdf"/>
  <topics dir="topics"/>
  <images dir="images"/>
</ihp>
''');
    await File(p.join(shared.path, 'topics', 'library.topic')).writeAsString('''
<topic id="library" title="Library">
  <snippet id="cross-module-snippet">
    <p>Cross-module include content.</p>
    <img src="shared.png" alt="Shared image"/>
  </snippet>
</topic>
''');
    await File(
      p.join(shared.path, 'images', 'shared.png'),
    ).writeAsBytes(const [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
    return _WritersideFixture(root: root, module: module);
  }

  Future<void> dispose() => root.delete(recursive: true);
}

class _RecordingMarkdownExporter extends MarkdownPdfExportService {
  _RecordingMarkdownExporter({this.failure});

  final MarkdownPdfExportException? failure;
  MarkdownPdfExportRequest? request;

  @override
  Future<MarkdownPdfExportResult> export(
    MarkdownPdfExportRequest request, {
    MarkdownPdfCancellationToken? cancellationToken,
  }) async {
    this.request = request;
    if (failure case final error?) {
      throw error;
    }
    cancellationToken?.throwIfCancelled();
    return MarkdownPdfExportResult(
      destinationPath: request.destinationPath,
      pageCount: 3,
      warnings: const [],
    );
  }
}
