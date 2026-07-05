import 'package:flutter/widgets.dart';

import '../app/localization.dart';
import '../core/busymark_exception.dart';

enum WorkspaceMessageCode {
  openFailed,
  createWritersideProjectFailed,
  createWritersideTopicFailed,
  couldNotOpenFile,
  chooseWhereToSaveMarkdown,
  saveBlockedFileChangedOnDisk,
  saveFailed,
  fileOperationFailed,
  validationFailed,
}

class WorkspaceMessage {
  const WorkspaceMessage(this.code, {this.error});

  final WorkspaceMessageCode code;
  final Object? error;
}

String localizeWorkspaceMessage(
  BuildContext context,
  WorkspaceMessage message,
) {
  final l10n = context.l10n;
  final error = _localizeWorkspaceError(context, message.error);
  return switch (message.code) {
    WorkspaceMessageCode.openFailed => l10n.workspaceErrorOpenFailed(error),
    WorkspaceMessageCode.createWritersideProjectFailed =>
      l10n.workspaceErrorCreateWritersideProjectFailed(error),
    WorkspaceMessageCode.createWritersideTopicFailed =>
      l10n.workspaceErrorCreateWritersideTopicFailed(error),
    WorkspaceMessageCode.couldNotOpenFile =>
      l10n.workspaceErrorCouldNotOpenFile(error),
    WorkspaceMessageCode.chooseWhereToSaveMarkdown =>
      l10n.workspaceErrorChooseWhereToSaveMarkdown,
    WorkspaceMessageCode.saveBlockedFileChangedOnDisk =>
      l10n.workspaceErrorSaveBlockedFileChangedOnDisk,
    WorkspaceMessageCode.saveFailed => l10n.workspaceErrorSaveFailed(error),
    WorkspaceMessageCode.fileOperationFailed =>
      l10n.workspaceErrorFileOperationFailed(error),
    WorkspaceMessageCode.validationFailed =>
      l10n.workspaceErrorValidationFailed(error),
  };
}

String _localizeWorkspaceError(BuildContext context, Object? error) {
  final l10n = context.l10n;
  if (error is BusyMarkException) {
    String value(String key) => '${error.args[key] ?? ''}';
    return switch (error.code) {
      'workspace.path-does-not-exist' => l10n.errorPathDoesNotExist(
        value('path'),
      ),
      'writerside.project.target-directory-not-empty' =>
        l10n.errorTargetDirectoryNotEmpty(value('path')),
      'writerside.project.target-path-not-directory' =>
        l10n.errorTargetPathNotDirectory(value('path')),
      'writerside.project.generated-file-exists' =>
        l10n.errorGeneratedFileAlreadyExists(value('path')),
      'writerside.project.parent-directory-required' =>
        l10n.errorParentDirectoryRequired,
      'writerside.project.parent-directory-missing' =>
        l10n.errorParentDirectoryMissing(value('path')),
      'writerside.project.name-required' => l10n.errorProjectNameRequired,
      'writerside.project.directory-required' =>
        l10n.errorDirectoryNameRequired,
      'writerside.project.directory-unsafe' => l10n.errorDirectoryNameUnsafe,
      'writerside.project.instance-id-invalid' => l10n.errorInstanceIdInvalid,
      'writerside.project.topic-file-invalid' => l10n.errorTopicFileInvalid,
      'writerside.project.topic-title-required' => l10n.errorTopicTitleRequired,
      'writerside.topic.module-root-missing' =>
        l10n.errorWritersideModuleRootMissing(value('path')),
      'writerside.topic.module-not-open' => l10n.errorWritersideModuleNotOpen,
      'writerside.topic.instance-tree-missing' =>
        l10n.errorWritersideInstanceTreeMissing,
      'writerside.topic.tree-file-missing' =>
        l10n.errorWritersideTreeFileMissing(value('path')),
      'writerside.topic.id-exists' => l10n.errorTopicIdAlreadyExists(
        value('topicId'),
      ),
      'writerside.topic.title-required' => l10n.errorTopicTitleRequired,
      'writerside.topic.file-exists' => l10n.errorTopicFileAlreadyExists(
        value('path'),
      ),
      'writerside.topic.reference-missing' => l10n.errorReferenceTopicMissing(
        value('topic'),
      ),
      'writerside.topic.topics-root-unsafe' => l10n.errorTopicsRootUnsafe,
      'writerside.topic.file-name-unsafe' => l10n.errorTopicFileNameUnsafe,
      'writerside.topic.file-extension-mismatch' =>
        l10n.errorTopicFileExtensionMismatch(value('extension')),
      'writerside.topic.file-name-invalid' => l10n.errorTopicFileNameInvalid,
      'workspace.directory-missing' => l10n.errorDirectoryMissing(
        value('path'),
      ),
      'workspace.file-name-required' => l10n.errorFileNameRequired,
      'workspace.file-name-unsafe' => l10n.errorFileNameUnsafe,
      'workspace.file-operation-invalid-target' =>
        l10n.errorFileOperationInvalidTarget,
      'workspace.file-operation-outside-root' =>
        l10n.errorFileOperationOutsideRoot,
      'workspace.file-operation-root' => l10n.errorFileOperationRoot,
      'workspace.path-already-exists' => l10n.errorPathAlreadyExists(
        value('path'),
      ),
      _ => l10n.errorUnknown(error.code),
    };
  }
  return '${error ?? ''}';
}
