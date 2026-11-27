import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:intl/intl.dart' show Bidi;
import 'package:path/path.dart' as p;

import '../../core/uri_utils.dart';
import '../../markdown/busymark_document.dart';
import '../../markdown/markdown_model.dart';
import '../../markdown/markdown_list_source.dart';
import '../../markdown/raw_html_adapter.dart';
import '../../markdown/raw_html_policy.dart';
import '../../markdown/semantic_html_inline.dart';
import '../../platform/rich_clipboard_service.dart';
import 'wysiwyg_clipboard_fragment.dart';
import 'wysiwyg_document_controller.dart';
import 'wysiwyg_inline_controller.dart';

class WysiwygClipboardHtml {
  const WysiwygClipboardHtml();

  String encode(WysiwygClipboardFragment fragment) {
    final writer = _HtmlWriter(fragment.sourcePath, fragment.mediaPaths);
    final body = dom.Element.tag('div')
      ..nodes.addAll(writer.blocks(fragment.documentBlocks));
    return '<html><head><meta charset="utf-8"></head><body>'
        '<!--StartFragment-->${body.innerHtml}<!--EndFragment-->'
        '</body></html>';
  }

  WysiwygClipboardFragment? decode(
    String source, {
    required MarkdownMode mode,
    bool external = true,
  }) {
    if (source.length > maxRichClipboardBytes ||
        utf8.encode(source).length > maxRichClipboardBytes) {
      return null;
    }
    try {
      final selected = _clipboardFragmentNodes(source, _clipboardNodes(source));
      if (selected == null) return null;
      final normalizer = _HtmlNormalizer(external: external);
      final clean = dom.Element.tag('div')
        ..nodes.addAll(normalizer.nodes(selected, 0, const {}));
      if (external) {
        _normalizeClipboardSemantics(clean);
        _normalizeBrowserParagraphs(clean);
      }
      var id = 0;
      final parsed = RawHtmlAdapter(
        preserveInlineWhitespace: true,
        importClipboardLists: external,
      ).parseRawHtmlBlock(clean.outerHtml, () => 'clipboard-html-${id++}');
      if (parsed == null || !parsed.safe || parsed.blocks.isEmpty) return null;
      BusyBlock task(BusyBlock block) {
        block = block.copyWith(
          inlines: busyMarkWysiwygNormalizeClipboardFormatting(block.inlines),
        );
        final children = [for (final child in block.children) task(child)];
        if ((block.kind == BusyBlockKind.unorderedListItem ||
                block.kind == BusyBlockKind.orderedListItem) &&
            RegExp(r'^[☐☑]\s').hasMatch(block.plainText)) {
          final checked = block.plainText.startsWith('☑');
          var remaining = 2;
          BusyInline strip(BusyInline value) {
            if (remaining == 0) return value;
            if (value.children.isNotEmpty) {
              return value.copyWith(
                children: [for (final child in value.children) strip(child)],
              );
            }
            final count = remaining.clamp(0, value.text.length);
            remaining -= count;
            return value.copyWith(text: value.text.substring(count));
          }

          return block.copyWith(
            kind: BusyBlockKind.taskListItem,
            inlines: [for (final value in block.inlines) strip(value)],
            children: children,
            attributes: {...block.attributes, 'task': '$checked'},
            dirty: true,
          );
        }
        return block.copyWith(
          children: children,
          attributes: {
            ...block.attributes,
            if (block.plainText.isNotEmpty &&
                block.plainText.trimRight() != block.plainText)
              busyMarkPreserveTextWhitespaceAttribute: 'true',
          },
          dirty: true,
        );
      }

      return WysiwygClipboardFragment(
        mode: mode,
        blocks: [
          for (final value in parsed.blocks.map(task))
            BusyWysiwygStyledBlock(
              kind: value.kind,
              text: value.plainText,
              ranges: busyInlineStyleRanges(value.inlines),
              attributes: value.attributes,
              completeBlock: value,
            ),
        ],
      );
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }
  }
}

List<dom.Node> _clipboardNodes(String source) {
  if (_documentWrapper.hasMatch(source)) {
    final document = html.parse(source);
    final documentElement = document.documentElement;
    final htmlDirection = busyMarkHtmlDirection(
      documentElement?.attributes['dir'],
    );
    final bodyDirection = busyMarkHtmlDirection(
      document.body?.attributes['dir'],
    );
    if (document.body case final body?
        when htmlDirection != null || bodyDirection != null) {
      // The original document scope can derive its direction from the title,
      // even though the body supplies all of the pasteable content.
      final directions = [
        if (bodyDirection != null)
          (bodyDirection, _resolvedAutoDirection(body)),
        if (htmlDirection != null)
          (htmlDirection, _resolvedAutoDirection(documentElement!)),
      ];
      var nodes = body.nodes.toList();
      for (final (direction, autoDirection) in directions) {
        nodes = [
          _element('div', nodes, {'dir': direction})
            .._preserveClipboardAutoDirection(autoDirection),
        ];
      }
      return nodes;
    }
  }
  // Fragment parsing retains leading text even without an explicit body.
  return html.parseFragment(source).nodes;
}

final _documentWrapper = RegExp(r'<(?:html|body)\s', caseSensitive: false);

String? _resolvedAutoDirection(dom.Element element) {
  final direction = busyMarkHtmlDirection(element.attributes['dir']);
  return direction == 'auto' ||
          (direction == null && element.localName == 'bdi')
      ? busyMarkResolvedHtmlDirection(element)
      : null;
}

extension on dom.Element {
  void _preserveClipboardAutoDirection(String? original) {
    if (original != null && busyMarkResolvedHtmlDirection(this) != original) {
      attributes['dir'] = original;
    }
  }
}

List<dom.Node>? _clipboardFragmentNodes(String source, List<dom.Node> nodes) {
  if (!source.contains('<!--StartFragment-->') ||
      !source.contains('<!--EndFragment-->')) {
    return nodes;
  }

  // A marker may sit inside a selected wrapper. Keep only nodes between
  // the markers and the ancestor shells that carry their inherited semantics.
  var started = false;
  var ended = false;
  var count = 0;
  List<dom.Node> visit(List<dom.Node> nodes, int depth) {
    if (depth > maxRawHtmlDepth) {
      throw const FormatException('Clipboard HTML nesting limit');
    }
    final selected = <dom.Node>[];
    for (final node in nodes) {
      if (ended) break;
      if (++count > maxRawHtmlNodes) {
        throw const FormatException('Clipboard HTML node limit');
      }
      if (node is dom.Comment) {
        if (node.data == 'StartFragment') started = true;
        if (node.data == 'EndFragment' && started) ended = true;
      } else if (node is dom.Element) {
        final inside = started;
        final children = visit(node.nodes, depth + 1);
        if (children.isNotEmpty || inside && !ended) {
          final clone = node.clone(false)..nodes.addAll(children);
          if (!inside || ended) {
            clone._preserveClipboardAutoDirection(_resolvedAutoDirection(node));
          }
          selected.add(clone);
        }
      } else if (started) {
        selected.add(node.clone(false));
      }
    }
    return selected;
  }

  final selected = visit(nodes, 0);
  return ended ? selected : null;
}

dom.Element _element(
  String tag,
  Iterable<dom.Node> children, [
  Map<String, String> attrs = const {},
]) {
  return dom.Element.tag(tag)
    ..attributes.addAll(attrs)
    ..nodes.addAll(children);
}

class _HtmlWriter {
  _HtmlWriter(this.sourcePath, this.mediaPaths);
  final String sourcePath;
  final Map<String, String> mediaPaths;
  var count = 0;

  void visit(int depth) {
    if (++count > maxRawHtmlNodes || depth > maxRawHtmlDepth) {
      throw const FormatException('Clipboard HTML is too complex');
    }
  }

  String? url(String? value, String tag, String attribute) {
    if (value == null || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null) return null;
    final mediaPath = attribute == 'src' ? mediaPaths[value] : null;
    if (mediaPath != null) {
      return withReferenceSuffix(Uri.file(mediaPath), uri).toString();
    }
    if (uri.scheme == 'file') return uri.toString();
    if (!isSafeHtmlUrlAttribute(tag, attribute, value)) return null;
    return !uri.hasScheme && !value.startsWith('#') && sourcePath.isNotEmpty
        ? Uri.file(p.absolute(sourcePath)).resolveUri(uri).toString()
        : value;
  }

  List<dom.Node> blocks(List<BusyBlock> values, [int depth = 0]) {
    final out = <dom.Node>[];
    for (var i = 0; i < values.length; i++) {
      final b = values[i];
      visit(depth);
      if (b.isSourceOnly || b.kind == BusyBlockKind.frontMatter) continue;
      if (_isList(b)) {
        final ordered = _ordered(b);
        final firstIndex = i;
        final list = dom.Element.tag(ordered ? 'ol' : 'ul');
        final start = int.tryParse(
          (b.attributes['marker'] ?? '').replaceAll(RegExp(r'\D'), ''),
        );
        if (ordered && start != null && start != 1) {
          list.attributes['start'] = '$start';
        }
        while (i < values.length &&
            _isList(values[i]) &&
            _ordered(values[i]) == ordered &&
            (i == firstIndex ||
                !ordered ||
                !busyMarkStartsSeparateOrderedList(values[i - 1], values[i]))) {
          final item = values[i++];
          final li = dom.Element.tag('li');
          if (item.kind == BusyBlockKind.taskListItem) {
            li.nodes.add(
              dom.Text(item.attributes['task'] == 'true' ? '☑ ' : '☐ '),
            );
          }
          li.nodes.addAll(inlines(item.inlines, depth + 1));
          li.nodes.addAll(blocks(item.children, depth + 1));
          list.nodes.add(li);
        }
        i--;
        out.add(list);
        continue;
      }
      List<dom.Node> content() => inlines(b.inlines, depth + 1);
      switch (b.kind) {
        case BusyBlockKind.heading:
          final level = (int.tryParse(b.attributes['level'] ?? '') ?? 1).clamp(
            1,
            6,
          );
          out.add(_element('h$level', content()));
          out.addAll(blocks(b.children, depth + 1));
        case BusyBlockKind.paragraph:
          out.add(_element('p', content()));
          out.addAll(blocks(b.children, depth + 1));
        case BusyBlockKind.codeBlock:
          out.add(
            _element('pre', [
              _element(
                'code',
                [dom.Text(b.plainText)],
                {
                  if (b.attributes['language'] case final language?)
                    'class': 'language-$language',
                },
              ),
            ]),
          );
        case BusyBlockKind.thematicBreak:
          out.add(dom.Element.tag('hr'));
        case BusyBlockKind.table:
          final table = dom.Element.tag('table')..attributes['border'] = '1';
          for (final row in b.children) {
            final tr = dom.Element.tag('tr');
            for (final cell in row.children) {
              final header =
                  cell.attributes['header'] == 'true' ||
                  cell.attributes['cell'] == 'th' ||
                  row.attributes['header'] == 'true';
              tr.nodes.add(
                _element(
                  header ? 'th' : 'td',
                  [
                    ...inlines(cell.inlines, depth + 1),
                    ...blocks(cell.children, depth + 1),
                  ],
                  {
                    for (final key in ['rowspan', 'colspan', 'align'])
                      if (cell.attributes[key] case final value?) key: value,
                  },
                ),
              );
            }
            table.nodes.add(tr);
          }
          out.add(table);
        case BusyBlockKind.blockquote:
        case BusyBlockKind.writersideAdmonition:
          out.add(
            _element('blockquote', [
              ...content(),
              ...blocks(b.children, depth + 1),
            ]),
          );
        case BusyBlockKind.image:
          if (b.inlines.isNotEmpty) {
            out.add(_element('p', content()));
          } else {
            out.add(image(b.attributes['src'], b.attributes['alt'] ?? ''));
          }
        case BusyBlockKind.video:
          final href = url(b.attributes['src'], 'a', 'href');
          out.add(
            _element('p', [
              _element(
                'a',
                [dom.Text(b.attributes['title'] ?? 'Video')],
                {if (href != null) 'href': href},
              ),
            ]),
          );
        case BusyBlockKind.htmlBlock:
          final fragment = const RawHtmlAdapter().parseSafeRawHtml(
            b.rawSource ?? '',
          );
          if (fragment != null) {
            for (final node in fragment.nodes) {
              _prepareRawNode(node, depth + 1);
            }
            out.addAll(fragment.nodes.toList());
          } else {
            out.add(_element('pre', [dom.Text(b.rawSource ?? b.plainText)]));
          }
        default:
          if (b.children.isNotEmpty) {
            out.add(
              _element('div', [...content(), ...blocks(b.children, depth + 1)]),
            );
          } else {
            out.add(_element('pre', [dom.Text(b.rawSource ?? b.plainText)]));
          }
      }
    }
    return out;
  }

  void _prepareRawNode(dom.Node node, int depth) {
    visit(depth);
    if (node is dom.Element) {
      final tag = node.localName!;
      final attributes = sanitizeHtmlAttributes(tag, node.attributes)!;
      node.attributes.clear();
      for (final entry in attributes.entries) {
        final value = const {'href', 'src', 'cite'}.contains(entry.key)
            ? url(entry.value, tag, entry.key)
            : entry.value;
        if (value != null) node.attributes[entry.key] = value;
      }
    }
    for (final child in node.nodes) {
      _prepareRawNode(child, depth + 1);
    }
  }

  bool _isList(BusyBlock b) => {
    BusyBlockKind.unorderedListItem,
    BusyBlockKind.orderedListItem,
    BusyBlockKind.taskListItem,
  }.contains(b.kind);
  bool _ordered(BusyBlock b) =>
      b.kind == BusyBlockKind.orderedListItem ||
      b.attributes['ordered'] == 'true';
  dom.Node image(String? src, String alt, [String? title]) {
    final resolved = url(src, 'img', 'src');
    return resolved == null
        ? dom.Text(alt)
        : _element('img', [], {
            'src': resolved,
            'alt': alt,
            if (title != null) 'title': title,
          });
  }

  List<dom.Node> inlines(List<BusyInline> values, int depth) {
    final out = <dom.Node>[];
    for (final value in values) {
      visit(depth);
      List<dom.Node> children() => value.children.isEmpty
          ? <dom.Node>[dom.Text(value.text)]
          : inlines(value.children, depth + 1);
      if (semanticHtmlInlineElement(value) case final element?) {
        if (element.attributes.remove('cite') case final cite?) {
          final resolved = url(cite, element.localName!, 'cite');
          if (resolved != null) element.attributes['cite'] = resolved;
        }
        out.add(element..nodes.addAll(children()));
        continue;
      }
      switch (value.kind) {
        case BusyInlineKind.strong:
          out.add(_element('strong', children()));
        case BusyInlineKind.emphasis:
          out.add(_element('em', children()));
        case BusyInlineKind.underline:
          out.add(_element('u', children()));
        case BusyInlineKind.strikethrough:
          out.add(_element('del', children()));
        case BusyInlineKind.code:
          out.add(_element('code', [dom.Text(value.text)]));
        case BusyInlineKind.hardBreak:
          out.add(dom.Element.tag('br'));
        case BusyInlineKind.softBreak:
          out.add(dom.Text('\n'));
        case BusyInlineKind.image:
          out.add(
            image(value.destination, value.text, value.attributes['title']),
          );
        case BusyInlineKind.link:
          final href = url(value.destination, 'a', 'href');
          out.add(
            _element('a', children(), {
              if (href != null) 'href': href,
              if (value.attributes['title'] case final title?) 'title': title,
            }),
          );
        default:
          out.addAll(children());
      }
    }
    return out;
  }
}

class _HtmlNormalizer {
  _HtmlNormalizer({required this.external});

  final bool external;
  var count = 0;
  static const _formattingTags = ['strong', 'em', 'u', 'del'];
  static const _discard = {
    'script',
    'style',
    'head',
    'title',
    'meta',
    'link',
    'iframe',
    'object',
    'embed',
    'template',
    'svg',
    'math',
  };

  List<dom.Node> nodes(
    Iterable<dom.Node> input,
    int depth,
    Set<String> styles, {
    bool preformatted = false,
  }) {
    if (depth > maxRawHtmlDepth) {
      throw const FormatException('Clipboard HTML nesting limit');
    }
    final out = <dom.Node>[];
    final siblings = input.toList();
    for (var index = 0; index < siblings.length; index++) {
      final node = siblings[index];
      if (++count > maxRawHtmlNodes) {
        throw const FormatException('Clipboard HTML node limit');
      }
      if (node is dom.Text) {
        if (preformatted) {
          out.add(dom.Text(node.data));
          continue;
        }
        bool structural(dom.Node? sibling) =>
            sibling is dom.Element &&
            isSafeBlockHtmlTag(sibling.localName ?? '');
        final before = index > 0 ? siblings[index - 1] : null;
        final after = index + 1 < siblings.length ? siblings[index + 1] : null;
        var data = node.data;
        final leading = data.substring(0, data.length - data.trimLeft().length);
        final trailing = data.substring(data.trimRight().length);
        if ((before == null || structural(before)) &&
            RegExp(r'[\r\n]').hasMatch(leading)) {
          data = data.trimLeft();
        }
        if ((after == null || structural(after)) &&
            RegExp(r'[\r\n]').hasMatch(trailing)) {
          data = data.trimRight();
        }
        if (data.trim().isEmpty) {
          // Indentation between blocks is layout. Newlines at a container's
          // edges are also layout; explicit horizontal inline spaces are text.
          if (structural(before) ||
              structural(after) ||
              ((before == null || after == null) &&
                  RegExp(r'[\r\n]').hasMatch(node.data))) {
            continue;
          }
        }
        out.add(_styled(dom.Text(data), styles));
        continue;
      }
      if (node is! dom.Element) continue;
      var tag = node.localName ?? '';
      if (_discard.contains(tag) ||
          (external && node.attributes.containsKey('hidden'))) {
        continue;
      }
      if (tag == 'input') {
        if (node.attributes['type']?.toLowerCase() == 'checkbox') {
          out.add(
            dom.Text(node.attributes.containsKey('checked') ? '☑ ' : '☐ '),
          );
        }
        continue;
      }
      tag = switch (tag) {
        'b' => 'strong',
        'i' => 'em',
        's' || 'strike' => 'del',
        'font' => 'span',
        _ => tag,
      };
      // Semantic tags and CSS contribute to the same set. Wrapping both
      // produces duplicate emphasis (e.g. ******title******) after paste.
      final inherited = {...styles, if (_formattingTags.contains(tag)) tag};
      var hidden = false;
      for (final declaration in (node.attributes['style'] ?? '').split(';')) {
        final colon = declaration.indexOf(':');
        if (colon < 0) continue;
        final name = declaration.substring(0, colon).trim().toLowerCase();
        final value = declaration
            .substring(colon + 1)
            .replaceAll('!important', '')
            .trim()
            .toLowerCase();
        if (name == 'display') {
          hidden = value == 'none';
        } else if (name == 'font-weight') {
          if (value == 'bold' || (int.tryParse(value) ?? 0) >= 600) {
            inherited.add('strong');
          } else if (value == 'normal' || (int.tryParse(value) ?? 600) < 600) {
            inherited.remove('strong');
          }
        } else if (name == 'font-style') {
          if (value == 'italic' || value == 'oblique') {
            inherited.add('em');
          } else if (value == 'normal') {
            inherited.remove('em');
          }
        } else if (name == 'text-decoration' ||
            name == 'text-decoration-line') {
          if (value.contains('underline')) inherited.add('u');
          if (value.contains('line-through')) inherited.add('del');
          if (value == 'none') {
            inherited
              ..remove('u')
              ..remove('del');
          }
        }
      }
      if (external && hidden) continue;
      final autoDirection = _resolvedAutoDirection(node);
      if (!isSafeHtmlTag(tag)) {
        out.addAll(
          nodes(node.nodes, depth + 1, inherited, preformatted: preformatted),
        );
        continue;
      }
      final attrs = <String, String>{};
      for (final entry in node.attributes.entries) {
        final name = entry.key.toString().toLowerCase();
        if (name == 'style' || name.startsWith('on')) continue;
        if (external && name.startsWith('data-')) continue;
        if (external && name == 'class') {
          if (tag == 'pre' || tag == 'code') {
            final languages = entry.value
                .split(RegExp(r'\s+'))
                .where(
                  (name) =>
                      name.startsWith('language-') || name.startsWith('lang-'),
                );
            if (languages.isNotEmpty) {
              attrs[name] = languages
                  .map(
                    (name) => name.startsWith('lang-')
                        ? 'language-${name.substring(5)}'
                        : name,
                  )
                  .join(' ');
            }
          }
          continue;
        }
        if (isSafeHtmlUrlAttribute(tag, name, entry.value)) {
          attrs[name] = entry.value;
        }
      }
      final attributes = sanitizeHtmlAttributes(tag, attrs) ?? {};
      if (_formattingTags.contains(tag)) {
        if (attributes.isEmpty) {
          tag = 'span';
        } else {
          // This element owns semantic metadata. Its wrapper already supplies
          // the corresponding style, so do not recreate it on each child.
          inherited.remove(tag);
        }
      }
      final inlineCode = tag == 'code' && !preformatted;
      final children = nodes(
        node.nodes,
        depth + 1,
        inlineCode ? const {} : inherited,
        preformatted:
            preformatted || (external && (tag == 'pre' || tag == 'code')),
      );
      final normalized = _element(tag, children, attributes)
        .._preserveClipboardAutoDirection(autoDirection);
      if (external &&
          tag == 'a' &&
          !_hasImportedAnchorContent(normalized) &&
          node.querySelector('video, audio, picture') != null) {
        if (normalized.attributes['href'] case final destination?) {
          final label =
              node.attributes['aria-label'] ?? node.attributes['title'];
          normalized.nodes.add(
            dom.Text(
              label == null || label.trim().isEmpty ? destination : label,
            ),
          );
        }
      }
      if (external &&
          tag == 'a' &&
          !normalized.attributes.containsKey('id') &&
          !_hasImportedAnchorContent(normalized)) {
        // Keep its spacing and any breaks for the paragraph boundary pass.
        out.addAll(normalized.nodes.toList());
      } else if (tag == 'span' && normalized.attributes.isEmpty) {
        out.addAll(normalized.nodes.toList());
      } else if (external &&
          tag == 'table' &&
          _isLayoutTable(normalized, node)) {
        // Web pages often use a one-column table to wrap an entire article.
        // Sending that wrapper to the table adapter flattens its headings,
        // paragraphs, lists and nested data tables into inline cell text.
        // Keep each cell as a block container and retain real tables inside it.
        out.addAll(_layoutContainers(normalized));
      } else {
        // The model reads code as a single text leaf. External styles belong
        // around that leaf, and its whitespace belongs inside it.
        out.add(inlineCode ? _styled(normalized, inherited) : normalized);
      }
    }
    return _mergeAdjacentFormatting(out);
  }

  dom.Node _styled(dom.Node node, Set<String> styles) {
    for (final tag in _formattingTags.where(styles.contains)) {
      node = _element(tag, [node]);
    }
    return node;
  }

  List<dom.Node> _mergeAdjacentFormatting(List<dom.Node> nodes) {
    final result = <dom.Node>[];
    for (final node in nodes) {
      final previous = result.lastOrNull;
      if (node is dom.Element &&
          previous is dom.Element &&
          _formattingTags.contains(node.localName) &&
          node.localName == previous.localName &&
          node.attributes.isEmpty &&
          previous.attributes.isEmpty) {
        final children = _mergeAdjacentFormatting([
          ...previous.nodes,
          ...node.nodes,
        ]);
        previous.nodes.clear();
        previous.nodes.addAll(children);
      } else {
        result.add(node);
      }
    }
    return result;
  }

  List<dom.Node> _layoutContainers(dom.Element element) {
    final tag = element.localName!;
    final attributes =
        sanitizeHtmlAttributes('div', element.attributes) ?? <String, String>{};
    if (tag == 'table' &&
        const {'none', 'presentation'}.contains(attributes['role'])) {
      attributes.remove('role');
    }
    final leaf = const {'caption', 'td', 'th'}.contains(tag);
    final children = leaf
        ? element.nodes.toList()
        : [for (final child in element.children) ..._layoutContainers(child)];
    // Cells and captions delimit flows. Structural shells only need a
    // replacement element when they carry semantics of their own.
    return leaf || attributes.isNotEmpty
        ? [_element('div', children, attributes)]
        : children;
  }

  Iterable<dom.Element> _tableRows(dom.Element table) sync* {
    for (final child in table.children) {
      if (child.localName == 'tr') {
        yield child;
      } else if (const {'thead', 'tbody', 'tfoot'}.contains(child.localName)) {
        yield* child.children.where((row) => row.localName == 'tr');
      }
    }
  }

  bool _isLayoutTable(dom.Element table, dom.Element original) {
    final normalizedRole = original.attributes['role']?.trim().toLowerCase();
    final rows = _tableRows(table).toList();
    if (table.attributes.containsKey('summary') ||
        table.children.any((child) => child.localName == 'colgroup') ||
        rows
            .expand((row) => row.children)
            .any(
              (cell) =>
                  cell.localName == 'th' ||
                  cell.attributes.containsKey('rowspan') ||
                  cell.attributes.containsKey('colspan'),
            )) {
      return false;
    }
    if (normalizedRole == 'presentation' || normalizedRole == 'none') {
      return true;
    }
    if (const {'table', 'grid', 'treegrid'}.contains(normalizedRole) ||
        (int.tryParse(original.attributes['border'] ?? '0') ?? 0) > 0 ||
        table.children.any(
          (child) => const {'caption', 'thead'}.contains(child.localName),
        )) {
      return false;
    }
    if (rows.isEmpty) return false;
    var hasDocumentContent = false;
    for (final row in rows) {
      final cells = row.children
          .where((cell) => cell.localName == 'td' || cell.localName == 'th')
          .toList();
      if (cells.length != 1) return false;
      final cell = cells.single;
      if (cell.localName == 'th' ||
          (int.tryParse(cell.attributes['colspan'] ?? '1') ?? 1) != 1 ||
          (int.tryParse(cell.attributes['rowspan'] ?? '1') ?? 1) != 1) {
        return false;
      }
      hasDocumentContent =
          hasDocumentContent ||
          cell.querySelector('table, h1, h2, h3, h4, h5, h6, ul, ol, pre') !=
              null ||
          cell.querySelectorAll('p').length > 1;
    }
    return hasDocumentContent;
  }
}

void _normalizeClipboardSemantics(dom.Element root) {
  final referencedIds = <String>{};
  for (final anchor in root.querySelectorAll('a[href]')) {
    final href = anchor.attributes['href']!;
    if (href.startsWith('#')) {
      final target = Uri.tryParse(href)?.fragment;
      if (target != null && target.isNotEmpty) referencedIds.add(target);
    }
  }

  for (final attribute in const [
    'aria-labelledby',
    'aria-describedby',
    'aria-details',
  ]) {
    for (final element in root.querySelectorAll('[$attribute]')) {
      referencedIds.addAll(
        element.attributes[attribute]!.split(RegExp(r'\s+')),
      );
    }
  }

  void visit(
    dom.Element element,
    String? inheritedDirection,
    bool inheritedAuto, {
    bool ltrInlineFlow = false,
  }) {
    final tag = element.localName!;
    final attrs = element.attributes;
    final block = isSafeBlockHtmlTag(tag);
    final direction = busyMarkHtmlDirection(attrs['dir']);
    if (direction == null ||
        (!inheritedAuto &&
            inheritedDirection != 'rtl' &&
            (direction == 'ltr' || direction == 'auto') &&
            (block ? _hasOnlyLtrFlow(element) : ltrInlineFlow))) {
      attrs.remove('dir');
    } else {
      attrs['dir'] = direction;
    }

    // Preserve destinations referenced within the selection. Other site IDs
    // can collide with the destination document's anchors.
    if (tag != 'a' && !referencedIds.contains(attrs['id'])) {
      attrs.remove('id');
    }
    if (tag == 'a' && attrs['aria-label']?.trim() == element.text.trim()) {
      attrs.remove('aria-label');
    }
    final role = attrs['role']?.trim().toLowerCase();
    if (role == 'link' &&
        !attrs.containsKey('href') &&
        const {'a', 'div', 'p', 'span'}.contains(tag) &&
        element.querySelector('a[href]') == null) {
      attrs.remove('role');
      attrs.remove('aria-label');
      _unwrapWholeLabel(element, 'u');
    }
    final headingLevel = const {
      'h1': 1,
      'h2': 2,
      'h3': 3,
      'h4': 4,
      'h5': 5,
      'h6': 6,
    }[tag];
    final ariaLevel = int.tryParse(attrs['aria-level'] ?? '');
    final roleHeadingLevel =
        role == 'heading' && (attrs['aria-level'] == null || ariaLevel != null)
        ? ariaLevel ?? 2
        : null;
    if (headingLevel != null &&
        (role == null || role == 'heading') &&
        (attrs['aria-level'] == null || ariaLevel == headingLevel)) {
      attrs.remove('role');
      attrs.remove('aria-level');
    } else if (headingLevel == null &&
        roleHeadingLevel != null &&
        roleHeadingLevel >= 1 &&
        roleHeadingLevel <= 6 &&
        const {'div', 'p'}.contains(tag) &&
        element.children.every(
          (child) => !isSafeBlockHtmlTag(child.localName!),
        )) {
      attrs.remove('role');
      attrs.remove('aria-level');
      final heading = _element(
        'h$roleHeadingLevel',
        element.nodes.toList(),
        attrs.cast<String, String>(),
      );
      element.replaceWith(heading);
      visit(heading, inheritedDirection, inheritedAuto);
      return;
    } else if (role != null &&
        role ==
            const {
              'p': 'paragraph',
              'ol': 'list',
              'ul': 'list',
              'li': 'listitem',
              'a': 'link',
              'img': 'img',
              'table': 'table',
              'tr': 'row',
              'td': 'cell',
            }[tag]) {
      attrs.remove('role');
    }

    if (headingLevel != null) _unwrapWholeLabel(element, 'strong');
    final effectiveDirection = busyMarkResolvedHtmlDirection(element);
    final automaticScope =
        attrs['dir'] == 'auto' ||
        tag == 'bdi' && attrs['dir'] == null ||
        effectiveDirection == null && inheritedAuto;
    final flowDirection = effectiveDirection ?? inheritedDirection;
    // Check the whole inline flow before removing an isolated direction.
    // Each nested block establishes its own flow.
    final sharedLtrFlow =
        !automaticScope &&
        flowDirection != 'rtl' &&
        (block
            ? tag != 'pre' &&
                  element.querySelector('[dir]') != null &&
                  _hasOnlyLtrFlow(element, inlineOnly: true)
            : ltrInlineFlow);
    for (final child in element.children.toList()) {
      visit(child, flowDirection, automaticScope, ltrInlineFlow: sharedLtrFlow);
    }
  }

  visit(root, null, false);
}

// Markdown resolves each visible block from its own first strong character.
// A neutral, mixed, or independently scoped descendant can make removing a
// browser direction change the result even if the wrapper starts with Latin.
bool _hasOnlyLtrFlow(dom.Element element, {bool inlineOnly = false}) {
  var text = StringBuffer();
  var hasStrongText = false;
  var checkInlineIsolation = inlineOnly;
  final breakOffsets = <int>[];

  bool hasLtrLines(String value) {
    if (breakOffsets.isEmpty) return true;
    var start = 0;
    bool through(int end) {
      final line = value.substring(start, end);
      start = end;
      return line.trim().isEmpty || Bidi.startsWithLtr(line);
    }

    return breakOffsets.every(through) && through(value.length);
  }

  bool flush() {
    final value = text.toString();
    final checkIsolation = checkInlineIsolation;
    text = StringBuffer();
    checkInlineIsolation = inlineOnly;
    final empty = value.trim().isEmpty;
    final ltr =
        empty ||
        (Bidi.startsWithLtr(value) &&
            !Bidi.hasAnyRtl(value) &&
            (!checkIsolation ||
                !_unprovenLtrFlow.hasMatch(value) && hasLtrLines(value)));
    breakOffsets.clear();
    if (!empty) hasStrongText = ltr;
    return ltr;
  }

  bool appendInline(dom.Node node) {
    if (node is dom.Text) {
      text.write(node.data);
    } else if (node is dom.Element) {
      final tag = node.localName!;
      final direction = busyMarkHtmlDirection(node.attributes['dir']);
      if (isSafeBlockHtmlTag(tag) ||
          const {'bdi', 'bdo', 'img'}.contains(tag) ||
          direction == 'rtl') {
        return false;
      }
      if (direction != null) {
        if (voidHtmlTags.contains(tag) ||
            (tag == 'code' &&
                (node.children.isNotEmpty ||
                    node.text.isEmpty ||
                    node.text.contains(RegExp(r'[\r\n]'))))) {
          return false;
        }
        checkInlineIsolation = true;
      }
      // Browser break runs can become separate Markdown paragraphs. Each
      // must still have its own strong text once the direction is removed.
      if (tag == 'br') breakOffsets.add(text.length);
      return node.nodes.every(appendInline);
    }
    return true;
  }

  for (final node in element.nodes) {
    if (node is dom.Element && isSafeBlockHtmlTag(node.localName!)) {
      if (!flush()) return false;
      if (!inlineOnly) {
        if (busyMarkHtmlDirection(node.attributes['dir']) == 'rtl' ||
            !_hasOnlyLtrFlow(node)) {
          return false;
        }
        hasStrongText = true;
      }
    } else if (!appendInline(node)) {
      return false;
    }
  }
  return flush() && hasStrongText;
}

// A first-strong heuristic alone cannot prove that removing bidi isolation
// leaves the line unchanged. Limit that rewrite to known LTR scripts and
// ordinary neutral characters, with authored bidi controls outside the set.
final _unprovenLtrFlow = RegExp(
  r'[^\x09-\x0d\x20-\x7e\p{Script=Latin}\p{Script=Greek}\p{Script=Cyrillic}'
  r'\u00a0\u2000-\u200a\u2010-\u2027\u202f\u2030-\u205e]',
  unicode: true,
);

void _unwrapWholeLabel(dom.Element element, String tag) {
  final label = element.children.singleOrNull;
  if (label?.localName != tag ||
      label!.attributes.isNotEmpty ||
      element.nodes.any(
        (node) => node is dom.Text && node.data.trim().isNotEmpty,
      )) {
    return;
  }
  final index = element.nodes.indexOf(label);
  final content = label.nodes.toList();
  element.nodes.removeAt(index);
  element.nodes.insertAll(index, content);
}

// Only line-break runs in paragraph flow are browser spacing. A single break,
// preformatted content, and breaks between words of a link label stay intact.
void _normalizeBrowserParagraphs(dom.Element container) {
  // These are real table cells. Layout tables were already unwrapped into
  // document containers. Keep the entire cell subtree in its inline form.
  final tag = container.localName;
  if (tag == 'td' || tag == 'th') return;
  const flow = {
    'p',
    'div',
    'article',
    'aside',
    'section',
    'header',
    'footer',
    'main',
    'nav',
    'details',
    'blockquote',
    'li',
  };
  for (final child in container.children.toList()) {
    if (child.localName != 'pre' && child.localName != 'code') {
      _normalizeBrowserParagraphs(child);
    }
  }
  if (!flow.contains(tag) ||
      container.attributes.isNotEmpty ||
      container.querySelector('[dir], [id], [lang], bdi, bdo') != null) {
    return;
  }

  // A stream across wrapper boundaries, retaining the original DOM nodes so
  // only participating breaks are removed when the wrappers are split.
  final tokens = <dom.Node>[];
  void collect(dom.Node node) {
    if (node is! dom.Element ||
        node.localName == 'br' ||
        isSafeBlockHtmlTag(node.localName ?? '') ||
        const {'img', 'video', 'audio', 'code'}.contains(node.localName)) {
      tokens.add(node);
      return;
    }
    final start = tokens.length;
    for (final child in node.nodes) {
      collect(child);
    }
    if (node.localName == 'a') {
      final label = tokens.sublist(start);
      final first = label.indexWhere(_hasImportedAnchorContent);
      final last = label.lastIndexWhere(_hasImportedAnchorContent);
      if (first >= 0) {
        tokens.replaceRange(start + first, start + last + 1, [node]);
      }
    }
  }

  for (final node in container.nodes) {
    collect(node);
  }
  final separators = <dom.Node, bool>{};
  final run = <dom.Node>[];
  var breaks = 0;
  void finishRun() {
    if (breaks >= 2) {
      for (final (index, node) in run.indexed) {
        separators[node] = index == 0;
      }
    }
    run.clear();
    breaks = 0;
  }

  for (final node in tokens) {
    if (node is dom.Element && node.localName == 'br') {
      run.add(node);
      breaks++;
    } else if (node is dom.Text && node.data.trim().isEmpty) {
      if (run.isNotEmpty) run.add(node);
    } else {
      finishRun();
    }
  }
  finishRun();
  if (separators.isEmpty) return;

  final output = <dom.Node>[];
  var paragraph = <dom.Node>[];
  void flush() {
    if (paragraph.any(_hasImportedAnchorContent) ||
        paragraph.any((node) => node is dom.Element)) {
      output.add(
        _element(
          'p',
          paragraph,
          tag == 'p' ? container.attributes.cast<String, String>() : const {},
        ),
      );
    }
    paragraph = [];
  }

  final wrapperCopies = <dom.Element, dom.Element>{};
  void copy(dom.Node node, List<dom.Element> wrappers) {
    if (separators[node] case final boundary?) {
      if (boundary) flush();
      return;
    }
    if (node is dom.Element &&
        !isSafeBlockHtmlTag(node.localName ?? '') &&
        node.nodes.isNotEmpty &&
        !const {'code', 'kbd', 'samp'}.contains(node.localName)) {
      for (final child in node.nodes) {
        copy(child, [...wrappers, node]);
      }
      return;
    }
    if (node is dom.Element &&
        isSafeBlockHtmlTag(node.localName ?? '') &&
        node.localName != 'img') {
      flush();
      output.add(node.clone(true));
      return;
    }
    var destination = paragraph;
    for (final wrapper in wrappers) {
      final last = destination.lastOrNull;
      if (last is dom.Element && identical(last, wrapperCopies[wrapper])) {
        destination = last.nodes;
      } else {
        final clone = wrapper.clone(false);
        wrapperCopies[wrapper] = clone;
        destination.add(clone);
        destination = clone.nodes;
      }
    }
    destination.add(node.clone(true));
  }

  for (final node in container.nodes) {
    copy(node, const []);
  }
  flush();
  if (tag == 'p') {
    final parent = container.parentNode;
    if (parent != null) {
      final index = parent.nodes.indexOf(container);
      parent.nodes.removeAt(index);
      parent.nodes.insertAll(index, output);
    }
  } else {
    container.nodes
      ..clear()
      ..addAll(output);
  }
}

bool _hasImportedAnchorContent(dom.Node node) {
  if (node is dom.Text) return node.data.trim().isNotEmpty;
  if (node is! dom.Element) return false;
  return const {'img', 'video', 'audio', 'source'}.contains(node.localName) ||
      node.nodes.any(_hasImportedAnchorContent);
}
