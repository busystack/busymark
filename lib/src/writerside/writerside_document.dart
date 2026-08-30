import '../core/source_span.dart';
import '../markdown/busymark_document.dart';
import 'writerside_schema.dart';

enum WritersideDocumentFormat { xmlTopic, markdown }

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
  const WritersideDocumentNode({required this.span, required this.rawSource});

  final SourceSpan span;
  final String rawSource;

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
  });

  final String text;

  @override
  String get plainText => text;

  WritersideTextNode copyWith({String? text}) => WritersideTextNode(
    text: text ?? this.text,
    span: span,
    rawSource: rawSource,
  );
}

class WritersideRawNode extends WritersideDocumentNode {
  const WritersideRawNode({required super.span, required super.rawSource});

  @override
  String get plainText => '';
}

sealed class WritersideElementNode extends WritersideDocumentNode {
  const WritersideElementNode({
    required this.name,
    required this.attributes,
    required this.attributeSpans,
    required this.children,
    required super.span,
    required super.rawSource,
  });

  final String name;
  final Map<String, String> attributes;
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
  });
}

/// A node for which BusyMark has an explicit semantic interpretation.
class WritersideSemanticElementNode extends WritersideElementNode {
  const WritersideSemanticElementNode({
    required this.kind,
    required super.name,
    required super.attributes,
    required super.attributeSpans,
    required super.children,
    required super.span,
    required super.rawSource,
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
  }) {
    return WritersideSemanticElementNode(
      kind: kind,
      name: name,
      attributes: attributes ?? this.attributes,
      attributeSpans: attributeSpans,
      children: children ?? this.children,
      span: span,
      rawSource: rawSource,
    );
  }
}

/// A lossless node for schema-known elements without a special renderer, and
/// for extensions unknown to the selected schema version.
class WritersideGenericElementNode extends WritersideElementNode {
  const WritersideGenericElementNode({
    required this.schemaKnown,
    required super.name,
    required super.attributes,
    required super.attributeSpans,
    required super.children,
    required super.span,
    required super.rawSource,
  });

  @override
  final bool schemaKnown;

  @override
  WritersideSemanticKind? get semanticKind => null;

  @override
  WritersideGenericElementNode copyWith({
    Map<String, String>? attributes,
    List<WritersideDocumentNode>? children,
  }) {
    return WritersideGenericElementNode(
      schemaKnown: schemaKnown,
      name: name,
      attributes: attributes ?? this.attributes,
      attributeSpans: attributeSpans,
      children: children ?? this.children,
      span: span,
      rawSource: rawSource,
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
  });

  final BusyBlock block;

  @override
  String get plainText => block.plainText;

  WritersideMarkdownBlockNode copyWith({BusyBlock? block}) {
    return WritersideMarkdownBlockNode(
      block: block ?? this.block,
      span: span,
      rawSource: rawSource,
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
