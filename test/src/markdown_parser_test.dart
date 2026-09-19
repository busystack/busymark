import 'dart:io';

import 'package:busymark/src/core/diagnostic.dart';
import 'package:busymark/src/core/local_image_resolver.dart';
import 'package:busymark/src/core/path_utils.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_ast_adapter.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  const parser = MarkdownParser();

  String fixture(String name) => 'test/fixtures/markdown/$name';

  test('inline source mapping uses parsed formatting boundaries', () {
    const marker = '\ue000';
    final codeSpans = List.filled(30, '`**`').join(' ');
    final source = '**start $codeSpans left${marker}right $codeSpans end**';
    final context = const MarkdownAstAdapter().createInlineParserContext(
      documentSource: source.replaceAll(marker, ''),
      mode: MarkdownMode.commonMark,
    );

    final mapped = context.parseMapped(source);

    expect(context.parseInvocations, 1);
    expect(mapped.inlines, hasLength(1));
    final strong = mapped.inlines.single;
    expect(strong.kind, BusyInlineKind.strong);
    final range = mapped.ranges[strong];
    expect(range?.start, 0);
    expect(range?.end, source.length);
    expect(range?.opening, '**');
    expect(range?.closing, '**');
    expect(
      strong.children.where((inline) => inline.kind == BusyInlineKind.code),
      hasLength(60),
    );
  });

  test('inline source mapping locates partially consumed delimiter runs', () {
    BusyMarkMappedInlineRange mappedRange(String source, BusyInlineKind kind) {
      final context = const MarkdownAstAdapter().createInlineParserContext(
        documentSource: source,
        mode: MarkdownMode.commonMark,
      );
      final mapped = context.parseMapped(source);
      BusyInline? result;
      void visit(Iterable<BusyInline> inlines) {
        for (final inline in inlines) {
          if (result == null && inline.kind == kind) result = inline;
          visit(inline.children);
        }
      }

      visit(mapped.inlines);
      expect(result, isNotNull, reason: source);
      return mapped.ranges[result!]!;
    }

    for (final delimiter in ['*', '_']) {
      final partialOpening =
          '$delimiter$delimiter${delimiter}leftright'
          '$delimiter$delimiter';
      final openingRange = mappedRange(partialOpening, BusyInlineKind.strong);
      expect(openingRange.start, 1, reason: partialOpening);
      expect(openingRange.end, partialOpening.length, reason: partialOpening);

      final partialClosing =
          '$delimiter${delimiter}leftright'
          '$delimiter$delimiter$delimiter';
      final closingRange = mappedRange(partialClosing, BusyInlineKind.strong);
      expect(closingRange.start, 0, reason: partialClosing);
      expect(
        closingRange.end,
        partialClosing.length - 1,
        reason: partialClosing,
      );

      final nested =
          '$delimiter$delimiter${delimiter}leftright'
          '$delimiter$delimiter$delimiter';
      final strongRange = mappedRange(nested, BusyInlineKind.strong);
      final emphasisRange = mappedRange(nested, BusyInlineKind.emphasis);
      expect(strongRange.start, 1, reason: nested);
      expect(strongRange.end, nested.length - 1, reason: nested);
      expect(emphasisRange.start, 0, reason: nested);
      expect(emphasisRange.end, nested.length, reason: nested);
    }
  });

  test('inline source mapping retains escaped collapsed references', () {
    const marker = '\ue000';
    final marked = '${r'[prefix \[ left'}$marker${r'right][]'}';
    final context = const MarkdownAstAdapter().createInlineParserContext(
      documentSource:
          '${r'[prefix \[ leftright][]'}\n\n'
          '${r'[prefix \[ leftright]: https://destination.test'}\n',
      mode: MarkdownMode.commonMark,
    );

    final mapped = context.parseMapped(
      marked,
      ignoredReferenceLabelMarkers: const [marker],
    );

    expect(context.parseInvocations, 4);
    expect(mapped.inlines, hasLength(1));
    final link = mapped.inlines.single;
    expect(link.kind, BusyInlineKind.link);
    expect(link.destination, 'https://destination.test');
    final range = mapped.ranges[link];
    expect(range?.start, 0);
    expect(range?.end, marked.length);
    expect(range?.labelStart, 1);
    expect(range?.labelEnd, marked.indexOf(']'));
    expect(range?.isReference, isTrue);
  });

  test('inline source mapping keeps original autolink semantics', () {
    const marker = '\ue000';
    const original = '<https://example.test/leftright>';
    const marked = '<https://example.test/left${marker}right>';
    final context = const MarkdownAstAdapter().createInlineParserContext(
      documentSource: original,
      mode: MarkdownMode.commonMark,
    );

    final mapped = context.parseMapped(
      marked,
      ignoredReferenceLabelMarkers: const [marker],
    );

    final link = mapped.inlines.single;
    expect(link.kind, BusyInlineKind.link);
    expect(link.plainText, 'https://example.test/left${marker}right');
    expect(link.destination, 'https://example.test/leftright');
    expect(link.attributes['href'], 'https://example.test/leftright');
    expect(mapped.ranges[link]?.isAutolink, isTrue);
    expect(mapped.ranges[link]?.isReference, isFalse);
  });

  test('inline source mapping preserves supported autolink variants', () {
    const cases = <({String original, String marked, String destination})>[
      (
        original: '<https://example.test/a%20b-right>',
        marked: '<https://example.test/a%20b-\ue000right>',
        destination: 'https://example.test/a%20b-right',
      ),
      (
        original: '<left@example.test>',
        marked: '<left\ue000@example.test>',
        destination: 'mailto:left@example.test',
      ),
      (
        original: '<https://example.test/\ue000-%EE%80%80-right>',
        marked: '<https://example.test/\ue000-%EE%80%80-\ue001right>',
        destination: 'https://example.test/%EE%80%80-%EE%80%80-right',
      ),
    ];
    for (final value in cases) {
      final marker = value.marked.contains('\ue001') ? '\ue001' : '\ue000';
      final context = const MarkdownAstAdapter().createInlineParserContext(
        documentSource: value.original,
        mode: MarkdownMode.commonMark,
      );

      final mapped = context.parseMapped(
        value.marked,
        ignoredReferenceLabelMarkers: [marker],
      );

      final link = mapped.inlines.single;
      expect(link.kind, BusyInlineKind.link, reason: value.original);
      expect(link.destination, value.destination, reason: value.original);
      expect(
        link.attributes['href'],
        value.destination,
        reason: value.original,
      );
      expect(
        mapped.ranges[link]?.originalInline?.destination,
        value.destination,
      );
      expect(mapped.ranges[link]?.isAutolink, isTrue);
    }
  });

  test('inline source mapping uses parser case folding for references', () {
    const marker = '\ue000';
    const original = '[STRA\u1e9eE][]\n\n[STRASSE]: https://destination.test\n';
    final parsed = parser.parse(
      filePath: 'case-folded.md',
      source: original,
      validateLocalReferences: false,
    );
    expect(
      parsed.busyDocument.blocks.first.inlines.single.destination,
      'https://destination.test',
    );
    final context = const MarkdownAstAdapter().createInlineParserContext(
      documentSource: original,
      mode: MarkdownMode.commonMark,
    );

    final mapped = context.parseMapped(
      '[STRA$marker\u1e9eE][]',
      ignoredReferenceLabelMarkers: const [marker],
    );

    final link = mapped.inlines.single;
    expect(link.kind, BusyInlineKind.link);
    expect(link.destination, 'https://destination.test');
    expect(link.attributes['href'], 'https://destination.test');
  });

  test(
    'ordinary reference parsing retains pinned sharp-S folding behavior',
    () {
      for (final link in const ['[STRA\u1e9eE][]', '[STRA\u1e9eE]']) {
        final parsed = parser.parse(
          filePath: 'case-folded.md',
          source: '$link\n\n[STRASSE]: https://destination.test\n',
          validateLocalReferences: false,
        );
        expect(
          parsed.busyDocument.blocks.first.inlines.single.destination,
          'https://destination.test',
          reason: link,
        );
      }

      final unsupported = parser.parse(
        filePath: 'case-folded.md',
        source: '[stra\u00dfe][]\n\n[STRASSE]: https://destination.test\n',
        validateLocalReferences: false,
      );
      expect(
        unsupported.busyDocument.blocks.first.inlines.single.kind,
        BusyInlineKind.text,
      );
    },
  );

  test('invalid email-like text cannot orphan a later mapped link', () {
    const marker = '\ue000';
    for (final original in const [
      'Before <x@-y> and <https://example.test/leftright> after',
      'Before <https://example.test/leftright> and <x@-y> after',
      'Before <https://example.test/leftright> and '
          '<https://example.test/leftright> after',
    ]) {
      final target = original.indexOf('leftright');
      final marked = original.replaceRange(target + 4, target + 4, marker);
      final context = const MarkdownAstAdapter().createInlineParserContext(
        documentSource: original,
        mode: MarkdownMode.commonMark,
      );
      final mapped = context.parseMapped(
        marked,
        ignoredReferenceLabelMarkers: const [marker],
      );
      final links = mapped.inlines
          .where((inline) => inline.kind == BusyInlineKind.link)
          .toList();
      final selected = links.singleWhere(
        (inline) => inline.plainText.contains(marker),
      );
      expect(
        mapped.ranges[selected]?.originalInline?.destination,
        'https://example.test/leftright',
        reason: original,
      );
      expect(
        mapped.inlines.map((inline) => inline.plainText).join(),
        marked.replaceAllMapped(
          RegExp(r'<(https://example\.test/[^>]*)>'),
          (match) => match[1]!,
        ),
        reason: original,
      );
    }
  });

  test('block inline mapping projects logical content to container source', () {
    const marker = '\ue000';
    const original =
        '> [left\n'
        '> right](https://destination.test)';
    const marked =
        '> [left$marker\n'
        '> right](https://destination.test)';
    final context = const MarkdownAstAdapter().createInlineParserContext(
      documentSource: original,
      mode: MarkdownMode.commonMark,
    );

    final mapped = context.parseMappedBlock(
      marked,
      sourceStart: 0,
      sourceEnd: marked.length,
      ignoredReferenceLabelMarkers: const [marker],
    );

    expect(mapped, isNotNull);
    final link = mapped!.inlines.single;
    expect(link.kind, BusyInlineKind.link);
    expect(link.plainText, 'left$marker\nright');
    expect(link.plainText, isNot(contains('>')));
    final range = mapped.ranges[link];
    expect(range?.start, 2);
    expect(range?.end, marked.length);
    expect(range?.lineBreaks, hasLength(1));
    expect(range?.lineBreaks.single.lineEnding, '\n');
    expect(range?.lineBreaks.single.continuationPrefix, '> ');
    expect(range?.lineBreaks.single.textOffset, 'left$marker'.length);

    final crlfMapped = context.parseMappedBlock(
      marked.replaceAll('\n', '\r\n'),
      sourceStart: 0,
      sourceEnd: marked.length + 1,
      ignoredReferenceLabelMarkers: const [marker],
    );
    final crlfLink = crlfMapped!.inlines.single;
    expect(crlfLink.plainText, 'left$marker\nright');
    expect(crlfMapped.ranges[crlfLink]?.lineBreaks.single.lineEnding, '\r\n');
    expect(
      crlfMapped.ranges[crlfLink]?.lineBreaks.single.continuationPrefix,
      '> ',
    );
  });

  test('block inline mapping ignores title and code-span source breaks', () {
    const marker = '\ue000';
    const titleSource =
        '> [left$marker\n'
        '> middle\r\n'
        '> right](https://destination.test "first\n'
        '> second")';
    final titleContext = const MarkdownAstAdapter().createInlineParserContext(
      documentSource: titleSource.replaceAll(marker, ''),
      mode: MarkdownMode.commonMark,
    );
    final titleMapped = titleContext.parseMappedBlock(
      titleSource,
      sourceStart: 0,
      sourceEnd: titleSource.length,
      ignoredReferenceLabelMarkers: const [marker],
    )!;
    final titleLink = titleMapped.inlines.single;
    expect(titleLink.attributes['title'], 'first\nsecond');
    expect(titleMapped.ranges[titleLink]?.lineBreaks, hasLength(2));
    expect(
      titleMapped.ranges[titleLink]?.lineBreaks.map(
        (value) => value.lineEnding,
      ),
      ['\n', '\r\n'],
    );
    expect(
      titleMapped.ranges[titleLink]?.lineBreaks.map(
        (value) => value.sourceOffset,
      ),
      [titleSource.indexOf('\n'), titleSource.indexOf('\r\n')],
    );

    const multipleTitleSource =
        '> [left$marker\r\n'
        '> right](https://destination.test "first\n'
        '> second\r\n'
        '> third")';
    final multipleTitleContext = const MarkdownAstAdapter()
        .createInlineParserContext(
          documentSource: multipleTitleSource.replaceAll(marker, ''),
          mode: MarkdownMode.commonMark,
        );
    final multipleTitleMapped = multipleTitleContext.parseMappedBlock(
      multipleTitleSource,
      sourceStart: 0,
      sourceEnd: multipleTitleSource.length,
      ignoredReferenceLabelMarkers: const [marker],
    )!;
    final multipleTitleLink = multipleTitleMapped.inlines.single;
    expect(multipleTitleLink.attributes['title'], 'first\nsecond\nthird');
    expect(
      multipleTitleMapped.ranges[multipleTitleLink]?.lineBreaks,
      hasLength(1),
    );
    expect(
      multipleTitleMapped
          .ranges[multipleTitleLink]
          ?.lineBreaks
          .single
          .lineEnding,
      '\r\n',
    );

    const codeSource =
        '> [left `code\n'
        '> span`$marker middle\r\n'
        '> right](https://destination.test)';
    final codeContext = const MarkdownAstAdapter().createInlineParserContext(
      documentSource: codeSource.replaceAll(marker, ''),
      mode: MarkdownMode.commonMark,
    );
    final codeMapped = codeContext.parseMappedBlock(
      codeSource,
      sourceStart: 0,
      sourceEnd: codeSource.length,
      ignoredReferenceLabelMarkers: const [marker],
    )!;
    final codeLink = codeMapped.inlines.single;
    expect(codeLink.plainText, 'left code span$marker middle\nright');
    expect(codeMapped.ranges[codeLink]?.lineBreaks, hasLength(1));
    expect(codeMapped.ranges[codeLink]?.lineBreaks.single.lineEnding, '\r\n');
  });

  test('block inline mapping keeps each hard-break occurrence range', () {
    const marker = '\ue000';
    const source =
        '> [left$marker  \r\n'
        '> middle  \n'
        '> right](https://destination.test)';
    final context = const MarkdownAstAdapter().createInlineParserContext(
      documentSource: source.replaceAll(marker, ''),
      mode: MarkdownMode.commonMark,
    );

    final mapped = context.parseMappedBlock(
      source,
      sourceStart: 0,
      sourceEnd: source.length,
      ignoredReferenceLabelMarkers: const [marker],
    )!;
    final link = mapped.inlines.single;
    final hardBreaks = link.children
        .where((inline) => inline.kind == BusyInlineKind.hardBreak)
        .toList(growable: false);
    final firstStart = source.indexOf('  \r\n');
    final secondStart = source.indexOf('  \n');

    expect(hardBreaks, hasLength(2));
    expect(identical(hardBreaks.first, hardBreaks.last), isFalse);
    expect(mapped.ranges[hardBreaks.first]?.start, firstStart);
    expect(mapped.ranges[hardBreaks.first]?.end, firstStart + '  \r\n'.length);
    expect(mapped.ranges[hardBreaks.last]?.start, secondStart);
    expect(mapped.ranges[hardBreaks.last]?.end, secondStart + '  \n'.length);
    expect(
      mapped.ranges[link]?.lineBreaks.map(
        (lineBreak) => (
          lineBreak.textOffset,
          lineBreak.sourceOffset,
          lineBreak.lineEnding,
          lineBreak.continuationPrefix,
        ),
      ),
      [
        ('left$marker'.length, source.indexOf('\r\n'), '\r\n', '> '),
        (
          'left$marker\nmiddle'.length,
          source.indexOf('\n', source.indexOf('\r\n') + 2),
          '\n',
          '> ',
        ),
      ],
    );
  });

  test('block inline mapping matches standalone HTML break layout', () {
    const marker = '\ue000';
    const original =
        '[A\n'
        '<br>\n'
        '<br>\n'
        'right](https://destination.test) tail';
    const marked =
        '[A\n'
        '<br>\n'
        '<br>\n'
        'ri${marker}ght](https://destination.test) tail';
    final parsed = parser.parse(
      filePath: 'generated-breaks.md',
      source: original,
      validateLocalReferences: false,
    );
    final ordinaryLink = parsed.busyDocument.blocks.single.inlines.firstWhere(
      (inline) => inline.kind == BusyInlineKind.link,
    );
    final context = const MarkdownAstAdapter().createInlineParserContext(
      documentSource: original,
      mode: MarkdownMode.commonMark,
    );

    final mapped = context.parseMappedBlock(
      marked,
      sourceStart: 0,
      sourceEnd: marked.length,
      ignoredReferenceLabelMarkers: const [marker],
    )!;
    final mappedLink = mapped.inlines.firstWhere(
      (inline) => inline.kind == BusyInlineKind.link,
    );
    final hardBreaks = mappedLink.children
        .where((inline) => inline.kind == BusyInlineKind.hardBreak)
        .toList(growable: false);
    final firstBreak = marked.indexOf('<br>');
    final secondBreak = marked.indexOf('<br>', firstBreak + 1);

    expect(ordinaryLink.plainText, 'A\n\nright');
    expect(mappedLink.plainText.replaceAll(marker, ''), ordinaryLink.plainText);
    expect(hardBreaks, hasLength(2));
    expect(mapped.ranges[hardBreaks.first]?.start, firstBreak);
    expect(mapped.ranges[hardBreaks.first]?.end, firstBreak + '<br>'.length);
    expect(mapped.ranges[hardBreaks.last]?.start, secondBreak);
    expect(mapped.ranges[hardBreaks.last]?.end, secondBreak + '<br>'.length);
    expect(mappedLink.destination, 'https://destination.test');
    expect(
      mapped.ranges[mappedLink]?.originalInline?.destination,
      'https://destination.test',
    );
    expect(
      mapped.ranges[mappedLink]?.lineBreaks.map(
        (lineBreak) => (
          lineBreak.lineEnding,
          lineBreak.continuationPrefix,
          lineBreak.sourceOffset,
        ),
      ),
      [
        ('\n', '', original.indexOf('\n', firstBreak)),
        ('\n', '', original.indexOf('\n', secondBreak)),
      ],
    );
  });

  test(
    'block inline mapping projects HTML break layout through containers',
    () {
      const marker = '\ue000';
      const original =
          '> [A\r\n'
          '> <br>\r\n'
          '> <br>\r\n'
          '> right](https://destination.test) tail';
      const marked =
          '> [A\r\n'
          '> <br>\r\n'
          '> <br>\r\n'
          '> ri${marker}ght](https://destination.test) tail';
      final parsed = parser.parse(
        filePath: 'generated-breaks.md',
        source: original,
        validateLocalReferences: false,
      );
      final ordinaryLink = parsed
          .busyDocument
          .blocks
          .single
          .children
          .single
          .inlines
          .firstWhere((inline) => inline.kind == BusyInlineKind.link);
      final context = const MarkdownAstAdapter().createInlineParserContext(
        documentSource: original,
        mode: MarkdownMode.commonMark,
      );

      final mapped = context.parseMappedBlock(
        marked,
        sourceStart: 0,
        sourceEnd: marked.length,
        ignoredReferenceLabelMarkers: const [marker],
      )!;
      final mappedLink = mapped.inlines.firstWhere(
        (inline) => inline.kind == BusyInlineKind.link,
      );

      expect(ordinaryLink.plainText, 'A\n\nright');
      expect(
        mappedLink.plainText.replaceAll(marker, ''),
        ordinaryLink.plainText,
      );
      expect(
        mappedLink.children.where(
          (inline) => inline.kind == BusyInlineKind.hardBreak,
        ),
        hasLength(2),
      );
      expect(
        mapped.ranges[mappedLink]?.lineBreaks.map(
          (lineBreak) => (lineBreak.lineEnding, lineBreak.continuationPrefix),
        ),
        const [('\r\n', '> '), ('\r\n', '> ')],
      );
      expect(
        mapped.ranges[mappedLink]?.originalInline?.destination,
        'https://destination.test',
      );
    },
  );

  test('HTML break layout mapping preserves soft breaks and literal code', () {
    const marker = '\ue000';
    const original =
        '> [left\n'
        '> `<br>`\n'
        '> right](https://destination.test)';
    const marked =
        '> [left\n'
        '> `<br>`\n'
        '> ri${marker}ght](https://destination.test)';
    final context = const MarkdownAstAdapter().createInlineParserContext(
      documentSource: original,
      mode: MarkdownMode.commonMark,
    );
    final ordinary = context.parse('left\n`<br>`\nright');

    final mapped = context.parseMappedBlock(
      marked,
      sourceStart: 0,
      sourceEnd: marked.length,
      ignoredReferenceLabelMarkers: const [marker],
    )!;
    final link = mapped.inlines.single;

    expect(
      link.plainText.replaceAll(marker, ''),
      ordinary.map((e) => e.plainText).join(),
    );
    expect(link.plainText, 'left\n<br>\nri${marker}ght');
    expect(
      link.children.where((inline) => inline.kind == BusyInlineKind.code),
      hasLength(1),
    );
    expect(
      link.children.where((inline) => inline.kind == BusyInlineKind.hardBreak),
      isEmpty,
    );
    expect(mapped.ranges[link]?.lineBreaks, hasLength(2));
    expect(mapped.ranges[link]?.originalInline, isNotNull);

    const hardBreakOriginal =
        '[left  \n'
        '<br>\n'
        'right](https://destination.test)';
    const hardBreakMarked =
        '[left  \n'
        '<br>\n'
        'ri${marker}ght](https://destination.test)';
    final hardBreakContext = const MarkdownAstAdapter()
        .createInlineParserContext(
          documentSource: hardBreakOriginal,
          mode: MarkdownMode.commonMark,
        );
    final hardBreakMapped = hardBreakContext.parseMappedBlock(
      hardBreakMarked,
      sourceStart: 0,
      sourceEnd: hardBreakMarked.length,
      ignoredReferenceLabelMarkers: const [marker],
    )!;
    final hardBreakLink = hardBreakMapped.inlines.single;
    expect(
      hardBreakLink.children.where(
        (inline) => inline.kind == BusyInlineKind.hardBreak,
      ),
      hasLength(2),
    );
    expect(
      hardBreakMapped.ranges[hardBreakLink]?.lineBreaks.map(
        (lineBreak) => lineBreak.sourceOffset,
      ),
      [
        hardBreakOriginal.indexOf('\n'),
        hardBreakOriginal.indexOf('\n', hardBreakOriginal.indexOf('<br>')),
      ],
    );
  });

  test('extracts title, outline, links, images, and code fences', () {
    final path = fixture('basic.md');
    final parsed = parser.parse(
      filePath: path,
      source: File(path).readAsStringSync(),
      workspaceRoot: 'test/fixtures/markdown',
    );

    expect(parsed.title, 'BusyMark Markdown Demo');
    expect(
      parsed.headings.map((item) => item.text),
      contains('12. Fenced Code Blocks'),
    );
    expect(
      parsed.headings
          .singleWhere((item) => item.text == '12. Fenced Code Blocks')
          .id,
      '12-fenced-code-blocks',
    );
    expect(
      parsed.links.map((item) => item.destination),
      contains('https://openai.com'),
    );
    expect(
      parsed.images.map((item) => item.destination),
      contains('https://picsum.photos/800/300'),
    );
    expect(parsed.codeBlocks.map((item) => item.language), contains('dart'));
  });

  test('extracts front matter title', () {
    final path = fixture('front_matter.md');
    final parsed = parser.parse(
      filePath: path,
      source: File(path).readAsStringSync(),
    );

    expect(parsed.title, 'Front Matter Title');
  });

  test('Writerside Markdown title comes from H1, not front matter', () {
    final parsed = parser.parse(
      filePath: 'guide.md',
      source: '---\ntitle: Front Matter\n---\n\n# Writerside H1\n',
      mode: MarkdownMode.writersideMarkdown,
    );

    expect(parsed.title, 'Writerside H1');
    expect(parsed.busyDocument.frontMatter['title'], 'Front Matter');
  });

  test('Writerside front matter title does not satisfy missing H1', () {
    final parsed = parser.parse(
      filePath: 'guide.md',
      source: '---\ntitle: Front Matter\n---\n',
      mode: MarkdownMode.writersideMarkdown,
    );

    expect(parsed.title, isNull);
    expect(
      parsed.diagnostics.map((diagnostic) => diagnostic.code),
      contains('writerside.topic.missing-title'),
    );
  });

  test('parseAsync handles documents above the background threshold', () async {
    final source = List.generate(
      1800,
      (index) => '## Section $index\n\nParagraph ${'content ' * 4}$index.\n',
    ).join('\n');

    final parsed = await parser.parseAsync(
      filePath: 'large.md',
      source: source,
      validateLocalReferences: false,
    );

    expect(source.length, greaterThan(64 * 1024));
    expect(parsed.source, source);
    expect(parsed.headings, hasLength(1800));
    expect(parsed.headings.last.text, 'Section 1799');
  });

  test('generates Unicode heading anchors for supported languages', () {
    final localizedHeadings = <String, ({String heading, String slug})>{
      'en': (heading: 'Getting Started', slug: 'getting-started'),
      'de': (heading: 'Überblick Änderungen', slug: 'überblick-änderungen'),
      'it': (heading: 'Novità rapide', slug: 'novità-rapide'),
      'no': (heading: 'Nøkkel område', slug: 'nøkkel-område'),
      'fr': (heading: 'État de l’art', slug: 'état-de-lart'),
      'ru': (heading: 'Быстрый старт', slug: 'быстрый-старт'),
      'uk': (heading: 'Швидкий старт', slug: 'швидкий-старт'),
      'pl': (heading: 'Zażółć gęślą jaźń', slug: 'zażółć-gęślą-jaźń'),
      'es': (heading: 'Guía rápida', slug: 'guía-rápida'),
      'pt': (heading: 'Visão geral', slug: 'visão-geral'),
      'ar': (heading: 'دليل البدء', slug: 'دليل-البدء'),
      'fa': (heading: 'راهنمای شروع', slug: 'راهنمای-شروع'),
      'hi': (heading: 'हिंदी दस्तावेज़', slug: 'हिंदी-दस्तावेज़'),
    };
    final source = localizedHeadings.entries
        .expand((entry) {
          final heading = entry.value.heading;
          final slug = entry.value.slug;
          return [
            '## $heading',
            '',
            '[${entry.key} raw](#$slug)',
            '[${entry.key} encoded](#${Uri.encodeComponent(slug)})',
            '',
          ];
        })
        .join('\n');

    final parsed = parser.parse(filePath: 'localized.md', source: source);
    final adapted = const MarkdownAstAdapter().parse(
      filePath: 'localized.md',
      source: source,
      mode: MarkdownMode.commonMark,
    );

    for (final MapEntry(key: locale, value: item)
        in localizedHeadings.entries) {
      expect(slugForHeading(item.heading), item.slug, reason: locale);
      expect(parsed.anchors, contains(item.slug), reason: locale);
      expect(
        adapted.blocks
            .where((block) => block.kind == BusyBlockKind.heading)
            .map((block) => block.attributes['id']),
        contains(item.slug),
        reason: locale,
      );
    }
    expect(
      parsed.diagnostics.map((item) => item.code),
      isNot(contains('markdown.link.unresolved-anchor')),
    );
  });

  test('deduplicates generated heading IDs in source order', () {
    final parsed = parser.parse(
      filePath: 'duplicates.md',
      source: '# Same\n\n# Same\n\n# !\n\n# ?\n',
    );

    expect(parsed.headings.map((heading) => heading.id), [
      'same',
      'same-1',
      'section',
      'section-1',
    ]);
  });

  test('generates heading IDs from semantic inline text', () {
    final parsed = parser.parse(
      filePath: 'formatted-heading.md',
      source:
          '# [Hello](https://example.com) and **friends** '
          '![Logo](logo.png)\n',
    );

    expect(parsed.headings.single.text, 'Hello and friends Logo');
    expect(parsed.headings.single.id, 'hello-and-friends-logo');
    expect(
      parsed.busyDocument.blocks
          .singleWhere((block) => block.kind == BusyBlockKind.heading)
          .attributes['id'],
      'hello-and-friends-logo',
    );
  });

  test('canonicalizes valid ATX and setext heading variants', () {
    final parsed = parser.parse(
      filePath: 'heading-variants.md',
      source:
          '   # [Indented](https://example.com) ###\n\n'
          '#\n\n'
          'Setext {id="stable"}\n'
          '====================\n',
    );

    expect(
      parsed.headings.map(
        (heading) =>
            (heading.level, heading.text, heading.id, heading.generatedId),
      ),
      [
        (1, 'Indented', 'indented', true),
        (1, '', 'section', true),
        (1, 'Setext', 'stable', false),
      ],
    );
  });

  test('retains Writerside title when complex list source needs fallback', () {
    final parsed = parser.parse(
      filePath: 'Wi-Fi-Interface.md',
      source: '''
# Wi-Fi Interface

## Development

1. Create the component.

    ```Bash
    idf.py create-component wi_fi_sta_interface -C components
    ```

2. Rename and move the source file. {collapsible="true"}

    1. Rename the file.
    2. Move it to the source folder.
3. Update the build file. {collapsible="true"}

    1. Add the required dependencies.

   The build file should look like this:

    ```CMake
    idf_component_register(SRCS "src/wi_fi_sta_interface.cpp")
    ```
   {collapsible="true" collapsed-title="CMakeLists.txt"}

## References
''',
      mode: MarkdownMode.writersideMarkdown,
    );

    expect(parsed.title, 'Wi-Fi Interface');
    expect(
      parsed.headings.map((heading) => heading.text),
      containsAll(['Wi-Fi Interface', 'Development', 'References']),
    );
    expect(
      parsed.diagnostics.map((diagnostic) => diagnostic.code),
      isNot(contains('writerside.topic.missing-title')),
    );
  });

  test('detects unresolved links, missing images, and missing alt text', () {
    final path = fixture('links_images.md');
    final parsed = parser.parse(
      filePath: path,
      source: File(path).readAsStringSync(),
      workspaceRoot: 'test/fixtures/markdown',
    );

    expect(
      parsed.diagnostics.map((item) => item.code),
      containsAll([
        'markdown.link.unresolved-target',
        'markdown.image.missing-file',
        'markdown.image.missing-alt',
      ]),
    );
  });

  test('does not validate schemed URIs as local references', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source:
          '[Ftp](ftp://example.com/doc.md)\n'
          '[Tel](tel:+15551234567)\n'
          '[Custom](docs://topic/intro)\n'
          '[File](file:///tmp/topic.md)\n'
          '[Script](javascript:alert(1))\n'
          '![Remote](ftp://example.com/logo.png)\n'
          '![Inline](data:image/png;base64,AAAA)\n',
      workspaceRoot: '/tmp/busymark-workspace',
    );
    final codes = parsed.diagnostics.map((item) => item.code);

    expect(codes, isNot(contains('markdown.link.unresolved-target')));
    expect(codes, isNot(contains('markdown.image.missing-file')));
    expect(codes, contains('markdown.raw-html.unsafe'));
  });

  test('resolves home-relative local image references', () {
    final fakeHome = Directory.systemTemp.createTempSync(
      'busymark_home_image_',
    );
    try {
      final downloads = Directory(p.join(fakeHome.path, 'Downloads'))
        ..createSync();
      File(p.join(downloads.path, 'example.jpg')).writeAsBytesSync([0]);
      final competingHome = Directory(p.join(fakeHome.path, 'snap-real-home'))
        ..createSync();
      debugLocalImageHomeDirectoryOverride = fakeHome.path;
      debugLocalImageEnvironmentOverride = {
        'SNAP_REAL_HOME': competingHome.path,
      };
      addTearDown(() {
        debugLocalImageHomeDirectoryOverride = null;
        debugLocalImageEnvironmentOverride = null;
      });

      final parsed = parser.parse(
        filePath: 'Untitled.md',
        source: '![Пример изображения](~/Downloads/example.jpg)\n',
      );

      expect(parsed.images.single.destination, '~/Downloads/example.jpg');
      expect(
        parsed.diagnostics.map((item) => item.code),
        isNot(contains('markdown.image.missing-file')),
      );
    } finally {
      debugLocalImageHomeDirectoryOverride = null;
      debugLocalImageEnvironmentOverride = null;
      fakeHome.deleteSync(recursive: true);
    }
  });

  test(
    'derives diagnostic links and images from Markdown AST semantics',
    () async {
      final root = await Directory.systemTemp.createTemp('busymark_ast_links_');
      addTearDown(() => root.deleteSync(recursive: true));
      Directory(p.join(root.path, 'docs')).createSync();
      File(p.join(root.path, 'target.md')).writeAsStringSync('# Target\n');
      File(p.join(root.path, 'docs', 'a(b).md')).writeAsStringSync('# Paren\n');
      File(
        p.join(root.path, 'docs', 'angle target.md'),
      ).writeAsStringSync('# Angle\n');
      File(p.join(root.path, 'logo.png')).writeAsBytesSync([0]);
      final path = p.join(root.path, 'topic.md');

      final parsed = await parser.parseAsync(
        filePath: path,
        workspaceRoot: root.path,
        source:
            '# AST links\n\n'
            '[Nested [label]](target.md)\n'
            '[Titled](target.md "Existing target")\n'
            '[Paren](docs/a(b).md)\n'
            '[Angle](<docs/angle target.md> "Existing target")\n'
            '![Logo][logo-ref]\n'
            '[Missing][missing-ref]\n\n'
            '[logo-ref]: logo.png "Logo title"\n'
            '[missing-ref]: missing.md\n',
      );

      expect(
        parsed.links.map((item) => item.destination),
        containsAll([
          'target.md',
          'docs/a(b).md',
          'docs/angle%20target.md',
          'missing.md',
        ]),
      );
      expect(parsed.images.single.destination, 'logo.png');
      expect(
        parsed.diagnostics
            .where((item) => item.code == 'markdown.link.unresolved-target')
            .map((item) => item.args['targetPath']),
        ['missing.md'],
      );
      expect(
        parsed.diagnostics.map((item) => item.code),
        isNot(contains('markdown.image.missing-file')),
      );
    },
  );

  test(
    'normal Markdown image diagnostics stay within the workspace root',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'busymark_writerside_',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      final topics = Directory(p.join(root.path, 'topics'))..createSync();
      final images = Directory(p.join(root.path, 'images', 'system-design'))
        ..createSync(recursive: true);
      final nestedImages = Directory(
        p.join(root.path, 'images', 'methodology', 'orchestrator-devices'),
      )..createSync(recursive: true);
      File(p.join(images.path, 'architecture.png')).writeAsBytesSync([0]);
      File(p.join(nestedImages.path, 'rpi_1.jpg')).writeAsBytesSync([0]);
      final topicPath = p.join(topics.path, 'System-Design.md');
      final parsed = parser.parse(
        filePath: topicPath,
        workspaceRoot: topics.path,
        source:
            '# System Design\n\n'
            '![Architecture Diagram](architecture.png){ width="500" }\n'
            '![Raspberry Pi Imager](rpi_1.jpg){ width="500" }\n',
      );

      expect(
        parsed.diagnostics.map((item) => item.code),
        contains('markdown.image.missing-file'),
      );
    },
  );

  test(
    'local reference diagnostics allow absolute images but reject other escapes',
    () async {
      final workspace = await Directory.systemTemp.createTemp(
        'busymark-reference-root-',
      );
      final outside = await Directory.systemTemp.createTemp(
        'busymark-reference-outside-',
      );
      addTearDown(() => workspace.deleteSync(recursive: true));
      addTearDown(() => outside.deleteSync(recursive: true));
      final outsideMarkdown = File(p.join(outside.path, 'outside.md'))
        ..writeAsStringSync('# Secret\n');
      final outsideImage = File(p.join(outside.path, 'outside.png'))
        ..writeAsBytesSync([0]);
      await Link(p.join(workspace.path, 'linked')).create(outside.path);
      final active = File(p.join(workspace.path, 'index.md'));
      final source =
          '# Index\n\n'
          '[Parent](../${p.basename(outside.path)}/outside.md#secret)\n'
          '[Absolute](${outsideMarkdown.path}#secret)\n'
          '[Symlink](linked/outside.md#secret)\n'
          '![Parent](../${p.basename(outside.path)}/outside.png)\n'
          '![Absolute](${outsideImage.path})\n'
          '![Symlink](linked/outside.png)\n';

      final parsed = await parser.parseAsync(
        filePath: active.path,
        source: source,
        workspaceRoot: workspace.path,
      );
      final linkTargets = parsed.diagnostics
          .where((item) => item.code == 'markdown.link.unresolved-target')
          .map((item) => item.args['targetPath'])
          .toList();
      final missingImages = parsed.diagnostics
          .where((item) => item.code == 'markdown.image.missing-file')
          .map((item) => item.args['destination'])
          .toList();

      expect(
        linkTargets,
        containsAll([
          '../${p.basename(outside.path)}/outside.md',
          outsideMarkdown.path,
          'linked/outside.md',
        ]),
      );
      expect(
        missingImages,
        containsAll([
          '../${p.basename(outside.path)}/outside.png',
          'linked/outside.png',
        ]),
      );
      expect(missingImages, isNot(contains(outsideImage.path)));
    },
    skip: Platform.isWindows
        ? 'POSIX symlink behavior is required for this coverage.'
        : false,
  );

  test(
    'cross-linked Markdown anchor validation does not recurse forever',
    () async {
      final path = fixture('cycle_a.md');
      final parsed = await parser.parseAsync(
        filePath: path,
        source: File(path).readAsStringSync(),
        workspaceRoot: 'test/fixtures/markdown',
      );

      expect(
        parsed.diagnostics.map((item) => item.code),
        isNot(contains('markdown.link.unresolved-anchor')),
      );
    },
  );

  test('local link validation stays inside the workspace root', () async {
    final root = await Directory.systemTemp.createTemp('busymark-link-scope-');
    addTearDown(() => root.deleteSync(recursive: true));
    final workspace = Directory(p.join(root.path, 'workspace'))..createSync();
    final secret = File(p.join(root.path, 'secret.md'))
      ..writeAsStringSync('# Secret\n');
    final path = p.join(workspace.path, 'topic.md');

    final parsed = await parser.parseAsync(
      filePath: path,
      source: '[Secret](../${p.basename(secret.path)}#secret)\n',
      workspaceRoot: workspace.path,
    );

    expect(
      parsed.diagnostics.map((item) => item.code),
      contains('markdown.link.unresolved-target'),
    );
  });

  test(
    'local link validation does not read unsupported anchor targets',
    () async {
      final root = Directory.systemTemp.createTempSync('busymark-link-binary-');
      addTearDown(() => root.deleteSync(recursive: true));
      final binary = File(p.join(root.path, 'binary.bin'))
        ..writeAsBytesSync([0xff, 0xfe, 0xfd]);
      final path = p.join(root.path, 'topic.md');

      final parsed = await parser.parseAsync(
        filePath: path,
        source: '[Binary](${p.basename(binary.path)}#anchor)\n',
        workspaceRoot: root.path,
      );

      expect(
        parsed.diagnostics.map((item) => item.code),
        isNot(contains('markdown.link.unresolved-anchor')),
      );
    },
  );

  test(
    'local link validation does not read oversized Markdown targets',
    () async {
      final root = Directory.systemTemp.createTempSync('busymark-link-large-');
      addTearDown(() => root.deleteSync(recursive: true));
      final large = File(p.join(root.path, 'large.md'))
        ..writeAsBytesSync([0xff, ...List<int>.filled(2 * 1024 * 1024, 0x61)]);
      final path = p.join(root.path, 'topic.md');

      final parsed = await parser.parseAsync(
        filePath: path,
        source: '[Large](${p.basename(large.path)}#anchor)\n',
        workspaceRoot: root.path,
      );

      expect(
        parsed.diagnostics.map((item) => item.code),
        isNot(contains('markdown.link.unresolved-anchor')),
      );
    },
  );

  test('detects unsafe raw HTML', () {
    final path = fixture('unsafe_html.md');
    final parsed = parser.parse(
      filePath: path,
      source: File(path).readAsStringSync(),
    );

    expect(
      parsed.diagnostics.map((item) => item.code),
      contains('markdown.raw-html.unsafe'),
    );
  });

  test('safe raw HTML does not produce unsafe diagnostics', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source:
          '<p>Hello <strong>bold</strong></p>\n\n'
          '<table><tr><td>A</td></tr></table>\n'
          '<blockquote cite="https://example.com">Quote</blockquote>\n'
          '<a href="https://example.com">Link</a>\n'
          '<img src="https://example.com/image.png" alt="Image">\n',
    );

    expect(
      parsed.diagnostics.map((diagnostic) => diagnostic.code),
      isNot(contains('markdown.raw-html.unsafe')),
    );
  });

  test('Markdown headings inside paired raw HTML are not outline headings', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '''
# Document

<div>

# Literal heading

</div>
''',
    );

    expect(parsed.headings.map((heading) => heading.text), ['Document']);
  });

  test('unsafe raw HTML tags produce unsafe diagnostics', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source:
          '<script>alert(1)</script>\n'
          '<iframe src="https://example.com"></iframe>\n'
          '<form><input name="x"></form>\n',
    );

    expect(
      parsed.diagnostics
          .where((diagnostic) => diagnostic.code == 'markdown.raw-html.unsafe')
          .length,
      3,
    );
  });

  test('unsafe raw HTML attributes produce unsafe diagnostics', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '<p onclick="alert(1)">Click</p>\n',
    );

    expect(
      parsed.diagnostics.map((diagnostic) => diagnostic.code),
      contains('markdown.raw-html.unsafe'),
    );
  });

  test('unsafe raw HTML URLs produce unsafe diagnostics', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source:
          '<a href="javascript:alert(1)">bad</a>\n'
          '<img src="vbscript:alert(1)">\n'
          '<img src="data:image/png;base64,AAAA">\n'
          '<img src="/home/albert/private.png">\n'
          '<img src="file:///home/albert/private.png">\n'
          '<a href="ftp://example.com/private.md">ftp</a>\n'
          '<a href="docs://topic/intro">custom</a>\n'
          '<a href="//example.com/path">protocol relative</a>\n',
    );

    expect(
      parsed.diagnostics
          .where((diagnostic) => diagnostic.code == 'markdown.raw-html.unsafe')
          .length,
      8,
    );
  });

  test('deeply nested raw HTML produces unsafe diagnostic', () {
    final source =
        '${List.filled(120, '<div>').join()}Deep${List.filled(120, '</div>').join()}\n';
    final parsed = parser.parse(filePath: 'topic.md', source: source);

    expect(
      parsed.diagnostics.map((diagnostic) => diagnostic.code),
      contains('markdown.raw-html.unsafe'),
    );
  });

  test('safe HTML tags do not become Writerside XML blocks', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source:
          '<table>\n'
          '<tr><td>A</td></tr>\n'
          '</table>\n'
          '<section><p>Intro</p></section>\n'
          '<var name="product" value="BusyMark"/>\n'
          '<tabs>\n',
      mode: MarkdownMode.writersideMarkdown,
    );

    expect(
      parsed.xmlBlocks.map((block) => block.elementName.toLowerCase()),
      containsAll(['var', 'tabs']),
    );
    expect(
      parsed.xmlBlocks.map((block) => block.elementName.toLowerCase()),
      isNot(containsAll(['table', 'tr', 'section'])),
    );
  });

  test('extracts Writerside Markdown XML blocks and variables', () {
    final path = fixture('writerside_markdown.md');
    final parsed = parser.parse(
      filePath: path,
      source: File(path).readAsStringSync(),
      mode: MarkdownMode.writersideMarkdown,
    );

    expect(
      parsed.xmlBlocks.map((item) => item.elementName),
      containsAll(['var', 'tabs']),
    );
    expect(parsed.variables.map((item) => item.name), contains('product'));
  });

  test('emits deterministic Markdown accessibility diagnostics', () {
    final parsed = parser.parse(
      filePath: 'accessibility.md',
      source: '''# Guide

### Skipped level

[](empty.md)

[Click here](details.md)

| Name | |
| --- | --- |
| BusyMark | Editor |
''',
      mode: MarkdownMode.gfm,
      validateLocalReferences: false,
    );
    final byCode = {for (final item in parsed.diagnostics) item.code: item};

    expect(byCode, contains('markdown.heading.skipped-level'));
    expect(byCode, contains('markdown.link.empty-text'));
    expect(byCode, contains('markdown.link.review-text'));
    expect(
      byCode['markdown.link.review-text']?.severity,
      DiagnosticSeverity.hint,
    );
    expect(byCode, contains('markdown.table.empty-header'));
    expect(byCode['markdown.table.empty-header']?.sourceSpan?.startLine, 9);
  });

  test('does not report populated table headers as empty', () {
    final parsed = parser.parse(
      filePath: 'table.md',
      source: '''# Formatting

| Formatting | Markdown | Result |
| --- | --- | --- |
| Bold text | `**text**` | **text** |
| Italic text | `*text*` | *text* |
''',
      mode: MarkdownMode.gfm,
      validateLocalReferences: false,
    );

    expect(
      parsed.diagnostics.where(
        (diagnostic) => diagnostic.code == 'markdown.table.empty-header',
      ),
      isEmpty,
    );
  });
}
