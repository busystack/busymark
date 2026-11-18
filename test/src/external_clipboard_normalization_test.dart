import 'dart:io';

import 'package:busymark/src/clipboard/clipboard_insertion.dart';
import 'package:busymark/src/editor/clipboard_paste_resolver.dart';
import 'package:busymark/src/editor/source/source_paste_engine.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_clipboard_fragment.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:markdown/markdown.dart' as md;

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

void main() {
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
