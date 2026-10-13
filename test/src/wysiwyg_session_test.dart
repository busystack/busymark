import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_session_state.dart';
import 'package:busymark/src/editor/wysiwyg/writerside_editing_adapter.dart';
import 'package:busymark/src/editor/wysiwyg/writerside_inspector_target.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_inline_controller.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _sessionReportProvider = NotifierProvider<_SessionReportNotifier, int>(
  _SessionReportNotifier.new,
);

class _SessionReportNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void record() => state += 1;
}

void main() {
  const parser = MarkdownParser();

  for (final xml in [false, true]) {
    testWidgets(
      '${xml ? "XML" : "Markdown"} revision refresh publishes restored anchor and enum state at the unchanged caret',
      (tester) async {
        String source(int state) {
          final attrs = state == 0
              ? ''
              : ' id="explicit"${state == 2 ? ' collapsible="true"' : ''}';
          return xml
              ? '<topic id="one" title="Topic"><chapter title="Heading"$attrs><p>Body</p></chapter></topic>'
              : '# Topic\n\n## Heading${attrs.isEmpty ? '' : ' {${attrs.trim()}}'}\n\nBody\n';
        }

        BusyDocument parse(String text) => xml
            ? const WritersideEditingAdapter().parseXml(
                filePath: 'one.topic',
                source: text,
              )!
            : parser
                  .parse(
                    filePath: 'one.md',
                    source: text,
                    mode: MarkdownMode.writersideMarkdown,
                  )
                  .busyDocument;
        BusyBlock heading(BusyDocument d) => xml
            ? d.blocks.first.children.firstWhere(
                (b) => b.kind == BusyBlockKind.heading,
              )
            : d.blocks.firstWhere((b) => b.plainText == 'Heading');
        var revision = 0;
        var document = parse(source(0));
        final id = heading(document).id;
        var session = WysiwygEditorSessionState(
          activeBlockId: id,
          anchorBlockId: id,
          extentBlockId: id,
          anchorOffset: 4,
          extentOffset: 4,
        );
        final snapshots = <WritersideInspectorTarget>[];
        final refreshes = <bool>[];
        var opened = 0;
        Widget editor() => _app(
          BusyMarkWysiwygEditor(
            document: document,
            documentId: 'same-buffer',
            contentRevision: revision,
            initialSessionState: session,
            onSessionChanged: (_, restored) => session = restored,
            onSourceChanged: (_, _) => fail('Inspection must not edit source'),
            onPropertiesRequested: () => opened++,
            onInspectElement:
                (
                  model,
                  blockId,
                  inline,
                  explicit,
                  multiple, {
                  bool revisionRefresh = false,
                }) {
                  expect(session.activeBlockId, id);
                  expect(session.anchorOffset, 4);
                  expect(session.extentOffset, 4);
                  snapshots.add(
                    WritersideInspectorTarget.fromSelection(
                      bufferId: 'same-buffer',
                      revision: revision,
                      source: document.source!,
                      document: model,
                      blockId: blockId,
                      inline: inline,
                      multiple: multiple,
                    ),
                  );
                  refreshes.add(revisionRefresh);
                },
          ),
        );
        await tester.pumpWidget(editor());
        await tester.pumpAndSettle();
        expect(snapshots.last.matches('same-buffer', 0, source(0)), isTrue);
        // Add, Undo, Redo, reset, Undo, Redo, enum change, Undo, Redo.
        for (final state in [1, 0, 1, 0, 1, 0, 2, 1, 2]) {
          document = parse(source(state));
          revision++;
          final before = snapshots.length;
          await tester.pumpWidget(editor());
          await tester.pumpAndSettle();
          expect(snapshots.length, greaterThan(before));
          final target = snapshots.last;
          expect(
            target.matches('same-buffer', revision, source(state)),
            isTrue,
          );
          expect(target.block?.plainText, 'Heading');
          expect(
            target.block?.attributes['id'],
            state == 0 ? (xml ? null : 'heading') : 'explicit',
          );
          expect(target.block?.attributes['generatedId'] == 'true', state == 0);
          expect(
            target.block?.attributes['collapsible'],
            state == 2 ? 'true' : null,
          );
          expect(refreshes.last, isTrue);
          final field = tester.widget<TextField>(
            find.byWidgetPredicate(
              (w) =>
                  w is TextField &&
                  w.controller is BusyMarkWysiwygTextController &&
                  w.controller!.text == 'Heading',
            ),
          );
          expect(
            field.controller!.selection,
            const TextSelection.collapsed(offset: 4),
          );
        }
        // A new authoritative revision also matters when the source is equal.
        revision++;
        final before = snapshots.length;
        await tester.pumpWidget(editor());
        await tester.pumpAndSettle();
        expect(snapshots.length, greaterThan(before));
        expect(snapshots.last.revision, revision);
        expect(refreshes.last, isTrue);
        final stable = snapshots.length;
        await tester.pumpWidget(editor());
        await tester.pumpAndSettle();
        expect(snapshots.length, stable);
        expect(opened, 0);
      },
    );
  }
  testWidgets('obsolete restore frames cannot publish an intermediate model', (
    tester,
  ) async {
    var revision = 0;
    var document = parser
        .parse(filePath: 'one.md', source: 'Heading\n')
        .busyDocument;
    final id = document.blocks.first.id;
    const selection = TextSelection.collapsed(offset: 3);
    final sources = <String>[];
    Widget editor() => _app(
      BusyMarkWysiwygEditor(
        document: document,
        documentId: 'same',
        contentRevision: revision,
        initialSessionState: WysiwygEditorSessionState(
          activeBlockId: id,
          anchorBlockId: id,
          extentBlockId: id,
          anchorOffset: 3,
          extentOffset: 3,
        ),
        onSourceChanged: (_, _) {},
        onInspectElement: (model, _, _, _, _, {bool revisionRefresh = false}) =>
            sources.add(model.source!),
      ),
    );
    await tester.pumpWidget(editor());
    await tester.pumpAndSettle();
    sources.clear();
    document = parser
        .parse(filePath: 'one.md', source: 'Intermediate\n')
        .busyDocument;
    revision++;
    await tester.pumpWidget(editor());
    document = parser
        .parse(filePath: 'one.md', source: 'Latest\n')
        .busyDocument;
    revision++;
    await tester.pumpWidget(editor());
    await tester.pumpAndSettle();
    expect(sources, isNotEmpty);
    expect(sources.every((s) => s == 'Latest\n'), isTrue);
    expect(
      tester
          .widget<TextField>(find.byType(TextField).first)
          .controller!
          .selection,
      selection,
    );
  });

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

  testWidgets('defers session provider updates until document rebuild ends', (
    tester,
  ) async {
    final populated = parser
        .parse(filePath: 'topic.md', source: '# Topic\n\nContent\n')
        .busyDocument;
    final empty = parser.parse(filePath: 'topic.md', source: '').busyDocument;

    Widget editor(String id, BusyDocument document) => ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          ref.watch(_sessionReportProvider);
          return _app(
            BusyMarkWysiwygEditor(
              document: document,
              documentId: id,
              onSessionChanged: (_, _) =>
                  ref.read(_sessionReportProvider.notifier).record(),
              onSourceChanged: (_, _) {},
            ),
          );
        },
      ),
    );

    await tester.pumpWidget(editor('populated', populated));
    await tester.pump();
    await tester.pumpWidget(editor('empty', empty));
    await tester.pump();

    expect(tester.takeException(), isNull);
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
