import '../app/command_registry.dart';
import '../workspace/workspace_model.dart';
import 'search_session.dart';

bool searchActionEnabled(
  BusyMarkCommandRegistry registry,
  BusyMarkCommand command,
  SearchSessionController controller,
  WorkspaceState workspace,
) {
  final target = controller.commandTarget;
  if (registry.requiresDocumentTarget(command) &&
      (!controller.workspaceVisible ||
          target?.bufferId == null ||
          target?.isCurrent(workspace) != true)) {
    return false;
  }
  final activeNotesAction =
      controller.workspaceVisible &&
      (workspace.workspace?.isRemote == true ||
          controller.actionAccountId != null) &&
      {
        BusyMarkCommandIds.newNote,
        BusyMarkCommandIds.browseNotes,
      }.contains(command.id);
  if ((registry.requiresWorkspaceTarget(command) || activeNotesAction) &&
      (!controller.workspaceVisible ||
          target?.workspaceId == null ||
          target?.workspaceId != workspace.workspace?.id)) {
    return false;
  }
  if (registry.isContextual(command)) {
    return controller.workspaceVisible &&
        target?.isCurrent(workspace) == true &&
        registry.canExecuteInContext(command.id, target!.context);
  }
  if (!controller.workspaceVisible &&
      command.scope != BusyMarkCommandScope.application) {
    return false;
  }
  return command.canExecute;
}
