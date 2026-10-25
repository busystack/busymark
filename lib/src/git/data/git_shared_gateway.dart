import 'dart:convert';
import 'package:busystack_git/busystack_git.dart' as shared;
import 'package:path/path.dart' as p;
import '../../core/anchored_path_guard.dart';
import '../application/git_gateway.dart';
import '../domain/git_diff_parser.dart';
import '../domain/git_models.dart';

/// Application compatibility adapter for authoring commands and the optional
/// message drafter. All Git execution and mutations belong to busystack_git.
/// Workspace trust, dirty buffers, localization and navigation remain here.
class GitCliGateway implements GitRepositoryGateway {
  const GitCliGateway({this.engine, this.diffParser = const GitDiffParser()});
  final shared.GitEngine? engine;
  final GitDiffParser diffParser;
  static final _engines = Expando<shared.GitEngine>();
  shared.GitEngine get core =>
      engine ?? (_engines[this] ??= shared.GitEngine(authorize: (_) => true));
  @override
  bool get requiresWorkspaceTrust => true;
  Future<T> _map<T>(
    Future<T> Function() action, [
    String command = 'git',
  ]) async {
    try {
      return await action();
    } on shared.GitException catch (error) {
      throw _failure(error, command);
    } on FormatException catch (error) {
      throw GitFailure(
        code: GitFailureCode.invalidPath,
        userMessageKey: 'gitErrorUnsafePath',
        rawMessage: '$error',
        commandName: command,
      );
    }
  }

  @override
  Future<GitAvailability> availability() async {
    final runner = shared.ProcessGitRunner();
    try {
      return GitAvailability(
        available: true,
        executablePath: runner.executable,
        version: await runner.verify(),
      );
    } on shared.GitException catch (error) {
      return GitAvailability.unavailable(error.diagnostic);
    }
  }

  Future<shared.RepositoryId> _repo(GitRepositoryInfo repository) async {
    final id = await core.discover(repository.rootPath);
    if (id == null ||
        id.root != repository.rootPath ||
        id.gitDir != repository.gitDirPath ||
        repository.identityKey != null && id.key != repository.identityKey) {
      throw const shared.GitException(shared.GitErrorCode.staleReview);
    }
    return id;
  }

  @override
  Future<GitRepositoryInfo?> detectRepository(String workspacePath) =>
      _map(() async {
        final id = await core.discover(workspacePath);
        if (id == null) return null;
        final state = await core.status(id);
        final remotes =
            (await core.inspect(
                  id,
                  const shared.GitInspection(shared.GitInspectionKind.remotes),
                ))['remotes']
                as List;
        return _info(state, hasRemote: remotes.isNotEmpty);
      });
  @override
  Future<GitStatusSnapshot> status(GitRepositoryInfo repository) =>
      _map(() async {
        final id = await _repo(repository), state = await core.status(id);
        final remotes =
            (await core.inspect(
                  id,
                  const shared.GitInspection(shared.GitInspectionKind.remotes),
                ))['remotes']
                as List;
        return _status(state, hasRemote: remotes.isNotEmpty);
      }, 'status');
  GitRepositoryInfo _info(
    shared.GitSnapshot state, {
    bool hasRemote = false,
  }) => GitRepositoryInfo(
    rootPath: state.repository.root,
    gitDirPath: state.repository.gitDir,
    identityKey: state.repository.key,
    currentBranch: state.branch,
    detachedHeadCommit: state.branch == null ? state.head?.abbreviated : null,
    upstreamBranch: state.upstream,
    aheadCount: state.ahead,
    behindCount: state.behind,
    hasRemote: hasRemote,
    isBare: state.repository.bare,
    isRebasing: state.operation.kind == shared.GitOperationKind.rebase,
    isMerging: state.operation.kind == shared.GitOperationKind.merge,
    isCherryPicking: state.operation.kind == shared.GitOperationKind.cherryPick,
    hasConflicts: state.operation.unmerged,
  );
  GitStatusSnapshot _status(
    shared.GitSnapshot state, {
    bool hasRemote = false,
  }) => GitStatusSnapshot(
    repositoryInfo: _info(state, hasRemote: hasRemote),
    unrepresentedPathCount: state.changes
        .where((change) => change.path.utf8Path == null)
        .length,
    files: [
      for (final change in state.changes)
        if (change.path.utf8Path != null)
          GitFileStatus(
            repoRelativePath: change.path.utf8Path!,
            absolutePath: p.join(state.repository.root, change.path.utf8Path!),
            originalRepoRelativePath: change.originalPath?.utf8Path,
            indexStatus: _letter(change.index),
            workTreeStatus: _letter(change.worktree),
            category: change.conflicted
                ? GitFileStatusCategory.conflicted
                : change.untracked
                ? GitFileStatusCategory.untracked
                : GitFileStatusCategory.values.byName(switch (change.index ==
                          '.'
                      ? change.worktree
                      : change.index) {
                    'M' => 'modified',
                    'A' => 'added',
                    'D' => 'deleted',
                    'R' => 'renamed',
                    'C' => 'copied',
                    'T' => 'typeChanged',
                    '!' => 'ignored',
                    _ => 'unknown',
                  }),
            staged: change.staged,
            unstaged: change.unstaged,
            untracked: change.untracked,
            deleted: change.index == 'D' || change.worktree == 'D',
            renamed: change.index == 'R' || change.worktree == 'R',
            copied: change.index == 'C' || change.worktree == 'C',
            conflicted: change.conflicted,
            ignored: change.ignored,
          ),
    ],
  );
  GitFileChangeStatus _letter(String value) => switch (value) {
    'M' => GitFileChangeStatus.modified,
    'A' => GitFileChangeStatus.added,
    'D' => GitFileChangeStatus.deleted,
    'R' => GitFileChangeStatus.renamed,
    'C' => GitFileChangeStatus.copied,
    'T' => GitFileChangeStatus.typeChanged,
    'U' => GitFileChangeStatus.unmerged,
    '?' => GitFileChangeStatus.untracked,
    '!' => GitFileChangeStatus.ignored,
    '.' => GitFileChangeStatus.unmodified,
    _ => GitFileChangeStatus.unknown,
  };
  Future<void> _guard(GitRepositoryInfo repository, String path) async {
    try {
      shared.RepoPath.text(path);
      final anchor = await captureCanonicalDirectoryAnchor(repository.rootPath);
      await resolveAnchoredPath(
        anchor,
        p.join(repository.rootPath, path),
        allowRoot: false,
      );
    } on Object catch (error) {
      throw GitFailure(
        code: GitFailureCode.invalidPath,
        userMessageKey: 'gitErrorUnsafePath',
        rawMessage: '$error',
        commandName: 'path',
      );
    }
  }

  Future<GitDiff> _diff(
    shared.RepositoryId repo,
    shared.GitDiffSpec comparison,
    String title,
  ) async {
    final patch = await core.patch(repo, comparison);
    final parsed = diffParser.parse(
      utf8.decode(patch.bytes, allowMalformed: true),
      title: title,
    );
    final snapshots = <String, String>{};
    for (final file in parsed.files) {
      final path = file.newPath ?? file.oldPath;
      if (path == null) continue;
      final version = file.status == GitDiffFileStatus.deleted
          ? comparison.left
          : comparison.right;
      final value = await core.content(
        repo,
        shared.RepoPath.text(path),
        version,
      );
      if (value.text != null) snapshots[path] = value.text!;
    }
    return GitDiff(
      title: title,
      files: parsed.files,
      rawPatch: parsed.rawPatch,
      hasBinaryFiles: parsed.hasBinaryFiles,
      fileSnapshots: snapshots,
    );
  }

  @override
  Future<GitDiff> diffFile(
    GitRepositoryInfo repository,
    String repoRelativePath, {
    required bool staged,
    String? originalRepoRelativePath,
  }) => _map(() async {
    await _guard(repository, repoRelativePath);
    final id = await _repo(repository),
        state = await core.status(await _repo(repository));
    return _diff(
      id,
      shared.GitDiffSpec(
        staged
            ? state.head == null
                  ? const shared.ContentVersion.absent()
                  : shared.ContentVersion(
                      shared.ContentKind.commit,
                      revision: state.head,
                    )
            : const shared.ContentVersion.index(),
        staged
            ? const shared.ContentVersion.index()
            : const shared.ContentVersion.working(),
        paths: [
          if (originalRepoRelativePath != null)
            shared.RepoPath.text(originalRepoRelativePath),
          shared.RepoPath.text(repoRelativePath),
        ],
      ),
      repoRelativePath,
    );
  }, 'diff');
  @override
  Future<GitDiff> diffAll(
    GitRepositoryInfo repository, {
    required bool staged,
  }) => _map(() async {
    final id = await _repo(repository),
        state = await core.status(await _repo(repository));
    return _diff(
      id,
      shared.GitDiffSpec(
        staged
            ? state.head == null
                  ? const shared.ContentVersion.absent()
                  : shared.ContentVersion(
                      shared.ContentKind.commit,
                      revision: state.head,
                    )
            : const shared.ContentVersion.index(),
        staged
            ? const shared.ContentVersion.index()
            : const shared.ContentVersion.working(),
      ),
      staged ? 'Staged' : 'Unstaged',
    );
  }, 'diff');
  @override
  Future<GitDiff> diffUntrackedFile(
    GitRepositoryInfo repository,
    String repoRelativePath,
  ) => _map(() async {
    await _guard(repository, repoRelativePath);
    final id = await _repo(repository),
        path = shared.RepoPath.text(repoRelativePath);
    final value = await core.content(
      id,
      path,
      const shared.ContentVersion.working(),
    );
    if (value.availability == shared.ContentAvailability.absent) {
      return GitDiff(
        title: repoRelativePath,
        files: const [],
        rawPatch: '',
        hasBinaryFiles: false,
      );
    }
    if (value.text == null) {
      return GitDiff(
        title: repoRelativePath,
        files: [
          GitDiffFile(
            newPath: repoRelativePath,
            status: GitDiffFileStatus.binary,
            hunks: const [],
            binary: true,
            additions: 0,
            deletions: 0,
            binarySize: value.size,
          ),
        ],
        rawPatch: '',
        hasBinaryFiles: true,
      );
    }
    final diff = shared.computeTextDiff('', value.text!);
    final lines = [
      for (final edit in diff.edits)
        GitDiffLine(
          kind: GitDiffLineKind.added,
          content: edit.text.replaceFirst(RegExp(r'\r?\n$'), ''),
          newLineNumber: edit.newLine,
        ),
    ];
    return GitDiff(
      title: repoRelativePath,
      rawPatch:
          '--- /dev/null\n+++ b/$repoRelativePath\n@@ -0,0 +1,${lines.length} @@\n${shared.exactLines(value.text!).map((line) => '+$line').join()}',
      hasBinaryFiles: false,
      fileSnapshots: {repoRelativePath: value.text!},
      files: [
        GitDiffFile(
          newPath: repoRelativePath,
          status: GitDiffFileStatus.added,
          hunks: [
            GitDiffHunk(
              oldStart: 0,
              oldCount: 0,
              newStart: 1,
              newCount: lines.length,
              heading: '',
              lines: lines,
            ),
          ],
          binary: false,
          additions: lines.length,
          deletions: 0,
        ),
      ],
    );
  }, 'diff');
  GitCommitSummary _summary(shared.GitCommit value) => GitCommitSummary(
    fullHash: value.oid.value,
    shortHash: value.oid.abbreviated,
    authorName: value.author,
    authorEmail: value.email,
    authorDate: value.date,
    subject: value.subject,
    parentHashes: value.parents.map((e) => e.value).toList(),
  );
  @override
  Future<List<GitCommitSummary>> history(
    GitRepositoryInfo repository, {
    String? repoRelativePath,
    int limit = 200,
    int skip = 0,
  }) => _map(() async {
    final page = await core.history(
      await _repo(repository),
      filter: shared.HistoryFilter(
        reference: 'HEAD',
        path: repoRelativePath == null
            ? null
            : shared.RepoPath.text(repoRelativePath),
      ),
      offset: skip,
      limit: limit,
    );
    return page.commits.map(_summary).toList();
  }, 'log');
  @override
  Future<List<GitFileHistoryEntry>> fileHistory(
    GitRepositoryInfo repository,
    String repoRelativePath, {
    int limit = 200,
    int skip = 0,
  }) => _map(() async {
    final page = await core.inspect(
      await _repo(repository),
      shared.GitInspection(
        shared.GitInspectionKind.fileHistory,
        path: shared.RepoPath.text(repoRelativePath),
        offset: skip,
        limit: limit,
      ),
    );
    return [
      for (final row in (page['entries'] as List).cast<shared.Json>())
        GitFileHistoryEntry(
          commit: _summary(
            shared.GitCommit.fromJson(row['commit'] as shared.Json),
          ),
          pathAtCommit: shared.RepoPath.fromJson(row['pathAtCommit']).utf8Path!,
          pathInParent: shared.RepoPath.fromJson(row['pathInParent']).utf8Path,
          status: _fileStatus(row['status'] as String),
        ),
    ];
  }, 'log');
  GitDiffFileStatus _fileStatus(String value) => switch (value[0]) {
    'A' => GitDiffFileStatus.added,
    'D' => GitDiffFileStatus.deleted,
    'R' => GitDiffFileStatus.renamed,
    'C' => GitDiffFileStatus.copied,
    _ => GitDiffFileStatus.modified,
  };
  Future<shared.GitCommit> _commit(shared.RepositoryId id, String hash) async =>
      (await core.history(
        id,
        filter: shared.HistoryFilter(reference: hash),
        limit: 1,
      )).commits.single;
  @override
  Future<GitCommitDetails> commitDetails(
    GitRepositoryInfo repository,
    String hash, {
    String? repoRelativePath,
  }) => _map(() async {
    final id = await _repo(repository),
        commit = await _commit(await _repo(repository), hash);
    final diff = await _diff(
      id,
      shared.GitDiffSpec(
        commit.parents.isEmpty
            ? const shared.ContentVersion.absent()
            : shared.ContentVersion(
                shared.ContentKind.commit,
                revision: commit.parents.first,
              ),
        shared.ContentVersion(shared.ContentKind.commit, revision: commit.oid),
        paths: repoRelativePath == null
            ? const []
            : [shared.RepoPath.text(repoRelativePath)],
      ),
      commit.subject,
    );
    return GitCommitDetails(
      summary: _summary(commit),
      body: commit.message,
      changedFiles: diff.files,
      patch: diff.rawPatch,
      fileSnapshots: diff.fileSnapshots,
    );
  }, 'show');
  @override
  Future<String?> readFileAtCommit(
    GitRepositoryInfo repository,
    String hash,
    String repoRelativePath,
  ) => _map(
    () async => (await core.content(
      await _repo(repository),
      shared.RepoPath.text(repoRelativePath),
      shared.ContentVersion(
        shared.ContentKind.commit,
        revision: shared.GitOid(hash),
      ),
    )).text,
    'show',
  );
  Future<GitHistoricalFileComparison> _compare(
    GitRepositoryInfo repository,
    shared.ContentVersion left,
    shared.ContentVersion right,
    String? oldPath,
    String? newPath,
  ) async {
    final id = await _repo(repository),
        paths = [
          if (oldPath != null) oldPath,
          if (newPath != null && newPath != oldPath) newPath,
        ];
    final diff = await _diff(
      id,
      shared.GitDiffSpec(
        left,
        right,
        paths: paths.map(shared.RepoPath.text).toList(),
      ),
      'Compare revisions',
    );
    Future<String?> text(String? path, shared.ContentVersion version) async =>
        path == null
        ? ''
        : (await core.content(
                id,
                shared.RepoPath.text(path),
                version,
              )).availability ==
              shared.ContentAvailability.absent
        ? ''
        : (await core.content(id, shared.RepoPath.text(path), version)).text;
    return GitHistoricalFileComparison(
      oldPath: oldPath,
      newPath: newPath,
      oldContent: await text(oldPath, left),
      newContent: await text(newPath, right),
      diff: diff,
    );
  }

  @override
  Future<GitHistoricalFileComparison> compareFileWithParent(
    GitRepositoryInfo repository,
    String hash, {
    String? oldPath,
    String? newPath,
  }) => _map(() async {
    final commit = await _commit(await _repo(repository), hash);
    return _compare(
      repository,
      commit.parents.isEmpty
          ? const shared.ContentVersion.absent()
          : shared.ContentVersion(
              shared.ContentKind.commit,
              revision: commit.parents.first,
            ),
      shared.ContentVersion(shared.ContentKind.commit, revision: commit.oid),
      oldPath,
      newPath,
    );
  }, 'diff');
  @override
  Future<GitHistoricalFileComparison> compareFileWithWorkingTree(
    GitRepositoryInfo repository,
    String hash, {
    required String historicalPath,
    required String currentPath,
  }) => _map(
    () => _compare(
      repository,
      shared.ContentVersion(
        shared.ContentKind.commit,
        revision: shared.GitOid(hash),
      ),
      const shared.ContentVersion.working(),
      historicalPath,
      currentPath,
    ),
    'diff',
  );
  Future<GitOperationResult> _mutate(
    GitRepositoryInfo repository,
    shared.GitMutation Function(shared.GitSnapshot) build,
  ) => _map(() async {
    final id = await _repo(repository),
        before = await core.status(await _repo(repository));
    final result = await core.mutate(id, build(before));
    if (result.error != null) throw _failure(result.error!, 'git');
    return GitOperationResult(
      success: result.completed,
      message: result.diagnostic,
      stdout: result.diagnostic,
      stderr: '',
      updatedStatus: result.snapshot == null ? null : _status(result.snapshot!),
    );
  });
  @override
  Future<GitOperationResult> stage(
    GitRepositoryInfo r,
    List<String> paths,
  ) async {
    for (final path in paths) {
      await _guard(r, path);
    }
    return _mutate(
      r,
      (s) => shared.StagePaths(
        paths.map(shared.RepoPath.text).toList(),
        expectedHead: s.head,
        expectedIndex: s.indexToken,
        expectedSnapshot: s.token,
      ),
    );
  }

  @override
  Future<GitOperationResult> unstage(GitRepositoryInfo r, List<String> paths) =>
      _mutate(
        r,
        (s) => shared.StagePaths(
          paths.map(shared.RepoPath.text).toList(),
          unstage: true,
          expectedHead: s.head,
          expectedIndex: s.indexToken,
        ),
      );
  Future<Map<String, String>> _workingTokens(
    GitRepositoryInfo repository,
    List<String> paths,
  ) async {
    final id = await _repo(repository), tokens = <String, String>{};
    for (final value in paths) {
      final path = shared.RepoPath.text(value);
      tokens[path.key] = (await core.content(
        id,
        path,
        const shared.ContentVersion.working(),
      )).token;
    }
    return tokens;
  }

  @override
  Future<GitOperationResult> rollbackTracked(
    GitRepositoryInfo r,
    List<String> paths,
  ) => _map(() async {
    final tokens = await _workingTokens(r, paths);
    return _mutate(
      r,
      (s) => shared.RestorePaths(
        paths.map(shared.RepoPath.text).toList(),
        target: shared.RestoreTarget.both,
        revision: s.head,
        expectedHead: s.head,
        expectedIndex: s.indexToken,
        contentTokens: tokens,
      ),
    );
  });
  @override
  Future<GitOperationResult> discardUntracked(
    GitRepositoryInfo r,
    List<String> paths,
    GitStatusSnapshot snapshot,
  ) async {
    for (final path in paths) {
      await _guard(r, path);
    }
    final tokens = await _workingTokens(r, paths);
    return _mutate(
      r,
      (s) => shared.RestorePaths(
        paths.map(shared.RepoPath.text).toList(),
        discardUntracked: true,
        expectedHead: s.head,
        expectedIndex: s.indexToken,
        contentTokens: tokens,
      ),
    );
  }

  @override
  Future<GitOperationResult> commit(GitRepositoryInfo r, String message) =>
      _mutate(
        r,
        (s) => shared.CommitIndex(
          message,
          expectedHead: s.head,
          expectedIndex: s.indexToken,
        ),
      );
  @override
  Future<GitOperationResult> configureAuthorIdentity(
    GitRepositoryInfo r, {
    required String name,
    required String email,
    required bool globally,
  }) {
    if (globally) {
      throw const GitFailure(
        code: GitFailureCode.commandFailed,
        userMessageKey: 'gitErrorCommandFailed',
        rawMessage:
            'The Git integration changes repository-local identity only.',
        commandName: 'config',
      );
    }
    return _mutate(
      r,
      (s) => shared.ConfigureIdentity(
        name,
        email,
        expectedHead: s.head,
        expectedIndex: s.indexToken,
      ),
    );
  }

  @override
  Future<List<GitBranch>> branches(GitRepositoryInfo r) => _map(
    () async => [
      for (final ref in await core.references(await _repo(r)))
        if (ref.name.startsWith('refs/heads/'))
          GitBranch(
            name: ref.shortName,
            current: ref.current,
            upstream: ref.upstream,
            objectName: ref.oid.value,
            subject: ref.subject,
          ),
    ],
  );
  @override
  Future<List<String>> remotes(GitRepositoryInfo r) => _map(
    () async => [
      for (final remote
          in (await core.inspect(
                await _repo(r),
                const shared.GitInspection(shared.GitInspectionKind.remotes),
              ))['remotes']
              as List)
        (remote as Map)['name'] as String,
    ],
  );
  Future<String> _remote(GitRepositoryInfo r) async {
    final names = await remotes(r);
    if (r.upstreamBranch != null) return r.upstreamBranch!.split('/').first;
    if (names.length == 1) return names.single;
    throw GitFailure(
      code: names.isEmpty
          ? GitFailureCode.noRemote
          : GitFailureCode.multipleRemotes,
      userMessageKey: names.isEmpty
          ? 'gitErrorNoRemote'
          : 'gitErrorMultipleRemotes',
      rawMessage: '',
      commandName: 'remote',
    );
  }

  @override
  Future<GitOperationResult> fetch(GitRepositoryInfo r) async {
    final name = await _remote(r);
    return _mutate(
      r,
      (s) => shared.FetchRemote(
        name,
        expectedHead: s.head,
        expectedIndex: s.indexToken,
      ),
    );
  }

  @override
  Future<GitOperationResult> pullFastForwardOnly(GitRepositoryInfo r) async {
    final name = await _remote(r);
    return _mutate(
      r,
      (s) => shared.PullRemote(
        name,
        r.upstreamBranch?.split('/').skip(1).join('/') ?? r.currentBranch!,
        shared.PullStrategy.fastForwardOnly,
        expectedHead: s.head,
        expectedIndex: s.indexToken,
      ),
    );
  }

  @override
  Future<GitOperationResult> push(GitRepositoryInfo r) async =>
      pushSetUpstream(r, await _remote(r), r.currentBranch!);
  @override
  Future<GitOperationResult> pushSetUpstream(
    GitRepositoryInfo r,
    String remote,
    String branch,
  ) => _map(() async {
    final id = await _repo(r), state = await core.status(await _repo(r));
    final review = await core.inspect(
      id,
      shared.GitInspection(
        shared.GitInspectionKind.pushReview,
        remote: remote,
        destination: 'refs/heads/$branch',
      ),
    );
    return _mutate(
      r,
      (s) => shared.PushReviewed(
        review['token'] as String,
        setUpstream: r.upstreamBranch == null,
        expectedHead: state.head,
        expectedIndex: state.indexToken,
      ),
    );
  });
  @override
  Future<GitOperationResult> createBranch(GitRepositoryInfo r, String name) =>
      _mutate(
        r,
        (s) => shared.BranchMutation(
          shared.BranchAction.create,
          name,
          start: s.head,
          switchAfterCreate: true,
          expectedHead: s.head,
          expectedIndex: s.indexToken,
        ),
      );
  @override
  Future<GitOperationResult> switchBranch(GitRepositoryInfo r, String name) =>
      _mutate(
        r,
        (s) => shared.BranchMutation(
          shared.BranchAction.switchBranch,
          name,
          expectedHead: s.head,
          expectedIndex: s.indexToken,
        ),
      );
  @override
  Future<GitOperationResult> initializeRepository(String rootPath) =>
      _map(() async {
        final result = await core.create(shared.InitializeRepository(rootPath));
        if (result.error != null) throw _failure(result.error!, 'init');
        return GitOperationResult(
          success: result.phase == shared.GitOperationPhase.completed,
          message: '',
          stdout: '',
          stderr: '',
        );
      });
  @override
  Future<GitOperationResult> resetCurrentBranch(
    GitRepositoryInfo r,
    String hash,
    GitResetMode mode,
  ) async {
    if (r.currentBranch == null) {
      throw const GitFailure(
        code: GitFailureCode.detachedHead,
        userMessageKey: 'gitErrorDetachedHead',
        rawMessage: '',
        commandName: 'reset',
      );
    }
    return _mutate(
      r,
      (s) => shared.ResetBranch(
        shared.GitOid(hash),
        shared.ResetMode.values.byName(mode.name),
        expectedHead: s.head,
        expectedIndex: s.indexToken,
        expectedWorkingToken: s.token,
      ),
    );
  }

  @override
  Future<GitOperationResult> restoreFileFromCommit(
    GitRepositoryInfo r,
    String hash, {
    required String historicalPath,
    required String currentPath,
  }) => _map(() async {
    await _guard(r, currentPath);
    final target = shared.RepoPath.text(currentPath),
        before = await core.content(
          await _repo(r),
          shared.RepoPath.text(currentPath),
          const shared.ContentVersion.working(),
        );
    return _mutate(
      r,
      (s) => shared.RestoreFileRevision(
        shared.RepoPath.text(historicalPath),
        target,
        shared.GitOid(hash),
        expectedWorking: before.token,
        expectedHead: s.head,
        expectedIndex: s.indexToken,
      ),
    );
  });
}

GitFailure _failure(shared.GitException error, String command) {
  final code = switch (error.code) {
    shared.GitErrorCode.unavailable => GitFailureCode.unavailable,
    shared.GitErrorCode.unsupportedVersion => GitFailureCode.unsupportedVersion,
    shared.GitErrorCode.unsafePath ||
    shared.GitErrorCode.staleReview ||
    shared.GitErrorCode.invalidRequest => GitFailureCode.invalidPath,
    shared.GitErrorCode.authorIdentity => GitFailureCode.authorIdentity,
    shared.GitErrorCode.authentication => GitFailureCode.authentication,
    shared.GitErrorCode.transport => GitFailureCode.network,
    shared.GitErrorCode.conflict => GitFailureCode.conflict,
    shared.GitErrorCode.dirty => GitFailureCode.dirtyWorkspace,
    _ => GitFailureCode.commandFailed,
  };
  return GitFailure(
    code: code,
    userMessageKey: switch (code) {
      GitFailureCode.invalidPath => 'gitErrorUnsafePath',
      GitFailureCode.authorIdentity => 'gitErrorAuthorIdentity',
      _ => 'gitErrorCommandFailed',
    },
    rawMessage: error.diagnostic,
    commandName: command,
    exitCode: error.exitCode,
  );
}
