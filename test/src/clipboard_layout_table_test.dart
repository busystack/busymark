import 'dart:io';

import 'package:busymark/src/clipboard/clipboard_insertion.dart';
import 'package:busymark/src/editor/clipboard_paste_resolver.dart';
import 'package:busymark/src/editor/source/source_paste_engine.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_clipboard_html.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File(
    'test/fixtures/clipboard/layout_table_job.html',
  ).readAsStringSync();
  const plainText =
      'Example Developer\nReference Example-42\nPlain description';
  final snapshot = BusyMarkClipboardSnapshot(
    html: source,
    text: plainText,
    external: true,
    sessionOwned: false,
    fromSystemClipboard: true,
  );
  const resolver = BusyMarkClipboardPasteResolver();
  const parser = MarkdownParser();

  test('data tables remain tables, including borderless and single-column data', () {
    for (final source in [
      '<table border="0"><tr><td>Name</td><td>Value</td></tr></table>',
      '<table><tr><td>First</td></tr><tr><td>Second</td></tr></table>',
      '<table><tr><th>Title</th></tr><tr><td><p>One</p><p>Two</p></td></tr></table>',
      '<table role="table"><tr><td><h2>Heading in a data cell</h2></td></tr></table>',
      '<table border="1"><tr><td><h2>Heading in a bordered cell</h2></td></tr></table>',
      '<table><caption>Data title</caption><tr><td><p>One</p><p>Two</p></td></tr></table>',
      '<table><tr><td><p>One</p><p>Two</p></td><td>Value</td></tr></table>',
      '<table><tr><td colspan="2"><h2>Spanning header</h2></td></tr></table>',
    ]) {
      final decoded = const WysiwygClipboardHtml().decode(
        source,
        mode: MarkdownMode.gfm,
      )!;
      expect(
        decoded.documentBlocks.where(
          (block) => block.kind == BusyBlockKind.table,
        ),
        hasLength(1),
        reason: source,
      );
    }
  });

  test('nested layout wrappers retain their inner data table and prose', () {
    final wrapped = '<table><tr><td>$source</td></tr></table>';
    final decoded = const WysiwygClipboardHtml().decode(
      wrapped,
      mode: MarkdownMode.gfm,
    )!;
    expect(decoded.documentBlocks.first.kind, BusyBlockKind.heading);
    expect(
      decoded.documentBlocks.where(
        (block) => block.kind == BusyBlockKind.table,
      ),
      hasLength(1),
    );
    expect(
      decoded.documentBlocks.last.plainText,
      'Send questions to team@example.test.',
    );
  });

  test(
    'explicit presentation table keeps caption, cell order and direction',
    () {
      final decoded = const WysiwygClipboardHtml().decode(
        '<table role="presentation" dir="rtl"><caption>Caption</caption><tr>'
        '<td><p>First</p></td><td dir="ltr"><p>Second</p></td>'
        '</tr></table>',
        mode: MarkdownMode.gfm,
      )!;
      expect(decoded.documentBlocks.map((block) => block.plainText), [
        'Caption',
        'First',
        'Second',
      ]);
      expect(decoded.documentBlocks.map((block) => block.attributes['dir']), [
        'rtl',
        'rtl',
        'ltr',
      ]);
      expect(
        decoded.documentBlocks.every(
          (block) => block.kind == BusyBlockKind.paragraph,
        ),
        isTrue,
      );
    },
  );

  for (final destination in [
    BusyMarkPasteDestination.editor,
    BusyMarkPasteDestination.markdownSource,
  ]) {
    test('${destination.name} preserves content inside a layout table', () {
      final plan = resolver.resolve(
        snapshot: snapshot,
        mode: BusyMarkPasteMode.normal,
        destination: destination,
        markdownMode: MarkdownMode.gfm,
      );
      final candidate =
          plan.candidates.first as BusyMarkStructuredPasteCandidate;
      final blocks = candidate.fragment.documentBlocks;
      expect(blocks.first.kind, BusyBlockKind.heading);
      expect(
        blocks.where((block) => block.kind == BusyBlockKind.table),
        hasLength(1),
      );
      expect(
        blocks.where((block) => block.kind == BusyBlockKind.unorderedListItem),
        hasLength(3),
      );

      final target = parser
          .parse(
            filePath: '/destination.md',
            source: 'Target\n',
            mode: MarkdownMode.gfm,
          )
          .busyDocument;
      late String output;
      if (destination == BusyMarkPasteDestination.editor) {
        final controller = BusyMarkWysiwygDocumentController(document: target);
        addTearDown(controller.dispose);
        expect(
          controller.insertStyledBlocksAtSelection(
            blockId: target.blocks.first.id,
            selectionStart: 0,
            selectionEnd: 6,
            blocks: candidate.fragment.blocks,
          ),
          isNotNull,
        );
        output = controller.markdown;
      } else {
        final prepared = const SourcePasteEngine().prepareStructured(
          target: const SourcePasteDocumentSnapshot(
            expectedSource: 'Target\n',
            selection: TextSelection(baseOffset: 0, extentOffset: 6),
            format: SourceDocumentFormat.markdown,
            markdownMode: MarkdownMode.gfm,
            filePath: '/destination.md',
          ),
          fragment: candidate.fragment,
        );
        expect(prepared, isA<SourcePasteReady>());
        final edit = (prepared as SourcePasteReady).edit;
        output = edit.expectedSource.replaceRange(
          edit.start,
          edit.end,
          edit.replacement,
        );
      }
      var previous = -1;
      for (final text in [
        '## Example Developer',
        '| Reference | Example-42 |',
        'Job Description',
        '**About the team**',
        'We build helpful tools for our community.',
        '- Design accessible interfaces.',
        '- Test changes carefully.',
        'Work with colleagues across the organization.',
        '**Qualifications**',
        '- Experience delivering reliable software.',
        'Closing invitation with [application details](https://example.test/careers).',
      ]) {
        final index = output.indexOf(text);
        expect(index, greaterThan(previous), reason: '$text in:\n$output');
        previous = index;
      }
      final reparsed = parser
          .parse(
            filePath: '/destination.md',
            source: output,
            mode: MarkdownMode.gfm,
          )
          .busyDocument;
      expect(reparsed.blocks.first.kind, BusyBlockKind.heading);
      expect(
        reparsed.blocks.where((block) => block.kind == BusyBlockKind.table),
        hasLength(1),
      );
      expect(
        reparsed.blocks.where(
          (block) => block.kind == BusyBlockKind.unorderedListItem,
        ),
        hasLength(3),
      );
    });

    test('${destination.name} plain paste ignores layout and rich content', () {
      final plan = resolver.resolve(
        snapshot: snapshot,
        mode: BusyMarkPasteMode.plainText,
        destination: destination,
      );
      expect(plan.candidates, hasLength(1));
      expect(
        (plan.candidates.single as BusyMarkPlainTextPasteCandidate).text,
        plainText,
      );
    });
  }
}
