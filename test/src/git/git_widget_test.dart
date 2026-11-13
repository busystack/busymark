import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/l10n/generated/app_localizations_en.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/system_accent.dart';
import 'package:busymark/src/editor/source/source_read_only_view.dart';
import 'package:busymark/src/git/domain/git_models.dart';
import 'package:busymark/src/git/presentation/git_diff_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
            openFilePath: 'README.md',
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

  testWidgets('diff open action requires an explicit working-tree target', (
    tester,
  ) async {
    await tester.pumpWidget(
      _localized(
        GitDiffViewer(
          diff: GitDiff(
            title: 'historical.md',
            files: [_diffFile('historical.md', 'Historical change')],
            rawPatch: '',
            hasBinaryFiles: false,
          ),
          hasUnsavedEditorChanges: false,
          onOpenFile: (_) {},
          onClose: () {},
        ),
      ),
    );

    expect(find.byTooltip(l10n.gitOpenFile), findsNothing);
  });

  testWidgets('diff open action uses the explicit current path', (
    tester,
  ) async {
    String? openedPath;
    await tester.pumpWidget(
      _localized(
        GitDiffViewer(
          diff: GitDiff(
            title: 'old.md',
            files: [_diffFile('old.md', 'Historical change')],
            rawPatch: '',
            hasBinaryFiles: false,
          ),
          hasUnsavedEditorChanges: false,
          openFilePath: 'current.md',
          onOpenFile: (path) => openedPath = path,
          onClose: () {},
        ),
      ),
    );

    await tester.tap(find.byTooltip(l10n.gitOpenFile));
    await tester.pump();

    expect(openedPath, 'current.md');
  });

  testWidgets('embedded diff keeps rename paths visible', (tester) async {
    await tester.pumpWidget(
      _localized(
        GitDiffViewer(
          diff: const GitDiff(
            title: 'new.md',
            files: [
              GitDiffFile(
                oldPath: 'old.md',
                newPath: 'new.md',
                status: GitDiffFileStatus.renamed,
                hunks: [],
                binary: false,
                additions: 0,
                deletions: 0,
              ),
            ],
            rawPatch: '',
            hasBinaryFiles: false,
            fileSnapshots: {'new.md': '# Renamed\n'},
          ),
          hasUnsavedEditorChanges: false,
          showHeader: false,
          showFileHeaders: false,
          showCloseButton: false,
          showFileActions: false,
          onOpenFile: (_) {},
          onClose: () {},
        ),
      ),
    );

    expect(find.text('old.md → new.md'), findsOneWidget);
  });

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

  testWidgets('deleted diff shows the complete removed file snapshot', (
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
                status: GitDiffFileStatus.deleted,
                hunks: [],
                binary: false,
                additions: 0,
                deletions: 3,
              ),
            ],
            rawPatch: '',
            hasBinaryFiles: false,
            fileSnapshots: {
              'README.md': '# Removed\n\nComplete old document.\n',
            },
          ),
          hasUnsavedEditorChanges: false,
          onOpenFile: (_) {},
          onClose: () {},
        ),
      ),
    );

    final source = tester.widget<BusyMarkReadOnlySourceLines>(
      find.byType(BusyMarkReadOnlySourceLines),
    );
    expect(source.lines.map((line) => line.text), [
      '# Removed',
      '',
      'Complete old document.',
    ]);
    expect(
      source.lines.every(
        (line) => line.tone == BusyMarkReadOnlySourceLineTone.removed,
      ),
      isTrue,
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
