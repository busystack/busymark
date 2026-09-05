import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:path/path.dart' as p;
import '../markdown/busymark_document.dart';
import '../core/path_utils.dart';
import '../markdown/raw_html_policy.dart';
import '../visualization/visualization_models.dart';
import '../writerside/writerside_document.dart';
import 'html_export_links.dart';
import 'html_export_models.dart';
import 'html_publication_plan.dart';
import 'html_rich_content.dart';
import 'markdown_export_document.dart';

// Every string enters the DOM as text or a validated attribute. Source HTML
// takes the separate structural allowlist path below; it is never interpolated.
dom.Element _el(
  String tag, {
  String? text,
  Map<String, String> attrs = const {},
  Iterable<dom.Node> children = const [],
}) {
  final result = dom.Element.tag(tag)..attributes.addAll(attrs);
  if (text != null) result.nodes.add(dom.Text(text));
  result.nodes.addAll(children);
  return result;
}

class HtmlDocumentWriter {
  HtmlDocumentWriter({
    required this.page,
    required this.plan,
    required this.links,
    required this.rich,
    required this.stylesheet,
    required this.warnings,
    this.limits = const HtmlExportLimits(),
    this.navigationLabel = 'Documentation',
    this.outlineLabel = 'On this page',
    this.workInProgressLabel = 'Work in progress',
    this.contentLabel = 'Content',
    this.disclosureLabel = 'Details',
  });
  final HtmlPage page;
  final HtmlPublicationPlan plan;
  final HtmlExportLinks links;
  final HtmlRichContent rich;
  final String stylesheet;
  final List<HtmlExportWarning> warnings;
  final HtmlExportLimits limits;
  final String navigationLabel,
      outlineLabel,
      workInProgressLabel,
      contentLabel,
      disclosureLabel;
  final List<String> _rules = [];
  final Set<String> _emittedIds = {};
  int _rawNodes = 0;

  void _warn(String code, String message, BusyBlock? block) => warnings.add(
    HtmlExportWarning(
      code,
      message,
      sourcePath: block == null
          ? page.sourcePath
          : links.source(page, block.attributes),
      line: block?.sourceSpan?.startLine ?? 1,
    ),
  );

  Future<String> write() async {
    var contentId = 'busymark-content';
    while (page.ids.contains(contentId)) {
      contentId = '$contentId-main';
    }
    final content = await _blocks(page.document.blocks);
    final article = _el('article', children: content);
    if (page.topic?.document.rootElement?.attributes['id'] case final id?
        when !_emittedIds.contains(id)) {
      _attributes(article, {'id': id});
    }
    if (page.workInProgress) {
      article.nodes.insert(
        0,
        _el('p', text: workInProgressLabel, attrs: {'class': 'status'}),
      );
    }
    if (article.querySelector('h1') == null) {
      article.nodes.insert(0, _el('h1', text: page.title));
    }
    final body = _el(
      'body',
      children: [
        _el(
          'a',
          text: contentLabel,
          attrs: {'href': '#$contentId', 'class': 'skip-link'},
        ),
        if (plan.navigation.isNotEmpty)
          _el(
            'nav',
            attrs: {'class': 'instance-nav', 'aria-label': navigationLabel},
            children: [
              _el(
                'details',
                attrs: {'open': ''},
                children: [
                  _el('summary', text: plan.title ?? navigationLabel),
                  await _navigation(plan.navigation),
                ],
              ),
            ],
          ),
        _el(
          'main',
          attrs: {'id': contentId, 'tabindex': '-1'},
          children: [
            if (page.outline.where((h) => h.level > 1).length > 1)
              _el(
                'nav',
                attrs: {'class': 'outline', 'aria-label': outlineLabel},
                children: [
                  _el(
                    'details',
                    children: [
                      _el('summary', text: outlineLabel),
                      _el(
                        'ul',
                        children: [
                          for (final h in page.outline.where(
                            (h) => h.level > 1,
                          ))
                            _el(
                              'li',
                              children: [
                                _el(
                                  'a',
                                  text: h.title,
                                  attrs: {
                                    'href': '#${Uri.encodeComponent(h.id)}',
                                  },
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            article,
          ],
        ),
      ],
    );
    final css = '$stylesheet\n${_rules.join('\n')}';
    // Meta CSP cannot enforce frame-ancestors or sandbox. All active source
    // content has already been rejected. file: images need an explicit source
    // in browsers that assign each local document an opaque origin.
    final csp =
        "default-src 'none'; script-src 'none'; connect-src 'none'; object-src 'none'; base-uri 'none'; form-action 'none'; frame-src 'none'; font-src 'none'; img-src 'self' file:; media-src 'self' file:; style-src 'sha256-${base64.encode(sha256.convert(utf8.encode(css)).bytes)}'";
    final metadata = page.document.frontMatter;
    final lang = metadata['lang'] ?? metadata['language'] ?? 'und';
    final language =
        RegExp(r'^[A-Za-z]{2,8}(?:-[A-Za-z0-9]{1,8})*$').hasMatch(lang)
        ? lang
        : 'und';
    final head = _el(
      'head',
      children: [
        _el('meta', attrs: {'charset': 'utf-8'}),
        _el(
          'meta',
          attrs: {'http-equiv': 'Content-Security-Policy', 'content': csp},
        ),
        _el(
          'meta',
          attrs: {
            'name': 'viewport',
            'content': 'width=device-width, initial-scale=1',
          },
        ),
        _el('title', text: page.title),
        for (final key in ['author', 'description', 'keywords'])
          if (metadata[key] case final value?)
            _el('meta', attrs: {'name': key, 'content': value}),
        if (metadata['web-summary'] case final summary?
            when !metadata.containsKey('description'))
          _el('meta', attrs: {'name': 'description', 'content': summary}),
        _el('style', text: css),
      ],
    );
    final root = _el(
      'html',
      attrs: {
        'lang': language,
        if ({'rtl', 'ltr', 'auto'}.contains(metadata['dir']))
          'dir': metadata['dir']!,
      },
      children: [head, body],
    );
    _validateBoundary(root);
    return '<!DOCTYPE html>\n${root.outerHtml}\n';
  }

  Future<dom.Element> _navigation(List<HtmlNavigationEntry> entries) async {
    final items = <dom.Node>[];
    for (final entry in entries) {
      if (entry.hidden) continue;
      final url = entry.page == null
          ? HtmlExportLinks.external(entry.href ?? '')
          : Uri.encodeComponent(entry.page!.filename);
      final label =
          '${entry.title}${entry.workInProgress ? ' — $workInProgressLabel' : ''}';
      final title = url == null
          ? _el('span', text: label)
          : _el(
              'a',
              text: label,
              attrs: {
                'href': url,
                if (entry.page == page) 'aria-current': 'page',
              },
            );
      final children = entry.children.where((e) => !e.hidden).toList();
      items.add(
        _el(
          'li',
          children: children.isEmpty
              ? [title]
              : [
                  _el(
                    'details',
                    attrs: {'open': ''},
                    children: [
                      _el('summary', children: [title]),
                      await _navigation(children),
                    ],
                  ),
                ],
        ),
      );
    }
    return _el('ul', children: items);
  }

  String _style(dom.Element element, String declarations) {
    final name = 's${_rules.length}';
    _rules.add('.$name{$declarations}');
    element.classes.add(name);
    return name;
  }

  void _attributes(
    dom.Element element,
    Map<String, String> attributes, {
    bool allowId = true,
  }) {
    final id = attributes['id'];
    if (allowId &&
        id != null &&
        id.isNotEmpty &&
        !RegExp(r'\s|[\x00-\x1f]').hasMatch(id) &&
        _emittedIds.add(id)) {
      element.id = id;
    }
    final direction = attributes['dir'];
    if ({'rtl', 'ltr', 'auto'}.contains(direction)) {
      element.attributes['dir'] = direction!;
    }
    if (attributes['title'] case final title?) {
      element.attributes['title'] = title;
    }
    if (attributes['lang'] case final lang?
        when RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(lang)) {
      element.attributes['lang'] = lang;
    }
  }

  bool _isList(BusyBlock b) => {
    BusyBlockKind.orderedListItem,
    BusyBlockKind.unorderedListItem,
    BusyBlockKind.taskListItem,
  }.contains(b.kind);
  bool _ordered(BusyBlock b) =>
      b.kind == BusyBlockKind.orderedListItem ||
      b.attributes['ordered'] == 'true';
  Future<List<dom.Node>> _blocks(
    List<BusyBlock> blocks, [
    int depth = 0,
  ]) async {
    if (depth > limits.depth) {
      throw const HtmlExportException(
        'Document nesting exceeds the HTML export limit.',
      );
    }
    final result = <dom.Node>[];
    for (var i = 0; i < blocks.length; i++) {
      rich.token.check();
      final b = blocks[i];
      if (_isList(b)) {
        final ordered = _ordered(b);
        final list = _el(ordered ? 'ol' : 'ul');
        final start =
            int.tryParse(
              (b.attributes['marker'] ?? '').replaceAll(RegExp(r'[^0-9-]'), ''),
            ) ??
            1;
        if (ordered && start != 1) list.attributes['start'] = '$start';
        while (i < blocks.length &&
            _isList(blocks[i]) &&
            _ordered(blocks[i]) == ordered) {
          final item = blocks[i];
          final li = _el('li');
          _attributes(li, item.attributes);
          if (item.kind == BusyBlockKind.taskListItem) {
            li.classes.add('task');
            li.nodes.add(
              _el(
                'input',
                attrs: {
                  'type': 'checkbox',
                  'disabled': '',
                  'aria-label': item.plainText,
                  if ((item.attributes['task'] ?? item.attributes['checked']) ==
                      'true')
                    'checked': '',
                },
              ),
            );
          }
          li.nodes.addAll(await _inlines(item.inlines, item));
          li.nodes.addAll(await _blocks(item.children, depth + 1));
          list.nodes.add(li);
          i++;
        }
        i--;
        result.add(list);
        continue;
      }
      if (b.attributes['htmlTag'] == 'caption' &&
          i + 1 < blocks.length &&
          blocks[i + 1].kind == BusyBlockKind.table) {
        result.add(await _table(blocks[++i], depth, caption: b));
        continue;
      }
      result.addAll(await _block(b, depth));
    }
    return result;
  }

  Future<List<dom.Node>> _block(
    BusyBlock b,
    int depth, {
    bool disclosure = true,
  }) async {
    if (b.kind == BusyBlockKind.frontMatter || b.isSourceOnly) return [];
    if (disclosure &&
        b.attributes['element'] != 'deflist' &&
        busyMarkWritersideIsCollapsible(b.attributes)) {
      final details = _el(
        'details',
        attrs: {
          if (busyMarkWritersideInitiallyExpanded(b.attributes)) 'open': '',
        },
      );
      _attributes(details, b.attributes);
      details.nodes.add(
        _el(
          'summary',
          text:
              b.attributes['collapsed-title'] ??
              b.attributes['title'] ??
              (b.plainText.trim().isEmpty ? disclosureLabel : b.plainText),
        ),
      );
      // Strip only the wrapper ID to avoid a duplicate anchor on the heading.
      final attributes = {...b.attributes}..remove('id');
      details.nodes.addAll(
        await _block(
          b.copyWith(attributes: attributes),
          depth + 1,
          disclosure: false,
        ),
      );
      return [details];
    }
    if (b.attributes['html-footnotes'] case final source?) {
      return _raw(source, b);
    }
    if (b.kind == BusyBlockKind.htmlBlock && b.rawSource != null) {
      return _raw(b.rawSource!, b);
    }
    dom.Element element;
    switch (b.kind) {
      case BusyBlockKind.heading:
        element = _el(
          'h${(int.tryParse(b.attributes['level'] ?? '') ?? 1).clamp(1, 6)}',
          children: await _inlines(b.inlines, b),
        );
        _attributes(element, b.attributes);
        return [element, ...await _blocks(b.children, depth + 1)];
      case BusyBlockKind.paragraph:
        element = _el('p', children: await _inlines(b.inlines, b));
        _attributes(element, b.attributes);
        return [element, ...await _blocks(b.children, depth + 1)];
      case BusyBlockKind.codeBlock:
        if (b.attributes['unsupported'] == 'true') {
          _warn(
            'content.unsupported',
            'Unsupported content is shown as source.',
            b,
          );
        }
        final descriptor = VisualizationDescriptor.maybeForFenceLanguage(
          b.attributes['language'],
        );
        if (descriptor != null) {
          final source = links.source(page, b.attributes);
          final result = await rich.diagram(
            b,
            source,
            b.attributes[writersideSourceModuleRootAttribute] ??
                page.module?.rootPath ??
                p.dirname(source),
            '${page.filename}:${b.id}',
          );
          if (result?.reference case final reference?) {
            return [await _reference(reference, b, depth)];
          }
          if (result?.url case final url?) {
            return [
              _el(
                'figure',
                children: [
                  _el(
                    'img',
                    attrs: {
                      'src': url,
                      'alt': '${descriptor.kind.displayName} diagram',
                    },
                  ),
                ],
              ),
            ];
          }
        }
        final language = b.attributes['language'] ?? '';
        element = _el(
          'pre',
          children: [
            _el(
              'code',
              text: b.plainText,
              attrs: {
                if (RegExp(r'^[A-Za-z0-9_+-]{1,40}$').hasMatch(language))
                  'class': 'language-$language',
              },
            ),
          ],
        );
      case BusyBlockKind.math:
        element = _el(
          'div',
          attrs: {'class': 'display-math'},
          children: [await _math(b.plainText, true, b)],
        );
      case BusyBlockKind.table:
        return [await _table(b, depth)];
      case BusyBlockKind.thematicBreak:
        element = _el('hr');
      case BusyBlockKind.image:
        element = _el('figure', children: await _inlines(b.inlines, b));
        if (b.attributes['src'] case final src? when b.inlines.isEmpty) {
          element.nodes.add(
            await _image(src, b.attributes['alt'] ?? '', b.attributes, b),
          );
        }
        if (b.attributes['caption'] case final caption?) {
          element.nodes.add(_el('figcaption', text: caption));
        }
      case BusyBlockKind.video:
        final src = b.attributes['src'] ?? '';
        final external = HtmlExportLinks.external(src);
        if (external != null) {
          _warn('asset.remote', 'Remote video remains an external link.', b);
          element = _el(
            'p',
            children: [
              _el(
                'a',
                text: b.attributes['title'] ?? external,
                attrs: {'href': external},
              ),
            ],
          );
        } else {
          final url = await links.assets.local(
            src,
            sourcePath: links.source(page, b.attributes),
            searchRoots: links.roots(page, b.attributes),
            line: b.sourceSpan?.startLine ?? 1,
          );
          if (url == null) {
            element = _el(
              'p',
              text: b.attributes['title'] ?? 'Video unavailable',
            );
          } else {
            element = _el(
              'video',
              attrs: {'src': url, 'controls': '', 'preload': 'metadata'},
              children: [
                _el(
                  'a',
                  text: b.attributes['title'] ?? p.basename(src),
                  attrs: {'href': url},
                ),
              ],
            );
          }
        }
      case BusyBlockKind.writersideAdmonition:
      case BusyBlockKind.blockquote:
        final style =
            b.attributes['style'] ??
            (b.kind == BusyBlockKind.blockquote ? 'quote' : 'note');
        element = _el(
          style == 'quote' ? 'blockquote' : 'aside',
          attrs: {
            'class':
                'admonition ${const {'tip', 'note', 'warning', 'quote'}.contains(style) ? style : 'note'}',
          },
          children: [
            if (style != 'quote')
              _el(
                'p',
                attrs: {'class': 'admonition-title'},
                text: b.attributes['title'] ?? style,
              ),
            ...await _inlines(b.inlines, b),
            ...await _blocks(b.children, depth + 1),
          ],
        );
      case BusyBlockKind.writersideProcedure:
        element = _el(
          'section',
          attrs: {'class': 'procedure'},
          children: [
            if (b.plainText.isNotEmpty)
              _el('h3', children: await _inlines(b.inlines, b)),
            ...await _blocks(b.children, depth + 1),
          ],
        );
      case BusyBlockKind.writersideTabs:
        if (b.attributes['topic-switcher'] == 'true') return [];
        element = _el(
          'section',
          attrs: {
            'class': b.attributes['element'] == 'tab' ? 'tab-panel' : 'tabs',
          },
          children: [
            if (b.plainText.trim().isNotEmpty || b.attributes['title'] != null)
              _el('h3', text: b.attributes['title'] ?? b.plainText),
            ...await _blocks(b.children, depth + 1),
          ],
        );
      case BusyBlockKind.writersideRawXml:
        final kind = b.attributes['element'];
        if (kind == 'deflist') {
          element = _el('dl');
          for (final child in b.children) {
            element.nodes.add(
              _el('dt', children: await _inlines(child.inlines, child)),
            );
            final definition = _el('dd');
            final content = await _blocks(child.children, depth + 1);
            if (busyMarkWritersideIsCollapsible(child.attributes)) {
              definition.nodes.add(
                _el(
                  'details',
                  attrs: {
                    if (busyMarkWritersideInitiallyExpanded(child.attributes))
                      'open': '',
                  },
                  children: [
                    _el(
                      'summary',
                      text:
                          child.attributes['collapsed-title'] ??
                          disclosureLabel,
                    ),
                    ...content,
                  ],
                ),
              );
            } else {
              definition.nodes.addAll(content);
            }
            _attributes(definition, child.attributes);
            element.nodes.add(definition);
          }
        } else if (b.children.isNotEmpty) {
          element = _el(
            'section',
            children: [
              ...await _inlines(b.inlines, b),
              ...await _blocks(b.children, depth + 1),
            ],
          );
        } else {
          _warn(
            'content.unsupported',
            'Unsupported content is shown as source.',
            b,
          );
          element = _el('pre', text: b.rawSource ?? b.plainText);
        }
      case BusyBlockKind.htmlBlock:
        element = _el(
          b.attributes['htmlTag'] == 'figure' ? 'figure' : 'section',
          attrs: {
            if (b.attributes['writerside-card'] == 'true') 'class': 'card',
          },
          children: [
            ...await _inlines(b.inlines, b),
            ...await _blocks(b.children, depth + 1),
          ],
        );
      case BusyBlockKind.unknown:
        _warn(
          'content.unsupported',
          'Unsupported content is shown as source.',
          b,
        );
        element = _el(
          'pre',
          attrs: {'class': 'unsupported'},
          text: b.rawSource ?? b.plainText,
        );
        element.nodes.addAll(await _blocks(b.children, depth + 1));
      case BusyBlockKind.unorderedListItem:
      case BusyBlockKind.orderedListItem:
      case BusyBlockKind.taskListItem:
        return _blocks([b], depth);
      case BusyBlockKind.frontMatter:
        return [];
    }
    _attributes(element, b.attributes);
    if (b.attributes['switcher-key'] case final key?) {
      return [
        _el(
          'section',
          attrs: {'class': 'switcher-section'},
          children: [
            _el('p', text: key, attrs: {'class': 'variant-label'}),
            element,
          ],
        ),
      ];
    }
    return [element];
  }

  Future<dom.Element> _table(
    BusyBlock b,
    int depth, {
    BusyBlock? caption,
  }) async {
    final table = _el('table');
    _attributes(table, b.attributes);
    if (caption != null) {
      table.nodes.add(
        _el('caption', children: await _inlines(caption.inlines, caption)),
      );
    }
    final head = _el('thead'), body = _el('tbody');
    for (final row in b.children) {
      final tr = _el('tr');
      final header = row.attributes['header'] == 'true';
      for (final cell in row.children) {
        final isHeader =
            cell.attributes['cell'] == 'th' ||
            cell.attributes['header'] == 'true' ||
            (header && cell.attributes['header'] != 'false');
        final td = _el(
          isHeader ? 'th' : 'td',
          attrs: {if (isHeader) 'scope': header ? 'col' : 'row'},
          children: [
            ...await _inlines(cell.inlines, cell),
            ...await _blocks(cell.children, depth + 1),
          ],
        );
        _attributes(td, cell.attributes);
        for (final name in ['rowspan', 'colspan']) {
          final n = int.tryParse(cell.attributes[name] ?? '');
          if (n != null && n > 0 && n <= 1000) td.attributes[name] = '$n';
        }
        final align = cell.attributes['align'];
        if ({'left', 'center', 'right'}.contains(align)) {
          td.classes.add('align-$align');
        }
        _dimension(
          td,
          cell.attributes['width'] ?? cell.attributes['column-width'],
          'width',
        );
        tr.nodes.add(td);
      }
      (header && body.nodes.isEmpty ? head : body).nodes.add(tr);
    }
    if (head.nodes.isNotEmpty) table.nodes.add(head);
    table.nodes.add(body);
    return _el(
      'div',
      attrs: {'class': 'table-scroll', 'tabindex': '0'},
      children: [table],
    );
  }

  void _dimension(dom.Element element, String? value, String name) {
    if (value == null ||
        !RegExp(r'^\d{1,5}(?:\.\d{1,3})?(?:px|%)?$').hasMatch(value)) {
      return;
    }
    final number = double.tryParse(value.replaceAll(RegExp(r'px|%'), ''));
    if (number == null ||
        number <= 0 ||
        number > (value.endsWith('%') ? 100 : 20000)) {
      return;
    }
    _style(
      element,
      '$name:${value.endsWith('%') || value.endsWith('px') ? value : '${value}px'};',
    );
  }

  Future<List<dom.Node>> _inlines(
    List<BusyInline> values,
    BusyBlock block, [
    int depth = 0,
    Map<String, String> inherited = const {},
  ]) async {
    if (depth > limits.depth) {
      throw const HtmlExportException(
        'Inline nesting exceeds the export limit.',
      );
    }
    final out = <dom.Node>[];
    for (final value in values) {
      final a = {...block.attributes, ...inherited, ...value.attributes};
      final nodes = value.children.isEmpty
          ? <dom.Node>[dom.Text(value.text)]
          : await _inlines(value.children, block, depth + 1, a);
      dom.Node node;
      switch (value.kind) {
        case BusyInlineKind.text:
          node = dom.Text(value.text);
        case BusyInlineKind.strong:
          node = _el('strong', children: nodes);
        case BusyInlineKind.emphasis:
          node = _el('em', children: nodes);
        case BusyInlineKind.underline:
          final description =
              a['tooltip-description'] ??
              a['resolved-description'] ??
              (a['element'] == 'tooltip' ? a['summary'] : null);
          node = _el(
            description == null ? 'u' : 'abbr',
            children: nodes,
            attrs: {if (description != null) 'title': description},
          );
        case BusyInlineKind.strikethrough:
          node = _el('del', children: nodes);
        case BusyInlineKind.code:
          var text = value.text;
          if (a['shortcut-layouts'] case final layouts?) {
            try {
              final map = jsonDecode(layouts) as Map;
              if (map.length > 1) {
                text = map.entries
                    .map((e) => '${e.key}: ${e.value}')
                    .join('; ');
              }
            } on Object {
              /* Resolved primary label remains. */
            }
          }
          node = _el(a['element'] == 'shortcut' ? 'kbd' : 'code', text: text);
        case BusyInlineKind.softBreak:
          node = dom.Text('\n');
        case BusyInlineKind.hardBreak:
          node = _el('br');
        case BusyInlineKind.image:
          node = await _image(value.destination ?? '', value.text, a, block);
        case BusyInlineKind.link:
          final url = await links.resolve(
            value.destination,
            page,
            a,
            line: block.sourceSpan?.startLine ?? 1,
          );
          if (url == null) {
            node = _el('span', children: nodes);
          } else {
            node = _el(
              'a',
              children: nodes,
              attrs: {
                'href': url,
                if (a['element'] == 'resource')
                  'download': p.basename(value.text),
                if (a['summary'] case final summary?) 'title': summary,
              },
            );
          }
          if (node is dom.Element) _attributes(node, value.attributes);
          if (value.attributes['id']?.startsWith('fnref') == true) {
            node = _el('sup', children: [node]);
          }
        case BusyInlineKind.math:
          node = await _math(value.text, false, block);
        case BusyInlineKind.html:
          out.addAll(await _raw(value.text, block));
          continue;
        case BusyInlineKind.writersideVariable:
        case BusyInlineKind.unknown:
          _warn(
            'content.unsupported',
            'Unresolved inline content is shown as source.',
            block,
          );
          node = _el('code', text: value.text);
      }
      if (node is dom.Element && value.kind != BusyInlineKind.link) {
        _attributes(node, value.attributes);
      }
      if (value.attributes['switcher-key'] case final key?) {
        node = _el('span', children: [dom.Text('[$key] '), node]);
      }
      out.add(node);
    }
    return out;
  }

  Future<dom.Node> _image(
    String src,
    String alt,
    Map<String, String> a,
    BusyBlock block,
  ) async {
    final url = await links.assets.local(
      src,
      sourcePath: links.source(page, a),
      searchRoots: links.roots(page, a),
      line: block.sourceSpan?.startLine ?? 1,
    );
    if (url == null) {
      final external = HtmlExportLinks.external(src);
      return _el(
        'span',
        attrs: {'class': 'unavailable-image'},
        children: [
          if (external != null)
            _el(
              'a',
              text: alt.isEmpty ? external : alt,
              attrs: {'href': external},
            )
          else
            dom.Text(
              alt.isEmpty ? 'Image unavailable: ${p.basename(src)}' : alt,
            ),
        ],
      );
    }
    final image = _el('img', attrs: {'src': url, 'alt': alt});
    if (a['title'] case final title?) image.attributes['title'] = title;
    _dimension(image, a['width'], 'width');
    _dimension(image, a['height'], 'height');
    return image;
  }

  Future<dom.Node> _math(
    String expression,
    bool display,
    BusyBlock block,
  ) async {
    final fontSize = block.kind == BusyBlockKind.heading
        ? switch (block.attributes['level']) {
            '1' => 39.1,
            '2' => 29.75,
            '3' => 22.1,
            _ => 17.0,
          }
        : 17.0;
    final image = await rich.formula(
      expression,
      display,
      links.source(page, block.attributes),
      block.sourceSpan?.startLine ?? 1,
      fontSize: fontSize,
    );
    if (image == null) {
      return _el('code', text: expression, attrs: {'class': 'math-fallback'});
    }
    final element = _el(
      'img',
      attrs: {
        'src': image.url,
        'alt': expression,
        'class': display ? 'math-display' : 'math-inline',
      },
    );
    if ([
      image.width,
      image.height,
      image.depth,
    ].every((v) => v.isFinite && v.abs() < 20000)) {
      _style(
        element,
        'width:${image.width / fontSize}em;height:${image.height / fontSize}em;${display ? '' : 'vertical-align:-${image.depth / fontSize}em;'}',
      );
    }
    return element;
  }

  /// Narrow HTML adapter: supported structure survives, attributes never pass
  /// through unchecked. Rejected elements remain visible as escaped source.
  Future<List<dom.Node>> _raw(String source, BusyBlock block) async {
    final fragment = parser.parseFragment(source);
    Future<List<dom.Node>> nodes(Iterable<dom.Node> values, int depth) async {
      if (depth > limits.depth) {
        throw const HtmlExportException(
          'Raw HTML nesting exceeds the export limit.',
        );
      }
      final out = <dom.Node>[];
      for (final value in values) {
        if (++_rawNodes > 50000) {
          throw const HtmlExportException('Raw HTML exceeds the node limit.');
        }
        if (value is dom.Text) {
          out.add(dom.Text(value.data));
          continue;
        }
        if (value is! dom.Element) continue;
        final tag = value.localName!;
        if (!safeHtmlTags.contains(tag)) {
          _warn(
            'html.unsupported',
            'Unsafe or unsupported HTML is shown as source.',
            block,
          );
          out.add(_el('code', text: value.outerHtml));
          continue;
        }
        final attrs = value.attributes.map((k, v) => MapEntry(k.toString(), v));
        if (attrs.keys.any(
          (name) =>
              name.startsWith('on') ||
              {'style', 'srcdoc', 'srcset'}.contains(name),
        )) {
          _warn(
            'html.attributes',
            'Active HTML attributes were omitted.',
            block,
          );
        }
        if (tag == 'img') {
          out.add(
            await _image(attrs['src'] ?? '', attrs['alt'] ?? '', {
              ...block.attributes,
              ...attrs,
            }, block),
          );
          continue;
        }
        final element = _el(tag, children: await nodes(value.nodes, depth + 1));
        _attributes(element, attrs);
        if (tag == 'a') {
          final url = await links.resolve(attrs['href'], page, {
            ...block.attributes,
            ...attrs,
          }, line: block.sourceSpan?.startLine ?? 1);
          if (url != null) element.attributes['href'] = url;
        }
        if (tag == 'details') {
          if (attrs.containsKey('open')) element.attributes['open'] = '';
          if (!element.children.any((e) => e.localName == 'summary')) {
            element.nodes.insert(0, _el('summary', text: disclosureLabel));
          }
        }
        for (final name in switch (tag) {
          'ol' => ['start'],
          'li' => ['value'],
          'td' || 'th' => ['rowspan', 'colspan'],
          _ => <String>[],
        }) {
          final n = int.tryParse(attrs[name] ?? '');
          if (n != null &&
              n.abs() <= 10000 &&
              (!name.endsWith('span') || n > 0)) {
            element.attributes[name] = '$n';
          }
        }
        if (tag == 'th' &&
            {'row', 'col', 'rowgroup', 'colgroup'}.contains(attrs['scope'])) {
          element.attributes['scope'] = attrs['scope']!;
        }
        if (tag == 'code' &&
            RegExp(
              r'^language-[A-Za-z0-9_+-]{1,40}$',
            ).hasMatch(attrs['class'] ?? '')) {
          element.attributes['class'] = attrs['class']!;
        }
        if (attrs['class'] == 'footnotes') {
          element.classes.add('footnotes');
          element.attributes['role'] = 'doc-endnotes';
        }
        if ({'left', 'center', 'right'}.contains(attrs['align'])) {
          element.classes.add('align-${attrs['align']}');
        }
        _dimension(element, attrs['width'], 'width');
        out.add(element);
      }
      return out;
    }

    return nodes(fragment.nodes, 0);
  }

  /// OpenAPI already has a structured static representation. Only that output
  /// uses this adapter; ordinary Markdown and Writerside never use the PDF mapper.
  Future<dom.Element> _reference(
    MarkdownExportBlock block,
    BusyBlock owner,
    int depth,
  ) async {
    if (depth > limits.depth) {
      throw const HtmlExportException(
        'API reference nesting exceeds the export limit.',
      );
    }
    Future<List<dom.Node>> inline(List<MarkdownExportInline> values) async =>
        _inlines([for (final i in values) _apiInline(i)], owner);
    final tag = switch (block.kind) {
      MarkdownExportBlockKind.heading =>
        'h${((block.attributes['level'] as int?) ?? 2).clamp(1, 6)}',
      MarkdownExportBlockKind.paragraph => 'p',
      MarkdownExportBlockKind.code => 'pre',
      MarkdownExportBlockKind.table => 'table',
      MarkdownExportBlockKind.tableRow => 'tr',
      MarkdownExportBlockKind.tableCell =>
        block.attributes['header'] == true ? 'th' : 'td',
      MarkdownExportBlockKind.list =>
        block.attributes['ordered'] == true ? 'ol' : 'ul',
      MarkdownExportBlockKind.listItem => 'li',
      MarkdownExportBlockKind.thematicBreak => 'hr',
      MarkdownExportBlockKind.blockquote => 'blockquote',
      _ => 'section',
    };
    final element = _el(
      tag,
      children: [
        if (block.text.isNotEmpty) dom.Text(block.text),
        ...await inline(block.inlines),
      ],
    );
    if (block.kind == MarkdownExportBlockKind.code) {
      final contents = element.nodes.toList();
      element.nodes.clear();
      final language = block.attributes['language']?.toString() ?? '';
      element.nodes.add(
        _el(
          'code',
          children: contents,
          attrs: {
            if (RegExp(r'^[a-zA-Z0-9_+-]{1,32}$').hasMatch(language))
              'class': 'language-$language',
          },
        ),
      );
    }
    if (block.kind == MarkdownExportBlockKind.heading) {
      final base = slugForHeading(element.text).isEmpty
          ? 'api-section'
          : slugForHeading(element.text);
      var id = base;
      var suffix = 2;
      while (page.ids.contains(id)) {
        id = '$base-${suffix++}';
      }
      page.ids.add(id);
      _attributes(element, {'id': id});
      page.outline.add((
        id: id,
        title: element.text,
        level: int.parse(tag.substring(1)),
      ));
    }
    final children = [
      for (final child in block.children)
        await _reference(child, owner, depth + 1),
    ];
    if (tag == 'table') {
      final head = _el('thead');
      final body = _el('tbody');
      for (final row in children) {
        (body.nodes.isEmpty && row.querySelector('th') != null ? head : body)
            .nodes
            .add(row);
      }
      if (head.nodes.isNotEmpty) element.nodes.add(head);
      element.nodes.add(body);
    } else {
      element.nodes.addAll(children);
    }
    if (tag == 'table') {
      return _el(
        'div',
        attrs: {'class': 'table-scroll', 'tabindex': '0'},
        children: [element],
      );
    }
    return element;
  }

  BusyInline _apiInline(MarkdownExportInline value) => BusyInline(
    kind: BusyInlineKind.values.byName(value.kind.name),
    text: value.text,
    destination: value.destination,
    attributes: value.attributes,
    children: value.children.map(_apiInline).toList(),
  );

  void _validateBoundary(dom.Element root) {
    for (final element in [root, ...root.querySelectorAll('*')]) {
      if ({
        'script',
        'iframe',
        'object',
        'embed',
        'form',
        'base',
        'link',
      }.contains(element.localName)) {
        throw const HtmlExportException(
          'Unsafe element at the HTML output boundary.',
        );
      }
      for (final entry in element.attributes.entries) {
        final key = entry.key.toString();
        if (key.startsWith('on') ||
            key == 'style' ||
            key.startsWith('busymark-source')) {
          throw const HtmlExportException(
            'Unsafe attribute at the HTML output boundary.',
          );
        }
        if (key == 'href' || key == 'src') {
          final value = entry.value;
          if (HtmlExportLinks.external(value) != null && key == 'href') {
            continue;
          }
          final uri = Uri.tryParse(value);
          if (uri == null ||
              uri.hasScheme ||
              uri.hasAuthority ||
              uri.path.startsWith('/') ||
              uri.path.split('/').contains('..')) {
            throw const HtmlExportException(
              'Non-portable URL at the HTML output boundary.',
            );
          }
        }
      }
    }
  }
}
