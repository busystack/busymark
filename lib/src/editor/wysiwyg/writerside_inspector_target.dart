import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../markdown/busymark_document.dart';
import 'wysiwyg_document_controller.dart';
import 'wysiwyg_inline_controller.dart';
import '../../markdown/busymark_markdown_serializer.dart';
import '../../markdown/markdown_source_map.dart';

/// A source-generation-bound identity. Parser IDs are only locators within
/// this snapshot, never durable identities across reparsing or replacement.
class WritersideInspectorTarget {
  const WritersideInspectorTarget({
    required this.bufferId,
    required this.revision,
    required this.source,
    required this.authoredSource,
    required this.document,
    required this.block,
    required this.path,
    this.inline,
    this.multiple = false,
    this.logicalTopic = false,
  });
  final String bufferId;
  final int revision;
  final String source;
  final String authoredSource;
  final BusyDocument document;
  final BusyBlock? block;
  final List<BusyBlock> path;
  final BusyInlineStyleRange? inline;
  final bool multiple;
  final bool logicalTopic;
  List<int> get address {
    List<int>? find(List<BusyBlock> blocks) {
      for (var i = 0; i < blocks.length; i++) {
        if (blocks[i].id == block?.id) return [i];
        final nested = find(blocks[i].children);
        if (nested != null) return [i, ...nested];
      }
      return null;
    }

    return find(document.blocks) ?? [];
  }

  bool get topic =>
      logicalTopic ||
      block?.attributes['element'] == 'topic' ||
      block?.kind == BusyBlockKind.heading &&
          block?.attributes['level'] == '1' &&
          block?.attributes.containsKey('element') != true;
  bool matches(String? id, int? generation, String? text) =>
      id == bufferId &&
      generation == revision &&
      source == text &&
      authoredSource == source;

  bool sameElement(WritersideInspectorTarget? current) =>
      current != null &&
      bufferId == current.bufferId &&
      revision == current.revision &&
      source == current.source &&
      topic == current.topic &&
      multiple == current.multiple &&
      listEquals(address, current.address) &&
      inline?.kind == current.inline?.kind &&
      inline?.start == current.inline?.start &&
      inline?.end == current.inline?.end;

  static WritersideInspectorTarget fromTopic({
    required String bufferId,
    required int revision,
    required String source,
    required BusyDocument document,
  }) {
    final root = document.blocks
        .where(
          (b) =>
              b.attributes['element'] == 'topic' ||
              b.kind == BusyBlockKind.heading &&
                  b.attributes['level'] == '1' &&
                  !b.attributes.containsKey('element'),
        )
        .firstOrNull;
    final selected = fromSelection(
      bufferId: bufferId,
      revision: revision,
      source: source,
      document: document,
      blockId: root?.id,
    );
    return WritersideInspectorTarget(
      bufferId: bufferId,
      revision: revision,
      source: source,
      authoredSource: selected.authoredSource,
      document: document,
      block: selected.block,
      path: selected.path,
      logicalTopic: true,
    );
  }

  static WritersideInspectorTarget fromSelection({
    required String bufferId,
    required int revision,
    required String source,
    required BusyDocument document,
    String? blockId,
    BusyInlineStyleRange? inline,
    bool multiple = false,
  }) {
    final model = BusyMarkWysiwygDocumentController(document: document);
    try {
      final block = blockId == null ? null : model.blockById(blockId);
      return WritersideInspectorTarget(
        bufferId: bufferId,
        revision: revision,
        source: source,
        authoredSource: model.markdown,
        document: document,
        block: block,
        path: block == null ? const [] : model.elementPath(block.id),
        inline: inline,
        multiple: multiple,
      );
    } finally {
      model.dispose();
    }
  }

  static WritersideInspectorTarget fromSource({
    required String bufferId,
    required int revision,
    required String source,
    required BusyDocument document,
    required TextSelection selection,
  }) {
    List<BusyBlock> locate(int offset) {
      List<BusyBlock> find(List<BusyBlock> blocks) {
        for (final block in blocks) {
          final span = block.sourceSpan;
          if (span == null ||
              offset < span.startOffset ||
              offset >= span.endOffset) {
            continue;
          }
          return [block, ...find(block.children)];
        }
        return [];
      }

      return find(document.blocks);
    }

    final start = selection.start.clamp(0, source.length);
    final first = locate(start);
    final last = selection.isCollapsed
        ? first
        : locate((selection.end - 1).clamp(0, source.length));
    final multiple = first.lastOrNull?.id != last.lastOrNull?.id;
    BusyInlineStyleRange? inline;
    final block = first.lastOrNull;
    if (!multiple && block != null && block.sourceSpan != null) {
      final base = block.sourceSpan!.startOffset;
      final raw = block.rawSource ?? '';
      final mapped =
          !document.isXmlTopic && !block.attributes.containsKey('element')
          ? const MarkdownSourceMapper()
                .createInlineParserContext(
                  documentSource: source,
                  mode: document.mode,
                )
                .parseMapped(raw)
          : null;
      final mappedReferences =
          mapped?.ranges.entries
              .where(
                (e) => {
                  BusyInlineKind.link,
                  BusyInlineKind.image,
                }.contains(e.key.kind),
              )
              .toList() ??
          const [];
      final references = busyInlineReferenceRanges(block.inlines);
      for (final range in references) {
        if (!{
          BusyInlineKind.link,
          BusyInlineKind.image,
          BusyInlineKind.writersideVariable,
          BusyInlineKind.writersideShortcut,
        }.contains(range.kind)) {
          continue;
        }
        final binding = range.attributes['xml-source-binding']?.split(':');
        int? begin;
        int? end;
        if (document.isXmlTopic && binding?.length == 2) {
          begin = int.tryParse(binding![0]);
          end = int.tryParse(binding[1]);
        } else if (mapped != null &&
            {BusyInlineKind.link, BusyInlineKind.image}.contains(range.kind)) {
          final peers = references.where((r) => r.kind == range.kind).toList();
          final ordinal = peers.indexOf(range);
          final candidates =
              mappedReferences.where((e) => e.key.kind == range.kind).toList()
                ..sort((a, b) => a.value.start.compareTo(b.value.start));
          if (ordinal >= 0 && candidates.length == peers.length) {
            begin = base + candidates[ordinal].value.start;
            end = base + candidates[ordinal].value.end;
            final attributes = RegExp(
              r'^\{(?:\s*[\w:.-]+\s*=\s*"[^"]*"\s*)+\}',
            ).firstMatch(raw.substring(candidates[ordinal].value.end));
            end += attributes?.end ?? 0;
          }
        } else {
          final fragment =
              range.attributes['xml-original-source'] ??
              (range.kind == BusyInlineKind.writersideVariable
                  ? '%${range.attributes['reference'] ?? block.plainText.substring(range.start, range.end)}%'
                  : const BusyMarkMarkdownSerializer().serializeInlineFragment([
                      BusyInline(
                        kind: range.kind,
                        text: block.plainText.substring(range.start, range.end),
                        destination: range.destination,
                        attributes: range.attributes,
                      ),
                    ]));
          final at = raw.indexOf(fragment);
          if (at >= 0 && raw.indexOf(fragment, at + fragment.length) < 0) {
            begin = base + at;
            end = begin + fragment.length;
          }
        }
        if (begin != null &&
            end != null &&
            start >= begin &&
            start < end &&
            selection.end <= end) {
          inline = range;
        }
      }
    }
    return fromSelection(
      bufferId: bufferId,
      revision: revision,
      source: source,
      document: document,
      blockId: multiple ? null : first.lastOrNull?.id,
      inline: inline,
      multiple: multiple,
    );
  }
}
