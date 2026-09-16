import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/writerside/writerside_html_reference_scanner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const scanner = WritersideAuthoredHtmlReferenceScanner();

  List<WritersideAuthoredHtmlAnchorReference> scan(String source) {
    final markdown = const MarkdownParser().parse(
      filePath: '/project/topics/source.md',
      source: source,
      mode: MarkdownMode.writersideMarkdown,
      validateLocalReferences: false,
    );
    return scanner.scanMarkdownAnchors(
      filePath: markdown.filePath,
      source: source,
      protectedSource: writersideMarkdownLiteralMask(
        source: source,
        protectedRanges: markdown.codeBlocks.map((block) => block.span),
      ),
    );
  }

  test('finds exact href and body spans for every supported quote form', () {
    const source = '''
<A class="x" HREF="one.md" title="One">One</A>
<a href='two.md'><strong>Two</strong></a>
<a data-href="ignored.md" href=three.md>Three</a>
<a data-href="ignored.md">Ignored</a>
''';

    final references = scan(source);

    expect(references.map((reference) => reference.href), [
      'one.md',
      'two.md',
      'three.md',
    ]);
    expect(references.map((reference) => reference.quote), [
      WritersideHtmlAttributeQuote.doubleQuoted,
      WritersideHtmlAttributeQuote.singleQuoted,
      WritersideHtmlAttributeQuote.unquoted,
    ]);
    expect(
      references.map(
        (reference) => source.substring(
          reference.hrefSpan.startOffset,
          reference.hrefSpan.endOffset,
        ),
      ),
      ['one.md', 'two.md', 'three.md'],
    );
    expect(
      references.map(
        (reference) => source.substring(
          reference.innerContentSpan!.startOffset,
          reference.innerContentSpan!.endOffset,
        ),
      ),
      ['One', '<strong>Two</strong>', 'Three'],
    );
    expect(references.every((reference) => reference.structurallySafe), isTrue);
  });

  test(
    'ignores comments, fenced code, and inline code but keeps containers',
    () {
      const source = '''
<!-- <a href="comment.md">Comment</a> -->

```html
<a href="fenced.md">Fenced</a>
```

`<a href="inline.md">Inline</a>`

![Image](image.png "<a href='image-title.md'>Image title</a>")

[Other](other.md "<a href='link-title.md'>Link title</a>")

- Read <a href="list.md">List</a>.

> Read <a href="quote.md">Quote</a>.
''';

      expect(scan(source).map((reference) => reference.href), [
        'list.md',
        'quote.md',
      ]);
    },
  );

  test('multiline anchors are exact and malformed anchors remain manual', () {
    const source = '''
Read <a
  origin="main"
  href="guide.md#part"
  class="x">Guide</a>.

Read <a href=broken.md>Broken.
''';

    final references = scan(source);

    expect(references, hasLength(2));
    expect(references.first.origin, 'main');
    expect(references.first.href, 'guide.md#part');
    expect(references.first.structurallySafe, isTrue);
    expect(references.last.href, 'broken.md');
    expect(references.last.structurallySafe, isFalse);
    expect(references.last.anchorSpan, isNull);
  });
}
