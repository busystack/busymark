import 'package:flutter/foundation.dart';

enum MarkdownExportBlockKind {
  heading,
  paragraph,
  code,
  list,
  listItem,
  blockquote,
  thematicBreak,
  image,
  table,
  tableRow,
  tableCell,
  rawText,
  group,
}

enum MarkdownExportInlineKind {
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
}

@immutable
class MarkdownExportMetadata {
  const MarkdownExportMetadata({
    required this.title,
    this.author = '',
    this.description = '',
    this.language = 'en',
    this.keywords = const [],
  });

  final String title;
  final String author;
  final String description;
  final String language;
  final List<String> keywords;

  Map<String, Object> toJson() => {
    'title': title,
    'author': author,
    'description': description,
    'language': language,
    'keywords': keywords,
  };
}

@immutable
class MarkdownExportDocument {
  const MarkdownExportDocument({required this.metadata, required this.blocks});

  final MarkdownExportMetadata metadata;
  final List<MarkdownExportBlock> blocks;

  Iterable<String> get imageDestinations sync* {
    for (final block in blocks) {
      yield* block.imageDestinations;
    }
  }
}

@immutable
class MarkdownExportBlock {
  const MarkdownExportBlock({
    required this.kind,
    this.inlines = const [],
    this.children = const [],
    this.attributes = const {},
    this.text = '',
  });

  final MarkdownExportBlockKind kind;
  final List<MarkdownExportInline> inlines;
  final List<MarkdownExportBlock> children;
  final Map<String, Object> attributes;
  final String text;

  Iterable<String> get imageDestinations sync* {
    for (final inline in inlines) {
      yield* inline.imageDestinations;
    }
    for (final child in children) {
      yield* child.imageDestinations;
    }
  }
}

@immutable
class MarkdownExportInline {
  const MarkdownExportInline({
    required this.kind,
    this.text = '',
    this.destination,
    this.children = const [],
    this.attributes = const {},
  });

  final MarkdownExportInlineKind kind;
  final String text;
  final String? destination;
  final List<MarkdownExportInline> children;
  final Map<String, String> attributes;

  Iterable<String> get imageDestinations sync* {
    if (kind == MarkdownExportInlineKind.image &&
        destination != null &&
        destination!.trim().isNotEmpty) {
      yield destination!;
    }
    for (final child in children) {
      yield* child.imageDestinations;
    }
  }
}
