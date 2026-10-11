import 'package:busymark/src/editor/link_destination.dart';
import 'package:busymark/src/app/app_settings.dart';
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

class NavigableFixtureWorkspace extends FixtureWorkspace {
  NavigableFixtureWorkspace(this.index);
  final ReferenceIndex index;
  DocumentViewModePreference? navigatedMode;
  @override
  void updateActiveEditorMode(DocumentViewModePreference mode) {
    navigatedMode = mode;
  }

  @override
  WorkspaceState build() => super.build().copyWith(
    documentBuffers: [
      DocumentBuffer(
        id: 'source',
        filePath: '/workspace/source.md',
        text: index.documents['/workspace/source.md']!.source,
        lastSavedText: index.documents['/workspace/source.md']!.source,
        dirty: false,
      ),
    ],
  );
  @override
  Future<bool> openActiveFile(String path) async {
    final doc = index.documents[path]!;
    state = state.copyWith(
      activeBufferId: path,
      documentBuffers: [
        ...state.documentBuffers.where((b) => b.id != path),
        DocumentBuffer(
          id: path,
          filePath: path,
          text: doc.source,
          lastSavedText: doc.source,
          dirty: false,
        ),
      ],
    );
    return true;
  }
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
  for (final heading in [
    (source: '# Café', id: 'café', label: 'Café'),
    (
      source: '# Explicit {id="élément%20id"}',
      id: 'élément%20id',
      label: 'Explicit',
    ),
  ]) {
    testWidgets('chooser → index → exact target navigation: ${heading.id}', (
      tester,
    ) async {
      final target = ParsedReferenceDocument(
        ReferenceDocument(
          identity: '/workspace/target.md',
          path: '/workspace/target.md',
          title: 'Target',
          source: heading.source,
        ),
      );
      final chooserIndex = ReferenceIndex(
        root: '/workspace',
        parsed: [
          ParsedReferenceDocument(
            const ReferenceDocument(
              identity: '/workspace/source.md',
              path: '/workspace/source.md',
              title: 'Source',
              source: 'source',
            ),
          ),
          target,
        ],
      );
      Widget scoped(
        Widget child,
        ReferenceIndex value, {
        bool navigate = false,
      }) => ProviderScope(
        overrides: [
          referenceIndexProvider.overrideWith(() => FixtureIndex(value)),
          workspaceControllerProvider.overrideWith(
            () => navigate
                ? NavigableFixtureWorkspace(value)
                : FixtureWorkspace(),
          ),
          refactoringRecoveryProvider.overrideWith((_) async => []),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        ),
      );
      LinkDestination? result;
      await tester.pumpWidget(
        scoped(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  result = await showReferenceLinkChooser(context),
              child: const Text('Choose'),
            ),
          ),
          chooserIndex,
        ),
      );
      await tester.tap(find.text('Choose'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, heading.label);
      await tester.pumpAndSettle();
      final href = 'target.md#${Uri.encodeComponent(heading.id)}';
      await tester.tap(find.text(href));
      await tester.pumpAndSettle();
      expect(result!.href, href);
      final source = ParsedReferenceDocument(
        ReferenceDocument(
          identity: '/workspace/source.md',
          path: '/workspace/source.md',
          title: 'Source',
          source: '[chosen](${result!.href})',
        ),
      );
      final resolved = ReferenceIndex(
        root: '/workspace',
        parsed: [source, target],
      );
      expect(
        resolved.references.single.resolution,
        ReferenceResolution.resolved,
      );
      expect(
        resolved
            .query(target.document.identity, incoming: true, anchor: heading.id)
            .total,
        1,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        scoped(const ReferencesPanel(), resolved, navigate: true),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PopupMenuButton<bool>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Target location'));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ReferencesPanel)),
      );
      final navigation = container.read(notesMatchNavigationProvider)!;
      expect(navigation.localId, target.document.identity);
      expect(navigation.start, target.headings.single.span.startOffset);
      expect(navigation.end, target.headings.single.span.endOffset);
      expect(navigation.digest, target.document.revision);
      expect(
        (container.read(workspaceControllerProvider.notifier)
                as NavigableFixtureWorkspace)
            .navigatedMode,
        DocumentViewModePreference.source,
      );
    });
  }
}
