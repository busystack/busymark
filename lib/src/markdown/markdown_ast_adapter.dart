import 'package:markdown/markdown.dart' as md;

import '../core/path_utils.dart';
import 'busymark_document.dart';
import 'markdown_model.dart';

class MarkdownAstAdapter {
  const MarkdownAstAdapter();

  BusyDocument parse({
    required String filePath,
    required String source,
    required MarkdownMode mode,
    String? title,
  }) {
    final frontMatter = _extractFrontMatter(source);
    final imageAttributes = _imageAttributeBlocks(source);
    final markdownSource = frontMatter == null
        ? source
        : source.substring(frontMatter.endOffset).trimLeft();
    final packageSource = _protectProseHyphenLines(markdownSource);
    final document = md.Document(
      extensionSet: md.ExtensionSet.gitHubWeb,
      encodeHtml: false,
    );
    final nodes = document.parse(packageSource);
    var blockIndex = 0;
    final blocks = <BusyBlock>[
      if (frontMatter != null)
        BusyBlock(
          id: 'front-matter',
          kind: BusyBlockKind.frontMatter,
          rawSource: frontMatter.raw,
          preserveRaw: true,
          attributes: frontMatter.values,
        ),
      for (final node in nodes)
        ..._blocksFromNode(node, nextId: () => 'b${blockIndex++}', mode: mode),
    ];
    return BusyDocument(
      filePath: filePath,
      mode: mode,
      title: title,
      blocks: _applyImageAttributes(blocks, imageAttributes),
      frontMatter: frontMatter?.values ?? const {},
      rawFrontMatter: frontMatter?.raw,
      source: source,
    );
  }

  List<BusyBlock> _applyImageAttributes(
    List<BusyBlock> blocks,
    List<Map<String, String>> imageAttributes,
  ) {
    var imageIndex = 0;
    BusyBlock visit(BusyBlock block) {
      final children = block.children.map(visit).toList();
      if (block.kind == BusyBlockKind.image &&
          imageIndex < imageAttributes.length) {
        return block.copyWith(
          children: children,
          attributes: {...block.attributes, ...imageAttributes[imageIndex++]},
        );
      }
      return children.isEmpty ? block : block.copyWith(children: children);
    }

    return blocks.map(visit).toList();
  }

  List<BusyBlock> _blocksFromNode(
    md.Node node, {
    required String Function() nextId,
    required MarkdownMode mode,
  }) {
    if (node is md.Text) {
      final text = node.text.trim();
      if (text.isEmpty) {
        return const [];
      }
      return [
        BusyBlock(
          id: nextId(),
          kind: BusyBlockKind.paragraph,
          inlines: [BusyInline(kind: BusyInlineKind.text, text: text)],
        ),
      ];
    }
    if (node is! md.Element) {
      return [
        BusyBlock(
          id: nextId(),
          kind: BusyBlockKind.unknown,
          rawSource: node.textContent,
          preserveRaw: true,
        ),
      ];
    }

    final tag = node.tag.toLowerCase();
    final children = node.children ?? const <md.Node>[];
    if (_headingLevel(tag) case final level?) {
      final rawText = node.textContent.trim();
      final attrId = _attributeValue(rawText, 'id');
      final text = _stripTrailingAttributeBlock(rawText);
      final id = attrId ?? node.generatedId ?? slugForHeading(text);
      return [
        BusyBlock(
          id: id.isEmpty ? nextId() : id,
          kind: BusyBlockKind.heading,
          inlines: _stripTrailingAttributeInline(_inlinesFromNodes(children)),
          attributes: {
            'level': '$level',
            'id': id,
            'generatedId': '${attrId == null}',
          },
        ),
      ];
    }

    if (tag == 'p') {
      final writerside = _writersideBlockFromText(
        node.textContent,
        nextId: nextId,
      );
      if (writerside != null) {
        return [writerside];
      }
      final inlines = _inlinesFromNodes(children);
      final imageBlock = _imageBlockFromParagraph(node, inlines, nextId);
      if (imageBlock != null) {
        return [imageBlock];
      }
      return [
        BusyBlock(
          id: nextId(),
          kind: BusyBlockKind.paragraph,
          inlines: _normalizeSoftBreaks(inlines),
        ),
      ];
    }

    if (tag == 'pre') {
      final code = children.whereType<md.Element>().firstWhere(
        (element) => element.tag == 'code',
        orElse: () => md.Element.text('code', node.textContent),
      );
      final className = code.attributes['class'] ?? '';
      final language = className.startsWith('language-')
          ? className.substring('language-'.length)
          : '';
      return [
        BusyBlock(
          id: nextId(),
          kind: BusyBlockKind.codeBlock,
          inlines: [
            BusyInline(
              kind: BusyInlineKind.text,
              text: code.textContent.trimRight(),
            ),
          ],
          attributes: {
            if (language.isNotEmpty) 'language': language,
            if (node.attributes['data-metadata'] case final metadata?)
              'metadata': metadata,
          },
        ),
      ];
    }

    if (tag == 'ul' || tag == 'ol') {
      return _listBlocksFromNode(node, ordered: tag == 'ol', nextId: nextId);
    }

    if (tag == 'blockquote') {
      final blocks = [
        for (final child in children)
          ..._blocksFromNode(child, nextId: nextId, mode: mode),
      ];
      return [
        BusyBlock(
          id: nextId(),
          kind: BusyBlockKind.blockquote,
          inlines: blocks.isEmpty
              ? _inlinesFromNodes(children)
              : const <BusyInline>[],
          children: blocks,
        ),
      ];
    }

    if (tag == 'hr') {
      return [BusyBlock(id: nextId(), kind: BusyBlockKind.thematicBreak)];
    }

    if (tag == 'table') {
      return [
        BusyBlock(
          id: nextId(),
          kind: BusyBlockKind.table,
          children: _tableRows(node, nextId),
        ),
      ];
    }

    if (_writersideBlockTag(tag)) {
      return [
        BusyBlock(
          id: nextId(),
          kind: _writersideKind(tag),
          inlines: _inlinesFromNodes(children),
          attributes: {...node.attributes, 'element': tag},
          rawSource: node.textContent,
          preserveRaw: !_editableWritersideTag(tag),
        ),
      ];
    }

    if (_dangerousHtmlTag(tag)) {
      return [
        BusyBlock(
          id: nextId(),
          kind: BusyBlockKind.htmlBlock,
          rawSource: node.textContent,
          preserveRaw: true,
        ),
      ];
    }

    return [
      BusyBlock(
        id: nextId(),
        kind: BusyBlockKind.unknown,
        inlines: _inlinesFromNodes(children),
        rawSource: node.textContent,
        preserveRaw: true,
      ),
    ];
  }

  List<BusyBlock> _listBlocksFromNode(
    md.Element node, {
    required bool ordered,
    required String Function() nextId,
  }) {
    final result = <BusyBlock>[];
    final items =
        node.children?.whereType<md.Element>().where(
          (child) => child.tag == 'li',
        ) ??
        const Iterable<md.Element>.empty();
    var number = int.tryParse(node.attributes['start'] ?? '') ?? 1;
    for (final item in items) {
      final itemChildren = item.children ?? const <md.Node>[];
      final checked = _taskChecked(itemChildren);
      final contentChildren = _withoutTaskCheckbox(itemChildren);
      final nestedBlocks = <BusyBlock>[];
      final inlineNodes = <md.Node>[];
      for (final child in contentChildren) {
        if (child is md.Element &&
            (child.tag == 'ul' ||
                child.tag == 'ol' ||
                child.tag == 'blockquote' ||
                child.tag == 'pre' ||
                child.tag == 'table')) {
          nestedBlocks.addAll(
            _blocksFromNode(child, nextId: nextId, mode: MarkdownMode.gfm),
          );
        } else {
          inlineNodes.add(child);
        }
      }
      final attributes = {
        'ordered': '$ordered',
        'marker': ordered ? '$number.' : '-',
        if (checked != null) 'task': '$checked',
      };
      result.add(
        BusyBlock(
          id: nextId(),
          kind: checked == null
              ? ordered
                    ? BusyBlockKind.orderedListItem
                    : BusyBlockKind.unorderedListItem
              : BusyBlockKind.taskListItem,
          inlines: _normalizeSoftBreaks(_inlinesFromNodes(inlineNodes)),
          children: nestedBlocks,
          attributes: attributes,
        ),
      );
      number++;
    }
    return result;
  }

  List<BusyInline> _inlinesFromNodes(Iterable<md.Node> nodes) {
    return [for (final node in nodes) ..._inlineFromNode(node)];
  }

  List<BusyInline> _inlineFromNode(md.Node node) {
    if (node is md.Text) {
      if (node.text.isEmpty) {
        return const [];
      }
      return [BusyInline(kind: BusyInlineKind.text, text: node.text)];
    }
    if (node is! md.Element) {
      return [BusyInline(kind: BusyInlineKind.unknown, text: node.textContent)];
    }
    final tag = node.tag.toLowerCase();
    final children = _inlinesFromNodes(node.children ?? const <md.Node>[]);
    final text = node.textContent;
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
      'del' || 's' => [
        BusyInline(
          kind: BusyInlineKind.strikethrough,
          text: text,
          children: children,
        ),
      ],
      'code' => [BusyInline(kind: BusyInlineKind.code, text: text)],
      'a' => [
        BusyInline(
          kind: BusyInlineKind.link,
          text: text,
          destination: node.attributes['href'],
          children: children,
          attributes: node.attributes,
        ),
      ],
      'img' => [
        BusyInline(
          kind: BusyInlineKind.image,
          text: node.attributes['alt'] ?? '',
          destination: node.attributes['src'],
          attributes: node.attributes,
        ),
      ],
      'br' => const [BusyInline(kind: BusyInlineKind.hardBreak, text: '\n')],
      'var' => [
        BusyInline(
          kind: BusyInlineKind.writersideVariable,
          text: text,
          attributes: node.attributes,
        ),
      ],
      _ when _dangerousHtmlTag(tag) => [
        BusyInline(kind: BusyInlineKind.html, text: text),
      ],
      _ => [
        if (children.isEmpty)
          BusyInline(kind: BusyInlineKind.text, text: text)
        else
          ...children,
      ],
    };
  }

  BusyBlock? _imageBlockFromParagraph(
    md.Element paragraph,
    List<BusyInline> inlines,
    String Function() nextId,
  ) {
    final image = inlines.where((item) => item.kind == BusyInlineKind.image);
    if (image.length != 1) {
      return null;
    }
    final imageInline = image.single;
    final plain = paragraph.textContent.trim();
    final attributeText = plain.replaceFirst(imageInline.text, '').trim();
    if (inlines.length > 2 ||
        (attributeText.isNotEmpty && !attributeText.startsWith('{'))) {
      return null;
    }
    return BusyBlock(
      id: nextId(),
      kind: BusyBlockKind.image,
      inlines: [imageInline],
      attributes: {
        ...imageInline.attributes,
        if (imageInline.destination case final destination?) 'src': destination,
        ..._parseAttributeBlock(attributeText),
      },
    );
  }

  List<BusyBlock> _tableRows(md.Element table, String Function() nextId) {
    final rows = <BusyBlock>[];
    for (final section
        in table.children?.whereType<md.Element>() ?? const <md.Element>[]) {
      final header = section.tag == 'thead';
      for (final row
          in section.children?.whereType<md.Element>() ??
              const <md.Element>[]) {
        if (row.tag != 'tr') {
          continue;
        }
        rows.add(
          BusyBlock(
            id: nextId(),
            kind: BusyBlockKind.table,
            attributes: {'header': '$header'},
            children: [
              for (final cell
                  in row.children?.whereType<md.Element>() ??
                      const <md.Element>[])
                BusyBlock(
                  id: nextId(),
                  kind: BusyBlockKind.paragraph,
                  inlines: _inlinesFromNodes(cell.children ?? const []),
                  attributes: {
                    'cell': cell.tag,
                    if (cell.attributes['align'] case final align?)
                      'align': align,
                  },
                ),
            ],
          ),
        );
      }
    }
    return rows;
  }

  BusyBlock? _writersideBlockFromText(
    String value, {
    required String Function() nextId,
  }) {
    final match = RegExp(
      r'^\s*<([A-Za-z][A-Za-z0-9_-]*)\b([^>]*)>(.*?)</\1>\s*$',
      dotAll: true,
    ).firstMatch(value);
    if (match == null) {
      return null;
    }
    final tag = match.group(1)!.toLowerCase();
    if (!_writersideBlockTag(tag)) {
      return null;
    }
    final text = match.group(3)!.trim();
    return BusyBlock(
      id: nextId(),
      kind: _writersideKind(tag),
      inlines: [BusyInline(kind: BusyInlineKind.text, text: text)],
      attributes: {'element': tag, ..._parseAttributePairs(match.group(2)!)},
      rawSource: value,
      preserveRaw: !_editableWritersideTag(tag),
    );
  }

  int? _headingLevel(String tag) {
    if (!RegExp(r'^h[1-6]$').hasMatch(tag)) {
      return null;
    }
    return int.parse(tag.substring(1));
  }

  List<BusyInline> _normalizeSoftBreaks(List<BusyInline> inlines) {
    final result = <BusyInline>[];
    for (final inline in inlines) {
      if (inline.kind == BusyInlineKind.text && inline.text.contains('\n')) {
        final parts = inline.text.split('\n');
        for (var i = 0; i < parts.length; i++) {
          if (parts[i].isNotEmpty) {
            result.add(BusyInline(kind: BusyInlineKind.text, text: parts[i]));
          }
          if (i < parts.length - 1) {
            result.add(
              const BusyInline(kind: BusyInlineKind.softBreak, text: ' '),
            );
          }
        }
      } else {
        result.add(inline);
      }
    }
    return result;
  }

  List<BusyInline> _stripTrailingAttributeInline(List<BusyInline> inlines) {
    if (inlines.isEmpty) {
      return inlines;
    }
    final text = inlines.map((inline) => inline.plainText).join();
    final stripped = _stripTrailingAttributeBlock(text);
    if (stripped == text) {
      return inlines;
    }
    return [BusyInline(kind: BusyInlineKind.text, text: stripped)];
  }

  bool? _taskChecked(List<md.Node> children) {
    for (final child in children) {
      if (child is md.Element && child.tag == 'input') {
        return child.attributes['checked'] == 'true';
      }
      if (child is md.Element && child.children != null) {
        final nested = _taskChecked(child.children!);
        if (nested != null) {
          return nested;
        }
      }
    }
    return null;
  }

  List<md.Node> _withoutTaskCheckbox(List<md.Node> children) {
    return [
      for (final child in children)
        if (child is md.Element && child.tag == 'input')
          ...const <md.Node>[]
        else if (child is md.Element && child.children != null)
          md.Element(child.tag, _withoutTaskCheckbox(child.children!))
            ..attributes.addAll(child.attributes)
        else
          child,
    ];
  }

  String _stripTrailingAttributeBlock(String value) {
    return value.replaceFirst(RegExp(r'\s*\{[^}]+\}\s*$'), '').trim();
  }

  String? _attributeValue(String raw, String key) {
    return RegExp('$key\\s*=\\s*"([^"]+)"').firstMatch(raw)?.group(1);
  }

  Map<String, String> _parseAttributeBlock(String raw) {
    final trimmed = raw.trim();
    if (!trimmed.startsWith('{') || !trimmed.endsWith('}')) {
      return const {};
    }
    return _parseAttributePairs(trimmed.substring(1, trimmed.length - 1));
  }

  Map<String, String> _parseAttributePairs(String raw) {
    final attributes = <String, String>{};
    for (final match in RegExp(
      r'([A-Za-z_:][-A-Za-z0-9_:.]*)\s*=\s*"([^"]*)"',
    ).allMatches(raw)) {
      attributes[match.group(1)!] = match.group(2)!;
    }
    return attributes;
  }

  List<Map<String, String>> _imageAttributeBlocks(String source) {
    return [
      for (final match in RegExp(
        r'!\[[^\]]*\]\([^)]+\)\s*(\{[^}]+\})',
      ).allMatches(source))
        _parseAttributeBlock(match.group(1)!),
    ];
  }

  bool _writersideBlockTag(String tag) {
    return {
      'note',
      'tip',
      'warning',
      'tabs',
      'tab',
      'procedure',
      'chapter',
    }.contains(tag);
  }

  bool _editableWritersideTag(String tag) {
    return {'note', 'tip', 'warning'}.contains(tag);
  }

  BusyBlockKind _writersideKind(String tag) {
    return switch (tag) {
      'note' || 'tip' || 'warning' => BusyBlockKind.writersideAdmonition,
      'tabs' || 'tab' => BusyBlockKind.writersideTabs,
      'procedure' => BusyBlockKind.writersideProcedure,
      _ => BusyBlockKind.writersideRawXml,
    };
  }

  bool _dangerousHtmlTag(String tag) {
    return {'script', 'style', 'iframe', 'object', 'embed'}.contains(tag);
  }

  _FrontMatter? _extractFrontMatter(String source) {
    if (!source.startsWith('---\n') && source != '---') {
      return null;
    }
    final closing = RegExp(
      r'^---\s*$',
      multiLine: true,
    ).allMatches(source).skip(1).firstOrNull;
    if (closing == null) {
      return null;
    }
    final end = closing.end;
    final raw = source.substring(0, end);
    final body = source.substring(4, closing.start);
    final values = <String, String>{};
    for (final line in body.split('\n')) {
      final match = RegExp(
        r'^\s*([A-Za-z0-9_-]+)\s*:\s*(.+?)\s*$',
      ).firstMatch(line);
      if (match != null) {
        values[match.group(1)!] = match
            .group(2)!
            .replaceAll(RegExp(r'''^["']|["']$'''), '');
      }
    }
    return _FrontMatter(raw: raw, endOffset: end, values: values);
  }

  String _protectProseHyphenLines(String source) {
    final lines = source.split('\n');
    for (var i = 1; i < lines.length; i++) {
      if (lines[i].trim() != '---') {
        continue;
      }
      final previous = lines[i - 1].trim();
      if (previous.contains(':')) {
        lines[i] = '\n${r'\---'}\n';
      }
    }
    return lines.join('\n');
  }
}

class _FrontMatter {
  const _FrontMatter({
    required this.raw,
    required this.endOffset,
    required this.values,
  });

  final String raw;
  final int endOffset;
  final Map<String, String> values;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
