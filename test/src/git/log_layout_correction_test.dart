import 'package:busymark/src/git/application/shared_git_presentation.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/busymark_glyphs.dart';
import 'package:busymark/src/app/linux/linux_header_style.dart';
import 'package:busystack_git_flutter/busystack_git_flutter.dart' as git;
import 'package:busystack_git_flutter/src/historical_change_tree.dart'
    show GitHistoricalChangeTree;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../busystack_git_flutter/test/support/presentation_fixture.dart'
    show FixtureClient;
import 'package:flutter_test/flutter_test.dart';
import 'package:yaru/yaru.dart';

import 'git_navigation_visual_contract_test.dart'
    show mountGitVisualContract, loadGitVisualFonts;

void main() {
  setUpAll(loadGitVisualFonts);
  testWidgets(
    'inspector exposes one dedicated commit selector beside Actions',
    (tester) async {
      await mountGitVisualContract(
        tester,
        (session) => SizedBox(
          width: 300,
          child: git.GitLogView(session: session, inspector: true),
        ),
      );
      final choose = find.byKey(const ValueKey('git-select-another-commit'));
      final actions = find.byKey(const ValueKey('git-commit-actions'));
      expect(choose, findsOneWidget);
      expect(
        tester.getRect(actions).left - tester.getRect(choose).right,
        BusyMarkSpacing.xs,
      );
      expect(tester.getRect(actions).right, 300 - BusyMarkSpacing.md);
    },
  );
  testWidgets('history footer has native bottom and end insets', (
    tester,
  ) async {
    await mountGitVisualContract(
      tester,
      (session) => git.GitLogView(
        session: session,
        onChooseCommit: (_) {},
        preserveActionsWhenChoosing: true,
      ),
    );
    final button = find.widgetWithText(git.GitButton, 'Select this commit');
    final bounds = tester.getRect(find.byType(git.GitLogView));
    expect(
      bounds.bottom - tester.getRect(button).bottom,
      greaterThanOrEqualTo(BusyMarkSpacing.lg),
    );
    expect(
      bounds.right - tester.getRect(button).right,
      greaterThanOrEqualTo(BusyMarkSpacing.lg),
    );
  });
  for (final locale in ['en', 'ar']) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'modal toggle matches main header geometry and states $locale $brightness',
        (tester) async {
          var mainToggleClicks = 0;
          await mountGitVisualContract(
            tester,
            (session) => Column(
              children: [
                BusyMarkLinuxHeaderLayout(
                  key: const ValueKey('main-header-reference'),
                  leading: BusyMarkLinuxHeaderControlGroup(
                    children: [
                      BusyMarkLinuxHeaderIconButton(
                        key: const ValueKey('main-toggle-reference'),
                        tooltip: 'Main sidebar',
                        icon: BusyMarkGlyphs.sidebar,
                        selected: true,
                        onPressed: () => mainToggleClicks++,
                      ),
                    ],
                  ),
                  title: const Text('Main'),
                  trailing: const SizedBox.shrink(),
                ),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    child: SizedBox(
                      width: 300,
                      child: git.GitLogView(session: session, inspector: true),
                    ),
                  ),
                ),
              ],
            ),
            locale: Locale(locale),
            brightness: brightness,
            size: const Size(1400, 900),
          );
          final main = find.byKey(const ValueKey('main-toggle-reference'));
          await tester.tap(
            find.byKey(const ValueKey('git-select-another-commit')),
          );
          await tester.pumpAndSettle();
          final modal = find.byKey(
            const ValueKey('git-history-sidebar-toggle'),
          );
          final sidebar = tester.getRect(
            find.byKey(const ValueKey('git-history-reference-sidebar')),
          );
          final modalBounds = tester.getRect(modal);
          final mainBounds = tester.getRect(main);
          expect(modalBounds.size, mainBounds.size);
          final gap = locale == 'ar'
              ? sidebar.left - modalBounds.right
              : modalBounds.left - sidebar.right;
          expect(gap, BusyMarkSpacing.headerInset);
          final native = tester.widget<git.NativeGitIconAction>(modal);
          expect(native.focusBorderRadius, kYaruButtonRadius);
          YaruIconButton control(Finder parent) =>
              tester.widget<YaruIconButton>(
                find.descendant(
                  of: parent,
                  matching: find.byType(YaruIconButton),
                ),
              );
          final expected = control(main), actual = control(modal);
          for (final states in [
            <WidgetState>{},
            {WidgetState.hovered},
            {WidgetState.pressed},
            {WidgetState.selected},
            {WidgetState.selected, WidgetState.hovered},
            {WidgetState.selected, WidgetState.pressed},
            {WidgetState.disabled},
          ]) {
            expect(
              actual.style?.backgroundColor?.resolve(states)?.a,
              expected.style?.backgroundColor?.resolve(states)?.a,
            );
            expect(
              actual.style?.foregroundColor?.resolve(states),
              expected.style?.foregroundColor?.resolve(states),
            );
            expect(
              actual.style?.overlayColor?.resolve(states)?.a,
              expected.style?.overlayColor?.resolve(states)?.a,
            );
          }
          await tester.tap(modal);
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('git-history-reference-sidebar')),
            findsNothing,
          );
          expect(mainToggleClicks, 0);
          await tester.tap(find.byType(EditableText).first);
          await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
          await tester.pump();
          // The shared modal Close action now participates in native keyboard
          // traversal. Verify that named action before continuing to the
          // leading sidebar toggle; it must not be an unnamed focus stop.
          final closeLabel = MaterialLocalizations.of(
            tester.element(modal),
          ).closeButtonTooltip;
          Future<void> expectFocusedClose() async {
            final semantics = tester.ensureSemantics();
            try {
              await tester.pump();
              expect(
                tester.getSemantics(find.bySemanticsLabel(closeLabel)),
                matchesSemantics(
                  label: closeLabel,
                  textDirection: locale == 'ar'
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  isButton: true,
                  hasEnabledState: true,
                  isEnabled: true,
                  isFocusable: true,
                  isFocused: true,
                  hasFocusAction: true,
                  hasTapAction: true,
                ),
              );
            } finally {
              semantics.dispose();
            }
          }

          await expectFocusedClose();
          await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
          expect(
            FocusManager.instance.primaryFocus?.context
                ?.findAncestorWidgetOfExactType<git.NativeGitIconAction>()
                ?.key,
            const ValueKey('git-history-sidebar-toggle'),
          );
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('git-history-reference-sidebar')),
            findsOneWidget,
          );
          expect(mainToggleClicks, 0);
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await expectFocusedClose();
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          await tester.pumpAndSettle();
          expect(modal, findsNothing);
          expect(
            find.byKey(const ValueKey('git-select-another-commit')),
            findsOneWidget,
          );
          expect(mainToggleClicks, 0);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'history references use flat Files disclosures beneath modal header',
    (tester) async {
      await mountGitVisualContract(
        tester,
        (session) => git.GitLogView(
          session: session,
          onChooseCommit: (_) {},
          preserveActionsWhenChoosing: true,
        ),
        size: const Size(1400, 850),
      );
      expect(find.byType(YaruExpandable), findsNothing);
      expect(
        find.byKey(const ValueKey('git-history-sidebar-toggle')),
        findsOneWidget,
      );
      expect(find.byType(git.NativeGitTreeRow), findsWidgets);
    },
  );
  testWidgets('date inputs have one label and spaced fields and actions', (
    tester,
  ) async {
    await mountGitVisualContract(
      tester,
      (session) => Builder(
        builder: (context) => TextButton(
          onPressed: () => session.host.presentation.dateRange(context),
          child: const Text('Open dates'),
        ),
      ),
    );
    await tester.tap(find.text('Open dates'));
    await tester.pumpAndSettle();
    expect(find.text('Enter Date'), findsNothing);
    final start = find.byKey(const ValueKey('git-date-start'));
    final end = find.byKey(const ValueKey('git-date-end'));
    expect(start, findsOneWidget);
    expect(end, findsOneWidget);
    expect(
      tester.getRect(end).top - tester.getRect(start).bottom,
      greaterThanOrEqualTo(BusyMarkSpacing.lg),
    );
    final cancel = find.widgetWithText(BusyMarkGitActionButton, 'Cancel');
    final save = find.widgetWithText(BusyMarkGitActionButton, 'Save');
    expect(
      tester.getRect(save).left - tester.getRect(cancel).right,
      greaterThanOrEqualTo(BusyMarkSpacing.sm),
    );
    expect(tester.takeException(), isNull);
  });
  for (final locale in ['en', 'de', 'ja', 'ar']) {
    for (final brightness in Brightness.values) {
      for (final width in [480.0, 1400.0]) {
        for (final scale in [1.0, 1.5]) {
          testWidgets(
            'modal geometry and retained references $locale $brightness $width $scale',
            (tester) async {
              await mountGitVisualContract(
                tester,
                (session) => Align(
                  alignment: AlignmentDirectional.topStart,
                  child: SizedBox(
                    width: 300,
                    child: git.GitLogView(session: session, inspector: true),
                  ),
                ),
                locale: Locale(locale),
                brightness: brightness,
                size: Size(width, 900),
                scale: scale,
              );
              await tester.tap(
                find.byKey(const ValueKey('git-select-another-commit')),
              );
              await tester.pumpAndSettle();
              final header = find.byKey(const ValueKey('git-history-header'));
              final title = find.byKey(const ValueKey('git-history-title'));
              final toggle = find.byKey(
                const ValueKey('git-history-sidebar-toggle'),
              );
              final sidebar = find.byKey(
                const ValueKey('git-history-reference-sidebar'),
              );
              final toolbar = find.byKey(const ValueKey('git-history-toolbar'));
              expect(toggle, findsOneWidget);
              expect(
                (tester.getCenter(title).dx - tester.getCenter(header).dx)
                    .abs(),
                lessThan(1),
              );
              expect(
                find.descendant(
                  of: toolbar,
                  matching: find.byKey(
                    const ValueKey('git-history-sidebar-toggle'),
                  ),
                ),
                findsNothing,
              );
              if (sidebar.evaluate().isEmpty) {
                await tester.tap(toggle);
                await tester.pumpAndSettle();
              }
              final sideBounds = tester.getRect(sidebar);
              final search = find.descendant(
                of: sidebar,
                matching: find.byType(git.GitTextField),
              );
              final searchBounds = tester.getRect(search);
              expect(
                searchBounds.left - sideBounds.left,
                greaterThanOrEqualTo(BusyMarkSpacing.sm),
              );
              expect(
                sideBounds.right - searchBounds.right,
                greaterThanOrEqualTo(BusyMarkSpacing.sm),
              );
              expect(sideBounds.top, closeTo(tester.getRect(header).top, 1));
              final sidebarHeader = find.byKey(
                const ValueKey('git-history-sidebar-header'),
              );
              expect(
                tester.getRect(sidebarHeader).height,
                tester.getRect(header).height,
              );
              expect(
                searchBounds.top,
                greaterThanOrEqualTo(tester.getRect(sidebarHeader).bottom),
              );
              if (width > 1000) {
                final rtl = locale == 'ar';
                expect(
                  rtl ? sideBounds.right : sideBounds.left,
                  closeTo(
                    rtl
                        ? tester.getRect(header).right
                        : tester.getRect(header).left,
                    1,
                  ),
                );
              }
              final groups = find.descendant(
                of: sidebar,
                matching: find.byType(git.GitReferenceRow),
              );
              final topRows = tester
                  .widgetList<git.GitReferenceRow>(groups)
                  .where((r) => r.depth == 0)
                  .toList();
              expect(topRows.length, 4);
              for (final row in topRows) {
                expect(
                  tester.getRect(find.byWidget(row)).left,
                  closeTo(searchBounds.left, 1),
                );
              }
              expect(find.byType(YaruExpandable), findsNothing);
              final local = find.byKey(
                const ValueKey('git-reference-group-Local'),
              );
              final actualLocal = find
                  .byWidgetPredicate(
                    (w) => w is git.GitReferenceRow && w.expanded != null,
                  )
                  .first;
              await tester.tapAt(
                tester.getTopLeft(actualLocal) + const Offset(45, 16),
              );
              await tester.pumpAndSettle();
              expect(
                tester.widget<git.GitReferenceRow>(actualLocal).expanded,
                isFalse,
              );
              await tester.enterText(
                find.descendant(
                  of: search,
                  matching: find.byType(EditableText),
                ),
                'origin',
              );
              await tester.pumpAndSettle();
              final referenceWidth = tester.getSize(sidebar).width;
              await tester.tap(toggle);
              await tester.pumpAndSettle();
              expect(sidebar, findsNothing);
              final historyButton = find.widgetWithText(
                git.GitButton,
                git.gitString(
                  tester.element(header),
                  git.GitMessages.selectThisCommit,
                ),
              );
              final modal = find
                  .ancestor(
                    of: header,
                    matching: find.byType(YaruBorderContainer),
                  )
                  .first;
              final surface = tester.getRect(modal);
              final action = tester.getRect(historyButton);
              expect(
                surface.bottom - action.bottom,
                greaterThanOrEqualTo(BusyMarkSpacing.lg),
              );
              expect(
                locale == 'ar'
                    ? action.left - surface.left
                    : surface.right - action.right,
                greaterThanOrEqualTo(BusyMarkSpacing.lg),
              );
              expect(tester.getRect(toolbar).bottom, lessThan(action.top));
              await tester.tap(toggle);
              await tester.pumpAndSettle();
              expect(tester.getSize(sidebar).width, closeTo(referenceWidth, 1));
              expect(
                tester.getRect(sidebar).overlaps(tester.getRect(historyButton)),
                isFalse,
                reason:
                    'The temporary reference pane must not cover the confirmation footer',
              );
              final input = tester.widget<EditableText>(
                find
                    .descendant(
                      of: sidebar,
                      matching: find.byType(EditableText),
                    )
                    .first,
              );
              expect(input.controller.text, 'origin');
              expect(
                tester.widget<git.GitReferenceRow>(actualLocal).expanded,
                isFalse,
              );
              if (width >= 1000) {
                final historyBounds = tester.getRect(toolbar);
                expect(
                  locale == 'ar'
                      ? historyBounds.right <= sideBounds.left
                      : historyBounds.left >= sideBounds.right,
                  isTrue,
                );
              }
              expect(tester.takeException(), isNull);
              await tester.sendKeyEvent(LogicalKeyboardKey.escape);
              await tester.binding.handlePopRoute();
              await tester.pumpAndSettle();
              // Keep the key read in the assertion context for translated groups.
              expect(local.evaluate().length, lessThanOrEqualTo(1));
            },
          );
        }
      }
    }
  }
  for (final locale in ['en', 'de', 'ja', 'ar']) {
    testWidgets(
      'native date editing validates saves clears cancels and reopens $locale',
      (tester) async {
        final session = await mountGitVisualContract(
          tester,
          (session) => git.GitLogView(
            session: session,
            preserveActionsWhenChoosing: true,
            onChooseCommit: (_) {},
          ),
          locale: Locale(locale),
          size: const Size(1200, 900),
        );
        final labels = MaterialLocalizations.of(
          tester.element(find.byType(git.GitLogView)),
        );
        Future<void> openDates() async {
          final button = find.byWidgetPredicate(
            (w) =>
                w is git.GitButton &&
                w.child is git.GitLabel &&
                [
                  (git.GitMessages.date),
                  (git.GitMessages.dateFilter),
                ].contains((w.child as git.GitLabel).message),
          );
          await tester.tap(button);
          await tester.pumpAndSettle();
        }

        Finder entry(String key) => find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(EditableText),
        );
        Finder save() => find.widgetWithText(
          BusyMarkGitActionButton,
          labels.saveButtonLabel,
        );
        await openDates();
        expect(
          tester.widget<BusyMarkGitActionButton>(save()).onPressed,
          isNull,
        );
        expect(
          tester.widget<EditableText>(entry('git-date-start')).controller.text,
          isEmpty,
        );
        await tester.enterText(entry('git-date-start'), 'invalid');
        await tester.pumpAndSettle();
        expect(find.text(labels.invalidDateFormatLabel), findsOneWidget);
        final startInput = find.descendant(
          of: find.byKey(const ValueKey('git-date-start')),
          matching: find.byType(BusyMarkGitTextEntry),
        );
        final endInput = find.descendant(
          of: find.byKey(const ValueKey('git-date-end')),
          matching: find.byType(BusyMarkGitTextEntry),
        );
        expect(
          tester.getSize(startInput).height,
          tester.getSize(endInput).height,
          reason:
              'A clear action must not change the field height when the other field is empty',
        );
        final first = DateTime(2026, 1, 2), last = DateTime(2026, 1, 5);
        final keyboardDates = switch (locale) {
          'de' => ('02.01.2026', '05.01.2026'),
          'ja' => ('2026/01/02', '2026/01/05'),
          'ar' => ('02/01/2026', '05/01/2026'),
          _ => ('01/02/2026', '01/05/2026'),
        };
        await tester.enterText(
          entry('git-date-start'),
          labels.formatCompactDate(last),
        );
        await tester.enterText(
          entry('git-date-end'),
          labels.formatCompactDate(first),
        );
        await tester.pumpAndSettle();
        expect(find.text(labels.invalidDateRangeLabel), findsOneWidget);
        expect(
          tester.widget<BusyMarkGitActionButton>(save()).onPressed,
          isNull,
        );
        await tester.enterText(entry('git-date-start'), keyboardDates.$1);
        await tester.enterText(entry('git-date-end'), keyboardDates.$2);
        await tester.pumpAndSettle();
        expect(find.text(labels.invalidDateRangeLabel), findsNothing);
        expect(
          tester.widget<BusyMarkGitActionButton>(save()).onPressed,
          isNotNull,
        );
        await tester.tap(save());
        await tester.pumpAndSettle();
        final client = session.client as FixtureClient;
        expect(client.historyFilters.last.since, first);
        expect(
          client.historyFilters.last.until,
          last.add(const Duration(days: 1)),
        );
        final reads = client.historyFilters.length;
        await openDates();
        expect(
          tester.widget<EditableText>(entry('git-date-start')).controller.text,
          labels.formatCompactDate(first),
        );
        expect(
          tester.widget<EditableText>(entry('git-date-end')).controller.text,
          labels.formatCompactDate(last),
        );
        await tester.tap(find.byKey(const ValueKey('git-date-start-clear')));
        await tester.pumpAndSettle();
        expect(
          tester.widget<EditableText>(entry('git-date-start')).controller.text,
          isEmpty,
        );
        expect(
          tester.widget<BusyMarkGitActionButton>(save()).onPressed,
          isNull,
        );
        await tester.tap(
          find.widgetWithText(
            BusyMarkGitActionButton,
            labels.cancelButtonLabel,
          ),
        );
        await tester.pumpAndSettle();
        expect(client.historyFilters.length, reads);
        expect(client.mutations, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final locale in ['en', 'de', 'ja', 'ar']) {
    for (final brightness in Brightness.values) {
      testWidgets('narrow enlarged date layout $locale $brightness', (
        tester,
      ) async {
        await mountGitVisualContract(
          tester,
          (session) => Builder(
            builder: (context) => TextButton(
              onPressed: () => session.host.presentation.dateRange(context),
              child: const Text('Open dates'),
            ),
          ),
          locale: Locale(locale),
          brightness: brightness,
          size: const Size(480, 900),
          scale: 1.5,
        );
        await tester.tap(find.text('Open dates'));
        await tester.pumpAndSettle();
        final start = find.byKey(const ValueKey('git-date-start'));
        final end = find.byKey(const ValueKey('git-date-end'));
        final labels = MaterialLocalizations.of(tester.element(start));
        final save = find.widgetWithText(
          BusyMarkGitActionButton,
          labels.saveButtonLabel,
        );
        final cancel = find.widgetWithText(
          BusyMarkGitActionButton,
          labels.cancelButtonLabel,
        );
        for (final field in [start, end]) {
          final label = find
              .descendant(of: field, matching: find.byType(Text))
              .first;
          final input = find.descendant(
            of: field,
            matching: find.byType(BusyMarkGitTextEntry),
          );
          expect(
            tester.getRect(input).top - tester.getRect(label).bottom,
            greaterThanOrEqualTo(BusyMarkSpacing.xs),
          );
          expect(
            tester.getRect(field).left,
            greaterThanOrEqualTo(BusyMarkSpacing.lg),
          );
          expect(
            tester.getRect(field).right,
            lessThanOrEqualTo(480 - BusyMarkSpacing.lg),
          );
        }
        expect(
          tester.getRect(end).top - tester.getRect(start).bottom,
          greaterThanOrEqualTo(BusyMarkSpacing.lg),
        );
        expect(
          tester.getRect(save).top - tester.getRect(end).bottom,
          greaterThanOrEqualTo(BusyMarkSpacing.lg),
        );
        final gap = locale == 'ar'
            ? tester.getRect(cancel).left - tester.getRect(save).right
            : tester.getRect(save).left - tester.getRect(cancel).right;
        expect(gap, greaterThanOrEqualTo(BusyMarkSpacing.sm));
        expect(tester.getRect(save).bottom, lessThan(900 - BusyMarkSpacing.lg));
        expect(tester.widget<BusyMarkGitActionButton>(save).onPressed, isNull);
        await tester.tap(
          find.descendant(of: start, matching: find.byType(EditableText)),
        );
        await tester.pump();
        expect(
          tester
              .widget<EditableText>(
                find.descendant(of: start, matching: find.byType(EditableText)),
              )
              .focusNode
              .hasFocus,
          isTrue,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'historical root and child filenames match Files without a status column at $scale',
      (tester) async {
        await mountGitVisualContract(
          tester,
          (session) => SizedBox(
            width: 300,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: BusyMarkSpacing.sm),
                  child: BusyMarkSidebarTreeRow(
                    key: ValueKey('files-root'),
                    title: 'Files root',
                    depth: 0,
                    icon: BusyMarkGlyphs.document,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: BusyMarkSpacing.sm),
                  child: BusyMarkSidebarTreeRow(
                    key: ValueKey('files-child'),
                    title: 'Files child',
                    depth: 1,
                    icon: BusyMarkGlyphs.document,
                  ),
                ),
                Expanded(
                  child: GitHistoricalChangeTree(
                    session: session,
                    files: [
                      for (final path in ['root.md', 'docs/child.md'])
                        git.GitChange(
                          path: git.RepoPath.text(path),
                          index: 'M',
                          worktree: ' ',
                        ),
                    ],
                    selected: null,
                    onHighlight: (_) {},
                    onActivate: (_) {},
                    onAction: (_, _) async {},
                  ),
                ),
              ],
            ),
          ),
          scale: scale,
        );
        expect(
          tester.getRect(find.text('root.md')).left,
          tester.getRect(find.text('Files root')).left,
        );
        expect(
          tester.getRect(find.text('child.md')).left,
          tester.getRect(find.text('Files child')).left,
        );
        expect(
          tester.getRect(find.text('child.md')).left -
              tester.getRect(find.text('root.md')).left,
          BusyMarkSizes.sidebarTreeDepthIndent,
        );
        expect(find.text('M'), findsNothing);
        expect(
          tester.widget<Text>(find.text('root.md')).style!.color,
          tester.widget<Text>(find.text('child.md')).style!.color,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'fractional device scaling preserves modal footer and header bounds',
    (tester) async {
      await mountGitVisualContract(
        tester,
        (session) => git.GitLogView(
          session: session,
          onChooseCommit: (_) {},
          preserveActionsWhenChoosing: true,
        ),
        size: const Size(1500, 1000),
      );
      tester.view.devicePixelRatio = 1.25;
      await tester.pumpAndSettle();
      final view = tester.getRect(find.byType(git.GitLogView));
      final action = tester.getRect(
        find.widgetWithText(git.GitButton, 'Select this commit'),
      );
      expect(
        view.right - action.right,
        greaterThanOrEqualTo(BusyMarkSpacing.lg),
      );
      expect(
        view.bottom - action.bottom,
        greaterThanOrEqualTo(BusyMarkSpacing.lg),
      );
      final header = find.byKey(const ValueKey('git-history-header'));
      final title = find.byKey(const ValueKey('git-history-title'));
      expect(
        tester.getCenter(title).dx,
        closeTo(tester.getCenter(header).dx, 1),
      );
      expect(tester.takeException(), isNull);
    },
  );
  for (final locale in ['en', 'ar']) {
    testWidgets(
      'reference disclosures retain native keyboard and expanded semantics $locale',
      (tester) async {
        await mountGitVisualContract(
          tester,
          (session) => git.GitLogView(session: session),
          locale: Locale(locale),
          size: const Size(1400, 900),
        );
        final group = find
            .byWidgetPredicate(
              (w) => w is git.GitReferenceRow && w.expanded != null,
            )
            .first;
        final row = find
            .descendant(of: group, matching: find.byType(git.NativeGitTreeRow))
            .first;
        final surface = find
            .descendant(of: row, matching: find.byType(git.NativeGitRowSurface))
            .first;
        final focus = find
            .descendant(of: surface, matching: find.byType(Focus))
            .first;
        Focus.of(tester.element(focus)).requestFocus();
        await tester.tapAt(tester.getTopLeft(row) + const Offset(45, 16));
        await tester.pumpAndSettle();
        expect(tester.widget<git.GitReferenceRow>(group).expanded, isFalse);
        await tester.sendKeyEvent(
          locale == 'ar'
              ? LogicalKeyboardKey.arrowLeft
              : LogicalKeyboardKey.arrowRight,
        );
        await tester.pumpAndSettle();
        expect(tester.widget<git.GitReferenceRow>(group).expanded, isTrue);
        await tester.sendKeyEvent(
          locale == 'ar'
              ? LogicalKeyboardKey.arrowRight
              : LogicalKeyboardKey.arrowLeft,
        );
        await tester.pumpAndSettle();
        expect(tester.widget<git.GitReferenceRow>(group).expanded, isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'hidden history references cannot retain or receive keyboard focus',
    (tester) async {
      await mountGitVisualContract(
        tester,
        (session) => git.GitLogView(session: session),
        size: const Size(1400, 900),
      );
      final sidebar = find.byKey(
        const ValueKey('git-history-reference-sidebar'),
      );
      final search = find.descendant(
        of: sidebar,
        matching: find.byType(EditableText),
      );
      final editor = tester.widget<EditableText>(search);
      await tester.tap(search);
      await tester.enterText(search, 'origin');
      await tester.tap(
        find.byKey(const ValueKey('git-history-sidebar-toggle')),
      );
      await tester.pumpAndSettle();
      expect(
        editor.focusNode.canRequestFocus,
        isFalse,
        reason:
            'Offstage alone must not leave hidden reference controls in the focus traversal',
      );
      final message = find.descendant(
        of: find.byKey(const ValueKey('git-history-filter-0')),
        matching: find.byType(EditableText),
      );
      await tester.tap(message);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(FocusManager.instance.primaryFocus, isNot(same(editor.focusNode)));
      await tester.tap(
        find.byKey(const ValueKey('git-history-sidebar-toggle')),
      );
      await tester.pumpAndSettle();
      expect(editor.focusNode.canRequestFocus, isTrue);
      expect(editor.controller.text, 'origin');
      expect(tester.takeException(), isNull);
    },
  );
}
