import '../writerside/writerside_source_loader.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../markdown/busymark_document.dart';
import '../visualization/generated_svg_normalizer.dart';
import '../visualization/visualization_coordinator.dart';
import '../visualization/visualization_models.dart';
import '../visualization/visualization_renderer.dart';
import '../writerside/writerside_diagram_source_loader.dart';
import 'markdown_export_document.dart';
import 'markdown_pdf_models.dart';
import 'openapi_static_export_mapper.dart';

const _visualizationExportFailureMessage =
    'The visualization could not be rendered for PDF export.';

class MarkdownVisualizationExportPreparation {
  const MarkdownVisualizationExportPreparation({
    required this.blockOverrides,
    required this.warnings,
  });

  final Map<String, MarkdownExportBlock> blockOverrides;
  final List<MarkdownPdfWarning> warnings;
}

class MarkdownVisualizationExportRenderer {
  const MarkdownVisualizationExportRenderer({
    required this.coordinator,
    this.svgNormalizer = const GeneratedSvgNormalizer(),
    this.openApiMapper = const OpenApiStaticExportMapper(),
    this.diagramSourceLoader = const WritersideDiagramSourceLoader(),
    this.maximumBlocks = 64,
    this.maximumGeneratedBytes = 64 * 1024 * 1024,
  });

  final VisualizationCoordinator coordinator;
  final GeneratedSvgNormalizer svgNormalizer;
  final OpenApiStaticExportMapper openApiMapper;
  final WritersideDiagramSourceLoader diagramSourceLoader;
  final int maximumBlocks;
  final int maximumGeneratedBytes;

  Future<MarkdownVisualizationExportPreparation> prepare({
    required BusyDocument document,
    required Directory exportRoot,
    required String documentPath,
    required String workspaceRoot,
    required MarkdownPdfCancellationToken cancellationToken,
  }) async {
    final candidates = _visualizationBlocks(document.blocks).toList();
    if (candidates.isEmpty) {
      return const MarkdownVisualizationExportPreparation(
        blockOverrides: {},
        warnings: [],
      );
    }
    final selected = candidates.take(maximumBlocks).toList(growable: false);
    final keys = [
      for (final block in selected) 'export:$documentPath:${block.id}',
    ];
    cancellationToken.attach(() {
      for (final key in keys) {
        coordinator.cancel(key);
      }
    });
    late List<_RenderedExportBlock> rendered;
    try {
      rendered = await Future.wait([
        for (final (index, block) in selected.indexed)
          _renderBlock(
            block,
            blockKey: keys[index],
            documentPath: documentPath,
            workspaceRoot: workspaceRoot,
            cancellationToken: cancellationToken,
          ),
      ]);
    } finally {
      cancellationToken.detach();
    }
    cancellationToken.throwIfCancelled();

    final generatedDirectory = Directory(
      p.join(exportRoot.path, 'generated-assets'),
    );
    final overrides = <String, MarkdownExportBlock>{};
    final warnings = <MarkdownPdfWarning>[
      if (candidates.length > maximumBlocks)
        MarkdownPdfWarning(
          MarkdownPdfWarningCode.visualizationLimitReached,
          '${candidates.length - maximumBlocks} visualization blocks',
        ),
    ];
    var generatedBytes = 0;
    for (final item in rendered) {
      cancellationToken.throwIfCancelled();
      final result = item.result;
      if (result is OpenApiVisualizationResult) {
        try {
          overrides[item.block.id] = openApiMapper.map(result.reference);
        } on Object {
          warnings.add(_warningFor(item.block));
        }
        continue;
      }
      final asset = _generatedAsset(result);
      if (asset == null ||
          asset.bytes.length > maximumGeneratedBytes - generatedBytes) {
        warnings.add(_warningFor(item.block));
        continue;
      }
      await generatedDirectory.create(recursive: true);
      final digest = sha256.convert(asset.bytes).toString();
      final filename = '$digest.${asset.extension}';
      final target = File(p.join(generatedDirectory.path, filename));
      if (!await target.exists()) {
        await target.writeAsBytes(asset.bytes, flush: true);
        generatedBytes += asset.bytes.length;
      }
      overrides[item.block.id] = MarkdownExportBlock(
        kind: MarkdownExportBlockKind.visualization,
        attributes: {
          'asset': p.posix.join('generated-assets', filename),
          'format': asset.extension,
          'alt': '${item.descriptor.kind.displayName} diagram',
          'renderer': item.descriptor.kind.displayName,
        },
      );
    }
    return MarkdownVisualizationExportPreparation(
      blockOverrides: Map.unmodifiable(overrides),
      warnings: List.unmodifiable(warnings),
    );
  }

  Future<_RenderedExportBlock> _renderBlock(
    BusyBlock block, {
    required String blockKey,
    required String documentPath,
    required String workspaceRoot,
    required MarkdownPdfCancellationToken cancellationToken,
  }) async {
    final descriptor = VisualizationDescriptor.forFenceLanguage(
      block.attributes['language'],
    );
    try {
      var source = block.plainText;
      final sourceReference = block.attributes['src']?.trim() ?? '';
      if (sourceReference.isNotEmpty &&
          !block.attributes.containsKey(writersideResolvedSourceAttribute)) {
        source = await diagramSourceLoader.load(
          reference: sourceReference,
          documentPath: documentPath,
          workspaceRoot: workspaceRoot,
        );
      }
      final result = await coordinator.render(
        VisualizationRenderRequest(
          blockKey: blockKey,
          kind: descriptor.kind,
          source: source,
          sourceStartLine: block.sourceSpan?.startLine ?? 1,
          documentPath: documentPath,
          workspaceRoot: workspaceRoot,
          theme: VisualizationTheme.light,
          profile: VisualizationRenderProfile.pdf,
          engineVersion: descriptor.kind.engineVersion,
          editRevision: 0,
          priority: VisualizationRenderPriority.export,
        ),
      );
      cancellationToken.throwIfCancelled();
      return _RenderedExportBlock(
        block: block,
        descriptor: descriptor,
        result: result,
      );
    } on VisualizationCancelledException {
      cancellationToken.throwIfCancelled();
      return _failedBlock(block, descriptor);
    } on VisualizationSupersededException {
      cancellationToken.throwIfCancelled();
      return _failedBlock(block, descriptor);
    } on Object {
      cancellationToken.throwIfCancelled();
      return _failedBlock(block, descriptor);
    }
  }

  _RenderedExportBlock _failedBlock(
    BusyBlock block,
    VisualizationDescriptor descriptor,
  ) {
    return _RenderedExportBlock(
      block: block,
      descriptor: descriptor,
      result: const FailedVisualizationResult(
        code: 'visualization.exportFailed',
        message: _visualizationExportFailureMessage,
      ),
    );
  }

  _GeneratedExportAsset? _generatedAsset(VisualizationRenderResult result) {
    if (result is SvgVisualizationResult) {
      try {
        final normalized = svgNormalizer.normalize(result.svg);
        final vectorSvg = normalized.vectorSafeSvg;
        if (normalized.hasForeignObject || vectorSvg == null) {
          return null;
        }
        return _GeneratedExportAsset(
          extension: 'svg',
          bytes: Uint8List.fromList(utf8.encode(vectorSvg)),
        );
      } on GeneratedSvgException {
        return null;
      }
    }
    if (result is RasterVisualizationResult) {
      return _GeneratedExportAsset(extension: 'png', bytes: result.pngBytes);
    }
    return null;
  }

  MarkdownPdfWarning _warningFor(BusyBlock block) => MarkdownPdfWarning(
    MarkdownPdfWarningCode.visualizationRenderFailed,
    '${block.attributes['language'] ?? 'visualization'} at line '
    '${block.sourceSpan?.startLine ?? 1}',
  );

  Iterable<BusyBlock> _visualizationBlocks(List<BusyBlock> blocks) sync* {
    for (final block in blocks) {
      if (block.kind == BusyBlockKind.codeBlock &&
          VisualizationDescriptor.maybeForFenceLanguage(
                block.attributes['language'],
              ) !=
              null) {
        yield block;
      }
      yield* _visualizationBlocks(block.children);
    }
  }
}

class _RenderedExportBlock {
  const _RenderedExportBlock({
    required this.block,
    required this.descriptor,
    required this.result,
  });

  final BusyBlock block;
  final VisualizationDescriptor descriptor;
  final VisualizationRenderResult result;
}

class _GeneratedExportAsset {
  const _GeneratedExportAsset({required this.extension, required this.bytes});

  final String extension;
  final Uint8List bytes;
}
