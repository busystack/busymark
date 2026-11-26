import 'dart:convert';
import 'dart:io';

import 'package:busymark/src/editor/source/source_paste_engine.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_clipboard_fragment.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_clipboard_html.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_commands.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/export/html_export_models.dart';
import 'package:busymark/src/export/html_export_service.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/busymark_markdown_serializer.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/markdown/raw_html_adapter.dart';
import 'package:busymark/src/markdown/preview_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;

import '../support/document_history_harness.dart';

const _codec = WysiwygClipboardHtml();
const _parser = MarkdownParser();
const _serializer = BusyMarkMarkdownSerializer();

WysiwygClipboardFragment _capture(
  List<BusyBlock> blocks, {
  String sourcePath = '/origin/source.md',
  Map<String, String> mediaPaths = const {},
}) => WysiwygClipboardFragment(
  mode: MarkdownMode.gfm,
  sourcePath: sourcePath,
  mediaPaths: mediaPaths,
  blocks: [
    for (final block in blocks)
      BusyWysiwygStyledBlock(
        kind: block.kind,
        text: block.plainText,
        ranges: const [],
        completeBlock: block,
      ),
  ],
);

BusyDocument _parse(String source) => _parser
    .parse(
      filePath: '/origin/source.md',
      source: source,
      mode: MarkdownMode.gfm,
    )
    .busyDocument;

String _paste(String source) => _codec
    .decode(source, mode: MarkdownMode.gfm)!
    .serializeFor(
      destinationMode: MarkdownMode.gfm,
      destinationFilePath: '/target.md',
    );

Future<String> _export(String source) async {
  final root = await Directory.systemTemp.createTemp('busymark-inline-export-');
  addTearDown(() => root.delete(recursive: true));
  final result = await HtmlExportService(stylesheetLoader: () async => '')
      .exportMarkdown(
        MarkdownHtmlExportRequest(
          source: source,
          filePath: '${root.path}/source.md',
          workspaceRoot: root.path,
          destinationPath: '${root.path}/index.html',
        ),
      );
  return File(result.entryPointPath).readAsString();
}

void main() {
  test(
    'directional inline keeps nested formatting in Markdown and both HTML outputs',
    () async {
      const content =
          '<span dir="rtl"><a href="https://example.test/guide" '
          'title="Guide"><strong>ABC &amp; DEF</strong> <em>details</em></a></span>';
      final inlines = const RawHtmlAdapter().parseRawHtmlInlineFragment(
        content,
      )!;
      final source = _serializer.serializeInlineFragment(inlines);
      final markup = html.parseFragment(source);
      expect(markup.querySelector('[dir=rtl] a strong')?.text, 'ABC & DEF');
      expect(markup.querySelector('[dir=rtl] a em')?.text, 'details');
      expect(markup.querySelector('a')?.attributes['title'], 'Guide');

      final document = _parse('Read $source today.');
      final clipboard = html.parseFragment(
        _codec.encode(_capture(document.blocks)),
      );
      expect(clipboard.querySelector('[dir=rtl] a strong')?.text, 'ABC & DEF');
      expect(
        clipboard.querySelector('a')?.attributes['href'],
        'https://example.test/guide',
      );
      final exported = html.parseFragment(
        await _export('Read $content today.'),
      );
      expect(exported.querySelector('[dir=rtl] a strong')?.text, 'ABC & DEF');
      expect(
        exported.querySelector('[dir=rtl] a')?.attributes['title'],
        'Guide',
      );
    },
  );

  test(
    'semantic inline HTML survives paste, reparsing, copy and export',
    () async {
      const input =
          '<p>H<sub>2</sub>O and x<sup>2</sup>. <mark>Remember</mark>'
          ' <q>quoted</q> <ruby>漢<rp>(</rp><rt>かん</rt><rp>)</rp></ruby>.</p>';
      final output = _paste(input);
      for (final markup in [
        output,
        _codec.encode(_capture(_parse(output).blocks)),
        await _export(output),
      ]) {
        final fragment = html.parseFragment(markup);
        for (final (selector, text) in [
          ('sub', '2'),
          ('sup', '2'),
          ('mark', 'Remember'),
          ('q', 'quoted'),
          ('ruby rt', 'かん'),
          ('ruby rp', '('),
        ]) {
          expect(fragment.querySelector(selector)?.text, text, reason: markup);
        }
      }
      expect(
        _paste('<p><b>Plain Markdown</b></p>').trim(),
        '**Plain Markdown**',
      );
    },
  );

  test(
    'semantic HTML remains editable and survives workspace Save and reopen',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'busymark-semantic-save-',
      );
      addTearDown(() => root.delete(recursive: true));
      final file = await File(
        '${root.path}/topic.md',
      ).writeAsString('Target\n');
      final incoming = _codec.decode(
        '<p>Try <mark><strong>bold</strong></mark>, x<sup>23</sup> and '
        '<q><a href="https://example.test/guide">Guide</a></q>.</p>',
        mode: MarkdownMode.gfm,
      )!;
      final controller = BusyMarkWysiwygDocumentController(
        document: _parse('Target'),
      );
      addTearDown(controller.dispose);
      final id = controller.document.blocks.single.id;
      expect(
        controller.insertStyledBlocksAtSelection(
          blockId: id,
          selectionStart: 0,
          selectionEnd: 6,
          blocks: incoming.blocks,
        ),
        isNotNull,
      );
      controller.updateBlockText(id, 'Try bold, x253 and Guide.');
      controller.updateBlockText(id, 'Try bold, x253 and Guide. Edited.');
      final authoring = await DocumentHistoryHarness.create(path: file.path);
      addTearDown(authoring.dispose);
      authoring.controller.updateActiveText(controller.markdown);
      expect(await authoring.controller.saveActive(), isTrue);

      final reopened = await DocumentHistoryHarness.create(path: file.path);
      addTearDown(reopened.dispose);
      final document = _parse(reopened.buffer.text);
      final preview = const BusyMarkPreviewBuilder()
          .build(document)
          .blocks
          .single;
      final mark = preview.inlines.singleWhere(
        (i) => i.attributes['htmlTag'] == 'mark',
      );
      expect(
        (mark.children.single.kind, mark.children.single.text),
        (PreviewInlineKind.strong, 'bold'),
      );
      expect(
        preview.inlines
            .singleWhere((i) => i.attributes['htmlTag'] == 'sup')
            .text,
        '253',
      );
      final quote = preview.inlines.singleWhere(
        (i) => i.attributes['htmlTag'] == 'q',
      );
      expect(
        (quote.children.single.text, quote.children.single.destination),
        ('Guide', 'https://example.test/guide'),
      );
      expect(preview.text, 'Try bold, x253 and Guide. Edited.');
    },
  );

  test('block hyperlink retains both paragraphs in flow and in a table', () {
    const link =
        '<a href="https://example.test/people"><p>Alice</p><p>Bob</p></a>';
    final ordinary = _paste(link);
    final flow = _parse(ordinary).blocks;
    expect(flow.map((b) => b.plainText), ['Alice', 'Bob']);
    expect(
      flow.map((b) => b.inlines.single.destination),
      everyElement('https://example.test/people'),
    );
    final table = _parse(
      _paste('<table><tr><th>People</th></tr><tr><td>$link</td></tr></table>'),
    );
    final cell = table.blocks.single.children.last.children.single;
    expect(cell.plainText, 'Alice\nBob');
    expect(
      cell.inlines
          .where((i) => i.kind == BusyInlineKind.link)
          .map((i) => (i.plainText, i.destination)),
      [
        ('Alice', 'https://example.test/people'),
        ('Bob', 'https://example.test/people'),
      ],
    );
  });

  test(
    'attributed deletion survives native insertion, Save and both HTML writers',
    () async {
      const cite = 'https://example.test/change';
      const date = '2026-11-26';
      const markup =
          'Before <del cite="$cite" datetime="$date">old</del> after';
      final fragment = WysiwygClipboardFragment.decode(
        _capture(_parse(markup).blocks).encode(),
      )!;
      final editor = BusyMarkWysiwygDocumentController(
        document: _parse('Target'),
      );
      addTearDown(editor.dispose);
      expect(
        editor.insertStyledBlocksAtSelection(
          blockId: editor.document.blocks.single.id,
          selectionStart: 0,
          selectionEnd: 6,
          blocks: fragment.blocks,
        ),
        isNotNull,
      );
      final root = await Directory.systemTemp.createTemp(
        'busymark-deletion-save-',
      );
      addTearDown(() => root.delete(recursive: true));
      final file = await File(
        '${root.path}/topic.md',
      ).writeAsString('Target\n');
      final workspace = await DocumentHistoryHarness.create(path: file.path);
      addTearDown(workspace.dispose);
      workspace.controller.updateActiveText(editor.markdown);
      expect(await workspace.controller.saveActive(), isTrue);
      final reopened = await DocumentHistoryHarness.create(path: file.path);
      addTearDown(reopened.dispose);
      for (final source in [
        reopened.buffer.text,
        _codec.encode(_capture(_parse(markup).blocks)),
        await _export(markup),
      ]) {
        final deletion = html.parseFragment(source).querySelector('del');
        expect(
          (
            deletion?.text,
            deletion?.attributes['cite'],
            deletion?.attributes['datetime'],
          ),
          ('old', cite, date),
          reason: source,
        );
      }
      expect(
        _paste('<p>Before <del>old</del> after</p>').trim(),
        'Before ~~old~~ after',
      );
    },
  );

  test(
    'HTML export packages relative citations from their source document',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'busymark-citation-export-',
      );
      addTearDown(() => root.delete(recursive: true));
      final work = await Directory('${root.path}/work').create();
      final output = await Directory('${root.path}/export').create();
      final changes = await Directory('${work.path}/changes').create();
      const bytes = 'Revision history\n';
      await File('${changes.path}/revision A.txt').writeAsString(bytes);
      await File('${root.path}/outside.txt').writeAsString('Outside');
      const citation = 'changes/revision%20A.txt?token=a%26b#part%202';
      const external = 'https://example.test/report?mode=full#notes';
      const date = '2026-11-26';
      const source =
          'Before <del cite="$citation" datetime="$date">old</del> '
          '<q cite="$citation">quote</q> <ins cite="$citation">new</ins> '
          '<q cite="$external">external</q> '
          '<q cite="topic.md?view=full#revision-history">entry</q> after.\n\n'
          '## Revision history\n\n'
          '<div><q cite="$citation">raw quote</q>'
          '<del cite="$citation">raw old</del><ins cite="$citation">raw new</ins>'
          '<q cite="javascript:alert(1)">unsafe</q>'
          '<q cite="../outside.txt">outside</q></div>\n';
      Future<HtmlExportResult> export(
        String filename,
        HtmlPackaging packaging,
      ) => HtmlExportService(stylesheetLoader: () async => '').exportMarkdown(
        MarkdownHtmlExportRequest(
          source: source,
          filePath: '${work.path}/topic.md',
          workspaceRoot: work.path,
          destinationPath: '${output.path}/$filename',
          options: HtmlExportOptions(packaging: packaging),
        ),
      );
      final result = await export('index.html', HtmlPackaging.assetsDirectory);
      final entry = File(result.entryPointPath);
      final markup = html.parse(await entry.readAsString());
      final cited = {
        for (final element in markup.querySelectorAll('del, q, ins'))
          element.text: element,
      };
      expect(cited['old']!.attributes['datetime'], date);
      expect(cited['external']!.attributes['cite'], external);
      expect(cited['entry']!.attributes['cite'], '?view=full#revision-history');
      expect(cited['unsafe']!.attributes['cite'], isNull);
      expect(cited['outside']!.attributes['cite'], isNull);
      for (final label in [
        'old',
        'quote',
        'new',
        'raw quote',
        'raw old',
        'raw new',
      ]) {
        final uri = Uri.file(
          entry.path,
        ).resolve(cited[label]!.attributes['cite']!);
        expect(uri.query, 'token=a%26b', reason: label);
        expect(uri.fragment, 'part%202', reason: label);
        expect(
          await File(
            Uri(scheme: 'file', path: uri.path).toFilePath(),
          ).readAsString(),
          bytes,
          reason: label,
        );
      }

      final single = await export('single.html', HtmlPackaging.singleFile);
      final embedded = html.parse(
        await File(single.entryPointPath).readAsString(),
      );
      final data = embedded.querySelector('del')!.attributes['cite']!;
      final hash = data.indexOf('#');
      expect(data.substring(hash), '#part%202');
      expect(
        UriData.parse(data.substring(0, hash)).contentAsString(encoding: utf8),
        bytes,
      );
      expect(
        single.warnings.map((warning) => warning.code),
        contains('link.embedded-query'),
      );
    },
  );

  test('auto direction respects overrides and original fragment scope', () {
    final whole = html.parseFragment(
      _paste('<div dir="auto"><p>العربية</p><p dir="ltr">LTR</p></div>'),
    );
    expect(whole.querySelector('[dir=auto] p[dir=ltr]')?.text, 'LTR');
    final partial = html.parseFragment(
      _paste(
        '<div dir="auto">العربية<!--StartFragment-->'
        '<p>Latin only</p><!--EndFragment-->tail</div>',
      ),
    );
    expect(partial.querySelector('div[dir=rtl] p')?.text, 'Latin only');
    expect(partial.text, isNot(contains('العربية')));
    expect(partial.text, isNot(contains('tail')));
  });

  test(
    'layout table preserves section and row directions and cell anchors',
    () {
      final source = _paste(
        '<p>See <a href="#target">destination</a></p>'
        '<table role="presentation"><tbody dir="rtl"><tr>'
        '<td id="target"><p>Latin under RTL</p></td></tr>'
        '<tr dir="ltr"><td><p>LTR row</p></td></tr></tbody></table>',
      );
      final fragment = html.parseFragment(source);
      expect(
        fragment.querySelector('[dir=rtl] #target')?.text,
        'Latin under RTL',
      );
      expect(fragment.querySelector('[dir=rtl] [dir=ltr]')?.text, 'LTR row');
      final link = _parse(source).blocks.first.inlines.last;
      expect((link.plainText, link.destination), ('destination', '#target'));
    },
  );

  test('retained Markdown and raw HTML images keep query and fragment', () {
    const ref = 'diagram.svg?v=a%26b#detail%202';
    final before = _parse('![]($ref)\n\n<div><img src="$ref" alt=""></div>');
    final fragment = _capture(
      before.blocks,
      mediaPaths: {ref: '/origin/diagram.svg'},
    );
    final htmlOut = html.parseFragment(_codec.encode(fragment));
    expect(
      htmlOut.querySelectorAll('img').map((img) => img.attributes['src']),
      everyElement('file:///origin/diagram.svg?v=a%26b#detail%202'),
    );
    final rebased = fragment
        .rebase('/target.md', mediaDestinations: {ref: 'assets/diagram.svg'})
        .serializeFor(
          destinationMode: MarkdownMode.gfm,
          destinationFilePath: '/target.md',
        );
    expect(
      RegExp(r'assets/diagram\.svg\?v=a%26b#detail%202').allMatches(rebased),
      hasLength(2),
    );
  });

  test('adjacent ordered list restart survives native and token-free HTML', () {
    const source = '3. First\n4. Second\n\n3) Restart\n4) Last\n';
    final document = _parse(source);
    final outgoing = _codec.encode(_capture(document.blocks));
    final lists = html.parseFragment(outgoing).querySelectorAll('ol');
    expect(lists.map((list) => list.attributes['start']), ['3', '3']);
    expect(lists.map((list) => list.children.map((li) => li.text)), [
      ['First', 'Second'],
      ['Restart', 'Last'],
    ]);
    expect(_paste(outgoing), source);
    final native = WysiwygClipboardFragment.decode(
      _capture(document.blocks).encode(),
    )!;
    final serialized = native.serializeFor(
      destinationMode: MarkdownMode.gfm,
      destinationFilePath: '/different.md',
    );
    final reopened = _parse(serialized);
    expect(reopened.blocks.map((b) => b.attributes['marker']), [
      '3.',
      '4.',
      '3)',
      '4)',
    ]);

    final editor = BusyMarkWysiwygDocumentController(document: document);
    addTearDown(editor.dispose);
    editor.applyBlockCommand(
      document.blocks.last.id,
      BusyWysiwygBlockCommand.orderedList,
    );
    expect(editor.document.blocks.map((b) => b.attributes['marker']), [
      '3.',
      '4.',
      '3)',
      '4)',
    ]);
    expect(_parse(editor.markdown).blocks.map((b) => b.attributes['marker']), [
      '3.',
      '4.',
      '3)',
      '4)',
    ]);
  });

  test('pasted ordered list owns its restart beside an existing list', () {
    const target = '3. Existing\n\nTarget\n\n3. Later\n';
    final input = _parse('3. Incoming\n4. Following\n');
    final fragment = _capture(input.blocks, sourcePath: '/origin/other.md');
    final source =
        const SourcePasteEngine().prepareStructured(
              target: SourcePasteDocumentSnapshot(
                expectedSource: target,
                selection: TextSelection(
                  baseOffset: target.indexOf('Target'),
                  extentOffset: target.indexOf('Target') + 6,
                ),
                format: SourceDocumentFormat.markdown,
                filePath: '/target.md',
                markdownMode: MarkdownMode.gfm,
              ),
              fragment: fragment,
            )
            as SourcePasteReady;
    final sourceDocument = _parse(
      target.replaceRange(
        source.edit.start,
        source.edit.end,
        source.edit.replacement,
      ),
    );
    void expectSeparateLists(BusyDocument document) {
      final lists = html
          .parseFragment(_codec.encode(_capture(document.blocks)))
          .querySelectorAll('ol');
      expect(lists.map((list) => list.attributes['start']), ['3', '3', '3']);
      expect(lists.map((list) => list.children.map((item) => item.text)), [
        ['Existing'],
        ['Incoming', 'Following'],
        ['Later'],
      ]);
    }

    expectSeparateLists(sourceDocument);

    final targetDocument = _parse(target);
    final editor = BusyMarkWysiwygDocumentController(document: targetDocument);
    addTearDown(editor.dispose);
    expect(
      editor.insertStyledBlocksAtSelection(
        blockId: targetDocument.blocks[1].id,
        selectionStart: 0,
        selectionEnd: 6,
        blocks: fragment.blocks,
      ),
      isNotNull,
    );
    expectSeparateLists(_parse(editor.markdown));
  });

  test('HTML export preserves alphabetic and reversed list markers', () async {
    final markup = html.parseFragment(
      await _export(
        '<ol type="A" reversed start="5"><li>Fifth</li>'
        '<li value="2">Second</li><li>First</li></ol>\n\n'
        '<ol type="i"><li>One</li></ol>',
      ),
    );
    expect(
      markup
          .querySelector('ol[type=A][reversed][start="5"] li[value="2"]')
          ?.text,
      'Second',
    );
    expect(markup.querySelector('ol[type=i] li')?.text, 'One');
  });
}
