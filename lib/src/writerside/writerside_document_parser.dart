import 'package:xml/xml_events.dart';

import '../core/source_span.dart';
import '../markdown/busymark_document.dart';
import '../markdown/markdown_model.dart';
import '../markdown/markdown_parser.dart';
import 'writerside_document.dart';
import 'writerside_schema.dart';

class WritersideDocumentParser {
  const WritersideDocumentParser();

  WritersideDocument parseXml({
    required String filePath,
    required String source,
  }) {
    try {
      return WritersideDocument(
        filePath: filePath,
        source: source,
        format: WritersideDocumentFormat.xmlTopic,
        nodes: _parseXmlNodes(filePath: filePath, source: source),
      );
    } on Object {
      return WritersideDocument(
        filePath: filePath,
        source: source,
        format: WritersideDocumentFormat.xmlTopic,
        nodes: [
          WritersideRawNode(
            span: SourceSpan.entireFile(filePath, source),
            rawSource: source,
          ),
        ],
        isWellFormed: false,
      );
    }
  }

  WritersideDocument parseMarkdown({
    required String filePath,
    required String source,
    required BusyDocument markdown,
  }) {
    final nodes = <WritersideDocumentNode>[];
    for (final block in markdown.blocks) {
      final span = block.sourceSpan ?? SourceSpan.entireFile(filePath, source);
      final raw =
          _safeSubstring(source, span.startOffset, span.endOffset) ??
          block.rawSource ??
          block.plainText;
      if (_isSemanticXmlBlock(block, raw)) {
        try {
          final parsed = _parseXmlNodes(
            filePath: filePath,
            source: raw,
            sourceOffset: span.startOffset,
            completeSource: source,
            markdownContent: true,
          );
          if (parsed.whereType<WritersideElementNode>().isNotEmpty) {
            nodes.addAll(parsed);
            continue;
          }
        } on Object {
          // Retain the original Markdown block when an in-progress XML
          // fragment is temporarily malformed.
        }
      }
      nodes.add(
        WritersideMarkdownBlockNode(block: block, span: span, rawSource: raw),
      );
    }
    return WritersideDocument(
      filePath: filePath,
      source: source,
      format: WritersideDocumentFormat.markdown,
      nodes: nodes,
    );
  }

  List<WritersideDocumentNode> _parseXmlNodes({
    required String filePath,
    required String source,
    int sourceOffset = 0,
    String? completeSource,
    bool markdownContent = false,
  }) {
    final fullSource = completeSource ?? source;
    final roots = <WritersideDocumentNode>[];
    final stack = <_ElementFrame>[];

    void append(WritersideDocumentNode node) {
      if (stack.isEmpty) {
        roots.add(node);
      } else {
        stack.last.children.add(node);
      }
    }

    for (final event in parseEvents(
      source,
      withLocation: true,
      validateNesting: true,
      validateDocument: false,
    )) {
      final localStart = event.start ?? 0;
      final localEnd = event.stop ?? localStart;
      final start = sourceOffset + localStart;
      final end = sourceOffset + localEnd;
      if (event is XmlStartElementEvent) {
        final opening = source.substring(localStart, localEnd);
        final frame = _ElementFrame(
          name: _localName(event.name),
          qualifiedName: event.name,
          attributes: {
            for (final attribute in event.attributes)
              _localName(attribute.name): attribute.value,
          },
          qualifiedAttributes: [
            for (final attribute in event.attributes)
              WritersideQualifiedAttribute(
                name: _localName(attribute.name),
                qualifiedName: attribute.name,
                value: attribute.value,
              ),
          ],
          attributeSpans: _attributeSpans(
            filePath: filePath,
            fullSource: fullSource,
            openingSource: opening,
            openingOffset: start,
          ),
          startOffset: start,
          openingEndOffset: end,
        );
        if (event.isSelfClosing) {
          append(frame.build(filePath: filePath, source: fullSource, end: end));
        } else {
          stack.add(frame);
        }
        continue;
      }
      if (event is XmlEndElementEvent) {
        if (stack.isEmpty) {
          continue;
        }
        final frame = stack.removeLast();
        if (markdownContent && _markdownContainers.contains(frame.name)) {
          final inner = fullSource.substring(frame.openingEndOffset, start);
          if (RegExp(r'^\s*\n\s*\n').hasMatch(inner) &&
              RegExp(r'\n\s*\n\s*$').hasMatch(inner) &&
              !inner.contains('<![CDATA[')) {
            final parsed = const MarkdownParser().parse(
              filePath: filePath,
              source: inner,
              mode: MarkdownMode.writersideMarkdown,
              validateLocalReferences: false,
            );
            final mixed = parseMarkdown(
              filePath: filePath,
              source: inner,
              markdown: parsed.busyDocument,
            );
            frame.children
              ..clear()
              ..addAll(
                mixed.nodes.map(
                  (node) => _rebaseNode(
                    node,
                    frame.openingEndOffset,
                    filePath,
                    fullSource,
                  ),
                ),
              );
          }
        }
        append(frame.build(filePath: filePath, source: fullSource, end: end));
        continue;
      }
      if (event is XmlTextEvent) {
        append(
          WritersideTextNode(
            text: event.value,
            span: SourceSpan.fromOffsets(
              filePath: filePath,
              source: fullSource,
              startOffset: start,
              endOffset: end,
            ),
            rawSource: _safeSubstring(fullSource, start, end) ?? event.value,
          ),
        );
        continue;
      }
      if (event is XmlCDATAEvent) {
        append(
          WritersideTextNode(
            text: event.value,
            span: SourceSpan.fromOffsets(
              filePath: filePath,
              source: fullSource,
              startOffset: start,
              endOffset: end,
            ),
            rawSource:
                _safeSubstring(fullSource, start, end) ??
                '<![CDATA[${event.value}]]>',
          ),
        );
        continue;
      }
      append(
        WritersideRawNode(
          span: SourceSpan.fromOffsets(
            filePath: filePath,
            source: fullSource,
            startOffset: start,
            endOffset: end,
          ),
          rawSource: _safeSubstring(fullSource, start, end) ?? '',
        ),
      );
    }
    if (stack.isNotEmpty) {
      throw const FormatException('Unclosed Writerside XML element');
    }
    return roots;
  }

  bool _isSemanticXmlBlock(BusyBlock block, String source) {
    if (!source.trimLeft().startsWith('<')) {
      return false;
    }
    return block.kind == BusyBlockKind.writersideAdmonition ||
        block.kind == BusyBlockKind.writersideTabs ||
        block.kind == BusyBlockKind.writersideProcedure ||
        block.kind == BusyBlockKind.writersideRawXml ||
        block.kind == BusyBlockKind.video ||
        block.kind == BusyBlockKind.htmlBlock ||
        block.kind == BusyBlockKind.unknown;
  }
}

const _markdownContainers = {
  'snippet',
  'tab',
  'chapter',
  'note',
  'tip',
  'warning',
  'quote',
  'step',
  'li',
  'def',
  'td',
  'if',
  'description',
  'card',
  'section-starting-page',
};

WritersideDocumentNode _rebaseNode(
  WritersideDocumentNode node,
  int offset,
  String filePath,
  String source,
) {
  SourceSpan span(SourceSpan original) => SourceSpan.fromOffsets(
    filePath: filePath,
    source: source,
    startOffset: offset + original.startOffset,
    endOffset: offset + original.endOffset,
  );
  BusyBlock block(BusyBlock original) => original.copyWith(
    sourceSpan: original.sourceSpan == null ? null : span(original.sourceSpan!),
    children: original.children.map(block).toList(),
  );
  if (node is WritersideMarkdownBlockNode) {
    return WritersideMarkdownBlockNode(
      block: block(node.block),
      span: span(node.span),
      rawSource: node.rawSource,
    );
  }
  if (node is WritersideTextNode) {
    return WritersideTextNode(
      text: node.text,
      span: span(node.span),
      rawSource: node.rawSource,
    );
  }
  if (node is WritersideRawNode) {
    return WritersideRawNode(span: span(node.span), rawSource: node.rawSource);
  }
  final element = node as WritersideElementNode;
  final frame = _ElementFrame(
    name: element.name,
    qualifiedName: element.qualifiedName,
    attributes: element.attributes,
    qualifiedAttributes: element.qualifiedAttributes,
    attributeSpans: element.attributeSpans.map(
      (key, value) => MapEntry(key, span(value)),
    ),
    startOffset: offset + element.span.startOffset,
    openingEndOffset: offset + element.span.startOffset,
  );
  frame.children.addAll(
    element.children.map(
      (child) => _rebaseNode(child, offset, filePath, source),
    ),
  );
  return frame.build(
    filePath: filePath,
    source: source,
    end: offset + element.span.endOffset,
  );
}

class _ElementFrame {
  _ElementFrame({
    required this.name,
    required this.qualifiedName,
    required this.attributes,
    required this.qualifiedAttributes,
    required this.attributeSpans,
    required this.startOffset,
    required this.openingEndOffset,
  });

  final String name;
  final String qualifiedName;
  final Map<String, String> attributes;
  final List<WritersideQualifiedAttribute> qualifiedAttributes;
  final Map<String, SourceSpan> attributeSpans;
  final int startOffset;
  final int openingEndOffset;
  final List<WritersideDocumentNode> children = [];

  WritersideElementNode build({
    required String filePath,
    required String source,
    required int end,
  }) {
    final span = SourceSpan.fromOffsets(
      filePath: filePath,
      source: source,
      startOffset: startOffset,
      endOffset: end,
    );
    final raw =
        _safeSubstring(source, startOffset, end) ??
        _safeSubstring(source, startOffset, openingEndOffset) ??
        '';
    final capability = WritersideSchema.capabilityFor(name);
    if (capability != null) {
      return WritersideSemanticElementNode(
        kind: capability.kind,
        name: name,
        qualifiedName: qualifiedName,
        attributes: Map.unmodifiable(attributes),
        qualifiedAttributes: List.unmodifiable(qualifiedAttributes),
        attributeSpans: Map.unmodifiable(attributeSpans),
        children: List.unmodifiable(children),
        span: span,
        rawSource: raw,
      );
    }
    return WritersideGenericElementNode(
      schemaKnown: WritersideSchema.isKnownElement(name),
      name: name,
      qualifiedName: qualifiedName,
      attributes: Map.unmodifiable(attributes),
      qualifiedAttributes: List.unmodifiable(qualifiedAttributes),
      attributeSpans: Map.unmodifiable(attributeSpans),
      children: List.unmodifiable(children),
      span: span,
      rawSource: raw,
    );
  }
}

Map<String, SourceSpan> _attributeSpans({
  required String filePath,
  required String fullSource,
  required String openingSource,
  required int openingOffset,
}) {
  final result = <String, SourceSpan>{};
  final matches = RegExp(
    r'''([A-Za-z_][A-Za-z0-9_.:-]*)\s*=\s*(["'])(.*?)\2''',
  ).allMatches(openingSource);
  for (final match in matches) {
    final quoteOffset = openingSource.indexOf(
      match.group(2)!,
      match.start + match.group(1)!.length,
    );
    final valueStart = quoteOffset + 1;
    final valueEnd = valueStart + match.group(3)!.length;
    result[_localName(match.group(1)!)] = SourceSpan.fromOffsets(
      filePath: filePath,
      source: fullSource,
      startOffset: openingOffset + valueStart,
      endOffset: openingOffset + valueEnd,
    );
  }
  return result;
}

String _localName(String value) => value.split(':').last.toLowerCase();

String? _safeSubstring(String value, int start, int end) {
  if (start < 0 || end < start || end > value.length) {
    return null;
  }
  return value.substring(start, end);
}
