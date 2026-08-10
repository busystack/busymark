import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../app/busymark_dialogs.dart';
import '../app/busymark_design.dart';
import '../app/busymark_glyphs.dart';
import '../app/localization.dart';
import '../platform/linux_header_bar_service.dart';
import '../workspace/workspace_model.dart';
import '../workspace/workspace_controller.dart';
import 'markdown_pdf_export_service.dart';
import 'markdown_pdf_models.dart';

final markdownPdfExportServiceProvider = Provider<MarkdownPdfExportService>(
  (ref) => const MarkdownPdfExportService(),
);

bool canExportActiveMarkdown(WorkspaceState state) {
  final workspace = state.workspace;
  if (workspace == null ||
      workspace.kind == WorkspaceKind.writersideModule ||
      workspace.markdown == null) {
    return false;
  }
  return switch (workspace.kind) {
    WorkspaceKind.untitledMarkdown || WorkspaceKind.singleMarkdown => true,
    WorkspaceKind.markdownFolder =>
      workspace.activeFilePath != null &&
          workspace.files.any(
            (file) =>
                file.absolutePath == workspace.activeFilePath &&
                file.kind == DocumentKind.markdown,
          ),
    WorkspaceKind.writersideModule => false,
  };
}

Future<void> exportActiveMarkdownToPdf(
  BuildContext context,
  WidgetRef ref,
) async {
  final snapshot = ref.read(workspaceControllerProvider);
  if (!canExportActiveMarkdown(snapshot)) {
    return;
  }
  final workspace = snapshot.workspace!;
  final headerBar = ref.read(linuxHeaderBarServiceProvider);
  final options = await showBusyMarkModalDialog<MarkdownPdfOptions>(
    context,
    headerBarService: headerBar.isAvailable ? headerBar : null,
    builder: (context) => const _MarkdownPdfOptionsDialog(),
  );
  if (options == null || !context.mounted) {
    return;
  }

  final activePath = workspace.activeFilePath ?? workspace.markdown?.filePath;
  final baseName = activePath == null || activePath.isEmpty
      ? context.l10n.untitledMarkdownFileName
      : p.basename(activePath);
  final location = await getSaveLocation(
    acceptedTypeGroups: [
      XTypeGroup(
        label: context.l10n.fileTypePdf,
        extensions: const ['pdf'],
        mimeTypes: const ['application/pdf'],
      ),
    ],
    suggestedName: '${p.basenameWithoutExtension(baseName)}.pdf',
    initialDirectory: _initialDirectory(workspace, activePath),
    confirmButtonText: context.l10n.export,
  );
  if (location == null || !context.mounted) {
    return;
  }

  final destinationPath = _withPdfExtension(location.path);
  final targetType = await FileSystemEntity.type(
    destinationPath,
    followLinks: false,
  );
  if (!context.mounted) {
    return;
  }
  var overwrite = false;
  if (targetType != FileSystemEntityType.notFound) {
    final confirmed = await _confirmPdfOverwrite(
      context,
      headerBar,
      destinationPath,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    overwrite = true;
  }
  if (!context.mounted) {
    return;
  }

  final cancellationToken = MarkdownPdfCancellationToken();
  final request = MarkdownPdfExportRequest(
    source: snapshot.activeText,
    filePath: activePath ?? '',
    workspaceRoot: workspace.rootPath,
    destinationPath: destinationPath,
    options: options,
    overwrite: overwrite,
  );
  final outcome = await showBusyMarkModalDialog<_PdfExportOutcome>(
    context,
    headerBarService: headerBar.isAvailable ? headerBar : null,
    barrierDismissible: false,
    builder: (context) => _MarkdownPdfProgressDialog(
      cancellationToken: cancellationToken,
      operation: () => ref
          .read(markdownPdfExportServiceProvider)
          .export(request, cancellationToken: cancellationToken),
    ),
  );
  if (outcome == null || !context.mounted) {
    return;
  }
  final failure = outcome.failure;
  if (failure != null) {
    if (failure.code != MarkdownPdfFailureCode.cancelled) {
      await _showPdfExportError(context, headerBar, failure);
    }
    return;
  }
  final result = outcome.result!;
  final fileName = p.basename(result.destinationPath);
  final message = result.warnings.isEmpty
      ? context.l10n.pdfExported(fileName)
      : context.l10n.pdfExportedWithWarnings(fileName, result.warnings.length);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      action: SnackBarAction(
        label: context.l10n.open,
        onPressed: () => unawaited(
          launchUrl(
            Uri.file(result.destinationPath),
            mode: LaunchMode.externalApplication,
          ),
        ),
      ),
    ),
  );
}

String? _initialDirectory(Workspace workspace, String? activePath) {
  if (activePath != null && activePath.isNotEmpty) {
    return p.dirname(activePath);
  }
  return workspace.rootPath.isEmpty ? null : workspace.rootPath;
}

String _withPdfExtension(String path) {
  final normalized = p.normalize(path);
  return p.extension(normalized).toLowerCase() == '.pdf'
      ? normalized
      : '$normalized.pdf';
}

Future<bool> _confirmPdfOverwrite(
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

Future<void> _showPdfExportError(
  BuildContext context,
  LinuxHeaderBarService headerBar,
  MarkdownPdfExportException failure,
) {
  final message = switch (failure.code) {
    MarkdownPdfFailureCode.compilerUnavailable =>
      context.l10n.pdfExportUnavailable,
    MarkdownPdfFailureCode.timedOut => context.l10n.pdfExportTimedOut,
    MarkdownPdfFailureCode.destinationExists =>
      context.l10n.errorPathAlreadyExists(failure.detail),
    MarkdownPdfFailureCode.compilerFailed ||
    MarkdownPdfFailureCode.invalidOutput ||
    MarkdownPdfFailureCode.fileSystem ||
    MarkdownPdfFailureCode.cancelled => context.l10n.pdfExportFailed,
  };
  return showBusyMarkModalDialog<void>(
    context,
    headerBarService: headerBar.isAvailable ? headerBar : null,
    builder: (context) => BusyMarkDialogShell(
      title: context.l10n.exportAsPdf,
      actions: [
        BusyMarkDialogButton(
          label: MaterialLocalizations.of(context).okButtonLabel,
          suggested: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
      children: [Text(message)],
    ),
  );
}

class _MarkdownPdfOptionsDialog extends StatefulWidget {
  const _MarkdownPdfOptionsDialog();

  @override
  State<_MarkdownPdfOptionsDialog> createState() =>
      _MarkdownPdfOptionsDialogState();
}

class _MarkdownPdfOptionsDialogState extends State<_MarkdownPdfOptionsDialog> {
  var _options = const MarkdownPdfOptions();

  @override
  Widget build(BuildContext context) {
    return BusyMarkDialogShell(
      title: context.l10n.exportAsPdf,
      maxWidth: 520,
      actions: [
        BusyMarkDialogButton(
          label: context.l10n.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        BusyMarkDialogButton(
          label: context.l10n.export,
          icon: BusyMarkGlyphs.exportPdf,
          suggested: true,
          onPressed: () => Navigator.pop(context, _options),
        ),
      ],
      children: [
        Text(context.l10n.pdfExportDescription),
        BusyMarkGroupedList(
          filled: true,
          children: [
            BusyMarkComboRow<MarkdownPdfPageSize>(
              title: context.l10n.pdfPageSize,
              values: MarkdownPdfPageSize.values,
              selected: _options.pageSize,
              labelFor: (value) => switch (value) {
                MarkdownPdfPageSize.a4 => context.l10n.pdfPageSizeA4,
                MarkdownPdfPageSize.letter => context.l10n.pdfPageSizeLetter,
              },
              onSelected: (value) =>
                  setState(() => _options = _options.copyWith(pageSize: value)),
            ),
            BusyMarkComboRow<MarkdownPdfOrientation>(
              title: context.l10n.pdfOrientation,
              values: MarkdownPdfOrientation.values,
              selected: _options.orientation,
              labelFor: (value) => switch (value) {
                MarkdownPdfOrientation.portrait => context.l10n.pdfPortrait,
                MarkdownPdfOrientation.landscape => context.l10n.pdfLandscape,
              },
              onSelected: (value) => setState(
                () => _options = _options.copyWith(orientation: value),
              ),
            ),
            BusyMarkComboRow<MarkdownPdfMargin>(
              title: context.l10n.pdfMargins,
              values: MarkdownPdfMargin.values,
              selected: _options.margin,
              labelFor: (value) => switch (value) {
                MarkdownPdfMargin.narrow => context.l10n.pdfMarginNarrow,
                MarkdownPdfMargin.normal => context.l10n.pdfMarginNormal,
                MarkdownPdfMargin.wide => context.l10n.pdfMarginWide,
              },
              onSelected: (value) =>
                  setState(() => _options = _options.copyWith(margin: value)),
            ),
            BusyMarkSwitchRow(
              title: context.l10n.pdfIncludePageNumbers,
              value: _options.pageNumbers,
              onChanged: (value) => setState(
                () => _options = _options.copyWith(pageNumbers: value),
              ),
            ),
          ],
        ),
        const SizedBox(height: BusyMarkSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsetsDirectional.only(top: 2),
              child: Icon(BusyMarkGlyphs.info, size: BusyMarkSizes.iconSm),
            ),
            const SizedBox(width: BusyMarkSpacing.sm),
            Expanded(
              child: Text(
                context.l10n.pdfRemoteImagesNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MarkdownPdfProgressDialog extends StatefulWidget {
  const _MarkdownPdfProgressDialog({
    required this.operation,
    required this.cancellationToken,
  });

  final Future<MarkdownPdfExportResult> Function() operation;
  final MarkdownPdfCancellationToken cancellationToken;

  @override
  State<_MarkdownPdfProgressDialog> createState() =>
      _MarkdownPdfProgressDialogState();
}

class _MarkdownPdfProgressDialogState
    extends State<_MarkdownPdfProgressDialog> {
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
        Navigator.pop(context, _PdfExportOutcome.success(result));
      }
    } on MarkdownPdfExportException catch (failure) {
      if (mounted) {
        Navigator.pop(context, _PdfExportOutcome.failure(failure));
      }
    } on Object catch (error) {
      if (mounted) {
        Navigator.pop(
          context,
          _PdfExportOutcome.failure(
            MarkdownPdfExportException(
              MarkdownPdfFailureCode.fileSystem,
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
        title: context.l10n.exportingPdf,
        closable: false,
        maxWidth: 420,
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

class _PdfExportOutcome {
  const _PdfExportOutcome._({this.result, this.failure});

  factory _PdfExportOutcome.success(MarkdownPdfExportResult result) {
    return _PdfExportOutcome._(result: result);
  }

  factory _PdfExportOutcome.failure(MarkdownPdfExportException failure) {
    return _PdfExportOutcome._(failure: failure);
  }

  final MarkdownPdfExportResult? result;
  final MarkdownPdfExportException? failure;
}
