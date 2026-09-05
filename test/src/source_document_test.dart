import 'dart:math' as math;

import 'package:busymark/src/editor/source/source_document.dart';
import 'package:busymark/src/editor/source/source_hidden_ranges.dart';
import 'package:busymark/src/editor/source/source_line_index.dart';
import 'package:busymark/src/editor/source_highlighter.dart';
import 'package:busymark/src/editor/source_folding.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('empty document mapping is stable', () {
    final document = SourceDocument(fullText: '');

    expect(document.visibleText, '');
    expect(document.fullOffsetToVisibleOffset(0), 0);
    expect(document.visibleOffsetToFullOffset(0), 0);
    expect(document.lineIndex.lineCount, 1);
    expect(document.visibleLineIndex.lineCount, 1);
  });

  test('no-fold mapping preserves offsets and ranges', () {
    final document = SourceDocument(fullText: 'one\ntwo\n');

    expect(document.visibleText, document.fullText);
    expect(document.fullOffsetToVisibleOffset(5), 5);
    expect(document.visibleOffsetToFullOffset(5), 5);
    expect(document.fullRangeToVisibleRange(4, 7).range.start, 4);
    expect(document.visibleRangeToFullRange(4, 7).range.end, 7);
  });

  test('single fold projects visible text and maps offsets', () {
    const source = '# Title\nIntro.\nMore.\n# Next\n';
    final region = sourceFoldRegions(
      source,
      SourceSyntaxLanguage.markdown,
    ).firstWhere((region) => region.startLine == 1);
    final document = SourceDocument(
      fullText: source,
      hiddenRanges: SourceHiddenRanges(
        ranges: [
          SourceHiddenRange(
            start: region.hiddenStartOffset,
            end: region.hiddenEndOffset,
          ),
        ],
        textLength: source.length,
      ),
    );

    expect(document.visibleText, '# Title\n# Next\n');
    expect(document.fullOffsetToVisibleOffset(source.indexOf('Intro')), 8);
    expect(document.visibleOffsetToFullOffset(8), region.hiddenStartOffset);
    expect(
      document.visibleOffsetToFullOffset(
        8,
        affinity: SourceHiddenAffinity.upstream,
      ),
      region.hiddenEndOffset,
    );
  });

  test('fold-boundary selection mapping preserves direction, not coverage', () {
    const source = '# Title\nIntro.\nMore.\n# Next\n';
    final region = sourceFoldRegions(
      source,
      SourceSyntaxLanguage.markdown,
    ).firstWhere((region) => region.startLine == 1);
    final document = SourceDocument(
      fullText: source,
      hiddenRanges: SourceHiddenRanges(
        ranges: [
          SourceHiddenRange(
            start: region.hiddenStartOffset,
            end: region.hiddenEndOffset,
          ),
        ],
        textLength: source.length,
      ),
    );
    final boundary = document.fullOffsetToVisibleOffset(
      region.hiddenStartOffset,
    );

    final forward = document.visibleSelectionToFullSelection(
      TextSelection(baseOffset: 0, extentOffset: boundary),
    );
    final backward = document.visibleSelectionToFullSelection(
      TextSelection(baseOffset: boundary, extentOffset: 0),
    );

    expect(forward.start, backward.start);
    expect(forward.end, backward.end);
    expect(forward.end, region.hiddenEndOffset);
    expect(forward.baseOffset, backward.extentOffset);
    expect(forward.extentOffset, backward.baseOffset);
  });

  test('multiple adjacent and overlapping ranges normalize safely', () {
    final ranges = SourceHiddenRanges(
      ranges: const [
        SourceHiddenRange(start: 2, end: 5),
        SourceHiddenRange(start: 5, end: 8),
        SourceHiddenRange(start: 7, end: 9),
        SourceHiddenRange(start: 12, end: 14),
      ],
      textLength: 20,
    );

    expect(ranges.ranges.map((range) => (range.start, range.end)), [
      (2, 9),
      (12, 14),
    ]);
    expect(ranges.visibleTextFor('abcdefghijklmnopqrst'), 'abjklopqrst');
  });

  test('full and visible ranges report hidden clipping', () {
    final document = SourceDocument(
      fullText: 'abcDEFghi',
      hiddenRanges: SourceHiddenRanges(
        ranges: const [SourceHiddenRange(start: 3, end: 6)],
        textLength: 9,
      ),
    );

    expect(
      document.fullRangeToVisibleRange(0, 2).clippedByHiddenRange,
      isFalse,
    );
    expect(document.fullRangeToVisibleRange(2, 7).clippedByHiddenRange, isTrue);
    expect(
      document.visibleRangeToFullRange(2, 4).range,
      isA<SourceTextRange>(),
    );
  });

  test('CRLF line endings keep line starts and projection correct', () {
    final document = SourceDocument(
      fullText: 'a\r\nb\r\nc',
      hiddenRanges: SourceHiddenRanges(
        ranges: const [SourceHiddenRange(start: 3, end: 6)],
        textLength: 7,
      ),
    );

    expect(document.lineIndex.lineAt(2).text, 'b');
    expect(document.visibleText, 'a\r\nc');
    expect(document.visibleLineForFullLine(3)?.number, 2);
  });

  test('visible edits before and after folds preserve unrelated folds', () {
    const source = '# Title\nIntro.\nMore.\n# Next\nDone.\n';
    final region = sourceFoldRegions(
      source,
      SourceSyntaxLanguage.markdown,
    ).firstWhere((region) => region.startLine == 1);
    final controller = BusyMarkSourceEditingController(
      text: source,
      language: SourceSyntaxLanguage.markdown,
    )..setFoldedRegions([region]);

    controller.value = TextEditingValue(
      text: 'Lead\n${controller.text}',
      selection: const TextSelection.collapsed(offset: 5),
    );
    expect(controller.fullText, startsWith('Lead\n# Title\nIntro.'));
    expect(controller.foldedRegions, hasLength(1));
    expect(controller.text, 'Lead\n# Title\n# Next\nDone.\n');

    controller.value = TextEditingValue(
      text: '${controller.text}Tail\n',
      selection: TextSelection.collapsed(offset: controller.text.length + 5),
    );
    expect(controller.foldedRegions, hasLength(1));
    expect(controller.fullText, endsWith('Done.\nTail\n'));
  });

  test('full editing values preserve composing through folded projection', () {
    const source = '# Title\nIntro.\nMore.\n# Next\nDone.\n';
    final region = sourceFoldRegions(
      source,
      SourceSyntaxLanguage.markdown,
    ).firstWhere((region) => region.startLine == 1);
    final controller = BusyMarkSourceEditingController(
      text: source,
      language: SourceSyntaxLanguage.markdown,
    )..setFoldedRegions([region]);
    addTearDown(controller.dispose);
    final fullStart = source.indexOf('Next');
    final fullComposing = TextRange(start: fullStart, end: fullStart + 4);

    controller.setFullEditingValue(
      TextEditingValue(
        text: source,
        selection: TextSelection.collapsed(offset: fullComposing.end),
        composing: fullComposing,
      ),
    );

    final visibleStart = controller.text.indexOf('Next');
    expect(
      controller.value.composing,
      TextRange(start: visibleStart, end: visibleStart + 4),
    );
    expect(controller.fullComposing, fullComposing);
  });

  test('visible edits incrementally retain unaffected line entries', () {
    final controller = BusyMarkSourceEditingController(
      text: 'first\nsecond\nthird\nfourth\n',
    );
    final previous = controller.document;

    controller.value = const TextEditingValue(
      text: 'first\nsecond\nTHIRD\nfourth\n',
      selection: TextSelection.collapsed(offset: 18),
    );

    expect(
      identical(
        previous.lineIndex.lines.first,
        controller.document.lineIndex.lines.first,
      ),
      isTrue,
    );
    expect(controller.document.lineIndex.lines.map((line) => line.text), [
      'first',
      'second',
      'THIRD',
      'fourth',
      '',
    ]);
    expect(controller.document.visibleLineIndex.lineCount, 5);
  });

  test(
    'incremental line indexes match full indexes across line-break edits',
    () {
      final random = math.Random(149);
      const pieces = ['a', 'b', ' ', '\n', '\r', '\r\n'];
      for (var iteration = 0; iteration < 300; iteration++) {
        final oldText = List.generate(
          random.nextInt(30),
          (_) => pieces[random.nextInt(pieces.length)],
        ).join();
        final start = random.nextInt(oldText.length + 1);
        final end = start + random.nextInt(oldText.length - start + 1);
        final replacement = List.generate(
          random.nextInt(8),
          (_) => pieces[random.nextInt(pieces.length)],
        ).join();
        final nextText = oldText.replaceRange(start, end, replacement);
        final incremental = SourceLineIndex.updated(
          previous: SourceLineIndex(oldText),
          source: nextText,
          oldStart: start,
          oldEnd: end,
        );
        final rebuilt = SourceLineIndex(nextText);

        expect(
          incremental.lines
              .map(
                (line) => (
                  line.number,
                  line.startOffset,
                  line.endOffset,
                  line.endOffsetIncludingLineBreak,
                  line.text,
                  line.lineBreak,
                ),
              )
              .toList(),
          rebuilt.lines
              .map(
                (line) => (
                  line.number,
                  line.startOffset,
                  line.endOffset,
                  line.endOffsetIncludingLineBreak,
                  line.text,
                  line.lineBreak,
                ),
              )
              .toList(),
          reason: 'iteration $iteration: ${oldText.replaceAll('\n', r'\n')}',
        );
      }
    },
  );

  test('visible edit intersecting a fold unfolds only affected region', () {
    const source = '# Title\nIntro.\nMore.\n# Next\nDone.\n';
    final region = sourceFoldRegions(
      source,
      SourceSyntaxLanguage.markdown,
    ).firstWhere((region) => region.startLine == 1);
    final controller = BusyMarkSourceEditingController(
      text: source,
      language: SourceSyntaxLanguage.markdown,
    )..setFoldedRegions([region]);

    controller.value = const TextEditingValue(
      text: '# Title\nInserted\n# Next\nDone.\n',
      selection: TextSelection.collapsed(offset: 17),
    );

    expect(controller.foldedRegions, isEmpty);
    expect(controller.fullText, contains('Inserted'));
    expect(controller.text, controller.fullText);
  });

  test('collapsed-boundary insertion preserves hidden folded content', () {
    const source = '# Title\nIntro.\nMore.\n# Next\nDone.\n';
    final region = sourceFoldRegions(
      source,
      SourceSyntaxLanguage.markdown,
    ).firstWhere((region) => region.startLine == 1);
    final controller = BusyMarkSourceEditingController(
      text: source,
      language: SourceSyntaxLanguage.markdown,
    )..setFoldedRegions([region]);

    expect(controller.text, '# Title\n# Next\nDone.\n');
    controller.value = const TextEditingValue(
      text: '# Title\nInserted\n# Next\nDone.\n',
      selection: TextSelection.collapsed(offset: 17),
    );

    expect(controller.fullText, contains('Intro.\nMore.\n'));
    expect(
      controller.fullText,
      '# Title\nInserted\nIntro.\nMore.\n# Next\nDone.\n',
    );
    expect(controller.foldedRegions, isEmpty);
  });

  test('visible insertions before and after a fold keep hidden text', () {
    const source = '# Title\nIntro.\nMore.\n# Next\nDone.\n';
    final region = sourceFoldRegions(
      source,
      SourceSyntaxLanguage.markdown,
    ).firstWhere((region) => region.startLine == 1);
    final controller = BusyMarkSourceEditingController(
      text: source,
      language: SourceSyntaxLanguage.markdown,
    )..setFoldedRegions([region]);

    controller.value = const TextEditingValue(
      text: 'Lead\n# Title\n# Next\nDone.\n',
      selection: TextSelection.collapsed(offset: 5),
    );
    expect(controller.fullText, contains('Intro.\nMore.\n'));

    controller.value = TextEditingValue(
      text: '${controller.text}Tail\n',
      selection: TextSelection.collapsed(offset: controller.text.length + 5),
    );
    expect(controller.fullText, contains('Intro.\nMore.\n'));
    expect(controller.fullText, endsWith('# Next\nDone.\nTail\n'));
  });

  test('visible deletions near a fold keep hidden text', () {
    const source = '# Title\nIntro.\nMore.\n# Next\nDone.\n';
    final region = sourceFoldRegions(
      source,
      SourceSyntaxLanguage.markdown,
    ).firstWhere((region) => region.startLine == 1);
    final controller = BusyMarkSourceEditingController(
      text: source,
      language: SourceSyntaxLanguage.markdown,
    )..setFoldedRegions([region]);

    controller.value = const TextEditingValue(
      text: '# Titl\n# Next\nDone.\n',
      selection: TextSelection.collapsed(offset: 6),
    );
    expect(controller.fullText, contains('Intro.\nMore.\n'));

    controller.value = const TextEditingValue(
      text: '# Titl\nNext\nDone.\n',
      selection: TextSelection.collapsed(offset: 7),
    );
    expect(controller.fullText, contains('Intro.\nMore.\n'));
  });

  test('visible replacement spanning a fold replaces the hidden range', () {
    const source = '# Title\nIntro.\nMore.\n# Next\nDone.\n';
    final region = sourceFoldRegions(
      source,
      SourceSyntaxLanguage.markdown,
    ).firstWhere((region) => region.startLine == 1);
    final document = SourceDocument(
      fullText: source,
      hiddenRanges: SourceHiddenRanges(
        ranges: [
          SourceHiddenRange(
            start: region.hiddenStartOffset,
            end: region.hiddenEndOffset,
            key: region.key,
          ),
        ],
        textLength: source.length,
      ),
    );

    final next = document.applyVisibleEdit('# Replaced\nDone.\n');

    expect(next, '# Replaced\nDone.\n');
  });
}
