import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../core/anchored_path_guard.dart';
import 'generated_svg_normalizer.dart';
import 'openapi_dependency_resolver.dart';
import 'visualization_models.dart';
import 'visualization_raster_sizing.dart';
import 'visualization_renderer.dart';
import 'web_render_host.dart';

const _d2RendererMismatchMessage = 'D2 was dispatched to the WebKit renderer.';
const _visualizationTimeoutMessage = 'The visualization engine timed out.';

class WebVisualizationRenderer implements VisualizationRenderer {
  const WebVisualizationRenderer({
    required this.host,
    this.svgNormalizer = const GeneratedSvgNormalizer(),
    this.rasterSizingPolicy = const VisualizationRasterSizingPolicy(),
    OpenApiDependencyResolver? openApiDependencyResolver,
    this.maximumSourceCharacters = 500000,
  }) : _openApiDependencyResolver = openApiDependencyResolver;

  final WebRenderHost host;
  final GeneratedSvgNormalizer svgNormalizer;
  final VisualizationRasterSizingPolicy rasterSizingPolicy;
  final OpenApiDependencyResolver? _openApiDependencyResolver;
  final int maximumSourceCharacters;

  OpenApiDependencyResolver get openApiDependencyResolver =>
      _openApiDependencyResolver ?? OpenApiDependencyResolver(host: host);

  @override
  Set<VisualizationRendererKind> get supportedKinds => const {
    VisualizationRendererKind.mermaid,
    VisualizationRendererKind.plantUml,
    VisualizationRendererKind.openApi,
  };

  @override
  Future<VisualizationRenderRequest> prepare(
    VisualizationRenderRequest request,
    VisualizationCancellationToken cancellationToken,
  ) async {
    if (request.source.length > maximumSourceCharacters) {
      return _withPreparationError(
        request,
        'visualization.sourceTooLarge',
        'Visualization source exceeds the size limit.',
      );
    }
    if (request.kind != VisualizationRendererKind.openApi) {
      return request;
    }
    try {
      return await openApiDependencyResolver.resolve(
        request,
        cancellationToken,
      );
    } on OpenApiDependencyException catch (error) {
      return _withPreparationError(
        request,
        error.code,
        error.message,
        line: error.line,
        column: error.column,
      );
    } on AnchoredPathViolation {
      return _withPreparationError(
        request,
        'visualization.openapiUnsafeReference',
        'The OpenAPI reference resolves outside the workspace or through a symbolic link.',
      );
    } on FileSystemException {
      return _withPreparationError(
        request,
        'visualization.openapiReferenceUnavailable',
        'A local OpenAPI reference could not be read.',
      );
    }
  }

  @override
  Future<VisualizationRenderResult> render(
    VisualizationRenderRequest request,
    VisualizationCancellationToken cancellationToken,
  ) async {
    cancellationToken.throwIfCancelled();
    final preparationCode = request.options.values['preparationErrorCode'];
    if (preparationCode is String) {
      final message =
          request.options.values['preparationErrorMessage'] as String? ??
          'Visualization preparation failed.';
      return UnsupportedVisualizationResult(
        feature: preparationCode,
        diagnostics: [
          VisualizationDiagnostic(
            code: preparationCode,
            message: message,
            severity: VisualizationDiagnosticSeverity.error,
            line: (request.options.values['preparationErrorLine'] as num?)
                ?.toInt(),
            column: (request.options.values['preparationErrorColumn'] as num?)
                ?.toInt(),
          ),
        ],
      );
    }
    try {
      return await switch (request.kind) {
        VisualizationRendererKind.mermaid => _renderDiagram(
          await host.renderMermaid(
            source: request.source,
            theme: request.theme,
            cancellationToken: cancellationToken,
          ),
          request,
          cancellationToken,
        ),
        VisualizationRendererKind.plantUml => _renderDiagram(
          await host.renderPlantUml(
            source: request.source,
            theme: request.theme,
            cancellationToken: cancellationToken,
          ),
          request,
          cancellationToken,
        ),
        VisualizationRendererKind.openApi => _renderOpenApi(
          await host.parseOpenApi(
            entryId:
                request.options.values['openApiEntryId'] as String? ??
                'document.openapi',
            source: request.source,
            dependencies: request.dependencies,
            cancellationToken: cancellationToken,
          ),
          request,
          cancellationToken,
        ),
        VisualizationRendererKind.d2 => const FailedVisualizationResult(
          code: 'visualization.rendererMismatch',
          message: _d2RendererMismatchMessage,
          retryable: false,
        ),
      };
    } on TimeoutException {
      return const FailedVisualizationResult(
        code: 'visualization.timeout',
        message: _visualizationTimeoutMessage,
      );
    } on GeneratedSvgException catch (error) {
      return FailedVisualizationResult(
        code: error.code,
        message: error.message,
        retryable: false,
      );
    } on PlatformException catch (error) {
      return FailedVisualizationResult(
        code: error.code,
        message: error.message ?? 'The WebKit visualization host failed.',
      );
    } on WebRenderHostException catch (error) {
      return FailedVisualizationResult(
        code: error.code,
        message: error.message,
      );
    }
  }

  Future<VisualizationRenderResult> _renderDiagram(
    Map<Object?, Object?> response,
    VisualizationRenderRequest request,
    VisualizationCancellationToken cancellationToken,
  ) async {
    cancellationToken.throwIfCancelled();
    final diagnostics = _diagnostics(response['diagnostics']);
    final svg = response['svg'];
    if (svg is! String || svg.trim().isEmpty) {
      return FailedVisualizationResult(
        code: response['code'] as String? ?? 'visualization.invalidSource',
        message:
            response['message'] as String? ??
            '${request.kind.displayName} could not render this block.',
        retryable: false,
        diagnostics: diagnostics,
      );
    }
    final normalized = svgNormalizer.normalize(svg);
    cancellationToken.throwIfCancelled();
    if (normalized.vectorSafeSvg == null) {
      final rasterSize = rasterSizingPolicy.fit(
        width: normalized.width,
        height: normalized.height,
        profile: request.profile,
      );
      final png = await host.rasterizeSvg(
        svg: normalized.browserSafeSvg,
        width: normalized.width,
        height: normalized.height,
        scale: rasterSize.scale,
        cancellationToken: cancellationToken,
      );
      cancellationToken.throwIfCancelled();
      return RasterVisualizationResult(
        pngBytes: png,
        width: rasterSize.pixelWidth,
        height: rasterSize.pixelHeight,
        diagnostics: diagnostics,
      );
    }
    return SvgVisualizationResult(
      svg: normalized.vectorSafeSvg!,
      width: normalized.width,
      height: normalized.height,
      diagnostics: diagnostics,
    );
  }

  VisualizationRenderResult _renderOpenApi(
    Map<Object?, Object?> response,
    VisualizationRenderRequest request,
    VisualizationCancellationToken cancellationToken,
  ) {
    cancellationToken.throwIfCancelled();
    final diagnostics = _diagnostics(response['diagnostics']);
    final reference = response['reference'];
    if (reference is! Map<Object?, Object?>) {
      return FailedVisualizationResult(
        code: response['code'] as String? ?? 'visualization.invalidOpenApi',
        message:
            response['message'] as String? ??
            'The OpenAPI document could not be parsed.',
        retryable: false,
        diagnostics: diagnostics,
      );
    }
    return OpenApiVisualizationResult(
      reference: OpenApiReferenceModel.fromJson(reference),
      content: request.source,
      entryId:
          request.options.values['openApiEntryId'] as String? ??
          'document.openapi',
      dependencies: request.dependencies,
      diagnostics: diagnostics,
    );
  }

  List<VisualizationDiagnostic> _diagnostics(Object? value) {
    return List.unmodifiable(
      (value as List<Object?>? ?? const [])
          .whereType<Map<Object?, Object?>>()
          .map(VisualizationDiagnostic.fromJson),
    );
  }

  VisualizationRenderRequest _withPreparationError(
    VisualizationRenderRequest request,
    String code,
    String message, {
    int? line,
    int? column,
  }) {
    return request.copyWith(
      options: VisualizationRendererOptions({
        ...request.options.values,
        'preparationErrorCode': code,
        'preparationErrorMessage': message,
        if (line != null) 'preparationErrorLine': line,
        if (column != null) 'preparationErrorColumn': column,
      }),
    );
  }
}
