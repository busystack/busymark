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

  test(
    'viewport pixel anchors round trip while older sessions remain readable',
    () {
      final old = WysiwygEditorSessionState.fromJson({
        'viewportBlockId': 'old',
        'viewportAlignment': 0.2,
      });
      expect(old.viewportOffset, 0);
      expect(old.viewportEditingOffset, isNull);
      const session = WysiwygEditorSessionState(
        activeBlockId: 'edit',
        viewportBlockId: 'reading',
        viewportOffset: 2300.25,
        viewportEditingOffset: -5000.5,
        viewportLayoutSignature: 'layout',
        sourceSignature: 'source',
        sourceBindings: {
          'reading': (start: 4, end: 9, kind: 'paragraph', tag: 'p'),
        },
      );
      final restored = WysiwygEditorSessionState.fromJson(session.toJson());
      expect(restored.toJson(), session.toJson());
      expect(restored.viewportOffset, 2300.25);
      expect(restored.viewportEditingOffset, -5000.5);
      expect(restored.sourceBindings, session.sourceBindings);
    },
  );

  testWidgets(
    'pinned non-list Markdown owner refreshes direct edits with authored positions',
    (tester) async {
      const original = '# Topic\n\n## Chapter A\n\nParagraph B.\n';
      var source = original;
      WritersideInspectorTarget? pinned;
      var revision = 0;
      await tester.pumpWidget(
        _app(
          BusyMarkWysiwygEditor(
            document: parser
                .parse(
                  filePath: 'one.md',
                  source: original,
                  mode: MarkdownMode.writersideMarkdown,
                )
                .busyDocument,
            documentId: 'same',
            onSourceChanged: (_, value) {
              source = value;
              revision++;
            },
            onInspectElement:
                (
                  document,
                  id,
                  inline,
                  explicit,
                  multiple, {
                  bool revisionRefresh = false,
                }) {
                  if (explicit) {
                    pinned = WritersideInspectorTarget.fromSelection(
                      bufferId: 'same',
                      revision: revision,
                      source: source,
                      document: document,
                      blockId: id,
                      inline: inline,
                    );
                  } else if (pinned != null) {
                    pinned =
                        pinned!.refreshUnchangedElement(
                          revision: revision,
                          source: source,
                          document: document,
                        ) ??
                        pinned;
                  }
                },
          ),
        ),
      );
      await tester.pumpAndSettle();
      Finder field(String text) => find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.controller is BusyMarkWysiwygTextController &&
            w.controller!.text == text,
      );
      await tester.tap(field('Chapter A'));
      tester
          .state<BusyMarkWysiwygEditorState>(find.byType(BusyMarkWysiwygEditor))
          .inspectCurrentSelection();
      await tester.pumpAndSettle();
      await tester.enterText(field('Paragraph B.'), 'Paragraph B. edited');
      await tester.pumpAndSettle();
      expect(pinned!.block!.plainText, 'Chapter A');
      expect(pinned!.matches('same', revision, source), isTrue);
      await tester.enterText(field('Chapter A'), 'Chapter A edited');
      await tester.pumpAndSettle();
      expect(pinned!.matches('same', revision, source), isTrue);
      expect(pinned!.block!.plainText, 'Chapter A edited');
      expect(pinned!.block!.attributes['id'], 'chapter-a-edited');
      expect(pinned!.sourceLocation, source.indexOf('## Chapter A edited'));
    },
  );

  for (final withList in [false, true]) {
    for (final style in ['Tip', 'Note', 'Warning', 'Quote']) {
      testWidgets(
        '$style Markdown caret survives workspace source reparse (list=$withList)',
        (tester) async {
          final original =
              '# Topic\n\n${withList ? "- Item\n\n" : ""}$style **example**.\n\nAfter.\n';
          BusyDocument parse(String source) => parser
              .parse(
                filePath: 'one.md',
                source: source,
                mode: MarkdownMode.writersideMarkdown,
              )
              .busyDocument;
          var session = const WysiwygEditorSessionState();
          var input = const WysiwygEditorSessionState();
          var revision = 0;
          var source = original;
          Widget editor(BusyDocument document) => _app(
            BusyMarkWysiwygEditor(
              document: document,
              documentId: 'same',
              contentRevision: revision,
              initialSessionState: input,
              useExternalUndoHistory: true,
              onSessionChanged: (_, value) => session = value,
              onSourceChanged: (_, value) => source = value,
            ),
          );
          Finder field() => find.byWidgetPredicate(
            (w) =>
                w is TextField &&
                w.controller is BusyMarkWysiwygTextController &&
                w.controller!.text == '$style example.',
          );
          await tester.pumpWidget(editor(parse(original)));
          await tester.pumpAndSettle();
          await tester.tap(field());
          tester.widget<TextField>(field()).controller!.selection =
              const TextSelection.collapsed(offset: 4);
          await tester.pumpAndSettle();
          final before = session;
          await tester.tap(find.byTooltip('Writerside'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Admonitions and quotes'));
          await tester.pumpAndSettle();
          await tester.tap(find.text(style));
          await tester.pumpAndSettle();
          final changed = source;
          final after = session;
          expect(changed, contains('> $style **example**.'));
          input = before;
          revision++;
          await tester.pumpWidget(editor(parse(original)));
          await tester.pumpAndSettle();
          expect(tester.widget<TextField>(field()).focusNode!.hasFocus, isTrue);
          input = after;
          revision++;
          await tester.pumpWidget(editor(parse(changed)));
          await tester.pumpAndSettle();
          expect(
            tester.widget<TextField>(field()).focusNode!.hasFocus,
            isTrue,
            reason: '${after.toJson()}',
          );
          expect(
            tester.widget<TextField>(field()).controller!.selection,
            const TextSelection.collapsed(offset: 4),
          );
        },
      );
    }
  }

  for (final xml in [false, true]) {
    testWidgets(
      '${xml ? "XML" : "Markdown"} caret session survives an exact reparse with new model IDs',
      (tester) async {
        final source = xml
            ? '<topic id="one" title="Topic"><p>First</p><p>Target</p><p>Third</p></topic>'
            : '# Topic\n\nFirst\n\nTarget\n\nThird\n';
        final parsed = xml
            ? const WritersideEditingAdapter().parseXml(
                filePath: 'one.topic',
                source: source,
              )!
            : parser
                  .parse(
                    filePath: 'one.md',
                    source: source,
                    mode: MarkdownMode.writersideMarkdown,
                  )
                  .busyDocument;
        Iterable<BusyBlock> walk(List<BusyBlock> blocks) sync* {
          for (final b in blocks) {
            yield b;
            yield* walk(b.children);
          }
        }

        final authored = walk(
          parsed.blocks,
        ).singleWhere((b) => b.plainText == 'Target');
        List<BusyBlock> remap(List<BusyBlock> blocks) => [
          for (final b in blocks)
            b.plainText == 'Target'
                ? b.copyWith(id: 'editing-child')
                : b.copyWith(children: remap(b.children)),
        ];
        final original = parsed.copyWith(blocks: remap(parsed.blocks));
        var session = const WysiwygEditorSessionState();
        Widget editor(BusyDocument document) => _app(
          BusyMarkWysiwygEditor(
            document: document,
            documentId: 'same-buffer',
            initialSessionState: session,
            onSessionChanged: (_, value) => session = value,
            onSourceChanged: (_, _) =>
                fail('Caret restoration must not edit source'),
          ),
        );
        await tester.pumpWidget(editor(original));
        await tester.pumpAndSettle();
        Finder target() => find.byWidgetPredicate(
          (w) => w is TextField && w.controller?.text == 'Target',
        );
        await tester.tap(target());
        tester.widget<TextField>(target()).controller!.selection =
            const TextSelection.collapsed(offset: 3);
        await tester.pumpAndSettle();
        expect(session.activeBlockId, 'editing-child');
        expect(session.sourceBindings['editing-child'], (
          start: authored.sourceSpan!.startOffset,
          end: authored.sourceSpan!.endOffset,
          kind: 'paragraph',
          tag: 'p',
        ));
        final restored = WysiwygEditorSessionState.fromJson(session.toJson());
        expect(restored.sourceSignature, session.sourceSignature);
        expect(restored.sourceBindings, session.sourceBindings);
        await tester.pumpWidget(const SizedBox.shrink());
        session = restored;
        await tester.pumpWidget(editor(parsed));
        await tester.pumpAndSettle();
        final field = tester.widget<TextField>(target());
        expect(field.focusNode!.hasFocus, isTrue);
        expect(
          field.controller!.selection,
          const TextSelection.collapsed(offset: 3),
        );
        expect(session.activeBlockId, authored.id);
      },
    );
  }

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
