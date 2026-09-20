import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_ast_adapter.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_source_map.dart';
import 'package:busymark/src/markdown/raw_html_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = MarkdownSourceMapper();

  test('annotated parsing has ordinary semantics across supported corpus', () {
    const fixtures = <String>[
      'plain text and  whitespace',
      r'escaped \*literal\* and [balanced [label]](https://example.test)',
      '***strong emphasis*** and ~~strike~~',
      r'`**not strong** <br>` and ``a ` b``',
      '![alt](image.png "title")',
      '[full][ref] [collapsed][] [shortcut]\n\n'
          '[ref]: https://one.test "One"\n'
          '[collapsed]: https://two.test\n'
          '[shortcut]: https://three.test',
      '<https://example.test/a?b=c> <person@example.test>',
      '<not an autolink> and <bad@example>',
      '<u>left<br>right</u>',
      '<strong>bold <em>nested</em></strong>',
      '<a href="https://example.test" title="A title">linked</a>',
      '<u title="tag-looking <br> text">left<br />right</u>',
      '<u title="tag-looking\n<br>\ntext">left<br>\nright</u>',
      '<u>left\nright</u>',
      '<!-- <br> --> visible',
      'left  \nright',
      'left\n<br>\n<br>\nright',
      r'inline $x + y$ and %Writerside_Variable%',
      'Straße STRAẞE 😀 supplementary',
    ];

    for (final fixture in fixtures) {
      final context = mapper.createInlineParserContext(
        documentSource: fixture,
        mode: MarkdownMode.writersideMarkdown,
      );
      final ordinary = context.parse(fixture);
      final mapped = context.parseMapped(fixture);
      expect(
        _semanticTree(mapped.inlines),
        _semanticTree(ordinary),
        reason: fixture,
      );
    }
  });

  test('position records do not change HTML or link semantics', () {
    const marker = '\ue001';
    const source =
        '[<u title="a &amp; b">left<br>right</u>]'
        '(https://destination.test "Original title") tail';
    final positions = <int>[
      source.indexOf('<br>'),
      source.indexOf('<br>') + '<br>'.length,
      source.indexOf('</u>'),
      source.indexOf('right') + 2,
    ];
    final ordinaryContext = mapper.createInlineParserContext(
      documentSource: source,
      mode: MarkdownMode.commonMark,
    );
    final ordinary = ordinaryContext.parse(source);

    for (final position in positions) {
      final marked = source.replaceRange(position, position, marker);
      final context = mapper.createInlineParserContext(
        documentSource: source,
        mode: MarkdownMode.commonMark,
      );
      final mapped = context.parseMapped(
        marked,
        ignoredReferenceLabelMarkers: const [marker],
      );
      expect(
        mapped.positionRecordsComplete,
        isTrue,
        reason: 'supported HTML boundary $position in $marked',
      );
      expect(
        _leafMarkerOccurrences(mapped.inlines, marker),
        1,
        reason: 'supported HTML boundary $position in $marked',
      );
      expect(
        _semanticTree(mapped.inlines, ignoredMarkers: const [marker]),
        _semanticTree(ordinary),
        reason: 'position $position in $marked',
      );
    }
  });

  test('selection endpoints crossing HTML retain one semantic fragment', () {
    const startMarker = '\ue001';
    const endMarker = '\ue002';
    const source = '<u>left<br>right</u> tail';
    final marked = source
        .replaceRange(
          source.indexOf('right') + 2,
          source.indexOf('right') + 2,
          endMarker,
        )
        .replaceRange(
          source.indexOf('left') + 2,
          source.indexOf('left') + 2,
          startMarker,
        );
    final context = mapper.createInlineParserContext(
      documentSource: source,
      mode: MarkdownMode.commonMark,
    );
    final ordinary = context.parse(source);
    final mapped = context.parseMapped(
      marked,
      ignoredReferenceLabelMarkers: const [startMarker, endMarker],
    );

    expect(mapped.positionRecordsComplete, isTrue);
    expect(_leafMarkerOccurrences(mapped.inlines, startMarker), 1);
    expect(_leafMarkerOccurrences(mapped.inlines, endMarker), 1);
    expect(
      _semanticTree(
        mapped.inlines,
        ignoredMarkers: const [startMarker, endMarker],
      ),
      _semanticTree(ordinary),
    );
    final underline = mapped.inlines.singleWhere(
      (inline) => inline.kind == BusyInlineKind.underline,
    );
    expect(
      underline.children.where(
        (inline) => inline.kind == BusyInlineKind.hardBreak,
      ),
      hasLength(1),
    );
  });

  test(
    'supported HTML whitespace positions have complete position records',
    () {
      const marker = '\ue001';
      final fixtures =
          <({String source, int position, String expectedMarkedText})>[
            (
              source:
                  '[<u>left  right</u>]'
                  '(https://destination.test) tail',
              position: '[<u>left'.length,
              expectedMarkedText: 'left$marker right',
            ),
            (
              source:
                  '[<u>left  right</u>]'
                  '(https://destination.test) tail',
              position: '[<u>left '.length,
              expectedMarkedText:
                  'left $marker'
                  'right',
            ),
            (
              source:
                  '[<u>left  right</u>]'
                  '(https://destination.test) tail',
              position: '[<u>left  '.length,
              expectedMarkedText:
                  'left $marker'
                  'right',
            ),
            (
              source:
                  '[<u>left \t right</u>]'
                  '(https://destination.test) tail',
              position: '[<u>left \t'.length,
              expectedMarkedText:
                  'left $marker'
                  'right',
            ),
            (
              source:
                  '[<u>left \r\n\t right</u>]'
                  '(https://destination.test) tail',
              position: '[<u>left \r\n'.length,
              expectedMarkedText:
                  'left $marker'
                  'right',
            ),
          ];

      for (final fixture in fixtures) {
        final marked = fixture.source.replaceRange(
          fixture.position,
          fixture.position,
          marker,
        );
        final context = mapper.createInlineParserContext(
          documentSource: fixture.source,
          mode: MarkdownMode.commonMark,
        );
        final ordinary = context.parse(fixture.source);
        final mapped = context.parseMapped(
          marked,
          ignoredReferenceLabelMarkers: const [marker],
        );

        expect(mapped.positionRecordsComplete, isTrue, reason: fixture.source);
        expect(
          _semanticTree(mapped.inlines, ignoredMarkers: const [marker]),
          _semanticTree(ordinary),
          reason: fixture.source,
        );
        final underline = _allInlines(
          mapped.inlines,
        ).singleWhere((inline) => inline.kind == BusyInlineKind.underline);
        expect(underline.plainText, fixture.expectedMarkedText);
        expect(
          _allInlines(
            mapped.inlines,
          ).where((inline) => inline.plainText.contains(marker)),
          isNotEmpty,
        );
      }
    },
  );

  test('only operation-local markers are ignored', () {
    const authored = '\ue000';
    const marker = '\ue001';
    const source = 'authored $authored [label](https://example.test/%EE%80%80)';
    final position = source.indexOf('label') + 2;
    final marked = source.replaceRange(position, position, marker);
    final context = mapper.createInlineParserContext(
      documentSource: source,
      mode: MarkdownMode.commonMark,
    );
    final mapped = context.parseMapped(
      marked,
      ignoredReferenceLabelMarkers: const [marker],
    );

    expect(mapped.inlines.first.plainText, contains(authored));
    final link = mapped.inlines.singleWhere(
      (inline) => inline.kind == BusyInlineKind.link,
    );
    expect(link.destination, 'https://example.test/%EE%80%80');
    expect(mapped.positionRecordsComplete, isTrue);
  });

  test('delimiter-only positions are explicitly incomplete', () {
    const marker = '\ue001';
    const source = '**left**';
    const position = 1; // Inside the opening delimiter, not text content.
    final context = mapper.createInlineParserContext(
      documentSource: source,
      mode: MarkdownMode.commonMark,
    );
    final ordinary = context.parse(source);
    final mapped = context.parseMapped(
      source.replaceRange(position, position, marker),
      ignoredReferenceLabelMarkers: const [marker],
    );

    expect(mapped.positionRecordsComplete, isFalse);
    expect(_semanticTree(mapped.inlines), _semanticTree(ordinary));
  });

  test('syntax-boundary probes retain the ordinary semantic oracle', () {
    // Completeness is deliberately not qualified here: this corpus includes
    // both content boundaries and positions inside delimiters, destinations,
    // and titles. Dedicated tests above classify those categories and require
    // complete records for supported content.
    const marker = '\ue001';
    final fixtures = <({String source, List<int> positions})>[
      (source: '**left**', positions: const [0, 1, 2, 4, 6, 7, 8]),
      (source: r'\*left\*', positions: const [0, 1, 2, 5, 6, 7, 8]),
      (source: '`left`', positions: const [0, 1, 3, 5, 6, 7]),
      (
        source: '[left](https://destination.test "Title")',
        positions: const [0, 1, 5, 6, 7, 15, 33, 35, 40, 41],
      ),
      (
        source: '[left][ref]\n\n[ref]: https://destination.test "Title"',
        positions: const [0, 1, 5, 6, 7, 10, 11],
      ),
      (
        source: '<https://destination.test/path>',
        positions: const [0, 1, 10, 30, 31],
      ),
    ];
    var cases = 0;
    for (final fixture in fixtures) {
      final ordinaryContext = mapper.createInlineParserContext(
        documentSource: fixture.source,
        mode: MarkdownMode.commonMark,
      );
      final ordinary = ordinaryContext.parse(fixture.source);
      for (final position in fixture.positions) {
        if (position > fixture.source.length) continue;
        cases += 1;
        final marked = fixture.source.replaceRange(position, position, marker);
        final context = mapper.createInlineParserContext(
          documentSource: fixture.source,
          mode: MarkdownMode.commonMark,
        );
        final mapped = context.parseMapped(
          marked,
          ignoredReferenceLabelMarkers: const [marker],
        );
        expect(
          _semanticTree(mapped.inlines, ignoredMarkers: const [marker]),
          _semanticTree(ordinary),
          reason: '${fixture.source} at $position',
        );
      }
    }
    expect(cases, 40);
  });

  test('deterministic inline combinations preserve annotated semantics', () {
    const marker = '\ue001';
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
        final source = wrap(content.value);
        final contentStart = source.indexOf(content.value);
        final position = contentStart + content.position;
        final marked = source.replaceRange(position, position, marker);
        final context = mapper.createInlineParserContext(
          documentSource: source,
          mode: MarkdownMode.writersideMarkdown,
        );
        final ordinary = context.parse(source);
        final mapped = context.parseMapped(
          marked,
          ignoredReferenceLabelMarkers: const [marker],
        );
        expect(
          mapped.positionRecordsComplete,
          isTrue,
          reason: 'case $cases: $source at $position',
        );
        expect(
          _leafMarkerOccurrences(mapped.inlines, marker),
          1,
          reason: 'case $cases: $source at $position',
        );
        expect(
          _semanticTree(mapped.inlines, ignoredMarkers: const [marker]),
          _semanticTree(ordinary),
          reason: 'case $cases: $source',
        );
      }
    }
    expect(cases, 70);
  });

  test('standalone HTML break ownership uses one indexed lookup per break', () {
    addTearDown(() => debugBusyMarkStandaloneBreakLayoutLookups = null);
    for (final count in [10, 100, 1000]) {
      var lookups = 0;
      debugBusyMarkStandaloneBreakLayoutLookups = (value) => lookups += value;
      final source = '<u>${List.filled(count, 'x<br>\n').join()}z</u>';
      final context = mapper.createInlineParserContext(
        documentSource: source,
        mode: MarkdownMode.commonMark,
      );
      final mapped = context.parseMapped(source);

      expect(context.parseInvocations, 1, reason: '$count breaks');
      expect(lookups, count, reason: '$count breaks');
      expect(_countKind(mapped.inlines, BusyInlineKind.hardBreak), count);
    }
  });

  test('AST source boundary lookahead is linear and maps the final link', () {
    addTearDown(() => debugBusyMarkSourceMappingBoundaryInspections = null);
    const marker = '\ue001';
    for (final count in [10, 100, 1000]) {
      final prefix = [
        for (var index = 0; index < count; index++) '`code$index`',
      ].join(' ');
      final source = '$prefix [leftright](https://destination.test)';
      final position = source.indexOf('leftright') + 4;
      final marked = source.replaceRange(position, position, marker);
      var inspections = 0;
      debugBusyMarkSourceMappingBoundaryInspections = (value) =>
          inspections += value;
      final context = mapper.createInlineParserContext(
        documentSource: source,
        mode: MarkdownMode.commonMark,
      );
      final mapped = context.parseMapped(
        marked,
        ignoredReferenceLabelMarkers: const [marker],
      );

      expect(mapped.positionRecordsComplete, isTrue, reason: '$count spans');
      final link = _allInlines(
        mapped.inlines,
      ).singleWhere((inline) => inline.kind == BusyInlineKind.link);
      expect(link.destination, 'https://destination.test');
      expect(link.plainText, 'left${marker}right');
      final range = mapped.ranges[link];
      expect(range, isNotNull);
      expect(range!.start, source.indexOf('[leftright]'));
      expect(range.end, marked.length);
      expect(
        inspections,
        lessThanOrEqualTo(count * 6 + 30),
        reason: '$count spans inspected $inspections boundaries',
      );
    }
  });

  test('tag-looking attribute text does not claim break layout', () {
    const source = '<u title="before\n<br>\nafter">left<br>\nright</u>';
    var lookups = 0;
    debugBusyMarkStandaloneBreakLayoutLookups = (value) => lookups += value;
    addTearDown(() => debugBusyMarkStandaloneBreakLayoutLookups = null);
    final context = mapper.createInlineParserContext(
      documentSource: source,
      mode: MarkdownMode.commonMark,
    );
    final ordinary = context.parse(source);
    final mapped = context.parseMapped(source);

    expect(_semanticTree(mapped.inlines), _semanticTree(ordinary));
    expect(lookups, 1);
    expect(_countKind(mapped.inlines, BusyInlineKind.hardBreak), 1);
  });
}

Object _semanticTree(
  List<BusyInline> inlines, {
  List<String> ignoredMarkers = const [],
}) {
  String clean(String value) {
    var result = value;
    for (final marker in ignoredMarkers) {
      result = result.replaceAll(marker, '');
    }
    return result;
  }

  List<Object> siblings(List<BusyInline> values) {
    final result = <Object>[];
    String? pendingText;
    Map<String, String>? pendingAttributes;
    void flushText() {
      if (pendingText == null) return;
      result.add(<String, Object?>{
        'kind': BusyInlineKind.text.name,
        'text': pendingText,
        'attributes': pendingAttributes,
        'children': const <Object>[],
      });
      pendingText = null;
      pendingAttributes = null;
    }

    for (final inline in values) {
      final attributes = Map<String, String>.fromEntries(
        inline.attributes.entries.toList()
          ..sort((left, right) => left.key.compareTo(right.key)),
      );
      if (inline.kind == BusyInlineKind.text && inline.children.isEmpty) {
        final text = clean(inline.text);
        if (text.isEmpty) continue;
        if (pendingText != null && _mapEquals(pendingAttributes!, attributes)) {
          pendingText = '$pendingText$text';
        } else {
          flushText();
          pendingText = text;
          pendingAttributes = attributes;
        }
        continue;
      }
      flushText();
      result.add(<String, Object?>{
        'kind': inline.kind.name,
        'text': clean(inline.text),
        'destination': inline.destination,
        'attributes': attributes,
        'children': siblings(inline.children),
      });
    }
    flushText();
    return result;
  }

  return siblings(inlines);
}

bool _mapEquals(Map<String, String> left, Map<String, String> right) {
  if (left.length != right.length) return false;
  return left.entries.every((entry) => right[entry.key] == entry.value);
}

int _countKind(List<BusyInline> inlines, BusyInlineKind kind) {
  var count = 0;
  for (final inline in inlines) {
    if (inline.kind == kind) count += 1;
    count += _countKind(inline.children, kind);
  }
  return count;
}

List<BusyInline> _allInlines(List<BusyInline> inlines) {
  return [
    for (final inline in inlines) ...[inline, ..._allInlines(inline.children)],
  ];
}

int _leafMarkerOccurrences(List<BusyInline> inlines, String marker) {
  var count = 0;
  for (final inline in inlines) {
    if (inline.children.isEmpty) {
      var offset = 0;
      while ((offset = inline.text.indexOf(marker, offset)) >= 0) {
        count += 1;
        offset += marker.length;
      }
    } else {
      count += _leafMarkerOccurrences(inline.children, marker);
    }
  }
  return count;
}
