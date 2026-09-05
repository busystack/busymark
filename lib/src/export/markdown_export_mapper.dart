import '../markdown/table_grid.dart';
import 'package:path/path.dart' as p;

import '../core/uri_utils.dart';
import '../markdown/busymark_document.dart';
import '../writerside/writerside_video.dart';
import 'markdown_export_document.dart';

const double busyMarkPdfBodyTextSize = 10.5;

double busyMarkPdfHeadingTextSize(int level) => switch (level.clamp(1, 6)) {
  1 => 22,
  2 => 17,
  3 => 13.5,
  4 => 11.5,
  5 || 6 => busyMarkPdfBodyTextSize,
  _ => busyMarkPdfBodyTextSize,
};

class MarkdownExportMapper {
  const MarkdownExportMapper();

  MarkdownExportDocument map(
    BusyDocument document, {
    Map<String, MarkdownExportBlock> blockOverrides = const {},
  }) {
    return MarkdownExportDocument(
      metadata: _metadata(document),
      blocks: _mapBlocks(document.blocks, blockOverrides),
    );
  }

  MarkdownExportMetadata _metadata(BusyDocument document) {
    final frontMatter = {
      for (final entry in document.frontMatter.entries)
        entry.key.toLowerCase().trim(): entry.value.trim(),
    };
    final title = _firstNonEmpty([
      frontMatter['title'],
      document.title,
      document.filePath.isEmpty
          ? null
          : p.basenameWithoutExtension(document.filePath),
      'Untitled',
    ])!;
    final keywords = _firstNonEmpty([
      frontMatter['keywords'],
      frontMatter['tags'],
    ]);
    return MarkdownExportMetadata(
      title: title,
      author:
          _firstNonEmpty([frontMatter['author'], frontMatter['authors']]) ?? '',
      description:
          _firstNonEmpty([
            frontMatter['description'],
            frontMatter['summary'],
          ]) ??
          '',
      language: _normalizedLanguage(
        _firstNonEmpty([frontMatter['lang'], frontMatter['language']]),
      ),
      keywords: keywords == null
          ? const []
          : keywords
                .split(RegExp(r'[,;]'))
                .map((value) => value.trim())
                .where((value) => value.isNotEmpty)
                .take(32)
                .toList(growable: false),
    );
  }

  List<MarkdownExportBlock> _mapBlocks(
    List<BusyBlock> blocks,
    Map<String, MarkdownExportBlock> blockOverrides,
  ) {
    final result = <MarkdownExportBlock>[];
    var index = 0;
    while (index < blocks.length) {
      final block = blocks[index];
      if (block.isSourceOnly) {
        index++;
        continue;
      }
      final override = blockOverrides[block.id];
      if (override != null) {
        result.add(override);
        index++;
        continue;
      }
      if (_isListItem(block.kind)) {
        final ordered = _isOrderedListItem(block);
        final listType =
            block.attributes['listType'] ?? (ordered ? 'decimal' : 'bullet');
        final items = <MarkdownExportBlock>[];
        final start = _listNumber(block.attributes['marker']) ?? 1;
        while (index < blocks.length && _isListItem(blocks[index].kind)) {
          final candidate = blocks[index];
          final candidateOrdered = _isOrderedListItem(candidate);
          final candidateListType =
              candidate.attributes['listType'] ??
              (candidateOrdered ? 'decimal' : 'bullet');
          if (candidateOrdered != ordered || candidateListType != listType) {
            break;
          }
          items.add(_mapListItem(candidate, blockOverrides));
          index++;
        }
        result.add(
          MarkdownExportBlock(
            kind: MarkdownExportBlockKind.list,
            children: items,
            attributes: {
              'ordered': ordered,
              'start': start,
              'listType': listType,
            },
          ),
        );
        continue;
      }
      final mapped = _mapBlock(block, blockOverrides);
      if (mapped != null) {
        result.add(mapped);
      }
      index++;
    }
    return List.unmodifiable(result);
  }

  MarkdownExportBlock _mapListItem(
    BusyBlock block,
    Map<String, MarkdownExportBlock> blockOverrides,
  ) {
    return MarkdownExportBlock(
      kind: MarkdownExportBlockKind.listItem,
      inlines: _mapInlines(block.inlines),
      children: _mapBlocks(block.children, blockOverrides),
      attributes: {
        if (block.attributes['task'] case final task?) 'task': task == 'true',
      },
    );
  }

  MarkdownExportBlock? _mapBlock(
    BusyBlock block,
    Map<String, MarkdownExportBlock> blockOverrides,
  ) {
    return switch (block.kind) {
      BusyBlockKind.heading => _mapHeading(block),
      BusyBlockKind.paragraph => MarkdownExportBlock(
        kind: MarkdownExportBlockKind.paragraph,
        inlines: _mapInlines(block.inlines),
      ),
      BusyBlockKind.math => MarkdownExportBlock(
        kind: MarkdownExportBlockKind.math,
        text: block.plainText,
        attributes: {
          'mathId': block.id,
          'display': true,
          if (block.attributes['mathSourceForm'] case final sourceForm?)
            'sourceForm': sourceForm,
        },
      ),
      BusyBlockKind.codeBlock => MarkdownExportBlock(
        kind: MarkdownExportBlockKind.code,
        text: block.plainText,
        attributes: {
          if (_safeCodeLanguage(block.attributes['language'])
              case final language?)
            'language': language,
        },
      ),
      BusyBlockKind.blockquote => _mapBlockquote(block, blockOverrides),
      BusyBlockKind.thematicBreak => const MarkdownExportBlock(
        kind: MarkdownExportBlockKind.thematicBreak,
      ),
      BusyBlockKind.image => _mapImageBlock(block),
      BusyBlockKind.video => _mapVideoBlock(block),
      BusyBlockKind.table => _mapTable(block, blockOverrides),
      BusyBlockKind.htmlBlock when block.children.isNotEmpty =>
        MarkdownExportBlock(
          kind: MarkdownExportBlockKind.group,
          children: _mapBlocks(block.children, blockOverrides),
        ),
      BusyBlockKind.htmlBlock => MarkdownExportBlock(
        kind: MarkdownExportBlockKind.rawText,
        text: block.rawSource ?? block.plainText,
      ),
      BusyBlockKind.frontMatter => null,
      BusyBlockKind.unorderedListItem ||
      BusyBlockKind.orderedListItem ||
      BusyBlockKind.taskListItem => _mapListItem(block, blockOverrides),
      BusyBlockKind.writersideAdmonition => _mapWritersideAdmonition(
        block,
        blockOverrides,
      ),
      BusyBlockKind.writersideTabs
          when block.attributes['topic-switcher'] == 'true' =>
        null,
      BusyBlockKind.writersideTabs => MarkdownExportBlock(
        kind: MarkdownExportBlockKind.group,
        children: [
          if (block.plainText.isNotEmpty)
            MarkdownExportBlock(
              kind: MarkdownExportBlockKind.paragraph,
              inlines: _mapInlines([
                BusyInline(kind: BusyInlineKind.strong, text: block.plainText),
              ]),
            ),
          ..._mapBlocks(block.children, blockOverrides),
        ],
      ),
      BusyBlockKind.writersideProcedure ||
      BusyBlockKind.writersideRawXml ||
      BusyBlockKind.unknown => MarkdownExportBlock(
        kind: block.children.isEmpty
            ? MarkdownExportBlockKind.rawText
            : MarkdownExportBlockKind.group,
        inlines: _mapInlines(block.inlines),
        children: _mapBlocks(block.children, blockOverrides),
        text: block.rawSource ?? block.plainText,
      ),
    };
  }

  MarkdownExportBlock _mapBlockquote(
    BusyBlock block,
    Map<String, MarkdownExportBlock> blockOverrides,
  ) {
    final style = busyAdmonitionStyleFromName(block.attributes['style']);
    final admonition =
        block.attributes[busyMarkWritersideAdmonitionAttribute] == 'true' &&
        style != BusyAdmonitionStyle.quote;
    return MarkdownExportBlock(
      kind: admonition
          ? MarkdownExportBlockKind.admonition
          : MarkdownExportBlockKind.blockquote,
      inlines: _mapInlines(block.inlines),
      children: _mapBlocks(block.children, blockOverrides),
      attributes: {if (admonition) 'style': style?.name ?? 'tip'},
    );
  }

  MarkdownExportBlock _mapWritersideAdmonition(
    BusyBlock block,
    Map<String, MarkdownExportBlock> blockOverrides,
  ) {
    final style =
        busyAdmonitionStyleFromName(
          block.attributes['style'] ?? block.attributes['element'],
        ) ??
        BusyAdmonitionStyle.note;
    return MarkdownExportBlock(
      kind: style == BusyAdmonitionStyle.quote
          ? MarkdownExportBlockKind.blockquote
          : MarkdownExportBlockKind.admonition,
      inlines: _mapInlines(block.inlines),
      children: _mapBlocks(block.children, blockOverrides),
      attributes: {if (style != BusyAdmonitionStyle.quote) 'style': style.name},
    );
  }

  MarkdownExportBlock _mapHeading(BusyBlock block) {
    final level =
        int.tryParse(block.attributes['level'] ?? '')?.clamp(1, 6) ?? 1;
    return MarkdownExportBlock(
      kind: MarkdownExportBlockKind.heading,
      inlines: _mapInlines(
        block.inlines,
        mathEm: busyMarkPdfHeadingTextSize(level),
      ),
      attributes: {
        'level': level,
        if (_safeAnchor(block.attributes['id']) case final id?) 'id': id,
      },
    );
  }

  MarkdownExportBlock _mapTable(
    BusyBlock table,
    Map<String, MarkdownExportBlock> blockOverrides,
  ) {
    final grid = TableGrid.place(
      table.children.map((row) => row.children).toList(),
      (cell) => cell.attributes,
    );
    return MarkdownExportBlock(
      kind: MarkdownExportBlockKind.table,
      attributes: {
        'columnCount': grid.columns,
        'fixedColumns': table.attributes['column-width'] == 'fixed',
        'columnWidths': [
          for (var column = 0; column < grid.columns; column++)
            grid.cells
                    .where(
                      (cell) =>
                          cell.column == column &&
                          cell.colspan == 1 &&
                          cell.value.attributes.containsKey('width'),
                    )
                    .firstOrNull
                    ?.value
                    .attributes['width'] ??
                '',
        ],
      },
      children: [
        for (final (rowIndex, row) in table.children.indexed)
          MarkdownExportBlock(
            kind: MarkdownExportBlockKind.tableRow,
            attributes: {'header': row.attributes['header'] == 'true'},
            children: [
              for (final placement in grid.cells.where(
                (cell) => cell.row == rowIndex,
              ))
                MarkdownExportBlock(
                  kind: MarkdownExportBlockKind.tableCell,
                  inlines: _mapInlines(placement.value.inlines),
                  children: _mapBlocks(
                    placement.value.children,
                    blockOverrides,
                  ),
                  attributes: {
                    'x': placement.column,
                    'y': placement.row,
                    'colspan': placement.colspan,
                    'rowspan': placement.rowspan,
                    'header':
                        placement.value.attributes['header'] == 'true' ||
                        row.attributes['header'] == 'true',
                    if (_safeAlignment(placement.value.attributes['align'])
                        case final alignment?)
                      'align': alignment,
                  },
                ),
            ],
          ),
      ],
    );
  }

  MarkdownExportBlock _mapImageBlock(BusyBlock block) {
    final onlyInline = block.inlines.length == 1 ? block.inlines.single : null;
    if (onlyInline?.kind == BusyInlineKind.link &&
        onlyInline!.children.length == 1 &&
        onlyInline.children.single.kind == BusyInlineKind.image) {
      return MarkdownExportBlock(
        kind: MarkdownExportBlockKind.image,
        inlines: [_mapInline(onlyInline.children.single)],
        attributes: {
          if (_safeLinkDestination(onlyInline.destination)
              case final destination?)
            'destination': destination,
        },
      );
    }
    return MarkdownExportBlock(
      kind: MarkdownExportBlockKind.image,
      inlines: _mapInlines(block.inlines),
    );
  }

  MarkdownExportBlock _mapVideoBlock(BusyBlock block) {
    final source = block.attributes['src']?.trim() ?? '';
    final preview = writersideVideoPreviewSource(
      source,
      block.attributes['preview-src'],
    );
    return MarkdownExportBlock(
      kind: MarkdownExportBlockKind.video,
      attributes: {
        'source': source,
        if (preview.isNotEmpty) 'preview': preview,
        if (block.attributes['width'] case final width?) 'width': width,
        if (block.attributes['height'] case final height?) 'height': height,
      },
    );
  }

  List<MarkdownExportInline> _mapInlines(
    List<BusyInline> inlines, {
    double mathEm = busyMarkPdfBodyTextSize,
  }) {
    return List.unmodifiable(
      inlines.map((inline) => _mapInline(inline, mathEm: mathEm)),
    );
  }

  MarkdownExportInline _mapInline(
    BusyInline inline, {
    double mathEm = busyMarkPdfBodyTextSize,
  }) {
    final children = _mapInlines(inline.children, mathEm: mathEm);
    return switch (inline.kind) {
      BusyInlineKind.text => MarkdownExportInline(
        kind: MarkdownExportInlineKind.text,
        text: inline.text,
      ),
      BusyInlineKind.strong => MarkdownExportInline(
        kind: MarkdownExportInlineKind.strong,
        text: inline.text,
        children: children,
      ),
      BusyInlineKind.emphasis => MarkdownExportInline(
        kind: MarkdownExportInlineKind.emphasis,
        text: inline.text,
        children: children,
      ),
      BusyInlineKind.underline => MarkdownExportInline(
        kind: MarkdownExportInlineKind.underline,
        text: inline.text,
        children: children,
      ),
      BusyInlineKind.strikethrough => MarkdownExportInline(
        kind: MarkdownExportInlineKind.strikethrough,
        text: inline.text,
        children: children,
      ),
      BusyInlineKind.code => MarkdownExportInline(
        kind: MarkdownExportInlineKind.code,
        text: inline.text,
      ),
      BusyInlineKind.math => MarkdownExportInline(
        kind: MarkdownExportInlineKind.math,
        text: inline.text,
        attributes: {
          'mathId': inline.attributes['expressionId'] ?? inline.text,
          'display': 'false',
          'renderEm': '$mathEm',
          'renderEx': '${mathEm / 2}',
          if (inline.attributes['mathSourceForm'] case final sourceForm?)
            'sourceForm': sourceForm,
        },
      ),
      BusyInlineKind.link => MarkdownExportInline(
        kind: MarkdownExportInlineKind.link,
        text: inline.text,
        destination: _safeLinkDestination(inline.destination),
        children: children,
      ),
      BusyInlineKind.image => MarkdownExportInline(
        kind: MarkdownExportInlineKind.image,
        text: inline.text,
        destination: _safeImageDestination(inline.destination),
        attributes: {
          if (inline.attributes['title'] case final title?) 'title': title,
        },
      ),
      BusyInlineKind.softBreak => const MarkdownExportInline(
        kind: MarkdownExportInlineKind.softBreak,
      ),
      BusyInlineKind.hardBreak => const MarkdownExportInline(
        kind: MarkdownExportInlineKind.hardBreak,
      ),
      BusyInlineKind.html ||
      BusyInlineKind.writersideVariable ||
      BusyInlineKind.unknown => MarkdownExportInline(
        kind: MarkdownExportInlineKind.text,
        text: inline.plainText,
      ),
    };
  }

  bool _isListItem(BusyBlockKind kind) {
    return kind == BusyBlockKind.unorderedListItem ||
        kind == BusyBlockKind.orderedListItem ||
        kind == BusyBlockKind.taskListItem;
  }

  bool _isOrderedListItem(BusyBlock block) {
    return block.kind == BusyBlockKind.orderedListItem ||
        block.attributes['ordered'] == 'true';
  }

  int? _listNumber(String? marker) {
    if (marker == null) {
      return null;
    }
    return int.tryParse(marker.replaceAll(RegExp(r'[^0-9]'), ''));
  }

  String? _safeCodeLanguage(String? value) {
    final language = value?.trim().toLowerCase();
    if (language == null ||
        language.isEmpty ||
        !RegExp(r'^[a-z0-9_+.#-]{1,40}$').hasMatch(language)) {
      return null;
    }
    return language;
  }

  String? _safeAnchor(String? value) {
    final anchor = value?.trim();
    if (anchor == null ||
        anchor.isEmpty ||
        anchor.length > 256 ||
        anchor.runes.any((rune) => rune < 0x20 || rune == 0x7f)) {
      return null;
    }
    return anchor;
  }

  String? _safeLinkDestination(String? value) {
    final destination = value?.trim();
    if (destination == null ||
        destination.isEmpty ||
        destination.length > 4096) {
      return null;
    }
    if (destination.startsWith('#')) {
      return _safeAnchor(destination.substring(1)) == null ? null : destination;
    }
    final uri = parseSchemedUri(destination);
    return uri != null && isLaunchableExternalUri(uri) ? uri.toString() : null;
  }

  String? _safeImageDestination(String? value) {
    final destination = value?.trim();
    if (destination == null ||
        destination.isEmpty ||
        destination.length > 4096 ||
        destination.runes.any((rune) => rune == 0 || rune < 0x09)) {
      return null;
    }
    return destination;
  }

  String? _safeAlignment(String? value) {
    final normalized = value?.trim().toLowerCase();
    return const {'left', 'center', 'right'}.contains(normalized)
        ? normalized
        : null;
  }

  String _normalizedLanguage(String? value) {
    final normalized = value?.trim().replaceAll('_', '-').toLowerCase();
    if (normalized == null ||
        !RegExp(r'^[a-z]{2,3}(?:-[a-z]{2})?$').hasMatch(normalized)) {
      return 'en';
    }
    return normalized.split('-').first;
  }

  String? _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}
