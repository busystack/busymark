import '../core/save_destination.dart';
import '../app/busymark_native_controls.dart';
import '../core/atomic_file_writer.dart';
import '../app/save_destination_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../app/app_settings.dart';
import '../app/git_dismissal.dart';
import '../app/busymark_dialogs.dart';
import '../app/busymark_design.dart';
import '../app/busymark_glyphs.dart';
import '../app/localization.dart';
import 'workspace_controller.dart';
import 'workspace_message.dart';
import 'workspace_model.dart';
import 'text_format_metadata.dart';

enum _UnsavedChangesAction { cancel, discard, save }

enum _OverwriteAction { cancel, overwrite }

Future<bool> confirmSafeToContinue(
  BuildContext context,
  WidgetRef ref, {
  bool Function()? canContinue,
}) => confirmWorkspaceDeparture(
  context,
  _container(ref),
  canContinue: canContinue,
);

Future<bool> confirmWorkspaceDeparture(
  BuildContext context,
  ProviderContainer container, {
  bool Function()? canContinue,
  bool deferDiscard = false,
}) async {
  if (!await container.read(busyMarkGitDismissalProvider).mayDismiss() ||
      !context.mounted ||
      canContinue?.call() == false) {
    return false;
  }
  if (!container
      .read(workspaceControllerProvider.notifier)
      .propertyEdits
      .flush()) {
    return false;
  }
  final state = container.read(workspaceControllerProvider);
  if (!state.hasUnsavedChanges) return true;
  return _confirmUnsavedChanges(
    context,
    container,
    dirtyBufferIds: state.dirtyBuffers.map((buffer) => buffer.id).toList(),
    canContinue: canContinue,
    deferDiscard: deferDiscard,
  );
}

ProviderContainer _container(WidgetRef ref) =>
    ProviderScope.containerOf(ref.context, listen: false);

/// Covers every affected tab, including inactive dirty tree/topic buffers.
Future<bool> confirmSafeToChangeWorkspaceFiles(
  BuildContext context,
  WidgetRef ref,
  Iterable<String> paths,
) {
  final affected = paths.toList();
  return _confirmUnsavedChanges(
    context,
    _container(ref),
    dirtyBufferIds: [
      for (final buffer in ref.read(workspaceControllerProvider).dirtyBuffers)
        if (buffer.filePath != null &&
            affected.any((path) => p.equals(path, buffer.filePath!)))
          buffer.id,
    ],
  );
}

bool hasDirtyWritersideProjectBuffers(WidgetRef ref) {
  final state = ref.read(workspaceControllerProvider);
  final workspace = state.workspace;
  if (workspace == null) return false;
  return state.dirtyBuffers.any(
    (buffer) =>
        buffer.filePath != null &&
        isWritersideProjectPath(workspace, buffer.filePath!),
  );
}

/// Resolves every dirty buffer in every discovered module before a
/// project-wide semantic refactoring is planned.
Future<bool> confirmSafeToRefactorWritersideProject(
  BuildContext context,
  WidgetRef ref,
) {
  final state = ref.read(workspaceControllerProvider);
  final workspace = state.workspace;
  if (workspace == null) return Future.value(false);
  return _confirmUnsavedChanges(
    context,
    _container(ref),
    withoutActivatingBuffers: true,
    dirtyBufferIds: [
      for (final buffer in state.dirtyBuffers)
        if (buffer.filePath != null &&
            isWritersideProjectPath(workspace, buffer.filePath!))
          buffer.id,
    ],
  );
}

Future<bool> confirmSafeToCloseActiveDocument(
  BuildContext context,
  WidgetRef ref,
) async {
  if (!ref.read(workspaceControllerProvider.notifier).propertyEdits.flush()) {
    return false;
  }
  final active = ref.read(workspaceControllerProvider).activeBuffer;
  if (active == null || !active.isDirty) {
    return true;
  }
  return _confirmUnsavedChanges(
    context,
    _container(ref),
    dirtyBufferIds: [active.id],
  );
}

/// Resolves only dirty documents in the requested close set, including
/// inactive buffers, without prompting for a retained document.
Future<bool> confirmSafeToCloseDocumentBuffers(
  BuildContext context,
  WidgetRef ref,
  Iterable<String> bufferIds,
) {
  final requested = bufferIds.toSet();
  return _confirmUnsavedChanges(
    context,
    _container(ref),
    dirtyBufferIds: [
      for (final buffer in ref.read(workspaceControllerProvider).dirtyBuffers)
        if (requested.contains(buffer.id)) buffer.id,
    ],
  );
}

Future<bool> _confirmUnsavedChanges(
  BuildContext context,
  ProviderContainer container, {
  required List<String> dirtyBufferIds,
  bool withoutActivatingBuffers = false,
  bool Function()? canContinue,
  bool deferDiscard = false,
}) async {
  final initialState = container.read(workspaceControllerProvider);
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
  final action = await showBusyMarkModalDialog<_UnsavedChangesAction>(
    context,
    builder: (context) => BusyMarkAlert(
      heading: context.l10n.unsavedChanges,
      responses: [
        BusyMarkAlertResponse(
          label: context.l10n.cancel,
          onPressed: () => Navigator.pop(context, _UnsavedChangesAction.cancel),
        ),
        BusyMarkAlertResponse(
          label: context.l10n.discard,
          destructive: true,
          onPressed: () =>
              Navigator.pop(context, _UnsavedChangesAction.discard),
        ),
        BusyMarkAlertResponse(
          label: context.l10n.save,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final buffer in dirtyBuffers)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: BusyMarkSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        BusyMarkGlyphs.document,
                        size: BusyMarkSizes.iconSm,
                      ),
                      const SizedBox(width: BusyMarkSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(buffer.displayName),
                            if (buffer.filePath != null)
                              Text(
                                buffer.filePath!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    ),
  );

  if (canContinue?.call() == false || !context.mounted) {
    return false;
  }
  final currentState = container.read(workspaceControllerProvider);
  final currentDirtyIds = currentState.dirtyBuffers
      .map((buffer) => buffer.id)
      .toSet();
  if (action != null &&
      action != _UnsavedChangesAction.cancel &&
      (currentState.workspace?.id != initialWorkspaceId ||
          currentState.activeBufferId != initialActiveBufferId ||
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
    if (deferDiscard) return true;
    if (withoutActivatingBuffers) {
      return container
          .read(workspaceControllerProvider.notifier)
          .discardDocumentBuffers(dirtyBufferIds);
    }
    return _discardDirtyDocuments(container, dirtyBufferIds);
  }
  if (action == _UnsavedChangesAction.save) {
    if (!context.mounted) {
      return false;
    }
    return withoutActivatingBuffers
        ? _saveDirtyDocumentsWithoutActivation(
            context,
            container,
            dirtyBufferIds,
          )
        : _saveDirtyDocuments(context, container, dirtyBufferIds);
  }
  return false;
}

Future<bool> _saveDirtyDocumentsWithoutActivation(
  BuildContext context,
  ProviderContainer container,
  List<String> bufferIds,
) async {
  final controller = container.read(workspaceControllerProvider.notifier);
  final firstResult = await controller.saveAll(bufferIds: bufferIds);
  if (firstResult.failedBufferIds.isNotEmpty ||
      firstResult.conflictBufferIds.isNotEmpty) {
    return false;
  }
  if (firstResult.normalizationRequiredBufferIds.isNotEmpty) {
    final normalizations = <String, LineEndingNormalization>{};
    for (final bufferId in firstResult.normalizationRequiredBufferIds) {
      if (!context.mounted) return false;
      final buffer = container
          .read(workspaceControllerProvider)
          .documentBuffers
          .where((candidate) => candidate.id == bufferId)
          .firstOrNull;
      if (buffer == null || !buffer.isDirty) continue;
      final normalization = await _chooseMixedLineEndingNormalizationForFormat(
        context,
        buffer.format,
      );
      if (normalization == null) return false;
      normalizations[bufferId] = normalization;
    }
    final normalizedResult = await controller.saveAll(
      bufferIds: firstResult.normalizationRequiredBufferIds,
      mixedLineEndingNormalizations: normalizations,
    );
    if (!normalizedResult.succeeded) return false;
  }
  return bufferIds.every((id) {
    final buffer = container
        .read(workspaceControllerProvider)
        .documentBuffers
        .where((candidate) => candidate.id == id)
        .firstOrNull;
    return buffer == null || !buffer.isDirty;
  });
}

Future<bool> _saveDirtyDocuments(
  BuildContext context,
  ProviderContainer container,
  List<String> bufferIds,
) async {
  final controller = container.read(workspaceControllerProvider.notifier);
  final originalActiveId = container
      .read(workspaceControllerProvider)
      .activeBufferId;
  for (final bufferId in bufferIds) {
    final current = container
        .read(workspaceControllerProvider)
        .documentBuffers
        .where((buffer) => buffer.id == bufferId)
        .firstOrNull;
    if (current == null || !current.isDirty) {
      continue;
    }
    if (!await controller.activateDocumentBuffer(bufferId) ||
        !context.mounted ||
        !await _saveActiveWithOverwriteConfirmation(context, container)) {
      await _restoreActiveBuffer(container, controller, originalActiveId);
      return false;
    }
  }
  await _restoreActiveBuffer(container, controller, originalActiveId);
  return bufferIds.every((id) {
    final buffer = container
        .read(workspaceControllerProvider)
        .documentBuffers
        .where((candidate) => candidate.id == id)
        .firstOrNull;
    return buffer == null || !buffer.isDirty;
  });
}

Future<bool> _discardDirtyDocuments(
  ProviderContainer container,
  List<String> bufferIds,
) async {
  final controller = container.read(workspaceControllerProvider.notifier);
  final originalActiveId = container
      .read(workspaceControllerProvider)
      .activeBufferId;
  for (final bufferId in bufferIds) {
    final current = container
        .read(workspaceControllerProvider)
        .documentBuffers
        .where((buffer) => buffer.id == bufferId)
        .firstOrNull;
    if (current == null || !current.isDirty) {
      continue;
    }
    if (!await controller.activateDocumentBuffer(bufferId)) {
      await _restoreActiveBuffer(container, controller, originalActiveId);
      return false;
    }
    final target = controller.captureActiveDocumentSaveTarget();
    final discarded = current.deletedOnDisk
        ? await controller.closeDocumentBuffer(bufferId, discard: true)
        : await controller.discardActiveChanges(target: target);
    if (!discarded) {
      await _restoreActiveBuffer(container, controller, originalActiveId);
      return false;
    }
  }
  await _restoreActiveBuffer(container, controller, originalActiveId);
  return true;
}

Future<void> _restoreActiveBuffer(
  ProviderContainer container,
  WorkspaceController controller,
  String? bufferId,
) async {
  if (bufferId != null &&
      container
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
  if (!ref.read(workspaceControllerProvider.notifier).propertyEdits.flush()) {
    return false;
  }
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
}) => _saveActiveWithOverwriteConfirmation(
  context,
  _container(ref),
  target: target,
);

Future<bool> _saveActiveWithOverwriteConfirmation(
  BuildContext context,
  ProviderContainer container, {
  ActiveDocumentSaveTarget? target,
}) async {
  final controller = container.read(workspaceControllerProvider.notifier);
  if (!controller.propertyEdits.flush()) return false;
  final operationTarget =
      target ?? controller.captureActiveDocumentSaveTarget();
  if (operationTarget == null ||
      !controller.isActiveDocumentSaveTargetCurrent(operationTarget)) {
    return false;
  }
  if (operationTarget.needsSaveLocation) {
    return _saveActiveAs(context, container, operationTarget);
  }
  final normalization = await _chooseMixedLineEndingNormalization(
    context,
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
  final state = container.read(workspaceControllerProvider);
  if (!controller.isActiveDocumentSaveTargetCurrent(operationTarget) ||
      state.message?.code !=
          WorkspaceMessageCode.saveBlockedFileChangedOnDisk) {
    return false;
  }
  if (!context.mounted) {
    return false;
  }
  final action = await showBusyMarkModalDialog<_OverwriteAction>(
    context,
    builder: (context) => BusyMarkAlert(
      heading: context.l10n.fileChangedOnDisk,
      responses: [
        BusyMarkAlertResponse(
          label: context.l10n.cancel,
          onPressed: () => Navigator.pop(context, _OverwriteAction.cancel),
        ),
        BusyMarkAlertResponse(
          label: context.l10n.overwrite,
          destructive: true,
          onPressed: () => Navigator.pop(context, _OverwriteAction.overwrite),
        ),
      ],
      children: [
        Text(context.l10n.fileChangedOnDiskMessage),
        if (state.message?.error case final AtomicFileChangedException error
            when error.recoveryPath != null)
          Text(error.toString()),
      ],
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
  final container = _container(ref);
  final controller = container.read(workspaceControllerProvider.notifier);
  final target = controller.captureActiveDocumentSaveTarget();
  if (target == null) {
    return false;
  }
  return _saveActiveAs(context, container, target);
}

Future<bool> _saveActiveAs(
  BuildContext context,
  ProviderContainer container,
  ActiveDocumentSaveTarget target,
) async {
  final controller = container.read(workspaceControllerProvider.notifier);
  if (!controller.isActiveDocumentSaveTargetCurrent(target)) {
    return false;
  }
  final normalization = await _chooseMixedLineEndingNormalization(
    context,
    target,
  );
  if (target.format.hasMixedLineEndings && normalization == null) {
    return false;
  }
  if (!context.mounted) {
    return false;
  }
  final activePath = target.path;
  final destination = await pickSaveDestination(
    context,
    suggestedName: activePath == null || activePath.isEmpty
        ? context.l10n.untitledMarkdownFileName
        : p.basename(activePath),
    initialDirectory: activePath == null || activePath.isEmpty
        ? null
        : p.dirname(activePath),
    actionLabel: context.l10n.save,
    suffix: '.md',
    filterLabel: context.l10n.fileTypeMarkdown,
    patterns: const ['*.[mM][dD]', '*.[mM][aA][rR][kK][dD][oO][wW][nN]'],
    suffixOnlyWhenMissing: true,
    kind: target.workspaceKind == WorkspaceKind.nextcloudNotes
        ? SaveDestinationKind.file
        : SaveDestinationKind.fileOrSymbolicLink,
    isCurrent: () => controller.isActiveDocumentSaveTargetCurrent(target),
  );
  if (destination == null ||
      !controller.isActiveDocumentSaveTargetCurrent(target)) {
    return false;
  }
  return controller.saveActiveAs(
    destination.path,
    target: target,
    overwriteExisting: destination.replacesExisting,
    authorization: destination,
    mixedLineEndingNormalization: normalization,
  );
}

Future<LineEndingNormalization?> _chooseMixedLineEndingNormalization(
  BuildContext context,
  ActiveDocumentSaveTarget target,
) => _chooseMixedLineEndingNormalizationForFormat(context, target.format);

Future<LineEndingNormalization?> _chooseMixedLineEndingNormalizationForFormat(
  BuildContext context,
  TextFormatMetadata format,
) async {
  if (!format.hasMixedLineEndings) {
    return null;
  }
  return showBusyMarkModalDialog<LineEndingNormalization>(
    context,
    builder: (context) => BusyMarkNativeDialogShell(
      title: context.l10n.normalizeLineEndings,
      maxWidth: BusyMarkSizes.dialog,
      actions: [
        BusyMarkNativeDialogButton(
          label: context.l10n.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        BusyMarkNativeDialogButton(
          label: LineEndingNormalization.lf.name.toUpperCase(),
          onPressed: () => Navigator.pop(context, LineEndingNormalization.lf),
        ),
        BusyMarkNativeDialogButton(
          label: LineEndingNormalization.crlf.name.toUpperCase(),
          suggested: true,
          onPressed: () => Navigator.pop(context, LineEndingNormalization.crlf),
        ),
      ],
      children: [Text(context.l10n.mixedLineEndingsSavePrompt)],
    ),
  );
}
