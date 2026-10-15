import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../markdown/busymark_document.dart';
import '../../markdown/markdown_source_map.dart';
import '../../markdown/writerside_authoring_syntax.dart';
import 'wysiwyg_document_controller.dart';
import 'wysiwyg_inline_controller.dart';
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
    this.navigationEditable = true,
    this.unavailable = false,
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
  final bool navigationEditable;

  /// Once identity has been lost, ordinary revisions cannot revive this owner.
  /// Explicit inspection or a previously captured history owner must replace it.
  final bool unavailable;

  WritersideInspectorTarget markUnavailable() => WritersideInspectorTarget(
    bufferId: bufferId,
    revision: revision,
    source: source,
    authoredSource: authoredSource,
    document: document,
    block: block,
    path: path,
    inline: inline,
    multiple: multiple,
    logicalTopic: logicalTopic,
    navigationEditable: navigationEditable,
    unavailable: true,
  );
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
          if (!a.key.startsWith('busymark-') &&
              !{
                'xml-source-binding',
                'xml-original-source',
                'xml-original-signature',
              }.contains(a.key))
            a.key: a.value,
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
      block != null &&
          WritersideEditingAdapter.topicHeading(document)?.id == block!.id;
  bool matches(String? id, int? generation, String? text) =>
      !unavailable &&
      id == bufferId &&
      generation == revision &&
      source == text &&
      authoredSource == source;

  bool sameElement(WritersideInspectorTarget? current) =>
      current != null &&
      bufferId == current.bufferId &&
      revision == current.revision &&
      source == current.source &&
      unavailable == current.unavailable &&
      topic == current.topic &&
      multiple == current.multiple &&
      listEquals(address, current.address) &&
      inline?.kind == current.inline?.kind &&
      inline?.start == current.inline?.start &&
      inline?.end == current.inline?.end &&
      inline?.referenceIndex == current.inline?.referenceIndex;

  /// Revalidate an off-caret selection after a property-only model refresh.
  /// Ordinals alone are insufficient: removal, replacement or changed content
  /// must not bind the old inspected element to another authored node.
  WritersideInspectorTarget? refreshUnchangedElement({
    required int revision,
    required String source,
    required BusyDocument document,
  }) {
    if (unavailable ||
        document.filePath != this.document.filePath ||
        document.isXmlTopic != this.document.isXmlTopic ||
        document.mode != this.document.mode) {
      return null;
    }
    if (logicalTopic) {
      final refreshed = fromTopic(
        bufferId: bufferId,
        revision: revision,
        source: source,
        document: document,
      );
      return refreshed.matches(bufferId, revision, source) ? refreshed : null;
    }
    final before = block;
    if (before == null || document.source != source && !document.isXmlTopic) {
      return null;
    }
    final span = before.sourceSpan;
    if (span == null ||
        span.startOffset < 0 ||
        span.endOffset > this.source.length) {
      return null;
    }

    // Locate the retained authored interval through the actual source change.
    // Neither parser IDs nor sibling ordinals establish cross-revision identity.
    var prefix = 0;
    while (prefix < this.source.length &&
        prefix < source.length &&
        this.source[prefix] == source[prefix]) {
      prefix++;
    }
    var suffix = 0;
    while (suffix < this.source.length - prefix &&
        suffix < source.length - prefix &&
        this.source[this.source.length - suffix - 1] ==
            source[source.length - suffix - 1]) {
      suffix++;
    }
    final oldEnd = this.source.length - suffix;
    final delta = source.length - this.source.length;
    int? boundary(int offset, {bool end = false}) {
      if (end && offset == prefix && prefix == oldEnd) return offset + delta;
      if (offset <= prefix) return offset;
      if (offset >= oldEnd) return offset + delta;
      return null;
    }

    final changedInside =
        prefix >= span.startOffset && oldEnd <= span.endOffset;
    final start = boundary(span.startOffset);
    final stop = boundary(span.endOffset, end: true);
    if (start == null) return null;
    // Complete replacement is ambiguous even when a new node has the same tag.
    if (prefix <= span.startOffset &&
        oldEnd >= span.endOffset &&
        this.source != source) {
      return null;
    }
    Iterable<BusyBlock> walk(List<BusyBlock> blocks) sync* {
      for (final b in blocks) {
        yield b;
        yield* walk(b.children);
      }
    }

    if (before.rawSource != null) {
      bool sameOccurrence(BusyBlock b) =>
          b.kind == before.kind && b.rawSource == before.rawSource;
      final oldCopies = walk(this.document.blocks).where(sameOccurrence).length;
      final newCopies = walk(document.blocks).where(sameOccurrence).length;
      if (oldCopies != newCopies &&
          (oldCopies > 1 || newCopies > 1) &&
          (this.source.substring(prefix, oldEnd).trim().isEmpty ||
              source
                  .substring(prefix, source.length - suffix)
                  .trim()
                  .isEmpty)) {
        return null;
      }
    }
    bool metadataTail(BusyBlock candidate) {
      if (document.isXmlTopic ||
          before.plainText != candidate.plainText ||
          !(before.attributes.containsKey(
                'busymark-writerside-source-attributes',
              ) ||
              candidate.attributes.containsKey(
                'busymark-writerside-source-attributes',
              ))) {
        return false;
      }
      int? coreEnd(BusyBlock owner) {
        if (!owner.attributes.containsKey(
          'busymark-writerside-source-attributes',
        )) {
          return owner.sourceSpan?.endOffset;
        }
        final raw = owner.rawSource;
        if (raw == null) return null;
        final token = WritersideAttributeSyntax().pattern
            .allMatches(raw)
            .where((m) => raw.substring(m.end).trim().isEmpty)
            .lastOrNull;
        return token == null
            ? null
            : markdownProjectedSourceOffset(owner, token.start);
      }

      final oldCoreEnd = coreEnd(before);
      final newCoreEnd = coreEnd(candidate);
      if (oldCoreEnd == null ||
          newCoreEnd == null ||
          prefix < oldCoreEnd ||
          prefix < newCoreEnd ||
          this.source.substring(span.startOffset, oldCoreEnd).trimRight() !=
              source
                  .substring(candidate.sourceSpan!.startOffset, newCoreEnd)
                  .trimRight()) {
        return false;
      }
      final end = candidate.sourceSpan!.endOffset;
      // Attribute-line attachment can change whether a trailing newline belongs
      // to the block span. The retained body and all changed bytes must still
      // belong to this parser-confirmed owner's tail, with only whitespace past it.
      final newEnd = source.length - suffix;
      return (oldEnd <= span.endOffset ||
              this.source.substring(span.endOffset, oldEnd).trim().isEmpty) &&
          (newEnd <= end || source.substring(end, newEnd).trim().isEmpty);
    }

    final candidates = walk(document.blocks)
        .where(
          (b) =>
              (b.sourceSpan?.startOffset == start ||
                  prefix == oldEnd &&
                      prefix == span.startOffset &&
                      b.sourceSpan?.startOffset == start + delta &&
                      stop != null &&
                      source.substring(start + delta, stop) ==
                          this.source.substring(
                            span.startOffset,
                            span.endOffset,
                          )) &&
              (b.sourceSpan?.endOffset == stop ||
                  metadataTail(b) ||
                  // An inserted sibling can start exactly after a closed XML
                  // element. Its original interval is still intact; do not
                  // extend that owner's boundary into the new sibling.
                  prefix == oldEnd &&
                      prefix == span.endOffset &&
                      b.sourceSpan?.endOffset == span.endOffset &&
                      source.substring(start, span.endOffset) ==
                          this.source.substring(
                            span.startOffset,
                            span.endOffset,
                          )) &&
              b.kind == before.kind &&
              WritersideEditingAdapter.tagForBlock(b) ==
                  WritersideEditingAdapter.tagForBlock(before),
        )
        .toList();
    if (candidates.length != 1) return null;
    final candidate = candidates.single;
    if (!changedInside &&
        !metadataTail(candidate) &&
        this.source != source &&
        this.source.substring(span.startOffset, span.endOffset) !=
            source.substring(start, stop ?? candidate.sourceSpan!.endOffset)) {
      return null;
    }
    // Protected fragments are never rebound through a content change.
    if ((before.isSourceProtected || before.preserveRaw) &&
        before.rawSource != candidate.rawSource) {
      return null;
    }
    BusyInlineStyleRange? refreshedInline;
    if (inline != null) {
      final occurrence =
          WritersideEditingAdapter.authoredInlineRanges(
                this.document,
                this.source,
                before,
              )
              .where(
                (e) =>
                    e.range.kind == inline!.kind &&
                    e.range.start == inline!.start &&
                    e.range.end == inline!.end &&
                    e.range.referenceIndex == inline!.referenceIndex,
              )
              .singleOrNull;
      if (occurrence == null) return null;
      final begin = boundary(occurrence.begin);
      final end = boundary(occurrence.end, end: true);
      if (begin == null ||
          end == null ||
          prefix <= occurrence.begin &&
              oldEnd >= occurrence.end &&
              this.source != source) {
        return null;
      }
      refreshedInline =
          WritersideEditingAdapter.authoredInlineRanges(
                document,
                source,
                candidate,
              )
              .where(
                (e) =>
                    e.begin == begin &&
                    e.end == end &&
                    e.range.kind == inline!.kind,
              )
              .singleOrNull
              ?.range;
      if (refreshedInline == null) return null;
    }
    final refreshed = fromSelection(
      bufferId: bufferId,
      revision: revision,
      source: source,
      document: document,
      blockId: candidate.id,
      inline: refreshedInline,
      multiple: multiple,
    );
    return refreshed.matches(bufferId, revision, source) ? refreshed : null;
  }

  static WritersideInspectorTarget fromTopic({
    required String bufferId,
    required int revision,
    required String source,
    required BusyDocument document,
  }) {
    final root = document.isXmlTopic
        ? document.blocks
              .where((b) => b.attributes['element'] == 'topic')
              .firstOrNull
        : WritersideEditingAdapter.topicHeading(document);
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
      navigationEditable: selected.navigationEditable,
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
        navigationEditable: WritersideEditingAdapter.topicNavigationEditable(
          document,
        ),
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
    return WritersideEditingAdapter.authoredInlineRanges(
          document,
          source,
          block!,
        )
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
      for (final entry in WritersideEditingAdapter.authoredInlineRanges(
        document,
        source,
        block,
      )) {
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
