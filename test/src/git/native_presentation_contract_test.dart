import '../../../../busystack_git_flutter/test/support/filename_presentation_contract.dart';
import '../../../../busystack_git_flutter/test/support/history_presentation_contract.dart';
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
import 'package:busymark/src/app/busymark_search_field.dart';

void main() {
  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 1.5, 2.0]) {
      for (final locale in ['en', 'de', 'ja', 'ar']) {
        testWidgets(
          'shared filename status rendering $brightness $scale $locale',
          (tester) async {
            await filenamePresentationContract(
              tester,
              mount: (child) => tester.pumpWidget(
                _nativeGitHarness(
                  brightness: brightness,
                  scale: scale,
                  locale: Locale(locale),
                  builder: (_, _) => child,
                ),
              ),
            );
          },
        );
      }
    }
  }

  for (final brightness in Brightness.values) {
    testWidgets(
      'Git selection paints the approved search-entry theme $brightness',
      (tester) async {
        await tester.pumpWidget(
          _nativeGitHarness(
            brightness: brightness,
            builder: (context, host) => const Column(
              children: [
                BusyMarkSearchField(hintText: 'Native reference'),
                git.GitTextField(
                  decoration: git.GitFieldDecoration(
                    isDense: true,
                    labelText: 'Search branches and tags',
                  ),
                ),
              ],
            ),
          ),
        );
        final editors = find.byType(EditableText);
        await tester.enterText(editors.first, 'selected text');
        final referenceState = tester.state<EditableTextState>(editors.first);
        referenceState.widget.controller.selection = const TextSelection(
          baseOffset: 0,
          extentOffset: 13,
        );
        await tester.pump();
        final reference = referenceState.renderEditable.selectionColor;
        expect(reference, isNotNull);
        await tester.enterText(editors.last, 'selected text');
        final state = tester.state<EditableTextState>(editors.last);
        state.widget.controller.selection = const TextSelection(
          baseOffset: 0,
          extentOffset: 13,
        );
        await tester.pump();
        expect(
          state.renderEditable.getBoxesForSelection(
            state.widget.controller.selection,
          ),
          isNotEmpty,
        );
        expect(state.renderEditable.selectionColor, reference);
        expect(
          tester.widget<EditableText>(editors.last).cursorColor,
          tester.widget<EditableText>(editors.first).cursorColor,
        );
      },
    );
  }
  testWidgets(
    'native actions show keyboard focus without inherited Yaru settings',
    (tester) async {
      final oldStrategy = FocusManager.instance.highlightStrategy;
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() => FocusManager.instance.highlightStrategy = oldStrategy);
      await tester.pumpWidget(
        _nativeGitHarness(
          builder: (context, host) => git.GitButton.standard(
            compact: true,
            onPressed: () {},
            child: const Text('New branch…'),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final border = find.descendant(
        of: find.byType(BusyMarkGitActionButton),
        matching: find.byType(YaruFocusBorder),
      );
      expect(border, findsOneWidget);
      final paint = tester.widget<AnimatedContainer>(
        find
            .descendant(of: border, matching: find.byType(AnimatedContainer))
            .first,
      );
      final decoration = paint.foregroundDecoration! as BoxDecoration;
      expect(
        decoration.border!.top.color.a,
        greaterThan(0),
        reason:
            'The focus indicator must actually paint, not merely receive a flag',
      );
    },
  );
  testWidgets('compact native field exposes one persistent accessible name', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _nativeGitHarness(
        builder: (context, host) => const git.GitTextField(
          decoration: git.GitFieldDecoration(
            labelText: 'Search branches and tags',
            isDense: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .getSemantics(find.byType(git.GitTextField))
          .getSemanticsData()
          .label,
      'Search branches and tags',
    );
    await tester.enterText(find.byType(EditableText), 'main');
    await tester.pump();
    expect(
      tester
          .getSemantics(find.byType(git.GitTextField))
          .getSemanticsData()
          .label,
      'Search branches and tags',
    );
    semantics.dispose();
  });
  for (final brightness in Brightness.values) {
    testWidgets(
      'Branches toolbar has native entry geometry and explicit gaps $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        git.GitSession? session;
        await tester.pumpWidget(
          _nativeGitHarness(
            brightness: brightness,
            builder: (context, host) {
              session ??= git.GitSession(
                client: _CommitControlsClient(),
                repository: repo,
                host: host,
              );
              return Column(
                children: [
                  const SizedBox(
                    width: 500,
                    child: BusyMarkSearchField(hintText: 'Native reference'),
                  ),
                  Flexible(
                    child: SizedBox(
                      width: 700,
                      child: git.GitBranchesView(session: session!),
                    ),
                  ),
                ],
              );
            },
          ),
        );
        addTearDown(() => session?.dispose());
        await session!.start();
        await tester.pumpAndSettle();
        final field = find.byType(git.GitTextField).first;
        final action = find.widgetWithText(git.GitButton, 'New branch…');
        final menu = find.byKey(const ValueKey('git-branch-workflows'));
        final reference = tester.getRect(find.byType(BusyMarkSearchField));
        expect(tester.getSize(field).height, closeTo(reference.height, 2));
        expect(
          tester.getRect(action).left - tester.getRect(field).right,
          greaterThanOrEqualTo(BusyMarkSpacing.sm),
        );
        expect(
          tester.getRect(menu).left - tester.getRect(action).right,
          greaterThanOrEqualTo(BusyMarkSpacing.sm),
        );
        final input = find.descendant(
          of: field,
          matching: find.byType(EditableText),
        );
        final icon = find.descendant(
          of: field,
          matching: find.byType(git.GitIcon),
        );
        expect(
          (tester.getCenter(input).dy - tester.getCenter(icon).dy).abs(),
          lessThanOrEqualTo(1),
        );
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is git.GitMenuButton && w.tooltip.startsWith('Actions for '),
          ),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'inline Git actions use neutral native foreground $brightness',
      (tester) async {
        await tester.pumpWidget(
          _nativeGitHarness(
            brightness: brightness,
            builder: (context, host) => const git.GitButton(
              onPressed: _noop,
              child: Text('Native action'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final context = tester.element(find.text('Native action'));
        expect(
          DefaultTextStyle.of(context).style.color,
          BusyMarkSurfaceColors.of(context).foreground,
        );
      },
    );
  }
  historyPresentationContract(
    referenceAction: (focus, onPressed) => BusyMarkPushButton.standard(
      focusNode: focus,
      onPressed: onPressed,
      child: const Text('Approved secondary'),
    ),
    mount: (tester, child, brightness) async {
      await tester.pumpWidget(
        _nativeGitHarness(
          brightness: brightness,
          builder: (context, host) => child,
        ),
      );
      await tester.pump();
      // Isolate-backed diffs need real event-loop progress before settling.
      for (
        var i = 0;
        i < 200 && find.byType(git.GitLoading).evaluate().isNotEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();
    },
  );
  for (final brightness in Brightness.values) {
    testWidgets(
      'neutral branch context row opens full modal and repository menu owns Refresh $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final client = _CommitControlsClient();
        git.GitSession? session;
        List<dynamic>? entries;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('busymark/native_menus'),
          (call) async {
            if (call.method == 'show') {
              entries = (call.arguments as Map)['entries'] as List;
              return entries!.indexWhere(
                (e) => (e as Map)['label'] == 'Refresh',
              );
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
        await tester.pumpWidget(
          _nativeGitHarness(
            brightness: brightness,
            builder: (context, host) {
              session ??= git.GitSession(
                client: client,
                repository: repo,
                host: host,
              );
              return SizedBox(
                width: busyMarkGitSidebarMinimumWidth(context),
                height: 900,
                child: git.GitCommitView(
                  session: session!,
                  branchActionLabel: AppLocalizations.of(
                    context,
                  ).gitManageBranches,
                  onReview: (_) {},
                  onLog: () {},
                  onBranches: () =>
                      git.GitWorkflowUi(context, session!).branches(),
                  onPush: () {},
                  onMore: (anchor) => git.GitWorkflowUi(anchor, session!).more(
                    showBranches: false,
                    includeRefresh: true,
                    showBranchOperations: false,
                  ),
                ),
              );
            },
          ),
        );
        addTearDown(() => session?.dispose());
        await session!.start();
        await tester.pumpAndSettle();
        final branch = find.ancestor(
          of: find.text(client.branch),
          matching: find.byType(git.GitActionRow),
        );
        expect(branch, findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.tooltip == 'Manage branches',
          ),
          findsOneWidget,
        );
        expect(find.byTooltip('Refresh'), findsNothing);
        expect(find.byTooltip(repo.root), findsNothing);
        expect(tester.widget<git.GitActionRow>(branch).dense, isTrue);
        expect(
          find.descendant(of: branch, matching: find.byType(TextButton)),
          findsNothing,
        );
        expect(
          tester.getRect(branch).height,
          greaterThanOrEqualTo(BusyMarkSizes.iconButton),
        );
        final branchText = tester.widget<Text>(find.text(client.branch));
        expect(branchText.maxLines, 1);
        expect(branchText.overflow, TextOverflow.ellipsis);
        await tester.tap(branch);
        await tester.pumpAndSettle();
        expect(find.byType(git.GitBranchesView), findsOneWidget);
        expect(find.byType(git.GitNativeDialog), findsOneWidget);
        expect(find.text('Local branches'), findsOneWidget);
        expect(find.text('Remote branches'), findsOneWidget);
        expect(find.text('Tags'), findsOneWidget);
        expect(find.text('New branch…'), findsOneWidget);
        expect(find.byType(DropdownButton<String>), findsNothing);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        final before = client.statusReads;
        await tester.tap(find.byTooltip('Actions'));
        await tester.pumpAndSettle();
        expect(entries, isNotNull);
        // The native service serializes indices, labels and enabled state. Labels
        // prove the actual host menu mapping; other workflow destinations survive.
        final labels = entries!.map((e) => (e as Map)['label']).toList();
        expect(labels, contains('Refresh'));
        expect(
          labels.whereType<String>().where((s) => s.startsWith('Branches')),
          isEmpty,
        );
        expect(labels, containsAll(['Fetch…', 'Pull…', 'Push…']));
        expect(client.statusReads, greaterThan(before));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Amend uses native desktop checkbox with one labelled target $brightness',
      (tester) async {
        final enabled = ValueNotifier(true), value = ValueNotifier(false);
        addTearDown(enabled.dispose);
        addTearDown(value.dispose);
        var changes = 0;
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          _nativeGitHarness(
            brightness: brightness,
            builder: (context, host) => Column(
              children: [
                // Established non-Git checkbox is the appearance reference.
                BusyMarkCheckbox(value: false, onChanged: (_) {}),
                ValueListenableBuilder<bool>(
                  valueListenable: enabled,
                  builder: (_, available, _) => ValueListenableBuilder<bool>(
                    valueListenable: value,
                    builder: (_, checked, _) => SizedBox(
                      width: 300,
                      child: git.GitCheckbox(
                        label: 'Amend last commit',
                        value: checked,
                        onChanged: available
                            ? (next) {
                                changes++;
                                value.value = next!;
                              }
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(YaruCheckButton), findsOneWidget);
        expect(find.byType(YaruCheckbox), findsNWidgets(2));
        expect(find.byType(Checkbox), findsNothing);
        final native = find.byType(YaruCheckbox);
        expect(tester.getSize(native.first), tester.getSize(native.last));
        await tester.tap(find.text('Amend last commit'));
        await tester.pumpAndSettle();
        expect(value.value, isTrue);
        expect(changes, 1);
        expect(tester.widget<YaruCheckbox>(native.last).value, isTrue);
        final node = tester.getSemantics(find.byType(YaruCheckButton));
        expect(node.label, contains('Amend last commit'));
        expect(
          node,
          matchesSemantics(
            label: 'Amend last commit',
            hasCheckedState: true,
            isChecked: true,
            hasEnabledState: true,
            isEnabled: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );
        final checkContext = tester.element(
          find
              .descendant(of: native.last, matching: find.byType(Semantics))
              .last,
        );
        Focus.of(checkContext).requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(value.value, isFalse);
        expect(changes, 2);
        enabled.value = false;
        await tester.pumpAndSettle();
        await tester.tap(find.text('Amend last commit'));
        await tester.pump();
        expect(changes, 2);
        expect(tester.widget<YaruCheckbox>(native.last).onChanged, isNull);
        semantics.dispose();
        expect(tester.takeException(), isNull);
      },
    );
  }
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
        var chosen = 0, authorized = 0, primaryCalls = 0;
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
                                  onPressed: () => primaryCalls++,
                                  child: const Text('Primary native action'),
                                ),
                                const git.GitButton.standard(
                                  onPressed: null,
                                  child: Text('Disabled native action'),
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
        expect(find.byType(BusyMarkGitTextEntry), findsOneWidget);
        expect(find.byType(TextFormField), findsNothing);
        expect(find.byType(YaruCheckbox), findsOneWidget);
        expect(find.byType(YaruCircularProgressIndicator), findsOneWidget);
        expect(find.byType(YaruLinearProgressIndicator), findsOneWidget);
        expect(find.byType(BusyMarkCompactIconButton), findsNothing);
        expect(find.byType(git.NativeGitIconAction), findsOneWidget);
        final iconFinder = find.descendant(
          of: find.byType(git.NativeGitIconAction),
          matching: find.byType(YaruIconButton),
        );
        expect(iconFinder, findsOneWidget);
        expect(
          tester.widget<YaruIconButton>(iconFinder).hasFocusBorder,
          isFalse,
        );
        final hit = tester.getRect(iconFinder);
        expect(hit.width, greaterThanOrEqualTo(BusyMarkSizes.iconButton));
        expect(hit.height, greaterThanOrEqualTo(BusyMarkSizes.iconButton));
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(DropdownButton<int>), findsNothing);
        final primaryAction = find.ancestor(
          of: find.text('Primary native action'),
          matching: find.byType(BusyMarkGitActionButton),
        );
        final disabledAction = find.ancestor(
          of: find.text('Disabled native action'),
          matching: find.byType(BusyMarkGitActionButton),
        );
        expect(primaryAction, findsOneWidget);
        expect(
          tester.widget<BusyMarkGitActionButton>(disabledAction).onPressed,
          isNull,
        );
        final focusBeforePointer = FocusManager.instance.primaryFocus;
        await tester.tap(primaryAction);
        await tester.pump();
        expect(primaryCalls, 1);
        expect(FocusManager.instance.primaryFocus, same(focusBeforePointer));
        final primaryFocus = tester
            .widget<FocusableActionDetector>(
              find.descendant(
                of: primaryAction,
                matching: find.byType(FocusableActionDetector),
              ),
            )
            .focusNode!;
        for (var step = 0; step < 20 && !primaryFocus.hasFocus; step++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
        }
        expect(primaryFocus.hasFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(primaryCalls, 2);
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
        await exerciseNativeGitNotification(tester, host: host);
        await exerciseNativeGitSurfaces(
          tester,
          host: host,
          nativeField: BusyMarkGitTextEntry,
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
          expect(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Semantics &&
                  widget.properties.tooltip == l10n.gitUiBranches,
            ),
            findsOneWidget,
          );
          expect(find.byType(BusyMarkCompactIconButton), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          session!.dispose();
        },
      );
    }
  }
  for (final locale in ['en', 'ar']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'native Git tree uses Files geometry and contextual actions $locale $scale',
        (tester) async {
          var opened = 0, toggled = 0, contexts = 0;
          await tester.pumpWidget(
            _nativeGitHarness(
              locale: Locale(locale),
              scale: scale,
              builder: (context, host) => SizedBox(
                width: 400,
                child: Column(
                  children: [
                    for (final depth in [0, 1, 2])
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: BusyMarkSpacing.sm,
                        ),
                        child: BusyMarkSidebarTreeRow(
                          title: 'Files $depth',
                          depth: depth,
                          icon: YaruIcons.document,
                          hasChildren: depth < 2,
                          expanded: true,
                        ),
                      ),
                    for (final depth in [0, 1, 2])
                      SizedBox(
                        height: host.rowHeight(context),
                        child: git.GitChangeRow(
                          title: 'Tree $depth',
                          depth: depth,
                          group: depth == 0,
                          expanded: depth < 2 ? true : null,
                          status: depth == 2
                              ? git.GitFileStatus.modified
                              : null,
                          onPointerDown: (_) {},
                          onTap: () => opened++,
                          onToggle: () => toggled++,
                          onSecondaryTapUp: (_) => contexts++,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final rows = find.byType(git.NativeGitTreeRow);
          expect(rows, findsNWidgets(3));
          expect(find.byType(git.NativeGitIconAction), findsNothing);
          expect(find.byType(BusyMarkCompactIconButton), findsNothing);
          for (var i = 0; i < 3; i++) {
            final reference = tester.getRect(find.text('Files $i'));
            final actual = tester.getRect(find.text('Tree $i'));
            expect(
              locale == 'ar' ? actual.right : actual.left,
              closeTo(locale == 'ar' ? reference.right : reference.left, .01),
            );
            final surface = find.descendant(
              of: rows.at(i),
              matching: find.byType(git.NativeGitRowSurface),
            );
            expect(
              tester.getRect(surface).left,
              greaterThanOrEqualTo(BusyMarkSpacing.sm),
            );
            expect(
              tester.getRect(rows.at(i)).height,
              tester.getRect(rows.first).height,
            );
            if (i > 0) {
              expect(
                locale == 'ar'
                    ? tester.getTopRight(find.text('Tree ${i - 1}')).dx -
                          tester.getTopRight(find.text('Tree $i')).dx
                    : tester.getTopLeft(find.text('Tree $i')).dx -
                          tester.getTopLeft(find.text('Tree ${i - 1}')).dx,
                closeTo(BusyMarkSizes.sidebarTreeDepthIndent, .01),
              );
            }
          }
          expect(find.text('M'), findsNothing);
          expect(
            tester.widget<Text>(find.text('Tree 2')).style!.color,
            isNotNull,
          );
          await tester.tap(find.text('Tree 2'), buttons: kSecondaryMouseButton);
          await tester.pump();
          expect(contexts, 1);
          expect(opened, 0);
          await tester.tap(
            find.descendant(
              of: rows.at(1),
              matching: find.byType(AnimatedRotation),
            ),
          );
          await tester.pump();
          expect(toggled, 1);
          expect(opened, 0);
          await tester.tap(find.text('Tree 2'));
          await tester.pump();
          expect(opened, 1);
          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await mouse.addPointer(
            location: tester.getCenter(find.text('Tree 2')),
          );
          await mouse.moveTo(tester.getCenter(find.text('Tree 2')));
          await tester.pump();
          expect(find.byType(git.NativeGitIconAction), findsNothing);
          expect(find.byType(BusyMarkCompactIconButton), findsNothing);
          await mouse.removePointer();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
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

void _noop() {}

Widget _nativeGitHarness({
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
          size: const Size(1200, 1000),
          textScaler: TextScaler.linear(scale),
        ),
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

class _CommitControlsClient extends FixtureClient {
  int statusReads = 0;
  final branch =
      'feature/very-long-branch-name-that-must-truncate-without-hiding-actions';
  final head = git.GitOid('1' * 40);
  @override
  Future<git.GitSnapshot> status(
    git.RepositoryId repository, {
    git.GitCancellation? cancellation,
    git.GitReadPolicy policy = git.GitReadPolicy.restricted,
  }) async {
    statusReads++;
    return git.GitSnapshot(
      repository: repository,
      head: head,
      branch: branch,
      token: 'status',
      indexToken: 'index',
      changes: const [],
      operation: const git.RepositoryOperation(git.GitOperationKind.none),
      observedAt: DateTime.utc(2026),
    );
  }

  @override
  Future<List<git.GitReference>> references(
    git.RepositoryId repository,
  ) async => [
    for (final name in [
      'refs/heads/main',
      'refs/remotes/origin/main',
      'refs/tags/v1',
    ])
      git.GitReference(name: name, oid: head),
  ];
}
