import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/core/diagnostic.dart';
import 'package:busymark/src/editor/source/source_editor.dart';
import 'package:busymark/src/editor/source/source_search.dart';
import 'package:busymark/src/editor/source_language.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_session_state.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/spellcheck/markdown_spelling_projection.dart';
import 'package:busymark/src/spellcheck/spelling_coordinator.dart';
import 'package:busymark/src/spellcheck/spelling_projection.dart';
import 'package:busymark/src/spellcheck/wysiwyg_spelling_projection.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _sourceSnapshot = SpellingSnapshotIdentity(
  bufferId: 'source-buffer',
  contentRevision: 7,
  documentKind: DocumentKind.markdown,
  contextGeneration: 2,
);

void main() {
  testWidgets('source spelling correction is one exact transaction', (
    tester,
  ) async {
    const source = 'mispelled and mispelled\n';
    final projection = const MarkdownSpellingProjector().project(
      filePath: '/tmp/spelling.md',
      source: source,
      mode: MarkdownMode.commonMark,
      languageId: 'en-Test',
      snapshot: _sourceSnapshot,
    );
    final occurrence = _occurrence(
      projection.runs.single,
      word: 'mispelled',
      logicalStart: 0,
    );
    final key = GlobalKey<BusyMarkSourceEditorState>();
    final transactions =
        <
          ({
            String text,
            TextSelection before,
            TextSelection after,
            String? group,
          })
        >[];

    await tester.pumpWidget(
      _testApp(
        BusyMarkSourceEditor(
          key: key,
          text: source,
          language: SourceSyntaxLanguage.markdown,
          filePath: '/tmp/spelling.md',
          documentId: 'source-buffer',
          diagnostics: const <Diagnostic>[],
          editorFontSize: 14,
          wordWrap: true,
          searchActive: false,
          searchOptions: const SourceSearchOptions(),
          onSearchOptionsChanged: (_) {},
          onChanged: (_, _) {},
          onTransactionalChanged: (text, _, before, after, group) {
            transactions.add((
              text: text,
              before: before,
              after: after,
              group: group,
            ));
          },
          onOpenSearch: () {},
          onCloseSearch: () {},
          editRevision: 7,
          initialSelection: const TextSelection(baseOffset: 0, extentOffset: 9),
          spellingAnnotations: [_annotation(occurrence)],
        ),
      ),
    );
    await tester.pump();

    expect(
      key.currentState!.applySpellingCorrection(
        occurrence: occurrence,
        suggestion: 'misspelled',
      ),
      isTrue,
    );
    await tester.pump();

    expect(transactions, hasLength(1));
    expect(transactions.single.text, 'misspelled and mispelled\n');
    expect(
      transactions.single.before,
      const TextSelection(baseOffset: 0, extentOffset: 9),
    );
    expect(
      transactions.single.after,
      const TextSelection.collapsed(offset: 10),
    );
    expect(transactions.single.group, isNull);
  });

  testWidgets(
    'formatted rich correction preserves structure and publishes once',
    (tester) async {
      const source = '**mispelled**\n';
      final document = const MarkdownParser()
          .parse(
            filePath: '/tmp/formatted.md',
            source: source,
            mode: MarkdownMode.commonMark,
            validateLocalReferences: false,
          )
          .busyDocument;
      const snapshot = SpellingSnapshotIdentity(
        bufferId: 'formatted-buffer',
        contentRevision: 3,
        documentKind: DocumentKind.markdown,
        contextGeneration: 2,
      );
      final projection = const WysiwygSpellingProjector().project(
        document: document,
        languageId: 'en-Test',
        snapshot: snapshot,
        documentGeneration: 0,
      );
      expect(projection.complete, isTrue, reason: projection.message);
      final run = projection.runs.singleWhere(
        (candidate) => candidate.text == 'mispelled',
      );
      final occurrence = _occurrence(run, word: 'mispelled', logicalStart: 0);
      final key = GlobalKey<BusyMarkWysiwygEditorState>();
      final sources = <String>[];
      BusyDocument? updatedDocument;

      await tester.pumpWidget(
        _testApp(
          BusyMarkWysiwygEditor(
            key: key,
            document: document,
            documentId: 'formatted-buffer',
            contentRevision: 3,
            useExternalUndoHistory: true,
            spellingAnnotations: [_annotation(occurrence)],
            onDocumentChanged: (value) => updatedDocument = value,
            onSourceChanged: (_, _) {},
            onSpellingSourceChanged: (_, value, _, _) => sources.add(value),
          ),
        ),
      );
      await tester.pump();

      expect(
        key.currentState!.applySpellingCorrection(
          occurrence: occurrence,
          suggestion: 'misspelled',
        ),
        isTrue,
      );
      await tester.pump();

      expect(sources, ['**misspelled**\n']);
      expect(updatedDocument, isNotNull);
      expect(
        updatedDocument!.blocks.single.inlines.single.kind,
        BusyInlineKind.strong,
      );
      expect(updatedDocument!.blocks.single.plainText, 'misspelled');
    },
  );

  testWidgets(
    'rich table-cell correction preserves link and publishes sessions once',
    (tester) async {
      const source =
          '| Heading |\n'
          '| --- |\n'
          '| [mispelled](target) |\n';
      final document = const MarkdownParser()
          .parse(
            filePath: '/tmp/table.md',
            source: source,
            mode: MarkdownMode.commonMark,
          )
          .busyDocument;
      const snapshot = SpellingSnapshotIdentity(
        bufferId: 'rich-buffer',
        contentRevision: 11,
        documentKind: DocumentKind.markdown,
        contextGeneration: 4,
      );
      final projection = const WysiwygSpellingProjector().project(
        document: document,
        languageId: 'en-Test',
        snapshot: snapshot,
        documentGeneration: 0,
      );
      expect(
        projection.complete,
        isTrue,
        reason:
            '${projection.message}; ${projection.runs.map((run) => '${run.target.runtimeType}:${run.text}:${run.atoms.map((atom) => '${atom.context.name}/${atom.sourceStart}/${atom.fieldStart}').join(',')}').join(' | ')}',
      );
      final run = projection.runs.singleWhere(
        (candidate) => candidate.text == 'mispelled',
      );
      expect(run.atoms.every((atom) => atom.sourceStart >= 0), isTrue);
      final occurrence = _occurrence(run, word: 'mispelled', logicalStart: 0);
      final target = run.target as SpellingRichTableCellTarget;
      final key = GlobalKey<BusyMarkWysiwygEditorState>();
      final publicationOrder = <String>[];
      final spellingTransactions =
          <
            ({
              String source,
              WysiwygEditorSessionState before,
              WysiwygEditorSessionState after,
            })
          >[];
      var genericSourceChanges = 0;

      await tester.pumpWidget(
        _testApp(
          BusyMarkWysiwygEditor(
            key: key,
            document: document,
            documentId: 'rich-buffer',
            contentRevision: 11,
            useExternalUndoHistory: true,
            spellingAnnotations: [_annotation(occurrence)],
            onDocumentChanged: (_) => publicationOrder.add('document'),
            onSourceChanged: (_, _) => genericSourceChanges++,
            onSpellingSourceChanged: (_, source, before, after) {
              publicationOrder.add('spelling');
              spellingTransactions.add((
                source: source,
                before: before,
                after: after,
              ));
            },
          ),
        ),
      );
      await tester.pump();
      final field = tester.widget<TextField>(
        find.byKey(ValueKey(target.cellId)),
      );
      field.focusNode!.requestFocus();
      field.controller!.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 9,
      );
      await tester.pump();

      expect(
        key.currentState!.applySpellingCorrection(
          occurrence: occurrence,
          suggestion: 'misspelled',
        ),
        isTrue,
      );
      await tester.pump();

      expect(publicationOrder, ['document', 'spelling']);
      expect(genericSourceChanges, 0);
      expect(spellingTransactions, hasLength(1));
      expect(
        spellingTransactions.single.source,
        contains('[misspelled](target)'),
      );
      expect(spellingTransactions.single.before.activeCellId, target.cellId);
      expect(spellingTransactions.single.before.extentOffset, 9);
      expect(spellingTransactions.single.after.activeCellId, target.cellId);
      expect(spellingTransactions.single.after.extentOffset, 10);
      expect(
        tester
            .widget<TextField>(find.byKey(ValueKey(target.cellId)))
            .controller!
            .text,
        'misspelled',
      );
    },
  );
}

SpellingOccurrence _occurrence(
  SpellingProseRun run, {
  required String word,
  required int logicalStart,
}) => SpellingOccurrence(
  id: '${run.id}:$logicalStart',
  run: run,
  logicalStart: logicalStart,
  logicalEnd: logicalStart + word.length,
  word: word,
  outcome: SpellingCheckOutcome.rejected,
);

SpellingAnnotation _annotation(SpellingOccurrence occurrence) =>
    SpellingAnnotation(
      occurrenceId: occurrence.id,
      start: occurrence.run.target is SpellingSourceTarget
          ? occurrence.sourceStart!
          : occurrence.fieldStart!,
      end: occurrence.run.target is SpellingSourceTarget
          ? occurrence.sourceEnd!
          : occurrence.fieldEnd!,
      target: occurrence.run.target,
    );

Widget _testApp(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SizedBox(width: 900, height: 640, child: child)),
);
