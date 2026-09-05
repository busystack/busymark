import 'dart:async';
import 'dart:convert';
import '../math/math_coordinator.dart';
import '../math/math_models.dart';
import '../math/math_svg_preprocessor.dart';
import '../visualization/visualization_coordinator.dart';
import '../visualization/visualization_models.dart';
import '../visualization/visualization_renderer.dart';
import '../writerside/writerside_diagram_source_loader.dart';
import '../writerside/writerside_source_loader.dart';
import '../markdown/busymark_document.dart';
import 'html_export_assets.dart';
import 'html_export_models.dart';
import 'markdown_export_document.dart';
import 'openapi_static_export_mapper.dart';

class HtmlMathImage {
  const HtmlMathImage(this.url, this.width, this.height, this.depth);
  final String url;
  final double width, height, depth;
}

class HtmlGraphic {
  const HtmlGraphic({this.url, this.reference});
  final String? url;
  final MarkdownExportBlock? reference;
}

/// Uses BusyMark's native/offline coordinators with HTML sizing and job identity.
class HtmlRichContent {
  HtmlRichContent({
    required this.assets,
    required this.token,
    required this.warnings,
    required this.exportId,
    this.options = const HtmlExportOptions(),
    this.math,
    this.visualization,
    this.limits = const HtmlExportLimits(),
  });
  final HtmlExportOptions options;
  final HtmlExportAssets assets;
  final HtmlExportCancellationToken token;
  final List<HtmlExportWarning> warnings;
  final MathCoordinator? math;
  final VisualizationCoordinator? visualization;
  final String exportId;
  final HtmlExportLimits limits;
  int _occurrence = 0;
  final Map<String, CapturedVisualizationRequest?> _captured = {};
  final Map<String, String> _captureErrors = {};

  Future<void> captureDiagram(
    BusyBlock block,
    String sourcePath,
    String root,
    String occurrenceId,
  ) async {
    if (_captured.length >= limits.graphics) return;
    token.check();
    final cancellation = VisualizationCancellationToken();
    token.attach(cancellation.cancel);
    try {
      final descriptor = VisualizationDescriptor.forFenceLanguage(
        block.attributes['language'],
      );
      var source = block.plainText;
      if (block.attributes['src'] case final reference?
          when !block.attributes.containsKey(
            writersideResolvedSourceAttribute,
          )) {
        source = await const WritersideDiagramSourceLoader().load(
          reference: reference,
          documentPath: sourcePath,
          workspaceRoot: root,
        );
      }
      final request = VisualizationRenderRequest(
        blockKey: 'html:$exportId:$occurrenceId',
        kind: descriptor.kind,
        source: source,
        sourceStartLine: block.sourceSpan?.startLine ?? 1,
        documentPath: sourcePath,
        workspaceRoot: root,
        theme: VisualizationTheme.light,
        profile: VisualizationRenderProfile.html,
        engineVersion: descriptor.kind.engineVersion,
        editRevision: 0,
        priority: VisualizationRenderPriority.export,
      );
      _captured[occurrenceId] = await visualization
          ?.capture(request, cancellation)
          .timeout(limits.renderTimeout);
    } on Object catch (error) {
      token.check();
      _captureErrors[occurrenceId] = error.toString();
      _captured[occurrenceId] = null;
    } finally {
      cancellation.cancel();
      token.detach(cancellation.cancel);
    }
  }

  Future<T?> _render<T>(
    String sourcePath,
    int line,
    String kind,
    Future<T> Function(String key) action,
    void Function(String key) cancel,
  ) async {
    token.check();
    final key = 'html:$exportId:$sourcePath:${_occurrence++}';
    if (_occurrence > limits.graphics) {
      warnings.add(
        HtmlExportWarning(
          'render.limit',
          'Generated graphics limit reached; $kind source is shown.',
          sourcePath: sourcePath,
          line: line,
        ),
      );
      return null;
    }
    void stop() => cancel(key);
    token.attach(stop);
    try {
      return await action(key).timeout(limits.renderTimeout);
    } on Object catch (error) {
      token.check();
      warnings.add(
        HtmlExportWarning(
          'render.failed',
          '$kind could not be rendered; its source is shown. ${error is HtmlExportException ? error.message : error.toString()}',
          sourcePath: sourcePath,
          line: line,
        ),
      );
      return null;
    } finally {
      token.detach(stop);
      stop();
    }
  }

  Future<HtmlMathImage?> formula(
    String expression,
    bool display,
    String sourcePath,
    int line, {
    double fontSize = 17,
  }) => _render(sourcePath, line, 'Mathematics', (key) async {
    if (math == null) throw StateError('Math renderer unavailable');
    final results = await math!.renderAll([
      MathRenderRequest(
        expressionId: key,
        expression: expression,
        display: display,
        blockKey: key,
        editRevision: 0,
        em: fontSize,
        ex: fontSize / 2,
        containerWidth: options.mathContainerWidth,
        renderProfile: 'html',
      ),
    ]);
    final result = results.single;
    if (result is! RenderedMathResult) {
      throw StateError('Math rendering failed');
    }
    final svg = const MathSvgPreprocessor().resolveCurrentColor(
      result.vectorSvg,
      '#20242b',
    );
    final url = await assets.bytesAsset(utf8.encode(svg), '.svg');
    return HtmlMathImage(url, result.width, result.height, result.depth);
  }, (key) => math?.cancel(key));

  Future<HtmlGraphic?> diagram(
    BusyBlock block,
    String sourcePath,
    String root,
    String occurrenceId,
  ) => _render(
    sourcePath,
    block.sourceSpan?.startLine ?? 1,
    block.attributes['language'] ?? 'Diagram',
    (key) async {
      final captured = _captured[occurrenceId];
      if (captured == null || visualization == null) {
        throw HtmlExportException(
          _captureErrors[occurrenceId] ??
              'The diagram renderer or prepared source is unavailable.',
        );
      }
      final result = await visualization!.renderCaptured(captured);
      if (result is OpenApiVisualizationResult) {
        return HtmlGraphic(
          reference: const OpenApiStaticExportMapper().map(result.reference),
        );
      }
      if (result is SvgVisualizationResult) {
        return HtmlGraphic(
          url: await assets.bytesAsset(utf8.encode(result.svg), '.svg'),
        );
      }
      if (result is RasterVisualizationResult) {
        return HtmlGraphic(
          url: await assets.bytesAsset(result.pngBytes, '.png'),
        );
      }
      throw HtmlExportException(
        result is FailedVisualizationResult
            ? result.message
            : 'The diagram renderer returned unsupported output.',
      );
    },
    (_) {
      final captured = _captured[occurrenceId];
      if (captured != null) visualization?.cancel(captured.request.blockKey);
    },
  );
}
