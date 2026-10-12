import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../markdown/busymark_document.dart';
import 'wysiwyg_document_controller.dart';
import 'wysiwyg_inline_controller.dart';
import '../../markdown/markdown_source_map.dart';
import 'writerside_editing_adapter.dart';

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
  List<int> get address => _address(includeSourceOnly: true);

  /// Serialization can add XML whitespace nodes. They are not authored
  /// property targets and must not shift the edited element's ordinal.
  List<int> get semanticAddress => _address(includeSourceOnly: false);

  List<int> _address({required bool includeSourceOnly}) {
    List<int>? find(List<BusyBlock> blocks) {
      if (!includeSourceOnly) {
        blocks = blocks.where((b) => !b.isSourceOnly).toList();
      }
      for (var i = 0; i < blocks.length; i++) {
        if (blocks[i].id == block?.id) return [i];
        final nested = find(blocks[i].children);
        if (nested != null) return [i, ...nested];
      }
      return null;
    }

    return find(document.blocks) ?? [];
  }

  bool hasSameAuthoredState(BusyDocument other) {
    bool authored(BusyBlock b) =>
        !b.isGenerated &&
        b.attributes[busyMarkTransientTrailingParagraphAttribute] != 'true' &&
        (!b.isSourceOnly || b.attributes['element'] == 'show-structure');
    Object inlineState(BusyInline inline) => [
      inline.kind,
      inline.text,
      inline.destination,
      {
        for (final a in inline.attributes.entries)
          if (!a.key.startsWith('busymark-')) a.key: a.value,
      },
      inline.children.map(inlineState).toList(),
    ];
    Object blockState(BusyBlock block) => [
      WritersideEditingAdapter.tagForBlock(block),
      WritersideEditingAdapter.sourceAttributes(block),
      if (block.kind == BusyBlockKind.codeBlock) block.attributes['language'],
      if (block.kind == BusyBlockKind.blockquote ||
          block.kind == BusyBlockKind.writersideAdmonition)
        block.attributes['style'],
      block.inlines.map(inlineState).toList(),
      block.children.where(authored).map(blockState).toList(),
      if (block.isSourceProtected || block.preserveRaw) block.rawSource,
    ];
    Object state(BusyDocument d) => [
      d.frontMatter,
      d.blocks.where(authored).map(blockState).toList(),
    ];
    bool equal(Object? a, Object? b) {
      if (a is List && b is List) {
        return a.length == b.length &&
            Iterable.generate(a.length).every((i) => equal(a[i], b[i]));
      }
      if (a is Map && b is Map) {
        return a.length == b.length &&
            a.keys.every((k) => b.containsKey(k) && equal(a[k], b[k]));
      }
      return a == b;
    }

    return equal(state(document), state(other));
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
      inline?.end == current.inline?.end &&
      inline?.referenceIndex == current.inline?.referenceIndex;

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

  /// The inspected occurrence's markup, independent of the editing caret.
  int? get sourceLocation {
    if (block == null) return topic ? 0 : null;
    final selected = inline;
    if (selected == null) return block!.sourceSpan?.startOffset;
    return _authoredInlineRanges(document, source, block!)
        .where(
          (entry) =>
              entry.range.kind == selected.kind &&
              entry.range.start == selected.start &&
              entry.range.end == selected.end &&
              (selected.referenceIndex == null ||
                  entry.range.referenceIndex == selected.referenceIndex),
        )
        .firstOrNull
        ?.begin;
  }

  static Iterable<({BusyInlineStyleRange range, int begin, int end})>
  _authoredInlineRanges(
    BusyDocument document,
    String source,
    BusyBlock block,
  ) sync* {
    if (block.sourceSpan == null) return;
    final base = block.sourceSpan!.startOffset;
    final raw = block.rawSource ?? '';
    if (!document.isXmlTopic && block.attributes.containsKey('element')) {
      // Semantic XML islands retain bindings relative to their own authored
      // fragment. Use that same adapter to map text occurrences, including
      // variables, then translate back into the containing Markdown source.
      const prefix = '<topic id="inspector" title="Inspector">';
      final wrapped = '$prefix$raw</topic>';
      final xml = const WritersideEditingAdapter().parseXml(
        filePath: document.filePath,
        source: wrapped,
      );
      final element = xml?.blocks.first.children
          .where((b) => !b.isSourceOnly)
          .singleOrNull;
      if (xml != null && element?.plainText == block.plainText) {
        final references = busyInlineReferenceRanges(block.inlines);
        for (final entry in _authoredInlineRanges(xml, wrapped, element!)) {
          final owner = references
              .where(
                (r) =>
                    r.kind == entry.range.kind &&
                    r.start == entry.range.start &&
                    r.end == entry.range.end &&
                    r.referenceIndex == entry.range.referenceIndex,
              )
              .firstOrNull;
          if (owner != null) {
            yield (
              range: owner,
              begin: base + entry.begin - prefix.length,
              end: base + entry.end - prefix.length,
            );
          }
        }
      }
      return;
    }
    final mapped =
        !document.isXmlTopic && !block.attributes.containsKey('element')
        ? const MarkdownSourceMapper()
              .createInlineParserContext(
                documentSource: source,
                mode: document.mode,
                mapWritersideReferences: true,
              )
              .parseMapped(raw)
        : null;
    final mappedReferences = <BusyInline>[];
    void collect(List<BusyInline> inlines, bool inheritedIgnore) {
      for (final inline in inlines) {
        final ignore = switch (inline.attributes['ignore-vars']) {
          'true' => true,
          'false' => false,
          _ => inheritedIgnore,
        };
        if (inline.kind != BusyInlineKind.writersideVariable || !ignore) {
          if (mapped!.ranges.containsKey(inline)) mappedReferences.add(inline);
        }
        collect(inline.children, ignore);
      }
    }

    if (mapped != null) {
      collect(mapped.inlines, block.attributes['ignore-vars'] == 'true');
    }
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
      } else if (mapped != null) {
        final peers = references.where((r) => r.kind == range.kind).toList();
        final ordinal = peers.indexOf(range);
        final candidates =
            mappedReferences.where((e) => e.kind == range.kind).toList()..sort(
              (a, b) =>
                  mapped.ranges[a]!.start.compareTo(mapped.ranges[b]!.start),
            );
        if (ordinal >= 0 && candidates.length == peers.length) {
          final positioned = mapped.ranges[candidates[ordinal]]!;
          begin = base + positioned.start;
          end = base + positioned.end;
          final attributes = RegExp(
            r'^\{(?:\s*[\w:.-]+\s*=\s*"[^"]*"\s*)+\}',
          ).firstMatch(raw.substring(positioned.end));
          end += attributes?.end ?? 0;
        }
      } else if (document.isXmlTopic &&
          range.kind == BusyInlineKind.writersideVariable) {
        final start = const WritersideEditingAdapter().xmlTextSourceOffset(
          document,
          block,
          range.start,
          endBoundary: false,
        );
        final finish = const WritersideEditingAdapter().xmlTextSourceOffset(
          document,
          block,
          range.end,
          endBoundary: true,
        );
        final fragment = '%${range.attributes['reference']}%';
        if (start != null &&
            finish != null &&
            start > 0 &&
            finish < source.length &&
            source.substring(start - 1, finish + 1) == fragment) {
          begin = start - 1;
          end = finish + 1;
        }
      }
      if (begin != null && end != null) {
        yield (range: range, begin: begin, end: end);
      }
    }
  }

  static WritersideInspectorTarget fromSource({
    required String bufferId,
    required int revision,
    required String source,
    required BusyDocument document,
    required TextSelection selection,
  }) {
    document = busyMarkWysiwygBindMarkdownReferences(document);
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
      for (final entry in _authoredInlineRanges(document, source, block)) {
        if (start >= entry.begin &&
            start < entry.end &&
            selection.end <= entry.end) {
          inline = entry.range;
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
