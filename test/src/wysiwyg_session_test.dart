import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_session_state.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = MarkdownParser();

  testWidgets('restores WYSIWYG selection from document session state', (
    tester,
  ) async {
    final document = parser
        .parse(filePath: 'one.md', source: 'Alpha beta\n')
        .busyDocument;
    final blockId = document.blocks.single.id;

    await tester.pumpWidget(
      _app(
        BusyMarkWysiwygEditor(
          document: document,
          documentId: 'one',
          initialSessionState: WysiwygEditorSessionState(
            activeBlockId: blockId,
            anchorBlockId: blockId,
            anchorOffset: 1,
            extentBlockId: blockId,
            extentOffset: 5,
          ),
          onSourceChanged: (_, _) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(
      field.controller?.selection,
      const TextSelection(baseOffset: 1, extentOffset: 5),
    );
  });

  testWidgets('reports the old document session before switching tabs', (
    tester,
  ) async {
    final first = parser
        .parse(filePath: 'one.md', source: 'First document\n')
        .busyDocument;
    final second = parser
        .parse(filePath: 'two.md', source: 'Second document\n')
        .busyDocument;
    final sessions = <String, WysiwygEditorSessionState>{};

    Widget editor(String id, dynamic document) => _app(
      BusyMarkWysiwygEditor(
        document: document,
        documentId: id,
        onSessionChanged: (documentId, state) {
          sessions[documentId] = state;
        },
        onSourceChanged: (_, _) {},
      ),
    );

    await tester.pumpWidget(editor('one', first));
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField).first);
    field.controller!.selection = const TextSelection.collapsed(offset: 4);
    await tester.pump();

    await tester.pumpWidget(editor('two', second));
    await tester.pump();

    expect(sessions['one']?.activeBlockId, first.blocks.single.id);
    expect(sessions['one']?.anchorOffset, 4);
    expect(sessions['one']?.extentOffset, 4);
  });

  testWidgets('workspace mode delegates WYSIWYG undo to buffer history', (
    tester,
  ) async {
    final document = parser
        .parse(filePath: 'one.md', source: 'Original\n')
        .busyDocument;
    var undoCalls = 0;

    await tester.pumpWidget(
      _app(
        BusyMarkWysiwygEditor(
          document: document,
          documentId: 'one',
          useExternalUndoHistory: true,
          onUndo: () => undoCalls++,
          onSourceChanged: (_, _) {},
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'Edited');
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(undoCalls, 1);
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SizedBox(width: 900, height: 640, child: child)),
  );
}
