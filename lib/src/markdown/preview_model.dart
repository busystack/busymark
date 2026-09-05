import '../core/source_span.dart';
import '../core/uri_utils.dart';
import '../visualization/visualization_models.dart';
import 'busymark_document.dart';
import 'document_outline.dart';
import 'markdown_model.dart';
import 'math_syntax.dart';
import '../writerside/writerside_document_parser.dart';
import '../writerside/writerside_document_renderer.dart';
import '../writerside/writerside_schema.dart';

enum PreviewBlockKind {
  heading,
  paragraph,
  math,
  code,
  list,
  quote,
  thematicBreak,
  image,
  video,
  table,
  container,
  raw,
  link,
  admonition,
  tabs,
  procedure,
  definitionList,
  definition,
  unknown,
}

class PreviewBlock {
  const PreviewBlock({
    required this.kind,
    required this.text,
    this.level,
    this.language,
    this.visualization,
    this.inlines = const [],
    this.children = const [],
    this.attributes = const {},
    this.sourceStartLine,
    this.sourceEndLine,
    this.sourceStartOffset,
    this.sourceEndOffset,
  });

  final PreviewBlockKind kind;
  final String text;
  final int? level;
  final String? language;
  final VisualizationDescriptor? visualization;
  final List<PreviewInline> inlines;
  final List<PreviewBlock> children;
  final Map<String, String> attributes;
  final int? sourceStartLine;
  final int? sourceEndLine;
  final int? sourceStartOffset;
  final int? sourceEndOffset;
}

enum PreviewInlineKind {
  text,
  strong,
  emphasis,
  underline,
  strikethrough,
  code,
  link,
  image,
  math,
}

class PreviewInline {
  const PreviewInline({
    required this.kind,
    required this.text,
    this.destination,
    this.children = const [],
    this.attributes = const {},
  });

  final PreviewInlineKind kind;
  final String text;
  final String? destination;
  final List<PreviewInline> children;
  final Map<String, String> attributes;
}

class PreviewDocument {
  const PreviewDocument({
    required this.title,
    required this.modeLabel,
    required this.compatibility,
    required this.blocks,
  });

  final String title;
  final String modeLabel;
  final String compatibility;
  final List<PreviewBlock> blocks;
}

extension PreviewDocumentOutline on PreviewDocument {
  List<DocumentOutlineHeading> get outline {
    final headings = <DocumentOutlineHeading>[];

    void collect(List<PreviewBlock> blocks) {
      for (final block in blocks) {
        if (block.kind == PreviewBlockKind.heading) {
          final level = block.level;
          final id = block.attributes['id'];
          final sourceStartLine = block.sourceStartLine;
          final sourceStartOffset = block.sourceStartOffset;
          if (level != null &&
              id != null &&
              id.isNotEmpty &&
              sourceStartLine != null &&
              sourceStartOffset != null) {
            headings.add(
              DocumentOutlineHeading(
                level: level,
                text: block.text,
                id: id,
                sourceStartLine: sourceStartLine,
                sourceStartOffset: sourceStartOffset,
                editorBlockId: block.attributes['editorBlockId'],
              ),
            );
          }
        }
        collect(block.children);
      }
    }

    collect(blocks);
    return List.unmodifiable(headings);
  }
}

class MarkdownPreviewBuilder {
  const MarkdownPreviewBuilder();

  PreviewDocument build(ParsedMarkdownDocument document) {
    if (document.mode == MarkdownMode.writersideMarkdown) {
      final semantic = const WritersideDocumentParser().parseMarkdown(
        filePath: document.filePath,
        source: document.source,
        markdown: document.busyDocument,
      );
      final rendered = const WritersideDocumentRenderer().toBusyDocument(
        semantic,
        title: document.title,
      );
      return const BusyMarkPreviewBuilder().build(rendered);
    }
    return PreviewDocument(
      title: document.title ?? '',
      modeLabel: '',
      compatibility: '',
      blocks: const BusyMarkPreviewBuilder().buildBlocks(document.busyDocument),
    );
  }
}

class BusyMarkPreviewBuilder {
  const BusyMarkPreviewBuilder();

  PreviewDocument build(BusyDocument document) {
    return PreviewDocument(
      title: document.title ?? '',
      modeLabel: '',
      compatibility: '',
      blocks: buildBlocks(document),
    );
  }

  List<PreviewBlock> buildBlocks(BusyDocument document) {
    final blocks = [
      for (final (index, block) in document.blocks.indexed)
        if (block.kind != BusyBlockKind.frontMatter && !block.isSourceOnly)
          _block(block, 'b$index'),
    ];
    return document.mode == MarkdownMode.writersideMarkdown
        ? _groupWritersideCollapsibleChapters(blocks)
        : blocks;
  }

  PreviewBlock _block(BusyBlock block, String path) {
    final preview = switch (block.kind) {
      BusyBlockKind.heading => PreviewBlock(
        kind: PreviewBlockKind.heading,
        text: _plainText(block.inlines),
        level: int.tryParse(block.attributes['level'] ?? ''),
        inlines: _inlines(block.inlines, 'block-${block.id}.i'),
        children: [
          for (final (index, child) in block.children.indexed)
            _block(child, '$path.b$index'),
        ],
        attributes: {
          ...block.attributes,
          if (block.attributes['id'] case final id?) 'id': id,
          'editorBlockId': block.id,
        },
      ),
      BusyBlockKind.paragraph => PreviewBlock(
        kind: PreviewBlockKind.paragraph,
        text: _plainText(block.inlines),
        inlines: _inlines(block.inlines, 'block-${block.id}.i'),
        children: [
          for (final (index, child) in block.children.indexed)
            _block(child, '$path.b$index'),
        ],
        attributes: block.attributes,
      ),
      BusyBlockKind.math => PreviewBlock(
        kind: PreviewBlockKind.math,
        text:
            block.attributes[busyMarkMathExpressionAttribute] ??
            block.plainText,
        inlines: _inlines(block.inlines, 'block-${block.id}.i'),
        attributes: {
          ...block.attributes,
          'expressionId': 'block-${block.id}',
          'editorBlockId': block.id,
        },
      ),
      BusyBlockKind.codeBlock => PreviewBlock(
        kind: PreviewBlockKind.code,
        text: block.plainText,
        language: block.attributes['language'],
        visualization: VisualizationDescriptor.maybeForFenceLanguage(
          block.attributes['language'],
        ),
        attributes: {...block.attributes, 'editorBlockId': block.id},
      ),
      BusyBlockKind.unorderedListItem ||
      BusyBlockKind.orderedListItem ||
      BusyBlockKind.taskListItem => PreviewBlock(
        kind: PreviewBlockKind.list,
        text: _plainText(block.inlines),
        inlines: _inlines(block.inlines, 'block-${block.id}.i'),
        children: [
          for (final (index, child) in block.children.indexed)
            _block(child, '$path.b$index'),
        ],
        attributes: block.attributes,
      ),
      BusyBlockKind.blockquote => _blockquote(block, path),
      BusyBlockKind.thematicBreak => const PreviewBlock(
        kind: PreviewBlockKind.thematicBreak,
        text: '---',
      ),
      BusyBlockKind.image => PreviewBlock(
        kind: PreviewBlockKind.image,
        text: block.inlines.isEmpty
            ? block.plainText
            : block.inlines.first.text,
        inlines: _inlines(block.inlines, 'block-${block.id}.i'),
        attributes: block.attributes,
      ),
      BusyBlockKind.video => PreviewBlock(
        kind: PreviewBlockKind.video,
        text: block.attributes['src'] ?? block.plainText,
        attributes: {...block.attributes, 'editorBlockId': block.id},
      ),
      BusyBlockKind.table => PreviewBlock(
        kind: PreviewBlockKind.table,
        text: '',
        children: [
          for (final (index, child) in block.children.indexed)
            _block(child, '$path.b$index'),
        ],
        attributes: block.attributes,
      ),
      BusyBlockKind.writersideAdmonition => _writersideAdmonition(block, path),
      BusyBlockKind.writersideTabs => PreviewBlock(
        kind: PreviewBlockKind.tabs,
        text: _plainText(block.inlines),
        children: [
          for (final (index, child) in block.children.indexed)
            _block(child, '$path.b$index'),
        ],
        attributes: block.attributes,
      ),
      BusyBlockKind.writersideProcedure =>
        _writersideSemanticBlock(block, path) ??
            PreviewBlock(
              kind: PreviewBlockKind.procedure,
              text: _plainText(block.inlines).isEmpty
                  ? block.attributes['title'] ?? ''
                  : _plainText(block.inlines),
              children: [
                for (final (index, child) in block.children.indexed)
                  _block(child, '$path.b$index'),
              ],
              attributes: block.attributes,
            ),
      BusyBlockKind.htmlBlock when block.children.isNotEmpty => PreviewBlock(
        kind: PreviewBlockKind.container,
        text: block.children.map((child) => child.plainText).join('\n'),
        children: [
          for (final (index, child) in block.children.indexed)
            _block(child, '$path.b$index'),
        ],
        attributes: block.attributes,
      ),
      BusyBlockKind.writersideRawXml =>
        _writersideSemanticBlock(block, path) ??
            PreviewBlock(
              kind: PreviewBlockKind.raw,
              text: block.rawSource ?? block.plainText,
              attributes: block.attributes,
            ),
      BusyBlockKind.htmlBlock || BusyBlockKind.unknown => PreviewBlock(
        kind: PreviewBlockKind.raw,
        text: block.rawSource ?? block.plainText,
        attributes: block.attributes,
      ),
      BusyBlockKind.frontMatter => const PreviewBlock(
        kind: PreviewBlockKind.raw,
        text: '',
      ),
    };
    return _withSourceSpan(preview, block.sourceSpan);
  }

  List<PreviewBlock> _groupWritersideCollapsibleChapters(
    List<PreviewBlock> blocks,
  ) {
    final result = <PreviewBlock>[];
    var index = 0;
    while (index < blocks.length) {
      final block = blocks[index];
      final level = block.level;
      final markdownChapter =
          block.kind == PreviewBlockKind.heading &&
          block.attributes['element'] != 'chapter' &&
          level != null &&
          busyMarkWritersideIsCollapsible(block.attributes);
      if (!markdownChapter) {
        result.add(block);
        index += 1;
        continue;
      }
      var end = index + 1;
      while (end < blocks.length) {
        final candidate = blocks[end];
        if (candidate.kind == PreviewBlockKind.heading &&
            candidate.level != null &&
            candidate.level! <= level) {
          break;
        }
        end += 1;
      }
      final children = blocks.sublist(index + 1, end);
      result.add(
        PreviewBlock(
          kind: block.kind,
          text: block.text,
          level: block.level,
          language: block.language,
          visualization: block.visualization,
          inlines: block.inlines,
          children: children,
          attributes: block.attributes,
          sourceStartLine: block.sourceStartLine,
          sourceEndLine: children.isEmpty
              ? block.sourceEndLine
              : children.last.sourceEndLine,
          sourceStartOffset: block.sourceStartOffset,
          sourceEndOffset: children.isEmpty
              ? block.sourceEndOffset
              : children.last.sourceEndOffset,
        ),
      );
      index = end;
    }
    return result;
  }

  PreviewBlock? _writersideSemanticBlock(BusyBlock block, String path) {
    final source = block.rawSource;
    if (source == null || source.trim().isEmpty) {
      return _writersideRenderedSemanticBlock(block, path);
    }
    try {
      final semantic = const WritersideDocumentParser().parseXml(
        filePath: block.sourceSpan?.filePath ?? '',
        source: source,
      );
      if (!semantic.isWellFormed) {
        return null;
      }
      final rendered = const WritersideDocumentRenderer().toBusyDocument(
        semantic,
      );
      final children = [
        for (final (index, child) in rendered.blocks.indexed)
          _block(child, '$path.semantic$index'),
      ];
      if (children.length == 1) {
        return _withPreviewAttributes(children.single, {
          ...children.single.attributes,
          'editorBlockId': block.id,
        });
      }
      if (children.isNotEmpty) {
        return PreviewBlock(
          kind: PreviewBlockKind.container,
          text: children.map((child) => child.text).join('\n'),
          children: children,
          attributes: {...block.attributes, 'editorBlockId': block.id},
        );
      }
      return null;
    } on Object {
      return null;
    }
  }

  PreviewBlock? _writersideRenderedSemanticBlock(BusyBlock block, String path) {
    final semanticKind = WritersideSchema.capabilityFor(
      block.attributes['element'] ?? '',
    )?.kind;
    final children = [
      for (final (index, child) in block.children.indexed)
        _block(child, '$path.b$index'),
    ];
    return switch (semanticKind) {
      WritersideSemanticKind.definitionList => PreviewBlock(
        kind: PreviewBlockKind.definitionList,
        text: '',
        children: children,
        attributes: block.attributes,
      ),
      WritersideSemanticKind.definition => PreviewBlock(
        kind: PreviewBlockKind.definition,
        text: _plainText(block.inlines),
        inlines: _inlines(block.inlines, 'block-${block.id}.i'),
        children: children,
        attributes: block.attributes,
      ),
      _
          when block.kind == BusyBlockKind.writersideRawXml &&
              children.isNotEmpty =>
        PreviewBlock(
          kind: PreviewBlockKind.container,
          text: children.map((child) => child.text).join('\n'),
          children: children,
          attributes: block.attributes,
        ),
      _ => null,
    };
  }

  PreviewBlock _withPreviewAttributes(
    PreviewBlock block,
    Map<String, String> attributes,
  ) => PreviewBlock(
    kind: block.kind,
    text: block.text,
    level: block.level,
    language: block.language,
    visualization: block.visualization,
    inlines: block.inlines,
    children: block.children,
    attributes: attributes,
    sourceStartLine: block.sourceStartLine,
    sourceEndLine: block.sourceEndLine,
    sourceStartOffset: block.sourceStartOffset,
    sourceEndOffset: block.sourceEndOffset,
  );

  PreviewBlock _blockquote(BusyBlock block, String path) {
    final style = busyAdmonitionStyleFromName(block.attributes['style']);
    final writersideAdmonition =
        block.attributes[busyMarkWritersideAdmonitionAttribute] == 'true';
    return PreviewBlock(
      kind: writersideAdmonition && style != BusyAdmonitionStyle.quote
          ? PreviewBlockKind.admonition
          : PreviewBlockKind.quote,
      text: block.children.isEmpty
          ? _plainText(block.inlines)
          : block.children.map((child) => child.plainText).join('\n'),
      inlines:
          block.children.length == 1 &&
              block.children.single.kind == BusyBlockKind.paragraph
          ? _inlines(
              block.children.single.inlines,
              'block-${block.children.single.id}.i',
            )
          : block.children.isEmpty
          ? _inlines(block.inlines, 'block-${block.id}.i')
          : const [],
      children: [
        for (final (index, child) in block.children.indexed)
          _block(child, '$path.b$index'),
      ],
      attributes: block.attributes,
    );
  }

  PreviewBlock _writersideAdmonition(BusyBlock block, String path) {
    final style =
        busyAdmonitionStyleFromName(
          block.attributes['style'] ?? block.attributes['element'],
        ) ??
        BusyAdmonitionStyle.note;
    return PreviewBlock(
      kind: style == BusyAdmonitionStyle.quote
          ? PreviewBlockKind.quote
          : PreviewBlockKind.admonition,
      text: block.children.isEmpty
          ? _plainText(block.inlines)
          : block.children.map((child) => child.plainText).join('\n'),
      inlines: _inlines(block.inlines, 'block-${block.id}.i'),
      children: [
        for (final (index, child) in block.children.indexed)
          _block(child, '$path.b$index'),
      ],
      attributes: {...block.attributes, 'style': style.name},
    );
  }

  PreviewBlock _withSourceSpan(PreviewBlock block, SourceSpan? span) {
    if (span == null) {
      return block;
    }
    return PreviewBlock(
      kind: block.kind,
      text: block.text,
      level: block.level,
      language: block.language,
      visualization: block.visualization,
      inlines: block.inlines,
      children: block.children,
      attributes: block.attributes,
      sourceStartLine: span.startLine,
      sourceEndLine: span.endLine,
      sourceStartOffset: span.startOffset,
      sourceEndOffset: span.endOffset,
    );
  }

  List<PreviewInline> _inlines(List<BusyInline> inlines, String path) {
    return [
      for (final (index, inline) in inlines.indexed)
        _inline(inline, '$path$index'),
    ];
  }

  PreviewInline _inline(BusyInline inline, String path) {
    return PreviewInline(
      kind: switch (inline.kind) {
        BusyInlineKind.text ||
        BusyInlineKind.softBreak ||
        BusyInlineKind.hardBreak ||
        BusyInlineKind.writersideVariable ||
        BusyInlineKind.html ||
        BusyInlineKind.unknown => PreviewInlineKind.text,
        BusyInlineKind.math => PreviewInlineKind.math,
        BusyInlineKind.strong => PreviewInlineKind.strong,
        BusyInlineKind.emphasis => PreviewInlineKind.emphasis,
        BusyInlineKind.underline => PreviewInlineKind.underline,
        BusyInlineKind.strikethrough => PreviewInlineKind.strikethrough,
        BusyInlineKind.code => PreviewInlineKind.code,
        BusyInlineKind.link => PreviewInlineKind.link,
        BusyInlineKind.image => PreviewInlineKind.image,
      },
      text: inline.kind == BusyInlineKind.softBreak ? ' ' : inline.text,
      destination: inline.destination,
      children: _inlines(inline.children, '$path.i'),
      attributes: {
        ...inline.attributes,
        if (inline.kind == BusyInlineKind.math) 'expressionId': 'inline-$path',
      },
    );
  }

  String _plainText(List<BusyInline> inlines) {
    return inlines
        .map((inline) {
          if (inline.kind == BusyInlineKind.softBreak) {
            return ' ';
          }
          return inline.plainText;
        })
        .join()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

List<PreviewInline> parseInlineMarkdown(String source) {
  final result = <PreviewInline>[];
  final buffer = StringBuffer();
  var index = 0;

  void flushText() {
    if (buffer.isEmpty) {
      return;
    }
    result.add(
      PreviewInline(kind: PreviewInlineKind.text, text: buffer.toString()),
    );
    buffer.clear();
  }

  while (index < source.length) {
    if (source.startsWith('\\', index) && index + 1 < source.length) {
      buffer.write(source[index + 1]);
      index += 2;
      continue;
    }
    if (source.startsWith('`', index)) {
      final end = source.indexOf('`', index + 1);
      if (end > index + 1) {
        flushText();
        result.add(
          PreviewInline(
            kind: PreviewInlineKind.code,
            text: source.substring(index + 1, end),
          ),
        );
        index = end + 1;
        continue;
      }
    }
    if (source.startsWith('![', index)) {
      final parsed = _parseInlineLink(source, index, image: true);
      if (parsed != null) {
        flushText();
        result.add(parsed.inline);
        index = parsed.end;
        continue;
      }
    }
    if (source.startsWith('[', index)) {
      final parsed = _parseInlineLink(source, index, image: false);
      if (parsed != null) {
        flushText();
        result.add(parsed.inline);
        index = parsed.end;
        continue;
      }
    }
    if (source.startsWith('<', index)) {
      final end = source.indexOf('>', index + 1);
      if (end > index + 1) {
        final destination = source.substring(index + 1, end);
        final uri = parseSchemedUri(destination);
        if (uri != null && isLaunchableExternalUri(uri)) {
          flushText();
          result.add(
            PreviewInline(
              kind: PreviewInlineKind.link,
              text: destination,
              destination: destination,
              children: [
                PreviewInline(kind: PreviewInlineKind.text, text: destination),
              ],
            ),
          );
          index = end + 1;
          continue;
        }
      }
    }
    final marker = _inlineMarkerAt(source, index);
    if (marker != null) {
      final end = source.indexOf(marker.marker, index + marker.marker.length);
      if (end > index + marker.marker.length) {
        final inner = source.substring(index + marker.marker.length, end);
        flushText();
        result.add(
          PreviewInline(
            kind: marker.kind,
            text: parseInlineMarkdownPlainText(inner),
            children: parseInlineMarkdown(inner),
          ),
        );
        index = end + marker.marker.length;
        continue;
      }
    }
    buffer.write(source[index]);
    index++;
  }
  flushText();
  return result;
}

String parseInlineMarkdownPlainText(String source) {
  return parseInlineMarkdown(source).map(_inlinePlainText).join().trim();
}

String _inlinePlainText(PreviewInline inline) {
  if (inline.children.isNotEmpty) {
    return inline.children.map(_inlinePlainText).join();
  }
  return inline.text;
}

_InlineMarker? _inlineMarkerAt(String source, int index) {
  for (final marker in const [
    _InlineMarker('**', PreviewInlineKind.strong),
    _InlineMarker('__', PreviewInlineKind.strong),
    _InlineMarker('~~', PreviewInlineKind.strikethrough),
    _InlineMarker('*', PreviewInlineKind.emphasis),
    _InlineMarker('_', PreviewInlineKind.emphasis),
  ]) {
    if (source.startsWith(marker.marker, index)) {
      return marker;
    }
  }
  return null;
}

class _InlineMarker {
  const _InlineMarker(this.marker, this.kind);

  final String marker;
  final PreviewInlineKind kind;
}

_ParsedInline? _parseInlineLink(
  String source,
  int start, {
  required bool image,
}) {
  final labelStart = start + (image ? 2 : 1);
  final labelEnd = source.indexOf(']', labelStart);
  if (labelEnd < 0 ||
      labelEnd + 1 >= source.length ||
      source[labelEnd + 1] != '(') {
    return null;
  }
  final destinationEnd = source.indexOf(')', labelEnd + 2);
  if (destinationEnd < 0) {
    return null;
  }
  final label = source.substring(labelStart, labelEnd);
  final destination = source.substring(labelEnd + 2, destinationEnd);
  return _ParsedInline(
    end: destinationEnd + 1,
    inline: PreviewInline(
      kind: image ? PreviewInlineKind.image : PreviewInlineKind.link,
      text: label.isEmpty ? destination : parseInlineMarkdownPlainText(label),
      destination: destination,
      children: image ? const [] : parseInlineMarkdown(label),
    ),
  );
}

class _ParsedInline {
  const _ParsedInline({required this.inline, required this.end});

  final PreviewInline inline;
  final int end;
}
