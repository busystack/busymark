import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const script = '<script>alert(1)</script>';
  for (final source in [
    '```html\n$script\n```\n\n$script\n',
    '    $script\n\n$script\n',
    '<div>\n<!--\n$script\n-->\n$script\n</div>\n',
    '<div>\n *hello*\n <<script>alert(1)</script>\n</div>\n',
    '[^unused]: $script\n\n\n$script\n',
    '[^used]: $script\n\n\nSee [^used].\n',
    '- ```html\n  $script\n  ```\n- $script\n',
    '`$script` then $script\n',
    '`` $script ``\n\n$script\n',
    '> ```html\n> $script\n> ```\n>\n> $script\n',
    '- Example\n\n      $script\n\n  $script\n',
    '> - `$script` then $script\n',
    '---\ntitle: "$script"\n---\n\n$script\n',
    '```html\r\n$script\r\n```\r\n\r\n$script\r\n',
    '| Code | HTML |\n| --- | --- |\n| `$script` | $script |\n',
    '| One |\n| --- |\n| a | $script |\n| $script |\n',
    '`a  $script`\n\n## a $script\n',
  ]) {
    test(
      'HTML location follows parsed source: ${source.split('\n').first}',
      () {
        final parsed = const MarkdownParser().parse(
          filePath: '/tmp/html.md',
          source: source,
        );
        final diagnostics = parsed.diagnostics.where(
          (d) => d.code == 'markdown.raw-html.unsafe',
        );
        expect(diagnostics, hasLength(1));
        final span = diagnostics.single.sourceSpan!;
        final start = source.lastIndexOf(script);
        expect(span.startOffset, start);
        expect(span.endOffset, start + '<script'.length);
        expect(
          span.startLine,
          '\n'.allMatches(source.substring(0, start)).length + 1,
        );
        expect(source.substring(span.startOffset, span.endOffset), '<script');
      },
    );
  }

  test(
    'unsafe Markdown URLs are located at the link, after literal examples',
    () {
      const link = '[unsafe](javascript:alert%281%29)';
      const source = '`$link` then $link\n';
      final parsed = const MarkdownParser().parse(
        filePath: '/tmp/html.md',
        source: source,
      );
      final diagnostic = parsed.diagnostics.singleWhere(
        (d) => d.code == 'markdown.raw-html.unsafe',
      );
      expect(diagnostic.sourceSpan!.startOffset, source.lastIndexOf(link));
      expect(
        diagnostic.sourceSpan!.endOffset,
        source.lastIndexOf(link) + link.length,
      );
    },
  );
}
