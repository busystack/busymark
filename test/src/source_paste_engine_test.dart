import 'package:busymark/src/editor/source/source_paste_engine.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_clipboard_fragment.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_inline_controller.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_ast_adapter.dart';
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

  test('native rich trailing space survives inherited HTML insertion', () {
    const source = '[<u>leftright</u>](https://destination.test) tail';
    const incomingDestination = 'https://incoming.test';
    const incomingText = 'Y ';
    const native = WysiwygClipboardFragment(
      mode: MarkdownMode.commonMark,
      sourcePath: '/clipboard/source.md',
      blocks: [
        BusyWysiwygStyledBlock(
          kind: BusyBlockKind.paragraph,
          text: incomingText,
          ranges: [
            BusyInlineStyleRange(
              start: 0,
              end: incomingText.length,
              kind: BusyInlineKind.link,
              destination: incomingDestination,
            ),
          ],
          completeBlock: BusyBlock(
            id: 'clipboard-paragraph',
            kind: BusyBlockKind.paragraph,
            inlines: [
              BusyInline(
                kind: BusyInlineKind.link,
                text: incomingText,
                destination: incomingDestination,
                children: [
                  BusyInline(kind: BusyInlineKind.text, text: incomingText),
                ],
              ),
            ],
          ),
        ),
      ],
    );
    final decoded = WysiwygClipboardFragment.decode(native.encode());

    expect(decoded, isNotNull);
    expect(decoded!.blocks.single.text, incomingText);
    final prepared = decoded.sourceInsertionInlinesFor(tableCell: false);
    expect(prepared.single.kind, BusyInlineKind.link);
    expect(prepared.single.plainText, incomingText);
    expect(prepared.single.destination, incomingDestination);

    final result = engine.prepareStructured(
      target: _target(
        source,
        TextSelection.collapsed(offset: source.indexOf('right')),
      ),
      fragment: decoded,
    );
    final applied = _applyReady(source, result);
    final paragraph = _parse(applied.source).blocks.single;

    expect(paragraph.plainText, 'leftY right tail', reason: applied.source);
    expect(_destinations(paragraph.inlines), [
      'https://destination.test',
      incomingDestination,
      'https://destination.test',
    ], reason: applied.source);
    expect(
      _links(paragraph.inlines)
          .singleWhere((inline) => inline.destination == incomingDestination)
          .plainText,
      'Y',
      reason: applied.source,
    );
    const caretMarker = '\ue002';
    final marked = applied.source.replaceRange(
      applied.edit.caretOffset,
      applied.edit.caretOffset,
      caretMarker,
    );
    expect(
      _parse(marked).blocks.single.plainText,
      'leftY ${caretMarker}right tail',
      reason: 'replacement: ${applied.edit.replacement}\nsource: $marked',
    );
  });

  test('native incoming edge whitespace survives inherited HTML styles', () {
    const incomingDestination = 'https://incoming.test';
    const destination = 'https://destination.test';
    const destinationTitle = 'Destination title';
    const incomingTitle = 'Incoming title';
    final styles = <({String tag, BusyInlineKind kind})>[
      (tag: 'u', kind: BusyInlineKind.underline),
      (tag: 'strong', kind: BusyInlineKind.strong),
      (tag: 'em', kind: BusyInlineKind.emphasis),
      (tag: 's', kind: BusyInlineKind.strikethrough),
    ];
    const incomingValues = ['Y ', ' Y', ' Y ', ' '];
    var cases = 0;

    for (final style in styles) {
      for (final incomingText in incomingValues) {
        for (final tableCell in [false, true]) {
          cases += 1;
          final link =
              '[<${style.tag}>leftright</${style.tag}>]'
              '($destination "$destinationTitle") tail';
          final source = tableCell
              ? '| H |\n| --- |\n| $link |\n'
              : 'prefix $link suffix';
          final fragment = _nativeFragment([
            BusyInline(
              kind: BusyInlineKind.link,
              text: incomingText,
              destination: incomingDestination,
              attributes: const {'title': incomingTitle},
              children: [
                BusyInline(kind: BusyInlineKind.text, text: incomingText),
              ],
            ),
          ]);
          final decoded = WysiwygClipboardFragment.decode(fragment.encode());

          expect(decoded, isNotNull, reason: 'case $cases');
          expect(decoded!.blocks.single.text, incomingText);
          expect(
            decoded
                .sourceInsertionInlinesFor(tableCell: tableCell)
                .map((inline) => inline.plainText)
                .join(),
            incomingText,
          );
          final result = engine.prepareStructured(
            target: _target(
              source,
              TextSelection.collapsed(offset: source.indexOf('right')),
            ),
            fragment: decoded,
          );
          expect(result, isA<SourcePasteReady>(), reason: 'case $cases');
          final applied = _applyReady(source, result);
          final paragraph = _contentParagraph(_parse(applied.source));
          final expectedText = tableCell
              ? 'left${incomingText}right tail'
              : 'prefix left${incomingText}right tail suffix';

          expect(
            paragraph.plainText,
            expectedText,
            reason: 'case $cases: ${applied.source}',
          );
          expect(
            applied.source.substring(0, applied.edit.start),
            source.substring(0, applied.edit.start),
          );
          expect(
            applied.source.substring(
              applied.edit.start + applied.edit.replacement.length,
            ),
            source.substring(applied.edit.end),
          );
          final links = _links(paragraph.inlines);
          expect(
            links
                .where((inline) => inline.destination == destination)
                .map((inline) => inline.attributes['title']),
            everyElement(destinationTitle),
            reason: applied.source,
          );
          final incomingLinks = links.where(
            (inline) => inline.destination == incomingDestination,
          );
          if (incomingText.trim().isEmpty) {
            expect(incomingLinks.length, lessThanOrEqualTo(1));
            if (incomingLinks.isNotEmpty) {
              expect(incomingLinks.single.plainText, incomingText);
              expect(incomingLinks.single.attributes['title'], incomingTitle);
            }
          } else {
            expect(incomingLinks, hasLength(1), reason: applied.source);
            expect(incomingLinks.single.plainText.trim(), 'Y');
            expect(incomingLinks.single.attributes['title'], incomingTitle);
            expect(
              _leafContexts(
                paragraph.inlines,
              ).where((run) => run.text.trim() == 'Y').single.contexts,
              containsAll([style.kind, BusyInlineKind.link]),
              reason: applied.source,
            );
          }
          if (incomingText.trim().isEmpty ||
              style.kind != BusyInlineKind.underline) {
            final localCaret = applied.edit.caretOffset - applied.edit.start;
            expect(
              localCaret,
              inInclusiveRange(0, applied.edit.replacement.length),
              reason: 'case $cases: ${applied.edit.replacement}',
            );
            if (incomingText.trim().isEmpty &&
                style.kind == BusyInlineKind.underline) {
              expect(
                applied.edit.replacement.substring(0, localCaret),
                endsWith(incomingText),
                reason: 'case $cases: ${applied.edit.replacement}',
              );
            }
          } else {
            final second = _applyReady(
              applied.source,
              engine.prepareStructured(
                target: _target(
                  applied.source,
                  TextSelection.collapsed(offset: applied.edit.caretOffset),
                ),
                fragment: _nativeFragment(const [
                  BusyInline(
                    kind: BusyInlineKind.link,
                    text: 'Z',
                    destination: 'https://second.test',
                    children: [
                      BusyInline(kind: BusyInlineKind.text, text: 'Z'),
                    ],
                  ),
                ]),
              ),
            );
            expect(
              _contentParagraph(_parse(second.source)).plainText,
              expectedText.replaceFirst(
                '${incomingText}right',
                '${incomingText}Zright',
              ),
              reason: 'case $cases: ${second.source}',
            );
            expect(
              _destinations(_contentParagraph(_parse(second.source)).inlines),
              contains('https://second.test'),
            );
          }
        }
      }
    }
    expect(cases, 32);
  });

  test('selection replacement retains native whitespace and link titles', () {
    const source =
        'prefix [<u>leftmiddleright</u>]'
        '(https://destination.test "Destination title") tail suffix';
    const incomingText = ' Y ';
    final start = source.indexOf('middle');
    final end = start + 'middle'.length;
    final fragment = _nativeFragment(const [
      BusyInline(
        kind: BusyInlineKind.link,
        text: incomingText,
        destination: 'https://incoming.test',
        attributes: {'title': 'Incoming title'},
        children: [BusyInline(kind: BusyInlineKind.text, text: incomingText)],
      ),
    ]);
    final applied = _applyReady(
      source,
      engine.prepareStructured(
        target: _target(
          source,
          TextSelection(baseOffset: start, extentOffset: end),
        ),
        fragment: WysiwygClipboardFragment.decode(fragment.encode())!,
      ),
    );
    final paragraph = _parse(applied.source).blocks.single;

    expect(paragraph.plainText, 'prefix left Y right tail suffix');
    expect(
      _links(
        paragraph.inlines,
      ).map((inline) => (inline.destination, inline.attributes['title'])),
      [
        ('https://destination.test', 'Destination title'),
        ('https://incoming.test', 'Incoming title'),
        ('https://destination.test', 'Destination title'),
      ],
      reason: applied.source,
    );
    const marker = '\ue002';
    expect(
      _parse(
        applied.source.replaceRange(
          applied.edit.caretOffset,
          applied.edit.caretOffset,
          marker,
        ),
      ).blocks.single.plainText,
      'prefix left Y ${marker}right tail suffix',
    );
  });

  test('multiple native inline runs retain text styles links and spaces', () {
    const source =
        '[<u>leftright</u>]'
        '(https://destination.test "Destination title") tail';
    final fragment = _nativeFragment(const [
      BusyInline(
        kind: BusyInlineKind.link,
        text: 'A ',
        destination: 'https://first.test',
        attributes: {'title': 'First title'},
        children: [BusyInline(kind: BusyInlineKind.text, text: 'A ')],
      ),
      BusyInline(
        kind: BusyInlineKind.strong,
        text: 'B ',
        children: [BusyInline(kind: BusyInlineKind.text, text: 'B ')],
      ),
      BusyInline(
        kind: BusyInlineKind.link,
        text: 'C',
        destination: 'https://second.test',
        attributes: {'title': 'Second title'},
        children: [BusyInline(kind: BusyInlineKind.text, text: 'C')],
      ),
    ]);
    final applied = _applyReady(
      source,
      engine.prepareStructured(
        target: _target(
          source,
          TextSelection.collapsed(offset: source.indexOf('right')),
        ),
        fragment: WysiwygClipboardFragment.decode(fragment.encode())!,
      ),
    );
    final paragraph = _parse(applied.source).blocks.single;

    expect(paragraph.plainText, 'leftA B Cright tail', reason: applied.source);
    expect(
      _links(
        paragraph.inlines,
      ).map((inline) => (inline.destination, inline.attributes['title'])),
      [
        ('https://destination.test', 'Destination title'),
        ('https://first.test', 'First title'),
        ('https://second.test', 'Second title'),
        ('https://destination.test', 'Destination title'),
      ],
      reason: applied.source,
    );
    final contexts = _leafContexts(paragraph.inlines);
    expect(
      contexts.singleWhere((run) => run.text.trim() == 'A').contexts,
      containsAll([BusyInlineKind.underline, BusyInlineKind.link]),
    );
    expect(
      contexts.singleWhere((run) => run.text.trim() == 'B').contexts,
      containsAll([BusyInlineKind.underline, BusyInlineKind.strong]),
    );
    expect(
      contexts.singleWhere((run) => run.text.trim() == 'C').contexts,
      containsAll([BusyInlineKind.underline, BusyInlineKind.link]),
    );
    const marker = '\ue002';
    expect(
      _parse(
        applied.source.replaceRange(
          applied.edit.caretOffset,
          applied.edit.caretOffset,
          marker,
        ),
      ).blocks.single.plainText,
      'leftA B C${marker}right tail',
    );
  });

  test('rich insertion maps collapsed HTML whitespace as content', () {
    final fixtures = <({String source, int caret})>[
      (
        source:
            '[<u>left  right</u>]'
            '(https://destination.test) tail',
        caret: '[<u>left '.length,
      ),
      (
        source:
            '[<u>left \t right</u>]'
            '(https://destination.test) tail',
        caret: '[<u>left \t'.length,
      ),
      (
        source:
            '[<u>left \r\n\t right</u>]'
            '(https://destination.test) tail',
        caret: '[<u>left \r\n'.length,
      ),
    ];

    for (final fixture in fixtures) {
      final result = engine.prepareStructured(
        target: _target(
          fixture.source,
          TextSelection.collapsed(offset: fixture.caret),
        ),
        fragment: _fragment('[Y](https://incoming.test)\n'),
      );
      expect(result, isA<SourcePasteReady>(), reason: fixture.source);
      final applied = _applyReady(fixture.source, result);
      final paragraph = _parse(applied.source).blocks.single;
      expect(paragraph.plainText, 'left Yright tail', reason: applied.source);
      expect(_destinations(paragraph.inlines), [
        'https://destination.test',
        'https://incoming.test',
        'https://destination.test',
      ], reason: applied.source);
      expect(_countKind(paragraph.inlines, BusyInlineKind.underline), 3);
      expect(
        applied.source,
        contains(
          '[<u>left</u>](https://destination.test) '
          '[<u>Y</u>](https://incoming.test)',
        ),
      );
      final incomingEnd =
          applied.source.indexOf('https://incoming.test') +
          'https://incoming.test'.length +
          1;
      expect(applied.edit.caretOffset, incomingEnd);
      expect(applied.source, endsWith(' tail'));
    }
  });

  test('collapsed whitespace maps through supported raw HTML styles', () {
    final fixtures = <({String tag, BusyInlineKind kind})>[
      (tag: 'u', kind: BusyInlineKind.underline),
      (tag: 'strong', kind: BusyInlineKind.strong),
      (tag: 'em', kind: BusyInlineKind.emphasis),
      (tag: 's', kind: BusyInlineKind.strikethrough),
    ];
    for (final fixture in fixtures) {
      final source =
          '[<${fixture.tag}>left  right</${fixture.tag}>]'
          '(https://destination.test) tail';
      final result = engine.prepareStructured(
        target: _target(
          source,
          TextSelection.collapsed(offset: source.indexOf('left') + 5),
        ),
        fragment: _fragment('[Y](https://incoming.test)\n'),
      );

      final applied = _applyReady(source, result);
      final paragraph = _parse(applied.source).blocks.single;
      expect(paragraph.plainText, 'left Yright tail', reason: applied.source);
      expect(_destinations(paragraph.inlines), [
        'https://destination.test',
        'https://incoming.test',
        'https://destination.test',
      ], reason: applied.source);
      expect(_countKind(paragraph.inlines, fixture.kind), 3);
    }
  });

  test('collapsed whitespace maps through a supported raw HTML link', () {
    const source = '<a href="https://destination.test">left  right</a> tail';
    final result = engine.prepareStructured(
      target: _target(
        source,
        TextSelection.collapsed(offset: source.indexOf('left') + 5),
      ),
      fragment: _fragment('[Y](https://incoming.test)\n'),
    );

    final applied = _applyReady(source, result);
    final paragraph = _parse(applied.source).blocks.single;
    expect(paragraph.plainText, 'left Yright tail', reason: applied.source);
    expect(_destinations(paragraph.inlines), [
      'https://destination.test',
      'https://incoming.test',
      'https://destination.test',
    ], reason: applied.source);
  });

  test('supported content corpus always plans a rich insertion', () {
    const incomingDestination = 'https://incoming.test';
    final contents = <({String value, int position})>[
      (value: 'plain', position: 2),
      (value: 'white space', position: 5),
      (value: 'white  space', position: 'white '.length),
      (value: 'Straße', position: 4),
      (value: '😀 value', position: 5),
      (value: r'escaped \* value', position: r'escaped \* val'.length),
      (value: 'entity &amp; value', position: 'entity &amp; val'.length),
    ];
    final wrappers = <String Function(String)>[
      (value) => value,
      (value) => '**$value**',
      (value) => '*$value*',
      (value) => '~~$value~~',
      (value) => '[$value](https://destination.test "Title")',
      (value) => '<u>$value</u>',
      (value) => '<strong>$value</strong>',
      (value) => '<em>$value</em>',
      (value) => '<a href="https://destination.test">$value</a>',
      (value) => '<u><strong>$value</strong><br>tail</u>',
    ];

    var cases = 0;
    for (final wrap in wrappers) {
      for (final content in contents) {
        cases += 1;
        final source = 'prefix ${wrap(content.value)} suffix';
        final position = source.indexOf(content.value) + content.position;
        final result = engine.prepareStructured(
          target: _target(source, TextSelection.collapsed(offset: position)),
          fragment: _fragment('[Y]($incomingDestination)\n'),
        );

        expect(
          result,
          isA<SourcePasteReady>(),
          reason: 'case $cases: $source at $position',
        );
        final applied = _applyReady(source, result);
        final parsed = _parse(applied.source);
        expect(applied.source, startsWith('prefix '));
        expect(applied.source, endsWith(' suffix'));
        expect(
          _destinations(parsed.blocks.single.inlines),
          contains(incomingDestination),
          reason: 'case $cases: ${applied.source}',
        );
        if (source.contains('https://destination.test')) {
          expect(
            _destinations(parsed.blocks.single.inlines),
            contains('https://destination.test'),
            reason: 'case $cases: ${applied.source}',
          );
        }
        if (source.contains('"Title"')) {
          expect(
            _links(parsed.blocks.single.inlines)
                .where(
                  (inline) => inline.destination == 'https://destination.test',
                )
                .map((inline) => inline.attributes['title']),
            everyElement('Title'),
            reason: 'case $cases: ${applied.source}',
          );
        }
        final incomingEnd =
            applied.source.indexOf(incomingDestination) +
            incomingDestination.length +
            1;
        expect(
          applied.edit.caretOffset,
          incomingEnd,
          reason: 'case $cases: ${applied.source}',
        );
      }
    }
    expect(cases, 70);
  });

  test('repeated mapped siblings avoid fallback and preserve final paste', () {
    addTearDown(() {
      debugBusyMarkSourceMappingBoundaryInspections = null;
      debugBusyMarkSourceMappingFallbackSearchCalls = null;
      debugBusyMarkSourceMappingFallbackSearchRanges = null;
    });
    const segment = r'**x** \[ ';
    for (final count in [10, 100, 1000]) {
      final prefix = List.filled(count, segment).join();
      final source = '$prefix[leftright](https://destination.test)';
      var inspections = 0;
      var fallbackCalls = 0;
      final fallbackRanges = <({int start, int end})>[];
      debugBusyMarkSourceMappingBoundaryInspections = (value) =>
          inspections += value;
      debugBusyMarkSourceMappingFallbackSearchCalls = () => fallbackCalls += 1;
      debugBusyMarkSourceMappingFallbackSearchRanges = (start, end) =>
          fallbackRanges.add((start: start, end: end));
      final first = _applyReady(
        source,
        engine.prepareStructured(
          target: _target(
            source,
            TextSelection.collapsed(offset: source.indexOf('right')),
          ),
          fragment: _nativeFragment(const [
            BusyInline(
              kind: BusyInlineKind.link,
              text: 'Q',
              destination: 'https://incoming.test',
              attributes: {'title': 'Incoming title'},
              children: [BusyInline(kind: BusyInlineKind.text, text: 'Q')],
            ),
          ]),
        ),
      );

      expect(first.source, startsWith(prefix), reason: '$count repetitions');
      final firstParagraph = _parse(first.source).blocks.single;
      expect(
        firstParagraph.plainText,
        '${List.filled(count, 'x [ ').join()}leftQright',
      );
      expect(
        _links(
          firstParagraph.inlines,
        ).map((inline) => (inline.destination, inline.attributes['title'])),
        [
          ('https://destination.test', null),
          ('https://incoming.test', 'Incoming title'),
          ('https://destination.test', null),
        ],
      );
      final second = _applyReady(
        first.source,
        engine.prepareStructured(
          target: _target(
            first.source,
            TextSelection.collapsed(offset: first.edit.caretOffset),
          ),
          fragment: _nativeFragment(const [
            BusyInline(
              kind: BusyInlineKind.link,
              text: 'R',
              destination: 'https://second.test',
              children: [BusyInline(kind: BusyInlineKind.text, text: 'R')],
            ),
          ]),
        ),
      );
      expect(second.source, startsWith(prefix));
      expect(
        _parse(second.source).blocks.single.plainText,
        '${List.filled(count, 'x [ ').join()}leftQRright',
      );
      expect(second.edit.caretOffset, greaterThan(first.edit.caretOffset));
      expect(fallbackCalls, 0, reason: '$count repetitions');
      expect(fallbackRanges, isEmpty, reason: '$count repetitions');
      expect(inspections, greaterThan(0));
    }
  });

  test('complete blocks split and preserve enclosing inline contexts', () {
    final destinations =
        <
          ({String source, int caret, BusyInlineKind kind, String? destination})
        >[
          (
            source: 'prefix **leftright** suffix',
            caret: 'prefix **left'.length,
            kind: BusyInlineKind.strong,
            destination: null,
          ),
          (
            source: 'prefix *leftright* suffix',
            caret: 'prefix *left'.length,
            kind: BusyInlineKind.emphasis,
            destination: null,
          ),
          (
            source:
                'prefix [leftright](https://destination.test "Title") suffix',
            caret: 'prefix [left'.length,
            kind: BusyInlineKind.link,
            destination: 'https://destination.test',
          ),
        ];
    final fragments =
        <
          ({WysiwygClipboardFragment fragment, BusyBlockKind kind, String text})
        >[
          (
            fragment: _fragment('## Heading\n'),
            kind: BusyBlockKind.heading,
            text: 'Heading',
          ),
          (
            fragment: _fragment('- Item\n'),
            kind: BusyBlockKind.unorderedListItem,
            text: 'Item',
          ),
          (
            fragment: _fragment('```text\ncode\n```\n'),
            kind: BusyBlockKind.codeBlock,
            text: 'code',
          ),
        ];

    for (final destination in destinations) {
      for (final inserted in fragments) {
        final applied = _applyReady(
          destination.source,
          engine.prepareStructured(
            target: _target(
              destination.source,
              TextSelection.collapsed(offset: destination.caret),
            ),
            fragment: inserted.fragment,
          ),
        );
        final document = _parse(applied.source);
        final editorDocument = _parse(destination.source);
        final editor = BusyMarkWysiwygDocumentController(
          document: editorDocument,
        );
        addTearDown(editor.dispose);
        final editorResult = editor.insertStyledBlocksAtSelection(
          blockId: editorDocument.blocks.single.id,
          selectionStart: 'prefix left'.length,
          selectionEnd: 'prefix left'.length,
          blocks: inserted.fragment.blocks,
        );
        expect(editorResult, isNotNull);
        expect(
          _documentSemanticSignature(document),
          _documentSemanticSignature(editor.document),
          reason: 'Source: ${applied.source}\nEditor: ${editor.markdown}',
        );
        expect(document.blocks, hasLength(3), reason: applied.source);
        expect(document.blocks[0].plainText, 'prefix left');
        expect(document.blocks[1].kind, inserted.kind);
        expect(document.blocks[1].plainText, inserted.text);
        expect(document.blocks[2].plainText, 'right suffix');
        for (final block in [document.blocks.first, document.blocks.last]) {
          expect(
            _countKind(block.inlines, destination.kind),
            1,
            reason: applied.source,
          );
          if (destination.destination case final value?) {
            final link = _links(block.inlines).single;
            expect(link.destination, value);
            expect(link.attributes['title'], 'Title');
          }
        }
        expect(applied.source, startsWith('prefix '));
        expect(applied.source, endsWith(' suffix'));

        const marker = '\ue003';
        final marked = _parse(
          applied.source.replaceRange(
            applied.edit.caretOffset,
            applied.edit.caretOffset,
            marker,
          ),
        );
        expect(marked.blocks[2].plainText, '${marker}right suffix');
        expect(
          _countKind(marked.blocks[2].inlines, destination.kind),
          1,
          reason: applied.source,
        );
      }
    }
  });

  test('paragraph-only block sequences match Editor merge semantics', () {
    final fragments = [
      _fragment('*A*\n\n[B](https://incoming.test "B title")\n'),
      _fragment('*A*\n\n`C`\n\n[B](https://incoming.test "B title")\n'),
    ];
    final selections = <({int start, int end})>[
      (start: 0, end: 0),
      (start: 4, end: 4),
      (start: 9, end: 9),
      (start: 3, end: 6),
    ];

    for (final fragment in fragments) {
      for (final selection in selections) {
        const source = '**leftright**';
        final sourceSelection = TextSelection(
          baseOffset: 2 + selection.start,
          extentOffset: 2 + selection.end,
        );
        final applied = _applyReady(
          source,
          engine.prepareStructured(
            target: _target(source, sourceSelection),
            fragment: fragment,
          ),
        );
        final sourceDocument = _parse(applied.source);

        final editorDocument = _parse(source);
        final editor = BusyMarkWysiwygDocumentController(
          document: editorDocument,
        );
        addTearDown(editor.dispose);
        final result = editor.insertStyledBlocksAtSelection(
          blockId: editorDocument.blocks.single.id,
          selectionStart: selection.start,
          selectionEnd: selection.end,
          blocks: fragment.blocks,
        );
        expect(result, isNotNull);
        final insertion = result!;
        expect(
          _documentSemanticSignature(sourceDocument),
          _documentSemanticSignature(editor.document),
          reason:
              'selection $selection\nSource: ${applied.source}\n'
              'Editor: ${editor.markdown}',
        );

        const marker = '\ue004';
        final marked = _parse(
          applied.source.replaceRange(
            applied.edit.caretOffset,
            applied.edit.caretOffset,
            marker,
          ),
        );
        final markedBlockIndex = marked.blocks.indexWhere(
          (block) => block.plainText.contains(marker),
        );
        final editorBlockIndex = editor.document.blocks.indexWhere(
          (block) => block.id == insertion.blockId,
        );
        expect(markedBlockIndex, editorBlockIndex, reason: applied.source);
        expect(
          marked.blocks[markedBlockIndex].plainText.indexOf(marker),
          insertion.offset,
          reason: applied.source,
        );
      }
    }
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

WysiwygClipboardFragment _nativeFragment(List<BusyInline> inlines) {
  final text = inlines.map((inline) => inline.plainText).join();
  final block = BusyBlock(
    id: 'native-clipboard-paragraph',
    kind: BusyBlockKind.paragraph,
    inlines: inlines,
  );
  return WysiwygClipboardFragment(
    sourcePath: '/clipboard/source.md',
    mode: MarkdownMode.commonMark,
    blocks: [
      BusyWysiwygStyledBlock(
        kind: BusyBlockKind.paragraph,
        text: text,
        ranges: busyInlineStyleRanges(inlines),
        completeBlock: block,
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

BusyBlock _contentParagraph(BusyDocument document) {
  final root = document.blocks.single;
  if (root.kind != BusyBlockKind.table) return root;
  return root.children.last.children.single;
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
  return [for (final inline in _links(inlines)) inline.destination];
}

List<BusyInline> _links(List<BusyInline> inlines) {
  final result = <BusyInline>[];
  void visit(List<BusyInline> values) {
    for (final inline in values) {
      if (inline.kind == BusyInlineKind.link) result.add(inline);
      visit(inline.children);
    }
  }

  visit(inlines);
  return result;
}

List<String> _documentSemanticSignature(BusyDocument document) {
  final result = <String>[];

  void addInline(BusyInline inline, int depth) {
    result.add(
      '${'  ' * depth}inline:${inline.kind.name}:${inline.text}:'
      '${inline.destination ?? ''}:${inline.attributes['title'] ?? ''}',
    );
    for (final child in inline.children) {
      addInline(child, depth + 1);
    }
  }

  void addBlock(BusyBlock block, int depth) {
    result.add(
      '${'  ' * depth}block:${block.kind.name}:${block.attributes.entries.toList()}',
    );
    for (final inline in block.inlines) {
      addInline(inline, depth + 1);
    }
    for (final child in block.children) {
      addBlock(child, depth + 1);
    }
  }

  for (final block in document.blocks) {
    addBlock(block, 0);
  }
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

List<({String text, List<BusyInlineKind> contexts})> _leafContexts(
  List<BusyInline> inlines,
) {
  final result = <({String text, List<BusyInlineKind> contexts})>[];

  void visit(BusyInline inline, List<BusyInlineKind> inherited) {
    final contexts = inline.kind == BusyInlineKind.text
        ? inherited
        : [...inherited, inline.kind];
    if (inline.children.isEmpty) {
      if (inline.plainText.isNotEmpty) {
        result.add((text: inline.plainText, contexts: contexts));
      }
      return;
    }
    for (final child in inline.children) {
      visit(child, contexts);
    }
  }

  for (final inline in inlines) {
    visit(inline, const []);
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
