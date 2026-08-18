import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../app/app_settings.dart';
import '../app/busymark_dialogs.dart';
import '../app/busymark_design.dart';
import '../app/busymark_glyphs.dart';
import '../app/localization.dart';
import '../platform/linux_header_bar_service.dart';
import 'workspace_controller.dart';
import 'workspace_message.dart';

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
  final controller = ref.read(workspaceControllerProvider.notifier);
  final target = controller.captureActiveDocumentSaveTarget();
  if (target == null) {
    return false;
  }
  final fileName = target.path?.split('/').last ?? context.l10n.currentFile;
  final headerBar = ref.read(linuxHeaderBarServiceProvider);
  final action = await showBusyMarkModalDialog<_UnsavedChangesAction>(
    context,
    headerBarService: headerBar.isAvailable ? headerBar : null,
    builder: (context) => BusyMarkDialogShell(
      title: context.l10n.unsavedChanges,
      maxWidth: BusyMarkSizes.dialog,
      actions: [
        BusyMarkDialogButton(
          label: context.l10n.cancel,
          icon: BusyMarkGlyphs.clear,
          onPressed: () => Navigator.pop(context, _UnsavedChangesAction.cancel),
        ),
        BusyMarkDialogButton(
          label: context.l10n.discard,
          icon: BusyMarkGlyphs.delete,
          destructive: true,
          onPressed: () =>
              Navigator.pop(context, _UnsavedChangesAction.discard),
        ),
        BusyMarkDialogButton(
          label: context.l10n.save,
          icon: BusyMarkGlyphs.save,
          suggested: true,
          onPressed: () => Navigator.pop(context, _UnsavedChangesAction.save),
        ),
      ],
      children: [Text(context.l10n.unsavedChangesMessage(fileName))],
    ),
  );

  if (action == _UnsavedChangesAction.discard) {
    return controller.discardActiveChanges(target: target);
  }
  if (action == _UnsavedChangesAction.save) {
    if (!context.mounted) {
      return false;
    }
    return saveActiveWithOverwriteConfirmation(context, ref, target: target);
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
  WidgetRef ref, {
  ActiveDocumentSaveTarget? target,
}) async {
  final controller = ref.read(workspaceControllerProvider.notifier);
  final operationTarget =
      target ?? controller.captureActiveDocumentSaveTarget();
  if (operationTarget == null ||
      !controller.isActiveDocumentSaveTargetCurrent(operationTarget)) {
    return false;
  }
  if (operationTarget.needsSaveLocation) {
    return _saveActiveAs(context, ref, operationTarget);
  }
  // The controller owns both the disk check and save serialization so a
  // separate preflight cannot race an already-running write.
  final saved = await controller.saveActive(target: operationTarget);
  if (saved) {
    return true;
  }
  final state = ref.read(workspaceControllerProvider);
  if (!controller.isActiveDocumentSaveTargetCurrent(operationTarget) ||
      state.message?.code !=
          WorkspaceMessageCode.saveBlockedFileChangedOnDisk) {
    return false;
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
        BusyMarkDialogButton(
          label: context.l10n.cancel,
          onPressed: () => Navigator.pop(context, _OverwriteAction.cancel),
        ),
        BusyMarkDialogButton(
          label: context.l10n.overwrite,
          destructive: true,
          onPressed: () => Navigator.pop(context, _OverwriteAction.overwrite),
        ),
      ],
      children: [Text(context.l10n.fileChangedOnDiskMessage)],
    ),
  );
  if (action != _OverwriteAction.overwrite) {
    return false;
  }
  return controller.saveActive(
    overwriteExternalChanges: true,
    target: operationTarget,
  );
}

Future<bool> _saveActiveAs(
  BuildContext context,
  WidgetRef ref,
  ActiveDocumentSaveTarget target,
) async {
  final controller = ref.read(workspaceControllerProvider.notifier);
  if (!controller.isActiveDocumentSaveTargetCurrent(target)) {
    return false;
  }
  final activePath = target.path;
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
  final savePath = p.normalize(_withMarkdownExtension(location.path));
  final exists = await controller.savePathExists(savePath, target: target);
  if (!controller.isActiveDocumentSaveTargetCurrent(target)) {
    return false;
  }
  var overwriteExisting = false;
  if (exists) {
    if (!context.mounted) {
      return false;
    }
    final action = await _confirmSaveAsOverwrite(context, ref, savePath);
    if (action != _OverwriteAction.overwrite ||
        !controller.isActiveDocumentSaveTargetCurrent(target)) {
      return false;
    }
    overwriteExisting = true;
  }
  return controller.saveActiveAs(
    savePath,
    target: target,
    overwriteExisting: overwriteExisting,
  );
}

Future<_OverwriteAction?> _confirmSaveAsOverwrite(
  BuildContext context,
  WidgetRef ref,
  String savePath,
) {
  final headerBar = ref.read(linuxHeaderBarServiceProvider);
  return showBusyMarkModalDialog<_OverwriteAction>(
    context,
    headerBarService: headerBar.isAvailable ? headerBar : null,
    builder: (context) => BusyMarkDialogShell(
      title: context.l10n.warning,
      maxWidth: BusyMarkSizes.dialog,
      actions: [
        BusyMarkDialogButton(
          label: context.l10n.cancel,
          onPressed: () => Navigator.pop(context, _OverwriteAction.cancel),
        ),
        BusyMarkDialogButton(
          label: context.l10n.overwrite,
          destructive: true,
          onPressed: () => Navigator.pop(context, _OverwriteAction.overwrite),
        ),
      ],
      children: [Text(context.l10n.errorPathAlreadyExists(savePath))],
    ),
  );
}

String _withMarkdownExtension(String path) {
  if (p.extension(path).isNotEmpty) {
    return path;
  }
  return '$path.md';
}
