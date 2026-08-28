import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../app/app_settings.dart';
import '../app/busymark_design.dart';
import '../app/busymark_dialogs.dart';
import '../app/busymark_toast.dart';
import '../app/localization.dart';
import '../math/math_providers.dart';
import '../platform/linux_header_bar_service.dart';
import '../visualization/visualization_providers.dart';
import '../workspace/workspace_controller.dart';
import '../workspace/workspace_model.dart';
import '../workspace/workspace_safety.dart';
import '../writerside/writerside_model.dart';
import 'markdown_math_export.dart';
import 'markdown_pdf_export_service.dart';
import 'markdown_pdf_models.dart';
import 'markdown_visualization_export.dart';
import 'writerside_pdf_export_service.dart';
import 'writerside_pdf_models.dart';

final writersidePdfExportServiceProvider = Provider<WritersidePdfExportService>(
  (ref) => WritersidePdfExportService(
    markdownExporter: MarkdownPdfExportService(
      visualizationRenderer: MarkdownVisualizationExportRenderer(
        coordinator: ref.watch(visualizationCoordinatorProvider),
      ),
      mathRenderer: MarkdownMathExportRenderer(
        coordinator: ref.watch(mathCoordinatorProvider),
      ),
    ),
  ),
);

bool canExportWritersidePdf(WorkspaceState state) {
  final workspace = state.workspace;
  final module = workspace?.writersideModule;
  return workspace?.kind == WorkspaceKind.writersideModule &&
      module != null &&
      module.instances.any((instance) => !instance.isLibrary);
}

String defaultWritersideModuleName(WritersideModule module) {
  final configured = module.config.moduleName?.trim();
  return configured == null || configured.isEmpty
      ? p.basename(p.normalize(module.rootPath))
      : configured;
}

Future<void> exportWritersideModuleToPdf(
  BuildContext context,
  WidgetRef ref,
) async {
  if (!canExportWritersidePdf(ref.read(workspaceControllerProvider))) {
    return;
  }
  if (!await confirmSafeToContinue(context, ref) || !context.mounted) {
    return;
  }
  final snapshot = ref.read(workspaceControllerProvider);
  final workspace = snapshot.workspace;
  final module = workspace?.writersideModule;
  if (workspace == null || module == null) {
    return;
  }
  final instances = module.instances
      .where((instance) => !instance.isLibrary)
      .toList(growable: false);
  final storedInstanceId = ref
      .read(appSettingsControllerProvider)
      .selectedWritersideInstanceId(workspace.rootPath);
  final initialInstance = instances
      .where((instance) => instance.id == storedInstanceId)
      .firstOrNull;
  final headerBar = ref.read(linuxHeaderBarServiceProvider);
  final selection =
      await showBusyMarkModalEditorDialog<_WritersidePdfSelection>(
        context,
        headerBarService: headerBar.isAvailable ? headerBar : null,
        maxWidth: BusyMarkSizes.dialog,
        builder: (context) => _WritersidePdfOptionsDialog(
          instances: instances,
          initialInstance: initialInstance ?? instances.first,
        ),
      );
  if (selection == null || !context.mounted) {
    return;
  }
  unawaited(
    ref
        .read(appSettingsControllerProvider.notifier)
        .selectWritersideInstance(workspace.rootPath, selection.instance.id),
  );
  final location = await getSaveLocation(
    acceptedTypeGroups: [
      XTypeGroup(
        label: context.l10n.fileTypePdf,
        extensions: const ['pdf'],
        mimeTypes: const ['application/pdf'],
      ),
    ],
    suggestedName: '${selection.instance.id}.pdf',
    initialDirectory: module.rootPath,
    confirmButtonText: context.l10n.export,
  );
  if (location == null || !context.mounted) {
    return;
  }
  final destination = _withPdfExtension(location.path);
  var overwrite = false;
  if (await FileSystemEntity.type(destination, followLinks: false) !=
      FileSystemEntityType.notFound) {
    if (!context.mounted ||
        !await _confirmOverwrite(context, headerBar, destination)) {
      return;
    }
    overwrite = true;
  }
  if (!context.mounted) {
    return;
  }
  final token = WritersidePdfCancellationToken();
  final request = WritersidePdfExportRequest(
    moduleRoot: module.rootPath,
    instanceId: selection.instance.id,
    destinationPath: destination,
    overwrite: overwrite,
    options: selection.options,
  );
  final outcome = await showBusyMarkModalDialog<_WritersidePdfOutcome>(
    context,
    headerBarService: headerBar.isAvailable ? headerBar : null,
    barrierDismissible: false,
    builder: (context) => _WritersidePdfProgressDialog(
      cancellationToken: token,
      operation: () => ref
          .read(writersidePdfExportServiceProvider)
          .export(request, cancellationToken: token),
    ),
  );
  if (outcome == null || !context.mounted) {
    return;
  }
  if (outcome.failure case final failure?) {
    if (failure.code != WritersidePdfFailureCode.cancelled) {
      await _showWritersidePdfError(context, headerBar, failure);
    }
    return;
  }
  final result = outcome.result!;
  final fileName = p.basename(result.destinationPath);
  BusyMarkToastOverlay.show(
    context,
    message: context.l10n.pdfExported(fileName),
    actionLabel: context.l10n.open,
    onAction: () => unawaited(
      launchUrl(
        Uri.file(result.destinationPath),
        mode: LaunchMode.externalApplication,
      ),
    ),
  );
}

class _WritersidePdfOptionsDialog extends StatefulWidget {
  const _WritersidePdfOptionsDialog({
    required this.instances,
    required this.initialInstance,
  });

  final List<WritersideInstance> instances;
  final WritersideInstance initialInstance;

  @override
  State<_WritersidePdfOptionsDialog> createState() =>
      _WritersidePdfOptionsDialogState();
}

class _WritersidePdfOptionsDialogState
    extends State<_WritersidePdfOptionsDialog> {
  late WritersideInstance _instance;
  var _pageSize = MarkdownPdfPageSize.a4;
  var _orientation = MarkdownPdfOrientation.portrait;
  var _margin = MarkdownPdfMargin.normal;
  var _pageNumbers = true;

  @override
  void initState() {
    super.initState();
    _instance = widget.initialInstance;
  }

  @override
  Widget build(BuildContext context) {
    return BusyMarkModalEditorScaffold(
      title: context.l10n.exportWritersideAsPdf,
      cancelLabel: context.l10n.cancel,
      saveLabel: context.l10n.export,
      onCancel: () => Navigator.pop(context),
      onSave: _submit,
      children: [
        BusyMarkGroupedList(
          title: context.l10n.writersidePdfContent,
          filled: true,
          children: [
            BusyMarkComboRow<WritersideInstance>(
              title: context.l10n.instanceName,
              values: widget.instances,
              selected: _instance,
              labelFor: (instance) => '${instance.name} (${instance.id})',
              onSelected: (instance) => setState(() => _instance = instance),
            ),
          ],
        ),
        BusyMarkGroupedList(
          title: context.l10n.writersidePdfPage,
          filled: true,
          children: [
            BusyMarkComboRow<MarkdownPdfPageSize>(
              title: context.l10n.pdfPageSize,
              values: MarkdownPdfPageSize.values,
              selected: _pageSize,
              labelFor: (value) => switch (value) {
                MarkdownPdfPageSize.a4 => context.l10n.pdfPageSizeA4,
                MarkdownPdfPageSize.letter => context.l10n.pdfPageSizeLetter,
              },
              onSelected: (value) => setState(() => _pageSize = value),
            ),
            BusyMarkComboRow<MarkdownPdfOrientation>(
              title: context.l10n.pdfOrientation,
              values: MarkdownPdfOrientation.values,
              selected: _orientation,
              labelFor: (value) => switch (value) {
                MarkdownPdfOrientation.portrait => context.l10n.pdfPortrait,
                MarkdownPdfOrientation.landscape => context.l10n.pdfLandscape,
              },
              onSelected: (value) => setState(() => _orientation = value),
            ),
            BusyMarkComboRow<MarkdownPdfMargin>(
              title: context.l10n.pdfMargins,
              values: MarkdownPdfMargin.values,
              selected: _margin,
              labelFor: (value) => switch (value) {
                MarkdownPdfMargin.narrow => context.l10n.pdfMarginNarrow,
                MarkdownPdfMargin.normal => context.l10n.pdfMarginNormal,
                MarkdownPdfMargin.wide => context.l10n.pdfMarginWide,
              },
              onSelected: (value) => setState(() => _margin = value),
            ),
            BusyMarkSwitchRow(
              title: context.l10n.pdfIncludePageNumbers,
              value: _pageNumbers,
              onChanged: (value) => setState(() => _pageNumbers = value),
            ),
          ],
        ),
        const SizedBox(height: BusyMarkSpacing.lg),
      ],
    );
  }

  void _submit() {
    Navigator.pop(
      context,
      _WritersidePdfSelection(
        instance: _instance,
        options: MarkdownPdfOptions(
          pageSize: _pageSize,
          orientation: _orientation,
          margin: _margin,
          pageNumbers: _pageNumbers,
        ),
      ),
    );
  }
}

class _WritersidePdfSelection {
  const _WritersidePdfSelection({
    required this.instance,
    required this.options,
  });

  final WritersideInstance instance;
  final MarkdownPdfOptions options;
}

class _WritersidePdfProgressDialog extends StatefulWidget {
  const _WritersidePdfProgressDialog({
    required this.operation,
    required this.cancellationToken,
  });

  final Future<WritersidePdfExportResult> Function() operation;
  final WritersidePdfCancellationToken cancellationToken;

  @override
  State<_WritersidePdfProgressDialog> createState() =>
      _WritersidePdfProgressDialogState();
}

class _WritersidePdfProgressDialogState
    extends State<_WritersidePdfProgressDialog> {
  var _cancelling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    try {
      final result = await widget.operation();
      if (mounted) {
        Navigator.pop(context, _WritersidePdfOutcome.success(result));
      }
    } on WritersidePdfExportException catch (failure) {
      if (mounted) {
        Navigator.pop(context, _WritersidePdfOutcome.failure(failure));
      }
    } on Object catch (error) {
      if (mounted) {
        Navigator.pop(
          context,
          _WritersidePdfOutcome.failure(
            WritersidePdfExportException(
              WritersidePdfFailureCode.fileSystem,
              detail: error.toString(),
              cause: error,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: BusyMarkDialogShell(
        title: context.l10n.exportingWritersidePdf,
        closable: false,
        maxWidth: 440,
        actions: [
          BusyMarkDialogButton(
            label: context.l10n.cancel,
            onPressed: _cancelling
                ? null
                : () {
                    setState(() => _cancelling = true);
                    widget.cancellationToken.cancel();
                  },
          ),
        ],
        children: const [
          Center(child: CircularProgressIndicator()),
          SizedBox(height: BusyMarkSpacing.md),
        ],
      ),
    );
  }
}

class _WritersidePdfOutcome {
  const _WritersidePdfOutcome._({this.result, this.failure});

  factory _WritersidePdfOutcome.success(WritersidePdfExportResult result) =>
      _WritersidePdfOutcome._(result: result);

  factory _WritersidePdfOutcome.failure(WritersidePdfExportException failure) =>
      _WritersidePdfOutcome._(failure: failure);

  final WritersidePdfExportResult? result;
  final WritersidePdfExportException? failure;
}

Future<bool> _confirmOverwrite(
  BuildContext context,
  LinuxHeaderBarService headerBar,
  String path,
) async {
  return await showBusyMarkModalDialog<bool>(
        context,
        headerBarService: headerBar.isAvailable ? headerBar : null,
        builder: (context) => BusyMarkDialogShell(
          title: context.l10n.warning,
          actions: [
            BusyMarkDialogButton(
              label: context.l10n.cancel,
              onPressed: () => Navigator.pop(context, false),
            ),
            BusyMarkDialogButton(
              label: context.l10n.overwrite,
              destructive: true,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
          children: [Text(context.l10n.errorPathAlreadyExists(path))],
        ),
      ) ??
      false;
}

Future<void> _showWritersidePdfError(
  BuildContext context,
  LinuxHeaderBarService headerBar,
  WritersidePdfExportException failure,
) {
  final message = switch (failure.code) {
    WritersidePdfFailureCode.exporterUnavailable =>
      context.l10n.pdfExportUnavailable,
    WritersidePdfFailureCode.timedOut => context.l10n.pdfExportTimedOut,
    WritersidePdfFailureCode.destinationExists =>
      context.l10n.errorPathAlreadyExists(failure.detail),
    WritersidePdfFailureCode.invalidRequest ||
    WritersidePdfFailureCode.buildFailed ||
    WritersidePdfFailureCode.invalidOutput ||
    WritersidePdfFailureCode.fileSystem ||
    WritersidePdfFailureCode.cancelled => context.l10n.pdfExportFailed,
  };
  return showBusyMarkModalDialog<void>(
    context,
    headerBarService: headerBar.isAvailable ? headerBar : null,
    builder: (context) => BusyMarkDialogShell(
      title: context.l10n.exportWritersideAsPdf,
      maxWidth: BusyMarkSizes.dialog,
      actions: [
        BusyMarkDialogButton(
          label: MaterialLocalizations.of(context).okButtonLabel,
          suggested: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
      children: [
        Text(message),
        if (failure.detail.trim().isNotEmpty) ...[
          const SizedBox(height: BusyMarkSpacing.md),
          SelectionArea(
            child: Text(
              failure.detail,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ],
    ),
  );
}

String _withPdfExtension(String path) {
  final normalized = p.normalize(path);
  return p.extension(normalized).toLowerCase() == '.pdf'
      ? normalized
      : '$normalized.pdf';
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
