import 'package:busymark/src/search/search_session.dart';
import 'package:busymark/src/search/search_sidebar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/quick_open.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/command_registry.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_transfer_service.dart';
import 'package:busymark/src/nextcloud_notes/presentation/notes_workspace_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const windowChannel = MethodChannel('yaru_window');
  const windowEvents = EventChannel('yaru_window/events');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  setUp(() {
    // The real Yaru dialog title bar subscribes to native window state. Keep
    // this file independent of plugin registration and async completion timing.
    messenger.setMockMethodCallHandler(windowChannel, (call) async {
      if (call.method == 'state') {
        return <String, Object?>{};
      }
      return null;
    });
    messenger.setMockStreamHandler(
      windowEvents,
      MockStreamHandler.inline(onListen: (_, _) {}, onCancel: (_) {}),
    );
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(windowChannel, null);
    messenger.setMockStreamHandler(windowEvents, null);
  });
  test(
    'Quick Open ranks exact/prefix/title/path matches with stable identities',
    () {
      const docs = [
        QuickOpenDocument(title: 'foo backup', path: 'b', localId: 'b'),
        QuickOpenDocument(title: 'foo', path: 'z', localId: 'z'),
        QuickOpenDocument(title: 'other', path: 'foo/category', localId: 'o'),
        QuickOpenDocument(title: 'a foo', path: 'a', filePath: '/real/a.md'),
        QuickOpenDocument(title: 'foo', path: 'a', localId: 'a'),
      ];
      expect(rankQuickOpen(docs, 'foo').map((d) => d.identity), [
        'a',
        'z',
        'b',
        '/real/a.md',
        'o',
      ]);
      expect(rankQuickOpen(docs, 'missing'), isEmpty);
      expect(
        BusyMarkCommandCatalog
            .metadata[BusyMarkCommandIds.quickOpen]!
            .shortcut!
            .label,
        'Ctrl+P',
      );
      expect(
        BusyMarkCommandCatalog
            .metadata[BusyMarkCommandIds.commandPalette]!
            .shortcut!
            .label,
        'Ctrl+Shift+P',
      );
    },
  );
  testWidgets(
    'Documents sidebar renders stable identities and pointer activation',
    (tester) async {
      SidebarSearchResult? selected;
      const first = DocumentSearchResult(
        'account-a',
        QuickOpenDocument(title: 'Same', path: 'Cat', localId: 'a'),
        accountId: 'a',
      );
      const second = DocumentSearchResult(
        'account-a',
        QuickOpenDocument(title: 'Same', path: 'Cat', localId: 'b'),
        accountId: 'a',
      );
      await tester.pumpWidget(
        ProviderScope(
          child: _app(
            SearchResultList(
              results: const [first, second],
              selected: 1,
              onActivate: (result) async => selected = result,
            ),
          ),
        ),
      );
      expect(find.text('Same'), findsNWidgets(2));
      expect(
        tester.widget<ListTile>(find.byKey(ValueKey(second.identity))).selected,
        isTrue,
      );
      await tester.tap(find.byKey(ValueKey(second.identity)));
      expect((selected as DocumentSearchResult).document.localId, 'b');
      expect((selected as DocumentSearchResult).document.filePath, isNull);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'lazy search selection reveals wrapped rows at increased text size',
    (tester) async {
      var selected = 0;
      late StateSetter update;
      final results = <SidebarSearchResult>[
        for (var i = 0; i < 80; i++)
          DocumentSearchResult(
            'workspace',
            QuickOpenDocument(
              title: 'Document $i ${'a long descriptive title ' * 8}',
              path: 'nested/path/with/context/document-$i.md',
              filePath: '/document-$i.md',
            ),
          ),
      ];
      await tester.pumpWidget(
        ProviderScope(
          child: _app(
            StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(1.6)),
                  child: SizedBox(
                    width: 280,
                    height: 260,
                    child: SearchResultList(
                      results: results,
                      selected: selected,
                      onActivate: (_) async {},
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      update(() => selected = 40);
      await tester.pumpAndSettle();
      final row = find.byKey(ValueKey(results[40].identity));
      expect(row.hitTestable(), findsOneWidget);
      expect(tester.widget<ListTile>(row).selected, isTrue);
      update(() => selected = 0);
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey(results.first.identity)).hitTestable(),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'import review exposes distinct collisions, missing media, category edits and selection',
    (tester) async {
      final item = NotesImportItem(
        key: 'one',
        path: '/source/one.md',
        title: 'Same title',
        category: 'Work/Sub',
        content: 'body',
        collision: true,
        issues: ['missing.png'],
      );
      final review = NotesImportReview('/source', [item], []);
      await tester.pumpWidget(_app(NotesImportReviewDialog(review: review)));
      await tester.pumpAndSettle();
      expect(find.text('Import as a distinct note'), findsOneWidget);
      expect(find.text('Incomplete: missing.png'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'Corrected/子');
      expect(item.category, 'Corrected/子');
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      expect(item.selected, false);
      final button = tester.widget<BusyMarkDialogButton>(
        find.widgetWithText(BusyMarkDialogButton, 'Import notes'),
      );
      expect(button.onPressed, isNull);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'correction: import chooser distinguishes a new import from an explicit resumed operation',
    (tester) async {
      String? choice;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                choice = await showDialog<String>(
                  context: context,
                  builder: (_) => const NotesImportOperationDialog(
                    operations: [
                      {
                        'id': 'reviewed-operation',
                        'root': '/source',
                        'created_at': 1780000000,
                      },
                    ],
                  ),
                );
              },
              child: const Text('launch'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('launch'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start a new import'));
      await tester.pumpAndSettle();
      expect(choice, '');
      await tester.tap(find.text('launch'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Resume interrupted import'));
      await tester.pumpAndSettle();
      expect(choice, 'reviewed-operation');
      final item = NotesImportItem(
        key: 'one',
        path: '/source/one.md',
        title: 'Imported',
        category: 'Reviewed/Sub',
        content: 'body',
      )..importedNoteId = 'stable-note';
      await tester.pumpWidget(
        _app(
          NotesImportReviewDialog(
            review: NotesImportReview('/source', [item], []),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Already imported in this operation'), findsOneWidget);
      expect(
        tester
            .widget<CheckboxListTile>(find.byType(CheckboxListTile))
            .onChanged,
        isNull,
      );
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byType(TextFormField),
                matching: find.byType(TextField),
              ),
            )
            .readOnly,
        true,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
