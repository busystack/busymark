import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as p;

import '../app/busymark_design.dart';
import '../app/busymark_glyphs.dart';
import '../app/localization.dart';
import 'visualization_coordinator.dart';
import 'visualization_models.dart';
import 'visualization_providers.dart';
import 'visualization_renderer.dart';

class BusyMarkVisualizationCard extends ConsumerStatefulWidget {
  const BusyMarkVisualizationCard({
    super.key,
    required this.descriptor,
    required this.source,
    required this.sourceFence,
    required this.documentPath,
    required this.workspaceRoot,
    required this.sourceStartLine,
    required this.editRevision,
    required this.blockKey,
    this.priority = VisualizationRenderPriority.visible,
    this.sourceEditor,
    this.onEditSource,
    this.onDiagnosticSelected,
  });

  final VisualizationDescriptor descriptor;
  final String source;
  final String sourceFence;
  final String documentPath;
  final String workspaceRoot;
  final int sourceStartLine;
  final int editRevision;
  final String blockKey;
  final VisualizationRenderPriority priority;
  final Widget? sourceEditor;
  final VoidCallback? onEditSource;
  final ValueChanged<int>? onDiagnosticSelected;

  @override
  ConsumerState<BusyMarkVisualizationCard> createState() =>
      _BusyMarkVisualizationCardState();
}

class _BusyMarkVisualizationCardState
    extends ConsumerState<BusyMarkVisualizationCard> {
  static const _editDebounce = Duration(milliseconds: 260);

  final _transformationController = TransformationController();
  late final VisualizationCoordinator _coordinator;
  Timer? _debounce;
  VisualizationRenderResult? _successfulResult;
  VisualizationRenderResult? _latestResult;
  VisualizationTheme? _theme;
  var _requestSerial = 0;
  var _rendering = false;
  var _showSource = false;

  @override
  void initState() {
    super.initState();
    _coordinator = ref.read(visualizationCoordinatorProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scheduleRender(immediate: true);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context).brightness == Brightness.dark
        ? VisualizationTheme.dark
        : VisualizationTheme.light;
    if (_theme != null && _theme != theme) {
      _theme = theme;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scheduleRender(immediate: true);
        }
      });
    } else {
      _theme = theme;
    }
  }

  @override
  void didUpdateWidget(covariant BusyMarkVisualizationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.blockKey != widget.blockKey) {
      _coordinator.cancel(oldWidget.blockKey);
      _coordinator.clearLastSuccessful(oldWidget.blockKey);
      _successfulResult = null;
      _latestResult = null;
    }
    if (oldWidget.source != widget.source ||
        oldWidget.documentPath != widget.documentPath ||
        oldWidget.workspaceRoot != widget.workspaceRoot ||
        oldWidget.descriptor.kind != widget.descriptor.kind ||
        oldWidget.editRevision != widget.editRevision ||
        oldWidget.priority != widget.priority) {
      _scheduleRender();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _coordinator.cancel(widget.blockKey);
    _coordinator.clearLastSuccessful(widget.blockKey);
    _transformationController.dispose();
    super.dispose();
  }

  void _scheduleRender({bool immediate = false}) {
    _debounce?.cancel();
    _coordinator.cancel(widget.blockKey);
    _requestSerial++;
    final retained =
        _successfulResult ?? _coordinator.lastSuccessfulFor(widget.blockKey);
    if (mounted) {
      setState(() {
        _successfulResult = retained;
        _rendering = true;
      });
    }
    _debounce = Timer(immediate ? Duration.zero : _editDebounce, _render);
  }

  Future<void> _render() async {
    final serial = _requestSerial;
    final theme = _theme ?? VisualizationTheme.light;
    final request = VisualizationRenderRequest(
      blockKey: widget.blockKey,
      kind: widget.descriptor.kind,
      source: widget.source,
      sourceStartLine: widget.sourceStartLine,
      documentPath: widget.documentPath,
      workspaceRoot: widget.workspaceRoot,
      theme: theme,
      profile: VisualizationRenderProfile.preview,
      engineVersion: widget.descriptor.kind.engineVersion,
      editRevision: widget.editRevision,
      priority: widget.priority,
    );
    try {
      final result = await _coordinator.render(request);
      if (!mounted || serial != _requestSerial) {
        return;
      }
      setState(() {
        _latestResult = result;
        if (result.isSuccessful) {
          _successfulResult = result;
          _transformationController.value = Matrix4.identity();
        }
        _rendering = false;
      });
    } on VisualizationSupersededException {
      // The replacement request owns the visible state.
    } on VisualizationCancelledException {
      // Unmounting or replacement deliberately cancels this request.
    } on Object catch (error) {
      if (!mounted || serial != _requestSerial) {
        return;
      }
      setState(() {
        _latestResult = FailedVisualizationResult(
          code: 'visualization.rendererFailure',
          message: error.toString(),
        );
        _rendering = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final displayResult = _successfulResult ?? _latestResult;
    final failedResult = _latestResult?.isSuccessful == false
        ? _latestResult
        : null;
    final stale =
        _successfulResult != null && (_rendering || failedResult != null);
    return Padding(
      padding: BusyMarkInsets.documentCodeBlock,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.panel,
          border: Border.all(color: colors.subtleBorder),
          borderRadius: BorderRadius.circular(BusyMarkRadius.md),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(BusyMarkRadius.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, colors, displayResult),
              Divider(height: 1, color: colors.subtleBorder),
              Padding(
                padding: BusyMarkInsets.documentCodeContent,
                child: _showSource
                    ? _buildSource(context)
                    : _buildOutput(context, displayResult),
              ),
              if (!_showSource && (_rendering || stale))
                _buildStatus(context, stale),
              if (!_showSource && failedResult != null)
                _buildDiagnostics(context, failedResult),
              if (!_showSource &&
                  displayResult != null &&
                  displayResult.diagnostics.isNotEmpty &&
                  !identical(displayResult, failedResult))
                _buildDiagnostics(context, displayResult),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    BusyMarkSurfaceColors colors,
    VisualizationRenderResult? result,
  ) {
    final diagramResult = switch (result) {
      SvgVisualizationResult() || RasterVisualizationResult() => result,
      _ => null,
    };
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        BusyMarkSpacing.md,
        BusyMarkSpacing.xs,
        BusyMarkSpacing.xs,
        BusyMarkSpacing.xs,
      ),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.control,
              borderRadius: BorderRadius.circular(BusyMarkRadius.pill),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BusyMarkSpacing.sm,
                vertical: BusyMarkSpacing.xs,
              ),
              child: Text(
                widget.descriptor.kind.displayName,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
          const Spacer(),
          if (!_showSource && diagramResult != null) ...[
            BusyMarkHeaderIconButton(
              tooltip: context.l10n.visualizationFitWidth,
              icon: BusyMarkGlyphs.fitWidth,
              foregroundColor: colors.mutedForeground,
              onPressed: () =>
                  _transformationController.value = Matrix4.identity(),
            ),
            BusyMarkHeaderIconButton(
              tooltip: context.l10n.fullScreen,
              icon: BusyMarkGlyphs.fullScreen,
              foregroundColor: colors.mutedForeground,
              onPressed: () => _openFullScreen(context, diagramResult),
            ),
            BusyMarkHeaderIconButton(
              tooltip: context.l10n.visualizationCopyImage,
              icon: BusyMarkGlyphs.copy,
              foregroundColor: colors.mutedForeground,
              onPressed: () => _copyImage(context, diagramResult),
            ),
            BusyMarkHeaderIconButton(
              tooltip: context.l10n.visualizationSaveImage,
              icon: BusyMarkGlyphs.save,
              foregroundColor: colors.mutedForeground,
              onPressed: () => _saveImage(context, diagramResult),
            ),
          ],
          if (widget.onEditSource != null)
            BusyMarkHeaderIconButton(
              tooltip: context.l10n.editor,
              icon: BusyMarkGlyphs.edit,
              foregroundColor: colors.mutedForeground,
              onPressed: _showSourceForEditing,
            ),
          BusyMarkHeaderIconButton(
            tooltip: _showSource
                ? context.l10n.visualizationShowRender
                : context.l10n.visualizationShowSource,
            icon: _showSource
                ? BusyMarkGlyphs.preview
                : BusyMarkGlyphs.sourceView,
            foregroundColor: colors.mutedForeground,
            selected: _showSource,
            onPressed: () => setState(() => _showSource = !_showSource),
          ),
        ],
      ),
    );
  }

  Widget _buildSource(BuildContext context) {
    final editor = widget.sourceEditor;
    if (editor != null) {
      return editor;
    }
    return SelectableText(
      widget.sourceFence,
      textDirection: TextDirection.ltr,
      style: (Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
          .copyWith(
            fontFamily: BusyMarkTypography.monoFontFamily,
            fontFamilyFallback: BusyMarkTypography.monoFontFamilyFallback,
            height: BusyMarkTypography.codeLineHeight,
          ),
    );
  }

  Widget _buildOutput(BuildContext context, VisualizationRenderResult? result) {
    if (result is SvgVisualizationResult ||
        result is RasterVisualizationResult) {
      return _DiagramViewport(
        result: result!,
        transformationController: _transformationController,
      );
    }
    if (result is OpenApiVisualizationResult) {
      return _OpenApiSummary(
        result: result,
        onOpenReference: () => _openApiReference(result),
      );
    }
    if (_rendering) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return SizedBox(
      height: 96,
      child: Center(child: Text(context.l10n.visualizationRenderFailed)),
    );
  }

  Widget _buildStatus(BuildContext context, bool stale) {
    final colors = BusyMarkSurfaceColors.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        BusyMarkSpacing.mdPlus,
        0,
        BusyMarkSpacing.mdPlus,
        BusyMarkSpacing.sm,
      ),
      child: Row(
        children: [
          if (_rendering) ...[
            const SizedBox.square(
              dimension: BusyMarkSizes.iconSm,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: BusyMarkSpacing.sm),
          ],
          Expanded(
            child: Text(
              stale
                  ? context.l10n.visualizationStale
                  : context.l10n.visualizationRendering,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: colors.mutedForeground),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnostics(
    BuildContext context,
    VisualizationRenderResult result,
  ) {
    final diagnostics = result.diagnostics.isEmpty
        ? [
            VisualizationDiagnostic(
              code: _failureCode(result),
              message: _failureMessage(context, result),
              severity: VisualizationDiagnosticSeverity.error,
            ),
          ]
        : result.diagnostics;
    final colors = BusyMarkSurfaceColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.admonitionWarning,
        border: Border(top: BorderSide(color: colors.subtleBorder)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BusyMarkSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final diagnostic in diagnostics.take(5))
              InkWell(
                onTap:
                    widget.onDiagnosticSelected == null ||
                        diagnostic.line == null
                    ? null
                    : () => _selectDiagnostic(diagnostic),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: BusyMarkSpacing.xs,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        diagnostic.severity ==
                                VisualizationDiagnosticSeverity.error
                            ? BusyMarkGlyphs.error
                            : BusyMarkGlyphs.warning,
                        size: BusyMarkSizes.iconSm,
                      ),
                      const SizedBox(width: BusyMarkSpacing.sm),
                      Expanded(child: Text(_diagnosticMessage(diagnostic))),
                    ],
                  ),
                ),
              ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () => _scheduleRender(immediate: true),
                icon: const Icon(
                  BusyMarkGlyphs.refresh,
                  size: BusyMarkSizes.iconSm,
                ),
                label: Text(context.l10n.visualizationRetry),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _failureCode(VisualizationRenderResult result) => switch (result) {
    FailedVisualizationResult() => result.code,
    UnsupportedVisualizationResult() => result.feature,
    _ => 'visualization.renderFailed',
  };

  String _failureMessage(
    BuildContext context,
    VisualizationRenderResult result,
  ) => switch (result) {
    FailedVisualizationResult() => result.message,
    _ => context.l10n.visualizationRenderFailed,
  };

  void _showSourceForEditing() {
    setState(() => _showSource = true);
    widget.onEditSource?.call();
  }

  void _selectDiagnostic(VisualizationDiagnostic diagnostic) {
    setState(() => _showSource = true);
    widget.onDiagnosticSelected?.call(
      diagnostic.documentLine(widget.sourceStartLine),
    );
  }

  String _diagnosticMessage(VisualizationDiagnostic diagnostic) {
    final sourceId = diagnostic.sourceId;
    if (sourceId == null || sourceId.isEmpty) {
      return diagnostic.message;
    }
    final location = diagnostic.sourceLine == null
        ? ''
        : ':${diagnostic.sourceLine}'
              '${diagnostic.sourceColumn == null ? '' : ':${diagnostic.sourceColumn}'}';
    return '$sourceId$location: ${diagnostic.message}';
  }

  Future<void> _openApiReference(OpenApiVisualizationResult result) async {
    try {
      await ref
          .read(webRenderHostProvider)
          .openOpenApiReference(
            title: result.reference.title,
            entryId: result.entryId,
            source: result.content,
            dependencies: result.dependencies,
            theme: _theme ?? VisualizationTheme.light,
          );
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _saveImage(
    BuildContext context,
    VisualizationRenderResult result,
  ) async {
    final svg = result is SvgVisualizationResult;
    final extension = svg ? 'svg' : 'png';
    final location = await getSaveLocation(
      suggestedName:
          '${widget.descriptor.kind.canonicalFence}-diagram.$extension',
      initialDirectory: widget.documentPath.isEmpty
          ? null
          : p.dirname(widget.documentPath),
      acceptedTypeGroups: [
        XTypeGroup(
          label: '${svg ? 'SVG' : 'PNG'} ${context.l10n.image}',
          extensions: [extension],
          mimeTypes: [svg ? 'image/svg+xml' : 'image/png'],
        ),
      ],
      confirmButtonText: context.l10n.save,
    );
    if (location == null) {
      return;
    }
    final path = p.extension(location.path).toLowerCase() == '.$extension'
        ? location.path
        : '${location.path}.$extension';
    final bytes = svg
        ? utf8.encode(result.svg)
        : (result as RasterVisualizationResult).pngBytes;
    await File(path).writeAsBytes(bytes, flush: true);
    if (mounted) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text(this.context.l10n.visualizationSaved(p.basename(path))),
        ),
      );
    }
  }

  Future<void> _copyImage(
    BuildContext context,
    VisualizationRenderResult result,
  ) async {
    try {
      final host = ref.read(webRenderHostProvider);
      final Uint8List pngBytes;
      if (result is RasterVisualizationResult) {
        pngBytes = result.pngBytes;
      } else if (result is SvgVisualizationResult) {
        final maximumDimensionScale =
            4096 / math.max(result.width, result.height);
        final maximumPixelScale = math.sqrt(
          16000000 / (result.width * result.height),
        );
        final scale = math.min(
          2.0,
          math.min(maximumDimensionScale, maximumPixelScale),
        );
        pngBytes = await host.rasterizeSvg(
          svg: result.svg,
          width: result.width,
          height: result.height,
          scale: scale,
          cancellationToken: VisualizationCancellationToken(),
        );
      } else {
        return;
      }
      await host.copyPngToClipboard(pngBytes);
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text(this.context.l10n.visualizationImageCopied)),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          this.context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _openFullScreen(
    BuildContext context,
    VisualizationRenderResult result,
  ) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog.fullscreen(
        child: _FullScreenDiagram(
          title: widget.descriptor.kind.displayName,
          result: result,
        ),
      ),
    );
  }
}

class _FullScreenDiagram extends StatefulWidget {
  const _FullScreenDiagram({required this.title, required this.result});

  final String title;
  final VisualizationRenderResult result;

  @override
  State<_FullScreenDiagram> createState() => _FullScreenDiagramState();
}

class _FullScreenDiagramState extends State<_FullScreenDiagram> {
  final _transformationController = TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(BusyMarkGlyphs.windowClose),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(BusyMarkSpacing.lg),
        child: Center(
          child: _DiagramViewport(
            result: widget.result,
            transformationController: _transformationController,
            maximumHeight: double.infinity,
          ),
        ),
      ),
    );
  }
}

class _DiagramViewport extends StatelessWidget {
  const _DiagramViewport({
    required this.result,
    required this.transformationController,
    this.maximumHeight = 520,
  });

  final VisualizationRenderResult result;
  final TransformationController transformationController;
  final double maximumHeight;

  @override
  Widget build(BuildContext context) {
    final (width, height) = switch (result) {
      SvgVisualizationResult(:final width, :final height) => (width, height),
      RasterVisualizationResult(:final width, :final height) => (
        width.toDouble(),
        height.toDouble(),
      ),
      _ => (1.0, 1.0),
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : BusyMarkSizes.documentContentWidth;
        final naturalHeight = availableWidth * height / width;
        final viewportHeight = maximumHeight.isFinite
            ? naturalHeight.clamp(160.0, maximumHeight)
            : constraints.maxHeight;
        return SizedBox(
          width: availableWidth,
          height: viewportHeight.isFinite ? viewportHeight : 600,
          child: InteractiveViewer(
            transformationController: transformationController,
            minScale: 0.5,
            maxScale: 8,
            boundaryMargin: const EdgeInsets.all(BusyMarkSpacing.xxl),
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: width,
                  height: height,
                  child: switch (result) {
                    SvgVisualizationResult(:final svg) => SvgPicture.string(
                      svg,
                      fit: BoxFit.contain,
                      semanticsLabel: context.l10n.image,
                    ),
                    RasterVisualizationResult(:final pngBytes) => Image.memory(
                      pngBytes,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                    _ => const SizedBox.shrink(),
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OpenApiSummary extends StatefulWidget {
  const _OpenApiSummary({required this.result, required this.onOpenReference});

  final OpenApiVisualizationResult result;
  final VoidCallback onOpenReference;

  @override
  State<_OpenApiSummary> createState() => _OpenApiSummaryState();
}

class _OpenApiSummaryState extends State<_OpenApiSummary> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final reference = widget.result.reference;
    final colors = BusyMarkSurfaceColors.of(context);
    final query = _query.trim().toLowerCase();
    final operations = query.isEmpty
        ? reference.operations
        : reference.operations
              .where(
                (operation) =>
                    operation.method.toLowerCase().contains(query) ||
                    operation.path.toLowerCase().contains(query) ||
                    operation.summary.toLowerCase().contains(query) ||
                    operation.operationId.toLowerCase().contains(query) ||
                    operation.tags.any(
                      (tag) => tag.toLowerCase().contains(query),
                    ),
              )
              .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(reference.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: BusyMarkSpacing.xs),
        Text(
          [
            if (reference.apiVersion.isNotEmpty) reference.apiVersion,
            if (reference.specificationVersion.isNotEmpty)
              'OpenAPI ${reference.specificationVersion}',
          ].join(' · '),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.mutedForeground),
        ),
        const SizedBox(height: BusyMarkSpacing.md),
        Wrap(
          spacing: BusyMarkSpacing.sm,
          runSpacing: BusyMarkSpacing.sm,
          children: [
            _SummaryChip(
              label: reference.valid
                  ? context.l10n.visualizationValid
                  : context.l10n.visualizationInvalid,
              icon: reference.valid
                  ? BusyMarkGlyphs.check
                  : BusyMarkGlyphs.error,
            ),
            _SummaryChip(
              label:
                  '${context.l10n.visualizationServers}: ${reference.serverCount}',
            ),
            _SummaryChip(
              label:
                  '${context.l10n.visualizationPaths}: ${reference.pathCount}',
            ),
            _SummaryChip(
              label:
                  '${context.l10n.visualizationOperations}: ${reference.operationCount}',
            ),
          ],
        ),
        if (reference.tags.isNotEmpty) ...[
          const SizedBox(height: BusyMarkSpacing.md),
          Text(
            '${context.l10n.visualizationTags}: ${reference.tags.join(', ')}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: BusyMarkSpacing.md),
        TextField(
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: const Icon(BusyMarkGlyphs.search),
            hintText: context.l10n.visualizationSearchOperations,
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: BusyMarkSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: operations.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(BusyMarkSpacing.lg),
                  child: Center(
                    child: Text(context.l10n.visualizationNoOperations),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: operations.length,
                  itemBuilder: (context, index) {
                    final operation = operations[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: BusyMarkSpacing.xs,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 58,
                            child: Text(
                              operation.method,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  operation.path,
                                  textDirection: TextDirection.ltr,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontFamily:
                                            BusyMarkTypography.monoFontFamily,
                                      ),
                                ),
                                if (operation.summary.isNotEmpty)
                                  Text(
                                    operation.summary,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: colors.mutedForeground,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: BusyMarkSpacing.md),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FilledButton.icon(
            onPressed: widget.onOpenReference,
            icon: const Icon(BusyMarkGlyphs.externalLink),
            label: Text(context.l10n.visualizationOpenApiReference),
          ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.control,
        borderRadius: BorderRadius.circular(BusyMarkRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BusyMarkSpacing.sm,
          vertical: BusyMarkSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: BusyMarkSizes.iconSm),
              const SizedBox(width: BusyMarkSpacing.xs),
            ],
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
