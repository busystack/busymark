import 'dart:io';
// Geometry and painted-treatment gates for the actual shared views and host.
// This file also runs against the previous sources in an isolated checkout.
import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/busymark_search_field.dart';
import 'package:busymark/src/app/system_accent.dart';
import 'package:busymark/src/git/application/shared_git_integration.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busystack_git_flutter/busystack_git_flutter.dart' as git;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../busystack_git_flutter/test/support/presentation_fixture.dart'
    show FixtureClient, repo;

class _Client extends FixtureClient implements git.GitWorkflowClient {
  _Client() {
    historyCommits = [
      git.GitCommit(
        oid: git.GitOid('a' * 40),
        parents: [git.GitOid('b' * 40)],
        subject: 'A readable selected commit',
        author: 'Author',
        email: 'a@example.invalid',
        date: DateTime(2026, 1, 1, 12),
      ),
    ];
  }
  @override
  Future<git.GitSnapshot> status(
    git.RepositoryId repository, {
    git.GitCancellation? cancellation,
    git.GitReadPolicy policy = git.GitReadPolicy.restricted,
  }) async => git.GitSnapshot(
    repository: repository,
    head: historyCommits.first.oid,
    branch: 'main',
    token: 'review',
    indexToken: 'index',
    changes: [],
    operation: const git.RepositoryOperation(git.GitOperationKind.none),
    observedAt: DateTime.utc(2026),
  );
  @override
  Future<List<git.GitReference>> references(
    git.RepositoryId repository,
  ) async => [
    for (final name in [
      'refs/heads/main',
      'refs/heads/feature',
      'refs/remotes/origin/main',
      'refs/tags/v1',
    ])
      git.GitReference(
        name: name,
        oid: historyCommits.first.oid,
        current: name == 'refs/heads/main',
      ),
  ];
  @override
  Future<git.Json> inspect(
    git.RepositoryId repository,
    git.GitInspection request, {
    git.GitCancellation? cancellation,
    void Function(git.GitProgress)? onProgress,
  }) => throw StateError('Read-only visual contract');
  @override
  Future<git.GitCreationOutcome> create(
    git.GitCreation request, {
    git.GitCancellation? cancellation,
    void Function(git.GitProgress)? onProgress,
  }) => throw StateError('Read-only visual contract');
}

Future<void> loadGitVisualFonts() async {
  for (final entry in {
    'Ubuntu': 'fonts/Ubuntu-R.ttf',
    'UbuntuMono': 'fonts/UbuntuMono-Regular.ttf',
    'YaruIcons': 'yaru_icons.otf',
  }.entries) {
    final loader = FontLoader('packages/yaru/${entry.key}');
    loader.addFont(rootBundle.load('packages/yaru/assets/${entry.value}'));
    await loader.load();
  }
}

Future<git.GitSession> mountGitVisualContract(
  WidgetTester tester,
  Widget Function(git.GitSession) view, {
  Locale locale = const Locale('en'),
  double scale = 1,
  Size size = const Size(1000, 800),
  Brightness brightness = Brightness.light,
  bool selectedCommit = true,
}) async {
  // The real Yaru titlebar paints in widget tests; only its OS-window channel
  // is provisioned here. Shipping acceptance exercises the actual GTK service.
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('yaru_window'),
    (call) async => call.method == 'state'
        ? <String, Object>{'active': true, 'closable': true}
        : null,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('yaru_window/events'),
    (_) async => null,
  );
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  git.GitSession? session;
  final client = _Client();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedGitDraftStoreProvider.overrideWithValue(
          git.MemoryGitDraftStore(),
        ),
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
              size: size,
              textScaler: TextScaler.linear(scale),
            ),
            child: Consumer(
              builder: (context, ref, _) {
                final host = busyMarkGitHost(
                  context,
                  ref,
                  Workspace(
                    id: 'geometry',
                    rootPath: repo.root,
                    kind: WorkspaceKind.markdownFolder,
                    openedAt: DateTime.utc(2026),
                    files: [],
                    diagnostics: [],
                  ),
                  isMounted: () => context.mounted,
                );
                session ??= git.GitSession(
                  client: client,
                  repository: repo,
                  host: host,
                );
                // Metadata and layout fixtures explicitly own their selection.
                if (selectedCommit) {
                  session!.feature.logCommit ??= client.historyCommits.first;
                }
                return git.GitHostScope(host: host, child: view(session!));
              },
            ),
          ),
        ),
      ),
    ),
  );
  addTearDown(() => session?.dispose());
  await session!.start();
  // The real view debounces reference reconciliation after session attachment.
  // Advance that timer before measuring commit information or opening its menu.
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
  return session!;
}

Color? _buttonPaint(WidgetTester tester, Finder button) => tester
    .widgetList<DecoratedBox>(
      find.descendant(of: button, matching: find.byType(DecoratedBox)),
    )
    .map((box) => box.decoration)
    .whereType<ShapeDecoration>()
    .map((shape) => shape.color)
    .whereType<Color>()
    .firstOrNull;

void main() {
  test(
    'workspace identity header owns navigation without Git data or workflows',
    () {
      final source = File(
        'lib/src/workspace/presentation/workspace_screen.dart',
      ).readAsStringSync();
      final header = source.substring(
        source.indexOf('class _SidebarHeader extends'),
        source.indexOf('class _SidebarHeaderRow extends'),
      );
      for (final dependency in [
        'GitRepositoryInfo',
        'GitView',
        'GitSession',
        'GitFeatureController',
        'gitControllerProvider',
      ]) {
        expect(
          header,
          isNot(contains(dependency)),
          reason:
              'The ordinary workspace header cannot own Git data or a second workflow selector.',
        );
      }
    },
  );

  setUpAll(loadGitVisualFonts);
  testWidgets(
    'history filter retains its editor and composing focus when toolbar wraps',
    (tester) async {
      await mountGitVisualContract(
        tester,
        (session) => git.GitLogView(
          session: session,
          onChooseCommit: (_) {},
          preserveActionsWhenChoosing: true,
        ),
        size: const Size(1200, 800),
      );
      final input = find.descendant(
        of: find.byKey(const ValueKey('git-history-filter-0')),
        matching: find.byType(EditableText),
      );
      await tester.tap(input);
      const value = TextEditingValue(
        text: '入力 composing',
        selection: TextSelection.collapsed(offset: 1),
        composing: TextRange(start: 0, end: 2),
      );
      tester.testTextInput.updateEditingValue(value);
      await tester.pump();
      final state = tester.state<EditableTextState>(input);
      final focus = FocusManager.instance.primaryFocus;
      tester.view.physicalSize = const Size(480, 800);
      await tester.pumpAndSettle();
      expect(tester.state<EditableTextState>(input), same(state));
      expect(FocusManager.instance.primaryFocus, same(focus));
      expect(state.widget.controller.value, value);
      expect(tester.takeException(), isNull);
    },
  );
  for (final locale in ['de', 'ja']) {
    testWidgets(
      'Branches preserves the complete search hint at enlarged text $locale',
      (tester) async {
        await mountGitVisualContract(
          tester,
          (session) => git.GitBranchesView(session: session),
          locale: Locale(locale),
          size: const Size(528, 700),
          scale: 1.5,
        );
        final field = find.byType(git.GitTextField);
        final action = find.widgetWithText(
          git.GitButton,
          locale == 'de' ? 'Neuer Branch…' : '新しいブランチ…',
        );
        final input = find.descendant(
          of: field,
          matching: find.byType(EditableText),
        );
        final editable = tester.widget<EditableText>(input);
        final hint = tester
            .widget<git.GitTextField>(field)
            .decoration!
            .labelText!;
        final painter = TextPainter(
          text: TextSpan(text: hint, style: editable.style),
          textDirection: editable.textDirection ?? TextDirection.ltr,
          textScaler: TextScaler.linear(1.5),
        )..layout();
        expect(
          tester.getSize(input).width,
          greaterThanOrEqualTo(painter.width),
        );
        expect(action, findsOneWidget);
        painter.dispose();
      },
    );
  }
  for (final brightness in Brightness.values) {
    testWidgets(
      'Branches visual acceptance rejects oversized unspaced accent actions and row menus $brightness',
      (tester) async {
        await mountGitVisualContract(
          tester,
          (session) => Column(
            children: [
              const SizedBox(
                width: 500,
                child: BusyMarkSearchField(hintText: 'Approved native search'),
              ),
              Flexible(
                child: SizedBox(
                  width: 700,
                  child: git.GitBranchesView(session: session),
                ),
              ),
            ],
          ),
          brightness: brightness,
        );
        final search = find.byType(git.GitTextField);
        final create = find.widgetWithText(git.GitButton, 'New branch…');
        final menu = find.byKey(const ValueKey('git-branch-workflows'));
        final defects = <String>[];
        final entry = tester.getRect(search),
            action = tester.getRect(create),
            actions = tester.getRect(menu);
        if (entry.height >
            tester.getSize(find.byType(BusyMarkSearchField)).height + 2) {
          defects.add('oversized search');
        }
        if (action.left - entry.right < BusyMarkSpacing.sm) {
          defects.add('missing Search/New branch gap');
        }
        if (actions.left - action.right < BusyMarkSpacing.sm) {
          defects.add('missing New branch/Actions gap');
        }
        if (action.height > 40) defects.add('oversized toolbar button');
        final colors = BusyMarkSurfaceColors.of(tester.element(create));
        if (_buttonPaint(tester, create) !=
            colors.foreground.withValues(alpha: .10)) {
          defects.add('New branch lacks native push surface');
        }
        final label = find.descendant(
          of: create,
          matching: find.text('New branch…'),
        );
        if (DefaultTextStyle.of(tester.element(label)).style.color !=
            colors.foreground) {
          defects.add('accent/link New branch foreground');
        }
        if (find
            .byWidgetPredicate(
              (w) =>
                  w is git.GitMenuButton &&
                  w.tooltip.startsWith('Actions for '),
            )
            .evaluate()
            .isNotEmpty) {
          defects.add('permanent reference action buttons');
        }
        expect(defects, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'Git Log header rejects activating subject duplicate hash and misplaced or incomplete Actions',
    (tester) async {
      List<dynamic> entries = [];
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
      await mountGitVisualContract(
        tester,
        (session) => Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(
            width: 320,
            child: git.GitLogView(session: session, inspector: true),
          ),
        ),
      );
      final header = find.byKey(const ValueKey('git-selected-commit'));
      final actions = find.byKey(const ValueKey('git-commit-actions'));
      final combinedHeader = find.byKey(const ValueKey('git-commit-header'));
      final headerBounds = tester.getRect(
        combinedHeader.evaluate().isEmpty ? header : combinedHeader,
      );
      final defects = <String>[];
      if (find
          .ancestor(of: header, matching: find.byType(git.GitActionRow))
          .evaluate()
          .isNotEmpty) {
        defects.add('clickable selected subject');
      }
      if ((tester.getRect(actions).top - headerBounds.top - BusyMarkSpacing.sm)
              .abs() >
          1) {
        defects.add('Actions outside common header action grid');
      }
      if ((headerBounds.right -
                  BusyMarkSpacing.md -
                  tester.getRect(actions).right)
              .abs() >
          1) {
        defects.add('Actions not aligned to end');
      }
      if (find.text('aaaaaaaaaa').evaluate().length != 1) {
        defects.add('duplicate or absent abbreviated hash');
      }
      await tester.tap(actions);
      await tester.pumpAndSettle();
      if (entries
          .where((e) => (e as Map)['label'] == 'Select commit')
          .isNotEmpty) {
        defects.add('duplicate Select another commit menu item');
      }
      expect(defects, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  for (final locale in ['en', 'de', 'ja', 'ar']) {
    for (final width in [480.0, 1200.0]) {
      for (final scale in [1.0, 1.5]) {
        testWidgets(
          'history toolbar has readable compact native fields and dialog actions $locale $width $scale',
          (tester) async {
            await mountGitVisualContract(
              tester,
              (session) => git.GitLogView(
                session: session,
                onChooseCommit: (_) {},
                preserveActionsWhenChoosing: true,
              ),
              locale: Locale(locale),
              size: Size(width, 850),
              scale: scale,
            );
            final toolbar = find.byKey(const ValueKey('git-history-toolbar'));
            final fields = find.descendant(
              of: toolbar,
              matching: find.byType(git.GitTextField),
            );
            final defects = <String>[];
            if (fields.evaluate().length != 3) {
              defects.add('primary filter fields hidden');
            }
            final rectangles = fields
                .evaluate()
                .map((e) => tester.getRect(find.byWidget(e.widget)))
                .toList();
            for (final rect in rectangles) {
              if (rect.height > 40 * scale ||
                  rect.width < 64 * scale ||
                  rect.left < 0 ||
                  rect.right > width) {
                defects.add('oversized/clipped filter');
              }
            }
            for (var i = 1; i < rectangles.length; i++) {
              if ((rectangles[i].top - rectangles[i - 1].top).abs() < 1 &&
                  (rectangles[i].left - rectangles[i - 1].right).abs() <
                      BusyMarkSpacing.sm &&
                  (rectangles[i - 1].left - rectangles[i].right).abs() <
                      BusyMarkSpacing.sm) {
                defects.add('missing filter gap');
              }
            }
            final affirmative = find
                .descendant(
                  of: find.byType(git.GitLogView),
                  matching: find.byType(git.GitButton),
                )
                .last;
            if (tester.getSize(affirmative).height > 40 * scale) {
              defects.add('oversized Select this commit action');
            }
            expect(defects, isEmpty);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
