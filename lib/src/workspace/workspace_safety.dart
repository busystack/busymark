import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../app/busymark_dialogs.dart';
import '../app/busymark_design.dart';
import '../platform/linux_header_bar_service.dart';
import 'workspace_controller.dart';

enum _UnsavedChangesAction { cancel, discard, save }

enum _OverwriteAction { cancel, overwrite }

const _markdownSaveType = XTypeGroup(
  label: 'Markdown',
  extensions: <String>['md', 'markdown'],
  mimeTypes: <String>['text/markdown', 'text/x-markdown'],
);

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

Future<bool> _saveActiveAs(BuildContext context, WidgetRef ref) async {
  final state = ref.read(workspaceControllerProvider);
  final activePath = state.workspace?.activeFilePath;
  final location = await getSaveLocation(
    acceptedTypeGroups: const [_markdownSaveType],
    suggestedName: activePath == null || activePath.isEmpty
        ? 'Untitled.md'
        : p.basename(activePath),
    initialDirectory: activePath == null || activePath.isEmpty
        ? null
        : p.dirname(activePath),
    confirmButtonText: 'Save',
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
