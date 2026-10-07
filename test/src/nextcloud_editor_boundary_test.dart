import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/assets/document_media_context.dart';
import 'package:busymark/src/editor/source/source_editor.dart';
import 'package:busymark/src/editor/source/source_search.dart';
import 'package:busymark/src/editor/source_language.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpReadOnly(WidgetTester tester, Widget editor) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DocumentMediaScope(
              media: DocumentMediaContext.unavailable,
              child: DocumentReadOnlyScope(readOnly: true, child: editor),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> boldShortcut(WidgetTester tester, Finder field) async {
    await tester.tap(field);
    final widget = tester.widget<TextField>(field);
    widget.focusNode?.requestFocus();
    widget.controller!.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 5,
    );
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyB);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyB);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'remote read-only source blocks typing and formatting mutations',
    (tester) async {
      final edits = <String>[];
      await pumpReadOnly(
        tester,
        BusyMarkSourceEditor(
          text: 'hello',
          language: SourceSyntaxLanguage.markdown,
          filePath: null,
          documentId: 'remote-note',
          diagnostics: const [],
          editorFontSize: 16,
          wordWrap: true,
          searchActive: false,
          searchOptions: const SourceSearchOptions(),
          onSearchOptionsChanged: (_) {},
          onChanged: (text, _) => edits.add(text),
          onOpenSearch: () {},
          onCloseSearch: () {},
        ),
      );
      final field = find.byType(TextField).first;
      expect(tester.widget<TextField>(field).readOnly, isTrue);
      await boldShortcut(tester, field);
      expect(edits, isEmpty);
      expect(tester.widget<TextField>(field).controller!.text, 'hello');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'remote read-only WYSIWYG blocks typing and formatting emissions',
    (tester) async {
      final edits = <String>[];
      final document = const MarkdownParser().parse(
        filePath: '',
        source: 'hello\n',
        validateLocalReferences: false,
      );
      await pumpReadOnly(
        tester,
        BusyMarkWysiwygEditor(
          document: document.busyDocument,
          documentId: 'remote-note',
          onSourceChanged: (_, source) => edits.add(source),
        ),
      );
      final field = find.widgetWithText(TextField, 'hello');
      expect(tester.widget<TextField>(field).readOnly, isTrue);
      await boldShortcut(tester, field);
      expect(edits, isEmpty);
      expect(tester.widget<TextField>(field).controller!.text, 'hello');
      expect(tester.takeException(), isNull);
    },
  );
}
