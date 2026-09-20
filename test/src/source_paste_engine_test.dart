import 'package:busymark/src/editor/source/source_paste_engine.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_clipboard_fragment.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_inline_controller.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = SourcePasteEngine();

  test('HTML break layout stays behind a caret after the semantic break', () {
    const source =
        '[A\n'
        '<br>\n'
        '<br>\n'
        'right](https://destination.test) tail';
    final secondBreak = source.indexOf('<br>', source.indexOf('<br>') + 1);
    final result = engine.prepareStructured(
      target: _target(
        source,
        TextSelection.collapsed(offset: secondBreak + '<br>'.length),
      ),
      fragment: _fragment('[Y](https://incoming.test)\n'),
    );

    final applied = _applyReady(source, result);
    expect(applied.edit.expectedSource, source);
    expect(
      applied.edit.caretOffset,
      inInclusiveRange(0, applied.source.length),
    );
    final paragraph = _parse(applied.source).blocks.single;
    expect(paragraph.plainText, 'A\n\nYright tail', reason: applied.source);
    expect(_destinations(paragraph.inlines), [
      'https://destination.test',
      'https://incoming.test',
      'https://destination.test',
    ]);
  });

  test(
    'caret immediately before an HTML break keeps the break after paste',
    () {
      const source =
          '[A\n'
          '<br>\n'
          '<br>\n'
          'right](https://destination.test) tail';
      final secondBreak = source.indexOf('<br>', source.indexOf('<br>') + 1);
      final applied = _applyReady(
        source,
        engine.prepareStructured(
          target: _target(source, TextSelection.collapsed(offset: secondBreak)),
          fragment: _fragment('[Y](https://incoming.test)\n'),
        ),
      );

      expect(
        _parse(applied.source).blocks.single.plainText,
        'A\nY\nright tail',
        reason: applied.source,
      );
    },
  );

  test('selection crossing an HTML break preserves both outside slices', () {
    const source =
        'prefix [<u>left<br>right</u>](https://destination.test) suffix';
    final start = source.indexOf('left') + 2;
    final end = source.indexOf('right') + 2;
    final applied = _applyReady(
      source,
      engine.prepareStructured(
        target: _target(
          source,
          TextSelection(baseOffset: start, extentOffset: end),
        ),
        fragment: _fragment('[Y](https://incoming.test)\n'),
      ),
    );

    final paragraph = _parse(applied.source).blocks.single;
    expect(paragraph.plainText, 'prefix leYght suffix', reason: applied.source);
    expect(applied.source, startsWith('prefix '));
    expect(applied.source, endsWith(' suffix'));
    expect(applied.source, isNot(contains('\ue000')));
    expect(applied.source, isNot(contains('\ue001')));
  });

  test('complete inline HTML survives rich link insertion as one fragment', () {
    const source = '[<u>left<br>right</u>](https://destination.test) tail';
    final applied = _applyReady(
      source,
      engine.prepareStructured(
        target: _target(
          source,
          TextSelection.collapsed(
            offset: source.indexOf('right') + 'ri'.length,
          ),
        ),
        fragment: _fragment('[Y](https://incoming.test)\n'),
      ),
    );

    final paragraph = _parse(applied.source).blocks.single;
    expect(paragraph.plainText, 'left\nriYght tail', reason: applied.source);
    expect(applied.source, isNot(contains('</u> tail')));
    expect(_destinations(paragraph.inlines), [
      'https://destination.test',
      'https://incoming.test',
      'https://destination.test',
    ]);
    expect(_countKind(paragraph.inlines, BusyInlineKind.underline), 3);
    expect(_countKind(paragraph.inlines, BusyInlineKind.hardBreak), 1);
  });

  test('paste output is valid input for a second paste at returned caret', () {
    const source =
        '[A\n'
        '<br>\n'
        '<br>\n'
        'right](https://destination.test) tail';
    final secondBreak = source.indexOf('<br>', source.indexOf('<br>') + 1);
    final first = _applyReady(
      source,
      engine.prepareStructured(
        target: _target(
          source,
          TextSelection.collapsed(offset: secondBreak + '<br>'.length),
        ),
        fragment: _fragment('[Y](https://first.test)\n'),
      ),
    );
    final second = _applyReady(
      first.source,
      engine.prepareStructured(
        target: _target(
          first.source,
          TextSelection.collapsed(offset: first.edit.caretOffset),
        ),
        fragment: _fragment('[Z](https://second.test)\n'),
      ),
    );

    final paragraph = _parse(second.source).blocks.single;
    expect(paragraph.plainText, 'A\n\nYZright tail', reason: second.source);
    expect(_destinations(paragraph.inlines), [
      'https://destination.test',
      'https://first.test',
      'https://second.test',
      'https://destination.test',
    ]);
    expect(second.edit.caretOffset, greaterThan(first.edit.caretOffset));
  });

  test('CRLF blockquote projection retains its authored prefixes', () {
    const source =
        '> [A\r\n'
        '> <br>\r\n'
        '> <br>\r\n'
        '> right](https://destination.test) tail';
    final applied = _applyReady(
      source,
      engine.prepareStructured(
        target: _target(
          source,
          TextSelection.collapsed(offset: source.indexOf('right') + 2),
        ),
        fragment: _fragment('[Y](https://incoming.test)\n'),
      ),
    );

    expect(applied.source, contains('> <br>\r\n> <br>\r\n> ri]'));
    final document = _parse(applied.source);
    expect(document.blocks.single.kind, BusyBlockKind.blockquote);
    expect(_destinations(_allInlines(document.blocks)), [
      'https://destination.test',
      'https://incoming.test',
      'https://destination.test',
    ]);
  });

  test('protected Source context explicitly permits textual fallback', () {
    const source = '```text\nprotected\n```';
    final result = engine.prepareStructured(
      target: _target(
        source,
        TextSelection.collapsed(offset: source.indexOf('protected') + 3),
      ),
      fragment: _fragment('**rich**\n'),
    );

    expect(result, isA<SourcePasteTryNext>());
  });

  test('syntax-only positions explicitly permit textual fallback', () {
    const source = '**left**';
    final result = engine.prepareStructured(
      target: _target(source, const TextSelection.collapsed(offset: 1)),
      fragment: _fragment('[Y](https://incoming.test)\n'),
    );

    expect(result, isA<SourcePasteTryNext>());
  });

  test('unmappable destination links stop rather than permit fallback', () {
    const source = '<a href="https://destination.test">left';
    final result = engine.prepareStructured(
      target: _target(
        source,
        TextSelection.collapsed(offset: source.indexOf('left') + 2),
      ),
      fragment: _fragment('[Y](https://incoming.test)\n'),
    );

    expect(result, isA<SourcePasteStop>());
  });
}

SourcePasteDocumentSnapshot _target(String source, TextSelection selection) {
  return SourcePasteDocumentSnapshot(
    expectedSource: source,
    selection: selection,
    format: SourceDocumentFormat.markdown,
    markdownMode: MarkdownMode.commonMark,
    filePath: '/project/source.md',
  );
}

WysiwygClipboardFragment _fragment(String source) {
  final document = _parse(source, filePath: '/clipboard/source.md');
  return WysiwygClipboardFragment(
    sourcePath: document.filePath,
    mode: document.mode,
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
}

BusyDocument _parse(String source, {String filePath = '/project/source.md'}) {
  return const MarkdownParser()
      .parse(
        filePath: filePath,
        source: source,
        mode: MarkdownMode.commonMark,
        validateLocalReferences: false,
      )
      .busyDocument;
}

({String source, SourcePasteEdit edit}) _applyReady(
  String source,
  SourcePastePreparation result,
) {
  expect(result, isA<SourcePasteReady>());
  final edit = (result as SourcePasteReady).edit;
  expect(edit.expectedSource, source);
  return (
    source: source.replaceRange(edit.start, edit.end, edit.replacement),
    edit: edit,
  );
}

List<String?> _destinations(List<BusyInline> inlines) {
  final result = <String?>[];
  void visit(List<BusyInline> values) {
    for (final inline in values) {
      if (inline.kind == BusyInlineKind.link) result.add(inline.destination);
      visit(inline.children);
    }
  }

  visit(inlines);
  return result;
}

int _countKind(List<BusyInline> inlines, BusyInlineKind kind) {
  var result = 0;
  for (final inline in inlines) {
    if (inline.kind == kind) result += 1;
    result += _countKind(inline.children, kind);
  }
  return result;
}

List<BusyInline> _allInlines(List<BusyBlock> blocks) {
  return [
    for (final block in blocks) ...[
      ...block.inlines,
      ..._allInlines(block.children),
    ],
  ];
}
