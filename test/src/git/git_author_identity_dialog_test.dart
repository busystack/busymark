import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_toast.dart';
import 'package:busymark/src/git/application/git_controller.dart';
import 'package:busymark/src/git/domain/git_models.dart';
import 'package:busymark/src/git/presentation/git_author_identity_dialog.dart';
import 'package:busymark/src/git/presentation/git_sidebar_tab.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Enter submits Git identity and preserves global scope', (
    tester,
  ) async {
    GitAuthorIdentityInput? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildBusyMarkTheme(
          brightness: Brightness.light,
          accentColor: const Color(0xFFB34CB4),
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showGitAuthorIdentityDialog(context);
              },
              child: const Text('Commit'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Commit'));
    await tester.pumpAndSettle();
    expect(find.text('Git Author Identity'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Albert Gee');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.enterText(fields.at(1), 'albert@example.com');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.text('Git Author Identity'), findsNothing);
    expect(result?.name, 'Albert Gee');
    expect(result?.email, 'albert@example.com');
    expect(result?.globally, isTrue);
  });

  testWidgets('failed commit saves identity and retries the same commit', (
    tester,
  ) async {
    final controller = _IdentityRecoveryGitController();
    final workspace = Workspace(
      id: '/repo',
      rootPath: '/repo',
      kind: WorkspaceKind.markdownFolder,
      openedAt: DateTime(2026),
      files: const [],
      diagnostics: const [],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [gitControllerProvider.overrideWith(() => controller)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildBusyMarkTheme(
            brightness: Brightness.light,
            accentColor: const Color(0xFFB34CB4),
          ),
          home: BusyMarkToastOverlay(
            child: Scaffold(
              body: GitSidebarTab(
                workspace: workspace,
                onOpenFile: (_) {},
                onConfirmDiscard: (_) async => true,
                onAfterWorkspaceFilesChanged: () async {},
                onConfirmSwitchBranch: (_) async => true,
                onConfirmPushSetUpstream: () async => true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Document strict Git');
    await tester.pump();
    await tester.tap(find.text('Commit'));
    await tester.pumpAndSettle();
    expect(controller.commitMessages, ['Document strict Git']);
    expect(find.text('Git Author Identity'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Albert Gee');
    await tester.enterText(fields.at(1), 'albert@example.com');
    await tester.pump();
    await tester.tap(find.text('Save and Commit'));
    await tester.pumpAndSettle();

    expect(controller.commitMessages, [
      'Document strict Git',
      'Document strict Git',
    ]);
    expect(controller.configuredName, 'Albert Gee');
    expect(controller.configuredEmail, 'albert@example.com');
    expect(controller.configuredGlobally, isTrue);
  });
}

class _IdentityRecoveryGitController extends GitController {
  static const repository = GitRepositoryInfo(
    rootPath: '/repo',
    gitDirPath: '/repo/.git',
    currentBranch: 'main',
  );

  final commitMessages = <String>[];
  String? configuredName;
  String? configuredEmail;
  bool? configuredGlobally;

  @override
  GitState build() => const GitState(
    availability: GitAvailability(
      available: true,
      executablePath: '/snap/busymark/current/usr/bin/git',
      version: '2.50.0',
    ),
    repositoryInfo: repository,
    statusSnapshot: GitStatusSnapshot(
      repositoryInfo: repository,
      files: [
        GitFileStatus(
          repoRelativePath: 'README.md',
          absolutePath: '/repo/README.md',
          indexStatus: GitFileChangeStatus.modified,
          workTreeStatus: GitFileChangeStatus.unmodified,
          category: GitFileStatusCategory.modified,
          staged: true,
          unstaged: false,
          untracked: false,
          conflicted: false,
          renamed: false,
          copied: false,
          deleted: false,
          ignored: false,
        ),
      ],
    ),
  );

  @override
  Future<bool> commit(String message) async {
    commitMessages.add(message);
    if (commitMessages.length == 1) {
      state = state.copyWith(
        lastError: const GitFailure(
          code: GitFailureCode.authorIdentity,
          userMessageKey: 'gitErrorAuthorIdentity',
          rawMessage: 'Author identity unknown',
          commandName: 'commit',
        ),
      );
      return false;
    }
    state = state.copyWith(lastError: null, lastOperationMessage: 'Committed');
    return true;
  }

  @override
  Future<bool> configureAuthorIdentity({
    required String name,
    required String email,
    required bool globally,
  }) async {
    configuredName = name;
    configuredEmail = email;
    configuredGlobally = globally;
    state = state.copyWith(lastError: null);
    return true;
  }
}
