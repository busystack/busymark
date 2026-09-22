import 'dart:io';
import 'dart:typed_data';

import 'package:busymark/src/clipboard/clipboard_insertion.dart';
import 'package:busymark/src/clipboard/clipboard_models.dart';
import 'package:busymark/src/editor/clipboard_paste_resolver.dart';
import 'package:busymark/src/editor/clipboard_local_image_path.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_clipboard_fragment.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_inline_controller.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolver = BusyMarkClipboardPasteResolver();

  WysiwygClipboardFragment fragment({
    MarkdownMode mode = MarkdownMode.commonMark,
    String text = 'native',
  }) => WysiwygClipboardFragment(
    mode: mode,
    blocks: [
      BusyWysiwygStyledBlock(
        kind: BusyBlockKind.paragraph,
        text: text,
        ranges: const [],
      ),
    ],
  );

  BusyMarkClipboardSnapshot snapshot({
    String? text,
    String? sourceText,
    String? html,
    String? richFragment,
  }) => BusyMarkClipboardSnapshot(
    text: text,
    sourceText: sourceText,
    html: html,
    richFragment: richFragment,
    external: true,
    sessionOwned: false,
    fromSystemClipboard: true,
  );

  BusyMarkPastePlan resolve(
    BusyMarkClipboardSnapshot value, {
    BusyMarkPasteMode mode = BusyMarkPasteMode.normal,
    BusyMarkPasteDestination destination = BusyMarkPasteDestination.editor,
    MarkdownMode markdownMode = MarkdownMode.commonMark,
  }) => resolver.resolve(
    snapshot: value,
    mode: mode,
    destination: destination,
    markdownMode: markdownMode,
  );

  test('valid native fragment wins over HTML and text', () {
    final plan = resolve(
      snapshot(
        richFragment: fragment().encode(),
        html: '<h1>HTML</h1>',
        text: 'plain',
      ),
    );
    final first = plan.candidates.first as BusyMarkStructuredPasteCandidate;
    expect(first.source, BusyMarkStructuredClipboardSource.richFragment);
    expect(first.fragment.blocks.single.text, 'native');
  });

  test('malformed native fragment falls through to valid HTML', () {
    final plan = resolve(
      snapshot(
        richFragment: '{bad',
        html: '<p><strong>HTML</strong></p>',
        text: 'plain',
      ),
    );
    final first = plan.candidates.first as BusyMarkStructuredPasteCandidate;
    expect(first.source, BusyMarkStructuredClipboardSource.html);
    expect(first.fragment.blocks.single.text, 'HTML');
  });

  test('unusable HTML falls through to source and plain text', () {
    final plan = resolve(
      snapshot(
        html: '<script>alert(1)</script>',
        sourceText: '**source**',
        text: 'plain',
      ),
      destination: BusyMarkPasteDestination.markdownSource,
    );
    expect(plan.candidates, [
      isA<BusyMarkSourceTextPasteCandidate>(),
      isA<BusyMarkPlainTextPasteCandidate>(),
    ]);
  });

  test('HTML-only blockquotes are usable through descendant content', () {
    for (final html in [
      '<blockquote><p>Quoted</p></blockquote>',
      '<blockquote><blockquote><p>Nested</p></blockquote></blockquote>',
      '<blockquote><ul><li>Listed</li></ul></blockquote>',
    ]) {
      final richOnly = resolve(snapshot(html: html));
      expect(richOnly.candidates, hasLength(1), reason: html);
      final rich =
          richOnly.candidates.single as BusyMarkStructuredPasteCandidate;
      expect(rich.source, BusyMarkStructuredClipboardSource.html);
      expect(
        rich.fragment.documentBlocks.single.kind,
        BusyBlockKind.blockquote,
      );
      expect(rich.fragment.markdown, startsWith('>'));
      expect(
        resolve(
          snapshot(html: html),
          mode: BusyMarkPasteMode.plainText,
        ).isEmpty,
        isTrue,
      );

      final withText = resolve(snapshot(html: html, text: 'plain'));
      expect(
        withText.candidates.first,
        isA<BusyMarkStructuredPasteCandidate>(),
      );
      expect(withText.candidates.last, isA<BusyMarkPlainTextPasteCandidate>());
      final plain = resolve(
        snapshot(html: html, text: 'plain'),
        mode: BusyMarkPasteMode.plainText,
      );
      expect(plain.candidates, hasLength(1));
      expect(
        (plain.candidates.single as BusyMarkPlainTextPasteCandidate).text,
        'plain',
      );
    }
  });

  test(
    'mixed external HTML preserves every block for Editor and Markdown Source',
    () {
      const mixedHtml = '''
<h1>Release notes</h1>
<p>Opening paragraph.</p>
<ul><li>First supported item</li></ul>
<p>Text before the data.</p>
<table>
  <thead><tr><th>Name</th><th>Value</th></tr></thead>
  <tbody><tr><td>Alpha</td><td>One</td></tr></tbody>
</table>
<p>Closing paragraph.</p>
''';
      const plainText = 'plain-text fallback only';
      const expectedKinds = [
        BusyBlockKind.heading,
        BusyBlockKind.paragraph,
        BusyBlockKind.unorderedListItem,
        BusyBlockKind.paragraph,
        BusyBlockKind.table,
        BusyBlockKind.paragraph,
      ];

      for (final destination in [
        BusyMarkPasteDestination.editor,
        BusyMarkPasteDestination.markdownSource,
      ]) {
        final plan = resolve(
          snapshot(html: mixedHtml, text: plainText),
          destination: destination,
          markdownMode: MarkdownMode.gfm,
        );
        final structured =
            plan.candidates.first as BusyMarkStructuredPasteCandidate;
        expect(
          structured.source,
          BusyMarkStructuredClipboardSource.html,
          reason: destination.name,
        );
        expect(
          structured.fragment.documentBlocks.map((block) => block.kind),
          expectedKinds,
          reason: destination.name,
        );
        final markdown = structured.fragment.serializeFor(
          destinationMode: MarkdownMode.gfm,
          destinationFilePath: '/workspace/mixed.md',
        );
        expect(
          markdown.indexOf('# Release notes'),
          lessThan(markdown.indexOf('Opening paragraph.')),
        );
        expect(
          markdown.indexOf('Opening paragraph.'),
          lessThan(markdown.indexOf('- First supported item')),
        );
        expect(
          markdown.indexOf('- First supported item'),
          lessThan(markdown.indexOf('Text before the data.')),
        );
        expect(
          markdown.indexOf('Text before the data.'),
          lessThan(markdown.indexOf('| Name | Value |')),
        );
        expect(
          markdown.indexOf('| Name | Value |'),
          lessThan(markdown.indexOf('Closing paragraph.')),
        );

        final plain = resolve(
          snapshot(html: mixedHtml, text: plainText),
          mode: BusyMarkPasteMode.plainText,
          destination: destination,
        );
        expect(plain.candidates, hasLength(1));
        expect(
          (plain.candidates.single as BusyMarkPlainTextPasteCandidate).text,
          plainText,
          reason: destination.name,
        );
      }
    },
  );

  test('plain mode uses only interoperable text', () {
    final plan = resolve(
      snapshot(
        text: 'plain',
        sourceText: '**source**',
        html: '<b>HTML</b>',
        richFragment: fragment().encode(),
      ),
      mode: BusyMarkPasteMode.plainText,
    );
    expect(plan.candidates, hasLength(1));
    expect(
      (plan.candidates.single as BusyMarkPlainTextPasteCandidate).text,
      'plain',
    );
  });

  test('plain mode rejects source-only and image-only payloads', () {
    expect(
      resolve(
        snapshot(sourceText: '**source**'),
        mode: BusyMarkPasteMode.plainText,
      ).isEmpty,
      isTrue,
    );
    final image = BusyMarkClipboardSnapshot.fromPayload(
      BusyMarkClipboardPayload(
        id: 'image',
        acquiredAt: DateTime.utc(2026),
        kind: BusyMarkClipboardContentKind.image,
        imageBytes: Uint8List.fromList([1]),
      ),
    );
    expect(resolve(image, mode: BusyMarkPasteMode.plainText).isEmpty, isTrue);
  });

  test('whitespace text is valid and empty text is unavailable', () {
    expect(
      (resolve(
                snapshot(text: ' \n'),
                mode: BusyMarkPasteMode.plainText,
              ).candidates.single
              as BusyMarkPlainTextPasteCandidate)
          .text,
      ' \n',
    );
    expect(
      resolve(snapshot(text: ''), mode: BusyMarkPasteMode.plainText).isEmpty,
      isTrue,
    );
  });

  test('explicit image is first in normal mode', () {
    final image = BusyMarkClipboardSnapshot.fromPayload(
      BusyMarkClipboardPayload(
        id: 'image',
        acquiredAt: DateTime.utc(2026),
        kind: BusyMarkClipboardContentKind.image,
        text: 'alternative',
        imageBytes: Uint8List.fromList([1, 2, 3]),
      ),
    );
    expect(
      resolve(image).candidates.single,
      isA<BusyMarkImagePasteCandidate>(),
    );
  });

  test('Editor and Source use their required textual fallback order', () {
    final value = snapshot(text: 'plain', sourceText: '**source**');
    expect(
      resolve(value).candidates.map((candidate) => candidate.runtimeType),
      [BusyMarkPlainTextPasteCandidate],
    );
    expect(
      resolve(
        value,
        destination: BusyMarkPasteDestination.markdownSource,
      ).candidates.map((candidate) => candidate.runtimeType),
      [BusyMarkSourceTextPasteCandidate, BusyMarkPlainTextPasteCandidate],
    );
  });

  test('structured source serialization accepts the destination mode', () {
    final original = fragment(
      mode: MarkdownMode.writersideMarkdown,
      text: 'destination content',
    );
    final candidate =
        resolve(
              snapshot(richFragment: original.encode()),
              destination: BusyMarkPasteDestination.markdownSource,
              markdownMode: MarkdownMode.gfm,
            ).candidates.single
            as BusyMarkStructuredPasteCandidate;
    expect(candidate.fragment.mode, MarkdownMode.writersideMarkdown);
    expect(
      candidate.fragment.serializeFor(
        destinationMode: MarkdownMode.gfm,
        destinationFilePath: '/workspace/destination.md',
      ),
      'destination content\n',
    );
    expect(
      candidate.fragment.serializeInlineFor(
        destinationMode: MarkdownMode.gfm,
        destinationFilePath: '/workspace/destination.md',
      ),
      'destination content',
    );
  });

  test(
    'native inline serialization preserves whitespace without a newline',
    () {
      final value = WysiwygClipboardFragment(
        mode: MarkdownMode.commonMark,
        blocks: [
          BusyWysiwygStyledBlock(
            kind: BusyBlockKind.paragraph,
            text: ' X ',
            ranges: const [
              BusyInlineStyleRange(
                start: 1,
                end: 2,
                kind: BusyInlineKind.strong,
              ),
            ],
          ),
        ],
      );
      expect(
        value.serializeInlineFor(
          destinationMode: MarkdownMode.commonMark,
          destinationFilePath: '/workspace/target.md',
        ),
        ' **X** ',
      );

      final spaces = fragment(text: '   ');
      expect(
        spaces.serializeInlineFor(
          destinationMode: MarkdownMode.commonMark,
          destinationFilePath: '/workspace/target.md',
        ),
        '   ',
      );
    },
  );

  test(
    'table-cell fragment serialization escapes pipes and flattens lines',
    () {
      final value = WysiwygClipboardFragment(
        mode: MarkdownMode.commonMark,
        blocks: [
          BusyWysiwygStyledBlock(
            kind: BusyBlockKind.paragraph,
            text: 'A|B',
            ranges: const [],
          ),
          BusyWysiwygStyledBlock(
            kind: BusyBlockKind.paragraph,
            text: 'C\nD',
            ranges: const [],
          ),
        ],
      );
      expect(
        value.serializeTableCellFor(
          destinationMode: MarkdownMode.gfm,
          destinationFilePath: '/workspace/target.md',
        ),
        r'A\|B C D',
      );
    },
  );

  test(
    'local image path detection is safe and rejects altered URI meaning',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-local-clipboard-path-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final image = File('${directory.path}/image.png')..writeAsBytesSync([1]);
      final text = File('${directory.path}/notes.txt')
        ..writeAsStringSync('text');

      expect(busyMarkLocalImagePathFromClipboardText(image.path), image.path);
      expect(
        busyMarkLocalImagePathFromClipboardText(image.uri.toString()),
        image.path,
      );
      expect(
        busyMarkLocalImagePathFromClipboardText(
          '${directory.path}/missing.png',
        ),
        isNull,
      );
      expect(busyMarkLocalImagePathFromClipboardText(text.path), isNull);
      expect(
        busyMarkLocalImagePathFromClipboardText('${image.uri}?version=2'),
        isNull,
      );
      expect(
        busyMarkLocalImagePathFromClipboardText('${image.uri}#preview'),
        isNull,
      );
      expect(
        busyMarkLocalImagePathFromClipboardText(
          'file://remote-host${image.uri.path}',
        ),
        isNull,
      );
    },
  );
}
