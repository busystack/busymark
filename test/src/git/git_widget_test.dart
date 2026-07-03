import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/l10n/generated/app_localizations_en.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/system_accent.dart';
import 'package:busymark/src/git/application/git_controller.dart';
import 'package:busymark/src/git/domain/git_models.dart';
import 'package:busymark/src/git/presentation/git_changes_view.dart';
import 'package:busymark/src/git/presentation/git_diff_viewer.dart';
import 'package:busymark/src/git/presentation/git_sidebar_tab.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaru/yaru.dart';

void main() {
  final l10n = AppLocalizationsEn();

  testWidgets('changes are grouped correctly', (tester) async {
    await tester.pumpWidget(
      _localized(
        GitCommitActions(
          commit: (_) async {},
          child: GitFileActions(
            select: (_) {},
            unselect: (_) {},
            discard: (_) {},
            child: GitChangesView(
              state: _state(
                files: [
                  _file('conflict.md', conflicted: true),
                  _file('staged.md', staged: true, unstaged: false),
                  _file('changed.md'),
                  _file('draft.md', untracked: true),
                ],
              ),
              onSelectFile: (_) {},
              onOpenFile: (_) {},
              onConfirmDiscard: (_) async => true,
            ),
          ),
        ),
      ),
    );

    expect(find.text(l10n.gitConflicts), findsOneWidget);
    expect(find.text(l10n.gitChanges), findsOneWidget);
    expect(find.text(l10n.gitUntracked), findsOneWidget);
  });

  testWidgets('file checkboxes select files for commit', (tester) async {
    final selectedPaths = <String>[];
    final unselectedPaths = <String>[];
    await tester.pumpWidget(
      _localized(
        GitCommitActions(
          commit: (_) async {},
          child: GitFileActions(
            select: selectedPaths.addAll,
            unselect: unselectedPaths.addAll,
            discard: (_) {},
            child: GitChangesView(
              state: _state(files: [_file('changed.md')]),
              onSelectFile: (_) {},
              onOpenFile: (_) {},
              onConfirmDiscard: (_) async => true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(YaruCheckbox).last);
    await tester.pump();

    expect(selectedPaths, ['changed.md']);
    expect(unselectedPaths, isEmpty);
  });

  testWidgets('file action menu does not contain commit selection actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _localized(
        GitCommitActions(
          commit: (_) async {},
          child: GitFileActions(
            select: (_) {},
            unselect: (_) {},
            discard: (_) {},
            child: GitChangesView(
              state: _state(files: [_file('changed.md')]),
              onSelectFile: (_) {},
              onOpenFile: (_) {},
              onConfirmDiscard: (_) async => true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip(l10n.gitFileActions));
    await tester.pumpAndSettle();

    expect(find.text(l10n.gitOpenFile), findsOneWidget);
    expect(find.text(l10n.gitDiscard), findsOneWidget);
    expect(find.text(l10n.gitSelectForCommit), findsNothing);
    expect(find.text(l10n.gitRemoveFromCommit), findsNothing);
  });

  testWidgets('commit section colors files by Git status', (tester) async {
    await tester.pumpWidget(
      _localized(
        GitCommitActions(
          commit: (_) async {},
          child: GitFileActions(
            select: (_) {},
            unselect: (_) {},
            discard: (_) {},
            child: GitChangesView(
              state: _state(
                files: [
                  _file('modified.md'),
                  _file('added.md', category: GitFileStatusCategory.added),
                  _file('deleted.md', category: GitFileStatusCategory.deleted),
                  _file('draft.md', untracked: true),
                ],
              ),
              onSelectFile: (_) {},
              onOpenFile: (_) {},
              onConfirmDiscard: (_) async => true,
            ),
          ),
        ),
      ),
    );

    _expectFileColor(tester, 'modified.md', BusyMarkVcsFileColor.modified);
    _expectFileColor(tester, 'added.md', BusyMarkVcsFileColor.added);
    _expectFileColor(tester, 'deleted.md', BusyMarkVcsFileColor.deleted);
    _expectFileColor(tester, 'draft.md', BusyMarkVcsFileColor.untracked);
  });

  testWidgets('changes view commit panel commits staged files with message', (
    tester,
  ) async {
    String? committedMessage;
    await tester.pumpWidget(
      _localized(
        GitCommitActions(
          commit: (message) async => committedMessage = message,
          child: GitFileActions(
            select: (_) {},
            unselect: (_) {},
            discard: (_) {},
            child: GitChangesView(
              state: _state(
                files: [_file('README.md', staged: true, unstaged: false)],
              ),
              onSelectFile: (_) {},
              onOpenFile: (_) {},
              onConfirmDiscard: (_) async => true,
            ),
          ),
        ),
      ),
    );

    expect(find.text(l10n.gitCommitMessage), findsOneWidget);
    await tester.tap(find.text(l10n.gitCommit));
    await tester.pump();
    expect(committedMessage, isNull);
    await tester.enterText(find.byType(TextField), 'Docs');
    await tester.pump();
    await tester.tap(find.text(l10n.gitCommit));
    await tester.pump();
    expect(committedMessage, 'Docs');
  });

  testWidgets('conflict group is visible', (tester) async {
    await tester.pumpWidget(
      _localized(
        GitCommitActions(
          commit: (_) async {},
          child: GitFileActions(
            select: (_) {},
            unselect: (_) {},
            discard: (_) {},
            child: GitChangesView(
              state: _state(files: [_file('conflict.md', conflicted: true)]),
              onSelectFile: (_) {},
              onOpenFile: (_) {},
              onConfirmDiscard: (_) async => true,
            ),
          ),
        ),
      ),
    );

    expect(find.text(l10n.gitConflicts), findsOneWidget);
    expect(find.text('conflict.md'), findsOneWidget);
  });

  testWidgets('Git unavailable empty state is shown', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: _localized(
          GitSidebarTab(
            workspace: _workspace(),
            onOpenFile: (_) {},
            onConfirmDiscard: (_) async => true,
            onAfterWorkspaceFilesChanged: () async {},
            onConfirmSwitchBranch: (_) async => true,
            onConfirmPushSetUpstream: () async => true,
          ),
        ),
      ),
    );

    expect(find.text(l10n.gitUnavailableTitle), findsOneWidget);
  });

  testWidgets('repository strip shows branch once with compact sync state', (
    tester,
  ) async {
    const repo = GitRepositoryInfo(
      rootPath: '/repo',
      gitDirPath: '/repo/.git',
      currentBranch: 'main',
      upstreamBranch: 'origin/main',
      hasRemote: true,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gitControllerProvider.overrideWith(
            () => _PresetGitController(_state(files: const [], repo: repo)),
          ),
        ],
        child: _localized(
          GitSidebarTab(
            workspace: _workspace(),
            onOpenFile: (_) {},
            onConfirmDiscard: (_) async => true,
            onAfterWorkspaceFilesChanged: () async {},
            onConfirmSwitchBranch: (_) async => true,
            onConfirmPushSetUpstream: () async => true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('main'), findsOneWidget);
    expect(find.textContaining('origin/main'), findsNothing);
    expect(find.textContaining('origin -'), findsNothing);
    expect(find.text(l10n.gitClean), findsAtLeastNWidgets(1));
  });

  testWidgets(
    'repository strip branch dropdown lists branches and new action',
    (tester) async {
      const repo = GitRepositoryInfo(
        rootPath: '/repo',
        gitDirPath: '/repo/.git',
        currentBranch: 'main',
        upstreamBranch: 'origin/main',
        hasRemote: true,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gitControllerProvider.overrideWith(
              () => _PresetGitController(
                _state(
                  files: const [],
                  repo: repo,
                  branches: const [
                    GitBranch(name: 'main', current: true),
                    GitBranch(name: 'docs', current: false),
                  ],
                ),
              ),
            ),
          ],
          child: _localized(
            GitSidebarTab(
              workspace: _workspace(),
              onOpenFile: (_) {},
              onConfirmDiscard: (_) async => true,
              onAfterWorkspaceFilesChanged: () async {},
              onConfirmSwitchBranch: (_) async => true,
              onConfirmPushSetUpstream: () async => true,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byTooltip(l10n.gitBranches));
      await tester.pumpAndSettle();

      expect(find.text('docs'), findsOneWidget);
      expect(find.text(l10n.gitNewBranch), findsOneWidget);
      expect(find.text(l10n.gitPull), findsOneWidget);
      expect(find.text(l10n.gitPush), findsOneWidget);
      expect(
        tester.getTopLeft(find.text(l10n.gitPull)).dy,
        lessThan(tester.getTopLeft(find.text(l10n.gitPush)).dy),
      );
      expect(
        tester.getTopLeft(find.text(l10n.gitPush)).dy,
        lessThan(tester.getTopLeft(find.text(l10n.gitNewBranch)).dy),
      );
      expect(
        tester.getTopLeft(find.text(l10n.gitNewBranch)).dy,
        lessThan(tester.getTopLeft(find.text('docs')).dy),
      );

      await tester.tap(find.text(l10n.gitNewBranch));
      await tester.pumpAndSettle();

      expect(find.text(l10n.gitBranchName), findsOneWidget);
    },
  );

  testWidgets(
    'repository strip describes unpushed commits without Git jargon',
    (tester) async {
      const repo = GitRepositoryInfo(
        rootPath: '/repo',
        gitDirPath: '/repo/.git',
        currentBranch: 'main',
        upstreamBranch: 'origin/main',
        aheadCount: 2,
        hasRemote: true,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gitControllerProvider.overrideWith(
              () => _PresetGitController(_state(files: const [], repo: repo)),
            ),
          ],
          child: _localized(
            GitSidebarTab(
              workspace: _workspace(),
              onOpenFile: (_) {},
              onConfirmDiscard: (_) async => true,
              onAfterWorkspaceFilesChanged: () async {},
              onConfirmSwitchBranch: (_) async => true,
              onConfirmPushSetUpstream: () async => true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(l10n.gitAheadCount(2)), findsOneWidget);
      expect(find.textContaining('2 ahead'), findsNothing);
    },
  );

  testWidgets('dirty editor banner appears in diff viewer', (tester) async {
    await tester.pumpWidget(
      _localized(
        GitDiffViewer(
          diff: const GitDiff(
            title: 'README.md',
            files: [],
            rawPatch: '',
            hasBinaryFiles: false,
          ),
          hasUnsavedEditorChanges: true,
          onOpenFile: (_) {},
          onClose: () {},
        ),
      ),
    );

    expect(find.text(l10n.gitUnsavedChangesBanner), findsOneWidget);
  });
}

Widget _localized(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildBusyMarkTheme(
      brightness: Brightness.light,
      accentColor: busyMarkDefaultAccentColor,
    ),
    home: Scaffold(body: child),
  );
}

void _expectFileColor(
  WidgetTester tester,
  String fileName,
  BusyMarkVcsFileColor color,
) {
  final finder = find.text(fileName);
  final context = tester.element(finder);
  final widget = tester.widget<Text>(finder);
  expect(widget.style?.color, busyMarkVcsFileStatusColor(context, color));
}

GitState _state({
  required List<GitFileStatus> files,
  GitRepositoryInfo repo = const GitRepositoryInfo(
    rootPath: '/repo',
    gitDirPath: '/repo/.git',
  ),
  List<GitBranch> branches = const [],
}) {
  return GitState(
    availability: const GitAvailability(
      available: true,
      executablePath: '/usr/bin/git',
      version: '2.50.0',
    ),
    repositoryInfo: repo,
    statusSnapshot: GitStatusSnapshot(
      repositoryInfo: repo.copyWith(
        hasConflicts: files.any((file) => file.conflicted),
      ),
      files: files,
    ),
    branches: branches,
  );
}

GitFileStatus _file(
  String path, {
  bool staged = false,
  bool unstaged = true,
  bool untracked = false,
  bool conflicted = false,
  GitFileStatusCategory? category,
}) {
  final resolvedCategory =
      category ??
      (conflicted
          ? GitFileStatusCategory.conflicted
          : untracked
          ? GitFileStatusCategory.untracked
          : GitFileStatusCategory.modified);
  return GitFileStatus(
    repoRelativePath: path,
    absolutePath: '/repo/$path',
    indexStatus: staged
        ? GitFileChangeStatus.modified
        : GitFileChangeStatus.unmodified,
    workTreeStatus: unstaged
        ? GitFileChangeStatus.modified
        : GitFileChangeStatus.unmodified,
    category: resolvedCategory,
    staged: staged,
    unstaged: unstaged,
    untracked: untracked,
    deleted: resolvedCategory == GitFileStatusCategory.deleted,
    renamed: resolvedCategory == GitFileStatusCategory.renamed,
    copied: resolvedCategory == GitFileStatusCategory.copied,
    conflicted: conflicted,
    ignored: false,
  );
}

Workspace _workspace() {
  return Workspace(
    id: '/repo',
    rootPath: '/repo',
    kind: WorkspaceKind.markdownFolder,
    openedAt: DateTime(2026),
    files: const [],
    diagnostics: const [],
  );
}

class _PresetGitController extends GitController {
  _PresetGitController(this.initialState);

  final GitState initialState;

  @override
  GitState build() => initialState;

  @override
  Future<List<GitBranch>> loadBranches() async => state.branches;
}
