import 'package:html/dom.dart' as html;
import 'package:html/parser.dart' as html_parser;
// The public parser does not expose authored closing-tag spans. Its tokenizer
// is the parser's own location-aware boundary source, not a second HTML parser.
// ignore: implementation_imports
import 'package:html/src/token.dart' as html_token;
// ignore: implementation_imports
import 'package:html/src/tokenizer.dart' as html_tokenizer;

import '../core/path_utils.dart';
import 'busymark_document.dart';
import 'raw_html_policy.dart';

/// Reports one indexed ownership lookup per semantic HTML break while source
/// metadata is collected. Tests use this to guard against per-break rescans.
void Function(int lookups)? debugBusyMarkStandaloneBreakLayoutLookups;

final RegExp _htmlWhitespaceUnit = RegExp(r'\s');

class RawHtmlBlockParseResult {
  const RawHtmlBlockParseResult({required this.safe, this.blocks = const []});

  final bool safe;
  final List<BusyBlock> blocks;
}

class RawHtmlInlineSourceRange {
  const RawHtmlInlineSourceRange({
    required this.start,
    required this.end,
    this.opening,
    this.closing,
    this.sourceLineBreakOffset,
  });

  final int start;
  final int end;
  final String? opening;
  final String? closing;
  final int? sourceLineBreakOffset;
}

class RawHtmlInlineParseResult {
  RawHtmlInlineParseResult({
    required this.inlines,
    required Map<BusyInline, RawHtmlInlineSourceRange> ranges,
  }) : ranges = Map.unmodifiable(ranges);

  final List<BusyInline> inlines;
  final Map<BusyInline, RawHtmlInlineSourceRange> ranges;
}

class RawHtmlAdapter {
  const RawHtmlAdapter();

  RawHtmlBlockParseResult? parseRawHtmlBlock(
    String rawSource,
    String Function() nextId,
  ) {
    if (!_mayContainHtml(rawSource)) {
      return null;
    }
    final fragment = _parseFragment(rawSource);
    if (fragment == null) {
      return null;
    }
    final elementScan = _HtmlElementScanState();
    if (!_hasElement(fragment.nodes, state: elementScan)) {
      return elementScan.exceeded
          ? const RawHtmlBlockParseResult(safe: false)
          : null;
    }
    if (!_isSafeFragment(fragment, inlineOnly: false)) {
      return const RawHtmlBlockParseResult(safe: false);
    }
    final blocks = _blocksFromNodes(fragment.nodes, nextId);
    return RawHtmlBlockParseResult(safe: true, blocks: blocks);
  }

  List<BusyInline>? parseRawHtmlInlineFragment(String text) {
    if (!_mayContainHtml(text)) return null;
    final normalized = _HtmlSourceProjection.create(
      text,
      standaloneBreakLayoutRemovals(text),
    ).normalized;
    final fragment = _parseFragment(normalized);
    if (fragment == null) return null;
    final elementScan = _HtmlElementScanState();
    if (!_hasElement(fragment.nodes, state: elementScan) ||
        !_isSafeFragment(fragment, inlineOnly: true)) {
      return null;
    }
    return _trimInlineEdges(_inlinesFromNodes(fragment.nodes));
  }

  /// Parses a complete safe inline HTML fragment and records the authored
  /// occurrence occupied by each semantic inline element.
  ///
  /// The HTML parser's element span covers its opening tag, not necessarily
  /// its closing tag. Closing extents are therefore paired from the same HTML
  /// tokenizer that feeds the parser. Repaired or inferred DOM nodes without
  /// authored spans deliberately receive no source range.
  RawHtmlInlineParseResult? parseRawHtmlInlineFragmentWithMetadata(
    String text, {
    String? sourceText,
    Iterable<String> ignoredPositionMarkers = const [],
  }) {
    if (!_mayContainHtml(text)) {
      return null;
    }
    final source = sourceText ?? text;
    final positionMarkers = ignoredPositionMarkers
        .where((marker) => marker.isNotEmpty)
        .toList(growable: false);
    final layoutRemovals = _mappedStandaloneBreakLayoutRemovals(
      source,
      positionMarkers,
    );
    final projection = _HtmlSourceProjection.create(
      source,
      layoutRemovals,
      parserText: text,
    );
    final fragment = _parseFragment(projection.normalized, generateSpans: true);
    if (fragment == null) {
      return null;
    }
    final elementScan = _HtmlElementScanState();
    if (!_hasElement(fragment.nodes, state: elementScan)) {
      return null;
    }
    if (!_isSafeFragment(fragment, inlineOnly: true)) {
      return null;
    }
    final context = _RawHtmlInlineMappingContext(
      projection: projection,
      authoredClosingsByOpeningStart: _authoredElementClosingsByOpeningStart(
        projection.normalized,
      ),
      layout: _StandaloneBreakLayoutIndex(layoutRemovals),
      positionMarkers: positionMarkers,
    );
    return RawHtmlInlineParseResult(
      inlines: _trimInlineEdges(
        _inlinesFromNodes(fragment.nodes, mapping: context),
        ranges: context.ranges,
        ignoredPositionMarkers: positionMarkers,
      ),
      ranges: context.ranges,
    );
  }

  List<({int start, int end, int lineFeedOffset})>
  _mappedStandaloneBreakLayoutRemovals(
    String source,
    Iterable<String> ignoredMarkers,
  ) {
    final markers = ignoredMarkers
        .where((marker) => marker.isNotEmpty)
        .toList(growable: false);
    if (markers.isEmpty) return standaloneBreakLayoutRemovals(source);
    final unmarked = StringBuffer();
    final starts = <int>[];
    final ends = <int>[];
    var offset = 0;
    while (offset < source.length) {
      final marker = markers.firstWhere(
        (candidate) => source.startsWith(candidate, offset),
        orElse: () => '',
      );
      if (marker.isNotEmpty) {
        offset += marker.length;
        continue;
      }
      unmarked.writeCharCode(source.codeUnitAt(offset));
      starts.add(offset);
      ends.add(offset + 1);
      offset += 1;
    }
    final removals = standaloneBreakLayoutRemovals(unmarked.toString());
    return [
      for (final removal in removals)
        if (removal.start < starts.length && removal.end > 0)
          (
            start: starts[removal.start],
            end: ends[removal.end - 1],
            lineFeedOffset: starts[removal.lineFeedOffset],
          ),
    ];
  }

  /// Source ranges which are layout around standalone `<br>` tags rather
  /// than additional semantic line breaks.
  ///
  /// Source mapping consumes these exact ranges while recording the real
  /// `<br>` occurrence separately. Keeping this classification here ensures
  /// mapped parsing and ordinary raw-HTML parsing use the same rule.
  List<({int start, int end, int lineFeedOffset})>
  standaloneBreakLayoutRemovals(String source) {
    final byLineFeed = <int, ({int start, int end, int lineFeedOffset})>{};

    void add(int start, int end) {
      final lineFeedOffset = source.indexOf('\n', start);
      if (lineFeedOffset < 0 || lineFeedOffset >= end) return;
      final existing = byLineFeed[lineFeedOffset];
      byLineFeed[lineFeedOffset] = (
        start: existing == null
            ? start
            : existing.start < start
            ? existing.start
            : start,
        end: existing == null
            ? end
            : existing.end > end
            ? existing.end
            : end,
        lineFeedOffset: lineFeedOffset,
      );
    }

    // Token spans, rather than a lexical `<br>` search, decide which text is
    // an actual HTML break. Tag-looking attribute values and comments must not
    // alter whitespace classification.
    final tokenizer = html_tokenizer.HtmlTokenizer(source, generateSpans: true);
    while (tokenizer.moveNext()) {
      final token = tokenizer.current;
      final span = token.span;
      if (token is! html_token.StartTagToken ||
          token.name?.toLowerCase() != 'br' ||
          span == null) {
        continue;
      }
      var before = span.start.offset;
      while (before > 0) {
        final unit = source.codeUnitAt(before - 1);
        if (unit != 0x20 && unit != 0x09) break;
        before -= 1;
      }
      if (before > 0 && source.codeUnitAt(before - 1) == 0x0a) {
        var lineStart = before - 1;
        if (lineStart > 0 && source.codeUnitAt(lineStart - 1) == 0x0d) {
          lineStart -= 1;
        }
        add(lineStart, span.start.offset);
      }

      final after = span.end.offset;
      if (after < source.length && source.codeUnitAt(after) == 0x0a) {
        add(after, after + 1);
      } else if (after + 1 < source.length &&
          source.codeUnitAt(after) == 0x0d &&
          source.codeUnitAt(after + 1) == 0x0a) {
        add(after, after + 2);
      }
    }
    final result = byLineFeed.values.toList()
      ..sort((left, right) => left.start.compareTo(right.start));
    return result;
  }

  html.DocumentFragment? _parseFragment(
    String source, {
    bool generateSpans = false,
  }) {
    try {
      return html_parser.parseFragment(source, generateSpans: generateSpans);
    } on Object {
      return null;
    }
  }

  Map<int, ({int start, int end})> _authoredElementClosingsByOpeningStart(
    String source,
  ) {
    final closings = <int, ({int start, int end})>{};
    final stack = <({String name, int start})>[];
    final tokenizer = html_tokenizer.HtmlTokenizer(source, generateSpans: true);
    while (tokenizer.moveNext()) {
      final token = tokenizer.current;
      final span = token.span;
      if (span == null) continue;
      if (token is html_token.StartTagToken) {
        final name = token.name?.toLowerCase() ?? '';
        if (token.selfClosing || voidHtmlTags.contains(name)) {
          closings[span.start.offset] = (
            start: span.end.offset,
            end: span.end.offset,
          );
        } else {
          stack.add((name: name, start: span.start.offset));
        }
        continue;
      }
      if (token is! html_token.EndTagToken) continue;
      final name = token.name?.toLowerCase() ?? '';
      final match = stack.lastIndexWhere((entry) => entry.name == name);
      if (match < 0) continue;
      final opening = stack[match];
      stack.removeRange(match, stack.length);
      closings[opening.start] = (
        start: span.start.offset,
        end: span.end.offset,
      );
    }
    return closings;
  }

  bool _isSafeFragment(
    html.Node node, {
    required bool inlineOnly,
    int depth = 0,
    _HtmlWalkState? state,
  }) {
    state ??= _HtmlWalkState();
    for (final child in node.nodes) {
      if (!_isSafeNode(
        child,
        inlineOnly: inlineOnly,
        depth: depth + 1,
        state: state,
      )) {
        return false;
      }
    }
    return true;
  }

  bool _isSafeNode(
    html.Node node, {
    required bool inlineOnly,
    required int depth,
    required _HtmlWalkState state,
  }) {
    if (!state.visit(depth)) {
      return false;
    }
    if (node is! html.Element) {
      return true;
    }
    final tag = node.localName?.toLowerCase() ?? '';
    if (!isSafeHtmlTag(tag)) {
      return false;
    }
    if (inlineOnly && !isSafeInlineHtmlTag(tag)) {
      return false;
    }
    if (sanitizeHtmlAttributes(tag, node.attributes) == null) {
      return false;
    }
    return _isSafeFragment(
      node,
      inlineOnly: inlineOnly,
      depth: depth,
      state: state,
    );
  }

  List<BusyBlock> _blocksFromNodes(
    Iterable<html.Node> nodes,
    String Function() nextId,
  ) {
    final blocks = <BusyBlock>[];
    final inlineBuffer = <BusyInline>[];

    void flushInlineBuffer() {
      final inlines = _trimInlineEdges(inlineBuffer);
      inlineBuffer.clear();
      if (inlines.isEmpty) {
        return;
      }
      blocks.add(
        BusyBlock(
          id: nextId(),
          kind: BusyBlockKind.paragraph,
          inlines: inlines,
        ),
      );
    }

    for (final node in nodes) {
      if (node is html.Text) {
        if (node.data.trim().isNotEmpty) {
          _appendInlineText(inlineBuffer, _collapseHtmlWhitespace(node.data));
        }
        continue;
      }
      if (node is! html.Element) {
        continue;
      }
      final tag = node.localName?.toLowerCase() ?? '';
      if (tag == 'img') {
        flushInlineBuffer();
        blocks.addAll(_blocksFromElement(node, nextId));
        continue;
      }
      if (isSafeInlineHtmlTag(tag) && !isSafeBlockHtmlTag(tag)) {
        inlineBuffer.addAll(_inlineFromElement(node));
        continue;
      }
      flushInlineBuffer();
      blocks.addAll(_blocksFromElement(node, nextId));
    }
    flushInlineBuffer();
    return blocks;
  }

  List<BusyBlock> _blocksFromElement(
    html.Element element,
    String Function() nextId,
  ) {
    final tag = element.localName?.toLowerCase() ?? '';
    final attributes = sanitizeHtmlAttributes(tag, element.attributes) ?? {};
    final children = element.nodes;
    final text = _plainTextFromNodes(children).trim();

    if (_headingLevel(tag) case final level?) {
      final anchorId = attributes['id'] ?? slugForHeading(text);
      return _applyHtmlDirection([
        BusyBlock(
          id: nextId(),
          kind: BusyBlockKind.heading,
          inlines: _trimInlineEdges(_inlinesFromNodes(children)),
          attributes: {
            ...attributes,
            'level': '$level',
            'id': anchorId,
            'generatedId': '${attributes['id'] == null}',
          },
        ),
      ], attributes['dir']);
    }

    final List<BusyBlock> blocks = switch (tag) {
      'article' ||
      'aside' ||
      'div' ||
      'section' ||
      'header' ||
      'footer' ||
      'main' ||
      'nav' ||
      'details' => _blocksFromNodes(children, nextId),
      'figure' => _figureBlocksFromElement(attributes, children, nextId),
      'p' || 'address' || 'figcaption' || 'summary' || 'caption' => [
        BusyBlock(
          id: nextId(),
          kind: BusyBlockKind.paragraph,
          inlines: _trimInlineEdges(_inlinesFromNodes(children)),
          attributes: {'htmlTag': tag, ...attributes},
        ),
      ],
      'blockquote' => [
        BusyBlock(
          id: nextId(),
          kind: BusyBlockKind.blockquote,
          children: _blocksFromNodes(children, nextId),
          attributes: attributes,
        ),
      ],
      'hr' => [
        BusyBlock(
          id: nextId(),
          kind: BusyBlockKind.thematicBreak,
          attributes: attributes,
        ),
      ],
      'pre' => [_codeBlockFromPre(element, attributes, nextId)],
      'ul' || 'ol' => _listBlocksFromElement(
        element,
        ordered: tag == 'ol',
        nextId: nextId,
      ),
      'li' => [
        _listItemFromElement(
          element,
          ordered: false,
          marker: '-',
          nextId: nextId,
        ),
      ],
      'dl' => _descriptionListBlocks(element, nextId),
      'dt' || 'dd' => [
        BusyBlock(
          id: nextId(),
          kind: BusyBlockKind.paragraph,
          inlines: _trimInlineEdges(_inlinesFromNodes(children)),
          attributes: {'htmlTag': tag, ...attributes},
        ),
      ],
      'table' => _tableBlocksFromElement(element, attributes, nextId),
      'img' => [_imageBlockFromElement(element, attributes, nextId)],
      'thead' || 'tbody' || 'tfoot' || 'tr' || 'th' || 'td' => const [],
      'colgroup' || 'col' => const [],
      _ =>
        isSafeInlineHtmlTag(tag)
            ? [
                BusyBlock(
                  id: nextId(),
                  kind: BusyBlockKind.paragraph,
                  inlines: _inlineFromElement(element),
                  attributes: {'htmlTag': tag, ...attributes},
                ),
              ]
            : const [],
    };
    return _applyHtmlDirection(blocks, attributes['dir']);
  }

  List<BusyBlock> _applyHtmlDirection(
    List<BusyBlock> blocks,
    String? inheritedDirection,
  ) {
    final normalizedDirection = _normalizedHtmlDirection(inheritedDirection);
    if (normalizedDirection == null) {
      return blocks;
    }
    BusyBlock visit(BusyBlock block, String direction) {
      final blockDirection =
          _normalizedHtmlDirection(block.attributes['dir']) ?? direction;
      return block.copyWith(
        attributes: {...block.attributes, 'dir': blockDirection},
        children: [
          for (final child in block.children) visit(child, blockDirection),
        ],
      );
    }

    return [for (final block in blocks) visit(block, normalizedDirection)];
  }

  String? _normalizedHtmlDirection(String? value) {
    final normalized = value?.trim().toLowerCase();
    return switch (normalized) {
      'ltr' || 'rtl' || 'auto' => normalized,
      _ => null,
    };
  }

  List<BusyBlock> _figureBlocksFromElement(
    Map<String, String> attributes,
    Iterable<html.Node> children,
    String Function() nextId,
  ) {
    final childBlocks = _blocksFromNodes(children, nextId);
    if (childBlocks.isEmpty) {
      return const [];
    }
    return [
      BusyBlock(
        id: nextId(),
        kind: BusyBlockKind.htmlBlock,
        children: childBlocks,
        attributes: {
          'sourceFormat': 'html',
          'htmlTag': 'figure',
          ...attributes,
        },
      ),
    ];
  }

  BusyBlock _codeBlockFromPre(
    html.Element element,
    Map<String, String> attributes,
    String Function() nextId,
  ) {
    final code = element.children.firstWhere(
      (child) => child.localName?.toLowerCase() == 'code',
      orElse: () => element,
    );
    final className = code.attributes['class'] ?? attributes['class'] ?? '';
    final language = className
        .split(RegExp(r'\s+'))
        .where((name) => name.startsWith('language-'))
        .map((name) => name.substring('language-'.length))
        .firstOrNull;
    return BusyBlock(
      id: nextId(),
      kind: BusyBlockKind.codeBlock,
      inlines: [BusyInline(kind: BusyInlineKind.text, text: code.text)],
      attributes: {
        ...attributes,
        if (language != null && language.isNotEmpty) 'language': language,
      },
    );
  }

  List<BusyBlock> _listBlocksFromElement(
    html.Element element, {
    required bool ordered,
    required String Function() nextId,
  }) {
    final attributes =
        sanitizeHtmlAttributes(element.localName ?? '', element.attributes) ??
        {};
    final start = int.tryParse(attributes['start'] ?? '') ?? 1;
    var number = start;
    return [
      for (final child in element.children)
        if (child.localName?.toLowerCase() == 'li')
          _listItemFromElement(
            child,
            ordered: ordered,
            marker: ordered ? '${number++}.' : '-',
            nextId: nextId,
            parentAttributes: attributes,
          ),
    ];
  }

  BusyBlock _listItemFromElement(
    html.Element element, {
    required bool ordered,
    required String marker,
    required String Function() nextId,
    Map<String, String> parentAttributes = const {},
  }) {
    final attributes = sanitizeHtmlAttributes('li', element.attributes) ?? {};
    final inlines = <BusyInline>[];
    final nestedBlocks = <BusyBlock>[];
    for (final child in element.nodes) {
      if (child is html.Text) {
        if (child.data.trim().isNotEmpty) {
          _appendInlineText(inlines, _collapseHtmlWhitespace(child.data));
        }
        continue;
      }
      if (child is! html.Element) {
        continue;
      }
      final tag = child.localName?.toLowerCase() ?? '';
      if (isSafeInlineHtmlTag(tag) && !isSafeBlockHtmlTag(tag)) {
        inlines.addAll(_inlineFromElement(child));
      } else if (tag == 'p' && inlines.isEmpty && nestedBlocks.isEmpty) {
        inlines.addAll(_inlinesFromNodes(child.nodes));
      } else {
        nestedBlocks.addAll(_blocksFromElement(child, nextId));
      }
    }
    return BusyBlock(
      id: nextId(),
      kind: ordered
          ? BusyBlockKind.orderedListItem
          : BusyBlockKind.unorderedListItem,
      inlines: _trimInlineEdges(inlines),
      children: nestedBlocks,
      attributes: {
        ...parentAttributes,
        ...attributes,
        'ordered': '$ordered',
        'marker': attributes['value'] ?? marker,
      },
    );
  }

  List<BusyBlock> _descriptionListBlocks(
    html.Element element,
    String Function() nextId,
  ) {
    return [
      for (final child in element.children)
        if (child.localName == 'dt' || child.localName == 'dd')
          ..._blocksFromElement(child, nextId),
    ];
  }

  List<BusyBlock> _tableBlocksFromElement(
    html.Element table,
    Map<String, String> attributes,
    String Function() nextId,
  ) {
    final blocks = <BusyBlock>[];
    for (final caption in table.children.where(
      (child) => child.localName?.toLowerCase() == 'caption',
    )) {
      final captionAttributes =
          sanitizeHtmlAttributes('caption', caption.attributes) ?? const {};
      blocks.add(
        BusyBlock(
          id: nextId(),
          kind: BusyBlockKind.paragraph,
          inlines: _trimInlineEdges(_inlinesFromNodes(caption.nodes)),
          attributes: {'htmlTag': 'caption', ...captionAttributes},
        ),
      );
    }
    blocks.add(
      BusyBlock(
        id: nextId(),
        kind: BusyBlockKind.table,
        children: _tableRows(table, nextId),
        attributes: attributes,
      ),
    );
    return blocks;
  }

  List<BusyBlock> _tableRows(html.Element table, String Function() nextId) {
    final rows = <BusyBlock>[];
    void addRow(
      html.Element row, {
      required bool sectionHeader,
      String? inheritedDirection,
    }) {
      final cells = row.children.where((child) {
        final tag = child.localName?.toLowerCase();
        return tag == 'th' || tag == 'td';
      }).toList();
      if (cells.isEmpty) {
        return;
      }
      final allHeaderCells = cells.every(
        (cell) => cell.localName?.toLowerCase() == 'th',
      );
      final rowAttributes =
          sanitizeHtmlAttributes('tr', row.attributes) ?? const {};
      final rowDirection =
          _normalizedHtmlDirection(rowAttributes['dir']) ?? inheritedDirection;
      final rowBlock = BusyBlock(
        id: nextId(),
        kind: BusyBlockKind.table,
        attributes: {
          'header': '${sectionHeader || allHeaderCells}',
          if (rowDirection != null) 'dir': rowDirection,
        },
        children: [
          for (final cell in cells)
            BusyBlock(
              id: nextId(),
              kind: BusyBlockKind.paragraph,
              inlines: _trimInlineEdges(_inlinesFromNodes(cell.nodes)),
              attributes: _tableCellAttributes(cell),
            ),
        ],
      );
      rows.add(
        rowDirection == null
            ? rowBlock
            : _applyHtmlDirection([rowBlock], rowDirection).single,
      );
    }

    for (final child in table.children) {
      final tag = child.localName?.toLowerCase();
      if (tag == 'tr') {
        addRow(child, sectionHeader: false);
      } else if (tag == 'thead' || tag == 'tbody' || tag == 'tfoot') {
        final sectionAttributes =
            sanitizeHtmlAttributes(tag ?? '', child.attributes) ?? const {};
        final sectionDirection = _normalizedHtmlDirection(
          sectionAttributes['dir'],
        );
        for (final row in child.children.where(
          (candidate) => candidate.localName?.toLowerCase() == 'tr',
        )) {
          addRow(
            row,
            sectionHeader: tag == 'thead',
            inheritedDirection: sectionDirection,
          );
        }
      }
    }
    return rows;
  }

  Map<String, String> _tableCellAttributes(html.Element cell) {
    final tag = cell.localName?.toLowerCase() ?? 'td';
    final sanitized = sanitizeHtmlAttributes(tag, cell.attributes) ?? {};
    return {
      'cell': tag,
      for (final name in ['align', 'colspan', 'rowspan', 'scope', 'dir'])
        if (sanitized[name] case final value?) name: value,
    };
  }

  BusyBlock _imageBlockFromElement(
    html.Element element,
    Map<String, String> attributes,
    String Function() nextId,
  ) {
    return BusyBlock(
      id: nextId(),
      kind: BusyBlockKind.image,
      inlines: [
        BusyInline(
          kind: BusyInlineKind.image,
          text: attributes['alt'] ?? '',
          destination: attributes['src'],
          attributes: attributes,
        ),
      ],
      attributes: {
        ...attributes,
        if (attributes['src'] case final source?) 'src': source,
      },
    );
  }

  List<BusyInline> _inlinesFromNodes(
    Iterable<html.Node> nodes, {
    _RawHtmlInlineMappingContext? mapping,
  }) {
    return [
      for (final node in nodes) ..._inlineFromNode(node, mapping: mapping),
    ];
  }

  List<BusyInline> _inlineFromNode(
    html.Node node, {
    _RawHtmlInlineMappingContext? mapping,
  }) {
    if (node is html.Text) {
      if (node.data.isEmpty) {
        return const [];
      }
      final text = _collapseHtmlWhitespace(
        node.data,
        ignoredPositionMarkers: mapping?.positionMarkers ?? const [],
      );
      if (text.trim().isEmpty) {
        return const [];
      }
      return [BusyInline(kind: BusyInlineKind.text, text: text)];
    }
    if (node is html.Element) {
      return _inlineFromElement(node, mapping: mapping);
    }
    return const [];
  }

  List<BusyInline> _inlineFromElement(
    html.Element element, {
    _RawHtmlInlineMappingContext? mapping,
  }) {
    final tag = element.localName?.toLowerCase() ?? '';
    final attributes = sanitizeHtmlAttributes(tag, element.attributes) ?? {};
    final children = _trimInlineEdges(
      _inlinesFromNodes(element.nodes, mapping: mapping),
      ranges: mapping?.ranges,
      ignoredPositionMarkers: mapping?.positionMarkers ?? const [],
    );
    final text = _plainText(children);
    final List<BusyInline> result = switch (tag) {
      'strong' || 'b' => [
        BusyInline(kind: BusyInlineKind.strong, text: text, children: children),
      ],
      'em' || 'i' => [
        BusyInline(
          kind: BusyInlineKind.emphasis,
          text: text,
          children: children,
        ),
      ],
      'u' => [
        BusyInline(
          kind: BusyInlineKind.underline,
          text: text,
          children: children,
        ),
      ],
      's' || 'del' => [
        BusyInline(
          kind: BusyInlineKind.strikethrough,
          text: text,
          children: children,
          attributes: attributes,
        ),
      ],
      'code' || 'kbd' || 'samp' => [
        BusyInline(
          kind: BusyInlineKind.code,
          text: element.text,
          attributes: attributes,
        ),
      ],
      'a' => [
        if (attributes['href'] case final href?)
          BusyInline(
            kind: BusyInlineKind.link,
            text: text,
            destination: href,
            children: children,
            attributes: attributes,
          )
        else
          ...children,
      ],
      'img' => [
        BusyInline(
          kind: BusyInlineKind.image,
          text: attributes['alt'] ?? '',
          destination: attributes['src'],
          attributes: attributes,
        ),
      ],
      'br' => [BusyInline(kind: BusyInlineKind.hardBreak, text: '\n')],
      'wbr' => const [],
      _ =>
        children.isEmpty
            ? [
                if (text.isNotEmpty)
                  BusyInline(
                    kind: BusyInlineKind.text,
                    text: text,
                    attributes: attributes,
                  ),
              ]
            : children,
    };
    final span = element.sourceSpan;
    if (mapping != null && span != null && result.length == 1) {
      final normalizedStart = span.start.offset;
      final authoredClosing =
          mapping.authoredClosingsByOpeningStart[normalizedStart];
      final normalizedEnd = authoredClosing?.end ?? span.end.offset;
      final start = mapping.projection.rawStartFor(normalizedStart);
      final end = mapping.projection.rawEndFor(normalizedEnd);
      final openingEnd = mapping.projection.rawEndFor(span.end.offset);
      final closingStart = authoredClosing == null
          ? null
          : mapping.projection.rawStartFor(authoredClosing.start);
      mapping.ranges[result.single] = RawHtmlInlineSourceRange(
        start: start,
        end: end,
        opening: mapping.projection.source.substring(start, openingEnd),
        closing: closingStart == null || closingStart >= end
            ? null
            : mapping.projection.source.substring(closingStart, end),
        sourceLineBreakOffset: tag == 'br'
            ? mapping.layout.claimForBreak(start, end)
            : null,
      );
    }
    return result;
  }

  List<BusyInline> _trimInlineEdges(
    List<BusyInline> inlines, {
    Map<BusyInline, RawHtmlInlineSourceRange>? ranges,
    Iterable<String> ignoredPositionMarkers = const [],
  }) {
    if (inlines.isEmpty) {
      return const [];
    }
    final result = [...inlines];
    if (result.first.kind == BusyInlineKind.text) {
      final previous = result.first;
      result[0] = previous.copyWith(
        text: _trimHtmlTextEdge(
          previous.text,
          ignoredPositionMarkers,
          left: true,
        ),
      );
      final range = ranges?.remove(previous);
      if (range != null) ranges![result[0]] = range;
    }
    if (result.last.kind == BusyInlineKind.text) {
      final previous = result.last;
      result[result.length - 1] = previous.copyWith(
        text: _trimHtmlTextEdge(
          previous.text,
          ignoredPositionMarkers,
          left: false,
        ),
      );
      final range = ranges?.remove(previous);
      if (range != null) ranges![result.last] = range;
    }
    return [
      for (final inline in result)
        if (inline.kind != BusyInlineKind.text || inline.text.isNotEmpty)
          inline,
    ];
  }

  void _appendInlineText(List<BusyInline> inlines, String text) {
    if (text.isEmpty) {
      return;
    }
    if (inlines.lastOrNull case final previous?
        when previous.kind == BusyInlineKind.text) {
      inlines[inlines.length - 1] = previous.copyWith(
        text: previous.text + text,
      );
      return;
    }
    inlines.add(BusyInline(kind: BusyInlineKind.text, text: text));
  }

  String _collapseHtmlWhitespace(
    String value, {
    Iterable<String> ignoredPositionMarkers = const [],
  }) {
    final markers = ignoredPositionMarkers
        .where((marker) => marker.isNotEmpty)
        .toList(growable: false);
    if (markers.isEmpty) return value.replaceAll(RegExp(r'\s+'), ' ');

    final result = StringBuffer();
    var inWhitespace = false;
    var offset = 0;
    while (offset < value.length) {
      final marker = markers.firstWhere(
        (candidate) => value.startsWith(candidate, offset),
        orElse: () => '',
      );
      if (marker.isNotEmpty) {
        // Position records are zero-width for HTML whitespace processing.
        // Keeping [inWhitespace] unchanged projects a position within a
        // collapsed run to the boundary selected by its authored offset.
        result.write(marker);
        offset += marker.length;
        continue;
      }
      final unit = String.fromCharCode(value.codeUnitAt(offset));
      if (_htmlWhitespaceUnit.hasMatch(unit)) {
        if (!inWhitespace) result.write(' ');
        inWhitespace = true;
      } else {
        result.writeCharCode(value.codeUnitAt(offset));
        inWhitespace = false;
      }
      offset += 1;
    }
    return result.toString();
  }

  String _trimHtmlTextEdge(
    String value,
    Iterable<String> ignoredPositionMarkers, {
    required bool left,
  }) {
    final markers = ignoredPositionMarkers
        .where((marker) => marker.isNotEmpty)
        .toList(growable: false);
    if (markers.isEmpty) return left ? value.trimLeft() : value.trimRight();

    final unmarked = StringBuffer();
    var offset = 0;
    while (offset < value.length) {
      final marker = markers.firstWhere(
        (candidate) => value.startsWith(candidate, offset),
        orElse: () => '',
      );
      if (marker.isNotEmpty) {
        offset += marker.length;
      } else {
        unmarked.writeCharCode(value.codeUnitAt(offset));
        offset += 1;
      }
    }
    final plain = unmarked.toString();
    final keptStart = left ? plain.length - plain.trimLeft().length : 0;
    final keptEnd = left ? plain.length : plain.trimRight().length;
    final result = StringBuffer();
    var plainOffset = 0;
    offset = 0;
    while (offset < value.length) {
      final marker = markers.firstWhere(
        (candidate) => value.startsWith(candidate, offset),
        orElse: () => '',
      );
      if (marker.isNotEmpty) {
        result.write(marker);
        offset += marker.length;
        continue;
      }
      if (plainOffset >= keptStart && plainOffset < keptEnd) {
        result.writeCharCode(value.codeUnitAt(offset));
      }
      plainOffset += 1;
      offset += 1;
    }
    return result.toString();
  }

  String _plainTextFromNodes(Iterable<html.Node> nodes) {
    return nodes.map((node) => node.text ?? '').join();
  }

  String _plainText(Iterable<BusyInline> inlines) {
    return inlines.map((inline) => inline.plainText).join();
  }

  int? _headingLevel(String tag) {
    if (!RegExp(r'^h[1-6]$').hasMatch(tag)) {
      return null;
    }
    return int.parse(tag.substring(1));
  }

  bool _hasElement(
    Iterable<html.Node> nodes, {
    required _HtmlElementScanState state,
    int depth = 0,
  }) {
    for (final node in nodes) {
      if (!state.visit(depth)) {
        return false;
      }
      if (node is html.Element) {
        return true;
      }
      if (_hasElement(node.nodes, state: state, depth: depth + 1)) {
        return true;
      }
      if (state.exceeded) {
        return false;
      }
    }
    return false;
  }

  bool _mayContainHtml(String value) {
    return value.contains('<') &&
        value.contains('>') &&
        RegExp(r'</?\s*[A-Za-z][A-Za-z0-9_-]*(?:\s|/?>)').hasMatch(value);
  }
}

class _RawHtmlInlineMappingContext {
  _RawHtmlInlineMappingContext({
    required this.projection,
    required this.authoredClosingsByOpeningStart,
    required this.layout,
    required this.positionMarkers,
  });

  final _HtmlSourceProjection projection;
  final Map<int, ({int start, int end})> authoredClosingsByOpeningStart;
  final _StandaloneBreakLayoutIndex layout;
  final List<String> positionMarkers;
  final Map<BusyInline, RawHtmlInlineSourceRange> ranges = Map.identity();
}

class _HtmlSourceProjection {
  const _HtmlSourceProjection({
    required this.source,
    required this.normalized,
    required this.rawStarts,
    required this.rawEnds,
    required this.rawLength,
  });

  factory _HtmlSourceProjection.create(
    String source,
    List<({int start, int end, int lineFeedOffset})> removals, {
    String? parserText,
  }) {
    final parsed = parserText ?? source;
    final parsedRawStarts = <int>[];
    final parsedRawEnds = <int>[];
    var rawOffset = 0;
    for (var parsedOffset = 0; parsedOffset < parsed.length; parsedOffset++) {
      final unit = parsed.codeUnitAt(parsedOffset);
      if (rawOffset < source.length && source.codeUnitAt(rawOffset) == unit) {
        parsedRawStarts.add(rawOffset);
        parsedRawEnds.add(rawOffset + 1);
        rawOffset += 1;
        continue;
      }
      if (rawOffset + 1 < source.length &&
          source.codeUnitAt(rawOffset) == 0x5c &&
          source.codeUnitAt(rawOffset + 1) == unit) {
        parsedRawStarts.add(rawOffset);
        parsedRawEnds.add(rawOffset + 2);
        rawOffset += 2;
        continue;
      }
      if (unit == 0x0a &&
          rawOffset + 1 < source.length &&
          source.codeUnitAt(rawOffset) == 0x0d &&
          source.codeUnitAt(rawOffset + 1) == 0x0a) {
        parsedRawStarts.add(rawOffset);
        parsedRawEnds.add(rawOffset + 2);
        rawOffset += 2;
        continue;
      }
      final found = source.indexOf(String.fromCharCode(unit), rawOffset);
      if (found >= 0) {
        parsedRawStarts.add(found);
        parsedRawEnds.add(found + 1);
        rawOffset = found + 1;
      } else {
        final boundary = rawOffset.clamp(0, source.length).toInt();
        parsedRawStarts.add(boundary);
        parsedRawEnds.add(boundary);
      }
    }
    final normalized = StringBuffer();
    final rawStarts = <int>[];
    final rawEnds = <int>[];
    var removalIndex = 0;
    for (var offset = 0; offset < parsed.length; offset++) {
      final start = parsedRawStarts[offset];
      final end = parsedRawEnds[offset];
      while (removalIndex < removals.length &&
          removals[removalIndex].end <= start) {
        removalIndex += 1;
      }
      if (removalIndex < removals.length &&
          start >= removals[removalIndex].start &&
          end <= removals[removalIndex].end) {
        continue;
      }
      normalized.writeCharCode(parsed.codeUnitAt(offset));
      rawStarts.add(start);
      rawEnds.add(end);
    }
    return _HtmlSourceProjection(
      source: source,
      normalized: normalized.toString(),
      rawStarts: rawStarts,
      rawEnds: rawEnds,
      rawLength: source.length,
    );
  }

  final String source;
  final String normalized;
  final List<int> rawStarts;
  final List<int> rawEnds;
  final int rawLength;

  int rawStartFor(int offset) {
    if (rawStarts.isEmpty || offset >= rawStarts.length) return rawLength;
    if (offset <= 0) return rawStarts.first;
    return rawStarts[offset];
  }

  int rawEndFor(int offset) {
    if (rawEnds.isEmpty || offset <= 0) return 0;
    if (offset > rawEnds.length) return rawLength;
    return rawEnds[offset - 1];
  }
}

class _StandaloneBreakLayoutIndex {
  _StandaloneBreakLayoutIndex(
    List<({int start, int end, int lineFeedOffset})> removals,
  ) : _afterTag = {
        for (final removal in removals) removal.start: removal.lineFeedOffset,
      },
      _beforeTag = {
        for (final removal in removals) removal.end: removal.lineFeedOffset,
      };

  final Map<int, int> _afterTag;
  final Map<int, int> _beforeTag;
  final Set<int> _claimedLineFeeds = {};

  int? claimForBreak(int start, int end) {
    debugBusyMarkStandaloneBreakLayoutLookups?.call(1);
    final after = _afterTag[end];
    if (after != null && _claimedLineFeeds.add(after)) return after;
    final before = _beforeTag[start];
    if (before != null && _claimedLineFeeds.add(before)) return before;
    return null;
  }
}

class _HtmlWalkState {
  var nodes = 0;

  bool visit(int depth) {
    if (depth > maxRawHtmlDepth || nodes >= maxRawHtmlNodes) {
      return false;
    }
    nodes += 1;
    return true;
  }
}

class _HtmlElementScanState {
  var nodes = 0;
  var exceeded = false;

  bool visit(int depth) {
    if (depth > maxRawHtmlDepth || nodes >= maxRawHtmlNodes) {
      exceeded = true;
      return false;
    }
    nodes += 1;
    return true;
  }
}
