import '../../app/busymark_design.dart';
import '../domain/git_models.dart';

BusyMarkVcsFileColor busyMarkVcsFileColorForGitStatus(GitFileStatus file) {
  return switch (file.category) {
    GitFileStatusCategory.added => BusyMarkVcsFileColor.added,
    GitFileStatusCategory.deleted => BusyMarkVcsFileColor.deleted,
    GitFileStatusCategory.renamed => BusyMarkVcsFileColor.renamed,
    GitFileStatusCategory.copied => BusyMarkVcsFileColor.copied,
    GitFileStatusCategory.untracked => BusyMarkVcsFileColor.untracked,
    GitFileStatusCategory.conflicted => BusyMarkVcsFileColor.conflicted,
    GitFileStatusCategory.ignored ||
    GitFileStatusCategory.typeChanged ||
    GitFileStatusCategory.modified ||
    GitFileStatusCategory.unknown => BusyMarkVcsFileColor.modified,
  };
}

BusyMarkVcsFileColor busyMarkVcsFileColorForChangeStatus(
  GitFileChangeStatus status,
) {
  return switch (status) {
    GitFileChangeStatus.added => BusyMarkVcsFileColor.added,
    GitFileChangeStatus.deleted => BusyMarkVcsFileColor.deleted,
    GitFileChangeStatus.renamed => BusyMarkVcsFileColor.renamed,
    GitFileChangeStatus.copied => BusyMarkVcsFileColor.copied,
    GitFileChangeStatus.untracked => BusyMarkVcsFileColor.untracked,
    GitFileChangeStatus.unmerged => BusyMarkVcsFileColor.conflicted,
    GitFileChangeStatus.unmodified ||
    GitFileChangeStatus.modified ||
    GitFileChangeStatus.typeChanged ||
    GitFileChangeStatus.ignored ||
    GitFileChangeStatus.unknown => BusyMarkVcsFileColor.modified,
  };
}
