import '../../support/widget_async.dart';
import 'dart:async';
import 'dart:convert';
import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/git/application/shared_git_integration.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/app/git_dismissal.dart';
import 'package:busystack_git_flutter/busystack_git_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../busystack_git_flutter/test/support/presentation_fixture.dart'
    as fixture;
import '../../../../busystack_git_flutter/test/conflict_editor_test.dart'
    as conflict_fixture;

class _IndexClient extends fixture.FixtureClient {
  @override
  Future<GitContent> content(
    RepositoryId repository,
    RepoPath path,
    ContentVersion version, {
    GitCancellation? cancellation,
  }) async => GitContent(
    path: path,
    version: version,
    availability: ContentAvailability.present,
    token: version.kind.name,
    mode: '100644',
    bytes: utf8.encode('one\nold\nend\n'),
  );
}

void main() {
  for (final conflict in [false, true]) {
    for (final (closeKind, beforeFrame) in [
      for (final kind
          in (conflict
              ? ['Close', 'window']
              : ['Close', 'Escape', 'Back', 'window']))
        (kind, false),
      ('Close', true),
    ]) {
      testWidgets(
        'actual BusyMark $closeKind${beforeFrame ? ' before frame' : ''} protects dirty ${conflict ? 'conflict' : 'index'} draft',
        (tester) async {
          tester.view.physicalSize = const Size(1440, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final client = conflict
              ? conflict_fixture.ConflictClient()
              : _IndexClient();
          late GitSession session;
          late WidgetRef appRef;
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sharedGitDraftStoreProvider.overrideWithValue(
                  MemoryGitDraftStore(),
                ),
              ],
              child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: Consumer(
                    builder: (context, ref, _) {
                      appRef = ref;
                      return TextButton(
                        onPressed: () async {
                          final workspace = Workspace(
                            id: 'test',
                            rootPath: '/fixture/repo',
                            kind: WorkspaceKind.markdownFolder,
                            openedAt: DateTime.utc(2026),
                            files: [],
                            diagnostics: [],
                          );
                          final host = busyMarkGitHost(
                            context,
                            ref,
                            workspace,
                            isMounted: () => context.mounted,
                          );
                          session = GitSession(
                            client: client,
                            repository: fixture.repo,
                            host: host,
                          );
                          await session.start();
                          if (context.mounted) {
                            unawaited(
                              host.present<void>(
                                context,
                                'Index review',
                                conflict
                                    ? GitConflictView(
                                        session: session,
                                        path: RepoPath.text('prose.md'),
                                      )
                                    : GitIndexEditor(
                                        session: session,
                                        path: RepoPath.text('chapter/notes.md'),
                                        computeDiff: (a, b) async =>
                                            computeTextDiff(a, b),
                                      ),
                                expanded: true,
                              ),
                            );
                          }
                        },
                        child: const Text('Open index'),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open index'));
          await pumpUntil(
            tester,
            () => find
                .byWidgetPredicate((w) => w is TextField && !w.readOnly)
                .evaluate()
                .isNotEmpty,
            operation: 'load source snapshots and editable result',
          );
          await tester.pumpAndSettle();
          final editor = find
              .byType(TextField)
              .evaluate()
              .map((e) => e.widget as TextField)
              .where((w) => !w.readOnly)
              .toList();
          expect(
            editor,
            hasLength(1),
            reason: tester.allWidgets
                .whereType<Text>()
                .map((t) => t.data)
                .toList()
                .toString(),
          );
          final editorFinder = find.byWidget(editor.single);
          final initialText = editor.single.controller!.text;
          await tester.enterText(editorFinder, 'one\nmanual draft\nend\n');
          if (!beforeFrame) await tester.pump();
          final controller = editor.single.controller!;
          controller.selection = const TextSelection(
            baseOffset: 4,
            extentOffset: 10,
          );
          final value = controller.value;
          final originalClose = tester
              .widgetList<IconButton>(find.byType(IconButton))
              .firstWhere((b) => b.tooltip == 'Close')
              .onPressed!;
          Future<void> close() async {
            switch (closeKind) {
              case 'Close':
                await tester.tap(find.byTooltip('Close').first);
              case 'Escape':
                await tester.sendKeyEvent(LogicalKeyboardKey.escape);
              case 'Back':
                await tester.binding.handlePopRoute();
              case 'window':
                unawaited(
                  appRef.read(busyMarkGitDismissalProvider).mayDismiss(),
                );
            }
            await tester.pumpAndSettle();
          }

          await close();
          expect(
            find.text(
              conflict
                  ? 'Discard unsaved conflict result?'
                  : 'Discard unsaved index draft?',
            ),
            findsOneWidget,
          );
          // An old queued close activation must not complete the confirmation or
          // remove its parent editor; the original button remains behind it.
          if (closeKind == 'Close') {
            originalClose();
            await tester.pump();
            expect(
              find.text(
                conflict
                    ? 'Discard unsaved conflict result?'
                    : 'Discard unsaved index draft?',
              ),
              findsOneWidget,
            );
          }
          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();
          expect(controller.value, value);
          if (closeKind == 'Close') {
            await tester.tap(
              find.byWidgetPredicate(
                (w) => w is TextField && identical(w.controller, controller),
              ),
            );
            Future<void> historyKey({bool redo = false}) async {
              await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
              if (redo) {
                await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
              }
              await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
              if (redo) {
                await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
              }
              await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
              await tester.pump();
            }

            await historyKey();
            expect(controller.text, initialText);
            await historyKey(redo: true);
            expect(controller.text, value.text);
          }
          expect(
            find.byType(conflict ? GitConflictView : GitIndexEditor),
            findsOneWidget,
          );
          expect(client.mutations, isEmpty);
          await close();
          await tester.tap(
            find.text(
              conflict ? 'Discard conflict draft' : 'Discard index draft',
            ),
          );
          await tester.pumpAndSettle();
          if (closeKind != 'window') {
            expect(
              find.byType(conflict ? GitConflictView : GitIndexEditor),
              findsNothing,
            );
          }
          expect(find.text('Open index'), findsOneWidget);
          expect(client.mutations, isEmpty);
          await tester.pumpWidget(const SizedBox());
          session.dispose();
        },
      );
    }
  }
}
