import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/core/busymark_exception.dart';
import 'package:busymark/src/workspace/presentation/writerside_markdown_import_dialog.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/workspace/workspace_message.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/writerside/writerside_instance_service.dart';
import 'package:busymark/src/writerside/writerside_topic_creator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('selects all candidates by default and disables OK for none', (
    tester,
  ) async {
    const candidates = [
      WritersideMarkdownImportCandidate(
        absolutePath: '/source/a.md',
        relativePath: 'a.md',
        title: 'Alpha',
      ),
      WritersideMarkdownImportCandidate(
        absolutePath: '/source/nested/b.md',
        relativePath: 'nested/b.md',
        title: 'Beta',
      ),
    ];
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: WritersideMarkdownImportDialog(
              sourceRootPath: '/source',
              candidates: candidates,
              treePath: '/module/guide.tree',
              placement: WritersideTopicCreatePlacement.root,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Add Local Markdown Files'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('nested/b.md'), findsOneWidget);
    expect(
      tester
          .widgetList<BusyMarkCheckbox>(find.byType(BusyMarkCheckbox))
          .map((checkbox) => checkbox.value),
      everyElement(true),
    );
    expect(
      tester
          .widget<BusyMarkDialogButton>(
            find.widgetWithText(BusyMarkDialogButton, 'OK'),
          )
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.text('Select none'));
    await tester.pump();
    expect(
      tester
          .widgetList<BusyMarkCheckbox>(find.byType(BusyMarkCheckbox))
          .map((checkbox) => checkbox.value),
      everyElement(false),
    );
    expect(
      tester
          .widget<BusyMarkDialogButton>(
            find.widgetWithText(BusyMarkDialogButton, 'OK'),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('Alpha'));
    await tester.pump();
    expect(
      tester
          .widget<BusyMarkDialogButton>(
            find.widgetWithText(BusyMarkDialogButton, 'OK'),
          )
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.text('Select all'));
    await tester.pump();
    expect(
      tester
          .widgetList<BusyMarkCheckbox>(find.byType(BusyMarkCheckbox))
          .map((checkbox) => checkbox.value),
      everyElement(true),
    );
  });

  testWidgets('successful import closes the dialog with selected list order', (
    tester,
  ) async {
    final controller = _ImportController(succeeds: true);
    await _pumpImportDialog(tester, controller);

    await tester.tap(find.widgetWithText(BusyMarkDialogButton, 'OK'));
    await tester.pumpAndSettle();

    expect(find.byType(WritersideMarkdownImportDialog), findsNothing);
    expect(controller.requests, hasLength(1));
    expect(controller.requests.single.selectedMarkdownPaths, [
      '/source/a.md',
      '/source/nested/b.md',
    ]);
  });

  testWidgets('failed import stays open and presents the localized error', (
    tester,
  ) async {
    final controller = _ImportController(succeeds: false);
    await _pumpImportDialog(tester, controller);

    await tester.tap(find.widgetWithText(BusyMarkDialogButton, 'OK'));
    await tester.pumpAndSettle();

    expect(find.byType(WritersideMarkdownImportDialog), findsOneWidget);
    expect(find.byType(BusyMarkStatusBox), findsOneWidget);
    expect(find.textContaining('guide'), findsOneWidget);
    expect(controller.requests, hasLength(1));
  });
}

const _candidates = [
  WritersideMarkdownImportCandidate(
    absolutePath: '/source/a.md',
    relativePath: 'a.md',
    title: 'Alpha',
  ),
  WritersideMarkdownImportCandidate(
    absolutePath: '/source/nested/b.md',
    relativePath: 'nested/b.md',
    title: 'Beta',
  ),
];

Future<void> _pumpImportDialog(
  WidgetTester tester,
  _ImportController controller,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [workspaceControllerProvider.overrideWith(() => controller)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (_) => const WritersideMarkdownImportDialog(
                  sourceRootPath: '/source',
                  candidates: _candidates,
                  treePath: '/module/guide.tree',
                  placement: WritersideTopicCreatePlacement.root,
                ),
              ),
              child: const Text('Launch'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Launch'));
  await tester.pumpAndSettle();
}

class _ImportController extends WorkspaceController {
  _ImportController({required this.succeeds});

  final bool succeeds;
  final requests = <WritersideMarkdownTopicImportRequest>[];

  @override
  WorkspaceState build() => const WorkspaceState();

  @override
  Future<bool> addWritersideMarkdownTopics(
    WritersideMarkdownTopicImportRequest request,
  ) async {
    requests.add(request);
    if (!succeeds) {
      state = state.copyWith(
        message: const WorkspaceMessage(
          WorkspaceMessageCode.fileOperationFailed,
          error: BusyMarkException(
            'writerside.topic.id-exists',
            args: {'topicId': 'guide'},
          ),
        ),
      );
    }
    return succeeds;
  }
}
