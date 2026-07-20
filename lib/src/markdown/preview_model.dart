import '../core/source_span.dart';
import '../core/uri_utils.dart';
import 'busymark_document.dart';
import 'markdown_model.dart';

enum PreviewBlockKind {
  heading,
  paragraph,
  code,
  list,
  quote,
  thematicBreak,
  image,
  table,
  container,
  raw,
  link,
  admonition,
  tabs,
  procedure,
  unknown,
}

class PreviewBlock {
  const PreviewBlock({
    required this.kind,
    required this.text,
    this.level,
    this.language,
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
}

class PreviewInline {
  const PreviewInline({
    required this.kind,
    required this.text,
    this.destination,
    this.children = const [],
  });

  final PreviewInlineKind kind;
  final String text;
  final String? destination;
  final List<PreviewInline> children;
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

class MarkdownPreviewBuilder {
  const MarkdownPreviewBuilder();

  PreviewDocument build(ParsedMarkdownDocument document) {
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
    return [
      for (final block in document.blocks)
        if (block.kind != BusyBlockKind.frontMatter && !block.isSourceOnly)
          _block(block),
    ];
  }

  PreviewBlock _block(BusyBlock block) {
    final preview = switch (block.kind) {
      BusyBlockKind.heading => PreviewBlock(
        kind: PreviewBlockKind.heading,
        text: _plainText(block.inlines),
        level: int.tryParse(block.attributes['level'] ?? ''),
        inlines: _inlines(block.inlines),
        attributes: {
          ...block.attributes,
          if (block.attributes['id'] case final id?) 'id': id,
        },
      ),
      BusyBlockKind.paragraph => PreviewBlock(
        kind: PreviewBlockKind.paragraph,
        text: _plainText(block.inlines),
        inlines: _inlines(block.inlines),
        attributes: block.attributes,
      ),
      BusyBlockKind.codeBlock => PreviewBlock(
        kind: PreviewBlockKind.code,
        text: block.plainText,
        language: block.attributes['language'],
      ),
      BusyBlockKind.unorderedListItem ||
      BusyBlockKind.orderedListItem ||
      BusyBlockKind.taskListItem => PreviewBlock(
        kind: PreviewBlockKind.list,
        text: _plainText(block.inlines),
        inlines: _inlines(block.inlines),
        children: block.children.map(_block).toList(),
        attributes: block.attributes,
      ),
      BusyBlockKind.blockquote => PreviewBlock(
        kind: PreviewBlockKind.quote,
        text: block.children.isEmpty
            ? _plainText(block.inlines)
            : block.children.map((child) => child.plainText).join('\n'),
        inlines:
            block.children.length == 1 &&
                block.children.single.kind == BusyBlockKind.paragraph
            ? _inlines(block.children.single.inlines)
            : block.children.isEmpty
            ? _inlines(block.inlines)
            : const [],
        children: block.children.map(_block).toList(),
      ),
      BusyBlockKind.thematicBreak => const PreviewBlock(
        kind: PreviewBlockKind.thematicBreak,
        text: '---',
      ),
      BusyBlockKind.image => PreviewBlock(
        kind: PreviewBlockKind.image,
        text: block.inlines.isEmpty
            ? block.plainText
            : block.inlines.first.text,
        inlines: _inlines(block.inlines),
        attributes: block.attributes,
      ),
      BusyBlockKind.table => PreviewBlock(
        kind: PreviewBlockKind.table,
        text: '',
        children: block.children.map(_block).toList(),
        attributes: block.attributes,
      ),
      BusyBlockKind.writersideAdmonition => PreviewBlock(
        kind: PreviewBlockKind.admonition,
        text: _plainText(block.inlines),
        inlines: _inlines(block.inlines),
        attributes: {
          ...block.attributes,
          'style': block.attributes['element'] ?? 'note',
        },
      ),
      BusyBlockKind.writersideTabs => PreviewBlock(
        kind: PreviewBlockKind.tabs,
        text: _plainText(block.inlines),
        attributes: block.attributes,
      ),
      BusyBlockKind.writersideProcedure => PreviewBlock(
        kind: PreviewBlockKind.procedure,
        text: _plainText(block.inlines).isEmpty
            ? block.attributes['title'] ?? ''
            : _plainText(block.inlines),
        attributes: block.attributes,
      ),
      BusyBlockKind.htmlBlock when block.children.isNotEmpty => PreviewBlock(
        kind: PreviewBlockKind.container,
        text: block.children.map((child) => child.plainText).join('\n'),
        children: block.children.map(_block).toList(),
        attributes: block.attributes,
      ),
      BusyBlockKind.htmlBlock ||
      BusyBlockKind.writersideRawXml ||
      BusyBlockKind.unknown => PreviewBlock(
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

  PreviewBlock _withSourceSpan(PreviewBlock block, SourceSpan? span) {
    if (span == null) {
      return block;
    }
    return PreviewBlock(
      kind: block.kind,
      text: block.text,
      level: block.level,
      language: block.language,
      inlines: block.inlines,
      children: block.children,
      attributes: block.attributes,
      sourceStartLine: span.startLine,
      sourceEndLine: span.endLine,
      sourceStartOffset: span.startOffset,
      sourceEndOffset: span.endOffset,
    );
  }

  List<PreviewInline> _inlines(List<BusyInline> inlines) {
    return [for (final inline in inlines) _inline(inline)];
  }

  PreviewInline _inline(BusyInline inline) {
    return PreviewInline(
      kind: switch (inline.kind) {
        BusyInlineKind.text ||
        BusyInlineKind.softBreak ||
        BusyInlineKind.hardBreak ||
        BusyInlineKind.writersideVariable ||
        BusyInlineKind.html ||
        BusyInlineKind.unknown => PreviewInlineKind.text,
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
      children: _inlines(inline.children),
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
