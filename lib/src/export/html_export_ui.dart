import '../nextcloud_notes/application/nextcloud_connection.dart';
import '../nextcloud_notes/application/notes_media.dart';
import 'dart:async';
import '../app/save_destination_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'export_options_editor.dart';
import '../app/busymark_design.dart';
import '../app/busymark_dialogs.dart';
import '../app/localization.dart';
import '../math/math_providers.dart';
import '../markdown/markdown_model.dart';
import '../visualization/visualization_providers.dart';
import '../workspace/workspace_controller.dart';
import '../workspace/workspace_model.dart';
import '../workspace/workspace_safety.dart';
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

Future<void> exportWorkspaceToHtml(
  BuildContext context,
  WidgetRef ref, {
  ExportOptionsSelection? configuredSelection,
}) async {
  var snapshot = ref.read(workspaceControllerProvider);
  if (!canExportWorkspaceHtml(snapshot)) return;
  final site = snapshot.workspace?.kind == WorkspaceKind.writersideModule;
  if (site) {
    if (!await confirmSafeToContinue(context, ref) || !context.mounted) return;
    snapshot = ref.read(workspaceControllerProvider);
  }
  final workspace = snapshot.workspace!;
  final remoteRef = snapshot.activeBuffer?.remoteNote;
  final media = remoteRef == null
      ? null
      : NextcloudDocumentMedia(
          await ref.read(nextcloudNotesRepositoryProvider.future),
          remoteRef.accountId,
          remoteRef.localId,
        ).context;
  if (!context.mounted) return;

  final configuration =
      configuredSelection ??
      await showExportOptions(
        context,
        ref,
        initialFormat: ExportFormat.html,
        canExportPdf: false,
        instances: site
            ? workspace.writersideModule!.instances
                  .where((i) => !i.isLibrary)
                  .toList()
            : const [],
        workspaceRoot: site ? (workspace.filesystemRootPath ?? '') : null,
      );
  if (configuration == null || configuration.html == null || !context.mounted) {
    return;
  }
  final instance = configuration.instance;
  final options = configuration.html!;
  final path = workspace.activeFilePath ?? workspace.markdown?.filePath ?? '';
  final name = remoteRef != null
      ? snapshot.activeBuffer!.displayName
      : path.isEmpty
      ? context.l10n.untitledMarkdownFileName
      : p.basename(path);
  final service = ref.read(htmlExportServiceProvider);
  String? siteOwnership;
  final authorization = site
      ? await pickHtmlSiteDestination(
          context,
          suggestedName: '${instance!.id}-html',
          initialDirectory: workspace.filesystemRootPath,
          validateReplacement: (path) async {
            siteOwnership = await service.publisher.siteOwnership(path);
          },
        )
      : await pickSaveDestination(
          context,
          suggestedName: '${p.basenameWithoutExtension(name)}.html',
          initialDirectory: workspace.filesystemRootPath,
          actionLabel: context.l10n.export,
          suffix: '.html',
          filterLabel: context.l10n.fileTypeHtml,
          patterns: const ['*.[hH][tT][mM][lL]'],
        );
  if (authorization == null || !context.mounted) return;
  final destination = authorization.path;
  final overwrite = authorization.replacesExisting;
  final request = MarkdownHtmlExportRequest(
    source: snapshot.activeText,
    media: media,
    filePath: path,
    workspaceRoot: (workspace.filesystemRootPath ?? ''),
    destinationPath: destination,
    overwrite: overwrite,
    authorization: authorization,
    options: options,
    mode: workspace.markdown?.mode ?? MarkdownMode.commonMark,
  );
  final selected = instance;
  final token = HtmlExportCancellationToken();
  final outcome = await showBusyMarkModalDialog<_Outcome>(
    context,
    barrierDismissible: false,
    builder: (context) => _Progress(
      token: token,
      operation: (progress) => site
          ? service.exportWriterside(
              projectRoot: (workspace.filesystemRootPath ?? ''),
              moduleRoot: workspace.writersideModule!.rootPath,
              instanceId: selected!.id,
              destinationPath: destination,
              overwrite: overwrite,
              authorization: authorization,
              expectedSiteOwnership: siteOwnership,
              options: options,
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
