import 'dart:io';

import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_clipboard_html.dart';
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
import 'package:markdown/markdown.dart' as md;

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

bool _parserHasInline(String source, BusyInlineKind kind) {
  final parsed = const MarkdownParser().parse(
    filePath: '/tmp/recognized-inline.md',
    source: source,
    mode: MarkdownMode.commonMark,
  );
  bool inInline(BusyInline inline) =>
      inline.kind == kind || inline.children.any(inInline);
  bool inBlock(BusyBlock block) =>
      block.inlines.any(inInline) || block.children.any(inBlock);
  return parsed.busyDocument.blocks.any(inBlock);
}

void _expectNestedMultilineLabel({
  required String source,
  required BusyInlineKind nestedKind,
  required List<String> bodyRuns,
  String? titleText,
}) {
  const filePath = '/tmp/nested-multiline-label.md';
  final parsed = const MarkdownParser().parse(
    filePath: filePath,
    source: source,
    mode: MarkdownMode.commonMark,
  );
  Iterable<BusyInline> inlines(Iterable<BusyInline> roots) sync* {
    for (final inline in roots) {
      yield inline;
      yield* inlines(inline.children);
    }
  }

  Iterable<BusyBlock> blocks(Iterable<BusyBlock> roots) sync* {
    for (final block in roots) {
      yield block;
      yield* blocks(block.children);
    }
  }

  final allInlines = [
    for (final block in blocks(parsed.busyDocument.blocks))
      ...inlines(block.inlines),
  ];
  final outerLink = allInlines.singleWhere(
    (inline) =>
        inline.kind == BusyInlineKind.link && inline.destination == 'target',
  );
  expect(
    inlines(outerLink.children).any((inline) => inline.kind == nestedKind),
    isTrue,
    reason: source,
  );
  if (nestedKind == BusyInlineKind.image) {
    expect(
      inlines(outerLink.children)
          .where((inline) => inline.kind == BusyInlineKind.image)
          .single
          .destination,
      contains('image.png'),
      reason: source,
    );
  }
  final projected = const MarkdownSpellingProjector().project(
    filePath: filePath,
    source: source,
    mode: MarkdownMode.commonMark,
    languageId: 'en-Test',
    snapshot: _snapshot,
  );
  final rich = const WysiwygSpellingProjector().project(
    document: parsed.busyDocument,
    languageId: 'en-Test',
    snapshot: _snapshot,
    documentGeneration: 1,
  );
  expect(projected.complete, isTrue, reason: source);
  expect(rich.complete, isTrue, reason: source);
  expect(projected.runs.every((run) => run.hasValidMapping), isTrue);
  expect(rich.runs.every((run) => run.hasValidMapping), isTrue);

  List<String> body(List<SpellingProseRun> runs) => [
    for (final run in runs)
      if (run.atoms.first.context == SpellingSourceContext.markdownProse)
        run.text.trim(),
  ];
  expect(body(projected.runs), bodyRuns, reason: source);
  expect(body(rich.runs), bodyRuns, reason: source);
  final sourceText = projected.runs.map((run) => run.text).join(' ');
  expect(sourceText, isNot(contains('image.png')), reason: source);
  expect(sourceText, isNot(contains('target')), reason: source);
  if (nestedKind == BusyInlineKind.code) {
    expect(sourceText, isNot(contains('code')), reason: source);
    expect(sourceText, isNot(contains('more')), reason: source);
  }
  if (titleText != null) {
    final sourceTitle = projected.runs.singleWhere(
      (run) => run.text == titleText,
    );
    final richTitle = rich.runs.singleWhere((run) => run.text == titleText);
    expect(sourceTitle.target, isA<SpellingSourceTarget>());
    expect(richTitle.target, isA<SpellingSourceTarget>());
  }
  for (final runs in [projected.runs, rich.runs]) {
    final run = runs.singleWhere(
      (candidate) => candidate.text.contains('wrld'),
    );
    final word = _rejected(run, 'wrld');
    expect(word.sourceStart, source.indexOf('wrld'));
    expect(word.sourceEnd, source.indexOf('wrld') + 'wrld'.length);
    if (identical(runs, rich.runs)) {
      expect(run.target, isA<SpellingRichBlockTarget>());
    }
    expect(
      const SpellingReplacementPlanner()
          .build(occurrence: word, suggestion: 'world')
          .applyToSource(source),
      source.replaceFirst('wrld', 'world'),
      reason: source,
    );
  }
}

void _expectCodeFenceBeforeWrld(String source, List<String> codeWords) {
  final parsed = const MarkdownParser().parse(
    filePath: '/tmp/fence-continuation.md',
    source: source,
    mode: MarkdownMode.commonMark,
  );
  Iterable<BusyBlock> blocks(Iterable<BusyBlock> roots) sync* {
    for (final block in roots) {
      yield block;
      yield* blocks(block.children);
    }
  }

  final structured = blocks(parsed.busyDocument.blocks).toList();
  expect(
    structured.any(
      (block) =>
          block.kind == BusyBlockKind.codeBlock &&
          codeWords.every(block.plainText.contains),
    ),
    isTrue,
    reason: source,
  );
  expect(
    structured.any(
      (block) =>
          block.kind == BusyBlockKind.paragraph &&
          block.plainText.contains('wrld'),
    ),
    isTrue,
    reason: source,
  );

  final projected = const MarkdownSpellingProjector().project(
    filePath: '/tmp/fence-continuation.md',
    source: source,
    mode: MarkdownMode.commonMark,
    languageId: 'en-Test',
    snapshot: _snapshot,
  );
  expect(projected.complete, isTrue, reason: source);
  expect(projected.runs.every((run) => run.hasValidMapping), isTrue);
  final visible = projected.runs.map((run) => run.text).join(' ');
  expect(visible, contains('wrld'), reason: source);
  for (final word in codeWords) {
    expect(visible, isNot(contains(word)), reason: source);
  }
  final occurrence = _rejected(
    projected.runs.firstWhere((run) => run.text.contains('wrld')),
    'wrld',
  );
  expect(
    source.substring(occurrence.sourceStart!, occurrence.sourceEnd!),
    'wrld',
  );
  expect(
    const SpellingReplacementPlanner()
        .build(occurrence: occurrence, suggestion: 'world')
        .applyToSource(source),
    source.replaceFirst('wrld', 'world'),
  );
}

void main() {
  test(
    'different live prose still reports incomplete instead of guessed mapping',
    () {
      final parsed = const MarkdownParser()
          .parse(
            filePath: '/changed.md',
            source: 'Original words\n',
            mode: MarkdownMode.gfm,
          )
          .busyDocument;
      final changed = parsed.copyWith(
        blocks: [
          parsed.blocks.single.copyWith(
            inlines: const [
              BusyInline(kind: BusyInlineKind.text, text: 'Different words'),
            ],
          ),
        ],
      );
      final projection = const WysiwygSpellingProjector().project(
        document: changed,
        languageId: 'en-CA',
        snapshot: _snapshot,
        documentGeneration: 1,
      );
      expect(projection.complete, isFalse);
    },
  );

  test(
    'general Markdown fixture has complete Source and rich spelling mappings',
    () {
      final source = File('test/fixtures/markdown/basic.md').readAsStringSync();
      final document = const MarkdownParser()
          .parse(filePath: '/basic.md', source: source, mode: MarkdownMode.gfm)
          .busyDocument;
      final sourceProjection = const MarkdownSpellingProjector().project(
        filePath: '/basic.md',
        source: source,
        mode: MarkdownMode.gfm,
        languageId: 'en-CA',
        snapshot: _snapshot,
      );
      final rich = const WysiwygSpellingProjector().project(
        document: document,
        languageId: 'en-CA',
        snapshot: _snapshot,
        documentGeneration: 1,
      );
      for (final projection in [sourceProjection, rich]) {
        expect(projection.complete, isTrue, reason: projection.message);
        final texts = projection.runs.map((run) => run.text);
        expect(texts, contains('2. Paragraphs'));
        expect(texts, contains('Less than: <'));
        expect(texts, contains('Greater than: >'));
        expect(texts.any((text) => text.contains(r'\frac')), isFalse);
        expect(texts.any((text) => text.contains('^markdown')), isFalse);
        expect(texts, contains('28. Document Conclusion'));
      }
      expect(
        rich.runs.firstWhere((run) => run.text == 'Raw HTML block ').target,
        isA<SpellingSourceTarget>(),
        reason: 'Protected HTML still gets checked in Source.',
      );
      expect(
        rich.runs
            .singleWhere((run) => run.text == '28. Document Conclusion')
            .target,
        isA<SpellingRichBlockTarget>(),
      );
    },
  );

  test('live HTML paste preserves prose and maps spelling before a reload', () {
    final html = File(
      'test/fixtures/spelling/pasted_job.html',
    ).readAsStringSync();
    final fragment = const WysiwygClipboardHtml().decode(
      html,
      mode: MarkdownMode.gfm,
    )!;
    final target = const MarkdownParser()
        .parse(
          filePath: '/pasted.md',
          source: 'Target\n',
          mode: MarkdownMode.gfm,
        )
        .busyDocument;
    final editor = BusyMarkWysiwygDocumentController(document: target);
    addTearDown(editor.dispose);
    editor.insertStyledBlocksAtSelection(
      blockId: target.blocks.first.id,
      selectionStart: 0,
      selectionEnd: 6,
      blocks: fragment.blocks,
    );
    final source = editor.markdown;
    final live = editor.document.copyWith(source: source);
    final reloaded = const MarkdownParser()
        .parse(filePath: '/pasted.md', source: source, mode: MarkdownMode.gfm)
        .busyDocument;
    List<String> prose(BusyDocument document) => [
      for (final block in document.blocks)
        if (block.plainText.trim().isNotEmpty)
          block.plainText.trim().replaceAll(RegExp(r'\s+'), ' '),
    ];
    expect(
      prose(reloaded),
      prose(live),
      reason: 'Formatting must not reload as literal Markdown markers.',
    );
    final projection = const WysiwygSpellingProjector().project(
      document: live,
      languageId: 'en-CA',
      snapshot: _snapshot,
      documentGeneration: 1,
    );
    expect(projection.complete, isTrue, reason: projection.message);
    final team = projection.runs.singleWhere(
      (run) => run.text.contains('Team responsibilities'),
    );
    final occurrence = _rejected(team, 'responsibilities');
    final block = live.blocks.singleWhere(
      (block) => block.id == (team.target as SpellingRichBlockTarget).blockId,
    );
    expect(occurrence.fieldStart, block.plainText.indexOf('responsibilities'));
    final plan = const SpellingReplacementPlanner().build(
      occurrence: occurrence,
      suggestion: 'duties',
    );
    expect(
      plan.applyToSource(source),
      source.replaceFirst('responsibilities', 'duties'),
    );
  });

  test('pasted job maps tables, trailing HTML breaks and address barriers', () {
    final source = File(
      'test/fixtures/spelling/pasted_job.md',
    ).readAsStringSync();
    final document = const MarkdownParser()
        .parse(filePath: '/pasted.md', source: source, mode: MarkdownMode.gfm)
        .busyDocument;
    final sourceProjection = const MarkdownSpellingProjector().project(
      filePath: '/pasted.md',
      source: source,
      mode: MarkdownMode.gfm,
      languageId: 'en-CA',
      snapshot: _snapshot,
    );
    final rich = const WysiwygSpellingProjector().project(
      document: document,
      languageId: 'en-CA',
      snapshot: _snapshot,
      documentGeneration: 3,
    );
    expect(sourceProjection.complete, isTrue, reason: sourceProjection.message);
    expect(rich.complete, isTrue, reason: rich.message);
    for (final projection in [sourceProjection, rich]) {
      expect(projection.runs.every((run) => run.hasValidMapping), isTrue);
      final reference = projection.runs.singleWhere(
        (run) => run.text == 'Reference #',
      );
      expect(
        reference.atoms.first.context,
        SpellingSourceContext.markdownTableCell,
      );
      expect(
        projection.runs.any((run) => run.text.contains('example.test')),
        isFalse,
      );
      final finalRun = projection.runs.singleWhere(
        (run) => run.text.contains('helo'),
      );
      final plan = const SpellingReplacementPlanner().build(
        occurrence: _rejected(finalRun, 'helo'),
        suggestion: 'hello',
      );
      expect(plan.applyToSource(source), source.replaceFirst('helo', 'hello'));
    }
    final reference = rich.runs.singleWhere((run) => run.text == 'Reference #');
    expect(reference.target, isA<SpellingRichTableCellTarget>());
    final finalRun = rich.runs.singleWhere((run) => run.text.contains('helo'));
    expect(finalRun.target, isA<SpellingRichBlockTarget>());
    final target = finalRun.target as SpellingRichBlockTarget;
    expect(target.blockId, document.blocks.last.id);
    expect(target.documentGeneration, 3);
    final occurrence = _rejected(finalRun, 'helo');
    expect(
      occurrence.fieldStart,
      document.blocks.last.plainText.indexOf('helo'),
    );
    expect(
      occurrence.fieldEnd,
      document.blocks.last.plainText.indexOf('helo') + 4,
    );
  });

  test('closing hashes are heading syntax only in an ATX heading', () {
    final projection = const MarkdownSpellingProjector().project(
      filePath: '/hash.md',
      source: 'Reference #\n\n## Heading #\n',
      mode: MarkdownMode.gfm,
      languageId: 'en-US',
      snapshot: _snapshot,
    );
    expect(projection.complete, isTrue);
    expect(projection.runs.map((run) => run.text), ['Reference #', 'Heading']);
  });

  group('Markdown spelling projection', () {
    test('keeps literal unresolved and invalid apparent links checkable', () {
      for (final source in [
        '[hello][wrld]',
        '[hello](wrld text)',
        'before [hello][wrld] after',
      ]) {
        final result = const MarkdownSpellingProjector().project(
          filePath: '/tmp/literal-links.md',
          source: source,
          mode: MarkdownMode.commonMark,
          languageId: 'en-Test',
          snapshot: _snapshot,
        );
        expect(result.complete, isTrue, reason: source);
        expect(result.runs.every((run) => run.hasValidMapping), isTrue);
        final text = result.runs.map((run) => run.text).join(' ');
        expect(text, contains('hello'), reason: source);
        expect(text, contains('wrld'), reason: source);
        final run = result.runs.firstWhere((run) => run.text.contains('wrld'));
        final occurrence = _rejected(run, 'wrld');
        expect(
          source.substring(occurrence.sourceStart!, occurrence.sourceEnd!),
          'wrld',
        );
        expect(
          const SpellingReplacementPlanner()
              .build(occurrence: occurrence, suggestion: 'world')
              .applyToSource(source),
          source.replaceFirst('wrld', 'world'),
        );
      }
    });

    test(
      'resolves only parser-recognized links and images across revisions',
      () {
        final cases = <({String source, bool literalReference, bool hasTitle})>[
          (
            source: '[helo](target "titl")',
            literalReference: false,
            hasTitle: true,
          ),
          (source: '[helo][wrld]', literalReference: true, hasTitle: false),
          (
            source: '[helo][wrld]\n\n[wrld]: /target',
            literalReference: false,
            hasTitle: false,
          ),
          (source: '[helo][]', literalReference: true, hasTitle: false),
          (
            source: '[helo][]\n\n[helo]: /target',
            literalReference: false,
            hasTitle: false,
          ),
          (source: '[helo]', literalReference: true, hasTitle: false),
          (
            source: '[helo]\n\n[helo]: /target',
            literalReference: false,
            hasTitle: false,
          ),
          (
            source: '![alttern](path "titl")',
            literalReference: false,
            hasTitle: true,
          ),
          (
            source: '![alttern][id]\n\n[id]: /path',
            literalReference: false,
            hasTitle: false,
          ),
          (source: '![alttern][id]', literalReference: true, hasTitle: false),
          (source: r'\[helo\][wrld]', literalReference: true, hasTitle: false),
        ];
        for (final (index, fixture) in cases.indexed) {
          final result = const MarkdownSpellingProjector().project(
            filePath: '/tmp/reference-revision.md',
            source: fixture.source,
            mode: MarkdownMode.commonMark,
            languageId: 'en-Test',
            snapshot: SpellingSnapshotIdentity(
              bufferId: 'reference-revision',
              contentRevision: index,
              documentKind: DocumentKind.markdown,
              contextGeneration: 1,
            ),
          );
          expect(result.complete, isTrue, reason: fixture.source);
          expect(result.runs.every((run) => run.hasValidMapping), isTrue);
          final all = result.runs.map((run) => run.text).join(' ');
          expect(
            all,
            contains(fixture.source.startsWith('!') ? 'alttern' : 'helo'),
            reason: fixture.source,
          );
          if (fixture.source.contains('[wrld]')) {
            expect(
              all.contains('wrld'),
              fixture.literalReference,
              reason: fixture.source,
            );
          }
          if (fixture.hasTitle) {
            expect(all, contains('titl'), reason: fixture.source);
          }
          if (fixture.source.contains('/target')) {
            expect(all, isNot(contains('/target')));
          }
          if (fixture.source.contains('/path')) {
            expect(all, isNot(contains('/path')));
          }
          if (fixture.source.contains('![alttern](path')) {
            expect(all, isNot(contains('path')));
          }
          if (fixture.source.startsWith('![alttern][id]')) {
            expect(
              all.contains('id'),
              fixture.literalReference,
              reason: fixture.source,
            );
          }
        }
      },
    );

    test('keeps literal trailing braces in paragraph and heading prose', () {
      for (final mode in MarkdownMode.values) {
        for (final source in [
          'Use {wrld}',
          '# Use {wrld}',
          '# Use {*wrld*}',
          '# Use {**wrld**}',
          '# Use {w&#114;ld}',
          '# Use {id="anchor"} {wrld}',
        ]) {
          final result = const MarkdownSpellingProjector().project(
            filePath: '/tmp/braces.md',
            source: source,
            mode: mode,
            languageId: 'en-Test',
            snapshot: _snapshot,
          );
          expect(result.complete, isTrue, reason: '$mode: $source');
          expect(result.runs.every((run) => run.hasValidMapping), isTrue);
          final run = result.runs.firstWhere(
            (run) => run.text.contains('wrld'),
          );
          final occurrence = _rejected(run, 'wrld');
          expect(
            source.substring(occurrence.sourceStart!, occurrence.sourceEnd!),
            source.contains('&#114;') ? 'w&#114;ld' : 'wrld',
          );
          expect(
            const SpellingReplacementPlanner()
                .build(occurrence: occurrence, suggestion: 'world')
                .applyToSource(source),
            source.contains('&#114;')
                ? '# Use {world}'
                : source.replaceFirst('wrld', 'world'),
          );
        }
      }
    });

    test('binds recognized images to their exact source occurrence', () {
      for (final (revision, source) in [
        '![helo][wrld] ![helo](image.png)',
        '![helo](image.png) ![helo][wrld]',
        '![**helo**](diagrm.png)',
        '![w&#114;ld](diagrm.png)',
        '![helo][wrld] ![helo](image.png)\n\n[wrld]: /diagram.png',
        '![helo][wrld] ![helo](image.png)',
      ].indexed) {
        final result = const MarkdownSpellingProjector().project(
          filePath: '/tmp/images.md',
          source: source,
          mode: MarkdownMode.commonMark,
          languageId: 'en-Test',
          snapshot: SpellingSnapshotIdentity(
            bufferId: 'image-revisions',
            contentRevision: revision,
            documentKind: DocumentKind.markdown,
            contextGeneration: 1,
          ),
        );
        expect(result.complete, isTrue, reason: source);
        expect(result.runs.every((run) => run.hasValidMapping), isTrue);
        final all = result.runs.map((run) => run.text).join(' ');
        expect(all, isNot(contains('diagrm.png')), reason: source);
        expect(all, isNot(contains('image.png')), reason: source);
        if (source.contains('[wrld]') && !source.contains('[wrld]:')) {
          expect(all, contains('wrld'), reason: source);
          final occurrence = _rejected(
            result.runs.firstWhere((run) => run.text.contains('wrld')),
            'wrld',
          );
          expect(
            const SpellingReplacementPlanner()
                .build(occurrence: occurrence, suggestion: 'world')
                .applyToSource(source),
            source.replaceFirst('wrld', 'world'),
          );
        }
        if (source.contains('[wrld]:')) {
          expect(all, isNot(contains('wrld')), reason: source);
        }
        if (source.contains('**helo**')) {
          expect(all, contains('helo'));
          final occurrence = _rejected(
            result.runs.firstWhere((run) => run.text.contains('helo')),
            'helo',
          );
          expect(
            const SpellingReplacementPlanner()
                .build(occurrence: occurrence, suggestion: 'hello')
                .applyToSource(source),
            '![**hello**](diagrm.png)',
          );
        }
        if (source.contains('&#114;')) {
          expect(all, contains('wrld'));
          final occurrence = _rejected(
            result.runs.firstWhere((run) => run.text.contains('wrld')),
            'wrld',
          );
          expect(
            const SpellingReplacementPlanner()
                .build(occurrence: occurrence, suggestion: 'world')
                .applyToSource(source),
            '![world](diagrm.png)',
          );
        }
      }
    });

    test('orders formatting from image labels and surrounding body', () {
      for (final (source, expectedImage) in [
        ('![hel**l**o](image.png) **text**', 'hello'),
        ('**text** ![hel**l**o](image.png)', 'hello'),
        ('![hel**l**o](one.png) **text** ![w**r**ld](two.png)', 'wrld'),
      ]) {
        final result = const MarkdownSpellingProjector().project(
          filePath: '/tmp/formatted-images.md',
          source: source,
          mode: MarkdownMode.commonMark,
          languageId: 'en-Test',
          snapshot: _snapshot,
        );
        expect(result.complete, isTrue, reason: source);
        expect(result.runs.every((run) => run.hasValidMapping), isTrue);
        final all = result.runs.map((run) => run.text).join(' ');
        expect(
          result.runs.map((run) => run.text),
          contains(expectedImage),
          reason: source,
        );
        expect(result.runs.map((run) => run.text.trim()), contains('text'));
        expect(all, isNot(contains('**')), reason: source);
        expect(all, isNot(contains('.png')), reason: source);
      }
      const misspelled = '![w**r**ld](image.png) **text**';
      final result = const MarkdownSpellingProjector().project(
        filePath: '/tmp/formatted-images.md',
        source: misspelled,
        mode: MarkdownMode.commonMark,
        languageId: 'en-Test',
        snapshot: _snapshot,
      );
      final image = result.runs.firstWhere((run) => run.text == 'wrld');
      expect(
        const SpellingReplacementPlanner()
            .build(occurrence: _rejected(image, 'wrld'), suggestion: 'world')
            .applyToSource(misspelled),
        '![wo**r**ld](image.png) **text**',
      );
    });

    test('recognizes nested syntax inside exact image descriptions', () {
      for (final (source, visible, hidden) in [
        ('![a [wrld](diagrm.md)](image.png)', 'a wrld', 'diagrm.md'),
        ('![a ![wrld](diagrm.png)](image.png)', 'a wrld', 'diagrm.png'),
        ('![a [wrld][missing]](image.png)', 'wrld', 'missing'),
      ]) {
        final result = const MarkdownSpellingProjector().project(
          filePath: '/tmp/nested-image.md',
          source: source,
          mode: MarkdownMode.commonMark,
          languageId: 'en-Test',
          snapshot: _snapshot,
        );
        expect(result.complete, isTrue, reason: source);
        expect(result.runs.every((run) => run.hasValidMapping), isTrue);
        final all = result.runs.map((run) => run.text).join(' ');
        if (source.contains('![wrld]')) {
          expect(all, contains('a'), reason: source);
          expect(all, contains('wrld'), reason: source);
        } else {
          expect(all, contains(visible), reason: source);
        }
        if (!source.contains('[missing]')) {
          expect(all, isNot(contains(hidden)), reason: source);
        } else {
          expect(all, contains(hidden), reason: source);
        }
        expect(all, isNot(contains('image.png')), reason: source);
        final occurrence = _rejected(
          result.runs.firstWhere((run) => run.text.contains('wrld')),
          'wrld',
        );
        expect(
          source.substring(occurrence.sourceStart!, occurrence.sourceEnd!),
          'wrld',
        );
        expect(
          const SpellingReplacementPlanner()
              .build(occurrence: occurrence, suggestion: 'world')
              .applyToSource(source),
          source.replaceFirst('wrld', 'world'),
        );
      }
    });

    test(
      'excludes only trailing attributes recognized by the current mode',
      () {
        for (final mode in MarkdownMode.values) {
          for (final source in [
            'Use {id="wrld"}',
            '# Use {id="wrld"',
            '# Use {class="wrld"}',
          ]) {
            final result = const MarkdownSpellingProjector().project(
              filePath: '/tmp/attribute-mode.md',
              source: source,
              mode: mode,
              languageId: 'en-Test',
              snapshot: _snapshot,
            );
            expect(result.complete, isTrue, reason: '$mode: $source');
            expect(result.runs.every((run) => run.hasValidMapping), isTrue);
            final containsWord = result.runs.any(
              (run) => run.text.contains('wrld'),
            );
            final recognized =
                source.startsWith('# Use {class=') &&
                mode == MarkdownMode.writersideMarkdown;
            expect(containsWord, !recognized, reason: '$mode: $source');
          }
          final recognizedId = const MarkdownSpellingProjector().project(
            filePath: '/tmp/attribute-mode.md',
            source: '# Use {id="technical"}',
            mode: mode,
            languageId: 'en-Test',
            snapshot: _snapshot,
          );
          expect(recognizedId.complete, isTrue);
          expect(recognizedId.runs.every((run) => run.hasValidMapping), isTrue);
          expect(
            recognizedId.runs.map((run) => run.text).join(' '),
            isNot(contains('technical')),
            reason: '$mode',
          );
        }
      },
    );

    test('metadata does not split a surrounding Markdown word', () {
      for (final source in [
        'docu[men](target "titl")tation',
        'docu<span title="titl">men</span>tation',
      ]) {
        final result = const MarkdownSpellingProjector().project(
          filePath: '/tmp/metadata.md',
          source: source,
          mode: MarkdownMode.commonMark,
          languageId: 'en-Test',
          snapshot: _snapshot,
        );
        expect(result.complete, isTrue, reason: source);
        expect(result.runs.every((run) => run.hasValidMapping), isTrue);
        expect(result.runs.map((run) => run.text), contains('documentation'));
        expect(result.runs.map((run) => run.text), contains('titl'));
      }
    });

    test('corrects a Markdown body word across independent metadata', () {
      for (final source in [
        'docu[men](target "titl")taton',
        'docu<span title="titl">men</span>taton',
      ]) {
        final result = const MarkdownSpellingProjector().project(
          filePath: '/tmp/metadata-correction.md',
          source: source,
          mode: MarkdownMode.commonMark,
          languageId: 'en-Test',
          snapshot: _snapshot,
        );
        expect(result.complete, isTrue);
        expect(result.runs.every((run) => run.hasValidMapping), isTrue);
        final body = result.runs.singleWhere(
          (run) => run.text == 'documentaton',
        );
        final plan = const SpellingReplacementPlanner().build(
          occurrence: _rejected(body, 'documentaton'),
          suggestion: 'documentation',
        );
        expect(
          plan.applyToSource(source),
          source.replaceFirst('taton', 'tation'),
        );
        final title = result.runs.singleWhere((run) => run.text == 'titl');
        expect(
          const SpellingReplacementPlanner()
              .build(occurrence: _rejected(title, 'titl'), suggestion: 'title')
              .applyToSource(source),
          source.replaceFirst('"titl"', '"title"'),
        );
      }
    });

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

    test('excludes a fenced code block nested in a block quote', () {
      const source = '''> ```java
> record Document(String title, String content) {}
> ```

Visiblee prose.
''';
      final result = const MarkdownSpellingProjector().project(
        filePath: '/tmp/quoted-code.md',
        source: source,
        mode: MarkdownMode.commonMark,
        languageId: 'en-CA',
        snapshot: _snapshot,
      );
      final all = result.runs.map((run) => run.text).join('\n');

      expect(result.complete, isTrue, reason: result.message);
      expect(all, contains('Visiblee prose.'));
      expect(all, isNot(contains('record Document')));
      for (final quoted in [
        '> ```\n> code\n> ```\n>\n> wrld\n',
        '> > ```\n> > code\n>\n> wrld\n',
      ]) {
        final parsed = const MarkdownParser().parse(
          filePath: '/tmp/quoted-code.md',
          source: quoted,
          mode: MarkdownMode.commonMark,
        );
        expect(parsed.busyDocument.blocks.first.kind, BusyBlockKind.blockquote);
        final outer = parsed.busyDocument.blocks.first;
        if (quoted.startsWith('> >')) {
          expect(outer.children.first.kind, BusyBlockKind.blockquote);
          expect(
            outer.children.first.children.any(
              (child) => child.kind == BusyBlockKind.codeBlock,
            ),
            isTrue,
          );
        } else {
          expect(
            outer.children.any(
              (child) => child.kind == BusyBlockKind.codeBlock,
            ),
            isTrue,
          );
        }
        expect(
          outer.children.any(
            (child) =>
                child.kind == BusyBlockKind.paragraph &&
                child.plainText == 'wrld',
          ),
          isTrue,
        );
        final projected = const MarkdownSpellingProjector().project(
          filePath: '/tmp/quoted-code.md',
          source: quoted,
          mode: MarkdownMode.commonMark,
          languageId: 'en-Test',
          snapshot: _snapshot,
        );
        expect(projected.complete, isTrue, reason: quoted);
        expect(projected.runs.every((run) => run.hasValidMapping), isTrue);
        final visible = projected.runs.map((run) => run.text).join(' ');
        expect(visible, contains('wrld'), reason: quoted);
        expect(visible, isNot(contains('code')), reason: quoted);
        final occurrence = _rejected(
          projected.runs.firstWhere((run) => run.text.contains('wrld')),
          'wrld',
        );
        expect(
          const SpellingReplacementPlanner()
              .build(occurrence: occurrence, suggestion: 'world')
              .applyToSource(quoted),
          quoted.replaceFirst('wrld', 'world'),
        );
      }
      for (final unclosed in [
        '> ```\n> code\n\nwrld\n',
        '> > ```\n> > code\n\nwrld\n',
        '> - ```\n>   code\n>\n> wrld\n',
        '- ```\n  code\n\nwrld\n',
        '- > ```\n  > code\n\nwrld\n',
      ]) {
        final projected = const MarkdownSpellingProjector().project(
          filePath: '/tmp/unclosed-code.md',
          source: unclosed,
          mode: MarkdownMode.commonMark,
          languageId: 'en-Test',
          snapshot: _snapshot,
        );
        expect(projected.complete, isTrue, reason: unclosed);
        expect(projected.runs.every((run) => run.hasValidMapping), isTrue);
        final visible = projected.runs.map((run) => run.text).join(' ');
        expect(visible, contains('wrld'), reason: unclosed);
        expect(visible, isNot(contains('code')), reason: unclosed);
        final run = projected.runs.firstWhere(
          (run) => run.text.contains('wrld'),
        );
        final occurrence = _rejected(run, 'wrld');
        expect(
          unclosed.substring(occurrence.sourceStart!, occurrence.sourceEnd!),
          'wrld',
        );
        expect(
          const SpellingReplacementPlanner()
              .build(occurrence: occurrence, suggestion: 'world')
              .applyToSource(unclosed),
          unclosed.replaceFirst('wrld', 'world'),
        );
      }
      for (final mixed in [
        '- > ```\n  > code\n  > ```\n  >\n  > wrld\n',
        '> ```\n> > ```\n> code\n> ```\n>\n> wrld\n',
      ]) {
        final parsed = const MarkdownParser().parse(
          filePath: '/tmp/mixed-fence.md',
          source: mixed,
          mode: MarkdownMode.commonMark,
        );
        bool containsKind(BusyBlock block, BusyBlockKind kind) =>
            block.kind == kind ||
            block.children.any((child) => containsKind(child, kind));
        bool containsProse(BusyBlock block) =>
            block.kind == BusyBlockKind.paragraph &&
                block.plainText.contains('wrld') ||
            block.children.any(containsProse);
        expect(
          parsed.busyDocument.blocks.any(
            (block) => containsKind(block, BusyBlockKind.codeBlock),
          ),
          isTrue,
          reason: mixed,
        );
        expect(
          parsed.busyDocument.blocks.any(containsProse),
          isTrue,
          reason: mixed,
        );
        final projected = const MarkdownSpellingProjector().project(
          filePath: '/tmp/mixed-fence.md',
          source: mixed,
          mode: MarkdownMode.commonMark,
          languageId: 'en-Test',
          snapshot: _snapshot,
        );
        expect(projected.complete, isTrue, reason: mixed);
        expect(projected.runs.every((run) => run.hasValidMapping), isTrue);
        final visible = projected.runs.map((run) => run.text).join(' ');
        expect(visible, contains('wrld'), reason: mixed);
        expect(visible, isNot(contains('code')), reason: mixed);
        final occurrence = _rejected(
          projected.runs.firstWhere((run) => run.text.contains('wrld')),
          'wrld',
        );
        expect(
          const SpellingReplacementPlanner()
              .build(occurrence: occurrence, suggestion: 'world')
              .applyToSource(mixed),
          mixed.replaceFirst('wrld', 'world'),
        );
      }
    });

    test('keeps quoted list fences across blank continuations', () {
      for (final blank in ['>', '>  ']) {
        final source =
            '> - ```\n>   code\n$blank\n>   more\n>   ```\n>\n>   wrld\n';
        _expectCodeFenceBeforeWrld(source, ['code', 'more']);
      }
    });

    test('counts tab columns in list fence continuations', () {
      const tabbed = '- ```\n\tcode\n  ```\n\n  wrld\n';
      const spaces = '- ```\n    code\n  ```\n\n  wrld\n';
      const quoted = '> - ```\n> \tcode\n>   ```\n>\n>   wrld\n';
      const indentedFence = '- ```\n\t\t```\n  more\n  ```\n\n  wrld\n';
      expect(tabbed.codeUnitAt(tabbed.indexOf('\n') + 1), 0x09);
      expect(quoted.codeUnitAt(quoted.indexOf('\n') + 3), 0x09);
      for (final source in [tabbed, spaces, quoted]) {
        _expectCodeFenceBeforeWrld(source, ['code']);
      }
      _expectCodeFenceBeforeWrld(indentedFence, ['more']);
      const insufficient = '- > ```\n  code\n\nwrld\n';
      final parsed = const MarkdownParser().parse(
        filePath: '/tmp/insufficient-list-indent.md',
        source: insufficient,
        mode: MarkdownMode.commonMark,
      );
      expect(parsed.busyDocument.blocks.first.plainText.trim(), 'code');
      expect(parsed.busyDocument.blocks.last.plainText, 'wrld');
      final projected = const MarkdownSpellingProjector().project(
        filePath: '/tmp/insufficient-list-indent.md',
        source: insufficient,
        mode: MarkdownMode.commonMark,
        languageId: 'en-Test',
        snapshot: _snapshot,
      );
      expect(projected.complete, isTrue);
      expect(projected.runs.every((run) => run.hasValidMapping), isTrue);
      final visible = projected.runs.map((run) => run.text).join(' ');
      expect(visible, contains('code'));
      expect(visible, contains('wrld'));
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

    test('preserves semantic HTML boundaries and multiline exclusions', () {
      const source = '''<div><p>hello</p><p>world</p></div>
<p>before<br>after<br/>again<br />last</p>
<div title="Readablee title">left<code>hiddenword</code>right</div>
<p>above<script>
hidden script prose
</script>below</p>
<style>
hidden style prose
</style><p>visible</p>
''';
      final projected = const MarkdownSpellingProjector().project(
        filePath: '/tmp/html.md',
        source: source,
        mode: MarkdownMode.commonMark,
        languageId: 'en-US',
        snapshot: _snapshot,
      );
      final texts = projected.runs.map((run) => run.text).toList();
      final all = texts.join('\n');

      expect(projected.complete, isTrue, reason: projected.message);
      expect(texts, containsAll(['hello', 'world']));
      expect(all, isNot(contains('helloworld')));
      expect(texts, containsAll(['before', 'after', 'again', 'last']));
      expect(all, isNot(contains('beforeafter')));
      expect(texts, contains('Readablee title'));
      expect(
        texts,
        containsAll(['left', 'right', 'above', 'below', 'visible']),
      );
      expect(all, isNot(contains('leftright')));
      expect(all, isNot(contains('hiddenword')));
      expect(all, isNot(contains('hidden script prose')));
      expect(all, isNot(contains('hidden style prose')));
      for (final run in projected.runs) {
        expect(run.hasValidMapping, isTrue);
      }
    });

    test('keeps comparison prose and scans multiline HTML tags exactly', () {
      const source = '''Before 2 < 3, mispelled > 1 and x <= y.
<div
  title="Readablee > prose"
  data-id="technicall"
  id="wrongg"
  class="mistakke"
  data-url="https://example.test/typpo"
>visiblee</div>
''';
      final projected = const MarkdownSpellingProjector().project(
        filePath: '/tmp/multiline-html.md',
        source: source,
        mode: MarkdownMode.commonMark,
        languageId: 'en-US',
        snapshot: _snapshot,
      );
      final all = projected.runs.map((run) => run.text).join('\n');
      expect(projected.complete, isTrue, reason: projected.message);
      expect(all, contains('mispelled'));
      expect(all, contains('Readablee > prose'));
      expect(all, contains('visiblee'));
      expect(all, isNot(contains('technicall')));
      expect(all, isNot(contains('wrongg')));
      expect(all, isNot(contains('mistakke')));
      expect(all, isNot(contains('typpo')));

      final run = projected.runs.singleWhere(
        (candidate) => candidate.text.contains('mispelled'),
      );
      final corrected = const SpellingReplacementPlanner()
          .build(
            occurrence: _rejected(run, 'mispelled'),
            suggestion: 'misspelled',
          )
          .applyToSource(source);
      expect(corrected, source.replaceFirst('mispelled', 'misspelled'));
    });

    test('keeps escaped multiline tag-like prose checkable', () {
      for (final source in [
        r'\<span'
            '\nwrld>\n',
        r'\\\<span'
            '\nwrld>\n',
        r'\<span'
            '\n title="wrld" data-id="hidden">body\n',
      ]) {
        expect(md.markdownToHtml(source), contains('&lt;span'));
        final result = const MarkdownSpellingProjector().project(
          filePath: '/tmp/escaped-multiline-tag.md',
          source: source,
          mode: MarkdownMode.commonMark,
          languageId: 'en-Test',
          snapshot: _snapshot,
        );
        expect(result.complete, isTrue, reason: source);
        expect(result.runs.every((run) => run.hasValidMapping), isTrue);
        expect(result.runs.map((run) => run.text).join(' '), contains('wrld'));
        expect(
          result.runs.where((run) => run.text.contains('wrld')),
          hasLength(1),
          reason: source,
        );
        final occurrence = _rejected(
          result.runs.firstWhere((run) => run.text.contains('wrld')),
          'wrld',
        );
        expect(
          const SpellingReplacementPlanner()
              .build(occurrence: occurrence, suggestion: 'world')
              .applyToSource(source),
          source.replaceFirst('wrld', 'world'),
        );
      }
      const real =
          r'\\<span'
          '\n title="wrld" data-id="hidden">body</span>\n';
      expect(md.markdownToHtml(real), contains('<span\n'));
      final result = const MarkdownSpellingProjector().project(
        filePath: '/tmp/real-multiline-tag.md',
        source: real,
        mode: MarkdownMode.commonMark,
        languageId: 'en-Test',
        snapshot: _snapshot,
      );
      expect(result.complete, isTrue);
      expect(result.runs.every((run) => run.hasValidMapping), isTrue);
      final all = result.runs.map((run) => run.text).join(' ');
      expect(all, contains('wrld'));
      expect(all, contains('body'));
      expect(all, isNot(contains('hidden')));
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

    test('validates formatting gaps in regional coordinates', () {
      for (final source in ['he**llo**x\n', 'intro\n\nhe**llo**x\n']) {
        final projected = const MarkdownSpellingProjector().project(
          filePath: '/tmp/regional.md',
          source: source,
          mode: MarkdownMode.commonMark,
          languageId: 'en-US',
          snapshot: _snapshot,
        );
        final run = projected.runs.firstWhere(
          (candidate) => candidate.text == 'hellox',
        );

        expect(
          const SpellingReplacementPlanner()
              .build(occurrence: _rejected(run, 'hellox'), suggestion: 'hello')
              .applyToSource(source),
          source.replaceFirst('he**llo**x', 'he**llo**'),
        );
      }
    });

    test('accepts canonically equivalent mapped replacement text', () {
      const source = 'prefix\n\ncafe\u0301x\n';
      final projected = const MarkdownSpellingProjector().project(
        filePath: '/tmp/unicode.md',
        source: source,
        mode: MarkdownMode.commonMark,
        languageId: 'en-US',
        snapshot: _snapshot,
      );
      final run = projected.runs.singleWhere(
        (candidate) => candidate.text.contains('cafe\u0301x'),
      );

      expect(
        const SpellingReplacementPlanner()
            .build(
              occurrence: _rejected(run, 'cafe\u0301x'),
              suggestion: 'café',
            )
            .applyToSource(source),
        'prefix\n\ncafe\u0301\n',
      );
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

    test('recognized link and image titles use their authored boundaries', () {
      for (final (source, kind) in [
        ('[hello](diagrm.md (wrld))', BusyInlineKind.link),
        ('[hello](diagrm.md "wrld)")', BusyInlineKind.link),
        ('![hello](diagrm.png (wrld))', BusyInlineKind.image),
        ('[hello](wrld.md "wrld")', BusyInlineKind.link),
        ('[he`[`llo](diagrm.md "wrld")', BusyInlineKind.link),
      ]) {
        expect(_parserHasInline(source, kind), isTrue, reason: source);
        final result = const MarkdownSpellingProjector().project(
          filePath: '/tmp/recognized-title.md',
          source: source,
          mode: MarkdownMode.commonMark,
          languageId: 'en-Test',
          snapshot: _snapshot,
        );
        expect(result.complete, isTrue, reason: source);
        expect(result.runs.every((run) => run.hasValidMapping), isTrue);
        final all = result.runs.map((run) => run.text).join(' ');
        if (source.contains('`[`')) {
          expect(all, contains('he'), reason: source);
          expect(all, contains('llo'), reason: source);
        } else {
          expect(all, contains('hello'), reason: source);
        }
        expect(all, contains('wrld'), reason: source);
        expect(all, isNot(contains('diagrm')), reason: source);
        expect(all, isNot(contains('wrld.md')), reason: source);
        final occurrence = _rejected(
          result.runs.firstWhere((run) => run.text.contains('wrld')),
          'wrld',
        );
        final titleOffset = source.lastIndexOf('wrld');
        expect(occurrence.sourceStart, titleOffset, reason: source);
        expect(
          const SpellingReplacementPlanner()
              .build(occurrence: occurrence, suggestion: 'world')
              .applyToSource(source),
          source.replaceRange(titleOffset, titleOffset + 4, 'world'),
        );
      }
    });

    test('destination-only links and images do not expose a false title', () {
      for (final (source, kind) in [
        ('[helo]( (wrld))', BusyInlineKind.link),
        ('![helo]( (wrld))', BusyInlineKind.image),
        ('[helo]( ("wrld"))', BusyInlineKind.link),
        ("![helo]( ('wrld'))", BusyInlineKind.image),
      ]) {
        expect(_parserHasInline(source, kind), isTrue, reason: source);
        final result = const MarkdownSpellingProjector().project(
          filePath: '/tmp/destination-only.md',
          source: source,
          mode: MarkdownMode.commonMark,
          languageId: 'en-Test',
          snapshot: _snapshot,
        );
        expect(result.complete, isTrue, reason: source);
        expect(result.runs.every((run) => run.hasValidMapping), isTrue);
        final all = result.runs.map((run) => run.text).join(' ');
        expect(all, contains('helo'), reason: source);
        expect(all, isNot(contains('wrld')), reason: source);
        final occurrence = _rejected(
          result.runs.firstWhere((run) => run.text.contains('helo')),
          'helo',
        );
        expect(occurrence.sourceStart, source.indexOf('helo'));
        expect(
          const SpellingReplacementPlanner()
              .build(occurrence: occurrence, suggestion: 'hello')
              .applyToSource(source),
          source.replaceFirst('helo', 'hello'),
        );
      }
    });

    test('recognized multiline links consume one mapped occurrence', () {
      for (final (source, kind) in [
        ('[hello](\ndiagrm.md\n"wrld"\n)\n', BusyInlineKind.link),
        ('[hello](\r\ndiagrm.md\r\n"wrld"\r\n)\r\n', BusyInlineKind.link),
        (
          '> - [hello](\n>   diagrm.md\n>   "wrld"\n>   )\n',
          BusyInlineKind.link,
        ),
        ('![hello](\ndiagrm.png\n"wrld"\n)\n', BusyInlineKind.image),
      ]) {
        expect(_parserHasInline(source, kind), isTrue);
        final result = const MarkdownSpellingProjector().project(
          filePath: '/tmp/multiline-link.md',
          source: source,
          mode: MarkdownMode.commonMark,
          languageId: 'en-Test',
          snapshot: _snapshot,
        );
        expect(result.complete, isTrue, reason: source);
        expect(result.runs.every((run) => run.hasValidMapping), isTrue);
        final all = result.runs.map((run) => run.text).join(' ');
        expect(all, contains('hello'), reason: source);
        expect(all, contains('wrld'), reason: source);
        expect(all, isNot(contains('diagrm')), reason: source);
        final occurrence = _rejected(
          result.runs.firstWhere((run) => run.text.contains('wrld')),
          'wrld',
        );
        expect(
          const SpellingReplacementPlanner()
              .build(occurrence: occurrence, suggestion: 'world')
              .applyToSource(source),
          source.replaceFirst('wrld', 'world'),
        );
      }
    });

    test('multiline link labels keep container prefixes out of prose', () {
      for (final source in [
        '> [helo\n> wrld](target)\n',
        '> [helo\r\n> wrld](target)\r\n',
        '- [helo\n  wrld](target)\n',
      ]) {
        final parsed = const MarkdownParser().parse(
          filePath: '/tmp/multiline-label.md',
          source: source,
          mode: MarkdownMode.commonMark,
        );
        final projected = const MarkdownSpellingProjector().project(
          filePath: '/tmp/multiline-label.md',
          source: source,
          mode: MarkdownMode.commonMark,
          languageId: 'en-Test',
          snapshot: _snapshot,
        );
        final rich = const WysiwygSpellingProjector().project(
          document: parsed.busyDocument,
          languageId: 'en-Test',
          snapshot: _snapshot,
          documentGeneration: 1,
        );
        expect(projected.complete, isTrue, reason: source);
        expect(rich.complete, isTrue, reason: source);
        expect(projected.runs.every((run) => run.hasValidMapping), isTrue);
        expect(rich.runs.every((run) => run.hasValidMapping), isTrue);
        final prose = projected.runs.map((run) => run.text).join(' ');
        expect(prose, contains('helo'));
        expect(prose, contains('wrld'));
        expect(prose, isNot(contains('>')));
        expect(prose, isNot(contains('target')));
        expect(rich.runs.map((run) => run.text).join(' '), prose);
        final word = _rejected(
          projected.runs.singleWhere((run) => run.text.contains('wrld')),
          'wrld',
        );
        expect(word.sourceStart, source.indexOf('wrld'));
        expect(
          const SpellingReplacementPlanner()
              .build(occurrence: word, suggestion: 'world')
              .applyToSource(source),
          source.replaceFirst('wrld', 'world'),
        );
        final richWord = _rejected(
          rich.runs.singleWhere((run) => run.text.contains('wrld')),
          'wrld',
        );
        expect(richWord.run.target, isA<SpellingRichBlockTarget>());
        expect(richWord.sourceStart, source.indexOf('wrld'));
        expect(
          const SpellingReplacementPlanner()
              .build(occurrence: richWord, suggestion: 'world')
              .applyToSource(source),
          source.replaceFirst('wrld', 'world'),
        );
      }
    });

    test('multiline mapped labels agree with rich prose and corrections', () {
      for (final (source, expected) in [
        ('> - [helo\n>   wrld](target)\n', 'helo wrld'),
        ('> - [helo\r\n>   wrld](target)\r\n', 'helo wrld'),
        ('> [helo\\\n> wrld](target)\n', 'helo wrld'),
        ('> [helo  \n> wrld](target)\n', 'helo wrld'),
        ('> [helo\\\r\n> wrld](target)\r\n', 'helo wrld'),
        ('> [helo\n> wrld](target)\n', 'helo wrld'),
        ('> [helo \n> wrld](target)\n', 'helo wrld'),
        ('> [helo\\\n> middle \n> wrld](target)\n', 'helo middle wrld'),
        ('- > [helo\n  > wrld](target)\n', 'helo wrld'),
        ('> - [**helo**\n>   wrld](target)\n', 'helo wrld'),
        ('> [helo  there\n> wrld](target)\n', 'helo  there wrld'),
        ('> ![helo\n> wrld](target)\n', 'helo wrld'),
        ('> - ![helo\n>   wrld](target)\n', 'helo wrld'),
        ('> ![helo\\\n> wrld](target)\n', 'helowrld'),
        ('> - ![helo\\\n>   wrld](target)\n', 'helowrld'),
        ('> ![helo  \n> wrld](target)\n', 'helowrld'),
        ('> ![helo  there\n> wrld](target)\n', 'helo  there wrld'),
        ('> ![helo\\\n> middle \n> wrld](target)\n', 'helomiddle wrld'),
      ]) {
        final kind = source.contains('![')
            ? BusyInlineKind.image
            : BusyInlineKind.link;
        expect(_parserHasInline(source, kind), isTrue, reason: source);
        final parsed = const MarkdownParser().parse(
          filePath: '/tmp/multiline-label-invariant.md',
          source: source,
          mode: MarkdownMode.commonMark,
        );
        final projected = const MarkdownSpellingProjector().project(
          filePath: '/tmp/multiline-label-invariant.md',
          source: source,
          mode: MarkdownMode.commonMark,
          languageId: 'en-Test',
          snapshot: _snapshot,
        );
        final rich = const WysiwygSpellingProjector().project(
          document: parsed.busyDocument,
          languageId: 'en-Test',
          snapshot: _snapshot,
          documentGeneration: 1,
        );
        final sourceText = projected.runs.map((run) => run.text).join(' ');
        final richText = rich.runs.map((run) => run.text).join(' ');
        expect(projected.complete, isTrue, reason: source);
        expect(rich.complete, isTrue, reason: source);
        expect(projected.runs.every((run) => run.hasValidMapping), isTrue);
        expect(rich.runs.every((run) => run.hasValidMapping), isTrue);
        expect(sourceText, expected, reason: source);
        expect(richText, sourceText, reason: source);
        expect(sourceText, isNot(contains('target')), reason: source);
        for (final run in [projected.runs.single, rich.runs.single]) {
          final word = _rejected(run, 'wrld');
          expect(word.sourceStart, source.indexOf('wrld'));
          expect(word.sourceEnd, source.indexOf('wrld') + 4);
          expect(
            const SpellingReplacementPlanner()
                .build(occurrence: word, suggestion: 'world')
                .applyToSource(source),
            source.replaceFirst('wrld', 'world'),
            reason: source,
          );
        }
      }
    });

    test('inline HTML breaks in link labels agree with rich prose', () {
      for (final source in [
        '[hello<br>wrld](target)',
        '[hello<br/>text\nwrld](target)',
        '> - [hello<br/>text\r\n>   wrld](target)',
      ]) {
        final parsed = const MarkdownParser().parse(
          filePath: '/tmp/link-inline-break.md',
          source: source,
          mode: MarkdownMode.commonMark,
        );
        expect(
          _parserHasInline(source, BusyInlineKind.hardBreak),
          isTrue,
          reason: source,
        );
        final projected = const MarkdownSpellingProjector().project(
          filePath: '/tmp/link-inline-break.md',
          source: source,
          mode: MarkdownMode.commonMark,
          languageId: 'en-Test',
          snapshot: _snapshot,
        );
        final rich = const WysiwygSpellingProjector().project(
          document: parsed.busyDocument,
          languageId: 'en-Test',
          snapshot: _snapshot,
          documentGeneration: 1,
        );
        expect(projected.complete, isTrue, reason: source);
        expect(rich.complete, isTrue, reason: source);
        expect(projected.runs.every((run) => run.hasValidMapping), isTrue);
        expect(rich.runs.every((run) => run.hasValidMapping), isTrue);
        final sourceText = projected.runs.map((run) => run.text).join(' ');
        expect(
          sourceText,
          source.contains('text') ? 'hello text wrld' : 'hello wrld',
          reason: source,
        );
        expect(
          rich.runs.map((run) => run.text).join(' '),
          sourceText,
          reason: source,
        );
        final tagAtoms = [
          for (final run in projected.runs)
            for (final atom in run.atoms)
              if (source
                  .substring(atom.sourceStart, atom.sourceEnd)
                  .startsWith('<br'))
                atom,
        ];
        expect(tagAtoms, hasLength(1), reason: source);
        expect(tagAtoms.single.logicalText, ' ');
        expect(
          tagAtoms.single.transformation,
          SpellingTransformationKind.lineBreak,
        );
        for (final run in [
          projected.runs.singleWhere((run) => run.text.contains('wrld')),
          rich.runs.singleWhere((run) => run.text.contains('wrld')),
        ]) {
          final word = _rejected(run, 'wrld');
          expect(word.sourceStart, source.indexOf('wrld'));
          expect(
            const SpellingReplacementPlanner()
                .build(occurrence: word, suggestion: 'world')
                .applyToSource(source),
            source.replaceFirst('wrld', 'world'),
          );
        }
      }
    });

    test('code-styled image alternative text agrees with rich image field', () {
      for (final source in [
        '![hello `wrld`](image.png)',
        '![hello `wrld\nagain`](image.png)',
        '![hello `wrld\r\nagain`](image.png)',
        '![hello ` wrld `](image.png)',
        '[before ![hello `wrld`](image.png) after](target)',
      ]) {
        final parsed = const MarkdownParser().parse(
          filePath: '/tmp/image-code-alt.md',
          source: source,
          mode: MarkdownMode.commonMark,
        );
        expect(
          _parserHasInline(source, BusyInlineKind.image),
          isTrue,
          reason: source,
        );
        Iterable<BusyInline> descendants(Iterable<BusyInline> roots) sync* {
          for (final inline in roots) {
            yield inline;
            yield* descendants(inline.children);
          }
        }

        final image = [
          for (final block in parsed.busyDocument.blocks)
            ...descendants(block.inlines),
        ].singleWhere((inline) => inline.kind == BusyInlineKind.image);
        expect(
          image.text,
          source.contains('again') ? 'hello wrld again' : 'hello wrld',
          reason: source,
        );
        final projected = const MarkdownSpellingProjector().project(
          filePath: '/tmp/image-code-alt.md',
          source: source,
          mode: MarkdownMode.commonMark,
          languageId: 'en-Test',
          snapshot: _snapshot,
        );
        final rich = const WysiwygSpellingProjector().project(
          document: parsed.busyDocument,
          languageId: 'en-Test',
          snapshot: _snapshot,
          documentGeneration: 1,
        );
        expect(projected.complete, isTrue, reason: source);
        expect(rich.complete, isTrue, reason: source);
        expect(projected.runs.every((run) => run.hasValidMapping), isTrue);
        expect(rich.runs.every((run) => run.hasValidMapping), isTrue);
        final sourceText = projected.runs.map((run) => run.text).join(' ');
        expect(
          sourceText,
          rich.runs.map((run) => run.text).join(' '),
          reason: source,
        );
        expect(
          sourceText,
          source.contains('before')
              ? 'before  hello wrld  after'
              : source.contains('again')
              ? 'hello wrld again'
              : 'hello wrld',
          reason: source,
        );
        expect(sourceText, isNot(contains('image.png')));
        expect(sourceText, isNot(contains('`')));
        expect(sourceText, contains(image.text), reason: source);
        for (final run in [
          projected.runs.singleWhere((run) => run.text.contains('wrld')),
          rich.runs.singleWhere((run) => run.text.contains('wrld')),
        ]) {
          final word = _rejected(run, 'wrld');
          expect(word.sourceStart, source.indexOf('wrld'));
          expect(word.sourceEnd, source.indexOf('wrld') + 4);
          expect(
            const SpellingReplacementPlanner()
                .build(occurrence: word, suggestion: 'world')
                .applyToSource(source),
            source.replaceFirst('wrld', 'world'),
          );
        }
      }
      const ordinary = '[hello `wrld`](target)';
      final ordinaryProjection = const MarkdownSpellingProjector().project(
        filePath: '/tmp/link-code-control.md',
        source: ordinary,
        mode: MarkdownMode.commonMark,
        languageId: 'en-Test',
        snapshot: _snapshot,
      );
      expect(ordinaryProjection.complete, isTrue);
      expect(ordinaryProjection.runs.map((run) => run.text), ['hello ']);
    });

    for (final (name, source, expectedImage) in [
      ('list', '- ![hello `wrld\n  again`](image.png)', 'hello wrld again'),
      ('quote', '> ![hello `wrld\n> again`](image.png)', 'hello wrld again'),
      (
        'crlf-after-content',
        'Intro.\r\n\r\n- ![hello `wrld\r\n  againn`](image.png)',
        'hello wrld againn',
      ),
      (
        'combined-quote-list',
        '> - ![hello `wrld\n>   again`](image.png)',
        'hello wrld again',
      ),
      (
        'nested-image',
        '> - [before ![hello `wrld\n>   again`](image.png) after](target)',
        'hello wrld again',
      ),
      (
        'authored-inner-spaces',
        '- ![hello `wrld  kept\n  again`](image.png)',
        'hello wrld  kept again',
      ),
      (
        'authored-continuation-space',
        '- ![hello `wrld\n   again`](image.png)',
        'hello wrld  again',
      ),
      (
        'literal-code-syntax',
        '- ![hello `wrld\\* &amp;\n  again`](image.png)',
        r'hello wrld\* &amp; again',
      ),
    ]) {
      test(
        'container image code matches the block-parsed alternative: $name',
        () {
          final parsed = const MarkdownParser().parse(
            filePath: '/tmp/container-image-code.md',
            source: source,
            mode: MarkdownMode.commonMark,
          );
          Iterable<BusyBlock> blocks(Iterable<BusyBlock> roots) sync* {
            for (final block in roots) {
              yield block;
              yield* blocks(block.children);
            }
          }

          Iterable<BusyInline> inlines(Iterable<BusyInline> roots) sync* {
            for (final inline in roots) {
              yield inline;
              yield* inlines(inline.children);
            }
          }

          final image = [
            for (final block in blocks(parsed.busyDocument.blocks))
              ...inlines(block.inlines),
          ].singleWhere((inline) => inline.kind == BusyInlineKind.image);
          expect(image.text, expectedImage, reason: source);
          final projected = const MarkdownSpellingProjector().project(
            filePath: '/tmp/container-image-code.md',
            source: source,
            mode: MarkdownMode.commonMark,
            languageId: 'en-Test',
            snapshot: _snapshot,
          );
          final rich = const WysiwygSpellingProjector().project(
            document: parsed.busyDocument,
            languageId: 'en-Test',
            snapshot: _snapshot,
            documentGeneration: 1,
          );
          final sourceImage = projected.runs.singleWhere(
            (run) => run.text.contains('wrld'),
          );
          expect(sourceImage.text, image.text, reason: source);
          final richImage = rich.runs.singleWhere(
            (run) => run.text == image.text,
          );
          expect(richImage.text, image.text, reason: source);
          expect(projected.complete, isTrue, reason: source);
          expect(rich.complete, isTrue, reason: source);
          expect(
            projected.runs.every((run) => run.hasValidMapping),
            isTrue,
            reason: source,
          );
          expect(
            rich.runs.every((run) => run.hasValidMapping),
            isTrue,
            reason: source,
          );
          final codeBreak = sourceImage.atoms.singleWhere(
            (atom) =>
                atom.transformation == SpellingTransformationKind.lineBreak &&
                source
                    .substring(atom.sourceStart, atom.sourceEnd)
                    .contains('\n'),
          );
          final expectedBreak = switch (name) {
            'quote' => '\n> ',
            'combined-quote-list' || 'nested-image' => '\n>   ',
            'crlf-after-content' => '\r\n  ',
            _ => '\n  ',
          };
          expect(
            source.substring(codeBreak.sourceStart, codeBreak.sourceEnd),
            expectedBreak,
            reason: source,
          );
          expect(codeBreak.logicalText, ' ');
          expect(
            projected.runs.map((run) => run.text).join(' '),
            isNot(contains('image.png')),
            reason: source,
          );
          if (source.contains('(target)')) {
            expect(
              projected.runs.map((run) => run.text).join(' '),
              isNot(contains('target')),
              reason: source,
            );
            expect(
              projected.runs.where((run) => run.text.contains('before')),
              hasLength(1),
              reason: source,
            );
            expect(
              projected.runs.where((run) => run.text.contains('after')),
              hasLength(1),
              reason: source,
            );
          }
          for (final word in [
            'wrld',
            if (source.contains('againn')) 'againn',
          ]) {
            final suggestion = word == 'wrld' ? 'world' : 'again';
            for (final run in [sourceImage, richImage]) {
              final occurrence = _rejected(run, word);
              expect(
                occurrence.sourceStart,
                source.indexOf(word),
                reason: source,
              );
              expect(
                occurrence.sourceEnd,
                source.indexOf(word) + word.length,
                reason: source,
              );
              expect(
                const SpellingReplacementPlanner()
                    .build(occurrence: occurrence, suggestion: suggestion)
                    .applyToSource(source),
                source.replaceFirst(word, suggestion),
                reason: source,
              );
            }
          }
        },
      );
    }

    test('nested image code inherits the enclosing container mapping', () {
      const source =
          '> - ![before ![hello `wrld\n>   again`](inner.png) after](outer.png)';
      final parsed = const MarkdownParser().parse(
        filePath: '/tmp/recursive-container-image-code.md',
        source: source,
        mode: MarkdownMode.commonMark,
      );
      Iterable<BusyBlock> blocks(Iterable<BusyBlock> roots) sync* {
        for (final block in roots) {
          yield block;
          yield* blocks(block.children);
        }
      }

      final image = [
        for (final block in blocks(parsed.busyDocument.blocks))
          ...block.inlines,
      ].singleWhere((inline) => inline.kind == BusyInlineKind.image);
      expect(image.text, 'before hello wrld again after');
      final projected = const MarkdownSpellingProjector().project(
        filePath: '/tmp/recursive-container-image-code.md',
        source: source,
        mode: MarkdownMode.commonMark,
        languageId: 'en-Test',
        snapshot: _snapshot,
      );
      expect(projected.complete, isTrue);
      expect(projected.runs.every((run) => run.hasValidMapping), isTrue);
      expect(projected.runs.map((run) => run.text), [
        'before ',
        'hello wrld again',
        ' after',
      ]);
      final word = _rejected(
        projected.runs.singleWhere((run) => run.text.contains('wrld')),
        'again',
      );
      expect(word.sourceStart, source.indexOf('again'));
      expect(
        const SpellingReplacementPlanner()
            .build(occurrence: word, suggestion: 'world')
            .applyToSource(source),
        source.replaceFirst('again', 'world'),
      );
    });

    test('link title keeps literal inline-break markup as scalar text', () {
      const source = '[hello](target "Use <br> wrld")';
      final result = const MarkdownSpellingProjector().project(
        filePath: '/tmp/literal-title-break.md',
        source: source,
        mode: MarkdownMode.commonMark,
        languageId: 'en-Test',
        snapshot: _snapshot,
      );
      expect(result.complete, isTrue);
      expect(result.runs.every((run) => run.hasValidMapping), isTrue);
      expect(result.runs.map((run) => run.text), ['hello', 'Use <br> wrld']);
      final title = result.runs.singleWhere((run) => run.text.contains('wrld'));
      expect(
        const SpellingReplacementPlanner()
            .build(occurrence: _rejected(title, 'wrld'), suggestion: 'world')
            .applyToSource(source),
        '[hello](target "Use <br> world")',
      );
    });

    test('multiline code inside a link label stays opaque', () {
      _expectNestedMultilineLabel(
        source: '[helo `code\nmore` wrld](target)',
        nestedKind: BusyInlineKind.code,
        bodyRuns: ['helo', 'wrld'],
      );
    });

    test('multiline nested-image destination stays outside outer prose', () {
      _expectNestedMultilineLabel(
        source: '[helo ![alt](\nimage.png) wrld](target)',
        nestedKind: BusyInlineKind.image,
        bodyRuns: ['helo', 'alt', 'wrld'],
      );
    });

    test('nested label syntax owns its breaks before outer prose resumes', () {
      for (final fixture in [
        (
          source: '[helo `code\nmore` prose\nwrld](target)',
          kind: BusyInlineKind.code,
          body: ['helo', 'prose wrld'],
          title: null,
        ),
        (
          source: '[helo `code\nmore` prose\\\nwrld](target)',
          kind: BusyInlineKind.code,
          body: ['helo', 'prose wrld'],
          title: null,
        ),
        (
          source: '[helo ![alt](\nimage.png) prose\nwrld](target)',
          kind: BusyInlineKind.image,
          body: ['helo', 'alt', 'prose wrld'],
          title: null,
        ),
        (
          source: '[helo ![alt\ntext](image.png) wrld](target)',
          kind: BusyInlineKind.image,
          body: ['helo', 'alt text', 'wrld'],
          title: null,
        ),
        (
          source: '[helo ![alt\ntext](image.png) prose\nwrld](target)',
          kind: BusyInlineKind.image,
          body: ['helo', 'alt text', 'prose wrld'],
          title: null,
        ),
        (
          source: '[helo ![alt](image.png "tit\nle") wrld](target)',
          kind: BusyInlineKind.image,
          body: ['helo', 'alt', 'wrld'],
          title: 'tit le',
        ),
        (
          source: '[helo ![alt](image.png "tit\nle") prose\nwrld](target)',
          kind: BusyInlineKind.image,
          body: ['helo', 'alt', 'prose wrld'],
          title: 'tit le',
        ),
        (
          source: '> - [helo `code\n>   more` wrld](target)',
          kind: BusyInlineKind.code,
          body: ['helo', 'wrld'],
          title: null,
        ),
        (
          source: '> - [helo ![alt](\r\n>   image.png) wrld](target)',
          kind: BusyInlineKind.image,
          body: ['helo', 'alt', 'wrld'],
          title: null,
        ),
      ]) {
        _expectNestedMultilineLabel(
          source: fixture.source,
          nestedKind: fixture.kind,
          bodyRuns: fixture.body,
          titleText: fixture.title,
        );
      }
    });

    test('metadata scalar tag-like text remains checkable', () {
      for (final source in [
        '[hello](target "Use <code>wrld</code> &amp; more")',
        '<span title="Use <code>wrld</code> &amp; more">hello</span>',
      ]) {
        final result = const MarkdownSpellingProjector().project(
          filePath: '/tmp/metadata-scalar.md',
          source: source,
          mode: MarkdownMode.commonMark,
          languageId: 'en-Test',
          snapshot: _snapshot,
        );
        expect(result.complete, isTrue, reason: source);
        expect(result.runs.every((run) => run.hasValidMapping), isTrue);
        final all = result.runs.map((run) => run.text).join(' ');
        expect(all, contains('wrld'), reason: source);
        expect(all, contains('&'), reason: source);
        final word = _rejected(
          result.runs.singleWhere((run) => run.text.contains('wrld')),
          'wrld',
        );
        expect(word.sourceStart, source.indexOf('wrld'));
        expect(
          const SpellingReplacementPlanner()
              .build(occurrence: word, suggestion: 'world')
              .applyToSource(source),
          source.replaceFirst('wrld', 'world'),
        );
      }
      const bodyCode = 'hello <code>wrld</code> again';
      final body = const MarkdownSpellingProjector().project(
        filePath: '/tmp/body-code.md',
        source: bodyCode,
        mode: MarkdownMode.commonMark,
        languageId: 'en-Test',
        snapshot: _snapshot,
      );
      expect(body.complete, isTrue);
      expect(
        body.runs.map((run) => run.text).join(' '),
        isNot(contains('wrld')),
      );
    });

    test('parenthesized title replacement escapes its own delimiter', () {
      const source = '[hello](target (wrld))';
      final result = const MarkdownSpellingProjector().project(
        filePath: '/tmp/parenthesized-title.md',
        source: source,
        mode: MarkdownMode.commonMark,
        languageId: 'en-Test',
        snapshot: _snapshot,
      );
      final occurrence = _rejected(
        result.runs.singleWhere((run) => run.text == 'wrld'),
        'wrld',
      );
      for (final (suggestion, expected) in [
        ('world)', r'[hello](target (world\)))'),
        ('world(', r'[hello](target (world\())'),
        ('world()', r'[hello](target (world\(\)))'),
        (r'world\done', r'[hello](target (world\\done))'),
        (r'world\(x)', r'[hello](target (world\\\(x\)))'),
      ]) {
        final corrected = const SpellingReplacementPlanner()
            .build(occurrence: occurrence, suggestion: suggestion)
            .applyToSource(source);
        expect(corrected, expected);
        final parsed = const MarkdownParser().parse(
          filePath: '/tmp/parenthesized-title.md',
          source: corrected,
          mode: MarkdownMode.commonMark,
        );
        final link = parsed.busyDocument.blocks.single.inlines.singleWhere(
          (inline) => inline.kind == BusyInlineKind.link,
        );
        expect(link.destination, 'target');
        expect(link.attributes['title'], suggestion);
        expect(md.markdownToHtml(corrected), contains('title="$suggestion"'));
      }
    });

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

    test('projects semantic HTML prose and trusts parser math nodes', () {
      const source =
          '''<div title="Readablee"><p>mispelled</p><code>hiddenbad</code></div>

Price \$ 5, mispelled \$ 6 and actual \$hiddenmath\$ tail.
''';
      final projected = const MarkdownSpellingProjector().project(
        filePath: '/tmp/html.md',
        source: source,
        mode: MarkdownMode.commonMark,
        languageId: 'en-US',
        snapshot: _snapshot,
      );
      final text = projected.runs.map((run) => run.text).join('\n');

      expect(projected.complete, isTrue, reason: projected.message);
      expect(text, contains('Readablee'));
      expect(text, contains('mispelled'));
      expect(text, contains(r'Price $ 5, mispelled $ 6'));
      expect(text, isNot(contains('hiddenbad')));
      expect(text, isNot(contains('hiddenmath')));
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
    test('keeps inline body words intact across readable attributes', () {
      const source =
          '<topic><p>docu<em title="titl">men</em>tation</p></topic>';
      final result = const WritersideXmlSpellingProjector().project(
        filePath: '/tmp/inline.topic',
        source: source,
        languageId: 'en-Test',
        snapshot: const SpellingSnapshotIdentity(
          bufferId: 'xml-inline',
          contentRevision: 1,
          documentKind: DocumentKind.writersideXmlTopic,
          contextGeneration: 1,
        ),
      );
      expect(result.complete, isTrue);
      expect(result.runs.every((run) => run.hasValidMapping), isTrue);
      expect(result.runs.map((run) => run.text), contains('documentation'));
      expect(result.runs.map((run) => run.text), contains('titl'));
    });

    test('corrects XML body and encoded metadata independently', () {
      const source =
          '<topic><p>docu<em title="titl &amp; titl">men</em>taton</p></topic>';
      final result = const WritersideXmlSpellingProjector().project(
        filePath: '/tmp/metadata.topic',
        source: source,
        languageId: 'en-Test',
        snapshot: const SpellingSnapshotIdentity(
          bufferId: 'xml-metadata',
          contentRevision: 1,
          documentKind: DocumentKind.writersideXmlTopic,
          contextGeneration: 1,
        ),
      );
      expect(result.complete, isTrue);
      expect(result.runs.every((run) => run.hasValidMapping), isTrue);
      final body = result.runs.singleWhere((run) => run.text == 'documentaton');
      expect(
        const SpellingReplacementPlanner()
            .build(
              occurrence: _rejected(body, 'documentaton'),
              suggestion: 'documentation',
            )
            .applyToSource(source),
        source.replaceFirst('taton', 'tation'),
      );
      final attribute = result.runs.singleWhere(
        (run) => run.text == 'titl & titl',
      );
      expect(
        const SpellingReplacementPlanner()
            .build(
              occurrence: _rejected(attribute, 'titl'),
              suggestion: 'title',
            )
            .applyToSource(source),
        source.replaceFirst('"titl &amp;', '"title &amp;'),
      );
    });

    test('excludes visible addresses in encoded text and CDATA', () {
      for (final body in [
        'helo https://example.invalid/path wrld',
        'helo https://examp&amp;le.invalid/path wrld',
        '<![CDATA[helo https://example.invalid/path wrld]]>',
      ]) {
        final source = '<topic><p>$body</p></topic>';
        final result = const WritersideXmlSpellingProjector().project(
          filePath: '/tmp/addresses.topic',
          source: source,
          languageId: 'en-Test',
          snapshot: const SpellingSnapshotIdentity(
            bufferId: 'xml-address',
            contentRevision: 1,
            documentKind: DocumentKind.writersideXmlTopic,
            contextGeneration: 1,
          ),
        );
        expect(result.complete, isTrue, reason: body);
        expect(result.runs.every((run) => run.hasValidMapping), isTrue);
        final all = result.runs.map((run) => run.text).join(' ');
        expect(all, contains('helo'), reason: body);
        expect(all, contains('wrld'), reason: body);
        expect(all, isNot(contains('example.invalid')), reason: body);
        expect(all, isNot(contains('examp&le.invalid')), reason: body);
        final run = result.runs.firstWhere((run) => run.text.contains('wrld'));
        final occurrence = _rejected(run, 'wrld');
        expect(
          source.substring(occurrence.sourceStart!, occurrence.sourceEnd!),
          'wrld',
        );
        expect(
          const SpellingReplacementPlanner()
              .build(occurrence: occurrence, suggestion: 'world')
              .applyToSource(source),
          source.replaceFirst('wrld', 'world'),
        );
      }
    });

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

    test('excludes entity-encoded variables after XML decoding', () {
      const source = r'''<topic id="sample">
  <p>before %project&#110;ame% after &#37;other_name% literal %\escaped%</p>
  <p title="prefix %pro&#106;ect% suffix">tail</p>
</topic>''';
      final projected = const WritersideXmlSpellingProjector().project(
        filePath: '/tmp/encoded-variables.topic',
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
      expect(text, contains('before '));
      expect(text, contains(' after '));
      expect(text, contains(r'literal %\escaped%'));
      expect(text, isNot(contains('projectname')));
      expect(text, isNot(contains('other_name')));
      expect(text, isNot(contains('project')));
    });

    test('keeps decomposed Unicode in XML and CDATA corrections', () {
      for (final source in [
        '<topic><p>cafe\u0301x</p></topic>',
        '<topic><p><![CDATA[cafe\u0301x]]></p></topic>',
      ]) {
        final projected = const WritersideXmlSpellingProjector().project(
          filePath: '/tmp/unicode.topic',
          source: source,
          languageId: 'en-US',
          snapshot: const SpellingSnapshotIdentity(
            bufferId: 'xml',
            contentRevision: 1,
            documentKind: DocumentKind.writersideXmlTopic,
            contextGeneration: 1,
          ),
        );
        final run = projected.runs.singleWhere(
          (candidate) => candidate.text.contains('cafe\u0301x'),
        );
        expect(
          const SpellingReplacementPlanner()
              .build(
                occurrence: _rejected(run, 'cafe\u0301x'),
                suggestion: 'café',
              )
              .applyToSource(source),
          source.replaceFirst('cafe\u0301x', 'cafe\u0301'),
        );
      }
    });
  });

  group('exact rich correction', () {
    test('container image code corrects after continuation in rich editor', () {
      const source =
          'Before paragraph.\n\n- ![hello `wrld\n  againn`](image.png)\n\nAfter paragraph.';
      final document = const MarkdownParser()
          .parse(
            filePath: '/tmp/container-image-code-rich.md',
            source: source,
            mode: MarkdownMode.commonMark,
          )
          .busyDocument;
      final projection = const WysiwygSpellingProjector().project(
        document: document,
        languageId: 'en-Test',
        snapshot: _snapshot,
        documentGeneration: 1,
      );
      expect(projection.complete, isTrue, reason: projection.message);
      final run = projection.runs.singleWhere(
        (candidate) => candidate.text == 'hello wrld againn',
      );
      final occurrence = _rejected(run, 'againn');
      expect(occurrence.sourceStart, source.indexOf('againn'));
      final plan = const SpellingReplacementPlanner().build(
        occurrence: occurrence,
        suggestion: 'again',
      );
      expect(
        plan.applyToSource(source),
        source.replaceFirst('againn', 'again'),
      );
      final target = run.target as SpellingRichBlockTarget;
      final controller = BusyMarkWysiwygDocumentController(document: document);
      addTearDown(controller.dispose);
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
      final corrected = controller.markdown;
      // Rich image fields contain flattened alt text; editing one currently
      // serializes its code styling and physical break as plain alt text.
      expect(
        corrected,
        'Before paragraph.\n\n- ![hello wrld again](image.png)\n\nAfter paragraph.\n',
      );
      final reparsed = const MarkdownParser().parse(
        filePath: '/tmp/container-image-code-rich.md',
        source: corrected,
        mode: MarkdownMode.commonMark,
      );
      Iterable<BusyBlock> blocks(Iterable<BusyBlock> roots) sync* {
        for (final block in roots) {
          yield block;
          yield* blocks(block.children);
        }
      }

      final image = [
        for (final block in blocks(reparsed.busyDocument.blocks))
          ...block.inlines,
      ].singleWhere((inline) => inline.kind == BusyInlineKind.image);
      expect(image.text, 'hello wrld again');
      expect(image.destination, 'image.png');
    });

    test('code-styled image alternative corrects through rich controller', () {
      const source = 'Before ![hello `wrld`](image.png) after';
      final document = const MarkdownParser()
          .parse(
            filePath: '/tmp/image-code-rich.md',
            source: source,
            mode: MarkdownMode.commonMark,
          )
          .busyDocument;
      final projection = const WysiwygSpellingProjector().project(
        document: document,
        languageId: 'en-Test',
        snapshot: _snapshot,
        documentGeneration: 1,
      );
      expect(projection.complete, isTrue, reason: projection.message);
      final run = projection.runs.singleWhere(
        (candidate) => candidate.text.contains('wrld'),
      );
      expect(run.hasValidMapping, isTrue);
      final target = run.target as SpellingRichBlockTarget;
      final controller = BusyMarkWysiwygDocumentController(document: document);
      addTearDown(controller.dispose);
      final plan = const SpellingReplacementPlanner().build(
        occurrence: _rejected(run, 'wrld'),
        suggestion: 'world',
      );
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
      // The rich image field stores flattened alternative text. Its current
      // serializer keeps the corrected value and destination, but normalizes
      // source-only code styling when the rich field is edited.
      expect(controller.markdown, 'Before ![hello world](image.png) after');
      final reparsed = const MarkdownParser().parse(
        filePath: '/tmp/image-code-rich.md',
        source: controller.markdown,
        mode: MarkdownMode.commonMark,
      );
      expect(
        reparsed.busyDocument.blocks.first.inlines
            .singleWhere((inline) => inline.kind == BusyInlineKind.image)
            .text,
        'hello world',
      );
    });

    test('multiline link label correction uses rich controller mapping', () {
      const source = '[helo ![alt\ntext](image.png) wrld](target)';
      final document = const MarkdownParser()
          .parse(
            filePath: '/tmp/nested-multiline-rich.md',
            source: source,
            mode: MarkdownMode.commonMark,
          )
          .busyDocument;
      final projection = const WysiwygSpellingProjector().project(
        document: document,
        languageId: 'en-Test',
        snapshot: _snapshot,
        documentGeneration: 1,
      );
      expect(projection.complete, isTrue, reason: projection.message);
      final run = projection.runs.singleWhere(
        (candidate) => candidate.text.contains('wrld'),
      );
      final target = run.target as SpellingRichBlockTarget;
      final controller = BusyMarkWysiwygDocumentController(document: document);
      addTearDown(controller.dispose);
      final plan = const SpellingReplacementPlanner().build(
        occurrence: _rejected(run, 'wrld'),
        suggestion: 'world',
      );
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
      expect(controller.markdown, source.replaceFirst('wrld', 'world'));
    });
    for (final source in [
      '# Introduction\n\n- [Overview](#overview)\n  - [Motivation](#motivation)\n- [Discussion](#discussion)\n<!-- busymark:toc:end -->\n\n## Overview\n\nhelo **world**\n\nhelo world\n',
      '- helo\n  - helo\n\nhelo\n',
      '<!-- hidden comment -->\n\nhelo\n',
    ]) {
      test(
        'maps all rich fields without requiring parser block spans: $source',
        () {
          final document = const MarkdownParser()
              .parse(
                filePath: '/topic.md',
                source: source,
                mode: MarkdownMode.writersideMarkdown,
                validateLocalReferences: false,
              )
              .busyDocument;
          final result = const WysiwygSpellingProjector().project(
            document: document,
            languageId: 'en-US',
            snapshot: _snapshot,
            documentGeneration: 1,
          );
          expect(result.complete, isTrue, reason: result.message);
          expect(
            result.runs.every((r) => r.target is SpellingRichBlockTarget),
            isTrue,
          );
          expect(result.runs.any((r) => r.text.contains('<!--')), isFalse);
          final runs = result.runs
              .where((r) => r.text.contains('helo'))
              .toList();
          expect(runs, hasLength('helo'.allMatches(source).length));
          final expectedOffsets = 'helo'
              .allMatches(source)
              .map((m) => m.start)
              .toList();
          for (final (index, run) in runs.indexed) {
            final occurrence = _rejected(run, 'helo');
            expect(occurrence.sourceStart, expectedOffsets[index]);
            expect(
              const SpellingReplacementPlanner()
                  .build(occurrence: occurrence, suggestion: 'hello')
                  .applyToSource(source),
              source.replaceRange(
                expectedOffsets[index],
                expectedOffsets[index] + 4,
                'hello',
              ),
            );
          }
        },
      );
    }

    test('escaped comment prose is still an editable rich spelling field', () {
      const source = r'\<!-- helo -->';
      final document = const MarkdownParser()
          .parse(
            filePath: '/literal.md',
            source: source,
            validateLocalReferences: false,
          )
          .busyDocument;
      final result = const WysiwygSpellingProjector().project(
        document: document,
        languageId: 'en-US',
        snapshot: _snapshot,
        documentGeneration: 1,
      );
      expect(result.complete, isTrue);
      expect(result.runs.single.text, contains('helo'));
    });

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

    test('rich links keep all title delimiters source-only', () {
      for (final title in ['(wrld)', '"wrld"', "'wrld'"]) {
        final source = '[helo](target $title)\n\nafter\n';
        final parsed = const MarkdownParser().parse(
          filePath: '/tmp/rich-title.md',
          source: source,
          mode: MarkdownMode.commonMark,
        );
        final sourceProjection = const MarkdownSpellingProjector().project(
          filePath: '/tmp/rich-title.md',
          source: source,
          mode: MarkdownMode.commonMark,
          languageId: 'en-Test',
          snapshot: _snapshot,
        );
        final rich = const WysiwygSpellingProjector().project(
          document: parsed.busyDocument,
          languageId: 'en-Test',
          snapshot: _snapshot,
          documentGeneration: 1,
        );
        expect(sourceProjection.complete, isTrue, reason: source);
        expect(rich.complete, isTrue, reason: source);
        expect(rich.runs.every((run) => run.hasValidMapping), isTrue);
        final label = rich.runs.singleWhere((run) => run.text == 'helo');
        final metadata = rich.runs.singleWhere((run) => run.text == 'wrld');
        final following = rich.runs.singleWhere((run) => run.text == 'after');
        expect(label.target, isA<SpellingRichBlockTarget>());
        expect(metadata.target, isA<SpellingSourceTarget>());
        expect(following.target, isA<SpellingRichBlockTarget>());
        expect(
          const SpellingReplacementPlanner()
              .build(
                occurrence: _rejected(metadata, 'wrld'),
                suggestion: 'world',
              )
              .applyToSource(source),
          source.replaceFirst('wrld', 'world'),
        );
        expect(
          const SpellingReplacementPlanner()
              .build(occurrence: _rejected(label, 'helo'), suggestion: 'hello')
              .applyToSource(source),
          source.replaceFirst('helo', 'hello'),
        );
      }
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
            (
              cell: r'he***x***llo $x$',
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
      for (final fixture
          in <
            ({String source, String word, String suggestion, String expected})
          >[
            (
              source:
                  r'mispel**led** $x$'
                  '\n',
              expected:
                  r'misspel**led** $x$'
                  '\n',
              word: 'mispelled',
              suggestion: 'misspelled',
            ),
            (
              source:
                  r'mispell&#101;d $x$'
                  '\n',
              expected:
                  r'misspelled $x$'
                  '\n',
              word: 'mispelled',
              suggestion: 'misspelled',
            ),
            (
              source:
                  r'he**x**llo $x$'
                  '\n',
              expected:
                  r'hello $x$'
                  '\n',
              word: 'hexllo',
              suggestion: 'hello',
            ),
            (
              source: 'cafe\u0301x \$x\$\n',
              expected: 'cafe\u0301 \$x\$\n',
              word: 'cafe\u0301x',
              suggestion: 'café',
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
          (candidate) => candidate.text.contains(fixture.word),
        );
        final plan = const SpellingReplacementPlanner().build(
          occurrence: _rejected(run, fixture.word),
          suggestion: fixture.suggestion,
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

    test('owns every nested wrapper in paragraph math-source fields', () {
      const source = 'he***x***llo \$y\$\n';
      final document = const MarkdownParser()
          .parse(
            filePath: '/tmp/nested-math-rich.md',
            source: source,
            mode: MarkdownMode.commonMark,
            validateLocalReferences: false,
          )
          .busyDocument;
      final projected = const WysiwygSpellingProjector().project(
        document: document,
        languageId: 'en-US',
        snapshot: _snapshot,
        documentGeneration: 10,
      );
      final run = projected.runs.singleWhere(
        (candidate) => candidate.text.contains('hexllo'),
      );
      final target = run.target as SpellingRichBlockTarget;
      final controller = BusyMarkWysiwygDocumentController(document: document);
      final plan = const SpellingReplacementPlanner().build(
        occurrence: _rejected(run, 'hexllo'),
        suggestion: 'hello',
      );

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
      expect(controller.markdown, 'hello \$y\$\n');
    });
  });
}
