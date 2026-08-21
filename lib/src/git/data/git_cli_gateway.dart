import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/anchored_path_guard.dart';
import '../application/git_gateway.dart';
import '../domain/git_diff_parser.dart';
import '../domain/git_log_parser.dart';
import '../domain/git_models.dart';
import '../domain/git_status_parser.dart';
import 'git_executable_locator.dart';
import 'git_process_runner.dart';

const _logFormat = '%x1e%H%x1f%h%x1f%an%x1f%ae%x1f%ad%x1f%s%x1f%P';
const _fileHistoryLogFormat = '$_logFormat%x00';
const _maxUntrackedDiffBytes = 16 * 1024 * 1024;

class GitCliGateway implements GitRepositoryGateway {
  const GitCliGateway({
    this.runner = const DartGitCommandRunner(),
    this.locator = const GitExecutableLocator(),
    this.statusParser = const GitStatusParser(),
    this.logParser = const GitLogParser(),
    this.diffParser = const GitDiffParser(),
  });

  final GitCommandRunner runner;
  final GitExecutableLocator locator;
  final GitStatusParser statusParser;
  final GitLogParser logParser;
  final GitDiffParser diffParser;

  @override
  bool get requiresWorkspaceTrust => true;

  @override
  Future<GitAvailability> availability() => locator.locate();

  @override
  Future<GitRepositoryInfo?> detectRepository(String workspacePath) async {
    final availability = await locator.locate();
    if (!availability.available || availability.executablePath == null) {
      return null;
    }
    final path = _directoryPathForGit(workspacePath);
    final topLevel = await _runGitMaybe(
      availability.executablePath!,
      path,
      const ['rev-parse', '--show-toplevel'],
      commandName: 'rev-parse',
    );
    if (topLevel == null || !topLevel.success) {
      return null;
    }
    final rootPath = p.normalize(topLevel.stdoutText.trimRight());
    final gitDirResult = await _runGit(
      availability.executablePath!,
      rootPath,
      const ['rev-parse', '--git-dir'],
      commandName: 'rev-parse',
    );
    final gitDir = gitDirResult.stdoutText.trimRight();
    final isBareResult = await _runGit(
      availability.executablePath!,
      rootPath,
      const ['rev-parse', '--is-bare-repository'],
      commandName: 'rev-parse',
    );
    final branch = await _branchName(availability.executablePath!, rootPath);
    final detached = branch == null
        ? await _detachedHead(availability.executablePath!, rootPath)
        : null;
    final upstream = await _upstreamBranch(
      availability.executablePath!,
      rootPath,
    );
    final aheadBehind = upstream == null
        ? (0, 0)
        : await _aheadBehind(availability.executablePath!, rootPath);
    final remotes = await _remotes(availability.executablePath!, rootPath);
    return GitRepositoryInfo(
      rootPath: rootPath,
      gitDirPath: p.isAbsolute(gitDir)
          ? p.normalize(gitDir)
          : p.join(rootPath, gitDir),
      currentBranch: branch,
      detachedHeadCommit: detached,
      upstreamBranch: upstream,
      aheadCount: aheadBehind.$1,
      behindCount: aheadBehind.$2,
      hasRemote: remotes.isNotEmpty,
      isBare: isBareResult.stdoutText.trim() == 'true',
      isRebasing: await _revExists(
        availability.executablePath!,
        rootPath,
        'REBASE_HEAD',
      ),
      isMerging: await _revExists(
        availability.executablePath!,
        rootPath,
        'MERGE_HEAD',
      ),
      isCherryPicking: await _revExists(
        availability.executablePath!,
        rootPath,
        'CHERRY_PICK_HEAD',
      ),
    );
  }

  @override
  Future<GitStatusSnapshot> status(GitRepositoryInfo repository) async {
    final executable = await _executable();
    final result = await _runGit(executable, repository.rootPath, const [
      'status',
      '--porcelain=v1',
      '-z',
      '--branch',
      '--untracked-files=all',
    ], commandName: 'status');
    final remotes = await _remotes(executable, repository.rootPath);
    final parsed = statusParser.parsePorcelainV1Z(
      output: result.stdoutText,
      repositoryInfo: repository.copyWith(hasRemote: remotes.isNotEmpty),
    );
    return parsed;
  }

  @override
  Future<GitDiff> diffFile(
    GitRepositoryInfo repository,
    String repoRelativePath, {
    required bool staged,
    String? originalRepoRelativePath,
  }) async {
    _validateRepoPath(repository, repoRelativePath);
    if (originalRepoRelativePath != null) {
      _validateRepoPath(repository, originalRepoRelativePath);
    }
    final paths = <String>[
      if (originalRepoRelativePath != null &&
          originalRepoRelativePath != repoRelativePath)
        originalRepoRelativePath,
      repoRelativePath,
    ];
    final args = [
      'diff',
      if (staged) '--cached',
      '--no-ext-diff',
      '--no-textconv',
      '--no-color',
      '--find-renames',
      '--find-copies',
      '--',
      ...paths,
    ];
    final executable = await _executable();
    final result = await _runGit(
      executable,
      repository.rootPath,
      args,
      commandName: 'diff',
    );
    final diff = diffParser.parse(
      result.stdoutText,
      title: staged ? '$repoRelativePath staged' : '$repoRelativePath unstaged',
    );
    final parsedFile = diff.files
        .where((file) => paths.any(file.matchesPath))
        .firstOrNull;
    if (parsedFile == null || parsedFile.binary) {
      return diff;
    }
    final snapshotPath = parsedFile.newPath ?? parsedFile.oldPath;
    if (snapshotPath == null) {
      return diff;
    }
    String? snapshot;
    if (parsedFile.status == GitDiffFileStatus.deleted) {
      snapshot = await _textAtRevision(
        executable,
        repository.rootPath,
        staged ? 'HEAD' : '',
        snapshotPath,
      );
    } else if (staged) {
      snapshot = await _textAtRevision(
        executable,
        repository.rootPath,
        '',
        snapshotPath,
      );
    } else {
      final resolution = await _resolveWorkingTreePath(
        repository,
        snapshotPath,
        commandName: 'diff',
      );
      if (resolution.type == FileSystemEntityType.file) {
        snapshot = _decodeTextBlob(await File(resolution.path).readAsBytes());
      }
    }
    return GitDiff(
      title: diff.title,
      files: diff.files,
      rawPatch: diff.rawPatch,
      hasBinaryFiles: diff.hasBinaryFiles,
      fileSnapshots: {if (snapshot != null) snapshotPath: snapshot},
    );
  }

  @override
  Future<GitDiff> diffUntrackedFile(
    GitRepositoryInfo repository,
    String repoRelativePath,
  ) async {
    _validateRepoPath(repository, repoRelativePath);
    final resolution = await _resolveWorkingTreePath(
      repository,
      repoRelativePath,
      commandName: 'diff',
    );
    final type = resolution.type;
    if (type == FileSystemEntityType.notFound) {
      return GitDiff(
        title: '$repoRelativePath untracked',
        files: const [],
        rawPatch: '',
        hasBinaryFiles: false,
      );
    }
    if (type != FileSystemEntityType.file) {
      throw GitFailure(
        code: GitFailureCode.invalidPath,
        userMessageKey: 'gitErrorUnsafePath',
        rawMessage: repoRelativePath,
        commandName: 'diff',
      );
    }
    final file = File(resolution.path);
    final size = await file.length();
    if (size > _maxUntrackedDiffBytes) {
      return _binaryUntrackedDiff(repoRelativePath, size);
    }
    final bytes = await file.readAsBytes();
    String content;
    try {
      content = utf8.decode(bytes);
    } on FormatException {
      return _binaryUntrackedDiff(repoRelativePath, size);
    }
    if (bytes.contains(0)) {
      return _binaryUntrackedDiff(repoRelativePath, size);
    }
    final lines = const LineSplitter().convert(content);
    final hunk = lines.isEmpty
        ? null
        : GitDiffHunk(
            oldStart: 0,
            oldCount: 0,
            newStart: 1,
            newCount: lines.length,
            heading: '',
            lines: [
              for (var index = 0; index < lines.length; index++)
                GitDiffLine(
                  kind: GitDiffLineKind.added,
                  content: lines[index],
                  newLineNumber: index + 1,
                ),
            ],
          );
    final diffFile = GitDiffFile(
      newPath: repoRelativePath,
      status: GitDiffFileStatus.added,
      hunks: hunk == null ? const [] : [hunk],
      binary: false,
      additions: lines.length,
      deletions: 0,
    );
    return GitDiff(
      title: '$repoRelativePath untracked',
      files: [diffFile],
      rawPatch: _untrackedPatch(repoRelativePath, lines, content),
      hasBinaryFiles: false,
      fileSnapshots: {repoRelativePath: content},
    );
  }

  @override
  Future<GitDiff> diffAll(
    GitRepositoryInfo repository, {
    required bool staged,
  }) async {
    final args = [
      'diff',
      if (staged) '--cached',
      '--no-ext-diff',
      '--no-textconv',
      '--no-color',
      '--find-renames',
      '--find-copies',
    ];
    final result = await _runGit(
      await _executable(),
      repository.rootPath,
      args,
      commandName: 'diff',
    );
    return diffParser.parse(
      result.stdoutText,
      title: staged ? 'Staged changes' : 'Unstaged changes',
    );
  }

  @override
  Future<List<GitCommitSummary>> history(
    GitRepositoryInfo repository, {
    String? repoRelativePath,
    int limit = 200,
    int skip = 0,
  }) async {
    if (repoRelativePath != null) {
      _validateRepoPath(repository, repoRelativePath);
    }
    final args = [
      'log',
      '--date=iso-strict',
      '--max-count=$limit',
      '--skip=$skip',
      '--format=$_logFormat',
      if (repoRelativePath != null) ...['--', repoRelativePath],
    ];
    final result = await _runGitMaybe(
      await _executable(),
      repository.rootPath,
      args,
      commandName: 'log',
    );
    if (result == null || !result.success) {
      return const [];
    }
    return logParser.parse(result.stdoutText);
  }

  @override
  Future<List<GitFileHistoryEntry>> fileHistory(
    GitRepositoryInfo repository,
    String repoRelativePath, {
    int limit = 200,
    int skip = 0,
  }) async {
    _validateRepoPath(repository, repoRelativePath);
    final result =
        await _runGitMaybe(await _executable(), repository.rootPath, [
          'log',
          '--follow',
          '--date=iso-strict',
          '--max-count=${limit + skip}',
          '--format=$_fileHistoryLogFormat',
          '--name-status',
          '-z',
          '--',
          repoRelativePath,
        ], commandName: 'log');
    if (result == null || !result.success) {
      return const [];
    }
    return _parseFileHistory(result.stdoutText).skip(skip).take(limit).toList();
  }

  @override
  Future<GitCommitDetails> commitDetails(
    GitRepositoryInfo repository,
    String hash, {
    String? repoRelativePath,
  }) async {
    _validateCommitHash(hash);
    if (repoRelativePath != null) {
      _validateRepoPath(repository, repoRelativePath);
    }
    final executable = await _executable();
    final headerResult = await _runGit(executable, repository.rootPath, [
      'show',
      '--no-patch',
      '--format=$_logFormat',
      hash,
    ], commandName: 'show');
    final summary = logParser.parseFirst(headerResult.stdoutText);
    if (summary == null) {
      throw GitFailure(
        code: GitFailureCode.commandFailed,
        userMessageKey: 'gitErrorCommandFailed',
        rawMessage: headerResult.stderrText,
        commandName: 'show',
        exitCode: headerResult.exitCode,
      );
    }
    final parent = await _firstParent(executable, repository.rootPath, hash);
    final paths = repoRelativePath == null
        ? const <String>[]
        : <String>[repoRelativePath];
    final patchResult = await _runGit(
      executable,
      repository.rootPath,
      parent == null
          ? [
              'show',
              '--no-ext-diff',
              '--no-textconv',
              '--no-color',
              '--find-renames',
              '--find-copies',
              '--format=',
              '--patch',
              hash,
              if (paths.isNotEmpty) ...['--', ...paths],
            ]
          : [
              'diff',
              '--no-ext-diff',
              '--no-textconv',
              '--no-color',
              '--find-renames',
              '--find-copies',
              parent,
              hash,
              if (paths.isNotEmpty) ...['--', ...paths],
            ],
      commandName: parent == null ? 'show' : 'diff',
    );
    final patch = patchResult.stdoutText;
    final diff = diffParser.parse(patch, title: summary.subject);
    final snapshots = <String, String>{};
    for (final file in diff.files) {
      if (file.binary) {
        continue;
      }
      final path = file.displayPath;
      if (path.isEmpty) {
        continue;
      }
      final revision = file.status == GitDiffFileStatus.deleted ? parent : hash;
      if (revision == null) {
        continue;
      }
      final content = await _fileContentAtRevision(
        executable,
        repository.rootPath,
        revision,
        path,
      );
      if (content != null) {
        snapshots[path] = content;
      }
    }
    return GitCommitDetails(
      summary: summary,
      changedFiles: diff.files,
      patch: patch,
      fileSnapshots: snapshots,
    );
  }

  @override
  Future<String?> readFileAtCommit(
    GitRepositoryInfo repository,
    String hash,
    String repoRelativePath,
  ) async {
    _validateCommitHash(hash);
    _validateRepoPath(repository, repoRelativePath);
    final bytes = await _fileBytesAtRevision(
      await _executable(),
      repository.rootPath,
      hash,
      repoRelativePath,
    );
    return bytes == null ? null : _decodeTextBlob(bytes);
  }

  @override
  Future<GitHistoricalFileComparison> compareFileWithParent(
    GitRepositoryInfo repository,
    String hash, {
    String? oldPath,
    String? newPath,
  }) async {
    _validateCommitHash(hash);
    if (oldPath == null && newPath == null) {
      throw GitFailure(
        code: GitFailureCode.invalidPath,
        userMessageKey: 'gitErrorUnsafePath',
        rawMessage: '',
        commandName: 'show',
      );
    }
    if (oldPath != null) {
      _validateRepoPath(repository, oldPath);
    }
    if (newPath != null) {
      _validateRepoPath(repository, newPath);
    }
    final executable = await _executable();
    final paths = <String>{
      if (oldPath != null) oldPath,
      if (newPath != null) newPath,
    };
    final parent = await _firstParent(executable, repository.rootPath, hash);
    final result = await _runGit(
      executable,
      repository.rootPath,
      parent == null
          ? [
              'show',
              '--no-ext-diff',
              '--no-textconv',
              '--no-color',
              '--find-renames',
              '--find-copies',
              '--format=',
              '--patch',
              hash,
              '--',
              ...paths,
            ]
          : [
              'diff',
              '--no-ext-diff',
              '--no-textconv',
              '--no-color',
              '--find-renames',
              '--find-copies',
              parent,
              hash,
              '--',
              ...paths,
            ],
      commandName: parent == null ? 'show' : 'diff',
    );
    final parsed = diffParser.parse(
      result.stdoutText,
      title: newPath ?? oldPath!,
    );
    final matchingFiles = parsed.files
        .where(
          (file) =>
              (oldPath != null && file.matchesPath(oldPath)) ||
              (newPath != null && file.matchesPath(newPath)),
        )
        .toList();
    final files = matchingFiles.isEmpty ? parsed.files : matchingFiles;
    final parsedFile = files.firstOrNull;
    final resolvedOldPath = parsedFile?.status == GitDiffFileStatus.added
        ? null
        : parsedFile?.oldPath ?? oldPath;
    final resolvedNewPath = parsedFile?.status == GitDiffFileStatus.deleted
        ? null
        : parsedFile?.newPath ?? newPath;
    final oldContent = resolvedOldPath == null || parent == null
        ? ''
        : await _textAtRevision(
            executable,
            repository.rootPath,
            parent,
            resolvedOldPath,
          );
    final newContent = resolvedNewPath == null
        ? ''
        : await _textAtRevision(
            executable,
            repository.rootPath,
            hash,
            resolvedNewPath,
          );
    final displayPath = resolvedNewPath ?? resolvedOldPath ?? '';
    final diff = GitDiff(
      title: displayPath,
      files: files,
      rawPatch: result.stdoutText,
      hasBinaryFiles: files.any((file) => file.binary),
      fileSnapshots: {
        if (displayPath.isNotEmpty)
          if (resolvedNewPath == null && oldContent != null)
            displayPath: oldContent
          else if (newContent != null)
            displayPath: newContent,
      },
    );
    return GitHistoricalFileComparison(
      oldPath: resolvedOldPath,
      newPath: resolvedNewPath,
      oldContent: oldContent,
      newContent: newContent,
      diff: diff,
    );
  }

  @override
  Future<GitHistoricalFileComparison> compareFileWithWorkingTree(
    GitRepositoryInfo repository,
    String hash, {
    required String historicalPath,
    required String currentPath,
  }) async {
    _validateCommitHash(hash);
    _validateRepoPath(repository, historicalPath);
    _validateRepoPath(repository, currentPath);
    final executable = await _executable();
    final oldContent = await _textAtRevision(
      executable,
      repository.rootPath,
      hash,
      historicalPath,
    );
    final currentResolution = await _resolveWorkingTreePath(
      repository,
      currentPath,
      commandName: 'diff',
    );
    final currentType = currentResolution.type;
    if (currentType != FileSystemEntityType.file &&
        currentType != FileSystemEntityType.notFound) {
      throw GitFailure(
        code: GitFailureCode.invalidPath,
        userMessageKey: 'gitErrorUnsafePath',
        rawMessage: currentPath,
        commandName: 'diff',
      );
    }
    final result = currentType == FileSystemEntityType.file
        ? await _runGit(executable, repository.rootPath, [
            'diff',
            '--no-ext-diff',
            '--no-textconv',
            '--no-color',
            '--find-renames',
            '$hash:$historicalPath',
            '--',
            currentPath,
          ], commandName: 'diff')
        : null;
    final currentBytes = currentType == FileSystemEntityType.file
        ? await File(currentResolution.path).readAsBytes()
        : null;
    final newContent = currentBytes == null
        ? ''
        : _decodeTextBlob(currentBytes);
    final diff = result == null
        ? _deletedWorkingTreeDiff(
            historicalPath: historicalPath,
            currentPath: currentPath,
            oldContent: oldContent,
          )
        : _withSnapshot(
            diffParser.parse(result.stdoutText, title: currentPath),
            currentPath,
            newContent,
          );
    return GitHistoricalFileComparison(
      oldPath: historicalPath,
      newPath: currentType == FileSystemEntityType.notFound
          ? null
          : currentPath,
      oldContent: oldContent,
      newContent: newContent,
      diff: diff,
    );
  }

  @override
  Future<List<GitBranch>> branches(GitRepositoryInfo repository) async {
    final result = await _runGit(await _executable(), repository.rootPath, const [
      'branch',
      '--format=%(HEAD)%1f%(refname:short)%1f%(upstream:short)%1f%(objectname)%1f%(subject)',
    ], commandName: 'branch');
    return [
      for (final line in result.stdoutText.split('\n'))
        if (line.trim().isNotEmpty) _parseBranch(line),
    ];
  }

  @override
  Future<List<String>> remotes(GitRepositoryInfo repository) {
    return _remotesForRepository(repository);
  }

  @override
  Future<GitOperationResult> stage(
    GitRepositoryInfo repository,
    List<String> repoRelativePaths,
  ) {
    _validateRepoPaths(repository, repoRelativePaths);
    return _operation(repository, ['add', '--', ...repoRelativePaths], 'add');
  }

  @override
  Future<GitOperationResult> unstage(
    GitRepositoryInfo repository,
    List<String> repoRelativePaths,
  ) {
    _validateRepoPaths(repository, repoRelativePaths);
    return _operation(repository, [
      'restore',
      '--staged',
      '--',
      ...repoRelativePaths,
    ], 'restore');
  }

  @override
  Future<GitOperationResult> rollbackTracked(
    GitRepositoryInfo repository,
    List<String> repoRelativePaths,
  ) {
    _validateRepoPaths(repository, repoRelativePaths);
    return _operation(repository, [
      'restore',
      '--source=HEAD',
      '--staged',
      '--worktree',
      '--',
      ...repoRelativePaths,
    ], 'restore');
  }

  @override
  Future<GitOperationResult> discardUntracked(
    GitRepositoryInfo repository,
    List<String> repoRelativePaths,
    GitStatusSnapshot snapshot,
  ) async {
    _validateRepoPaths(repository, repoRelativePaths);
    for (final relativePath in repoRelativePaths) {
      final trackedStatus = snapshot.files
          .where((file) => file.repoRelativePath == relativePath)
          .firstOrNull;
      if (trackedStatus == null || !trackedStatus.untracked) {
        throw GitFailure(
          code: GitFailureCode.invalidPath,
          userMessageKey: 'gitErrorUnsafePath',
          rawMessage: relativePath,
          commandName: 'delete',
        );
      }
      final resolution = await _resolveWorkingTreePath(
        repository,
        relativePath,
        commandName: 'delete',
        allowFinalSymlink: true,
      );
      final type = resolution.type;
      if (type == FileSystemEntityType.directory) {
        throw GitFailure(
          code: GitFailureCode.invalidPath,
          userMessageKey: 'gitErrorUntrackedDirectory',
          rawMessage: relativePath,
          commandName: 'delete',
        );
      }
      if (type == FileSystemEntityType.link) {
        await Link(resolution.path).delete();
      } else if (type == FileSystemEntityType.file) {
        await File(resolution.path).delete();
      }
    }
    return const GitOperationResult(
      success: true,
      message: '',
      stdout: '',
      stderr: '',
    );
  }

  @override
  Future<GitOperationResult> commit(
    GitRepositoryInfo repository,
    String message,
  ) async {
    final tempDir = await Directory.systemTemp.createTemp('busymark-git-');
    final file = File(p.join(tempDir.path, 'commit-message.txt'));
    try {
      await file.writeAsString(message);
      return await _operation(repository, [
        'commit',
        '--file',
        file.path,
      ], 'commit');
    } finally {
      try {
        await tempDir.delete(recursive: true);
      } on Object {
        // Best-effort cleanup; preserve the Git result or failure.
      }
    }
  }

  @override
  Future<GitOperationResult> restoreFileFromCommit(
    GitRepositoryInfo repository,
    String hash, {
    required String historicalPath,
    required String currentPath,
  }) async {
    _validateCommitHash(hash);
    _validateRepoPath(repository, historicalPath);
    _validateRepoPath(repository, currentPath);
    final executable = await _executable();
    await _ensureCommitExists(
      executable,
      repository.rootPath,
      hash,
      commandName: 'restore',
    );
    final initialDestination = await _resolveWorkingTreePath(
      repository,
      currentPath,
      commandName: 'restore',
    );
    _requireFileOrMissing(
      initialDestination,
      relativePath: currentPath,
      commandName: 'restore',
    );
    final bytes = await _fileBytesAtRevision(
      executable,
      repository.rootPath,
      hash,
      historicalPath,
    );
    if (bytes == null) {
      if (initialDestination.type == FileSystemEntityType.file) {
        await File(initialDestination.path).delete();
      }
      return const GitOperationResult(
        success: true,
        message: '',
        stdout: '',
        stderr: '',
      );
    }
    if (historicalPath == currentPath) {
      return _operation(repository, [
        'restore',
        '--source=$hash',
        '--worktree',
        '--',
        currentPath,
      ], 'restore');
    }
    final destination = File(initialDestination.path);
    final stagingDirectory = await destination.parent.createTemp(
      '.busymark-restore-',
    );
    final temporary = File(p.join(stagingDirectory.path, 'contents'));
    try {
      await temporary.writeAsBytes(bytes, flush: true);
      final checkedDestination = await _resolveWorkingTreePath(
        repository,
        currentPath,
        commandName: 'restore',
      );
      _requireFileOrMissing(
        checkedDestination,
        relativePath: currentPath,
        commandName: 'restore',
      );
      await temporary.rename(checkedDestination.path);
    } finally {
      try {
        if (await stagingDirectory.exists()) {
          await stagingDirectory.delete(recursive: true);
        }
      } on Object {
        // Best-effort cleanup; preserve the restore result or failure.
      }
    }
    return const GitOperationResult(
      success: true,
      message: '',
      stdout: '',
      stderr: '',
    );
  }

  @override
  Future<GitOperationResult> resetCurrentBranch(
    GitRepositoryInfo repository,
    String hash,
    GitResetMode mode,
  ) async {
    _validateCommitHash(hash);
    final executable = await _executable();
    await _ensureCommitExists(
      executable,
      repository.rootPath,
      hash,
      commandName: 'reset',
    );
    final branch = await _runGitMaybe(executable, repository.rootPath, const [
      'symbolic-ref',
      '--quiet',
      '--short',
      'HEAD',
    ], commandName: 'reset');
    if (branch == null || !branch.success || branch.stdoutText.trim().isEmpty) {
      throw const GitFailure(
        code: GitFailureCode.detachedHead,
        userMessageKey: 'gitErrorResetDetachedHead',
        rawMessage: '',
        commandName: 'reset',
      );
    }
    return _operation(repository, ['reset', '--${mode.name}', hash], 'reset');
  }

  @override
  Future<GitOperationResult> fetch(GitRepositoryInfo repository) {
    return _operation(repository, const ['fetch'], 'fetch');
  }

  @override
  Future<GitOperationResult> pullFastForwardOnly(GitRepositoryInfo repository) {
    return _operation(repository, const ['pull', '--ff-only'], 'pull');
  }

  @override
  Future<GitOperationResult> push(GitRepositoryInfo repository) {
    return _operation(repository, const ['push', '--porcelain'], 'push');
  }

  @override
  Future<GitOperationResult> pushSetUpstream(
    GitRepositoryInfo repository,
    String remote,
    String branch,
  ) {
    return _operation(repository, [
      'push',
      '--porcelain',
      '--set-upstream',
      '--',
      remote,
      branch,
    ], 'push');
  }

  @override
  Future<GitOperationResult> createBranch(
    GitRepositoryInfo repository,
    String branchName,
  ) async {
    await _runGit(await _executable(), repository.rootPath, [
      'check-ref-format',
      '--branch',
      branchName,
    ], commandName: 'check-ref-format');
    return _operation(repository, ['switch', '-c', branchName], 'switch');
  }

  @override
  Future<GitOperationResult> switchBranch(
    GitRepositoryInfo repository,
    String branchName,
  ) {
    return _operation(repository, ['switch', '--', branchName], 'switch');
  }

  @override
  Future<GitOperationResult> initializeRepository(String rootPath) async {
    final executable = await _executable();
    final result = await _runGit(
      executable,
      rootPath,
      const ['init'],
      commandName: 'init',
      passive: false,
    );
    return GitOperationResult(
      success: true,
      message: _operationMessage(result, ''),
      stdout: result.stdoutText,
      stderr: result.stderrText,
    );
  }

  GitDiff _binaryUntrackedDiff(String repoRelativePath, int size) {
    final file = GitDiffFile(
      newPath: repoRelativePath,
      status: GitDiffFileStatus.binary,
      hunks: const [],
      binary: true,
      additions: 0,
      deletions: 0,
      binarySize: size,
    );
    return GitDiff(
      title: '$repoRelativePath untracked',
      files: [file],
      rawPatch: 'Binary file $repoRelativePath ($size bytes)\n',
      hasBinaryFiles: true,
    );
  }

  String _untrackedPatch(
    String repoRelativePath,
    List<String> lines,
    String content,
  ) {
    final aPath = _quotePatchPath('a/$repoRelativePath');
    final bPath = _quotePatchPath('b/$repoRelativePath');
    final buffer = StringBuffer()
      ..writeln('diff --git $aPath $bPath')
      ..writeln('new file mode 100644')
      ..writeln('--- /dev/null')
      ..writeln('+++ $bPath');
    if (lines.isNotEmpty) {
      buffer.writeln('@@ -0,0 +1,${lines.length} @@');
      for (final line in lines) {
        buffer.writeln('+$line');
      }
      if (!content.endsWith('\n')) {
        buffer.writeln(r'\ No newline at end of file');
      }
    }
    return buffer.toString();
  }

  String _quotePatchPath(String path) {
    if (!RegExp(r'[\s"\\\x00-\x1f\x7f]').hasMatch(path)) {
      return path;
    }
    return jsonEncode(path);
  }

  Future<String> _executable() async {
    final availability = await locator.locate();
    if (!availability.available || availability.executablePath == null) {
      throw GitFailure(
        code: GitFailureCode.unavailable,
        userMessageKey: 'gitErrorUnavailable',
        rawMessage:
            availability.unavailableReason ?? 'Git executable was not found.',
        commandName: 'git',
      );
    }
    return availability.executablePath!;
  }

  Future<GitProcessResult> _runGit(
    String executable,
    String repoRoot,
    List<String> args, {
    required String commandName,
    bool passive = true,
  }) async {
    final result = await _runGitMaybe(
      executable,
      repoRoot,
      args,
      commandName: commandName,
      passive: passive,
    );
    if (result == null || result.success) {
      return result!;
    }
    throw _failureForResult(result, commandName);
  }

  Future<GitProcessResult?> _runGitMaybe(
    String executable,
    String repoRoot,
    List<String> args, {
    required String commandName,
    bool passive = true,
  }) async {
    try {
      return await runner.run(
        executable,
        [
          '--no-pager',
          '--no-optional-locks',
          '-c',
          'core.fsmonitor=false',
          '-C',
          repoRoot,
          ...args,
        ],
        timeout: gitCommandTimeout,
        commandName: commandName,
        environment: passive ? const {'GIT_NO_LAZY_FETCH': '1'} : const {},
      );
    } on ProcessException catch (error) {
      throw GitFailure(
        code: GitFailureCode.unavailable,
        userMessageKey: 'gitErrorUnavailable',
        rawMessage: '$error',
        commandName: commandName,
      );
    }
  }

  Future<GitOperationResult> _operation(
    GitRepositoryInfo repository,
    List<String> args,
    String commandName,
  ) async {
    final result = await _runGit(
      await _executable(),
      repository.rootPath,
      args,
      commandName: commandName,
      passive: false,
    );
    return GitOperationResult(
      success: true,
      message: _operationMessage(result, ''),
      stdout: result.stdoutText,
      stderr: result.stderrText,
    );
  }

  Future<String?> _fileContentAtRevision(
    String executable,
    String repoRoot,
    String revision,
    String repoRelativePath,
  ) async {
    return _textAtRevision(executable, repoRoot, revision, repoRelativePath);
  }

  Future<List<int>?> _fileBytesAtRevision(
    String executable,
    String repoRoot,
    String revision,
    String repoRelativePath,
  ) async {
    final objectId = await _blobObjectIdAtRevision(
      executable,
      repoRoot,
      revision,
      repoRelativePath,
    );
    if (objectId == null) {
      return null;
    }
    final result = await _runGit(executable, repoRoot, [
      'cat-file',
      'blob',
      objectId,
    ], commandName: 'show');
    return result.stdoutBytes;
  }

  Future<String?> _blobObjectIdAtRevision(
    String executable,
    String repoRoot,
    String revision,
    String repoRelativePath,
  ) async {
    final literalPath = ':(literal)$repoRelativePath';
    final result = revision.isEmpty
        ? await _runGit(executable, repoRoot, [
            'ls-files',
            '--stage',
            '-z',
            '--',
            literalPath,
          ], commandName: 'show')
        : await _runGit(executable, repoRoot, [
            'ls-tree',
            '--full-tree',
            '-z',
            revision,
            '--',
            literalPath,
          ], commandName: 'show');
    if (result.stdoutBytes.isEmpty) {
      return null;
    }
    for (final record in result.stdoutText.split('\x00')) {
      final tab = record.indexOf('\t');
      if (tab < 0) {
        continue;
      }
      final fields = record.substring(0, tab).split(' ');
      if (revision.isEmpty) {
        if (fields.length >= 3 && fields[2] == '0') {
          return fields[1];
        }
      } else if (fields.length >= 3 && fields[1] == 'blob') {
        return fields[2];
      }
    }
    throw GitFailure(
      code: GitFailureCode.commandFailed,
      userMessageKey: 'gitErrorCommandFailed',
      rawMessage: 'Git did not report a readable blob for $repoRelativePath.',
      commandName: 'show',
    );
  }

  Future<String?> _textAtRevision(
    String executable,
    String repoRoot,
    String revision,
    String repoRelativePath,
  ) async {
    final bytes = await _fileBytesAtRevision(
      executable,
      repoRoot,
      revision,
      repoRelativePath,
    );
    return bytes == null ? null : _decodeTextBlob(bytes);
  }

  String? _decodeTextBlob(List<int> bytes) {
    if (bytes.contains(0)) {
      return null;
    }
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return null;
    }
  }

  Future<String?> _firstParent(
    String executable,
    String repoRoot,
    String hash,
  ) async {
    final result = await _runGitMaybe(executable, repoRoot, [
      'rev-list',
      '--parents',
      '--max-count=1',
      hash,
    ], commandName: 'rev-list');
    if (result == null || !result.success) {
      return null;
    }
    final fields = result.stdoutText.trim().split(RegExp(r'\s+'));
    return fields.length > 1 ? fields[1] : null;
  }

  Future<void> _ensureCommitExists(
    String executable,
    String repoRoot,
    String hash, {
    required String commandName,
  }) async {
    await _runGit(executable, repoRoot, [
      'cat-file',
      '-e',
      '$hash^{commit}',
    ], commandName: commandName);
  }

  GitDiff _withSnapshot(GitDiff diff, String path, String? content) {
    return GitDiff(
      title: diff.title,
      files: diff.files,
      rawPatch: diff.rawPatch,
      hasBinaryFiles: diff.hasBinaryFiles,
      fileSnapshots: {if (content != null) path: content},
    );
  }

  GitDiff _deletedWorkingTreeDiff({
    required String historicalPath,
    required String currentPath,
    required String? oldContent,
  }) {
    if (oldContent == null) {
      final file = GitDiffFile(
        oldPath: historicalPath,
        status: GitDiffFileStatus.binary,
        hunks: const [],
        binary: true,
        additions: 0,
        deletions: 0,
      );
      return GitDiff(
        title: currentPath,
        files: [file],
        rawPatch: 'Binary file $historicalPath was deleted.\n',
        hasBinaryFiles: true,
      );
    }
    final lines = const LineSplitter().convert(oldContent);
    final hunk = lines.isEmpty
        ? null
        : GitDiffHunk(
            oldStart: 1,
            oldCount: lines.length,
            newStart: 0,
            newCount: 0,
            heading: '',
            lines: [
              for (var index = 0; index < lines.length; index++)
                GitDiffLine(
                  kind: GitDiffLineKind.removed,
                  content: lines[index],
                  oldLineNumber: index + 1,
                ),
            ],
          );
    final file = GitDiffFile(
      oldPath: historicalPath,
      status: GitDiffFileStatus.deleted,
      hunks: hunk == null ? const [] : [hunk],
      binary: false,
      additions: 0,
      deletions: lines.length,
    );
    final buffer = StringBuffer()
      ..writeln(
        'diff --git ${_quotePatchPath('a/$historicalPath')} ${_quotePatchPath('b/$currentPath')}',
      )
      ..writeln('deleted file mode 100644')
      ..writeln('--- ${_quotePatchPath('a/$historicalPath')}')
      ..writeln('+++ /dev/null');
    if (lines.isNotEmpty) {
      buffer.writeln('@@ -1,${lines.length} +0,0 @@');
      for (final line in lines) {
        buffer.writeln('-$line');
      }
      if (!oldContent.endsWith('\n')) {
        buffer.writeln(r'\ No newline at end of file');
      }
    }
    return GitDiff(
      title: currentPath,
      files: [file],
      rawPatch: buffer.toString(),
      hasBinaryFiles: false,
      fileSnapshots: {historicalPath: oldContent},
    );
  }

  GitFailure _failureForResult(GitProcessResult result, String commandName) {
    final message = result.stderrText.isEmpty
        ? result.stdoutText
        : result.stderrText;
    final lower = message.toLowerCase();
    var code = GitFailureCode.commandFailed;
    var key = 'gitErrorCommandFailed';
    if (lower.contains('not a git repository')) {
      code = GitFailureCode.notRepository;
      key = 'gitErrorNotRepository';
    } else if (lower.contains('could not read from remote repository') ||
        lower.contains('permission denied') ||
        lower.contains('authentication failed') ||
        lower.contains('terminal prompts disabled')) {
      code = GitFailureCode.authentication;
      key = 'gitErrorAuthentication';
    } else if (lower.contains('unable to access') ||
        lower.contains('could not resolve host') ||
        lower.contains('failed to connect')) {
      code = GitFailureCode.network;
      key = 'gitErrorNetwork';
    } else if (lower.contains('not possible to fast-forward') ||
        lower.contains('divergent branches')) {
      code = GitFailureCode.diverged;
      key = 'gitErrorDiverged';
    } else if (lower.contains('needs merge') ||
        lower.contains('unmerged') ||
        lower.contains('conflict')) {
      code = GitFailureCode.conflict;
      key = 'gitErrorConflict';
    }
    return GitFailure(
      code: code,
      userMessageKey: key,
      rawMessage: message,
      commandName: commandName,
      exitCode: result.exitCode,
    );
  }

  String _operationMessage(GitProcessResult result, String fallback) {
    final stdout = result.stdoutText.trim();
    final stderr = result.stderrText.trim();
    if (stdout.isNotEmpty) {
      return stdout;
    }
    if (stderr.isNotEmpty) {
      return stderr;
    }
    return fallback;
  }

  String _directoryPathForGit(String path) {
    final type = FileSystemEntity.typeSync(path);
    if (type == FileSystemEntityType.file) {
      return p.dirname(path);
    }
    return path;
  }

  Future<String?> _branchName(String executable, String rootPath) async {
    final result = await _runGitMaybe(executable, rootPath, const [
      'branch',
      '--show-current',
    ], commandName: 'branch');
    final value = result?.stdoutText.trim() ?? '';
    return value.isEmpty ? null : value;
  }

  Future<String?> _detachedHead(String executable, String rootPath) async {
    final result = await _runGitMaybe(executable, rootPath, const [
      'rev-parse',
      '--short',
      'HEAD',
    ], commandName: 'rev-parse');
    if (result == null || !result.success) {
      return null;
    }
    final value = result.stdoutText.trim();
    return value.isEmpty ? null : value;
  }

  Future<String?> _upstreamBranch(String executable, String rootPath) async {
    final result = await _runGitMaybe(executable, rootPath, const [
      'rev-parse',
      '--abbrev-ref',
      '--symbolic-full-name',
      '@{u}',
    ], commandName: 'rev-parse');
    if (result == null || !result.success) {
      return null;
    }
    final value = result.stdoutText.trim();
    return value.isEmpty ? null : value;
  }

  Future<(int, int)> _aheadBehind(String executable, String rootPath) async {
    final result = await _runGitMaybe(executable, rootPath, const [
      'rev-list',
      '--left-right',
      '--count',
      'HEAD...@{u}',
    ], commandName: 'rev-list');
    if (result == null || !result.success) {
      return (0, 0);
    }
    final parts = result.stdoutText.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) {
      return (0, 0);
    }
    return (int.tryParse(parts[0]) ?? 0, int.tryParse(parts[1]) ?? 0);
  }

  Future<bool> _revExists(
    String executable,
    String rootPath,
    String name,
  ) async {
    final result = await _runGitMaybe(executable, rootPath, [
      'rev-parse',
      '-q',
      '--verify',
      name,
    ], commandName: 'rev-parse');
    return result?.success ?? false;
  }

  Future<List<String>> _remotesForRepository(
    GitRepositoryInfo repository,
  ) async {
    return _remotes(await _executable(), repository.rootPath);
  }

  Future<List<String>> _remotes(String executable, String rootPath) async {
    final result = await _runGitMaybe(executable, rootPath, const [
      'remote',
      '-v',
    ], commandName: 'remote');
    if (result == null || !result.success) {
      return const [];
    }
    final remotes = <String>{};
    for (final line in result.stdoutText.split('\n')) {
      if (line.trim().isEmpty) {
        continue;
      }
      final match = RegExp(r'^([^\s]+)\s+').firstMatch(line);
      if (match != null) {
        remotes.add(match.group(1)!);
      }
    }
    return remotes.toList()..sort();
  }

  GitBranch _parseBranch(String line) {
    final parts = line.split('\x1f');
    return GitBranch(
      current: parts.isNotEmpty && parts[0] == '*',
      name: parts.length > 1 ? parts[1] : '',
      upstream: parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null,
      objectName: parts.length > 3 && parts[3].isNotEmpty ? parts[3] : null,
      subject: parts.length > 4 && parts[4].isNotEmpty ? parts[4] : null,
    );
  }

  List<GitFileHistoryEntry> _parseFileHistory(String output) {
    final entries = <GitFileHistoryEntry>[];
    for (final record in output.split('\x1e')) {
      if (record.trim().isEmpty) {
        continue;
      }
      final headerEnd = record.indexOf('\x00');
      if (headerEnd < 0) {
        continue;
      }
      final commit = logParser.parseFirst(
        '\x1e${record.substring(0, headerEnd)}',
      );
      if (commit == null) {
        continue;
      }
      final tokens = record
          .substring(headerEnd + 1)
          .split('\x00')
          .where((token) => token.isNotEmpty)
          .toList();
      if (tokens.length < 2) {
        continue;
      }
      final statusToken = tokens[0].replaceFirst(RegExp(r'^[\r\n]+'), '');
      if (statusToken.isEmpty) {
        continue;
      }
      final statusCode = statusToken[0];
      final status = switch (statusCode) {
        'A' => GitDiffFileStatus.added,
        'D' => GitDiffFileStatus.deleted,
        'R' => GitDiffFileStatus.renamed,
        'C' => GitDiffFileStatus.copied,
        'M' || 'T' => GitDiffFileStatus.modified,
        _ => GitDiffFileStatus.unknown,
      };
      final isTwoPathStatus = statusCode == 'R' || statusCode == 'C';
      if (isTwoPathStatus && tokens.length < 3) {
        continue;
      }
      final pathInParent = isTwoPathStatus ? tokens[1] : tokens[1];
      final pathAtCommit = isTwoPathStatus ? tokens[2] : tokens[1];
      entries.add(
        GitFileHistoryEntry(
          commit: commit,
          pathAtCommit: pathAtCommit,
          pathInParent: status == GitDiffFileStatus.added ? null : pathInParent,
          status: status,
        ),
      );
    }
    return entries;
  }

  void _validateRepoPaths(GitRepositoryInfo repository, List<String> paths) {
    for (final path in paths) {
      _validateRepoPath(repository, path);
    }
  }

  Future<AnchoredPathResolution> _resolveWorkingTreePath(
    GitRepositoryInfo repository,
    String relativePath, {
    required String commandName,
    bool allowFinalSymlink = false,
  }) async {
    _validateRepoPath(repository, relativePath);
    try {
      final anchor = await captureCanonicalDirectoryAnchor(repository.rootPath);
      final normalized = p.posix.normalize(relativePath.replaceAll(r'\', '/'));
      return await resolveAnchoredPath(
        anchor,
        p.join(repository.rootPath, normalized),
        allowRoot: false,
        allowFinalSymlink: allowFinalSymlink,
      );
    } on AnchoredPathViolation catch (error) {
      throw GitFailure(
        code: GitFailureCode.invalidPath,
        userMessageKey: 'gitErrorUnsafePath',
        rawMessage: '$relativePath (${error.reason.name})',
        commandName: commandName,
      );
    } on FileSystemException catch (error) {
      throw GitFailure(
        code: GitFailureCode.invalidPath,
        userMessageKey: 'gitErrorUnsafePath',
        rawMessage: '$relativePath (${error.message})',
        commandName: commandName,
      );
    }
  }

  void _requireFileOrMissing(
    AnchoredPathResolution resolution, {
    required String relativePath,
    required String commandName,
  }) {
    if (resolution.type == FileSystemEntityType.file ||
        resolution.type == FileSystemEntityType.notFound) {
      return;
    }
    throw GitFailure(
      code: GitFailureCode.invalidPath,
      userMessageKey: 'gitErrorUnsafePath',
      rawMessage: relativePath,
      commandName: commandName,
    );
  }

  void _validateCommitHash(String hash) {
    if (RegExp(r'^[0-9a-fA-F]{7,64}$').hasMatch(hash)) {
      return;
    }
    throw GitFailure(
      code: GitFailureCode.invalidPath,
      userMessageKey: 'gitErrorInvalidCommit',
      rawMessage: hash,
      commandName: 'show',
    );
  }

  void _validateRepoPath(GitRepositoryInfo repository, String relativePath) {
    if (relativePath.isEmpty ||
        relativePath.contains('\x00') ||
        p.isAbsolute(relativePath) ||
        relativePath.startsWith(':')) {
      throw GitFailure(
        code: GitFailureCode.invalidPath,
        userMessageKey: 'gitErrorUnsafePath',
        rawMessage: relativePath,
        commandName: 'path-validation',
      );
    }
    final normalized = p.posix.normalize(relativePath.replaceAll(r'\', '/'));
    if (normalized == '..' ||
        normalized.startsWith('../') ||
        normalized == '.git' ||
        normalized.startsWith('.git/')) {
      throw GitFailure(
        code: GitFailureCode.invalidPath,
        userMessageKey: 'gitErrorUnsafePath',
        rawMessage: relativePath,
        commandName: 'path-validation',
      );
    }
    final absolute = p.normalize(p.join(repository.rootPath, normalized));
    if (!_isInside(repository.rootPath, absolute)) {
      throw GitFailure(
        code: GitFailureCode.invalidPath,
        userMessageKey: 'gitErrorUnsafePath',
        rawMessage: relativePath,
        commandName: 'path-validation',
      );
    }
  }

  bool _isInside(String rootPath, String path) {
    final relative = p.relative(p.normalize(path), from: p.normalize(rootPath));
    return relative == '.' ||
        (!relative.startsWith('..') && !p.isAbsolute(relative));
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
