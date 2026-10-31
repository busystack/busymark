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
        expect(find.byType(BusyMarkCompactIconButton), findsOneWidget);
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
}
