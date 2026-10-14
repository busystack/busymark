import 'dart:convert';
import '../../markdown/markdown_source_map.dart';
import 'wysiwyg_inline_controller.dart';
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

  static Iterable<
    ({
      BusyInlineStyleRange range,
      int begin,
      int end,
      int localBegin,
      int localEnd,
      bool xmlSource,
    })
  >
  authoredInlineRanges(
    BusyDocument document,
    String source,
    BusyBlock block,
  ) sync* {
    if (block.sourceSpan == null) return;
    if (document.isXmlTopic && document.authoredXml?.source != source) return;
    final raw =
        block.attributes['busymark-native-inline-source'] ??
        block.rawSource ??
        '';
    if (block.children.isNotEmpty &&
        !block.attributes.containsKey('element') &&
        block.attributes.containsKey('busymark-native-source-map') &&
        !block.attributes.containsKey('busymark-native-inline-source')) {
      return;
    }
    if (!document.isXmlTopic && block.attributes.containsKey('element')) {
      // Semantic XML islands retain bindings relative to their own authored
      // fragment. Use that same adapter to map text occurrences, including
      // variables, then translate back into the containing Markdown source.
      const prefix = '<topic id="inspector" title="Inspector">';
      final wrapped = '$prefix$raw</topic>';
      final xml = const WritersideEditingAdapter().parseXml(
        filePath: document.filePath,
        source: wrapped,
      );
      final element = xml?.blocks.first.children
          .where((b) => !b.isSourceOnly)
          .singleOrNull;
      if (xml != null && element?.plainText == block.plainText) {
        final references = busyInlineReferenceRanges(block.inlines);
        for (final entry in authoredInlineRanges(xml, wrapped, element!)) {
          final owner = references
              .where(
                (r) =>
                    r.kind == entry.range.kind &&
                    r.start == entry.range.start &&
                    r.end == entry.range.end &&
                    r.referenceIndex == entry.range.referenceIndex,
              )
              .firstOrNull;
          if (owner != null) {
            final begin = markdownProjectedSourceOffset(
              block,
              entry.begin - prefix.length,
              inline: true,
            );
            final end = markdownProjectedSourceOffset(
              block,
              entry.end - prefix.length,
              inline: true,
            );
            if (begin == null || end == null) continue;
            yield (
              range: owner,
              begin: begin,
              end: end,
              localBegin: entry.begin - prefix.length,
              localEnd: entry.end - prefix.length,
              xmlSource: entry.xmlSource,
            );
          }
        }
      }
      return;
    }
    final mapped =
        !document.isXmlTopic && !block.attributes.containsKey('element')
        ? const MarkdownSourceMapper()
              .createInlineParserContext(
                documentSource: source,
                mode: document.mode,
                mapWritersideReferences: true,
              )
              .parseMapped(raw)
        : null;
    final mappedReferences = <BusyInline>[];
    void collect(List<BusyInline> inlines, bool inheritedIgnore) {
      for (final inline in inlines) {
        final ignore = switch (inline.attributes['ignore-vars']) {
          'true' => true,
          'false' => false,
          _ => inheritedIgnore,
        };
        if (inline.kind != BusyInlineKind.writersideVariable || !ignore) {
          if (mapped!.ranges.containsKey(inline)) mappedReferences.add(inline);
        }
        collect(inline.children, ignore);
      }
    }

    if (mapped != null) {
      collect(mapped.inlines, block.attributes['ignore-vars'] == 'true');
    }
    final references = busyInlineReferenceRanges(block.inlines);
    final xmlVariables = document.isXmlTopic
        ? const WritersideEditingAdapter()
              .xmlVariableSourceRanges(document, block)
              .toList()
        : const <({int start, int end, int sourceStart, int sourceEnd})>[];
    for (final range in references) {
      if (!{
        BusyInlineKind.link,
        BusyInlineKind.image,
        BusyInlineKind.writersideVariable,
        BusyInlineKind.writersideShortcut,
      }.contains(range.kind)) {
        continue;
      }
      final binding = range.attributes['xml-source-binding']?.split(':');
      int? begin;
      int? end;
      int? localBegin;
      int? localEnd;
      var xmlSource = false;
      if (document.isXmlTopic && binding?.length == 2) {
        xmlSource = true;
        begin = int.tryParse(binding![0]);
        end = int.tryParse(binding[1]);
        localBegin = begin == null
            ? null
            : begin - block.sourceSpan!.startOffset;
        localEnd = end == null ? null : end - block.sourceSpan!.startOffset;
      } else if (mapped != null) {
        final peers = references.where((r) => r.kind == range.kind).toList();
        final ordinal = peers.indexOf(range);
        final candidates =
            mappedReferences.where((e) => e.kind == range.kind).toList()..sort(
              (a, b) =>
                  mapped.ranges[a]!.start.compareTo(mapped.ranges[b]!.start),
            );
        if (ordinal >= 0 && candidates.length == peers.length) {
          final positioned = mapped.ranges[candidates[ordinal]]!;
          final attributes = RegExp(
            r'^\{(?:\s*[\w:.-]+\s*=\s*"[^"]*"\s*)+\}',
          ).firstMatch(raw.substring(positioned.end));
          xmlSource = positioned.rawHtmlFragment != null;
          localBegin = positioned.start;
          localEnd = positioned.end + (attributes?.end ?? 0);
          begin = markdownProjectedSourceOffset(
            block,
            positioned.start,
            inline: true,
          );
          end = markdownProjectedSourceOffset(
            block,
            positioned.end + (attributes?.end ?? 0),
            inline: true,
          );
        }
      } else if (document.isXmlTopic &&
          range.kind == BusyInlineKind.writersideVariable) {
        final occurrence = xmlVariables
            .where((v) => v.start == range.start && v.end == range.end)
            .singleOrNull;
        if (occurrence != null) {
          begin = occurrence.sourceStart;
          end = occurrence.sourceEnd;
          localBegin = begin - block.sourceSpan!.startOffset;
          localEnd = end - block.sourceSpan!.startOffset;
        }
      }
      if (begin != null &&
          end != null &&
          localBegin != null &&
          localEnd != null) {
        yield (
          range: range,
          begin: begin,
          end: end,
          localBegin: localBegin,
          localEnd: localEnd,
          xmlSource: xmlSource,
        );
      }
    }
  }

  static bool isNativeHeading(BusyDocument document, BusyBlock block) =>
      !document.isXmlTopic &&
      block.kind == BusyBlockKind.heading &&
      !block.attributes.containsKey('element');

  /// The existing document interpretation uses the first top-level H1 as the
  /// topic heading. Subsequent H1s retain their own heading/anchor ownership.
  static BusyBlock? topicHeading(BusyDocument document) => document.blocks
      .where(
        (b) => isNativeHeading(document, b) && b.attributes['level'] == '1',
      )
      .firstOrNull;

  static String propertyTag(BusyDocument document, BusyBlock block) =>
      isNativeHeading(document, block) ? 'chapter' : tagForBlock(block);

  static Iterable<String> propertyAttributes(
    BusyDocument document,
    BusyBlock block,
  ) => WritersideSchema.attributesFor(propertyTag(document, block)).where(
    (name) =>
        !(topicHeading(document)?.id == block.id &&
            !{'id', 'title'}.contains(name)),
  );

  /// Reuse the authored semantic parser to protect declarations that an opaque
  /// editing block cannot safely expose as one unscoped navigation owner.
  static bool topicNavigationEditable(BusyDocument document) {
    final semantic =
        document.authoredXml ??
        const WritersideDocumentParser().parseMarkdown(
          filePath: document.filePath,
          source: document.source ?? '',
          markdown: document,
        );
    final declarations = semantic.elements
        .where((e) => e.name == 'show-structure')
        .toList();
    final topLevel = document.isXmlTopic
        ? semantic.rootElement?.children
                  .whereType<WritersideElementNode>()
                  .where((e) => e.name == 'show-structure')
                  .length ??
              0
        : semantic.nodes
              .whereType<WritersideElementNode>()
              .where((e) => e.name == 'show-structure')
              .length;
    return declarations.length < 2 &&
        declarations.length == topLevel &&
        !declarations.any(
          (e) => e.attributes.keys.any(
            {'instance', 'filter', 'switcher-key'}.contains,
          ),
        );
  }

  /// Source authoring shares the semantic XML serializer and namespace rules.
  String? insertSourceLink({
    required String filePath,
    required String source,
    required int start,
    required int end,
    required String destination,
    required String placeholder,
    String? origin,
  }) {
    final document = const WritersideDocumentParser().parseXml(
      filePath: filePath,
      source: source,
    );
    if (!document.isWellFormed ||
        start < 0 ||
        end < start ||
        end > source.length) {
      return null;
    }
    final parent = document
        .walk()
        .whereType<WritersideElementNode>()
        .where((n) => n.span.startOffset < start && n.span.endOffset > end)
        .lastOrNull;
    if (parent == null ||
        !{
          'p',
          'title',
          'b',
          'i',
          'em',
          'strong',
          'u',
          's',
          'td',
          'li',
        }.contains(parent.name)) {
      return null;
    }
    final openingEnd = source.indexOf('>', parent.span.startOffset);
    final closingStart = source.lastIndexOf('</', parent.span.endOffset);
    if (start <= openingEnd || end > closingStart) return null;
    final prefix = parent.qualifiedName.contains(':')
        ? '${parent.qualifiedName.split(':').first}:'
        : '';
    final inner = source.substring(start, end);
    final link = elementNode(
      'a',
      {'href': destination, if (origin != null) 'origin': origin},
      [
        if (inner.isEmpty)
          ...inlineNodes(
            BusyInline(kind: BusyInlineKind.text, text: placeholder),
            filePath,
          )
        else
          rawNode(inner, filePath),
      ],
      filePath,
      namespacePrefix: prefix,
    );
    final fragment = const WritersideDocumentSerializer().serialize(
      WritersideDocument(
        filePath: filePath,
        source: '',
        format: WritersideDocumentFormat.xmlTopic,
        nodes: [link],
      ),
    );
    final candidate = source.replaceRange(start, end, fragment);
    final checked = const WritersideDocumentParser().parseXml(
      filePath: filePath,
      source: candidate,
    );
    if (!checked.isWellFormed) return null;
    final authored = checked.elements
        .where((e) => e.name == 'a' && e.span.startOffset == start)
        .firstOrNull;
    return authored?.attributes['href'] == destination ? candidate : null;
  }

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
          (!node.attributes.containsKey(a) &&
              !(a == 'title' &&
                  node.children.whereType<WritersideElementNode>().any(
                    (child) => child.name == 'title',
                  ))) ||
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
      if (!node.attributes.containsKey('title') &&
          titleElements.contains(tag) &&
          node.children.whereType<WritersideElementNode>().any(
            (child) => child.name == 'title',
          ))
        'busymark-title-label': node.children
            .whereType<WritersideElementNode>()
            .firstWhere((child) => child.name == 'title')
            .plainText,
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
      if (tag == 'li' && listType == 'checkbox')
        'task': node.attributes['checked'] ?? 'false',
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
            : listType == 'checkbox'
            ? BusyBlockKind.taskListItem
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

  List<BusyInline> textInlines(
    String text, {
    WritersideTextNode? authoredText,
    Map<BusyInline, ({int start, int end})>? sourceBindings,
  }) {
    final result = <BusyInline>[];
    final positions = authoredText == null || sourceBindings == null
        ? null
        : _authoredTextPositions(authoredText);
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
      final variable = BusyInline(
        kind: BusyInlineKind.writersideVariable,
        text: match.group(1)!,
        attributes: {'reference': match.group(1)!},
      );
      result.add(variable);
      if (positions != null) {
        sourceBindings![variable] = (
          start: positions[match.start].start,
          end: positions[match.end - 1].end,
        );
      }
      end = match.end;
    }
    if (end < text.length) {
      result.add(
        BusyInline(kind: BusyInlineKind.text, text: text.substring(end)),
      );
    }
    return result;
  }

  List<BusyInline> inlinesFromNodes(
    List<WritersideDocumentNode> nodes, {
    Map<BusyInline, ({int start, int end})>? sourceBindings,
  }) => [
    for (final node in nodes)
      if (node is WritersideTextNode)
        ...textInlines(
          node.text,
          authoredText: node,
          sourceBindings: sourceBindings,
        )
      else if (node is WritersideRawNode)
        BusyInline(
          kind: BusyInlineKind.html,
          text: '',
          attributes: {'xml-raw': node.rawSource},
        )
      else if (node is WritersideElementNode)
        _inline(node, sourceBindings: sourceBindings),
  ];

  BusyInline _inline(
    WritersideElementNode node, {
    Map<BusyInline, ({int start, int end})>? sourceBindings,
  }) {
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
          : inlinesFromNodes(node.children, sourceBindings: sourceBindings),
      attributes: {
        ...node.attributes,
        'xml-name': node.qualifiedName,
        'xml-source-binding': '${node.span.startOffset}:${node.span.endOffset}',
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

  // Bind tokens within their actual XML text node, including entity and CDATA
  // spelling. A binding is emitted only when the decoded text agrees with the
  // existing authored parser. Images, breaks and comments are separate nodes.
  static List<({int start, int end})>? _authoredTextPositions(
    WritersideTextNode node,
  ) {
    final cdata = node.rawSource.startsWith('<![CDATA[');
    final raw = cdata
        ? node.rawSource.substring(9, node.rawSource.length - 3)
        : node.rawSource;
    final base = node.span.startOffset + (cdata ? 9 : 0);
    final decoded = StringBuffer();
    final positions = <({int start, int end})>[];
    for (var i = 0; i < raw.length;) {
      var end = i + 1;
      var value = raw.substring(i, end);
      if (!cdata && raw[i] == '&') {
        final closing = raw.indexOf(';', i + 1);
        if (closing < 0) return null;
        end = closing + 1;
        try {
          value = XmlDocumentFragment.parse(raw.substring(i, end)).innerText;
        } on XmlParserException {
          return null;
        }
      }
      decoded.write(value);
      for (var j = 0; j < value.length; j++) {
        positions.add((start: base + i, end: base + end));
      }
      i = end;
    }
    return decoded.toString() == node.text ? positions : null;
  }

  /// Variable bindings in the editor's inline coordinate system. Reusing the
  /// editing projection makes image alt text, breaks, wrappers and atomic
  /// elements advance the position exactly as they do in the editor.
  Iterable<({int start, int end, int sourceStart, int sourceEnd})>
  xmlVariableSourceRanges(BusyDocument document, BusyBlock block) sync* {
    final authored = document.authoredXml;
    final binding = block.attributes[busyMarkXmlBindingAttribute];
    if (authored == null || binding == null) return;
    final node = authored
        .walk()
        .where((n) => '${n.span.startOffset}:${n.span.endOffset}' == binding)
        .firstOrNull;
    if (node == null) return;
    final bindings = Map<BusyInline, ({int start, int end})>.identity();
    final projected = node is WritersideTextNode
        ? textInlines(node.text, authoredText: node, sourceBindings: bindings)
        : node is WritersideElementNode
        ? inlinesFromNodes(node.children, sourceBindings: bindings)
        : const <BusyInline>[];
    if (projected.map((i) => i.plainText).join() != block.plainText) return;
    var offset = 0;
    Iterable<({int start, int end, int sourceStart, int sourceEnd})> visit(
      BusyInline inline,
    ) sync* {
      final position = bindings[inline];
      if (position != null) {
        yield (
          start: offset,
          end: offset + inline.plainText.length,
          sourceStart: position.start,
          sourceEnd: position.end,
        );
      }
      if (inline.children.isNotEmpty) {
        for (final child in inline.children) {
          yield* visit(child);
        }
      } else {
        offset += inline.plainText.length;
      }
    }

    for (final inline in projected) {
      yield* visit(inline);
    }
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
      if (titleElements.contains(name) &&
          (block.attributes.containsKey('title') ||
              block.plainText.isNotEmpty)) {
        attributes['title'] = block.plainText;
      }
      if (name == 'code-block') {
        if (block.attributes['language']?.isNotEmpty == true) {
          attributes['lang'] = block.attributes['language']!;
        }
      }
      if (name == 'img') {
        final image = block.inlines
            .where((i) => i.kind == BusyInlineKind.image)
            .firstOrNull;
        if (image != null) {
          attributes['src'] = image.destination ?? attributes['src'] ?? '';
          if (attributes.containsKey('alt') || image.text.isNotEmpty) {
            attributes['alt'] = image.text;
          }
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

  /// XML has one marker style per list. Materializing a mixed native owner
  /// would turn ordinary items into tasks or lose task editing semantics.
  static bool nativeListHasMixedMarkers(BusyBlock block) =>
      block.attributes['busymark-list-form'] == 'markdown' &&
          block.children.any((b) => b.kind == BusyBlockKind.taskListItem) &&
          block.children.any((b) => b.kind != BusyBlockKind.taskListItem) ||
      block.children.any(nativeListHasMixedMarkers);
  static const _projectionAttributes = {
    'element',
    'htmlTag',
    'htmlAttributes',
    'editorBlockId',
    'level',
    'language',
    'marker',
    'task',
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
  static bool isProjectionAttribute(String key, BusyBlockKind kind) =>
      key.startsWith('busymark-') ||
      _projectionAttributes.contains(key) &&
          (key != 'style' ||
              kind == BusyBlockKind.writersideAdmonition ||
              kind == BusyBlockKind.blockquote);
  static Map<String, String> sourceAttributes(BusyBlock block) => {
    // Some authored attributes share names with the existing Markdown editing
    // metadata. Keep their original values independently of the projection.
    if (block.attributes['busymark-xml-source-attributes'] ??
            block.attributes['busymark-writerside-source-attributes']
        case final source?)
      for (final entry in (jsonDecode(source) as Map<String, dynamic>).entries)
        if (isProjectionAttribute(entry.key, block.kind))
          entry.key: entry.value as String,
    for (final entry in block.attributes.entries)
      if (!isProjectionAttribute(entry.key, block.kind)) entry.key: entry.value,
  };
  static String tagForBlock(BusyBlock block) => switch (block.kind) {
    BusyBlockKind.paragraph => 'p',
    BusyBlockKind.heading =>
      block.attributes['element'] == 'topic' ? 'topic' : 'chapter',
    BusyBlockKind.codeBlock => 'code-block',
    BusyBlockKind.image => 'img',
    BusyBlockKind.table => 'table',
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
      if (text.isEmpty) return const [];
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
        if (!e.key.startsWith('xml-') &&
            !e.key.startsWith('busymark-') &&
            e.key != 'reference')
          e.key: e.value,
      if (inline.kind == BusyInlineKind.link && inline.destination != null)
        'href': inline.destination!,
      if (inline.kind == BusyInlineKind.image && inline.destination != null)
        'src': inline.destination!,
      if (inline.kind == BusyInlineKind.image &&
          (inline.text.isNotEmpty || inline.attributes.containsKey('alt')))
        'alt': inline.text,
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

  static String serializeInlineElement(BusyInline inline) =>
      const WritersideDocumentSerializer().serialize(
        WritersideDocument(
          filePath: '',
          source: '',
          format: WritersideDocumentFormat.xmlTopic,
          nodes: inlineNodes(inline, ''),
        ),
      );

  String serializeMarkdownElement(BusyBlock block) {
    if (!hasDirtyContent(block) && block.rawSource != null) {
      return block.rawSource!;
    }
    final name = block.attributes['element'] ?? tagForBlock(block);
    final qualifiedName =
        '${block.attributes['busymark-xml-element-prefix'] ?? ''}$name';
    final attrs = sourceAttributes(block);
    if (titleElements.contains(name) &&
        (block.attributes.containsKey('title') || block.plainText.isNotEmpty)) {
      attrs['title'] = block.plainText;
    }
    final attributes = attrs.entries
        .map((e) => ' ${e.key}="${escape(e.value)}"')
        .join();
    if (!busyMarkIsWritersideContainer(block)) {
      if ({'p', 'code-block'}.contains(name)) {
        return const WritersideDocumentSerializer().serialize(
          WritersideDocument(
            filePath: '',
            source: '',
            format: WritersideDocumentFormat.xmlTopic,
            nodes: [
              elementNode(name, attrs, [
                for (final inline in block.inlines) ...inlineNodes(inline, ''),
              ], ''),
            ],
          ),
        );
      }
      final content = block.attributes['busymark-xml-leaf-content'];
      return content == null
          ? '<$qualifiedName$attributes/>'
          : '<$qualifiedName$attributes>$content</$qualifiedName>';
    }
    final content = block.children
        .map(
          (child) => child.rawSource != null && !hasDirtyContent(child)
              ? child.rawSource!
              : child.attributes.containsKey('busymark-property-edits')
              ? const BusyMarkMarkdownSerializer().serializeBlock(child)
              : child.isSourceOnly
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
