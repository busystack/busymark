import 'dart:io';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/ai/ai_models.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/platform/native_menu_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('WYSIWYG AI maps a nested Writerside block to its source block', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final source = File(
      'test/fixtures/markdown/writerside_markdown.md',
    ).readAsStringSync();
    final document = const MarkdownParser()
        .parse(
          filePath: 'writerside_markdown.md',
          source: source,
          mode: MarkdownMode.writersideMarkdown,
          validateLocalReferences: false,
        )
        .busyDocument;
    AiEditorSnapshot? captured;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildBusyMarkTheme(
            brightness: Brightness.dark,
            accentColor: BusyMarkLinuxPalette.blueAccent,
          ),
          home: Scaffold(
            body: BusyMarkWysiwygEditor(
              document: document,
              onSourceChanged: (_, _) {},
              onAiEdit: (snapshot) async {
                captured = snapshot;
                return null;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final nestedFieldFinder = find.widgetWithText(
      TextField,
      'Use %product% for docs. {style="note"}',
    );
    await tester.tap(nestedFieldFinder);
    final nestedField = tester.widget<TextField>(nestedFieldFinder);
    nestedField.focusNode!.requestFocus();
    nestedField.controller!.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 3,
    );
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyG);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyG);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.blockTargetAvailable, isTrue);
    expect(
      source.substring(captured!.selectionStart, captured!.selectionEnd),
      'Use',
    );
  });

  testWidgets(
    'WYSIWYG AI maps selected text when unsourced editor blocks exist',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const source = '# Guide\n\nRefine this sentence.\n';
      final parsed = const MarkdownParser()
          .parse(
            filePath: '/project/guide.md',
            source: source,
            mode: MarkdownMode.gfm,
            validateLocalReferences: false,
          )
          .busyDocument;
      final document = parsed.copyWith(
        blocks: [
          parsed.blocks.first,
          const BusyBlock(
            id: 'unsourced-empty-paragraph',
            kind: BusyBlockKind.paragraph,
            attributes: {busyMarkPreserveEmptyParagraphAttribute: 'true'},
            dirty: true,
          ),
          ...parsed.blocks.skip(1),
        ],
      );
      AiEditorSnapshot? captured;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BusyMarkWysiwygEditor(
              document: document,
              onSourceChanged: (_, _) {},
              onAiEdit: (snapshot) async {
                captured = snapshot;
                return null;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final paragraphFinder = find.widgetWithText(
        TextField,
        'Refine this sentence.',
      );
      await tester.tap(paragraphFinder);
      final paragraph = tester.widget<TextField>(paragraphFinder);
      paragraph.controller!.selection = const TextSelection(
        baseOffset: 7,
        extentOffset: 11,
      );
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyG);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyG);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(
        captured!.documentSource.substring(
          captured!.selectionStart,
          captured!.selectionEnd,
        ),
        'this',
      );
    },
  );

  testWidgets('WYSIWYG AI applies through canonical Markdown source', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const source = '# Guide\n\nThis is **unclear**\ntext.\n';
    final document = const MarkdownParser()
        .parse(
          filePath: '/project/guide.md',
          source: source,
          mode: MarkdownMode.gfm,
          validateLocalReferences: false,
        )
        .busyDocument;
    AiEditorSnapshot? captured;
    String? changedSource;
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
          body: BusyMarkWysiwygEditor(
            document: document,
            visualizationRevision: 5,
            onSourceChanged: (_, value) => changedSource = value,
            onAiEdit: (snapshot) async {
              captured = snapshot;
              return AiEditApplication(
                invocation: AiEditInvocation(
                  feature: AiFeature.editDocument,
                  scope: AiScope.markdownEdit,
                  input: source.substring(
                    snapshot.selectionStart,
                    snapshot.selectionEnd,
                  ),
                  replacementOriginal: 'text',
                  sourceRevision: snapshot.sourceRevision,
                  targetId: snapshot.targetId,
                  documentPath: snapshot.documentPath,
                  instruction: 'Make this clearer.',
                  editTarget: AiEditTargetKind.selection,
                  editContext: AiEditContextKind.selection,
                  documentSource: snapshot.documentSource,
                  replacementStart: snapshot.selectionStart,
                  replacementEnd: snapshot.selectionEnd,
                ),
                output: 'word',
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final paragraphFinder = find.widgetWithText(
      TextField,
      'This is unclear text.',
    );
    final paragraph = tester.widget<TextField>(paragraphFinder);
    await tester.tap(paragraphFinder);
    paragraph.controller!.selection = const TextSelection(
      baseOffset: 16,
      extentOffset: 20,
    );
    await tester.pump();
    final editableFinder = find.descendant(
      of: paragraphFinder,
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

    expect(paragraph.controller!.selection.isCollapsed, isFalse);
    expect(paragraph.contextMenuBuilder, isNotNull);
    expect(find.byTooltip('Edit with AI'), findsNothing);

    await tester.tap(paragraphFinder, buttons: kSecondaryMouseButton);
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

    expect(captured?.sourceRevision, 5);
    expect(
      source.substring(captured!.selectionStart, captured!.selectionEnd),
      'text',
    );
    expect(changedSource, '# Guide\n\nThis is **unclear**\nword.\n');
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
