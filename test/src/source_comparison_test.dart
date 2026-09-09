import 'package:busymark/src/comparison/source_comparison.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SourceComparison compare(
    String oldSource,
    String currentSource, {
    int? bound,
  }) {
    return compareSource(
      SourceComparisonInput(
        id: 'old-input',
        version: 1,
        label: 'old',
        source: oldSource,
      ),
      SourceComparisonInput(
        id: 'current-input',
        version: 2,
        label: 'current',
        source: currentSource,
      ),
      maximumLcsCells: bound ?? 2000000,
    );
  }

  test('keeps separated edits as exact separate changes', () {
    final unchanged = List.generate(1500, (index) => 'line $index\n');
    final oldLines = [...unchanged];
    final currentLines = [...unchanged];
    oldLines[120] = 'old first\n';
    currentLines[120] = 'new first\n';
    oldLines[1320] = 'old second\n';
    currentLines[1320] = 'new second\n';

    final result = compare(oldLines.join(), currentLines.join(), bound: 2000);

    expect(result.simplified, isFalse);
    expect(result.changes, hasLength(2));
    expect(result.changes.every((change) => change.exact), isTrue);
    expect(result.changes[0].oldText, 'old first\n');
    expect(result.changes[1].currentText, 'new second\n');
  });

  test('handles repeated lines without losing exact offsets', () {
    const oldSource = 'same\nsame\nold\nsame\nsame\n';
    const currentSource = 'same\nsame\nnew\nsame\nsame\n';
    final result = compare(oldSource, currentSource);

    expect(result.changes, hasLength(1));
    final change = result.changes.single;
    expect(change.exact, isTrue);
    expect(
      oldSource.substring(change.oldRange.start, change.oldRange.end),
      'old\n',
    );
    expect(
      currentSource.substring(
        change.currentRange.start,
        change.currentRange.end,
      ),
      'new\n',
    );
  });

  test('refines Unicode intraline ranges on UTF-16 boundaries', () {
    const oldSource = 'A 😀 brown fox\n';
    const currentSource = 'A 😀 blue fox\n';
    final change = compare(oldSource, currentSource).changes.single;

    expect(
      change.oldText.substring(
        change.oldIntralineRange.start,
        change.oldIntralineRange.end,
      ),
      'rown',
    );
    expect(
      change.currentText.substring(
        change.currentIntralineRange.start,
        change.currentIntralineRange.end,
      ),
      'lue',
    );
  });

  test('distinguishes whitespace, final newline, empty, and XML changes', () {
    expect(compare('a\tb\n', 'a  b\n').changes, hasLength(1));
    expect(
      compare('<p>old</p>\n', '<p>new</p>\n').changes.single.exact,
      isTrue,
    );
    expect(compare('text', 'text\n').changes.single.currentText, 'text\n');
    expect(compare('', 'created\n').changes.single.oldRange.start, 0);
    expect(compare('removed\n', '').changes.single.currentRange.end, 0);
  });

  test('labels an unanchored expensive comparison as simplified', () {
    final oldSource = List.generate(100, (index) => 'old $index\n').join();
    final currentSource = List.generate(100, (index) => 'new $index\n').join();
    final result = compare(oldSource, currentSource, bound: 100);

    expect(result.simplified, isTrue);
    expect(result.changes.single.exact, isFalse);
  });

  test('version identity detects stale comparison inputs', () {
    final result = compare('old\n', 'new\n');
    expect(result.stillMatches(result.oldInput, result.currentInput), isTrue);
    expect(
      result.stillMatches(
        result.oldInput,
        SourceComparisonInput(
          id: result.currentInput.id,
          version: 3,
          label: 'current',
          source: 'newer\n',
        ),
      ),
      isFalse,
    );
  });
}
