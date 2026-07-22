import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../app/app_settings.dart';
import '../../workspace/workspace_controller.dart';
import '../../workspace/workspace_model.dart';
import '../domain/git_models.dart';
import 'git_gateway.dart';
import 'git_use_cases.dart';

final gitRepositoryGatewayProvider = Provider<GitRepositoryGateway>(
  (ref) => const UnavailableGitRepositoryGateway(),
);

final gitControllerProvider = NotifierProvider<GitController, GitState>(
  GitController.new,
);

class GitState {
  const GitState({
    this.availability = const GitAvailability.unavailable(),
    this.repositoryInfo,
    this.statusSnapshot,
    this.selectedView = GitView.changes,
    this.selectedFilePath,
    this.selectedCommitHash,
    this.selectedCommitFilePath,
    this.openDiffFilePaths = const [],
    this.selectedDiff,
    this.history = const [],
    this.historyFilePath,
    this.branches = const [],
    this.requiresWorkspaceTrust = false,
    this.isRefreshing = false,
    this.isRunningOperation = false,
    this.lastError,
    this.lastOperationMessage,
    this.attachedWorkspace,
    this.scopedFilePath,
  });

  final GitAvailability availability;
  final GitRepositoryInfo? repositoryInfo;
  final GitStatusSnapshot? statusSnapshot;
  final GitView selectedView;
  final String? selectedFilePath;
  final String? selectedCommitHash;
  final String? selectedCommitFilePath;
  final List<String> openDiffFilePaths;
  final GitDiff? selectedDiff;
  final List<GitCommitSummary> history;
  final String? historyFilePath;
  final List<GitBranch> branches;
  final bool requiresWorkspaceTrust;
  final bool isRefreshing;
  final bool isRunningOperation;
  final GitFailure? lastError;
  final String? lastOperationMessage;
  final Workspace? attachedWorkspace;
  final String? scopedFilePath;

  bool get isRepository => repositoryInfo != null;

  GitDiff? get selectedDiffForDisplay {
    final diff = selectedDiff;
    final path = selectedCommitFilePath;
    if (diff == null) {
      return null;
    }
    if (path == null) {
      return openDiffFilePaths.isEmpty ? diff : null;
    }
    if (!openDiffFilePaths.contains(path) && openDiffFilePaths.isNotEmpty) {
      return null;
    }
    if (path.isEmpty) {
      return diff;
    }
    final selectedFiles = [
      for (final file in diff.files)
        if (file.matchesPath(path)) file,
    ];
    if (selectedFiles.isEmpty) {
      return diff;
    }
    final title = path.isEmpty ? diff.title : path;
    return GitDiff(
      title: title,
      files: selectedFiles,
      rawPatch: diff.rawPatch,
      hasBinaryFiles: selectedFiles.any((file) => file.binary),
      fileSnapshots: diff.fileSnapshots,
    );
  }

  GitState copyWith({
    GitAvailability? availability,
    Object? repositoryInfo = _unset,
    Object? statusSnapshot = _unset,
    GitView? selectedView,
    Object? selectedFilePath = _unset,
    Object? selectedCommitHash = _unset,
    Object? selectedCommitFilePath = _unset,
    List<String>? openDiffFilePaths,
    Object? selectedDiff = _unset,
    List<GitCommitSummary>? history,
    Object? historyFilePath = _unset,
    List<GitBranch>? branches,
    bool? requiresWorkspaceTrust,
    bool? isRefreshing,
    bool? isRunningOperation,
    Object? lastError = _unset,
    Object? lastOperationMessage = _unset,
    Object? attachedWorkspace = _unset,
    Object? scopedFilePath = _unset,
  }) {
    return GitState(
      availability: availability ?? this.availability,
      repositoryInfo: identical(repositoryInfo, _unset)
          ? this.repositoryInfo
          : repositoryInfo as GitRepositoryInfo?,
      statusSnapshot: identical(statusSnapshot, _unset)
          ? this.statusSnapshot
          : statusSnapshot as GitStatusSnapshot?,
      selectedView: selectedView ?? this.selectedView,
      selectedFilePath: identical(selectedFilePath, _unset)
          ? this.selectedFilePath
          : selectedFilePath as String?,
      selectedCommitHash: identical(selectedCommitHash, _unset)
          ? this.selectedCommitHash
          : selectedCommitHash as String?,
      selectedCommitFilePath: identical(selectedCommitFilePath, _unset)
          ? this.selectedCommitFilePath
          : selectedCommitFilePath as String?,
      openDiffFilePaths: openDiffFilePaths ?? this.openDiffFilePaths,
      selectedDiff: identical(selectedDiff, _unset)
          ? this.selectedDiff
          : selectedDiff as GitDiff?,
      history: history ?? this.history,
      historyFilePath: identical(historyFilePath, _unset)
          ? this.historyFilePath
          : historyFilePath as String?,
      branches: branches ?? this.branches,
      requiresWorkspaceTrust:
          requiresWorkspaceTrust ?? this.requiresWorkspaceTrust,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isRunningOperation: isRunningOperation ?? this.isRunningOperation,
      lastError: identical(lastError, _unset)
          ? this.lastError
          : lastError as GitFailure?,
      lastOperationMessage: identical(lastOperationMessage, _unset)
          ? this.lastOperationMessage
          : lastOperationMessage as String?,
      attachedWorkspace: identical(attachedWorkspace, _unset)
          ? this.attachedWorkspace
          : attachedWorkspace as Workspace?,
      scopedFilePath: identical(scopedFilePath, _unset)
          ? this.scopedFilePath
          : scopedFilePath as String?,
    );
  }
}

class GitController extends Notifier<GitState> {
  static const _refreshDebounce = Duration(milliseconds: 350);

  late GitRepositoryGateway _gateway;
  final _validation = const GitValidation();
  Timer? _debounce;
  var _knownHashes = <String>{};
  var _refreshEpoch = 0;
  var _isUpdatingWorkspaceTrust = false;

  @override
  GitState build() {
    _gateway = ref.read(gitRepositoryGatewayProvider);
    ref.listen(appSettingsControllerProvider, (previous, next) {
      if (!_gateway.requiresWorkspaceTrust || _isUpdatingWorkspaceTrust) {
        return;
      }
      final workspace = state.attachedWorkspace;
      if (workspace == null) {
        return;
      }
      final wasTrusted =
          previous?.trustsGitWorkspace(workspace.rootPath) ?? false;
      final isTrusted = next.trustsGitWorkspace(workspace.rootPath);
      if (wasTrusted != isTrusted) {
        if (!isTrusted) {
          _setWorkspaceTrustRequiredState();
        }
        _scheduleRefresh(immediate: true);
      }
    });
    ref.onDispose(() => _debounce?.cancel());
    return const GitState();
  }

  void attachWorkspace(Workspace workspace) {
    if (_gateway is UnavailableGitRepositoryGateway) {
      _debounce?.cancel();
      _knownHashes = {};
      state = _workspaceResetState(
        workspace,
        availability: const GitAvailability.unavailable(
          'Git gateway is not configured.',
        ),
      );
      return;
    }
    if (workspace.kind == WorkspaceKind.untitledMarkdown) {
      _debounce?.cancel();
      _knownHashes = {};
      state = const GitState();
      return;
    }
    final current = state.attachedWorkspace;
    if (current?.id != workspace.id) {
      _debounce?.cancel();
      _knownHashes = {};
      state = _workspaceResetState(workspace);
      _scheduleRefresh(immediate: true);
    } else {
      state = state.copyWith(attachedWorkspace: workspace);
      _scheduleRefresh();
    }
  }

  Future<void> refresh() async {
    final workspace = state.attachedWorkspace;
    if (workspace == null || workspace.kind == WorkspaceKind.untitledMarkdown) {
      return;
    }
    final workspaceId = workspace.id;
    final refreshEpoch = ++_refreshEpoch;
    _debounce?.cancel();
    state = state.copyWith(isRefreshing: true, lastError: null);
    final availability = await _gateway.availability();
    if (!_isCurrentRefresh(workspaceId, refreshEpoch)) {
      return;
    }
    state = state.copyWith(availability: availability);
    if (!availability.available) {
      state = state.copyWith(
        isRefreshing: false,
        requiresWorkspaceTrust: false,
        repositoryInfo: null,
        statusSnapshot: null,
        selectedFilePath: null,
        selectedCommitHash: null,
        selectedDiff: null,
        selectedCommitFilePath: null,
        openDiffFilePaths: const [],
        history: const [],
        historyFilePath: null,
        branches: const [],
        lastOperationMessage: null,
        scopedFilePath: null,
      );
      return;
    }
    final trustedWorkspacePath = _trustedWorkspaceGitPath(workspace);
    if (trustedWorkspacePath == null) {
      _setWorkspaceTrustRequiredState();
      return;
    }
    state = state.copyWith(requiresWorkspaceTrust: false);
    try {
      final repository = await _gateway.detectRepository(trustedWorkspacePath);
      if (!_isCurrentRefresh(workspaceId, refreshEpoch)) {
        return;
      }
      if (_trustedWorkspaceGitPath(workspace) != trustedWorkspacePath) {
        _setWorkspaceTrustRequiredState();
        return;
      }
      if (repository == null) {
        state = state.copyWith(
          isRefreshing: false,
          requiresWorkspaceTrust: false,
          repositoryInfo: null,
          statusSnapshot: null,
          selectedFilePath: null,
          selectedCommitHash: null,
          selectedDiff: null,
          selectedCommitFilePath: null,
          openDiffFilePaths: const [],
          history: const [],
          historyFilePath: null,
          branches: const [],
          lastOperationMessage: null,
          scopedFilePath: null,
        );
        return;
      }
      state = state.copyWith(repositoryInfo: repository);
      final status = await _gateway.status(repository);
      if (!_isCurrentRefresh(workspaceId, refreshEpoch)) {
        return;
      }
      final scoped = _workspaceScopedRepoPath(workspace, status.repositoryInfo);
      state = state.copyWith(
        isRefreshing: false,
        requiresWorkspaceTrust: false,
        repositoryInfo: status.repositoryInfo,
        statusSnapshot: status,
        scopedFilePath: scoped,
        selectedFilePath: state.selectedFilePath ?? scoped,
        lastError: null,
      );
    } on Object catch (error) {
      if (!_isCurrentRefresh(workspaceId, refreshEpoch)) {
        return;
      }
      _setFailure(error, commandName: 'status');
      state = state.copyWith(isRefreshing: false);
    }
  }

  Future<void> trustWorkspace() async {
    final workspace = state.attachedWorkspace;
    if (workspace == null ||
        !state.requiresWorkspaceTrust ||
        !_gateway.requiresWorkspaceTrust) {
      return;
    }
    final workspaceId = workspace.id;
    _isUpdatingWorkspaceTrust = true;
    try {
      await ref
          .read(appSettingsControllerProvider.notifier)
          .trustGitWorkspace(workspace.rootPath);
    } finally {
      _isUpdatingWorkspaceTrust = false;
    }
    if (_isCurrentWorkspace(workspaceId)) {
      await refresh();
    }
  }

  Future<void> selectView(GitView view) async {
    state = state.copyWith(selectedView: view);
    if (view == GitView.history &&
        (state.history.isEmpty || state.historyFilePath != null)) {
      await loadProjectHistory();
    }
  }

  void clearSelection() {
    state = state.copyWith(
      selectedFilePath: null,
      selectedCommitHash: null,
      selectedCommitFilePath: null,
      openDiffFilePaths: const [],
      selectedDiff: null,
    );
  }

  void deactivateDiffFile() {
    if (state.selectedCommitFilePath == null) {
      return;
    }
    state = state.copyWith(selectedCommitFilePath: null);
  }

  Future<void> selectChangedFile(String repoRelativePath) async {
    final failure = _validation.validateRepoRelativePaths([repoRelativePath]);
    if (failure != null) {
      state = state.copyWith(lastError: failure);
      return;
    }
    state = state.copyWith(
      selectedFilePath: repoRelativePath,
      selectedCommitHash: null,
      selectedCommitFilePath: null,
      openDiffFilePaths: const [],
      selectedDiff: null,
    );
    await _loadChangedFileDiff(repoRelativePath);
  }

  Future<void> showCurrentFileDiff() async {
    final path = state.scopedFilePath;
    if (path != null) {
      await selectChangedFile(path);
    }
  }

  Future<void> loadFileHistory(String absolutePath) async {
    final repository = _trustedRepositoryInfo;
    if (repository == null) {
      return;
    }
    final relative = _repoRelativePath(repository.rootPath, absolutePath);
    if (relative == null) {
      return;
    }
    await _loadHistory(repoRelativePath: relative);
  }

  Future<void> loadProjectHistory() => _loadHistory();

  Future<void> loadCommitDetails(String hash) async {
    final repository = _trustedRepositoryInfo;
    if (repository == null || !_knownHashes.contains(hash)) {
      state = state.copyWith(
        lastError: GitFailure(
          code: GitFailureCode.invalidPath,
          userMessageKey: 'gitErrorInvalidCommit',
          rawMessage: hash,
          commandName: 'show',
        ),
      );
      return;
    }
    state = state.copyWith(isRunningOperation: true, lastError: null);
    try {
      final details = await _gateway.commitDetails(
        repository,
        hash,
        repoRelativePath: state.historyFilePath,
      );
      final firstFilePath = _firstDiffFilePath(details.changedFiles);
      state = state.copyWith(
        isRunningOperation: false,
        selectedCommitHash: hash,
        selectedCommitFilePath: firstFilePath,
        openDiffFilePaths: firstFilePath == null ? const [] : [firstFilePath],
        selectedFilePath: null,
        selectedDiff: GitDiff(
          title: details.summary.subject,
          files: details.changedFiles,
          rawPatch: details.patch,
          hasBinaryFiles: details.changedFiles.any((file) => file.binary),
          fileSnapshots: details.fileSnapshots,
        ),
      );
    } on Object catch (error) {
      _setFailure(error, commandName: 'show');
      state = state.copyWith(isRunningOperation: false);
    }
  }

  void selectCommitFile(String repoRelativePath) {
    final diff = state.selectedDiff;
    if (diff == null) {
      return;
    }
    final failure = _validation.validateRepoRelativePaths([repoRelativePath]);
    if (failure != null) {
      state = state.copyWith(lastError: failure);
      return;
    }
    if (!diff.files.any((file) => file.matchesPath(repoRelativePath))) {
      return;
    }
    final openPaths = state.openDiffFilePaths.contains(repoRelativePath)
        ? state.openDiffFilePaths
        : [...state.openDiffFilePaths, repoRelativePath];
    state = state.copyWith(
      selectedCommitFilePath: repoRelativePath,
      openDiffFilePaths: openPaths,
    );
  }

  void closeDiffFile(String repoRelativePath) {
    final openPaths = [...state.openDiffFilePaths];
    final index = openPaths.indexOf(repoRelativePath);
    if (index < 0) {
      return;
    }
    openPaths.removeAt(index);
    if (openPaths.isEmpty) {
      clearSelection();
      return;
    }
    final nextIndex = index >= openPaths.length ? openPaths.length - 1 : index;
    final activePath = state.selectedCommitFilePath == repoRelativePath
        ? openPaths[nextIndex]
        : state.selectedCommitFilePath;
    state = state.copyWith(
      selectedCommitFilePath: activePath,
      openDiffFilePaths: openPaths,
    );
  }

  Future<void> stageFiles(List<String> repoRelativePaths) {
    return _runPathOperation(
      repoRelativePaths,
      (repository, paths) => _gateway.stage(repository, paths),
    );
  }

  Future<void> unstageFiles(List<String> repoRelativePaths) {
    return _runPathOperation(
      repoRelativePaths,
      (repository, paths) => _gateway.unstage(repository, paths),
    );
  }

  Future<void> discardFiles(List<String> repoRelativePaths) async {
    final repository = _trustedRepositoryInfo;
    final snapshot = state.statusSnapshot;
    if (repository == null || snapshot == null) {
      return;
    }
    final failure = _validation.validateRepoRelativePaths(repoRelativePaths);
    if (failure != null) {
      state = state.copyWith(lastError: failure);
      return;
    }
    final untracked = <String>[];
    final tracked = <String>[];
    for (final path in repoRelativePaths) {
      final status = snapshot.files
          .where((file) => file.repoRelativePath == path)
          .firstOrNull;
      if (status?.untracked ?? false) {
        untracked.add(path);
      } else {
        tracked.add(path);
      }
    }
    state = state.copyWith(isRunningOperation: true, lastError: null);
    try {
      GitOperationResult? result;
      if (tracked.isNotEmpty) {
        result = await _gateway.discardTracked(repository, tracked);
      }
      if (untracked.isNotEmpty) {
        result = await _gateway.discardUntracked(
          repository,
          untracked,
          snapshot,
        );
      }
      state = state.copyWith(
        isRunningOperation: false,
        lastOperationMessage: result?.message,
      );
      await refresh();
      final selected = state.selectedFilePath;
      if (selected != null && repoRelativePaths.contains(selected)) {
        state = state.copyWith(selectedDiff: null);
      }
    } on Object catch (error) {
      _setFailure(error, commandName: 'restore');
      state = state.copyWith(isRunningOperation: false);
    }
  }

  Future<void> commit(String message) async {
    final repository = _trustedRepositoryInfo;
    if (repository == null) {
      return;
    }
    final messageFailure = _validation.validateCommitMessage(message);
    final stagedFailure = _validation.validateHasStagedFiles(
      state.statusSnapshot,
    );
    final failure = messageFailure ?? stagedFailure;
    if (failure != null) {
      state = state.copyWith(lastError: failure);
      return;
    }
    await _runOperation((repository) => _gateway.commit(repository, message));
    await loadProjectHistory();
  }

  Future<void> pullFastForwardOnly() {
    return _runOperation(
      (repository) => _gateway.pullFastForwardOnly(repository),
    );
  }

  Future<void> push({bool allowSetUpstream = false}) async {
    final repository = _trustedRepositoryInfo;
    if (repository == null) {
      return;
    }
    if (repository.upstreamBranch != null) {
      await _runOperation((repository) => _gateway.push(repository));
      return;
    }
    final branch = repository.currentBranch;
    if (branch == null) {
      state = state.copyWith(
        lastError: const GitFailure(
          code: GitFailureCode.noUpstream,
          userMessageKey: 'gitErrorNoUpstream',
          rawMessage: '',
          commandName: 'push',
        ),
      );
      return;
    }
    final remotes = await _gateway.remotes(repository);
    if (remotes.isEmpty) {
      state = state.copyWith(
        lastError: const GitFailure(
          code: GitFailureCode.noRemote,
          userMessageKey: 'gitErrorNoRemote',
          rawMessage: '',
          commandName: 'push',
        ),
      );
      return;
    }
    if (remotes.length > 1 || !allowSetUpstream) {
      state = state.copyWith(
        lastError: GitFailure(
          code: remotes.length > 1
              ? GitFailureCode.multipleRemotes
              : GitFailureCode.noUpstream,
          userMessageKey: remotes.length > 1
              ? 'gitErrorMultipleRemotes'
              : 'gitErrorNoUpstream',
          rawMessage: remotes.join(', '),
          commandName: 'push',
        ),
      );
      return;
    }
    await _runOperation(
      (repository) =>
          _gateway.pushSetUpstream(repository, remotes.single, branch),
    );
  }

  Future<void> createBranch(String branchName) async {
    final failure = _validation.validateBranchNameShape(branchName);
    if (failure != null) {
      state = state.copyWith(lastError: failure);
      return;
    }
    await _runOperation(
      (repository) => _gateway.createBranch(repository, branchName.trim()),
    );
    await loadBranches();
  }

  Future<void> switchBranch(String branchName) async {
    if (ref.read(workspaceControllerProvider).hasUnsavedChanges) {
      state = state.copyWith(
        lastError: const GitFailure(
          code: GitFailureCode.dirtyWorkspace,
          userMessageKey: 'gitErrorDirtyWorkspace',
          rawMessage: '',
          commandName: 'switch',
        ),
      );
      return;
    }
    await _runOperation(
      (repository) => _gateway.switchBranch(repository, branchName),
    );
    await loadBranches();
  }

  Future<void> initializeRepository() async {
    final workspace = state.attachedWorkspace;
    final trustedWorkspacePath = workspace == null
        ? null
        : _trustedWorkspaceGitPath(workspace);
    if (workspace == null ||
        trustedWorkspacePath == null ||
        workspace.kind == WorkspaceKind.untitledMarkdown ||
        workspace.kind == WorkspaceKind.singleMarkdown) {
      return;
    }
    await _runRootOperation(
      trustedWorkspacePath,
      _gateway.initializeRepository,
    );
  }

  Future<List<GitBranch>> loadBranches() async {
    final repository = _trustedRepositoryInfo;
    if (repository == null) {
      return state.branches;
    }
    state = state.copyWith(isRunningOperation: true, lastError: null);
    try {
      final branches = await _gateway.branches(repository);
      state = state.copyWith(isRunningOperation: false, branches: branches);
      return branches;
    } on Object catch (error) {
      _setFailure(error, commandName: 'branch');
      state = state.copyWith(isRunningOperation: false);
      return state.branches;
    }
  }

  Future<void> _loadHistory({String? repoRelativePath}) async {
    final repository = _trustedRepositoryInfo;
    if (repository == null) {
      return;
    }
    state = state.copyWith(isRunningOperation: true, lastError: null);
    try {
      final history = await _gateway.history(
        repository,
        repoRelativePath: repoRelativePath,
      );
      _knownHashes = {for (final commit in history) commit.fullHash};
      state = state.copyWith(
        isRunningOperation: false,
        history: history,
        historyFilePath: repoRelativePath,
        selectedCommitHash: null,
        selectedCommitFilePath: null,
        openDiffFilePaths: const [],
        selectedDiff: null,
        selectedView: repoRelativePath == null
            ? GitView.history
            : state.selectedView,
      );
    } on Object catch (error) {
      _setFailure(error, commandName: 'log');
      state = state.copyWith(isRunningOperation: false);
    }
  }

  Future<void> _loadChangedFileDiff(String repoRelativePath) async {
    final repository = _trustedRepositoryInfo;
    if (repository == null) {
      return;
    }
    state = state.copyWith(isRunningOperation: true, lastError: null);
    try {
      final staged = await _gateway.diffFile(
        repository,
        repoRelativePath,
        staged: true,
      );
      final unstaged = await _gateway.diffFile(
        repository,
        repoRelativePath,
        staged: false,
      );
      state = state.copyWith(
        isRunningOperation: false,
        selectedCommitFilePath: repoRelativePath,
        openDiffFilePaths: [repoRelativePath],
        selectedDiff: _combineDiffs(
          repoRelativePath,
          staged: staged,
          unstaged: unstaged,
        ),
      );
    } on Object catch (error) {
      _setFailure(error, commandName: 'diff');
      state = state.copyWith(isRunningOperation: false);
    }
  }

  Future<void> _runPathOperation(
    List<String> repoRelativePaths,
    Future<GitOperationResult> Function(
      GitRepositoryInfo repository,
      List<String> paths,
    )
    operation,
  ) async {
    final repository = _trustedRepositoryInfo;
    if (repository == null) {
      return;
    }
    final failure = _validation.validateRepoRelativePaths(repoRelativePaths);
    if (failure != null) {
      state = state.copyWith(lastError: failure);
      return;
    }
    await _runOperation(
      (repository) => operation(repository, repoRelativePaths),
    );
  }

  Future<void> _runOperation(
    Future<GitOperationResult> Function(GitRepositoryInfo repository) operation,
  ) async {
    final repository = _trustedRepositoryInfo;
    if (repository == null) {
      return;
    }
    state = state.copyWith(isRunningOperation: true, lastError: null);
    try {
      final result = await operation(repository);
      state = state.copyWith(
        isRunningOperation: false,
        lastOperationMessage: result.message,
      );
      await refresh();
      final selected = state.selectedFilePath;
      if (selected != null) {
        await _loadChangedFileDiff(selected);
      }
    } on Object catch (error) {
      _setFailure(error, commandName: 'git');
      state = state.copyWith(isRunningOperation: false);
    }
  }

  Future<void> _runRootOperation(
    String rootPath,
    Future<GitOperationResult> Function(String rootPath) operation,
  ) async {
    state = state.copyWith(isRunningOperation: true, lastError: null);
    try {
      final result = await operation(rootPath);
      state = state.copyWith(
        isRunningOperation: false,
        lastOperationMessage: result.message,
      );
      await refresh();
    } on Object catch (error) {
      _setFailure(error, commandName: 'git');
      state = state.copyWith(isRunningOperation: false);
    }
  }

  void _scheduleRefresh({bool immediate = false}) {
    _debounce?.cancel();
    if (immediate) {
      unawaited(refresh());
      return;
    }
    _debounce = Timer(_refreshDebounce, () => unawaited(refresh()));
  }

  void _setWorkspaceTrustRequiredState() {
    _debounce?.cancel();
    _knownHashes = {};
    state = state.copyWith(
      isRefreshing: false,
      isRunningOperation: false,
      requiresWorkspaceTrust: true,
      repositoryInfo: null,
      statusSnapshot: null,
      selectedFilePath: null,
      selectedCommitHash: null,
      selectedCommitFilePath: null,
      openDiffFilePaths: const [],
      selectedDiff: null,
      history: const [],
      historyFilePath: null,
      branches: const [],
      lastError: null,
      lastOperationMessage: null,
      scopedFilePath: null,
    );
  }

  void _setFailure(Object error, {required String commandName}) {
    final failure = error is GitFailure
        ? error
        : GitFailure(
            code: GitFailureCode.commandFailed,
            userMessageKey: 'gitErrorCommandFailed',
            rawMessage: '$error',
            commandName: commandName,
          );
    state = state.copyWith(lastError: failure);
  }

  GitState _workspaceResetState(
    Workspace workspace, {
    GitAvailability? availability,
  }) {
    return GitState(
      availability: availability ?? state.availability,
      selectedView: GitView.changes,
      attachedWorkspace: workspace,
      requiresWorkspaceTrust: !_workspaceHasGitTrust(workspace),
    );
  }

  bool _isCurrentWorkspace(String workspaceId) {
    return ref.mounted && state.attachedWorkspace?.id == workspaceId;
  }

  bool _isCurrentRefresh(String workspaceId, int refreshEpoch) {
    return _refreshEpoch == refreshEpoch && _isCurrentWorkspace(workspaceId);
  }

  bool _workspaceHasGitTrust(Workspace workspace) {
    return _trustedWorkspaceGitPath(workspace) != null;
  }

  String? _trustedWorkspaceGitPath(Workspace workspace) {
    if (!_gateway.requiresWorkspaceTrust) {
      return workspace.rootPath;
    }
    return ref
        .read(appSettingsControllerProvider)
        .trustedGitWorkspacePath(workspace.rootPath);
  }

  GitRepositoryInfo? get _trustedRepositoryInfo {
    final workspace = state.attachedWorkspace;
    if (workspace == null || !_workspaceHasGitTrust(workspace)) {
      return null;
    }
    return state.repositoryInfo;
  }

  String? _workspaceScopedRepoPath(
    Workspace workspace,
    GitRepositoryInfo repository,
  ) {
    final active = workspace.activeFilePath ?? workspace.markdown?.filePath;
    if (active == null) {
      return null;
    }
    return _repoRelativePath(repository.rootPath, active);
  }

  String? _repoRelativePath(String rootPath, String absolutePath) {
    final relative = p.normalize(p.relative(absolutePath, from: rootPath));
    if (relative == '.' ||
        relative.startsWith('..') ||
        p.isAbsolute(relative)) {
      return null;
    }
    return relative.replaceAll(r'\', '/');
  }

  String? _firstDiffFilePath(List<GitDiffFile> files) {
    for (final file in files) {
      final path = file.displayPath;
      if (path.isNotEmpty) {
        return path;
      }
    }
    return null;
  }

  GitDiff _combineDiffs(
    String title, {
    required GitDiff staged,
    required GitDiff unstaged,
  }) {
    final raw = [
      if (staged.rawPatch.trim().isNotEmpty)
        '--- BusyMark staged changes ---\n${staged.rawPatch}',
      if (unstaged.rawPatch.trim().isNotEmpty)
        '--- BusyMark unstaged changes ---\n${unstaged.rawPatch}',
    ].join('\n');
    return GitDiff(
      title: title,
      files: [...staged.files, ...unstaged.files],
      rawPatch: raw,
      hasBinaryFiles: staged.hasBinaryFiles || unstaged.hasBinaryFiles,
      fileSnapshots: {...staged.fileSnapshots, ...unstaged.fileSnapshots},
    );
  }
}

class UnavailableGitRepositoryGateway implements GitRepositoryGateway {
  const UnavailableGitRepositoryGateway();

  @override
  bool get requiresWorkspaceTrust => false;

  @override
  Future<GitAvailability> availability() async {
    return const GitAvailability.unavailable('Git gateway is not configured.');
  }

  @override
  Future<GitRepositoryInfo?> detectRepository(String workspacePath) async =>
      null;

  @override
  Future<GitStatusSnapshot> status(GitRepositoryInfo repository) =>
      _unavailable();

  @override
  Future<GitDiff> diffFile(
    GitRepositoryInfo repository,
    String repoRelativePath, {
    required bool staged,
  }) => _unavailable();

  @override
  Future<GitDiff> diffAll(
    GitRepositoryInfo repository, {
    required bool staged,
  }) => _unavailable();

  @override
  Future<List<GitCommitSummary>> history(
    GitRepositoryInfo repository, {
    String? repoRelativePath,
    int limit = 200,
    int skip = 0,
  }) => _unavailable();

  @override
  Future<GitCommitDetails> commitDetails(
    GitRepositoryInfo repository,
    String hash, {
    String? repoRelativePath,
  }) => _unavailable();

  @override
  Future<List<GitBranch>> branches(GitRepositoryInfo repository) =>
      _unavailable();

  @override
  Future<List<String>> remotes(GitRepositoryInfo repository) => _unavailable();

  @override
  Future<GitOperationResult> stage(
    GitRepositoryInfo repository,
    List<String> repoRelativePaths,
  ) => _unavailable();

  @override
  Future<GitOperationResult> unstage(
    GitRepositoryInfo repository,
    List<String> repoRelativePaths,
  ) => _unavailable();

  @override
  Future<GitOperationResult> discardTracked(
    GitRepositoryInfo repository,
    List<String> repoRelativePaths,
  ) => _unavailable();

  @override
  Future<GitOperationResult> discardUntracked(
    GitRepositoryInfo repository,
    List<String> repoRelativePaths,
    GitStatusSnapshot snapshot,
  ) => _unavailable();

  @override
  Future<GitOperationResult> commit(
    GitRepositoryInfo repository,
    String message,
  ) => _unavailable();

  @override
  Future<GitOperationResult> pullFastForwardOnly(
    GitRepositoryInfo repository,
  ) => _unavailable();

  @override
  Future<GitOperationResult> push(GitRepositoryInfo repository) =>
      _unavailable();

  @override
  Future<GitOperationResult> pushSetUpstream(
    GitRepositoryInfo repository,
    String remote,
    String branch,
  ) => _unavailable();

  @override
  Future<GitOperationResult> createBranch(
    GitRepositoryInfo repository,
    String branchName,
  ) => _unavailable();

  @override
  Future<GitOperationResult> switchBranch(
    GitRepositoryInfo repository,
    String branchName,
  ) => _unavailable();

  @override
  Future<GitOperationResult> initializeRepository(String rootPath) =>
      _unavailable();

  Future<T> _unavailable<T>() {
    throw const GitFailure(
      code: GitFailureCode.unavailable,
      userMessageKey: 'gitErrorUnavailable',
      rawMessage: 'Git is unavailable.',
      commandName: 'git',
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

const Object _unset = Object();
