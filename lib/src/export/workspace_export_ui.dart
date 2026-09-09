import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../workspace/workspace_controller.dart';
import '../workspace/workspace_model.dart';
import 'export_options_editor.dart';
import 'html_export_ui.dart';
import 'markdown_pdf_export_ui.dart';

export 'html_export_ui.dart' show canExportWorkspaceHtml;
export 'markdown_pdf_export_ui.dart' show canExportWorkspacePdf;

bool canExportWorkspace(WorkspaceState state) =>
    canExportWorkspacePdf(state) || canExportWorkspaceHtml(state);

Future<void> exportWorkspace(BuildContext context, WidgetRef ref) async {
  final state = ref.read(workspaceControllerProvider);
  final canExportPdf = canExportWorkspacePdf(state);
  final canExportHtml = canExportWorkspaceHtml(state);
  if (!canExportPdf && !canExportHtml) return;

  final workspace = state.workspace!;
  final writerside = workspace.kind == WorkspaceKind.writersideModule;
  final selection = await showExportOptions(
    context,
    ref,
    initialFormat: canExportPdf ? ExportFormat.pdf : ExportFormat.html,
    canExportPdf: canExportPdf,
    canExportHtml: canExportHtml,
    instances: writerside
        ? workspace.writersideModule!.instances
              .where((instance) => !instance.isLibrary)
              .toList(growable: false)
        : const [],
    workspaceRoot: writerside ? workspace.rootPath : null,
  );
  if (selection == null || !context.mounted) return;

  if (selection.pdf != null) {
    await exportWorkspaceToPdf(context, ref, configuredSelection: selection);
  } else if (selection.html != null) {
    await exportWorkspaceToHtml(context, ref, configuredSelection: selection);
  }
}
