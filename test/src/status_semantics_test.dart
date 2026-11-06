import 'package:busystack_git_flutter/busystack_git_flutter.dart' as shared;
import 'package:busymark/src/git/application/shared_git_integration.dart';
import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/system_accent.dart';
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

  testWidgets(
    'shared Git failures retain diagnostics and copy in the native surface',
    (tester) async {
      await tester.pumpWidget(_testApp(const _GitHostProbe(failed: true)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Diagnostics'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Author identity unknown'), findsOneWidget);
      expect(find.text('Copy diagnostics'), findsOneWidget);
      expect(find.byType(BusyMarkStatusBox), findsNothing);
    },
  );

  testWidgets(
    'Git host notifications use the shared native surface without a host toast',
    (tester) async {
      await tester.pumpWidget(_testApp(const _GitHostProbe()));
      await tester.tap(find.text('Notify'));
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      expect(find.text('Done'), findsOneWidget);
      expect(find.byType(shared.NativeGitNotificationSurface), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(BusyMarkStatusBox), findsNothing);
    },
  );
}

class _GitHostProbe extends ConsumerWidget {
  const _GitHostProbe({this.failed = false});
  final bool failed;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final host = busyMarkGitHost(
      context,
      ref,
      Workspace(
        id: '/repo',
        rootPath: '/repo',
        kind: WorkspaceKind.markdownFolder,
        openedAt: DateTime.utc(2026),
        files: const [],
        diagnostics: const [],
      ),
      isMounted: () => context.mounted,
    );
    return shared.GitHostScope(
      host: host,
      child: failed
          ? const shared.GitFailurePanel(
              error: shared.GitException(
                shared.GitErrorCode.authorIdentity,
                diagnostic: 'Author identity unknown',
              ),
            )
          : shared.GitButton(
              onPressed: () => host.notify('Done'),
              child: const Text('Notify'),
            ),
    );
  }
}

Widget _testApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildBusyMarkTheme(
        brightness: Brightness.light,
        accentColor: busyMarkDefaultAccentColor,
      ),
      home: Scaffold(body: child),
    ),
  );
}
