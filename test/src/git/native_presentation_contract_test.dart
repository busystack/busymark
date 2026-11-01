import 'package:busymark/src/app/busymark_toast.dart';
import 'package:busymark/src/app/busymark_glyphs.dart';
import '../../../../busystack_git_flutter/test/support/native_surface_contract.dart';
import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/system_accent.dart';
import 'package:busymark/src/git/application/shared_git_integration.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busystack_git_flutter/busystack_git_flutter.dart' as git;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../../../busystack_git_flutter/test/support/presentation_fixture.dart'
    show FixtureClient, repo;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaru/yaru.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'real BusyMark native Git contract: fields, choices, errors, progress and menus $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final surface = ValueNotifier<Widget?>(null);
        addTearDown(surface.dispose);
        final input = TextEditingController(text: 'draft');
        addTearDown(input.dispose);
        final focus = FocusNode();
        addTearDown(focus.dispose);
        var chosen = 0, authorized = 0;
        final calls = <MethodCall>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('busymark/native_menus'),
          (call) async {
            calls.add(call);
            return call.method == 'show' ? 1 : true;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            const MethodChannel('busymark/native_menus'),
            null,
          ),
        );
        final workspace = Workspace(
          id: 'native-contract',
          rootPath: '/fixture',
          kind: WorkspaceKind.markdownFolder,
          openedAt: DateTime.utc(2026),
          files: const [],
          diagnostics: const [],
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedGitDraftStoreProvider.overrideWithValue(
                git.MemoryGitDraftStore(),
              ),
            ],
            child: MaterialApp(
              theme: buildBusyMarkTheme(
                brightness: brightness,
                accentColor: busyMarkDefaultAccentColor,
              ),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) => git.GitHostScope(
                    host: busyMarkGitHost(
                      context,
                      ref,
                      workspace,
                      isMounted: () => context.mounted,
                    ),
                    child: ValueListenableBuilder<Widget?>(
                      valueListenable: surface,
                      builder: (context, replacement, _) =>
                          replacement ??
                          SingleChildScrollView(
                            child: Column(
                              children: [
                                git.GitButton.primary(
                                  onPressed: () {},
                                  child: const Text('Primary native action'),
                                ),
                                git.GitIconButton(
                                  tooltip: git.GitMessages.refresh,
                                  onPressed: () {},
                                  icon: const git.GitIcon(git.GitGlyph.refresh),
                                ),
                                git.GitTextField(
                                  controller: input,
                                  focusNode: focus,
                                  decoration: const git.GitFieldDecoration(
                                    labelText: 'Native draft',
                                  ),
                                ),
                                git.GitCheckbox(value: true, onChanged: (_) {}),
                                git.GitChoice<int>(
                                  value: 0,
                                  items: const [
                                    git.GitChoiceItem(
                                      value: 0,
                                      child: Text('First native choice'),
                                    ),
                                    git.GitChoiceItem(
                                      value: 1,
                                      child: Text('Second native choice'),
                                    ),
                                  ],
                                  onChanged: (value) => chosen = value!,
                                ),
                                git.GitActionRow(
                                  title: const Text('Native row'),
                                  onTap: () {},
                                ),
                                const git.GitExpander(
                                  title: Text('Native expander'),
                                  children: [Text('Details')],
                                ),
                                const git.GitLoading(),
                                const git.GitLoading.spinner(),
                                const git.GitSeparator(),
                                git.GitFailurePanel(
                                  error: const git.GitException(
                                    git.GitErrorCode.trustRequired,
                                  ),
                                  onAuthorize: () => authorized++,
                                ),
                              ],
                            ),
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(BusyMarkGroupedTextEntry), findsOneWidget);
        expect(find.byType(YaruCheckbox), findsOneWidget);
        expect(find.byType(YaruCircularProgressIndicator), findsOneWidget);
        expect(find.byType(YaruLinearProgressIndicator), findsOneWidget);
        expect(find.byType(BusyMarkCompactIconButton), findsNothing);
        expect(find.byType(BusyMarkHeaderIconButton), findsOneWidget);
        final iconFinder = find.descendant(
          of: find.byType(BusyMarkHeaderIconButton),
          matching: find.byType(IconButton),
        );
        final icon = tester.widget<IconButton>(iconFinder);
        for (final state in <Set<WidgetState>>[
          {},
          {WidgetState.hovered},
          {WidgetState.pressed},
          {WidgetState.focused},
          {WidgetState.disabled},
        ]) {
          final shape = icon.style!.shape!.resolve(state)!;
          expect(shape, isA<RoundedRectangleBorder>());
          expect(
            (shape as RoundedRectangleBorder).borderRadius.resolve(
              TextDirection.ltr,
            ),
            BorderRadius.circular(BusyMarkRadius.headerButton),
          );
        }
        final hit = tester.getRect(iconFinder);
        expect(hit.width, greaterThanOrEqualTo(BusyMarkSizes.iconButton));
        expect(hit.height, greaterThanOrEqualTo(BusyMarkSizes.iconButton));
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(DropdownButton<int>), findsNothing);
        focus.requestFocus();
        await tester.pump();
        const value = TextEditingValue(
          text: 'typed draft',
          selection: TextSelection.collapsed(offset: 5),
          composing: TextRange(start: 0, end: 5),
        );
        tester.testTextInput.updateEditingValue(value);
        await tester.pump();
        expect(input.value, value);
        await tester.tap(find.text('First native choice'));
        await tester.pump();
        expect(chosen, 1);
        expect(calls.any((call) => call.method == 'show'), isTrue);
        await tester.tap(find.text(git.GitMessages.authorizeGitInspection));
        await tester.pump();
        expect(authorized, 1);
        expect(tester.takeException(), isNull);
        final host = tester
            .widget<git.GitHostScope>(find.byType(git.GitHostScope).first)
            .host;
        await exerciseNativeGitSurfaces(
          tester,
          host: host,
          nativeField: BusyMarkGroupedTextEntry,
          mount: (widget) async {
            surface.value = widget;
            await tester.pump();
          },
        );
      },
    );
  }
  for (final locale in ['en', 'de', 'ja', 'ar']) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets(
        'compact Commit actions retain full labels and token gap $locale $scale',
        (tester) async {
          tester.view.physicalSize = const Size(1500, 1400);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          git.GitSession? session;
          late double width;
          late AppLocalizations l10n;
          await tester.pumpWidget(
            _nativeGitHarness(
              locale: Locale(locale),
              scale: scale,
              builder: (context, host) {
                l10n = AppLocalizations.of(context);
                width = busyMarkGitSidebarMinimumWidth(context);
                session ??= git.GitSession(
                  client: FixtureClient(),
                  repository: repo,
                  host: host,
                );
                return Align(
                  alignment: AlignmentDirectional.topStart,
                  child: SizedBox(
                    width: width,
                    height: 1200,
                    child: git.GitCommitView(
                      session: session!,
                      layout: git.GitCommitLayout.sidebar,
                      onReview: (_) {},
                      onLog: () {},
                      onBranches: () {},
                      onPush: () {},
                      onMore: (_) {},
                    ),
                  ),
                );
              },
            ),
          );
          await tester.runAsync(session!.start);
          await tester.pumpAndSettle();
          final commit = find.widgetWithText(git.GitButton, l10n.gitUiCommit);
          final push = find.widgetWithText(
            git.GitButton,
            l10n.gitUiCommitAndPush,
          );
          expect(commit, findsOneWidget);
          expect(push, findsOneWidget);
          final a = tester.getRect(commit), b = tester.getRect(push);
          expect(a.top, closeTo(b.top, .01));
          expect(a.height, closeTo(b.height, .01));
          final rtl = locale == 'ar';
          expect(
            rtl ? a.left - b.right : b.left - a.right,
            closeTo(BusyMarkSpacing.sm, .01),
          );
          final bounds = tester.getRect(find.byType(git.GitCommitView));
          expect(
            bounds.contains(a.topLeft) && bounds.contains(a.bottomRight),
            isTrue,
          );
          expect(
            bounds.contains(b.topLeft) && bounds.contains(b.bottomRight),
            isTrue,
          );
          for (final label in [l10n.gitUiCommit, l10n.gitUiCommitAndPush]) {
            final text = tester.widget<Text>(find.text(label));
            expect(text.overflow, isNull);
            expect(tester.getSize(find.text(label)).height, lessThan(a.height));
          }
          expect(find.byTooltip(l10n.gitUiLog), findsNothing);
          expect(
            find.text(l10n.gitUiCommitScopeEntireRepository),
            findsNothing,
          );
          expect(find.byTooltip(repo.root), findsOneWidget);
          expect(find.byType(BusyMarkCompactIconButton), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          session!.dispose();
        },
      );
    }
  }
  testWidgets(
    'native Git tree shares row metrics; disclosure and flat action isolate activation',
    (tester) async {
      var opened = 0, toggled = 0, staged = 0;
      final enabled = ValueNotifier(true);
      addTearDown(enabled.dispose);
      await tester.pumpWidget(
        _nativeGitHarness(
          builder: (context, host) => ValueListenableBuilder<bool>(
            valueListenable: enabled,
            builder: (context, available, _) => SizedBox(
              width: 400,
              child: Column(
                children: [
                  for (final depth in [0, 1, 2])
                    SizedBox(
                      height: host.rowHeight(context),
                      child: git.GitChangeRow(
                        title: 'Tree $depth',
                        depth: depth,
                        group: depth == 0,
                        expanded: depth < 2 ? true : null,
                        status: depth == 2 ? 'M' : null,
                        onPointerDown: (_) {},
                        onTap: () => opened++,
                        onToggle: () => toggled++,
                        trailing: git.GitIconButton(
                          tooltip: 'Stage $depth',
                          icon: const git.GitIcon(git.GitGlyph.add),
                          onPressed: available ? () => staged++ : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final rows = find.byType(BusyMarkSidebarTreeRow);
      expect(rows, findsNWidgets(3));
      for (var i = 1; i < 3; i++) {
        expect(
          tester.getRect(rows.at(i)).height,
          tester.getRect(rows.first).height,
        );
        expect(
          tester.getTopLeft(find.text('Tree $i')).dx -
              tester.getTopLeft(find.text('Tree ${i - 1}')).dx,
          closeTo(BusyMarkSizes.sidebarTreeDepthIndent, .01),
        );
      }
      await tester.tap(find.byTooltip('Stage 2'));
      await tester.pumpAndSettle();
      expect(staged, 1);
      expect(opened, 0);
      final disclosure = find.descendant(
        of: rows.at(1),
        matching: find.byType(AnimatedRotation),
      );
      await tester.tap(disclosure);
      await tester.pumpAndSettle();
      expect(toggled, 1);
      expect(opened, 0);
      await tester.tap(find.text('Tree 2'));
      await tester.pumpAndSettle();
      expect(opened, 1);
      final action = find.widgetWithIcon(IconButton, BusyMarkGlyphs.add).last;
      final rect = tester.getRect(action);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: rect.center);
      await mouse.moveTo(rect.center);
      await tester.pump();
      await mouse.down(rect.center);
      await tester.pump();
      await mouse.up();
      await tester.pumpAndSettle();
      expect(staged, 2);
      expect(opened, 1);
      final iconContext = tester.element(
        find.descendant(of: action, matching: find.byType(Icon)).first,
      );
      final focus = Focus.of(iconContext);
      focus.requestFocus();
      await tester.pump();
      expect(focus.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(staged, 3);
      expect(opened, 1);
      enabled.value = false;
      await tester.pumpAndSettle();
      expect(tester.getRect(action), rect);
      expect(tester.widget<IconButton>(action).onPressed, isNull);
      await tester.tap(find.byTooltip('Stage 2'));
      await tester.pump();
      expect(staged, 3);
      expect(opened, 1);
      await mouse.removePointer();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'native-required Git header menu reports unavailable without a Flutter fallback',
    (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('busymark/native_menus'),
        (_) async => throw MissingPluginException(),
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('busymark/native_menus'),
          null,
        ),
      );
      var invoked = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildBusyMarkTheme(
            brightness: Brightness.light,
            accentColor: busyMarkDefaultAccentColor,
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BusyMarkToastOverlay(
            child: Scaffold(
              body: BusyMarkHeaderPopupMenuButton<int>.native(
                tooltip: 'Git native header',
                icon: BusyMarkGlyphs.branch,
                itemBuilder: (_) => [
                  BusyMarkPopupMenuItem(value: 1, label: 'Git action'),
                  const BusyMarkNativeMenuSeparator<int>(),
                ],
                onSelected: (_) => invoked = true,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Git native header'));
      await tester.pumpAndSettle();
      expect(invoked, isFalse);
      expect(find.byType(PopupMenuItem<int>), findsNothing);
      expect(
        find.text(
          AppLocalizations.of(
            tester.element(find.byType(Scaffold)),
          ).gitUiNativeMenuUnavailable,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  for (final available in [true, false]) {
    testWidgets('comparison tab menu requires the native service: $available', (
      tester,
    ) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('busymark/native_menus'),
        (call) async {
          calls.add(call);
          if (!available) throw MissingPluginException();
          return call.method == 'show' ? 1 : true;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('busymark/native_menus'),
          null,
        ),
      );
      String? action;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BusyMarkToastOverlay(
            child: Scaffold(
              body: Builder(
                builder: (context) => BusyMarkPushButton.standard(
                  onPressed: () async {
                    action = await busyMarkPresentGitTabMenu(
                      context,
                      position: const Offset(10, 10),
                      hasOtherTabs: true,
                    );
                  },
                  child: const Text('Tab actions'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Tab actions'));
      await tester.pumpAndSettle();
      expect(action, available ? 'closeOthers' : isNull);
      final entries =
          (calls.singleWhere((c) => c.method == 'show').arguments
                  as Map)['entries']
              as List;
      expect(entries.map((e) => (e as Map)['label']), [
        'Close',
        'Close other tabs',
        'Close all tabs',
      ]);
      expect(find.byType(PopupMenuButton<String>), findsNothing);
      expect(find.byType(PopupMenuItem<String>), findsNothing);
      if (!available) {
        expect(
          find.text(
            AppLocalizations.of(
              tester.element(find.byType(Scaffold)),
            ).gitUiNativeMenuUnavailable,
          ),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'native Git separators become toolkit entries without widget construction',
    (tester) async {
      List<dynamic>? entries;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('busymark/native_menus'),
        (call) async {
          if (call.method == 'show') {
            entries = (call.arguments as Map)['entries'] as List;
            return 2;
          }
          return true;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('busymark/native_menus'),
          null,
        ),
      );
      int? action;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BusyMarkHeaderPopupMenuButton<int>.native(
              tooltip: 'Native separated actions',
              icon: BusyMarkGlyphs.branch,
              itemBuilder: (_) => [
                BusyMarkPopupMenuItem(value: 1, label: 'First'),
                const BusyMarkNativeMenuSeparator<int>(),
                BusyMarkPopupMenuItem(value: 2, label: 'Second'),
              ],
              onSelected: (value) => action = value,
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Native separated actions'));
      await tester.pumpAndSettle();
      expect(entries, hasLength(3));
      expect((entries![1] as Map)['separator'], isTrue);
      expect(action, 2);
      expect(find.byType(PopupMenuDivider), findsNothing);
      expect(find.byType(BusyMarkNativeMenuSeparator<int>), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _nativeGitHarness({
  required Widget Function(BuildContext, git.GitHost) builder,
  Locale locale = const Locale('en'),
  double scale = 1,
}) => ProviderScope(
  overrides: [
    sharedGitDraftStoreProvider.overrideWithValue(git.MemoryGitDraftStore()),
  ],
  child: MaterialApp(
    locale: locale,
    theme: buildBusyMarkTheme(
      brightness: Brightness.light,
      accentColor: busyMarkDefaultAccentColor,
    ),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Consumer(
          builder: (context, ref, _) {
            final host = busyMarkGitHost(
              context,
              ref,
              Workspace(
                id: 'native-contract',
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
