import 'package:busymark/src/git/application/shared_git_presentation.dart';
import 'dart:convert';
import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/system_accent.dart';
import 'package:busymark/src/git/application/shared_git_integration.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busystack_git_flutter/busystack_git_flutter.dart' as git;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
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
      merge = true,
      short = false,
      unicode = false;
  git.GitCommit get commit => git.GitCommit(
    oid: head,
    parents: merge ? [first, second] : [first],
    subject: short
        ? 'Short commit'
        : 'Long immutable subject ${'readable commit ' * 12}',
    message: short
        ? 'Short commit'
        : 'Long immutable subject ${'readable commit ' * 12}\n\n${'Body with exact content and a long preview.\n' * 70}',
    author: unicode ? 'Zoë 宮崎 العلي' : 'Original Author',
    email: unicode
        ? '${'long-address.' * 8}author@example.invalid'
        : 'author@example.invalid',
    date: DateTime.utc(2026, 4, 5, 10, 11, 12, 345),
    committer: unicode
        ? 'Élodie コミッター'
        : sameCommitter
        ? 'Original Author'
        : 'Different Committer',
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
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
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
  testWidgets(
    'selected commit is information and its header menu owns selection',
    (tester) async {
      final semantics = tester.ensureSemantics();
      git.GitSession? session;
      List<dynamic>? entries;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('busymark/native_menus'),
        (call) async {
          if (call.method == 'show') {
            entries = (call.arguments as Map)['entries'] as List;
          }
          return call.method == 'show' ? null : true;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('busymark/native_menus'),
          null,
        ),
      );
      await tester.pumpWidget(
        _host(
          builder: (context, host) {
            session ??= git.GitSession(
              client: _ReviewClient()..short = true,
              repository: repo,
              host: host,
            );
            session!.feature.logCommit ??=
                (session!.client as _ReviewClient).commit;
            return SizedBox(
              width: 320,
              child: git.GitLogView(session: session!, inspector: true),
            );
          },
        ),
      );
      addTearDown(() => session?.dispose());
      await session!.start();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 400));
      await _ready(tester);
      final header = find.byKey(const ValueKey('git-selected-commit'));
      expect(
        tester.widget(header),
        isA<git.GitTooltip>(),
        reason: 'The subject is informational context',
      );
      expect(
        find.descendant(of: header, matching: find.byType(Icon)),
        findsNothing,
        reason: 'Informational context has no redundant title icon',
      );
      expect(
        find.ancestor(of: header, matching: find.byType(git.GitActionRow)),
        findsNothing,
        reason: 'The subject must not regain an activation surface',
      );
      expect(
        tester
            .getSemantics(find.text('Short commit'))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isFalse,
        reason:
            'The host surface must not add a no-op tap action to informational text',
      );
      final actions = find.byKey(const ValueKey('git-commit-actions'));
      final headerBounds = tester.getRect(
        find.byKey(const ValueKey('git-commit-header')),
      );
      expect(
        tester.getRect(actions).right,
        closeTo(headerBounds.right - BusyMarkSpacing.md, 1),
      );
      expect(
        tester.getRect(actions).top,
        closeTo(headerBounds.top + BusyMarkSpacing.sm, 1),
      );
      expect(
        find.descendant(of: header, matching: find.byType(git.GitButton)),
        findsNothing,
      );
      await tester.tap(actions);
      await tester.pumpAndSettle();
      expect(
        entries!.where((e) => (e as Map)['label'] == 'Select commit'),
        isEmpty,
      );
      expect(find.byKey(const ValueKey('git-commit-actions')), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
  for (final locale in ['en', 'de', 'ja', 'ar']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'short native commit details size and complete Unicode metadata $locale $scale',
        (tester) async {
          final viewport = scale == 1
              ? const Size(1200, 1000)
              : const Size(480, 720);
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final client = _ReviewClient()
            ..short = true
            ..unicode = true
            ..merge = false;
          git.GitSession? session;
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            const MethodChannel('busymark/native_menus'),
            (call) async {
              if (call.method != 'show') return true;
              final entries = (call.arguments as Map)['entries'] as List;
              return entries.indexWhere(
                (e) =>
                    (e as Map)['label'] ==
                    session!.host.message(git.GitMessages.viewCommitDetails),
              );
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
                session!.feature.logCommit ??= client.commit;
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
          await tester.tap(find.byKey(const ValueKey('git-commit-actions')));
          await tester.pumpAndSettle();
          final dialog = find.byType(git.GitNativeDialog);
          final nativeSurface = find.descendant(
            of: dialog,
            matching: find.byType(YaruBorderContainer),
          );
          final rect = tester.getRect(nativeSurface);
          expect(tester.widget<git.GitNativeDialog>(dialog).expanded, isFalse);
          expect(rect.width, lessThanOrEqualTo(BusyMarkSizes.dialogWide));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(viewport.width));
          expect(
            rect.height,
            lessThanOrEqualTo(
              viewport.height - BusyMarkSizes.modalVerticalInset * 2,
            ),
          );
          if (scale == 1) {
            expect(rect.width, lessThan(viewport.width * .6));
            expect(rect.height, lessThan(viewport.height * .75));
            final content = tester.getRect(
              find.byKey(const ValueKey('git-complete-commit-information')),
            );
            expect(
              rect.height - content.height,
              lessThan(BusyMarkSizes.iconButton + BusyMarkSpacing.lg * 4),
            );
          }
          for (final value in [
            client.commit.message,
            client.commit.author,
            client.commit.email,
            client.commit.committer,
            client.first.value,
            'refs/heads/main',
            'refs/tags/v1',
          ]) {
            final text = find.descendant(
              of: dialog,
              matching: find.text(value),
            );
            expect(text, findsOneWidget);
            await tester.ensureVisible(text);
            await tester.pumpAndSettle();
            expect(text.hitTestable(), findsOneWidget);
          }
          expect(
            find.descendant(of: dialog, matching: find.byType(git.GitButton)),
            findsNothing,
          );
          expect(
            find
                .byType(git.GitIconButton)
                .evaluate()
                .where(
                  (e) =>
                      (e.widget as git.GitIconButton).tooltip ==
                      git.GitMessages.copyText,
                ),
            isEmpty,
          );
          expect(client.mutations, isEmpty);
          expect(tester.takeException(), isNull);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(find.byType(git.GitNativeDialog), findsNothing);
          expect(
            find.byKey(const ValueKey('git-selected-commit')),
            findsOneWidget,
          );
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
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
              session!.feature.logCommit ??= client.commit;
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
                session!.feature.logCommit ??= client.commit;
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
          // Renaming a redundant icon's key must not evade the contract.
          expect(
            find.descendant(of: info, matching: find.byType(git.GitIconButton)),
            findsNothing,
          );
          final nativeSelected = find.descendant(
            of: selected,
            matching: find.byType(BusyMarkGitActionButton),
          );
          expect(nativeSelected, findsNothing);
          expect(tester.widget(selected), isA<git.GitTooltip>());
          expect(
            find.descendant(of: selected, matching: find.byType(Icon)),
            findsNothing,
          );
          expect(
            find.ancestor(
              of: selected,
              matching: find.byType(git.GitActionRow),
            ),
            findsNothing,
          );
          expect(
            find.descendant(of: selected, matching: find.byType(TextButton)),
            findsNothing,
          );
          expect(
            find.byKey(const ValueKey('git-copy-commit-id')),
            findsNothing,
          );
          expect(
            find.byKey(const ValueKey('git-commit-details')),
            findsNothing,
          );
          expect(find.text(client.head.abbreviated), findsOneWidget);
          for (final icon in session!.host.icons.values) {
            expect(icon.fontFamily, 'YaruIcons');
            expect(icon.fontPackage, 'yaru');
          }
          await tester.tap(find.byKey(const ValueKey('git-commit-actions')));
          await tester.pumpAndSettle();
          final labels = menus.last
              .where((e) => (e as Map)['separator'] != true)
              .map((e) => (e as Map)['label']);
          expect(
            labels,
            isNot(
              contains(
                session!.host.message(git.GitMessages.selectAnotherCommit),
              ),
            ),
          );
          expect(
            find.byKey(const ValueKey('git-select-another-commit')),
            findsOneWidget,
          );
          for (final message in [
            git.GitMessages.createBranch2,
            git.GitMessages.createTag,
            git.GitMessages.compareRevisions,
            git.GitMessages.openSnapshot,
            git.GitMessages.cherryPickOperation,
            git.GitMessages.revertCommit,
            git.GitMessages.interactiveRebaseAfterThisBoundary,
            git.GitMessages.resetCurrentBranch,
            git.GitMessages.copyCommitHash,
            git.GitMessages.viewCommitDetails,
            git.GitMessages.copyCommitMessage,
          ]) {
            expect(
              labels.where((l) => l == session!.host.message(message)),
              hasLength(1),
            );
          }
          choose = session!.host.message(git.GitMessages.copyCommitHash);
          await tester.tap(find.byKey(const ValueKey('git-commit-actions')));
          await tester.pumpAndSettle();
          expect(copied, client.head.value);
          choose = session!.host.message(git.GitMessages.copyCommitMessage);
          await tester.tap(find.byKey(const ValueKey('git-commit-actions')));
          await tester.pumpAndSettle();
          expect(copied, client.commit.message);
          choose = null;
          final file = git.RepoPath.text('docs/a.md');
          expect(
            find.byKey(ValueKey('git-historical-menu:${file.key}')),
            findsNothing,
          );
          final filename = find.text('a.md').first;
          final surface = find
              .ancestor(
                of: filename,
                matching: find.byType(git.NativeGitRowSurface),
              )
              .first;
          expect(
            tester.getRect(surface).left,
            greaterThanOrEqualTo(BusyMarkSpacing.sm),
          );
          await tester.tap(filename, buttons: kSecondaryMouseButton);
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
          final beforeContext = menus.length;
          await tester.tap(filename, buttons: kSecondaryMouseButton);
          await tester.pumpAndSettle();
          expect(menus.length, beforeContext + 1);
          expect(opened, hasLength(1));
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
          await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
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
          choose = session!.host.message(git.GitMessages.viewCommitDetails);
          await tester.tap(find.byKey(const ValueKey('git-commit-actions')));
          await tester.pumpAndSettle();
          final shell = tester.widget<git.GitNativeDialog>(
            find.byType(git.GitNativeDialog),
          );
          expect(shell.expanded, isFalse);
          expect(
            tester
                .getSize(
                  find.descendant(
                    of: find.byType(git.GitNativeDialog),
                    matching: find.byType(YaruBorderContainer),
                  ),
                )
                .width,
            lessThanOrEqualTo(BusyMarkSizes.dialogWide),
          );
          expect(
            tester
                .getRect(
                  find.descendant(
                    of: find.byType(git.GitNativeDialog),
                    matching: find.byType(YaruBorderContainer),
                  ),
                )
                .width,
            lessThanOrEqualTo(BusyMarkSizes.dialogWide),
          );
          expect(find.text(client.commit.message), findsOneWidget);
          expect(
            find.descendant(
              of: find.byType(git.GitNativeDialog),
              matching: find.byType(git.GitButton),
            ),
            findsNothing,
          );
          expect(
            find.descendant(
              of: find.byType(git.GitNativeDialog),
              matching: find.byType(git.GitIconButton),
            ),
            findsNothing,
          );
          expect(
            find.widgetWithText(
              git.GitButton,
              session!.host.message(git.GitMessages.copyText),
            ),
            findsNothing,
          );
          final details = find.byKey(
            const ValueKey('git-complete-commit-information'),
          );
          expect(
            find.ancestor(
              of: details,
              matching: find.byType(SingleChildScrollView),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: details,
              matching: find.byType(SingleChildScrollView),
            ),
            findsNothing,
          );
          expect(
            find.descendant(
              of: find.byType(git.GitNativeDialog),
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Semantics &&
                    widget.properties.tooltip == '2026-04-05T10:11:12.345Z',
              ),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: find.byType(git.GitNativeDialog),
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Semantics &&
                    widget.properties.tooltip == '2026-04-06T12:13:14.456Z',
              ),
            ),
            findsOneWidget,
          );
          final message = find.byKey(const ValueKey('git-commit-message'));
          await tester.tapAt(tester.getTopLeft(message) + const Offset(20, 10));
          await tester.pumpAndSettle();
          await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
          await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
          await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
          await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
          await tester.pumpAndSettle();
          expect(copied, client.commit.message);
          for (final value in [
            client.first.value,
            client.second.value,
            'refs/heads/main',
            'refs/tags/v1',
            client.commit.email,
            client.commit.committerEmail,
          ]) {
            final text = find.text(value);
            expect(text, findsOneWidget);
            await tester.ensureVisible(text);
            await tester.pumpAndSettle();
            expect(text.hitTestable(), findsOneWidget);
          }
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
