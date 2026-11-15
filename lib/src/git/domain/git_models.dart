import 'package:busystack_git/busystack_git.dart' as shared;

enum GitFileChangeStatus {
  unmodified,
  modified,
  added,
  deleted,
  renamed,
  copied,
  typeChanged,
  unmerged,
  untracked,
  ignored,
  unknown,
}

enum GitFileStatusCategory {
  modified,
  added,
  deleted,
  renamed,
  copied,
  untracked,
  ignored,
  conflicted,
  typeChanged,
  unknown,
}

enum GitDiffLineKind { added, removed, context, header }

enum GitDiffFileStatus {
  modified,
  added,
  deleted,
  renamed,
  copied,
  binary,
  unknown,
}

enum GitFailureCode {
  unavailable,
  unsupportedVersion,
  invalidPath,
  dirtyWorkspace,
  authorIdentity,
  authentication,
  network,
  conflict,
  commandFailed,
}

class GitAvailability {
  const GitAvailability({
    required this.available,
    this.executablePath,
    this.version,
    this.unavailableReason,
  });

  const GitAvailability.unavailable([String? reason])
    : available = false,
      executablePath = null,
      version = null,
      unavailableReason = reason;

  final bool available;
  final String? executablePath;
  final String? version;
  final String? unavailableReason;
}

class GitRepositoryInfo {
  const GitRepositoryInfo({
    required this.rootPath,
    required this.gitDirPath,
    this.identityKey,
  });

  final String rootPath;
  final String gitDirPath;
  final String? identityKey;
}

class GitFileStatus {
  const GitFileStatus({
    required this.repoRelativePath,
    required this.absolutePath,
    this.originalRepoRelativePath,
    required this.indexStatus,
    required this.workTreeStatus,
    required this.category,
    required this.staged,
    required this.unstaged,
    required this.untracked,
    required this.deleted,
    required this.renamed,
    required this.copied,
    required this.conflicted,
    required this.ignored,
  });

  final String repoRelativePath;
  final String absolutePath;
  final String? originalRepoRelativePath;
  final GitFileChangeStatus indexStatus;
  final GitFileChangeStatus workTreeStatus;
  final GitFileStatusCategory category;
  final bool staged;
  final bool unstaged;
  final bool untracked;
  final bool deleted;
  final bool renamed;
  final bool copied;
  final bool conflicted;
  final bool ignored;

  bool get hasStagedRename => indexStatus == GitFileChangeStatus.renamed;

  bool get hasUnstagedRename => workTreeStatus == GitFileChangeStatus.renamed;

  bool get hasWorkingTreeFile {
    if (untracked) {
      return true;
    }
    if (workTreeStatus == GitFileChangeStatus.deleted) {
      return false;
    }
    return indexStatus != GitFileChangeStatus.deleted ||
        workTreeStatus != GitFileChangeStatus.unmodified;
  }
}

class GitStatusSnapshot {
  const GitStatusSnapshot({
    required this.repositoryInfo,
    required this.files,
    this.unrepresentedPathCount = 0,
    this.source,
  });

  final GitRepositoryInfo repositoryInfo;
  final List<GitFileStatus> files;

  /// Retain byte paths and repository identity for shared presentation.
  final shared.GitSnapshot? source;

  /// Byte-named entries are reviewed in the shared Git surfaces. String-only
  /// authoring decorations must not turn their escaped labels into paths.
  final int unrepresentedPathCount;

  List<GitFileStatus> get stagedFiles =>
      files.where((file) => file.staged && !file.conflicted).toList();

  List<GitFileStatus> get unstagedFiles => files
      .where((file) => file.unstaged && !file.untracked && !file.conflicted)
      .toList();

  List<GitFileStatus> get untrackedFiles =>
      files.where((file) => file.untracked).toList();

  List<GitFileStatus> get conflictedFiles =>
      files.where((file) => file.conflicted).toList();

  bool get clean => files.isEmpty && unrepresentedPathCount == 0;
}

class GitDiff {
  const GitDiff({
    required this.title,
    required this.files,
    required this.rawPatch,
    required this.hasBinaryFiles,
    this.fileSnapshots = const {},
  });

  final String title;
  final List<GitDiffFile> files;
  final String rawPatch;
  final bool hasBinaryFiles;
  final Map<String, String> fileSnapshots;
}

class GitDiffFile {
  const GitDiffFile({
    this.oldPath,
    this.newPath,
    required this.status,
    required this.hunks,
    required this.binary,
    required this.additions,
    required this.deletions,
    this.binarySize,
  });

  final String? oldPath;
  final String? newPath;
  final GitDiffFileStatus status;
  final List<GitDiffHunk> hunks;
  final bool binary;
  final int additions;
  final int deletions;
  final int? binarySize;

  String get displayPath => newPath ?? oldPath ?? '';

  bool matchesPath(String repoRelativePath) =>
      newPath == repoRelativePath || oldPath == repoRelativePath;

  GitDiffFile copyWith({
    String? oldPath,
    String? newPath,
    GitDiffFileStatus? status,
    List<GitDiffHunk>? hunks,
    bool? binary,
    int? additions,
    int? deletions,
    Object? binarySize = _unset,
  }) {
    return GitDiffFile(
      oldPath: oldPath ?? this.oldPath,
      newPath: newPath ?? this.newPath,
      status: status ?? this.status,
      hunks: hunks ?? this.hunks,
      binary: binary ?? this.binary,
      additions: additions ?? this.additions,
      deletions: deletions ?? this.deletions,
      binarySize: identical(binarySize, _unset)
          ? this.binarySize
          : binarySize as int?,
    );
  }
}

class GitDiffHunk {
  const GitDiffHunk({
    required this.oldStart,
    required this.oldCount,
    required this.newStart,
    required this.newCount,
    required this.heading,
    required this.lines,
  });

  final int oldStart;
  final int oldCount;
  final int newStart;
  final int newCount;
  final String heading;
  final List<GitDiffLine> lines;
}

class GitDiffLine {
  const GitDiffLine({
    required this.kind,
    required this.content,
    this.oldLineNumber,
    this.newLineNumber,
  });

  final GitDiffLineKind kind;
  final String content;
  final int? oldLineNumber;
  final int? newLineNumber;
}

class GitFailure {
  const GitFailure({
    required this.code,
    required this.userMessageKey,
    required this.rawMessage,
    required this.commandName,
    this.exitCode,
  });

  final GitFailureCode code;
  final String userMessageKey;
  final String rawMessage;
  final String commandName;
  final int? exitCode;
}

const Object _unset = Object();
