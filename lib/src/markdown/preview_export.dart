import 'dart:convert';

import 'markdown_model.dart';

enum PreviewBlockKind {
  heading,
  paragraph,
  code,
  list,
  quote,
  thematicBreak,
  image,
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
  });

  final PreviewBlockKind kind;
  final String text;
  final int? level;
  final String? language;
  final List<PreviewInline> inlines;
  final List<PreviewBlock> children;
  final Map<String, String> attributes;
}

enum PreviewInlineKind {
  text,
  strong,
  emphasis,
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
    final blocks = <PreviewBlock>[];
    var inCode = false;
    String? codeLanguage;
    final codeBuffer = StringBuffer();
    final paragraphLines = <String>[];
    var headingIndex = 0;
    final lines = document.source.split('\n');

    void flushParagraph() {
      if (paragraphLines.isEmpty) {
        return;
      }
      final paragraph = _softJoinParagraphLines(paragraphLines);
      paragraphLines.clear();
      if (paragraph.isEmpty) {
        return;
      }
      final stripped = _stripTags(paragraph);
      blocks.add(
        PreviewBlock(
          kind: PreviewBlockKind.paragraph,
          text: parseInlineMarkdownPlainText(stripped),
          inlines: parseInlineMarkdown(stripped),
        ),
      );
    }

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (i == 0 && line.trim() == '---') {
        flushParagraph();
        while (i + 1 < lines.length) {
          i++;
          if (lines[i].trim() == '---') {
            break;
          }
        }
        continue;
      }
      final fence = RegExp(
        r'^\s*(```|~~~)\s*([A-Za-z0-9_+\-#.]*)',
      ).firstMatch(line);
      if (fence != null) {
        flushParagraph();
        if (inCode) {
          blocks.add(
            PreviewBlock(
              kind: PreviewBlockKind.code,
              text: codeBuffer.toString().trimRight(),
              language: codeLanguage,
            ),
          );
          codeBuffer.clear();
          codeLanguage = null;
        } else {
          codeLanguage = fence.group(2)?.trim();
          if (codeLanguage != null && codeLanguage.isEmpty) {
            codeLanguage = null;
          }
        }
        inCode = !inCode;
        continue;
      }
      if (inCode) {
        codeBuffer.writeln(line);
        continue;
      }

      if (i + 1 < lines.length) {
        final setext = RegExp(r'^\s*(=+)\s*$').firstMatch(lines[i + 1]);
        if (line.trim().isNotEmpty && setext != null) {
          flushParagraph();
          blocks.add(
            PreviewBlock(
              kind: PreviewBlockKind.heading,
              text: parseInlineMarkdownPlainText(line.trim()),
              level: 1,
              inlines: parseInlineMarkdown(line.trim()),
            ),
          );
          i++;
          continue;
        }
      }

      final heading = RegExp(
        r'^(#{1,6})\s+(.+?)\s*(\{[^}]+\})?\s*$',
      ).firstMatch(line);
      if (heading != null) {
        flushParagraph();
        final parsedHeading = headingIndex < document.headings.length
            ? document.headings[headingIndex]
            : null;
        headingIndex++;
        final text = heading.group(2)!.trim();
        blocks.add(
          PreviewBlock(
            kind: PreviewBlockKind.heading,
            text: parseInlineMarkdownPlainText(text),
            level: heading.group(1)!.length,
            inlines: parseInlineMarkdown(text),
            attributes: {if (parsedHeading != null) 'id': parsedHeading.id},
          ),
        );
        continue;
      }
      if (line.trim().isEmpty) {
        flushParagraph();
        continue;
      }
      if (_isThematicBreak(line)) {
        flushParagraph();
        blocks.add(
          PreviewBlock(kind: PreviewBlockKind.thematicBreak, text: line.trim()),
        );
        continue;
      }
      final image = RegExp(r'!\[([^\]]*)\]\(([^)]+)\)').firstMatch(line);
      if (image != null && image.group(0) == line.trim()) {
        flushParagraph();
        final alt = image.group(1) ?? '';
        final destination = image.group(2) ?? '';
        blocks.add(
          PreviewBlock(
            kind: PreviewBlockKind.image,
            text: alt.isEmpty ? destination : alt,
            inlines: [
              PreviewInline(
                kind: PreviewInlineKind.image,
                text: alt.isEmpty ? destination : alt,
                destination: destination,
              ),
            ],
            attributes: {'src': destination},
          ),
        );
        continue;
      }
      if (line.trimLeft().startsWith('>')) {
        flushParagraph();
        final quoteLines = <String>[];
        var style = 'quote';
        for (; i < lines.length; i++) {
          final quote = RegExp(r'^\s*>\s?(.*)$').firstMatch(lines[i]);
          if (quote == null) {
            i--;
            break;
          }
          final text = quote.group(1) ?? '';
          final styleValue = _attributeValue(text, 'style');
          if (styleValue != null) {
            style = styleValue;
          } else {
            quoteLines.add(text);
          }
          if (i + 1 >= lines.length ||
              !lines[i + 1].trimLeft().startsWith('>')) {
            break;
          }
        }
        final text = quoteLines.join('\n').trim();
        blocks.add(
          PreviewBlock(
            kind: style == 'quote'
                ? PreviewBlockKind.quote
                : PreviewBlockKind.admonition,
            text: parseInlineMarkdownPlainText(text),
            inlines: parseInlineMarkdown(text),
            attributes: {'style': style},
          ),
        );
        continue;
      }
      final list = _listItem(line);
      if (list != null) {
        flushParagraph();
        blocks.add(
          PreviewBlock(
            kind: PreviewBlockKind.list,
            text: parseInlineMarkdownPlainText(list.text),
            inlines: parseInlineMarkdown(list.text),
            attributes: {
              'ordered': list.ordered.toString(),
              'marker': list.marker,
              if (list.task != null) 'task': list.task.toString(),
            },
          ),
        );
        continue;
      }
      if (line.contains('<tabs')) {
        flushParagraph();
        blocks.add(
          const PreviewBlock(kind: PreviewBlockKind.tabs, text: 'Tabs'),
        );
        continue;
      }
      if (line.contains('<procedure')) {
        flushParagraph();
        blocks.add(
          PreviewBlock(
            kind: PreviewBlockKind.procedure,
            text: _attributeValue(line, 'title') ?? 'Procedure',
          ),
        );
        continue;
      }
      if (line.contains('<note') ||
          line.contains('<tip') ||
          line.contains('<warning')) {
        flushParagraph();
        blocks.add(
          PreviewBlock(
            kind: PreviewBlockKind.admonition,
            text: parseInlineMarkdownPlainText(_stripTags(line)),
            inlines: parseInlineMarkdown(_stripTags(line)),
            attributes: {
              'style': line.contains('<warning')
                  ? 'warning'
                  : line.contains('<tip')
                  ? 'tip'
                  : 'note',
            },
          ),
        );
        continue;
      }
      paragraphLines.add(line.trim());
    }
    flushParagraph();
    if (inCode && codeBuffer.isNotEmpty) {
      blocks.add(
        PreviewBlock(
          kind: PreviewBlockKind.code,
          text: codeBuffer.toString().trimRight(),
          language: codeLanguage,
        ),
      );
    }
    return PreviewDocument(
      title: document.title ?? 'Untitled',
      modeLabel: 'Preview',
      compatibility: '',
      blocks: blocks,
    );
  }
}

class MarkdownHtmlExporter {
  const MarkdownHtmlExporter();

  String export(ParsedMarkdownDocument document) {
    final preview = const MarkdownPreviewBuilder().build(document);
    final buffer = StringBuffer()
      ..writeln('<!doctype html>')
      ..writeln('<html lang="en">')
      ..writeln('<head>')
      ..writeln('<meta charset="utf-8">')
      ..writeln('<title>${htmlEscape.convert(preview.title)}</title>')
      ..writeln(
        '<style>body{font-family:sans-serif;max-width:860px;margin:2rem auto;line-height:1.55}code,pre{font-family:monospace}.admonition{border-left:4px solid #4a86cf;padding:.5rem 1rem;background:#f4f7fb}</style>',
      )
      ..writeln('</head>')
      ..writeln('<body>');
    for (final block in preview.blocks) {
      _writeBlock(buffer, block);
    }
    buffer
      ..writeln('</body>')
      ..writeln('</html>');
    return buffer.toString();
  }

  void _writeBlock(StringBuffer buffer, PreviewBlock block) {
    final text = _inlineHtml(block);
    switch (block.kind) {
      case PreviewBlockKind.heading:
        final level = block.level?.clamp(1, 6) ?? 2;
        buffer.writeln('<h$level>$text</h$level>');
      case PreviewBlockKind.code:
        buffer.writeln(
          '<pre><code>${htmlEscape.convert(block.text)}</code></pre>',
        );
      case PreviewBlockKind.thematicBreak:
        buffer.writeln('<hr>');
      case PreviewBlockKind.image:
        final src = htmlEscape.convert(block.attributes['src'] ?? '');
        buffer.writeln(
          '<figure><img src="$src" alt="${htmlEscape.convert(block.text)}"><figcaption>${htmlEscape.convert(block.text)}</figcaption></figure>',
        );
      case PreviewBlockKind.admonition:
        buffer.writeln('<aside class="admonition">$text</aside>');
      case PreviewBlockKind.list:
        final tag = block.attributes['ordered'] == 'true' ? 'ol' : 'ul';
        final task = block.attributes['task'];
        final checkbox = task == null
            ? ''
            : '<input type="checkbox" disabled${task == 'true' ? ' checked' : ''}> ';
        buffer.writeln('<$tag><li>$checkbox$text</li></$tag>');
      case PreviewBlockKind.tabs:
        buffer.writeln('<section><strong>Tabs</strong><p>$text</p></section>');
      case PreviewBlockKind.procedure:
        buffer.writeln('<section><h2>$text</h2></section>');
      case PreviewBlockKind.unknown:
        buffer.writeln('<p><em>$text</em></p>');
      case PreviewBlockKind.paragraph:
      case PreviewBlockKind.quote:
      case PreviewBlockKind.link:
        buffer.writeln('<p>$text</p>');
    }
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
    if (source.startsWith('<http://', index) ||
        source.startsWith('<https://', index) ||
        source.startsWith('<mailto:', index)) {
      final end = source.indexOf('>', index + 1);
      if (end > index + 1) {
        final destination = source.substring(index + 1, end);
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

String _softJoinParagraphLines(List<String> lines) {
  final buffer = StringBuffer();
  for (final rawLine in lines) {
    final line = rawLine.trim();
    if (line.isEmpty) {
      continue;
    }
    if (buffer.isNotEmpty) {
      buffer.write(' ');
    }
    buffer.write(line);
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _inlinePlainText(PreviewInline inline) {
  if (inline.children.isNotEmpty) {
    return inline.children.map(_inlinePlainText).join();
  }
  return inline.text;
}

String _stripTags(String value) {
  return value.replaceAll(RegExp('<[^>]+>'), '').trim();
}

bool _isThematicBreak(String line) {
  return RegExp(r'^\s{0,3}(?:\*\s*){3,}$').hasMatch(line) ||
      RegExp(r'^\s{0,3}(?:-\s*){3,}$').hasMatch(line) ||
      RegExp(r'^\s{0,3}(?:_\s*){3,}$').hasMatch(line);
}

_ListItem? _listItem(String line) {
  final match = RegExp(
    r'^\s{0,8}((?:[-*+])|(?:\d+[.)]))\s+(\[[ xX]\]\s+)?(.+)$',
  ).firstMatch(line);
  if (match == null) {
    return null;
  }
  final marker = match.group(1)!;
  final taskMarker = match.group(2);
  return _ListItem(
    ordered: RegExp(r'^\d').hasMatch(marker),
    marker: marker,
    task: taskMarker?.toLowerCase().contains('x'),
    text: match.group(3)!.trim(),
  );
}

class _ListItem {
  const _ListItem({
    required this.ordered,
    required this.marker,
    required this.task,
    required this.text,
  });

  final bool ordered;
  final String marker;
  final bool? task;
  final String text;
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

String _inlineHtml(PreviewBlock block) {
  final inlines = block.inlines.isEmpty
      ? [PreviewInline(kind: PreviewInlineKind.text, text: block.text)]
      : block.inlines;
  return inlines.map(_inlineNodeHtml).join();
}

String _inlineNodeHtml(PreviewInline inline) {
  final childHtml = inline.children.isEmpty
      ? htmlEscape.convert(inline.text)
      : inline.children.map(_inlineNodeHtml).join();
  return switch (inline.kind) {
    PreviewInlineKind.text => htmlEscape.convert(inline.text),
    PreviewInlineKind.strong => '<strong>$childHtml</strong>',
    PreviewInlineKind.emphasis => '<em>$childHtml</em>',
    PreviewInlineKind.strikethrough => '<del>$childHtml</del>',
    PreviewInlineKind.code => '<code>${htmlEscape.convert(inline.text)}</code>',
    PreviewInlineKind.link =>
      '<a href="${htmlEscape.convert(inline.destination ?? '')}">$childHtml</a>',
    PreviewInlineKind.image =>
      '<img src="${htmlEscape.convert(inline.destination ?? '')}" alt="${htmlEscape.convert(inline.text)}">',
  };
}

String? _attributeValue(String raw, String key) {
  return RegExp('$key\\s*=\\s*"([^"]+)"').firstMatch(raw)?.group(1);
}
