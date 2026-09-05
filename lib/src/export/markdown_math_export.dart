import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../math/math_coordinator.dart';
import '../math/math_models.dart';
import '../math/math_svg_preprocessor.dart';
import '../visualization/generated_svg_normalizer.dart';
import 'markdown_export_document.dart';
import 'markdown_pdf_models.dart';

class MarkdownMathExportPreparation {
  const MarkdownMathExportPreparation({
    required this.document,
    required this.warnings,
  });

  final MarkdownExportDocument document;
  final List<MarkdownPdfWarning> warnings;
}

class MarkdownMathExportRenderer {
  const MarkdownMathExportRenderer({
    required this.coordinator,
    this.svgNormalizer = const GeneratedSvgNormalizer(
      maximumBytes: busyMarkMaximumMathSvgBytes,
    ),
    this.maximumExpressions = 512,
    this.maximumGeneratedBytes = 64 * 1024 * 1024,
  });

  final MathCoordinator coordinator;
  final GeneratedSvgNormalizer svgNormalizer;
  final int maximumExpressions;
  final int maximumGeneratedBytes;
  static const _svgPreprocessor = MathSvgPreprocessor();
  // Bundled Noto Sans and Noto Serif OS/2 sxHeight=536, unitsPerEm=1000.
  static const _notoXHeightRatio = 0.536;

  Future<MarkdownMathExportPreparation> prepare({
    required MarkdownExportDocument document,
    required Directory exportRoot,
    required PdfExportOptions options,
    required MarkdownPdfCancellationToken cancellationToken,
  }) async {
    options.validateOrThrow();
    final annotated = _annotate(document);
    final candidates = _mathCandidates(
      annotated,
      options,
    ).toList(growable: false);
    if (candidates.isEmpty) {
      return MarkdownMathExportPreparation(
        document: document,
        warnings: const [],
      );
    }
    final selected = candidates
        .take(maximumExpressions)
        .toList(growable: false);
    final blockKeys = [
      for (final item in selected) 'pdf-math:${item.renderKey}',
    ];
    cancellationToken.attach(() {
      for (final key in blockKeys) {
        coordinator.cancel(key);
      }
    });
    final results = <String, MathRenderResult>{};
    try {
      final rendered = await coordinator.renderAll([
        for (final (index, item) in selected.indexed)
          MathRenderRequest(
            expressionId: item.renderKey,
            expression: item.expression,
            display: item.display,
            blockKey: blockKeys[index],
            editRevision: 0,
            em: item.em,
            ex: item.ex,
            containerWidth: options.geometry.contentWidthPt,
            renderProfile: 'pdf',
          ),
      ]);
      for (final result in rendered) {
        results[result.expressionId] = result;
      }
    } on Object {
      cancellationToken.throwIfCancelled();
    } finally {
      cancellationToken.detach();
      for (final key in blockKeys) {
        coordinator.cancel(key);
      }
    }
    cancellationToken.throwIfCancelled();

    final assets = <String, _PreparedMathAsset>{};
    final warnings = <MarkdownPdfWarning>[
      if (candidates.length > maximumExpressions)
        MarkdownPdfWarning(
          MarkdownPdfWarningCode.mathLimitReached,
          '${candidates.length - maximumExpressions} math expressions',
        ),
    ];
    final generatedDirectory = Directory(
      p.join(exportRoot.path, 'generated-assets'),
    );
    var generatedBytes = 0;
    for (final item in selected) {
      cancellationToken.throwIfCancelled();
      final result = results[item.renderKey];
      if (result is! RenderedMathResult) {
        warnings.add(
          MarkdownPdfWarning(
            MarkdownPdfWarningCode.mathRenderFailed,
            item.expression,
          ),
        );
        continue;
      }
      try {
        final normalized = svgNormalizer.normalize(
          _svgPreprocessor.resolveCurrentColor(result.vectorSvg, '#000000'),
        );
        final svg = normalized.vectorSafeSvg;
        if (svg == null) {
          throw const GeneratedSvgException(
            'math.unsafeOutput',
            'Math SVG is not vector safe.',
          );
        }
        final bytes = utf8.encode(svg);
        if (bytes.length > maximumGeneratedBytes - generatedBytes) {
          warnings.add(
            MarkdownPdfWarning(
              MarkdownPdfWarningCode.mathRenderFailed,
              item.expression,
            ),
          );
          continue;
        }
        await generatedDirectory.create(recursive: true);
        final digest = sha256.convert(bytes).toString();
        final filename = '$digest.svg';
        final target = File(p.join(generatedDirectory.path, filename));
        if (!await target.exists()) {
          await target.writeAsBytes(bytes, flush: true);
          generatedBytes += bytes.length;
        }
        assets[item.renderKey] = _PreparedMathAsset(
          path: p.posix.join('generated-assets', filename),
          width: result.width,
          height: result.height,
          depth: result.depth,
        );
      } on GeneratedSvgException {
        warnings.add(
          MarkdownPdfWarning(
            MarkdownPdfWarningCode.mathRenderFailed,
            item.expression,
          ),
        );
      }
    }
    return MarkdownMathExportPreparation(
      document: _applyAssets(annotated, assets),
      warnings: List.unmodifiable(warnings),
    );
  }

  MarkdownExportDocument _annotate(MarkdownExportDocument document) {
    MarkdownExportInline inline(MarkdownExportInline value, String path) {
      final children = [
        for (final (index, child) in value.children.indexed)
          inline(child, '$path.i$index'),
      ];
      if (value.kind != MarkdownExportInlineKind.math) {
        return value.copyWith(children: children);
      }
      return value.copyWith(
        children: children,
        attributes: {
          ...value.attributes,
          'mathRenderKey': _renderKey(path, value.text, false),
        },
      );
    }

    MarkdownExportBlock block(MarkdownExportBlock value, String path) {
      final inlines = [
        for (final (index, child) in value.inlines.indexed)
          inline(child, '$path.i$index'),
      ];
      final children = [
        for (final (index, child) in value.children.indexed)
          block(child, '$path.b$index'),
      ];
      if (value.kind != MarkdownExportBlockKind.math) {
        return value.copyWith(inlines: inlines, children: children);
      }
      return value.copyWith(
        inlines: inlines,
        children: children,
        attributes: {
          ...value.attributes,
          'mathRenderKey': _renderKey(path, value.text, true),
        },
      );
    }

    return document.copyWith(
      blocks: [
        for (final (index, value) in document.blocks.indexed)
          block(value, 'b$index'),
      ],
    );
  }

  Iterable<_MathExportCandidate> _mathCandidates(
    MarkdownExportDocument document,
    PdfExportOptions options,
  ) sync* {
    Iterable<_MathExportCandidate> inlines(
      List<MarkdownExportInline> values,
      double size,
    ) sync* {
      for (final value in values) {
        if (value.kind == MarkdownExportInlineKind.math) {
          yield _MathExportCandidate(
            renderKey: value.attributes['mathRenderKey']!,
            expression: value.text,
            display: false,
            em: size,
            ex: size * _notoXHeightRatio,
          );
        }
        yield* inlines(value.children, size);
      }
    }

    Iterable<_MathExportCandidate> blocks(
      List<MarkdownExportBlock> values,
    ) sync* {
      for (final value in values) {
        final size = value.kind == MarkdownExportBlockKind.heading
            ? options.headingFontSize((value.attributes['level'] as int?) ?? 1)
            : options.bodyFontSize;
        if (value.kind == MarkdownExportBlockKind.math) {
          yield _MathExportCandidate(
            renderKey: value.attributes['mathRenderKey']! as String,
            expression: value.text,
            display: true,
            em: size,
            ex: size * _notoXHeightRatio,
          );
        }
        yield* inlines(value.inlines, size);
        yield* blocks(value.children);
      }
    }

    yield* blocks(document.blocks);
  }

  MarkdownExportDocument _applyAssets(
    MarkdownExportDocument document,
    Map<String, _PreparedMathAsset> assets,
  ) {
    Map<String, String> inlineAttributes(Map<String, String> source) {
      final asset = assets[source['mathRenderKey']];
      return {
        ...source,
        if (asset != null) ...{
          'asset': asset.path,
          'width': '${asset.width}',
          'height': '${asset.height}',
          'depth': '${asset.depth}',
          'vector': 'true',
        } else
          'failed': 'true',
      };
    }

    MarkdownExportInline inline(MarkdownExportInline value) {
      return value.copyWith(
        children: value.children.map(inline).toList(growable: false),
        attributes: value.kind == MarkdownExportInlineKind.math
            ? inlineAttributes(value.attributes)
            : value.attributes,
      );
    }

    MarkdownExportBlock block(MarkdownExportBlock value) {
      final key = value.attributes['mathRenderKey'] as String?;
      final asset = assets[key];
      return value.copyWith(
        inlines: value.inlines.map(inline).toList(growable: false),
        children: value.children.map(block).toList(growable: false),
        attributes: value.kind == MarkdownExportBlockKind.math
            ? {
                ...value.attributes,
                if (asset != null) ...{
                  'asset': asset.path,
                  'width': '${asset.width}',
                  'height': '${asset.height}',
                  'depth': '${asset.depth}',
                  'vector': 'true',
                } else
                  'failed': 'true',
              }
            : value.attributes,
      );
    }

    return document.copyWith(
      blocks: document.blocks.map(block).toList(growable: false),
    );
  }

  String _renderKey(String path, String expression, bool display) {
    return sha256
        .convert(utf8.encode('$path\u0000$display\u0000$expression'))
        .toString();
  }
}

class _MathExportCandidate {
  const _MathExportCandidate({
    required this.renderKey,
    required this.expression,
    required this.display,
    required this.em,
    required this.ex,
  });

  final String renderKey;
  final String expression;
  final bool display;
  final double em;
  final double ex;
}

class _PreparedMathAsset {
  const _PreparedMathAsset({
    required this.path,
    required this.width,
    required this.height,
    required this.depth,
  });

  final String path;
  final double width;
  final double height;
  final double depth;
}
