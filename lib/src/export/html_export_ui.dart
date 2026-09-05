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
import '../app/localization.dart';
import '../math/math_providers.dart';
import '../markdown/markdown_model.dart';
import '../platform/linux_header_bar_service.dart';
import '../visualization/visualization_providers.dart';
import '../workspace/workspace_controller.dart';
import '../workspace/workspace_model.dart';
import '../workspace/workspace_safety.dart';
import '../writerside/writerside_model.dart';
import 'markdown_pdf_export_ui.dart' show canExportActiveMarkdown;
import 'writerside_pdf_export_ui.dart' show canExportWritersidePdf;
import 'html_export_models.dart';
import 'html_export_service.dart';

final htmlExportServiceProvider = Provider<HtmlExportService>(
  (ref) => HtmlExportService(
    math: ref.watch(mathCoordinatorProvider),
    visualization: ref.watch(visualizationCoordinatorProvider),
  ),
);

bool canExportWorkspaceHtml(WorkspaceState state) =>
    canExportActiveMarkdown(state) || canExportWritersidePdf(state);

Future<void> exportWorkspaceToHtml(BuildContext context, WidgetRef ref) async {
  var snapshot = ref.read(workspaceControllerProvider);
  if (!canExportWorkspaceHtml(snapshot)) return;
  final site = snapshot.workspace?.kind == WorkspaceKind.writersideModule;
  if (site) {
    if (!await confirmSafeToContinue(context, ref) || !context.mounted) return;
    snapshot = ref.read(workspaceControllerProvider);
  }
  final workspace = snapshot.workspace!;
  final headerBar = ref.read(linuxHeaderBarServiceProvider);
  WritersideInstance? instance;
  if (site) {
    final instances = workspace.writersideModule!.instances
        .where((i) => !i.isLibrary)
        .toList();
    final stored = ref
        .read(appSettingsControllerProvider)
        .selectedWritersideInstanceId(workspace.rootPath);
    var selected =
        instances.where((i) => i.id == stored).firstOrNull ?? instances.first;
    instance = await showBusyMarkModalDialog<WritersideInstance>(
      context,
      headerBarService: headerBar.isAvailable ? headerBar : null,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => BusyMarkDialogShell(
          title: context.l10n.exportAsHtml,
          actions: [
            BusyMarkDialogButton(
              label: context.l10n.cancel,
              onPressed: () => Navigator.pop(context),
            ),
            BusyMarkDialogButton(
              label: context.l10n.export,
              suggested: true,
              onPressed: () => Navigator.pop(context, selected),
            ),
          ],
          children: [
            Text(context.l10n.htmlInstanceDescription),
            BusyMarkComboRow<WritersideInstance>(
              title: context.l10n.htmlInstance,
              values: instances,
              selected: selected,
              labelFor: (i) => i.name,
              onSelected: (i) => setState(() => selected = i),
            ),
          ],
        ),
      ),
    );
    if (instance == null || !context.mounted) return;
  }
  final path = workspace.activeFilePath ?? workspace.markdown?.filePath ?? '';
  final name = path.isEmpty
      ? context.l10n.untitledMarkdownFileName
      : p.basename(path);
  final location = await getSaveLocation(
    suggestedName: site
        ? '${instance!.id}-html'
        : '${p.basenameWithoutExtension(name)}.html',
    initialDirectory: workspace.rootPath.isEmpty ? null : workspace.rootPath,
    acceptedTypeGroups: site
        ? const []
        : [
            XTypeGroup(
              label: context.l10n.fileTypeHtml,
              extensions: const ['html'],
              mimeTypes: const ['text/html'],
            ),
          ],
    confirmButtonText: context.l10n.export,
  );
  if (location == null || !context.mounted) return;
  final destination =
      !site && p.extension(location.path).toLowerCase() != '.html'
      ? '${location.path}.html'
      : location.path;
  var overwrite = false;
  if (await FileSystemEntity.type(destination, followLinks: false) !=
      FileSystemEntityType.notFound) {
    if (!context.mounted) return;
    overwrite =
        await showBusyMarkModalDialog<bool>(
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
            children: [
              Text(context.l10n.errorPathAlreadyExists(destination)),
              if (site) Text(context.l10n.htmlOwnedDirectoryOnly),
            ],
          ),
        ) ??
        false;
    if (!overwrite || !context.mounted) return;
  }
  if (!context.mounted) return;
  // Capture text and service before starting the modal operation. Subsequent
  // workspace notifications cannot replace these inputs.
  final service = ref.read(htmlExportServiceProvider);
  final request = MarkdownHtmlExportRequest(
    source: snapshot.activeText,
    filePath: path,
    workspaceRoot: workspace.rootPath,
    destinationPath: destination,
    overwrite: overwrite,
    mode: workspace.markdown?.mode ?? MarkdownMode.commonMark,
  );
  final selected = instance;
  final token = HtmlExportCancellationToken();
  final outcome = await showBusyMarkModalDialog<_Outcome>(
    context,
    barrierDismissible: false,
    headerBarService: headerBar.isAvailable ? headerBar : null,
    builder: (context) => _Progress(
      token: token,
      operation: (progress) => site
          ? service.exportWriterside(
              projectRoot: workspace.rootPath,
              moduleRoot: workspace.writersideModule!.rootPath,
              instanceId: selected!.id,
              destinationPath: destination,
              overwrite: overwrite,
              cancellationToken: token,
              onProgress: progress,
            )
          : service.exportMarkdown(
              request,
              cancellationToken: token,
              onProgress: progress,
            ),
    ),
  );
  if (outcome == null || !context.mounted || outcome.cancelled) return;
  final result = outcome.result;
  await showBusyMarkModalDialog<void>(
    context,
    headerBarService: headerBar.isAvailable ? headerBar : null,
    builder: (context) => BusyMarkDialogShell(
      title: result == null
          ? context.l10n.htmlExportFailed
          : context.l10n.htmlExported,
      maxWidth: 640,
      actions: [
        if (result != null)
          BusyMarkDialogButton(
            label: context.l10n.open,
            onPressed: () => unawaited(
              launchUrl(
                Uri.file(result.entryPointPath),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ),
        if (result != null)
          BusyMarkDialogButton(
            label: context.l10n.showInFolder,
            onPressed: () => unawaited(
              launchUrl(
                Uri.directory(p.dirname(result.entryPointPath)),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ),
        BusyMarkDialogButton(
          label: MaterialLocalizations.of(context).closeButtonLabel,
          onPressed: () => Navigator.pop(context),
        ),
      ],
      children: [
        if (result == null)
          SelectableText(outcome.error ?? context.l10n.htmlExportFailed)
        else ...[
          SelectableText(result.entryPointPath),
          if (!site && result.assetsPath != null)
            Text(context.l10n.htmlKeepAssetsTogether),
          if (result.warnings.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: SingleChildScrollView(
                child: SelectionArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final warning in result.warnings)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(warning.toString()),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ],
    ),
  );
}

class _Outcome {
  const _Outcome({this.result, this.error, this.cancelled = false});
  final HtmlExportResult? result;
  final String? error;
  final bool cancelled;
}

class _Progress extends StatefulWidget {
  const _Progress({required this.token, required this.operation});
  final HtmlExportCancellationToken token;
  final Future<HtmlExportResult> Function(HtmlExportProgress progress)
  operation;
  @override
  State<_Progress> createState() => _ProgressState();
}

class _ProgressState extends State<_Progress> {
  double? progress;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => run());
  }

  Future<void> run() async {
    _Outcome outcome;
    try {
      outcome = _Outcome(
        result: await widget.operation((done, total) {
          if (mounted) {
            setState(() => progress = total == 0 ? null : done / total);
          }
        }),
      );
    } on HtmlExportException catch (error) {
      outcome = _Outcome(error: error.message, cancelled: error.cancelled);
    } on Object catch (error) {
      outcome = _Outcome(error: error.toString());
    }
    if (mounted) Navigator.pop(context, outcome);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: BusyMarkDialogShell(
      title: context.l10n.exportingHtml,
      closable: false,
      actions: [
        BusyMarkDialogButton(
          label: context.l10n.cancel,
          onPressed: widget.token.isCancelled
              ? null
              : () => setState(widget.token.cancel),
        ),
      ],
      children: [
        LinearProgressIndicator(value: progress),
        const SizedBox(height: 20),
      ],
    ),
  );
}
