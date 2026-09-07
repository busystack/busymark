import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:path/path.dart' as p;

import '../../markdown/busymark_document.dart';
import '../../markdown/markdown_model.dart';
import '../../markdown/raw_html_adapter.dart';
import '../../markdown/raw_html_policy.dart';
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
  }) {
    if (source.length > maxRichClipboardBytes ||
        utf8.encode(source).length > maxRichClipboardBytes) {
      return null;
    }
    try {
      final start = source.indexOf('<!--StartFragment-->');
      final end = source.indexOf('<!--EndFragment-->');
      final content = start >= 0 && end > start
          ? source.substring(start + '<!--StartFragment-->'.length, end)
          : source;
      final body = html.parse(content).body;
      if (body == null) return null;
      final normalizer = _HtmlNormalizer();
      final clean = dom.Element.tag('div')
        ..nodes.addAll(normalizer.nodes(body.nodes, 0, const {}));
      var id = 0;
      final parsed = const RawHtmlAdapter().parseRawHtmlBlock(
        clean.outerHtml,
        () => 'clipboard-html-${id++}',
      );
      if (parsed == null || !parsed.safe || parsed.blocks.isEmpty) return null;
      BusyBlock task(BusyBlock block) {
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
        return block.copyWith(children: children, dirty: true);
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
    if (attribute == 'src' && mediaPaths[value] != null) {
      return Uri.file(mediaPaths[value]!).toString();
    }
    final uri = Uri.tryParse(value);
    if (uri == null) return null;
    if (uri.scheme == 'file') return uri.toString();
    if (!isSafeHtmlUrlAttribute(tag, attribute, value)) return null;
    return !uri.hasScheme && sourcePath.isNotEmpty
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
        final list = dom.Element.tag(ordered ? 'ol' : 'ul');
        final start = int.tryParse(
          (b.attributes['marker'] ?? '').replaceAll(RegExp(r'\D'), ''),
        );
        if (ordered && start != null && start != 1) {
          list.attributes['start'] = '$start';
        }
        while (i < values.length &&
            _isList(values[i]) &&
            _ordered(values[i]) == ordered) {
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
          final adapted = const RawHtmlAdapter().parseRawHtmlBlock(
            b.rawSource ?? '',
            () => 'html-export-${count++}',
          );
          if (adapted != null && adapted.safe && adapted.blocks.isNotEmpty) {
            out.addAll(blocks(adapted.blocks, depth + 1));
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

  bool _isList(BusyBlock b) => {
    BusyBlockKind.unorderedListItem,
    BusyBlockKind.orderedListItem,
    BusyBlockKind.taskListItem,
  }.contains(b.kind);
  bool _ordered(BusyBlock b) =>
      b.kind == BusyBlockKind.orderedListItem ||
      b.attributes['ordered'] == 'true';
  dom.Node image(String? src, String alt) {
    final resolved = url(src, 'img', 'src');
    return resolved == null
        ? dom.Text(alt)
        : _element('img', [], {'src': resolved, 'alt': alt});
  }

  List<dom.Node> inlines(List<BusyInline> values, int depth) {
    final out = <dom.Node>[];
    for (final value in values) {
      visit(depth);
      List<dom.Node> children() => value.children.isEmpty
          ? <dom.Node>[dom.Text(value.text)]
          : inlines(value.children, depth + 1);
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
          out.add(image(value.destination, value.text));
        case BusyInlineKind.link:
          final href = url(value.destination, 'a', 'href');
          out.add(_element('a', children(), {if (href != null) 'href': href}));
        default:
          out.addAll(children());
      }
    }
    return out;
  }
}

class _HtmlNormalizer {
  var count = 0;
  static const _discard = {
    'script',
    'style',
    'head',
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
    Set<String> styles,
  ) {
    if (depth > maxRawHtmlDepth) {
      throw const FormatException('Clipboard HTML nesting limit');
    }
    final out = <dom.Node>[];
    for (final node in input) {
      if (++count > maxRawHtmlNodes) {
        throw const FormatException('Clipboard HTML node limit');
      }
      if (node is dom.Text) {
        dom.Node text = dom.Text(node.data);
        if (node.data.trim().isNotEmpty) {
          for (final tag in styles) {
            text = _element(tag, [text]);
          }
        }
        out.add(text);
        continue;
      }
      if (node is! dom.Element) continue;
      var tag = node.localName ?? '';
      if (_discard.contains(tag)) continue;
      if (tag == 'input') {
        if (node.attributes['type']?.toLowerCase() == 'checkbox') {
          out.add(
            dom.Text(node.attributes.containsKey('checked') ? '☑ ' : '☐ '),
          );
        }
        continue;
      }
      final inherited = {...styles};
      for (final declaration in (node.attributes['style'] ?? '').split(';')) {
        final colon = declaration.indexOf(':');
        if (colon < 0) continue;
        final name = declaration.substring(0, colon).trim().toLowerCase();
        final value = declaration
            .substring(colon + 1)
            .replaceAll('!important', '')
            .trim()
            .toLowerCase();
        if (name == 'font-weight') {
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
      final children = nodes(node.nodes, depth + 1, inherited);
      tag = switch (tag) {
        'b' => 'strong',
        'i' => 'em',
        'strike' => 'del',
        'font' => 'span',
        _ => tag,
      };
      if (!isSafeHtmlTag(tag)) {
        out.addAll(children);
        continue;
      }
      final attrs = <String, String>{};
      for (final entry in node.attributes.entries) {
        final name = entry.key.toString().toLowerCase();
        if (name == 'style' || name.startsWith('on')) continue;
        // IDs from another document must not collide with destination anchors.
        if (name == 'id') continue;
        if (isSafeHtmlUrlAttribute(tag, name, entry.value)) {
          attrs[name] = entry.value;
        }
      }
      out.add(
        _element(tag, children, sanitizeHtmlAttributes(tag, attrs) ?? const {}),
      );
    }
    return out;
  }
}
