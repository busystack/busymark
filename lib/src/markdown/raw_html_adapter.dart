import 'package:html/dom.dart' as html;
import 'package:html/parser.dart' as html_parser;
// The public parser does not expose authored closing-tag spans. Its tokenizer
// is the parser's own location-aware boundary source, not a second HTML parser.
// ignore: implementation_imports
import 'package:html/src/token.dart' as html_token;
// ignore: implementation_imports
import 'package:html/src/tokenizer.dart' as html_tokenizer;

import '../core/path_utils.dart';
import '../core/source_span.dart';
import 'busymark_document.dart';
import 'raw_html_policy.dart';
import 'semantic_html_inline.dart';

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
  const RawHtmlAdapter({
    this.preserveInlineWhitespace = false,
    this.importClipboardLists = false,
  });

  /// Browser lists have explicit DOM owners. Clipboard import can serialize
  /// their items as a group without inferring ownership in authored Markdown.
  final bool importClipboardLists;

  /// Clipboard selections can explicitly include spaces at inline edges.
  /// Callers enabling this must first remove structural HTML layout whitespace.
  final bool preserveInlineWhitespace;

  RawHtmlBlockParseResult? parseRawHtmlBlock(
    String rawSource,
    String Function() nextId, {
    bool trackImageSpans = false,
  }) {
    if (!_mayContainHtml(rawSource)) {
      return null;
    }
    final fragment = _parseFragment(rawSource, generateSpans: trackImageSpans);
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
    return RawHtmlBlockParseResult(
      safe: true,
      blocks: importClipboardLists ? _separateClipboardLists(blocks) : blocks,
    );
  }

  /// A bounded DOM for operations that must keep the authored HTML structure.
  html.DocumentFragment? parseSafeRawHtml(String source) {
    if (!_mayContainHtml(source)) return null;
    final fragment = _parseFragment(source);
    if (fragment == null || !_isSafeFragment(fragment, inlineOnly: false)) {
      return null;
    }
    return fragment;
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
    final inlineNodes = <html.Node>[];

    void flushInlineBuffer() {
      final inlines = _trimInlineEdges(inlineBuffer);
      inlineBuffer.clear();
      if (inlines.isNotEmpty) {
        final paragraph = BusyBlock(
          id: nextId(),
          kind: BusyBlockKind.paragraph,
          inlines: inlines,
        );
        if (importClipboardLists && inlineNodes.any(_inlineNeedsHtml)) {
          final wrapper = html.Element.tag('p')
            ..nodes.addAll(inlineNodes.map((node) => node.clone(true)));
          blocks.add(_importedHtmlBlock(wrapper, [paragraph], nextId));
        } else {
          blocks.add(paragraph);
        }
      }
      inlineNodes.clear();
    }

    for (final node in nodes) {
      if (node is html.Text) {
        if (node.data.trim().isNotEmpty || preserveInlineWhitespace) {
          _appendInlineText(inlineBuffer, _collapseHtmlWhitespace(node.data));
          inlineNodes.add(node);
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
      if (isSafeInlineHtmlTag(tag) &&
          !isSafeBlockHtmlTag(tag) &&
          !_isBlockLink(node)) {
        inlineBuffer.addAll(_inlineFromElement(node));
        inlineNodes.add(node);
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
    final direction = busyMarkResolvedHtmlDirection(element);
    if (attributes.containsKey('dir')) {
      attributes.remove('dir');
      if (direction != null) attributes['dir'] = direction;
    }
    final children = element.nodes;
    final text = _plainTextFromNodes(children).trim();

    if (_isBlockLink(element)) {
      List<BusyBlock> linkBlocks(List<BusyBlock> blocks) => [
        for (final block in blocks)
          block.copyWith(
            inlines: block.inlines.isEmpty
                ? const []
                : _linkInlines(block.inlines, attributes),
            children: linkBlocks(block.children),
          ),
      ];
      final linked = linkBlocks(_blocksFromNodes(children, nextId));
      // A link split into separate Markdown blocks has no common wrapper.
      // Keep that wrapper if it carries additional attributes or if a raw
      // descendant would serialize independently of its semantic inlines.
      bool needsWrapper(BusyBlock block) =>
          block.preserveRaw ||
          block.kind == BusyBlockKind.image ||
          block.kind == BusyBlockKind.codeBlock ||
          block.children.any(needsWrapper);
      return attributes.keys.any((key) => key != 'href' && key != 'title') ||
              linked.any(needsWrapper)
          ? [_importedHtmlBlock(element, linked, nextId)]
          : linked;
    }

    if (_headingLevel(tag) case final level?) {
      final anchorId = attributes['id'] ?? slugForHeading(text);
      final heading = _applyHtmlDirection([
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
      ], direction);
      return _preserveClipboardHtml(element, heading, nextId);
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
      'figure' => [
        _importedHtmlBlock(element, _blocksFromNodes(children, nextId), nextId),
      ],
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
    return _preserveClipboardHtml(
      element,
      _applyHtmlDirection(blocks, direction),
      nextId,
    );
  }

  List<BusyBlock> _preserveClipboardHtml(
    html.Element element,
    List<BusyBlock> blocks,
    String Function() nextId,
  ) {
    final tag = element.localName!;
    if (!importClipboardLists ||
        const {'ol', 'ul', 'table', 'figure'}.contains(tag)) {
      return blocks;
    }
    final needsHtml =
        element.attributes.keys.any(
          (key) => switch (tag) {
            'img' => !const {'src', 'alt', 'title'}.contains(key),
            'pre' => key != 'class',
            _ => true,
          },
        ) ||
        element.nodes.any(_inlineNeedsHtml) ||
        const {'dl', 'details', 'address'}.contains(tag);
    return needsHtml ? [_importedHtmlBlock(element, blocks, nextId)] : blocks;
  }

  bool _inlineNeedsHtml(html.Node node) {
    if (node is! html.Element) return false;
    final tag = node.localName!;
    if (isSafeBlockHtmlTag(tag)) return false;
    if (tag == 'bdo' || tag == 'bdi') return true;
    return node.attributes.keys.any(
          (key) => switch (tag) {
            'a' => key != 'href' && key != 'title',
            'img' => !const {'src', 'alt', 'title'}.contains(key),
            'code' => key != 'class',
            _ => true,
          },
        ) ||
        node.nodes.any(_inlineNeedsHtml);
  }

  BusyBlock _importedHtmlBlock(
    html.Element element,
    List<BusyBlock> blocks,
    String Function() nextId,
  ) => BusyBlock(
    id: nextId(),
    kind: BusyBlockKind.htmlBlock,
    rawSource: element.outerHtml,
    children: blocks,
    attributes: {
      'sourceFormat': 'html',
      'htmlTag': element.localName!,
      if (busyMarkResolvedHtmlDirection(element) case final direction?)
        'dir': direction,
    },
    preserveRaw: true,
  );

  List<BusyBlock> _applyHtmlDirection(
    List<BusyBlock> blocks,
    String? inheritedDirection,
  ) {
    final normalizedDirection = busyMarkHtmlDirection(inheritedDirection);
    if (normalizedDirection == null) {
      return blocks;
    }
    BusyBlock visit(BusyBlock block, String direction) {
      final ownDirection = busyMarkHtmlDirection(block.attributes['dir']);
      final blockDirection = ownDirection == 'auto'
          ? direction
          : ownDirection ?? direction;
      return block.copyWith(
        attributes: {...block.attributes, 'dir': blockDirection},
        children: [
          for (final child in block.children) visit(child, blockDirection),
        ],
      );
    }

    return [for (final block in blocks) visit(block, normalizedDirection)];
  }

  BusyBlock _codeBlockFromPre(
    html.Element element,
    Map<String, String> attributes,
    String Function() nextId,
  ) {
    final code = element.children.where((child) => child.localName == 'code');
    final className =
        code.firstOrNull?.attributes['class'] ?? attributes['class'] ?? '';
    final text = StringBuffer();
    void append(html.Node node) {
      if (node is html.Text) {
        text.write(node.data);
      } else if (node is html.Element && node.localName == 'br') {
        text.writeln();
      } else {
        node.nodes.forEach(append);
      }
    }

    element.nodes.forEach(append);
    final language = className
        .split(RegExp(r'\s+'))
        .where((name) => name.startsWith('language-'))
        .map((name) => name.substring('language-'.length))
        .firstOrNull;
    return BusyBlock(
      id: nextId(),
      kind: BusyBlockKind.codeBlock,
      inlines: [BusyInline(kind: BusyInlineKind.text, text: text.toString())],
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
    final items = element.children.where((child) => child.localName == 'li');
    final reversed = attributes.containsKey('reversed');
    final start =
        int.tryParse(attributes['start'] ?? '') ??
        (reversed ? items.length : 1);
    var number = start;
    final blocks = <BusyBlock>[];
    for (final child in items) {
      if (ordered) {
        number = int.tryParse(child.attributes['value'] ?? '') ?? number;
      }
      blocks.add(
        _listItemFromElement(
          child,
          ordered: ordered,
          marker: ordered
              ? _htmlOrderedMarker(number, attributes['type'])
              : '-',
          nextId: nextId,
        ),
      );
      if (ordered) number += reversed ? -1 : 1;
    }
    if (!importClipboardLists || blocks.isEmpty) return blocks;
    final loose = items.any(
      (item) => item.children.any((c) => c.localName == 'p'),
    );
    // Alphabetic, reversed, and per-item numbering have no Markdown marker
    // equivalent. Keep the sanitized list itself as the source in that case.
    if (attributes.keys.any((name) => name != 'start' && name != 'type') ||
        (ordered &&
            (reversed ||
                (attributes['type'] ?? '1') != '1' ||
                start < 0 ||
                start > 999999999 - blocks.length + 1 ||
                items.any((item) => item.attributes.containsKey('value')))) ||
        items.any(
          (item) =>
              item.attributes.keys.any((name) => name != 'value') ||
              item.nodes.any(_inlineNeedsHtml),
        ) ||
        (loose && blocks.length == 1 && blocks.single.children.isEmpty)) {
      return [
        _importedHtmlBlock(
          element,
          _applyHtmlDirection(blocks, busyMarkResolvedHtmlDirection(element)),
          nextId,
        ),
      ];
    }
    final last = blocks.length - 1;
    return [
      BusyBlock(
        id: nextId(),
        kind: BusyBlockKind.writersideRawXml,
        children: [
          for (final (index, block) in blocks.indexed)
            if (loose && index < last)
              block.copyWith(
                attributes: {
                  ...block.attributes,
                  'busymark-native-trailing-gap': '\n\n',
                },
              )
            else
              block,
        ],
        attributes: {
          'element': 'list',
          busyMarkWritersideContainerAttribute: 'true',
          'busymark-list-form': 'markdown',
          'busymark-native-list-type': ordered ? 'decimal' : 'bullet',
          'busymark-native-list-start': '$start',
        },
      ),
    ];
  }

  List<BusyBlock> _separateClipboardLists(List<BusyBlock> blocks) {
    String? previousMarker;
    final result = <BusyBlock>[];
    for (final block in blocks) {
      var children = _separateClipboardLists(block.children);
      String? marker;
      if (block.attributes['busymark-list-form'] == 'markdown') {
        final ordered =
            block.attributes['busymark-native-list-type'] == 'decimal';
        final standard = ordered ? '.' : '-';
        marker = previousMarker == standard ? (ordered ? ')' : '+') : standard;
        children = [
          for (final child in children)
            child.copyWith(
              attributes: {
                ...child.attributes,
                'marker': ordered
                    ? '${child.attributes['marker']!.split('.').first}$marker'
                    : marker,
                if (!ordered && marker != '-')
                  'busymark-clipboard-list-marker': marker,
              },
            ),
        ];
      }
      result.add(block.copyWith(children: children));
      previousMarker = marker;
    }
    return result;
  }

  BusyBlock _listItemFromElement(
    html.Element element, {
    required bool ordered,
    required String marker,
    required String Function() nextId,
  }) {
    final attributes = sanitizeHtmlAttributes('li', element.attributes) ?? {};
    final children = _blocksFromNodes(element.nodes, nextId);
    final first = children.firstOrNull;
    final inlines =
        first?.kind == BusyBlockKind.paragraph &&
            first!.attributes.keys.every((key) => key == 'htmlTag')
        ? children.removeAt(0).inlines
        : const <BusyInline>[];
    final direction = busyMarkResolvedHtmlDirection(element);
    return BusyBlock(
      id: nextId(),
      kind: ordered
          ? BusyBlockKind.orderedListItem
          : BusyBlockKind.unorderedListItem,
      inlines: inlines,
      children: _applyHtmlDirection(children, direction),
      attributes: {
        ...attributes..remove('dir'),
        if (direction != null) 'dir': direction,
        'ordered': '$ordered',
        'marker': marker,
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
    if (importClipboardLists &&
        !_canSerializeMarkdownTable(table, blocks.last)) {
      return [
        _importedHtmlBlock(
          table,
          _applyHtmlDirection(blocks, busyMarkResolvedHtmlDirection(table)),
          nextId,
        ),
      ];
    }
    return blocks;
  }

  bool _canSerializeMarkdownTable(html.Element table, BusyBlock adapted) {
    final rows = adapted.children;
    if (rows.isEmpty) return false;
    final firstHeaderCount = rows.first.children
        .where((cell) => cell.attributes['cell'] == 'th')
        .length;
    if (firstHeaderCount != 0 &&
        firstHeaderCount != rows.first.children.length) {
      return false;
    }
    final width = rows.first.children.length;
    if (rows.any((row) => row.children.length != width) ||
        rows
            .skip(1)
            .any(
              (row) =>
                  row.children.any((cell) => cell.attributes['cell'] == 'th'),
            )) {
      return false;
    }
    for (var column = 0; column < width; column++) {
      final alignments = {
        for (final row in rows)
          if (row.children[column].attributes['align'] case final alignment?)
            alignment,
      };
      if (alignments.length > 1) return false;
    }

    bool representable(html.Element element) {
      final tag = element.localName!;
      final attrs = element.attributes;
      if (_inlineNeedsHtml(element)) return false;
      if (tag == 'td' || tag == 'th') {
        return attrs.keys.every((key) => key == 'align') &&
            element.children.every(_isTableCellFlow);
      }
      return const {'table', 'thead', 'tbody', 'tr'}.contains(tag) &&
          attrs.isEmpty &&
          element.children.every(representable);
    }

    return representable(table);
  }

  bool _isBlockLink(html.Element element) =>
      element.localName == 'a' &&
      element.querySelector(safeBlockHtmlTags.join(',')) != null;

  List<BusyInline> _linkInlines(
    List<BusyInline> children,
    Map<String, String> attributes,
  ) => switch (attributes['href']) {
    final href? => [
      BusyInline(
        kind: BusyInlineKind.link,
        text: _plainText(children),
        destination: href,
        children: children,
        attributes: attributes,
      ),
    ],
    null => children,
  };

  bool _isTableCellFlow(html.Element element) {
    if (_isBlockLink(element)) {
      return !_inlineNeedsHtml(element) &&
          element.children.every(_isTableCellFlow);
    }
    if (!isSafeBlockHtmlTag(element.localName!)) {
      return !_inlineNeedsHtml(element);
    }
    return const {
          'p',
          'div',
          'section',
          'article',
        }.contains(element.localName) &&
        element.attributes.isEmpty &&
        element.children.every(_isTableCellFlow);
  }

  List<BusyInline> _tableCellInlines(html.Element cell) {
    final result = <BusyInline>[];
    var flow = <BusyInline>[];
    void flush(Map<String, String> link) {
      final inlines = _trimInlineEdges(flow);
      flow = [];
      if (inlines.every(
        (inline) =>
            inline.plainText.trim().isEmpty &&
            inline.kind == BusyInlineKind.text,
      )) {
        return;
      }
      if (result.isNotEmpty &&
          result.last.kind != BusyInlineKind.hardBreak &&
          inlines.first.kind != BusyInlineKind.hardBreak) {
        result.add(
          const BusyInline(kind: BusyInlineKind.hardBreak, text: '\n'),
        );
      }
      result.addAll(_linkInlines(inlines, link));
    }

    void append(html.Node node, Map<String, String> link) {
      if (node is html.Element && _isBlockLink(node)) {
        flush(link);
        final attributes = sanitizeHtmlAttributes('a', node.attributes) ?? {};
        for (final child in node.nodes) {
          append(child, attributes);
        }
        flush(attributes);
      } else if (node is html.Element && isSafeBlockHtmlTag(node.localName!)) {
        flush(link);
        for (final child in node.nodes) {
          append(child, link);
        }
        flush(link);
      } else {
        flow.addAll(_inlineFromNode(node));
      }
    }

    for (final node in cell.nodes) {
      append(node, const {});
    }
    flush(const {});
    return result;
  }

  List<BusyBlock> _tableRows(html.Element table, String Function() nextId) {
    final rows = <BusyBlock>[];
    void addRow(
      html.Element row, {
      required bool sectionHeader,
      required int remainingRows,
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
      final rowDirection =
          busyMarkResolvedHtmlDirection(row) ?? inheritedDirection;
      final rowBlock = BusyBlock(
        id: nextId(),
        kind: BusyBlockKind.table,
        attributes: {
          'header': '${sectionHeader || allHeaderCells}',
          if (rowDirection != null) 'dir': rowDirection,
        },
        children: [
          for (final cell in cells)
            _tableCellFromElement(cell, nextId, remainingRows),
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
        addRow(child, sectionHeader: false, remainingRows: 1);
      } else if (tag == 'thead' || tag == 'tbody' || tag == 'tfoot') {
        final sectionDirection = busyMarkResolvedHtmlDirection(child);
        final sectionRows = child.children
            .where((candidate) => candidate.localName == 'tr')
            .toList();
        for (final (index, row) in sectionRows.indexed) {
          addRow(
            row,
            sectionHeader: tag == 'thead',
            remainingRows: sectionRows.length - index,
            inheritedDirection: sectionDirection,
          );
        }
      }
    }
    return rows;
  }

  BusyBlock _tableCellFromElement(
    html.Element cell,
    String Function() nextId,
    int remainingRows,
  ) {
    final useBlocks = cell.children.any(
      (child) =>
          isSafeBlockHtmlTag(child.localName!) && !_isTableCellFlow(child),
    );
    final direction = busyMarkResolvedHtmlDirection(cell);
    return BusyBlock(
      id: nextId(),
      kind: BusyBlockKind.paragraph,
      inlines: useBlocks ? const [] : _tableCellInlines(cell),
      children: useBlocks
          ? _applyHtmlDirection(_blocksFromNodes(cell.nodes, nextId), direction)
          : const [],
      attributes: _tableCellAttributes(cell, remainingRows),
    );
  }

  Map<String, String> _tableCellAttributes(
    html.Element cell,
    int remainingRows,
  ) {
    final tag = cell.localName?.toLowerCase() ?? 'td';
    final sanitized = sanitizeHtmlAttributes(tag, cell.attributes) ?? {};
    final rowspan = int.tryParse(sanitized['rowspan'] ?? '');
    return {
      'cell': tag,
      if (tag == 'th') 'header': 'true',
      for (final name in ['align', 'colspan', 'scope'])
        if (sanitized[name] case final value?) name: value,
      if (rowspan != null && rowspan >= 0)
        'rowspan':
            '${rowspan == 0 ? remainingRows : rowspan.clamp(1, remainingRows)}',
      if (busyMarkResolvedHtmlDirection(cell) case final direction?)
        'dir': direction,
    };
  }

  SourceSpan? _imageSpan(html.Element element) {
    final span = element.sourceSpan;
    if (span == null) return null;
    return SourceSpan(
      filePath: '',
      startOffset: span.start.offset,
      endOffset: span.end.offset,
      startLine: span.start.line + 1,
      endLine: span.end.line + 1,
      startColumn: span.start.column + 1,
      endColumn: span.end.column + 1,
    );
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
          imageSpan: _imageSpan(element),
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
      final inline = BusyInline(kind: BusyInlineKind.text, text: text);
      final span = node.sourceSpan;
      if (mapping != null && span != null) {
        mapping.ranges[inline] = RawHtmlInlineSourceRange(
          start: mapping.projection.rawStartFor(span.start.offset),
          end: mapping.projection.rawEndFor(span.end.offset),
        );
      }
      return [inline];
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
    final direction = busyMarkResolvedHtmlDirection(element);
    final semanticTag = semanticHtmlInlineTags.contains(tag);
    final inlineAttributes = semanticTag || tag == 'img' || tag == 'br'
        ? attributes
        : ({...attributes}..remove('dir'));
    // Whitespace inside an inline wrapper separates it from adjacent content.
    // Only the containing block/fragment may trim its outer edges.
    final children = _inlinesFromNodes(element.nodes, mapping: mapping);
    final text = _plainText(children);
    if (text.trim().isEmpty &&
        const {'strong', 'b', 'em', 'i', 'u', 's', 'del'}.contains(tag)) {
      return children;
    }
    List<BusyInline> result = switch (tag) {
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
          attributes: inlineAttributes,
        ),
      ],
      'code' => [
        BusyInline(
          kind: BusyInlineKind.code,
          text: element.text,
          attributes: inlineAttributes,
        ),
      ],
      'a' => _linkInlines(children, inlineAttributes),
      'img' => [
        BusyInline(
          kind: BusyInlineKind.image,
          text: attributes['alt'] ?? '',
          destination: attributes['src'],
          imageSpan: _imageSpan(element),
          attributes: inlineAttributes,
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
                    attributes: inlineAttributes,
                  ),
              ]
            : children,
    };
    if (semanticTag || direction != null && tag != 'img' && tag != 'br') {
      final contents = semanticTag ? children : result;
      result = [
        BusyInline(
          kind: BusyInlineKind.html,
          text: _plainText(contents),
          children: contents,
          attributes: {
            if (semanticTag || tag == 'span') ...attributes,
            'htmlTag': semanticTag ? tag : 'span',
            if (direction != null) 'dir': direction,
          },
        ),
      ];
    }
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
      // Transparent HTML containers can return their existing child. Keep
      // that child's authored text/break interval rather than widening it to
      // the surrounding tag and attributes.
      mapping.ranges.putIfAbsent(
        result.single,
        () => RawHtmlInlineSourceRange(
          start: start,
          end: end,
          opening: mapping.projection.source.substring(start, openingEnd),
          closing: closingStart == null || closingStart >= end
              ? null
              : mapping.projection.source.substring(closingStart, end),
          sourceLineBreakOffset: tag == 'br'
              ? mapping.layout.claimForBreak(start, end)
              : null,
        ),
      );
    }
    return result;
  }

  List<BusyInline> _trimInlineEdges(
    List<BusyInline> inlines, {
    Map<BusyInline, RawHtmlInlineSourceRange>? ranges,
    Iterable<String> ignoredPositionMarkers = const [],
  }) {
    if (preserveInlineWhitespace) return inlines.toList();
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
    if (preserveInlineWhitespace && !RegExp(r'[\r\n\t\f]').hasMatch(value)) {
      return value.replaceAll(RegExp(r'[^\S ]+'), ' ');
    }
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

String _htmlOrderedMarker(int number, String? type) {
  if (number < 1) return '$number.';
  if (type == 'a' || type == 'A') {
    var letters = '';
    for (var n = number; n > 0; n = (n - 1) ~/ 26) {
      letters = String.fromCharCode(65 + (n - 1) % 26) + letters;
    }
    return type == 'a' ? '${letters.toLowerCase()}.' : '$letters.';
  }
  if ((type == 'i' || type == 'I') && number <= 3999) {
    const digits = [
      (1000, 'M'),
      (900, 'CM'),
      (500, 'D'),
      (400, 'CD'),
      (100, 'C'),
      (90, 'XC'),
      (50, 'L'),
      (40, 'XL'),
      (10, 'X'),
      (9, 'IX'),
      (5, 'V'),
      (4, 'IV'),
      (1, 'I'),
    ];
    final roman = StringBuffer();
    for (final (value, symbol) in digits) {
      while (number >= value) {
        roman.write(symbol);
        number -= value;
      }
    }
    return type == 'i' ? '${roman.toString().toLowerCase()}.' : '$roman.';
  }
  return '$number.';
}
