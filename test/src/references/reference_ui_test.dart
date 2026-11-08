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
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:busymark/src/app/busymark_design.dart';
import '../../support/native_menu_probe.dart';
import 'package:yaru/yaru.dart';
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
  Future<bool> openActiveFile(
    String path, {
    bool Function()? acceptNavigation,
  }) async => acceptNavigation?.call() != false;
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
  Future<bool> openActiveFile(
    String path, {
    bool Function()? acceptNavigation,
  }) async {
    if (acceptNavigation?.call() == false) return false;
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

class UntitledFixtureWorkspace extends FixtureWorkspace {
  @override
  WorkspaceState build() => super.build().copyWith(
    documentBuffers: [
      DocumentBuffer(
        id: 'source',
        untitledName: 'Untitled',
        text: '',
        lastSavedText: '',
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
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(app(const ReferencesPanel()));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.byKey(const ValueKey('references-scope'))).label,
      'Scope: Whole document',
    );
    expect(find.text('source.md'), findsOneWidget);
    expect(find.text('/workspace'), findsNothing);
    expect(find.text('Target'), findsOneWidget);
    expect(find.textContaining('Resolved'), findsOneWidget);
    await tester.tap(find.text('Incoming'));
    await tester.pumpAndSettle();
    expect(find.text('Target'), findsNothing);
    semantics.dispose();
  });
  testWidgets('an active untitled document has an accurate empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          referenceIndexProvider.overrideWith(() => FixtureIndex(index)),
          workspaceControllerProvider.overrideWith(
            UntitledFixtureWorkspace.new,
          ),
          refactoringRecoveryProvider.overrideWith((_) async => []),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: ReferencesPanel()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(ReferencesPanel));
    final l10n = AppLocalizations.of(context);
    expect(find.text(l10n.referenceNoResults), findsOneWidget);
    expect(find.text(l10n.referenceNoActiveDocument), findsNothing);
    expect(find.text('Untitled'), findsOneWidget);
  });
  testWidgets(
    'stale source occurrence refreshes without selecting unrelated text',
    (tester) async {
      await tester.pumpWidget(app(const ReferencesPanel()));
      await tester.pumpAndSettle();
      await selectReferenceContext(tester, 0);
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
      await tester.enterText(find.byType(EditableText).last, 'Actual');
      await tester.pumpAndSettle();
      expect(find.text('Actual'), findsWidgets);
      await tester.tap(find.text('target.md#actual'));
      await tester.pumpAndSettle();
      expect(result?.href, 'target.md#actual');
      await tester.tap(find.text('Choose'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(EditableText).first,
        'https://example.com/manual',
      );
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(result?.href, 'https://example.com/manual');
    },
  );
  testWidgets(
    'native scope and direction preserve documents and clear document-specific anchors',
    (tester) async {
      final scopedIndex = ReferenceIndex(
        root: '/workspace',
        parsed: [
          ParsedReferenceDocument(
            const ReferenceDocument(
              identity: '/workspace/source.md',
              path: '/workspace/source.md',
              title: 'Source',
              source:
                  '# One\n\n[first](target.md)\n\n# Two\n\n[second](target.md)',
            ),
          ),
          ParsedReferenceDocument(
            const ReferenceDocument(
              identity: '/workspace/target.md',
              path: '/workspace/target.md',
              title: 'Target',
              source: '# Destination\n\n[back](source.md#one)',
            ),
          ),
        ],
      );
      final controller = NavigableFixtureWorkspace(scopedIndex);
      final container = ProviderContainer(
        overrides: [
          referenceIndexProvider.overrideWith(() => FixtureIndex(scopedIndex)),
          workspaceControllerProvider.overrideWith(() => controller),
          refactoringRecoveryProvider.overrideWith((_) async => []),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SizedBox(width: 300, child: ReferencesPanel()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final original = container
          .read(workspaceControllerProvider)
          .activeBuffer!
          .text;
      expect(find.text('source.md'), findsOneWidget);
      expect(find.byType(BusyMarkSidebarRecordRow<bool>), findsNWidgets(2));
      expect(find.byType(SegmentedButton<bool>), findsNothing);
      expect(find.byType(DropdownButton<String>), findsNothing);
      expect(find.byType(ListTile), findsNothing);
      expect(find.byType(PopupMenuButton<bool>), findsNothing);
      expect(find.byType(TextButton), findsNothing);
      final menu = NativeMenuProbe(tester);
      await tester.tap(find.byKey(const ValueKey('references-scope')));
      await tester.pumpAndSettle();
      expect(
        menu.entries.map((e) => e['label']),
        containsAll(['Whole document', 'One', 'Two']),
      );
      expect(
        menu.entries.singleWhere(
          (e) => e['label'] == 'Whole document',
        )['selected'],
        isTrue,
      );
      await menu.activate('One');
      await tester.pumpAndSettle();
      expect(find.text('Scope: One'), findsOneWidget);
      expect(find.byType(BusyMarkSidebarRecordRow<bool>), findsOneWidget);
      expect(find.textContaining('first'), findsOneWidget);
      await tester.tap(find.text('Incoming'));
      await tester.pumpAndSettle();
      expect(find.textContaining('back'), findsOneWidget);
      expect(
        container.read(workspaceControllerProvider).activeBuffer!.text,
        original,
      );
      await controller.openActiveFile('/workspace/target.md');
      await tester.pumpAndSettle();
      expect(find.text('target.md'), findsOneWidget);
      expect(find.text('Scope: Whole document'), findsOneWidget);
      expect(find.byType(BusyMarkSidebarRecordRow<bool>), findsNWidgets(2));
      // Incoming is retained; querying target's outgoing would return one row.
      expect(
        tester.widget<YaruTabBar>(find.byType(YaruTabBar)).tabController!.index,
        0,
      );
      await tester.tap(find.text('Outgoing'));
      await tester.pumpAndSettle();
      expect(find.byType(BusyMarkSidebarRecordRow<bool>), findsOneWidget);
      await tester.tap(find.byType(BusyMarkSidebarRecordRow<bool>));
      await tester.pumpAndSettle();
      expect(
        container.read(workspaceControllerProvider).activeBuffer!.filePath,
        '/workspace/source.md',
      );
      expect(
        container.read(notesMatchNavigationProvider)?.digest,
        scopedIndex.documents['/workspace/source.md']!.revision,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty document has accurate context and an empty native state', (
    tester,
  ) async {
    final empty = ProviderContainer(
      overrides: [
        workspaceControllerProvider.overrideWith(EmptyFixtureWorkspace.new),
        referenceIndexProvider.overrideWith(() => FixtureIndex(index)),
        refactoringRecoveryProvider.overrideWith((_) async => []),
      ],
    );
    addTearDown(empty.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: empty,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: ReferencesPanel()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('References'), findsOneWidget);
    expect(find.text('No active document'), findsOneWidget);
    expect(find.text('source.md'), findsNothing);
    expect(find.byType(BusyMarkSidebarRecordRow<bool>), findsNothing);
  });

  testWidgets('native loading error retry and recovery stay available', (
    tester,
  ) async {
    final loader = RecoverableFixtureIndex(index);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workspaceControllerProvider.overrideWith(FixtureWorkspace.new),
          referenceIndexProvider.overrideWith(() => loader),
          refactoringRecoveryProvider.overrideWith(
            (_) async => ['pending-journal'],
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: ReferencesPanel()),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(YaruCircularProgressIndicator), findsOneWidget);
    loader.fail();
    await tester.pumpAndSettle();
    expect(find.textContaining('reference fixture failure'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(loader.retries, 1);
    expect(find.byType(BusyMarkSidebarRecordRow<bool>), findsOneWidget);
    expect(find.text('Recovery'), findsOneWidget);
  });

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
      await tester.enterText(find.byType(EditableText).last, heading.label);
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
      await selectReferenceContext(tester, 1);
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

Future<void> selectReferenceContext(WidgetTester tester, int choice) async {
  final menus = <MethodCall>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('busymark/native_menus'),
    (call) async {
      menus.add(call);
      return call.method == 'show' ? choice : null;
    },
  );
  try {
    final row = find.byType(BusyMarkSidebarRecordRow<bool>);
    final mouse = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await mouse.down(tester.getCenter(row));
    await mouse.up();
    await tester.pumpAndSettle();
    final entries =
        ((menus.singleWhere((call) => call.method == 'show').arguments
                    as Map)['entries']
                as List)
            .cast<Map>();
    expect(entries.map((e) => e['label']), contains('Source location'));
    if (choice == 1) {
      expect(entries.map((e) => e['label']), contains('Target location'));
    }
  } finally {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('busymark/native_menus'),
      null,
    );
  }
}

class EmptyFixtureWorkspace extends FixtureWorkspace {
  @override
  WorkspaceState build() => WorkspaceState();
}

class RecoverableFixtureIndex extends FixtureIndex {
  RecoverableFixtureIndex(super.index);
  int retries = 0;
  @override
  AsyncValue<ReferenceIndex> build() => const AsyncLoading();
  void fail() => state = AsyncError(
    StateError('reference fixture failure'),
    StackTrace.current,
  );
  @override
  void refresh() {
    retries++;
    state = AsyncData(index);
  }
}
