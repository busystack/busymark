import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/l10n/generated/app_localizations_en.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/git/application/git_controller.dart';
import 'package:busymark/src/git/domain/git_models.dart';
import 'package:busymark/src/git/presentation/git_changes_view.dart';
import 'package:busymark/src/git/presentation/git_commit_dialog.dart';
import 'package:busymark/src/git/presentation/git_diff_viewer.dart';
import 'package:busymark/src/git/presentation/git_sidebar_tab.dart';
import 'package:busymark/src/app/system_accent.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  testWidgets('changes are grouped correctly', (tester) async {
    await tester.pumpWidget(
      _localized(
        GitCommitActions(
          commit: (_) async {},
          child: GitFileActions(
            stage: (_) {},
            unstage: (_) {},
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
    expect(find.text(l10n.gitStaged), findsOneWidget);
    expect(find.text(l10n.gitChanges), findsOneWidget);
    expect(find.text(l10n.gitUntracked), findsOneWidget);
  });

  testWidgets('commit dialog enables only with staged files and message', (
    tester,
  ) async {
    await tester.pumpWidget(
      _localized(
        GitCommitDialog(
          stagedFiles: [_file('README.md', staged: true, unstaged: false)],
          onCommit: (_) async {},
        ),
      ),
    );

    FilledButton button() {
      return tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, l10n.gitCommit),
      );
    }

    expect(button().onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'Docs');
    await tester.pump();
    expect(button().onPressed, isNotNull);
  });

  testWidgets('conflict group is visible', (tester) async {
    await tester.pumpWidget(
      _localized(
        GitCommitActions(
          commit: (_) async {},
          child: GitFileActions(
            stage: (_) {},
            unstage: (_) {},
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

GitState _state({required List<GitFileStatus> files}) {
  const repo = GitRepositoryInfo(rootPath: '/repo', gitDirPath: '/repo/.git');
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
  );
}

GitFileStatus _file(
  String path, {
  bool staged = false,
  bool unstaged = true,
  bool untracked = false,
  bool conflicted = false,
}) {
  return GitFileStatus(
    repoRelativePath: path,
    absolutePath: '/repo/$path',
    indexStatus: staged
        ? GitFileChangeStatus.modified
        : GitFileChangeStatus.unmodified,
    workTreeStatus: unstaged
        ? GitFileChangeStatus.modified
        : GitFileChangeStatus.unmodified,
    category: conflicted
        ? GitFileStatusCategory.conflicted
        : untracked
        ? GitFileStatusCategory.untracked
        : GitFileStatusCategory.modified,
    staged: staged,
    unstaged: unstaged,
    untracked: untracked,
    deleted: false,
    renamed: false,
    copied: false,
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
