import '../markdown/busymark_document.dart';
import '../markdown/markdown_model.dart';
import '../markdown/math_syntax.dart';
import 'writerside_document.dart';
import 'writerside_schema.dart';
import 'writerside_source_loader.dart';

class WritersideDocumentRenderer {
  const WritersideDocumentRenderer();

  BusyDocument toBusyDocument(
    WritersideDocument document, {
    String? title,
    bool includeTitleHeading = false,
    int titleHeadingLevel = 1,
  }) {
    final blocks = <BusyBlock>[
      if (includeTitleHeading && title?.trim().isNotEmpty == true)
        BusyBlock(
          id: 'writerside-document-title',
          kind: BusyBlockKind.heading,
          inlines: [BusyInline(kind: BusyInlineKind.text, text: title!.trim())],
          attributes: {
            'level': '${titleHeadingLevel.clamp(1, 6)}',
            'id': _headingId(title),
            'element': 'title',
          },
          isGenerated: true,
        ),
      ..._blocks(document.nodes, headingLevel: titleHeadingLevel + 1),
    ];
    return BusyDocument(
      filePath: document.filePath,
      mode: MarkdownMode.writersideMarkdown,
      title: title,
      blocks: List.unmodifiable(blocks),
      source: document.source,
    );
  }

  List<BusyBlock> _blocks(
    Iterable<WritersideDocumentNode> nodes, {
    required int headingLevel,
  }) {
    final result = <BusyBlock>[];
    for (final node in nodes) {
      if (node is WritersideRawNode) {
        if (!writersideIgnorableRaw(node.rawSource)) {
          result.add(
            BusyBlock(
              id: _id('unsupported', node.span.startOffset),
              kind: BusyBlockKind.codeBlock,
              inlines: [
                BusyInline(kind: BusyInlineKind.text, text: node.rawSource),
              ],
              attributes: const {'unsupported': 'true', 'language': 'xml'},
              sourceSpan: node.span,
            ),
          );
        }
        continue;
      }
      if (node is WritersideMarkdownBlockNode) {
        if (node.block.kind != BusyBlockKind.frontMatter &&
            !node.block.isSourceOnly) {
          result.add(_withProvenance(node.block, node.provenance));
        }
        continue;
      }
      if (node is WritersideTextNode) {
        if (node.text.trim().isNotEmpty) {
          result.add(
            BusyBlock(
              id: _id('text', node.span.startOffset),
              kind: BusyBlockKind.paragraph,
              inlines: [BusyInline(kind: BusyInlineKind.text, text: node.text)],
              sourceSpan: node.span,
            ),
          );
        }
        continue;
      }
      final element = node as WritersideElementNode;
      final kind = element.semanticKind;
      final attributes = _attributes(element);
      switch (kind) {
        case WritersideSemanticKind.topic:
        case WritersideSemanticKind.condition:
        case WritersideSemanticKind.container:
          result.addAll(_blocks(element.children, headingLevel: headingLevel));
        case null:
          result.add(
            BusyBlock(
              id: _nodeId(element),
              kind: BusyBlockKind.codeBlock,
              inlines: [
                BusyInline(kind: BusyInlineKind.text, text: element.rawSource),
              ],
              attributes: {
                ...attributes,
                'unsupported': 'true',
                'language': 'xml',
              },
              sourceSpan: element.span,
            ),
          );
        case WritersideSemanticKind.paragraph:
          final inlines = _inlines(element.children, element);
          if (inlines.isNotEmpty) {
            result.add(
              BusyBlock(
                id: _nodeId(element),
                kind: BusyBlockKind.paragraph,
                inlines: inlines,
                attributes: attributes,
                sourceSpan: element.span,
              ),
            );
          }
          result.addAll(
            _nestedBlocks(element.children, headingLevel: headingLevel),
          );
        case WritersideSemanticKind.chapter:
          final title = _elementTitle(element);
          result.add(
            BusyBlock(
              id: _nodeId(element),
              kind: BusyBlockKind.heading,
              inlines: [
                if (title.isNotEmpty)
                  BusyInline(kind: BusyInlineKind.text, text: title),
              ],
              children: _blocks(
                _contentChildren(element),
                headingLevel: headingLevel + 1,
              ),
              attributes: {
                ...attributes,
                'level': '${headingLevel.clamp(1, 6)}',
                'id': element.attributes['id'] ?? _headingId(title),
              },
              sourceSpan: element.span,
            ),
          );
        case WritersideSemanticKind.procedure:
          result.add(
            BusyBlock(
              id: _nodeId(element),
              kind: BusyBlockKind.writersideProcedure,
              inlines: [
                if (_elementTitle(element).isNotEmpty)
                  BusyInline(
                    kind: BusyInlineKind.text,
                    text: _elementTitle(element),
                  ),
              ],
              children: _blocks(
                _contentChildren(element),
                headingLevel: headingLevel + 1,
              ),
              attributes: attributes,
              sourceSpan: element.span,
            ),
          );
        case WritersideSemanticKind.step:
          result.add(
            BusyBlock(
              id: _nodeId(element),
              kind: BusyBlockKind.orderedListItem,
              inlines: _inlines(element.children, element),
              children: _nestedBlocks(
                element.children,
                headingLevel: headingLevel,
              ),
              attributes: {...attributes, 'ordered': 'true', 'marker': '1.'},
              sourceSpan: element.span,
            ),
          );
        case WritersideSemanticKind.list:
          result.addAll(_listBlocks(element, headingLevel: headingLevel));
        case WritersideSemanticKind.listItem:
          result.add(
            _listItemBlock(
              element,
              listType: 'bullet',
              itemNumber: 1,
              headingLevel: headingLevel,
            ),
          );
        case WritersideSemanticKind.table:
          result.add(_table(element));
        case WritersideSemanticKind.codeBlock:
          final language = element.attributes['lang'];
          final text = _trimCode(
            element.attributes[writersideResolvedSourceAttribute] ??
                element.plainText,
          );
          if (language?.toLowerCase() == 'tex') {
            result.add(
              BusyBlock(
                id: _nodeId(element),
                kind: BusyBlockKind.math,
                inlines: [BusyInline(kind: BusyInlineKind.math, text: text)],
                attributes: {
                  ...attributes,
                  'language': language!,
                  busyMarkMathExpressionAttribute: text,
                  busyMarkMathDisplayAttribute: 'true',
                  busyMarkMathSourceFormAttribute:
                      BusyMathSourceForm.writersideTexElement.name,
                },
                sourceSpan: element.span,
              ),
            );
          } else {
            result.add(
              BusyBlock(
                id: _nodeId(element),
                kind: BusyBlockKind.codeBlock,
                inlines: [BusyInline(kind: BusyInlineKind.text, text: text)],
                attributes: {
                  ...attributes,
                  if (language != null) 'language': language,
                },
                sourceSpan: element.span,
              ),
            );
          }
        case WritersideSemanticKind.math:
          final expression = element.plainText.trim();
          result.add(
            BusyBlock(
              id: _nodeId(element),
              kind: BusyBlockKind.math,
              inlines: [
                BusyInline(kind: BusyInlineKind.math, text: expression),
              ],
              attributes: {
                ...attributes,
                busyMarkMathExpressionAttribute: expression,
                busyMarkMathDisplayAttribute: 'true',
                busyMarkMathSourceFormAttribute:
                    BusyMathSourceForm.writersideElement.name,
              },
              sourceSpan: element.span,
            ),
          );
        case WritersideSemanticKind.note:
        case WritersideSemanticKind.tip:
        case WritersideSemanticKind.warning:
        case WritersideSemanticKind.quote:
          final paragraphChildren = element.children
              .whereType<WritersideElementNode>()
              .where(
                (child) =>
                    child.semanticKind == WritersideSemanticKind.paragraph,
              )
              .toList();
          final singleParagraph =
              paragraphChildren.length == 1 &&
              element.children.whereType<WritersideElementNode>().length == 1;
          result.add(
            BusyBlock(
              id: _nodeId(element),
              kind: BusyBlockKind.writersideAdmonition,
              inlines: singleParagraph
                  ? _inlines(paragraphChildren.single.children, element)
                  : _inlines(element.children, element),
              children: singleParagraph
                  ? const []
                  : _nestedBlocks(element.children, headingLevel: headingLevel),
              attributes: {
                ...attributes,
                'style': element.name,
                busyMarkWritersideAdmonitionAttribute: 'true',
              },
              sourceSpan: element.span,
            ),
          );
        case WritersideSemanticKind.tabs:
        case WritersideSemanticKind.tab:
          result.add(
            BusyBlock(
              id: _nodeId(element),
              kind: BusyBlockKind.writersideTabs,
              inlines: [
                if (_elementTitle(element).isNotEmpty)
                  BusyInline(
                    kind: BusyInlineKind.text,
                    text: _elementTitle(element),
                  ),
              ],
              children: _blocks(
                _contentChildren(element),
                headingLevel: headingLevel,
              ),
              attributes: attributes,
              sourceSpan: element.span,
            ),
          );
        case WritersideSemanticKind.definitionList:
          final children = _blocks(
            element.children,
            headingLevel: headingLevel,
          );
          final inheritedCollapsible = element.attributes['collapsible'];
          result.add(
            BusyBlock(
              id: _nodeId(element),
              kind: BusyBlockKind.writersideRawXml,
              children: [
                for (final child in children)
                  inheritedCollapsible == null ||
                          child.attributes.containsKey('collapsible')
                      ? child
                      : child.copyWith(
                          attributes: {
                            ...child.attributes,
                            'collapsible': inheritedCollapsible,
                          },
                        ),
              ],
              attributes: attributes,
              sourceSpan: element.span,
            ),
          );
        case WritersideSemanticKind.definition:
          result.add(
            BusyBlock(
              id: _nodeId(element),
              kind: BusyBlockKind.writersideRawXml,
              inlines: [
                if (_elementTitle(element).isNotEmpty)
                  BusyInline(
                    kind: BusyInlineKind.strong,
                    text: _elementTitle(element),
                  ),
              ],
              children: _blocks(
                _contentChildren(element),
                headingLevel: headingLevel,
              ),
              attributes: attributes,
              sourceSpan: element.span,
            ),
          );
        case WritersideSemanticKind.image:
          result.add(_imageBlock(element));
        case WritersideSemanticKind.video:
          result.add(
            BusyBlock(
              id: _nodeId(element),
              kind: BusyBlockKind.video,
              attributes: attributes,
              sourceSpan: element.span,
            ),
          );
        case WritersideSemanticKind.title:
        case WritersideSemanticKind.metadata:
        case WritersideSemanticKind.variable:
        case WritersideSemanticKind.snippet:
          break;
        case WritersideSemanticKind.include:
          result.add(
            BusyBlock(
              id: _nodeId(element),
              kind: BusyBlockKind.unknown,
              inlines: const [
                BusyInline(
                  kind: BusyInlineKind.text,
                  text: 'Unresolved Writerside include',
                ),
              ],
              attributes: attributes,
              sourceSpan: element.span,
            ),
          );
        case WritersideSemanticKind.tableRow:
        case WritersideSemanticKind.tableCell:
        case WritersideSemanticKind.link:
        case WritersideSemanticKind.control:
        case WritersideSemanticKind.path:
        case WritersideSemanticKind.shortcut:
        case WritersideSemanticKind.code:
        case WritersideSemanticKind.resource:
        case WritersideSemanticKind.tooltip:
        case WritersideSemanticKind.strong:
        case WritersideSemanticKind.emphasis:
        case WritersideSemanticKind.lineBreak:
          final inlines = _inlines([element], element);
          if (inlines.isNotEmpty) {
            result.add(
              BusyBlock(
                id: _nodeId(element),
                kind: BusyBlockKind.paragraph,
                inlines: inlines,
                attributes: attributes,
                sourceSpan: element.span,
              ),
            );
          }
      }
    }
    return result;
  }

  BusyBlock _table(WritersideElementNode table) {
    final rows = table.children.whereType<WritersideElementNode>().where(
      (element) => element.semanticKind == WritersideSemanticKind.tableRow,
    );
    return BusyBlock(
      id: _nodeId(table),
      kind: BusyBlockKind.table,
      attributes: _attributes(table),
      children: [
        for (final row in rows)
          BusyBlock(
            id: _nodeId(row),
            kind: BusyBlockKind.table,
            attributes: {
              ..._attributes(row),
              'header': row.attributes['header'] ?? 'false',
            },
            children: [
              for (final cell
                  in row.children.whereType<WritersideElementNode>().where(
                    (element) =>
                        element.semanticKind ==
                        WritersideSemanticKind.tableCell,
                  ))
                BusyBlock(
                  id: _nodeId(cell),
                  kind: BusyBlockKind.paragraph,
                  inlines: _inlines(cell.children, cell),
                  children: _nestedBlocks(cell.children, headingLevel: 2),
                  attributes: {..._attributes(cell), 'cell': 'td'},
                  sourceSpan: cell.span,
                ),
            ],
            sourceSpan: row.span,
          ),
      ],
      sourceSpan: table.span,
    );
  }

  List<BusyBlock> _listBlocks(
    WritersideElementNode list, {
    required int headingLevel,
  }) {
    final type = list.attributes['type']?.trim().toLowerCase() ?? 'bullet';
    final start = int.tryParse(list.attributes['start'] ?? '') ?? 1;
    var itemNumber = start;
    final result = <BusyBlock>[];
    for (final child in list.children) {
      if (child is WritersideElementNode &&
          child.semanticKind == WritersideSemanticKind.listItem) {
        result.add(
          _listItemBlock(
            child,
            listType: type,
            itemNumber: itemNumber++,
            headingLevel: headingLevel,
          ),
        );
      } else {
        result.addAll(_blocks([child], headingLevel: headingLevel));
      }
    }
    return result;
  }

  BusyBlock _listItemBlock(
    WritersideElementNode item, {
    required String listType,
    required int itemNumber,
    required int headingLevel,
  }) {
    final ordered = listType == 'decimal' || listType == 'alpha-lower';
    final checkbox = listType == 'checkbox';
    final marker = switch (listType) {
      'decimal' => '$itemNumber.',
      'alpha-lower' => '${_alphaMarker(itemNumber)}.',
      'none' => '',
      _ => '-',
    };
    return BusyBlock(
      id: _nodeId(item),
      kind: checkbox
          ? BusyBlockKind.taskListItem
          : ordered
          ? BusyBlockKind.orderedListItem
          : BusyBlockKind.unorderedListItem,
      inlines: _inlines(item.children, item),
      children: _nestedBlocks(item.children, headingLevel: headingLevel),
      attributes: {
        ..._attributes(item),
        'ordered': '$ordered',
        'marker': marker,
        'listType': listType,
        if (listType == 'none') 'markerHidden': 'true',
        if (checkbox) 'task': item.attributes['checked'] ?? 'false',
      },
      sourceSpan: item.span,
    );
  }

  BusyBlock _imageBlock(WritersideElementNode image) {
    final inline = _imageInline(image);
    return BusyBlock(
      id: _nodeId(image),
      kind: BusyBlockKind.image,
      inlines: [inline],
      attributes: _attributes(image),
      sourceSpan: image.span,
    );
  }

  List<BusyBlock> _nestedBlocks(
    Iterable<WritersideDocumentNode> nodes, {
    required int headingLevel,
  }) {
    return _blocks(
      nodes.where((node) {
        return node is WritersideMarkdownBlockNode ||
            (node is WritersideElementNode && _isBlockElement(node));
      }),
      headingLevel: headingLevel,
    );
  }

  List<BusyInline> _inlines(
    Iterable<WritersideDocumentNode> nodes,
    WritersideElementNode owner,
  ) {
    final result = <BusyInline>[];
    for (final node in nodes) {
      if (node is WritersideTextNode) {
        if (node.text.isNotEmpty) {
          result.add(BusyInline(kind: BusyInlineKind.text, text: node.text));
        }
        continue;
      }
      if (node is! WritersideElementNode || _isBlockElement(node)) {
        continue;
      }
      final children = _inlines(node.children, owner);
      final text = node.plainText;
      switch (node.semanticKind) {
        case WritersideSemanticKind.strong:
          result.add(
            BusyInline(
              kind: BusyInlineKind.strong,
              text: text,
              children: children,
            ),
          );
        case WritersideSemanticKind.emphasis:
          result.add(
            BusyInline(
              kind: BusyInlineKind.emphasis,
              text: text,
              children: children,
            ),
          );
        case WritersideSemanticKind.code:
        case WritersideSemanticKind.control:
        case WritersideSemanticKind.path:
        case WritersideSemanticKind.shortcut:
        case WritersideSemanticKind.resource:
          result.add(
            BusyInline(
              kind: BusyInlineKind.code,
              text: text,
              attributes: _attributes(node),
            ),
          );
        case WritersideSemanticKind.tooltip:
          result.add(
            BusyInline(
              kind: BusyInlineKind.underline,
              text: text,
              children: children,
              attributes: _attributes(node),
            ),
          );
        case WritersideSemanticKind.link:
          result.add(
            BusyInline(
              kind:
                  node.attributes['nullable'] == 'true' &&
                      node.attributes['resolved-available'] == 'false'
                  ? BusyInlineKind.text
                  : BusyInlineKind.link,
              text: text.trim().isEmpty
                  ? node.attributes['resolved-label'] ??
                        node.attributes['href'] ??
                        ''
                  : text,
              destination:
                  node.attributes['resolved-destination'] ??
                  node.attributes['href'] ??
                  (node.attributes['anchor'] == null
                      ? null
                      : '#${node.attributes['anchor']}'),
              children: text.trim().isEmpty ? const [] : children,
              attributes: _attributes(node),
            ),
          );
        case WritersideSemanticKind.image:
          result.add(_imageInline(node));
        case WritersideSemanticKind.math:
          result.add(
            BusyInline(
              kind: BusyInlineKind.math,
              text: text,
              attributes: {
                busyMarkMathSourceFormAttribute:
                    BusyMathSourceForm.writersideElement.name,
                'expressionId': _nodeId(node),
              },
            ),
          );
        case WritersideSemanticKind.lineBreak:
          result.add(
            const BusyInline(kind: BusyInlineKind.hardBreak, text: '\n'),
          );
        case WritersideSemanticKind.title:
        case WritersideSemanticKind.metadata:
        case WritersideSemanticKind.variable:
        case WritersideSemanticKind.snippet:
        case WritersideSemanticKind.include:
          break;
        default:
          result.addAll(
            children.isEmpty && text.isNotEmpty
                ? [BusyInline(kind: BusyInlineKind.text, text: text)]
                : children,
          );
      }
    }
    return result;
  }

  BusyInline _imageInline(WritersideElementNode image) {
    return BusyInline(
      kind: BusyInlineKind.image,
      text: image.attributes['alt'] ?? '',
      destination: image.attributes['src'],
      attributes: _attributes(image),
    );
  }

  bool _isBlockElement(WritersideElementNode element) {
    return WritersideSchema.capabilityFor(element.name)?.block ?? true;
  }

  Iterable<WritersideDocumentNode> _contentChildren(
    WritersideElementNode element,
  ) => element.children.where((node) {
    return node is! WritersideElementNode ||
        node.semanticKind != WritersideSemanticKind.title;
  });

  String _elementTitle(WritersideElementNode element) {
    for (final child in element.children.whereType<WritersideElementNode>()) {
      if (child.semanticKind == WritersideSemanticKind.title &&
          child.plainText.trim().isNotEmpty) {
        return child.plainText.trim();
      }
    }
    return element.attributes['title']?.trim() ?? '';
  }

  Map<String, String> _attributes(WritersideElementNode element) => {
    'element': element.name,
    ...element.attributes,
    if (element.provenance case final provenance?) ...{
      writersideSourceModuleRootAttribute: provenance.moduleRoot,
      writersideSourceTopicPathAttribute: provenance.topicPath,
    },
    if (element is WritersideGenericElementNode)
      'schemaKnown': '${element.schemaKnown}',
  };

  String _nodeId(WritersideDocumentNode node) =>
      _id('writerside', node.span.startOffset);

  String _id(String prefix, int offset) => '$prefix-$offset';

  String _headingId(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .replaceAll(RegExp(r'\s+'), '-');

  String _trimCode(String value) => value
      .replaceFirst(RegExp(r'^\r?\n'), '')
      .replaceFirst(RegExp(r'\r?\n\s*$'), '');

  BusyBlock _withProvenance(
    BusyBlock block,
    WritersideSourceProvenance? provenance,
  ) {
    if (provenance == null) {
      return block;
    }
    BusyInline annotateInline(BusyInline inline) => inline.copyWith(
      attributes: {
        ...inline.attributes,
        writersideSourceModuleRootAttribute: provenance.moduleRoot,
        writersideSourceTopicPathAttribute: provenance.topicPath,
      },
      children: inline.children.map(annotateInline).toList(growable: false),
    );

    return block.copyWith(
      attributes: {
        ...block.attributes,
        writersideSourceModuleRootAttribute: provenance.moduleRoot,
        writersideSourceTopicPathAttribute: provenance.topicPath,
      },
      inlines: block.inlines.map(annotateInline).toList(growable: false),
      children: block.children
          .map((child) => _withProvenance(child, provenance))
          .toList(growable: false),
    );
  }

  String _alphaMarker(int value) {
    var number = value < 1 ? 1 : value;
    final result = StringBuffer();
    while (number > 0) {
      number--;
      result.writeCharCode(97 + (number % 26));
      number ~/= 26;
    }
    return result.toString().split('').reversed.join();
  }
}
