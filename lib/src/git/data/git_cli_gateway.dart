import 'dart:io';

import 'package:path/path.dart' as p;

import '../application/git_gateway.dart';
import '../domain/git_diff_parser.dart';
import '../domain/git_log_parser.dart';
import '../domain/git_models.dart';
import '../domain/git_status_parser.dart';
import 'git_executable_locator.dart';
import 'git_process_runner.dart';

const _logFormat = '%x1e%H%x1f%h%x1f%an%x1f%ae%x1f%ad%x1f%s%x1f%P';

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
  }) async {
    _validateRepoPath(repository, repoRelativePath);
    final args = [
      'diff',
      if (staged) '--cached',
      '--no-ext-diff',
      '--no-color',
      '--find-renames',
      '--find-copies',
      '--',
      repoRelativePath,
    ];
    final result = await _runGit(
      await _executable(),
      repository.rootPath,
      args,
      commandName: 'diff',
    );
    return diffParser.parse(
      result.stdoutText,
      title: staged ? '$repoRelativePath staged' : '$repoRelativePath unstaged',
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
  Future<GitCommitDetails> commitDetails(
    GitRepositoryInfo repository,
    String hash, {
    String? repoRelativePath,
  }) async {
    if (!RegExp(r'^[0-9a-fA-F]{7,64}$').hasMatch(hash)) {
      throw GitFailure(
        code: GitFailureCode.invalidPath,
        userMessageKey: 'gitErrorInvalidCommit',
        rawMessage: hash,
        commandName: 'show',
      );
    }
    if (repoRelativePath != null) {
      _validateRepoPath(repository, repoRelativePath);
    }
    final result = await _runGit(await _executable(), repository.rootPath, [
      'show',
      '--no-ext-diff',
      '--no-color',
      '--find-renames',
      '--find-copies',
      '--format=$_logFormat',
      '--patch',
      hash,
      if (repoRelativePath != null) ...['--', repoRelativePath],
    ], commandName: 'show');
    final output = result.stdoutText;
    final diffIndex = output.indexOf('\ndiff --git ');
    final header = diffIndex < 0 ? output : output.substring(0, diffIndex);
    final patch = diffIndex < 0 ? '' : output.substring(diffIndex + 1);
    final summary = logParser.parseFirst(header);
    if (summary == null) {
      throw GitFailure(
        code: GitFailureCode.commandFailed,
        userMessageKey: 'gitErrorCommandFailed',
        rawMessage: result.stderrText,
        commandName: 'show',
        exitCode: result.exitCode,
      );
    }
    final diff = diffParser.parse(patch, title: summary.subject);
    final snapshots = <String, String>{};
    final executable = await _executable();
    for (final file in diff.files) {
      if (file.binary) {
        continue;
      }
      final path = file.displayPath;
      if (path.isEmpty) {
        continue;
      }
      final revision = file.status == GitDiffFileStatus.deleted
          ? '$hash^'
          : hash;
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
  Future<GitOperationResult> discardTracked(
    GitRepositoryInfo repository,
    List<String> repoRelativePaths,
  ) {
    _validateRepoPaths(repository, repoRelativePaths);
    return _operation(repository, [
      'restore',
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
      final absolute = p.normalize(p.join(repository.rootPath, relativePath));
      if (!_isInside(repository.rootPath, absolute)) {
        throw GitFailure(
          code: GitFailureCode.invalidPath,
          userMessageKey: 'gitErrorUnsafePath',
          rawMessage: relativePath,
          commandName: 'delete',
        );
      }
      final type = await FileSystemEntity.type(absolute, followLinks: false);
      if (type == FileSystemEntityType.directory) {
        throw GitFailure(
          code: GitFailureCode.invalidPath,
          userMessageKey: 'gitErrorUntrackedDirectory',
          rawMessage: relativePath,
          commandName: 'delete',
        );
      }
      if (type != FileSystemEntityType.notFound) {
        await File(absolute).delete();
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
      '--set-upstream',
      remote,
      branch,
      '--porcelain',
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
    return _operation(repository, ['switch', branchName], 'switch');
  }

  @override
  Future<GitOperationResult> initializeRepository(String rootPath) async {
    final executable = await _executable();
    final result = await _runGit(executable, rootPath, const [
      'init',
    ], commandName: 'init');
    return GitOperationResult(
      success: true,
      message: _operationMessage(result, ''),
      stdout: result.stdoutText,
      stderr: result.stderrText,
    );
  }

  Future<String> _executable() async {
    final availability = await locator.locate();
    if (!availability.available || availability.executablePath == null) {
      throw GitFailure(
        code: GitFailureCode.unavailable,
        userMessageKey: 'gitErrorUnavailable',
        rawMessage:
            availability.unsupportedReason ?? 'Git executable was not found.',
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
  }) async {
    final result = await _runGitMaybe(
      executable,
      repoRoot,
      args,
      commandName: commandName,
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
  }) async {
    try {
      return await runner.run(executable, [
        '--no-pager',
        '-C',
        repoRoot,
        ...args,
      ]);
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
    final result = await _runGitMaybe(executable, repoRoot, [
      'show',
      '$revision:$repoRelativePath',
    ], commandName: 'show');
    if (result == null || !result.success) {
      return null;
    }
    return result.stdoutText;
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

  void _validateRepoPaths(GitRepositoryInfo repository, List<String> paths) {
    for (final path in paths) {
      _validateRepoPath(repository, path);
    }
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
