import '../core/diagnostic.dart';
import '../core/source_span.dart';
import 'busymark_document.dart';

enum MarkdownMode { commonMark, writersideMarkdown, gfm }

class MarkdownHeading {
  const MarkdownHeading({
    required this.level,
    required this.text,
    required this.id,
    required this.generatedId,
    required this.span,
  });

  final int level;
  final String text;
  final String id;
  final bool generatedId;
  final SourceSpan span;
}

class MarkdownLink {
  const MarkdownLink({
    required this.text,
    required this.destination,
    required this.span,
  });

  final String text;
  final String destination;
  final SourceSpan span;
}

class MarkdownImage {
  const MarkdownImage({
    required this.alt,
    required this.destination,
    required this.span,
  });

  final String alt;
  final String destination;
  final SourceSpan span;
}

class MarkdownCodeBlock {
  const MarkdownCodeBlock({
    required this.language,
    required this.content,
    required this.span,
  });

  final String? language;
  final String content;
  final SourceSpan span;
}

class MarkdownXmlBlock {
  const MarkdownXmlBlock({
    required this.rawXml,
    required this.elementName,
    required this.span,
  });

  final String rawXml;
  final String elementName;
  final SourceSpan span;
}

class MarkdownVariableToken {
  const MarkdownVariableToken({
    required this.name,
    required this.escaped,
    required this.span,
  });

  final String name;
  final bool escaped;
  final SourceSpan span;
}

class ParsedMarkdownDocument {
  const ParsedMarkdownDocument({
    required this.filePath,
    required this.source,
    required this.mode,
    required this.title,
    required this.headings,
    required this.links,
    required this.images,
    required this.codeBlocks,
    required this.xmlBlocks,
    required this.variables,
    required this.diagnostics,
    required this.busyDocument,
  });

  final String filePath;
  final String source;
  final MarkdownMode mode;
  final String? title;
  final List<MarkdownHeading> headings;
  final List<MarkdownLink> links;
  final List<MarkdownImage> images;
  final List<MarkdownCodeBlock> codeBlocks;
  final List<MarkdownXmlBlock> xmlBlocks;
  final List<MarkdownVariableToken> variables;
  final List<Diagnostic> diagnostics;
  final BusyDocument busyDocument;

  Set<String> get anchors => headings.map((heading) => heading.id).toSet();
}
