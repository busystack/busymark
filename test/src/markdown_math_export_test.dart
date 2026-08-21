import 'dart:convert';
import 'dart:io';

import 'package:busymark/src/export/markdown_export_document.dart';
import 'package:busymark/src/export/markdown_export_mapper.dart';
import 'package:busymark/src/export/markdown_math_export.dart';
import 'package:busymark/src/export/markdown_pdf_export_service.dart';
import 'package:busymark/src/export/markdown_pdf_models.dart';
import 'package:busymark/src/export/typst_compiler.dart';
import 'package:busymark/src/export/typst_payload_builder.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/math/math_coordinator.dart';
import 'package:busymark/src/math/math_renderer.dart';
import 'package:busymark/src/visualization/visualization_renderer.dart';
import 'package:busymark/src/visualization/web_render_host.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('uses each heading level effective text size for inline math', () async {
    final root = await Directory.systemTemp.createTemp(
      'busymark-heading-math-export-',
    );
    addTearDown(() => root.delete(recursive: true));
    final host = _PdfMathHost();
    final coordinator = MathCoordinator(renderer: MathRenderer(host: host));
    addTearDown(coordinator.dispose);
    final source = [
      for (var level = 1; level <= 6; level++)
        '${'#' * level} Heading \$h$level\$\n',
    ].join('\n');
    final mapped = const MarkdownExportMapper().map(
      const MarkdownParser()
          .parse(filePath: '/workspace/headings.md', source: source)
          .busyDocument,
    );

    await MarkdownMathExportRenderer(coordinator: coordinator).prepare(
      document: mapped,
      exportRoot: root,
      containerWidth: 480,
      cancellationToken: MarkdownPdfCancellationToken(),
    );

    final requests = host.batches.expand((batch) => batch).toList();
    expect(requests, hasLength(6));
    for (var level = 1; level <= 6; level++) {
      final request = requests.singleWhere(
        (item) => item['expression'] == 'h$level',
      );
      final expected = busyMarkPdfHeadingTextSize(level);
      expect(request['em'], expected, reason: 'heading level $level');
      expect(request['ex'], expected / 2, reason: 'heading level $level');
    }
  });

  test(
    'prepares inline and display math as deterministic vector assets',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'busymark-math-export-',
      );
      addTearDown(() => root.delete(recursive: true));
      final coordinator = MathCoordinator(
        renderer: MathRenderer(host: _PdfMathHost()),
      );
      addTearDown(coordinator.dispose);
      final parsed = const MarkdownParser().parse(
        filePath: '/workspace/math.md',
        source: r'''
Text before $x^2$ and $\frac{a}{b}$ after.

$$
\ce{2H2 + O2 -> 2H2O}
$$
''',
        validateLocalReferences: false,
      );
      final mapped = const MarkdownExportMapper().map(parsed.busyDocument);

      final preparation =
          await MarkdownMathExportRenderer(coordinator: coordinator).prepare(
            document: mapped,
            exportRoot: root,
            containerWidth: 480,
            cancellationToken: MarkdownPdfCancellationToken(),
          );

      expect(preparation.warnings, isEmpty);
      final paragraph = preparation.document.blocks.firstWhere(
        (block) => block.kind == MarkdownExportBlockKind.paragraph,
      );
      final inlineMath = paragraph.inlines
          .where((inline) => inline.kind == MarkdownExportInlineKind.math)
          .toList();
      expect(inlineMath, hasLength(2));
      expect(
        inlineMath,
        everyElement(
          predicate<MarkdownExportInline>((inline) {
            return inline.attributes['vector'] == 'true' &&
                inline.attributes['depth'] == '2.0' &&
                inline.attributes['asset']!.endsWith('.svg');
          }),
        ),
      );
      final display = preparation.document.blocks.firstWhere(
        (block) => block.kind == MarkdownExportBlockKind.math,
      );
      expect(display.attributes['vector'], 'true');
      expect(display.attributes['depth'], '2.0');
      final generated = Directory(p.join(root.path, 'generated-assets'));
      expect(
        await generated
            .list()
            .where((entry) => entry.path.endsWith('.svg'))
            .length,
        3,
      );
      await for (final asset in generated.list().where(
        (entry) => entry.path.endsWith('.svg'),
      )) {
        final svg = await File(asset.path).readAsString();
        expect(svg, isNot(contains('currentColor')));
        expect(svg, contains('#000000'));
      }

      final payload = const TypstPayloadBuilder().build(
        document: preparation.document,
        options: const MarkdownPdfOptions(),
        assets: const {},
      );
      final json = jsonEncode(payload);
      expect(json, contains('"kind":"math"'));
      expect(json, contains('"depth":"2.0"'));
      expect(json, contains('generated-assets/'));
    },
  );

  final typstPath = Platform.environment['BUSYMARK_TYPST_PATH'];
  final canRunTypst = typstPath != null && File(typstPath).existsSync();
  test(
    'Typst keeps MathJax SVG inline and exports failed math visibly',
    () async {
      final root = await Directory.systemTemp.createTemp('busymark-math-pdf-');
      addTearDown(() => root.delete(recursive: true));
      final coordinator = MathCoordinator(
        renderer: MathRenderer(host: _PdfMathHost()),
      );
      addTearDown(coordinator.dispose);
      final destination = p.join(root.path, 'math.pdf');
      final result =
          await MarkdownPdfExportService(
            compilerLocator: TypstCompilerLocator(
              environment: {'BUSYMARK_TYPST_PATH': typstPath!},
            ),
            mathRenderer: MarkdownMathExportRenderer(coordinator: coordinator),
            templateLoader: () =>
                File('assets/export/markdown.typ').readAsString(),
          ).export(
            MarkdownPdfExportRequest(
              source: r'''
Text before $x^2$ and $\frac{a}{b}$ after.

$$\ce{2H2 + O2 -> 2H2O}$$

Failed but visible: $BAD$.
''',
              filePath: p.join(root.path, 'math.md'),
              workspaceRoot: root.path,
              destinationPath: destination,
              options: const MarkdownPdfOptions(),
              overwrite: false,
            ),
          );

      final bytes = await File(destination).readAsBytes();
      expect(bytes.take(5), <int>[37, 80, 68, 70, 45]);
      expect(
        result.warnings.map((warning) => warning.code),
        contains(MarkdownPdfWarningCode.mathRenderFailed),
      );
    },
    skip: canRunTypst ? false : 'Set BUSYMARK_TYPST_PATH to run Typst math.',
  );
}

class _PdfMathHost implements WebRenderHost {
  final List<List<Map<String, Object?>>> batches = [];

  @override
  Future<Map<Object?, Object?>> renderMathBatch({
    required List<Map<String, Object?>> expressions,
    required VisualizationCancellationToken cancellationToken,
  }) async {
    batches.add(expressions);
    return {
      'results': [
        for (final item in expressions)
          if (item['expression'] == 'BAD')
            {
              'id': item['id'],
              'error': {
                'code': 'math.invalidTex',
                'message': 'The expression contains invalid TeX.',
              },
            }
          else
            {
              'id': item['id'],
              'svg': '''<svg xmlns="http://www.w3.org/2000/svg"
                viewBox="0 -10 30 14" style="vertical-align:-0.25ex">
                <defs><path id="glyph" d="M0 0L10 10L20 0"/></defs>
                <use href="#glyph" fill="currentColor"/>
              </svg>''',
              'width': 30,
              'height': 14,
              'depth': 2,
            },
      ],
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
