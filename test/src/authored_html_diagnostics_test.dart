import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const script = '<script>alert(1)</script>';
  const header = '| One | Two | Three |\n| --- | --- | --- |\n';
  test('escaped table pipes cannot bind across subsequent cells', () {
    final parsed = const MarkdownParser().parse(
      filePath: '/tmp/table.md',
      source: '$header${r'| a\|b | a|b |'}\n',
    );
    expect(parsed.diagnostics, isEmpty);
    final table = parsed.busyDocument.blocks.singleWhere(
      (block) => block.kind == BusyBlockKind.table,
    );
    expect(table.children.last.children.map((cell) => cell.plainText), [
      'a|b',
      'a',
      'b',
    ]);
  });

  for (final row in [
    r'a\|b | a|b',
    r'| a\|b\|c | a|b|c |',
    r'| a\\\|b | a\\|b |',
    r'| a\|b | a|b\',
    r'| a\|b |',
    r'| `a\|b` | a|b |',
  ]) {
    test('escaped table normalization preserves a later HTML cell: $row', () {
      // A separate row also exercises missing, extra, and escaped delimiters
      // without letting their source mapping affect subsequent cells.
      final source = '$header$row\n| a\\|$script | a|$script |\n';
      final parsed = const MarkdownParser().parse(
        filePath: '/tmp/table.md',
        source: source,
      );
      final warnings = parsed.diagnostics.where(
        (d) => d.code == 'markdown.raw-html.unsafe',
      );
      expect(warnings.map((d) => d.sourceSpan!.startOffset), [
        source.indexOf(script),
        source.lastIndexOf(script),
      ]);
    });
  }

  test('escaped pipes in the table header retain diagnostic positions', () {
    final source =
        '| a\\|$script | a|$script |\n| --- | --- | --- |\n| a | b | c |\n';
    final parsed = const MarkdownParser().parse(
      filePath: '/tmp/table.md',
      source: source,
    );
    final warnings = parsed.diagnostics.where(
      (d) => d.code == 'markdown.raw-html.unsafe',
    );
    expect(warnings.map((d) => d.sourceSpan!.startOffset), [
      source.indexOf(script),
      source.lastIndexOf(script),
    ]);
  });

  for (final row in [
    '| a\\|${script}b | a|${script}b |',
    '| `$script` a\\|b | a|$script |',
  ]) {
    test('escaped table cells retain HTML positions: $row', () {
      final source = '$header$row\n';
      final parsed = const MarkdownParser().parse(
        filePath: '/tmp/table.md',
        source: source,
      );
      final warnings = parsed.diagnostics
          .where((d) => d.code == 'markdown.raw-html.unsafe')
          .toList();
      final starts = [
        if (!row.contains('`')) source.indexOf(script),
        source.lastIndexOf(script),
      ];
      expect(warnings.map((d) => d.sourceSpan!.startOffset), starts);
      expect(
        warnings.map((d) => d.sourceSpan!.endOffset),
        starts.map((start) => start + '<script'.length),
      );
      expect(warnings.map((d) => d.sourceSpan!.startLine), everyElement(3));
    });
  }

  const tableHtml = '<table><tr onclick="example()"><td>Cell</td></tr></table>';
  for (final prefix in ['', 'Text ']) {
    test(
      'table HTML attributes are checked in ${prefix.isEmpty ? 'block' : 'inline'} context',
      () {
        final source = '$prefix$tableHtml\n';
        final parsed = const MarkdownParser().parse(
          filePath: '/tmp/table.md',
          source: source,
        );
        final warning = parsed.diagnostics.singleWhere(
          (d) => d.code == 'markdown.raw-html.unsafe',
        );
        expect(warning.sourceSpan!.startOffset, source.indexOf('<tr'));
        expect(
          warning.sourceSpan!.endOffset,
          source.indexOf('<tr') + '<tr'.length,
        );
        expect(warning.sourceSpan!.startLine, 1);
      },
    );
  }

  for (final tag in [
    'caption',
    'colgroup',
    'col',
    'thead',
    'tbody',
    'tfoot',
    'th',
    'td',
  ]) {
    test('inline $tag attributes are checked before tree construction', () {
      final source =
          'Literal `<$tag ONCLICK="example()">` then <$tag ONCLICK="example()">\n';
      final parsed = const MarkdownParser().parse(
        filePath: '/tmp/table.md',
        source: source,
      );
      final warning = parsed.diagnostics.singleWhere(
        (d) => d.code == 'markdown.raw-html.unsafe',
      );
      expect(warning.sourceSpan!.startOffset, source.lastIndexOf('<$tag'));
      expect(
        warning.sourceSpan!.endOffset,
        source.lastIndexOf('<$tag') + tag.length + 1,
      );
    });
  }

  test('inline URL attributes use HTML entity decoding', () {
    const source = 'Text <a href="java&#x73;cript&#58;example()">Link</a>\n';
    final parsed = const MarkdownParser().parse(
      filePath: '/tmp/table.md',
      source: source,
    );
    final warning = parsed.diagnostics.singleWhere(
      (d) => d.code == 'markdown.raw-html.unsafe',
    );
    expect(warning.sourceSpan!.startOffset, source.indexOf('<a'));
    expect(warning.sourceSpan!.endOffset, source.indexOf('<a') + 2);
  });

  for (final source in [
    'Text `$tableHtml`\n',
    'Text ${tableHtml.replaceAll('<', r'\<')}\n',
    '```html\n$tableHtml\n```\n',
    '    $tableHtml\n',
    'Text <table><tr title="onclick=example()"><td>Cell</td></tr></table>\n',
  ]) {
    test('table HTML remains literal or safe: ${source.split('\n').first}', () {
      final parsed = const MarkdownParser().parse(
        filePath: '/tmp/table.md',
        source: source,
      );
      expect(
        parsed.diagnostics.where((d) => d.code == 'markdown.raw-html.unsafe'),
        isEmpty,
      );
    });
  }

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
