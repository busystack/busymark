import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_inline_controller.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/spellcheck/markdown_spelling_projection.dart';
import 'package:busymark/src/spellcheck/spelling_projection.dart';
import 'package:busymark/src/spellcheck/spelling_replacement.dart';
import 'package:busymark/src/spellcheck/writerside_spelling_projection.dart';
import 'package:busymark/src/spellcheck/wysiwyg_spelling_projection.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:flutter_test/flutter_test.dart';

const _snapshot = SpellingSnapshotIdentity(
  bufferId: 'buffer-1',
  contentRevision: 7,
  documentKind: DocumentKind.markdown,
  contextGeneration: 2,
);

SpellingOccurrence _rejected(SpellingProseRun run, String word) {
  final start = run.text.indexOf(word);
  expect(start, isNonNegative);
  return SpellingOccurrence(
    id: '${run.id}:$start',
    run: run,
    logicalStart: start,
    logicalEnd: start + word.length,
    word: word,
    outcome: SpellingCheckOutcome.rejected,
  );
}

void main() {
  group('Markdown spelling projection', () {
    test('maps repeated and formatted prose without searching globally', () {
      const source = 'mispelled\n\n**mispel**led and `hiddenbad` tail\n';
      final result = const MarkdownSpellingProjector().project(
        filePath: '/tmp/test.md',
        source: source,
        mode: MarkdownMode.commonMark,
        languageId: 'en-US',
        snapshot: _snapshot,
      );

      expect(result.complete, isTrue);
      expect(result.runs.map((run) => run.text), contains('mispelled'));
      expect(result.runs.map((run) => run.text), contains('mispelled and '));
      expect(result.runs.map((run) => run.text), contains(' tail'));
      expect(
        result.runs.every((run) => !run.text.contains('hiddenbad')),
        isTrue,
      );

      final formatted = result.runs.firstWhere(
        (run) => run.text.startsWith('mispelled and'),
      );
      final plan = const SpellingReplacementPlanner().build(
        occurrence: _rejected(formatted, 'mispelled'),
        suggestion: 'misspelled',
      );
      expect(
        plan.applyToSource(source),
        'mispelled\n\n**misspel**led and `hiddenbad` tail\n',
      );
    });

    test('keeps entities, escapes, links, and table cells source exact', () {
      const source =
          '''A sm&amp;ll [labell](https://example.invalid/badd) and \\word.

| first | errored\\|cell |
| --- | --- |
| second | 😀 mistakke |
''';
      final result = const MarkdownSpellingProjector().project(
        filePath: '/tmp/test.md',
        source: source,
        mode: MarkdownMode.commonMark,
        languageId: 'en-US',
        snapshot: _snapshot,
      );

      expect(result.complete, isTrue);
      final allText = result.runs.map((run) => run.text).join('\n');
      expect(allText, contains('sm&ll'));
      expect(allText, contains('labell'));
      expect(allText, isNot(contains('example.invalid')));
      expect(allText, contains('errored|cell'));
      expect(allText, contains('😀 mistakke'));
      for (final run in result.runs) {
        expect(run.hasValidMapping, isTrue);
        for (final atom in run.atoms) {
          expect(atom.sourceStart, greaterThanOrEqualTo(0));
          expect(atom.sourceEnd, lessThanOrEqualTo(source.length));
        }
      }
    });

    test('keeps CRLF and repeated occurrence targets exact', () {
      const source = '> First mistakke\r\n> second mistakke\r\n';
      final result = const MarkdownSpellingProjector().project(
        filePath: '/tmp/repeated.md',
        source: source,
        mode: MarkdownMode.commonMark,
        languageId: 'en-US',
        snapshot: _snapshot,
      );
      final run = result.runs.single;
      final start = run.text.lastIndexOf('mistakke');
      final occurrence = SpellingOccurrence(
        id: 'second-mistakke',
        run: run,
        logicalStart: start,
        logicalEnd: start + 'mistakke'.length,
        word: 'mistakke',
        outcome: SpellingCheckOutcome.rejected,
      );
      final corrected = const SpellingReplacementPlanner()
          .build(occurrence: occurrence, suggestion: 'mistake')
          .applyToSource(source);

      expect(corrected, '> First mistakke\r\n> second mistake\r\n');
    });

    test('uses barriers around excluded authored syntax', () {
      const source = r'''---
title: hiddenfront
---

Visiblee pre`hiddeninline`fix and $hiddenmath$ afterr.
<!-- hiddencomment -->
<https://example.invalid/hiddenurl>
Plainn https://example.invalid/hiddenplain thenn person@example.invalid afterwardd.
Beforecomment <!-- hidden
continuedcomment --> aftercomment.
Beforecode ``hidden
continuedcode`` aftercode.
Beforee %hiddenvariable% afterrr.
![Altternativ text](path/hidden.png "Readablee title")
''';
      final result = const MarkdownSpellingProjector().project(
        filePath: '/tmp/exclusions.md',
        source: source,
        mode: MarkdownMode.writersideMarkdown,
        languageId: 'en-US',
        snapshot: _snapshot,
      );
      final texts = result.runs.map((run) => run.text).toList();
      final all = texts.join('\n');

      expect(all, contains('Visiblee pre'));
      expect(all, contains('fix and '));
      expect(all, contains(' afterr.'));
      expect(all, contains('Beforee '));
      expect(all, contains(' afterrr.'));
      expect(all, contains('Plainn '));
      expect(all, contains(' thenn '));
      expect(all, contains(' afterwardd.'));
      expect(all, contains('Beforecomment '));
      expect(all, contains(' aftercomment.'));
      expect(all, contains('Beforecode '));
      expect(all, contains(' aftercode.'));
      expect(all, contains('Altternativ text'));
      expect(all, contains('Readablee title'));
      expect(all, isNot(contains('prefix')));
      expect(all, isNot(contains('hiddenfront')));
      expect(all, isNot(contains('hiddeninline')));
      expect(all, isNot(contains('hiddenmath')));
      expect(all, isNot(contains('hiddencomment')));
      expect(all, isNot(contains('hiddenurl')));
      expect(all, isNot(contains('hiddenplain')));
      expect(all, isNot(contains('example.invalid')));
      expect(all, isNot(contains('continuedcomment')));
      expect(all, isNot(contains('continuedcode')));
      expect(all, isNot(contains('hiddenvariable')));
      expect(all, isNot(contains('hidden.png')));
    });

    test('keeps unmatched delimiters and removes only parsed formatting', () {
      const source =
          'Matched **mispel**led and literal foo_bar plus *unclosed.\n';
      final result = const MarkdownSpellingProjector().project(
        filePath: '/tmp/delimiters.md',
        source: source,
        mode: MarkdownMode.commonMark,
        languageId: 'en-US',
        snapshot: _snapshot,
      );

      expect(result.complete, isTrue);
      expect(
        result.runs.single.text,
        'Matched mispelled and literal foo_bar plus *unclosed.',
      );
      expect(
        result.runs.single.atoms.map((atom) => atom.logicalText).join(),
        result.runs.single.text,
      );
    });

    test('maps quoted HTML attribute values from quote boundaries', () {
      for (final fixture in <({String source, String expected})>[
        (
          source: 'A <span title="titl" data-x="titl">x</span>.\n',
          expected: 'A <span title="title" data-x="titl">x</span>.\n',
        ),
        (
          source: 'A <span title="titl" summary="titl">x</span>.\n',
          expected: 'A <span title="title" summary="titl">x</span>.\n',
        ),
        (
          source: "A <span title='titl' summary='other'>x</span>.\n",
          expected: "A <span title='title' summary='other'>x</span>.\n",
        ),
        (
          source: 'A <span title="titl &amp; more" tooltip="titl">x</span>.\n',
          expected:
              'A <span title="title &amp; more" tooltip="titl">x</span>.\n',
        ),
      ]) {
        final result = const MarkdownSpellingProjector().project(
          filePath: '/tmp/attributes.md',
          source: fixture.source,
          mode: MarkdownMode.commonMark,
          languageId: 'en-US',
          snapshot: _snapshot,
        );
        final run = result.runs.firstWhere(
          (candidate) =>
              candidate.text == 'titl' || candidate.text.startsWith('titl '),
        );
        final corrected = const SpellingReplacementPlanner()
            .build(occurrence: _rejected(run, 'titl'), suggestion: 'title')
            .applyToSource(fixture.source);

        expect(corrected, fixture.expected);
        expect(corrected, contains('<span title='));
      }
    });

    test('removes delimiters when a correction empties formatting', () {
      for (final fixture in <({String source, MarkdownMode mode})>[
        (source: 'he**x**llo\n', mode: MarkdownMode.commonMark),
        (source: 'he***x***llo\n', mode: MarkdownMode.commonMark),
        (source: 'he~~x~~llo\n', mode: MarkdownMode.gfm),
      ]) {
        final result = const MarkdownSpellingProjector().project(
          filePath: '/tmp/empty-format.md',
          source: fixture.source,
          mode: fixture.mode,
          languageId: 'en-US',
          snapshot: _snapshot,
        );
        final run = result.runs.single;
        final corrected = const SpellingReplacementPlanner()
            .build(occurrence: _rejected(run, 'hexllo'), suggestion: 'hello')
            .applyToSource(fixture.source);
        final parsed = const MarkdownParser().parse(
          filePath: '/tmp/empty-format.md',
          source: corrected,
          mode: fixture.mode,
          validateLocalReferences: false,
        );

        expect(corrected, 'hello\n');
        expect(parsed.busyDocument.blocks.single.plainText, 'hello');
        expect(
          parsed.busyDocument.blocks.single.inlines.where(
            (inline) => inline.kind != BusyInlineKind.text,
          ),
          isEmpty,
        );
      }
    });

    test('uses parser-compatible percentages escapes and code spans', () {
      const source =
          r'20% mispelled 30% \letter \*escaped* %real_variable% '
          'before ``hidden ` tick`` after `unmatched\n';
      final commonMark = const MarkdownSpellingProjector().project(
        filePath: '/tmp/common.md',
        source: source,
        mode: MarkdownMode.commonMark,
        languageId: 'en-US',
        snapshot: _snapshot,
      );
      final writerside = const MarkdownSpellingProjector().project(
        filePath: '/tmp/writerside.md',
        source: source,
        mode: MarkdownMode.writersideMarkdown,
        languageId: 'en-US',
        snapshot: _snapshot,
      );
      final commonText = commonMark.runs.map((run) => run.text).join(' ');
      final writersideText = writerside.runs.map((run) => run.text).join(' ');

      expect(commonText, contains(r'20% mispelled 30% \letter *escaped*'));
      expect(commonText, contains('%real_variable%'));
      expect(commonText, isNot(contains('hidden ` tick')));
      expect(commonText, contains('after `unmatched'));
      expect(writersideText, contains('20% mispelled 30%'));
      expect(writersideText, isNot(contains('real_variable')));
      final typoRun = writerside.runs.firstWhere(
        (run) => run.text.contains('mispelled'),
      );
      expect(
        const SpellingReplacementPlanner()
            .build(
              occurrence: _rejected(typoRun, 'mispelled'),
              suggestion: 'misspelled',
            )
            .applyToSource(source),
        contains('20% misspelled 30%'),
      );
    });

    test('retains complete formatting ancestors across opaque children', () {
      for (final fixture in <({String source, String expected})>[
        (source: 'hello**x`code`world**\n', expected: 'hello**`code`world**\n'),
        (
          source:
              r'hello**x$y$world**'
              '\n',
          expected:
              r'hello**$y$world**'
              '\n',
        ),
        (
          source: 'hello***x`code`world***\n',
          expected: 'hello***`code`world***\n',
        ),
        (
          source: 'hello**x [good](target "title") world**\n',
          expected: 'hello** [good](target "title") world**\n',
        ),
      ]) {
        final projected = const MarkdownSpellingProjector().project(
          filePath: '/tmp/ancestor.md',
          source: fixture.source,
          mode: MarkdownMode.commonMark,
          languageId: 'en-US',
          snapshot: _snapshot,
        );
        final run = projected.runs.firstWhere(
          (candidate) => candidate.text.contains('hellox'),
        );
        late final String corrected;
        expect(
          () => corrected = const SpellingReplacementPlanner()
              .build(occurrence: _rejected(run, 'hellox'), suggestion: 'hello')
              .applyToSource(fixture.source),
          returnsNormally,
          reason: fixture.source,
        );

        expect(corrected, fixture.expected);
      }
    });

    test(
      'link titles use exact quote boundaries before trailing whitespace',
      () {
        for (final fixture in <({String source, String expected})>[
          (
            source: '[label](mispelled "mispelled"   )\n',
            expected: '[label](mispelled "misspelled"   )\n',
          ),
          (
            source: "[label](target 'mispelled'\t )\n",
            expected: "[label](target 'misspelled'\t )\n",
          ),
          (
            source:
                r'''[label](target "mispelled \"quoted\"")'''
                '\n',
            expected:
                r'''[label](target "misspelled \"quoted\"")'''
                '\n',
          ),
        ]) {
          final projected = const MarkdownSpellingProjector().project(
            filePath: '/tmp/title.md',
            source: fixture.source,
            mode: MarkdownMode.commonMark,
            languageId: 'en-US',
            snapshot: _snapshot,
          );
          final run = projected.runs.firstWhere(
            (candidate) => candidate.text.contains('mispelled'),
          );
          final occurrence = _rejected(run, 'mispelled');
          expect(
            fixture.source.substring(
              occurrence.sourceStart!,
              occurrence.sourceEnd!,
            ),
            'mispelled',
          );
          expect(
            const SpellingReplacementPlanner()
                .build(occurrence: occurrence, suggestion: 'misspelled')
                .applyToSource(fixture.source),
            fixture.expected,
          );
        }
      },
    );

    test('semantic leaf blocks define independent complete prose runs', () {
      const source = r'''    hiddenindent

- parentt
  - nestedd

> firstt
>
> secondd

- visiblee

      hiddencontainercode

before $$ mispelled $$ afterr

before $hiddenmath$ aftermath
''';
      final projected = const MarkdownSpellingProjector().project(
        filePath: '/tmp/leaves.md',
        source: source,
        mode: MarkdownMode.commonMark,
        languageId: 'en-US',
        snapshot: _snapshot,
      );
      final texts = projected.runs.map((run) => run.text).toList();

      expect(projected.complete, isTrue, reason: projected.message);
      expect(texts, contains('parentt'));
      expect(texts, contains('nestedd'));
      expect(texts, contains('firstt'));
      expect(texts, contains('secondd'));
      expect(texts, contains(r'before $$ mispelled $$ afterr'));
      expect(texts.join(' '), isNot(contains('hiddenindent')));
      expect(texts.join(' '), isNot(contains('hiddencontainercode')));
      expect(texts.join(' '), isNot(contains('hiddenmath')));
      expect(texts.every((text) => text != 'parentt nestedd'), isTrue);
    });

    test('large formatting-heavy projection and correction stay bounded', () {
      final source = List.generate(
        600,
        (index) =>
            '**mispel**led paragraph $index with [hello](target) and `code` '
            r'$x$',
      ).join('\n\n');
      final watch = Stopwatch()..start();
      final projected = const MarkdownSpellingProjector().project(
        filePath: '/tmp/large-correction.md',
        source: source,
        mode: MarkdownMode.commonMark,
        languageId: 'en-US',
        snapshot: _snapshot,
      );
      final first = projected.runs.firstWhere(
        (run) => run.text.contains('mispelled'),
      );
      final corrected = const SpellingReplacementPlanner()
          .build(
            occurrence: _rejected(first, 'mispelled'),
            suggestion: 'misspelled',
          )
          .applyToSource(source);
      watch.stop();

      expect(projected.complete, isTrue, reason: projected.message);
      expect(corrected, startsWith('**misspel**led paragraph 0'));
      expect(corrected, contains('**mispel**led paragraph 599'));
      expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
    });
  });

  group('Writerside XML spelling projection', () {
    test('maps text, entities, CDATA, and positive attributes', () {
      const source = '''<topic id="sample" title="Titlle">
  <p>Repeeted &amp; <b>formmatted</b>.</p>
  <p><![CDATA[Cdataa prose]]></p>
  <code>hiddenbad</code>
  <include from="other.topic" element-id="badtechnical"/>
  <img src="path/teh.png" alt="Altternativ text"/>
</topic>''';
      final result = const WritersideXmlSpellingProjector().project(
        filePath: '/tmp/topic.topic',
        source: source,
        languageId: 'en-US',
        snapshot: const SpellingSnapshotIdentity(
          bufferId: 'xml',
          contentRevision: 1,
          documentKind: DocumentKind.writersideXmlTopic,
          contextGeneration: 1,
        ),
      );
      final text = result.runs.map((run) => run.text).join('\n');
      expect(result.complete, isTrue);
      expect(text, contains('Titlle'));
      expect(text, contains('Repeeted & formmatted'));
      expect(text, contains('Cdataa prose'));
      expect(text, contains('Altternativ text'));
      expect(text, isNot(contains('hiddenbad')));
      expect(text, isNot(contains('other.topic')));
      expect(text, isNot(contains('path/teh.png')));
    });

    test('reports malformed XML as incomplete without guessed targets', () {
      final result = const WritersideXmlSpellingProjector().project(
        filePath: '/tmp/topic.topic',
        source: '<topic><p>broken',
        languageId: 'en-US',
        snapshot: const SpellingSnapshotIdentity(
          bufferId: 'xml',
          contentRevision: 1,
          documentKind: DocumentKind.writersideXmlTopic,
          contextGeneration: 1,
        ),
      );
      expect(result.complete, isFalse);
      expect(result.runs, isEmpty);
    });

    test(
      'clips CDATA occurrences while preserving repeated surrounding text',
      () {
        const source =
            '<topic><p><![CDATA[hello helo helo world]]> plain helo</p></topic>';
        final projected = const WritersideXmlSpellingProjector().project(
          filePath: '/tmp/cdata.topic',
          source: source,
          languageId: 'en-US',
          snapshot: const SpellingSnapshotIdentity(
            bufferId: 'xml',
            contentRevision: 1,
            documentKind: DocumentKind.writersideXmlTopic,
            contextGeneration: 1,
          ),
        );
        final run = projected.runs.firstWhere(
          (candidate) => candidate.text.contains('hello helo helo world'),
        );
        final first = _rejected(run, 'helo');

        expect(source.substring(first.sourceStart!, first.sourceEnd!), 'helo');
        expect(first.sourceIntervals, hasLength(1));
        expect(
          const SpellingReplacementPlanner()
              .build(occurrence: first, suggestion: 'hello')
              .applyToSource(source),
          '<topic><p><![CDATA[hello hello helo world]]> plain helo</p></topic>',
        );

        final transformed = SpellingSourceAtom(
          logicalText: 'xy',
          logicalStart: 0,
          logicalEnd: 2,
          sourceStart: 10,
          sourceEnd: 18,
          transformation: SpellingTransformationKind.entity,
          context: SpellingSourceContext.xmlText,
        );
        expect(transformed.sourceIntervalFor(1, 2)?.start, 10);
        expect(transformed.sourceIntervalFor(1, 2)?.end, 18);
      },
    );

    test('maps line breaks, excludes variables, and includes controls', () {
      const source = r'''<topic id="sample">
  <p>hello<br/>world %projectname% prose %\escaped%</p>
  <p title="%projectname% Titlle">tail</p>
  <control>Setttings</control>
</topic>''';
      final projected = const WritersideXmlSpellingProjector().project(
        filePath: '/tmp/variables.topic',
        source: source,
        languageId: 'en-US',
        snapshot: const SpellingSnapshotIdentity(
          bufferId: 'xml',
          contentRevision: 1,
          documentKind: DocumentKind.writersideXmlTopic,
          contextGeneration: 1,
        ),
      );
      final text = projected.runs.map((run) => run.text).join('\n');

      expect(projected.complete, isTrue, reason: projected.message);
      expect(text, contains('hello world'));
      expect(text, isNot(contains('helloworld')));
      expect(text, isNot(contains('projectname')));
      expect(text, contains(r'%\escaped%'));
      expect(text, contains('Titlle'));
      expect(text, contains('Setttings'));
    });
  });

  group('exact rich correction', () {
    test('maps hard breaks by structural field identity', () {
      const source = 'helo  \nworld\n\nhelo world\n';
      final document = const MarkdownParser()
          .parse(
            filePath: '/tmp/hard-break.md',
            source: source,
            mode: MarkdownMode.commonMark,
            validateLocalReferences: false,
          )
          .busyDocument;
      final projection = const WysiwygSpellingProjector().project(
        document: document,
        languageId: 'en-US',
        snapshot: _snapshot,
        documentGeneration: 4,
      );
      final richRuns = projection.runs
          .where((run) => run.target is SpellingRichBlockTarget)
          .toList();

      expect(projection.complete, isTrue, reason: projection.message);
      expect(richRuns, hasLength(2));
      expect(richRuns.map((run) => run.text), everyElement('helo world'));
      expect(
        const SpellingReplacementPlanner()
            .build(
              occurrence: _rejected(richRuns.first, 'helo'),
              suggestion: 'hello',
            )
            .applyToSource(source),
        'hello  \nworld\n\nhelo world\n',
      );
      expect(
        (richRuns.first.target as SpellingRichBlockTarget).blockId,
        isNot((richRuns.last.target as SpellingRichBlockTarget).blockId),
      );
    });

    test('removes a rich formatting container emptied by deletion', () {
      final document = BusyDocument(
        filePath: '/tmp/empty-rich.md',
        mode: MarkdownMode.commonMark,
        blocks: const [
          BusyBlock(
            id: 'p',
            kind: BusyBlockKind.paragraph,
            inlines: [
              BusyInline(kind: BusyInlineKind.text, text: 'he'),
              BusyInline(
                kind: BusyInlineKind.strong,
                text: 'x',
                children: [BusyInline(kind: BusyInlineKind.text, text: 'x')],
              ),
              BusyInline(kind: BusyInlineKind.text, text: 'llo'),
            ],
          ),
        ],
      );
      final run = const WysiwygSpellingProjector()
          .project(
            document: document,
            languageId: 'en-US',
            snapshot: _snapshot,
            documentGeneration: 1,
          )
          .runs
          .single;
      final plan = const SpellingReplacementPlanner().build(
        occurrence: _rejected(run, 'hexllo'),
        suggestion: 'hello',
      );
      final controller = BusyMarkWysiwygDocumentController(document: document);

      expect(
        controller.replaceSpellingInBlock(
          blockId: 'p',
          expectedFieldText: 'hexllo',
          plan: plan,
        ),
        isTrue,
      );
      expect(controller.markdown, 'hello\n');
      expect(
        controller
            .blockById('p')!
            .inlines
            .where((inline) => inline.kind == BusyInlineKind.strong),
        isEmpty,
      );
    });

    test('retains current source anchors and source-only title targets', () {
      const source =
          '![Altternativ](asset.png "Repeeted")\n\nRepeeted\n\n**mispel**led\n';
      final document = const MarkdownParser()
          .parse(
            filePath: '/tmp/current.md',
            source: source,
            mode: MarkdownMode.commonMark,
            validateLocalReferences: false,
          )
          .busyDocument;
      final projection = const WysiwygSpellingProjector().project(
        document: document,
        languageId: 'en-US',
        snapshot: _snapshot,
        documentGeneration: 9,
      );

      expect(projection.complete, isTrue);
      final title = projection.runs.singleWhere(
        (run) => run.text == 'Repeeted' && run.target is SpellingSourceTarget,
      );
      final paragraph = projection.runs.singleWhere(
        (run) =>
            run.text == 'Repeeted' && run.target is SpellingRichBlockTarget,
      );
      final formatted = projection.runs.singleWhere(
        (run) => run.text == 'mispelled',
      );
      expect(paragraph.atoms.every((atom) => atom.sourceStart >= 0), isTrue);
      expect(formatted.atoms.every((atom) => atom.sourceStart >= 0), isTrue);
      expect(
        const SpellingReplacementPlanner()
            .build(
              occurrence: _rejected(formatted, 'mispelled'),
              suggestion: 'misspelled',
            )
            .applyToSource(source),
        '![Altternativ](asset.png "Repeeted")\n\nRepeeted\n\n**misspel**led\n',
      );
      expect(
        const SpellingReplacementPlanner()
            .build(
              occurrence: _rejected(title, 'Repeeted'),
              suggestion: 'Bob"s',
            )
            .applyToSource(source),
        '![Altternativ](asset.png "Bob\\"s")\n\nRepeeted\n\n**mispel**led\n',
      );
    });

    test('preserves formatting ownership across leaves', () {
      final document = BusyDocument(
        filePath: '/tmp/test.md',
        mode: MarkdownMode.commonMark,
        blocks: const [
          BusyBlock(
            id: 'p',
            kind: BusyBlockKind.paragraph,
            inlines: [
              BusyInline(
                kind: BusyInlineKind.strong,
                text: 'mispel',
                children: [
                  BusyInline(kind: BusyInlineKind.text, text: 'mispel'),
                ],
              ),
              BusyInline(kind: BusyInlineKind.text, text: 'led'),
            ],
          ),
        ],
      );
      final projection = const WysiwygSpellingProjector().project(
        document: document,
        languageId: 'en-US',
        snapshot: _snapshot,
        documentGeneration: 4,
      );
      final run = projection.runs.single;
      final plan = const SpellingReplacementPlanner().build(
        occurrence: _rejected(run, 'mispelled'),
        suggestion: 'misspelled',
      );
      final controller = BusyMarkWysiwygDocumentController(document: document);

      expect(
        controller.replaceSpellingInBlock(
          blockId: 'p',
          expectedFieldText: 'mispelled',
          plan: plan,
        ),
        isTrue,
      );
      expect(controller.markdown, '**misspel**led\n');
    });

    test('keeps trailing formatting on its original leaf', () {
      final document = BusyDocument(
        filePath: '/tmp/test.md',
        mode: MarkdownMode.commonMark,
        blocks: const [
          BusyBlock(
            id: 'p',
            kind: BusyBlockKind.paragraph,
            inlines: [
              BusyInline(kind: BusyInlineKind.text, text: 'mispel'),
              BusyInline(
                kind: BusyInlineKind.strong,
                text: 'led',
                children: [BusyInline(kind: BusyInlineKind.text, text: 'led')],
              ),
            ],
          ),
        ],
      );
      final run = const WysiwygSpellingProjector()
          .project(
            document: document,
            languageId: 'en-US',
            snapshot: _snapshot,
            documentGeneration: 4,
          )
          .runs
          .single;
      final plan = const SpellingReplacementPlanner().build(
        occurrence: _rejected(run, 'mispelled'),
        suggestion: 'misspelled',
      );
      final controller = BusyMarkWysiwygDocumentController(document: document);

      expect(
        controller.replaceSpellingInBlock(
          blockId: 'p',
          expectedFieldText: 'mispelled',
          plan: plan,
        ),
        isTrue,
      );
      expect(controller.markdown, 'misspel**led**\n');
    });

    test('preserves link destination and table structure', () {
      final link = BusyInline(
        kind: BusyInlineKind.link,
        text: 'mispelled',
        destination: 'target',
        children: const [
          BusyInline(kind: BusyInlineKind.text, text: 'mispelled'),
        ],
      );
      final cell = BusyBlock(
        id: 'cell',
        kind: BusyBlockKind.paragraph,
        inlines: [link],
      );
      final document = BusyDocument(
        filePath: '/tmp/test.md',
        mode: MarkdownMode.commonMark,
        blocks: [
          BusyBlock(
            id: 'table',
            kind: BusyBlockKind.table,
            children: [
              BusyBlock(
                id: 'row',
                kind: BusyBlockKind.table,
                attributes: const {'header': 'true'},
                children: [cell],
              ),
            ],
          ),
        ],
      );
      final run = const WysiwygSpellingProjector()
          .project(
            document: document,
            languageId: 'en-US',
            snapshot: _snapshot,
            documentGeneration: 1,
          )
          .runs
          .single;
      final plan = const SpellingReplacementPlanner().build(
        occurrence: _rejected(run, 'mispelled'),
        suggestion: 'misspelled',
      );
      final controller = BusyMarkWysiwygDocumentController(document: document);
      expect(
        controller.replaceSpellingInTableCell(
          tableBlockId: 'table',
          cellId: 'cell',
          expectedFieldText: 'mispelled',
          plan: plan,
        ),
        isTrue,
      );
      final updated = controller.blockById('cell')!;
      expect(updated.plainText, 'misspelled');
      expect(updated.inlines.single.destination, 'target');
      expect(controller.blockById('table')!.children.length, 1);
    });

    test('maps and corrects a table-cell field containing inline math', () {
      const source =
          '| Value |\n'
          '| --- |\n'
          r'| erroor $x$ tail |'
          '\n';
      final document = const MarkdownParser()
          .parse(
            filePath: '/tmp/math-table.md',
            source: source,
            mode: MarkdownMode.commonMark,
            validateLocalReferences: false,
          )
          .busyDocument;
      final projection = const WysiwygSpellingProjector().project(
        document: document,
        languageId: 'en-US',
        snapshot: _snapshot,
        documentGeneration: 3,
      );
      expect(projection.complete, isTrue, reason: projection.message);
      final run = projection.runs.singleWhere(
        (candidate) => candidate.text.contains('erroor'),
      );
      final target = run.target as SpellingRichTableCellTarget;
      expect(run.atoms.every((atom) => atom.sourceStart >= 0), isTrue);
      final controller = BusyMarkWysiwygDocumentController(document: document);
      final cell = controller.blockById(target.cellId)!;
      final plan = const SpellingReplacementPlanner().build(
        occurrence: _rejected(run, 'erroor'),
        suggestion: 'error',
      );

      expect(
        controller.replaceSpellingInTableCell(
          tableBlockId: target.tableBlockId,
          cellId: target.cellId,
          expectedFieldText: busyMarkWysiwygEditableText(cell),
          plan: plan,
        ),
        isTrue,
      );
      expect(controller.markdown, contains(r'error $x$ tail'));
    });

    test('corrects transformed prose in table math source fields', () {
      for (final fixture
          in <({String cell, String word, String suggestion, String expected})>[
            (
              cell: r'mispel**led** $x$',
              word: 'mispelled',
              suggestion: 'misspelled',
              expected: r'misspel**led** $x$',
            ),
            (
              cell: r'mispell&#101;d $x$',
              word: 'mispelled',
              suggestion: 'misspelled',
              expected: r'misspelled $x$',
            ),
            (
              cell: r'he**x**llo $x$',
              word: 'hexllo',
              suggestion: 'hello',
              expected: r'hello $x$',
            ),
          ]) {
        final source = '| Value |\n| --- |\n| ${fixture.cell} |\n';
        final document = const MarkdownParser()
            .parse(
              filePath: '/tmp/transformed-math-table.md',
              source: source,
              mode: MarkdownMode.commonMark,
              validateLocalReferences: false,
            )
            .busyDocument;
        final projected = const WysiwygSpellingProjector().project(
          document: document,
          languageId: 'en-US',
          snapshot: _snapshot,
          documentGeneration: 8,
        );
        final run = projected.runs.firstWhere(
          (candidate) => candidate.text.contains(fixture.word),
        );
        final target = run.target as SpellingRichTableCellTarget;
        final controller = BusyMarkWysiwygDocumentController(
          document: document,
        );
        final plan = const SpellingReplacementPlanner().build(
          occurrence: _rejected(run, fixture.word),
          suggestion: fixture.suggestion,
        );

        expect(
          controller.replaceSpellingInTableCell(
            tableBlockId: target.tableBlockId,
            cellId: target.cellId,
            expectedFieldText: busyMarkWysiwygEditableText(
              controller.blockById(target.cellId)!,
            ),
            plan: plan,
          ),
          isTrue,
        );
        expect(controller.markdown, contains('| ${fixture.expected} |'));
      }
    });

    test('corrects formatted and encoded prose in math source fields', () {
      for (final fixture in <({String source, String expected})>[
        (
          source:
              r'mispel**led** $x$'
              '\n',
          expected:
              r'misspel**led** $x$'
              '\n',
        ),
        (
          source:
              r'mispell&#101;d $x$'
              '\n',
          expected:
              r'misspelled $x$'
              '\n',
        ),
        (
          source:
              r'he**x**llo $x$'
              '\n',
          expected:
              r'hello $x$'
              '\n',
        ),
      ]) {
        final document = const MarkdownParser()
            .parse(
              filePath: '/tmp/math-rich.md',
              source: fixture.source,
              mode: MarkdownMode.commonMark,
              validateLocalReferences: false,
            )
            .busyDocument;
        final projected = const WysiwygSpellingProjector().project(
          document: document,
          languageId: 'en-US',
          snapshot: _snapshot,
          documentGeneration: 7,
        );
        final run = projected.runs.firstWhere(
          (candidate) =>
              candidate.text.contains('mispelled') ||
              candidate.text.contains('hexllo'),
        );
        final word = run.text.contains('mispelled') ? 'mispelled' : 'hexllo';
        final plan = const SpellingReplacementPlanner().build(
          occurrence: _rejected(run, word),
          suggestion: word == 'hexllo' ? 'hello' : 'misspelled',
        );
        final controller = BusyMarkWysiwygDocumentController(
          document: document,
        );
        final target = run.target as SpellingRichBlockTarget;

        expect(
          controller.replaceSpellingInBlock(
            blockId: target.blockId,
            expectedFieldText: busyMarkWysiwygEditableText(
              controller.blockById(target.blockId)!,
            ),
            plan: plan,
          ),
          isTrue,
        );
        expect(controller.markdown, fixture.expected);
      }
    });
  });
}
