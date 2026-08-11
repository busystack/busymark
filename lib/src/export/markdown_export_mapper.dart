import 'package:path/path.dart' as p;

import '../core/uri_utils.dart';
import '../markdown/busymark_document.dart';
import 'markdown_export_document.dart';

class MarkdownExportMapper {
  const MarkdownExportMapper();

  MarkdownExportDocument map(BusyDocument document) {
    return MarkdownExportDocument(
      metadata: _metadata(document),
      blocks: _mapBlocks(document.blocks),
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

  List<MarkdownExportBlock> _mapBlocks(List<BusyBlock> blocks) {
    final result = <MarkdownExportBlock>[];
    var index = 0;
    while (index < blocks.length) {
      final block = blocks[index];
      if (_isListItem(block.kind)) {
        final ordered = _isOrderedListItem(block);
        final items = <MarkdownExportBlock>[];
        final start = _listNumber(block.attributes['marker']) ?? 1;
        while (index < blocks.length && _isListItem(blocks[index].kind)) {
          final candidate = blocks[index];
          final candidateOrdered = _isOrderedListItem(candidate);
          if (candidateOrdered != ordered) {
            break;
          }
          items.add(_mapListItem(candidate));
          index++;
        }
        result.add(
          MarkdownExportBlock(
            kind: MarkdownExportBlockKind.list,
            children: items,
            attributes: {'ordered': ordered, 'start': start},
          ),
        );
        continue;
      }
      final mapped = _mapBlock(block);
      if (mapped != null) {
        result.add(mapped);
      }
      index++;
    }
    return List.unmodifiable(result);
  }

  MarkdownExportBlock _mapListItem(BusyBlock block) {
    return MarkdownExportBlock(
      kind: MarkdownExportBlockKind.listItem,
      inlines: _mapInlines(block.inlines),
      children: _mapBlocks(block.children),
      attributes: {
        if (block.attributes['task'] case final task?) 'task': task == 'true',
      },
    );
  }

  MarkdownExportBlock? _mapBlock(BusyBlock block) {
    return switch (block.kind) {
      BusyBlockKind.heading => MarkdownExportBlock(
        kind: MarkdownExportBlockKind.heading,
        inlines: _mapInlines(block.inlines),
        attributes: {
          'level':
              int.tryParse(block.attributes['level'] ?? '')?.clamp(1, 6) ?? 1,
          if (_safeAnchor(block.attributes['id']) case final id?) 'id': id,
        },
      ),
      BusyBlockKind.paragraph => MarkdownExportBlock(
        kind: MarkdownExportBlockKind.paragraph,
        inlines: _mapInlines(block.inlines),
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
      BusyBlockKind.blockquote => MarkdownExportBlock(
        kind: MarkdownExportBlockKind.blockquote,
        inlines: _mapInlines(block.inlines),
        children: _mapBlocks(block.children),
      ),
      BusyBlockKind.thematicBreak => const MarkdownExportBlock(
        kind: MarkdownExportBlockKind.thematicBreak,
      ),
      BusyBlockKind.image => _mapImageBlock(block),
      BusyBlockKind.table => _mapTable(block),
      BusyBlockKind.htmlBlock when block.children.isNotEmpty =>
        MarkdownExportBlock(
          kind: MarkdownExportBlockKind.group,
          children: _mapBlocks(block.children),
        ),
      BusyBlockKind.htmlBlock => MarkdownExportBlock(
        kind: MarkdownExportBlockKind.rawText,
        text: block.rawSource ?? block.plainText,
      ),
      BusyBlockKind.frontMatter => null,
      BusyBlockKind.unorderedListItem ||
      BusyBlockKind.orderedListItem ||
      BusyBlockKind.taskListItem => _mapListItem(block),
      BusyBlockKind.writersideAdmonition ||
      BusyBlockKind.writersideTabs ||
      BusyBlockKind.writersideProcedure ||
      BusyBlockKind.writersideRawXml ||
      BusyBlockKind.unknown => MarkdownExportBlock(
        kind: block.children.isEmpty
            ? MarkdownExportBlockKind.rawText
            : MarkdownExportBlockKind.group,
        inlines: _mapInlines(block.inlines),
        children: _mapBlocks(block.children),
        text: block.rawSource ?? block.plainText,
      ),
    };
  }

  MarkdownExportBlock _mapTable(BusyBlock table) {
    return MarkdownExportBlock(
      kind: MarkdownExportBlockKind.table,
      children: [
        for (final row in table.children)
          MarkdownExportBlock(
            kind: MarkdownExportBlockKind.tableRow,
            attributes: {'header': row.attributes['header'] == 'true'},
            children: [
              for (final cell in row.children)
                MarkdownExportBlock(
                  kind: MarkdownExportBlockKind.tableCell,
                  inlines: _mapInlines(cell.inlines),
                  children: _mapBlocks(cell.children),
                  attributes: {
                    if (_safeAlignment(cell.attributes['align'])
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

  List<MarkdownExportInline> _mapInlines(List<BusyInline> inlines) {
    return List.unmodifiable(inlines.map(_mapInline));
  }

  MarkdownExportInline _mapInline(BusyInline inline) {
    final children = _mapInlines(inline.children);
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
