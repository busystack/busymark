import 'package:busymark/src/editor/link_destination.dart';
import 'package:busymark/src/nextcloud_notes/presentation/notes_workspace_ui.dart';
import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/references/reference_controller.dart';
import 'package:busymark/src/references/reference_index.dart';
import 'package:busymark/src/references/reference_ui.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FixtureIndex extends ReferenceController {
  FixtureIndex(this.index);
  final ReferenceIndex index;
  @override
  void refresh() {}
  @override
  AsyncValue<ReferenceIndex> build() => AsyncData(index);
}

class FixtureWorkspace extends WorkspaceController {
  @override
  Future<bool> openActiveFile(String path) async => true;
  @override
  WorkspaceState build() => WorkspaceState(
    workspace: Workspace(
      id: 'fixture',
      rootPath: '/workspace',
      kind: WorkspaceKind.markdownFolder,
      openedAt: DateTime(2026),
      files: const [],
      diagnostics: const [],
    ),
    activeBufferId: 'source',
    documentBuffers: [
      DocumentBuffer(
        id: 'source',
        filePath: '/workspace/source.md',
        text: 'source',
        lastSavedText: 'source',
        dirty: false,
      ),
    ],
  );
}

void main() {
  final index = ReferenceIndex(
    root: '/workspace',
    parsed: [
      ParsedReferenceDocument(
        const ReferenceDocument(
          identity: '/workspace/source.md',
          path: '/workspace/source.md',
          title: 'Source',
          source: '[target](target.md#actual)',
        ),
      ),
      ParsedReferenceDocument(
        const ReferenceDocument(
          identity: '/workspace/target.md',
          path: '/workspace/target.md',
          title: 'Target',
          source: '# Actual',
        ),
      ),
    ],
  );
  Widget app(Widget home) => ProviderScope(
    overrides: [
      referenceIndexProvider.overrideWith(() => FixtureIndex(index)),
      workspaceControllerProvider.overrideWith(FixtureWorkspace.new),
      refactoringRecoveryProvider.overrideWith((_) async => []),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: home),
    ),
  );
  testWidgets('panel shows scope, outgoing status and incoming switch', (
    tester,
  ) async {
    await tester.pumpWidget(app(const ReferencesPanel()));
    await tester.pumpAndSettle();
    expect(find.text('/workspace'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);
    expect(find.textContaining('Resolved'), findsOneWidget);
    await tester.tap(find.text('Incoming'));
    await tester.pumpAndSettle();
    expect(find.text('Target'), findsNothing);
  });
  testWidgets(
    'stale source occurrence refreshes without selecting unrelated text',
    (tester) async {
      await tester.pumpWidget(app(const ReferencesPanel()));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PopupMenuButton<bool>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Source location'));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ReferencesPanel)),
      );
      expect(container.read(notesMatchNavigationProvider), isNull);
    },
  );
  testWidgets(
    'chooser searches actual heading targets and preserves manual URLs',
    (tester) async {
      LinkDestination? result;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showReferenceLinkChooser(context);
              },
              child: const Text('Choose'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Choose'));
      await tester.pumpAndSettle();
      expect(find.text('Choose link target'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'Actual');
      await tester.pumpAndSettle();
      expect(find.text('Actual'), findsWidgets);
      await tester.tap(find.text('target.md#actual'));
      await tester.pumpAndSettle();
      expect(result?.href, 'target.md#actual');
      await tester.tap(find.text('Choose'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).first,
        'https://example.com/manual',
      );
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(result?.href, 'https://example.com/manual');
    },
  );
}
