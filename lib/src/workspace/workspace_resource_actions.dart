import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../app/app_router.dart';
import '../app/app_settings.dart';
import '../app/busymark_design.dart';
import '../app/busymark_dialogs.dart';
import '../app/localization.dart';
import '../nextcloud_notes/presentation/nextcloud_settings.dart';
import '../local_history/local_history_controller.dart';
import '../search/search_session.dart';
import '../search/welcome_notes_action.dart';
import 'document_navigation.dart';
import 'presentation/create_writerside_project_dialog.dart';
import 'workspace_controller.dart';
import 'workspace_safety.dart';

enum WorkspaceResourceAction {
  newMarkdown,
  newNote,
  newWriterside,
  openMarkdown,
  openFolder,
  browseNotes;

  static WorkspaceResourceAction forNotes(WelcomeNotesAction action) =>
      switch (action) {
        WelcomeNotesAction.create => newNote,
        WelcomeNotesAction.browse => browseNotes,
      };
}

final _resourceActionProvider = Provider((ref) => _ResourceAction());

class _ResourceAction {
  bool running = false;
}

Future<void> performWorkspaceResourceAction(
  BuildContext context,
  WidgetRef ref,
  WorkspaceResourceAction action,
) async {
  final operation = ref.read(_resourceActionProvider);
  if (operation.running) return;
  operation.running = true;
  try {
    final router = ref.read(appRouterProvider);
    final origin = router.routeInformationProvider.value.uri;
    bool currentRequest() =>
        context.mounted && router.routeInformationProvider.value.uri == origin;
    final controller = ref.read(workspaceControllerProvider.notifier);
    final initialDirectory = _initialDirectory(ref);

    Future<bool> canDepartSettings() async =>
        currentRequest() &&
        (origin.path != settingsRoutePath ||
            await confirmNotesSettingsDeparture(context)) &&
        currentRequest();

    switch (action) {
      case WorkspaceResourceAction.newMarkdown:
        if (!await canDepartSettings() || !context.mounted) return;
        final replacesWorkspace =
            settingsReturnTargetForUri(origin) ==
                SettingsReturnTarget.welcome ||
            ref.read(workspaceControllerProvider).workspace?.isRemote == true;
        if (replacesWorkspace &&
            (!await confirmSafeToContinue(context, ref) || !currentRequest())) {
          return;
        }
        // Expose the editor before it tries to claim the creation focus.
        ref.read(searchSessionProvider.notifier).close(restoreFocus: false);
        ref.read(localHistoryControllerProvider.notifier).clearComparison();
        final created = replacesWorkspace
            ? await controller.createMarkdownWorkspace(
                focusSource: true,
                acceptNavigation: currentRequest,
              )
            : await controller.createMarkdownFile(focusSource: true);
        if (created && currentRequest()) {
          revealOpenedDocument(ref);
          router.go('/workspace');
        }
      case WorkspaceResourceAction.newNote:
      case WorkspaceResourceAction.browseNotes:
        if (!await canDepartSettings() || !context.mounted) return;
        await performWelcomeNotesAction(
          context,
          ref,
          action == WorkspaceResourceAction.newNote
              ? WelcomeNotesAction.create
              : WelcomeNotesAction.browse,
        );
      case WorkspaceResourceAction.newWriterside:
        final parentPath = await getDirectoryPath(
          initialDirectory: initialDirectory,
          confirmButtonText: context.l10n.chooseLocation,
          canCreateDirectories: true,
        );
        if (parentPath == null ||
            !await canDepartSettings() ||
            !context.mounted ||
            !await confirmSafeToContinue(context, ref) ||
            !context.mounted ||
            !currentRequest()) {
          return;
        }
        final created = await showBusyMarkModalEditorDialog<bool>(
          context,
          maxWidth: BusyMarkSizes.dialogWide,
          builder: (context) => BusyMarkCreateWritersideProjectDialog(
            parentDirectoryPath: parentPath,
            onCreate: (request) => controller.createWritersideProject(request),
            message: () => ref.read(workspaceControllerProvider).message,
          ),
        );
        if (created == true && currentRequest()) {
          ref.read(searchSessionProvider.notifier).close(restoreFocus: false);
          revealOpenedDocument(ref);
          final bufferId = ref.read(workspaceControllerProvider).activeBufferId;
          if (bufferId != null) controller.focusNewlyCreatedDocument(bufferId);
          router.go('/workspace');
        }
      case WorkspaceResourceAction.openMarkdown:
      case WorkspaceResourceAction.openFolder:
        final path = action == WorkspaceResourceAction.openMarkdown
            ? (await openFile(
                acceptedTypeGroups: [
                  XTypeGroup(
                    label: context.l10n.fileTypeMarkdown,
                    extensions: const ['md', 'markdown'],
                    mimeTypes: const ['text/markdown', 'text/x-markdown'],
                  ),
                ],
                initialDirectory: initialDirectory,
                confirmButtonText: context.l10n.open,
              ))?.path
            : await getDirectoryPath(
                initialDirectory: initialDirectory,
                confirmButtonText: context.l10n.open,
                canCreateDirectories: false,
              );
        if (path != null && await canDepartSettings() && context.mounted) {
          await openWorkspaceResourcePath(context, ref, path);
        }
    }
  } finally {
    operation.running = false;
  }
}

String? _initialDirectory(WidgetRef ref) {
  final lastPath = ref.read(appSettingsControllerProvider).lastOpenedPath;
  if (lastPath == null || lastPath.isEmpty) return null;
  return p.extension(lastPath).isEmpty ? lastPath : p.dirname(lastPath);
}

Future<void> openWorkspaceResourcePath(
  BuildContext context,
  WidgetRef ref,
  String path,
) async {
  if (path.isEmpty) return;
  final router = ref.read(appRouterProvider);
  final origin = router.routeInformationProvider.value.uri;
  bool currentRequest() =>
      context.mounted && router.routeInformationProvider.value.uri == origin;
  if (!await confirmSafeToContinue(context, ref) || !currentRequest()) return;
  await ref
      .read(workspaceControllerProvider.notifier)
      .openPath(
        path,
        acceptNavigation: currentRequest,
        onOpened: () {
          if (!currentRequest()) return;
          revealOpenedDocument(ref);
          ref.read(searchSessionProvider.notifier).close(restoreFocus: false);
          router.go('/workspace');
        },
      );
}
