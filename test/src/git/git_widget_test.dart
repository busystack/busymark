import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/l10n/generated/app_localizations_de.dart';
import 'package:busymark/l10n/generated/app_localizations_en.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/system_accent.dart';
import 'package:busymark/src/editor/source/source_read_only_view.dart';
import 'package:busymark/src/git/application/git_controller.dart';
import 'package:busymark/src/git/domain/git_models.dart';
import 'package:busymark/src/git/presentation/git_changes_view.dart';
import 'package:busymark/src/git/presentation/git_diff_viewer.dart';
import 'package:busymark/src/git/presentation/git_history_view.dart';
import 'package:busymark/src/git/presentation/git_sidebar_tab.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaru/yaru.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('hunk range text hides raw unified diff markers', () {
    const hunk = GitDiffHunk(
      oldStart: 1,
      oldCount: 5,
      newStart: 1,
      newCount: 6,
      heading: 'git checkout abcdef0',
      lines: [],
    );

    final text = gitDiffHunkRangeText(
      hunk,
      format: l10n.gitDiffHunkRange,
      noLinesText: l10n.gitDiffNoLines,
    );
    expect(text, 'old 1-5 → new 1-6');
    expect(text, isNot(contains('@@')));
    expect(text, isNot(contains('git checkout abcdef0')));
  });

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
    expect(find.byType(YaruCheckbox), findsNWidgets(4));
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

    final fileCheckbox = find.byType(YaruCheckbox).last;
    final checkboxSize = tester.getSize(fileCheckbox);
    expect(checkboxSize.width, greaterThanOrEqualTo(32));
    expect(checkboxSize.height, greaterThanOrEqualTo(32));

    await tester.tap(fileCheckbox);
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
    final commitField = tester.widget<TextField>(find.byType(TextField));
    expect(commitField.decoration?.border, isNull);
    expect(commitField.decoration?.filled, isNull);
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

  testWidgets('untrusted workspace shows repository trust prompt', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gitControllerProvider.overrideWith(
            () => _PresetGitController(
              _state(files: const [], requiresWorkspaceTrust: true),
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

    expect(find.text(l10n.gitTrustRequiredTitle), findsOneWidget);
    expect(find.text(l10n.gitTrustRequiredMessage), findsOneWidget);
    expect(find.text(l10n.gitTrustWorkspace), findsOneWidget);
  });

  testWidgets('commit view shows no repository sync strip when clean', (
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

    expect(find.text('main'), findsNothing);
    expect(find.textContaining('origin/main'), findsNothing);
    expect(find.textContaining('origin -'), findsNothing);
    expect(find.text(l10n.gitClean), findsNothing);
    expect(find.text(l10n.gitNoChanges), findsOneWidget);
  });

  testWidgets('commit view does not show branch dropdown', (tester) async {
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

    expect(find.byTooltip(l10n.gitBranches), findsNothing);
    expect(find.text('main'), findsNothing);
    expect(find.text('docs'), findsNothing);
  });

  testWidgets('commit view does not describe branch sync state', (
    tester,
  ) async {
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

    expect(find.text(l10n.gitAheadCount(2)), findsNothing);
    expect(find.textContaining('2 ahead'), findsNothing);
    expect(find.text(l10n.gitNoChanges), findsOneWidget);
  });

  testWidgets('history view does not show project or current file controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      _localized(
        GitHistoryView(
          state: _state(files: const [], scopedFilePath: 'docs/topic.md'),
          onSelectCommit: (_) {},
          onShowFileDiff: (_) {},
        ),
      ),
    );

    expect(find.text(l10n.gitProjectHistory), findsNothing);
    expect(find.text(l10n.gitFileHistory), findsNothing);
    expect(find.byType(BusyMarkHeaderIconButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets('project history file rows show selected file diff', (
    tester,
  ) async {
    final de = AppLocalizationsDe();
    final commit = GitCommitSummary(
      fullHash: '1234567890abcdef',
      shortHash: '1234567',
      authorName: 'BusyMark Test',
      authorEmail: 'busymark@example.com',
      authorDate: DateTime(2026),
      subject: 'Update docs',
      parentHashes: [],
    );
    final diff = GitDiff(
      title: 'Update docs',
      files: [
        _diffFile('README.md', 'Readme change'),
        _diffFile('guide.md', 'Guide change'),
      ],
      rawPatch: '',
      hasBinaryFiles: false,
    );
    var state = _state(
      files: const [],
      selectedView: GitView.history,
      history: [commit],
      selectedCommitHash: commit.fullHash,
      selectedCommitFilePath: 'README.md',
      openDiffFilePaths: const ['README.md'],
      selectedDiff: diff,
    );

    await tester.pumpWidget(
      _localized(
        StatefulBuilder(
          builder: (context, setState) {
            return Row(
              children: [
                SizedBox(
                  width: 320,
                  child: GitHistoryView(
                    state: state,
                    onSelectCommit: (_) {},
                    onShowFileDiff: (path) {
                      setState(() {
                        state = state.copyWith(
                          selectedCommitFilePath: path,
                          openDiffFilePaths:
                              state.openDiffFilePaths.contains(path)
                              ? state.openDiffFilePaths
                              : [...state.openDiffFilePaths, path],
                        );
                      });
                    },
                  ),
                ),
                Expanded(
                  child: GitDiffViewer(
                    diff: state.selectedDiffForDisplay,
                    hasUnsavedEditorChanges: false,
                    onOpenFile: (_) {},
                    onClose: () {},
                  ),
                ),
              ],
            );
          },
        ),
        locale: const Locale('de'),
      ),
    );

    expect(find.text('README.md'), findsAtLeastNWidgets(1));
    expect(find.text('guide.md'), findsOneWidget);
    expect(
      find.textContaining('Readme change', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Guide change', findRichText: true),
      findsNothing,
    );

    await tester.tap(find.text('guide.md'));
    await tester.pump();

    expect(state.openDiffFilePaths, ['README.md', 'guide.md']);
    expect(
      find.textContaining('Guide change', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Readme change', findRichText: true),
      findsNothing,
    );

    await tester.tap(
      find.text('README.md').first,
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();

    expect(find.text(de.gitShowDiff), findsOneWidget);

    await tester.tap(find.text(de.gitShowDiff));
    await tester.pump();

    expect(state.openDiffFilePaths, ['README.md', 'guide.md']);
    expect(
      find.textContaining('Readme change', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Guide change', findRichText: true),
      findsNothing,
    );
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

  testWidgets(
    'embedded diff hides duplicate file header but keeps open action',
    (tester) async {
      String? openedPath;
      await tester.pumpWidget(
        _localized(
          GitDiffViewer(
            diff: GitDiff(
              title: 'README.md',
              files: [_diffFile('README.md', 'Readme change')],
              rawPatch: '',
              hasBinaryFiles: false,
            ),
            hasUnsavedEditorChanges: false,
            showHeader: false,
            showFileHeaders: false,
            showCloseButton: false,
            onOpenFile: (path) => openedPath = path,
            onClose: () {},
          ),
        ),
      );

      expect(find.text('README.md'), findsNothing);
      expect(find.byTooltip(l10n.gitOpenFile), findsOneWidget);

      await tester.tap(find.byTooltip(l10n.gitOpenFile));
      await tester.pump();

      expect(openedPath, 'README.md');
    },
  );

  testWidgets('diff viewer renders patch rows with shared source view', (
    tester,
  ) async {
    await tester.pumpWidget(
      _localized(
        GitDiffViewer(
          diff: GitDiff(
            title: 'README.md',
            files: [_diffFile('README.md', '**Readme** change')],
            rawPatch: '',
            hasBinaryFiles: false,
          ),
          hasUnsavedEditorChanges: false,
          onOpenFile: (_) {},
          onClose: () {},
        ),
      ),
    );

    expect(find.byType(BusyMarkReadOnlySourceLines), findsOneWidget);
    final sourceLines = tester.widget<BusyMarkReadOnlySourceLines>(
      find.byType(BusyMarkReadOnlySourceLines),
    );
    expect(sourceLines.textStyle?.fontSize, BusyMarkTypography.defaultFontSize);
    expect(
      sourceLines.padding,
      const EdgeInsets.only(bottom: BusyMarkSourceEditorMetrics.paddingBottom),
    );
    expect(
      find.textContaining('**Readme** change', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        l10n.gitDiffHunkRange(l10n.gitDiffNoLines, '1'),
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(find.textContaining('@@', findRichText: true), findsNothing);
  });

  testWidgets('embedded diff can hide hunk headers and file action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _localized(
        GitDiffViewer(
          diff: GitDiff(
            title: 'README.md',
            files: [_diffFile('README.md', 'Readme change')],
            rawPatch: '',
            hasBinaryFiles: false,
          ),
          hasUnsavedEditorChanges: false,
          showFileActions: false,
          showHunkHeaders: false,
          onOpenFile: (_) {},
          onClose: () {},
        ),
      ),
    );

    expect(
      find.textContaining(
        l10n.gitDiffHunkRange(l10n.gitDiffNoLines, '1'),
        findRichText: true,
      ),
      findsNothing,
    );
    expect(find.textContaining('@@', findRichText: true), findsNothing);
    expect(find.byTooltip(l10n.gitOpenFile), findsNothing);
    expect(
      find.textContaining('Readme change', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('diff viewer source uses full file snapshot when available', (
    tester,
  ) async {
    await tester.pumpWidget(
      _localized(
        GitDiffViewer(
          diff: GitDiff(
            title: 'README.md',
            files: [
              _diffFile(
                'README.md',
                'new heading',
                oldContent: 'old heading',
                hunkHeading: 'git checkout abcdef0',
              ),
            ],
            rawPatch: '',
            hasBinaryFiles: false,
            fileSnapshots: const {
              'README.md': 'new heading\n\nunchanged after change\n',
            },
          ),
          hasUnsavedEditorChanges: false,
          onOpenFile: (_) {},
          onClose: () {},
        ),
      ),
    );

    expect(find.byType(BusyMarkReadOnlySourceLines), findsOneWidget);
    expect(
      find.textContaining('@@ -1,1 +1,1 @@', findRichText: true),
      findsNothing,
    );
    expect(
      find.textContaining('git checkout abcdef0', findRichText: true),
      findsNothing,
    );
    expect(
      find.textContaining('old heading', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('new heading', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('unchanged after change', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('diff viewer scrolls to the first source change on open', (
    tester,
  ) async {
    final lines = List.generate(120, (index) => 'unchanged line ${index + 1}');
    lines[89] = 'changed target line';

    await tester.pumpWidget(
      _localized(
        SizedBox(
          height: 220,
          child: GitDiffViewer(
            diff: GitDiff(
              title: 'README.md',
              files: const [
                GitDiffFile(
                  oldPath: 'README.md',
                  newPath: 'README.md',
                  status: GitDiffFileStatus.modified,
                  hunks: [
                    GitDiffHunk(
                      oldStart: 90,
                      oldCount: 1,
                      newStart: 90,
                      newCount: 1,
                      heading: '',
                      lines: [
                        GitDiffLine(
                          kind: GitDiffLineKind.removed,
                          content: 'old target line',
                          oldLineNumber: 90,
                        ),
                        GitDiffLine(
                          kind: GitDiffLineKind.added,
                          content: 'changed target line',
                          newLineNumber: 90,
                        ),
                      ],
                    ),
                  ],
                  binary: false,
                  additions: 1,
                  deletions: 1,
                ),
              ],
              rawPatch: '',
              hasBinaryFiles: false,
              fileSnapshots: {'README.md': lines.join('\n')},
            ),
            hasUnsavedEditorChanges: false,
            showChangeNavigator: true,
            onOpenFile: (_) {},
            onClose: () {},
          ),
        ),
      ),
    );

    final listView = tester.widget<ListView>(find.byType(ListView));
    expect(listView.controller?.offset, 0);

    await tester.pump();
    await tester.pump();
    await tester.pump(BusyMarkMotion.scroll);

    expect(listView.controller?.offset, greaterThan(0));
  });

  testWidgets('diff viewer source rows use configured editor font size', (
    tester,
  ) async {
    await tester.pumpWidget(
      _localized(
        GitDiffViewer(
          diff: GitDiff(
            title: 'README.md',
            files: [_diffFile('README.md', 'Readme change')],
            rawPatch: '',
            hasBinaryFiles: false,
          ),
          hasUnsavedEditorChanges: false,
          editorFontSize: 19,
          onOpenFile: (_) {},
          onClose: () {},
        ),
      ),
    );

    final sourceLines = tester.widget<BusyMarkReadOnlySourceLines>(
      find.byType(BusyMarkReadOnlySourceLines),
    );
    expect(sourceLines.textStyle?.fontSize, 19);
  });

  testWidgets('diff context lines show old and new number columns', (
    tester,
  ) async {
    await tester.pumpWidget(
      _localized(
        GitDiffViewer(
          diff: const GitDiff(
            title: 'README.md',
            files: [
              GitDiffFile(
                oldPath: 'README.md',
                newPath: 'README.md',
                status: GitDiffFileStatus.modified,
                hunks: [
                  GitDiffHunk(
                    oldStart: 7,
                    oldCount: 1,
                    newStart: 7,
                    newCount: 1,
                    heading: '',
                    lines: [
                      GitDiffLine(
                        kind: GitDiffLineKind.context,
                        content: 'unchanged',
                        oldLineNumber: 7,
                        newLineNumber: 7,
                      ),
                    ],
                  ),
                ],
                binary: false,
                additions: 0,
                deletions: 0,
              ),
            ],
            rawPatch: '',
            hasBinaryFiles: false,
          ),
          hasUnsavedEditorChanges: false,
          onOpenFile: (_) {},
          onClose: () {},
        ),
      ),
    );

    expect(find.text('7'), findsNWidgets(2));
    expect(
      find.textContaining('unchanged', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('diff line numbers use source gutter geometry', (tester) async {
    await tester.pumpWidget(
      _localized(
        GitDiffViewer(
          diff: const GitDiff(
            title: 'README.md',
            files: [
              GitDiffFile(
                oldPath: 'README.md',
                newPath: 'README.md',
                status: GitDiffFileStatus.modified,
                hunks: [
                  GitDiffHunk(
                    oldStart: 7,
                    oldCount: 1,
                    newStart: 8,
                    newCount: 1,
                    heading: '',
                    lines: [
                      GitDiffLine(
                        kind: GitDiffLineKind.removed,
                        content: 'old line',
                        oldLineNumber: 7,
                      ),
                      GitDiffLine(
                        kind: GitDiffLineKind.added,
                        content: 'new line',
                        newLineNumber: 8,
                      ),
                    ],
                  ),
                ],
                binary: false,
                additions: 1,
                deletions: 1,
              ),
            ],
            rawPatch: '',
            hasBinaryFiles: false,
          ),
          hasUnsavedEditorChanges: false,
          onOpenFile: (_) {},
          onClose: () {},
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.text('7')).dx,
      lessThan(tester.getTopLeft(find.text('8')).dx),
    );
    final removedRow = find.ancestor(
      of: find.textContaining('old line', findRichText: true),
      matching: find.byType(BusyMarkReadOnlySourceLineRow),
    );
    final rowLeft = tester.getTopLeft(removedRow).dx;
    expect(
      tester.getCenter(find.text('7')).dx,
      closeTo(rowLeft + BusyMarkReadOnlySourceLineRow.gutterWidth / 4, 1.0),
    );
    expect(
      tester.getTopLeft(find.textContaining('old line', findRichText: true)).dx,
      closeTo(
        rowLeft +
            BusyMarkReadOnlySourceLineRow.gutterWidth +
            BusyMarkStroke.hairline +
            BusyMarkSourceEditorMetrics.paddingLeft,
        0.1,
      ),
    );
  });
}

Widget _localized(Widget child, {Locale? locale}) {
  return MaterialApp(
    locale: locale,
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
  String? scopedFilePath,
  GitView selectedView = GitView.changes,
  List<GitCommitSummary> history = const [],
  String? historyFilePath,
  String? selectedCommitHash,
  String? selectedCommitFilePath,
  List<String> openDiffFilePaths = const [],
  GitDiff? selectedDiff,
  bool requiresWorkspaceTrust = false,
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
    scopedFilePath: scopedFilePath,
    selectedView: selectedView,
    history: history,
    historyFilePath: historyFilePath,
    selectedCommitHash: selectedCommitHash,
    selectedCommitFilePath: selectedCommitFilePath,
    openDiffFilePaths: openDiffFilePaths,
    selectedDiff: selectedDiff,
    requiresWorkspaceTrust: requiresWorkspaceTrust,
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

GitDiffFile _diffFile(
  String path,
  String content, {
  String? oldContent,
  String hunkHeading = '',
}) {
  final hasOldContent = oldContent != null;
  return GitDiffFile(
    oldPath: path,
    newPath: path,
    status: GitDiffFileStatus.modified,
    hunks: [
      GitDiffHunk(
        oldStart: 1,
        oldCount: hasOldContent ? 1 : 0,
        newStart: 1,
        newCount: 1,
        heading: hunkHeading,
        lines: [
          if (oldContent != null)
            GitDiffLine(
              kind: GitDiffLineKind.removed,
              content: oldContent,
              oldLineNumber: 1,
            ),
          GitDiffLine(
            kind: GitDiffLineKind.added,
            content: content,
            newLineNumber: 1,
          ),
        ],
      ),
    ],
    binary: false,
    additions: 1,
    deletions: hasOldContent ? 1 : 0,
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
