import '../core/diagnostic.dart';
import '../core/source_span.dart';
import 'markdown_model.dart';

/// Marks an empty WYSIWYG paragraph that must remain a source blank line.
const busyMarkPreserveEmptyParagraphAttribute = 'preserveEmptyParagraph';

enum BusyTableAlignment { unspecified, left, center, right }

BusyTableAlignment busyTableAlignmentFromAttribute(String? value) {
  return switch (value?.toLowerCase()) {
    'left' => BusyTableAlignment.left,
    'center' => BusyTableAlignment.center,
    'right' => BusyTableAlignment.right,
    _ => BusyTableAlignment.unspecified,
  };
}

String? busyTableAlignmentAttribute(BusyTableAlignment alignment) {
  return switch (alignment) {
    BusyTableAlignment.unspecified => null,
    BusyTableAlignment.left => 'left',
    BusyTableAlignment.center => 'center',
    BusyTableAlignment.right => 'right',
  };
}

class BusyDocument {
  const BusyDocument({
    required this.filePath,
    required this.mode,
    required this.blocks,
    this.title,
    this.diagnostics = const [],
    this.frontMatter = const {},
    this.rawFrontMatter,
    this.source,
  });

  final String filePath;
  final MarkdownMode mode;
  final String? title;
  final List<BusyBlock> blocks;
  final List<Diagnostic> diagnostics;
  final Map<String, String> frontMatter;
  final String? rawFrontMatter;
  final String? source;

  BusyDocument copyWith({
    String? title,
    List<BusyBlock>? blocks,
    List<Diagnostic>? diagnostics,
    Map<String, String>? frontMatter,
    String? rawFrontMatter,
    String? source,
  }) {
    return BusyDocument(
      filePath: filePath,
      mode: mode,
      title: title ?? this.title,
      blocks: blocks ?? this.blocks,
      diagnostics: diagnostics ?? this.diagnostics,
      frontMatter: frontMatter ?? this.frontMatter,
      rawFrontMatter: rawFrontMatter ?? this.rawFrontMatter,
      source: source ?? this.source,
    );
  }
}

enum BusyBlockKind {
  heading,
  paragraph,
  codeBlock,
  unorderedListItem,
  orderedListItem,
  taskListItem,
  blockquote,
  thematicBreak,
  image,
  table,
  htmlBlock,
  writersideAdmonition,
  writersideTabs,
  writersideProcedure,
  writersideRawXml,
  frontMatter,
  unknown,
}

class BusyBlock {
  const BusyBlock({
    required this.id,
    required this.kind,
    this.inlines = const [],
    this.children = const [],
    this.attributes = const {},
    this.rawSource,
    this.sourceSpan,
    this.preserveRaw = false,
    this.isSourceOnly = false,
    this.isGenerated = false,
    this.isSourceProtected = false,
    this.dirty = false,
  });

  final String id;
  final BusyBlockKind kind;
  final List<BusyInline> inlines;
  final List<BusyBlock> children;
  final Map<String, String> attributes;
  final String? rawSource;
  final SourceSpan? sourceSpan;
  final bool preserveRaw;
  final bool isSourceOnly;
  final bool isGenerated;
  final bool isSourceProtected;
  final bool dirty;

  String get plainText => inlines.map((inline) => inline.plainText).join();

  BusyBlock copyWith({
    String? id,
    BusyBlockKind? kind,
    List<BusyInline>? inlines,
    List<BusyBlock>? children,
    Map<String, String>? attributes,
    String? rawSource,
    SourceSpan? sourceSpan,
    bool? preserveRaw,
    bool? isSourceOnly,
    bool? isGenerated,
    bool? isSourceProtected,
    bool? dirty,
  }) {
    return BusyBlock(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      inlines: inlines ?? this.inlines,
      children: children ?? this.children,
      attributes: attributes ?? this.attributes,
      rawSource: rawSource ?? this.rawSource,
      sourceSpan: sourceSpan ?? this.sourceSpan,
      preserveRaw: preserveRaw ?? this.preserveRaw,
      isSourceOnly: isSourceOnly ?? this.isSourceOnly,
      isGenerated: isGenerated ?? this.isGenerated,
      isSourceProtected: isSourceProtected ?? this.isSourceProtected,
      dirty: dirty ?? this.dirty,
    );
  }
}

enum BusyInlineKind {
  text,
  strong,
  emphasis,
  underline,
  strikethrough,
  code,
  link,
  image,
  softBreak,
  hardBreak,
  html,
  writersideVariable,
  unknown,
}

class BusyInline {
  const BusyInline({
    required this.kind,
    required this.text,
    this.destination,
    this.children = const [],
    this.attributes = const {},
  });

  final BusyInlineKind kind;
  final String text;
  final String? destination;
  final List<BusyInline> children;
  final Map<String, String> attributes;

  String get plainText {
    if (children.isNotEmpty) {
      return children.map((inline) => inline.plainText).join();
    }
    return text;
  }

  BusyInline copyWith({
    BusyInlineKind? kind,
    String? text,
    String? destination,
    List<BusyInline>? children,
    Map<String, String>? attributes,
  }) {
    return BusyInline(
      kind: kind ?? this.kind,
      text: text ?? this.text,
      destination: destination ?? this.destination,
      children: children ?? this.children,
      attributes: attributes ?? this.attributes,
    );
  }
}
