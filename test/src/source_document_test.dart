import 'package:busymark/src/editor/source/source_document.dart';
import 'package:busymark/src/editor/source/source_hidden_ranges.dart';
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
