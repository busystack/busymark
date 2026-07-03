import 'package:html/dom.dart' as html;
import 'package:html/parser.dart' as html_parser;

import '../core/path_utils.dart';
import 'busymark_document.dart';
import 'raw_html_policy.dart';

class RawHtmlBlockParseResult {
  const RawHtmlBlockParseResult({required this.safe, this.blocks = const []});

  final bool safe;
  final List<BusyBlock> blocks;
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
    if (fragment == null || !_hasElement(fragment.nodes)) {
      return null;
    }
    if (!_isSafeFragment(fragment, inlineOnly: false)) {
      return const RawHtmlBlockParseResult(safe: false);
    }
    final blocks = _blocksFromNodes(fragment.nodes, nextId);
    return RawHtmlBlockParseResult(safe: true, blocks: blocks);
  }

  List<BusyInline>? parseRawHtmlInlineFragment(String text) {
    if (!_mayContainHtml(text)) {
      return null;
    }
    final fragment = _parseFragment(text);
    if (fragment == null || !_hasElement(fragment.nodes)) {
      return null;
    }
    if (!_isSafeFragment(fragment, inlineOnly: true)) {
      return null;
    }
    return _trimInlineEdges(_inlinesFromNodes(fragment.nodes));
  }

  html.DocumentFragment? _parseFragment(String source) {
    try {
      return html_parser.parseFragment(source);
    } on Object {
      return null;
    }
  }

  bool _isSafeFragment(html.Node node, {required bool inlineOnly}) {
    for (final child in node.nodes) {
      if (!_isSafeNode(child, inlineOnly: inlineOnly)) {
        return false;
      }
    }
    return true;
  }

  bool _isSafeNode(html.Node node, {required bool inlineOnly}) {
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
    return _isSafeFragment(node, inlineOnly: inlineOnly);
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
          inlineBuffer.add(
            BusyInline(kind: BusyInlineKind.text, text: node.data),
          );
        }
        continue;
      }
      if (node is! html.Element) {
        continue;
      }
      final tag = node.localName?.toLowerCase() ?? '';
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
      final id = attributes['id'] ?? slugForHeading(text);
      return [
        BusyBlock(
          id: id.isEmpty ? nextId() : id,
          kind: BusyBlockKind.heading,
          inlines: _trimInlineEdges(_inlinesFromNodes(children)),
          attributes: {
            ...attributes,
            'level': '$level',
            'id': id,
            'generatedId': '${attributes['id'] == null}',
          },
        ),
      ];
    }

    return switch (tag) {
      'article' ||
      'aside' ||
      'div' ||
      'section' ||
      'header' ||
      'footer' ||
      'main' ||
      'nav' ||
      'details' ||
      'figure' => _blocksFromNodes(children, nextId),
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
          inlines.add(BusyInline(kind: BusyInlineKind.text, text: child.data));
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
      blocks.add(
        BusyBlock(
          id: nextId(),
          kind: BusyBlockKind.paragraph,
          inlines: _trimInlineEdges(_inlinesFromNodes(caption.nodes)),
          attributes: {'htmlTag': 'caption'},
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
    void addRow(html.Element row, {required bool sectionHeader}) {
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
      rows.add(
        BusyBlock(
          id: nextId(),
          kind: BusyBlockKind.table,
          attributes: {'header': '${sectionHeader || allHeaderCells}'},
          children: [
            for (final cell in cells)
              BusyBlock(
                id: nextId(),
                kind: BusyBlockKind.paragraph,
                inlines: _trimInlineEdges(_inlinesFromNodes(cell.nodes)),
                attributes: _tableCellAttributes(cell),
              ),
          ],
        ),
      );
    }

    for (final child in table.children) {
      final tag = child.localName?.toLowerCase();
      if (tag == 'tr') {
        addRow(child, sectionHeader: false);
      } else if (tag == 'thead' || tag == 'tbody' || tag == 'tfoot') {
        for (final row in child.children.where(
          (candidate) => candidate.localName?.toLowerCase() == 'tr',
        )) {
          addRow(row, sectionHeader: tag == 'thead');
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
      for (final name in ['align', 'colspan', 'rowspan', 'scope'])
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

  List<BusyInline> _inlinesFromNodes(Iterable<html.Node> nodes) {
    return [for (final node in nodes) ..._inlineFromNode(node)];
  }

  List<BusyInline> _inlineFromNode(html.Node node) {
    if (node is html.Text) {
      if (node.data.isEmpty) {
        return const [];
      }
      return [BusyInline(kind: BusyInlineKind.text, text: node.data)];
    }
    if (node is html.Element) {
      return _inlineFromElement(node);
    }
    return const [];
  }

  List<BusyInline> _inlineFromElement(html.Element element) {
    final tag = element.localName?.toLowerCase() ?? '';
    final attributes = sanitizeHtmlAttributes(tag, element.attributes) ?? {};
    final children = _trimInlineEdges(_inlinesFromNodes(element.nodes));
    final text = _plainText(children);
    return switch (tag) {
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
          text: text,
          attributes: attributes,
        ),
      ],
      'a' => [
        BusyInline(
          kind: BusyInlineKind.link,
          text: text,
          destination: attributes['href'],
          children: children,
          attributes: attributes,
        ),
      ],
      'img' => [
        BusyInline(
          kind: BusyInlineKind.image,
          text: attributes['alt'] ?? '',
          destination: attributes['src'],
          attributes: attributes,
        ),
      ],
      'br' => const [BusyInline(kind: BusyInlineKind.hardBreak, text: '\n')],
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
  }

  List<BusyInline> _trimInlineEdges(List<BusyInline> inlines) {
    if (inlines.isEmpty) {
      return const [];
    }
    final result = [...inlines];
    if (result.first.kind == BusyInlineKind.text) {
      result[0] = result.first.copyWith(text: result.first.text.trimLeft());
    }
    if (result.last.kind == BusyInlineKind.text) {
      result[result.length - 1] = result.last.copyWith(
        text: result.last.text.trimRight(),
      );
    }
    return [
      for (final inline in result)
        if (inline.kind != BusyInlineKind.text || inline.text.isNotEmpty)
          inline,
    ];
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

  bool _hasElement(Iterable<html.Node> nodes) {
    return nodes.any((node) => node is html.Element || _hasElement(node.nodes));
  }

  bool _mayContainHtml(String value) {
    return value.contains('<') &&
        value.contains('>') &&
        RegExp(r'</?\s*[A-Za-z][A-Za-z0-9_-]*(?:\s|/?>)').hasMatch(value);
  }
}
