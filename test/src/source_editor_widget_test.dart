import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show BoxHeightStyle;

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/l10n/generated/app_localizations_de.dart';
import 'package:busymark/l10n/generated/app_localizations_en.dart';
import 'package:busymark/src/ai/ai_models.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/assets/asset_ingestion_service.dart';
import 'package:busymark/src/assets/asset_input_service.dart';
import 'package:busymark/src/clipboard/clipboard_insertion.dart';
import 'package:busymark/src/clipboard/clipboard_models.dart';
import 'package:busymark/src/core/diagnostic.dart';
import 'package:busymark/src/core/source_span.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/busymark_markdown_serializer.dart';
import 'package:busymark/src/markdown/markdown_ast_adapter.dart';
import 'package:busymark/src/editor/document_text_geometry.dart';
import 'package:busymark/src/editor/editor_text_context_menu.dart';
import 'package:busymark/src/editor/source_highlighter.dart'
    show BusyMarkSourceEditingController;
import 'package:busymark/src/editor/source/source_editor.dart';
import 'package:busymark/src/editor/source/source_autocomplete.dart';
import 'package:busymark/src/editor/source/source_gutter.dart'
    show sourceTextHeightBehavior;
import 'package:busymark/src/editor/source/source_search.dart';
import 'package:busymark/src/editor/source_folding.dart';
import 'package:busymark/src/editor/source_language.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_clipboard_fragment.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_inline_controller.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/platform/native_menu_service.dart';
import 'package:busymark/src/platform/rich_clipboard_service.dart';
import 'package:busymark/src/spellcheck/spelling_coordinator.dart';
import 'package:busymark/src/spellcheck/spelling_projection.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/writerside/writerside_project.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:yaru/yaru.dart';

void main() {
  for (final lookupFinished in [false, true]) {
    for (final findNext in [false, true]) {
      testWidgets(
        'search replacement recovers after editing a ${lookupFinished ? 'missing' : 'pending'} result (${findNext ? 'find next' : 'current'})',
        (tester) async {
          final key = GlobalKey<BusyMarkSourceEditorState>();
          var text = lookupFinished ? 'dog cat cat' : 'cat cat cat';
          await tester.pumpWidget(
            MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: StatefulBuilder(
                  builder: (context, setState) => BusyMarkSourceEditor(
                    key: key,
                    text: text,
                    language: SourceSyntaxLanguage.markdown,
                    filePath: '/project/topic.md',
                    diagnostics: const [],
                    editorFontSize: 14,
                    wordWrap: true,
                    searchActive: true,
                    searchOptions: const SourceSearchOptions(query: 'cat'),
                    searchReplacement: 'bat',
                    onSearchReplacementChanged: (_) {},
                    onSearchOptionsChanged: (_) {},
                    onChanged: (value, _) => setState(() => text = value),
                    onOpenSearch: () {},
                    onCloseSearch: () {},
                  ),
                ),
              ),
            ),
          );
          final controller = tester
              .widgetList<TextField>(find.byType(TextField))
              .map((field) => field.controller)
              .whereType<BusyMarkSourceEditingController>()
              .single;
          // Click before the initial search debounce expires, as happens when
          // entering a previously unopened document through the sidebar.
          key.currentState!.scrollToSearchRange(
            line: 1,
            startOffset: 0,
            endOffset: 3,
          );
          await tester.pump();
          final en = AppLocalizationsEn();
          YaruIconButton button(String tooltip) => tester
              .widgetList<YaruIconButton>(find.byType(YaruIconButton))
              .singleWhere((button) => button.tooltip == tooltip);
          if (lookupFinished) {
            await _pumpUntil(
              tester,
              () => controller.searchResult.totalMatchCount == 2,
            );
            await tester.pump();
            // A missing target is settled with replacement unavailable, not
            // silently redirected to a different occurrence.
            expect(controller.searchResult.currentMatchIndex, isNull);
            expect(button(en.sourceSearchReplaceCurrent).onPressed, isNull);
            expect(button(en.sourceSearchReplaceAndFindNext).onPressed, isNull);
            expect(button(en.sourceSearchNextMatch).onPressed, isNotNull);
            expect(
              controller.fullSelection,
              const TextSelection(baseOffset: 0, extentOffset: 3),
            );
          } else {
            expect(controller.searchResult.matches, isEmpty);
          }
          final edited = lookupFinished ? 'fox cat cat' : 'dog cat cat';
          tester.testTextInput.updateEditingValue(
            TextEditingValue(
              text: edited,
              selection: const TextSelection.collapsed(offset: 3),
            ),
          );
          await tester.pump();
          expect(text, edited);
          await _pumpUntil(
            tester,
            () => controller.searchResult.totalMatchCount == 2,
          );
          await tester.pump();
          final tooltip = findNext
              ? en.sourceSearchReplaceAndFindNext
              : en.sourceSearchReplaceCurrent;
          expect(button(tooltip).onPressed, isNotNull);
          await tester.tap(find.byTooltip(tooltip));
          await _pumpUntil(
            tester,
            () => text == edited.replaceRange(4, 7, 'bat'),
          );
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 1));
        },
      );
    }
  }

  for (final count in [3, 3000]) {
    testWidgets('Replace current follows selected result with $count matches', (
      tester,
    ) async {
      final key = GlobalKey<BusyMarkSourceEditorState>();
      final selectedIndex = count == 3 ? 1 : 2048;
      var currentText = List.filled(count, 'cat').join(' ');
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => BusyMarkSourceEditor(
                key: key,
                text: currentText,
                language: SourceSyntaxLanguage.markdown,
                filePath: '/project/topic.md',
                diagnostics: const [],
                editorFontSize: 14,
                wordWrap: true,
                searchActive: true,
                searchOptions: const SourceSearchOptions(query: 'cat'),
                searchReplacement: 'dog',
                onSearchReplacementChanged: (_) {},
                onSearchOptionsChanged: (_) {},
                onChanged: (text, _) => setState(() => currentText = text),
                onOpenSearch: () {},
                onCloseSearch: () {},
              ),
            ),
          ),
        ),
      );
      final controller = tester
          .widgetList<TextField>(find.byType(TextField))
          .map((field) => field.controller)
          .whereType<BusyMarkSourceEditingController>()
          .single;
      await _pumpUntil(
        tester,
        () => controller.searchResult.totalMatchCount == count,
      );
      // Establish a different current index before using the sidebar's API.
      await tester.tap(
        find.byTooltip(AppLocalizationsEn().sourceSearchNextMatch),
      );
      await tester.pump();
      key.currentState!.scrollToSearchRange(
        line: 1,
        startOffset: selectedIndex * 4,
        endOffset: selectedIndex * 4 + 3,
      );
      await _pumpUntil(
        tester,
        () => controller.searchResult.currentMatchIndex == selectedIndex,
      );
      await tester.pump();
      expect(controller.fullSelection.start, selectedIndex * 4);
      expect(find.text('${selectedIndex + 1} / $count'), findsOneWidget);
      await tester.tap(
        find.byTooltip(AppLocalizationsEn().sourceSearchReplaceCurrent),
      );
      await _pumpUntil(
        tester,
        () => currentText.split(' ')[selectedIndex] == 'dog',
      );
      await _pumpUntil(
        tester,
        () => controller.searchResult.totalMatchCount == count - 1,
      );
      expect(
        controller.searchResult.currentMatch!.fullStart,
        (selectedIndex + 1) * 4,
      );
      expect(controller.fullSelection.start, (selectedIndex + 1) * 4);
      await tester.tap(
        find.byTooltip(AppLocalizationsEn().sourceSearchReplaceCurrent),
      );
      await _pumpUntil(
        tester,
        () => currentText.split(' ')[selectedIndex + 1] == 'dog',
      );
      expect(currentText.split(' ').take(selectedIndex), everyElement('cat'));
      expect(
        currentText.split(' ').where((word) => word == 'dog'),
        hasLength(2),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  }

  testWidgets('search navigation retains a later window when unfolding', (
    tester,
  ) async {
    final source = '# Section\n${'cat\n' * 3000}';
    final region = sourceFoldRegions(
      source,
      SourceSyntaxLanguage.markdown,
    ).first;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BusyMarkSourceEditor(
            text: source,
            language: SourceSyntaxLanguage.markdown,
            filePath: '/project/topic.md',
            diagnostics: const [],
            editorFontSize: 14,
            wordWrap: true,
            searchActive: true,
            searchOptions: const SourceSearchOptions(query: 'cat'),
            initialFoldedRegionKeys: {region.key},
            onSearchOptionsChanged: (_) {},
            onChanged: (_, _) {},
            onOpenSearch: () {},
            onCloseSearch: () {},
          ),
        ),
      ),
    );
    final controller = tester
        .widgetList<TextField>(find.byType(TextField))
        .map((field) => field.controller)
        .whereType<BusyMarkSourceEditingController>()
        .single;
    await _pumpUntil(
      tester,
      () => controller.searchResult.totalMatchCount == 3000,
    );
    await tester.tap(
      find.byTooltip(AppLocalizationsEn().sourceSearchPreviousMatch),
    );
    await _pumpUntil(
      tester,
      () =>
          controller.searchResult.currentMatchIndex == 2999 &&
          controller.searchResult.currentMatch?.hidden == false,
    );
    expect(controller.fullSelection.start, source.lastIndexOf('cat'));
    expect(controller.searchResult.firstMatchIndex, greaterThan(0));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('spelling review caret uses full offsets after an earlier fold', (
    tester,
  ) async {
    const source = '# First\nhidden text\n# Second\nmistakke\n';
    const path = '/project/folded-spelling.md';
    final firstRegion = sourceFoldRegions(
      source,
      SourceSyntaxLanguage.markdown,
    ).first;
    final target = source.indexOf('mistakke');
    final key = GlobalKey<BusyMarkSourceEditorState>();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BusyMarkSourceEditor(
            key: key,
            text: source,
            language: SourceSyntaxLanguage.markdown,
            filePath: path,
            diagnostics: const [],
            editorFontSize: 14,
            wordWrap: true,
            searchActive: false,
            searchOptions: const SourceSearchOptions(),
            initialSelection: TextSelection.collapsed(offset: target),
            initialFoldedRegionKeys: {firstRegion.key},
            onSearchOptionsChanged: (_) {},
            onChanged: (_, _) {},
            onOpenSearch: () {},
            onCloseSearch: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    final controller = tester
        .widgetList<TextField>(find.byType(TextField))
        .map((field) => field.controller)
        .whereType<BusyMarkSourceEditingController>()
        .single;

    expect(controller.selection.extentOffset, lessThan(target));
    expect(controller.fullSelection.extentOffset, target);
    expect(key.currentState!.spellingCaretOffset, target);
  });

  testWidgets('spelling reveal unfolds and retains the word selection', (
    tester,
  ) async {
    const source = '# Fold\nhidden mistakke here\n# Next\nend\n';
    const path = '/project/folded-spelling.md';
    final region = sourceFoldRegions(
      source,
      SourceSyntaxLanguage.markdown,
    ).first;
    final start = source.indexOf('mistakke');
    final end = start + 'mistakke'.length;
    final key = GlobalKey<BusyMarkSourceEditorState>();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BusyMarkSourceEditor(
            key: key,
            text: source,
            language: SourceSyntaxLanguage.markdown,
            filePath: path,
            diagnostics: const [],
            editorFontSize: 14,
            wordWrap: true,
            searchActive: false,
            searchOptions: const SourceSearchOptions(),
            initialFoldedRegionKeys: {region.key},
            onSearchOptionsChanged: (_) {},
            onChanged: (_, _) {},
            onOpenSearch: () {},
            onCloseSearch: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    final controller = tester
        .widgetList<TextField>(find.byType(TextField))
        .map((field) => field.controller)
        .whereType<BusyMarkSourceEditingController>()
        .single;
    expect(controller.text, isNot(contains('hidden mistakke')));

    key.currentState!.revealSpellingOccurrence(
      _sourceSpellingOccurrence(
        word: 'mistakke',
        sourceStart: start,
        sourceEnd: end,
        filePath: path,
      ),
    );
    await tester.pump();

    expect(controller.text, contains('hidden mistakke'));
    expect(
      controller.fullSelection,
      TextSelection(baseOffset: start, extentOffset: end),
    );
    expect(controller.fullSelection.isCollapsed, isFalse);
    expect(
      source.substring(
        controller.fullSelection.start,
        controller.fullSelection.end,
      ),
      'mistakke',
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  for (final mode
      in <
        ({
          String label,
          String path,
          SourceSyntaxLanguage language,
          SourceDocumentFormat documentFormat,
          MarkdownMode? markdownMode,
        })
      >[
        (
          label: 'Markdown',
          path: '/project/spelling.md',
          language: SourceSyntaxLanguage.markdown,
          documentFormat: SourceDocumentFormat.markdown,
          markdownMode: MarkdownMode.commonMark,
        ),
        (
          label: 'Writerside Markdown',
          path: '/project/topics/spelling.md',
          language: SourceSyntaxLanguage.markdown,
          documentFormat: SourceDocumentFormat.markdown,
          markdownMode: MarkdownMode.writersideMarkdown,
        ),
        (
          label: 'XML',
          path: '/project/topics/spelling.topic',
          language: SourceSyntaxLanguage.xml,
          documentFormat: SourceDocumentFormat.genericXml,
          markdownMode: null,
        ),
      ]) {
    testWidgets(
      'Source ${mode.label} spelling painter ignores selection and tracks composition',
      (tester) async {
        final annotation = SpellingAnnotation(
          occurrenceId: 'source-paint-helo',
          start: 0,
          end: 4,
          target: SpellingSourceTarget(filePath: mode.path),
        );
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox(
                width: 900,
                height: 600,
                child: BusyMarkSourceEditor(
                  text: 'helo world',
                  language: mode.language,
                  documentFormat: mode.documentFormat,
                  markdownMode: mode.markdownMode,
                  filePath: mode.path,
                  diagnostics: const [],
                  editorFontSize: 14,
                  wordWrap: true,
                  searchActive: false,
                  searchOptions: const SourceSearchOptions(),
                  initialSelection: const TextSelection.collapsed(offset: 4),
                  spellingAnnotations: [annotation],
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

        final controller = tester
            .widgetList<TextField>(find.byType(TextField))
            .map((field) => field.controller)
            .whereType<BusyMarkSourceEditingController>()
            .single;
        const range = TextRange(start: 0, end: 4);
        final painterFinder = find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint &&
              widget.foregroundPainter.runtimeType.toString() ==
                  '_SourceSpellingPainter',
        );
        expect(painterFinder, findsOneWidget);
        final render = tester.renderObject<RenderCustomPaint>(painterFinder);
        expect(render.debugNeedsPaint, isFalse);
        expect(controller.fullSelection.extentOffset, 4);
        expect(
          busyMarkSourceSpellingUnderlineSuppressed(controller, range),
          isFalse,
        );

        controller.fullSelection = const TextSelection.collapsed(offset: 0);
        await tester.pump();
        expect(painterFinder, findsOneWidget);
        expect(
          busyMarkSourceSpellingUnderlineSuppressed(controller, range),
          isFalse,
        );

        controller.fullSelection = const TextSelection.collapsed(offset: 2);
        await tester.pump();
        expect(painterFinder, findsOneWidget);
        expect(
          busyMarkSourceSpellingUnderlineSuppressed(controller, range),
          isFalse,
        );

        controller.fullSelection = const TextSelection.collapsed(offset: 4);
        await tester.pump();
        expect(painterFinder, findsOneWidget);
        expect(
          busyMarkSourceSpellingUnderlineSuppressed(controller, range),
          isFalse,
        );

        controller.fullSelection = const TextSelection(
          baseOffset: 0,
          extentOffset: 4,
        );
        await tester.pump();
        expect(painterFinder, findsOneWidget);
        expect(
          busyMarkSourceSpellingUnderlineSuppressed(controller, range),
          isFalse,
        );

        controller.fullSelection = const TextSelection(
          baseOffset: 5,
          extentOffset: 10,
        );
        await tester.pump();
        expect(painterFinder, findsOneWidget);
        expect(
          busyMarkSourceSpellingUnderlineSuppressed(controller, range),
          isFalse,
        );

        expect(render.debugNeedsPaint, isFalse);
        controller.value = controller.value.copyWith(
          composing: const TextRange(start: 0, end: 4),
        );
        expect(render.debugNeedsPaint, isTrue);
        await tester.pump();
        expect(controller.fullComposing, range);
        expect(
          busyMarkSourceSpellingUnderlineSuppressed(controller, range),
          isTrue,
        );

        controller.value = controller.value.copyWith(
          composing: TextRange.empty,
        );
        expect(render.debugNeedsPaint, isTrue);
        await tester.pump();
        expect(painterFinder, findsOneWidget);
        expect(
          busyMarkSourceSpellingUnderlineSuppressed(controller, range),
          isFalse,
        );

        controller.value = controller.value.copyWith(
          composing: const TextRange(start: 5, end: 10),
        );
        expect(render.debugNeedsPaint, isTrue);
        await tester.pump();
        expect(
          busyMarkSourceSpellingUnderlineSuppressed(controller, range),
          isFalse,
        );
      },
    );
  }

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
              clipboardService: _SourceTestClipboard(
                readData: const RichClipboardData(text: 'Paste', generation: 7),
              ),
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

    final expectedWithPlainPaste = <String>[];
    for (final label in expectedSelectionActions) {
      expectedWithPlainPaste.add(label);
      if (label == 'Paste') {
        expectedWithPlainPaste.add('Paste as Plain Text');
      }
    }
    expect(nativeEntries!.map((entry) => entry['label']), <String>[
      ...expectedWithPlainPaste,
      'Refine with AI',
      '',
      'Clipboard History',
      'Local History…',
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
    expect(
      _nativeShortcut(nativeEntries!, 'Paste as Plain Text'),
      'Ctrl+Shift+V',
    );
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

  testWidgets('source spelling menu targets the pointer occurrence exactly', (
    tester,
  ) async {
    const source = 'helo middle helo\n';
    final secondStart = source.lastIndexOf('helo');
    int? requestedOffset;
    const nativeMenuChannel = MethodChannel(nativeMenuChannelName);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      nativeMenuChannel,
      (call) async {
        if (call.method != 'show') return false;
        return -1;
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
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 600,
            child: BusyMarkSourceEditor(
              text: source,
              clipboardService: _SourceTestClipboard(),
              language: SourceSyntaxLanguage.markdown,
              filePath: '/project/spelling.md',
              diagnostics: const [],
              editorFontSize: 14,
              wordWrap: true,
              searchActive: false,
              searchOptions: const SourceSearchOptions(),
              onSearchOptionsChanged: (_) {},
              onChanged: (_, _) {},
              onOpenSearch: () {},
              onCloseSearch: () {},
              readSpellingMenuItems: (offset) async {
                requestedOffset = offset;
                return [
                  BusyMarkEditorSpellingMenuItem(
                    label: 'hello',
                    onSelected: () {},
                    suggestion: true,
                  ),
                ];
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final field = find.byType(TextField);
    final render = _findRenderEditable(tester.renderObject(field))!;
    final local = render.getLocalRectForCaret(
      TextPosition(offset: secondStart + 1),
    );
    await tester.tapAt(
      render.localToGlobal(local.center),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();

    expect(
      requestedOffset,
      inInclusiveRange(secondStart, secondStart + 'helo'.length),
    );
  });

  testWidgets(
    'source spelling language uses a checked native submenu without a dialog',
    (tester) async {
      const source = 'helo\n';
      const nativeMenuChannel = MethodChannel(nativeMenuChannelName);
      List<Map<Object?, Object?>>? nativeEntries;
      String? targetLabel;
      String? selected;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        nativeMenuChannel,
        (call) async {
          if (call.method != 'show') return false;
          final arguments = call.arguments as Map<Object?, Object?>;
          nativeEntries = (arguments['entries'] as List<Object?>)
              .cast<Map<Object?, Object?>>();
          return targetLabel == null
              ? -1
              : _nativeMenuIndexForLabel(nativeEntries!, targetLabel);
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
          home: Scaffold(
            body: SizedBox(
              width: 900,
              height: 600,
              child: BusyMarkSourceEditor(
                text: source,
                clipboardService: _SourceTestClipboard(),
                language: SourceSyntaxLanguage.markdown,
                filePath: '/project/spelling-submenu.md',
                diagnostics: const [],
                editorFontSize: 14,
                wordWrap: true,
                searchActive: false,
                searchOptions: const SourceSearchOptions(),
                onSearchOptionsChanged: (_) {},
                onChanged: (_, _) {},
                onOpenSearch: () {},
                onCloseSearch: () {},
                readSpellingMenuItems: (_) async => [
                  BusyMarkEditorSpellingMenuItem.submenu(
                    label: 'Choose spelling language',
                    children: [
                      BusyMarkEditorSpellingMenuItem(
                        label: 'Inherit spelling language',
                        checked: true,
                        mutuallyExclusive: true,
                        onSelected: () => selected = 'inherit',
                      ),
                      BusyMarkEditorSpellingMenuItem(
                        label: 'Disable spelling',
                        mutuallyExclusive: true,
                        onSelected: () => selected = 'disabled',
                      ),
                      const BusyMarkEditorSpellingMenuItem.divider(),
                      BusyMarkEditorSpellingMenuItem(
                        label: 'Test English',
                        mutuallyExclusive: true,
                        onSelected: () => selected = 'en-Test',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      Future<void> openMenu() async {
        nativeEntries = null;
        await tester.tap(
          find.byType(TextField),
          buttons: kSecondaryMouseButton,
        );
        await _pumpUntil(tester, () => nativeEntries != null);
      }

      await openMenu();
      final languageMenu = nativeEntries!.singleWhere(
        (entry) => entry['label'] == 'Choose spelling language',
      );
      final children = (languageMenu['children'] as List<Object?>)
          .cast<Map<Object?, Object?>>();
      expect(children.map((entry) => entry['label']), [
        'Inherit spelling language',
        'Disable spelling',
        '',
        'Test English',
      ]);
      expect(
        children.where((entry) => entry['selected'] == true),
        hasLength(1),
      );
      expect(children.first['selected'], isTrue);
      expect(children.first['checkable'], isTrue);
      expect(find.byType(SimpleDialog), findsNothing);
      expect(find.byType(SimpleDialogOption), findsNothing);

      for (final choice in const {
        'Inherit spelling language': 'inherit',
        'Disable spelling': 'disabled',
        'Test English': 'en-Test',
      }.entries) {
        targetLabel = choice.key;
        selected = null;
        await openMenu();
        expect(selected, choice.value);
      }
    },
  );

  testWidgets('source spelling menu converts folded offsets to full source', (
    tester,
  ) async {
    const source = '# First\nhelo hidden\n# Second\nhelo visible\n';
    const path = '/project/folded-menu.md';
    final region = sourceFoldRegions(
      source,
      SourceSyntaxLanguage.markdown,
    ).first;
    final expected = source.lastIndexOf('helo');
    int? requestedOffset;
    const nativeMenuChannel = MethodChannel(nativeMenuChannelName);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      nativeMenuChannel,
      (call) async => call.method == 'show' ? -1 : false,
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
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 600,
            child: BusyMarkSourceEditor(
              text: source,
              clipboardService: _SourceTestClipboard(),
              language: SourceSyntaxLanguage.markdown,
              filePath: path,
              diagnostics: const [],
              editorFontSize: 14,
              wordWrap: true,
              searchActive: false,
              searchOptions: const SourceSearchOptions(),
              initialFoldedRegionKeys: {region.key},
              onSearchOptionsChanged: (_) {},
              onChanged: (_, _) {},
              onOpenSearch: () {},
              onCloseSearch: () {},
              readSpellingMenuItems: (offset) async {
                requestedOffset = offset;
                return const [];
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final field = find.byType(TextField);
    final controller =
        tester.widget<TextField>(field).controller!
            as BusyMarkSourceEditingController;
    final visibleTarget = controller.text.lastIndexOf('helo');
    expect(visibleTarget, lessThan(expected));
    final render = _findRenderEditable(tester.renderObject(field))!;
    final local = render.getLocalRectForCaret(
      TextPosition(offset: visibleTarget + 1),
    );
    await tester.tapAt(
      render.localToGlobal(local.center),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();

    expect(
      requestedOffset,
      inInclusiveRange(expected, expected + 'helo'.length),
    );
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

  testWidgets('source search reports no current match before navigation', (
    tester,
  ) async {
    final en = AppLocalizationsEn();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 600,
            child: BusyMarkSourceEditor(
              text: 'cat cat',
              language: SourceSyntaxLanguage.markdown,
              filePath: '/project/topic.md',
              diagnostics: const [],
              editorFontSize: 14,
              wordWrap: true,
              searchActive: true,
              searchOptions: const SourceSearchOptions(query: 'cat'),
              onSearchOptionsChanged: (_) {},
              onChanged: (_, _) {},
              onOpenSearch: () {},
              onCloseSearch: () {},
            ),
          ),
        ),
      ),
    );

    await _pumpUntil(tester, () => find.text('– / 2').evaluate().isNotEmpty);
    final sourceField = tester
        .widgetList<TextField>(find.byType(TextField))
        .firstWhere((field) => field.controller?.text == 'cat cat');
    final controller =
        sourceField.controller! as BusyMarkSourceEditingController;
    expect(controller.searchResult.currentMatch, isNull);

    await tester.tap(find.byTooltip(en.sourceSearchNextMatch));
    await tester.pump();

    expect(find.text('1 / 2'), findsOneWidget);
    expect(controller.searchResult.currentMatchIndex, 0);
    expect(
      controller.selection,
      const TextSelection(baseOffset: 0, extentOffset: 3),
    );
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
                  return TextEditingValue(
                    text: previous,
                    selection: const TextSelection.collapsed(offset: 0),
                  );
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
    await _pumpUntil(tester, () => find.text('– / 2').evaluate().isNotEmpty);
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
    await _pumpUntil(tester, () => find.text('– / 3').evaluate().isNotEmpty);

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
    'source sessions ignore render notifications and coalesce scrolling',
    (tester) async {
      final sessions =
          <
            ({
              TextSelection selection,
              double scrollOffset,
              Set<String> foldedRegionKeys,
            })
          >[];
      final source = List.generate(80, (index) => 'Line $index').join('\n');
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 900,
              height: 200,
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
                onSessionChanged: (selection, scrollOffset, foldedKeys) {
                  sessions.add((
                    selection: selection,
                    scrollOffset: scrollOffset,
                    foldedRegionKeys: foldedKeys,
                  ));
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      sessions.clear();

      final field = tester.widget<TextField>(find.byType(TextField));
      final controller = field.controller! as BusyMarkSourceEditingController;
      controller.setSearchResult(
        SourceSearchResult(
          options: const SourceSearchOptions(query: 'Line'),
          matches: const [],
        ),
      );
      await tester.pump();
      expect(sessions, isEmpty);

      controller.selection = const TextSelection.collapsed(offset: 3);
      controller.setSearchResult(
        SourceSearchResult(
          options: const SourceSearchOptions(query: 'Line'),
          matches: const [],
          invalidRegex: true,
        ),
      );
      await tester.pump();
      expect(sessions, hasLength(1));
      expect(
        sessions.single.selection,
        const TextSelection.collapsed(offset: 3),
      );

      sessions.clear();
      final scrollController = field.scrollController!;
      expect(scrollController.position.maxScrollExtent, greaterThan(30));
      scrollController
        ..jumpTo(10)
        ..jumpTo(20)
        ..jumpTo(30);
      expect(sessions, isEmpty);
      await tester.pump();
      expect(sessions, hasLength(1));
      expect(sessions.single.scrollOffset, 30);
    },
  );

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
        BusyMarkDocumentTextGeometry.sourceSelectionHeightStyle,
      );
      expect(
        BusyMarkDocumentTextGeometry.sourceSelectionHeightStyle,
        BoxHeightStyle.max,
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
      final selectionTopPadding = glyphBox.top - selectionBox.top;
      final selectionBottomPadding = selectionBox.bottom - glyphBox.bottom;
      expect(selectionTopPadding, greaterThan(1));
      expect(selectionBottomPadding, greaterThan(1));
      expect(selectionBottomPadding, closeTo(selectionTopPadding, 1));
      expect(selectionBox.bottom - caret.bottom, greaterThan(1));
    },
  );

  testWidgets('source heading selections cover styled glyphs evenly', (
    tester,
  ) async {
    const source = '# Agjpqy\nBody\n';
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
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    final renderEditable = _findRenderEditable(
      tester.renderObject<RenderObject>(find.byType(EditableText)),
    )!;
    const selection = TextSelection(baseOffset: 2, extentOffset: 8);
    final selectionBox = renderEditable
        .getBoxesForSelection(selection)
        .single
        .toRect();
    final textPainter = TextPainter(
      text: renderEditable.text,
      strutStyle: field.strutStyle,
      textDirection: TextDirection.ltr,
      textHeightBehavior: sourceTextHeightBehavior,
      textScaler: MediaQuery.textScalerOf(
        tester.element(find.byType(EditableText)),
      ),
    )..layout(maxWidth: 800);
    final glyphBox = textPainter
        .getBoxesForSelection(selection, boxHeightStyle: BoxHeightStyle.tight)
        .single
        .toRect();
    textPainter.dispose();

    final topPadding = glyphBox.top - selectionBox.top;
    final bottomPadding = selectionBox.bottom - glyphBox.bottom;
    expect(topPadding, greaterThan(1));
    expect(bottomPadding, greaterThan(1));
    expect(bottomPadding, closeTo(topPadding, 2));
  });

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

  testWidgets('Tab indents selected Source lines without replacing text', (
    tester,
  ) async {
    var source = 'one\ntwo\nthree';
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
              body: BusyMarkSourceEditor(
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
            );
          },
        ),
      ),
    );
    final fieldFinder = find.byType(TextField);
    await tester.tap(fieldFinder);
    final controller = tester.widget<TextField>(fieldFinder).controller!;
    controller.selection = const TextSelection(baseOffset: 1, extentOffset: 6);
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(source, '  one\n  two\nthree');
    expect(controller.selection.textInside(controller.text), '  one\n  two');
  });

  testWidgets('source symbol shortcuts dispatch the full source caret', (
    tester,
  ) async {
    final actions = <SourceSymbolAction>[];
    final offsets = <int>[];
    final controller = await _pumpAutocompleteSourceEditor(
      tester,
      onSymbolAction: (action, offset) {
        actions.add(action);
        offsets.add(offset);
      },
    );
    controller.selection = const TextSelection.collapsed(offset: 5);
    for (final keys in [
      (LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyB),
      (LogicalKeyboardKey.altLeft, LogicalKeyboardKey.f7),
      (LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.f6),
    ]) {
      await tester.sendKeyDownEvent(keys.$1);
      await tester.sendKeyEvent(keys.$2);
      await tester.sendKeyUpEvent(keys.$1);
    }
    expect(actions, SourceSymbolAction.values);
    expect(offsets, [5, 5, 5]);
    expect(controller.text, _autocompleteSource);
  });

  testWidgets('Ctrl+Space opens project-aware source completion', (
    tester,
  ) async {
    String? changedText;
    await _pumpAutocompleteSourceEditor(
      tester,
      onChanged: (text, _) => changedText = text,
    );
    await _pressControlSpace(tester);

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

  for (final (label, key) in const [
    ('Enter', LogicalKeyboardKey.enter),
    ('Tab', LogicalKeyboardKey.tab),
    ('autocomplete Escape', LogicalKeyboardKey.escape),
  ]) {
    testWidgets('active IME composition defers $label to the input method', (
      tester,
    ) async {
      final controller = await _pumpAutocompleteSourceEditor(tester);
      await _pressControlSpace(tester);
      expect(
        find.byKey(const ValueKey('source-autocomplete-popup')),
        findsOneWidget,
      );

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: _autocompleteSource,
          selection: TextSelection.collapsed(offset: 13),
          composing: TextRange(start: 10, end: 13),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(key);
      await tester.pump();

      expect(controller.text, _autocompleteSource);
      expect(controller.value.composing, const TextRange(start: 10, end: 13));
      expect(
        find.byKey(const ValueKey('source-autocomplete-popup')),
        findsOneWidget,
      );
    });
  }

  testWidgets('active IME composition defers the autocomplete shortcut', (
    tester,
  ) async {
    final controller = await _pumpAutocompleteSourceEditor(tester);
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: _autocompleteSource,
        selection: TextSelection.collapsed(offset: 13),
        composing: TextRange(start: 10, end: 13),
      ),
    );
    await tester.pump();

    await _pressControlSpace(tester);

    expect(controller.text, _autocompleteSource);
    expect(controller.value.composing, const TextRange(start: 10, end: 13));
    expect(
      find.byKey(const ValueKey('source-autocomplete-popup')),
      findsNothing,
    );
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

  testWidgets('source keyboard copy retains exact whitespace once', (
    tester,
  ) async {
    const source = 'before\n \n\t\nafter\n';
    final clipboard = _SourceTestClipboard();
    final captures = <BusyMarkClipboardCapture>[];
    final controller = await _pumpClipboardSourceEditor(
      tester,
      source: source,
      clipboard: clipboard,
      onCaptured: captures.add,
    );
    controller.selection = TextSelection(
      baseOffset: source.indexOf(' \n'),
      extentOffset: source.indexOf('after'),
    );

    await _pressControlKey(tester, LogicalKeyboardKey.keyC);
    await tester.pump();

    expect(clipboard.writes, hasLength(1));
    expect(clipboard.writes.single.text, ' \n\t\n');
    expect(clipboard.writes.single.sourceText, ' \n\t\n');
    expect(captures, hasLength(1));
    expect(captures.single.sourceText, ' \n\t\n');
  });

  testWidgets('Source normal HTML paste converts while plain paste uses text', (
    tester,
  ) async {
    final normalClipboard = _SourceTestClipboard(
      readData: const RichClipboardData(
        text: 'Plain HTML',
        html: '<h2>Heading</h2><p><strong>Bold</strong></p>',
        generation: 1,
      ),
    );
    final normal = await _pumpClipboardSourceEditor(
      tester,
      source: 'Target',
      clipboard: normalClipboard,
    );
    normal.selection = const TextSelection(baseOffset: 0, extentOffset: 6);
    await _pressControlKey(tester, LogicalKeyboardKey.keyV);
    await tester.pump();
    expect(normal.text, contains('## Heading'));
    expect(normal.text, contains('**Bold**'));
    expect(normalClipboard.reads, 1);

    final plainClipboard = _SourceTestClipboard(
      readData: const RichClipboardData(
        text: '  Plain HTML\n',
        html: '<h2>Heading</h2><p><strong>Bold</strong></p>',
        generation: 2,
      ),
    );
    final plain = await _pumpClipboardSourceEditor(
      tester,
      source: 'Target',
      clipboard: plainClipboard,
    );
    final readsBeforePlainPaste = plainClipboard.reads;
    plain.selection = const TextSelection(baseOffset: 0, extentOffset: 6);
    await _pressControlKey(tester, LogicalKeyboardKey.keyV, shift: true);
    await tester.pump();
    expect(plain.text, '  Plain HTML\n');
    expect(plainClipboard.reads, readsBeforePlainPaste + 1);
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('Source CRLF structured paste is one exact undo transaction', (
    tester,
  ) async {
    const source = 'leftright\r\n';
    final clipboard = _SourceTestClipboard(
      readData: RichClipboardData(
        text: '# Heading',
        richFragment: _completeSourceFragment('# Heading\n').encode(),
      ),
    );
    var modelText = source;
    var modelSelection = const TextSelection.collapsed(offset: 'left'.length);
    var history = const DocumentUndoState();
    var transactions = 0;
    final controller = await _pumpClipboardSourceEditor(
      tester,
      source: source,
      clipboard: clipboard,
      onTransactionalChanged:
          (value, _, previousSelection, selection, undoGroup) {
            transactions++;
            history = history.push(
              DocumentHistoryState(
                text: modelText,
                selection: previousSelection,
              ),
              group: undoGroup,
            );
            modelText = value;
            modelSelection = selection;
          },
      onUndo: () {
        if (history.undo.isEmpty) return null;
        final target = history.undo.last;
        history = history.afterUndo(
          DocumentHistoryState(text: modelText, selection: modelSelection),
        );
        modelText = target.text;
        modelSelection = target.selection;
        return TextEditingValue(text: target.text, selection: target.selection);
      },
      onRedo: () {
        if (history.redo.isEmpty) return null;
        final target = history.redo.last;
        history = history.afterRedo(
          DocumentHistoryState(text: modelText, selection: modelSelection),
        );
        modelText = target.text;
        modelSelection = target.selection;
        return TextEditingValue(text: target.text, selection: target.selection);
      },
    );
    controller.selection = modelSelection;

    await _pressControlKey(tester, LogicalKeyboardKey.keyV);
    await tester.pump();
    final pasted = controller.text;
    final pastedSelection = controller.selection;
    expect(transactions, 1);
    expect(pasted, contains('# Heading'));
    expect(_sourceContainsLoneLf(pasted), isFalse, reason: pasted);

    await _pressControlKey(tester, LogicalKeyboardKey.keyZ);
    await tester.pump();
    expect(controller.text, source);
    await _pressControlKey(tester, LogicalKeyboardKey.keyZ, shift: true);
    await tester.pump();
    expect(controller.text, pasted);
    expect(controller.selection, pastedSelection);
  });

  testWidgets('Source plain paste keeps LF bytes in a CRLF document', (
    tester,
  ) async {
    const source = 'left\r\nright\r\n';
    final controller = await _pumpClipboardSourceEditor(
      tester,
      source: source,
      clipboard: _SourceTestClipboard(
        readData: const RichClipboardData(text: 'A\nB'),
      ),
    );
    controller.selection = const TextSelection.collapsed(offset: 'left'.length);

    await _pressControlKey(tester, LogicalKeyboardKey.keyV, shift: true);
    await tester.pump();

    expect(controller.text, 'leftA\nB\r\nright\r\n');
  });

  testWidgets('Source structured inline paste keeps surrounding text inline', (
    tester,
  ) async {
    final clipboard = _SourceTestClipboard(
      readData: const RichClipboardData(
        text: 'X',
        html: '<strong>X</strong>',
        generation: 40,
      ),
    );
    final controller = await _pumpClipboardSourceEditor(
      tester,
      source: 'leftright',
      clipboard: clipboard,
    );
    controller.selection = const TextSelection.collapsed(offset: 4);

    await _pressControlKey(tester, LogicalKeyboardKey.keyV);
    await tester.pump();

    expect(controller.text, 'left**X**right');
    expect(clipboard.reads, 1);
  });

  testWidgets('Source structured block paste adds Markdown boundaries', (
    tester,
  ) async {
    final clipboard = _SourceTestClipboard(
      readData: const RichClipboardData(
        text: 'Heading\nItem',
        html: '<h2>Heading</h2><ul><li>Item</li></ul>',
        generation: 41,
      ),
    );
    final controller = await _pumpClipboardSourceEditor(
      tester,
      source: 'existing',
      clipboard: clipboard,
    );
    controller.selection = const TextSelection.collapsed(offset: 8);

    await _pressControlKey(tester, LogicalKeyboardKey.keyV);
    await tester.pump();

    expect(controller.text, 'existing\n\n## Heading\n\n- Item\n');
    expect(clipboard.reads, 1);
  });

  testWidgets('Source structured blocks keep boundaries at every position', (
    tester,
  ) async {
    final fragment = WysiwygClipboardFragment(
      mode: MarkdownMode.commonMark,
      blocks: const [
        BusyWysiwygStyledBlock(
          kind: BusyBlockKind.heading,
          text: 'Heading',
          ranges: [],
          attributes: {'level': '2'},
        ),
        BusyWysiwygStyledBlock(
          kind: BusyBlockKind.unorderedListItem,
          text: 'Item',
          ranges: [],
        ),
      ],
    );
    for (final value in [
      ('existing', 0, '## Heading\n\n- Item\n\nexisting'),
      ('existing', 8, 'existing\n\n## Heading\n\n- Item\n'),
      ('leftright', 4, 'left\n\n## Heading\n\n- Item\n\nright'),
    ]) {
      final controller = await _pumpClipboardSourceEditor(
        tester,
        source: value.$1,
        clipboard: _SourceTestClipboard(
          readData: RichClipboardData(
            text: 'Heading\nItem',
            richFragment: fragment.encode(),
          ),
        ),
      );
      controller.selection = TextSelection.collapsed(offset: value.$2);
      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();
      expect(controller.text, value.$3);
    }
  });

  testWidgets(
    'Source complete heading list and code blocks retain structure at every paragraph position',
    (tester) async {
      final cases = <({String source, BusyBlockKind kind, String text})>[
        (source: '## Heading\n', kind: BusyBlockKind.heading, text: 'Heading'),
        (
          source: '- Item\n',
          kind: BusyBlockKind.unorderedListItem,
          text: 'Item',
        ),
        (
          source: '```text\ncode\n```\n',
          kind: BusyBlockKind.codeBlock,
          text: 'code',
        ),
      ];
      for (final blockCase in cases) {
        final fragment = _completeSourceFragment(blockCase.source);
        for (final position in [0, 4, 9]) {
          final controller = await _pumpClipboardSourceEditor(
            tester,
            source: 'leftright',
            clipboard: _SourceTestClipboard(
              readData: RichClipboardData(
                text: blockCase.text,
                richFragment: fragment.encode(),
                generation: 700 + position,
              ),
            ),
          );
          controller.selection = TextSelection.collapsed(offset: position);

          await _pressControlKey(tester, LogicalKeyboardKey.keyV);
          await tester.pump();

          final parsed = const MarkdownParser()
              .parse(
                filePath: '/project/source.md',
                source: controller.text,
                validateLocalReferences: false,
              )
              .busyDocument;
          expect(
            parsed.blocks.where((block) => block.kind == blockCase.kind),
            hasLength(1),
          );
          expect(
            parsed.blocks
                .singleWhere((block) => block.kind == blockCase.kind)
                .plainText,
            blockCase.text,
          );
          expect(
            parsed.blocks
                .where((block) => block.kind == BusyBlockKind.paragraph)
                .map((block) => block.plainText)
                .join(),
            'leftright',
          );
        }
      }
    },
  );

  testWidgets(
    'Source complete-block split preserves styles caret and one-step Undo',
    (tester) async {
      const source = '**leftright**';
      final fragment = _completeSourceFragment('## Heading\n');
      var modelText = source;
      var modelSelection = const TextSelection.collapsed(offset: 0);
      var history = const DocumentUndoState();
      var transactions = 0;
      final controller = await _pumpClipboardSourceEditor(
        tester,
        source: source,
        clipboard: _SourceTestClipboard(
          readData: RichClipboardData(
            text: 'Heading',
            richFragment: fragment.encode(),
          ),
        ),
        onTransactionalChanged:
            (value, _, previousSelection, selection, undoGroup) {
              transactions += 1;
              history = history.push(
                DocumentHistoryState(
                  text: modelText,
                  selection: previousSelection,
                ),
                group: undoGroup,
              );
              modelText = value;
              modelSelection = selection;
            },
        onUndo: () {
          if (history.undo.isEmpty) return null;
          final target = history.undo.last;
          history = history.afterUndo(
            DocumentHistoryState(text: modelText, selection: modelSelection),
          );
          modelText = target.text;
          modelSelection = target.selection;
          return TextEditingValue(
            text: target.text,
            selection: target.selection,
          );
        },
        onRedo: () {
          if (history.redo.isEmpty) return null;
          final target = history.redo.last;
          history = history.afterRedo(
            DocumentHistoryState(text: modelText, selection: modelSelection),
          );
          modelText = target.text;
          modelSelection = target.selection;
          return TextEditingValue(
            text: target.text,
            selection: target.selection,
          );
        },
      );
      const initialSelection = TextSelection.collapsed(offset: 6);
      controller.selection = initialSelection;

      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();

      final parsed = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: controller.text,
            validateLocalReferences: false,
          )
          .busyDocument;
      expect(parsed.blocks, hasLength(3), reason: controller.text);
      expect(parsed.blocks.map((block) => block.plainText), [
        'left',
        'Heading',
        'right',
      ]);
      expect(parsed.blocks[1].kind, BusyBlockKind.heading);
      for (final block in [parsed.blocks.first, parsed.blocks.last]) {
        expect(block.inlines.single.kind, BusyInlineKind.strong);
      }
      const marker = '\ue005';
      final marked = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: controller.text.replaceRange(
              controller.selection.baseOffset,
              controller.selection.baseOffset,
              marker,
            ),
            validateLocalReferences: false,
          )
          .busyDocument;
      expect(marked.blocks.last.plainText, '${marker}right');
      expect(marked.blocks.last.inlines.single.kind, BusyInlineKind.strong);

      final editorDocument = const MarkdownParser()
          .parse(
            filePath: '/project/editor.md',
            source: source,
            validateLocalReferences: false,
          )
          .busyDocument;
      final editor = BusyMarkWysiwygDocumentController(
        document: editorDocument,
      );
      addTearDown(editor.dispose);
      final editorResult = editor.insertStyledBlocksAtSelection(
        blockId: editorDocument.blocks.single.id,
        selectionStart: 4,
        selectionEnd: 4,
        blocks: fragment.blocks,
      );
      expect(editorResult, isNotNull);
      expect(editor.document.blocks.map((block) => block.plainText), [
        'left',
        'Heading',
        'right',
      ]);
      for (final block in [
        editor.document.blocks.first,
        editor.document.blocks.last,
      ]) {
        expect(block.inlines.single.kind, BusyInlineKind.strong);
      }

      expect(transactions, 1);
      await _pressControlKey(tester, LogicalKeyboardKey.keyZ);
      await tester.pump();
      expect(controller.text, source);
      expect(controller.selection, initialSelection);
      expect(transactions, 1);
    },
  );

  testWidgets(
    'Source boundary-crossing replacements restore text selection and caret',
    (tester) async {
      final cases =
          <
            ({
              String source,
              TextSelection selection,
              String fragmentSource,
              String clipboardText,
              String expected,
              int expectedCaret,
            })
          >[
            (
              source: '**leftSELECT**tail',
              selection: TextSelection(
                baseOffset: '**left'.length,
                extentOffset: '**leftSELECT**'.length,
              ),
              fragmentSource: '## Heading\n',
              clipboardText: 'Heading',
              expected: '**left**\n\n## Heading\n\ntail',
              expectedCaret: '**left**\n\n## Heading\n\n'.length,
            ),
            (
              source: 'alpha\n\nbeta',
              selection: TextSelection(baseOffset: 2, extentOffset: 9),
              fragmentSource: 'A\n\nB\n',
              clipboardText: 'A\n\nB',
              expected: 'alA\n\nBta',
              expectedCaret: 'alA\n\nB'.length,
            ),
          ];

      for (var index = 0; index < cases.length; index++) {
        final value = cases[index];
        final fragment = _completeSourceFragment(value.fragmentSource);
        var modelText = value.source;
        var modelSelection = const TextSelection.collapsed(offset: 0);
        var history = const DocumentUndoState();
        var transactions = 0;
        final controller = await _pumpClipboardSourceEditor(
          tester,
          source: value.source,
          clipboard: _SourceTestClipboard(
            readData: RichClipboardData(
              text: value.clipboardText,
              richFragment: fragment.encode(),
              generation: 810 + index,
            ),
          ),
          onTransactionalChanged:
              (text, _, previousSelection, selection, undoGroup) {
                transactions += 1;
                history = history.push(
                  DocumentHistoryState(
                    text: modelText,
                    selection: previousSelection,
                  ),
                  group: undoGroup,
                );
                modelText = text;
                modelSelection = selection;
              },
          onUndo: () {
            if (history.undo.isEmpty) return null;
            final target = history.undo.last;
            history = history.afterUndo(
              DocumentHistoryState(text: modelText, selection: modelSelection),
            );
            modelText = target.text;
            modelSelection = target.selection;
            return TextEditingValue(
              text: target.text,
              selection: target.selection,
            );
          },
          onRedo: () {
            if (history.redo.isEmpty) return null;
            final target = history.redo.last;
            history = history.afterRedo(
              DocumentHistoryState(text: modelText, selection: modelSelection),
            );
            modelText = target.text;
            modelSelection = target.selection;
            return TextEditingValue(
              text: target.text,
              selection: target.selection,
            );
          },
        );
        controller.selection = value.selection;

        await _pressControlKey(tester, LogicalKeyboardKey.keyV);
        await tester.pump();

        final pastedSelection = TextSelection.collapsed(
          offset: value.expectedCaret,
        );
        expect(controller.text, value.expected);
        expect(controller.selection, pastedSelection);
        expect(transactions, 1);

        await _pressControlKey(tester, LogicalKeyboardKey.keyZ);
        await tester.pump();
        expect(controller.text, value.source);
        expect(controller.selection, value.selection);

        await _pressControlKey(tester, LogicalKeyboardKey.keyZ, shift: true);
        await tester.pump();
        expect(controller.text, value.expected);
        expect(controller.selection, pastedSelection);
        expect(transactions, 1);

        if (index + 1 < cases.length) {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        }
      }
    },
  );

  testWidgets(
    'Source rich inline paste composes with enclosing inline syntax',
    (tester) async {
      Future<TextEditingController> paste({
        required String source,
        required int offset,
        required String fragmentSource,
      }) async {
        final fragment = _completeSourceFragment(fragmentSource);
        final controller = await _pumpClipboardSourceEditor(
          tester,
          source: source,
          clipboard: _SourceTestClipboard(
            readData: RichClipboardData(
              text: 'X',
              richFragment: fragment.encode(),
            ),
          ),
        );
        controller.selection = TextSelection.collapsed(offset: offset);
        await _pressControlKey(tester, LogicalKeyboardKey.keyV);
        await tester.pump();
        return controller;
      }

      final bold = await paste(
        source: 'Before\n\n**leftright**\n\nAfter\n',
        offset: 'Before\n\n**left'.length,
        fragmentSource: '**X**\n',
      );
      expect(bold.text, 'Before\n\n**leftXright**\n\nAfter\n');
      final boldBlock = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: bold.text,
            validateLocalReferences: false,
          )
          .busyDocument
          .blocks[1];
      expect(boldBlock.inlines.single.kind, BusyInlineKind.strong);
      expect(boldBlock.inlines.single.plainText, 'leftXright');

      final emphasis = await paste(
        source: '*leftright*',
        offset: '*left'.length,
        fragmentSource: '*X*\n',
      );
      expect(emphasis.text, '*leftXright*');
      final emphasisInline = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: emphasis.text,
            validateLocalReferences: false,
          )
          .busyDocument
          .blocks
          .single
          .inlines
          .single;
      expect(emphasisInline.kind, BusyInlineKind.emphasis);
      expect(emphasisInline.plainText, 'leftXright');

      const linkedSource = '[leftright](https://example.test)';
      final linked = await paste(
        source: linkedSource,
        offset: '[left'.length,
        fragmentSource: '**X**\n',
      );
      final link = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: linked.text,
            validateLocalReferences: false,
          )
          .busyDocument
          .blocks
          .single
          .inlines
          .single;
      expect(link.kind, BusyInlineKind.link);
      expect(link.destination, 'https://example.test');
      expect(link.plainText, 'leftXright');
      expect(
        link.children.where((inline) => inline.kind == BusyInlineKind.strong),
        hasLength(1),
      );

      final adjacent = await paste(
        source: '**left****right**',
        offset: '**left**'.length,
        fragmentSource: '**X**\n',
      );
      expect(adjacent.text, '**leftXright**');
      final adjacentBlock = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: adjacent.text,
            validateLocalReferences: false,
          )
          .busyDocument
          .blocks
          .single;
      expect(adjacentBlock.inlines.single.kind, BusyInlineKind.strong);
      expect(adjacentBlock.inlines.single.plainText, 'leftXright');
    },
  );

  testWidgets(
    'Source inline reconciliation ignores separate destination runs',
    (tester) async {
      const source = '**left** gap **right**';
      final controller = await _pumpClipboardSourceEditor(
        tester,
        source: source,
        clipboard: _SourceTestClipboard(
          readData: RichClipboardData(
            text: 'X',
            richFragment: _completeSourceFragment('**X**\n').encode(),
          ),
        ),
      );
      final gap = source.indexOf('gap');
      controller.selection = TextSelection(
        baseOffset: gap,
        extentOffset: gap + 3,
      );

      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();

      expect(controller.text, '**left** **X** **right**');
      expect(controller.selection.baseOffset, '**left** **X**'.length);
      final inlines = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: controller.text,
            validateLocalReferences: false,
          )
          .busyDocument
          .blocks
          .single
          .inlines;
      expect(
        inlines
            .where((inline) => inline.kind == BusyInlineKind.strong)
            .map((inline) => inline.plainText),
        ['left', 'X', 'right'],
      );
    },
  );

  testWidgets(
    'Source adjacent-style reconciliation preserves literal code delimiters',
    (tester) async {
      Future<void> verify({
        required String source,
        required MarkdownMode mode,
      }) async {
        var transactions = 0;
        TextEditingValue? undoValue;
        final controller = await _pumpClipboardSourceEditor(
          tester,
          source: source,
          markdownMode: mode,
          clipboard: _SourceTestClipboard(
            readData: RichClipboardData(
              text: 'X',
              richFragment: _completeSourceFragment(
                '**X**\n',
                mode: mode,
              ).encode(),
            ),
          ),
          onTransactionalChanged: (_, _, previousSelection, _, _) {
            transactions += 1;
            undoValue = TextEditingValue(
              text: source,
              selection: previousSelection,
            );
          },
          onUndo: () {
            final value = undoValue;
            undoValue = null;
            return value;
          },
        );
        final firstRunEnd = source.indexOf('**left**') + '**left**'.length;
        controller.selection = TextSelection.collapsed(offset: firstRunEnd);

        await _pressControlKey(tester, LogicalKeyboardKey.keyV);
        await tester.pump();

        final expected = source.replaceRange(firstRunEnd, firstRunEnd, '**X**');
        expect(controller.text, expected);
        expect(controller.selection.baseOffset, firstRunEnd + '**X**'.length);
        final document = const MarkdownParser()
            .parse(
              filePath: '/project/source.md',
              source: controller.text,
              mode: mode,
              validateLocalReferences: false,
            )
            .busyDocument;
        final inlines = document.blocks.single.kind == BusyBlockKind.table
            ? document.blocks.single.children.last.children.single.inlines
            : document.blocks.single.inlines;
        expect(inlines, hasLength(1));
        expect(inlines.single.kind, BusyInlineKind.code);
        expect(inlines.single.text, '**left****X****right**');
        expect(transactions, 1);

        await _pressControlKey(tester, LogicalKeyboardKey.keyZ);
        await tester.pump();
        expect(controller.text, source);
      }

      await verify(
        source: '`**left****right**`',
        mode: MarkdownMode.commonMark,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await verify(
        source:
            '| H |\n'
            '| --- |\n'
            '| `**left****right**` |\n',
        mode: MarkdownMode.gfm,
      );
    },
  );

  testWidgets(
    'Source table reconciliation preserves a partially consumed delimiter',
    (tester) async {
      const source = '| H |\n| --- |\n| ***leftright** |\n';
      var transactions = 0;
      TextEditingValue? undoValue;
      final controller = await _pumpClipboardSourceEditor(
        tester,
        source: source,
        markdownMode: MarkdownMode.gfm,
        clipboard: _SourceTestClipboard(
          readData: RichClipboardData(
            text: 'X',
            richFragment: _completeSourceFragment(
              'X\n',
              mode: MarkdownMode.gfm,
            ).encode(),
          ),
        ),
        onTransactionalChanged: (_, _, previousSelection, _, _) {
          transactions += 1;
          undoValue = TextEditingValue(
            text: source,
            selection: previousSelection,
          );
        },
        onUndo: () {
          final value = undoValue;
          undoValue = null;
          return value;
        },
      );
      controller.selection = TextSelection.collapsed(
        offset: source.indexOf('leftright') + 'left'.length,
      );

      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();

      expect(controller.text, '| H |\n| --- |\n| ***left**X**right** |\n');
      final parsed = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: controller.text,
            mode: MarkdownMode.gfm,
            validateLocalReferences: false,
          )
          .busyDocument;
      final inlines =
          parsed.blocks.single.children.last.children.single.inlines;
      expect(inlines.map((inline) => inline.plainText).join(), '*leftXright');
      expect(
        inlines
            .where((inline) => inline.kind == BusyInlineKind.strong)
            .map((inline) => inline.plainText),
        ['left', 'right'],
      );
      expect(controller.selection.baseOffset, controller.text.indexOf('X') + 1);
      expect(transactions, 1);

      await _pressControlKey(tester, LogicalKeyboardKey.keyZ);
      await tester.pump();
      expect(controller.text, source);
    },
  );

  testWidgets(
    'Source table inline reconciliation is confined to the selected cell',
    (tester) async {
      const source =
          '| A | B | C |\n'
          '| --- | --- | --- |\n'
          '| **left** | gap | **right** |\n';
      final controller = await _pumpClipboardSourceEditor(
        tester,
        source: source,
        markdownMode: MarkdownMode.gfm,
        clipboard: _SourceTestClipboard(
          readData: RichClipboardData(
            text: 'X',
            richFragment: _completeSourceFragment('**X**\n').encode(),
          ),
        ),
      );
      final gap = source.indexOf('gap');
      controller.selection = TextSelection(
        baseOffset: gap,
        extentOffset: gap + 3,
      );

      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();

      expect(
        controller.text,
        '| A | B | C |\n'
        '| --- | --- | --- |\n'
        '| **left** | **X** | **right** |\n',
      );
      expect(controller.selection.baseOffset, controller.text.indexOf('X') + 3);
      final table = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: controller.text,
            mode: MarkdownMode.gfm,
            validateLocalReferences: false,
          )
          .busyDocument
          .blocks
          .single;
      final cells = table.children.last.children;
      expect(cells[0].inlines.single.kind, BusyInlineKind.strong);
      expect(cells[1].inlines.single.kind, BusyInlineKind.strong);
      expect(cells[1].inlines.single.plainText, 'X');
      expect(cells[2].inlines.single.kind, BusyInlineKind.strong);
    },
  );

  testWidgets('Source table keeps multiple independent incoming style runs', (
    tester,
  ) async {
    const source = '| H |\n| --- |\n| gap |\n';
    final controller = await _pumpClipboardSourceEditor(
      tester,
      source: source,
      markdownMode: MarkdownMode.gfm,
      clipboard: _SourceTestClipboard(
        readData: RichClipboardData(
          text: 'A and B',
          richFragment: _completeSourceFragment('**A** and **B**\n').encode(),
        ),
      ),
    );
    final gap = source.indexOf('gap');
    controller.selection = TextSelection(
      baseOffset: gap,
      extentOffset: gap + 3,
    );

    await _pressControlKey(tester, LogicalKeyboardKey.keyV);
    await tester.pump();

    expect(controller.text, '| H |\n| --- |\n| **A** and **B** |\n');
    final table = const MarkdownParser()
        .parse(
          filePath: '/project/source.md',
          source: controller.text,
          mode: MarkdownMode.gfm,
          validateLocalReferences: false,
        )
        .busyDocument
        .blocks
        .single;
    expect(
      table.children.last.children.single.inlines
          .where((inline) => inline.kind == BusyInlineKind.strong)
          .map((inline) => inline.plainText),
      ['A', 'B'],
    );
  });

  testWidgets(
    'Source does not treat multiple incoming bold runs as one wrapper',
    (tester) async {
      final fragment = _completeSourceFragment('**A** and **B**\n');
      final controller = await _pumpClipboardSourceEditor(
        tester,
        source: 'leftright',
        clipboard: _SourceTestClipboard(
          readData: RichClipboardData(
            text: 'A and B',
            richFragment: fragment.encode(),
          ),
        ),
      );
      controller.selection = const TextSelection.collapsed(offset: 4);

      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();

      expect(controller.text, 'left**A** and **B**right');
      final inlines = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: controller.text,
            validateLocalReferences: false,
          )
          .busyDocument
          .blocks
          .single
          .inlines;
      expect(
        inlines
            .where((inline) => inline.kind == BusyInlineKind.strong)
            .map((inline) => inline.plainText),
        ['A', 'B'],
      );
    },
  );

  testWidgets(
    'Source reconciles arbitrary inline sequences with paragraph context',
    (tester) async {
      final cases = [
        _completeSourceFragment('**A** and **B**\n'),
        _completeSourceFragment('***A*** and [B](https://incoming.test)\n'),
      ];
      for (final (index, fragment) in cases.indexed) {
        const source = '**leftright**';
        final sourceController = await _pumpClipboardSourceEditor(
          tester,
          source: source,
          clipboard: _SourceTestClipboard(
            readData: RichClipboardData(
              text: fragment.documentBlocks.single.plainText,
              richFragment: fragment.encode(),
            ),
          ),
        );
        sourceController.selection = const TextSelection.collapsed(offset: 6);
        await _pressControlKey(tester, LogicalKeyboardKey.keyV);
        await tester.pump();

        final sourceDocument = const MarkdownParser()
            .parse(
              filePath: '/project/source.md',
              source: sourceController.text,
              validateLocalReferences: false,
            )
            .busyDocument;
        final editorDocument = const MarkdownParser()
            .parse(
              filePath: '/project/editor.md',
              source: source,
              validateLocalReferences: false,
            )
            .busyDocument;
        final editorController = BusyMarkWysiwygDocumentController(
          document: editorDocument,
        );
        addTearDown(editorController.dispose);
        final editorBlock = editorController.document.blocks.single;
        expect(
          editorController.insertStyledBlocksAtSelection(
            blockId: editorBlock.id,
            selectionStart: 4,
            selectionEnd: 4,
            blocks: fragment.blocks,
          ),
          isNotNull,
        );

        expect(
          _inlineSemanticRuns(sourceDocument.blocks.single.inlines),
          _inlineSemanticRuns(editorController.document.blocks.single.inlines),
          reason: sourceController.text,
        );
        expect(
          sourceDocument.blocks.single.plainText,
          'left${fragment.documentBlocks.single.plainText}right',
        );
        if (index == 0) {
          expect(sourceController.text, '**leftA and Bright**');
        } else {
          expect(
            _inlineSemanticRuns(
              sourceDocument.blocks.single.inlines,
            ).any((run) => run.context.contains('link:https://incoming.test')),
            isTrue,
          );
        }
        if (index + 1 < cases.length) {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        }
      }
    },
  );

  testWidgets(
    'Source reconciles arbitrary inline sequences inside table cells',
    (tester) async {
      final fragment = _completeSourceFragment(
        '**A** and **B**\n',
        mode: MarkdownMode.gfm,
      );
      const source = '| H |\n| --- |\n| **leftright** |\n';
      final sourceController = await _pumpClipboardSourceEditor(
        tester,
        source: source,
        markdownMode: MarkdownMode.gfm,
        clipboard: _SourceTestClipboard(
          readData: RichClipboardData(
            text: 'A and B',
            richFragment: fragment.encode(),
          ),
        ),
      );
      sourceController.selection = TextSelection.collapsed(
        offset: source.indexOf('leftright') + 4,
      );
      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();

      final sourceTable = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: sourceController.text,
            mode: MarkdownMode.gfm,
            validateLocalReferences: false,
          )
          .busyDocument
          .blocks
          .single;
      final editorDocument = const MarkdownParser()
          .parse(
            filePath: '/project/editor.md',
            source: source,
            mode: MarkdownMode.gfm,
            validateLocalReferences: false,
          )
          .busyDocument;
      final editorController = BusyMarkWysiwygDocumentController(
        document: editorDocument,
      );
      addTearDown(editorController.dispose);
      final editorTable = editorController.document.blocks.single;
      final editorCell = editorTable.children.last.children.single;
      expect(
        editorController.insertStyledInlinesInTableCell(
          tableBlockId: editorTable.id,
          cellId: editorCell.id,
          selectionStart: 4,
          selectionEnd: 4,
          blocks: fragment.blocks,
        ),
        isNotNull,
      );

      final sourceCell = sourceTable.children.last.children.single;
      final resultingEditorCell = editorController.blockById(editorCell.id)!;
      expect(
        _inlineSemanticRuns(sourceCell.inlines),
        _inlineSemanticRuns(resultingEditorCell.inlines),
        reason: sourceController.text,
      );
      expect(sourceCell.plainText, 'leftA and Bright');
      expect(sourceTable.children, hasLength(2));
    },
  );

  testWidgets(
    'Source table sequence reconciliation retains authored delimiters',
    (tester) async {
      final fragment = _completeSourceFragment(
        '**A** and **B**\n',
        mode: MarkdownMode.gfm,
      );
      const source = '| H |\n| --- |\n| __leftright__ |\n';
      final controller = await _pumpClipboardSourceEditor(
        tester,
        source: source,
        markdownMode: MarkdownMode.gfm,
        clipboard: _SourceTestClipboard(
          readData: RichClipboardData(
            text: 'A and B',
            richFragment: fragment.encode(),
          ),
        ),
      );
      controller.selection = TextSelection.collapsed(
        offset: source.indexOf('leftright') + 4,
      );
      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();

      expect(controller.text, '| H |\n| --- |\n| __leftA__ and __Bright__ |\n');
      expect(controller.selection.baseOffset, controller.text.indexOf('B') + 1);
    },
  );

  testWidgets('Source table reconciliation retains mixed nested styles', (
    tester,
  ) async {
    final fragment = _completeSourceFragment(
      '***A*** and [B](https://incoming.test)\n',
      mode: MarkdownMode.gfm,
    );
    const source = '| H |\n| --- |\n| **leftright** |\n';
    final sourceController = await _pumpClipboardSourceEditor(
      tester,
      source: source,
      markdownMode: MarkdownMode.gfm,
      clipboard: _SourceTestClipboard(
        readData: RichClipboardData(
          text: 'A and B',
          richFragment: fragment.encode(),
        ),
      ),
    );
    sourceController.selection = TextSelection.collapsed(
      offset: source.indexOf('leftright') + 4,
    );
    await _pressControlKey(tester, LogicalKeyboardKey.keyV);
    await tester.pump();

    final sourceTable = const MarkdownParser()
        .parse(
          filePath: '/project/source.md',
          source: sourceController.text,
          mode: MarkdownMode.gfm,
          validateLocalReferences: false,
        )
        .busyDocument
        .blocks
        .single;
    final sourceCell = sourceTable.children.last.children.single;
    final editorDocument = const MarkdownParser()
        .parse(
          filePath: '/project/editor.md',
          source: source,
          mode: MarkdownMode.gfm,
          validateLocalReferences: false,
        )
        .busyDocument;
    final editorController = BusyMarkWysiwygDocumentController(
      document: editorDocument,
    );
    addTearDown(editorController.dispose);
    final editorTable = editorController.document.blocks.single;
    final editorCell = editorTable.children.last.children.single;
    expect(
      editorController.insertStyledInlinesInTableCell(
        tableBlockId: editorTable.id,
        cellId: editorCell.id,
        selectionStart: 4,
        selectionEnd: 4,
        blocks: fragment.blocks,
      ),
      isNotNull,
    );
    expect(
      _inlineSemanticRuns(sourceCell.inlines),
      _inlineSemanticRuns(editorController.blockById(editorCell.id)!.inlines),
      reason: sourceController.text,
    );
    expect(sourceTable.children, hasLength(2));
    expect(sourceCell.plainText, 'leftA and Bright');
    expect(
      _inlineSemanticRuns(
        sourceCell.inlines,
      ).any((run) => run.context.contains('link:https://incoming.test')),
      isTrue,
    );
  });

  testWidgets('Source preserves hyperlink semantics in table cells', (
    tester,
  ) async {
    final cases =
        <
          ({
            String label,
            int start,
            int end,
            String incoming,
            List<String?> links,
          })
        >[
          (
            label: 'leftright',
            start: 4,
            end: 4,
            incoming: 'https://incoming.test',
            links: const [
              'https://destination.test',
              'https://incoming.test',
              'https://destination.test',
            ],
          ),
          (
            label: 'leftright',
            start: 4,
            end: 4,
            incoming: 'https://destination.test',
            links: const ['https://destination.test'],
          ),
          (
            label: 'leftmiddleright',
            start: 4,
            end: 10,
            incoming: 'https://incoming.test',
            links: const [
              'https://destination.test',
              'https://incoming.test',
              'https://destination.test',
            ],
          ),
        ];
    for (final (index, value) in cases.indexed) {
      final fragment = _completeSourceFragment(
        '[X](${value.incoming})\n',
        mode: MarkdownMode.gfm,
      );
      final source =
          '| H |\n'
          '| --- |\n'
          '| [${value.label}](https://destination.test) |\n';
      final controller = await _pumpClipboardSourceEditor(
        tester,
        source: source,
        markdownMode: MarkdownMode.gfm,
        clipboard: _SourceTestClipboard(
          readData: RichClipboardData(
            text: 'X',
            richFragment: fragment.encode(),
          ),
        ),
      );
      final labelStart = source.indexOf(value.label);
      controller.selection = TextSelection(
        baseOffset: labelStart + value.start,
        extentOffset: labelStart + value.end,
      );
      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();

      final table = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: controller.text,
            mode: MarkdownMode.gfm,
            validateLocalReferences: false,
          )
          .busyDocument
          .blocks
          .single;
      expect(table.children, hasLength(2), reason: controller.text);
      final sourceCell = table.children.last.children.single;
      expect(
        sourceCell.inlines
            .where((inline) => inline.kind == BusyInlineKind.link)
            .map((inline) => inline.destination),
        value.links,
        reason: controller.text,
      );

      final editorDocument = const MarkdownParser()
          .parse(
            filePath: '/project/editor.md',
            source: source,
            mode: MarkdownMode.gfm,
            validateLocalReferences: false,
          )
          .busyDocument;
      final editorController = BusyMarkWysiwygDocumentController(
        document: editorDocument,
      );
      addTearDown(editorController.dispose);
      final editorTable = editorController.document.blocks.single;
      final editorCell = editorTable.children.last.children.single;
      expect(
        editorController.insertStyledInlinesInTableCell(
          tableBlockId: editorTable.id,
          cellId: editorCell.id,
          selectionStart: value.start,
          selectionEnd: value.end,
          blocks: fragment.blocks,
        ),
        isNotNull,
      );
      expect(
        _inlineSemanticRuns(sourceCell.inlines),
        _inlineSemanticRuns(editorController.blockById(editorCell.id)!.inlines),
        reason: controller.text,
      );
      if (index + 1 < cases.length) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    }
  });

  testWidgets(
    'Source inline mapping handles links multiline styles and literal syntax',
    (tester) async {
      var pasteCount = 0;
      Future<TextEditingController> paste({
        required String source,
        required int start,
        int? end,
        required String fragmentSource,
      }) async {
        if (pasteCount++ > 0) {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        }
        final controller = await _pumpClipboardSourceEditor(
          tester,
          source: source,
          clipboard: _SourceTestClipboard(
            readData: RichClipboardData(
              text: 'X',
              richFragment: _completeSourceFragment(fragmentSource).encode(),
            ),
          ),
        );
        controller.selection = TextSelection(
          baseOffset: start,
          extentOffset: end ?? start,
        );
        await _pressControlKey(tester, LogicalKeyboardKey.keyV);
        await tester.pump();
        return controller;
      }

      const destinationLink = '[leftright](https://destination.test)';
      var controller = await paste(
        source: destinationLink,
        start: '[left'.length,
        fragmentSource: '[X](https://incoming.test)\n',
      );
      expect(
        controller.text,
        '[left](https://destination.test)'
        '[X](https://incoming.test)'
        '[right](https://destination.test)',
      );
      expect(
        controller.selection.baseOffset,
        '[left](https://destination.test)'
                '[X](https://incoming.test)'
            .length,
      );
      var parsed = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: controller.text,
            validateLocalReferences: false,
          )
          .busyDocument;
      expect(parsed.blocks.single.inlines.map((inline) => inline.destination), [
        'https://destination.test',
        'https://incoming.test',
        'https://destination.test',
      ]);

      controller = await paste(
        source: destinationLink,
        start: '[left'.length,
        fragmentSource: '[X](https://destination.test)\n',
      );
      expect(controller.text, '[leftXright](https://destination.test)');
      parsed = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: controller.text,
            validateLocalReferences: false,
          )
          .busyDocument;
      expect(
        parsed.blocks.single.inlines.single.destination,
        'https://destination.test',
      );

      const selectedLink = '[leftmiddleright](https://destination.test)';
      controller = await paste(
        source: selectedLink,
        start: selectedLink.indexOf('middle'),
        end: selectedLink.indexOf('middle') + 'middle'.length,
        fragmentSource: '[X](https://incoming.test)\n',
      );
      expect(
        controller.text,
        '[left](https://destination.test)'
        '[X](https://incoming.test)'
        '[right](https://destination.test)',
      );

      controller = await paste(
        source: destinationLink,
        start: 1,
        end: 1 + 'leftright'.length,
        fragmentSource: '[X](https://incoming.test)\n',
      );
      expect(controller.text, '[X](https://incoming.test)');
      expect(
        controller.selection.baseOffset,
        '[X](https://incoming.test)'.length,
      );

      const titledDestination =
          '[leftright](https://destination.test "Destination title")';
      controller = await paste(
        source: titledDestination,
        start: '[left'.length,
        fragmentSource: '[X](https://incoming.test "Incoming title")\n',
      );
      expect(
        controller.text,
        '[left](https://destination.test "Destination title")'
        '[X](https://incoming.test "Incoming title")'
        '[right](https://destination.test "Destination title")',
      );
      parsed = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: controller.text,
            validateLocalReferences: false,
          )
          .busyDocument;
      expect(
        parsed.blocks.single.inlines.map(
          (inline) => (inline.destination, inline.attributes['title']),
        ),
        [
          ('https://destination.test', 'Destination title'),
          ('https://incoming.test', 'Incoming title'),
          ('https://destination.test', 'Destination title'),
        ],
      );

      controller = await paste(
        source: 'leftright',
        start: 4,
        fragmentSource: '[X](https://incoming.test)\n',
      );
      expect(controller.text, 'left[X](https://incoming.test)right');
      expect(
        controller.selection.baseOffset,
        'left[X](https://incoming.test)'.length,
      );

      const multiline = '*left\nright*';
      controller = await paste(
        source: multiline,
        start: '*left'.length,
        fragmentSource: '*X*\n',
      );
      expect(controller.text, '*leftX\nright*');
      expect(controller.selection.baseOffset, '*leftX'.length);
      parsed = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: controller.text,
            validateLocalReferences: false,
          )
          .busyDocument;
      expect(parsed.blocks.single.inlines.single.kind, BusyInlineKind.emphasis);

      const escaped = r'\*\*left\*\* gap \*\*right\*\*';
      final escapedGap = escaped.indexOf('gap');
      controller = await paste(
        source: escaped,
        start: escapedGap,
        end: escapedGap + 3,
        fragmentSource: '**X**\n',
      );
      expect(controller.text, r'\*\*left\*\* **X** \*\*right\*\*');
      parsed = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: controller.text,
            validateLocalReferences: false,
          )
          .busyDocument;
      expect(
        parsed.blocks.single.inlines
            .where((inline) => inline.kind == BusyInlineKind.strong)
            .map((inline) => inline.plainText),
        ['X'],
      );

      const code = '`**left** gap **right**`';
      final codeGap = code.indexOf('gap');
      controller = await paste(
        source: code,
        start: codeGap,
        end: codeGap + 3,
        fragmentSource: '**X**\n',
      );
      expect(controller.text, '`**left** **X** **right**`');
      parsed = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: controller.text,
            validateLocalReferences: false,
          )
          .busyDocument;
      expect(parsed.blocks.single.inlines.single.kind, BusyInlineKind.code);
      expect(
        parsed.blocks.single.inlines.single.plainText,
        '**left** **X** **right**',
      );

      const crossing = 'before **bold** and *em* after';
      final crossingStart = crossing.indexOf('**bold**');
      final crossingEnd = crossing.indexOf('*em*') + '*em*'.length;
      controller = await paste(
        source: crossing,
        start: crossingStart,
        end: crossingEnd,
        fragmentSource: '**X**\n',
      );
      expect(controller.text, 'before **X** after');
      expect(controller.selection.baseOffset, 'before **X**'.length);

      const replacement = '**leftDELETEright**';
      final replacementStart = replacement.indexOf('DELETE');
      controller = await paste(
        source: replacement,
        start: replacementStart,
        end: replacementStart + 'DELETE'.length,
        fragmentSource: '**X**\n',
      );
      expect(controller.text, '**leftXright**');
      expect(controller.selection.baseOffset, '**leftX'.length);

      controller = await paste(
        source: '**left**right',
        start: '**left**'.length,
        fragmentSource: '**X**\n',
      );
      expect(controller.text, '**left****X**right');
      expect(controller.selection.baseOffset, '**left****X**'.length);
    },
  );

  testWidgets(
    'Source caret mapping preserves literal bang before a following link',
    (tester) async {
      Future<void> verify({
        required String source,
        required MarkdownMode mode,
      }) async {
        var transactions = 0;
        TextEditingValue? undoValue;
        final fragment = _completeSourceFragment(
          '[X](https://incoming.test)!\n',
          mode: mode,
        );
        final controller = await _pumpClipboardSourceEditor(
          tester,
          source: source,
          markdownMode: mode,
          clipboard: _SourceTestClipboard(
            readData: RichClipboardData(
              text: 'X!',
              richFragment: fragment.encode(),
            ),
          ),
          onTransactionalChanged: (_, _, previousSelection, _, _) {
            transactions += 1;
            undoValue = TextEditingValue(
              text: source,
              selection: previousSelection,
            );
          },
          onUndo: () {
            final value = undoValue;
            undoValue = null;
            return value;
          },
        );
        controller.selection = TextSelection.collapsed(
          offset: source.indexOf('leftright') + 4,
        );

        await _pressControlKey(tester, LogicalKeyboardKey.keyV);
        await tester.pump();

        const replacement =
            '[left](https://destination.test)'
            '[X](https://incoming.test)\\!'
            '[right](https://destination.test)';
        final expected = source.replaceFirst(
          '[leftright](https://destination.test)',
          replacement,
        );
        expect(controller.text, expected);
        expect(controller.selection.baseOffset, expected.indexOf(r'\!') + 2);
        final document = const MarkdownParser()
            .parse(
              filePath: '/project/source.md',
              source: controller.text,
              mode: mode,
              validateLocalReferences: false,
            )
            .busyDocument;
        final inlines = document.blocks.single.kind == BusyBlockKind.table
            ? document.blocks.single.children.last.children.single.inlines
            : document.blocks.single.inlines;
        expect(
          inlines
              .where((inline) => inline.kind == BusyInlineKind.link)
              .map((inline) => inline.destination),
          [
            'https://destination.test',
            'https://incoming.test',
            'https://destination.test',
          ],
          reason: controller.text,
        );
        expect(
          inlines.where((inline) => inline.kind == BusyInlineKind.image),
          isEmpty,
          reason: controller.text,
        );
        expect(inlines.map((inline) => inline.plainText).join(), 'leftX!right');
        expect(transactions, 1);
        await _pressControlKey(tester, LogicalKeyboardKey.keyZ);
        await tester.pump();
        expect(controller.text, source);
      }

      await verify(
        source: '[leftright](https://destination.test)',
        mode: MarkdownMode.commonMark,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await verify(
        source:
            '| H |\n'
            '| --- |\n'
            '| [leftright](https://destination.test) |\n',
        mode: MarkdownMode.gfm,
      );
    },
  );

  testWidgets(
    'Source splits resolved reference links without changing definitions',
    (tester) async {
      final cases = <({String link, String definition})>[
        (
          link: '[leftright][dest]',
          definition: '[dest]: https://destination.test',
        ),
        (
          link: '[leftright][]',
          definition: '[leftright]: https://destination.test',
        ),
        (
          link: '[leftright]',
          definition: '[leftright]: https://destination.test',
        ),
      ];
      for (final (index, value) in cases.indexed) {
        final source = '${value.link}\n\n${value.definition}\n';
        final fragment = _completeSourceFragment(
          '[X](https://incoming.test)\n',
        );
        final controller = await _pumpClipboardSourceEditor(
          tester,
          source: source,
          clipboard: _SourceTestClipboard(
            readData: RichClipboardData(
              text: 'X',
              richFragment: fragment.encode(),
            ),
          ),
        );
        controller.selection = TextSelection.collapsed(
          offset: source.indexOf('leftright') + 4,
        );

        await _pressControlKey(tester, LogicalKeyboardKey.keyV);
        await tester.pump();

        expect(
          controller.text,
          '[left](https://destination.test)'
          '[X](https://incoming.test)'
          '[right](https://destination.test)\n\n'
          '${value.definition}\n',
          reason: value.link,
        );
        expect(
          controller.selection.baseOffset,
          '[left](https://destination.test)'
                  '[X](https://incoming.test)'
              .length,
        );
        final parsed = const MarkdownParser()
            .parse(
              filePath: '/project/source.md',
              source: controller.text,
              validateLocalReferences: false,
            )
            .busyDocument;
        expect(
          parsed.blocks.first.inlines
              .where((inline) => inline.kind == BusyInlineKind.link)
              .map((inline) => inline.destination),
          [
            'https://destination.test',
            'https://incoming.test',
            'https://destination.test',
          ],
        );
        expect(controller.text, contains('${value.definition}\n'));
        if (index + 1 < cases.length) {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        }
      }
    },
  );

  testWidgets(
    'Source splits multiline blockquote links without exposing prefixes',
    (tester) async {
      const source =
          '> [left\n'
          '> right](https://destination.test)';
      var transactions = 0;
      TextEditingValue? undoValue;
      final controller = await _pumpClipboardSourceEditor(
        tester,
        source: source,
        clipboard: _SourceTestClipboard(
          readData: RichClipboardData(
            text: 'X',
            richFragment: _completeSourceFragment(
              '[X](https://incoming.test)\n',
            ).encode(),
          ),
        ),
        onTransactionalChanged: (_, _, previousSelection, _, _) {
          transactions += 1;
          undoValue = TextEditingValue(
            text: source,
            selection: previousSelection,
          );
        },
        onUndo: () {
          final value = undoValue;
          undoValue = null;
          return value;
        },
      );
      controller.selection = TextSelection.collapsed(
        offset: source.indexOf('left') + 'left'.length,
      );

      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();

      expect(
        controller.text,
        '> [left](https://destination.test)'
        '[X](https://incoming.test)'
        '[\n'
        '> right](https://destination.test)',
      );
      final parsed = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: controller.text,
            validateLocalReferences: false,
          )
          .busyDocument;
      expect(parsed.blocks, hasLength(1), reason: controller.text);
      expect(parsed.blocks.single.kind, BusyBlockKind.blockquote);
      final paragraph = _sourceBlocksDepthFirst(
        parsed.blocks.single.children,
      ).firstWhere((block) => block.kind == BusyBlockKind.paragraph);
      final links = paragraph.inlines
          .where((inline) => inline.kind == BusyInlineKind.link)
          .toList();
      expect(links.map((inline) => inline.destination), [
        'https://destination.test',
        'https://incoming.test',
        'https://destination.test',
      ], reason: controller.text);
      expect(links[0].plainText, 'left');
      expect(links[1].plainText, 'X');
      expect(links[2].plainText, '\nright');
      expect(paragraph.plainText, 'leftX\nright');
      expect(paragraph.plainText, isNot(contains('>')));
      final incomingEnd =
          controller.text.indexOf('[X](https://incoming.test)') +
          '[X](https://incoming.test)'.length;
      expect(controller.selection.baseOffset, incomingEnd);
      expect(transactions, 1);

      await _pressControlKey(tester, LogicalKeyboardKey.keyZ);
      await tester.pump();
      expect(controller.text, source);
    },
  );

  testWidgets('Source preserves occurrence-specific hard-break provenance', (
    tester,
  ) async {
    final cases = <({String source, String expected})>[
      (
        source:
            '> [left  \r\n'
            '> middle  \n'
            '> right](https://destination.test)',
        expected:
            '> [left](https://destination.test)'
            '[X](https://incoming.test)'
            '[  \r\n'
            '> middle  \n'
            '> right](https://destination.test)',
      ),
      (
        source:
            '> [left  \r\n'
            '  > middle  \n'
            '> right](https://destination.test)',
        expected:
            '> [left](https://destination.test)'
            '[X](https://incoming.test)'
            '[  \r\n'
            '  > middle  \n'
            '> right](https://destination.test)',
      ),
      (
        source:
            '> [left  \r\n'
            '> right](https://destination.test) and '
            '[later  \n'
            '> end](https://later.test)',
        expected:
            '> [left](https://destination.test)'
            '[X](https://incoming.test)'
            '[  \r\n'
            '> right](https://destination.test) and '
            '[later  \n'
            '> end](https://later.test)',
      ),
    ];
    for (final (index, value) in cases.indexed) {
      var transactions = 0;
      TextEditingValue? undoValue;
      final controller = await _pumpClipboardSourceEditor(
        tester,
        source: value.source,
        clipboard: _SourceTestClipboard(
          readData: RichClipboardData(
            text: 'X',
            richFragment: _completeSourceFragment(
              '[X](https://incoming.test)\n',
            ).encode(),
          ),
        ),
        onTransactionalChanged: (_, _, previousSelection, _, _) {
          transactions += 1;
          undoValue = TextEditingValue(
            text: value.source,
            selection: previousSelection,
          );
        },
        onUndo: () {
          final value = undoValue;
          undoValue = null;
          return value;
        },
      );
      controller.selection = TextSelection.collapsed(
        offset: value.source.indexOf('left') + 'left'.length,
      );

      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();

      expect(controller.text, value.expected, reason: value.source);
      final incomingEnd =
          controller.text.indexOf('[X](https://incoming.test)') +
          '[X](https://incoming.test)'.length;
      expect(controller.selection.baseOffset, incomingEnd);
      expect(controller.text, isNot(contains('\ue000')));
      final document = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: controller.text,
            validateLocalReferences: false,
          )
          .busyDocument;
      expect(document.blocks.single.kind, BusyBlockKind.blockquote);
      final links = _sourceBlocksDepthFirst(document.blocks)
          .expand((block) => block.inlines)
          .where((inline) => inline.kind == BusyInlineKind.link)
          .toList(growable: false);
      expect(links.take(3).map((inline) => inline.destination), [
        'https://destination.test',
        'https://incoming.test',
        'https://destination.test',
      ]);
      expect(transactions, 1);

      await _pressControlKey(tester, LogicalKeyboardKey.keyZ);
      await tester.pump();
      expect(controller.text, value.source);
      if (index + 1 < cases.length) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    }
  });

  testWidgets('Source caret remains between pasted and retained hard breaks', (
    tester,
  ) async {
    const source = '[left  \nright](https://destination.test)';
    var modelText = source;
    var modelSelection = const TextSelection.collapsed(offset: 0);
    var history = const DocumentUndoState();
    final controller = await _pumpClipboardSourceEditor(
      tester,
      source: source,
      clipboard: _SourceTestClipboard(
        readData: RichClipboardData(
          text: 'XA',
          richFragment: _completeSourceFragment(
            '[X](https://incoming.test)'
            '[A  \n](https://destination.test)\n',
          ).encode(),
        ),
      ),
      onTransactionalChanged:
          (value, _, previousSelection, selection, undoGroup) {
            history = history.push(
              DocumentHistoryState(
                text: modelText,
                selection: previousSelection,
              ),
              group: undoGroup,
            );
            modelText = value;
            modelSelection = selection;
          },
      onUndo: () {
        if (history.undo.isEmpty) return null;
        final target = history.undo.last;
        history = history.afterUndo(
          DocumentHistoryState(text: modelText, selection: modelSelection),
        );
        modelText = target.text;
        modelSelection = target.selection;
        return TextEditingValue(text: target.text, selection: target.selection);
      },
      onRedo: () {
        if (history.redo.isEmpty) return null;
        final target = history.redo.last;
        history = history.afterRedo(
          DocumentHistoryState(text: modelText, selection: modelSelection),
        );
        modelText = target.text;
        modelSelection = target.selection;
        return TextEditingValue(text: target.text, selection: target.selection);
      },
    );
    controller.selection = TextSelection.collapsed(
      offset: source.indexOf('left') + 'left'.length,
    );

    await _pressControlKey(tester, LogicalKeyboardKey.keyV);
    await tester.pump();

    const pasted =
        '[left](https://destination.test)'
        '[X](https://incoming.test)'
        '[A\n'
        '<br>\n'
        '<br>\n'
        'right](https://destination.test)';
    expect(controller.text, pasted);
    final intendedCaret = pasted.indexOf('<br>\n<br>') + '<br>'.length;
    expect(controller.selection.baseOffset, intendedCaret);

    final typed = pasted.replaceRange(intendedCaret, intendedCaret, 'Z');
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: typed,
        selection: TextSelection.collapsed(offset: intendedCaret + 1),
      ),
    );
    await tester.pump();
    expect(controller.text, typed);
    final parsed = const MarkdownParser()
        .parse(
          filePath: '/project/source.md',
          source: controller.text,
          validateLocalReferences: false,
        )
        .busyDocument;
    final links = parsed.blocks.single.inlines
        .where((inline) => inline.kind == BusyInlineKind.link)
        .toList(growable: false);
    expect(links.map((inline) => inline.destination), [
      'https://destination.test',
      'https://incoming.test',
      'https://destination.test',
    ]);
    final lastChildren = links.last.children;
    final hardBreakIndexes = [
      for (final (index, inline) in lastChildren.indexed)
        if (inline.kind == BusyInlineKind.hardBreak) index,
    ];
    final typedIndex = lastChildren.indexWhere(
      (inline) => inline.plainText.contains('Z'),
    );
    expect(hardBreakIndexes, hasLength(2));
    expect(hardBreakIndexes.first, lessThan(typedIndex));
    expect(typedIndex, lessThan(hardBreakIndexes.last));
    expect(controller.text, contains('<br>Z\n<br>'));

    await _pressControlKey(tester, LogicalKeyboardKey.keyZ);
    await tester.pump();
    expect(controller.text, pasted);
    expect(controller.selection.baseOffset, intendedCaret);
    await _pressControlKey(tester, LogicalKeyboardKey.keyZ);
    await tester.pump();
    expect(controller.text, source);
    await _pressControlKey(tester, LogicalKeyboardKey.keyZ, shift: true);
    await tester.pump();
    expect(controller.text, pasted);
    expect(controller.selection.baseOffset, intendedCaret);
    await _pressControlKey(tester, LogicalKeyboardKey.keyZ, shift: true);
    await tester.pump();
    expect(controller.text, typed);
    expect(controller.selection.baseOffset, intendedCaret + 1);
  });

  testWidgets(
    'Source rich paste after an HTML break does not retain its layout newline',
    (tester) async {
      const source =
          '[A\n'
          '<br>\n'
          '<br>\n'
          'right](https://destination.test) tail';
      final controller = await _pumpClipboardSourceEditor(
        tester,
        source: source,
        clipboard: _SourceTestClipboard(
          readData: RichClipboardData(
            text: 'Y',
            richFragment: _completeSourceFragment(
              '[Y](https://incoming.test)\n',
            ).encode(),
          ),
        ),
      );
      final secondBreak = source.indexOf('<br>', source.indexOf('<br>') + 1);
      controller.selection = TextSelection.collapsed(
        offset: secondBreak + '<br>'.length,
      );

      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();

      final parsed = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: controller.text,
            validateLocalReferences: false,
          )
          .busyDocument;
      final paragraph = parsed.blocks.single;
      expect(paragraph.plainText, 'A\n\nYright tail', reason: controller.text);
      expect(
        paragraph.inlines
            .where((inline) => inline.kind == BusyInlineKind.link)
            .map((inline) => inline.destination),
        [
          'https://destination.test',
          'https://incoming.test',
          'https://destination.test',
        ],
        reason: controller.text,
      );
    },
  );

  testWidgets('Source rich paste preserves enclosing inline HTML as one run', (
    tester,
  ) async {
    const source = '[<u>left<br>right</u>](https://destination.test) tail';
    final controller = await _pumpClipboardSourceEditor(
      tester,
      source: source,
      clipboard: _SourceTestClipboard(
        readData: RichClipboardData(
          text: 'Y',
          richFragment: _completeSourceFragment(
            '[Y](https://incoming.test)\n',
          ).encode(),
        ),
      ),
    );
    controller.selection = TextSelection.collapsed(
      offset: source.indexOf('right') + 'ri'.length,
    );

    await _pressControlKey(tester, LogicalKeyboardKey.keyV);
    await tester.pump();

    final parsed = const MarkdownParser()
        .parse(
          filePath: '/project/source.md',
          source: controller.text,
          validateLocalReferences: false,
        )
        .busyDocument;
    final paragraph = parsed.blocks.single;
    expect(paragraph.plainText, 'left\nriYght tail', reason: controller.text);
    expect(controller.text, isNot(contains('</u> tail')));
    final links = paragraph.inlines
        .where((inline) => inline.kind == BusyInlineKind.link)
        .toList(growable: false);
    expect(links.map((inline) => inline.destination), [
      'https://destination.test',
      'https://incoming.test',
      'https://destination.test',
    ], reason: controller.text);
    final surviving = [links.first, links.last]
        .expand((inline) => inline.children)
        .where((inline) => inline.kind == BusyInlineKind.underline)
        .toList(growable: false);
    expect(surviving, hasLength(2), reason: controller.text);
    expect(
      surviving
          .expand((inline) => inline.children)
          .where((inline) => inline.kind == BusyInlineKind.hardBreak),
      hasLength(1),
      reason: controller.text,
    );
  });

  testWidgets(
    'Source system and history rich paste map normalized HTML whitespace',
    (tester) async {
      const source =
          '[<u>left  right</u>]'
          '(https://destination.test) tail';
      const html = '<a href="https://incoming.test">Y</a>';
      for (final (index, fromHistory) in [false, true].indexed) {
        final registry = BusyMarkClipboardInsertionRegistry();
        final clipboard = _SourceTestClipboard(
          readData: const RichClipboardData(
            text: 'Y',
            html: html,
            generation: 55,
          ),
        );
        TextEditingValue? undoValue;
        var transactions = 0;
        final controller = await _pumpClipboardSourceEditor(
          tester,
          source: source,
          clipboard: clipboard,
          registry: registry,
          onTransactionalChanged: (_, _, previousSelection, _, _) {
            transactions += 1;
            undoValue = TextEditingValue(
              text: source,
              selection: previousSelection,
            );
          },
          onUndo: () {
            final value = undoValue;
            undoValue = null;
            return value;
          },
        );
        controller.selection = const TextSelection.collapsed(
          offset: '[<u>left '.length,
        );

        if (fromHistory) {
          final payload = BusyMarkClipboardPayload(
            id: 'html-whitespace-history',
            acquiredAt: DateTime.utc(2026),
            kind: BusyMarkClipboardContentKind.richText,
            text: 'Y',
            html: html,
          );
          expect(registry.canPaste(payload), isTrue);
          expect(await registry.paste(payload), ClipboardPasteResult.inserted);
        } else {
          await _pressControlKey(tester, LogicalKeyboardKey.keyV);
          await tester.pump();
        }

        final document = const MarkdownParser()
            .parse(
              filePath: '/project/source.md',
              source: controller.text,
              validateLocalReferences: false,
            )
            .busyDocument;
        final paragraph = document.blocks.single;
        expect(paragraph.plainText, 'left Yright tail');
        final links = paragraph.inlines
            .where((inline) => inline.kind == BusyInlineKind.link)
            .toList(growable: false);
        expect(links.map((inline) => inline.destination), [
          'https://destination.test',
          'https://incoming.test',
          'https://destination.test',
        ], reason: controller.text);
        expect(
          _inlineSemanticRuns(paragraph.inlines)
              .where((run) => run.context.contains('underline'))
              .map((run) => run.text),
          ['left', 'Y', 'right'],
          reason: controller.text,
        );
        final incomingEnd =
            controller.text.indexOf('https://incoming.test') +
            'https://incoming.test'.length +
            1;
        expect(controller.selection.baseOffset, incomingEnd);
        expect(transactions, 1);

        await _pressControlKey(tester, LogicalKeyboardKey.keyZ);
        await tester.pump();
        expect(controller.text, source);
        registry.dispose();
        if (index == 0) {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        }
      }
    },
  );

  testWidgets(
    'Source syntax-only availability agrees with textual fallback execution',
    (tester) async {
      const source = '**left**';
      final registry = BusyMarkClipboardInsertionRegistry();
      addTearDown(registry.dispose);
      final controller = await _pumpClipboardSourceEditor(
        tester,
        source: source,
        registry: registry,
        clipboard: _SourceTestClipboard(),
      );
      controller.selection = const TextSelection.collapsed(offset: 1);
      final fragment = _completeSourceFragment('[Y](https://incoming.test)\n');
      final payload = BusyMarkClipboardPayload(
        id: 'syntax-fallback',
        acquiredAt: DateTime.utc(2026),
        kind: BusyMarkClipboardContentKind.richText,
        text: 'Y',
        richFragment: fragment.encode(),
      );

      expect(registry.canPaste(payload), isTrue);
      expect(await registry.paste(payload), ClipboardPasteResult.inserted);
      expect(controller.text, '*Y*left**');
      expect(controller.selection, const TextSelection.collapsed(offset: 2));
    },
  );

  testWidgets(
    'Source terminal structured failure blocks availability and text fallback',
    (tester) async {
      const source = '<a href="https://destination.test">left';
      final registry = BusyMarkClipboardInsertionRegistry();
      addTearDown(registry.dispose);
      var transactions = 0;
      final fragment = _completeSourceFragment('[Y](https://incoming.test)\n');
      final controller = await _pumpClipboardSourceEditor(
        tester,
        source: source,
        registry: registry,
        clipboard: _SourceTestClipboard(
          readData: RichClipboardData(
            text: 'Y',
            richFragment: fragment.encode(),
          ),
        ),
        onTransactionalChanged: (_, _, _, _, _) => transactions += 1,
      );
      controller.selection = TextSelection.collapsed(
        offset: source.indexOf('left') + 2,
      );
      final payload = BusyMarkClipboardPayload(
        id: 'terminal-structured',
        acquiredAt: DateTime.utc(2026),
        kind: BusyMarkClipboardContentKind.richText,
        text: 'Y',
        richFragment: fragment.encode(),
      );

      expect(registry.canPaste(payload), isFalse);
      expect(await registry.paste(payload), ClipboardPasteResult.unavailable);
      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();
      expect(controller.text, source);
      expect(transactions, 0);
    },
  );

  testWidgets('Source rich paste remaps generated grouped hard breaks', (
    tester,
  ) async {
    const source = '[left  \nright](https://destination.test) tail';
    final clipboard = _SourceTestClipboard(
      readData: RichClipboardData(
        text: 'XA',
        richFragment: _completeSourceFragment(
          '[X](https://incoming.test)'
          '[A  \n](https://destination.test)\n',
        ).encode(),
      ),
    );
    var modelText = source;
    var modelSelection = const TextSelection.collapsed(offset: 0);
    var history = const DocumentUndoState();
    var transactions = 0;
    final controller = await _pumpClipboardSourceEditor(
      tester,
      source: source,
      clipboard: clipboard,
      onTransactionalChanged:
          (value, _, previousSelection, selection, undoGroup) {
            transactions += 1;
            history = history.push(
              DocumentHistoryState(
                text: modelText,
                selection: previousSelection,
              ),
              group: undoGroup,
            );
            modelText = value;
            modelSelection = selection;
          },
      onUndo: () {
        if (history.undo.isEmpty) return null;
        final target = history.undo.last;
        history = history.afterUndo(
          DocumentHistoryState(text: modelText, selection: modelSelection),
        );
        modelText = target.text;
        modelSelection = target.selection;
        return TextEditingValue(text: target.text, selection: target.selection);
      },
      onRedo: () {
        if (history.redo.isEmpty) return null;
        final target = history.redo.last;
        history = history.afterRedo(
          DocumentHistoryState(text: modelText, selection: modelSelection),
        );
        modelText = target.text;
        modelSelection = target.selection;
        return TextEditingValue(text: target.text, selection: target.selection);
      },
    );
    controller.selection = TextSelection.collapsed(
      offset: source.indexOf('left') + 'left'.length,
    );

    await _pressControlKey(tester, LogicalKeyboardKey.keyV);
    await tester.pump();

    const firstPaste =
        '[left](https://destination.test)'
        '[X](https://incoming.test)'
        '[A\n'
        '<br>\n'
        '<br>\n'
        'right](https://destination.test) tail';
    expect(controller.text, firstPaste);
    final firstCaret = firstPaste.indexOf('<br>\n<br>') + '<br>'.length;
    expect(controller.selection.baseOffset, firstCaret);

    clipboard.readData = RichClipboardData(
      text: 'Y',
      richFragment: _completeSourceFragment(
        '[Y](https://second.test)\n',
      ).encode(),
    );
    final secondInsertion = firstPaste.indexOf('right') + 'ri'.length;
    controller.selection = TextSelection.collapsed(offset: secondInsertion);
    await _pressControlKey(tester, LogicalKeyboardKey.keyV);
    await tester.pump();

    const secondPaste =
        '[left](https://destination.test)'
        '[X](https://incoming.test)'
        '[A\n'
        '<br>\n'
        '<br>\n'
        'ri](https://destination.test)'
        '[Y](https://second.test)'
        '[ght](https://destination.test) tail';
    expect(controller.text, secondPaste);
    final secondCaret =
        secondPaste.indexOf('[Y](https://second.test)') +
        '[Y](https://second.test)'.length;
    expect(controller.selection.baseOffset, secondCaret);
    expect(transactions, 2);

    final parsed = const MarkdownParser()
        .parse(
          filePath: '/project/source.md',
          source: controller.text,
          validateLocalReferences: false,
        )
        .busyDocument;
    final links = parsed.blocks.single.inlines
        .where((inline) => inline.kind == BusyInlineKind.link)
        .toList(growable: false);
    expect(links.map((inline) => inline.destination), [
      'https://destination.test',
      'https://incoming.test',
      'https://destination.test',
      'https://second.test',
      'https://destination.test',
    ]);
    expect(
      links
          .expand((link) => link.children)
          .where((inline) => inline.kind == BusyInlineKind.hardBreak),
      hasLength(2),
    );

    await _pressControlKey(tester, LogicalKeyboardKey.keyZ);
    await tester.pump();
    expect(controller.text, firstPaste);
    expect(controller.selection.baseOffset, secondInsertion);
    await _pressControlKey(tester, LogicalKeyboardKey.keyZ);
    await tester.pump();
    expect(controller.text, source);
    await _pressControlKey(tester, LogicalKeyboardKey.keyZ, shift: true);
    await tester.pump();
    expect(controller.text, firstPaste);
    expect(controller.selection.baseOffset, secondInsertion);
    await _pressControlKey(tester, LogicalKeyboardKey.keyZ, shift: true);
    await tester.pump();
    expect(controller.text, secondPaste);
    expect(controller.selection.baseOffset, secondCaret);
  });

  testWidgets('Source remaps reopened grouped breaks in a CRLF container', (
    tester,
  ) async {
    const source =
        '> [A\r\n'
        '> <br>\r\n'
        '> <br>\r\n'
        '> right](https://destination.test) tail';
    TextEditingValue? undoValue;
    final controller = await _pumpClipboardSourceEditor(
      tester,
      source: source,
      clipboard: _SourceTestClipboard(
        readData: RichClipboardData(
          text: 'Y',
          richFragment: _completeSourceFragment(
            '[Y](https://second.test)\n',
          ).encode(),
        ),
      ),
      onTransactionalChanged: (_, _, previousSelection, _, _) {
        undoValue = TextEditingValue(
          text: source,
          selection: previousSelection,
        );
      },
      onUndo: () {
        final value = undoValue;
        undoValue = null;
        return value;
      },
    );
    controller.selection = TextSelection.collapsed(
      offset: source.indexOf('right') + 'ri'.length,
    );

    await _pressControlKey(tester, LogicalKeyboardKey.keyV);
    await tester.pump();

    const expected =
        '> [A\r\n'
        '> <br>\r\n'
        '> <br>\r\n'
        '> ri](https://destination.test)'
        '[Y](https://second.test)'
        '[ght](https://destination.test) tail';
    expect(controller.text, expected);
    final caret =
        expected.indexOf('[Y](https://second.test)') +
        '[Y](https://second.test)'.length;
    expect(controller.selection.baseOffset, caret);
    final parsed = const MarkdownParser()
        .parse(
          filePath: '/project/source.md',
          source: controller.text,
          validateLocalReferences: false,
        )
        .busyDocument;
    final links = _sourceBlocksDepthFirst(parsed.blocks)
        .expand((block) => block.inlines)
        .where((inline) => inline.kind == BusyInlineKind.link)
        .toList(growable: false);
    expect(links.map((inline) => inline.destination), [
      'https://destination.test',
      'https://second.test',
      'https://destination.test',
    ]);
    expect(
      links
          .expand((link) => link.children)
          .where((inline) => inline.kind == BusyInlineKind.hardBreak),
      hasLength(2),
    );

    await _pressControlKey(tester, LogicalKeyboardKey.keyZ);
    await tester.pump();
    expect(controller.text, source);
  });

  testWidgets(
    'Source maps nested and reference links through container prefixes',
    (tester) async {
      final cases =
          <
            ({
              String source,
              MarkdownMode mode,
              List<BusyBlockKind> path,
              String continuationPrefix,
              String? definition,
            })
          >[
            (
              source:
                  '> > [left\n'
                  '> > right](https://destination.test)',
              mode: MarkdownMode.commonMark,
              path: const [
                BusyBlockKind.blockquote,
                BusyBlockKind.blockquote,
                BusyBlockKind.paragraph,
              ],
              continuationPrefix: '> > ',
              definition: null,
            ),
            (
              source:
                  '> [left\n'
                  'right](https://destination.test)',
              mode: MarkdownMode.commonMark,
              path: const [BusyBlockKind.blockquote, BusyBlockKind.paragraph],
              continuationPrefix: '',
              definition: null,
            ),
            (
              source:
                  '- [left\n'
                  '  right][dest]\n'
                  '\n'
                  '[dest]: https://destination.test\n',
              mode: MarkdownMode.commonMark,
              path: const [BusyBlockKind.unorderedListItem],
              continuationPrefix: '  ',
              definition: '[dest]: https://destination.test\n',
            ),
          ];
      for (final (index, value) in cases.indexed) {
        var transactions = 0;
        TextEditingValue? undoValue;
        final controller = await _pumpClipboardSourceEditor(
          tester,
          source: value.source,
          markdownMode: value.mode,
          clipboard: _SourceTestClipboard(
            readData: RichClipboardData(
              text: 'X',
              richFragment: _completeSourceFragment(
                '[X](https://incoming.test)\n',
                mode: value.mode,
              ).encode(),
            ),
          ),
          onTransactionalChanged: (_, _, previousSelection, _, _) {
            transactions += 1;
            undoValue = TextEditingValue(
              text: value.source,
              selection: previousSelection,
            );
          },
          onUndo: () {
            final result = undoValue;
            undoValue = null;
            return result;
          },
        );
        controller.selection = TextSelection.collapsed(
          offset: value.source.indexOf('left') + 'left'.length,
        );

        await _pressControlKey(tester, LogicalKeyboardKey.keyV);
        await tester.pump();

        final document = const MarkdownParser()
            .parse(
              filePath: '/project/source.md',
              source: controller.text,
              mode: value.mode,
              validateLocalReferences: false,
            )
            .busyDocument;
        final paragraph = _sourceBlocksDepthFirst(document.blocks).firstWhere(
          (block) =>
              block.inlines
                  .where((inline) => inline.kind == BusyInlineKind.link)
                  .length ==
              3,
        );
        final links = paragraph.inlines
            .where((inline) => inline.kind == BusyInlineKind.link)
            .toList();
        expect(links.map((inline) => inline.destination), [
          'https://destination.test',
          'https://incoming.test',
          'https://destination.test',
        ], reason: controller.text);
        expect(links[0].plainText, 'left');
        expect(links[1].plainText, 'X');
        expect(links[2].plainText, '\nright');
        expect(paragraph.plainText, isNot(contains('>')));
        expect(
          controller.text.split('\n')[1],
          startsWith('${value.continuationPrefix}right'),
          reason: controller.text,
        );
        final paths = _busyBlockKindPaths(document.blocks, paragraph.kind);
        expect(paths, contains(equals(value.path)), reason: controller.text);
        if (value.definition case final definition?) {
          expect(
            RegExp(RegExp.escape(definition)).allMatches(controller.text),
            hasLength(1),
          );
        }
        final incomingEnd =
            controller.text.indexOf('[X](https://incoming.test)') +
            '[X](https://incoming.test)'.length;
        expect(controller.selection.baseOffset, incomingEnd);
        expect(transactions, 1);

        await _pressControlKey(tester, LogicalKeyboardKey.keyZ);
        await tester.pump();
        expect(controller.text, value.source);

        if (index + 1 < cases.length) {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        }
      }
    },
  );

  testWidgets('Source paste preserves autolink destination semantics', (
    tester,
  ) async {
    const originalDestination = 'https://example.test/leftright';
    const incomingDestination = 'https://incoming.test';
    for (final (index, value)
        in <({String source, bool table, int length, String incoming})>[
          (
            source: 'Before <$originalDestination> after',
            table: false,
            length: 0,
            incoming: incomingDestination,
          ),
          (
            source: 'Before <$originalDestination> after',
            table: false,
            length: 'left'.length,
            incoming: incomingDestination,
          ),
          (
            source: '| H |\n| --- |\n| <$originalDestination> |\n',
            table: true,
            length: 0,
            incoming: incomingDestination,
          ),
          (
            source: 'Before <$originalDestination> after',
            table: false,
            length: 0,
            incoming: originalDestination,
          ),
        ].indexed) {
      final source = value.source;
      TextEditingValue? undoValue;
      final controller = await _pumpClipboardSourceEditor(
        tester,
        source: source,
        markdownMode: value.table ? MarkdownMode.gfm : MarkdownMode.commonMark,
        clipboard: _SourceTestClipboard(
          readData: RichClipboardData(
            text: 'X',
            richFragment: _completeSourceFragment(
              '[X](${value.incoming})\n',
              mode: value.table ? MarkdownMode.gfm : MarkdownMode.commonMark,
            ).encode(),
          ),
        ),
        onTransactionalChanged: (_, _, previousSelection, _, _) {
          undoValue = TextEditingValue(
            text: source,
            selection: previousSelection,
          );
        },
        onUndo: () {
          final result = undoValue;
          undoValue = null;
          return result;
        },
      );
      final selectionStart =
          source.indexOf('left') + (value.length == 0 ? 'left'.length : 0);
      controller.selection = TextSelection(
        baseOffset: selectionStart,
        extentOffset: selectionStart + value.length,
      );

      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();

      final document = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: controller.text,
            mode: value.table ? MarkdownMode.gfm : MarkdownMode.commonMark,
            validateLocalReferences: false,
          )
          .busyDocument;
      final links = _sourceBlocksDepthFirst(document.blocks)
          .expand((block) => block.inlines)
          .where((inline) => inline.kind == BusyInlineKind.link)
          .toList();
      expect(
        links.map((inline) => inline.destination),
        value.incoming == originalDestination
            ? [originalDestination]
            : [originalDestination, value.incoming, originalDestination],
        reason: controller.text,
      );
      expect(
        links.map((inline) => inline.plainText).join(),
        value.length == 0
            ? originalDestination.replaceFirst('right', 'Xright')
            : originalDestination.replaceFirst('left', 'X'),
      );
      expect(
        links.every((link) => link.attributes['href'] == link.destination),
        isTrue,
      );
      expect(controller.text, isNot(contains('%EE%80%80')));
      expect(controller.text, isNot(contains('\ue000')));

      await _pressControlKey(tester, LogicalKeyboardKey.keyZ);
      await tester.pump();
      expect(controller.text, source);
      if (index < 3) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    }
  });

  testWidgets(
    'invalid email-like text does not invalidate another link target',
    (tester) async {
      const target = '<https://example.test/leftright>';
      for (final (index, source) in const [
        'Before <x@-y> and $target after',
        'Before $target and <x@-y> after',
        '| H |\n| --- |\n| Before <x@-y> and $target after |\n',
        'Before $target and $target after',
      ].indexed) {
        var transactions = 0;
        TextEditingValue? undoValue;
        final controller = await _pumpClipboardSourceEditor(
          tester,
          source: source,
          markdownMode: index == 2 ? MarkdownMode.gfm : MarkdownMode.commonMark,
          clipboard: _SourceTestClipboard(
            readData: RichClipboardData(
              text: 'X',
              richFragment: _completeSourceFragment(
                '[X](https://incoming.test)\n',
                mode: index == 2 ? MarkdownMode.gfm : MarkdownMode.commonMark,
              ).encode(),
            ),
          ),
          onTransactionalChanged: (_, _, previousSelection, _, _) {
            transactions += 1;
            undoValue = TextEditingValue(
              text: source,
              selection: previousSelection,
            );
          },
          onUndo: () {
            final result = undoValue;
            undoValue = null;
            return result;
          },
        );
        final selectedTarget = source.indexOf(target);
        controller.selection = TextSelection.collapsed(
          offset: selectedTarget + target.indexOf('leftright') + 4,
        );

        await _pressControlKey(tester, LogicalKeyboardKey.keyV);
        await tester.pump();

        const replacement =
            '[https://example.test/left](https://example.test/leftright)'
            '[X](https://incoming.test)'
            '[right](https://example.test/leftright)';
        final expected = source.replaceRange(
          selectedTarget,
          selectedTarget + target.length,
          replacement,
        );
        expect(controller.text, expected);
        if (source.contains('<x@-y>')) {
          expect(controller.text, contains('<x@-y>'), reason: source);
        }
        expect(controller.text, isNot(contains('\ue000')));
        final parsed = const MarkdownParser()
            .parse(
              filePath: '/project/source.md',
              source: controller.text,
              mode: index == 2 ? MarkdownMode.gfm : MarkdownMode.commonMark,
              validateLocalReferences: false,
            )
            .busyDocument;
        final links = _sourceBlocksDepthFirst(parsed.blocks)
            .expand((block) => block.inlines)
            .where((inline) => inline.kind == BusyInlineKind.link)
            .toList();
        expect(links.take(3).map((inline) => inline.destination), [
          'https://example.test/leftright',
          'https://incoming.test',
          'https://example.test/leftright',
        ], reason: controller.text);
        expect(
          links
              .take(3)
              .every((link) => link.attributes['href'] == link.destination),
          isTrue,
        );
        final incomingEnd =
            controller.text.indexOf('[X](https://incoming.test)') +
            '[X](https://incoming.test)'.length;
        expect(controller.selection.baseOffset, incomingEnd);
        expect(transactions, 1);

        await _pressControlKey(tester, LogicalKeyboardKey.keyZ);
        await tester.pump();
        expect(controller.text, source);
        if (index + 1 < 4) {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        }
      }
    },
  );

  testWidgets('Source paste distinguishes authored and generated URL content', (
    tester,
  ) async {
    final cases = <({String source, String needle})>[
      (
        source: '<https://example.test/a%20b-\ue000-%EE%80%80-leftright>',
        needle: 'right',
      ),
      (source: '<left@example.test>', needle: '@'),
    ];
    for (final (index, value) in cases.indexed) {
      final original = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: value.source,
            validateLocalReferences: false,
          )
          .busyDocument
          .blocks
          .single
          .inlines
          .single;
      expect(original.kind, BusyInlineKind.link);
      final controller = await _pumpClipboardSourceEditor(
        tester,
        source: value.source,
        clipboard: _SourceTestClipboard(
          readData: RichClipboardData(
            text: 'X',
            richFragment: _completeSourceFragment(
              '[X](https://incoming.test)\n',
            ).encode(),
          ),
        ),
      );
      controller.selection = TextSelection.collapsed(
        offset: value.source.indexOf(value.needle),
      );

      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();

      final parsed = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: controller.text,
            validateLocalReferences: false,
          )
          .busyDocument;
      final links = parsed.blocks.single.inlines
          .where((inline) => inline.kind == BusyInlineKind.link)
          .toList();
      expect(links.map((inline) => inline.destination), [
        original.destination,
        'https://incoming.test',
        original.destination,
      ], reason: controller.text);
      if (value.source.contains('\ue000')) {
        expect(controller.text, contains('\ue000'));
        expect(controller.text, contains('%EE%80%80'));
        expect(controller.text, isNot(contains('\ue001')));
        expect(controller.text, isNot(contains('%EE%81%81')));
      }
      if (index == 0) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    }
  });

  testWidgets('Source paste preserves parser-folded reference identity', (
    tester,
  ) async {
    const definition = '[STRASSE]: https://destination.test';
    for (final (index, value) in <({String link, String needle})>[
      (link: '[STRA\u1e9eE][]', needle: 'STRA'),
      (link: '[STRA\u1e9eE]', needle: 'STRA'),
      (link: '[leftright][STRA\u1e9eE]', needle: 'left'),
    ].indexed) {
      final source = '${value.link}\n\n$definition\n';
      final before = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: source,
            validateLocalReferences: false,
          )
          .busyDocument;
      expect(
        before.blocks.first.inlines.single.destination,
        'https://destination.test',
      );
      TextEditingValue? undoValue;
      final controller = await _pumpClipboardSourceEditor(
        tester,
        source: source,
        clipboard: _SourceTestClipboard(
          readData: RichClipboardData(
            text: 'X',
            richFragment: _completeSourceFragment(
              '[X](https://incoming.test)\n',
            ).encode(),
          ),
        ),
        onTransactionalChanged: (_, _, previousSelection, _, _) {
          undoValue = TextEditingValue(
            text: source,
            selection: previousSelection,
          );
        },
        onUndo: () {
          final result = undoValue;
          undoValue = null;
          return result;
        },
      );
      controller.selection = TextSelection.collapsed(
        offset: source.indexOf(value.needle) + 4,
      );

      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();

      final after = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: controller.text,
            validateLocalReferences: false,
          )
          .busyDocument;
      final links = after.blocks.first.inlines
          .where((inline) => inline.kind == BusyInlineKind.link)
          .toList();
      expect(links.map((inline) => inline.destination), [
        'https://destination.test',
        'https://incoming.test',
        'https://destination.test',
      ], reason: controller.text);
      expect(
        RegExp(RegExp.escape('$definition\n')).allMatches(controller.text),
        hasLength(1),
      );
      expect(controller.text, isNot(contains('\ue000')));

      await _pressControlKey(tester, LogicalKeyboardKey.keyZ);
      await tester.pump();
      expect(controller.text, source);
      if (index < 2) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    }
  });

  testWidgets(
    'Source same-destination paste preserves parser-folded reference identity',
    (tester) async {
      const definition = '[STRASSE]: https://destination.test';
      const source = '[STRA\u1e9eE][]\n\n$definition\n';
      TextEditingValue? undoValue;
      final controller = await _pumpClipboardSourceEditor(
        tester,
        source: source,
        clipboard: _SourceTestClipboard(
          readData: RichClipboardData(
            text: 'X',
            richFragment: _completeSourceFragment(
              '[X](https://destination.test)\n',
            ).encode(),
          ),
        ),
        onTransactionalChanged: (_, _, previousSelection, _, _) {
          undoValue = TextEditingValue(
            text: source,
            selection: previousSelection,
          );
        },
        onUndo: () {
          final result = undoValue;
          undoValue = null;
          return result;
        },
      );
      controller.selection = const TextSelection.collapsed(offset: 5);

      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();

      final parsed = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: controller.text,
            validateLocalReferences: false,
          )
          .busyDocument;
      final links = parsed.blocks.first.inlines
          .where((inline) => inline.kind == BusyInlineKind.link)
          .toList();
      expect(links, isNotEmpty, reason: controller.text);
      expect(
        links.map((inline) => inline.destination),
        everyElement('https://destination.test'),
      );
      expect(links.map((inline) => inline.plainText).join(), 'STRAX\u1e9eE');
      expect(controller.text, endsWith('\n\n$definition\n'));
      expect(controller.text, isNot(contains('\ue000')));

      await _pressControlKey(tester, LogicalKeyboardKey.keyZ);
      await tester.pump();
      expect(controller.text, source);
    },
  );

  testWidgets('Source paste retains the provenance of surviving line breaks', (
    tester,
  ) async {
    const source =
        '> [left\n'
        '> middle\r\n'
        '> right](https://destination.test)';
    TextEditingValue? undoValue;
    final controller = await _pumpClipboardSourceEditor(
      tester,
      source: source,
      clipboard: _SourceTestClipboard(
        readData: RichClipboardData(
          text: 'X',
          richFragment: _completeSourceFragment(
            '[X](https://incoming.test)\n',
          ).encode(),
        ),
      ),
      onTransactionalChanged: (_, _, previousSelection, _, _) {
        undoValue = TextEditingValue(
          text: source,
          selection: previousSelection,
        );
      },
      onUndo: () {
        final result = undoValue;
        undoValue = null;
        return result;
      },
    );
    controller.selection = TextSelection(
      baseOffset: source.indexOf('left') + 'left'.length,
      extentOffset: source.indexOf('middle') + 'middle'.length,
    );

    await _pressControlKey(tester, LogicalKeyboardKey.keyV);
    await tester.pump();

    expect(
      controller.text,
      '> [left](https://destination.test)'
      '[X](https://incoming.test)'
      '[\r\n> right](https://destination.test)',
    );
    final incomingEnd =
        controller.text.indexOf('[X](https://incoming.test)') +
        '[X](https://incoming.test)'.length;
    expect(controller.selection.baseOffset, incomingEnd);

    await _pressControlKey(tester, LogicalKeyboardKey.keyZ);
    await tester.pump();
    expect(controller.text, source);
  });

  testWidgets(
    'Source paste keeps label break provenance independent of link titles',
    (tester) async {
      const source =
          '> [left\n'
          '> middle\r\n'
          '> right](https://destination.test "first\n'
          '> second")';
      var transactions = 0;
      TextEditingValue? undoValue;
      final controller = await _pumpClipboardSourceEditor(
        tester,
        source: source,
        clipboard: _SourceTestClipboard(
          readData: RichClipboardData(
            text: 'X',
            richFragment: _completeSourceFragment(
              '[X](https://incoming.test)\n',
            ).encode(),
          ),
        ),
        onTransactionalChanged: (_, _, previousSelection, _, _) {
          transactions += 1;
          undoValue = TextEditingValue(
            text: source,
            selection: previousSelection,
          );
        },
        onUndo: () {
          final result = undoValue;
          undoValue = null;
          return result;
        },
      );
      controller.selection = TextSelection(
        baseOffset: source.indexOf('left') + 'left'.length,
        extentOffset: source.indexOf('middle') + 'middle'.length,
      );

      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();

      expect(
        controller.text,
        '> [left](https://destination.test "first&#10;second")'
        '[X](https://incoming.test)'
        '[\r\n> right](https://destination.test "first&#10;second")',
      );
      final parsed = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: controller.text,
            validateLocalReferences: false,
          )
          .busyDocument;
      final paragraph = _sourceBlocksDepthFirst(
        parsed.blocks,
      ).firstWhere((block) => block.kind == BusyBlockKind.paragraph);
      final links = paragraph.inlines
          .where((inline) => inline.kind == BusyInlineKind.link)
          .toList();
      expect(links.map((inline) => inline.destination), [
        'https://destination.test',
        'https://incoming.test',
        'https://destination.test',
      ]);
      expect(links.first.attributes['title'], 'first\nsecond');
      expect(links.last.attributes['title'], 'first\nsecond');
      expect(links.last.plainText, '\nright');
      expect(parsed.blocks.first.kind, BusyBlockKind.blockquote);
      final incomingEnd =
          controller.text.indexOf('[X](https://incoming.test)') +
          '[X](https://incoming.test)'.length;
      expect(controller.selection.baseOffset, incomingEnd);
      expect(transactions, 1);

      await _pressControlKey(tester, LogicalKeyboardKey.keyZ);
      await tester.pump();
      expect(controller.text, source);
    },
  );

  testWidgets(
    'normalized code-span breaks do not shift surviving link provenance',
    (tester) async {
      const source =
          '> [left `code\n'
          '> span` middle\r\n'
          '> right](https://destination.test)';
      var transactions = 0;
      TextEditingValue? undoValue;
      final controller = await _pumpClipboardSourceEditor(
        tester,
        source: source,
        clipboard: _SourceTestClipboard(
          readData: RichClipboardData(
            text: 'X',
            richFragment: _completeSourceFragment(
              '[X](https://incoming.test)\n',
            ).encode(),
          ),
        ),
        onTransactionalChanged: (_, _, previousSelection, _, _) {
          transactions += 1;
          undoValue = TextEditingValue(
            text: source,
            selection: previousSelection,
          );
        },
        onUndo: () {
          final result = undoValue;
          undoValue = null;
          return result;
        },
      );
      controller.selection = TextSelection(
        baseOffset: source.indexOf('left') + 'left'.length,
        extentOffset: source.indexOf('middle') + 'middle'.length,
      );

      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();

      expect(
        controller.text,
        '> [left](https://destination.test)'
        '[X](https://incoming.test)'
        '[\r\n> right](https://destination.test)',
      );
      final parsed = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: controller.text,
            validateLocalReferences: false,
          )
          .busyDocument;
      final paragraph = _sourceBlocksDepthFirst(
        parsed.blocks,
      ).firstWhere((block) => block.kind == BusyBlockKind.paragraph);
      final links = paragraph.inlines
          .where((inline) => inline.kind == BusyInlineKind.link)
          .toList();
      expect(links.map((inline) => inline.destination), [
        'https://destination.test',
        'https://incoming.test',
        'https://destination.test',
      ]);
      expect(links.last.plainText, '\nright');
      expect(parsed.blocks.first.kind, BusyBlockKind.blockquote);
      final incomingEnd =
          controller.text.indexOf('[X](https://incoming.test)') +
          '[X](https://incoming.test)'.length;
      expect(controller.selection.baseOffset, incomingEnd);
      expect(transactions, 1);

      await _pressControlKey(tester, LogicalKeyboardKey.keyZ);
      await tester.pump();
      expect(controller.text, source);
    },
  );

  testWidgets(
    'Source paste combines folded references with surviving break provenance',
    (tester) async {
      const source =
          '> [STRA\n'
          '> MIDDLE\r\n'
          '> \u1e9eE][]\n'
          '\n'
          '[STRA MIDDLE SSE]: https://destination.test\n';
      final original = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: source,
            validateLocalReferences: false,
          )
          .busyDocument;
      final originalLink = _sourceBlocksDepthFirst(original.blocks)
          .expand((block) => block.inlines)
          .singleWhere((inline) => inline.kind == BusyInlineKind.link);
      expect(originalLink.destination, 'https://destination.test');
      TextEditingValue? undoValue;
      final controller = await _pumpClipboardSourceEditor(
        tester,
        source: source,
        clipboard: _SourceTestClipboard(
          readData: RichClipboardData(
            text: 'X',
            richFragment: _completeSourceFragment(
              '[X](https://incoming.test)\n',
            ).encode(),
          ),
        ),
        onTransactionalChanged: (_, _, previousSelection, _, _) {
          undoValue = TextEditingValue(
            text: source,
            selection: previousSelection,
          );
        },
        onUndo: () {
          final result = undoValue;
          undoValue = null;
          return result;
        },
      );
      controller.selection = TextSelection(
        baseOffset: source.indexOf('STRA') + 'STRA'.length,
        extentOffset: source.indexOf('MIDDLE') + 'MIDDLE'.length,
      );

      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();

      expect(
        controller.text,
        '> [STRA](https://destination.test)'
        '[X](https://incoming.test)'
        '[\r\n> \u1e9eE](https://destination.test)\n'
        '\n'
        '[STRA MIDDLE SSE]: https://destination.test\n',
      );
      final parsed = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: controller.text,
            validateLocalReferences: false,
          )
          .busyDocument;
      final links = _sourceBlocksDepthFirst(parsed.blocks)
          .expand((block) => block.inlines)
          .where((inline) => inline.kind == BusyInlineKind.link)
          .toList();
      expect(links.map((inline) => inline.destination), [
        'https://destination.test',
        'https://incoming.test',
        'https://destination.test',
      ]);
      expect(parsed.blocks.first.kind, BusyBlockKind.blockquote);

      await _pressControlKey(tester, LogicalKeyboardKey.keyZ);
      await tester.pump();
      expect(controller.text, source);
    },
  );

  testWidgets('Source paste tracks old and new breaks independently', (
    tester,
  ) async {
    final cases =
        <({String source, bool replace, String incoming, String expected})>[
          (
            source:
                '> [left\r\n'
                '> middle\n'
                '> right](https://destination.test)',
            replace: true,
            incoming: '[X](https://incoming.test)\n',
            expected:
                '> [left](https://destination.test)'
                '[X](https://incoming.test)'
                '[\n> right](https://destination.test)',
          ),
          (
            source:
                '> [left\n'
                '> middle\r\n'
                '> right](https://destination.test)',
            replace: false,
            incoming: '[X\nY](https://incoming.test)\n',
            expected:
                '> [left\n> middle](https://destination.test)'
                '[X\n> Y](https://incoming.test)'
                '[\r\n> right](https://destination.test)',
          ),
        ];
    for (final (index, value) in cases.indexed) {
      final source = value.source;
      final leftEnd = source.indexOf('left') + 'left'.length;
      final middleEnd = source.indexOf('middle') + 'middle'.length;
      final selection = value.replace
          ? TextSelection(baseOffset: leftEnd, extentOffset: middleEnd)
          : TextSelection.collapsed(offset: middleEnd);
      TextEditingValue? undoValue;
      final controller = await _pumpClipboardSourceEditor(
        tester,
        source: source,
        clipboard: _SourceTestClipboard(
          readData: RichClipboardData(
            text: value.incoming.startsWith('[X\n') ? 'X\nY' : 'X',
            richFragment: _completeSourceFragment(value.incoming).encode(),
          ),
        ),
        onTransactionalChanged: (_, _, previousSelection, _, _) {
          undoValue = TextEditingValue(
            text: source,
            selection: previousSelection,
          );
        },
        onUndo: () {
          final result = undoValue;
          undoValue = null;
          return result;
        },
      );
      controller.selection = selection;

      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();

      expect(controller.text, value.expected);
      final parsed = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: controller.text,
            validateLocalReferences: false,
          )
          .busyDocument;
      final links = _sourceBlocksDepthFirst(parsed.blocks)
          .expand((block) => block.inlines)
          .where((inline) => inline.kind == BusyInlineKind.link)
          .toList();
      expect(links.first.destination, 'https://destination.test');
      expect(links.last.destination, 'https://destination.test');
      expect(parsed.blocks.single.kind, BusyBlockKind.blockquote);

      await _pressControlKey(tester, LogicalKeyboardKey.keyZ);
      await tester.pump();
      expect(controller.text, source);
      if (index == 0) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    }
  });

  testWidgets('Source reference-link label replacement retains definitions', (
    tester,
  ) async {
    final cases = <({String link, String definition})>[
      (
        link: '[leftright][dest]',
        definition: '[dest]: https://destination.test',
      ),
      (
        link: '[leftright][]',
        definition: '[leftright]: https://destination.test',
      ),
      (
        link: '[leftright]',
        definition: '[leftright]: https://destination.test',
      ),
    ];
    for (final (index, value) in cases.indexed) {
      final source = '${value.link}\n\n${value.definition}\n';
      final controller = await _pumpClipboardSourceEditor(
        tester,
        source: source,
        clipboard: _SourceTestClipboard(
          readData: RichClipboardData(
            text: 'X',
            richFragment: _completeSourceFragment(
              '[X](https://incoming.test)\n',
            ).encode(),
          ),
        ),
      );
      final labelStart = source.indexOf('leftright');
      controller.selection = TextSelection(
        baseOffset: labelStart,
        extentOffset: labelStart + 'leftright'.length,
      );

      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();

      expect(
        controller.text,
        '[X](https://incoming.test)\n\n${value.definition}\n',
        reason: value.link,
      );
      expect(
        controller.selection.baseOffset,
        '[X](https://incoming.test)'.length,
      );
      if (index + 1 < cases.length) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    }
  });

  testWidgets(
    'Source maps escaped brackets in collapsed and shortcut references',
    (tester) async {
      final cases = <({String link, String definition})>[
        (
          link: r'[prefix \[ leftright][]',
          definition: r'[prefix \[ leftright]: https://destination.test',
        ),
        (
          link: r'[prefix \[ leftright]',
          definition: r'[prefix \[ leftright]: https://destination.test',
        ),
      ];
      for (final (caseIndex, value) in cases.indexed) {
        for (final selectionLength in [0, 'left'.length]) {
          final source = '${value.link}\n\n${value.definition}\n';
          var transactions = 0;
          TextEditingValue? undoValue;
          final controller = await _pumpClipboardSourceEditor(
            tester,
            source: source,
            clipboard: _SourceTestClipboard(
              readData: RichClipboardData(
                text: 'X',
                richFragment: _completeSourceFragment(
                  '[X](https://incoming.test)\n',
                ).encode(),
              ),
            ),
            onTransactionalChanged: (_, _, previousSelection, _, _) {
              transactions += 1;
              undoValue = TextEditingValue(
                text: source,
                selection: previousSelection,
              );
            },
            onUndo: () {
              final value = undoValue;
              undoValue = null;
              return value;
            },
          );
          final selectionStart = source.indexOf('left');
          controller.selection = TextSelection(
            baseOffset: selectionStart,
            extentOffset: selectionStart + selectionLength,
          );

          await _pressControlKey(tester, LogicalKeyboardKey.keyV);
          await tester.pump();

          final parsed = const MarkdownParser()
              .parse(
                filePath: '/project/source.md',
                source: controller.text,
                validateLocalReferences: false,
              )
              .busyDocument;
          final links = parsed.blocks.first.inlines
              .where((inline) => inline.kind == BusyInlineKind.link)
              .toList();
          expect(
            links.map((inline) => inline.destination),
            [
              'https://destination.test',
              'https://incoming.test',
              'https://destination.test',
            ],
            reason:
                '${value.link}; selection $selectionLength; '
                '${controller.text}',
          );
          expect(links[0].plainText, r'prefix [ ');
          expect(links[1].plainText, 'X');
          expect(
            links[2].plainText,
            selectionLength == 0 ? 'leftright' : 'right',
          );
          expect(
            RegExp(
              RegExp.escape('${value.definition}\n'),
            ).allMatches(controller.text),
            hasLength(1),
          );
          final incomingEnd =
              controller.text.indexOf('[X](https://incoming.test)') +
              '[X](https://incoming.test)'.length;
          expect(controller.selection.baseOffset, incomingEnd);
          expect(transactions, 1);

          await _pressControlKey(tester, LogicalKeyboardKey.keyZ);
          await tester.pump();
          expect(controller.text, source);

          if (caseIndex != cases.length - 1 || selectionLength != 4) {
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump();
          }
        }
      }
    },
  );

  testWidgets('Source maps links around unmatched and code-span backticks', (
    tester,
  ) async {
    final cases =
        <
          ({
            String link,
            String caretNeedle,
            String expectedPlainText,
            String expectedLeftLabel,
            bool hasCode,
          })
        >[
          (
            link: r'literal ` then [leftright](https://destination.test)',
            caretNeedle: 'right',
            expectedPlainText: r'literal ` then leftXright',
            expectedLeftLabel: 'left',
            hasCode: false,
          ),
          (
            link: r'[left`right](https://destination.test)',
            caretNeedle: 'right',
            expectedPlainText: r'left`Xright',
            expectedLeftLabel: r'left`',
            hasCode: false,
          ),
          (
            link: r'[left `code\` right](https://destination.test)',
            caretNeedle: 'right',
            expectedPlainText: r'left code\ Xright',
            expectedLeftLabel: r'left code\ ',
            hasCode: true,
          ),
        ];
    for (final (caseIndex, value) in cases.indexed) {
      for (final inTable in [false, true]) {
        final source = inTable
            ? '| H |\n| --- |\n| ${value.link} |\n'
            : value.link;
        var transactions = 0;
        TextEditingValue? undoValue;
        final controller = await _pumpClipboardSourceEditor(
          tester,
          source: source,
          markdownMode: inTable ? MarkdownMode.gfm : MarkdownMode.commonMark,
          clipboard: _SourceTestClipboard(
            readData: RichClipboardData(
              text: 'X',
              richFragment: _completeSourceFragment(
                '[X](https://incoming.test)\n',
                mode: inTable ? MarkdownMode.gfm : MarkdownMode.commonMark,
              ).encode(),
            ),
          ),
          onTransactionalChanged: (_, _, previousSelection, _, _) {
            transactions += 1;
            undoValue = TextEditingValue(
              text: source,
              selection: previousSelection,
            );
          },
          onUndo: () {
            final value = undoValue;
            undoValue = null;
            return value;
          },
        );
        controller.selection = TextSelection.collapsed(
          offset: source.indexOf(value.caretNeedle),
        );

        await _pressControlKey(tester, LogicalKeyboardKey.keyV);
        await tester.pump();

        final parsed = const MarkdownParser()
            .parse(
              filePath: '/project/source.md',
              source: controller.text,
              mode: inTable ? MarkdownMode.gfm : MarkdownMode.commonMark,
              validateLocalReferences: false,
            )
            .busyDocument;
        final inlines = inTable
            ? parsed.blocks.single.children.last.children.single.inlines
            : parsed.blocks.single.inlines;
        final links = inlines
            .where((inline) => inline.kind == BusyInlineKind.link)
            .toList();
        expect(links.map((inline) => inline.destination), [
          'https://destination.test',
          'https://incoming.test',
          'https://destination.test',
        ], reason: controller.text);
        expect(
          inlines.map((inline) => inline.plainText).join(),
          value.expectedPlainText,
        );
        expect(links[0].plainText, value.expectedLeftLabel);
        expect(links[1].plainText, 'X');
        expect(links[2].plainText, 'right');
        if (value.hasCode) {
          expect(
            links[0].children
                .where((inline) => inline.kind == BusyInlineKind.code)
                .single
                .text,
            r'code\',
          );
        }
        final incomingEnd =
            controller.text.indexOf('[X](https://incoming.test)') +
            '[X](https://incoming.test)'.length;
        expect(controller.selection.baseOffset, incomingEnd);
        expect(transactions, 1);

        await _pressControlKey(tester, LogicalKeyboardKey.keyZ);
        await tester.pump();
        expect(controller.text, source);

        if (caseIndex != cases.length - 1 || !inTable) {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        }
      }
    }
  });

  testWidgets('Source maps links with escaped and balanced label brackets', (
    tester,
  ) async {
    final measurements = <int>[];
    debugBusyMarkSourceInlineMappingParseCount = measurements.add;
    addTearDown(() => debugBusyMarkSourceInlineMappingParseCount = null);
    final escapedBrackets = List.filled(20, r'\[').join();
    final literalBrackets = List.filled(20, '[').join();
    final cases = [
      (
        source:
            '[$escapedBrackets'
            'leftright](https://destination.test)',
        startText: 'leftright',
        selectionLength: 0,
        expectedBefore: '${literalBrackets}left',
        expectedAfter: 'right',
      ),
      (
        source: '[prefix [balanced] leftright](https://destination.test)',
        startText: 'left',
        selectionLength: 'left'.length,
        expectedBefore: 'prefix [balanced] ',
        expectedAfter: 'right',
      ),
    ];
    for (final (index, value) in cases.indexed) {
      final registry = BusyMarkClipboardInsertionRegistry();
      final fragment = _completeSourceFragment('[X](https://incoming.test)\n');
      final controller = await _pumpClipboardSourceEditor(
        tester,
        source: value.source,
        registry: registry,
        clipboard: _SourceTestClipboard(
          readData: RichClipboardData(
            text: 'X',
            richFragment: fragment.encode(),
          ),
        ),
      );
      final selectionStart =
          value.source.indexOf(value.startText) +
          (value.selectionLength == 0 ? 4 : 0);
      controller.selection = TextSelection(
        baseOffset: selectionStart,
        extentOffset: selectionStart + value.selectionLength,
      );
      final payload = BusyMarkClipboardPayload(
        id: 'bracket-link-$index',
        acquiredAt: DateTime.utc(2026),
        kind: BusyMarkClipboardContentKind.richText,
        text: 'X',
        richFragment: fragment.encode(),
      );

      measurements.clear();
      expect(registry.canPaste(payload), isTrue);
      expect(measurements, isNotEmpty);

      measurements.clear();
      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();

      final parsed = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: controller.text,
            validateLocalReferences: false,
          )
          .busyDocument;
      final links = parsed.blocks.single.inlines
          .where((inline) => inline.kind == BusyInlineKind.link)
          .toList();
      expect(links.map((inline) => inline.destination), [
        'https://destination.test',
        'https://incoming.test',
        'https://destination.test',
      ], reason: controller.text);
      expect(links[0].plainText, value.expectedBefore);
      expect(links[1].plainText, 'X');
      expect(links[2].plainText, value.expectedAfter);
      final incomingEnd =
          controller.text.indexOf('[X](https://incoming.test)') +
          '[X](https://incoming.test)'.length;
      expect(controller.selection.baseOffset, incomingEnd);
      expect(measurements, isNotEmpty);
      expect(measurements.reduce(math.max), lessThanOrEqualTo(4));
      registry.dispose();
      if (index + 1 < cases.length) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    }
  });

  testWidgets(
    'Source inline wrapper mapping stays bounded for paste and availability',
    (tester) async {
      final measurements = <int>[];
      debugBusyMarkSourceInlineMappingParseCount = measurements.add;
      addTearDown(() => debugBusyMarkSourceInlineMappingParseCount = null);
      final fragment = _completeSourceFragment('**X**\n');
      for (final (index, spanCount) in [10, 60].indexed) {
        final source = [
          for (var span = 0; span < spanCount; span++) '**value$span**',
        ].join(' gap ');
        final registry = BusyMarkClipboardInsertionRegistry();
        final controller = await _pumpClipboardSourceEditor(
          tester,
          source: source,
          registry: registry,
          clipboard: _SourceTestClipboard(
            readData: RichClipboardData(
              text: 'X',
              richFragment: fragment.encode(),
            ),
          ),
        );
        controller.selection = TextSelection.collapsed(
          offset: source.indexOf('value${spanCount ~/ 2}') + 3,
        );
        final payload = BusyMarkClipboardPayload(
          id: 'mapping-$spanCount',
          acquiredAt: DateTime.utc(2026),
          kind: BusyMarkClipboardContentKind.richText,
          text: 'X',
          richFragment: fragment.encode(),
        );

        measurements.clear();
        expect(registry.canPaste(payload), isTrue);
        expect(measurements, isNotEmpty);
        expect(measurements.reduce(math.max), lessThanOrEqualTo(4));

        measurements.clear();
        await _pressControlKey(tester, LogicalKeyboardKey.keyV);
        await tester.pump();
        expect(measurements, isNotEmpty);
        expect(measurements.reduce(math.max), lessThanOrEqualTo(4));
        expect(controller.text, contains('valXue${spanCount ~/ 2}'));
        registry.dispose();
        if (index + 1 < 2) {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        }
      }

      final surroundingDocument = [
        for (var paragraph = 0; paragraph < 80; paragraph++)
          'Paragraph $paragraph has **bold text** and '
              '[a link](https://example.test/$paragraph).',
      ].join('\n\n');
      final largeSource =
          '$surroundingDocument\n\n'
          'Target **leftright** paragraph.\n\n'
          '$surroundingDocument\n';
      final registry = BusyMarkClipboardInsertionRegistry();
      final controller = await _pumpClipboardSourceEditor(
        tester,
        source: largeSource,
        registry: registry,
        clipboard: _SourceTestClipboard(
          readData: RichClipboardData(
            text: 'X',
            richFragment: fragment.encode(),
          ),
        ),
      );
      controller.selection = TextSelection.collapsed(
        offset: largeSource.indexOf('leftright') + 4,
      );
      final payload = BusyMarkClipboardPayload(
        id: 'mapping-large-document',
        acquiredAt: DateTime.utc(2026),
        kind: BusyMarkClipboardContentKind.richText,
        text: 'X',
        richFragment: fragment.encode(),
      );

      measurements.clear();
      expect(registry.canPaste(payload), isTrue);
      expect(measurements, isNotEmpty);
      expect(measurements.reduce(math.max), lessThanOrEqualTo(4));

      measurements.clear();
      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();
      expect(measurements, isNotEmpty);
      expect(measurements.reduce(math.max), lessThanOrEqualTo(4));
      expect(controller.text, contains('Target **leftXright** paragraph.'));
      registry.dispose();

      for (final codeSpanCount in [10, 20, 30]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        final codeSpans = List.filled(codeSpanCount, '`**`').join(' ');
        final source = '**start $codeSpans leftright $codeSpans end**';
        final registry = BusyMarkClipboardInsertionRegistry();
        final controller = await _pumpClipboardSourceEditor(
          tester,
          source: source,
          registry: registry,
          clipboard: _SourceTestClipboard(
            readData: RichClipboardData(
              text: 'X',
              richFragment: fragment.encode(),
            ),
          ),
        );
        controller.selection = TextSelection.collapsed(
          offset: source.indexOf('leftright') + 4,
        );
        final payload = BusyMarkClipboardPayload(
          id: 'mapping-code-spans-$codeSpanCount',
          acquiredAt: DateTime.utc(2026),
          kind: BusyMarkClipboardContentKind.richText,
          text: 'X',
          richFragment: fragment.encode(),
        );

        measurements.clear();
        expect(registry.canPaste(payload), isTrue);
        expect(measurements, isNotEmpty);
        expect(
          measurements.reduce(math.max),
          lessThanOrEqualTo(4),
          reason: 'availability with $codeSpanCount code spans per side',
        );

        measurements.clear();
        await _pressControlKey(tester, LogicalKeyboardKey.keyV);
        await tester.pump();
        expect(measurements, isNotEmpty);
        expect(
          measurements.reduce(math.max),
          lessThanOrEqualTo(4),
          reason: 'paste with $codeSpanCount code spans per side',
        );
        expect(controller.text, source.replaceFirst('leftright', 'leftXright'));
        final parsed = const MarkdownParser()
            .parse(
              filePath: '/project/source.md',
              source: controller.text,
              validateLocalReferences: false,
            )
            .busyDocument;
        expect(parsed.blocks.single.inlines.single.kind, BusyInlineKind.strong);
        expect(
          parsed.blocks.single.inlines.single.children.where(
            (inline) => inline.kind == BusyInlineKind.code,
          ),
          hasLength(codeSpanCount * 2),
        );
        registry.dispose();
      }
    },
  );

  testWidgets(
    'Source maps all retained break offsets in one serialization traversal',
    (tester) async {
      final measurements = <int>[];
      final visitedNodes = <int>[];
      debugBusyMarkInlineSerializationTraversal = measurements.add;
      debugBusyMarkInlineSerializationVisitedNodes = visitedNodes.add;
      addTearDown(() {
        debugBusyMarkInlineSerializationTraversal = null;
        debugBusyMarkInlineSerializationVisitedNodes = null;
      });
      for (final (caseIndex, breakCount) in [10, 100, 1000].indexed) {
        const destination = 'https://destination.test';
        const incoming = '[X](https://incoming.test)';
        final label = StringBuffer('line0');
        final rawLabel = StringBuffer('line0');
        final surviving = StringBuffer();
        for (var line = 1; line <= breakCount; line++) {
          final ending = line.isEven ? '\n' : '\r\n';
          label.write('$ending> line$line');
          rawLabel.write('\nline$line');
          surviving.write('$ending> line$line');
        }
        final source =
            '> [${label.toString()}]($destination "first\n> second")';
        final fragment = _completeSourceFragment('$incoming\n');
        final registry = BusyMarkClipboardInsertionRegistry();
        final controller = await _pumpClipboardSourceEditor(
          tester,
          source: source,
          registry: registry,
          clipboard: _SourceTestClipboard(
            readData: RichClipboardData(
              text: 'X',
              richFragment: fragment.encode(),
            ),
          ),
        );
        controller.selection = TextSelection.collapsed(
          offset: source.indexOf('line0') + 'line0'.length,
        );
        final payload = BusyMarkClipboardPayload(
          id: 'break-offsets-$breakCount',
          acquiredAt: DateTime.utc(2026),
          kind: BusyMarkClipboardContentKind.richText,
          text: 'X',
          richFragment: fragment.encode(),
        );

        measurements.clear();
        visitedNodes.clear();
        expect(registry.canPaste(payload), isTrue);
        expect(measurements, hasLength(1));
        expect(visitedNodes, hasLength(1));
        expect(visitedNodes.single, lessThan(breakCount * 5 + 20));

        measurements.clear();
        visitedNodes.clear();
        await _pressControlKey(tester, LogicalKeyboardKey.keyV);
        await tester.pump();
        expect(measurements, hasLength(1));
        expect(visitedNodes, hasLength(1));
        expect(visitedNodes.single, lessThan(breakCount * 5 + 20));
        expect(measurements.single, lessThan(source.length * 3));

        final expected =
            '> [line0]($destination "first&#10;second")'
            '$incoming'
            '[${surviving.toString()}]($destination "first&#10;second")';
        expect(controller.text, expected);
        final parsed = const MarkdownParser()
            .parse(
              filePath: '/project/source.md',
              source: controller.text,
              validateLocalReferences: false,
            )
            .busyDocument;
        final paragraph = _sourceBlocksDepthFirst(
          parsed.blocks,
        ).firstWhere((block) => block.kind == BusyBlockKind.paragraph);
        final links = paragraph.inlines
            .where((inline) => inline.kind == BusyInlineKind.link)
            .toList();
        expect(links.map((inline) => inline.destination), [
          destination,
          'https://incoming.test',
          destination,
        ]);
        expect(links.last.plainText, rawLabel.toString().substring(5));
        expect(links.first.attributes['title'], 'first\nsecond');
        expect(links.last.attributes['title'], 'first\nsecond');
        final incomingEnd = controller.text.indexOf(incoming) + incoming.length;
        expect(controller.selection.baseOffset, incomingEnd);
        registry.dispose();
        if (caseIndex + 1 < 3) {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        }
      }
    },
  );

  testWidgets(
    'Source AST boundary mapping stays linear for availability and paste',
    (tester) async {
      addTearDown(() => debugBusyMarkSourceMappingBoundaryInspections = null);
      final fragment = _completeSourceFragment('[X](https://incoming.test)\n');
      for (final (caseIndex, codeSpanCount) in [10, 100, 1000].indexed) {
        final prefix = [
          for (var index = 0; index < codeSpanCount; index++) '`code$index`',
        ].join(' ');
        final source = '$prefix [leftright](https://destination.test)';
        final registry = BusyMarkClipboardInsertionRegistry();
        final controller = await _pumpClipboardSourceEditor(
          tester,
          source: source,
          registry: registry,
          clipboard: _SourceTestClipboard(),
        );
        controller.selection = TextSelection.collapsed(
          offset: source.indexOf('leftright') + 4,
        );
        final payload = BusyMarkClipboardPayload(
          id: 'ast-boundaries-$codeSpanCount',
          acquiredAt: DateTime.utc(2026),
          kind: BusyMarkClipboardContentKind.richText,
          text: 'X',
          richFragment: fragment.encode(),
        );

        var inspections = 0;
        debugBusyMarkSourceMappingBoundaryInspections = (value) =>
            inspections += value;
        expect(registry.canPaste(payload), isTrue);
        expect(
          inspections,
          lessThanOrEqualTo(codeSpanCount * 8 + 30),
          reason:
              'availability with $codeSpanCount spans inspected '
              '$inspections boundaries',
        );

        inspections = 0;
        expect(await registry.paste(payload), ClipboardPasteResult.inserted);
        expect(
          inspections,
          lessThanOrEqualTo(codeSpanCount * 16 + 60),
          reason:
              'paste with $codeSpanCount spans inspected '
              '$inspections boundaries',
        );
        expect(controller.text, startsWith('$prefix '));
        final parsed = const MarkdownParser()
            .parse(
              filePath: '/project/source.md',
              source: controller.text,
              validateLocalReferences: false,
            )
            .busyDocument;
        expect(
          parsed.blocks.single.inlines.where(
            (inline) => inline.kind == BusyInlineKind.code,
          ),
          hasLength(codeSpanCount),
        );
        expect(
          parsed.blocks.single.inlines
              .where((inline) => inline.kind == BusyInlineKind.link)
              .map((inline) => inline.destination),
          [
            'https://destination.test',
            'https://incoming.test',
            'https://destination.test',
          ],
          reason: controller.text,
        );
        registry.dispose();
        if (caseIndex < 2) {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        }
      }
    },
  );

  testWidgets('Source table paste preserves multiline link titles', (
    tester,
  ) async {
    const title = 'first\nsecond &copy;';
    final fragment = WysiwygClipboardFragment(
      mode: MarkdownMode.gfm,
      blocks: const [
        BusyWysiwygStyledBlock(
          kind: BusyBlockKind.paragraph,
          text: 'X',
          ranges: [],
          completeBlock: BusyBlock(
            id: 'title-fragment',
            kind: BusyBlockKind.paragraph,
            inlines: [
              BusyInline(
                kind: BusyInlineKind.link,
                text: 'X',
                destination: 'https://example.test',
                children: [BusyInline(kind: BusyInlineKind.text, text: 'X')],
                attributes: {'title': title},
              ),
            ],
          ),
        ),
      ],
    );
    const source = '| H |\n| --- |\n| gap |\n';
    final controller = await _pumpClipboardSourceEditor(
      tester,
      source: source,
      markdownMode: MarkdownMode.gfm,
      clipboard: _SourceTestClipboard(
        readData: RichClipboardData(text: 'X', richFragment: fragment.encode()),
      ),
    );
    final gap = source.indexOf('gap');
    controller.selection = TextSelection(
      baseOffset: gap,
      extentOffset: gap + 3,
    );

    await _pressControlKey(tester, LogicalKeyboardKey.keyV);
    await tester.pump();

    expect(controller.text.split('\n'), hasLength(4));
    final table = const MarkdownParser()
        .parse(
          filePath: '/project/source.md',
          source: controller.text,
          mode: MarkdownMode.gfm,
          validateLocalReferences: false,
        )
        .busyDocument
        .blocks
        .single;
    expect(table.children, hasLength(2));
    expect(table.children.last.children, hasLength(1));
    final link = table.children.last.children.single.inlines.single;
    expect(link.kind, BusyInlineKind.link);
    expect(link.destination, 'https://example.test');
    expect(link.attributes['title'], title);
  });

  testWidgets(
    'Source table boundary paste preserves styles caret and one-step history',
    (tester) async {
      const source = '| **leftSELECT**tail |\n| --- |\n';
      const expected = '| **leftX**tail |\n| --- |\n';
      var modelText = source;
      var modelSelection = const TextSelection.collapsed(offset: 0);
      var history = const DocumentUndoState();
      var transactions = 0;
      final controller = await _pumpClipboardSourceEditor(
        tester,
        source: source,
        markdownMode: MarkdownMode.gfm,
        clipboard: _SourceTestClipboard(
          readData: RichClipboardData(
            text: 'X',
            richFragment: _completeSourceFragment('**X**\n').encode(),
          ),
        ),
        onTransactionalChanged:
            (value, _, previousSelection, selection, undoGroup) {
              transactions += 1;
              history = history.push(
                DocumentHistoryState(
                  text: modelText,
                  selection: previousSelection,
                ),
                group: undoGroup,
              );
              modelText = value;
              modelSelection = selection;
            },
        onUndo: () {
          if (history.undo.isEmpty) return null;
          final target = history.undo.last;
          history = history.afterUndo(
            DocumentHistoryState(text: modelText, selection: modelSelection),
          );
          modelText = target.text;
          modelSelection = target.selection;
          return TextEditingValue(
            text: target.text,
            selection: target.selection,
          );
        },
        onRedo: () {
          if (history.redo.isEmpty) return null;
          final target = history.redo.last;
          history = history.afterRedo(
            DocumentHistoryState(text: modelText, selection: modelSelection),
          );
          modelText = target.text;
          modelSelection = target.selection;
          return TextEditingValue(
            text: target.text,
            selection: target.selection,
          );
        },
      );
      final selection = TextSelection(
        baseOffset: source.indexOf('SELECT'),
        extentOffset: source.indexOf('**tail') + 2,
      );
      controller.selection = selection;

      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();

      expect(controller.text, expected);
      expect(
        controller.selection,
        TextSelection.collapsed(offset: expected.indexOf('**tail') + 2),
      );
      expect(transactions, 1);
      final parsed = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: controller.text,
            mode: MarkdownMode.gfm,
            validateLocalReferences: false,
          )
          .busyDocument;
      final cell = parsed.blocks.single.children.single.children.single;
      expect(cell.plainText, 'leftXtail');
      expect(cell.inlines.first.kind, BusyInlineKind.strong);
      expect(cell.inlines.first.plainText, 'leftX');
      expect(cell.inlines.last.kind, BusyInlineKind.text);
      expect(cell.inlines.last.plainText, 'tail');

      await _pressControlKey(tester, LogicalKeyboardKey.keyZ);
      await tester.pump();
      expect(controller.text, source);
      expect(controller.selection, selection);

      await _pressControlKey(tester, LogicalKeyboardKey.keyZ, shift: true);
      await tester.pump();
      expect(controller.text, expected);
      expect(
        controller.selection,
        TextSelection.collapsed(offset: expected.indexOf('**tail') + 2),
      );
      expect(transactions, 1);
    },
  );

  testWidgets('Source structured inline paste handles every line boundary', (
    tester,
  ) async {
    final cases = <({String source, int offset, String expected})>[
      (source: '', offset: 0, expected: '**X**'),
      (source: '\nright', offset: 0, expected: '**X**\nright'),
      (source: '\n\nright', offset: 0, expected: '**X**\n\nright'),
      (source: '\r\nright', offset: 0, expected: '**X**\r\nright'),
      (source: 'left\nright', offset: 4, expected: 'left**X**\nright'),
      (source: 'left\nright', offset: 5, expected: 'left\n**X**right'),
      (source: 'right', offset: 5, expected: 'right**X**'),
      (source: 'right\n', offset: 6, expected: 'right\n**X**'),
    ];
    for (final (index, value) in cases.indexed) {
      var transactions = 0;
      final controller = await _pumpClipboardSourceEditor(
        tester,
        source: value.source,
        clipboard: _SourceTestClipboard(
          readData: RichClipboardData(
            text: 'X',
            richFragment: _completeSourceFragment('**X**\n').encode(),
          ),
        ),
        onTransactionalChanged: (_, _, _, _, _) => transactions++,
      );
      controller.selection = TextSelection.collapsed(offset: value.offset);

      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();

      expect(controller.text, value.expected, reason: value.source);
      expect(
        controller.selection.baseOffset,
        value.offset + '**X**'.length,
        reason: value.source,
      );
      expect(transactions, 1, reason: value.source);
      if (index + 1 < cases.length) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    }
  });

  testWidgets(
    'Source inline paste preserves unrelated syntax whitespace and caret',
    (tester) async {
      Future<TextEditingController> paste(
        String source,
        int offset,
        String? fragmentSource,
      ) async {
        final fragment = fragmentSource == null
            ? WysiwygClipboardFragment(
                mode: MarkdownMode.commonMark,
                blocks: const [
                  BusyWysiwygStyledBlock(
                    kind: BusyBlockKind.paragraph,
                    text: 'X ',
                    ranges: [],
                  ),
                ],
              )
            : _completeSourceFragment(fragmentSource);
        final controller = await _pumpClipboardSourceEditor(
          tester,
          source: source,
          clipboard: _SourceTestClipboard(
            readData: RichClipboardData(
              text: 'X',
              richFragment: fragment.encode(),
            ),
          ),
        );
        controller.selection = TextSelection.collapsed(offset: offset);
        await _pressControlKey(tester, LogicalKeyboardKey.keyV);
        await tester.pump();
        return controller;
      }

      var controller = await paste(
        'left __keep__ right',
        'left'.length,
        '**X**\n',
      );
      expect(controller.text, 'left**X** __keep__ right');
      expect(controller.selection.baseOffset, 'left**X**'.length);

      controller = await paste('**left**right', '**left**'.length, null);
      expect(controller.text, '**left**X right');
      expect(controller.selection.baseOffset, '**left**X '.length);

      controller = await paste('__leftright__', '__left'.length, '**X**\n');
      expect(controller.text, '__leftXright__');
      expect(controller.selection.baseOffset, '__leftX'.length);
    },
  );

  testWidgets('Source table cells reconcile surrounding inline styles', (
    tester,
  ) async {
    const source = '| H |\n| --- |\n| **leftright** |\n';
    final controller = await _pumpClipboardSourceEditor(
      tester,
      source: source,
      markdownMode: MarkdownMode.gfm,
      clipboard: _SourceTestClipboard(
        readData: RichClipboardData(
          text: 'X',
          richFragment: _completeSourceFragment('**X**\n').encode(),
        ),
      ),
    );
    controller.selection = TextSelection.collapsed(
      offset: source.indexOf('left') + 4,
    );
    await _pressControlKey(tester, LogicalKeyboardKey.keyV);
    await tester.pump();

    expect(controller.text, '| H |\n| --- |\n| **leftXright** |\n');
    expect(controller.selection.baseOffset, controller.text.indexOf('X') + 1);
    final table = const MarkdownParser()
        .parse(
          filePath: '/project/source.md',
          source: controller.text,
          mode: MarkdownMode.gfm,
          validateLocalReferences: false,
        )
        .busyDocument
        .blocks
        .single;
    expect(
      table.children.last.children.single.inlines.single.kind,
      BusyInlineKind.strong,
    );

    const indented = '  | H |\n  | --- |\n  | *leftright* |\n';
    final indentedController = await _pumpClipboardSourceEditor(
      tester,
      source: indented,
      markdownMode: MarkdownMode.gfm,
      clipboard: _SourceTestClipboard(
        readData: RichClipboardData(
          text: 'X',
          richFragment: _completeSourceFragment('*X*\n').encode(),
        ),
      ),
    );
    indentedController.selection = TextSelection.collapsed(
      offset: indented.indexOf('left') + 4,
    );
    await _pressControlKey(tester, LogicalKeyboardKey.keyV);
    await tester.pump();
    expect(indentedController.text, '  | H |\n  | --- |\n  | *leftXright* |\n');
  });

  testWidgets('Source reconciliation reuses table-normalized inline content', (
    tester,
  ) async {
    final cases = <({BusyInlineKind kind, List<BusyInline> children})>[
      (
        kind: BusyInlineKind.strong,
        children: const [
          BusyInline(kind: BusyInlineKind.text, text: 'A'),
          BusyInline(kind: BusyInlineKind.hardBreak, text: '\n'),
          BusyInline(kind: BusyInlineKind.text, text: 'B'),
        ],
      ),
      (
        kind: BusyInlineKind.emphasis,
        children: const [BusyInline(kind: BusyInlineKind.text, text: 'A\r\nB')],
      ),
    ];
    for (final (index, value) in cases.indexed) {
      final delimiter = value.kind == BusyInlineKind.strong ? '**' : '*';
      final fragment = WysiwygClipboardFragment(
        mode: MarkdownMode.gfm,
        blocks: [
          BusyWysiwygStyledBlock(
            kind: BusyBlockKind.paragraph,
            text: 'A\nB',
            ranges: const [],
            completeBlock: BusyBlock(
              id: 'normalized-inline-$index',
              kind: BusyBlockKind.paragraph,
              inlines: [
                BusyInline(
                  kind: value.kind,
                  text: 'A\nB',
                  children: value.children,
                ),
              ],
            ),
          ),
        ],
      );
      final source =
          '| H |\n'
          '| --- |\n'
          '| ${delimiter}leftright$delimiter |\n';
      final controller = await _pumpClipboardSourceEditor(
        tester,
        source: source,
        markdownMode: MarkdownMode.gfm,
        clipboard: _SourceTestClipboard(
          readData: RichClipboardData(
            text: 'A B',
            richFragment: fragment.encode(),
          ),
        ),
      );
      controller.selection = TextSelection.collapsed(
        offset: source.indexOf('leftright') + 4,
      );
      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();

      expect(
        controller.text,
        '| H |\n'
        '| --- |\n'
        '| ${delimiter}leftA Bright$delimiter |\n',
      );
      final parsed = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: controller.text,
            mode: MarkdownMode.gfm,
            validateLocalReferences: false,
          )
          .busyDocument;
      expect(parsed.blocks, hasLength(1), reason: controller.text);
      final table = parsed.blocks.single;
      expect(table.kind, BusyBlockKind.table);
      expect(table.children, hasLength(2));
      final cell = table.children.last.children.single;
      expect(cell.plainText, 'leftA Bright');
      expect(cell.inlines.single.kind, value.kind);
      expect(controller.text.split('\n'), hasLength(4));
      if (index + 1 < cases.length) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    }
  });

  testWidgets(
    'Source whole-block replacement differs from surviving table and code contexts',
    (tester) async {
      final heading = _completeSourceFragment('## Replacement\n');
      const tableSource = '| A | B |\n| --- | --- |\n| one | two |\n';
      final wholeTable = await _pumpClipboardSourceEditor(
        tester,
        source: tableSource,
        markdownMode: MarkdownMode.gfm,
        clipboard: _SourceTestClipboard(
          readData: RichClipboardData(
            text: 'Replacement',
            richFragment: heading.encode(),
          ),
        ),
      );
      wholeTable.selection = TextSelection(
        baseOffset: 0,
        extentOffset: tableSource.length,
      );
      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();
      var parsed = const MarkdownParser().parse(
        filePath: '/project/source.md',
        source: wholeTable.text,
        mode: MarkdownMode.gfm,
        validateLocalReferences: false,
      );
      expect(
        parsed.busyDocument.blocks.single.kind,
        BusyBlockKind.heading,
        reason: wholeTable.text,
      );

      final replacementTable = _completeSourceFragment(
        '| C | D |\n| --- | --- |\n| three | four |\n',
        mode: MarkdownMode.gfm,
      );
      final tableWithTable = await _pumpClipboardSourceEditor(
        tester,
        source: tableSource,
        markdownMode: MarkdownMode.gfm,
        clipboard: _SourceTestClipboard(
          readData: RichClipboardData(
            text: 'C D three four',
            richFragment: replacementTable.encode(),
          ),
        ),
      );
      tableWithTable.selection = TextSelection(
        baseOffset: 0,
        extentOffset: tableSource.length,
      );
      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();
      parsed = const MarkdownParser().parse(
        filePath: '/project/source.md',
        source: tableWithTable.text,
        mode: MarkdownMode.gfm,
        validateLocalReferences: false,
      );
      expect(parsed.busyDocument.blocks.single.kind, BusyBlockKind.table);
      expect(
        parsed.busyDocument.blocks.single.children.last.children.last.plainText,
        'four',
      );

      const codeSource = '```text\nold\n```\n';
      final wholeCode = await _pumpClipboardSourceEditor(
        tester,
        source: codeSource,
        clipboard: _SourceTestClipboard(
          readData: RichClipboardData(
            text: 'Replacement',
            richFragment: heading.encode(),
          ),
        ),
      );
      wholeCode.selection = TextSelection(
        baseOffset: 0,
        extentOffset: codeSource.length,
      );
      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();
      parsed = const MarkdownParser().parse(
        filePath: '/project/source.md',
        source: wholeCode.text,
        validateLocalReferences: false,
      );
      expect(parsed.busyDocument.blocks.single.kind, BusyBlockKind.heading);

      final registry = BusyMarkClipboardInsertionRegistry();
      addTearDown(registry.dispose);
      final crossCell = await _pumpClipboardSourceEditor(
        tester,
        source: tableSource,
        markdownMode: MarkdownMode.gfm,
        registry: registry,
        clipboard: _SourceTestClipboard(),
      );
      crossCell.selection = TextSelection(
        baseOffset: tableSource.indexOf('one'),
        extentOffset: tableSource.indexOf('two') + 3,
      );
      await tester.pump();
      final richOnly = BusyMarkClipboardPayload(
        id: 'cross-cell-rich-only',
        acquiredAt: DateTime.utc(2026),
        kind: BusyMarkClipboardContentKind.richText,
        richFragment: heading.encode(),
      );
      expect(registry.canPaste(richOnly), isFalse);
      expect(await registry.paste(richOnly), ClipboardPasteResult.unavailable);
      expect(crossCell.text, tableSource);
    },
  );

  testWidgets(
    'Source structured paragraph markers escape only at block starts',
    (tester) async {
      for (final marker in ['# Heading', '> quotation', '- item', '1. item']) {
        final fragment = WysiwygClipboardFragment(
          mode: MarkdownMode.commonMark,
          blocks: [
            BusyWysiwygStyledBlock(
              kind: BusyBlockKind.paragraph,
              text: marker,
              ranges: const [],
              completeBlock: BusyBlock(
                id: 'literal-marker',
                kind: BusyBlockKind.paragraph,
                inlines: [BusyInline(kind: BusyInlineKind.text, text: marker)],
              ),
            ),
          ],
        );
        final empty = await _pumpClipboardSourceEditor(
          tester,
          source: '',
          clipboard: _SourceTestClipboard(
            readData: RichClipboardData(
              text: marker,
              richFragment: fragment.encode(),
            ),
          ),
        );
        empty.selection = const TextSelection.collapsed(offset: 0);
        await _pressControlKey(tester, LogicalKeyboardKey.keyV);
        await tester.pump();
        final parsed = const MarkdownParser().parse(
          filePath: '/project/source.md',
          source: empty.text,
          validateLocalReferences: false,
        );
        expect(parsed.busyDocument.blocks.single.kind, BusyBlockKind.paragraph);
        expect(parsed.busyDocument.blocks.single.plainText, marker);

        final middle = await _pumpClipboardSourceEditor(
          tester,
          source: 'leftright',
          clipboard: _SourceTestClipboard(
            readData: RichClipboardData(
              text: marker,
              richFragment: fragment.encode(),
            ),
          ),
        );
        middle.selection = const TextSelection.collapsed(offset: 4);
        await _pressControlKey(tester, LogicalKeyboardKey.keyV);
        await tester.pump();
        expect(middle.text, 'left${marker}right');
      }

      final prefixedFragment = WysiwygClipboardFragment(
        mode: MarkdownMode.commonMark,
        blocks: const [
          BusyWysiwygStyledBlock(
            kind: BusyBlockKind.paragraph,
            text: '# Heading',
            ranges: [],
          ),
        ],
      );
      for (final value in [
        (source: '> right', offset: 2, kind: BusyBlockKind.blockquote),
        (source: '- right', offset: 2, kind: BusyBlockKind.unorderedListItem),
      ]) {
        final prefixed = await _pumpClipboardSourceEditor(
          tester,
          source: value.source,
          clipboard: _SourceTestClipboard(
            readData: RichClipboardData(
              text: '# Heading',
              richFragment: prefixedFragment.encode(),
            ),
          ),
        );
        prefixed.selection = TextSelection.collapsed(offset: value.offset);
        await _pressControlKey(tester, LogicalKeyboardKey.keyV);
        await tester.pump();
        final parsed = const MarkdownParser()
            .parse(
              filePath: '/project/source.md',
              source: prefixed.text,
              validateLocalReferences: false,
            )
            .busyDocument;
        expect(parsed.blocks.single.kind, value.kind, reason: prefixed.text);
        expect(
          _sourceBlocksDepthFirst(
            parsed.blocks,
          ).any((block) => block.plainText == '# Headingright'),
          isTrue,
          reason: prefixed.text,
        );
        expect(prefixed.text, contains(r'\# Heading'));
      }

      final plain = await _pumpClipboardSourceEditor(
        tester,
        source: '',
        clipboard: _SourceTestClipboard(
          readData: const RichClipboardData(text: '# Heading'),
        ),
      );
      await _pressControlKey(tester, LogicalKeyboardKey.keyV, shift: true);
      await tester.pump();
      expect(plain.text, '# Heading');
    },
  );

  testWidgets('Source native inline paste preserves edge and only whitespace', (
    tester,
  ) async {
    WysiwygClipboardFragment native(
      String text, {
      List<BusyInlineStyleRange> ranges = const [],
    }) => WysiwygClipboardFragment(
      mode: MarkdownMode.commonMark,
      blocks: [
        BusyWysiwygStyledBlock(
          kind: BusyBlockKind.paragraph,
          text: text,
          ranges: ranges,
        ),
      ],
    );

    final trailing = await _pumpClipboardSourceEditor(
      tester,
      source: 'leftright',
      clipboard: _SourceTestClipboard(
        readData: RichClipboardData(
          text: 'X ',
          richFragment: native('X ').encode(),
          generation: 42,
        ),
      ),
    );
    trailing.selection = const TextSelection.collapsed(offset: 4);
    await _pressControlKey(tester, LogicalKeyboardKey.keyV);
    await tester.pump();
    expect(trailing.text, 'leftX right');

    final styled = await _pumpClipboardSourceEditor(
      tester,
      source: 'leftright',
      clipboard: _SourceTestClipboard(
        readData: RichClipboardData(
          text: ' X ',
          richFragment: native(
            ' X ',
            ranges: const [
              BusyInlineStyleRange(
                start: 1,
                end: 2,
                kind: BusyInlineKind.strong,
              ),
            ],
          ).encode(),
          generation: 43,
        ),
      ),
    );
    styled.selection = const TextSelection.collapsed(offset: 4);
    await _pressControlKey(tester, LogicalKeyboardKey.keyV);
    await tester.pump();
    expect(styled.text, 'left **X** right');

    final whitespace = await _pumpClipboardSourceEditor(
      tester,
      source: 'leftDELETEright',
      clipboard: _SourceTestClipboard(
        readData: RichClipboardData(
          text: '   ',
          richFragment: native('   ').encode(),
          generation: 44,
        ),
      ),
    );
    whitespace.selection = const TextSelection(baseOffset: 4, extentOffset: 10);
    await _pressControlKey(tester, LogicalKeyboardKey.keyV);
    await tester.pump();
    expect(whitespace.text, 'left   right');
  });

  testWidgets(
    'Source native rich edge whitespace repeats and restores real Undo state',
    (tester) async {
      const source = '[<u>leftright</u>](https://destination.test) tail';
      const fragment = WysiwygClipboardFragment(
        mode: MarkdownMode.commonMark,
        sourcePath: '/clipboard/source.md',
        blocks: [
          BusyWysiwygStyledBlock(
            kind: BusyBlockKind.paragraph,
            text: 'Y ',
            ranges: [
              BusyInlineStyleRange(
                start: 0,
                end: 2,
                kind: BusyInlineKind.link,
                destination: 'https://incoming.test',
              ),
            ],
            completeBlock: BusyBlock(
              id: 'native-rich-space',
              kind: BusyBlockKind.paragraph,
              inlines: [
                BusyInline(
                  kind: BusyInlineKind.link,
                  text: 'Y ',
                  destination: 'https://incoming.test',
                  attributes: {'title': 'Incoming title'},
                  children: [BusyInline(kind: BusyInlineKind.text, text: 'Y ')],
                ),
              ],
            ),
          ),
        ],
      );
      final clipboard = _SourceTestClipboard(
        readData: RichClipboardData(
          text: 'PLAIN_FALLBACK',
          sourceText: '**SOURCE_FALLBACK**',
          html: '<p><strong>HTML_FALLBACK</strong></p>',
          richFragment: fragment.encode(),
          generation: 46,
        ),
      );
      var modelText = source;
      var modelSelection = const TextSelection.collapsed(offset: 0);
      var history = const DocumentUndoState();
      final controller = await _pumpClipboardSourceEditor(
        tester,
        source: source,
        clipboard: clipboard,
        onTransactionalChanged:
            (value, _, previousSelection, selection, undoGroup) {
              history = history.push(
                DocumentHistoryState(
                  text: modelText,
                  selection: previousSelection,
                ),
                group: undoGroup,
              );
              modelText = value;
              modelSelection = selection;
            },
        onUndo: () {
          if (history.undo.isEmpty) return null;
          final target = history.undo.last;
          history = history.afterUndo(
            DocumentHistoryState(text: modelText, selection: modelSelection),
          );
          modelText = target.text;
          modelSelection = target.selection;
          return TextEditingValue(
            text: target.text,
            selection: target.selection,
          );
        },
        onRedo: () {
          if (history.redo.isEmpty) return null;
          final target = history.redo.last;
          history = history.afterRedo(
            DocumentHistoryState(text: modelText, selection: modelSelection),
          );
          modelText = target.text;
          modelSelection = target.selection;
          return TextEditingValue(
            text: target.text,
            selection: target.selection,
          );
        },
      );
      final initialSelection = TextSelection.collapsed(
        offset: source.indexOf('right'),
      );
      controller.selection = initialSelection;

      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();
      final firstText = controller.text;
      final firstSelection = controller.selection;
      expect(firstSelection.isCollapsed, isTrue);
      expect(firstText, isNot(contains('PLAIN_FALLBACK')));
      expect(firstText, isNot(contains('SOURCE_FALLBACK')));
      expect(firstText, isNot(contains('HTML_FALLBACK')));
      var paragraph = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: firstText,
            validateLocalReferences: false,
          )
          .busyDocument
          .blocks
          .single;
      expect(paragraph.plainText, 'leftY right tail', reason: firstText);
      expect(
        paragraph.inlines
            .where((inline) => inline.kind == BusyInlineKind.link)
            .map((inline) => inline.destination),
        [
          'https://destination.test',
          'https://incoming.test',
          'https://destination.test',
        ],
      );
      final editorDocument = const MarkdownParser()
          .parse(
            filePath: '/project/editor.md',
            source: source,
            validateLocalReferences: false,
          )
          .busyDocument;
      final editorController = BusyMarkWysiwygDocumentController(
        document: editorDocument,
      );
      addTearDown(editorController.dispose);
      final editorBlock = editorController.document.blocks.single;
      expect(
        editorController.insertStyledBlocksAtSelection(
          blockId: editorBlock.id,
          selectionStart: 4,
          selectionEnd: 4,
          blocks: fragment.blocks,
        ),
        isNotNull,
      );
      final editorParagraph = editorController.document.blocks.single;
      expect(editorParagraph.plainText, paragraph.plainText);
      final sourceRuns = _inlineSemanticRuns(
        paragraph.inlines,
      ).where((run) => run.text.trim().isNotEmpty).toList(growable: false);
      final editorRuns = _inlineSemanticRuns(
        editorParagraph.inlines,
      ).where((run) => run.text.trim().isNotEmpty).toList(growable: false);
      expect(
        sourceRuns.map((run) => run.text.trim()),
        editorRuns.map((run) => run.text.trim()),
      );
      for (final runs in [sourceRuns, editorRuns]) {
        final incoming = runs.singleWhere((run) => run.text.trim() == 'Y');
        expect(incoming.context, contains('underline'));
        expect(incoming.context, contains('link:https://incoming.test'));
        expect(incoming.context, contains('Incoming title'));
      }
      expect(
        editorRuns
            .where(
              (run) => run.context.contains('link:https://destination.test'),
            )
            .map((run) => run.text.trim()),
        ['left', 'right'],
      );

      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();
      final secondText = controller.text;
      final secondSelection = controller.selection;
      paragraph = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: secondText,
            validateLocalReferences: false,
          )
          .busyDocument
          .blocks
          .single;
      expect(paragraph.plainText, 'leftY Y right tail', reason: secondText);
      expect(
        secondSelection.baseOffset,
        greaterThan(firstSelection.baseOffset),
      );

      final typedOffset = secondSelection.baseOffset;
      final typedText = secondText.replaceRange(typedOffset, typedOffset, 'Z');
      tester.testTextInput.updateEditingValue(
        TextEditingValue(
          text: typedText,
          selection: TextSelection.collapsed(offset: typedOffset + 1),
        ),
      );
      await tester.pump();
      expect(controller.text, typedText);

      await _pressControlKey(tester, LogicalKeyboardKey.keyZ);
      await tester.pump();
      expect(controller.text, secondText);
      expect(controller.selection, secondSelection);
      await _pressControlKey(tester, LogicalKeyboardKey.keyZ);
      await tester.pump();
      expect(controller.text, firstText);
      expect(controller.selection, firstSelection);
      await _pressControlKey(tester, LogicalKeyboardKey.keyZ);
      await tester.pump();
      expect(controller.text, source);
      expect(controller.selection, initialSelection);

      await _pressControlKey(tester, LogicalKeyboardKey.keyZ, shift: true);
      await tester.pump();
      expect(controller.text, firstText);
      expect(controller.selection, firstSelection);
      await _pressControlKey(tester, LogicalKeyboardKey.keyZ, shift: true);
      await tester.pump();
      expect(controller.text, secondText);
      expect(controller.selection, secondSelection);
      await _pressControlKey(tester, LogicalKeyboardKey.keyZ, shift: true);
      await tester.pump();
      expect(controller.text, typedText);
      expect(
        controller.selection,
        TextSelection.collapsed(offset: typedOffset + 1),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      final reopened = await _pumpClipboardSourceEditor(
        tester,
        source: secondText,
        clipboard: clipboard,
      );
      reopened.selection = secondSelection;
      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();
      paragraph = const MarkdownParser()
          .parse(
            filePath: '/project/source.md',
            source: reopened.text,
            validateLocalReferences: false,
          )
          .busyDocument
          .blocks
          .single;
      expect(paragraph.plainText, 'leftY Y Y right tail');
    },
  );

  testWidgets('Source structured paste respects table-cell semantics', (
    tester,
  ) async {
    final fragment = WysiwygClipboardFragment(
      mode: MarkdownMode.gfm,
      blocks: [
        BusyWysiwygStyledBlock(
          kind: BusyBlockKind.paragraph,
          text: 'A|B',
          ranges: const [],
        ),
        BusyWysiwygStyledBlock(
          kind: BusyBlockKind.paragraph,
          text: 'C\nD',
          ranges: const [],
        ),
      ],
    );
    const source = 'before\n\n| H |\n| --- |\n| leftright |\n\nafter\n';
    final controller = await _pumpClipboardSourceEditor(
      tester,
      source: source,
      markdownMode: MarkdownMode.gfm,
      clipboard: _SourceTestClipboard(
        readData: RichClipboardData(
          text: 'A|B C D',
          richFragment: fragment.encode(),
          generation: 45,
        ),
      ),
    );
    controller.selection = TextSelection.collapsed(
      offset: source.indexOf('leftright') + 4,
    );
    await _pressControlKey(tester, LogicalKeyboardKey.keyV);
    await tester.pump();

    expect(
      controller.text,
      'before\n\n| H |\n| --- |\n| leftA\\|B C Dright |\n\nafter\n',
    );
    final parsed = const MarkdownParser().parse(
      filePath: '/project/source.md',
      source: controller.text,
      mode: MarkdownMode.gfm,
      validateLocalReferences: false,
    );
    expect(parsed.busyDocument.blocks[1].kind, BusyBlockKind.table);
    expect(
      parsed.busyDocument.blocks[1].children.last.children.single.plainText,
      'leftA|B C Dright',
    );
  });

  testWidgets('Source maps a final table cell ending in an escaped pipe', (
    tester,
  ) async {
    const source =
        '| A | B |\n'
        '| --- | --- |\n'
        '| left | B\\|';
    final controller = await _pumpClipboardSourceEditor(
      tester,
      source: source,
      markdownMode: MarkdownMode.gfm,
      clipboard: _SourceTestClipboard(
        readData: RichClipboardData(
          text: 'X',
          richFragment: _completeSourceFragment('**X**\n').encode(),
        ),
      ),
    );
    final selected = source.lastIndexOf('B');
    controller.selection = TextSelection(
      baseOffset: selected,
      extentOffset: selected + 1,
    );

    await _pressControlKey(tester, LogicalKeyboardKey.keyV);
    await tester.pump();

    expect(
      controller.text,
      '| A | B |\n'
      '| --- | --- |\n'
      '| left | **X**\\|',
    );
    expect(controller.selection.baseOffset, controller.text.indexOf('X') + 3);
    final table = const MarkdownParser()
        .parse(
          filePath: '/project/source.md',
          source: controller.text,
          mode: MarkdownMode.gfm,
          validateLocalReferences: false,
        )
        .busyDocument
        .blocks
        .single;
    final cells = table.children.last.children;
    expect(cells, hasLength(2));
    expect(cells.first.plainText, 'left');
    expect(cells.last.plainText, 'X|');
    expect(cells.last.inlines.first.kind, BusyInlineKind.strong);
  });

  testWidgets('Source structured blocks preserve list and quote containers', (
    tester,
  ) async {
    final fragment = WysiwygClipboardFragment(
      mode: MarkdownMode.commonMark,
      blocks: [
        BusyWysiwygStyledBlock(
          kind: BusyBlockKind.heading,
          text: 'Heading',
          ranges: const [],
          attributes: const {'level': '2'},
        ),
      ],
    );
    for (final value in [
      ('- leftright\n', '- left\n\n  ## Heading\n\n  right\n'),
      ('> leftright\n', '> left\n>\n> ## Heading\n>\n> right\n'),
    ]) {
      final controller = await _pumpClipboardSourceEditor(
        tester,
        source: value.$1,
        clipboard: _SourceTestClipboard(
          readData: RichClipboardData(
            text: 'Heading',
            richFragment: fragment.encode(),
            generation: 46,
          ),
        ),
      );
      controller.selection = TextSelection.collapsed(
        offset: value.$1.indexOf('leftright') + 4,
      );
      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();
      expect(controller.text, value.$2);
    }
  });

  testWidgets(
    'Source complete blocks remain in containers at every content boundary',
    (tester) async {
      final heading = _completeSourceFragment('## Heading\n');
      final cases = <({String source, int offset})>[];
      for (final source in ['> item', '> item\n', '- item', '- item\n']) {
        final contentStart = source.indexOf('item');
        for (final relative in [0, 2, 4]) {
          cases.add((source: source, offset: contentStart + relative));
        }
      }
      cases.addAll([
        (source: '   - item', offset: '   - item'.length),
        (source: '>   3. item', offset: '>   3. item'.length),
      ]);
      for (final value in cases) {
        final controller = await _pumpClipboardSourceEditor(
          tester,
          source: value.source,
          clipboard: _SourceTestClipboard(
            readData: RichClipboardData(
              text: 'Heading',
              richFragment: heading.encode(),
            ),
          ),
        );
        controller.selection = TextSelection.collapsed(offset: value.offset);
        await _pressControlKey(tester, LogicalKeyboardKey.keyV);
        await tester.pump();

        final headingPaths = _markdownElementPaths(
          md.Document().parse(controller.text),
          'h2',
        );
        expect(headingPaths, hasLength(1), reason: controller.text);
        expect(
          headingPaths.single.any(
            (element) => element.tag == 'li' || element.tag == 'blockquote',
          ),
          isTrue,
          reason: 'Heading escaped its container: ${controller.text}',
        );
      }
    },
  );

  testWidgets('Source complete blocks retain continuation-line ancestors', (
    tester,
  ) async {
    final heading = _completeSourceFragment('## Heading\n');
    for (final source in [
      '- first\n  leftright\n',
      '- first\n\n  leftright\n',
      '> first\nleftright\n',
    ]) {
      final contentStart = source.indexOf('leftright');
      for (final relative in [0, 4, 9]) {
        final controller = await _pumpClipboardSourceEditor(
          tester,
          source: source,
          clipboard: _SourceTestClipboard(
            readData: RichClipboardData(
              text: 'Heading',
              richFragment: heading.encode(),
            ),
          ),
        );
        controller.selection = TextSelection.collapsed(
          offset: contentStart + relative,
        );
        await _pressControlKey(tester, LogicalKeyboardKey.keyV);
        await tester.pump();

        final headingPaths = _markdownElementPaths(
          md.Document().parse(controller.text),
          'h2',
        );
        expect(headingPaths, hasLength(1), reason: controller.text);
        expect(
          headingPaths.single.any(
            (element) => element.tag == 'li' || element.tag == 'blockquote',
          ),
          isTrue,
          reason: 'Heading escaped continuation: ${controller.text}',
        );
      }
    }
  });

  testWidgets(
    'Source container recovery is bound to the actual nested ancestors',
    (tester) async {
      final heading = _completeSourceFragment('## Heading\n');
      const subtree =
          'Paragraph.\n\n'
          '- Outer\n'
          '  - Inner\n'
          '    leftright\n';
      final prefixes = ['12345.  - unrelated\n\n', '', '9.  - unrelated\n\n'];
      for (final (index, prefix) in prefixes.indexed) {
        final source = '$prefix$subtree';
        final controller = await _pumpClipboardSourceEditor(
          tester,
          source: source,
          clipboard: _SourceTestClipboard(
            readData: RichClipboardData(
              text: 'Heading',
              richFragment: heading.encode(),
            ),
          ),
        );
        controller.selection = TextSelection.collapsed(
          offset: source.indexOf('leftright') + 4,
        );

        await _pressControlKey(tester, LogicalKeyboardKey.keyV);
        await tester.pump();

        expect(
          controller.text,
          '$prefix'
          'Paragraph.\n\n'
          '- Outer\n'
          '  - Inner\n'
          '    left\n'
          '\n'
          '    ## Heading\n'
          '\n'
          '    right\n',
          reason: prefix,
        );
        final headingPaths = _markdownElementPaths(
          md.Document().parse(controller.text),
          'h2',
        );
        expect(headingPaths, hasLength(1), reason: controller.text);
        expect(
          headingPaths.single.where((element) => element.tag == 'li'),
          hasLength(2),
          reason: 'Heading does not belong to Inner under Outer',
        );
        expect(RegExp(r'\bright\b').allMatches(controller.text), hasLength(1));
        if (index + 1 < prefixes.length) {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        }
      }
    },
  );

  testWidgets(
    'Source complete blocks use list markers rather than task prefixes',
    (tester) async {
      final heading = _completeSourceFragment('## Heading\n');
      final cases = <({String source, String expected, int listDepth})>[
        (
          source: '- [ ] leftright',
          expected:
              '- [ ] left\n'
              '\n'
              '  ## Heading\n'
              '\n'
              '  right',
          listDepth: 1,
        ),
        (
          source: '- [x] leftright',
          expected:
              '- [x] left\n'
              '\n'
              '  ## Heading\n'
              '\n'
              '  right',
          listDepth: 1,
        ),
        (
          source: '2. [X] leftright',
          expected:
              '2. [X] left\n'
              '\n'
              '   ## Heading\n'
              '\n'
              '   right',
          listDepth: 1,
        ),
        (
          source: '- Outer\n  - [ ] leftright',
          expected:
              '- Outer\n'
              '  - [ ] left\n'
              '\n'
              '    ## Heading\n'
              '\n'
              '    right',
          listDepth: 2,
        ),
        (
          source: '0. leftright',
          expected:
              '0. left\n'
              '\n'
              '   ## Heading\n'
              '\n'
              '   right',
          listDepth: 1,
        ),
      ];
      for (final (index, value) in cases.indexed) {
        final controller = await _pumpClipboardSourceEditor(
          tester,
          source: value.source,
          markdownMode: MarkdownMode.gfm,
          clipboard: _SourceTestClipboard(
            readData: RichClipboardData(
              text: 'Heading',
              richFragment: heading.encode(),
            ),
          ),
        );
        controller.selection = TextSelection.collapsed(
          offset: value.source.indexOf('leftright') + 4,
        );
        await _pressControlKey(tester, LogicalKeyboardKey.keyV);
        await tester.pump();

        expect(controller.text, value.expected, reason: value.source);
        final document = const MarkdownParser()
            .parse(
              filePath: '/project/source.md',
              source: controller.text,
              mode: MarkdownMode.gfm,
              validateLocalReferences: false,
            )
            .busyDocument;
        final paths = _busyBlockKindPaths(
          document.blocks,
          BusyBlockKind.heading,
        );
        expect(paths, hasLength(1), reason: controller.text);
        expect(
          paths.single
              .where(
                (kind) =>
                    kind == BusyBlockKind.taskListItem ||
                    kind == BusyBlockKind.orderedListItem ||
                    kind == BusyBlockKind.unorderedListItem,
              )
              .length,
          value.listDepth,
          reason: controller.text,
        );
        if (value.source.contains('[ ]')) {
          final task = _sourceBlocksDepthFirst(
            document.blocks,
          ).firstWhere((block) => block.kind == BusyBlockKind.taskListItem);
          expect(task.attributes['task'], 'false');
        }
        if (value.source.contains('[x]') || value.source.contains('[X]')) {
          final task = _sourceBlocksDepthFirst(
            document.blocks,
          ).firstWhere((block) => block.kind == BusyBlockKind.taskListItem);
          expect(task.attributes['task'], 'true');
        }
        if (index + 1 < cases.length) {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        }
      }
    },
  );

  testWidgets('Source task items keep block kinds at every content position', (
    tester,
  ) async {
    final fragments = [
      (
        fragment: _completeSourceFragment('## Heading\n'),
        kind: BusyBlockKind.heading,
        text: 'Heading',
      ),
      (
        fragment: _completeSourceFragment('```text\ncode\n```\n'),
        kind: BusyBlockKind.codeBlock,
        text: 'code',
      ),
    ];
    var caseIndex = 0;
    for (final value in fragments) {
      for (final relativeOffset in [0, 4, 'leftright'.length]) {
        if (caseIndex++ > 0) {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        }
        const source = '- [ ] leftright';
        final controller = await _pumpClipboardSourceEditor(
          tester,
          source: source,
          markdownMode: MarkdownMode.gfm,
          clipboard: _SourceTestClipboard(
            readData: RichClipboardData(
              text: value.text,
              richFragment: value.fragment.encode(),
            ),
          ),
        );
        controller.selection = TextSelection.collapsed(
          offset: source.indexOf('leftright') + relativeOffset,
        );
        await _pressControlKey(tester, LogicalKeyboardKey.keyV);
        await tester.pump();

        final document = const MarkdownParser()
            .parse(
              filePath: '/project/source.md',
              source: controller.text,
              mode: MarkdownMode.gfm,
              validateLocalReferences: false,
            )
            .busyDocument;
        final task = _sourceBlocksDepthFirst(
          document.blocks,
        ).firstWhere((block) => block.kind == BusyBlockKind.taskListItem);
        expect(task.attributes['task'], 'false', reason: controller.text);
        final paths = _busyBlockKindPaths(document.blocks, value.kind);
        expect(paths, hasLength(1), reason: controller.text);
        expect(
          paths.single,
          contains(BusyBlockKind.taskListItem),
          reason: controller.text,
        );
      }
    }
  });

  testWidgets(
    'Source checked ordered nested and zero lists retain inserted block kinds',
    (tester) async {
      final heading = _completeSourceFragment('## Heading\n');
      final code = _completeSourceFragment('```text\ncode\n```\n');
      final cases =
          <
            ({
              String source,
              int offset,
              WysiwygClipboardFragment fragment,
              BusyBlockKind kind,
              int depth,
              bool? checked,
            })
          >[
            (
              source: '- [x] leftright',
              offset: 0,
              fragment: code,
              kind: BusyBlockKind.codeBlock,
              depth: 1,
              checked: true,
            ),
            (
              source: '3. [ ] leftright',
              offset: 'leftright'.length,
              fragment: code,
              kind: BusyBlockKind.codeBlock,
              depth: 1,
              checked: false,
            ),
            (
              source: '- Outer\n  - [x] leftright',
              offset: 4,
              fragment: code,
              kind: BusyBlockKind.codeBlock,
              depth: 2,
              checked: true,
            ),
            (
              source: '0. leftright',
              offset: 0,
              fragment: code,
              kind: BusyBlockKind.codeBlock,
              depth: 1,
              checked: null,
            ),
            (
              source: '0. leftright',
              offset: 'leftright'.length,
              fragment: heading,
              kind: BusyBlockKind.heading,
              depth: 1,
              checked: null,
            ),
          ];
      for (final (index, value) in cases.indexed) {
        final controller = await _pumpClipboardSourceEditor(
          tester,
          source: value.source,
          markdownMode: MarkdownMode.gfm,
          clipboard: _SourceTestClipboard(
            readData: RichClipboardData(
              text: value.kind == BusyBlockKind.heading ? 'Heading' : 'code',
              richFragment: value.fragment.encode(),
            ),
          ),
        );
        controller.selection = TextSelection.collapsed(
          offset: value.source.indexOf('leftright') + value.offset,
        );
        await _pressControlKey(tester, LogicalKeyboardKey.keyV);
        await tester.pump();

        final document = const MarkdownParser()
            .parse(
              filePath: '/project/source.md',
              source: controller.text,
              mode: MarkdownMode.gfm,
              validateLocalReferences: false,
            )
            .busyDocument;
        final paths = _busyBlockKindPaths(document.blocks, value.kind);
        expect(paths, hasLength(1), reason: controller.text);
        expect(
          paths.single
              .where(
                (kind) =>
                    kind == BusyBlockKind.taskListItem ||
                    kind == BusyBlockKind.orderedListItem ||
                    kind == BusyBlockKind.unorderedListItem,
              )
              .length,
          value.depth,
          reason: controller.text,
        );
        if (value.checked != null) {
          final task = _sourceBlocksDepthFirst(
            document.blocks,
          ).firstWhere((block) => block.kind == BusyBlockKind.taskListItem);
          expect(task.attributes['task'], '${value.checked}');
        }
        if (value.source.startsWith('0.')) {
          final ordered = document.blocks.single;
          expect(ordered.kind, BusyBlockKind.orderedListItem);
          expect(ordered.attributes['marker'], '0.');
        }
        if (index + 1 < cases.length) {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        }
      }
    },
  );

  testWidgets('Source composes mixed and continuation container ancestors', (
    tester,
  ) async {
    final heading = _completeSourceFragment('## Heading\n');
    final cases = <({String source, String expected, List<String> ancestors})>[
      (
        source: '> Outer\n> - Inner\n>   leftright',
        expected:
            '> Outer\n'
            '> - Inner\n'
            '>   left\n'
            '>\n'
            '>   ## Heading\n'
            '>\n'
            '>   right',
        ancestors: ['blockquote', 'li'],
      ),
      (
        source: '- Outer\n  > Inner\n  > leftright',
        expected:
            '- Outer\n'
            '  > Inner\n'
            '  > left\n'
            '  >\n'
            '  > ## Heading\n'
            '  >\n'
            '  > right',
        ancestors: ['li', 'blockquote'],
      ),
      (
        source: '- Outer\n\n    Later leftright',
        expected:
            '- Outer\n'
            '\n'
            '    Later left\n'
            '\n'
            '    ## Heading\n'
            '\n'
            '    right',
        ancestors: ['li'],
      ),
      (
        source: '- Outer\n  - Inner\n\tleftright',
        expected:
            '- Outer\n'
            '  - Inner\n'
            '\tleft\n'
            '\n'
            '\t## Heading\n'
            '\n'
            '\tright',
        ancestors: ['li', 'li'],
      ),
      (
        source: '12345. Outer\n       - Inner\n         leftright',
        expected:
            '12345. Outer\n'
            '       - Inner\n'
            '         left\n'
            '\n'
            '         ## Heading\n'
            '\n'
            '         right',
        ancestors: ['li', 'li'],
      ),
      (
        source: '> Outer\nleftright',
        expected:
            '> Outer\n'
            'left\n'
            '>\n'
            '> ## Heading\n'
            '>\n'
            '> right',
        ancestors: ['blockquote'],
      ),
    ];
    for (final (index, value) in cases.indexed) {
      final controller = await _pumpClipboardSourceEditor(
        tester,
        source: value.source,
        clipboard: _SourceTestClipboard(
          readData: RichClipboardData(
            text: 'Heading',
            richFragment: heading.encode(),
          ),
        ),
      );
      controller.selection = TextSelection.collapsed(
        offset: value.source.indexOf('leftright') + 4,
      );

      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await tester.pump();

      expect(controller.text, value.expected, reason: value.source);
      final paths = _markdownElementPaths(
        md.Document().parse(controller.text),
        'h2',
      );
      expect(paths, hasLength(1), reason: controller.text);
      expect(
        paths.single
            .where(
              (element) => element.tag == 'li' || element.tag == 'blockquote',
            )
            .map((element) => element.tag),
        value.ancestors,
        reason: controller.text,
      );
      expect(RegExp(r'\bright\b').allMatches(controller.text), hasLength(1));
      if (index + 1 < cases.length) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    }
  });

  testWidgets('Source protected contexts use the safe source fallback', (
    tester,
  ) async {
    final registry = BusyMarkClipboardInsertionRegistry();
    addTearDown(registry.dispose);
    final fragment = WysiwygClipboardFragment(
      mode: MarkdownMode.commonMark,
      blocks: const [
        BusyWysiwygStyledBlock(
          kind: BusyBlockKind.heading,
          text: 'Heading',
          ranges: [],
          attributes: {'level': '2'},
        ),
      ],
    );
    const source = '```text\nleftright\n```\n';
    final controller = await _pumpClipboardSourceEditor(
      tester,
      source: source,
      clipboard: _SourceTestClipboard(
        readData: RichClipboardData(
          text: 'Heading',
          sourceText: '## Heading',
          richFragment: fragment.encode(),
        ),
      ),
      registry: registry,
    );
    controller.selection = TextSelection.collapsed(
      offset: source.indexOf('leftright') + 4,
    );
    await tester.pump();
    expect(
      registry.canPaste(
        BusyMarkClipboardPayload(
          id: 'protected-rich-only',
          acquiredAt: DateTime.utc(2026),
          kind: BusyMarkClipboardContentKind.richText,
          richFragment: fragment.encode(),
          external: true,
        ),
      ),
      isFalse,
    );

    await _pressControlKey(tester, LogicalKeyboardKey.keyV);
    await tester.pump();

    expect(controller.text, '```text\nleft## Headingright\n```\n');
  });

  testWidgets('Writerside Source preserves a structured procedure block', (
    tester,
  ) async {
    const procedure =
        '<procedure title="Deploy"><step><p>Run.</p></step></procedure>';
    final parsed = const MarkdownParser().parse(
      filePath: '/project/topic.md',
      source: '$procedure\n',
      mode: MarkdownMode.writersideMarkdown,
      validateLocalReferences: false,
    );
    final block = parsed.busyDocument.blocks.single;
    final fragment = WysiwygClipboardFragment(
      mode: MarkdownMode.writersideMarkdown,
      blocks: [
        BusyWysiwygStyledBlock(
          kind: block.kind,
          text: block.plainText,
          ranges: busyInlineStyleRanges(block.inlines),
          attributes: block.attributes,
          completeBlock: busyMarkWysiwygImmutableBlockSnapshot(block),
        ),
      ],
    );
    final controller = await _pumpClipboardSourceEditor(
      tester,
      source: 'Before',
      markdownMode: MarkdownMode.writersideMarkdown,
      clipboard: _SourceTestClipboard(
        readData: RichClipboardData(
          text: 'Deploy Run.',
          sourceText: '$procedure\n',
          richFragment: fragment.encode(),
        ),
      ),
    );
    controller.selection = const TextSelection.collapsed(offset: 6);

    await _pressControlKey(tester, LogicalKeyboardKey.keyV);
    await tester.pump();

    expect(controller.text, 'Before\n\n$procedure\n');
  });

  testWidgets('Source delayed paste rejects a changed selection', (
    tester,
  ) async {
    final clipboard = _SourceTestClipboard(
      readData: const RichClipboardData(text: 'paste', generation: 3),
      delayRead: true,
    );
    final controller = await _pumpClipboardSourceEditor(
      tester,
      source: 'abcdef',
      clipboard: clipboard,
    );
    controller.selection = const TextSelection.collapsed(offset: 1);
    await _pressControlKey(tester, LogicalKeyboardKey.keyV);
    await clipboard.readStarted.future;
    controller.selection = const TextSelection.collapsed(offset: 5);
    clipboard.releaseRead();
    await tester.pump();
    expect(controller.text, 'abcdef');
    expect(clipboard.reads, 1);
  });

  testWidgets('Source paste preserves composition before and during a read', (
    tester,
  ) async {
    final clipboard = _SourceTestClipboard(
      readData: const RichClipboardData(text: 'paste', generation: 47),
    );
    final registry = BusyMarkClipboardInsertionRegistry();
    addTearDown(registry.dispose);
    final captures = <BusyMarkClipboardCapture>[];
    final controller = await _pumpClipboardSourceEditor(
      tester,
      source: 'abcdef',
      clipboard: clipboard,
      registry: registry,
      onCaptured: captures.add,
    );
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'abcdef',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 1, end: 2),
      ),
    );
    await tester.pump();
    await _pressControlKey(tester, LogicalKeyboardKey.keyV);
    await tester.pump();
    expect(clipboard.reads, 0);
    expect(controller.text, 'abcdef');
    expect(controller.value.composing, const TextRange(start: 1, end: 2));
    expect(
      await registry.paste(
        BusyMarkClipboardPayload(
          id: 'source-composition-history',
          acquiredAt: DateTime.utc(2026),
          kind: BusyMarkClipboardContentKind.text,
          text: 'history',
          external: true,
        ),
      ),
      ClipboardPasteResult.unavailable,
    );

    final delayed = _SourceTestClipboard(
      readData: const RichClipboardData(text: 'paste', generation: 48),
      delayRead: true,
    );
    final delayedController = await _pumpClipboardSourceEditor(
      tester,
      source: 'abcdef',
      clipboard: delayed,
      onCaptured: captures.add,
    );
    delayedController.selection = const TextSelection.collapsed(offset: 2);
    await _pressControlKey(tester, LogicalKeyboardKey.keyV);
    await delayed.readStarted.future;
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'abcdef',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 1, end: 2),
      ),
    );
    await tester.pump();
    expect(
      delayedController.value.composing,
      const TextRange(start: 1, end: 2),
    );
    delayed.releaseRead();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(delayedController.text, 'abcdef');
    expect(captures, isEmpty);
  });

  testWidgets('source failed cut keeps text and does not record history', (
    tester,
  ) async {
    const source = 'alpha beta gamma';
    final clipboard = _SourceTestClipboard(writeResult: false);
    final captures = <BusyMarkClipboardCapture>[];
    String? changed;
    final controller = await _pumpClipboardSourceEditor(
      tester,
      source: source,
      clipboard: clipboard,
      onCaptured: captures.add,
      onChanged: (value, _) => changed = value,
    );
    controller.selection = const TextSelection(baseOffset: 6, extentOffset: 10);

    await _pressControlKey(tester, LogicalKeyboardKey.keyX);
    await tester.pump();

    expect(controller.text, source);
    expect(changed, isNull);
    expect(captures, isEmpty);
  });

  testWidgets('source delayed cut revalidates selection before deletion', (
    tester,
  ) async {
    const source = 'alpha beta gamma';
    final clipboard = _SourceTestClipboard(delayWrite: true);
    final captures = <BusyMarkClipboardCapture>[];
    String? changed;
    final controller = await _pumpClipboardSourceEditor(
      tester,
      source: source,
      clipboard: clipboard,
      onCaptured: captures.add,
      onChanged: (value, _) => changed = value,
    );
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);

    await _pressControlKey(tester, LogicalKeyboardKey.keyX);
    await clipboard.writeStarted.future;
    controller.selection = const TextSelection(
      baseOffset: 11,
      extentOffset: 16,
    );
    clipboard.releaseWrite();
    await tester.pump();

    expect(controller.text, source);
    expect(changed, isNull);
    expect(captures.single.sourceText, 'alpha');
  });

  testWidgets('history insertion follows the latest Source selection', (
    tester,
  ) async {
    final registry = BusyMarkClipboardInsertionRegistry();
    String? changed;
    final controller = await _pumpClipboardSourceEditor(
      tester,
      source: 'abcd',
      clipboard: _SourceTestClipboard(),
      registry: registry,
      onChanged: (value, _) => changed = value,
    );
    controller.selection = const TextSelection.collapsed(offset: 3);
    final payload = BusyMarkClipboardPayload(
      id: 'source-history-payload',
      acquiredAt: DateTime.utc(2026),
      kind: BusyMarkClipboardContentKind.richText,
      text: 'plain',
      sourceText: '**rich**',
    );

    final sourceOnly = BusyMarkClipboardPayload(
      id: 'source-only-payload',
      acquiredAt: DateTime.utc(2026),
      kind: BusyMarkClipboardContentKind.text,
      sourceText: '**source only**',
    );
    expect(registry.canPaste(sourceOnly), isTrue);
    expect(
      registry.canPaste(sourceOnly, mode: BusyMarkPasteMode.plainText),
      isFalse,
    );

    expect(await registry.paste(payload), ClipboardPasteResult.inserted);
    expect(changed, 'abc**rich**d');
    controller.selection = const TextSelection.collapsed(offset: 0);
    expect(
      await registry.paste(payload, mode: BusyMarkPasteMode.plainText),
      ClipboardPasteResult.inserted,
    );
    expect(changed, 'plainabc**rich**d');
  });

  testWidgets('structured history rebases retained media into Source', (
    tester,
  ) async {
    final root = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('busymark-source-history-media-'),
    ))!;
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final sourceDirectory = Directory('${root.path}/source');
    final destinationDirectory = Directory('${root.path}/destination');
    await tester.runAsync(() async {
      await sourceDirectory.create();
      await destinationDirectory.create();
    });
    final sourcePath = '${sourceDirectory.path}/origin.md';
    final destinationPath = '${destinationDirectory.path}/target.md';
    final fragment = _structuredImageFragment(sourcePath);
    final registry = BusyMarkClipboardInsertionRegistry();
    addTearDown(registry.dispose);
    String? changed;
    await _pumpClipboardSourceEditor(
      tester,
      source: 'Target\n',
      clipboard: _SourceTestClipboard(),
      registry: registry,
      filePath: destinationPath,
      workspaceRoot: root.path,
      assetWorkspaceKind: AssetWorkspaceKind.markdownWorkspace,
      onChanged: (value, _) => changed = value,
    );
    final payload = BusyMarkClipboardPayload(
      id: 'source-rich-media',
      acquiredAt: DateTime.utc(2026),
      kind: BusyMarkClipboardContentKind.richText,
      text: 'Alt',
      sourceText: '![Alt](diagram.png)\n',
      richFragment: fragment.encode(),
      mediaBytes: {
        'diagram.png': Uint8List.fromList(
          utf8.encode(
            '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"/>',
          ),
        ),
      },
    );

    expect(
      await tester.runAsync(() => registry.paste(payload)),
      ClipboardPasteResult.inserted,
    );
    expect(changed, contains('![Alt](../images/diagram.svg)'));
    expect(
      await tester.runAsync(
        () => File('${root.path}/images/diagram.svg').exists(),
      ),
      isTrue,
    );
  });

  testWidgets('structured history restores a local video into Source', (
    tester,
  ) async {
    final root = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('busymark-source-history-video-'),
    ))!;
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final destinationPath = '${root.path}/target.md';
    final fragment = _structuredVideoFragment('/original/topic.md');
    final registry = BusyMarkClipboardInsertionRegistry();
    addTearDown(registry.dispose);
    String? changed;
    await _pumpClipboardSourceEditor(
      tester,
      source: 'Target\n',
      clipboard: _SourceTestClipboard(),
      registry: registry,
      filePath: destinationPath,
      assetWorkspaceKind: AssetWorkspaceKind.standalone,
      onChanged: (value, _) => changed = value,
    );
    final video = Uint8List.fromList([
      0,
      0,
      0,
      20,
      ...ascii.encode('ftypmp42'),
      0,
      0,
      0,
      0,
    ]);
    final payload = BusyMarkClipboardPayload(
      id: 'source-rich-video',
      acquiredAt: DateTime.utc(2026),
      kind: BusyMarkClipboardContentKind.richText,
      text: 'Local clip',
      sourceText: '<video src="clip.mp4" title="Local clip"/>\n',
      richFragment: fragment.encode(),
      mediaBytes: {'clip.mp4': video},
    );

    expect(registry.canPaste(payload), isTrue);
    expect(
      await tester.runAsync(() => registry.paste(payload)),
      ClipboardPasteResult.inserted,
    );
    expect(changed, contains('<video src="images/clip.mp4"'));
    expect(
      await tester.runAsync(
        () => File('${root.path}/images/clip.mp4').readAsBytes(),
      ),
      video,
    );
  });

  testWidgets(
    'standalone image history ingests and inserts one undoable Source edit',
    (tester) async {
      final root = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('busymark-source-image-history-'),
      ))!;
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      final filePath = '${root.path}/target.md';
      final registry = BusyMarkClipboardInsertionRegistry();
      addTearDown(registry.dispose);
      const source = 'Before after';
      var transactionCount = 0;
      String modelText = source;
      TextEditingValue? undoValue;
      final controller = await _pumpClipboardSourceEditor(
        tester,
        source: source,
        clipboard: _SourceTestClipboard(),
        registry: registry,
        filePath: filePath,
        workspaceRoot: root.path,
        assetWorkspaceKind: AssetWorkspaceKind.markdownWorkspace,
        onTransactionalChanged:
            (value, _, previousSelection, selection, undoGroup) {
              transactionCount++;
              undoValue = TextEditingValue(
                text: modelText,
                selection: previousSelection,
              );
              modelText = value;
            },
        onUndo: () {
          final value = undoValue;
          if (value != null) {
            modelText = value.text;
            undoValue = null;
          }
          return value;
        },
      );
      controller.selection = const TextSelection.collapsed(offset: 7);
      final payload = BusyMarkClipboardPayload(
        id: 'source-image-history',
        acquiredAt: DateTime.utc(2026),
        kind: BusyMarkClipboardContentKind.image,
        imageBytes: Uint8List.fromList(const [
          0x89,
          0x50,
          0x4e,
          0x47,
          0x0d,
          0x0a,
          0x1a,
          0x0a,
        ]),
        imageMimeType: 'image/png',
        imageDisplayName: 'screenshot.png',
      );

      expect(registry.canPaste(payload), isTrue);
      expect(
        await tester.runAsync(() => registry.paste(payload)),
        ClipboardPasteResult.inserted,
      );
      expect(modelText, 'Before ![Image](images/screenshot.png)after');
      expect(transactionCount, 1);
      final asset = File('${root.path}/images/screenshot.png');
      expect(await tester.runAsync(asset.exists), isTrue);

      await _pressControlKey(tester, LogicalKeyboardKey.keyZ);
      await tester.pump();
      expect(controller.text, source);
      expect(modelText, source);
      expect(transactionCount, 1);
      expect(await tester.runAsync(asset.exists), isTrue);
    },
  );

  testWidgets('Source local image path retains imported bytes once', (
    tester,
  ) async {
    final root = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('busymark-source-path-image-'),
    ))!;
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final original = Uint8List.fromList(const [
      0x89,
      0x50,
      0x4e,
      0x47,
      0x0d,
      0x0a,
      0x1a,
      0x0a,
    ]);
    final sourceFile = File('${root.path}/original.png');
    await tester.runAsync(() => sourceFile.writeAsBytes(original));
    final clipboard = _SourceTestClipboard(
      readData: RichClipboardData(text: sourceFile.path, generation: 42),
    );
    final captures = <BusyMarkClipboardCapture>[];
    final controller = await _pumpClipboardSourceEditor(
      tester,
      source: 'Target',
      clipboard: clipboard,
      onCaptured: captures.add,
      filePath: '${root.path}/target.md',
      assetWorkspaceKind: AssetWorkspaceKind.standalone,
    );
    controller.selection = const TextSelection.collapsed(offset: 6);

    await _pressControlKey(tester, LogicalKeyboardKey.keyV);
    await _pumpUntil(tester, () => captures.isNotEmpty);

    expect(controller.text, contains('![Image](images/original.png)'));
    expect(captures, hasLength(1));
    expect(captures.single.kind, BusyMarkClipboardContentKind.image);
    expect(captures.single.text, sourceFile.path);
    expect(captures.single.imageBytes, original);

    final capture = captures.single;
    final retained = BusyMarkClipboardPayload(
      id: 'source-retained-path-image',
      acquiredAt: DateTime.utc(2026),
      kind: capture.kind,
      text: capture.text,
      sourceText: capture.sourceText,
      html: capture.html,
      richFragment: capture.richFragment,
      imageBytes: capture.imageBytes,
      imageMimeType: capture.imageMimeType,
      imageDisplayName: capture.imageDisplayName,
      origin: capture.origin,
      mediaBytes: capture.mediaBytes,
      mediaComplete: capture.mediaComplete,
      external: true,
    );
    final registry = BusyMarkClipboardInsertionRegistry();
    addTearDown(registry.dispose);
    final replacement = Uint8List.fromList(original);
    replacement[replacement.length - 1] ^= 0xff;
    await tester.runAsync(() => sourceFile.writeAsBytes(replacement));

    Future<void> expectNormalReplay(String directoryName) async {
      final directory = Directory('${root.path}/$directoryName');
      await tester.runAsync(directory.create);
      await _pumpClipboardSourceEditor(
        tester,
        source: 'Target',
        clipboard: _SourceTestClipboard(),
        registry: registry,
        filePath: '${directory.path}/target.md',
        assetWorkspaceKind: AssetWorkspaceKind.standalone,
      );
      expect(
        await tester.runAsync(() => registry.paste(retained)),
        ClipboardPasteResult.inserted,
      );
      expect(
        await tester.runAsync(
          () => File('${directory.path}/images/original.png').readAsBytes(),
        ),
        original,
      );
    }

    await expectNormalReplay('modified-replay');
    await tester.runAsync(sourceFile.delete);
    await expectNormalReplay('deleted-replay');

    final plainDirectory = Directory('${root.path}/plain-replay');
    await tester.runAsync(plainDirectory.create);
    final plain = await _pumpClipboardSourceEditor(
      tester,
      source: 'Target',
      clipboard: _SourceTestClipboard(),
      registry: registry,
      filePath: '${plainDirectory.path}/target.md',
      assetWorkspaceKind: AssetWorkspaceKind.standalone,
    );
    plain.selection = const TextSelection(baseOffset: 0, extentOffset: 6);
    expect(
      await registry.paste(retained, mode: BusyMarkPasteMode.plainText),
      ClipboardPasteResult.inserted,
    );
    expect(plain.text, sourceFile.path);
    expect(
      await tester.runAsync(
        () => Directory('${plainDirectory.path}/images').exists(),
      ),
      isFalse,
    );
  });

  testWidgets('unsafe local image candidates paste their original text', (
    tester,
  ) async {
    final root = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('busymark-source-path-fallback-'),
    ))!;
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final image = File('${root.path}/image.png');
    final invalidImage = File('${root.path}/invalid.png');
    final textFile = File('${root.path}/notes.txt');
    await tester.runAsync(() async {
      await image.writeAsBytes(const [0x89, 0x50, 0x4e, 0x47]);
      await invalidImage.writeAsString('not an image');
      await textFile.writeAsString('notes');
    });
    final clipboard = _SourceTestClipboard();
    final values = [
      '  ${root.path}/missing.png  ',
      invalidImage.path,
      textFile.path,
      '${image.uri}?download=1',
      '${image.uri}#preview',
      'file://remote-host${image.uri.path}',
    ];
    for (final value in values) {
      clipboard.readData = RichClipboardData(text: value);
      final controller = await _pumpClipboardSourceEditor(
        tester,
        source: 'Target',
        clipboard: clipboard,
        filePath: '${root.path}/target.md',
        assetWorkspaceKind: AssetWorkspaceKind.standalone,
      );
      controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 6,
      );

      await _pressControlKey(tester, LogicalKeyboardKey.keyV);
      await _pumpUntil(tester, () => controller.text != 'Target');

      expect(controller.text, value, reason: value);
    }
  });

  testWidgets('image history asks to save an untitled Source document', (
    tester,
  ) async {
    final registry = BusyMarkClipboardInsertionRegistry();
    addTearDown(registry.dispose);
    var saveRequests = 0;
    var changes = 0;
    await _pumpClipboardSourceEditor(
      tester,
      source: 'Untitled',
      clipboard: _SourceTestClipboard(),
      registry: registry,
      filePath: null,
      onChanged: (_, _) => changes++,
      onAssetSaveRequired: () => saveRequests++,
    );
    final payload = BusyMarkClipboardPayload(
      id: 'untitled-source-image-history',
      acquiredAt: DateTime.utc(2026),
      kind: BusyMarkClipboardContentKind.image,
      imageBytes: Uint8List.fromList(const [
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
      ]),
      imageMimeType: 'image/png',
      imageDisplayName: 'screenshot.png',
    );

    expect(registry.canPaste(payload), isTrue);
    expect(
      await tester.runAsync(() => registry.paste(payload)),
      ClipboardPasteResult.unsupported,
    );
    expect(saveRequests, 1);
    expect(changes, 0);
  });

  testWidgets('generic XML does not invent Writerside image syntax', (
    tester,
  ) async {
    final registry = BusyMarkClipboardInsertionRegistry();
    addTearDown(registry.dispose);
    final controller = await _pumpClipboardSourceEditor(
      tester,
      source: '<root/>',
      clipboard: _SourceTestClipboard(),
      registry: registry,
      documentFormat: SourceDocumentFormat.genericXml,
    );
    final payload = BusyMarkClipboardPayload(
      id: 'generic-xml-image',
      acquiredAt: DateTime.utc(2026),
      kind: BusyMarkClipboardContentKind.image,
      imageBytes: Uint8List.fromList(const [
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
      ]),
      imageDisplayName: 'image.png',
    );

    expect(registry.canPaste(payload), isFalse);
    expect(await registry.paste(payload), ClipboardPasteResult.unavailable);
    expect(controller.text, '<root/>');
  });
}

WysiwygClipboardFragment _completeSourceFragment(
  String source, {
  MarkdownMode mode = MarkdownMode.commonMark,
}) {
  final document = const MarkdownParser()
      .parse(
        filePath: '/clipboard/source.md',
        source: source,
        mode: mode,
        validateLocalReferences: false,
      )
      .busyDocument;
  return WysiwygClipboardFragment(
    sourcePath: document.filePath,
    mode: document.mode,
    blocks: [
      for (final block in document.blocks)
        BusyWysiwygStyledBlock(
          kind: block.kind,
          text: block.plainText,
          ranges: busyInlineStyleRanges(block.inlines),
          attributes: block.attributes,
          completeBlock: busyMarkWysiwygImmutableBlockSnapshot(block),
        ),
    ],
  );
}

List<List<md.Element>> _markdownElementPaths(
  Iterable<md.Node> nodes,
  String targetTag, [
  List<md.Element> ancestors = const [],
]) {
  final paths = <List<md.Element>>[];
  for (final node in nodes) {
    if (node is! md.Element) continue;
    final path = [...ancestors, node];
    if (node.tag == targetTag) paths.add(path);
    paths.addAll(
      _markdownElementPaths(node.children ?? const [], targetTag, path),
    );
  }
  return paths;
}

List<({String text, String context})> _inlineSemanticRuns(
  List<BusyInline> inlines,
) {
  final runs = <({String text, String context})>[];
  void append(String text, Iterable<String> contexts) {
    if (text.isEmpty) return;
    final context = (contexts.toSet().toList()..sort()).join('|');
    if (runs.isNotEmpty && runs.last.context == context) {
      final previous = runs.removeLast();
      runs.add((text: previous.text + text, context: context));
    } else {
      runs.add((text: text, context: context));
    }
  }

  void visit(BusyInline inline, List<String> inherited) {
    final own = switch (inline.kind) {
      BusyInlineKind.strong => 'strong',
      BusyInlineKind.emphasis => 'emphasis',
      BusyInlineKind.underline => 'underline',
      BusyInlineKind.strikethrough => 'strikethrough',
      BusyInlineKind.link => 'link:${inline.destination}:${inline.attributes}',
      _ => null,
    };
    final contexts = own == null ? inherited : [...inherited, own];
    if (inline.children.isEmpty) {
      append(inline.plainText, contexts);
      return;
    }
    for (final child in inline.children) {
      visit(child, contexts);
    }
  }

  for (final inline in inlines) {
    visit(inline, const []);
  }
  return runs;
}

List<List<BusyBlockKind>> _busyBlockKindPaths(
  Iterable<BusyBlock> blocks,
  BusyBlockKind target, [
  List<BusyBlockKind> ancestors = const [],
]) {
  final paths = <List<BusyBlockKind>>[];
  for (final block in blocks) {
    final path = [...ancestors, block.kind];
    if (block.kind == target) paths.add(path);
    paths.addAll(_busyBlockKindPaths(block.children, target, path));
  }
  return paths;
}

Iterable<BusyBlock> _sourceBlocksDepthFirst(Iterable<BusyBlock> blocks) sync* {
  for (final block in blocks) {
    yield block;
    yield* _sourceBlocksDepthFirst(block.children);
  }
}

WysiwygClipboardFragment _structuredImageFragment(String sourcePath) {
  const parser = MarkdownParser();
  final document = parser
      .parse(
        filePath: sourcePath,
        source: '![Alt](diagram.png)\n',
        mode: MarkdownMode.writersideMarkdown,
      )
      .busyDocument;
  final block = document.blocks.single;
  return WysiwygClipboardFragment(
    sourcePath: sourcePath,
    mode: document.mode,
    mediaPaths: const {'diagram.png': '/original/assets/diagram.png'},
    blocks: [
      BusyWysiwygStyledBlock(
        kind: block.kind,
        text: block.plainText,
        ranges: busyInlineStyleRanges(block.inlines),
        attributes: block.attributes,
        completeBlock: busyMarkWysiwygImmutableBlockSnapshot(block),
      ),
    ],
  );
}

WysiwygClipboardFragment _structuredVideoFragment(String sourcePath) {
  const parser = MarkdownParser();
  final document = parser
      .parse(
        filePath: sourcePath,
        source: '<video src="clip.mp4" title="Local clip"/>\n',
        mode: MarkdownMode.writersideMarkdown,
      )
      .busyDocument;
  final block = document.blocks.single;
  return WysiwygClipboardFragment(
    sourcePath: sourcePath,
    mode: document.mode,
    mediaPaths: const {'clip.mp4': '/original/assets/clip.mp4'},
    blocks: [
      BusyWysiwygStyledBlock(
        kind: block.kind,
        text: block.plainText,
        ranges: busyInlineStyleRanges(block.inlines),
        attributes: block.attributes,
        completeBlock: busyMarkWysiwygImmutableBlockSnapshot(block),
      ),
    ],
  );
}

const _autocompleteSource = '<topic><p>fea';

Future<TextEditingController> _pumpAutocompleteSourceEditor(
  WidgetTester tester, {
  BusyMarkSourceChanged? onChanged,
  void Function(SourceSymbolAction action, int offset)? onSymbolAction,
}) async {
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
            onSymbolAction: onSymbolAction,
            text: _autocompleteSource,
            language: SourceSyntaxLanguage.xml,
            filePath: '/project/topics/current.topic',
            diagnostics: const [],
            editorFontSize: 14,
            wordWrap: true,
            searchActive: false,
            searchOptions: const SourceSearchOptions(),
            onSearchOptionsChanged: (_) {},
            onChanged: onChanged ?? (_, _) {},
            onOpenSearch: () {},
            onCloseSearch: () {},
            initialSelection: const TextSelection.collapsed(
              offset: _autocompleteSource.length,
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
  final fieldFinder = find.byType(TextField);
  await tester.tap(fieldFinder);
  await tester.showKeyboard(fieldFinder);
  return tester.widget<TextField>(fieldFinder).controller!;
}

Future<void> _pressControlSpace(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.space);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();
}

Future<TextEditingController> _pumpClipboardSourceEditor(
  WidgetTester tester, {
  required String source,
  required _SourceTestClipboard clipboard,
  BusyMarkClipboardInsertionRegistry? registry,
  ValueChanged<BusyMarkClipboardCapture>? onCaptured,
  BusyMarkSourceChanged? onChanged,
  BusyMarkSourceTransactionalChanged? onTransactionalChanged,
  TextEditingValue? Function()? onUndo,
  TextEditingValue? Function()? onRedo,
  String? filePath = '/project/source.md',
  String? workspaceRoot,
  AssetWorkspaceKind? assetWorkspaceKind,
  SourceDocumentFormat documentFormat = SourceDocumentFormat.markdown,
  MarkdownMode markdownMode = MarkdownMode.commonMark,
  AssetInputService? assetInputService,
  VoidCallback? onAssetSaveRequired,
}) async {
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
            documentFormat: documentFormat,
            markdownMode: markdownMode,
            filePath: filePath,
            documentId: 'source-document',
            workspaceRoot: workspaceRoot,
            assetWorkspaceKind: assetWorkspaceKind,
            assetInputService: assetInputService,
            diagnostics: const [],
            editorFontSize: 14,
            wordWrap: true,
            searchActive: false,
            searchOptions: const SourceSearchOptions(),
            onSearchOptionsChanged: (_) {},
            onChanged: onChanged ?? (_, _) {},
            onTransactionalChanged: onTransactionalChanged,
            onUndo: onUndo,
            onRedo: onRedo,
            onOpenSearch: () {},
            onCloseSearch: () {},
            clipboardService: clipboard,
            clipboardInsertionRegistry: registry,
            onClipboardCaptured: onCaptured,
            onAssetSaveRequired: onAssetSaveRequired,
          ),
        ),
      ),
    ),
  );
  final field = find.byType(TextField);
  await tester.tap(field);
  await tester.showKeyboard(field);
  return tester.widget<TextField>(field).controller!;
}

Future<void> _pressControlKey(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool shift = false,
}) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(key);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
}

bool _sourceContainsLoneLf(String value) {
  for (var index = 0; index < value.length; index++) {
    if (value.codeUnitAt(index) == 0x0a &&
        (index == 0 || value.codeUnitAt(index - 1) != 0x0d)) {
      return true;
    }
  }
  return false;
}

class _SourceTestClipboard extends RichClipboardService {
  _SourceTestClipboard({
    this.writeResult = true,
    this.delayWrite = false,
    this.readData = const RichClipboardData(),
    this.delayRead = false,
  }) : super(channel: const MethodChannel('busymark.test/source-clipboard'));

  final bool writeResult;
  final bool delayWrite;
  RichClipboardData readData;
  final bool delayRead;
  final writes = <RichClipboardData>[];
  int reads = 0;
  final writeStarted = Completer<void>();
  final _writeRelease = Completer<void>();
  final readStarted = Completer<void>();
  final _readRelease = Completer<void>();

  void releaseWrite() {
    if (!_writeRelease.isCompleted) _writeRelease.complete();
  }

  void releaseRead() {
    if (!_readRelease.isCompleted) _readRelease.complete();
  }

  @override
  Future<RichClipboardData> read() async {
    reads++;
    if (!readStarted.isCompleted) readStarted.complete();
    if (delayRead) await _readRelease.future;
    return readData;
  }

  @override
  Future<bool> write(RichClipboardData data) async {
    writes.add(data);
    if (!writeStarted.isCompleted) writeStarted.complete();
    if (delayWrite) await _writeRelease.future;
    return writeResult;
  }
}

String? _nativeShortcut(List<Map<Object?, Object?>> entries, String label) {
  return entries.singleWhere((entry) => entry['label'] == label)['shortcut']
      as String?;
}

String? _nativeIcon(List<Map<Object?, Object?>> entries, String label) {
  return entries.singleWhere((entry) => entry['label'] == label)['icon']
      as String?;
}

int _nativeMenuIndexForLabel(
  List<Map<Object?, Object?>> entries,
  String label,
) {
  var index = 0;
  int? visit(List<Map<Object?, Object?>> items) {
    for (final item in items) {
      final current = index++;
      if (item['label'] == label) return current;
      final children = item['children'];
      if (children is List<Object?>) {
        final found = visit(children.cast<Map<Object?, Object?>>());
        if (found != null) return found;
      }
    }
    return null;
  }

  return visit(entries) ?? -1;
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

SpellingOccurrence _sourceSpellingOccurrence({
  required String word,
  required int sourceStart,
  required int sourceEnd,
  required String filePath,
}) {
  final run = SpellingProseRun(
    id: 'source-fold-$sourceStart',
    text: word,
    languageId: 'en-Test',
    atoms: [
      SpellingSourceAtom(
        logicalText: word,
        logicalStart: 0,
        logicalEnd: word.length,
        sourceStart: sourceStart,
        sourceEnd: sourceEnd,
        transformation: SpellingTransformationKind.identity,
        context: SpellingSourceContext.markdownProse,
      ),
    ],
    target: SpellingSourceTarget(filePath: filePath),
    snapshot: SpellingSnapshotIdentity(
      bufferId: filePath,
      contentRevision: 0,
      documentKind: DocumentKind.markdown,
      contextGeneration: 1,
    ),
  );
  return SpellingOccurrence(
    id: 'source-fold-occurrence-$sourceStart',
    run: run,
    logicalStart: 0,
    logicalEnd: word.length,
    word: word,
    outcome: SpellingCheckOutcome.rejected,
  );
}
