import '../core/source_span.dart';
import 'busymark_document.dart';

class BusyMarkMarkdownSerializer {
  const BusyMarkMarkdownSerializer();

  String serialize(BusyDocument document) {
    final patched = _serializeByPatchingSource(document);
    if (patched != null) {
      return patched;
    }
    final chunks = <String>[];
    if (document.rawFrontMatter != null &&
        document.rawFrontMatter!.trim().isNotEmpty) {
      chunks.add(document.rawFrontMatter!.trimRight());
    }
    for (final block in document.blocks) {
      if (block.kind == BusyBlockKind.frontMatter) {
        continue;
      }
      final source = serializeBlock(block);
      if (source.trim().isNotEmpty) {
        chunks.add(source.trimRight());
      }
    }
    if (chunks.isEmpty) {
      return '';
    }
    return '${chunks.join('\n\n')}\n';
  }

  String serializeBlock(BusyBlock block) {
    if (!block.dirty && block.rawSource != null) {
      return block.rawSource!;
    }
    return switch (block.kind) {
      BusyBlockKind.heading => _heading(block),
      BusyBlockKind.paragraph => _inlineMarkdown(block.inlines),
      BusyBlockKind.codeBlock => _codeBlock(block),
      BusyBlockKind.unorderedListItem => _listItem(block, '-'),
      BusyBlockKind.orderedListItem => _listItem(
        block,
        block.attributes['marker'] ?? '1.',
      ),
      BusyBlockKind.taskListItem => _listItem(
        block,
        '- [${block.attributes['task'] == 'true' ? 'x' : ' '}]',
      ),
      BusyBlockKind.blockquote => _blockquote(block),
      BusyBlockKind.thematicBreak => '---',
      BusyBlockKind.image => _image(block),
      BusyBlockKind.table => _table(block),
      BusyBlockKind.writersideAdmonition => _writersideAdmonition(block),
      BusyBlockKind.writersideTabs ||
      BusyBlockKind.writersideProcedure ||
      BusyBlockKind.writersideRawXml ||
      BusyBlockKind.htmlBlock ||
      BusyBlockKind.unknown ||
      BusyBlockKind.frontMatter =>
        block.rawSource ?? _inlineMarkdown(block.inlines),
    };
  }

  String? _serializeByPatchingSource(BusyDocument document) {
    final source = document.source;
    if (source == null) {
      return null;
    }
    final dirtyBlocks = [
      for (final block in document.blocks)
        if (block.kind != BusyBlockKind.frontMatter && block.dirty) block,
    ];
    if (dirtyBlocks.isEmpty) {
      return source;
    }
    if (dirtyBlocks.any((block) => _isListKind(block.kind))) {
      return null;
    }
    if (dirtyBlocks.any((block) => block.sourceSpan == null)) {
      return null;
    }
    final spannedBlocks = [
      for (final block in document.blocks)
        if (block.kind != BusyBlockKind.frontMatter && block.sourceSpan != null)
          block,
    ];
    if (spannedBlocks.length !=
        document.blocks
            .where((block) => block.kind != BusyBlockKind.frontMatter)
            .length) {
      return null;
    }
    if (_sourceOutsideSpansHasContent(
      source,
      spannedBlocks.map((block) => block.sourceSpan!).toList(),
    )) {
      return null;
    }
    final sorted = [...dirtyBlocks]
      ..sort(
        (left, right) => left.sourceSpan!.startOffset.compareTo(
          right.sourceSpan!.startOffset,
        ),
      );
    for (var index = 1; index < sorted.length; index++) {
      if (sorted[index].sourceSpan!.startOffset <
          sorted[index - 1].sourceSpan!.endOffset) {
        return null;
      }
    }
    final buffer = StringBuffer();
    var offset = 0;
    for (final block in sorted) {
      final span = block.sourceSpan!;
      if (span.startOffset < offset ||
          span.endOffset > source.length ||
          span.startOffset > source.length) {
        return null;
      }
      buffer
        ..write(source.substring(offset, span.startOffset))
        ..write(serializeBlock(block).trimRight());
      offset = span.endOffset;
    }
    buffer.write(source.substring(offset));
    return buffer.toString();
  }

  bool _sourceOutsideSpansHasContent(String source, List<SourceSpan> spans) {
    final sorted = [...spans]
      ..sort((left, right) => left.startOffset.compareTo(right.startOffset));
    var offset = 0;
    for (final span in sorted) {
      if (span.startOffset < offset || span.endOffset > source.length) {
        return true;
      }
      if (source.substring(offset, span.startOffset).trim().isNotEmpty) {
        return true;
      }
      offset = span.endOffset;
    }
    return source.substring(offset).trim().isNotEmpty;
  }

  String _heading(BusyBlock block) {
    final level =
        int.tryParse(block.attributes['level'] ?? '')?.clamp(1, 6) ?? 1;
    final text = _inlineMarkdown(block.inlines);
    final id = block.attributes['id'];
    final generated = block.attributes['generatedId'] != 'false';
    final suffix = id == null || id.isEmpty || generated ? '' : ' {id="$id"}';
    return '${'#' * level} $text$suffix';
  }

  String _codeBlock(BusyBlock block) {
    final language = block.attributes['language'] ?? '';
    final text = block.plainText.trimRight();
    return '```$language\n$text\n```';
  }

  String _listItem(BusyBlock block, String marker) {
    final text = _inlineMarkdown(block.inlines);
    final line = text.isEmpty ? marker : '$marker $text';
    if (block.children.isEmpty) {
      return line;
    }
    final nested = block.children
        .map(serializeBlock)
        .where((source) => source.trim().isNotEmpty)
        .map(_indentBlock)
        .join('\n');
    return nested.isEmpty ? line : '$line\n$nested';
  }

  String _indentBlock(String source) {
    return source
        .split('\n')
        .map((line) => line.isEmpty ? line : '  $line')
        .join('\n');
  }

  bool _isListKind(BusyBlockKind kind) {
    return kind == BusyBlockKind.unorderedListItem ||
        kind == BusyBlockKind.orderedListItem ||
        kind == BusyBlockKind.taskListItem;
  }

  String _blockquote(BusyBlock block) {
    final text = block.children.isEmpty
        ? _inlineMarkdown(block.inlines)
        : block.children.map(serializeBlock).join('\n\n');
    return text
        .split('\n')
        .map((line) => line.isEmpty ? '>' : '> $line')
        .join('\n');
  }

  String _image(BusyBlock block) {
    final imageInline = block.inlines
        .where((inline) => inline.kind == BusyInlineKind.image)
        .firstOrNull;
    final alt = imageInline?.text ?? block.plainText;
    final src = block.attributes['src'] ?? imageInline?.destination ?? '';
    final attributes = {...block.attributes}
      ..removeWhere((key, value) => {'src', 'alt', 'title'}.contains(key));
    final attrText = attributes.isEmpty
        ? ''
        : '{ ${attributes.entries.map((entry) => '${entry.key}="${entry.value}"').join(' ')} }';
    return '![${_escapeInlineText(alt)}]($src)$attrText';
  }

  String _table(BusyBlock block) {
    if (block.children.isEmpty) {
      return block.rawSource ?? '';
    }
    final rows = block.children;
    final header = rows.first.children
        .map((cell) => _inlineMarkdown(cell.inlines))
        .toList();
    final body = rows.skip(1);
    final buffer = StringBuffer()
      ..writeln('| ${header.join(' | ')} |')
      ..writeln('| ${header.map((_) => '---').join(' | ')} |');
    for (final row in body) {
      buffer.writeln(
        '| ${row.children.map((cell) => _inlineMarkdown(cell.inlines)).join(' | ')} |',
      );
    }
    return buffer.toString().trimRight();
  }

  String _writersideAdmonition(BusyBlock block) {
    if (!block.dirty && block.rawSource != null) {
      return block.rawSource!;
    }
    final element = block.attributes['element'] ?? 'note';
    return '<$element>${_inlineMarkdown(block.inlines)}</$element>';
  }

  String _inlineMarkdown(List<BusyInline> inlines) {
    return inlines.map(_inline).join();
  }

  String _inline(BusyInline inline) {
    final children = inline.children.isEmpty
        ? _escapeInlineText(inline.text)
        : _inlineMarkdown(inline.children);
    return switch (inline.kind) {
      BusyInlineKind.text => _escapeInlineText(inline.text),
      BusyInlineKind.strong => '**$children**',
      BusyInlineKind.emphasis => '*$children*',
      BusyInlineKind.underline => '<u>$children</u>',
      BusyInlineKind.strikethrough => '~~$children~~',
      BusyInlineKind.code => '`${inline.text.replaceAll('`', r'\`')}`',
      BusyInlineKind.link =>
        '[${children.isEmpty ? inline.text : children}](${inline.destination ?? ''})',
      BusyInlineKind.image =>
        '![${_escapeInlineText(inline.text)}](${inline.destination ?? ''})',
      BusyInlineKind.softBreak => ' ',
      BusyInlineKind.hardBreak => '  \n',
      BusyInlineKind.writersideVariable => '%${inline.text}%',
      BusyInlineKind.html || BusyInlineKind.unknown => inline.text,
    };
  }

  String _escapeInlineText(String value) {
    return value
        .replaceAll('\\', r'\\')
        .replaceAll('[', r'\[')
        .replaceAll(']', r'\]');
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
