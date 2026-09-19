import '../core/source_span.dart';
import 'busymark_document.dart';
import 'math_syntax.dart';

class BusyMarkSerializedInlineFragment {
  const BusyMarkSerializedInlineFragment({
    required this.source,
    required this.sourceOffset,
  });

  final String source;
  final int sourceOffset;
}

class BusyMarkInlineDelimiter {
  const BusyMarkInlineDelimiter({required this.opening, required this.closing});

  final String opening;
  final String closing;
}

class BusyMarkMarkdownSerializer {
  const BusyMarkMarkdownSerializer();

  /// Serializes an inline fragment without document-level trimming or a final
  /// newline. This is also the single entry point for context-sensitive inline
  /// escaping used by clipboard insertion.
  String serializeInlineFragment(
    List<BusyInline> inlines, {
    bool tableCell = false,
    bool atBlockStart = false,
    bool readableHardBreakRuns = true,
  }) {
    final source = _inlineMarkdown(
      inlines,
      tableCell: tableCell,
      atBlockStart: atBlockStart,
      readableHardBreakRuns: readableHardBreakRuns,
    );
    return tableCell ? source.replaceAll('|', r'\|') : source;
  }

  /// Serializes [inlines] without altering their semantic adjacency and maps
  /// a plain-text boundary to its resulting source offset.
  BusyMarkSerializedInlineFragment serializeInlineFragmentAtTextOffset(
    List<BusyInline> inlines, {
    required int textOffset,
    bool tableCell = false,
    bool atBlockStart = false,
    bool readableHardBreakRuns = true,
    Map<BusyInlineKind, BusyMarkInlineDelimiter> delimiterOverrides = const {},
  }) {
    final result = _inlineMarkdownAtTextOffset(
      inlines,
      textOffset: textOffset,
      tableCell: tableCell,
      atBlockStart: atBlockStart,
      readableHardBreakRuns: readableHardBreakRuns,
      delimiterOverrides: delimiterOverrides,
    );
    if (!tableCell) {
      return BusyMarkSerializedInlineFragment(
        source: result.source,
        sourceOffset: result.sourceOffset!,
      );
    }
    final prefix = result.source.substring(0, result.sourceOffset!);
    return BusyMarkSerializedInlineFragment(
      source: result.source.replaceAll('|', r'\|'),
      sourceOffset: prefix.replaceAll('|', r'\|').length,
    );
  }

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
      BusyBlockKind.paragraph => _inlineMarkdown(
        block.inlines,
        atBlockStart: true,
        readableHardBreakRuns: true,
      ),
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
    final text = _inlineMarkdown(
      block.inlines,
      atBlockStart: true,
      readableHardBreakRuns: true,
    );
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
    return block.kind != BusyBlockKind.frontMatter &&
        !block.isGenerated &&
        !_isTransientTrailingParagraph(block);
  }

  bool _isTransientTrailingParagraph(BusyBlock block) {
    return block.kind == BusyBlockKind.paragraph &&
        block.plainText.isEmpty &&
        block.attributes[busyMarkTransientTrailingParagraphAttribute] == 'true';
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
        ? _inlineMarkdown(block.inlines, readableHardBreakRuns: true)
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
    return serializeInlineFragment(
      cell.inlines,
      tableCell: true,
      readableHardBreakRuns: false,
    );
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

  _InlineSerialization _inlineMarkdownAtTextOffset(
    List<BusyInline> inlines, {
    required int textOffset,
    required bool tableCell,
    required bool atBlockStart,
    required bool readableHardBreakRuns,
    required Map<BusyInlineKind, BusyMarkInlineDelimiter> delimiterOverrides,
  }) {
    final totalTextLength = inlines.fold<int>(
      0,
      (length, inline) => length + inline.plainText.length,
    );
    final target = textOffset.clamp(0, totalTextLength).toInt();
    final buffer = StringBuffer();
    var consumedText = 0;
    int? sourceOffset;
    var nextAtBlockStart = atBlockStart;
    for (var index = 0; index < inlines.length; index++) {
      final inline = inlines[index];
      if (inline.kind == BusyInlineKind.hardBreak) {
        var runEnd = index + 1;
        while (runEnd < inlines.length &&
            inlines[runEnd].kind == BusyInlineKind.hardBreak) {
          runEnd += 1;
        }
        final run = inlines.sublist(index, runEnd);
        final runTextLength = run.fold<int>(
          0,
          (length, item) => length + item.plainText.length,
        );
        final runSource = _hardBreakRunSource(
          count: run.length,
          startsBlock: buffer.isEmpty,
          hasFollowingContent: runEnd < inlines.length,
          tableCell: tableCell,
          nextAtBlockStart: nextAtBlockStart,
          readableHardBreakRuns: readableHardBreakRuns,
        );
        if (sourceOffset == null && target >= consumedText) {
          if (target == consumedText) {
            sourceOffset = buffer.length;
          } else if (target <= consumedText + runTextLength) {
            sourceOffset = buffer.length + runSource.length;
          }
        }
        buffer.write(runSource);
        consumedText += runTextLength;
        nextAtBlockStart = runSource.endsWith('\n');
        index = runEnd - 1;
        continue;
      }
      final length = inline.plainText.length;
      final localOffset =
          target >= consumedText && target <= consumedText + length
          ? target - consumedText
          : null;
      final result = _inlineAtTextOffset(
        inline,
        textOffset: localOffset,
        tableCell: tableCell,
        atBlockStart: nextAtBlockStart,
        readableHardBreakRuns: readableHardBreakRuns,
        followedByLink:
            index + 1 < inlines.length &&
            inlines[index + 1].kind == BusyInlineKind.link,
        delimiterOverrides: delimiterOverrides,
      );
      if (sourceOffset == null && result.sourceOffset != null) {
        sourceOffset = buffer.length + result.sourceOffset!;
      }
      buffer.write(result.source);
      consumedText += length;
      if (result.source.isNotEmpty) {
        nextAtBlockStart = result.source.endsWith('\n');
      }
    }
    return _InlineSerialization(
      source: buffer.toString(),
      sourceOffset: sourceOffset ?? buffer.length,
    );
  }

  _InlineSerialization _inlineAtTextOffset(
    BusyInline inline, {
    required int? textOffset,
    required bool tableCell,
    required bool atBlockStart,
    required bool readableHardBreakRuns,
    required bool followedByLink,
    required Map<BusyInlineKind, BusyMarkInlineDelimiter> delimiterOverrides,
  }) {
    final length = inline.plainText.length;
    final target = textOffset?.clamp(0, length).toInt();
    final childResult = inline.children.isEmpty
        ? null
        : _inlineMarkdownAtTextOffset(
            inline.children,
            textOffset: target ?? 0,
            tableCell: tableCell,
            atBlockStart: false,
            readableHardBreakRuns: readableHardBreakRuns,
            delimiterOverrides: delimiterOverrides,
          );
    final children = inline.children.isEmpty
        ? _escapeInlineText(inline.text, atBlockStart: atBlockStart)
        : childResult!.source;
    final delimiter = delimiterOverrides[inline.kind];
    final source = switch (inline.kind) {
      BusyInlineKind.text => _escapeInlineText(
        inline.text,
        atBlockStart: atBlockStart,
        escapeTrailingBang: followedByLink,
      ),
      BusyInlineKind.math => _mathInline(inline),
      BusyInlineKind.strong =>
        '${delimiter?.opening ?? '**'}$children${delimiter?.closing ?? '**'}',
      BusyInlineKind.emphasis =>
        '${delimiter?.opening ?? '*'}$children${delimiter?.closing ?? '*'}',
      BusyInlineKind.underline =>
        '${delimiter?.opening ?? '<u>'}$children${delimiter?.closing ?? '</u>'}',
      BusyInlineKind.strikethrough =>
        '${delimiter?.opening ?? '~~'}$children${delimiter?.closing ?? '~~'}',
      BusyInlineKind.code =>
        tableCell && _tableCodeNeedsHtml(inline.text)
            ? _htmlCodeSpan(inline.text)
            : _codeSpan(inline.text),
      BusyInlineKind.link =>
        '[${children.isEmpty ? inline.text : children}](${_linkTarget(inline)})',
      BusyInlineKind.image =>
        '![${_escapeInlineText(inline.text)}](${inline.destination ?? ''})',
      BusyInlineKind.softBreak => ' ',
      BusyInlineKind.hardBreak => '  \n',
      BusyInlineKind.writersideVariable => '%${inline.text}%',
      BusyInlineKind.html || BusyInlineKind.unknown => inline.text,
    };
    if (target == null) {
      return _InlineSerialization(source: source);
    }
    if (target == 0) {
      return _InlineSerialization(source: source, sourceOffset: 0);
    }
    if (target == length) {
      return _InlineSerialization(source: source, sourceOffset: source.length);
    }
    final childOffset = childResult?.sourceOffset;
    final sourceOffset = switch (inline.kind) {
      BusyInlineKind.text => _escapedInlineTextOffset(
        inline.text,
        target,
        atBlockStart: atBlockStart,
        escapeTrailingBang: followedByLink,
      ),
      BusyInlineKind.strong ||
      BusyInlineKind.emphasis ||
      BusyInlineKind.underline ||
      BusyInlineKind.strikethrough =>
        (delimiter?.opening.length ??
                switch (inline.kind) {
                  BusyInlineKind.strong || BusyInlineKind.strikethrough => 2,
                  BusyInlineKind.underline => 3,
                  _ => 1,
                }) +
            (childOffset ?? 0),
      BusyInlineKind.link => 1 + (childOffset ?? 0),
      _ => source.length,
    };
    return _InlineSerialization(source: source, sourceOffset: sourceOffset);
  }

  String _hardBreakRunSource({
    required int count,
    required bool startsBlock,
    required bool hasFollowingContent,
    required bool tableCell,
    required bool nextAtBlockStart,
    required bool readableHardBreakRuns,
  }) {
    if (count == 1) return '  \n';
    if (!readableHardBreakRuns || tableCell) {
      return List.filled(count, '<br>').join();
    }
    final buffer = StringBuffer();
    if (!startsBlock && !nextAtBlockStart) buffer.write('\n');
    if (startsBlock) {
      buffer.write('<br><br>');
      for (var marker = 2; marker < count; marker++) {
        buffer.write('\n<br>');
      }
    } else {
      buffer.write(List.filled(count, '<br>').join('\n'));
    }
    if (hasFollowingContent) buffer.write('\n');
    return buffer.toString();
  }

  int _escapedInlineTextOffset(
    String value,
    int offset, {
    required bool atBlockStart,
    required bool escapeTrailingBang,
  }) {
    final blockMarkerOffsets = _blockMarkerEscapeOffsets(
      value,
      atBlockStart: atBlockStart,
    );
    var sourceOffset = 0;
    for (var index = 0; index < offset; index++) {
      final unit = value.codeUnitAt(index);
      if (_inlineSyntaxCharacters.contains(unit) ||
          (escapeTrailingBang && unit == 0x21 && index == value.length - 1) ||
          blockMarkerOffsets.contains(index)) {
        sourceOffset += 1;
      }
      sourceOffset += 1;
    }
    return sourceOffset;
  }

  String _inlineMarkdown(
    List<BusyInline> inlines, {
    bool tableCell = false,
    bool atBlockStart = false,
    bool readableHardBreakRuns = false,
  }) {
    final buffer = StringBuffer();
    var nextAtBlockStart = atBlockStart;
    for (var index = 0; index < inlines.length; index++) {
      final inline = inlines[index];
      if (inline.kind == BusyInlineKind.hardBreak) {
        var runEnd = index + 1;
        while (runEnd < inlines.length &&
            inlines[runEnd].kind == BusyInlineKind.hardBreak) {
          runEnd += 1;
        }
        final count = runEnd - index;
        if (count > 1) {
          if (readableHardBreakRuns && !tableCell) {
            final startsBlock = buffer.isEmpty;
            if (!startsBlock && !nextAtBlockStart) {
              buffer.write('\n');
            }
            if (startsBlock) {
              // Two tags on the marker-only first line keep CommonMark from
              // treating a leading <br> as a raw HTML block.
              buffer.write('<br><br>');
              for (var marker = 2; marker < count; marker++) {
                buffer.write('\n<br>');
              }
            } else {
              buffer.write(List.filled(count, '<br>').join('\n'));
            }
            final hasFollowingContent = runEnd < inlines.length;
            if (hasFollowingContent) {
              buffer.write('\n');
            }
            nextAtBlockStart = hasFollowingContent;
          } else {
            // Physical newlines cannot safely occur in headings or table
            // cells. Keep their repeated breaks in compact inline HTML.
            buffer.write(List.filled(count, '<br>').join());
            nextAtBlockStart = false;
          }
          index = runEnd - 1;
          continue;
        }
      }
      final source = _inline(
        inline,
        tableCell: tableCell,
        atBlockStart: nextAtBlockStart,
        readableHardBreakRuns: readableHardBreakRuns,
        followedByLink:
            index + 1 < inlines.length &&
            inlines[index + 1].kind == BusyInlineKind.link,
      );
      buffer.write(source);
      if (source.isNotEmpty) {
        nextAtBlockStart = source.endsWith('\n');
      }
    }
    return buffer.toString();
  }

  String _inline(
    BusyInline inline, {
    bool tableCell = false,
    bool atBlockStart = false,
    bool readableHardBreakRuns = false,
    bool followedByLink = false,
  }) {
    final children = inline.children.isEmpty
        ? _escapeInlineText(inline.text, atBlockStart: atBlockStart)
        : _inlineMarkdown(
            inline.children,
            tableCell: tableCell,
            readableHardBreakRuns: readableHardBreakRuns,
          );
    return switch (inline.kind) {
      BusyInlineKind.text => _escapeInlineText(
        inline.text,
        atBlockStart: atBlockStart,
        escapeTrailingBang: followedByLink,
      ),
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
        '[${children.isEmpty ? inline.text : children}](${_linkTarget(inline)})',
      BusyInlineKind.image =>
        '![${_escapeInlineText(inline.text)}](${inline.destination ?? ''})',
      BusyInlineKind.softBreak => ' ',
      BusyInlineKind.hardBreak => '  \n',
      BusyInlineKind.writersideVariable => '%${inline.text}%',
      BusyInlineKind.html || BusyInlineKind.unknown => inline.text,
    };
  }

  String _linkTarget(BusyInline inline) {
    final destination = inline.destination ?? '';
    final title = inline.attributes['title'];
    if (title == null || title.isEmpty) return destination;
    final escapedTitle = title
        .replaceAll('&', '&amp;')
        .replaceAll('\\', '&#92;')
        .replaceAll('"', '\\"')
        .replaceAll('\r', '&#13;')
        .replaceAll('\n', '&#10;');
    return '$destination "$escapedTitle"';
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

  String _escapeInlineText(
    String value, {
    bool atBlockStart = false,
    bool escapeTrailingBang = false,
  }) {
    final blockMarkerOffsets = _blockMarkerEscapeOffsets(
      value,
      atBlockStart: atBlockStart,
    );
    final buffer = StringBuffer();
    for (var index = 0; index < value.length; index++) {
      final unit = value.codeUnitAt(index);
      if (_inlineSyntaxCharacters.contains(unit) ||
          (escapeTrailingBang && unit == 0x21 && index == value.length - 1) ||
          blockMarkerOffsets.contains(index)) {
        buffer.writeCharCode(0x5c);
      }
      buffer.writeCharCode(unit);
    }
    return buffer.toString();
  }

  Set<int> _blockMarkerEscapeOffsets(
    String value, {
    required bool atBlockStart,
  }) {
    final offsets = <int>{};
    var lineStart = 0;
    var firstLine = true;
    while (lineStart <= value.length) {
      final newline = value.indexOf('\n', lineStart);
      final lineEnd = newline < 0 ? value.length : newline;
      if (!firstLine || atBlockStart) {
        final markerOffset = _blockMarkerEscapeOffset(
          value.substring(lineStart, lineEnd),
        );
        if (markerOffset != null) {
          offsets.add(lineStart + markerOffset);
        }
      }
      if (newline < 0) {
        break;
      }
      lineStart = newline + 1;
      firstLine = false;
    }
    return offsets;
  }

  int? _blockMarkerEscapeOffset(String line) {
    final indentation = RegExp(r'^[ \t]{0,3}').firstMatch(line)!.group(0)!;
    final content = line.substring(indentation.length);
    if (RegExp(r'^#{1,6}(?:[ \t]+|$)').hasMatch(content)) {
      return indentation.length;
    }
    if (content.startsWith('>')) {
      return indentation.length;
    }
    if (RegExp(r'^[-+](?:[ \t]+|$)').hasMatch(content)) {
      return indentation.length;
    }
    final ordered = RegExp(r'^(\d{1,9})([.)])(?:[ \t]+|$)').firstMatch(content);
    if (ordered != null) {
      return indentation.length + ordered.group(1)!.length;
    }
    if (RegExp(r'^=+[ \t]*$').hasMatch(content) ||
        RegExp(r'^-(?:[ \t]*-){2,}[ \t]*$').hasMatch(content)) {
      return indentation.length;
    }
    return null;
  }

  static const _inlineSyntaxCharacters = <int>{
    0x24, // $
    0x25, // %
    0x26, // &
    0x2a, // *
    0x3c, // <
    0x5b, // [
    0x5c, // backslash
    0x5d, // ]
    0x5f, // _
    0x60, // `
    0x7e, // ~
  };
}

class _InlineSerialization {
  const _InlineSerialization({required this.source, this.sourceOffset});

  final String source;
  final int? sourceOffset;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
