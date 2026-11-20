import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../app/app_router.dart';
import '../app/app_settings.dart';
import '../app/busymark_design.dart';
import '../app/busymark_dialogs.dart';
import '../app/localization.dart';
import '../nextcloud_notes/presentation/nextcloud_settings.dart';
import '../search/welcome_notes_action.dart';
import 'presentation/create_writerside_project_dialog.dart';
import 'workspace_controller.dart';
import 'workspace_navigation.dart';

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

Future<void> performWorkspaceResourceAction(
  WidgetRef ref,
  WorkspaceResourceAction action,
) {
  final navigation = ref.read(workspaceNavigationProvider);
  return navigation.run(action, (origin, currentRequest) async {
    final context = navigation.dialogContext;
    if (context == null) return;
    final container = navigation.container;
    final controller = container.read(workspaceControllerProvider.notifier);
    final lastPath = container
        .read(appSettingsControllerProvider)
        .lastOpenedPath;
    final initialDirectory = lastPath == null || lastPath.isEmpty
        ? null
        : p.extension(lastPath).isEmpty
        ? lastPath
        : p.dirname(lastPath);
    final l10n = context.l10n;

    Future<bool> canDepartSettings() async =>
        currentRequest() &&
        (origin.path != settingsRoutePath ||
            await confirmNotesSettingsDeparture(context)) &&
        currentRequest();

    Future<bool> confirmDeparture({
      bool deferDiscard = false,
      bool Function()? canContinue,
    }) => navigation.confirmDeparture(
      canContinue: () => currentRequest() && canContinue?.call() != false,
      deferDiscard: deferDiscard,
    );

    switch (action) {
      case WorkspaceResourceAction.newMarkdown:
        if (!await canDepartSettings()) return;
        final replacesWorkspace =
            settingsReturnTargetForUri(origin) ==
                SettingsReturnTarget.welcome ||
            container.read(workspaceControllerProvider).workspace?.isRemote ==
                true;
        if (replacesWorkspace &&
            (!await confirmDeparture() || !currentRequest())) {
          return;
        }
        final created = replacesWorkspace
            ? await controller.createMarkdownWorkspace(
                acceptNavigation: currentRequest,
              )
            : await controller.createMarkdownFile();
        if (created && currentRequest()) {
          navigation.reveal(focusNewDocument: true);
        }
      case WorkspaceResourceAction.newNote:
      case WorkspaceResourceAction.browseNotes:
        if (!await canDepartSettings()) return;
        await performWelcomeNotesAction(
          navigation,
          origin,
          currentRequest,
          action == WorkspaceResourceAction.newNote
              ? WelcomeNotesAction.create
              : WelcomeNotesAction.browse,
        );
      case WorkspaceResourceAction.newWriterside:
        final parentPath = await getDirectoryPath(
          initialDirectory: initialDirectory,
          confirmButtonText: l10n.chooseLocation,
          canCreateDirectories: true,
        );
        if (parentPath == null ||
            !await canDepartSettings() ||
            !context.mounted) {
          return;
        }
        final bufferId = await showBusyMarkModalEditorDialog<String>(
          context,
          maxWidth: BusyMarkSizes.dialogWide,
          builder: (context) => BusyMarkCreateWritersideProjectDialog(
            parentDirectoryPath: parentPath,
            onCreate: (request, onError, onPublished) =>
                controller.createWritersideProject(
                  request,
                  authorizeReplacement: (isCurrent) => confirmDeparture(
                    deferDiscard: true,
                    canContinue: isCurrent,
                  ),
                  acceptNavigation: currentRequest,
                  onError: onError,
                  onPublished: onPublished,
                ),
          ),
        );
        if (bufferId != null &&
            currentRequest() &&
            container.read(workspaceControllerProvider).activeBufferId ==
                bufferId) {
          navigation.reveal(focusNewDocument: true);
        }
      case WorkspaceResourceAction.openMarkdown:
      case WorkspaceResourceAction.openFolder:
        final path = action == WorkspaceResourceAction.openMarkdown
            ? (await openFile(
                acceptedTypeGroups: [
                  XTypeGroup(
                    label: l10n.fileTypeMarkdown,
                    extensions: const ['md', 'markdown'],
                    mimeTypes: const ['text/markdown', 'text/x-markdown'],
                  ),
                ],
                initialDirectory: initialDirectory,
                confirmButtonText: l10n.open,
              ))?.path
            : await getDirectoryPath(
                initialDirectory: initialDirectory,
                confirmButtonText: l10n.open,
                canCreateDirectories: false,
              );
        if (path != null && await canDepartSettings()) {
          await _openPath(navigation, path, currentRequest);
        }
    }
  });
}

Future<void> openWorkspaceResourcePath(WidgetRef ref, String path) {
  if (path.isEmpty) return Future.value();
  final navigation = ref.read(workspaceNavigationProvider);
  return navigation.run((
    path: path,
  ), (_, currentRequest) => _openPath(navigation, path, currentRequest));
}

Future<void> _openPath(
  WorkspaceNavigation navigation,
  String path,
  bool Function() currentRequest,
) async {
  if (!await navigation.confirmDeparture(canContinue: currentRequest) ||
      !currentRequest()) {
    return;
  }
  await navigation.container
      .read(workspaceControllerProvider.notifier)
      .openPath(
        path,
        acceptNavigation: currentRequest,
        onOpened: () {
          if (currentRequest()) navigation.reveal();
        },
      );
}
