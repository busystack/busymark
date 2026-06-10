import 'dart:convert';

import 'markdown_model.dart';

enum PreviewBlockKind {
  heading,
  paragraph,
  code,
  list,
  quote,
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
    this.children = const [],
    this.attributes = const {},
  });

  final PreviewBlockKind kind;
  final String text;
  final int? level;
  final String? language;
  final List<PreviewBlock> children;
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

class MarkdownPreviewBuilder {
  const MarkdownPreviewBuilder();

  PreviewDocument build(ParsedMarkdownDocument document) {
    final blocks = <PreviewBlock>[];
    var inCode = false;
    var headingIndex = 0;
    final lines = document.source.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final fence = RegExp(r'^\s*```').hasMatch(line);
      if (fence) {
        inCode = !inCode;
        continue;
      }
      if (inCode) {
        continue;
      }
      final heading = RegExp(
        r'^(#{1,6})\s+(.+?)\s*(\{[^}]+\})?\s*$',
      ).firstMatch(line);
      if (heading != null) {
        final parsedHeading = headingIndex < document.headings.length
            ? document.headings[headingIndex]
            : null;
        headingIndex++;
        blocks.add(
          PreviewBlock(
            kind: PreviewBlockKind.heading,
            text: heading.group(2)!.trim(),
            level: heading.group(1)!.length,
            attributes: {if (parsedHeading != null) 'id': parsedHeading.id},
          ),
        );
        continue;
      }
      if (line.trim().isEmpty ||
          line.trim() == '---' ||
          RegExp(r'^\s*[A-Za-z_-]+:').hasMatch(line)) {
        continue;
      }
      if (line.trimLeft().startsWith('>')) {
        blocks.add(
          PreviewBlock(
            kind: PreviewBlockKind.admonition,
            text: _stripInlineMarkup(
              line.replaceFirst(RegExp(r'^\s*>\s?'), ''),
            ),
            attributes: {
              'style': line.contains('warning') ? 'warning' : 'note',
            },
          ),
        );
        continue;
      }
      if (line.trimLeft().startsWith('- ') ||
          RegExp(r'^\s*\d+\.\s+').hasMatch(line)) {
        blocks.add(
          PreviewBlock(
            kind: PreviewBlockKind.list,
            text: _stripInlineMarkup(_stripListMarker(line)),
          ),
        );
        continue;
      }
      if (line.contains('<tabs')) {
        blocks.add(
          const PreviewBlock(kind: PreviewBlockKind.tabs, text: 'Tabs'),
        );
        continue;
      }
      if (line.contains('<procedure')) {
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
        blocks.add(
          PreviewBlock(
            kind: PreviewBlockKind.admonition,
            text: _stripTags(line),
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
      blocks.add(
        PreviewBlock(
          kind: PreviewBlockKind.paragraph,
          text: _stripInlineMarkup(_stripTags(line.trim())),
        ),
      );
    }
    for (final code in document.codeBlocks) {
      blocks.add(
        PreviewBlock(
          kind: PreviewBlockKind.code,
          text: code.content.trimRight(),
          language: code.language,
        ),
      );
    }
    for (final image in document.images) {
      blocks.add(
        PreviewBlock(
          kind: PreviewBlockKind.image,
          text: image.alt.isEmpty ? image.destination : image.alt,
          attributes: {'src': image.destination},
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
    final text = htmlEscape.convert(block.text);
    switch (block.kind) {
      case PreviewBlockKind.heading:
        final level = block.level?.clamp(1, 6) ?? 2;
        buffer.writeln('<h$level>$text</h$level>');
      case PreviewBlockKind.code:
        buffer.writeln('<pre><code>$text</code></pre>');
      case PreviewBlockKind.image:
        final src = htmlEscape.convert(block.attributes['src'] ?? '');
        buffer.writeln(
          '<figure><img src="$src" alt="$text"><figcaption>$text</figcaption></figure>',
        );
      case PreviewBlockKind.admonition:
        buffer.writeln('<aside class="admonition">$text</aside>');
      case PreviewBlockKind.list:
        buffer.writeln('<ul><li>$text</li></ul>');
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

String _stripInlineMarkup(String value) {
  return value
      .replaceAll(RegExp(r'[*_`]+'), '')
      .replaceAllMapped(
        RegExp(r'!\[([^\]]*)\]\(([^)]+)\)'),
        (match) => match.group(1)!.isEmpty ? match.group(2)! : match.group(1)!,
      )
      .replaceAllMapped(
        RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
        (match) => match.group(1)!,
      )
      .trim();
}

String _stripListMarker(String value) {
  return value
      .trimLeft()
      .replaceFirst(RegExp(r'^-\s+'), '')
      .replaceFirst(RegExp(r'^\d+\.\s+'), '')
      .trim();
}

String _stripTags(String value) {
  return value.replaceAll(RegExp('<[^>]+>'), '').trim();
}

String? _attributeValue(String raw, String key) {
  return RegExp('$key\\s*=\\s*"([^"]+)"').firstMatch(raw)?.group(1);
}
