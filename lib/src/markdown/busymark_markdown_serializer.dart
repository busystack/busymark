import '../core/source_span.dart';
import 'busymark_document.dart';
import 'math_syntax.dart';

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
      if (!_isSourceBackedBlock(block)) {
        continue;
      }
      if (_isPreservedEmptyParagraph(block)) {
        chunks.add('');
        continue;
      }
      final source = serializeBlock(block);
      if (source.trim().isNotEmpty) {
        chunks.add(source.trimRight());
      }
    }
    return _joinDocumentChunks(chunks);
  }

  String serializeBlock(BusyBlock block) {
    if ((block.isSourceProtected || !_hasDirtyContent(block)) &&
        block.rawSource != null) {
      return block.rawSource!;
    }
    return switch (block.kind) {
      BusyBlockKind.heading => _heading(block),
      BusyBlockKind.paragraph => _inlineMarkdown(block.inlines),
      BusyBlockKind.math => _mathBlock(block),
      BusyBlockKind.codeBlock => _codeBlock(block),
      BusyBlockKind.unorderedListItem => _listItem(block, '-'),
      BusyBlockKind.orderedListItem => _listItem(
        block,
        block.attributes['marker'] ?? '1.',
      ),
      BusyBlockKind.taskListItem => _listItem(
        block,
        block.attributes['ordered'] == 'true'
            ? block.attributes['marker'] ?? '1.'
            : '-',
        contentPrefix: '[${block.attributes['task'] == 'true' ? 'x' : ' '}]',
      ),
      BusyBlockKind.blockquote => _blockquote(block),
      BusyBlockKind.thematicBreak => '---',
      BusyBlockKind.image => _image(block),
      BusyBlockKind.video => block.rawSource ?? _inlineMarkdown(block.inlines),
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
        if (_isSourceBackedBlock(block) &&
            !block.isSourceProtected &&
            _hasDirtyContent(block))
          block,
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
    if (dirtyBlocks.any(
      (block) =>
          _isPreservedEmptyParagraph(block) ||
          block.sourceSpan!.startOffset == block.sourceSpan!.endOffset,
    )) {
      return null;
    }
    final spannedBlocks = [
      for (final block in document.blocks)
        if (_isSourceBackedBlock(block) && block.sourceSpan != null) block,
    ];
    if (spannedBlocks.length !=
        document.blocks.where(_isSourceBackedBlock).length) {
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
    final attributes = <String>[
      if (id != null && id.isNotEmpty && !generated) 'id="${_attribute(id)}"',
      if (busyMarkWritersideIsCollapsible(block.attributes))
        'collapsible="true"',
      if (block.attributes[busyMarkWritersideDefaultStateAttribute]
          case final state? when state.trim().isNotEmpty)
        'default-state="${_attribute(state)}"',
    ];
    final suffix = attributes.isEmpty ? '' : ' {${attributes.join(' ')}}';
    return '${'#' * level} $text$suffix';
  }

  String _codeBlock(BusyBlock block) {
    final language = block.attributes['language'] ?? '';
    final text = block.plainText;
    if (block.attributes[busyMarkWritersideCodeBlockSourceFormAttribute] ==
        busyMarkWritersideCodeBlockElementSourceForm) {
      final attributes = <String>[
        if (language.trim().isNotEmpty)
          'lang="${_xmlAttribute(language.trim())}"',
        for (final entry in block.attributes.entries)
          if (_writersideCodeBlockXmlAttribute(entry.key) &&
              entry.value.trim().isNotEmpty)
            '${entry.key}="${_xmlAttribute(entry.value)}"',
      ];
      final opening =
          '<code-block${attributes.isEmpty ? '' : ' ${attributes.join(' ')}'}';
      if (text.isEmpty && (block.attributes['src']?.isNotEmpty ?? false)) {
        return '$opening/>';
      }
      return '$opening>\n${busyMarkEncodeXmlMathText(text)}\n</code-block>';
    }
    final delimiter = language.contains('`') ? '~' : '`';
    final fence = delimiter * _delimiterLength(text, delimiter, minimum: 3);
    final infoSeparator = language.startsWith(delimiter) ? ' ' : '';
    final source = '$fence$infoSeparator$language\n$text\n$fence';
    final hasSource = block.attributes['src']?.trim().isNotEmpty ?? false;
    if (!busyMarkWritersideIsCollapsible(block.attributes) && !hasSource) {
      return source;
    }
    final attributes = <String>[
      'collapsible="true"',
      if (block.attributes[busyMarkWritersideCollapsedTitleAttribute]
          case final title? when title.trim().isNotEmpty)
        'collapsed-title="${_attribute(title)}"',
      if (block.attributes[busyMarkWritersideDefaultStateAttribute]
          case final state? when state.trim().isNotEmpty)
        'default-state="${_attribute(state)}"',
      if (block.attributes['src'] case final source?
          when source.trim().isNotEmpty)
        'src="${_attribute(source)}"',
    ];
    return '$source\n{${attributes.join(' ')}}';
  }

  bool _writersideCodeBlockXmlAttribute(String key) => !{
    'element',
    'lang',
    'language',
    'editorBlockId',
    busyMarkWritersideCodeBlockSourceFormAttribute,
  }.contains(key);

  String _xmlAttribute(String value) => busyMarkEncodeXmlMathText(
    value,
  ).replaceAll('"', '&quot;').replaceAll("'", '&apos;');

  String _attribute(String value) => value.replaceAll('"', '&quot;');

  String _mathBlock(BusyBlock block) {
    final expression =
        block.attributes[busyMarkMathExpressionAttribute] ?? block.plainText;
    final form = busyMathSourceFormFromName(
      block.attributes[busyMarkMathSourceFormAttribute],
    );
    return switch (form) {
      BusyMathSourceForm.mathFence => '```math\n$expression\n```',
      BusyMathSourceForm.writersideTexFence => '```tex\n$expression\n```',
      BusyMathSourceForm.writersideTexElement =>
        '<code-block lang="tex">\n${busyMarkEncodeXmlMathText(expression)}\n</code-block>',
      BusyMathSourceForm.writersideElement => '<math>$expression</math>',
      BusyMathSourceForm.doubleDollarDisplay ||
      BusyMathSourceForm.dollarInline ||
      BusyMathSourceForm.githubDollarBacktick => '\$\$\n$expression\n\$\$',
    };
  }

  String _listItem(BusyBlock block, String marker, {String? contentPrefix}) {
    final text = _inlineMarkdown(block.inlines);
    final content = [
      if (contentPrefix != null) contentPrefix,
      if (text.isNotEmpty) text,
    ].join(' ');
    final line = content.isEmpty ? marker : '$marker $content';
    if (block.children.isEmpty) {
      return line;
    }
    final indentation = marker.length + 1;
    final nested = block.children
        .map(serializeBlock)
        .where((source) => source.trim().isNotEmpty)
        .map((source) => _indentBlock(source, indentation))
        .join('\n');
    return nested.isEmpty ? line : '$line\n$nested';
  }

  String _indentBlock(String source, int width) {
    final indentation = ' ' * width;
    return source
        .split('\n')
        .map((line) => line.isEmpty ? line : '$indentation$line')
        .join('\n');
  }

  bool _isListKind(BusyBlockKind kind) {
    return kind == BusyBlockKind.unorderedListItem ||
        kind == BusyBlockKind.orderedListItem ||
        kind == BusyBlockKind.taskListItem;
  }

  bool _isSourceBackedBlock(BusyBlock block) {
    return block.kind != BusyBlockKind.frontMatter && !block.isGenerated;
  }

  bool _isPreservedEmptyParagraph(BusyBlock block) {
    return block.kind == BusyBlockKind.paragraph &&
        block.plainText.isEmpty &&
        block.attributes[busyMarkPreserveEmptyParagraphAttribute] == 'true';
  }

  String _joinDocumentChunks(List<String> chunks) {
    if (chunks.isEmpty) {
      return '';
    }
    // Empty chunks are intentional WYSIWYG paragraphs. Each contributes one
    // source line in addition to normal Markdown block separation.
    final firstContentIndex = chunks.indexWhere((chunk) => chunk.isNotEmpty);
    if (firstContentIndex == -1) {
      return chunks.length <= 1 ? '' : '\n' * (chunks.length - 1);
    }
    final buffer = StringBuffer()
      ..write('\n' * firstContentIndex)
      ..write(chunks[firstContentIndex]);
    var emptyParagraphs = 0;
    for (final chunk in chunks.skip(firstContentIndex + 1)) {
      if (chunk.isEmpty) {
        emptyParagraphs += 1;
        continue;
      }
      buffer
        ..write('\n' * (2 + emptyParagraphs))
        ..write(chunk);
      emptyParagraphs = 0;
    }
    buffer.write('\n' * (1 + emptyParagraphs));
    return buffer.toString();
  }

  bool _hasDirtyContent(BusyBlock block) {
    return block.dirty || block.children.any(_hasDirtyContent);
  }

  String _blockquote(BusyBlock block) {
    final text = block.children.isEmpty
        ? _inlineMarkdown(block.inlines)
        : block.children.map(serializeBlock).join('\n\n');
    final quote = text
        .split('\n')
        .map((line) => line.isEmpty ? '>' : '> $line')
        .join('\n');
    if (block.attributes[busyMarkWritersideAdmonitionAttribute] != 'true') {
      return quote;
    }
    final style =
        busyAdmonitionStyleFromName(block.attributes['style']) ??
        BusyAdmonitionStyle.tip;
    if (style == BusyAdmonitionStyle.tip) {
      return quote;
    }
    final attribute = '{style="${style.name}"}';
    return quote.isEmpty ? attribute : '$quote\n$attribute';
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
    final header = rows.first.children.map(_tableCellMarkdown).toList();
    final body = rows.skip(1);
    final buffer = StringBuffer()
      ..writeln('| ${header.join(' | ')} |')
      ..writeln(
        '| ${[for (var column = 0; column < header.length; column++) _tableColumnDelimiter(block, column)].join(' | ')} |',
      );
    for (final row in body) {
      buffer.writeln('| ${row.children.map(_tableCellMarkdown).join(' | ')} |');
    }
    return buffer.toString().trimRight();
  }

  String _tableColumnDelimiter(BusyBlock table, int column) {
    final alignment = table.children
        .where((row) => column < row.children.length)
        .map(
          (row) => busyTableAlignmentFromAttribute(
            row.children[column].attributes['align'],
          ),
        )
        .firstWhere(
          (value) => value != BusyTableAlignment.unspecified,
          orElse: () => BusyTableAlignment.unspecified,
        );
    return switch (alignment) {
      BusyTableAlignment.unspecified => '---',
      BusyTableAlignment.left => ':---',
      BusyTableAlignment.center => ':---:',
      BusyTableAlignment.right => '---:',
    };
  }

  String _tableCellMarkdown(BusyBlock cell) {
    return _inlineMarkdown(
      cell.inlines,
      tableCell: true,
    ).replaceAll('|', r'\|');
  }

  String _writersideAdmonition(BusyBlock block) {
    if (!_hasDirtyContent(block) && block.rawSource != null) {
      return block.rawSource!;
    }
    final style =
        busyAdmonitionStyleFromName(
          block.attributes['style'] ?? block.attributes['element'],
        ) ??
        BusyAdmonitionStyle.note;
    final attributes = block.attributes.entries
        .where(
          (entry) =>
              entry.key != 'element' &&
              entry.key != 'style' &&
              entry.key != busyMarkWritersideAdmonitionAttribute &&
              entry.key != busyMarkWritersideAdmonitionSourceFormAttribute,
        )
        .map((entry) => '${entry.key}="${_escapeXmlAttribute(entry.value)}"')
        .join(' ');
    final opening = attributes.isEmpty
        ? '<${style.name}>'
        : '<${style.name} $attributes>';
    final content = block.children.isEmpty
        ? _inlineMarkdown(block.inlines)
        : block.children.map(serializeBlock).join('\n\n');
    return '$opening$content</${style.name}>';
  }

  String _escapeXmlAttribute(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('"', '&quot;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  String _inlineMarkdown(List<BusyInline> inlines, {bool tableCell = false}) {
    return inlines
        .map((inline) => _inline(inline, tableCell: tableCell))
        .join();
  }

  String _inline(BusyInline inline, {bool tableCell = false}) {
    final children = inline.children.isEmpty
        ? _escapeInlineText(inline.text)
        : _inlineMarkdown(inline.children, tableCell: tableCell);
    return switch (inline.kind) {
      BusyInlineKind.text => _escapeInlineText(inline.text),
      BusyInlineKind.math => _mathInline(inline),
      BusyInlineKind.strong => '**$children**',
      BusyInlineKind.emphasis => '*$children*',
      BusyInlineKind.underline => '<u>$children</u>',
      BusyInlineKind.strikethrough => '~~$children~~',
      BusyInlineKind.code =>
        tableCell && _tableCodeNeedsHtml(inline.text)
            ? _htmlCodeSpan(inline.text)
            : _codeSpan(inline.text),
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

  String _mathInline(BusyInline inline) {
    final form = busyMathSourceFormFromName(
      inline.attributes[busyMarkMathSourceFormAttribute],
    );
    return switch (form) {
      BusyMathSourceForm.githubDollarBacktick => '\$`${inline.text}`\$',
      BusyMathSourceForm.writersideElement =>
        '<math>${_writersideMathExpression(inline)}</math>',
      BusyMathSourceForm.dollarInline ||
      BusyMathSourceForm.doubleDollarDisplay ||
      BusyMathSourceForm.mathFence ||
      BusyMathSourceForm.writersideTexFence ||
      BusyMathSourceForm.writersideTexElement => '\$${inline.text}\$',
    };
  }

  String _writersideMathExpression(BusyInline inline) {
    final raw = inline.attributes[busyMarkMathRawExpressionAttribute];
    if (raw != null && busyMarkDecodeXmlMathText(raw) == inline.text) {
      return raw;
    }
    return busyMarkEncodeXmlMathText(inline.text);
  }

  String _codeSpan(String text) {
    final delimiter = '`' * _delimiterLength(text, '`');
    final touchesDelimiter = text.startsWith('`') || text.endsWith('`');
    final hasOuterSpaces =
        text.startsWith(' ') &&
        text.endsWith(' ') &&
        text.codeUnits.any((unit) => unit != 0x20);
    final content = touchesDelimiter || hasOuterSpaces ? ' $text ' : text;
    return '$delimiter$content$delimiter';
  }

  bool _tableCodeNeedsHtml(String text) {
    var backslashes = 0;
    for (final unit in text.codeUnits) {
      if (unit == 0x5c) {
        backslashes += 1;
        continue;
      }
      if (unit == 0x7c && backslashes.isOdd) {
        return true;
      }
      backslashes = 0;
    }
    return false;
  }

  String _htmlCodeSpan(String text) {
    final encoded = text.runes.map((rune) => '&#$rune;').join();
    return '<code>$encoded</code>';
  }

  int _delimiterLength(String text, String delimiter, {int minimum = 1}) {
    var longest = 0;
    var current = 0;
    for (final unit in text.codeUnits) {
      if (unit == delimiter.codeUnitAt(0)) {
        current += 1;
        if (current > longest) {
          longest = current;
        }
      } else {
        current = 0;
      }
    }
    final required = longest + 1;
    return required < minimum ? minimum : required;
  }

  String _escapeInlineText(String value) {
    return value
        .replaceAll('\\', r'\\')
        .replaceAll(r'$', r'\$')
        .replaceAll('[', r'\[')
        .replaceAll(']', r'\]');
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
