import 'dart:ui' show BoxHeightStyle;

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/l10n/generated/app_localizations_de.dart';
import 'package:busymark/l10n/generated/app_localizations_en.dart';
import 'package:busymark/src/ai/ai_models.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/core/diagnostic.dart';
import 'package:busymark/src/core/source_span.dart';
import 'package:busymark/src/editor/document_text_geometry.dart';
import 'package:busymark/src/editor/source/source_editor.dart';
import 'package:busymark/src/editor/source/source_autocomplete.dart';
import 'package:busymark/src/editor/source/source_gutter.dart'
    show sourceTextHeightBehavior;
import 'package:busymark/src/editor/source/source_search.dart';
import 'package:busymark/src/editor/source_folding.dart';
import 'package:busymark/src/editor/source_language.dart';
import 'package:busymark/src/platform/native_menu_service.dart';
import 'package:busymark/src/writerside/writerside_project.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaru/yaru.dart';

void main() {
  testWidgets('source AI action applies a selection through the editor path', (
    tester,
  ) async {
    const source = 'Unclear text.\n';
    AiEditorSnapshot? snapshot;
    String? changedText;
    List<Map<Object?, Object?>>? nativeEntries;
    const nativeMenuChannel = MethodChannel(nativeMenuChannelName);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      nativeMenuChannel,
      (call) async {
        if (call.method != 'show') {
          return false;
        }
        final arguments = call.arguments as Map<Object?, Object?>;
        nativeEntries = (arguments['entries'] as List<Object?>)
            .cast<Map<Object?, Object?>>();
        return nativeEntries!.indexWhere(
          (entry) => entry['label'] == 'Refine with AI',
        );
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        nativeMenuChannel,
        null,
      );
    });
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildBusyMarkTheme(
          brightness: Brightness.dark,
          accentColor: BusyMarkLinuxPalette.blueAccent,
        ),
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 600,
            child: BusyMarkSourceEditor(
              text: source,
              language: SourceSyntaxLanguage.markdown,
              filePath: '/project/topic.md',
              diagnostics: const [],
              editorFontSize: 14,
              wordWrap: true,
              searchActive: false,
              searchOptions: const SourceSearchOptions(),
              onSearchOptionsChanged: (_) {},
              onChanged: (text, _) => changedText = text,
              onOpenSearch: () {},
              onCloseSearch: () {},
              editRevision: 7,
              onAiEdit: (value) async {
                snapshot = value;
                return AiEditApplication(
                  invocation: AiEditInvocation(
                    feature: AiFeature.editDocument,
                    scope: AiScope.markdownEdit,
                    input: 'Unclear text.',
                    replacementOriginal: 'Unclear text.',
                    sourceRevision: value.sourceRevision,
                    targetId: value.targetId,
                    documentPath: value.documentPath,
                    instruction: 'Rewrite for clarity.',
                    editTarget: AiEditTargetKind.selection,
                    editContext: AiEditContextKind.selection,
                    documentSource: value.documentSource,
                    replacementStart: value.selectionStart,
                    replacementEnd: value.selectionEnd,
                  ),
                  output: 'Clear text.',
                );
              },
            ),
          ),
        ),
      ),
    );
    final fieldFinder = find.byType(TextField);
    await tester.tap(fieldFinder);
    final field = tester.widget<TextField>(fieldFinder);
    field.controller!.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 13,
    );
    await tester.pump();
    final editableFinder = find.descendant(
      of: fieldFinder,
      matching: find.byType(EditableText),
    );
    final editableState = tester.state<EditableTextState>(editableFinder);
    editableState.clipboardStatus.value = ClipboardStatus.pasteable;
    final expectedSelectionActions = editableState.contextMenuButtonItems
        .map(
          (item) => AdaptiveTextSelectionToolbar.getButtonLabel(
            tester.element(editableFinder),
            item,
          ),
        )
        .toList();

    expect(find.byTooltip('Edit with AI'), findsNothing);

    await tester.tap(fieldFinder, buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();

    expect(nativeEntries!.map((entry) => entry['label']), <String>[
      ...expectedSelectionActions,
      'Refine with AI',
    ]);
    expect(
      nativeEntries!.map((entry) => entry['label']),
      isNot(contains('Undo')),
    );
    expect(
      nativeEntries!.map((entry) => entry['label']),
      isNot(contains('Redo')),
    );
    expect(_nativeShortcut(nativeEntries!, 'Cut'), 'Ctrl+X');
    expect(_nativeShortcut(nativeEntries!, 'Copy'), 'Ctrl+C');
    expect(_nativeShortcut(nativeEntries!, 'Paste'), 'Ctrl+V');
    expect(_nativeShortcut(nativeEntries!, 'Select all'), 'Ctrl+A');
    expect(_nativeShortcut(nativeEntries!, 'Refine with AI'), 'Ctrl+G');
    expect(_nativeIcon(nativeEntries!, 'Cut'), 'edit-cut-symbolic');
    expect(_nativeIcon(nativeEntries!, 'Copy'), 'edit-copy-symbolic');
    expect(_nativeIcon(nativeEntries!, 'Paste'), 'edit-paste-symbolic');
    expect(
      _nativeIcon(nativeEntries!, 'Select all'),
      'edit-select-all-symbolic',
    );
    expect(_nativeIcon(nativeEntries!, 'Refine with AI'), 'starred-symbolic');

    expect(snapshot?.sourceRevision, 7);
    expect(snapshot?.documentSource, source);
    expect(snapshot?.selectionStart, 0);
    expect(snapshot?.selectionEnd, 13);
    expect(changedText, 'Clear text.\n');
  });

  testWidgets('source AI applies a user-selected insertion target', (
    tester,
  ) async {
    const source = '# Plan\n\nNotes for draft.\n\nAfter.\n';
    AiEditorSnapshot? snapshot;
    String? changedText;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildBusyMarkTheme(
          brightness: Brightness.dark,
          accentColor: BusyMarkLinuxPalette.blueAccent,
        ),
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 600,
            child: BusyMarkSourceEditor(
              text: source,
              language: SourceSyntaxLanguage.markdown,
              filePath: '/project/topic.md',
              diagnostics: const [],
              editorFontSize: 14,
              wordWrap: true,
              searchActive: false,
              searchOptions: const SourceSearchOptions(),
              onSearchOptionsChanged: (_) {},
              onChanged: (text, _) => changedText = text,
              onOpenSearch: () {},
              onCloseSearch: () {},
              editRevision: 10,
              onAiEdit: (value) async {
                snapshot = value;
                final insertion = source.indexOf('After.');
                return AiEditApplication(
                  invocation: AiEditInvocation(
                    feature: AiFeature.editDocument,
                    scope: AiScope.markdownEdit,
                    input: source.substring(
                      value.selectionStart,
                      value.selectionEnd,
                    ),
                    replacementOriginal: '',
                    sourceRevision: value.sourceRevision,
                    targetId: value.targetId,
                    documentPath: value.documentPath,
                    instruction: 'Draft a section from these notes.',
                    editTarget: AiEditTargetKind.insertAfterBlock,
                    editContext: AiEditContextKind.selection,
                    documentSource: value.documentSource,
                    replacementStart: insertion,
                    replacementEnd: insertion,
                    replacementSuffix: '\n\n',
                  ),
                  output: 'Generated section.',
                );
              },
            ),
          ),
        ),
      ),
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    await tester.tap(find.byType(TextField));
    final start = source.indexOf('Notes');
    field.controller!.selection = TextSelection(
      baseOffset: start,
      extentOffset: start + 'Notes for draft.'.length,
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyG);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyG);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(
      source.substring(snapshot!.selectionStart, snapshot!.selectionEnd),
      'Notes for draft.',
    );
    expect(changedText, contains('Notes for draft.'));
    expect(changedText, contains('Generated section.\n\nAfter.'));
  });

  testWidgets('source editor remains LTR inside an Arabic interface', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildBusyMarkTheme(
          brightness: Brightness.dark,
          accentColor: BusyMarkLinuxPalette.blueAccent,
        ),
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 600,
            child: BusyMarkSourceEditor(
              text: '# مقدمة\npath: docs/مقدمة-v2.md\n',
              language: SourceSyntaxLanguage.markdown,
              filePath: '/project/topic.md',
              diagnostics: const [],
              editorFontSize: 14,
              wordWrap: true,
              searchActive: false,
              searchOptions: const SourceSearchOptions(),
              onSearchOptionsChanged: (_) {},
              onChanged: (_, _) {},
              onOpenSearch: () {},
              onCloseSearch: () {},
            ),
          ),
        ),
      ),
    );

    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.rtl,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).textDirection,
      TextDirection.ltr,
    );
    expect(
      tester
          .widgetList<Row>(find.byType(Row))
          .any((row) => row.textDirection == TextDirection.ltr),
      isTrue,
    );
  });

  testWidgets('source editor shows large-file fallback status', (tester) async {
    final source = 'a' * 300001;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildBusyMarkTheme(
          brightness: Brightness.dark,
          accentColor: BusyMarkLinuxPalette.blueAccent,
        ),
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 600,
            child: BusyMarkSourceEditor(
              text: source,
              language: SourceSyntaxLanguage.markdown,
              filePath: '/project/topic.md',
              diagnostics: const [],
              editorFontSize: 14,
              wordWrap: true,
              searchActive: false,
              searchOptions: const SourceSearchOptions(),
              onSearchOptionsChanged: (_) {},
              onChanged: (_, _) {},
              onOpenSearch: () {},
              onCloseSearch: () {},
            ),
          ),
        ),
      ),
    );

    expect(
      find.text('Large file: highlighting and folding are paused'),
      findsOneWidget,
    );
  });

  testWidgets('source editor renders visible diagnostic gutter tooltip', (
    tester,
  ) async {
    const filePath = '/project/topic.md';
    const source = '# Intro\nBody\n';
    final diagnostic = Diagnostic(
      code: 'markdown.heading.duplicate-id',
      severity: DiagnosticSeverity.warning,
      filePath: filePath,
      args: const {'id': 'intro'},
      sourceSpan: SourceSpan.fromOffsets(
        filePath: filePath,
        source: source,
        startOffset: 0,
        endOffset: 7,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildBusyMarkTheme(
          brightness: Brightness.dark,
          accentColor: BusyMarkLinuxPalette.blueAccent,
        ),
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 600,
            child: BusyMarkSourceEditor(
              text: source,
              language: SourceSyntaxLanguage.markdown,
              filePath: filePath,
              diagnostics: [diagnostic],
              editorFontSize: 14,
              wordWrap: true,
              searchActive: false,
              searchOptions: const SourceSearchOptions(),
              onSearchOptionsChanged: (_) {},
              onChanged: (_, _) {},
              onOpenSearch: () {},
              onCloseSearch: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Duplicate heading ID "intro".'), findsOneWidget);
  });

  testWidgets('source search localizes an invalid regular expression', (
    tester,
  ) async {
    final de = AppLocalizationsDe();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 600,
            child: BusyMarkSourceEditor(
              text: 'Text',
              language: SourceSyntaxLanguage.markdown,
              filePath: '/project/topic.md',
              diagnostics: const [],
              editorFontSize: 14,
              wordWrap: true,
              searchActive: true,
              searchOptions: const SourceSearchOptions(query: '[', regex: true),
              onSearchOptionsChanged: (_) {},
              onChanged: (_, _) {},
              onOpenSearch: () {},
              onCloseSearch: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text(de.sourceSearchInvalidRegex), findsOneWidget);
  });

  testWidgets('source fold and search options use semantic icon buttons', (
    tester,
  ) async {
    final en = AppLocalizationsEn();
    SourceSearchOptions? updatedOptions;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildBusyMarkTheme(
          brightness: Brightness.light,
          accentColor: BusyMarkLinuxPalette.blueAccent,
        ),
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 600,
            child: BusyMarkSourceEditor(
              text: '# Intro\nBody\n',
              language: SourceSyntaxLanguage.markdown,
              filePath: '/project/topic.md',
              diagnostics: const [],
              editorFontSize: 14,
              wordWrap: true,
              searchActive: true,
              searchOptions: const SourceSearchOptions(caseSensitive: true),
              onSearchOptionsChanged: (options) => updatedOptions = options,
              onChanged: (_, _) {},
              onOpenSearch: () {},
              onCloseSearch: () {},
            ),
          ),
        ),
      ),
    );

    final foldTooltip = find.byTooltip(en.collapseKind(en.foldKindSection));
    final foldButton = find.ancestor(
      of: foldTooltip,
      matching: find.byType(BusyMarkCompactIconButton),
    );
    expect(foldTooltip, findsOneWidget);
    expect(foldButton, findsOneWidget);

    final caseButton = find.ancestor(
      of: find.byTooltip(en.sourceSearchCaseSensitive),
      matching: find.byType(YaruIconButton),
    );
    final wholeWordButton = find.ancestor(
      of: find.byTooltip(en.sourceSearchWholeWord),
      matching: find.byType(YaruIconButton),
    );
    expect(tester.widget<YaruIconButton>(caseButton).isSelected, isTrue);
    expect(tester.widget<YaruIconButton>(wholeWordButton).isSelected, isFalse);

    await tester.tap(wholeWordButton);
    await tester.pump();
    expect(updatedOptions?.caseSensitive, isTrue);
    expect(updatedOptions?.wholeWord, isTrue);

    await tester.tap(foldButton);
    await tester.pump();
    expect(find.byTooltip(en.expandKind(en.foldKindSection)), findsOneWidget);
  });

  testWidgets('source Replace All is one editor operation', (tester) async {
    final en = AppLocalizationsEn();
    var replacement = '';
    var currentText = 'cat cat';
    String? undoText;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: 900,
              height: 600,
              child: BusyMarkSourceEditor(
                text: currentText,
                language: SourceSyntaxLanguage.markdown,
                filePath: '/project/topic.md',
                diagnostics: const [],
                editorFontSize: 14,
                wordWrap: true,
                searchActive: true,
                searchOptions: const SourceSearchOptions(query: 'cat'),
                searchReplacement: replacement,
                onSearchReplacementChanged: (value) =>
                    setState(() => replacement = value),
                onSearchOptionsChanged: (_) {},
                onChanged: (text, _) {
                  undoText = currentText;
                  setState(() => currentText = text);
                },
                onUndo: () {
                  final previous = undoText;
                  if (previous == null) {
                    return null;
                  }
                  undoText = null;
                  setState(() => currentText = previous);
                  return previous;
                },
                onOpenSearch: () {},
                onCloseSearch: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('source-search-replacement')),
      'dog',
    );
    await _pumpUntil(tester, () => find.text('1 / 2').evaluate().isNotEmpty);
    await tester.tap(find.byTooltip(en.sourceSearchReplaceAll));
    await _pumpUntil(tester, () => currentText == 'dog dog');

    expect(currentText, 'dog dog');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(currentText, 'cat cat');
  });

  testWidgets('source Replace and Find Next selects the logical next match', (
    tester,
  ) async {
    final en = AppLocalizationsEn();
    var currentText = 'a a a';
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: 900,
              height: 600,
              child: BusyMarkSourceEditor(
                text: currentText,
                language: SourceSyntaxLanguage.markdown,
                filePath: '/project/topic.md',
                diagnostics: const [],
                editorFontSize: 14,
                wordWrap: true,
                searchActive: true,
                searchOptions: const SourceSearchOptions(query: 'a'),
                searchReplacement: 'x',
                onSearchReplacementChanged: (_) {},
                onSearchOptionsChanged: (_) {},
                onChanged: (text, _) => setState(() => currentText = text),
                onOpenSearch: () {},
                onCloseSearch: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await _pumpUntil(tester, () => find.text('1 / 3').evaluate().isNotEmpty);

    await tester.tap(find.byTooltip(en.sourceSearchReplaceAndFindNext));
    await _pumpUntil(tester, () => currentText == 'x a a');
    await _pumpUntil(tester, () => find.text('1 / 2').evaluate().isNotEmpty);

    final sourceField = tester
        .widgetList<TextField>(find.byType(TextField))
        .firstWhere((field) => field.controller?.text == currentText);
    expect(currentText, 'x a a');
    expect(
      sourceField.controller!.selection,
      const TextSelection(baseOffset: 2, extentOffset: 3),
    );
  });

  testWidgets('shifted folded regions are persisted after edit debounce', (
    tester,
  ) async {
    final en = AppLocalizationsEn();
    var currentText = 'Prelude\n# Section\nHidden\nMore\n';
    var sessionKeys = <String>{};

    Widget editor({Key? key, Set<String> initialKeys = const {}}) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 600,
            child: BusyMarkSourceEditor(
              key: key,
              text: currentText,
              language: SourceSyntaxLanguage.markdown,
              filePath: '/project/topic.md',
              diagnostics: const [],
              editorFontSize: 14,
              wordWrap: true,
              searchActive: false,
              searchOptions: const SourceSearchOptions(),
              onSearchOptionsChanged: (_) {},
              onChanged: (text, _) => currentText = text,
              onOpenSearch: () {},
              onCloseSearch: () {},
              initialFoldedRegionKeys: initialKeys,
              onSessionChanged: (_, _, keys) => sessionKeys = keys,
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(editor(key: const ValueKey('original')));
    await tester.tap(find.byTooltip(en.collapseKind(en.foldKindSection)));
    await tester.pump();
    final sourceField = tester.widget<TextField>(find.byType(TextField));
    final visibleBeforeEdit = sourceField.controller!.text;
    expect(visibleBeforeEdit, isNot(contains('Hidden')));
    await tester.tap(find.byType(TextField));
    await tester.showKeyboard(find.byType(TextField));

    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: 'Lead\n$visibleBeforeEdit',
        selection: const TextSelection.collapsed(offset: 5),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump();

    final shiftedRegion = sourceFoldRegions(
      currentText,
      SourceSyntaxLanguage.markdown,
    ).singleWhere((region) => region.startLine == 3);
    expect(sessionKeys, contains(shiftedRegion.key));

    await tester.pumpWidget(
      editor(key: const ValueKey('restored'), initialKeys: sessionKeys),
    );
    await tester.pump();

    expect(find.byTooltip(en.expandKind(en.foldKindSection)), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isNot(contains('Hidden')),
    );
  });

  testWidgets(
    'source editor gives glyphs, caret, and selection breathing room',
    (tester) async {
      const source = 'Agjpqy\nSecond line\n';
      const fontSize = 14.0;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildBusyMarkTheme(
            brightness: Brightness.dark,
            accentColor: BusyMarkLinuxPalette.blueAccent,
          ),
          home: Scaffold(
            body: SizedBox(
              width: 900,
              height: 600,
              child: BusyMarkSourceEditor(
                text: source,
                language: SourceSyntaxLanguage.markdown,
                filePath: '/project/topic.md',
                diagnostics: const [],
                editorFontSize: fontSize,
                wordWrap: true,
                searchActive: false,
                searchOptions: const SourceSearchOptions(),
                onSearchOptionsChanged: (_) {},
                onChanged: (_, _) {},
                onOpenSearch: () {},
                onCloseSearch: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      final renderEditable = _findRenderEditable(
        tester.renderObject<RenderObject>(find.byType(EditableText)),
      );
      expect(renderEditable, isNotNull);
      expect(field.style?.height, BusyMarkTypography.sourceEditorLineHeight);
      expect(
        field.selectionHeightStyle,
        BusyMarkDocumentTextGeometry.selectionHeightStyle,
      );
      expect(
        BusyMarkDocumentTextGeometry.selectionHeightStyle,
        BoxHeightStyle.strut,
      );
      expect(
        field.cursorHeight,
        fontSize * BusyMarkTypography.sourceCursorHeightScale,
      );

      const selection = TextSelection(baseOffset: 0, extentOffset: 6);
      final selectionBox = renderEditable!
          .getBoxesForSelection(selection)
          .single
          .toRect();
      final caret = renderEditable.getLocalRectForCaret(
        const TextPosition(offset: 3),
      );
      final textPainter = TextPainter(
        text: TextSpan(text: source, style: field.style),
        strutStyle: field.strutStyle,
        textDirection: TextDirection.ltr,
        textHeightBehavior: sourceTextHeightBehavior,
      )..layout(maxWidth: 800);
      final glyphBox = textPainter
          .getBoxesForSelection(selection, boxHeightStyle: BoxHeightStyle.tight)
          .single
          .toRect();
      textPainter.dispose();

      expect(selectionBox.top, lessThan(glyphBox.top));
      expect(selectionBox.bottom, greaterThan(glyphBox.bottom));
      expect(caret.top, lessThan(glyphBox.top));
      expect(caret.bottom, greaterThan(glyphBox.bottom));
      expect(selectionBox.bottom - glyphBox.bottom, greaterThan(2));
      expect(selectionBox.bottom - caret.bottom, greaterThan(1));
    },
  );

  testWidgets('source heading caret advances after a typed space', (
    tester,
  ) async {
    var source = '';
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildBusyMarkTheme(
          brightness: Brightness.dark,
          accentColor: BusyMarkLinuxPalette.blueAccent,
        ),
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: SizedBox(
                width: 900,
                height: 600,
                child: BusyMarkSourceEditor(
                  text: source,
                  language: SourceSyntaxLanguage.markdown,
                  filePath: '/project/topic.md',
                  diagnostics: const [],
                  editorFontSize: 14,
                  wordWrap: true,
                  searchActive: false,
                  searchOptions: const SourceSearchOptions(),
                  onSearchOptionsChanged: (_) {},
                  onChanged: (text, _) => setState(() => source = text),
                  onOpenSearch: () {},
                  onCloseSearch: () {},
                ),
              ),
            );
          },
        ),
      ),
    );
    final fieldFinder = find.byType(TextField);
    await tester.tap(fieldFinder);
    await tester.showKeyboard(fieldFinder);

    Future<Rect> enterAndReadCaret(String text) async {
      tester.testTextInput.updateEditingValue(
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        ),
      );
      await tester.pump();
      final field = tester.widget<TextField>(fieldFinder);
      expect(field.controller!.selection.extentOffset, text.length);
      final editable = _findRenderEditable(
        tester.renderObject<RenderObject>(find.byType(EditableText)),
      )!;
      return editable.getLocalRectForCaret(TextPosition(offset: text.length));
    }

    final beforeMarkerSpace = await enterAndReadCaret('#');
    final afterMarkerSpace = await enterAndReadCaret('# ');
    final beforeWordSpace = await enterAndReadCaret('# Linguality');
    final afterWordSpace = await enterAndReadCaret('# Linguality ');
    await enterAndReadCaret('# Linguality\nBody');
    final field = tester.widget<TextField>(fieldFinder);
    field.controller!.selection = const TextSelection.collapsed(offset: 12);
    await tester.pump();
    final editable = _findRenderEditable(
      tester.renderObject<RenderObject>(find.byType(EditableText)),
    )!;
    final beforeLineEndSpace = editable.getLocalRectForCaret(
      const TextPosition(offset: 12),
    );
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '# Linguality \nBody',
        selection: TextSelection.collapsed(offset: 13),
      ),
    );
    await tester.pump();
    final lineEndSelection = tester
        .widget<TextField>(fieldFinder)
        .controller!
        .selection;
    final afterLineEndSpace = editable.getLocalRectForCaret(
      TextPosition(offset: 13, affinity: lineEndSelection.affinity),
    );

    expect(afterMarkerSpace.left, greaterThan(beforeMarkerSpace.left));
    expect(afterWordSpace.left, greaterThan(beforeWordSpace.left));
    expect(lineEndSelection.affinity, TextAffinity.upstream);
    expect(afterLineEndSpace.left, greaterThan(beforeLineEndSpace.left));
  });

  testWidgets('source caret follows an immediate end-of-file contraction', (
    tester,
  ) async {
    var source = List.generate(80, (index) => 'Line $index').join('\n');
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildBusyMarkTheme(
          brightness: Brightness.dark,
          accentColor: BusyMarkLinuxPalette.blueAccent,
        ),
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: SizedBox(
                width: 500,
                height: 180,
                child: BusyMarkSourceEditor(
                  text: source,
                  language: SourceSyntaxLanguage.markdown,
                  filePath: '/project/topic.md',
                  diagnostics: const [],
                  editorFontSize: 14,
                  wordWrap: true,
                  searchActive: false,
                  searchOptions: const SourceSearchOptions(),
                  onSearchOptionsChanged: (_) {},
                  onChanged: (text, _) => setState(() => source = text),
                  onOpenSearch: () {},
                  onCloseSearch: () {},
                ),
              ),
            );
          },
        ),
      ),
    );
    final fieldFinder = find.byType(TextField);
    await tester.tap(fieldFinder);
    await tester.showKeyboard(fieldFinder);
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: source,
        selection: TextSelection.collapsed(offset: source.length),
      ),
    );
    await tester.pumpAndSettle();
    var field = tester.widget<TextField>(fieldFinder);
    expect(field.scrollController!.offset, greaterThan(0));

    const shortened = 'Remaining text';
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: shortened,
        selection: TextSelection.collapsed(offset: shortened.length),
      ),
    );
    await tester.pump();

    field = tester.widget<TextField>(fieldFinder);
    final editable = _findRenderEditable(
      tester.renderObject<RenderObject>(find.byType(EditableText)),
    )!;
    final caret = editable.getLocalRectForCaret(
      const TextPosition(offset: shortened.length),
    );
    expect(field.scrollController!.offset, 0);
    expect(caret.top, lessThan(180));
  });

  testWidgets('Ctrl+Space opens project-aware source completion', (
    tester,
  ) async {
    const source = '<topic><p>fea';
    String? changedText;
    const index = WritersideProjectIndex(
      symbols: [
        WritersideSymbol(
          name: 'features',
          qualifiedName: 'docs:features',
          kind: WritersideSymbolKind.topic,
          moduleId: 'docs',
          filePath: '/project/topics/features.topic',
        ),
      ],
      references: [],
      diagnostics: [],
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildBusyMarkTheme(
          brightness: Brightness.dark,
          accentColor: BusyMarkLinuxPalette.blueAccent,
        ),
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 600,
            child: BusyMarkSourceEditor(
              text: source,
              language: SourceSyntaxLanguage.xml,
              filePath: '/project/topics/current.topic',
              diagnostics: const [],
              editorFontSize: 14,
              wordWrap: true,
              searchActive: false,
              searchOptions: const SourceSearchOptions(),
              onSearchOptionsChanged: (_) {},
              onChanged: (text, _) => changedText = text,
              onOpenSearch: () {},
              onCloseSearch: () {},
              initialSelection: const TextSelection.collapsed(
                offset: source.length,
              ),
              autocompleteContext: const SourceAutocompleteContext(
                projectIndex: index,
                moduleId: 'docs',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(find.byKey(const ValueKey('source-autocomplete-popup')), findsOne);
    final suggestion = find.byKey(
      const ValueKey('source-autocomplete-topic-features'),
    );
    expect(suggestion, findsOne);
    await tester.tap(suggestion);
    await tester.pump();

    expect(changedText, '<topic><p>features');
    expect(
      find.byKey(const ValueKey('source-autocomplete-popup')),
      findsNothing,
    );
  });

  testWidgets('wordWrap false uses one horizontally scrollable layout', (
    tester,
  ) async {
    final source = List.filled(80, 'long-source-token').join('-');
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 240,
            child: BusyMarkSourceEditor(
              text: source,
              language: SourceSyntaxLanguage.markdown,
              filePath: '/project/topic.md',
              diagnostics: const [],
              editorFontSize: 14,
              wordWrap: false,
              searchActive: false,
              searchOptions: const SourceSearchOptions(),
              onSearchOptionsChanged: (_) {},
              onChanged: (_, _) {},
              onOpenSearch: () {},
              onCloseSearch: () {},
            ),
          ),
        ),
      ),
    );

    final scroller = tester.widget<SingleChildScrollView>(
      find.byKey(const ValueKey('source-horizontal-scroll-view')),
    );
    expect(scroller.controller!.position.maxScrollExtent, greaterThan(0));
    expect(tester.getSize(find.byType(TextField)).width, greaterThan(320));

    final field = tester.widget<TextField>(find.byType(TextField));
    field.controller!.selection = TextSelection.collapsed(
      offset: source.length,
    );
    await tester.pump();
    expect(scroller.controller!.offset, greaterThan(0));
  });

  testWidgets('source input preserves an active IME composing range', (
    tester,
  ) async {
    String? changedText;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BusyMarkSourceEditor(
            text: '',
            language: SourceSyntaxLanguage.markdown,
            filePath: '/project/topic.md',
            diagnostics: const [],
            editorFontSize: 14,
            wordWrap: true,
            searchActive: false,
            searchOptions: const SourceSearchOptions(),
            onSearchOptionsChanged: (_) {},
            onChanged: (text, _) => changedText = text,
            onOpenSearch: () {},
            onCloseSearch: () {},
          ),
        ),
      ),
    );
    final fieldFinder = find.byType(TextField);
    await tester.tap(fieldFinder);
    await tester.showKeyboard(fieldFinder);
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'に',
        selection: TextSelection.collapsed(offset: 1),
        composing: TextRange(start: 0, end: 1),
      ),
    );
    await tester.pump();

    final field = tester.widget<TextField>(fieldFinder);
    expect(
      field.controller!.value.composing,
      const TextRange(start: 0, end: 1),
    );
    expect(changedText, 'に');
  });

  testWidgets('focused Source accepts authoritative parent text updates', (
    tester,
  ) async {
    var source = 'local';
    String? changedText;
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return BusyMarkSourceEditor(
                text: source,
                language: SourceSyntaxLanguage.markdown,
                filePath: '/project/topic.md',
                diagnostics: const [],
                editorFontSize: 14,
                wordWrap: true,
                searchActive: false,
                searchOptions: const SourceSearchOptions(),
                onSearchOptionsChanged: (_) {},
                onChanged: (text, _) => changedText = text,
                onOpenSearch: () {},
                onCloseSearch: () {},
              );
            },
          ),
        ),
      ),
    );
    final fieldFinder = find.byType(TextField);
    await tester.tap(fieldFinder);
    expect(tester.widget<TextField>(fieldFinder).focusNode!.hasFocus, isTrue);

    updateHost(() => source = 'authoritative');
    await tester.pump();

    expect(tester.widget<TextField>(fieldFinder).controller!.text, source);
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'authoritative!',
        selection: TextSelection.collapsed(offset: 14),
      ),
    );
    await tester.pump();
    expect(changedText, 'authoritative!');
  });
}

String? _nativeShortcut(List<Map<Object?, Object?>> entries, String label) {
  return entries.singleWhere((entry) => entry['label'] == label)['shortcut']
      as String?;
}

String? _nativeIcon(List<Map<Object?, Object?>> entries, String label) {
  return entries.singleWhere((entry) => entry['label'] == label)['icon']
      as String?;
}

RenderEditable? _findRenderEditable(RenderObject root) {
  if (root is RenderEditable) {
    return root;
  }
  RenderEditable? result;
  root.visitChildren((child) {
    result ??= _findRenderEditable(child);
  });
  return result;
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (condition()) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  fail('Timed out waiting for asynchronous Source editor work.');
}
