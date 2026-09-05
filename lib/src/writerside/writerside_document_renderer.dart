import 'dart:convert';
import '../export/openapi_static_export_mapper.dart';
import '../export/markdown_export_document.dart';
import '../export/markdown_export_mapper.dart';
import '../visualization/visualization_models.dart';
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
    var blocks = <BusyBlock>[
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
    final keys = <String>{};
    void inlineKeys(Iterable<BusyInline> values) {
      for (final value in values) {
        keys.addAll(
          (value.attributes['switcher-key'] ?? '')
              .split(',')
              .map((key) => key.trim())
              .where((key) => key.isNotEmpty),
        );
        inlineKeys(value.children);
      }
    }

    void findKeys(Iterable<BusyBlock> values) {
      for (final block in values) {
        final key = block.attributes['switcher-key'];
        if (key != null && key.isNotEmpty) {
          keys.addAll(key.split(',').map((value) => value.trim()));
        }
        inlineKeys(block.inlines);
        findKeys(block.children);
      }
    }

    findKeys(blocks);
    if (keys.isNotEmpty) {
      final chapterScopes = <(int, String?)>[];
      BusyInline annotateInline(BusyInline inline) => inline.copyWith(
        attributes: {...inline.attributes, 'switcher-default': keys.first},
        children: inline.children.map(annotateInline).toList(),
      );
      BusyBlock annotate(BusyBlock block) => block.copyWith(
        inlines: block.inlines.map(annotateInline).toList(),
        attributes: {...block.attributes, 'switcher-default': keys.first},
        children: block.children.map(annotate).toList(),
      );
      blocks = [
        BusyBlock(
          id: 'writerside-topic-switcher',
          kind: BusyBlockKind.writersideTabs,
          attributes: {
            'group': 'busymark-topic-switcher',
            'topic-switcher': 'true',
            'title':
                document.rootElement?.attributes['switcher-label'] ??
                document.nodes
                    .whereType<WritersideMarkdownBlockNode>()
                    .where(
                      (node) => node.block.kind == BusyBlockKind.frontMatter,
                    )
                    .firstOrNull
                    ?.block
                    .attributes['switcher-label'] ??
                'Section',
          },
          children: [
            for (final key in keys)
              BusyBlock(
                id: 'switcher-$key',
                kind: BusyBlockKind.writersideTabs,
                inlines: [BusyInline(kind: BusyInlineKind.text, text: key)],
                attributes: {'group-key': key},
              ),
          ],
          isGenerated: true,
        ),
        for (final original in blocks)
          (() {
            var block = original;
            if (block.kind == BusyBlockKind.heading) {
              final level = int.tryParse(block.attributes['level'] ?? '') ?? 1;
              while (chapterScopes.isNotEmpty &&
                  chapterScopes.last.$1 >= level) {
                chapterScopes.removeLast();
              }
              chapterScopes.add((
                level,
                block.attributes['switcher-key'] ??
                    (chapterScopes.isEmpty ? null : chapterScopes.last.$2),
              ));
            }
            if (!block.attributes.containsKey('switcher-key') &&
                chapterScopes.isNotEmpty &&
                chapterScopes.last.$2 != null) {
              block = block.copyWith(
                attributes: {
                  ...block.attributes,
                  'switcher-key': chapterScopes.last.$2!,
                },
              );
            }
            return annotate(block);
          })(),
      ];
    }
    return BusyDocument(
      filePath: document.filePath,
      mode: MarkdownMode.writersideMarkdown,
      title: title,
      blocks: List.unmodifiable(blocks),
      source: document.source,
      frontMatter: {
        for (final element in document.elements)
          if ({
            'link-summary',
            'card-summary',
            'web-summary',
          }.contains(element.name))
            element.name: element.attributes['rel'] == null
                ? element.plainText.trim()
                : document
                          .contentById(element.attributes['rel']!)
                          ?.map((node) => node.plainText)
                          .join(' ')
                          .trim() ??
                      '',
      },
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
          final starting = element.children
              .whereType<WritersideElementNode>()
              .where(
                (child) =>
                    child.semanticKind == WritersideSemanticKind.startingPage,
              )
              .toList();
          result.addAll(
            _blocks(
              starting.isEmpty ? element.children : starting,
              headingLevel: headingLevel,
            ),
          );
        case WritersideSemanticKind.condition:
        case WritersideSemanticKind.container:
        case WritersideSemanticKind.snippet:
          result.addAll(_blocks(element.children, headingLevel: headingLevel));
        case WritersideSemanticKind.startingPage:
        case WritersideSemanticKind.section:
        case WritersideSemanticKind.seealso:
        case WritersideSemanticKind.category:
          final title = _elementTitle(element).isNotEmpty
              ? _elementTitle(element)
              : element.name == 'request'
              ? 'Request samples'
              : element.name == 'response'
              ? 'Response ${element.attributes['type'] ?? 'default'} samples'
              : '';
          final content = _sectionChildren(element);
          result.add(
            BusyBlock(
              id: _nodeId(element),
              kind: BusyBlockKind.htmlBlock,
              attributes: {
                ...attributes,
                'writerside-section': 'true',
                if ({
                  'spotlight',
                  'primary',
                  'secondary',
                  'cards',
                  'misc',
                  'links',
                }.contains(element.name))
                  'writerside-grid': 'true',
              },
              children: [
                if (title.isNotEmpty || kind == WritersideSemanticKind.seealso)
                  BusyBlock(
                    id: '${_nodeId(element)}-title',
                    kind: BusyBlockKind.heading,
                    inlines: [
                      BusyInline(
                        kind: BusyInlineKind.text,
                        text: title.isEmpty ? 'See also' : title,
                      ),
                    ],
                    attributes: {'level': '${headingLevel.clamp(1, 6)}'},
                    sourceSpan: element.span,
                  ),
                ..._blocks(content, headingLevel: headingLevel + 1),
              ],
              sourceSpan: element.span,
            ),
          );
        case WritersideSemanticKind.card:
          result.add(
            BusyBlock(
              id: _nodeId(element),
              kind: BusyBlockKind.htmlBlock,
              attributes: {...attributes, 'writerside-card': 'true'},
              children: [
                if (attributes['image'] ?? attributes['icon'] case final image?)
                  BusyBlock(
                    id: '${_nodeId(element)}-image',
                    kind: BusyBlockKind.image,
                    attributes: attributes,
                    sourceSpan: element.span,
                    inlines: [
                      BusyInline(
                        kind: BusyInlineKind.image,
                        destination: image,
                        text: '',
                      ),
                    ],
                  ),
                if (attributes['badge'] case final badge?)
                  BusyBlock(
                    id: '${_nodeId(element)}-badge',
                    kind: BusyBlockKind.paragraph,
                    inlines: [
                      BusyInline(kind: BusyInlineKind.code, text: badge),
                    ],
                  ),
                BusyBlock(
                  id: '${_nodeId(element)}-link',
                  kind: BusyBlockKind.paragraph,
                  inlines: [
                    BusyInline(
                      kind:
                          attributes['nullable'] == 'true' &&
                              attributes['resolved-available'] == 'false'
                          ? BusyInlineKind.text
                          : BusyInlineKind.link,
                      text:
                          (element.plainText.trim().isEmpty
                              ? null
                              : element.plainText.trim()) ??
                          attributes['resolved-label'] ??
                          attributes['href'] ??
                          element.plainText,
                      destination:
                          attributes['resolved-destination'] ??
                          attributes['href'],
                      attributes: attributes,
                    ),
                  ],
                  sourceSpan: element.span,
                ),
                if (attributes['summary'] case final summary?)
                  BusyBlock(
                    id: '${_nodeId(element)}-summary',
                    kind: BusyBlockKind.paragraph,
                    inlines: [
                      BusyInline(kind: BusyInlineKind.text, text: summary),
                    ],
                    sourceSpan: element.span,
                  ),
              ],
              sourceSpan: element.span,
            ),
          );
        case WritersideSemanticKind.api:
          result.addAll(_apiBlocks(element, headingLevel));
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
              attributes: {
                ...attributes,
                if (kind == WritersideSemanticKind.tabs &&
                    !attributes.containsKey('group'))
                  'group':
                      'busymark-tabs:${element.span.filePath}:${element.span.startOffset}',
              },
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

  List<WritersideDocumentNode> _sectionChildren(WritersideElementNode element) {
    final children = _contentChildren(element).toList();
    if ({'request', 'response'}.contains(element.name)) {
      final samples = children
          .whereType<WritersideElementNode>()
          .where((node) => node.name == 'sample')
          .toList();
      if (samples.isNotEmpty) {
        WritersideElementNode wrap(
          WritersideSemanticKind kind,
          String name,
          WritersideElementNode source,
          List<WritersideDocumentNode> nodes,
          Map<String, String> attributes,
        ) => WritersideSemanticElementNode(
          kind: kind,
          name: name,
          qualifiedName: name,
          attributes: attributes,
          qualifiedAttributes: const [],
          attributeSpans: const {},
          children: nodes,
          span: source.span,
          rawSource: source.rawSource,
          provenance: source.provenance,
        );
        return [
          wrap(WritersideSemanticKind.tabs, 'tabs', element, [
            for (final sample in samples)
              wrap(
                WritersideSemanticKind.tab,
                'tab',
                sample,
                [sample],
                {
                  'title':
                      sample.attributes['title'] ??
                      '${sample.attributes['lang'] ?? 'JSON'} example',
                },
              ),
          ], const {}),
          ...children.where((node) => !samples.contains(node)),
        ];
      }
    }
    if (element.semanticKind == WritersideSemanticKind.seealso) {
      children.sort(
        (a, b) =>
            (a is WritersideElementNode
                    ? int.tryParse(a.attributes['order'] ?? '') ?? 0
                    : 0)
                .compareTo(
                  b is WritersideElementNode
                      ? int.tryParse(b.attributes['order'] ?? '') ?? 0
                      : 0,
                ),
      );
    }
    WritersideDocumentNode cards(WritersideDocumentNode node) {
      if (node is! WritersideElementNode) return node;
      if (node.name != 'a') {
        return node.copyWith(children: node.children.map(cards).toList());
      }
      return WritersideSemanticElementNode(
        kind: WritersideSemanticKind.card,
        name: 'card',
        qualifiedName: node.qualifiedName,
        attributes: {
          ...node.attributes,
          if (node.attributes['card-summary'] case final summary?)
            'summary': summary,
        },
        qualifiedAttributes: node.qualifiedAttributes,
        attributeSpans: node.attributeSpans,
        children: node.children,
        span: node.span,
        rawSource: node.rawSource,
        provenance: node.provenance,
      );
    }

    return element.attributes['style'] == 'cards' || element.name == 'cards'
        ? children.map(cards).toList()
        : children;
  }

  List<BusyBlock> _apiBlocks(WritersideElementNode element, int headingLevel) {
    final selections = element.children
        .whereType<WritersideElementNode>()
        .where((child) => child.semanticKind == WritersideSemanticKind.api)
        .toList();
    if (element.name == 'api-doc' && selections.isNotEmpty) {
      return _blocks(selections, headingLevel: headingLevel);
    }
    try {
      final json = element.attributes['busymark-api-reference'];
      if (json == null) {
        throw FormatException(
          element.attributes['busymark-api-error'] ??
              'Unresolved API specification',
        );
      }
      final reference = OpenApiReferenceModel.fromJson(
        (jsonDecode(json) as Map).cast<Object?, Object?>(),
      );
      final samples = element.children.whereType<WritersideElementNode>().where(
        (child) => {'request', 'response'}.contains(child.name),
      );
      final operationKey =
          "${element.attributes['method']?.toLowerCase() ?? ''} ${element.attributes['endpoint'] ?? element.attributes['webhook'] ?? ''}";
      final sampleBlocks = {
        for (final sample in samples)
          '${sample.span.startOffset}': _blocks([
            sample,
          ], headingLevel: headingLevel + 1).single,
      };
      final mapped = const OpenApiStaticExportMapper().mapWriterside(
        reference,
        element: element.name,
        attributes: element.attributes,
        overrides: {
          for (final sample in samples)
            '$operationKey ${sample.name}${sample.name == 'response' ? ' ${sample.attributes['type'] ?? 'default'}' : ''}':
                [
                  MarkdownExportBlock(
                    kind: MarkdownExportBlockKind.group,
                    attributes: {
                      'writerside-override': '${sample.span.startOffset}',
                    },
                    children: const MarkdownExportMapper()
                        .map(
                          BusyDocument(
                            filePath: element.span.filePath,
                            mode: MarkdownMode.writersideMarkdown,
                            blocks: [
                              sampleBlocks['${sample.span.startOffset}']!,
                            ],
                          ),
                        )
                        .blocks,
                  ),
                ],
        },
      );
      var index = 0;
      BusyInline inline(MarkdownExportInline value) => BusyInline(
        kind: BusyInlineKind.values.firstWhere(
          (kind) => kind.name == value.kind.name,
          orElse: () => BusyInlineKind.text,
        ),
        text: value.text,
        destination: value.attributes['destination'],
        children: value.children.map(inline).toList(),
      );
      BusyBlock block(MarkdownExportBlock value) {
        if (sampleBlocks[value.attributes['writerside-override']]
            case final original?) {
          return original;
        }
        return BusyBlock(
          id: '${_nodeId(element)}-api-${index++}',
          kind: switch (value.kind) {
            MarkdownExportBlockKind.heading => BusyBlockKind.heading,
            MarkdownExportBlockKind.code => BusyBlockKind.codeBlock,
            MarkdownExportBlockKind.table ||
            MarkdownExportBlockKind.tableRow => BusyBlockKind.table,
            MarkdownExportBlockKind.group ||
            MarkdownExportBlockKind.openApiReference => BusyBlockKind.htmlBlock,
            _ => BusyBlockKind.paragraph,
          },
          inlines: value.inlines.isEmpty && value.text.isNotEmpty
              ? [BusyInline(kind: BusyInlineKind.text, text: value.text)]
              : value.inlines.map(inline).toList(),
          children: value.children.map(block).toList(),
          attributes: {
            ..._attributes(element),
            for (final entry in value.attributes.entries)
              entry.key: '${entry.value}',
            if (value.kind == MarkdownExportBlockKind.heading)
              'level':
                  '${((value.attributes['level'] as int? ?? 2) - 3 + headingLevel).clamp(1, 6)}',
          },
          sourceSpan: element.span,
          isGenerated: true,
        );
      }

      return [block(mapped)];
    } on FormatException catch (error) {
      return [
        BusyBlock(
          id: _nodeId(element),
          kind: BusyBlockKind.codeBlock,
          inlines: [
            BusyInline(
              kind: BusyInlineKind.text,
              text:
                  'API reference unavailable: ${error.message}\n${element.rawSource}',
            ),
          ],
          attributes: {..._attributes(element), 'unsupported': 'true'},
          sourceSpan: element.span,
        ),
      ];
    }
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
        for (final (rowIndex, row) in rows.indexed)
          BusyBlock(
            id: _nodeId(row),
            kind: BusyBlockKind.table,
            attributes: {
              ..._attributes(row),
              'header':
                  '${rowIndex == 0 && !{'none', 'header-column'}.contains(table.attributes['style'])}',
            },
            children: [
              for (final (columnIndex, cell)
                  in row.children
                      .whereType<WritersideElementNode>()
                      .where(
                        (element) =>
                            element.semanticKind ==
                            WritersideSemanticKind.tableCell,
                      )
                      .indexed)
                BusyBlock(
                  id: _nodeId(cell),
                  kind: BusyBlockKind.paragraph,
                  inlines: _inlines(cell.children, cell),
                  children: _nestedBlocks(cell.children, headingLevel: 2),
                  attributes: {
                    ..._attributes(cell),
                    'cell': 'td',
                    'header':
                        '${(rowIndex == 0 && !{'none', 'header-column'}.contains(table.attributes['style'])) || (columnIndex == 0 && {'both', 'header-column'}.contains(table.attributes['style']))}',
                  },
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
              attributes: _attributes(node),
              text: text,
              children: children,
            ),
          );
        case WritersideSemanticKind.emphasis:
          result.add(
            BusyInline(
              kind: BusyInlineKind.emphasis,
              attributes: _attributes(node),
              text: text,
              children: children,
            ),
          );
        case WritersideSemanticKind.code:
        case WritersideSemanticKind.control:
        case WritersideSemanticKind.path:
        case WritersideSemanticKind.shortcut:
          result.add(
            BusyInline(
              kind: BusyInlineKind.code,
              text: text.trim().isEmpty
                  ? node.attributes['resolved-label'] ?? ''
                  : text,
              attributes: _attributes(node),
            ),
          );
        case WritersideSemanticKind.tooltip:
          result.add(
            BusyInline(
              kind: BusyInlineKind.underline,
              text: text.trim().isEmpty
                  ? node.attributes['resolved-label'] ?? ''
                  : text,
              children: text.trim().isEmpty ? const [] : children,
              attributes: _attributes(node),
            ),
          );
        case WritersideSemanticKind.resource:
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
