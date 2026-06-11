import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/busymark_dialogs.dart';
import '../app/busymark_design.dart';
import '../platform/linux_header_bar_service.dart';
import 'workspace_controller.dart';

enum _UnsavedChangesAction { cancel, discard, save }

enum _OverwriteAction { cancel, overwrite }

Future<bool> confirmSafeToContinue(BuildContext context, WidgetRef ref) async {
  final state = ref.read(workspaceControllerProvider);
  if (!state.hasUnsavedChanges) {
    return true;
  }
  final fileName =
      state.workspace?.activeFilePath?.split('/').last ?? 'the current file';
  final headerBar = ref.read(linuxHeaderBarServiceProvider);
  final action = await showBusyMarkModalDialog<_UnsavedChangesAction>(
    context,
    headerBarService: headerBar.isAvailable ? headerBar : null,
    builder: (context) => BusyMarkDialogShell(
      title: 'Unsaved changes',
      maxWidth: 520,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _UnsavedChangesAction.cancel),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(context, _UnsavedChangesAction.discard),
          child: const Text('Discard'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _UnsavedChangesAction.save),
          child: const Text('Save'),
        ),
      ],
      children: [
        Text(
          'You have unsaved changes in $fileName. Save them before continuing?',
        ),
      ],
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

Future<bool> saveActiveWithOverwriteConfirmation(
  BuildContext context,
  WidgetRef ref,
) async {
  final controller = ref.read(workspaceControllerProvider.notifier);
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
      title: 'File changed on disk',
      maxWidth: 520,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _OverwriteAction.cancel),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _OverwriteAction.overwrite),
          child: const Text('Overwrite'),
        ),
      ],
      children: const [
        Text('This file changed on disk since you opened it. Overwrite it?'),
      ],
    ),
  );
  if (action != _OverwriteAction.overwrite) {
    return false;
  }
  return controller.saveActive(overwriteExternalChanges: true);
}
