import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueChanged, visibleForTesting;
import 'package:flutter/services.dart';

import '../../markdown/busymark_document.dart';
import '../../markdown/busymark_markdown_serializer.dart';
import '../../markdown/markdown_model.dart';
import '../../markdown/markdown_parser.dart';
import '../../markdown/markdown_source_map.dart';
import '../../markdown/markdown_source_structure.dart';
import '../inline_semantics.dart';
import '../wysiwyg/wysiwyg_clipboard_fragment.dart';

enum SourceDocumentFormat {
  markdown,
  writersideXmlTopic,
  genericXml,
  plainText,
}

@visibleForTesting
ValueChanged<int>? debugBusyMarkSourceInlineMappingParseCount;

class SourcePasteDocumentSnapshot {
  const SourcePasteDocumentSnapshot({
    required this.expectedSource,
    required this.selection,
    required this.format,
    required this.markdownMode,
    required this.filePath,
  });

  final String expectedSource;
  final TextSelection selection;
  final SourceDocumentFormat format;
  final MarkdownMode markdownMode;
  final String? filePath;

  String get text => expectedSource;
}

sealed class SourcePastePreparation {
  const SourcePastePreparation();
}

class SourcePasteReady extends SourcePastePreparation {
  const SourcePasteReady(this.edit);

  final SourcePasteEdit edit;
}

class SourcePasteTryNext extends SourcePastePreparation {
  const SourcePasteTryNext();
}

class SourcePasteStop extends SourcePastePreparation {
  const SourcePasteStop();
}

class SourcePasteEdit {
  const SourcePasteEdit({
    required this.expectedSource,
    required this.start,
    required this.end,
    required this.replacement,
    required this.caretOffset,
  });

  final String expectedSource;
  final int start;
  final int end;
  final String replacement;
  final int caretOffset;
}

class SourcePasteEngine {
  const SourcePasteEngine();

  SourcePastePreparation prepareStructured({
    required SourcePasteDocumentSnapshot target,
    required WysiwygClipboardFragment fragment,
  }) {
    final insertion = _serializeStructuredClipboardInsertion(target, fragment);
    if (insertion == null) return const SourcePasteTryNext();
    if (insertion is _SourceTerminalPlan) return const SourcePasteStop();
    final edit = insertion as _SourceEditPlan;
    return SourcePasteReady(
      SourcePasteEdit(
        expectedSource: target.expectedSource,
        start: edit.start,
        end: edit.end,
        replacement: edit.text,
        caretOffset: edit.caretOffset ?? edit.start + edit.text.length,
      ),
    );
  }

  _SourcePlan? _serializeStructuredClipboardInsertion(
    SourcePasteDocumentSnapshot target,
    WysiwygClipboardFragment fragment,
  ) {
    final context = _structuredSourceInsertionContext(target);
    if (context.sourceProtected || context.unsafeStructuredContainer) {
      return null;
    }
    if (context.tableCell) {
      final inlines = fragment.sourceInsertionInlinesFor(tableCell: true);
      if (context.inlineMappingFailed) {
        return _reconcileIncompleteSyntaxBoundary(target, context, inlines);
      }
      final serialized = const BusyMarkMarkdownSerializer()
          .serializeInlineFragment(
            inlines,
            tableCell: true,
            atBlockStart: context.atBlockStart,
            readableHardBreakRuns: false,
          );
      if (serialized.isEmpty) return null;
      return _reconcileStructuredInlineInsertion(
        target,
        context,
        inlines,
        serialized,
      );
    }
    if (fragment.isInlineSourceFragment) {
      final inlines = fragment.sourceInsertionInlinesFor(tableCell: false);
      if (context.inlineMappingFailed) {
        return _reconcileIncompleteSyntaxBoundary(target, context, inlines);
      }
      final serialized = const BusyMarkMarkdownSerializer()
          .serializeInlineFragment(
            inlines,
            atBlockStart: context.atBlockStart,
            readableHardBreakRuns: true,
          );
      if (serialized.isEmpty) return null;
      return _reconcileStructuredInlineInsertion(
        target,
        context,
        inlines,
        serialized,
      );
    }
    final serialized = fragment.serializeFor(
      destinationMode: target.markdownMode,
      destinationFilePath: target.filePath ?? '',
    );
    if (serialized.isEmpty) return null;
    final before = target.text.substring(0, context.start);
    final after = target.text.substring(context.end);
    if (context.containerContinuationPrefix.isNotEmpty) {
      final lines = serialized.endsWith('\n')
          ? serialized.substring(0, serialized.length - 1).split('\n')
          : serialized.split('\n');
      final nested = [
        for (var index = 0; index < lines.length; index++)
          if (!context.hasContainerContentBefore &&
              !context.taskItemAtContentStart &&
              index == 0)
            lines[index]
          else if (lines[index].isEmpty)
            context.containerBlankPrefix
          else
            '${context.containerContinuationPrefix}${lines[index]}',
      ].join('\n');
      final beforeBoundary =
          context.hasContainerContentBefore || context.taskItemAtContentStart
          ? '\n${context.containerBlankPrefix}\n'
          : '';
      final afterBoundary = context.hasContainerContentAfter
          ? '\n${context.containerBlankPrefix}\n${context.containerContinuationPrefix}'
          : '';
      return _SourceEditPlan(
        start: context.start,
        end: context.end,
        text: '$beforeBoundary$nested$afterBoundary',
      );
    }
    final leadingBreaks = _leadingLineBreaks(serialized);
    final trailingBreaks = _trailingLineBreaks(serialized);
    final prefix = before.isEmpty
        ? ''
        : '\n' * math.max(0, 2 - _trailingLineBreaks(before) - leadingBreaks);
    final suffix = after.isEmpty
        ? ''
        : '\n' * math.max(0, 2 - trailingBreaks - _leadingLineBreaks(after));
    return _SourceEditPlan(
      start: context.start,
      end: context.end,
      text: '$prefix$serialized$suffix',
    );
  }

  _SourceEditPlan? _reconcileIncompleteSyntaxBoundary(
    SourcePasteDocumentSnapshot target,
    _StructuredSourceInsertionContext context,
    List<BusyInline> incoming,
  ) {
    final destination = context.inlineContext;
    final singleIncoming = incoming.length == 1 ? incoming.single : null;
    if (destination == null ||
        context.start != context.end ||
        singleIncoming == null) {
      return null;
    }
    final adjacent = _adjacentEquivalentInlineRuns(
      target.text,
      context.start,
      singleIncoming,
      destination,
    );
    if (adjacent == null) return null;
    final innerSource = _serializeSourceInlineSequence(
      _removeEquivalentInlineContexts(incoming, [singleIncoming]),
      context,
    );
    return _SourceEditPlan(
      start: adjacent.leftClosingRange.start,
      end: adjacent.rightOpeningRange.end,
      text: innerSource,
      caretOffset: adjacent.leftClosingRange.start + innerSource.length,
    );
  }

  _SourcePlan _reconcileStructuredInlineInsertion(
    SourcePasteDocumentSnapshot target,
    _StructuredSourceInsertionContext context,
    List<BusyInline> incoming,
    String serialized,
  ) {
    final destination = context.inlineContext;
    if (destination != null) {
      final activeContexts = destination.commonAncestors
          .where((inline) => busyMarkIsInheritedInlineContext(inline.kind))
          .toList(growable: false);
      final destinationLinkIndex = activeContexts.indexWhere(
        (inline) => inline.kind == BusyInlineKind.link,
      );
      if (destinationLinkIndex >= 0 &&
          (destination
                      .wrapperFor(activeContexts[destinationLinkIndex])
                      ?.isAutolink ==
                  true ||
              destination
                      .wrapperFor(activeContexts[destinationLinkIndex])
                      ?.isReference ==
                  true ||
              _containsDifferentLink(
                incoming,
                activeContexts[destinationLinkIndex],
              ))) {
        final expanded = _replaceMappedDestinationLink(
          context,
          destination,
          incoming,
          activeContexts[destinationLinkIndex],
        );
        return expanded ?? const _SourceTerminalPlan();
      }
      if (context.tableCell &&
          activeContexts.isNotEmpty &&
          !_allInlinesCarryContexts(incoming, activeContexts)) {
        final expanded = _replaceMappedInlineContext(
          context,
          destination,
          incoming,
        );
        if (expanded != null) return expanded;
      }
      final reconciled = _removeEquivalentInlineContexts(
        incoming,
        activeContexts,
      );
      final reconciledSource = _serializeSourceInlineSequence(
        reconciled,
        context,
      );
      final singleIncoming = incoming.length == 1 ? incoming.single : null;
      final adjacent = context.start == context.end && singleIncoming != null
          ? _adjacentEquivalentInlineRuns(
              target.text,
              context.start,
              singleIncoming,
              destination,
            )
          : null;
      // Joining three semantically adjacent equivalent runs is local and
      // retains the authored delimiter choice on the destination runs.
      if (adjacent != null) {
        final innerSource = _serializeSourceInlineSequence(
          _removeEquivalentInlineContexts(incoming, [singleIncoming!]),
          context,
        );
        return _SourceEditPlan(
          start: adjacent.leftClosingRange.start,
          end: adjacent.rightOpeningRange.end,
          text: innerSource,
          caretOffset: adjacent.leftClosingRange.start + innerSource.length,
        );
      }
      return _SourceEditPlan(
        start: context.start,
        end: context.end,
        text: reconciledSource,
        caretOffset: context.start + reconciledSource.length,
      );
    }
    return _SourceEditPlan(
      start: context.start,
      end: context.end,
      text: serialized,
      caretOffset: context.start + serialized.length,
    );
  }

  String _serializeSourceInlineSequence(
    List<BusyInline> inlines,
    _StructuredSourceInsertionContext context,
  ) => const BusyMarkMarkdownSerializer().serializeInlineFragment(
    inlines,
    tableCell: context.tableCell,
    atBlockStart: context.atBlockStart,
    readableHardBreakRuns: !context.tableCell,
  );

  bool _containsDifferentLink(
    List<BusyInline> inlines,
    BusyInline destination,
  ) {
    for (final inline in inlines) {
      if (inline.kind == BusyInlineKind.link &&
          !busyMarkSameInlineSemantics(inline, destination)) {
        return true;
      }
      if (_containsDifferentLink(inline.children, destination)) return true;
    }
    return false;
  }

  bool _containsSourceInlineKind(
    List<BusyInline> inlines,
    BusyInlineKind kind,
  ) {
    for (final inline in inlines) {
      if (inline.kind == kind ||
          _containsSourceInlineKind(inline.children, kind)) {
        return true;
      }
    }
    return false;
  }

  bool _allInlinesCarryContexts(
    List<BusyInline> inlines,
    List<BusyInline> contexts,
  ) {
    var sawContent = false;
    var covered = true;
    void visit(BusyInline inline, List<BusyInline> inherited) {
      final active = busyMarkIsInheritedInlineContext(inline.kind)
          ? [...inherited, inline]
          : inherited;
      if (inline.children.isEmpty) {
        if (inline.plainText.isEmpty) return;
        sawContent = true;
        if (!contexts.every(
          (context) => active.any(
            (candidate) => busyMarkSameInlineSemantics(candidate, context),
          ),
        )) {
          covered = false;
        }
        return;
      }
      for (final child in inline.children) {
        visit(child, active);
      }
    }

    for (final inline in inlines) {
      visit(inline, const []);
    }
    return sawContent && covered;
  }

  List<BusyInline> _removeEquivalentInlineContexts(
    List<BusyInline> inlines,
    List<BusyInline> contexts, [
    _SourceInlineOccurrenceAnnotations? annotations,
  ]) {
    List<BusyInline> transform(BusyInline inline) {
      final children = inline.children.isEmpty
          ? <BusyInline>[
              if (inline.text.isNotEmpty)
                BusyInline(kind: BusyInlineKind.text, text: inline.text),
            ]
          : [for (final child in inline.children) ...transform(child)];
      if (busyMarkIsInheritedInlineContext(inline.kind) &&
          contexts.any(
            (context) => busyMarkSameInlineSemantics(context, inline),
          )) {
        return children;
      }
      final rebuilt = inline.copyWith(
        text: children.isEmpty
            ? inline.text
            : children.map((child) => child.plainText).join(),
        children: inline.children.isEmpty ? inline.children : children,
      );
      return [annotations?.copyAnnotation(inline, rebuilt) ?? rebuilt];
    }

    return [for (final inline in inlines) ...transform(inline)];
  }

  List<BusyInline> _applySourceInlineContexts(
    List<BusyInline> inlines,
    List<BusyInline> contexts,
    Set<BusyInline> rawHtmlSourceInlines,
    _SourceInlineOccurrenceAnnotations annotations,
  ) {
    var result = inlines;
    for (final wrapper in contexts.reversed) {
      if (wrapper.kind == BusyInlineKind.link &&
          _containsSourceInlineKind(result, BusyInlineKind.link)) {
        continue;
      }
      if (result.length == 1 &&
          busyMarkSameInlineSemantics(wrapper, result.single)) {
        continue;
      }
      if (wrapper.kind == BusyInlineKind.underline &&
          _containsSourceInlineKind(result, BusyInlineKind.link)) {
        BusyInline applyInsideLinks(BusyInline inline) {
          if (inline.kind == BusyInlineKind.link) {
            final wrapped = annotations.copyAnnotation(
              wrapper,
              wrapper.copyWith(
                text: inline.plainText,
                children: inline.children,
              ),
              rawHtml: rawHtmlSourceInlines.contains(wrapper),
            );
            return annotations.copyAnnotation(
              inline,
              inline.copyWith(children: [wrapped]),
            );
          }
          if (inline.children.isNotEmpty) {
            return annotations.copyAnnotation(
              inline,
              inline.copyWith(
                children: [
                  for (final child in inline.children) applyInsideLinks(child),
                ],
              ),
            );
          }
          return annotations.copyAnnotation(
            wrapper,
            wrapper.copyWith(text: inline.plainText, children: [inline]),
            rawHtml: rawHtmlSourceInlines.contains(wrapper),
          );
        }

        result = [for (final inline in result) applyInsideLinks(inline)];
        continue;
      }
      result = [
        annotations.copyAnnotation(
          wrapper,
          wrapper.copyWith(
            text: result.map((inline) => inline.plainText).join(),
            children: result,
          ),
          rawHtml: rawHtmlSourceInlines.contains(wrapper),
        ),
      ];
    }
    return result;
  }

  _SourceEditPlan? _replaceMappedInlineContext(
    _StructuredSourceInsertionContext context,
    _MappedSourceInlineContext destination,
    List<BusyInline> incoming,
  ) {
    final outermost = destination.commonAncestors
        .where((inline) => busyMarkIsInheritedInlineContext(inline.kind))
        .firstOrNull;
    if (outermost == null) return null;
    final mapped = destination.wrapperFor(outermost);
    if (mapped == null) return null;
    final annotations = _SourceInlineOccurrenceAnnotations();
    final partition = _partitionMappedInline(
      mapped.inline,
      destination.startMarker,
      destination.endMarker,
      rawHtmlSourceInlines: _rawHtmlSourceInlines(destination),
      annotations: annotations,
    );
    if (partition == null) return null;
    return _serializeMappedInlineReplacement(
      context,
      mapped.sourceRange,
      partition.before,
      incoming,
      partition.after,
      authoredWrapper: mapped,
      annotations: annotations,
    );
  }

  _SourceEditPlan? _replaceMappedDestinationLink(
    _StructuredSourceInsertionContext context,
    _MappedSourceInlineContext destination,
    List<BusyInline> incoming,
    BusyInline destinationLink,
  ) {
    final mapped = destination.wrapperFor(destinationLink);
    if (mapped == null) return null;
    final rawHtmlSourceInlines = _rawHtmlSourceInlines(destination);
    final annotations = _SourceInlineOccurrenceAnnotations();
    final partition = _partitionMappedInline(
      mapped.inline,
      destination.startMarker,
      destination.endMarker,
      rawHtmlSourceInlines: rawHtmlSourceInlines,
      annotations: annotations,
    );
    if (partition == null) return null;
    final linkIndex = destination.commonAncestors.indexWhere(
      (inline) => identical(inline, destinationLink),
    );
    if (linkIndex < 0) return null;
    final outerContexts = destination.commonAncestors
        .take(linkIndex)
        .where((inline) => busyMarkIsInheritedInlineContext(inline.kind))
        .toList(growable: false);
    final innerContexts = destination.commonAncestors
        .skip(linkIndex + 1)
        .where((inline) => busyMarkIsInheritedInlineContext(inline.kind))
        .toList(growable: false);
    final adjustedIncoming = _removeEquivalentInlineContexts(
      _applySourceInlineContexts(
        incoming,
        innerContexts,
        rawHtmlSourceInlines,
        annotations,
      ),
      outerContexts,
      annotations,
    );
    return _serializeMappedInlineReplacement(
      context,
      mapped.sourceRange,
      partition.before,
      adjustedIncoming,
      partition.after,
      authoredWrapper: mapped,
      annotations: annotations,
    );
  }

  Set<BusyInline> _rawHtmlSourceInlines(
    _MappedSourceInlineContext destination,
  ) {
    final result = Set<BusyInline>.identity();
    for (final wrapper in destination.wrappers) {
      if (wrapper.opening?.trimLeft().startsWith('<') ?? false) {
        result.add(wrapper.inline);
      }
    }
    return result;
  }

  _SourceEditPlan _serializeMappedInlineReplacement(
    _StructuredSourceInsertionContext context,
    TextRange sourceRange,
    List<BusyInline> before,
    List<BusyInline> incoming,
    List<BusyInline> after, {
    _MappedSourceInlineWrapper? authoredWrapper,
    required _SourceInlineOccurrenceAnnotations annotations,
  }) {
    final caretTextOffset = [
      ...before,
      ...incoming,
    ].fold<int>(0, (length, inline) => length + inline.plainText.length);
    final retainedLineBreaks = <BusyMarkMappedSourceLineBreak>[];
    final mappedText = authoredWrapper?.inline.plainText;
    final inlineContext = context.inlineContext;
    if (authoredWrapper != null &&
        mappedText != null &&
        inlineContext != null) {
      final markerStart = mappedText.indexOf(inlineContext.startMarker);
      final markerEnd = inlineContext.endMarker == null
          ? markerStart + inlineContext.startMarker.length
          : mappedText.indexOf(
                  inlineContext.endMarker!,
                  markerStart + inlineContext.startMarker.length,
                ) +
                inlineContext.endMarker!.length;
      if (markerStart >= 0 && markerEnd >= markerStart) {
        final beforeLength = before.fold<int>(
          0,
          (length, inline) => length + inline.plainText.length,
        );
        final incomingLength = incoming.fold<int>(
          0,
          (length, inline) => length + inline.plainText.length,
        );
        for (final lineBreak in authoredWrapper.lineBreaks) {
          if (lineBreak.textOffset < markerStart) {
            retainedLineBreaks.add(lineBreak);
          } else if (lineBreak.textOffset >= markerEnd) {
            retainedLineBreaks.add(
              BusyMarkMappedSourceLineBreak(
                textOffset:
                    beforeLength +
                    incomingLength +
                    lineBreak.textOffset -
                    markerEnd,
                lineEnding: lineBreak.lineEnding,
                continuationPrefix: lineBreak.continuationPrefix,
                sourceOffset: lineBreak.sourceOffset,
              ),
            );
          }
        }
      }
    }
    final merged = _stabilizeMappedWrapperWhitespace(
      _mergeAdjacentSourceInlineStyles([
        ...before,
        ...incoming,
        ...after,
      ], annotations),
      annotations,
    );
    final lineBreakOffsets = {
      for (final lineBreak in retainedLineBreaks)
        lineBreak: BusyMarkInlineLineBreakOffset(
          textOffset: lineBreak.textOffset,
        ),
    };
    final serialized = _serializeMappedInlineSequence(
      merged,
      caretTextOffset,
      context,
      authoredWrapper,
      lineBreakOffsets.values,
    );
    final serializedLineBreaks = [
      for (final entry in lineBreakOffsets.entries)
        if (serialized.lineBreakSourceOffsets[entry.value] case final offset?)
          _SerializedMappedSourceLineBreak(
            sourceOffset: offset,
            lineBreak: entry.key,
          ),
    ];
    final restored = _restoreMappedSourceLineBreaks(
      serialized,
      serializedLineBreaks,
      context.containerContinuationPrefix,
      context.lineEnding,
    );
    return _SourceEditPlan(
      start: sourceRange.start,
      end: sourceRange.end,
      text: restored.source,
      caretOffset: sourceRange.start + restored.sourceOffset,
    );
  }

  BusyMarkSerializedInlineFragment _restoreMappedSourceLineBreaks(
    BusyMarkSerializedInlineFragment serialized,
    List<_SerializedMappedSourceLineBreak> lineBreaks,
    String fallbackPrefix,
    String fallbackLineEnding,
  ) {
    if (!serialized.source.contains('\n')) return serialized;
    final source = StringBuffer();
    var sourceOffset = serialized.sourceOffset;
    final lineBreaksByOffset = {
      for (final lineBreak in lineBreaks) lineBreak.sourceOffset: lineBreak,
    };
    for (var index = 0; index < serialized.source.length; index++) {
      final character = serialized.source[index];
      if (character != '\n') {
        source.write(character);
        continue;
      }
      final mapped = lineBreaksByOffset[index]?.lineBreak;
      final lineEnding = mapped?.lineEnding ?? fallbackLineEnding;
      final prefix = mapped?.continuationPrefix ?? fallbackPrefix;
      source.write(lineEnding);
      source.write(prefix);
      if (index < serialized.sourceOffset) {
        sourceOffset += lineEnding.length - 1 + prefix.length;
      }
    }
    return BusyMarkSerializedInlineFragment(
      source: source.toString(),
      sourceOffset: sourceOffset,
    );
  }

  BusyMarkSerializedInlineFragment _serializeMappedInlineSequence(
    List<BusyInline> inlines,
    int caretTextOffset,
    _StructuredSourceInsertionContext context,
    _MappedSourceInlineWrapper? authoredWrapper, [
    Iterable<BusyMarkInlineLineBreakOffset> lineBreakOffsets = const [],
  ]) {
    final opening = authoredWrapper?.opening;
    final closing = authoredWrapper?.closing;
    return const BusyMarkMarkdownSerializer()
        .serializeInlineFragmentWithOffsets(
          inlines,
          textOffset: caretTextOffset,
          lineBreakOffsets: lineBreakOffsets,
          tableCell: context.tableCell,
          atBlockStart: context.atBlockStart,
          readableHardBreakRuns: !context.tableCell,
          delimiterOverrides: opening == null || closing == null
              ? const {}
              : {
                  authoredWrapper!.inline.kind: BusyMarkInlineDelimiter(
                    opening: opening,
                    closing: closing,
                  ),
                },
        );
  }

  List<BusyInline> _mergeAdjacentSourceInlineStyles(
    List<BusyInline> inlines,
    _SourceInlineOccurrenceAnnotations annotations,
  ) {
    final merged = <BusyInline>[];
    for (final sourceInline in inlines) {
      final inline = sourceInline.children.isEmpty
          ? sourceInline
          : annotations.copyAnnotation(
              sourceInline,
              sourceInline.copyWith(
                children: _mergeAdjacentSourceInlineStyles(
                  sourceInline.children,
                  annotations,
                ),
              ),
            );
      final previous = merged.lastOrNull;
      if (previous == null ||
          !busyMarkSameInlineSemantics(previous, inline) ||
          (inline.kind != BusyInlineKind.text &&
              (!busyMarkIsInheritedInlineContext(inline.kind) ||
                  previous.children.isEmpty ||
                  inline.children.isEmpty))) {
        merged.add(inline);
        continue;
      }
      merged.removeLast();
      if (inline.kind == BusyInlineKind.text) {
        merged.add(
          annotations.copyAnnotations([
            previous,
            inline,
          ], previous.copyWith(text: previous.text + inline.text)),
        );
      } else {
        final children = _mergeAdjacentSourceInlineStyles([
          ...previous.children,
          ...inline.children,
        ], annotations);
        merged.add(
          annotations.copyAnnotations(
            [previous, inline],
            previous.copyWith(
              text: children.map((child) => child.plainText).join(),
              children: children,
            ),
          ),
        );
      }
    }
    return merged;
  }

  /// Raw-HTML conversion can trim whitespace at a styled element or link edge.
  /// When mapped paste splits such a wrapper at that edge, hoist the whitespace
  /// outside the affected delimiter so its text semantics survive the
  /// serializer/reparse round trip.
  List<BusyInline> _stabilizeMappedWrapperWhitespace(
    List<BusyInline> inlines,
    _SourceInlineOccurrenceAnnotations annotations,
  ) {
    final result = <BusyInline>[];
    for (final inline in inlines) {
      if (inline.children.isEmpty) {
        result.add(inline);
        continue;
      }
      final containsRawHtmlWrapper = _containsMappedRawHtmlInline(
        inline.children,
        annotations,
      );
      final children = _stabilizeMappedWrapperWhitespace(
        inline.children,
        annotations,
      );
      final rebuilt = annotations.copyAnnotation(
        inline,
        inline.copyWith(
          text: children.map((child) => child.plainText).join(),
          children: children,
        ),
      );
      final rawHtmlStyle = annotations.isRawHtml(inline);
      final containingInheritedContext =
          busyMarkIsInheritedInlineContext(inline.kind) &&
          containsRawHtmlWrapper;
      if (!rawHtmlStyle && !containingInheritedContext) {
        result.add(rebuilt);
        continue;
      }

      final leading = children.firstOrNull?.kind == BusyInlineKind.text
          ? RegExp(r'^\s+').firstMatch(children.first.text)?.group(0) ?? ''
          : '';
      final core = [...children];
      if (leading.isNotEmpty) {
        final first = core.first;
        core[0] = first.copyWith(text: first.text.substring(leading.length));
      }
      final trailing = core.lastOrNull?.kind == BusyInlineKind.text
          ? RegExp(r'\s+$').firstMatch(core.last.text)?.group(0) ?? ''
          : '';
      if (leading.isEmpty && trailing.isEmpty) {
        result.add(rebuilt);
        continue;
      }
      if (trailing.isNotEmpty) {
        final last = core.last;
        core[core.length - 1] = last.copyWith(
          text: last.text.substring(0, last.text.length - trailing.length),
        );
      }
      core.removeWhere(
        (child) => child.kind == BusyInlineKind.text && child.plainText.isEmpty,
      );
      if (leading.isNotEmpty) {
        result.add(BusyInline(kind: BusyInlineKind.text, text: leading));
      }
      if (core.isNotEmpty) {
        result.add(
          rebuilt.copyWith(
            text: core.map((child) => child.plainText).join(),
            children: core,
          ),
        );
      }
      if (trailing.isNotEmpty) {
        result.add(BusyInline(kind: BusyInlineKind.text, text: trailing));
      }
    }
    return result;
  }

  bool _containsMappedRawHtmlInline(
    List<BusyInline> inlines,
    _SourceInlineOccurrenceAnnotations annotations,
  ) {
    for (final inline in inlines) {
      if (annotations.isRawHtml(inline) ||
          _containsMappedRawHtmlInline(inline.children, annotations)) {
        return true;
      }
    }
    return false;
  }

  ({List<BusyInline> before, List<BusyInline> after})? _partitionMappedInline(
    BusyInline inline,
    String startMarker,
    String? endMarker, {
    required Set<BusyInline> rawHtmlSourceInlines,
    required _SourceInlineOccurrenceAnnotations annotations,
  }) {
    final text = inline.plainText;
    final start = text.indexOf(startMarker);
    if (start < 0) return null;
    final end = endMarker == null
        ? start + startMarker.length
        : text.indexOf(endMarker, start + startMarker.length) +
              endMarker.length;
    if (end < start + startMarker.length) return null;
    final partition = _partitionSourceInline(
      inline,
      start,
      end,
      rawHtmlSourceInlines,
      annotations,
    );
    return (
      before: [if (partition.before case final before?) before],
      after: [if (partition.after case final after?) after],
    );
  }

  ({List<BusyInline> before, List<BusyInline> after}) _partitionSourceInlines(
    List<BusyInline> inlines,
    int start,
    int end,
    Set<BusyInline> rawHtmlSourceInlines,
    _SourceInlineOccurrenceAnnotations annotations,
  ) {
    final before = <BusyInline>[];
    final after = <BusyInline>[];
    var offset = 0;
    for (final inline in inlines) {
      final length = inline.plainText.length;
      final inlineEnd = offset + length;
      if (inlineEnd <= start) {
        before.add(inline);
      } else if (offset >= end) {
        after.add(inline);
      } else {
        final partition = _partitionSourceInline(
          inline,
          (start - offset).clamp(0, length).toInt(),
          (end - offset).clamp(0, length).toInt(),
          rawHtmlSourceInlines,
          annotations,
        );
        if (partition.before != null) before.add(partition.before!);
        if (partition.after != null) after.add(partition.after!);
      }
      offset = inlineEnd;
    }
    return (before: before, after: after);
  }

  ({BusyInline? before, BusyInline? after}) _partitionSourceInline(
    BusyInline inline,
    int start,
    int end,
    Set<BusyInline> rawHtmlSourceInlines,
    _SourceInlineOccurrenceAnnotations annotations,
  ) {
    final length = inline.plainText.length;
    if (inline.children.isNotEmpty) {
      final partition = _partitionSourceInlines(
        inline.children,
        start,
        end,
        rawHtmlSourceInlines,
        annotations,
      );
      final before = partition.before.isEmpty
          ? null
          : inline.copyWith(
              text: partition.before.map((child) => child.plainText).join(),
              children: partition.before,
            );
      final after = partition.after.isEmpty
          ? null
          : inline.copyWith(
              text: partition.after.map((child) => child.plainText).join(),
              children: partition.after,
            );
      if (rawHtmlSourceInlines.contains(inline)) {
        if (before != null) annotations.markRawHtml(before);
        if (after != null) annotations.markRawHtml(after);
      }
      return (before: before, after: after);
    }
    return (
      before: start == 0
          ? null
          : inline.copyWith(text: inline.text.substring(0, start)),
      after: end == length
          ? null
          : inline.copyWith(text: inline.text.substring(end)),
    );
  }

  _MappedAdjacentInlineRuns? _adjacentEquivalentInlineRuns(
    String source,
    int offset,
    BusyInline incoming,
    _MappedSourceInlineContext destination,
  ) {
    final previous = destination.previousSibling;
    final next = destination.nextSibling;
    if (previous == null ||
        next == null ||
        !busyMarkSameInlineSemantics(previous, incoming) ||
        !busyMarkSameInlineSemantics(next, incoming)) {
      return null;
    }
    final delimiters = switch (incoming.kind) {
      BusyInlineKind.strong => const ['**', '__'],
      BusyInlineKind.emphasis => const ['*', '_'],
      BusyInlineKind.strikethrough => const ['~~'],
      _ => const <String>[],
    };
    for (final delimiter in delimiters) {
      if (offset >= delimiter.length &&
          offset + delimiter.length <= source.length &&
          source.substring(offset - delimiter.length, offset) == delimiter &&
          source.substring(offset, offset + delimiter.length) == delimiter) {
        return _MappedAdjacentInlineRuns(
          leftClosingRange: TextRange(
            start: offset - delimiter.length,
            end: offset,
          ),
          rightOpeningRange: TextRange(
            start: offset,
            end: offset + delimiter.length,
          ),
        );
      }
    }
    return null;
  }

  _StructuredSourceInsertionContext _structuredSourceInsertionContext(
    SourcePasteDocumentSnapshot target,
  ) {
    final selection = target.selection.isValid
        ? target.selection
        : TextSelection.collapsed(offset: target.text.length);
    final start = math
        .min(selection.start, selection.end)
        .clamp(0, target.text.length)
        .toInt();
    final end = math
        .max(selection.start, selection.end)
        .clamp(start, target.text.length)
        .toInt();
    if (target.format != SourceDocumentFormat.markdown) {
      return _StructuredSourceInsertionContext(start: start, end: end);
    }
    final marker = _sourceClipboardMarker(target.text);
    final markedSource = target.text.replaceRange(start, end, marker);
    final original = const MarkdownParser().parse(
      filePath: target.filePath ?? '',
      source: target.text,
      mode: target.markdownMode,
      validateLocalReferences: false,
    );
    final marked = const MarkdownParser().parse(
      filePath: target.filePath ?? '',
      source: markedSource,
      mode: target.markdownMode,
      validateLocalReferences: false,
    );
    final path = _sourceBlockPathContainingMarker(
      marked.busyDocument.blocks,
      marker,
    );
    final markerBlock = path?.lastOrNull;
    final markerOffset = markerBlock?.plainText.indexOf(marker);
    final sourceProtected =
        path == null ||
        path.any(
          (block) =>
              block.isSourceProtected ||
              block.preserveRaw ||
              block.kind == BusyBlockKind.codeBlock ||
              block.kind == BusyBlockKind.math ||
              block.kind == BusyBlockKind.htmlBlock ||
              block.kind == BusyBlockKind.writersideRawXml,
        );
    final survivingTable =
        path?.any((block) => block.kind == BusyBlockKind.table) ?? false;
    final originalCell = _singleTableCellContainingSelection(
      original.busyDocument.blocks,
      target.text,
      start,
      end,
    );
    final originalTable = _tableIntersectingSelection(
      original.busyDocument.blocks,
      start,
      end,
    );
    final partialTableSelection =
        originalTable != null &&
        !originalTable.coversWhole &&
        originalCell == null;
    final tableCell = survivingTable && originalCell != null;
    final unsafeStructuredContainer =
        partialTableSelection || (survivingTable && originalCell == null);
    final atBlockStart = markerOffset == null || markerOffset == 0;
    final prefixes = _sourceContainerPrefixes(markedSource, start, path ?? []);
    final inlineMappingRange = originalCell == null
        ? _sourceInlineMappingRange(
            original.busyDocument.blocks,
            target.text,
            start,
            end,
          )
        : TextRange(
            start: originalCell.span.startOffset,
            end: originalCell.span.endOffset,
          );
    final inlineMapping = _mappedSourceInlineContext(
      target,
      start,
      end,
      inlineMappingRange,
      inlineOnly: originalCell != null,
    );
    return _StructuredSourceInsertionContext(
      start: start,
      end: end,
      lineEnding: _sourceInsertionLineEnding(target.text, start),
      marker: marker,
      tableCell: tableCell,
      sourceProtected: sourceProtected,
      unsafeStructuredContainer: unsafeStructuredContainer,
      atBlockStart: atBlockStart,
      containerContinuationPrefix: prefixes.continuation,
      containerBlankPrefix: prefixes.blank,
      hasContainerContentBefore: markerOffset != null && markerOffset > 0,
      hasContainerContentAfter:
          markerOffset != null &&
          markerBlock != null &&
          markerOffset + marker.length < markerBlock.plainText.length,
      taskItemAtContentStart:
          markerOffset == 0 && markerBlock?.kind == BusyBlockKind.taskListItem,
      inlineContext: inlineMapping.context,
      inlineMappingFailed: inlineMapping.failed,
    );
  }

  String _sourceInsertionLineEnding(String source, int offset) {
    final before = source.lastIndexOf('\n', math.max(0, offset - 1));
    if (before >= 0) {
      return before > 0 && source.codeUnitAt(before - 1) == 0x0d
          ? '\r\n'
          : '\n';
    }
    final after = source.indexOf('\n', offset.clamp(0, source.length).toInt());
    if (after >= 0) {
      return after > 0 && source.codeUnitAt(after - 1) == 0x0d ? '\r\n' : '\n';
    }
    return '\n';
  }

  ({_MappedSourceInlineContext? context, bool failed})
  _mappedSourceInlineContext(
    SourcePasteDocumentSnapshot target,
    int start,
    int end,
    TextRange sourceBounds, {
    required bool inlineOnly,
  }) {
    final startMarker = _sourceClipboardMarker(target.text);
    final endMarker = start == end
        ? startMarker
        : _sourceClipboardMarker('${target.text}$startMarker');
    var markedSource = target.text;
    if (start != end) {
      markedSource = markedSource.replaceRange(end, end, endMarker);
    }
    markedSource = markedSource.replaceRange(start, start, startMarker);
    final parserContext = const MarkdownSourceMapper()
        .createInlineParserContext(
          documentSource: target.text,
          mode: target.markdownMode,
        );
    final markerCount =
        startMarker.length + (start == end ? 0 : endMarker.length);
    final markedBounds = TextRange(
      start: sourceBounds.start,
      end: (sourceBounds.end + markerCount)
          .clamp(0, markedSource.length)
          .toInt(),
    );
    if (markedBounds.start < 0 ||
        markedBounds.start > markedBounds.end ||
        markedBounds.end > markedSource.length) {
      return (context: null, failed: true);
    }
    final markers = [startMarker, if (start != end) endMarker];
    final mapped = inlineOnly
        ? parserContext.parseMapped(
            markedSource.substring(markedBounds.start, markedBounds.end),
            ignoredReferenceLabelMarkers: markers,
          )
        : parserContext.parseMappedBlock(
            markedSource,
            sourceStart: markedBounds.start,
            sourceEnd: markedBounds.end,
            ignoredReferenceLabelMarkers: markers,
          );
    if (mapped == null) {
      return (context: null, failed: true);
    }
    if (!mapped.positionRecordsComplete) {
      final boundary = start == end
          ? _mappedSourceBoundaryContext(
              mapped,
              start,
              rangeBaseOffset: inlineOnly ? markedBounds.start : 0,
              startMarker: startMarker,
            )
          : null;
      return (context: boundary, failed: true);
    }
    final startTrace = _sourceInlineTraceContainingMarkerInInlines(
      mapped.inlines,
      startMarker,
    );
    if (startTrace == null) return (context: null, failed: true);
    final endTrace = start == end
        ? startTrace
        : _sourceInlineTraceContainingMarkerInInlines(
            mapped.inlines,
            endMarker,
          );
    if (endTrace == null) return (context: null, failed: true);
    final commonAncestors = <BusyInline>[];
    final commonLength = math.min(
      startTrace.frames.length,
      endTrace.frames.length,
    );
    for (var index = 0; index < commonLength; index++) {
      final startInline = startTrace.frames[index].inline;
      if (!identical(startInline, endTrace.frames[index].inline)) break;
      commonAncestors.add(startInline);
    }
    final wrappers = <_MappedSourceInlineWrapper>[];
    for (final inline in commonAncestors) {
      if (!busyMarkIsInheritedInlineContext(inline.kind)) continue;
      final range = mapped.ranges[inline];
      final wrapper = range == null
          ? _mappedSourceInlineWrapperFallback(
              target,
              markedSource,
              inline,
              startMarker,
              start == end ? null : endMarker,
              start,
              end,
              markedBounds,
              parserContext,
            )
          : _mappedSourceInlineWrapperFromRange(
              target,
              inline,
              range,
              start,
              end,
              markerCount,
              markedBounds,
              rangeBaseOffset: inlineOnly ? markedBounds.start : 0,
            );
      if (wrapper != null) wrappers.add(wrapper);
    }
    assert(() {
      debugBusyMarkSourceInlineMappingParseCount?.call(
        parserContext.parseInvocations,
      );
      return true;
    }());
    return (
      context: _MappedSourceInlineContext(
        commonAncestors: List.unmodifiable(commonAncestors),
        wrappers: List.unmodifiable(wrappers),
        startMarker: startMarker,
        endMarker: start == end ? null : endMarker,
        previousSibling: start == end
            ? _sourceInlineSibling(startTrace, startMarker, before: true)
            : null,
        nextSibling: start == end
            ? _sourceInlineSibling(startTrace, startMarker, before: false)
            : null,
      ),
      failed: false,
    );
  }

  _MappedSourceInlineContext? _mappedSourceBoundaryContext(
    BusyMarkMappedInlineParse mapped,
    int sourceOffset, {
    required int rangeBaseOffset,
    required String startMarker,
  }) {
    BusyInline semantic(BusyInline inline) =>
        mapped.ranges[inline]?.originalInline ?? inline;

    ({BusyInline previous, BusyInline next})? find(List<BusyInline> siblings) {
      for (var index = 1; index < siblings.length; index++) {
        final previous = siblings[index - 1];
        final next = siblings[index];
        final previousRange = mapped.ranges[previous];
        final nextRange = mapped.ranges[next];
        if (previousRange != null &&
            nextRange != null &&
            rangeBaseOffset + previousRange.end == sourceOffset &&
            rangeBaseOffset + nextRange.start == sourceOffset) {
          return (previous: semantic(previous), next: semantic(next));
        }
      }
      for (final inline in siblings) {
        final nested = find(inline.children);
        if (nested != null) return nested;
      }
      // CommonMark treats `**left****right**` as one strong run whose middle
      // delimiter text is literal. Source editing has historically treated
      // the authored close/open pair as a joinable boundary. Keep that local
      // behavior only when the authoritative parse says the boundary remains
      // inside the same matching semantic wrapper; the caller separately
      // verifies the exact delimiter bytes on both sides of the caret.
      for (final inline in siblings.reversed) {
        final range = mapped.ranges[inline];
        final value = semantic(inline);
        if (range != null &&
            rangeBaseOffset + range.start < sourceOffset &&
            sourceOffset < rangeBaseOffset + range.end &&
            (value.kind == BusyInlineKind.strong ||
                value.kind == BusyInlineKind.emphasis ||
                value.kind == BusyInlineKind.strikethrough)) {
          return (previous: value, next: value);
        }
      }
      return null;
    }

    final boundary = find(mapped.inlines);
    if (boundary == null) return null;
    return _MappedSourceInlineContext(
      commonAncestors: const [],
      wrappers: const [],
      startMarker: startMarker,
      endMarker: null,
      previousSibling: boundary.previous,
      nextSibling: boundary.next,
    );
  }

  _MappedSourceInlineWrapper? _mappedSourceInlineWrapperFromRange(
    SourcePasteDocumentSnapshot target,
    BusyInline inline,
    BusyMarkMappedInlineRange mappedRange,
    int selectionStart,
    int selectionEnd,
    int markerCount,
    TextRange markedBounds, {
    required int rangeBaseOffset,
  }) {
    if (inline.kind == BusyInlineKind.link &&
        mappedRange.originalInline == null) {
      return null;
    }
    final markedStart = rangeBaseOffset + mappedRange.start;
    final markedEnd = rangeBaseOffset + mappedRange.end;
    final originalEnd = markedEnd - markerCount;
    if (markedStart < markedBounds.start ||
        markedStart > selectionStart ||
        originalEnd < selectionEnd ||
        markedEnd > markedBounds.end ||
        originalEnd > target.text.length) {
      return null;
    }
    return _MappedSourceInlineWrapper(
      inline: inline,
      sourceRange: TextRange(start: markedStart, end: originalEnd),
      opening: mappedRange.opening,
      closing: mappedRange.closing,
      lineBreaks: mappedRange.lineBreaks,
      isAutolink: mappedRange.isAutolink,
      isReference: mappedRange.isReference,
    );
  }

  _MappedSourceInlineWrapper? _mappedSourceInlineWrapperFallback(
    SourcePasteDocumentSnapshot target,
    String markedSource,
    BusyInline inline,
    String startMarker,
    String? endMarker,
    int selectionStart,
    int selectionEnd,
    TextRange markedBounds,
    BusyMarkInlineParserContext parserContext,
  ) {
    final markerCount = startMarker.length + (endMarker?.length ?? 0);
    TextRange? originalRange(int markedStart, int markedEnd) {
      final end = markedEnd - markerCount;
      if (markedStart < 0 ||
          markedStart > selectionStart ||
          end < selectionEnd ||
          end > target.text.length) {
        return null;
      }
      return TextRange(start: markedStart, end: end);
    }

    bool containsMarkers(String text) =>
        text.contains(startMarker) &&
        (endMarker == null || text.contains(endMarker));
    bool candidateMatches(int start, int end) {
      if (start < markedBounds.start ||
          end > markedBounds.end ||
          start >= end) {
        return false;
      }
      final parsed = parserContext.parse(
        markedSource.substring(start, end),
        ignoredReferenceLabelMarkers: [
          startMarker,
          if (endMarker != null) endMarker,
        ],
      );
      return parsed.length == 1 &&
          busyMarkSameInlineSemantics(parsed.single, inline) &&
          parsed.single.plainText == inline.plainText &&
          containsMarkers(parsed.single.plainText);
    }

    final markedStart = markedSource.indexOf(startMarker);
    final markedEnd = endMarker == null
        ? markedStart + startMarker.length
        : markedSource.indexOf(endMarker, markedStart + startMarker.length) +
              endMarker.length;
    if (markedStart < 0 || markedEnd <= markedStart) return null;
    if (inline.kind == BusyInlineKind.link) {
      // A known original link must have a parser-derived range and semantic
      // association. Falling back to marked link content could persist a
      // mapping marker as its destination or change reference identity.
      return null;
    }

    if (inline.kind == BusyInlineKind.underline) {
      const openingDelimiter = '<u>';
      const closingDelimiter = '</u>';
      final opening = markedSource.lastIndexOf(openingDelimiter, markedStart);
      final closing = markedSource.indexOf(closingDelimiter, markedEnd);
      final candidateEnd = closing + closingDelimiter.length;
      if (opening >= markedBounds.start &&
          closing >= markedEnd &&
          candidateEnd <= markedBounds.end &&
          candidateMatches(opening, candidateEnd)) {
        final range = originalRange(opening, candidateEnd);
        return range == null
            ? null
            : _MappedSourceInlineWrapper(
                inline: inline,
                sourceRange: range,
                opening: openingDelimiter,
                closing: closingDelimiter,
              );
      }
    }
    return null;
  }

  _SourceInlineTrace? _sourceInlineTraceContainingMarkerInInlines(
    List<BusyInline> siblings,
    String marker,
  ) {
    for (var index = 0; index < siblings.length; index++) {
      final inline = siblings[index];
      if (!inline.plainText.contains(marker)) continue;
      final child = _sourceInlineTraceContainingMarkerInInlines(
        inline.children,
        marker,
      );
      return _SourceInlineTrace(
        frames: [
          _SourceInlineFrame(inline: inline, siblings: siblings, index: index),
          ...?child?.frames,
        ],
      );
    }
    return null;
  }

  BusyInline? _sourceInlineSibling(
    _SourceInlineTrace trace,
    String marker, {
    required bool before,
  }) {
    final leafText = trace.frames.last.inline.plainText;
    final markerOffset = leafText.indexOf(marker);
    if (markerOffset < 0) return null;
    if (before && markerOffset != 0) return null;
    if (!before && markerOffset + marker.length != leafText.length) {
      return null;
    }
    for (final frame in trace.frames.reversed) {
      final siblingIndex = before ? frame.index - 1 : frame.index + 1;
      if (siblingIndex >= 0 && siblingIndex < frame.siblings.length) {
        return frame.siblings[siblingIndex];
      }
    }
    return null;
  }

  String _sourceClipboardMarker(String source) {
    for (var codePoint = 0xe000; codePoint <= 0xf8ff; codePoint++) {
      final marker = String.fromCharCode(codePoint);
      if (!source.contains(marker)) return marker;
    }
    return '\u{f0000}';
  }

  List<BusyBlock>? _sourceBlockPathContainingMarker(
    Iterable<BusyBlock> blocks,
    String marker,
  ) {
    bool contains(BusyBlock block) =>
        block.plainText.contains(marker) ||
        block.children.any((child) => contains(child));

    for (final block in blocks) {
      if (!contains(block)) continue;
      final childPath = _sourceBlockPathContainingMarker(
        block.children,
        marker,
      );
      return [block, ...?childPath];
    }
    return null;
  }

  BusyMarkMarkdownTableCellRegion? _singleTableCellContainingSelection(
    Iterable<BusyBlock> blocks,
    String source,
    int start,
    int end,
  ) {
    for (final block in _sourceBlocksDepthFirst(blocks)) {
      if (block.kind != BusyBlockKind.table || block.sourceSpan == null) {
        continue;
      }
      for (final region in busyMarkMarkdownTableCellRegions(
        source: source,
        table: block,
      )) {
        if (start >= region.span.startOffset && end <= region.span.endOffset) {
          return region;
        }
      }
    }
    return null;
  }

  TextRange _sourceInlineMappingRange(
    Iterable<BusyBlock> blocks,
    String source,
    int start,
    int end,
  ) {
    TextRange? smallest;
    for (final block in _sourceBlocksDepthFirst(blocks)) {
      final span = block.sourceSpan;
      if (span == null || start < span.startOffset || end > span.endOffset) {
        continue;
      }
      final candidate = TextRange(start: span.startOffset, end: span.endOffset);
      if (smallest == null ||
          candidate.end - candidate.start < smallest.end - smallest.start) {
        smallest = candidate;
      }
    }
    if (smallest != null) return smallest;
    final line = busyMarkSourceLineBounds(source, start);
    return TextRange(start: line.start, end: line.end);
  }

  ({BusyBlock table, bool coversWhole})? _tableIntersectingSelection(
    Iterable<BusyBlock> blocks,
    int start,
    int end,
  ) {
    for (final block in _sourceBlocksDepthFirst(blocks)) {
      final span = block.sourceSpan;
      if (block.kind != BusyBlockKind.table || span == null) continue;
      final intersects = start == end
          ? start >= span.startOffset && start <= span.endOffset
          : start < span.endOffset && end > span.startOffset;
      if (!intersects) continue;
      return (
        table: block,
        coversWhole: start <= span.startOffset && end >= span.endOffset,
      );
    }
    return null;
  }

  Iterable<BusyBlock> _sourceBlocksDepthFirst(
    Iterable<BusyBlock> blocks,
  ) sync* {
    for (final block in blocks) {
      yield block;
      yield* _sourceBlocksDepthFirst(block.children);
    }
  }

  ({String continuation, String blank}) _sourceContainerPrefixes(
    String source,
    int markerOffset,
    List<BusyBlock> path,
  ) {
    final containerKinds = [
      for (final block in path)
        if (block.kind == BusyBlockKind.blockquote ||
            block.kind == BusyBlockKind.unorderedListItem ||
            block.kind == BusyBlockKind.orderedListItem ||
            block.kind == BusyBlockKind.taskListItem)
          block.kind,
    ];
    if (containerKinds.isEmpty) return (continuation: '', blank: '');
    ({String value, int count}) parseLineFrom(String line, int firstKindIndex) {
      var cursor = 0;
      var count = 0;
      final continuation = StringBuffer();
      for (
        var kindIndex = firstKindIndex;
        kindIndex < containerKinds.length;
        kindIndex++
      ) {
        final kind = containerKinds[kindIndex];
        if (kind == BusyBlockKind.blockquote) {
          final start = cursor;
          var spaces = 0;
          while (cursor < line.length &&
              (firstKindIndex > 0 || spaces < 3) &&
              line.codeUnitAt(cursor) == 0x20) {
            cursor += 1;
            spaces += 1;
          }
          if (cursor >= line.length || line.codeUnitAt(cursor) != 0x3e) {
            cursor = start;
            break;
          }
          cursor += 1;
          if (cursor < line.length &&
              (line.codeUnitAt(cursor) == 0x20 ||
                  line.codeUnitAt(cursor) == 0x09)) {
            cursor += 1;
          }
          continuation.write(line.substring(start, cursor));
          count++;
          continue;
        }
        final start = cursor;
        while (cursor < line.length &&
            (line.codeUnitAt(cursor) == 0x20 ||
                line.codeUnitAt(cursor) == 0x09)) {
          cursor += 1;
        }
        final marker = _consumeSourceListMarker(line, cursor);
        if (marker == null) {
          cursor = start;
          break;
        }
        cursor = marker.end;
        continuation
          ..write(line.substring(start, marker.start))
          ..write(
            ' ' *
                (_sourceIndentationColumn(line, cursor) -
                    _sourceIndentationColumn(line, marker.start)),
          );
        count++;
      }
      return (
        value: continuation.toString(),
        count: count == 0 ? 0 : firstKindIndex + count,
      );
    }

    ({String value, int count}) parseLine(String line) {
      var best = (value: '', count: 0);
      for (var index = 0; index < containerKinds.length; index++) {
        final candidate = parseLineFrom(line, index);
        if (candidate.count > best.count) best = candidate;
      }
      return best;
    }

    final currentLine = busyMarkSourceLineBounds(source, markerOffset);
    final currentLineStart = currentLine.start;
    final currentLineEnd = currentLine.end;
    var best = parseLine(source.substring(currentLineStart, currentLineEnd));

    // Continuation and lazy-quote lines need not repeat their ancestors'
    // opening markers. Search only within the surviving outer container and
    // resolve the deepest visible ancestor on each opening line. This permits
    // outer and inner containers to open on different physical lines.
    final outerContainer = path.firstWhere(
      (block) =>
          block.kind == BusyBlockKind.blockquote ||
          block.kind == BusyBlockKind.unorderedListItem ||
          block.kind == BusyBlockKind.orderedListItem ||
          block.kind == BusyBlockKind.taskListItem,
    );
    final outerStart =
        (outerContainer.sourceSpan?.startOffset ?? currentLineStart)
            .clamp(0, currentLineStart)
            .toInt();
    var scanEnd = currentLineStart;
    while (best.count < containerKinds.length && scanEnd > outerStart) {
      final previousLine = busyMarkSourceLineBounds(source, scanEnd - 1);
      final scanStart = math.max(outerStart, previousLine.start);
      final candidate = parseLine(
        source.substring(scanStart, previousLine.end),
      );
      if (candidate.count > best.count) best = candidate;
      if (candidate.count == containerKinds.length || scanStart == outerStart) {
        break;
      }
      scanEnd = scanStart;
    }
    var value = best.value;
    if (containerKinds.every(
      (kind) =>
          kind == BusyBlockKind.unorderedListItem ||
          kind == BusyBlockKind.orderedListItem ||
          kind == BusyBlockKind.taskListItem,
    )) {
      var indentationEnd = currentLineStart;
      while (indentationEnd < currentLineEnd &&
          (source.codeUnitAt(indentationEnd) == 0x20 ||
              source.codeUnitAt(indentationEnd) == 0x09)) {
        indentationEnd += 1;
      }
      final authoredIndentation = source.substring(
        currentLineStart,
        indentationEnd,
      );
      if (_sourceIndentationColumn(
            authoredIndentation,
            authoredIndentation.length,
          ) >=
          _sourceIndentationColumn(value, value.length)) {
        value = authoredIndentation;
      }
    }
    return (continuation: value, blank: value.trimRight());
  }

  ({int start, int end})? _consumeSourceListMarker(String line, int offset) {
    if (offset >= line.length) return null;
    var cursor = offset;
    final first = line.codeUnitAt(cursor);
    if (first == 0x2d || first == 0x2b || first == 0x2a) {
      cursor += 1;
    } else if (first >= 0x30 && first <= 0x39) {
      var digits = 0;
      while (cursor < line.length &&
          line.codeUnitAt(cursor) >= 0x30 &&
          line.codeUnitAt(cursor) <= 0x39 &&
          digits < 9) {
        cursor += 1;
        digits += 1;
      }
      if (cursor >= line.length ||
          (line.codeUnitAt(cursor) != 0x2e &&
              line.codeUnitAt(cursor) != 0x29)) {
        return null;
      }
      cursor += 1;
    } else {
      return null;
    }
    if (cursor >= line.length ||
        (line.codeUnitAt(cursor) != 0x20 && line.codeUnitAt(cursor) != 0x09)) {
      return null;
    }
    while (cursor < line.length &&
        (line.codeUnitAt(cursor) == 0x20 || line.codeUnitAt(cursor) == 0x09)) {
      cursor += 1;
    }
    return (start: offset, end: cursor);
  }

  int _sourceIndentationColumn(String line, int offset) {
    var column = 0;
    for (var index = 0; index < offset; index++) {
      if (line.codeUnitAt(index) == 0x09) {
        column += 4 - (column % 4);
      } else {
        column += 1;
      }
    }
    return column;
  }

  int _leadingLineBreaks(String value) {
    var count = 0;
    while (count < value.length && value.codeUnitAt(count) == 0x0a) {
      count += 1;
    }
    return count;
  }

  int _trailingLineBreaks(String value) {
    var count = 0;
    for (
      var index = value.length - 1;
      index >= 0 && value.codeUnitAt(index) == 0x0a;
      index -= 1
    ) {
      count += 1;
    }
    return count;
  }
}

class _StructuredSourceInsertionContext {
  const _StructuredSourceInsertionContext({
    required this.start,
    required this.end,
    this.lineEnding = '\n',
    this.marker = '',
    this.tableCell = false,
    this.sourceProtected = false,
    this.unsafeStructuredContainer = false,
    this.atBlockStart = false,
    this.containerContinuationPrefix = '',
    this.containerBlankPrefix = '',
    this.hasContainerContentBefore = false,
    this.hasContainerContentAfter = false,
    this.taskItemAtContentStart = false,
    this.inlineMappingFailed = false,
    this.inlineContext,
  });

  final int start;
  final int end;
  final String lineEnding;
  final String marker;
  final bool tableCell;
  final bool sourceProtected;
  final bool unsafeStructuredContainer;
  final bool atBlockStart;
  final String containerContinuationPrefix;
  final String containerBlankPrefix;
  final bool hasContainerContentBefore;
  final bool hasContainerContentAfter;
  final bool taskItemAtContentStart;
  final bool inlineMappingFailed;
  final _MappedSourceInlineContext? inlineContext;
}

class _MappedSourceInlineContext {
  const _MappedSourceInlineContext({
    required this.commonAncestors,
    required this.wrappers,
    required this.startMarker,
    required this.endMarker,
    this.previousSibling,
    this.nextSibling,
  });

  final List<BusyInline> commonAncestors;
  final List<_MappedSourceInlineWrapper> wrappers;
  final String startMarker;
  final String? endMarker;
  final BusyInline? previousSibling;
  final BusyInline? nextSibling;

  _MappedSourceInlineWrapper? wrapperFor(BusyInline inline) {
    for (final wrapper in wrappers) {
      if (identical(wrapper.inline, inline)) return wrapper;
    }
    return null;
  }
}

class _MappedSourceInlineWrapper {
  const _MappedSourceInlineWrapper({
    required this.inline,
    required this.sourceRange,
    this.opening,
    this.closing,
    this.lineBreaks = const [],
    this.isAutolink = false,
    this.isReference = false,
  });

  final BusyInline inline;
  final TextRange sourceRange;
  final String? opening;
  final String? closing;
  final List<BusyMarkMappedSourceLineBreak> lineBreaks;
  final bool isAutolink;
  final bool isReference;
}

class _SerializedMappedSourceLineBreak {
  const _SerializedMappedSourceLineBreak({
    required this.sourceOffset,
    required this.lineBreak,
  });

  final int sourceOffset;
  final BusyMarkMappedSourceLineBreak lineBreak;
}

class _SourceInlineTrace {
  const _SourceInlineTrace({required this.frames});

  final List<_SourceInlineFrame> frames;
}

class _SourceInlineFrame {
  const _SourceInlineFrame({
    required this.inline,
    required this.siblings,
    required this.index,
  });

  final BusyInline inline;
  final List<BusyInline> siblings;
  final int index;
}

class _MappedAdjacentInlineRuns {
  const _MappedAdjacentInlineRuns({
    required this.leftClosingRange,
    required this.rightOpeningRange,
  });

  final TextRange leftClosingRange;
  final TextRange rightOpeningRange;
}

class _SourceInlineOccurrenceAnnotations {
  final Set<BusyInline> _rawHtml = Set<BusyInline>.identity();

  bool isRawHtml(BusyInline inline) => _rawHtml.contains(inline);

  void markRawHtml(BusyInline inline) => _rawHtml.add(inline);

  BusyInline copyAnnotation(
    BusyInline source,
    BusyInline replacement, {
    bool rawHtml = false,
  }) {
    if (rawHtml || isRawHtml(source)) markRawHtml(replacement);
    return replacement;
  }

  BusyInline copyAnnotations(
    Iterable<BusyInline> sources,
    BusyInline replacement,
  ) {
    if (sources.any(isRawHtml)) markRawHtml(replacement);
    return replacement;
  }
}

sealed class _SourcePlan {
  const _SourcePlan();
}

class _SourceTerminalPlan extends _SourcePlan {
  const _SourceTerminalPlan();
}

class _SourceEditPlan extends _SourcePlan {
  const _SourceEditPlan({
    required this.start,
    required this.end,
    required this.text,
    this.caretOffset,
  });

  final int start;
  final int end;
  final String text;
  final int? caretOffset;
}
