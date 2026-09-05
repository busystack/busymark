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
  const compiler = 'build/linux/x64/release/bundle/libexec/busymark/typst';
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
      final result = await Process.run(p.absolute(compiler), [
        'compile',
        p.join(fixture.root.path, 'main.typ'),
        pdf,
      ]);
      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(await File(pdf).length(), greaterThan(1000));
    },
    skip: !File(compiler).existsSync(),
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
    'native Writerside demo runs through the bundled PDF pipeline',
    () async {
      final output = await Directory.systemTemp.createTemp(
        'busymark-writerside-native-pdf-',
      );
      addTearDown(() => output.delete(recursive: true));
      final module = Directory('demo/writerside-instances').absolute;
      final destination = p.join(output.path, 'writerside-demo.pdf');
      const service = WritersidePdfExportService(
        markdownExporter: MarkdownPdfExportService(
          compilerLocator: TypstCompilerLocator(
            environment: {'BUSYMARK_TYPST_PATH': '/bin/true'},
          ),
          commandRunner: _PdfWritingTypstRunner(),
        ),
      );

      final result = await service.export(
        WritersidePdfExportRequest(
          moduleRoot: module.path,
          instanceId: 'guide',
          destinationPath: destination,
          overwrite: false,
        ),
      );

      expect(await File(destination).length(), greaterThan(1024));
      expect(result.pageCount, isNotNull);
    },
  );
}

Iterable<BusyBlock> _allBlocks(Iterable<BusyBlock> blocks) sync* {
  for (final block in blocks) {
    yield block;
    yield* _allBlocks(block.children);
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

class _PdfWritingTypstRunner implements TypstCommandRunner {
  const _PdfWritingTypstRunner();

  @override
  Future<TypstProcessResult> compile({
    required String executable,
    required Directory workingDirectory,
    required Duration timeout,
    required MarkdownPdfCancellationToken cancellationToken,
  }) async {
    cancellationToken.throwIfCancelled();
    final bytes = <int>[
      ...'%PDF-1.7\n1 0 obj\n<< /Type /Page >>\nendobj\n'.codeUnits,
      ...List<int>.filled(1200, 0x20),
      ...'\n%%EOF\n'.codeUnits,
    ];
    await File(
      p.join(workingDirectory.path, 'output.pdf'),
    ).writeAsBytes(bytes, flush: true);
    return const TypstProcessResult(exitCode: 0, stdout: '', stderr: '');
  }
}
