import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/quick_open.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/command_registry.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_transfer_service.dart';
import 'package:busymark/src/nextcloud_notes/presentation/notes_workspace_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _drain(WidgetTester tester) async {
  for (var i = 0; i < 25; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
}

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);
void main() {
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
    'Quick Open arrow/Enter opens the chosen identity and Escape dismisses',
    (tester) async {
      QuickOpenDocument? result;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showDialog<QuickOpenDocument>(
                  context: context,
                  builder: (_) => const QuickOpenDialog(
                    documents: [
                      QuickOpenDocument(title: 'A', path: 'Cat', localId: 'a'),
                      QuickOpenDocument(title: 'B', path: 'Cat', localId: 'b'),
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
      await _drain(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(result?.localId, 'b');
      expect(result?.filePath, isNull);
      await tester.tap(find.text('launch'));
      await _drain(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(QuickOpenDialog), findsNothing);
      expect(result, isNull);
      expect(tester.takeException(), isNull);
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
