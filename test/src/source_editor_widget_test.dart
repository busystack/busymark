import 'dart:ui' show BoxHeightStyle;

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/l10n/generated/app_localizations_de.dart';
import 'package:busymark/l10n/generated/app_localizations_en.dart';
import 'package:busymark/src/ai/ai_models.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/core/diagnostic.dart';
import 'package:busymark/src/core/source_span.dart';
import 'package:busymark/src/editor/source/source_editor.dart';
import 'package:busymark/src/editor/source/source_gutter.dart'
    show sourceTextHeightBehavior;
import 'package:busymark/src/editor/source/source_search.dart';
import 'package:busymark/src/editor/source_language.dart';
import 'package:busymark/src/platform/native_menu_service.dart';
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
      expect(field.selectionHeightStyle, BoxHeightStyle.strut);
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
