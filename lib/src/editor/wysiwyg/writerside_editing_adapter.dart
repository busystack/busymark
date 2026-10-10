import 'dart:convert';
import 'package:xml/xml.dart';
import '../../core/source_span.dart';
import '../../markdown/busymark_document.dart';
import '../../markdown/busymark_markdown_serializer.dart';
import '../../markdown/markdown_model.dart';
import '../../writerside/writerside_document.dart';
import '../../writerside/writerside_document_parser.dart';
import '../../writerside/writerside_document_serializer.dart';
import '../../writerside/writerside_schema.dart';

/// An unresolved editing projection with bindings back to the authored tree.
/// Unlike the preview renderer, this never substitutes references or invents
/// titles. Unsupported nodes stay atomic and keep their original source.
class WritersideEditingAdapter {
  const WritersideEditingAdapter();

  static const containers = {
    'topic',
    'chapter',
    'procedure',
    'step',
    'tabs',
    'tab',
    'deflist',
    'def',
    'tldr',
    'list',
    'li',
    'tip',
    'note',
    'warning',
    'quote',
  };
  static const titleElements = {'topic', 'chapter', 'procedure', 'tab', 'def'};
  static const referenceLeaves = {'img', 'video', 'include', 'show-structure'};

  BusyDocument? parseXml({required String filePath, required String source}) {
    final authored = const WritersideDocumentParser().parseXml(
      filePath: filePath,
      source: source,
    );
    if (!authored.isWellFormed ||
        authored.rootElement?.name != 'topic' ||
        authored.nodes.whereType<WritersideElementNode>().length != 1) {
      return null;
    }
    var index = 0;
    return BusyDocument(
      filePath: filePath,
      mode: MarkdownMode.writersideMarkdown,
      source: source,
      authoredXml: authored,
      title: authored.rootElement?.attributes['title'],
      blocks: [
        for (final node in authored.nodes)
          blockFromNode(node, () => 'xml-${index++}'),
      ],
    );
  }

  BusyBlock? parseMarkdownElement(String source, String Function() nextId) {
    final doc = const WritersideDocumentParser().parseMarkdown(
      filePath: '',
      source: source,
      markdown: BusyDocument(
        filePath: '',
        mode: MarkdownMode.writersideMarkdown,
        blocks: [
          BusyBlock(
            id: 'semantic',
            kind: BusyBlockKind.writersideRawXml,
            rawSource: source,
            sourceSpan: SourceSpan.entireFile('', source),
          ),
        ],
      ),
    );
    final element = doc.rootElement;
    if (element == null ||
        (!containers.contains(element.name) &&
            !{'include', 'video', 'show-structure'}.contains(element.name)) ||
        element.name == 'topic') {
      return null;
    }
    return blockFromNode(element, nextId, markdown: true);
  }

  BusyBlock blockFromNode(
    WritersideDocumentNode node,
    String Function() nextId, {
    bool markdown = false,
    int level = 1,
    String? listType,
  }) {
    final id = nextId();
    if (node is WritersideMarkdownBlockNode) {
      BusyBlock reidentify(BusyBlock block) => block.copyWith(
        id: nextId(),
        children: block.children.map(reidentify).toList(),
      );
      return reidentify(node.block);
    }
    final binding = '${node.span.startOffset}:${node.span.endOffset}';
    if (node is! WritersideElementNode) {
      if (node is WritersideTextNode && node.text.trim().isNotEmpty) {
        return BusyBlock(
          id: id,
          kind: BusyBlockKind.paragraph,
          inlines: textInlines(node.text),
          rawSource: node.rawSource,
          sourceSpan: node.span,
          attributes: {
            busyMarkXmlBindingAttribute: binding,
            'element': '#text',
          },
        );
      }
      return BusyBlock(
        id: id,
        kind: BusyBlockKind.writersideRawXml,
        rawSource: node.rawSource,
        sourceSpan: node.span,
        preserveRaw: true,
        isSourceOnly: true,
        attributes: {busyMarkXmlBindingAttribute: binding},
      );
    }
    final tag = node.name;
    if (WritersideSchema.requiredAttributesFor(tag).any(
      (a) =>
          !node.attributes.containsKey(a) ||
          a != 'title' && (node.attributes[a] ?? '').trim().isEmpty,
    )) {
      return BusyBlock(
        id: id,
        kind: BusyBlockKind.writersideRawXml,
        rawSource: node.rawSource,
        sourceSpan: node.span,
        preserveRaw: true,
        attributes: {
          ...node.attributes,
          'element': tag,
          busyMarkXmlBindingAttribute: binding,
        },
      );
    }
    final container = containers.contains(tag);
    final editable =
        container ||
        {
          'p',
          'code-block',
          'video',
          'include',
          'img',
          'show-structure',
        }.contains(tag);
    final title = titleElements.contains(tag);
    final attributes = <String, String>{
      ...node.attributes,
      'element': tag,
      if (node.qualifiedName != tag)
        'busymark-xml-element-prefix': node.qualifiedName.substring(
          0,
          node.qualifiedName.length - tag.length,
        ),
      if (referenceLeaves.contains(tag) && node.children.isNotEmpty)
        'busymark-xml-leaf-content': node.children
            .map((n) => n.rawSource)
            .join(),
      busyMarkXmlBindingAttribute: binding,
      if (container) busyMarkWritersideContainerAttribute: 'true',
      if (tag == 'topic' || tag == 'chapter') 'level': '$level',
      if (tag == 'topic' || tag == 'chapter')
        'generatedId': node.attributes.containsKey('id') ? 'false' : 'true',
      if (tag == 'code-block') ...{
        'language': node.attributes['lang'] ?? '',
        busyMarkWritersideCodeBlockSourceFormAttribute:
            busyMarkWritersideCodeBlockElementSourceForm,
      },
      if (tag == 'li') 'marker': listType == 'decimal' ? '1.' : '-',
      if (busyAdmonitionStyleFromName(tag) != null) ...{
        'style': tag,
        busyMarkWritersideAdmonitionAttribute: 'true',
        busyMarkWritersideAdmonitionSourceFormAttribute: 'element',
      },
      if (node.attributes.keys.any(
        (key) =>
            key.startsWith('busymark-') || _projectionAttributes.contains(key),
      ))
        'busymark-xml-source-attributes': jsonEncode(node.attributes),
    };
    final kind = switch (tag) {
      'topic' || 'chapter' => BusyBlockKind.heading,
      'p' => BusyBlockKind.paragraph,
      'code-block' => BusyBlockKind.codeBlock,
      'tip' ||
      'note' ||
      'warning' ||
      'quote' => BusyBlockKind.writersideAdmonition,
      'tabs' || 'tab' => BusyBlockKind.writersideTabs,
      'procedure' => BusyBlockKind.writersideProcedure,
      'li' =>
        listType == 'decimal'
            ? BusyBlockKind.orderedListItem
            : BusyBlockKind.unorderedListItem,
      'video' => BusyBlockKind.video,
      'img' => BusyBlockKind.image,
      _ => BusyBlockKind.writersideRawXml,
    };
    return BusyBlock(
      id: id,
      kind: kind,
      attributes: attributes,
      rawSource: node.rawSource,
      sourceSpan: node.span,
      preserveRaw:
          !editable ||
          (tag == 'p' &&
              inlinesFromNodes(node.children).any((i) => _protectedInline(i))),
      isSourceOnly: tag == 'show-structure' && !markdown,
      inlines: title
          ? [
              BusyInline(
                kind: BusyInlineKind.text,
                text: node.attributes['title'] ?? '',
              ),
            ]
          : tag == 'img'
          ? [
              BusyInline(
                kind: BusyInlineKind.image,
                text: node.attributes['alt'] ?? '',
                destination: node.attributes['src'],
                attributes: node.attributes,
              ),
            ]
          : container || !editable
          ? const []
          : tag == 'code-block'
          ? [BusyInline(kind: BusyInlineKind.text, text: node.plainText)]
          : inlinesFromNodes(node.children),
      children: container
          ? [
              for (final child in node.children)
                blockFromNode(
                  child,
                  nextId,
                  markdown: markdown,
                  level: tag == 'topic' || tag == 'chapter' ? level + 1 : level,
                  listType: tag == 'list' ? node.attributes['type'] : listType,
                ),
            ]
          : const [],
    );
  }

  List<BusyInline> textInlines(String text) {
    final result = <BusyInline>[];
    var end = 0;
    for (final match in RegExp(r'%([\w.-]+)%').allMatches(text)) {
      if (match.start > end) {
        result.add(
          BusyInline(
            kind: BusyInlineKind.text,
            text: text.substring(end, match.start),
          ),
        );
      }
      result.add(
        BusyInline(
          kind: BusyInlineKind.writersideVariable,
          text: match.group(1)!,
          attributes: {'reference': match.group(1)!},
        ),
      );
      end = match.end;
    }
    if (end < text.length) {
      result.add(
        BusyInline(kind: BusyInlineKind.text, text: text.substring(end)),
      );
    }
    return result;
  }

  List<BusyInline> inlinesFromNodes(List<WritersideDocumentNode> nodes) => [
    for (final node in nodes)
      if (node is WritersideTextNode)
        ...textInlines(node.text)
      else if (node is WritersideRawNode)
        BusyInline(
          kind: BusyInlineKind.html,
          text: '',
          attributes: {'xml-raw': node.rawSource},
        )
      else if (node is WritersideElementNode)
        _inline(node),
  ];

  BusyInline _inline(WritersideElementNode node) {
    final kind = switch (node.name) {
      'control' => BusyInlineKind.writersideControl,
      'path' => BusyInlineKind.writersidePath,
      'ui-path' => BusyInlineKind.writersideUiPath,
      'shortcut' => BusyInlineKind.writersideShortcut,
      'b' || 'strong' => BusyInlineKind.strong,
      'emphasis' || 'i' => BusyInlineKind.emphasis,
      'code' => BusyInlineKind.code,
      'u' => BusyInlineKind.underline,
      's' => BusyInlineKind.strikethrough,
      'br' => BusyInlineKind.hardBreak,
      'a' => BusyInlineKind.link,
      'img' => BusyInlineKind.image,
      _ => BusyInlineKind.html,
    };
    final inline = BusyInline(
      kind: kind,
      text: kind == BusyInlineKind.image
          ? node.attributes['alt'] ?? ''
          : kind == BusyInlineKind.hardBreak
          ? '\n'
          : node.plainText,
      destination: node.attributes['href'] ?? node.attributes['src'],
      children: kind == BusyInlineKind.html
          ? const []
          : inlinesFromNodes(node.children),
      attributes: {
        ...node.attributes,
        'xml-name': node.qualifiedName,
        if (kind == BusyInlineKind.html) 'xml-raw': node.rawSource,
      },
    );
    return inline.copyWith(
      attributes: {
        ...inline.attributes,
        'xml-original-source': node.rawSource,
        'xml-original-signature': _inlineSignature(inline),
      },
    );
  }

  static bool _protectedInline(BusyInline inline) =>
      (inline.attributes.containsKey('xml-raw') &&
          inline.plainText.isNotEmpty) ||
      inline.children.any(_protectedInline);

  static String _inlineSignature(BusyInline inline) {
    final keys =
        inline.attributes.keys
            .where((k) => !k.startsWith('xml-') || k == 'xml-name')
            .toList()
          ..sort();
    return jsonEncode([
      inline.kind.name,
      inline.text,
      inline.destination,
      {for (final k in keys) k: inline.attributes[k]},
      [for (final child in inline.children) _inlineSignature(child)],
    ]);
  }

  String serializeXml(BusyDocument document) {
    final authored = document.authoredXml!;
    final bindings = <String, WritersideDocumentNode>{
      for (final node in authored.walk())
        '${node.span.startOffset}:${node.span.endOffset}': node,
    };
    WritersideDocumentNode build(BusyBlock block, String namespacePrefix) {
      final original = bindings[block.attributes[busyMarkXmlBindingAttribute]];
      if (block.preserveRaw || (!hasDirtyContent(block) && original != null)) {
        return original ?? rawNode(block.rawSource ?? '', document.filePath);
      }
      final tag = block.attributes['element'];
      if (tag == '#text') {
        return WritersideTextNode(
          text: block.plainText,
          span: original?.span ?? SourceSpan.entireFile(document.filePath, ''),
          rawSource: '',
          isModified: true,
        );
      }
      final name = tagForBlock(block);
      // New descendants belong to their actual parent's namespace. Its
      // qualified prefix is already bound by the preserved declarations,
      // including local aliases, default namespaces and prefix rebindings.
      final childPrefix = original is WritersideElementNode
          ? _namespacePrefix(original.qualifiedName)
          : namespacePrefix;
      final attributes = sourceAttributes(block);
      if (titleElements.contains(name)) attributes['title'] = block.plainText;
      if (name == 'code-block') {
        attributes['lang'] = block.attributes['language'] ?? '';
      }
      if (name == 'img') {
        final image = block.inlines
            .where((i) => i.kind == BusyInlineKind.image)
            .firstOrNull;
        if (image != null) {
          attributes['src'] = image.destination ?? attributes['src'] ?? '';
          attributes['alt'] = image.text;
        }
      }
      final leafContent = block.attributes['busymark-xml-leaf-content'];
      final children = referenceLeaves.contains(name)
          ? original is WritersideElementNode
                ? original.children
                : leafContent != null
                ? [rawNode(leafContent, document.filePath)]
                : const <WritersideDocumentNode>[]
          : busyMarkIsWritersideContainer(block) ||
                containers.contains(name) && block.children.isNotEmpty
          ? block.children.map((child) => build(child, childPrefix)).toList()
          : [
              for (final inline in block.inlines)
                ...inlineNodes(
                  inline,
                  document.filePath,
                  namespacePrefix: childPrefix,
                ),
            ];
      return elementNode(
        name,
        attributes,
        children,
        document.filePath,
        original: original is WritersideElementNode ? original : null,
        namespacePrefix: namespacePrefix,
      );
    }

    final next = authored.copyWith(
      nodes: document.blocks.map((block) => build(block, '')).toList(),
    );
    return const WritersideDocumentSerializer().serialize(next);
  }

  /// Reparse the committed source to refresh every span and raw subtree, while
  /// retaining the live IDs used by selection, outline and transaction targets.
  BusyDocument rebaseXml(BusyDocument document, String source) {
    final parsed = parseXml(filePath: document.filePath, source: source);
    if (parsed == null) {
      throw const FormatException('Invalid authored XML edit');
    }
    List<BusyBlock> retain(List<BusyBlock> old, List<BusyBlock> fresh) {
      final oldVisible = old.where((b) => !b.isSourceOnly).toList();
      var index = 0;
      return [
        for (final block in fresh)
          if (block.isSourceOnly)
            block.copyWith(id: 'xml-raw-${block.id}')
          else if (index < oldVisible.length)
            (() {
              final previous = oldVisible[index++];
              return block.copyWith(
                id: previous.id,
                children: retain(previous.children, block.children),
              );
            })()
          else
            block,
      ];
    }

    return parsed.copyWith(blocks: retain(document.blocks, parsed.blocks));
  }

  /// Maps an editor boundary to its authored XML text, including entities and
  /// title attributes. Comments and markup never participate in text matching.
  int? xmlTextSourceOffset(
    BusyDocument document,
    BusyBlock block,
    int textOffset, {
    required bool endBoundary,
  }) {
    final authored = document.authoredXml;
    final binding = block.attributes[busyMarkXmlBindingAttribute];
    if (authored == null || binding == null) return null;
    final node = authored
        .walk()
        .where((n) => '${n.span.startOffset}:${n.span.endOffset}' == binding)
        .firstOrNull;
    if (node == null) return null;
    final ranges = <({int start, int end})>[];
    void append(
      String raw,
      int start, {
      bool literal = false,
      bool variables = false,
    }) {
      for (var i = 0; i < raw.length;) {
        if (variables && raw[i] == '%') {
          final match = RegExp(r'^%[\w.-]+%').firstMatch(raw.substring(i));
          if (match != null) {
            for (var j = 1; j < match.end - 1; j++) {
              ranges.add((start: start + i + j, end: start + i + j + 1));
            }
            i += match.end;
            continue;
          }
        }
        if (!literal && raw[i] == '&') {
          final end = raw.indexOf(';', i + 1);
          if (end >= 0) {
            final decoded = XmlDocumentFragment.parse(
              raw.substring(i, end + 1),
            ).innerText;
            for (var j = 0; j < decoded.length; j++) {
              ranges.add((start: start + i, end: start + end + 1));
            }
            i = end + 1;
            continue;
          }
        }
        ranges.add((start: start + i, end: start + i + 1));
        i++;
      }
    }

    if (node is WritersideElementNode && titleElements.contains(node.name)) {
      final span = node.attributeSpans['title'];
      if (span == null) return node.span.startOffset;
      append(
        authored.source.substring(span.startOffset, span.endOffset),
        span.startOffset,
      );
    } else {
      for (final text in node.walk().whereType<WritersideTextNode>()) {
        final cdata = text.rawSource.startsWith('<![CDATA[');
        append(
          cdata
              ? text.rawSource.substring(9, text.rawSource.length - 3)
              : text.rawSource,
          text.span.startOffset + (cdata ? 9 : 0),
          literal: cdata,
          variables: block.kind != BusyBlockKind.codeBlock,
        );
      }
    }
    if (ranges.isEmpty) return node.span.startOffset;
    final offset = textOffset.clamp(0, ranges.length);
    return offset == ranges.length
        ? ranges.last.end
        : endBoundary && offset > 0
        ? ranges[offset - 1].end
        : ranges[offset].start;
  }

  static bool hasDirtyContent(BusyBlock block) =>
      block.dirty || block.children.any(hasDirtyContent);
  static const _projectionAttributes = {
    'element',
    'level',
    'language',
    'marker',
    'ordered',
    'style',
    'generatedId',
    'sourceFormat',
    busyMarkWritersideAdmonitionAttribute,
    busyMarkWritersideAdmonitionSourceFormAttribute,
    busyMarkWritersideCodeBlockSourceFormAttribute,
    busyMarkPreserveTextWhitespaceAttribute,
    busyMarkTransientTrailingParagraphAttribute,
    busyMarkPreserveEmptyParagraphAttribute,
  };
  static bool _isProjectionAttribute(String key, BusyBlock block) =>
      key.startsWith('busymark-') ||
      _projectionAttributes.contains(key) &&
          (key != 'style' ||
              block.kind == BusyBlockKind.writersideAdmonition ||
              block.kind == BusyBlockKind.blockquote);
  static Map<String, String> sourceAttributes(BusyBlock block) => {
    // Some authored attributes share names with the existing Markdown editing
    // metadata. Keep their original values independently of the projection.
    if (block.attributes['busymark-xml-source-attributes'] case final source?)
      for (final entry in (jsonDecode(source) as Map<String, dynamic>).entries)
        if (_isProjectionAttribute(entry.key, block))
          entry.key: entry.value as String,
    for (final entry in block.attributes.entries)
      if (!_isProjectionAttribute(entry.key, block)) entry.key: entry.value,
  };
  static String tagForBlock(BusyBlock block) => switch (block.kind) {
    BusyBlockKind.paragraph => 'p',
    BusyBlockKind.heading =>
      block.attributes['element'] == 'topic' ? 'topic' : 'chapter',
    BusyBlockKind.codeBlock => 'code-block',
    BusyBlockKind.image => 'img',
    BusyBlockKind.video => 'video',
    BusyBlockKind.unorderedListItem ||
    BusyBlockKind.orderedListItem ||
    BusyBlockKind.taskListItem => 'li',
    BusyBlockKind.blockquote ||
    BusyBlockKind.writersideAdmonition => block.attributes['style'] ?? 'quote',
    _ => block.attributes['element'] ?? 'p',
  };

  static WritersideRawNode rawNode(String source, String path) =>
      WritersideRawNode(
        span: SourceSpan.entireFile(path, source),
        rawSource: source,
      );
  static String _namespacePrefix(String qualifiedName) =>
      qualifiedName.contains(':') ? '${qualifiedName.split(':').first}:' : '';
  static WritersideElementNode elementNode(
    String name,
    Map<String, String> attributes,
    List<WritersideDocumentNode> children,
    String path, {
    WritersideElementNode? original,
    String namespacePrefix = '',
    String? qualifiedName,
  }) {
    final prefix = original?.qualifiedName.contains(':') == true
        ? '${original!.qualifiedName.split(':').first}:'
        : original == null
        ? namespacePrefix
        : '';
    return WritersideGenericElementNode(
      name: name,
      qualifiedName: qualifiedName ?? '$prefix$name',
      attributes: attributes,
      children: children,
      schemaKnown: WritersideSchema.isKnownElement(name),
      qualifiedAttributes: original?.qualifiedAttributes ?? const [],
      attributeSpans: original?.attributeSpans ?? const {},
      span: original?.span ?? SourceSpan.entireFile(path, ''),
      rawSource: original?.rawSource ?? (children.isEmpty ? '<$name/>' : ''),
      isModified: true,
    );
  }

  static List<WritersideDocumentNode> inlineNodes(
    BusyInline inline,
    String path, {
    String namespacePrefix = '',
  }) {
    final source = inline.attributes['xml-original-source'];
    if (source != null &&
        inline.attributes['xml-original-signature'] ==
            _inlineSignature(inline)) {
      return [rawNode(source, path)];
    }
    if (inline.attributes['xml-raw'] case final raw?) {
      return [rawNode(raw, path)];
    }
    if (inline.kind == BusyInlineKind.hardBreak) {
      return [
        elementNode(
          'br',
          const {},
          const [],
          path,
          namespacePrefix: namespacePrefix,
        ),
      ];
    }
    if (inline.kind == BusyInlineKind.text ||
        inline.kind == BusyInlineKind.softBreak ||
        inline.kind == BusyInlineKind.writersideVariable) {
      final text = inline.kind == BusyInlineKind.writersideVariable
          ? '%${inline.attributes['reference'] ?? inline.text}%'
          : inline.text;
      return [
        WritersideTextNode(
          text: text,
          span: SourceSpan.entireFile(path, ''),
          rawSource: '',
          isModified: true,
        ),
      ];
    }
    final name =
        busyMarkSemanticInlineTag(inline.kind) ??
        switch (inline.kind) {
          BusyInlineKind.strong => 'b',
          BusyInlineKind.emphasis => 'emphasis',
          BusyInlineKind.underline => 'u',
          BusyInlineKind.strikethrough => 's',
          BusyInlineKind.code => 'code',
          BusyInlineKind.link => 'a',
          BusyInlineKind.image => 'img',
          _ => inline.attributes['xml-name'] ?? 'emphasis',
        };
    final attrs = {
      for (final e in inline.attributes.entries)
        if (!e.key.startsWith('xml-') && e.key != 'reference') e.key: e.value,
      if (inline.kind == BusyInlineKind.link && inline.destination != null)
        'href': inline.destination!,
      if (inline.kind == BusyInlineKind.image && inline.destination != null)
        'src': inline.destination!,
      if (inline.kind == BusyInlineKind.image) 'alt': inline.text,
    };
    final qualifiedName = inline.attributes['xml-name'];
    final childPrefix = qualifiedName != null
        ? _namespacePrefix(qualifiedName)
        : namespacePrefix;
    return [
      elementNode(
        name.split(':').last,
        attrs,
        inline.kind == BusyInlineKind.image
            ? const []
            : inline.children.isEmpty
            ? [
                WritersideTextNode(
                  text: inline.text,
                  span: SourceSpan.entireFile(path, ''),
                  rawSource: '',
                  isModified: true,
                ),
              ]
            : [
                for (final child in inline.children)
                  ...inlineNodes(child, path, namespacePrefix: childPrefix),
              ],
        path,
        namespacePrefix: namespacePrefix,
        qualifiedName: inline.attributes['xml-name'],
      ),
    ];
  }

  String serializeMarkdownElement(BusyBlock block) {
    if (!hasDirtyContent(block) && block.rawSource != null) {
      return block.rawSource!;
    }
    final name = block.attributes['element'] ?? tagForBlock(block);
    final qualifiedName =
        '${block.attributes['busymark-xml-element-prefix'] ?? ''}$name';
    final attrs = sourceAttributes(block);
    if (titleElements.contains(name)) attrs['title'] = block.plainText;
    final attributes = attrs.entries
        .map((e) => ' ${e.key}="${escape(e.value)}"')
        .join();
    if (!busyMarkIsWritersideContainer(block)) {
      final content = block.attributes['busymark-xml-leaf-content'];
      return content == null
          ? '<$qualifiedName$attributes/>'
          : '<$qualifiedName$attributes>$content</$qualifiedName>';
    }
    final content = block.children
        .map(
          (child) => child.isSourceOnly
              ? child.rawSource ?? ''
              : busyMarkIsWritersideContainer(child)
              ? serializeMarkdownElement(child)
              : child.kind == BusyBlockKind.paragraph &&
                    (name == 'tldr' || child.attributes['element'] == 'p')
              ? const WritersideDocumentSerializer().serialize(
                  WritersideDocument(
                    filePath: '',
                    source: '',
                    format: WritersideDocumentFormat.xmlTopic,
                    nodes: [
                      elementNode('p', sourceAttributes(child), [
                        for (final inline in child.inlines)
                          ...inlineNodes(inline, ''),
                      ], ''),
                    ],
                  ),
                )
              : const BusyMarkMarkdownSerializer().serializeBlock(child),
        )
        .join('\n\n');
    return '<$qualifiedName$attributes>\n\n$content\n\n</$qualifiedName>';
  }

  static String escape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}
