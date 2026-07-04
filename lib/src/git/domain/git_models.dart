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
  notRepository,
  invalidPath,
  invalidBranchName,
  invalidCommitMessage,
  noStagedFiles,
  noRemote,
  noUpstream,
  multipleRemotes,
  dirtyWorkspace,
  diverged,
  authentication,
  network,
  conflict,
  commandFailed,
}

enum GitView { changes, history }

class GitAvailability {
  const GitAvailability({
    required this.available,
    this.executablePath,
    this.version,
    this.unsupportedReason,
  });

  const GitAvailability.unavailable([String? reason])
    : available = false,
      executablePath = null,
      version = null,
      unsupportedReason = reason;

  final bool available;
  final String? executablePath;
  final String? version;
  final String? unsupportedReason;
}

class GitRepositoryInfo {
  const GitRepositoryInfo({
    required this.rootPath,
    required this.gitDirPath,
    this.currentBranch,
    this.detachedHeadCommit,
    this.upstreamBranch,
    this.aheadCount = 0,
    this.behindCount = 0,
    this.hasRemote = false,
    this.isBare = false,
    this.isRebasing = false,
    this.isMerging = false,
    this.isCherryPicking = false,
    this.hasConflicts = false,
  });

  final String rootPath;
  final String gitDirPath;
  final String? currentBranch;
  final String? detachedHeadCommit;
  final String? upstreamBranch;
  final int aheadCount;
  final int behindCount;
  final bool hasRemote;
  final bool isBare;
  final bool isRebasing;
  final bool isMerging;
  final bool isCherryPicking;
  final bool hasConflicts;

  GitRepositoryInfo copyWith({
    String? rootPath,
    String? gitDirPath,
    Object? currentBranch = _unset,
    Object? detachedHeadCommit = _unset,
    Object? upstreamBranch = _unset,
    int? aheadCount,
    int? behindCount,
    bool? hasRemote,
    bool? isBare,
    bool? isRebasing,
    bool? isMerging,
    bool? isCherryPicking,
    bool? hasConflicts,
  }) {
    return GitRepositoryInfo(
      rootPath: rootPath ?? this.rootPath,
      gitDirPath: gitDirPath ?? this.gitDirPath,
      currentBranch: identical(currentBranch, _unset)
          ? this.currentBranch
          : currentBranch as String?,
      detachedHeadCommit: identical(detachedHeadCommit, _unset)
          ? this.detachedHeadCommit
          : detachedHeadCommit as String?,
      upstreamBranch: identical(upstreamBranch, _unset)
          ? this.upstreamBranch
          : upstreamBranch as String?,
      aheadCount: aheadCount ?? this.aheadCount,
      behindCount: behindCount ?? this.behindCount,
      hasRemote: hasRemote ?? this.hasRemote,
      isBare: isBare ?? this.isBare,
      isRebasing: isRebasing ?? this.isRebasing,
      isMerging: isMerging ?? this.isMerging,
      isCherryPicking: isCherryPicking ?? this.isCherryPicking,
      hasConflicts: hasConflicts ?? this.hasConflicts,
    );
  }
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
}

class GitStatusSnapshot {
  const GitStatusSnapshot({required this.repositoryInfo, required this.files});

  final GitRepositoryInfo repositoryInfo;
  final List<GitFileStatus> files;

  List<GitFileStatus> get stagedFiles =>
      files.where((file) => file.staged && !file.conflicted).toList();

  List<GitFileStatus> get unstagedFiles => files
      .where((file) => file.unstaged && !file.untracked && !file.conflicted)
      .toList();

  List<GitFileStatus> get untrackedFiles =>
      files.where((file) => file.untracked).toList();

  List<GitFileStatus> get conflictedFiles =>
      files.where((file) => file.conflicted).toList();

  bool get clean => files.isEmpty;
}

class GitCommitSummary {
  const GitCommitSummary({
    required this.fullHash,
    required this.shortHash,
    required this.authorName,
    required this.authorEmail,
    required this.authorDate,
    required this.subject,
    required this.parentHashes,
  });

  final String fullHash;
  final String shortHash;
  final String authorName;
  final String authorEmail;
  final DateTime authorDate;
  final String subject;
  final List<String> parentHashes;
}

class GitCommitDetails {
  const GitCommitDetails({
    required this.summary,
    this.body,
    required this.changedFiles,
    required this.patch,
    this.fileSnapshots = const {},
  });

  final GitCommitSummary summary;
  final String? body;
  final List<GitDiffFile> changedFiles;
  final String patch;
  final Map<String, String> fileSnapshots;
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
  });

  final String? oldPath;
  final String? newPath;
  final GitDiffFileStatus status;
  final List<GitDiffHunk> hunks;
  final bool binary;
  final int additions;
  final int deletions;

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
  }) {
    return GitDiffFile(
      oldPath: oldPath ?? this.oldPath,
      newPath: newPath ?? this.newPath,
      status: status ?? this.status,
      hunks: hunks ?? this.hunks,
      binary: binary ?? this.binary,
      additions: additions ?? this.additions,
      deletions: deletions ?? this.deletions,
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

class GitOperationResult {
  const GitOperationResult({
    required this.success,
    required this.message,
    required this.stdout,
    required this.stderr,
    this.updatedStatus,
  });

  final bool success;
  final String message;
  final String stdout;
  final String stderr;
  final GitStatusSnapshot? updatedStatus;
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

class GitBranch {
  const GitBranch({
    required this.name,
    required this.current,
    this.upstream,
    this.objectName,
    this.subject,
  });

  final String name;
  final bool current;
  final String? upstream;
  final String? objectName;
  final String? subject;
}

const Object _unset = Object();
