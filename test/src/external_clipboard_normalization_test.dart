import 'dart:io';

import 'package:busymark/src/clipboard/clipboard_insertion.dart';
import 'package:busymark/src/editor/clipboard_paste_resolver.dart';
import 'package:busymark/src/editor/source/source_paste_engine.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_clipboard_fragment.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_clipboard_html.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_inline_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/document_outline.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/markdown/preview_model.dart';
import 'package:busymark/src/markdown/table_grid.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:markdown/markdown.dart' as md;

import '../support/document_history_harness.dart';

BusyMarkPastePlan _resolve(
  String html, {
  String? native,
  BusyMarkPasteDestination destination =
      BusyMarkPasteDestination.markdownSource,
  BusyMarkPasteMode mode = BusyMarkPasteMode.normal,
}) => const BusyMarkClipboardPasteResolver().resolve(
  snapshot: BusyMarkClipboardSnapshot(
    text: 'Interoperable plain text',
    html: html,
    richFragment: native,
    external: native == null,
    sessionOwned: native != null,
    fromSystemClipboard: true,
  ),
  mode: mode,
  destination: destination,
  markdownMode: MarkdownMode.gfm,
);

String _paste(BusyMarkPastePlan plan) {
  final fragment =
      (plan.candidates.first as BusyMarkStructuredPasteCandidate).fragment;
  final result =
      const SourcePasteEngine().prepareStructured(
            target: const SourcePasteDocumentSnapshot(
              expectedSource: '',
              selection: TextSelection.collapsed(offset: 0),
              format: SourceDocumentFormat.markdown,
              markdownMode: MarkdownMode.gfm,
              filePath: '/project/new.md',
            ),
            fragment: fragment,
          )
          as SourcePasteReady;
  return result.edit.replacement;
}

const _filePath = '/project/new.md';

BusyDocument _parse(String source, {String path = _filePath}) =>
    const MarkdownParser()
        .parse(filePath: path, source: source, mode: MarkdownMode.gfm)
        .busyDocument;

WysiwygClipboardFragment _capture(BusyDocument document) =>
    WysiwygClipboardFragment(
      mode: document.mode,
      sourcePath: document.filePath,
      blocks: [
        for (final block in document.blocks)
          BusyWysiwygStyledBlock(
            kind: block.kind,
            text: block.plainText,
            ranges: busyInlineStyleRanges(block.inlines),
            attributes: block.attributes,
            completeBlock: busyMarkWysiwygImmutableBlockSnapshot(block),
          ),
      ],
    );

String _pasteIntoEditor(BusyMarkPastePlan plan) {
  final fragment =
      (plan.candidates.first as BusyMarkStructuredPasteCandidate).fragment;
  final document = _parse('Target');
  final editor = BusyMarkWysiwygDocumentController(document: document);
  addTearDown(editor.dispose);
  expect(
    editor.insertStyledBlocksAtSelection(
      blockId: document.blocks.single.id,
      selectionStart: 0,
      selectionEnd: 6,
      blocks: fragment.blocks,
    ),
    isNotNull,
  );
  return editor.markdown;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final destination in [
    BusyMarkPasteDestination.markdownSource,
    BusyMarkPasteDestination.editor,
  ]) {
    String paste(String input) {
      final plan = _resolve(input, destination: destination);
      return destination == BusyMarkPasteDestination.editor
          ? _pasteIntoEditor(plan)
          : _paste(plan);
    }

    group(destination.name, () {
      test('expanded browser selection keeps prose and all five bullets', () {
        final items = [for (var i = 1; i <= 5; i++) '<li>Item $i</li>'].join();
        for (final input in [
          '<div>not numbered</div><ul>$items</ul>',
          '<div dir="auto">not numbered</div><ul>$items</ul>',
          '<div>not numbered</div><ul dir="auto">$items</ul>',
          '<div dir="auto"><div>not numbered</div><ul>$items</ul></div>',
        ]) {
          expect(
            paste(input).trim(),
            'not numbered\n\n'
            '${[for (var i = 1; i <= 5; i++) '- Item $i'].join('\n')}',
            reason: input,
          );
        }
      });

      test('job headings, emphasis, block boundaries and address reparse', () {
        const address = '2325 Cambie Street, Vancouver, BC V5Z 2T9';
        const input =
            '<h4 dir="ltr" aria-level="4" role="heading">'
            '<strong>Job details</strong></h4>'
            '<div dir="ltr"><strong>\$20–\$21 an hour</strong></div>'
            '<div dir="ltr">Store discount, On-site parking</div>'
            '<div dir="ltr"><strong>Full-time</strong></div>'
            '<div dir="ltr">Morning shift</div>'
            '<div dir="ltr" role="link" aria-label="Open $address in maps">'
            '<u>$address</u></div>'
            '<h4 dir="ltr" role="heading" aria-level="4" '
            'data-testid="description"><strong>Full job description</strong></h4>'
            '<p>Apply <a href="https://example.test/apply" title="Application">'
            'here</a>.</p>';
        final plain = html.parseFragment(input);
        for (final element in plain.querySelectorAll(
          '[dir], [role], [aria-level], [data-testid], [aria-label]',
        )) {
          element.attributes.clear();
        }
        final underline = plain.querySelector('u')!;
        underline.replaceWith(html.parseFragment(address).nodes.single);
        for (final variant in [
          input,
          '<main dir="ltr">$input</main>',
          '<main dir="ltr">${plain.outerHtml}</main>',
        ]) {
          final output = paste(variant);
          expect(output, contains('#### Job details\n\n'));
          expect(output, contains('#### Full job description\n\n'));
          final blocks = _parse(output).blocks;
          expect(blocks.map((b) => b.plainText), [
            'Job details',
            '\$20–\$21 an hour',
            'Store discount, On-site parking',
            'Full-time',
            'Morning shift',
            address,
            'Full job description',
            'Apply here.',
          ]);
          expect(blocks.first.attributes['level'], '4');
          expect(blocks[6].attributes['level'], '4');
          final outline = const BusyMarkPreviewBuilder()
              .build(_parse(output))
              .outline;
          expect(outline.map((entry) => (entry.level, entry.text)), [
            (4, 'Job details'),
            (4, 'Full job description'),
          ]);
          expect(
            outline.last.sourceStartOffset,
            output.indexOf('#### Full job description'),
          );
          expect(blocks[1].inlines.single.kind, BusyInlineKind.strong);
          expect(blocks[3].inlines.single.kind, BusyInlineKind.strong);
          expect(blocks[5].inlines.single.kind, BusyInlineKind.text);
          final link = blocks.last.inlines.firstWhere(
            (value) => value.kind == BusyInlineKind.link,
          );
          expect(link.destination, 'https://example.test/apply');
          expect(link.attributes['title'], 'Application');
        }
      });

      test(
        'clipboard document wrappers preserve only the selected direction scope',
        () {
          for (final (input, selector) in [
            (
              '<html dir="rtl"><head><title>Hidden title</title></head><body>'
                  '<!--StartFragment--><p>ABC !</p><!--EndFragment--></body></html>',
              '[dir=rtl] p',
            ),
            (
              '<html><body dir="rtl"><!--StartFragment--><section>'
                  '<p>ABC !</p><p dir="ltr">Override !</p></section>'
                  '<!--EndFragment--></body></html>',
              '[dir=rtl] p[dir=ltr]',
            ),
            (
              '<html dir="auto"><body>العربية<!--StartFragment-->'
                  '<p>ABC !</p><!--EndFragment-->unselected tail</body></html>',
              '[dir=rtl] p',
            ),
            (
              '<html><body dir="auto">العربية<!--StartFragment-->'
                  '<p>ABC !</p><!--EndFragment-->unselected tail</body></html>',
              '[dir=rtl] p',
            ),
          ]) {
            final source = paste(input);
            final output = html.parseFragment(source);
            expect(output.querySelector(selector), isNotNull, reason: input);
            expect(output.text, contains('ABC !'));
            expect(output.text, isNot(contains('العربية')));
            expect(output.text, isNot(contains('unselected tail')));
            expect(output.text, isNot(contains('Hidden title')));
          }
          expect(paste('Leading <b>bold</b>').trim(), 'Leading **bold**');
        },
      );

      test('direction and accessibility attributes with meaning survive', () {
        for (final (input, selector) in [
          ('<ul><li dir="rtl">ABC</li></ul>', 'ul li[dir=rtl]'),
          (
            '<div dir="rtl"><p dir="ltr">ABC</p></div>',
            'div[dir=rtl] p[dir=ltr]',
          ),
          ('<p dir="auto">ABC العربية</p>', 'p[dir=auto]'),
          ('<p dir="ltr">123</p>', 'p[dir=ltr]'),
          ('<p>One <span dir="rtl">ABC</span></p>', 'p span[dir=rtl]'),
          ('<p aria-label="Accessible name">Text</p>', 'p[aria-label]'),
          ('<h3 role="heading" aria-level="4">Text</h3>', 'h3[aria-level="4"]'),
          (
            '<table><tr><th>H</th></tr><tr><td dir="rtl">ABC</td></tr></table>',
            'td[dir=rtl]',
          ),
        ]) {
          expect(
            html.parseFragment(paste(input)).querySelector(selector),
            isNotNull,
            reason: input,
          );
        }
        expect(
          paste('<div role="heading" aria-level="4">Details</div>').trim(),
          '#### Details',
        );
      });

      test(
        'workspace save and reopen preserve the pasted outline and raw structure',
        () async {
          final root = await Directory.systemTemp.createTemp(
            'busymark-clipboard-reopen-',
          );
          addTearDown(() => root.delete(recursive: true));
          final target = await File(
            '${root.path}/target.md',
          ).writeAsString('Target\n');
          final history = await DocumentHistoryHarness.create(
            path: target.path,
          );
          addTearDown(history.dispose);
          final output = paste(
            '<h4 dir="ltr" aria-level="4" role="heading">'
            '<strong>Job details</strong></h4><p>Before</p>'
            '<figure><img src="https://example.test/chart.png" alt="Chart">'
            '<figcaption>Quarterly results</figcaption></figure>'
            '<table><tr><th colspan="2">Both</th></tr><tr><td>A</td>'
            '<td><p>Alice</p><p>Bob</p></td></tr></table><p>After</p>',
          );
          history.controller.updateActiveText(output);
          expect(await history.controller.saveActive(), isTrue);

          final reopened = await DocumentHistoryHarness.create(
            path: target.path,
          );
          addTearDown(reopened.dispose);
          expect(reopened.buffer.text, await target.readAsString());
          final document = _parse(reopened.buffer.text, path: target.path);
          expect(
            document.outline.map(
              (entry) => (entry.level, entry.text, entry.id),
            ),
            [(4, 'Job details', 'job-details')],
          );
          final preview = const BusyMarkPreviewBuilder().build(document);
          expect(preview.blocks.map((block) => block.kind), [
            PreviewBlockKind.heading,
            PreviewBlockKind.paragraph,
            PreviewBlockKind.container,
            PreviewBlockKind.container,
            PreviewBlockKind.paragraph,
          ]);
          final figure = preview.blocks[2].children.single;
          expect(figure.children.map((block) => block.text), [
            'Chart',
            'Quarterly results',
          ]);
          expect(
            figure.children.first.attributes['src'],
            'https://example.test/chart.png',
          );
          final table = document.blocks[3].children.single;
          expect(
            table.children.first.children.single.attributes['colspan'],
            '2',
          );
          expect(table.children.last.children.last.plainText, 'Alice\nBob');
        },
      );

      test('figure image, alt and caption survive persistence in order', () {
        final output = paste(
          '<p>Before</p>'
          '<figure><img src="https://example.test/chart.png" alt="Chart">'
          '<figcaption>Quarterly results</figcaption></figure><p>After</p>',
        );
        final parsed = _parse(output).blocks;
        expect(parsed.map((b) => b.kind), [
          BusyBlockKind.paragraph,
          BusyBlockKind.htmlBlock,
          BusyBlockKind.paragraph,
        ]);
        final figure = html.parseFragment(parsed[1].rawSource!);
        expect(
          figure.querySelector('figure img')!.attributes,
          containsPair('src', 'https://example.test/chart.png'),
        );
        expect(figure.querySelector('img')!.attributes['alt'], 'Chart');
        expect(figure.querySelector('figcaption')!.text, 'Quarterly results');
        expect(parsed.first.plainText, 'Before');
        expect(parsed.last.plainText, 'After');
      });

      test('merged cells and their relationships survive reparsing', () {
        for (final (input, rowContents, spans) in [
          (
            '<tr><th colspan="2">Both</th></tr><tr><td>A</td><td>B</td></tr>',
            [
              ['Both'],
              ['A', 'B'],
            ],
            ['colspan'],
          ),
          (
            '<tr><th>H</th><th>I</th></tr><tr><td rowspan="2">A</td><td>B</td></tr>'
                '<tr><td>C</td></tr>',
            [
              ['H', 'I'],
              ['A', 'B'],
              ['C'],
            ],
            ['rowspan'],
          ),
          (
            '<tr><th colspan="2">Both</th></tr>'
                '<tr><td rowspan="2">A</td><td>B</td></tr><tr><td>C</td></tr>',
            [
              ['Both'],
              ['A', 'B'],
              ['C'],
            ],
            ['colspan', 'rowspan'],
          ),
        ]) {
          final blocks = _parse(paste('<table>$input</table>')).blocks;
          final table = blocks.single.children.single;
          expect(table.kind, BusyBlockKind.table);
          expect(
            table.children.map((row) => row.children.map((c) => c.plainText)),
            rowContents,
          );
          final grid = TableGrid.place([
            for (final row in table.children) row.children,
          ], (cell) => cell.attributes);
          expect(grid.columns, 2);
          expect(
            grid.cells
                .singleWhere((cell) => cell.value.plainText == 'B')
                .column,
            1,
          );
          if (spans.contains('rowspan')) {
            expect(
              grid.cells
                  .singleWhere((cell) => cell.value.plainText == 'C')
                  .column,
              1,
            );
          }
          for (final span in spans) {
            expect(
              table.children
                  .expand((r) => r.children)
                  .where((c) => c.attributes[span] == '2'),
              hasLength(1),
            );
          }
        }
        expect(
          paste(
            '<table><tr><th>H</th><th>I</th></tr>'
            '<tr><td>A</td><td>B</td></tr></table>',
          ).trim(),
          '| H | I |\n| --- | --- |\n| A | B |',
        );
      });

      test('table cells keep block boundaries and inline spans', () {
        final output = paste(
          '<table><tr><th>Names</th></tr>'
          '<tr><td><p>A<span>lice</span></p><div>Bob<br>Carol</div></td>'
          '</tr></table>',
        );
        final table = _parse(output).blocks.single;
        expect(
          table.children.last.children.single.plainText,
          'Alice\nBob\nCarol',
        );
      });

      test(
        'fragment markers retain inherited direction and exclude unselected text',
        () {
          final output = paste(
            '<div dir="rtl"><p>Unselected before</p>'
            '<!--StartFragment--><p>ABC !</p><!--EndFragment-->'
            '<p>Unselected after</p></div>',
          );
          final wrapper = html
              .parseFragment(output)
              .querySelector('div[dir=rtl]')!;
          expect(wrapper.text, 'ABC !');
          expect(wrapper.children.single.localName, 'p');
        },
      );

      test('preformatted siblings and breaks survive Markdown round trip', () {
        for (final (input, expected) in [
          ('before <code>inside</code> after', 'before inside after'),
          ('<code>one</code>\n<code>two</code>', 'one\ntwo'),
          ('A<br>B', 'A\nB'),
          ('\n\n  A\tB\n\n', '\n  A\tB\n\n'),
          ('<code class="language-dart">\n  A\tB\n\n</code>', '\n  A\tB\n\n'),
        ]) {
          final block = _parse(paste('<pre>$input</pre>')).blocks.single;
          expect(block.kind, BusyBlockKind.codeBlock);
          expect(block.plainText, expected, reason: input);
          if (input.contains('language-dart')) {
            expect(block.attributes['language'], 'dart');
          }
        }
      });
    });
  }

  test(
    'authored HTML list order and markers render from the default adapter',
    () {
      const input =
          '<ul dir="auto"><li>Before<ul><li>Nested</li></ul>After</li></ul>'
          '\n\n<ol type="A" reversed start="5"><li>Fifth</li>'
          '<li value="2">Second</li><li>First</li></ol>'
          '\n\n<ol type="i" reversed><li>Two</li><li>One</li></ol>';
      final blocks = _parse(input).blocks;
      final item = blocks.first.children.single;
      expect(item.plainText, 'Before');
      expect(item.children.map((block) => block.plainText), [
        'Nested',
        'After',
      ]);
      expect(blocks[1].children.map((b) => b.attributes['marker']), [
        'E.',
        'B.',
        'A.',
      ]);
      expect(blocks[2].children.map((b) => b.attributes['marker']), [
        'ii.',
        'i.',
      ]);
    },
  );

  test(
    'external clipboard HTML retains authored list, figure and link metadata',
    () {
      final fragment = _capture(
        _parse(
          'Before\n\n'
          '<ol type="A" reversed start="5"><li dir="rtl">Fifth</li>'
          '<li value="2">Second</li><li><a href="guide.md" title="Guide">First</a></li></ol>'
          '\n\n<figure><img src="https://example.test/chart.png" alt="Chart">'
          '<figcaption>Quarterly results</figcaption></figure>\n\nAfter',
        ),
      );
      final published = html.parseFragment(
        const WysiwygClipboardHtml().encode(fragment),
      );
      expect(
        published.querySelector('ol[type=A][reversed][start="5"]'),
        isNotNull,
      );
      expect(published.querySelector('li[dir=rtl]')!.text, 'Fifth');
      expect(published.querySelector('li[value="2"]')!.text, 'Second');
      expect(published.querySelector('a[title=Guide]')!.text, 'First');
      expect(
        published.querySelector('figure figcaption')!.text,
        'Quarterly results',
      );
      expect(published.querySelector('figure img')!.attributes['alt'], 'Chart');
    },
  );

  test('BusyMark GFM drops the extra body cell in the former span output', () {
    final table = _parse('| Both |\n| --- |\n| A | B |').blocks.single;
    expect(table.children.last.children.map((cell) => cell.plainText), ['A']);
  });

  test(
    'native clipboard raw HTML rebases its persisted references and assets',
    () {
      const source = '/project/old/source.md';
      const target = '/project/new/target.md';
      const input =
          '<div><a href="guide%20one.md?q=a%26b#c%20d">Guide</a>'
          '<img src="chart.png" alt="Chart"></div>';
      final fragment = WysiwygClipboardFragment.decode(
        _capture(_parse(input, path: source)).encode(),
      )!;
      expect(fragment.rebase(source).markdown.trim(), input);
      final output = fragment
          .rebase(
            target,
            mediaDestinations: {'chart.png': 'assets/retained-chart.png'},
          )
          .serializeFor(
            destinationMode: MarkdownMode.gfm,
            destinationFilePath: target,
          );
      final markup = html.parseFragment(
        _parse(output, path: target).blocks.single.rawSource!,
      );
      final link = markup.querySelector('a')!.attributes['href']!;
      expect(
        Uri.file(target).resolve(link).toString(),
        'file:///project/old/guide%20one.md?q=a%26b#c%20d',
      );
      expect(
        markup.querySelector('img')!.attributes['src'],
        'assets/retained-chart.png',
      );
    },
  );

  test(
    'synthetic browser selection preserves headings, prose and destinations',
    () {
      final source = File(
        'test/fixtures/clipboard/synthetic_browser_job.html',
      ).readAsStringSync();
      final markdown = _paste(_resolve(source));
      expect(
        markdown,
        '## Example Developer\n\n'
        '**About the role**\n\n'
        'Build tools with the team.  \nOffice hours vary.\n\n'
        '[Application details](https://example.test/apply?source=listing&tracking=abc)\n\n'
        '*Keep this selected interface text.*\n\n'
        '```dart\nvoid main() {}\n```\n',
      );
      final rendered = html.parseFragment(md.markdownToHtml(markdown));
      expect(rendered.querySelector('h2')!.text, 'Example Developer');
      expect(rendered.querySelectorAll('p'), hasLength(4));
      expect(rendered.querySelectorAll('p br'), hasLength(1));
      expect(
        rendered.querySelector('p em')!.text,
        'Keep this selected interface text.',
      );
      expect(rendered.querySelectorAll('a'), hasLength(1));
      expect(
        rendered.querySelector('a')!.attributes['href'],
        'https://example.test/apply?source=listing&tracking=abc',
      );
      expect(
        rendered.querySelector('pre code')!.classes,
        contains('language-dart'),
      );

      final plain = _resolve(source, mode: BusyMarkPasteMode.plainText);
      expect(
        (plain.candidates.single as BusyMarkPlainTextPasteCandidate).text,
        'Interoperable plain text',
      );
    },
  );

  for (final destination in [
    BusyMarkPasteDestination.markdownSource,
    BusyMarkPasteDestination.editor,
  ]) {
    test('browser table preserves consecutive breaks in ${destination.name}', () {
      for (final (imported, header, body) in [
        (
          '<table><tr><th>H</th></tr><tr><td>A<br><br>B</td></tr></table>',
          'H',
          'A<br><br>B',
        ),
        (
          '<table><tr><th><p><strong>H</strong><br><br>I</p></th></tr>'
              '<tr><td><p>A<span><br><br><em>B</em></span></p></td></tr></table>',
          '**H**<br><br>I',
          'A<br><br>*B*',
        ),
      ]) {
        final plan = _resolve(imported, destination: destination);
        final fragment =
            (plan.candidates.first as BusyMarkStructuredPasteCandidate)
                .fragment;
        final table = fragment.documentBlocks.single;
        expect(table.kind, BusyBlockKind.table);
        for (final cell in table.children.expand((row) => row.children)) {
          if (cell.plainText == 'H') continue;
          expect(
            cell.inlines.where(
              (inline) => inline.kind == BusyInlineKind.hardBreak,
            ),
            hasLength(2),
          );
        }
        final String output;
        if (destination == BusyMarkPasteDestination.markdownSource) {
          output = _paste(plan);
        } else {
          final document = const MarkdownParser()
              .parse(
                source: 'Target',
                filePath: '/project/new.md',
                mode: MarkdownMode.gfm,
              )
              .busyDocument;
          final editor = BusyMarkWysiwygDocumentController(document: document);
          addTearDown(editor.dispose);
          expect(
            editor.insertStyledBlocksAtSelection(
              blockId: document.blocks.single.id,
              selectionStart: 0,
              selectionEnd: 6,
              blocks: fragment.blocks,
            ),
            isNotNull,
          );
          output = editor.markdown;
        }
        expect(output.trim(), '| $header |\n| --- |\n| $body |');
        final rendered = html.parseFragment(
          md.markdownToHtml(
            output,
            extensionSet: md.ExtensionSet.gitHubFlavored,
          ),
        );
        expect(rendered.querySelector('td')!.text, 'AB');
        expect(rendered.querySelectorAll('td br'), hasLength(2));
        if (header != 'H') {
          expect(rendered.querySelectorAll('th br'), hasLength(2));
          expect(rendered.querySelector('th strong')!.text, 'H');
          expect(rendered.querySelector('td em')!.text, 'B');
        }
      }
    });
  }

  test(
    'a line break between linked words and an image-only link remain linked',
    () {
      final markdown = _paste(
        _resolve(
          '<p><a href="guide.md#install">Read<br>this guide</a></p>'
          '<p><a href="https://example.test/big"><img src="https://example.test/small"></a></p>',
        ),
      );
      expect(
        markdown,
        '[Read  \nthis guide](guide.md#install)\n\n'
        '[![](https://example.test/small)](https://example.test/big)',
      );
      final rendered = html.parseFragment(md.markdownToHtml(markdown));
      expect(rendered.querySelector('a br'), isNotNull);
      expect(
        rendered.querySelector('a[href="guide.md#install"]')!.text,
        contains('this guide'),
      );
      expect(
        rendered
            .querySelector('a[href="https://example.test/big"] img')!
            .attributes['src'],
        'https://example.test/small',
      );
    },
  );

  test(
    'DOM ownership retains tight, loose, nested, task and restarted lists',
    () {
      final source = File(
        'test/fixtures/clipboard/browser_list_ownership.html',
      ).readAsStringSync();
      final markdown = _paste(_resolve(source));
      expect(
        markdown,
        '- Design\n  - Outline\n  - Review\n- Test\n\n'
        '+ [x] Ship\n+ [ ] Document\n\n'
        '3. Third\n4. Fourth\n\n'
        '3) Restart\n4) Continue\n\n'
        '- First paragraph\n\n  Second paragraph\n\n- Last item\n',
      );
      final rendered = html.parseFragment(
        md.markdownToHtml(
          markdown,
          extensionSet: md.ExtensionSet.gitHubFlavored,
        ),
      );
      final lists = rendered.children;
      expect(lists.map((list) => list.localName), [
        'ul',
        'ul',
        'ol',
        'ol',
        'ul',
      ]);
      expect(
        lists.first.querySelectorAll('li ul li').map((node) => node.text),
        ['Outline', 'Review'],
      );
      expect(lists.first.querySelector('li p'), isNull);
      expect(lists[1].querySelectorAll('input'), hasLength(2));
      expect(lists[1].querySelectorAll('input[checked]'), hasLength(1));
      expect(lists[2].attributes['start'], '3');
      expect(lists[3].attributes['start'], '3');
      expect(
        lists[4].children.first.querySelectorAll('p').map((node) => node.text),
        ['First paragraph', 'Second paragraph'],
      );
    },
  );

  test('HTML-only list markers survive when Markdown cannot encode them', () {
    const list =
        '<ol type="A" reversed="" start="5"><li>Fifth</li>'
        '<li value="2">Second</li><li>First</li></ol>';
    final markdown = _paste(_resolve(list));
    expect(markdown, '$list\n');
    final rendered = html.parseFragment(md.markdownToHtml(markdown));
    expect(
      rendered.querySelector('ol[reversed][type="A"][start="5"]'),
      isNotNull,
    );
    expect(rendered.querySelector('ol li[value="2"]')!.text, 'Second');
  });

  test('direction with an HTML heading and a linked video retains meaning', () {
    final markup = _paste(
      _resolve(
        '<h2 class="site" dir="rtl">عنوان</h2>'
        '<p><a href="https://example.test/movie" aria-label="Watch">'
        '<video src="https://example.test/movie"></video></a></p>',
      ),
    );
    expect(
      markup,
      '<h2 dir="rtl">عنوان</h2>\n\n'
      '[Watch](https://example.test/movie)\n',
    );
    final rendered = html.parseFragment(md.markdownToHtml(markup));
    expect(rendered.querySelector('h2[dir="rtl"]')!.text, 'عنوان');
    expect(
      rendered.querySelector('a')!.attributes['href'],
      'https://example.test/movie',
    );
  });

  test('native rich fragment priority retains authored metadata', () {
    final heading = BusyBlock(
      id: 'heading',
      kind: BusyBlockKind.heading,
      attributes: const {
        'level': '2',
        'class': 'authored',
        'id': 'guide',
        'generatedId': 'false',
      },
      inlines: const [
        BusyInline(kind: BusyInlineKind.text, text: 'Native heading'),
      ],
    );
    final native = WysiwygClipboardFragment(
      mode: MarkdownMode.writersideMarkdown,
      blocks: [
        BusyWysiwygStyledBlock(
          kind: heading.kind,
          ranges: const [],
          text: heading.plainText,
          completeBlock: heading,
        ),
      ],
    );
    final plan = _resolve(
      '<h2 class="browser">Alternative</h2>',
      native: native.encode(),
    );
    final candidate = plan.candidates.first as BusyMarkStructuredPasteCandidate;
    expect(candidate.source, BusyMarkStructuredClipboardSource.richFragment);
    expect(
      candidate.fragment.documentBlocks.single.attributes['class'],
      'authored',
    );
    expect(_paste(plan), '## Native heading {id="guide" class="authored"}\n');
  });
}
