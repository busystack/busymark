import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../app/app_settings.dart';
import '../../core/path_utils.dart';
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

class GitFileHistoryState {
  const GitFileHistoryState({
    this.entries = const [],
    this.currentPath,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.selectedCommitHash,
    this.comparisonType = GitComparisonType.commitChange,
    this.comparison,
  });

  final List<GitFileHistoryEntry> entries;
  final String? currentPath;
  final bool hasMore;
  final bool isLoadingMore;
  final String? selectedCommitHash;
  final GitComparisonType comparisonType;
  final GitHistoricalFileComparison? comparison;

  GitFileHistoryEntry? get selectedEntry {
    final hash = selectedCommitHash;
    if (hash == null) {
      return null;
    }
    return entries.where((entry) => entry.commit.fullHash == hash).firstOrNull;
  }

  GitFileHistoryState copyWith({
    List<GitFileHistoryEntry>? entries,
    Object? currentPath = _unset,
    bool? hasMore,
    bool? isLoadingMore,
    Object? selectedCommitHash = _unset,
    GitComparisonType? comparisonType,
    Object? comparison = _unset,
  }) {
    return GitFileHistoryState(
      entries: entries ?? this.entries,
      currentPath: identical(currentPath, _unset)
          ? this.currentPath
          : currentPath as String?,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      selectedCommitHash: identical(selectedCommitHash, _unset)
          ? this.selectedCommitHash
          : selectedCommitHash as String?,
      comparisonType: comparisonType ?? this.comparisonType,
      comparison: identical(comparison, _unset)
          ? this.comparison
          : comparison as GitHistoricalFileComparison?,
    );
  }
}

class GitProjectHistoryState {
  const GitProjectHistoryState({
    this.commits = const [],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.selectedCommitHash,
    this.selectedFilePath,
    this.details,
    this.comparisonType = GitComparisonType.commitChange,
    this.comparison,
  });

  final List<GitCommitSummary> commits;
  final bool hasMore;
  final bool isLoadingMore;
  final String? selectedCommitHash;
  final String? selectedFilePath;
  final GitCommitDetails? details;
  final GitComparisonType comparisonType;
  final GitHistoricalFileComparison? comparison;

  GitProjectHistoryState copyWith({
    List<GitCommitSummary>? commits,
    bool? hasMore,
    bool? isLoadingMore,
    Object? selectedCommitHash = _unset,
    Object? selectedFilePath = _unset,
    Object? details = _unset,
    GitComparisonType? comparisonType,
    Object? comparison = _unset,
  }) {
    return GitProjectHistoryState(
      commits: commits ?? this.commits,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      selectedCommitHash: identical(selectedCommitHash, _unset)
          ? this.selectedCommitHash
          : selectedCommitHash as String?,
      selectedFilePath: identical(selectedFilePath, _unset)
          ? this.selectedFilePath
          : selectedFilePath as String?,
      details: identical(details, _unset)
          ? this.details
          : details as GitCommitDetails?,
      comparisonType: comparisonType ?? this.comparisonType,
      comparison: identical(comparison, _unset)
          ? this.comparison
          : comparison as GitHistoricalFileComparison?,
    );
  }
}

class GitState {
  const GitState({
    this.availability = const GitAvailability.unavailable(),
    this.repositoryInfo,
    this.statusSnapshot,
    this.selectedView = GitView.changes,
    this.selectedChange,
    this.changeDiff,
    this.fileHistory = const GitFileHistoryState(),
    this.projectHistory = const GitProjectHistoryState(),
    this.selectedCommitFilePath,
    this.openDiffFilePaths = const [],
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
  final GitChangeSelection? selectedChange;
  final GitDiff? changeDiff;
  final GitFileHistoryState fileHistory;
  final GitProjectHistoryState projectHistory;
  final String? selectedCommitFilePath;
  final List<String> openDiffFilePaths;
  final List<GitBranch> branches;
  final bool requiresWorkspaceTrust;
  final bool isRefreshing;
  final bool isRunningOperation;
  final GitFailure? lastError;
  final String? lastOperationMessage;
  final Workspace? attachedWorkspace;
  final String? scopedFilePath;

  bool get isRepository => repositoryInfo != null;
  String? get selectedFilePath => selectedChange?.path;
  String? get selectedCommitHash => switch (selectedView) {
    GitView.fileHistory => fileHistory.selectedCommitHash,
    GitView.projectHistory => projectHistory.selectedCommitHash,
    GitView.changes => null,
  };
  GitDiff? get selectedDiff => switch (selectedView) {
    GitView.changes => changeDiff,
    GitView.fileHistory => fileHistory.comparison?.diff,
    GitView.projectHistory => projectHistory.comparison?.diff,
  };
  String? get selectedDiffOpenFilePath {
    return switch (selectedView) {
      GitView.changes => () {
        final selection = selectedChange;
        if (selection == null) {
          return null;
        }
        final path = selectedCommitFilePath ?? selection.path;
        final status = statusSnapshot?.files
            .where((file) => file.repoRelativePath == path)
            .firstOrNull;
        return (status?.hasWorkingTreeFile ?? false) ? path : null;
      }(),
      GitView.fileHistory => fileHistory.currentPath,
      GitView.projectHistory => null,
    };
  }

  List<GitCommitSummary> get history => switch (selectedView) {
    GitView.fileHistory => [
      for (final entry in fileHistory.entries) entry.commit,
    ],
    GitView.projectHistory => projectHistory.commits,
    GitView.changes => const [],
  };
  String? get historyFilePath =>
      selectedView == GitView.fileHistory ? fileHistory.currentPath : null;

  GitDiff? get selectedDiffForDisplay {
    final diff = selectedDiff;
    final path = selectedCommitFilePath;
    if (diff == null) {
      return null;
    }
    if (path == null) {
      return null;
    }
    if (!openDiffFilePaths.contains(path) && openDiffFilePaths.isNotEmpty) {
      return null;
    }
    final selectedFiles = [
      for (final file in diff.files)
        if (file.matchesPath(path)) file,
    ];
    if (selectedFiles.isEmpty) {
      return diff.files.isEmpty ? diff : null;
    }
    return GitDiff(
      title: path,
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
    Object? selectedChange = _unset,
    Object? changeDiff = _unset,
    GitFileHistoryState? fileHistory,
    GitProjectHistoryState? projectHistory,
    Object? selectedCommitFilePath = _unset,
    List<String>? openDiffFilePaths,
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
      selectedChange: identical(selectedChange, _unset)
          ? this.selectedChange
          : selectedChange as GitChangeSelection?,
      changeDiff: identical(changeDiff, _unset)
          ? this.changeDiff
          : changeDiff as GitDiff?,
      fileHistory: fileHistory ?? this.fileHistory,
      projectHistory: projectHistory ?? this.projectHistory,
      selectedCommitFilePath: identical(selectedCommitFilePath, _unset)
          ? this.selectedCommitFilePath
          : selectedCommitFilePath as String?,
      openDiffFilePaths: openDiffFilePaths ?? this.openDiffFilePaths,
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
  static const _historyPageSize = 50;

  late GitRepositoryGateway _gateway;
  final _validation = const GitValidation();
  Timer? _debounce;
  var _knownHashes = <String>{};
  var _refreshEpoch = 0;
  var _workspaceEpoch = 0;
  var _commitDetailsEpoch = 0;
  var _branchesEpoch = 0;
  var _fileHistoryEpoch = 0;
  var _projectHistoryEpoch = 0;
  var _diffEpoch = 0;
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
    if (state.attachedWorkspace?.id != workspace.id) {
      _workspaceEpoch++;
    }
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
        selectedChange: null,
        changeDiff: null,
        selectedCommitFilePath: null,
        openDiffFilePaths: const [],
        fileHistory: const GitFileHistoryState(),
        projectHistory: const GitProjectHistoryState(),
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
          selectedChange: null,
          changeDiff: null,
          selectedCommitFilePath: null,
          openDiffFilePaths: const [],
          fileHistory: const GitFileHistoryState(),
          projectHistory: const GitProjectHistoryState(),
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
      final selectedChange = _reconcileChangeSelection(
        state.selectedChange,
        status,
      );
      final clearChangeTab =
          state.selectedView == GitView.changes && selectedChange == null;
      state = state.copyWith(
        isRefreshing: false,
        requiresWorkspaceTrust: false,
        repositoryInfo: status.repositoryInfo,
        statusSnapshot: status,
        scopedFilePath: scoped,
        selectedChange: selectedChange,
        changeDiff: selectedChange == state.selectedChange
            ? state.changeDiff
            : null,
        selectedCommitFilePath: clearChangeTab
            ? null
            : state.selectedCommitFilePath,
        openDiffFilePaths: clearChangeTab ? const [] : state.openDiffFilePaths,
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
    final activePath = switch (view) {
      GitView.changes =>
        state.changeDiff == null ? null : state.selectedChange?.path,
      GitView.fileHistory =>
        state.fileHistory.comparison?.diff.files.firstOrNull?.displayPath,
      GitView.projectHistory => state.projectHistory.selectedFilePath,
    };
    state = state.copyWith(
      selectedView: view,
      selectedCommitFilePath: activePath,
      openDiffFilePaths: activePath == null ? const [] : [activePath],
    );
    switch (view) {
      case GitView.changes:
        return;
      case GitView.fileHistory:
        final path = state.scopedFilePath;
        if (path != null &&
            (state.fileHistory.currentPath != path ||
                state.fileHistory.entries.isEmpty)) {
          await _loadFileHistory(path);
        }
      case GitView.projectHistory:
        if (state.projectHistory.commits.isEmpty) {
          await loadProjectHistory();
        }
    }
  }

  void clearSelection() {
    state = state.copyWith(
      selectedChange: null,
      changeDiff: null,
      selectedCommitFilePath: null,
      openDiffFilePaths: const [],
    );
  }

  void deactivateDiffFile() {
    if (state.selectedCommitFilePath == null) {
      return;
    }
    state = state.copyWith(selectedCommitFilePath: null);
  }

  Future<void> activateDiffFile(String repoRelativePath) async {
    if (!state.openDiffFilePaths.contains(repoRelativePath)) {
      return;
    }
    switch (state.selectedView) {
      case GitView.changes:
        if (state.changeDiff != null) {
          state = state.copyWith(selectedCommitFilePath: repoRelativePath);
        }
      case GitView.fileHistory:
        if (state.fileHistory.comparison != null) {
          state = state.copyWith(selectedCommitFilePath: repoRelativePath);
        }
      case GitView.projectHistory:
        await selectCommitFile(repoRelativePath);
    }
  }

  Future<void> selectChange(GitChangeSelection selection) async {
    final failure = _validation.validateRepoRelativePaths(
      selection.repoRelativePaths,
    );
    if (failure != null) {
      state = state.copyWith(lastError: failure);
      return;
    }
    state = state.copyWith(
      selectedView: GitView.changes,
      selectedChange: selection,
      changeDiff: null,
      selectedCommitFilePath: null,
      openDiffFilePaths: const [],
    );
    await _loadChangedFileDiff(selection);
  }

  Future<void> selectChangedFile(String repoRelativePath) async {
    final selection = _preferredChangeSelection(repoRelativePath);
    if (selection != null) {
      await selectChange(selection);
    }
  }

  Future<void> showCurrentFileDiff() async {
    final path = state.scopedFilePath;
    if (path != null) {
      final selection = _preferredChangeSelection(path);
      if (selection != null) {
        await selectChange(selection);
      }
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
    await _loadFileHistory(relative);
  }

  Future<void> loadActiveFileHistory() async {
    final path = state.scopedFilePath;
    if (path != null) {
      await _loadFileHistory(path);
    }
  }

  Future<void> loadProjectHistory() => _loadProjectHistory();

  Future<void> loadCommitDetails(String hash) async {
    if (state.selectedView == GitView.fileHistory) {
      await selectFileHistoryCommit(hash);
    } else {
      await selectProjectCommit(hash);
    }
  }

  Future<void> selectFileHistoryCommit(String hash) async {
    final operation = _captureRepositoryOperation();
    final entry = state.fileHistory.entries
        .where((candidate) => candidate.commit.fullHash == hash)
        .firstOrNull;
    if (operation == null || entry == null || !_knownHashes.contains(hash)) {
      _setInvalidCommit(hash);
      return;
    }
    final requestEpoch = ++_commitDetailsEpoch;
    state = state.copyWith(isRunningOperation: true, lastError: null);
    try {
      final comparison = await _gateway.compareFileWithParent(
        operation.repository,
        hash,
        oldPath: entry.oldPath,
        newPath: entry.newPath,
      );
      if (!_isCurrentRepositoryOperation(operation) ||
          requestEpoch != _commitDetailsEpoch) {
        return;
      }
      final displayPath = comparison.newPath ?? comparison.oldPath;
      state = state.copyWith(
        isRunningOperation: false,
        selectedView: GitView.fileHistory,
        fileHistory: state.fileHistory.copyWith(
          selectedCommitHash: hash,
          comparisonType: GitComparisonType.commitChange,
          comparison: comparison,
        ),
        selectedCommitFilePath: displayPath,
        openDiffFilePaths: displayPath == null ? const [] : [displayPath],
      );
    } on Object catch (error) {
      if (!_isCurrentRepositoryOperation(operation) ||
          requestEpoch != _commitDetailsEpoch) {
        return;
      }
      _setFailure(error, commandName: 'show');
      state = state.copyWith(isRunningOperation: false);
    }
  }

  Future<void> selectProjectCommit(String hash) async {
    final operation = _captureRepositoryOperation();
    if (operation == null) {
      return;
    }
    if (!_knownHashes.contains(hash)) {
      _setInvalidCommit(hash);
      return;
    }
    final requestEpoch = ++_commitDetailsEpoch;
    state = state.copyWith(isRunningOperation: true, lastError: null);
    try {
      final details = await _gateway.commitDetails(operation.repository, hash);
      if (!_isCurrentRepositoryOperation(operation) ||
          requestEpoch != _commitDetailsEpoch) {
        return;
      }
      final firstFilePath = _firstDiffFilePath(details.changedFiles);
      state = state.copyWith(
        selectedView: GitView.projectHistory,
        selectedCommitFilePath: null,
        openDiffFilePaths: const [],
        projectHistory: state.projectHistory.copyWith(
          selectedCommitHash: hash,
          selectedFilePath: firstFilePath,
          details: details,
          comparisonType: GitComparisonType.commitChange,
          comparison: null,
        ),
      );
      if (firstFilePath == null) {
        state = state.copyWith(
          isRunningOperation: false,
          selectedCommitFilePath: null,
          openDiffFilePaths: const [],
        );
        return;
      }
      await _loadProjectFileComparison(
        operation,
        hash,
        firstFilePath,
        requestEpoch: requestEpoch,
      );
    } on Object catch (error) {
      if (!_isCurrentRepositoryOperation(operation) ||
          requestEpoch != _commitDetailsEpoch) {
        return;
      }
      _setFailure(error, commandName: 'show');
      state = state.copyWith(isRunningOperation: false);
    }
  }

  Future<void> selectCommitFile(String repoRelativePath) async {
    final project = state.projectHistory;
    final hash = project.selectedCommitHash;
    final details = project.details;
    if (hash == null || details == null) {
      return;
    }
    final failure = _validation.validateRepoRelativePaths([repoRelativePath]);
    if (failure != null) {
      state = state.copyWith(lastError: failure);
      return;
    }
    if (!details.changedFiles.any(
      (file) => file.matchesPath(repoRelativePath),
    )) {
      return;
    }
    final operation = _captureRepositoryOperation();
    if (operation == null) {
      return;
    }
    final requestEpoch = ++_commitDetailsEpoch;
    state = state.copyWith(
      isRunningOperation: true,
      projectHistory: project.copyWith(selectedFilePath: repoRelativePath),
    );
    await _loadProjectFileComparison(
      operation,
      hash,
      repoRelativePath,
      requestEpoch: requestEpoch,
    );
  }

  Future<void> compareFileHistoryWithCurrent() async {
    final operation = _captureRepositoryOperation();
    final history = state.fileHistory;
    final entry = history.selectedEntry;
    final historicalPath = entry?.newPath;
    final currentPath = history.currentPath;
    if (operation == null || entry == null || currentPath == null) {
      return;
    }
    final requestEpoch = ++_commitDetailsEpoch;
    state = state.copyWith(isRunningOperation: true, lastError: null);
    try {
      final comparison = historicalPath == null
          ? await _comparisonFromEmptyWorkingTree(
              operation.repository,
              currentPath,
            )
          : await _gateway.compareFileWithWorkingTree(
              operation.repository,
              entry.commit.fullHash,
              historicalPath: historicalPath,
              currentPath: currentPath,
            );
      if (!_isCurrentRepositoryOperation(operation) ||
          requestEpoch != _commitDetailsEpoch) {
        return;
      }
      state = state.copyWith(
        isRunningOperation: false,
        fileHistory: state.fileHistory.copyWith(
          comparisonType: GitComparisonType.commitVersusCurrent,
          comparison: comparison,
        ),
        selectedCommitFilePath: currentPath,
        openDiffFilePaths: [currentPath],
      );
    } on Object catch (error) {
      if (!_isCurrentRepositoryOperation(operation) ||
          requestEpoch != _commitDetailsEpoch) {
        return;
      }
      _setFailure(error, commandName: 'diff');
      state = state.copyWith(isRunningOperation: false);
    }
  }

  Future<bool> restoreSelectedFileVersion() async {
    if (ref.read(workspaceControllerProvider).hasUnsavedChanges) {
      state = state.copyWith(
        lastError: const GitFailure(
          code: GitFailureCode.dirtyWorkspace,
          userMessageKey: 'gitErrorDirtyWorkspace',
          rawMessage: '',
          commandName: 'restore',
        ),
      );
      return false;
    }
    if (selectedFileHasStagedChanges) {
      state = state.copyWith(
        lastError: const GitFailure(
          code: GitFailureCode.stagedChanges,
          userMessageKey: 'gitErrorRestoreStagedFile',
          rawMessage: '',
          commandName: 'restore',
        ),
      );
      return false;
    }
    final operation = _captureRepositoryOperation();
    final history = state.fileHistory;
    final entry = history.selectedEntry;
    final historicalPath = entry?.newPath ?? entry?.pathAtCommit;
    final currentPath = history.currentPath;
    if (operation == null ||
        entry == null ||
        historicalPath == null ||
        currentPath == null) {
      return false;
    }
    state = state.copyWith(isRunningOperation: true, lastError: null);
    try {
      final result = await _gateway.restoreFileFromCommit(
        operation.repository,
        entry.commit.fullHash,
        historicalPath: historicalPath,
        currentPath: currentPath,
      );
      if (!_isCurrentRepositoryOperation(operation)) {
        return false;
      }
      final reloaded = await ref
          .read(workspaceControllerProvider.notifier)
          .refreshWorkspaceFromDiskPreservingOpenTabs();
      if (!reloaded || !_isCurrentRepositoryOperation(operation)) {
        return false;
      }
      state = state.copyWith(
        isRunningOperation: false,
        lastOperationMessage: result.message,
      );
      await refresh();
      return _isCurrentRepositoryOperation(operation);
    } on Object catch (error) {
      if (!_isCurrentRepositoryOperation(operation)) {
        return false;
      }
      _setFailure(error, commandName: 'restore');
      state = state.copyWith(isRunningOperation: false);
      return false;
    }
  }

  bool get selectedFileHasStagedChanges {
    final currentPath = state.fileHistory.currentPath;
    if (currentPath == null) {
      return false;
    }
    return state.statusSnapshot?.stagedFiles.any(
          (file) =>
              file.repoRelativePath == currentPath ||
              (file.hasStagedRename &&
                  file.originalRepoRelativePath == currentPath),
        ) ??
        false;
  }

  bool isOutsideWorkspace(String repoRelativePath) {
    final repository = state.repositoryInfo;
    final workspace = state.attachedWorkspace;
    if (repository == null || workspace == null) {
      return false;
    }
    final absolute = p.normalize(p.join(repository.rootPath, repoRelativePath));
    if (workspace.kind == WorkspaceKind.singleMarkdown) {
      final active = workspace.activeFilePath ?? workspace.rootPath;
      return p.normalize(active) != absolute;
    }
    final relative = p.relative(
      absolute,
      from: p.normalize(workspace.rootPath),
    );
    return relative == '..' ||
        relative.startsWith('..${p.separator}') ||
        p.isAbsolute(relative);
  }

  void closeDiffFile(String repoRelativePath) {
    final openPaths = [...state.openDiffFilePaths];
    final index = openPaths.indexOf(repoRelativePath);
    if (index < 0) {
      return;
    }
    openPaths.removeAt(index);
    if (openPaths.isEmpty) {
      state = state.copyWith(
        selectedCommitFilePath: null,
        openDiffFilePaths: const [],
      );
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
    if (state.selectedView == GitView.projectHistory && activePath != null) {
      unawaited(selectCommitFile(activePath));
    }
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

  Future<void> rollbackFiles(List<String> repoRelativePaths) {
    return _runPathOperation(
      repoRelativePaths,
      (repository, paths) => _gateway.rollbackTracked(repository, paths),
    );
  }

  Future<void> deleteUntrackedFiles(List<String> repoRelativePaths) async {
    final snapshot = state.statusSnapshot;
    if (snapshot == null) {
      return;
    }
    final failure = _validation.validateRepoRelativePaths(repoRelativePaths);
    if (failure != null) {
      state = state.copyWith(lastError: failure);
      return;
    }
    for (final path in repoRelativePaths) {
      final status = snapshot.files
          .where((file) => file.repoRelativePath == path)
          .firstOrNull;
      if (status?.untracked != true) {
        state = state.copyWith(
          lastError: GitFailure(
            code: GitFailureCode.invalidPath,
            userMessageKey: 'gitErrorUnsafePath',
            rawMessage: path,
            commandName: 'delete',
          ),
        );
        return;
      }
    }
    await _runPathOperation(
      repoRelativePaths,
      (repository, paths) =>
          _gateway.discardUntracked(repository, paths, snapshot),
    );
  }

  Future<bool> commit(String message) async {
    final operation = _captureRepositoryOperation();
    if (operation == null) {
      return false;
    }
    final messageFailure = _validation.validateCommitMessage(message);
    final stagedFailure = _validation.validateHasStagedFiles(
      state.statusSnapshot,
    );
    final failure = messageFailure ?? stagedFailure;
    if (failure != null) {
      state = state.copyWith(lastError: failure);
      return false;
    }
    final completed = await _runOperation(
      (repository) => _gateway.commit(repository, message),
      context: operation,
    );
    if (completed) {
      await loadProjectHistory();
    }
    return completed;
  }

  Future<void> pullFastForwardOnly() async {
    await _runOperation(
      (repository) => _gateway.pullFastForwardOnly(repository),
    );
  }

  Future<void> fetch() async {
    await _runOperation((repository) => _gateway.fetch(repository));
  }

  Future<void> push({bool allowSetUpstream = false}) async {
    final operation = _captureRepositoryOperation();
    if (operation == null) {
      return;
    }
    final repository = operation.repository;
    if (repository.upstreamBranch != null) {
      await _runOperation(
        (repository) => _gateway.push(repository),
        context: operation,
      );
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
    final currentRepository = _trustedRepositoryInfo;
    if (!_isCurrentRepositoryOperation(operation) ||
        currentRepository?.currentBranch != branch ||
        currentRepository?.upstreamBranch != null) {
      return;
    }
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
      context: operation,
    );
  }

  Future<void> createBranch(String branchName) async {
    final failure = _validation.validateBranchNameShape(branchName);
    if (failure != null) {
      state = state.copyWith(lastError: failure);
      return;
    }
    final completed = await _runOperation(
      (repository) => _gateway.createBranch(repository, branchName.trim()),
    );
    if (completed) {
      await loadBranches();
    }
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
    final completed = await _runOperation(
      (repository) => _gateway.switchBranch(repository, branchName),
    );
    if (completed) {
      await loadBranches();
    }
  }

  Future<void> initializeRepository() async {
    final workspace = state.attachedWorkspace;
    final context = _captureWorkspaceOperation();
    final trustedWorkspacePath = workspace == null
        ? null
        : _trustedWorkspaceGitPath(workspace);
    if (workspace == null ||
        context == null ||
        trustedWorkspacePath == null ||
        workspace.kind == WorkspaceKind.untitledMarkdown ||
        workspace.kind == WorkspaceKind.singleMarkdown) {
      return;
    }
    await _runRootOperation(
      trustedWorkspacePath,
      _gateway.initializeRepository,
      context: context,
    );
  }

  Future<List<GitBranch>> loadBranches() async {
    final operation = _captureRepositoryOperation();
    if (operation == null) {
      return state.branches;
    }
    final requestEpoch = ++_branchesEpoch;
    state = state.copyWith(isRunningOperation: true, lastError: null);
    try {
      final branches = await _gateway.branches(operation.repository);
      if (!_isCurrentRepositoryOperation(operation) ||
          requestEpoch != _branchesEpoch) {
        return state.branches;
      }
      state = state.copyWith(isRunningOperation: false, branches: branches);
      return branches;
    } on Object catch (error) {
      if (!_isCurrentRepositoryOperation(operation) ||
          requestEpoch != _branchesEpoch) {
        return state.branches;
      }
      _setFailure(error, commandName: 'branch');
      state = state.copyWith(isRunningOperation: false);
      return state.branches;
    }
  }

  Future<void> _loadFileHistory(
    String repoRelativePath, {
    bool append = false,
  }) async {
    final operation = _captureRepositoryOperation();
    if (operation == null) {
      return;
    }
    final requestEpoch = ++_fileHistoryEpoch;
    final existing = append
        ? state.fileHistory.entries
        : const <GitFileHistoryEntry>[];
    state = state.copyWith(
      isRunningOperation: true,
      lastError: null,
      selectedView: GitView.fileHistory,
      fileHistory: state.fileHistory.copyWith(
        currentPath: repoRelativePath,
        isLoadingMore: append,
        selectedCommitHash: append
            ? state.fileHistory.selectedCommitHash
            : null,
        comparison: append ? state.fileHistory.comparison : null,
      ),
    );
    try {
      final page = await _gateway.fileHistory(
        operation.repository,
        repoRelativePath,
        limit: _historyPageSize + 1,
        skip: existing.length,
      );
      if (!_isCurrentRepositoryOperation(operation) ||
          requestEpoch != _fileHistoryEpoch) {
        return;
      }
      final hasMore = page.length > _historyPageSize;
      final entries = [...existing, ...page.take(_historyPageSize)];
      _knownHashes.addAll(entries.map((entry) => entry.commit.fullHash));
      state = state.copyWith(
        isRunningOperation: false,
        fileHistory: state.fileHistory.copyWith(
          entries: entries,
          currentPath: repoRelativePath,
          hasMore: hasMore,
          isLoadingMore: false,
        ),
        selectedCommitFilePath: append ? state.selectedCommitFilePath : null,
        openDiffFilePaths: append ? state.openDiffFilePaths : const [],
      );
    } on Object catch (error) {
      if (!_isCurrentRepositoryOperation(operation) ||
          requestEpoch != _fileHistoryEpoch) {
        return;
      }
      _setFailure(error, commandName: 'log');
      state = state.copyWith(
        isRunningOperation: false,
        fileHistory: state.fileHistory.copyWith(isLoadingMore: false),
      );
    }
  }

  Future<void> loadMoreFileHistory() async {
    final history = state.fileHistory;
    if (!history.hasMore ||
        history.isLoadingMore ||
        history.currentPath == null) {
      return;
    }
    await _loadFileHistory(history.currentPath!, append: true);
  }

  Future<void> _loadProjectHistory({bool append = false}) async {
    final operation = _captureRepositoryOperation();
    if (operation == null) {
      return;
    }
    final requestEpoch = ++_projectHistoryEpoch;
    final existing = append
        ? state.projectHistory.commits
        : const <GitCommitSummary>[];
    state = state.copyWith(
      isRunningOperation: true,
      lastError: null,
      selectedView: GitView.projectHistory,
      projectHistory: state.projectHistory.copyWith(
        isLoadingMore: append,
        selectedCommitHash: append
            ? state.projectHistory.selectedCommitHash
            : null,
        selectedFilePath: append ? state.projectHistory.selectedFilePath : null,
        details: append ? state.projectHistory.details : null,
        comparison: append ? state.projectHistory.comparison : null,
      ),
    );
    try {
      final page = await _gateway.history(
        operation.repository,
        limit: _historyPageSize + 1,
        skip: existing.length,
      );
      if (!_isCurrentRepositoryOperation(operation) ||
          requestEpoch != _projectHistoryEpoch) {
        return;
      }
      final hasMore = page.length > _historyPageSize;
      final commits = [...existing, ...page.take(_historyPageSize)];
      _knownHashes.addAll(commits.map((commit) => commit.fullHash));
      state = state.copyWith(
        isRunningOperation: false,
        projectHistory: state.projectHistory.copyWith(
          commits: commits,
          hasMore: hasMore,
          isLoadingMore: false,
        ),
        selectedCommitFilePath: append ? state.selectedCommitFilePath : null,
        openDiffFilePaths: append ? state.openDiffFilePaths : const [],
      );
    } on Object catch (error) {
      if (!_isCurrentRepositoryOperation(operation) ||
          requestEpoch != _projectHistoryEpoch) {
        return;
      }
      _setFailure(error, commandName: 'log');
      state = state.copyWith(
        isRunningOperation: false,
        projectHistory: state.projectHistory.copyWith(isLoadingMore: false),
      );
    }
  }

  Future<void> loadMoreProjectHistory() async {
    final history = state.projectHistory;
    if (!history.hasMore || history.isLoadingMore) {
      return;
    }
    await _loadProjectHistory(append: true);
  }

  Future<void> _loadChangedFileDiff(GitChangeSelection selection) async {
    final operation = _captureRepositoryOperation();
    if (operation == null) {
      return;
    }
    final requestEpoch = ++_diffEpoch;
    state = state.copyWith(isRunningOperation: true, lastError: null);
    try {
      final diff = switch (selection.comparison) {
        GitComparisonType.staged => _gateway.diffFile(
          operation.repository,
          selection.path,
          staged: true,
          originalRepoRelativePath: selection.originalRepoRelativePath,
        ),
        GitComparisonType.unstaged => _gateway.diffFile(
          operation.repository,
          selection.path,
          staged: false,
          originalRepoRelativePath: selection.originalRepoRelativePath,
        ),
        GitComparisonType.untracked => _gateway.diffUntrackedFile(
          operation.repository,
          selection.path,
        ),
        GitComparisonType.commitChange ||
        GitComparisonType.commitVersusCurrent => throw StateError(
          'Historical comparison cannot be loaded as a working-tree change.',
        ),
      };
      final loaded = await diff;
      if (!_isCurrentRepositoryOperation(operation) ||
          requestEpoch != _diffEpoch ||
          state.selectedChange != selection) {
        return;
      }
      state = state.copyWith(
        isRunningOperation: false,
        changeDiff: loaded,
        selectedCommitFilePath: selection.path,
        openDiffFilePaths: [selection.path],
      );
    } on Object catch (error) {
      if (!_isCurrentRepositoryOperation(operation) ||
          requestEpoch != _diffEpoch) {
        return;
      }
      _setFailure(error, commandName: 'diff');
      state = state.copyWith(isRunningOperation: false);
    }
  }

  Future<void> _loadProjectFileComparison(
    _GitRepositoryOperation operation,
    String hash,
    String repoRelativePath, {
    required int requestEpoch,
  }) async {
    try {
      final file = state.projectHistory.details?.changedFiles
          .where((candidate) => candidate.matchesPath(repoRelativePath))
          .firstOrNull;
      if (file == null) {
        state = state.copyWith(isRunningOperation: false);
        return;
      }
      final comparison = await _gateway.compareFileWithParent(
        operation.repository,
        hash,
        oldPath: file.oldPath,
        newPath: file.newPath,
      );
      if (!_isCurrentRepositoryOperation(operation) ||
          requestEpoch != _commitDetailsEpoch ||
          state.projectHistory.selectedCommitHash != hash ||
          state.projectHistory.selectedFilePath != repoRelativePath) {
        return;
      }
      final displayPath = comparison.newPath ?? comparison.oldPath;
      final openPaths = displayPath == null
          ? state.openDiffFilePaths
          : state.openDiffFilePaths.contains(displayPath)
          ? state.openDiffFilePaths
          : [...state.openDiffFilePaths, displayPath];
      state = state.copyWith(
        isRunningOperation: false,
        projectHistory: state.projectHistory.copyWith(
          comparisonType: GitComparisonType.commitChange,
          comparison: comparison,
        ),
        selectedCommitFilePath: displayPath,
        openDiffFilePaths: openPaths,
      );
    } on Object catch (error) {
      if (!_isCurrentRepositoryOperation(operation) ||
          requestEpoch != _commitDetailsEpoch) {
        return;
      }
      _setFailure(error, commandName: 'show');
      state = state.copyWith(isRunningOperation: false);
    }
  }

  Future<GitHistoricalFileComparison> _comparisonFromEmptyWorkingTree(
    GitRepositoryInfo repository,
    String currentPath,
  ) async {
    final diff = await _gateway.diffUntrackedFile(repository, currentPath);
    return GitHistoricalFileComparison(
      oldPath: null,
      newPath: diff.files.isEmpty ? null : currentPath,
      oldContent: '',
      newContent: diff.files.isEmpty ? '' : diff.fileSnapshots[currentPath],
      diff: diff,
    );
  }

  Future<void> _runPathOperation(
    List<String> repoRelativePaths,
    Future<GitOperationResult> Function(
      GitRepositoryInfo repository,
      List<String> paths,
    )
    operation,
  ) async {
    final context = _captureRepositoryOperation();
    if (context == null) {
      return;
    }
    final failure = _validation.validateRepoRelativePaths(repoRelativePaths);
    if (failure != null) {
      state = state.copyWith(lastError: failure);
      return;
    }
    await _runOperation(
      (repository) => operation(repository, repoRelativePaths),
      context: context,
    );
  }

  Future<bool> _runOperation(
    Future<GitOperationResult> Function(GitRepositoryInfo repository)
    operation, {
    _GitRepositoryOperation? context,
  }) async {
    final currentContext = context ?? _captureRepositoryOperation();
    if (currentContext == null ||
        !_isCurrentRepositoryOperation(currentContext)) {
      return false;
    }
    state = state.copyWith(isRunningOperation: true, lastError: null);
    try {
      final result = await operation(currentContext.repository);
      if (!_isCurrentRepositoryOperation(currentContext)) {
        return false;
      }
      state = state.copyWith(
        isRunningOperation: false,
        lastOperationMessage: result.message,
      );
      await refresh();
      if (!_isCurrentRepositoryOperation(currentContext)) {
        return false;
      }
      final selected = state.selectedChange;
      if (selected != null) {
        await _loadChangedFileDiff(selected);
        if (!_isCurrentRepositoryOperation(currentContext)) {
          return false;
        }
      }
      return true;
    } on Object catch (error) {
      if (!_isCurrentRepositoryOperation(currentContext)) {
        return false;
      }
      _setFailure(error, commandName: 'git');
      state = state.copyWith(isRunningOperation: false);
      return false;
    }
  }

  Future<bool> _runRootOperation(
    String rootPath,
    Future<GitOperationResult> Function(String rootPath) operation, {
    required _GitWorkspaceOperation context,
  }) async {
    if (!_isCurrentWorkspaceOperation(context)) {
      return false;
    }
    state = state.copyWith(isRunningOperation: true, lastError: null);
    try {
      final result = await operation(rootPath);
      if (!_isCurrentWorkspaceOperation(context)) {
        return false;
      }
      state = state.copyWith(
        isRunningOperation: false,
        lastOperationMessage: result.message,
      );
      await refresh();
      return _isCurrentWorkspaceOperation(context);
    } on Object catch (error) {
      if (!_isCurrentWorkspaceOperation(context)) {
        return false;
      }
      _setFailure(error, commandName: 'git');
      state = state.copyWith(isRunningOperation: false);
      return false;
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
    _workspaceEpoch++;
    _knownHashes = {};
    state = state.copyWith(
      isRefreshing: false,
      isRunningOperation: false,
      requiresWorkspaceTrust: true,
      repositoryInfo: null,
      statusSnapshot: null,
      selectedChange: null,
      changeDiff: null,
      selectedCommitFilePath: null,
      openDiffFilePaths: const [],
      fileHistory: const GitFileHistoryState(),
      projectHistory: const GitProjectHistoryState(),
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

  _GitWorkspaceOperation? _captureWorkspaceOperation() {
    final workspace = state.attachedWorkspace;
    if (workspace == null) {
      return null;
    }
    return _GitWorkspaceOperation(
      workspaceId: workspace.id,
      workspaceEpoch: _workspaceEpoch,
    );
  }

  _GitRepositoryOperation? _captureRepositoryOperation() {
    final workspace = _captureWorkspaceOperation();
    final repository = _trustedRepositoryInfo;
    if (workspace == null || repository == null) {
      return null;
    }
    return _GitRepositoryOperation(
      workspace: workspace,
      repository: repository,
    );
  }

  bool _isCurrentWorkspaceOperation(_GitWorkspaceOperation operation) {
    return _workspaceEpoch == operation.workspaceEpoch &&
        _isCurrentWorkspace(operation.workspaceId);
  }

  bool _isCurrentRepositoryOperation(_GitRepositoryOperation operation) {
    if (!_isCurrentWorkspaceOperation(operation.workspace)) {
      return false;
    }
    final repository = _trustedRepositoryInfo;
    return repository != null &&
        repository.rootPath == operation.repository.rootPath &&
        repository.gitDirPath == operation.repository.gitDirPath;
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
    if (active == null || !isMarkdownPath(active)) {
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

  GitChangeSelection? _preferredChangeSelection(String repoRelativePath) {
    final snapshot = state.statusSnapshot;
    if (snapshot == null) {
      return null;
    }
    final file = snapshot.files
        .where((candidate) => candidate.repoRelativePath == repoRelativePath)
        .firstOrNull;
    if (file == null || file.conflicted) {
      return null;
    }
    if (file.unstaged) {
      return GitChangeSelection(
        path: repoRelativePath,
        comparison: GitComparisonType.unstaged,
        originalRepoRelativePath: file.hasUnstagedRename
            ? file.originalRepoRelativePath
            : null,
      );
    }
    if (file.untracked) {
      return GitChangeSelection(
        path: repoRelativePath,
        comparison: GitComparisonType.untracked,
      );
    }
    if (file.staged) {
      return GitChangeSelection(
        path: repoRelativePath,
        comparison: GitComparisonType.staged,
        originalRepoRelativePath: file.hasStagedRename
            ? file.originalRepoRelativePath
            : null,
      );
    }
    return null;
  }

  GitChangeSelection? _reconcileChangeSelection(
    GitChangeSelection? selection,
    GitStatusSnapshot snapshot,
  ) {
    if (selection == null) {
      return null;
    }
    final file = snapshot.files
        .where((candidate) => candidate.repoRelativePath == selection.path)
        .firstOrNull;
    if (file == null || file.conflicted) {
      return null;
    }
    final stillExists = switch (selection.comparison) {
      GitComparisonType.staged => file.staged,
      GitComparisonType.unstaged => file.unstaged,
      GitComparisonType.untracked => file.untracked,
      GitComparisonType.commitChange ||
      GitComparisonType.commitVersusCurrent => false,
    };
    if (stillExists) {
      return GitChangeSelection(
        path: selection.path,
        comparison: selection.comparison,
        originalRepoRelativePath: _originalPathForComparison(
          file,
          selection.comparison,
        ),
      );
    }
    if (file.unstaged) {
      return GitChangeSelection(
        path: selection.path,
        comparison: GitComparisonType.unstaged,
        originalRepoRelativePath: file.hasUnstagedRename
            ? file.originalRepoRelativePath
            : null,
      );
    }
    if (file.untracked) {
      return GitChangeSelection(
        path: selection.path,
        comparison: GitComparisonType.untracked,
      );
    }
    if (file.staged) {
      return GitChangeSelection(
        path: selection.path,
        comparison: GitComparisonType.staged,
        originalRepoRelativePath: file.hasStagedRename
            ? file.originalRepoRelativePath
            : null,
      );
    }
    return null;
  }

  String? _originalPathForComparison(
    GitFileStatus file,
    GitComparisonType comparison,
  ) {
    return switch (comparison) {
      GitComparisonType.staged =>
        file.hasStagedRename ? file.originalRepoRelativePath : null,
      GitComparisonType.unstaged =>
        file.hasUnstagedRename ? file.originalRepoRelativePath : null,
      GitComparisonType.untracked ||
      GitComparisonType.commitChange ||
      GitComparisonType.commitVersusCurrent => null,
    };
  }

  void _setInvalidCommit(String hash) {
    state = state.copyWith(
      lastError: GitFailure(
        code: GitFailureCode.invalidPath,
        userMessageKey: 'gitErrorInvalidCommit',
        rawMessage: hash,
        commandName: 'show',
      ),
    );
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
}

class _GitWorkspaceOperation {
  const _GitWorkspaceOperation({
    required this.workspaceId,
    required this.workspaceEpoch,
  });

  final String workspaceId;
  final int workspaceEpoch;
}

class _GitRepositoryOperation {
  const _GitRepositoryOperation({
    required this.workspace,
    required this.repository,
  });

  final _GitWorkspaceOperation workspace;
  final GitRepositoryInfo repository;
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
    String? originalRepoRelativePath,
  }) => _unavailable();

  @override
  Future<GitDiff> diffUntrackedFile(
    GitRepositoryInfo repository,
    String repoRelativePath,
  ) => _unavailable();

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
  Future<List<GitFileHistoryEntry>> fileHistory(
    GitRepositoryInfo repository,
    String repoRelativePath, {
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
  Future<String?> readFileAtCommit(
    GitRepositoryInfo repository,
    String hash,
    String repoRelativePath,
  ) => _unavailable();

  @override
  Future<GitHistoricalFileComparison> compareFileWithParent(
    GitRepositoryInfo repository,
    String hash, {
    String? oldPath,
    String? newPath,
  }) => _unavailable();

  @override
  Future<GitHistoricalFileComparison> compareFileWithWorkingTree(
    GitRepositoryInfo repository,
    String hash, {
    required String historicalPath,
    required String currentPath,
  }) => _unavailable();

  @override
  Future<GitOperationResult> restoreFileFromCommit(
    GitRepositoryInfo repository,
    String hash, {
    required String historicalPath,
    required String currentPath,
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
  Future<GitOperationResult> rollbackTracked(
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
  Future<GitOperationResult> fetch(GitRepositoryInfo repository) =>
      _unavailable();

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
