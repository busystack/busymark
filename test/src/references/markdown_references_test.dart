import 'package:busymark/src/references/markdown_references.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'repeated reference occurrences retain one exact definition destination',
    () {
      const source =
          '[one][ref] [two][ref] [ref][] [ref]\n\n[ref]: <café%20file.md#id> "title"\n';
      final refs = markdownReferences(identity: 'a.md', source: source);
      expect(refs.length, 4);
      expect(refs.map((r) => r.occurrence.startOffset).toSet().length, 4);
      expect(refs.map((r) => r.destinationSpan!.startOffset).toSet().length, 1);
      for (final ref in refs) {
        expect(
          source.substring(
            ref.destinationSpan!.startOffset,
            ref.destinationSpan!.endOffset,
          ),
          'café%20file.md#id',
        );
      }
    },
  );
  test('inline destinations preserve titles balanced paths and HTML spans', () {
    const source =
        '[one](a_(b).md#id "title") <a href="other.md#id">HTML</a>\n';
    final refs = markdownReferences(identity: 'a.md', source: source);
    expect(refs.length, 2);
    expect(
      refs.map(
        (r) => source.substring(
          r.destinationSpan!.startOffset,
          r.destinationSpan!.endOffset,
        ),
      ),
      ['a_(b).md#id', 'other.md#id'],
    );
  });
  test('code, escaped syntax, comments and losing definitions are excluded', () {
    const source =
        r'\[escape](bad.md)'
        '\n`[inline](bad.md)`\n\n    [indented](bad.md)\n\n```\n[fenced](bad.md)\n```\n\n<!-- <a href="bad.md">hidden</a> -->\n[ok][ref]\n\n[ref]: good.md\n[ref]: ignored.md\n';
    final refs = markdownReferences(identity: 'a.md', source: source);
    expect(refs.map((r) => r.destination), ['good.md']);
  });
  test(
    'multiline container definitions use parser-winning source positions',
    () {
      const source = '> [text][ref]\n>\n> [ref]:\n>   <other.md> "title"\n';
      final refs = markdownReferences(identity: 'a.md', source: source);
      expect(refs.length, 1);
      expect(refs.single.destination, 'other.md');
    },
  );
}
