import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/system_accent.dart';
import 'package:busymark/src/git/application/git_controller.dart';
import 'package:busymark/src/git/domain/git_models.dart';
import 'package:busymark/src/git/presentation/git_sidebar_tab.dart';
import 'package:busymark/src/workspace/presentation/welcome_screen.dart';
import 'package:busymark/src/workspace/workspace_message.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaru/yaru.dart';

void main() {
  testWidgets('status colors stay semantic across accents and brightness', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      Map<BusyMarkStatusKind, Color>? colorsForFirstAccent;
      for (final accent in const [Color(0xFFE95420), Color(0xFF7764D8)]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildBusyMarkTheme(
              brightness: brightness,
              accentColor: accent,
            ),
            home: const Scaffold(
              body: SizedBox(key: ValueKey('status-color-probe')),
            ),
          ),
        );

        final context = tester.element(
          find.byKey(const ValueKey('status-color-probe')),
        );
        final semanticColors = YaruColors.of(context);
        final actual = <BusyMarkStatusKind, Color>{
          for (final kind in BusyMarkStatusKind.values)
            kind: busyMarkStatusColor(context, kind),
        };

        expect(actual, <BusyMarkStatusKind, Color>{
          BusyMarkStatusKind.information: semanticColors.link,
          BusyMarkStatusKind.success: semanticColors.success,
          BusyMarkStatusKind.warning: semanticColors.warning,
          BusyMarkStatusKind.error: semanticColors.error,
        });
        colorsForFirstAccent ??= actual;
        expect(actual, colorsForFirstAccent);
        expect(actual[BusyMarkStatusKind.information], isNot(accent));
      }
    }
  });

  test('workspace messages use semantic status roles', () {
    expect(
      busyMarkWorkspaceMessageStatusKind(
        WorkspaceMessageCode.chooseWhereToSaveMarkdown,
      ),
      BusyMarkStatusKind.information,
    );
    expect(
      busyMarkWorkspaceMessageStatusKind(
        WorkspaceMessageCode.saveBlockedFileChangedOnDisk,
      ),
      BusyMarkStatusKind.warning,
    );

    const operationalFailures = {
      WorkspaceMessageCode.openFailed,
      WorkspaceMessageCode.createWritersideProjectFailed,
      WorkspaceMessageCode.createWritersideTopicFailed,
      WorkspaceMessageCode.couldNotOpenFile,
      WorkspaceMessageCode.saveFailed,
      WorkspaceMessageCode.fileOperationFailed,
      WorkspaceMessageCode.validationFailed,
    };
    for (final code in operationalFailures) {
      expect(
        busyMarkWorkspaceMessageStatusKind(code),
        BusyMarkStatusKind.error,
        reason: '$code is an operational failure',
      );
    }
  });

  testWidgets('Git failures use their semantic status roles', (tester) async {
    const cases = {
      GitFailureCode.commandFailed: BusyMarkStatusKind.error,
      GitFailureCode.dirtyWorkspace: BusyMarkStatusKind.warning,
      GitFailureCode.stagedChanges: BusyMarkStatusKind.warning,
      GitFailureCode.detachedHead: BusyMarkStatusKind.warning,
      GitFailureCode.noUpstream: BusyMarkStatusKind.information,
    };

    for (final entry in cases.entries) {
      await tester.pumpWidget(
        _testApp(
          _gitSidebar(
            GitFailure(
              code: entry.key,
              userMessageKey: 'unused',
              rawMessage: '',
              commandName: 'test',
            ),
          ),
        ),
      );
      await tester.pump();

      final status = tester.widget<BusyMarkStatusBox>(
        find.byType(BusyMarkStatusBox),
      );
      expect(status.kind, entry.value, reason: '${entry.key}');
    }
  });

  testWidgets('successful Git operations use the success role', (tester) async {
    await tester.pumpWidget(_testApp(_gitSidebar(null, message: 'Done')));
    await tester.pump();

    final status = tester.widget<BusyMarkStatusBox>(
      find.byType(BusyMarkStatusBox),
    );
    expect(status.kind, BusyMarkStatusKind.success);
  });
}

Widget _gitSidebar(GitFailure? failure, {String? message}) {
  const repository = GitRepositoryInfo(
    rootPath: '/repo',
    gitDirPath: '/repo/.git',
  );
  final state = GitState(
    availability: const GitAvailability(
      available: true,
      executablePath: '/usr/bin/git',
      version: '2.50.0',
    ),
    repositoryInfo: repository,
    statusSnapshot: const GitStatusSnapshot(
      repositoryInfo: repository,
      files: [],
    ),
    lastError: failure,
    lastOperationMessage: message,
  );
  return ProviderScope(
    key: ValueKey((failure?.code, message)),
    overrides: [
      gitControllerProvider.overrideWith(() => _PresetGitController(state)),
    ],
    child: GitSidebarTab(
      workspace: Workspace(
        id: '/repo',
        rootPath: '/repo',
        kind: WorkspaceKind.markdownFolder,
        openedAt: DateTime(2026),
        files: const [],
        diagnostics: const [],
      ),
      onOpenFile: (_) {},
      onConfirmDiscard: (_) async => true,
      onAfterWorkspaceFilesChanged: () async {},
      onConfirmSwitchBranch: (_) async => true,
      onConfirmPushSetUpstream: () async => true,
    ),
  );
}

Widget _testApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildBusyMarkTheme(
      brightness: Brightness.light,
      accentColor: busyMarkDefaultAccentColor,
    ),
    home: Scaffold(body: child),
  );
}

class _PresetGitController extends GitController {
  _PresetGitController(this.initialState);

  final GitState initialState;

  @override
  GitState build() => initialState;
}
