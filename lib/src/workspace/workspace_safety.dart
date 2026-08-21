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
import 'text_format_metadata.dart';

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
  return _confirmUnsavedChanges(
    context,
    ref,
    dirtyBufferIds: state.dirtyBuffers.map((buffer) => buffer.id).toList(),
  );
}

Future<bool> confirmSafeToCloseActiveDocument(
  BuildContext context,
  WidgetRef ref,
) async {
  final active = ref.read(workspaceControllerProvider).activeBuffer;
  if (active == null || !active.isDirty) {
    return true;
  }
  return _confirmUnsavedChanges(context, ref, dirtyBufferIds: [active.id]);
}

Future<bool> _confirmUnsavedChanges(
  BuildContext context,
  WidgetRef ref, {
  required List<String> dirtyBufferIds,
}) async {
  final initialState = ref.read(workspaceControllerProvider);
  final dirtyBuffers = [
    for (final id in dirtyBufferIds)
      if (initialState.documentBuffers
              .where((buffer) => buffer.id == id && buffer.isDirty)
              .firstOrNull
          case final buffer?)
        buffer,
  ];
  if (dirtyBuffers.isEmpty) {
    return true;
  }
  final initialWorkspaceId = initialState.workspace?.id;
  final initialActiveBufferId = initialState.activeBufferId;
  final initialRevisions = {
    for (final buffer in dirtyBuffers) buffer.id: buffer.revision,
  };
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
      children: [
        Text(
          dirtyBuffers.length == 1
              ? context.l10n.unsavedChangesMessage(
                  dirtyBuffers.single.displayName,
                )
              : context.l10n.unsavedChangesMultipleMessage(dirtyBuffers.length),
        ),
        if (dirtyBuffers.length > 1) ...[
          const SizedBox(height: BusyMarkSpacing.md),
          BusyMarkGroupedList(
            filled: true,
            children: [
              for (final buffer in dirtyBuffers)
                BusyMarkActionRow(
                  title: buffer.displayName,
                  subtitle: buffer.filePath,
                  leading: const Icon(BusyMarkGlyphs.document),
                ),
            ],
          ),
        ],
      ],
    ),
  );

  final currentState = ref.read(workspaceControllerProvider);
  final currentDirtyIds = currentState.dirtyBuffers
      .map((buffer) => buffer.id)
      .toSet();
  if (action != null &&
      action != _UnsavedChangesAction.cancel &&
      (currentState.workspace?.id != initialWorkspaceId ||
          currentState.activeBufferId != initialActiveBufferId ||
          currentDirtyIds.length != initialRevisions.length ||
          !currentDirtyIds.containsAll(initialRevisions.keys) ||
          initialRevisions.entries.any((entry) {
            final current = currentState.documentBuffers
                .where((buffer) => buffer.id == entry.key)
                .firstOrNull;
            return current == null || current.revision != entry.value;
          }))) {
    return false;
  }

  if (action == _UnsavedChangesAction.discard) {
    return _discardDirtyDocuments(ref, dirtyBufferIds);
  }
  if (action == _UnsavedChangesAction.save) {
    if (!context.mounted) {
      return false;
    }
    return _saveDirtyDocuments(context, ref, dirtyBufferIds);
  }
  return false;
}

Future<bool> _saveDirtyDocuments(
  BuildContext context,
  WidgetRef ref,
  List<String> bufferIds,
) async {
  final controller = ref.read(workspaceControllerProvider.notifier);
  final originalActiveId = ref.read(workspaceControllerProvider).activeBufferId;
  for (final bufferId in bufferIds) {
    final current = ref
        .read(workspaceControllerProvider)
        .documentBuffers
        .where((buffer) => buffer.id == bufferId)
        .firstOrNull;
    if (current == null || !current.isDirty) {
      continue;
    }
    if (!await controller.activateDocumentBuffer(bufferId) ||
        !context.mounted ||
        !await saveActiveWithOverwriteConfirmation(context, ref)) {
      await _restoreActiveBuffer(ref, controller, originalActiveId);
      return false;
    }
  }
  await _restoreActiveBuffer(ref, controller, originalActiveId);
  return bufferIds.every((id) {
    final buffer = ref
        .read(workspaceControllerProvider)
        .documentBuffers
        .where((candidate) => candidate.id == id)
        .firstOrNull;
    return buffer == null || !buffer.isDirty;
  });
}

Future<bool> _discardDirtyDocuments(
  WidgetRef ref,
  List<String> bufferIds,
) async {
  final controller = ref.read(workspaceControllerProvider.notifier);
  final originalActiveId = ref.read(workspaceControllerProvider).activeBufferId;
  for (final bufferId in bufferIds) {
    final current = ref
        .read(workspaceControllerProvider)
        .documentBuffers
        .where((buffer) => buffer.id == bufferId)
        .firstOrNull;
    if (current == null || !current.isDirty) {
      continue;
    }
    if (!await controller.activateDocumentBuffer(bufferId)) {
      await _restoreActiveBuffer(ref, controller, originalActiveId);
      return false;
    }
    final target = controller.captureActiveDocumentSaveTarget();
    final discarded = current.deletedOnDisk
        ? await controller.closeDocumentBuffer(bufferId, discard: true)
        : await controller.discardActiveChanges(target: target);
    if (!discarded) {
      await _restoreActiveBuffer(ref, controller, originalActiveId);
      return false;
    }
  }
  await _restoreActiveBuffer(ref, controller, originalActiveId);
  return true;
}

Future<void> _restoreActiveBuffer(
  WidgetRef ref,
  WorkspaceController controller,
  String? bufferId,
) async {
  if (bufferId != null &&
      ref
          .read(workspaceControllerProvider)
          .documentBuffers
          .any((buffer) => buffer.id == bufferId)) {
    await controller.activateDocumentBuffer(bufferId);
  }
}

Future<bool> saveOrConfirmSafeToChangeActiveFile(
  BuildContext context,
  WidgetRef ref,
) async {
  final state = ref.read(workspaceControllerProvider);
  if (!state.isDirty) {
    return true;
  }
  if (!ref.read(appSettingsControllerProvider).autoSave) {
    return confirmSafeToCloseActiveDocument(context, ref);
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
  final normalization = await _chooseMixedLineEndingNormalization(
    context,
    ref,
    operationTarget,
  );
  if (operationTarget.format.hasMixedLineEndings && normalization == null) {
    return false;
  }
  // The controller owns both the disk check and save serialization so a
  // separate preflight cannot race an already-running write.
  final saved = await controller.saveActive(
    target: operationTarget,
    mixedLineEndingNormalization: normalization,
  );
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
    mixedLineEndingNormalization: normalization,
  );
}

Future<bool> saveActiveToNewLocation(
  BuildContext context,
  WidgetRef ref,
) async {
  final controller = ref.read(workspaceControllerProvider.notifier);
  final target = controller.captureActiveDocumentSaveTarget();
  if (target == null) {
    return false;
  }
  return _saveActiveAs(context, ref, target);
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
  final normalization = await _chooseMixedLineEndingNormalization(
    context,
    ref,
    target,
  );
  if (target.format.hasMixedLineEndings && normalization == null) {
    return false;
  }
  if (!context.mounted) {
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
    mixedLineEndingNormalization: normalization,
  );
}

Future<LineEndingNormalization?> _chooseMixedLineEndingNormalization(
  BuildContext context,
  WidgetRef ref,
  ActiveDocumentSaveTarget target,
) async {
  if (!target.format.hasMixedLineEndings) {
    return null;
  }
  final headerBar = ref.read(linuxHeaderBarServiceProvider);
  return showBusyMarkModalDialog<LineEndingNormalization>(
    context,
    headerBarService: headerBar.isAvailable ? headerBar : null,
    builder: (context) => BusyMarkDialogShell(
      title: context.l10n.normalizeLineEndings,
      maxWidth: BusyMarkSizes.dialog,
      actions: [
        BusyMarkDialogButton(
          label: context.l10n.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        BusyMarkDialogButton(
          label: LineEndingNormalization.lf.name.toUpperCase(),
          onPressed: () => Navigator.pop(context, LineEndingNormalization.lf),
        ),
        BusyMarkDialogButton(
          label: LineEndingNormalization.crlf.name.toUpperCase(),
          suggested: true,
          onPressed: () => Navigator.pop(context, LineEndingNormalization.crlf),
        ),
      ],
      children: [Text(context.l10n.mixedLineEndingsSavePrompt)],
    ),
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
