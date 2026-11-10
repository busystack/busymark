// The retired app-owned identity form is replaced by the real shared workflow.
import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/git/application/shared_git_integration.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busystack_git_flutter/busystack_git_flutter.dart' as git;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../busystack_git_flutter/test/support/presentation_fixture.dart'
    as fixture;

class _IdentityClient extends fixture.FixtureClient
    implements git.GitWorkflowClient {
  @override
  Future<git.Json> inspect(
    git.RepositoryId repository,
    git.GitInspection request, {
    git.GitCancellation? cancellation,
    void Function(git.GitProgress)? onProgress,
  }) async => {'name': '', 'email': '', 'hooks': <String>[]};
  @override
  Future<git.GitCreationOutcome> create(
    git.GitCreation request, {
    git.GitCancellation? cancellation,
    void Function(git.GitProgress)? onProgress,
  }) => throw StateError('Identity form cannot create a repository.');
}

void main() {
  testWidgets(
    'Enter moves to email and saves the reviewed shared repository identity once',
    (tester) async {
      tester.view.physicalSize = const Size(1100, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final client = _IdentityClient();
      git.GitSession? session;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedGitDraftStoreProvider.overrideWithValue(
              git.MemoryGitDraftStore(),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildBusyMarkTheme(
              brightness: Brightness.light,
              accentColor: const Color(0xFFB34CB4),
            ),
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final host = busyMarkGitHost(
                    context,
                    ref,
                    Workspace(
                      id: '/fixture/repo',
                      rootPath: '/fixture/repo',
                      kind: WorkspaceKind.markdownFolder,
                      openedAt: DateTime.utc(2026),
                      files: [],
                      diagnostics: [],
                    ),
                    isMounted: () => context.mounted,
                  );
                  // This form fixture approves only the identity write; shipping safety
                  // remains exercised by shared_host_dismissal and real adapter tests.
                  final formHost = git.GitHost(
                    presentation: host.presentation,
                    icons: host.icons,
                    presentMenu: host.presentMenu,
                    present: <T>(context, title, child, {expanded = false}) =>
                        host.present<T>(
                          context,
                          title,
                          child,
                          expanded: expanded,
                        ),
                    openDocument: host.openDocument,
                    prepareMutation: (_, request) async =>
                        request is git.ConfigureIdentity,
                    chooseDirectory: host.chooseDirectory,
                    notify: host.notify,
                    drafts: git.MemoryGitDraftStore(),
                  );
                  return git.GitHostScope(
                    host: formHost,
                    child: Builder(
                      builder: (context) => git.GitButton(
                        onPressed: () async {
                          session = git.GitSession(
                            client: client,
                            repository: fixture.repo,
                            host: formHost,
                          );
                          await session!.start();
                          if (context.mounted) {
                            await formHost.present<void>(
                              context,
                              git.GitMessages.commitIdentityAndHooks,
                              git.GitIdentityView(session: session!),
                            );
                          }
                        },
                        child: const Text('Inspect identity'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Inspect identity'));
      await tester.pumpAndSettle();
      final fields = find.descendant(
        of: find.byType(git.GitIdentityView),
        matching: find.byType(EditableText),
      );
      expect(fields, findsNWidgets(2));
      await tester.enterText(fields.at(0), 'Example Author');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(
        tester.widget<EditableText>(fields.at(1)).focusNode.hasFocus,
        isTrue,
      );
      await tester.enterText(fields.at(1), 'author@example.invalid');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.byType(git.GitIdentityView), findsNothing);
      final write = client.mutations.single as git.ConfigureIdentity;
      expect(write.name, 'Example Author');
      expect(write.email, 'author@example.invalid');
      expect(write.expectedIndex, 'index');
      expect(client.mutations.whereType<git.CommitIndex>(), isEmpty);
      await tester.pumpWidget(const SizedBox());
      session?.dispose();
    },
  );
}
