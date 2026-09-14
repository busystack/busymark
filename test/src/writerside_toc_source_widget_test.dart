import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/l10n/generated/app_localizations_en.dart';
import 'package:busymark/src/editor/source/source_editor.dart';
import 'package:busymark/src/editor/source/source_search.dart';
import 'package:busymark/src/editor/source_highlighter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'tree exact reveal unfolds and line movement is one undoable full-source edit',
    (tester) async {
      const original =
          '<instance-profile id="g">\r\n  <toc-element toc-title="Group">\r\n    <toc-element topic="a.md"/>\r\n    <toc-element topic="b.md"/>\r\n  </toc-element>\r\n</instance-profile>';
      var text = original;
      var changes = 0;
      TextEditingValue? undo;
      TextEditingValue? redo;
      final key = GlobalKey<BusyMarkSourceEditorState>();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => BusyMarkSourceEditor(
                key: key,
                text: text,
                filePath: '/project/guide.tree',
                language: SourceSyntaxLanguage.xml,
                diagnostics: const [],
                editorFontSize: 14,
                wordWrap: true,
                searchActive: false,
                searchOptions: const SourceSearchOptions(),
                onSearchOptionsChanged: (_) {},
                onChanged: (_, _) {},
                onTransactionalChanged:
                    (value, _, previousSelection, selection, _) {
                      undo = TextEditingValue(
                        text: text,
                        selection: previousSelection,
                      );
                      redo = TextEditingValue(
                        text: value,
                        selection: selection,
                      );
                      changes++;
                      setState(() => text = value);
                    },
                onUndo: () {
                  final result = undo;
                  if (result != null) setState(() => text = result.text);
                  return result;
                },
                onRedo: () {
                  final result = redo;
                  if (result != null) setState(() => text = result.text);
                  return result;
                },
                onOpenSearch: () {},
                onCloseSearch: () {},
              ),
            ),
          ),
        ),
      );
      final en = AppLocalizationsEn();
      await tester.tap(find.byTooltip(en.collapseKind(en.foldKindTag)).first);
      await tester.pumpAndSettle();
      final controller = tester
          .widgetList<TextField>(find.byType(TextField))
          .map((field) => field.controller)
          .whereType<BusyMarkSourceEditingController>()
          .single;
      expect(controller.text, isNot(contains('topic="b.md"')));
      final offset = original.indexOf('<toc-element topic="b.md"');
      key.currentState!.scrollToOffset(offset);
      await tester.pumpAndSettle();
      expect(controller.text, contains('topic="b.md"'));
      expect(controller.selection.extentOffset, offset);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(changes, 1);
      expect(
        text.indexOf('topic="b.md"'),
        lessThan(text.indexOf('topic="a.md"')),
      );
      expect(text, contains('\r\n'));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(text, original);
      expect(changes, 1);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(text, redo!.text);
    },
  );
}
