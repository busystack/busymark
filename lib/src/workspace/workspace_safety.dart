import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../app/app_settings.dart';
import '../app/busymark_dialogs.dart';
import '../app/busymark_design.dart';
import '../app/localization.dart';
import '../platform/linux_header_bar_service.dart';
import 'workspace_controller.dart';

enum _UnsavedChangesAction { cancel, discard, save }

enum _OverwriteAction { cancel, overwrite }

XTypeGroup _markdownSaveType(BuildContext context) => XTypeGroup(
  label: context.l10n.fileTypeMarkdown,
  extensions: <String>['md', 'markdown'],
  mimeTypes: <String>['text/markdown', 'text/x-markdown'],
);

Future<bool> confirmSafeToContinue(BuildContext context, WidgetRef ref) async {
  final state = ref.read(workspaceControllerProvider);
  if (!state.hasUnsavedChanges) {
    return true;
  }
  final fileName =
      state.workspace?.activeFilePath?.split('/').last ??
      context.l10n.currentFile;
  final headerBar = ref.read(linuxHeaderBarServiceProvider);
  final action = await showBusyMarkModalDialog<_UnsavedChangesAction>(
    context,
    headerBarService: headerBar.isAvailable ? headerBar : null,
    builder: (context) => BusyMarkDialogShell(
      title: context.l10n.unsavedChanges,
      maxWidth: BusyMarkSizes.dialog,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _UnsavedChangesAction.cancel),
          child: Text(context.l10n.cancel),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(context, _UnsavedChangesAction.discard),
          child: Text(context.l10n.discard),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _UnsavedChangesAction.save),
          child: Text(context.l10n.save),
        ),
      ],
      children: [Text(context.l10n.unsavedChangesMessage(fileName))],
    ),
  );

  if (action == _UnsavedChangesAction.discard) {
    return true;
  }
  if (action == _UnsavedChangesAction.save) {
    if (!context.mounted) {
      return false;
    }
    return saveActiveWithOverwriteConfirmation(context, ref);
  }
  return false;
}

Future<bool> saveOrConfirmSafeToChangeActiveFile(
  BuildContext context,
  WidgetRef ref,
) async {
  final state = ref.read(workspaceControllerProvider);
  if (!state.hasUnsavedChanges) {
    return true;
  }
  if (!ref.read(appSettingsControllerProvider).autoSave) {
    return confirmSafeToContinue(context, ref);
  }
  return ref
      .read(workspaceControllerProvider.notifier)
      .autoSaveActiveIfNeeded();
}

Future<bool> saveActiveWithOverwriteConfirmation(
  BuildContext context,
  WidgetRef ref,
) async {
  final controller = ref.read(workspaceControllerProvider.notifier);
  if (controller.activeDocumentNeedsSaveLocation) {
    return _saveActiveAs(context, ref);
  }
  if (!await controller.activeFileChangedOnDisk()) {
    return controller.saveActive();
  }
  if (!context.mounted) {
    return false;
  }
  final headerBar = ref.read(linuxHeaderBarServiceProvider);
  final action = await showBusyMarkModalDialog<_OverwriteAction>(
    context,
    headerBarService: headerBar.isAvailable ? headerBar : null,
    builder: (context) => BusyMarkDialogShell(
      title: context.l10n.fileChangedOnDisk,
      maxWidth: BusyMarkSizes.dialog,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _OverwriteAction.cancel),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _OverwriteAction.overwrite),
          child: Text(context.l10n.overwrite),
        ),
      ],
      children: [Text(context.l10n.fileChangedOnDiskMessage)],
    ),
  );
  if (action != _OverwriteAction.overwrite) {
    return false;
  }
  return controller.saveActive(overwriteExternalChanges: true);
}

Future<bool> _saveActiveAs(BuildContext context, WidgetRef ref) async {
  final state = ref.read(workspaceControllerProvider);
  final activePath = state.workspace?.activeFilePath;
  final location = await getSaveLocation(
    acceptedTypeGroups: [_markdownSaveType(context)],
    suggestedName: activePath == null || activePath.isEmpty
        ? context.l10n.untitledMarkdownFileName
        : p.basename(activePath),
    initialDirectory: activePath == null || activePath.isEmpty
        ? null
        : p.dirname(activePath),
    confirmButtonText: context.l10n.save,
  );
  if (location == null) {
    return false;
  }
  final savePath = _withMarkdownExtension(location.path);
  return ref.read(workspaceControllerProvider.notifier).saveActiveAs(savePath);
}

String _withMarkdownExtension(String path) {
  if (p.extension(path).isNotEmpty) {
    return path;
  }
  return '$path.md';
}
