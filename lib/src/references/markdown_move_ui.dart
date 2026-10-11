import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/busymark_dialogs.dart';
import '../app/busymark_design.dart';
import '../app/localization.dart';
import '../workspace/workspace_controller.dart';
import '../workspace/workspace_model.dart';
import '../workspace/workspace_safety.dart';
import 'markdown_move_service.dart';

Future<void> reviewMarkdownRecovery(
  BuildContext context,
  WidgetRef ref,
  String journal,
) async {
  final workspace = ref.read(workspaceControllerProvider).workspace;
  if (workspace == null ||
      !await confirmSafeToChangeWorkspaceFiles(
        context,
        ref,
        workspace.files.map((f) => f.absolutePath),
      ) ||
      !context.mounted) {
    return;
  }
  try {
    final plan = await const MarkdownMoveService().prepareRecovery(
      workspace.rootPath,
      journal,
    );
    if (!context.mounted ||
        ref.read(workspaceControllerProvider).workspace?.id != workspace.id) {
      return;
    }
    final accepted = await showBusyMarkModalDialog<bool>(
      context,
      builder: (context) => BusyMarkDialogShell(
        title: context.l10n.notesRecovery,
        actions: [
          BusyMarkDialogButton(
            label: context.l10n.cancel,
            onPressed: () => Navigator.pop(context, false),
          ),
          BusyMarkDialogButton(
            label: context.l10n.apply,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
        children: [
          Text('${plan.destination} → ${plan.source}'),
          SizedBox(
            height: 360,
            child: ListView(
              children: [for (final file in plan.files) Text(file.path)],
            ),
          ),
        ],
      ),
    );
    if (accepted == true) {
      await ref
          .read(workspaceControllerProvider.notifier)
          .recoverMarkdownMove(plan);
    }
  } on Object catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

Future<({bool proceed, MarkdownMovePlan? plan})> reviewMarkdownMove(
  BuildContext context,
  WidgetRef ref,
  String source,
  String destination,
) async {
  final workspace = ref.read(workspaceControllerProvider).workspace;
  if (workspace?.kind != WorkspaceKind.markdownFolder) {
    return (proceed: true, plan: null);
  }
  if (!await confirmSafeToChangeWorkspaceFiles(
        context,
        ref,
        workspace!.files.map((f) => f.absolutePath),
      ) ||
      !context.mounted) {
    return (proceed: false, plan: null);
  }
  try {
    final plan = await ref
        .read(workspaceControllerProvider.notifier)
        .prepareMarkdownMove(source, destination);
    if (plan == null ||
        !context.mounted ||
        ref.read(workspaceControllerProvider).workspace?.id != workspace.id) {
      return (proceed: false, plan: null);
    }
    final focus = FocusManager.instance.primaryFocus;
    final accepted = await showBusyMarkModalDialog<bool>(
      context,
      builder: (context) => BusyMarkDialogShell(
        title: context.l10n.rename,
        maxWidth: 720,
        actions: [
          BusyMarkDialogButton(
            onPressed: () => Navigator.pop(context, false),
            label: context.l10n.cancel,
          ),
          BusyMarkDialogButton(
            onPressed: () => Navigator.pop(context, true),
            label: context.l10n.apply,
          ),
        ],
        children: [
          Text('$source → $destination'),
          SizedBox(
            height: 360,
            child: ListView(
              children: [
                for (final file in plan.files) ...[
                  Text(
                    file.path,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  for (final edit in file.edits)
                    SelectableText(
                      '${edit.start}: ${edit.before} → ${edit.after}',
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
    if (focus?.context?.mounted == true) focus!.requestFocus();
    return (proceed: accepted == true, plan: plan);
  } on Object catch (error) {
    if (context.mounted) {
      await showBusyMarkModalDialog<void>(
        context,
        builder: (context) => BusyMarkDialogShell(
          title: context.l10n.rename,
          actions: [
            BusyMarkDialogButton(
              onPressed: () => Navigator.pop(context),
              label: context.l10n.close,
            ),
          ],
          children: [Text(error.toString())],
        ),
      );
    }
    return (proceed: false, plan: null);
  }
}
