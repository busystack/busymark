import 'dart:convert';
import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/system_accent.dart';
import 'package:busymark/src/git/application/shared_git_integration.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busystack_git_flutter/busystack_git_flutter.dart' as git;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaru/yaru.dart';
import '../../../../busystack_git_flutter/test/support/presentation_fixture.dart'
    show FixtureClient, repo;

class _ReviewClient extends FixtureClient implements git.GitWorkflowClient {
  final head = git.GitOid('a' * 40),
      first = git.GitOid('b' * 40),
      second = git.GitOid('c' * 40);
  final parentReads = <git.GitOid?>[];
  var reads = 0;
  bool absent = false,
      sameCommitter = false,
      lateCommitter = false,
      merge = true;
  git.GitCommit get commit => git.GitCommit(
    oid: head,
    parents: merge ? [first, second] : [first],
    subject: 'Long immutable subject ${'readable commit ' * 12}',
    message:
        'Long immutable subject ${'readable commit ' * 12}\n\n${'Body with exact content and a long preview.\n' * 70}',
    author: 'Original Author',
    email: 'author@example.invalid',
    date: DateTime.utc(2026, 4, 5, 10, 11, 12, 345),
    committer: sameCommitter ? 'Original Author' : 'Different Committer',
    committerEmail: sameCommitter
        ? 'author@example.invalid'
        : 'committer@example.invalid',
    committerDate: sameCommitter && !lateCommitter
        ? DateTime.utc(2026, 4, 5, 10, 11, 12, 345)
        : DateTime.utc(2026, 4, 6, 12, 13, 14, 456),
  );
  @override
  Future<git.GitSnapshot> status(
    git.RepositoryId repository, {
    git.GitCancellation? cancellation,
    git.GitReadPolicy policy = git.GitReadPolicy.restricted,
  }) async {
    reads++;
    return git.GitSnapshot(
      repository: repository,
      token: 'review',
      indexToken: 'index',
      head: head,
      branch: 'main',
      changes: [
        git.GitChange(
          path: git.RepoPath.text('chapter/notes.md'),
          index: 'M',
          worktree: 'M',
        ),
      ],
      operation: const git.RepositoryOperation(git.GitOperationKind.none),
      observedAt: DateTime.utc(2026),
    );
  }

  @override
  Future<git.HistoryPage> history(
    git.RepositoryId repository, {
    git.HistoryFilter filter = const git.HistoryFilter(),
    int offset = 0,
    int limit = 100,
    String? anchor,
    git.GitCancellation? cancellation,
  }) async =>
      git.HistoryPage([commit], nextOffset: 1, hasMore: false, anchor: 'refs');
  @override
  Future<List<git.GitChange>> changedFiles(
    git.RepositoryId repository,
    git.GitOid revision, {
    git.GitOid? parent,
  }) async {
    parentReads.add(parent);
    return [
      for (final name in ['a.md', 'b.md', 'c.md'])
        git.GitChange(
          path: git.RepoPath.text('docs/$name'),
          index: 'M',
          worktree: ' ',
        ),
      git.GitChange(
        path: git.RepoPath.text('docs/renamed.md'),
        originalPath: git.RepoPath.text('old/name.md'),
        index: 'R',
        worktree: ' ',
      ),
      git.GitChange(
        path: git.RepoPath.text('other/a.md'),
        index: 'D',
        worktree: ' ',
      ),
    ];
  }

  @override
  Future<List<git.GitReference>> references(
    git.RepositoryId repository,
  ) async => [
    git.GitReference(name: 'refs/heads/main', oid: head, current: true),
    git.GitReference(name: 'refs/heads/feature', oid: first),
    git.GitReference(name: 'refs/tags/v1', oid: head),
  ];
  @override
  Future<git.GitContent> content(
    git.RepositoryId repository,
    git.RepoPath path,
    git.ContentVersion version, {
    git.GitCancellation? cancellation,
  }) async => git.GitContent(
    path: path,
    version: version,
    availability:
        absent &&
            const {
              git.ContentKind.workingTree,
              git.ContentKind.normalizedWorking,
            }.contains(version.kind)
        ? git.ContentAvailability.absent
        : git.ContentAvailability.present,
    token: version.label,
    mode:
        absent &&
            const {
              git.ContentKind.workingTree,
              git.ContentKind.normalizedWorking,
            }.contains(version.kind)
        ? '000000'
        : '100644',
    bytes:
        absent &&
            const {
              git.ContentKind.workingTree,
              git.ContentKind.normalizedWorking,
            }.contains(version.kind)
        ? []
        : utf8.encode(
            version.kind == git.ContentKind.indexVersion
                ? 'old\ncontext\n'
                : 'new\ncontext\n',
          ),
  );
  @override
  Future<git.Json> inspect(
    git.RepositoryId repository,
    git.GitInspection request, {
    git.GitCancellation? cancellation,
    void Function(git.GitProgress)? onProgress,
  }) async => {};
  @override
  Future<git.GitCreationOutcome> create(
    git.GitCreation request, {
    git.GitCancellation? cancellation,
    void Function(git.GitProgress)? onProgress,
  }) => throw StateError('No creation expected');
}

Widget _host({
  required Widget Function(BuildContext, git.GitHost) builder,
  Locale locale = const Locale('en'),
  double scale = 1,
  Brightness brightness = Brightness.light,
}) => ProviderScope(
  overrides: [
    sharedGitDraftStoreProvider.overrideWithValue(git.MemoryGitDraftStore()),
  ],
  child: MaterialApp(
    locale: locale,
    theme: buildBusyMarkTheme(
      brightness: brightness,
      accentColor: busyMarkDefaultAccentColor,
    ),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(
          size: const Size(1400, 1000),
          textScaler: TextScaler.linear(scale),
        ),
        child: Consumer(
          builder: (context, ref, _) {
            final host = busyMarkGitHost(
              context,
              ref,
              Workspace(
                id: 'log-native',
                rootPath: repo.root,
                kind: WorkspaceKind.markdownFolder,
                openedAt: DateTime.utc(2026),
                files: const [],
                diagnostics: const [],
              ),
              isMounted: () => context.mounted,
            );
            return git.GitHostScope(
              host: host,
              child: Builder(builder: (context) => builder(context, host)),
            );
          },
        ),
      ),
    ),
  ),
);

Future<void> _ready(WidgetTester tester) async {
  for (var attempt = 0; attempt < 200; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump();
    if (find.byType(git.GitLoading).evaluate().isEmpty) {
      await tester.pumpAndSettle();
      return;
    }
  }
  fail('Git content did not reach its explicit ready state');
}

void main() {
  for (final late in [false, true]) {
    testWidgets(
      'ordinary inspector avoids duplicate identical identities; changed date=$late',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final client = _ReviewClient()
          ..sameCommitter = true
          ..lateCommitter = late
          ..merge = false;
        git.GitSession? session;
        await tester.pumpWidget(
          _host(
            builder: (context, host) {
              session ??= git.GitSession(
                client: client,
                repository: repo,
                host: host,
              );
              return SizedBox(
                width: 320,
                height: 900,
                child: git.GitLogView(session: session!, inspector: true),
              );
            },
          ),
        );
        addTearDown(() => session?.dispose());
        await session!.start();
        for (
          var i = 0;
          i < 20 &&
              find
                  .byKey(const ValueKey('git-changed-files'))
                  .evaluate()
                  .isEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        await tester.pumpAndSettle();
        expect(find.textContaining('Original Author'), findsOneWidget);
        expect(
          find.textContaining('Committer · '),
          late ? findsOneWidget : findsNothing,
        );
        expect(find.textContaining('.345'), findsNothing);
        expect(find.text('Parent bbbbbbbbbb'), findsOneWidget);
        expect(find.byType(git.GitSplitter), findsNothing);
        expect(find.text('docs').hitTestable(), findsOneWidget);
        expect(client.mutations, isEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  for (final locale in ['en', 'de', 'ja', 'ar']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'actual native inspector metadata/tree/actions $locale scale $scale',
        (tester) async {
          tester.view.physicalSize = const Size(1400, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final client = _ReviewClient();
          git.GitSession? session;
          final opened = <git.GitComparison>[];
          final menus = <List<dynamic>>[];
          final anchors = <Map>[];
          String? choose, copied;
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            (call) async {
              if (call.method == 'Clipboard.setData') {
                copied = (call.arguments as Map)['text'] as String;
              }
              if (call.method == 'Clipboard.getData') {
                return {'text': copied};
              }
              return null;
            },
          );
          addTearDown(
            () => tester.binding.defaultBinaryMessenger
                .setMockMethodCallHandler(SystemChannels.platform, null),
          );
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            const MethodChannel('busymark/native_menus'),
            (call) async {
              if (call.method != 'show') return true;
              final entries = (call.arguments as Map)['entries'] as List;
              menus.add(entries);
              anchors.add((call.arguments as Map)['anchor'] as Map);
              return choose == null
                  ? null
                  : entries.indexWhere((e) => (e as Map)['label'] == choose);
            },
          );
          addTearDown(
            () =>
                tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
                  const MethodChannel('busymark/native_menus'),
                  null,
                ),
          );
          await tester.pumpWidget(
            _host(
              locale: Locale(locale),
              scale: scale,
              brightness: locale == 'ja' ? Brightness.dark : Brightness.light,
              builder: (context, host) {
                session ??= git.GitSession(
                  client: client,
                  repository: repo,
                  host: host,
                );
                return SizedBox(
                  width: 320,
                  height: 900,
                  child: git.GitLogView(
                    session: session!,
                    inspector: true,
                    onReview: (comparison, _) => opened.add(comparison),
                  ),
                );
              },
            ),
          );
          addTearDown(() => session?.dispose());
          await session!.start();
          // Advance the existing repository-reference debounce until the inspector
          // has attached its first immutable HEAD; no wall-clock race sleeps.
          for (
            var step = 0;
            step < 20 &&
                find
                    .byKey(const ValueKey('git-changed-files'))
                    .evaluate()
                    .isEmpty;
            step++
          ) {
            await tester.pump(const Duration(milliseconds: 50));
          }
          await tester.pumpAndSettle();
          final selected = find.byKey(const ValueKey('git-selected-commit'));
          final info = find.byWidgetPredicate(
            (w) =>
                w.key is PageStorageKey &&
                '${w.key}'.contains('git-commit-information:'),
          );
          final files = find.byKey(const ValueKey('git-changed-files'));
          expect(
            tester.getRect(selected).bottom,
            lessThanOrEqualTo(tester.getRect(info).top),
          );
          expect(
            tester.getRect(info).bottom,
            lessThanOrEqualTo(tester.getRect(files).top),
          );
          expect(find.byType(git.GitSplitter), findsNothing);
          expect(
            find.descendant(of: info, matching: find.byType(Scrollable)),
            findsNothing,
          );
          expect(find.textContaining(client.commit.subject), findsOneWidget);
          expect(
            tester
                .widget<Text>(find.byKey(const ValueKey('git-commit-body')))
                .maxLines,
            lessThanOrEqualTo(3),
          );
          expect(find.text('docs').hitTestable(), findsOneWidget);
          expect(
            find.text('Different Committer'),
            findsNothing,
          ); // Visible compact row includes its localized role.
          expect(find.textContaining('Different Committer'), findsOneWidget);
          final nativeSelected = find.descendant(
            of: selected,
            matching: find.byType(TextButton),
          );
          final button = tester.widget<TextButton>(nativeSelected);
          final style = Theme.of(
            tester.element(nativeSelected),
          ).textButtonTheme.style!.merge(button.style);
          for (final state in <Set<WidgetState>>[
            {},
            {WidgetState.hovered},
            {WidgetState.pressed},
            {WidgetState.focused},
            {WidgetState.disabled},
          ]) {
            expect(style.shape!.resolve(state), isA<RoundedRectangleBorder>());
          }
          expect(style.backgroundColor!.resolve({})!.a, 0);
          final copy = find.byKey(const ValueKey('git-copy-commit-id'));
          await tester.tap(copy);
          await tester.pump();
          expect(copied, client.head.value);
          await tester.tap(find.byKey(const ValueKey('git-commit-actions')));
          await tester.pumpAndSettle();
          final labels = menus.last
              .where((e) => (e as Map)['separator'] != true)
              .map((e) => (e as Map)['label']);
          for (final message in [
            git.GitMessages.createBranch2,
            git.GitMessages.createTag,
            git.GitMessages.compareRevisions,
            git.GitMessages.openSnapshot,
            git.GitMessages.cherryPickOperation,
            git.GitMessages.revertCommit,
            git.GitMessages.interactiveRebaseAfterThisBoundary,
            git.GitMessages.resetCurrentBranch,
            git.GitMessages.copyFullObjectID,
          ]) {
            expect(labels, contains(session!.host.message(message)));
          }
          final file = git.RepoPath.text('docs/a.md');
          final fileMenu = find.byKey(
            ValueKey('git-historical-menu:${file.key}'),
          );
          final filename = find.text('a.md').first;
          final surface = find
              .ancestor(
                of: filename,
                matching: find.byType(BusyMarkSidebarRowSurface),
              )
              .first;
          if (locale == 'ar') {
            expect(
              tester.getRect(fileMenu).right,
              lessThanOrEqualTo(tester.getRect(surface).left),
            );
          } else {
            expect(
              tester.getRect(surface).right,
              lessThanOrEqualTo(tester.getRect(fileMenu).left),
            );
          }
          await tester.tap(fileMenu);
          await tester.pumpAndSettle();
          expect(opened, isEmpty);
          expect(
            menus.last.where((e) => (e as Map)['separator'] != true),
            hasLength(3),
          );
          await tester.tap(filename);
          await tester.pump();
          expect(opened, hasLength(1));
          final captured = opened.single;
          final menuCount = menus.length;
          await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
          await tester.sendKeyEvent(LogicalKeyboardKey.f10);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
          await tester.pumpAndSettle();
          expect(menus.length, menuCount + 1);
          expect(opened, hasLength(1));
          final nativeRow = find.byKey(
            ValueKey('git-historical-row:file:${file.key}'),
          );
          expect(
            anchors.last['y'],
            closeTo(tester.getRect(nativeRow).bottom, 1),
          );
          final focusContext = tester.element(
            find
                .descendant(of: fileMenu, matching: find.byType(Semantics))
                .last,
          );
          Focus.of(focusContext).requestFocus();
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          expect(menus.length, menuCount + 2);
          expect(opened, hasLength(1));
          choose = session!.host.message(
            git.GitMessages.compareParentArg0Arg1,
            values: {'arg0': 2, 'arg1': client.second.abbreviated},
          );
          await tester.tap(find.byKey(const ValueKey('git-inspector-parent')));
          await tester.pumpAndSettle();
          expect(client.parentReads.last, client.second);
          expect(opened, hasLength(1));
          expect(captured.left.revision, client.first);
          await tester.tap(find.text('renamed.md'));
          await tester.pump();
          expect(opened.last.leftPath, git.RepoPath.text('old/name.md'));
          expect(opened.last.left.revision, client.second);
          await tester.tap(find.byKey(const ValueKey('git-commit-details')));
          await tester.pumpAndSettle();
          expect(find.byType(BusyMarkDialogShell), findsOneWidget);
          expect(find.text(client.commit.message), findsOneWidget);
          await tester.tap(
            find.text(session!.host.message(git.GitMessages.copyText)),
          );
          await tester.pump();
          expect(copied, client.commit.message);
          expect(
            find.textContaining('2026-04-05T10:11:12.345Z'),
            findsOneWidget,
          );
          expect(
            find.text(client.first.value),
            findsNothing,
          ); // Full parent identity has its localized role.
          expect(find.textContaining(client.first.value), findsOneWidget);
          expect(client.mutations, isEmpty);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
  for (final locale in ['en', 'de', 'ja', 'ar']) {
    for (final scale in [1.0, 2.0]) {
      for (final width in [480.0, 1000.0]) {
        testWidgets(
          'actual native two-way toolbar $locale $scale width $width',
          (tester) async {
            tester.view.physicalSize = const Size(1400, 1000);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final client = _ReviewClient();
            git.GitSession? session;
            final menus = <List<dynamic>>[];
            tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
              const MethodChannel('busymark/native_menus'),
              (call) async {
                if (call.method != 'show') return true;
                menus.add((call.arguments as Map)['entries'] as List);
                return null;
              },
            );
            addTearDown(
              () => tester.binding.defaultBinaryMessenger
                  .setMockMethodCallHandler(
                    const MethodChannel('busymark/native_menus'),
                    null,
                  ),
            );
            await tester.pumpWidget(
              _host(
                locale: Locale(locale),
                scale: scale,
                brightness: locale == 'ja' || scale == 2
                    ? Brightness.dark
                    : Brightness.light,
                builder: (context, host) {
                  session ??= git.GitSession(
                    client: client,
                    repository: repo,
                    host: host,
                  );
                  return SizedBox(
                    width: width,
                    height: 850,
                    child: git.GitDiffView(
                      session: session!,
                      showFileHeader: false,
                      comparison: git.GitComparison(
                        git.RepoPath.text('chapter/notes.md'),
                        const git.ContentVersion.index(),
                        const git.ContentVersion.working(),
                      ),
                      onPreviousFile: () {},
                      onNextFile: () {},
                    ),
                  );
                },
              ),
            );
            addTearDown(() => session?.dispose());
            await session!.start();
            await _ready(tester);
            expect(
              find.byKey(const ValueKey('git-diff-file-header')),
              findsNothing,
            );
            expect(find.byType(git.GitChoiceBar<bool>), findsNothing);
            expect(find.byType(YaruRadio<bool>), findsNothing);
            final toolbar = find.byKey(const ValueKey('git-diff-toolbar'));
            final controls = find
                .descendant(
                  of: toolbar,
                  matching: find.byType(git.GitIconButton),
                )
                .evaluate()
                .toList();
            final rect = tester.getRect(toolbar);
            for (final control in controls) {
              final box = control.renderObject! as RenderBox;
              final bounds = box.localToGlobal(Offset.zero) & box.size;
              expect(rect.contains(bounds.center), isTrue);
              expect(
                bounds.height,
                greaterThanOrEqualTo(BusyMarkSizes.iconButton),
              );
            }
            final row = tester.widget<Row>(toolbar);
            expect(row.children.whereType<Wrap>(), isEmpty);
            final regions = row.children
                .whereType<SizedBox>()
                .where((box) => box.child != null)
                .map((box) => tester.getRect(find.byWidget(box)))
                .toList();
            for (var i = 1; i < regions.length; i++) {
              expect(regions[i].center.dy, closeTo(regions.first.center.dy, 1));
              expect(regions[i].overlaps(regions[i - 1]), isFalse);
            }
            for (final paragraph
                in find
                    .descendant(of: toolbar, matching: find.byType(RichText))
                    .evaluate()) {
              final render = paragraph.renderObject! as RenderParagraph;
              expect(
                render.size.height,
                lessThanOrEqualTo(
                  MediaQuery.textScalerOf(
                        paragraph,
                      ).scale(render.text.style!.fontSize!) *
                      1.6,
                ),
              );
            }
            final mode = find.byKey(const ValueKey('git-diff-mode'));
            if (mode.evaluate().isNotEmpty) {
              await tester.tap(mode);
              await tester.pumpAndSettle();
              final checked = menus.last
                  .where((e) => (e as Map)['separator'] != true)
                  .toList();
              expect(checked, hasLength(2));
              expect((checked.first as Map)['selected'], isTrue);
              expect((checked.first as Map)['checkable'], isTrue);
              expect((checked.first as Map)['mutuallyExclusive'], isTrue);
              expect((checked.last as Map)['selected'], isFalse);
            }
            await tester.tap(find.byKey(const ValueKey('git-diff-overflow')));
            await tester.pumpAndSettle();
            expect(
              menus.last.map((e) => (e as Map)['label']),
              contains(
                session!.host.message(git.GitMessages.editIndexInThreeWayView),
              ),
            );
            expect(
              menus.last
                  .where(
                    (e) =>
                        (e as Map)['label'] ==
                        session!.host.message(
                          git.GitMessages.stageSelectedLines,
                        ),
                  )
                  .single['enabled'],
              isFalse,
            );
            expect(client.mutations, isEmpty);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox());
          },
        );
      }
    }
  }
}
