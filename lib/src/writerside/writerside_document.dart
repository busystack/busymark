import '../core/source_span.dart';
import '../markdown/busymark_document.dart';
import 'writerside_schema.dart';

enum WritersideDocumentFormat { xmlTopic, markdown }

const writersideSourceModuleRootAttribute =
    'busymark-writerside-source-module-root';
const writersideSourceTopicPathAttribute =
    'busymark-writerside-source-topic-path';

bool writersideIgnorableRaw(String source) {
  final value = source.trim();
  return value.isEmpty ||
      value.startsWith('<!--') ||
      value.startsWith('<?') ||
      value.startsWith('<!DOCTYPE');
}

class WritersideSourceProvenance {
  const WritersideSourceProvenance({
    required this.moduleRoot,
    required this.topicPath,
  });

  final String moduleRoot;
  final String topicPath;
}

/// The source spelling of an XML attribute alongside its normalized semantic
/// lookup name. Writerside semantics use [name], while lossless serialization
/// must retain namespace prefixes and original casing from [qualifiedName].
class WritersideQualifiedAttribute {
  const WritersideQualifiedAttribute({
    required this.name,
    required this.qualifiedName,
    required this.value,
  });

  final String name;
  final String qualifiedName;
  final String value;
}

class WritersideDocument {
  const WritersideDocument({
    required this.filePath,
    required this.source,
    required this.format,
    required this.nodes,
    this.isWellFormed = true,
  });

  final String filePath;
  final String source;
  final WritersideDocumentFormat format;
  final List<WritersideDocumentNode> nodes;
  final bool isWellFormed;

  WritersideElementNode? get rootElement =>
      nodes.whereType<WritersideElementNode>().firstOrNull;

  Iterable<WritersideDocumentNode> walk() sync* {
    for (final node in nodes) {
      yield* node.walk();
    }
  }

  Iterable<WritersideElementNode> get elements =>
      walk().whereType<WritersideElementNode>();

  WritersideElementNode? elementById(String id) {
    for (final element in elements) {
      if (element.attributes['id'] == id) {
        return element;
      }
    }
    return null;
  }

  /// The source representation is immaterial to reference identity. Markdown
  /// headings own the following blocks up to the next peer or ancestor heading.
  List<WritersideDocumentNode>? contentById(String id) {
    List<WritersideDocumentNode>? search(
      List<WritersideDocumentNode> siblings,
    ) {
      for (var i = 0; i < siblings.length; i++) {
        final node = siblings[i];
        if (node is WritersideElementNode) {
          if (node.attributes['id'] == id) return [node];
          final nested = search(node.children);
          if (nested != null) return nested;
        } else if (node is WritersideMarkdownBlockNode) {
          if (node.block.attributes['id'] == id) {
            if (node.block.kind != BusyBlockKind.heading) return [node];
            final level =
                int.tryParse(node.block.attributes['level'] ?? '') ?? 1;
            var end = i + 1;
            while (end < siblings.length) {
              final next = siblings[end];
              if (next is WritersideMarkdownBlockNode &&
                  next.block.kind == BusyBlockKind.heading &&
                  (int.tryParse(next.block.attributes['level'] ?? '') ?? 1) <=
                      level) {
                break;
              }
              end++;
            }
            return siblings.sublist(i, end);
          }
          List<WritersideDocumentNode>? searchBlocks(List<BusyBlock> blocks) {
            for (final block in blocks) {
              if (block.attributes['id'] == id) {
                return [
                  WritersideMarkdownBlockNode(
                    block: block,
                    span: block.sourceSpan ?? node.span,
                    rawSource: block.rawSource ?? node.rawSource,
                  ),
                ];
              }
              final nested = searchBlocks(block.children);
              if (nested != null) return nested;
            }
            return null;
          }

          final nested = searchBlocks(node.block.children);
          if (nested != null) return nested;
        }
      }
      return null;
    }

    return search(nodes);
  }

  WritersideDocument copyWith({
    List<WritersideDocumentNode>? nodes,
    bool? isWellFormed,
  }) {
    return WritersideDocument(
      filePath: filePath,
      source: source,
      format: format,
      nodes: nodes ?? this.nodes,
      isWellFormed: isWellFormed ?? this.isWellFormed,
    );
  }
}

sealed class WritersideDocumentNode {
  const WritersideDocumentNode({
    required this.span,
    required this.rawSource,
    this.provenance,
    this.isModified = false,
  });

  final SourceSpan span;
  final String rawSource;
  final WritersideSourceProvenance? provenance;
  final bool isModified;

  Iterable<WritersideDocumentNode> walk() sync* {
    yield this;
  }

  String get plainText;
}

class WritersideTextNode extends WritersideDocumentNode {
  const WritersideTextNode({
    required this.text,
    required super.span,
    required super.rawSource,
    super.provenance,
    super.isModified,
  });

  final String text;

  @override
  String get plainText => text;

  WritersideTextNode copyWith({
    String? text,
    WritersideSourceProvenance? provenance,
  }) {
    final nextText = text ?? this.text;
    return WritersideTextNode(
      text: nextText,
      span: span,
      rawSource: rawSource,
      provenance: provenance ?? this.provenance,
      isModified: isModified || nextText != this.text,
    );
  }
}

class WritersideRawNode extends WritersideDocumentNode {
  const WritersideRawNode({
    required super.span,
    required super.rawSource,
    super.provenance,
    super.isModified,
  });

  @override
  String get plainText => '';

  WritersideRawNode copyWith({WritersideSourceProvenance? provenance}) =>
      WritersideRawNode(
        span: span,
        rawSource: rawSource,
        provenance: provenance ?? this.provenance,
        isModified: isModified,
      );
}

sealed class WritersideElementNode extends WritersideDocumentNode {
  const WritersideElementNode({
    required this.name,
    required this.qualifiedName,
    required this.attributes,
    required this.qualifiedAttributes,
    required this.attributeSpans,
    required this.children,
    required super.span,
    required super.rawSource,
    super.provenance,
    super.isModified,
  });

  final String name;
  final String qualifiedName;
  final Map<String, String> attributes;
  final List<WritersideQualifiedAttribute> qualifiedAttributes;
  final Map<String, SourceSpan> attributeSpans;
  final List<WritersideDocumentNode> children;

  WritersideSemanticKind? get semanticKind;
  bool get schemaKnown;

  @override
  String get plainText => children.map((node) => node.plainText).join();

  @override
  Iterable<WritersideDocumentNode> walk() sync* {
    yield this;
    for (final child in children) {
      yield* child.walk();
    }
  }

  WritersideElementNode copyWith({
    Map<String, String>? attributes,
    List<WritersideDocumentNode>? children,
    WritersideSourceProvenance? provenance,
  });
}

/// A node for which BusyMark has an explicit semantic interpretation.
class WritersideSemanticElementNode extends WritersideElementNode {
  const WritersideSemanticElementNode({
    required this.kind,
    required super.name,
    required super.qualifiedName,
    required super.attributes,
    required super.qualifiedAttributes,
    required super.attributeSpans,
    required super.children,
    required super.span,
    required super.rawSource,
    super.provenance,
    super.isModified,
  });

  final WritersideSemanticKind kind;

  @override
  WritersideSemanticKind get semanticKind => kind;

  @override
  bool get schemaKnown => true;

  @override
  WritersideSemanticElementNode copyWith({
    Map<String, String>? attributes,
    List<WritersideDocumentNode>? children,
    WritersideSourceProvenance? provenance,
  }) {
    final nextAttributes = attributes ?? this.attributes;
    final nextChildren = children ?? this.children;
    return WritersideSemanticElementNode(
      kind: kind,
      name: name,
      qualifiedName: qualifiedName,
      attributes: nextAttributes,
      qualifiedAttributes: qualifiedAttributes,
      attributeSpans: attributeSpans,
      children: nextChildren,
      span: span,
      rawSource: rawSource,
      provenance: provenance ?? this.provenance,
      isModified:
          isModified ||
          !_sameStringMap(nextAttributes, this.attributes) ||
          !_sameNodeList(nextChildren, this.children),
    );
  }
}

/// A lossless node for schema-known elements without a special renderer, and
/// for extensions unknown to the selected schema version.
class WritersideGenericElementNode extends WritersideElementNode {
  const WritersideGenericElementNode({
    required this.schemaKnown,
    required super.name,
    required super.qualifiedName,
    required super.attributes,
    required super.qualifiedAttributes,
    required super.attributeSpans,
    required super.children,
    required super.span,
    required super.rawSource,
    super.provenance,
    super.isModified,
  });

  @override
  final bool schemaKnown;

  @override
  WritersideSemanticKind? get semanticKind => null;

  @override
  WritersideGenericElementNode copyWith({
    Map<String, String>? attributes,
    List<WritersideDocumentNode>? children,
    WritersideSourceProvenance? provenance,
  }) {
    final nextAttributes = attributes ?? this.attributes;
    final nextChildren = children ?? this.children;
    return WritersideGenericElementNode(
      schemaKnown: schemaKnown,
      name: name,
      qualifiedName: qualifiedName,
      attributes: nextAttributes,
      qualifiedAttributes: qualifiedAttributes,
      attributeSpans: attributeSpans,
      children: nextChildren,
      span: span,
      rawSource: rawSource,
      provenance: provenance ?? this.provenance,
      isModified:
          isModified ||
          !_sameStringMap(nextAttributes, this.attributes) ||
          !_sameNodeList(nextChildren, this.children),
    );
  }
}

/// A Markdown block retained without a lossy serialization step. Embedded
/// semantic XML blocks are parsed into [WritersideElementNode] instead.
class WritersideMarkdownBlockNode extends WritersideDocumentNode {
  const WritersideMarkdownBlockNode({
    required this.block,
    required super.span,
    required super.rawSource,
    super.provenance,
    super.isModified,
  });

  final BusyBlock block;

  @override
  String get plainText => block.plainText;

  WritersideMarkdownBlockNode copyWith({
    BusyBlock? block,
    WritersideSourceProvenance? provenance,
  }) {
    final nextBlock = block ?? this.block;
    return WritersideMarkdownBlockNode(
      block: nextBlock,
      span: span,
      rawSource: rawSource,
      provenance: provenance ?? this.provenance,
      isModified: isModified || !identical(nextBlock, this.block),
    );
  }
}

bool _sameStringMap(Map<String, String> first, Map<String, String> second) {
  if (first.length != second.length) {
    return false;
  }
  for (final entry in first.entries) {
    if (second[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

bool _sameNodeList(
  List<WritersideDocumentNode> first,
  List<WritersideDocumentNode> second,
) {
  if (first.length != second.length) {
    return false;
  }
  for (var index = 0; index < first.length; index++) {
    if (!identical(first[index], second[index])) {
      return false;
    }
  }
  return true;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
