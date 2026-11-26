import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show CharacterBoundary;

import '../../app/busymark_design.dart';
import '../../markdown/busymark_document.dart';
import '../../markdown/busymark_markdown_serializer.dart';
import '../../markdown/markdown_model.dart';
import '../../markdown/markdown_source_map.dart';
import '../../markdown/semantic_html_inline.dart';
import '../document_html_inline.dart';
import '../document_text_direction.dart';

bool busyMarkWysiwygBlockContainsMath(BusyBlock block) {
  bool contains(List<BusyInline> inlines) => inlines.any(
    (inline) => inline.kind == BusyInlineKind.math || contains(inline.children),
  );
  return block.kind == BusyBlockKind.math || contains(block.inlines);
}

bool busyMarkWysiwygBlockDescendantsContainMath(BusyBlock block) {
  return block.children.any(
    (child) =>
        busyMarkWysiwygBlockContainsMath(child) ||
        busyMarkWysiwygBlockDescendantsContainMath(child),
  );
}

String busyMarkWysiwygEditableText(BusyBlock block) {
  if (!busyMarkWysiwygBlockContainsMath(block)) {
    return block.plainText;
  }
  if (block.kind != BusyBlockKind.math && block.inlines.isNotEmpty) {
    final raw = block.rawSource;
    if (!block.dirty &&
        block.sourceSpan != null &&
        raw != null &&
        _containsImage(block.inlines)) {
      if (_authoredMathFieldSource(raw) case final authored?) {
        return authored;
      }
    }
    return const BusyMarkMarkdownSerializer().serializeBlock(
      BusyBlock(
        id: 'wysiwyg-inline-source',
        kind: BusyBlockKind.paragraph,
        inlines: block.inlines,
        dirty: true,
      ),
    );
  }
  final source =
      block.rawSource ??
      const BusyMarkMarkdownSerializer().serializeBlock(block);
  return source.replaceFirst(RegExp(r'(?:\r\n|\r|\n)$'), '');
}

bool _containsImage(List<BusyInline> inlines) => inlines.any(
  (inline) =>
      inline.kind == BusyInlineKind.image || _containsImage(inline.children),
);

String? _authoredMathFieldSource(String raw) {
  final mapped = const MarkdownSourceMapper()
      .createInlineParserContext(
        documentSource: raw,
        mode: MarkdownMode.commonMark,
      )
      .parsePositionedBlocks(raw);
  if (mapped.length != 1 || !mapped.single.positionRecordsComplete) {
    return null;
  }
  final content = mapped.single;
  final start = content.sourceStart;
  final end = content.sourceEnd;
  if (start == null ||
      end == null ||
      start < 0 ||
      end <= start ||
      end > raw.length) {
    return null;
  }
  final breaks = [...content.positionedLineBreaks]
    ..sort(
      (left, right) =>
          (left.sourceOffset ?? -1).compareTo(right.sourceOffset ?? -1),
    );
  final field = StringBuffer();
  var cursor = start;
  for (final lineBreak in breaks) {
    final offset = lineBreak.sourceOffset;
    if (offset == null || offset < cursor || offset >= end) continue;
    final prefixEnd =
        offset +
        lineBreak.lineEnding.length +
        lineBreak.continuationPrefix.length;
    if (prefixEnd > end ||
        !raw.startsWith(
          '${lineBreak.lineEnding}${lineBreak.continuationPrefix}',
          offset,
        )) {
      return null;
    }
    field.write(raw.substring(cursor, offset + lineBreak.lineEnding.length));
    cursor = prefixEnd;
  }
  field.write(raw.substring(cursor, end));
  return field.toString();
}

/// Maps an inline Markdown source boundary back to the block's semantic text
/// coordinate. Math-bearing fields use source coordinates while the document
/// insertion APIs and ordinary fields use semantic coordinates.
int busyMarkWysiwygTextOffsetForSourceOffset(
  BusyBlock block,
  int sourceOffset,
) {
  final source = busyMarkWysiwygEditableText(block);
  final target = sourceOffset.clamp(0, source.length).toInt();
  final textLength = block.plainText.length;
  var low = 0;
  var high = textLength;
  var bestTextOffset = 0;
  var bestSourceOffset = 0;
  while (low <= high) {
    final textOffset = low + ((high - low) ~/ 2);
    final mapped = const BusyMarkMarkdownSerializer()
        .serializeInlineFragmentAtTextOffset(
          block.inlines,
          textOffset: textOffset,
          atBlockStart: true,
          readableHardBreakRuns: true,
        )
        .sourceOffset;
    if ((mapped - target).abs() < (bestSourceOffset - target).abs() ||
        ((mapped - target).abs() == (bestSourceOffset - target).abs() &&
            mapped <= target)) {
      bestTextOffset = textOffset;
      bestSourceOffset = mapped;
    }
    if (mapped == target) return textOffset;
    if (mapped < target) {
      low = textOffset + 1;
    } else {
      high = textOffset - 1;
    }
  }
  return bestTextOffset;
}

class BusyInlineStyleRange {
  const BusyInlineStyleRange({
    required this.start,
    required this.end,
    required this.kind,
    this.destination,
    this.attributes = const {},
    this.referenceIndex,
  });

  final int start;
  final int end;
  final BusyInlineKind kind;
  final String? destination;
  final Map<String, String> attributes;

  /// Owning reference's ordinal within this block snapshot. Empty references
  /// can share text boundaries, so offsets alone are not their identity.
  final int? referenceIndex;
}

class BusyInlineSemanticAnchor {
  const BusyInlineSemanticAnchor({required this.offset, required this.inline});

  final int offset;
  final BusyInline inline;
}

/// One range per owning reference, independent of formatting in its caption.
/// Styling still uses [busyInlineStyleRanges]'s individual text segments.
/// References without a label retain their editable source position.
List<BusyInlineStyleRange> busyInlineReferenceRanges(List<BusyInline> inlines) {
  final ranges = <BusyInlineStyleRange>[];
  var offset = 0;
  void visit(BusyInline inline) {
    if ({
      BusyInlineKind.link,
      BusyInlineKind.image,
      BusyInlineKind.writersideVariable,
      BusyInlineKind.writersideShortcut,
    }.contains(inline.kind)) {
      ranges.add(
        BusyInlineStyleRange(
          start: offset,
          end: offset + inline.plainText.length,
          kind: inline.kind,
          destination: inline.destination,
          attributes: inline.attributes,
          referenceIndex: ranges.length,
        ),
      );
    }
    if (inline.children.isNotEmpty) {
      inline.children.forEach(visit);
    } else {
      offset += inline.plainText.length;
    }
  }

  inlines.forEach(visit);
  return ranges;
}

List<BusyInlineSemanticAnchor> busyInlineSemanticAnchors(
  List<BusyInline> inlines,
) {
  final anchors = <BusyInlineSemanticAnchor>[];
  var offset = 0;

  void visit(BusyInline inline, List<BusyInline> ancestors) {
    if (inline.plainText.isEmpty) {
      if (inline.kind == BusyInlineKind.text &&
          !inline.children.any(_containsNonTextInline)) {
        return;
      }
      var anchored = inline;
      for (final ancestor in ancestors.reversed) {
        anchored = ancestor.copyWith(text: '', children: [anchored]);
      }
      anchors.add(BusyInlineSemanticAnchor(offset: offset, inline: anchored));
      return;
    }
    if (inline.children.isNotEmpty) {
      for (final child in inline.children) {
        visit(child, [...ancestors, inline]);
      }
      return;
    }
    offset += inline.plainText.length;
  }

  for (final inline in inlines) {
    visit(inline, const []);
  }
  return anchors;
}

bool _containsNonTextInline(BusyInline inline) {
  return inline.kind != BusyInlineKind.text ||
      inline.children.any(_containsNonTextInline);
}

class BusyMarkWysiwygTextController extends TextEditingController {
  BusyMarkWysiwygTextController({
    required String text,
    required List<BusyInlineStyleRange> ranges,
  }) : _ranges = ranges,
       super(text: text);

  List<BusyInlineStyleRange> _ranges;
  Map<int, String> _directionControls = const {};
  _DirectionalEditingController? _directional;

  TextEditingController get editableController =>
      _directional ??
      (_directionControls.isEmpty
          ? this
          : (_directional = _DirectionalEditingController(this)));

  int documentOffset(int editableOffset) =>
      _directional?._projection.documentOffset(editableOffset) ??
      editableOffset;

  TextPosition editablePosition(TextPosition position) => TextPosition(
    offset:
        _directional?._projection.editableOffset(
          position.offset,
          beforeControls: position.affinity == TextAffinity.upstream,
        ) ??
        position.offset,
    affinity: position.affinity,
  );

  TextSelection editableSelection(TextSelection selection) =>
      _directional?._projection.toEditable(selection) ?? selection;

  void updateFromBlock(BusyBlock block) {
    final sourceEditing = busyMarkWysiwygBlockContainsMath(block);
    final nextText = busyMarkWysiwygEditableText(block);
    final nextRanges = sourceEditing
        ? const <BusyInlineStyleRange>[]
        : busyInlineStyleRanges(block.inlines, includeHtml: true);
    final rangesChanged = !_inlineStyleRangesEqual(_ranges, nextRanges);
    _directionControls = sourceEditing
        ? const {}
        : _inlineDirectionControls(block.inlines);
    if (text != nextText) {
      final previousSelection = selection;
      _ranges = nextRanges;
      value = value.copyWith(
        text: nextText,
        selection: _clampedSelection(previousSelection, nextText.length),
        composing: TextRange.empty,
      );
    } else if (rangesChanged) {
      _ranges = nextRanges;
      notifyListeners();
    }
    _directional?.refresh(stylesChanged: rangesChanged);
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) => _buildTextSpan(context, style, text, _ranges, TextRange.empty);

  TextSpan _buildTextSpan(
    BuildContext context,
    TextStyle? style,
    String text,
    List<BusyInlineStyleRange> styleRanges,
    TextRange composing,
  ) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    if (text.isEmpty || styleRanges.isEmpty && composing.isCollapsed) {
      return TextSpan(text: text, style: baseStyle);
    }
    final spans = <TextSpan>[];
    final ranges = _normalizedRanges(styleRanges, text.length);
    final boundaries = <int>{0, text.length};
    if (!composing.isCollapsed) {
      boundaries
        ..add(composing.start)
        ..add(composing.end);
    }
    for (final range in ranges) {
      boundaries
        ..add(range.start)
        ..add(range.end);
    }
    final sortedBoundaries = boundaries.toList()..sort();
    for (var index = 0; index < sortedBoundaries.length - 1; index++) {
      final start = sortedBoundaries[index];
      final end = sortedBoundaries[index + 1];
      if (end <= start) {
        continue;
      }
      final segmentStyle = _styleForRanges(
        context,
        _activeRangesForSegment(ranges, start, end),
        baseStyle,
      );
      spans.add(
        TextSpan(
          text: text.substring(start, end),
          style: start >= composing.start && end <= composing.end
              ? segmentStyle.copyWith(
                  decoration: TextDecoration.combine([
                    if (segmentStyle.decoration case final decoration?)
                      decoration,
                    TextDecoration.underline,
                  ]),
                )
              : segmentStyle,
        ),
      );
    }
    return TextSpan(style: baseStyle, children: spans);
  }

  @override
  void dispose() {
    _directional?.dispose();
    super.dispose();
  }

  TextStyle _styleForRanges(
    BuildContext context,
    List<BusyInlineStyleRange> ranges,
    TextStyle baseStyle,
  ) {
    var style = baseStyle;
    for (final range in ranges..sort(_compareRangesByStylePriority)) {
      style = _styleForRange(context, range, style);
    }
    return style;
  }

  TextStyle _styleForRange(
    BuildContext context,
    BusyInlineStyleRange range,
    TextStyle baseStyle,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = BusyMarkSurfaceColors.of(context);
    return switch (range.kind) {
      BusyInlineKind.strong => baseStyle.copyWith(fontWeight: FontWeight.w700),
      BusyInlineKind.emphasis => baseStyle.copyWith(
        fontStyle: FontStyle.italic,
      ),
      BusyInlineKind.underline => baseStyle.copyWith(
        decoration: TextDecoration.underline,
      ),
      BusyInlineKind.strikethrough => baseStyle.copyWith(
        decoration: TextDecoration.lineThrough,
      ),
      BusyInlineKind.code ||
      BusyInlineKind.writersidePath ||
      BusyInlineKind.writersideUiPath ||
      BusyInlineKind.writersideShortcut => baseStyle.copyWith(
        fontFamily: BusyMarkTypography.monoFontFamily,
        backgroundColor: colors.control,
      ),
      BusyInlineKind.link => baseStyle.copyWith(
        color: colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
      BusyInlineKind.writersideControl => baseStyle.copyWith(
        fontWeight: FontWeight.w600,
      ),
      BusyInlineKind.html => busyMarkHtmlInlineTextStyle(
        context,
        range.attributes['htmlTag']!,
        baseStyle,
      ),
      BusyInlineKind.image => baseStyle.copyWith(
        color: colorScheme.primary,
        fontStyle: FontStyle.italic,
      ),
      _ => baseStyle,
    };
  }
}

Map<int, String> _inlineDirectionControls(List<BusyInline> inlines) {
  final controls = <int, String>{};
  var offset = 0;
  void add(String text) => controls.update(
    offset,
    (existing) => existing + text,
    ifAbsent: () => text,
  );
  void visit(BusyInline inline) {
    final controls =
        inline.kind == BusyInlineKind.html && inline.plainText.isNotEmpty
        ? busyMarkInlineDirectionControls(inline.attributes)
        : null;
    if (controls != null) add(controls.open);
    if (inline.children.isEmpty) {
      offset += inline.plainText.length;
    } else {
      inline.children.forEach(visit);
    }
    if (controls != null) add(controls.close);
  }

  inlines.forEach(visit);
  return controls;
}

/// EditableText and the platform input client need the same UTF-16 offsets as
/// RenderEditable. The document controller only sees authored text and offsets.
class _DirectionalEditingController extends TextEditingController {
  _DirectionalEditingController(this._document) {
    _document.addListener(refresh);
    refresh();
  }

  final BusyMarkWysiwygTextController _document;
  var _projection = const _InlineDirectionText('', []);
  bool _handlingInput = false;

  void refresh({bool stylesChanged = false}) {
    if (_handlingInput) return;
    final next = _InlineDirectionText.fromDocument(
      _document.text,
      _document._directionControls,
    );
    final current = super.value;
    final selection =
        next.text == current.text &&
            listEquals(next.controls, _projection.controls) &&
            next.toDocument(current.selection) == _document.selection
        ? current.selection
        : next.toEditable(_document.selection);
    final composing = _document.value.composing;
    final updated = TextEditingValue(
      text: next.text,
      selection: selection,
      composing: composing.isValid && !composing.isCollapsed
          ? TextRange(
              start: next.editableOffset(composing.start),
              end: next.editableOffset(composing.end, beforeControls: true),
            )
          : TextRange.empty,
    );
    _projection = next;
    if (current != updated) {
      super.value = updated;
    } else if (stylesChanged) {
      notifyListeners();
    }
  }

  @override
  set value(TextEditingValue next) {
    final previous = super.value;
    if (next == previous) return;
    final previousDocumentText = _document.text;
    final oldProjection = _projection;
    var edited = oldProjection.afterEdit(previous.selection, next.text);
    if (previous.selection.isValid &&
        previous.selection.isCollapsed &&
        next.selection.isValid &&
        next.selection.isCollapsed &&
        edited.controls.length < oldProjection.controls.length &&
        edited.documentText == previousDocumentText) {
      // Backspace and Delete can otherwise repeatedly remove an invisible
      // scope boundary which would be restored on the next layout.
      final offset = _document.selection.extentOffset;
      final backward =
          next.selection.extentOffset < previous.selection.extentOffset;
      final boundary = CharacterBoundary(previousDocumentText);
      final start = backward && offset > 0
          ? boundary.getLeadingTextBoundaryAt(offset - 1) ?? 0
          : offset;
      final end = !backward && offset < previousDocumentText.length
          ? boundary.getTrailingTextBoundaryAt(offset) ??
                previousDocumentText.length
          : offset;
      if (end > start) {
        final removed = oldProjection.toEditable(
          TextSelection(baseOffset: start, extentOffset: end),
        );
        next = TextEditingValue(
          text: previous.text.replaceRange(removed.start, removed.end, ''),
          selection: TextSelection.collapsed(offset: removed.start),
        );
        edited = oldProjection.afterEdit(removed, next.text);
      }
    }
    _projection = edited;
    final composing = next.composing;
    final authored = TextEditingValue(
      text: _projection.documentText,
      selection: _projection.toDocument(next.selection),
      composing: composing.isValid && !composing.isCollapsed
          ? TextRange(
              start: _projection.documentOffset(composing.start),
              end: _projection.documentOffset(composing.end),
            )
          : TextRange.empty,
    );
    _handlingInput = true;
    try {
      _document.value = authored;
      super.value = next;
    } finally {
      _handlingInput = false;
    }
    if (next.text != previous.text && authored.text == previousDocumentText) {
      refresh();
    }
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) => _document._buildTextSpan(
    context,
    style,
    text,
    [
      for (final range in _document._ranges)
        BusyInlineStyleRange(
          start: _projection.editableOffset(range.start),
          end: _projection.editableOffset(range.end, beforeControls: true),
          kind: range.kind,
          destination: range.destination,
          attributes: range.attributes,
        ),
    ],
    withComposing && value.isComposingRangeValid
        ? value.composing
        : TextRange.empty,
  );

  @override
  void dispose() {
    _document.removeListener(refresh);
    super.dispose();
  }
}

class _InlineDirectionText {
  const _InlineDirectionText(this.text, this.controls);

  factory _InlineDirectionText.fromDocument(
    String text,
    Map<int, String> insertions,
  ) {
    final controls = <int>[];
    final result = StringBuffer();
    var start = 0;
    for (final MapEntry(key: offset, value: codes) in insertions.entries) {
      if (offset > text.length) break;
      result.write(text.substring(start, offset));
      for (var i = 0; i < codes.length; i++) {
        controls.add(result.length + i);
      }
      result.write(codes);
      start = offset;
    }
    result.write(text.substring(start));
    return _InlineDirectionText(result.toString(), controls);
  }

  final String text;
  // Sorted indices of generated UTF-16 code units in the editable text.
  final List<int> controls;

  String get documentText {
    if (controls.isEmpty) return text;
    final result = StringBuffer();
    var start = 0;
    for (final offset in controls) {
      result.write(text.substring(start, offset));
      start = offset + 1;
    }
    return (result..write(text.substring(start))).toString();
  }

  int documentOffset(int offset) {
    var result = offset;
    for (final control in controls) {
      if (control >= offset) break;
      result--;
    }
    return result;
  }

  int editableOffset(int offset, {bool beforeControls = false}) {
    var result = offset;
    for (final control in controls) {
      if (control > result || beforeControls && control == result) break;
      result++;
    }
    return result;
  }

  TextSelection toDocument(TextSelection selection) => selection.copyWith(
    baseOffset: documentOffset(selection.baseOffset),
    extentOffset: documentOffset(selection.extentOffset),
  );

  TextSelection toEditable(TextSelection selection) {
    if (selection.isCollapsed) {
      return selection.copyWith(
        baseOffset: editableOffset(
          selection.baseOffset,
          beforeControls: selection.affinity == TextAffinity.upstream,
        ),
        extentOffset: editableOffset(
          selection.extentOffset,
          beforeControls: selection.affinity == TextAffinity.upstream,
        ),
      );
    }
    return selection.copyWith(
      baseOffset: editableOffset(
        selection.baseOffset,
        beforeControls: selection.baseOffset == selection.end,
      ),
      extentOffset: editableOffset(
        selection.extentOffset,
        beforeControls: selection.extentOffset == selection.end,
      ),
    );
  }

  _InlineDirectionText afterEdit(TextSelection previousSelection, String next) {
    if (next == text) return this;
    if (controls.isEmpty) return _InlineDirectionText(next, const []);
    var prefix = 0;
    // Prefer the previous selection edges when equal text can be attributed
    // either to an insertion or to one of the old generated controls.
    final anchored =
        previousSelection.isValid &&
        next.startsWith(text.substring(0, previousSelection.start)) &&
        next.endsWith(text.substring(previousSelection.end)) &&
        next.length >=
            text.length - (previousSelection.end - previousSelection.start);
    if (anchored) {
      prefix = previousSelection.start;
    } else {
      while (prefix < text.length &&
          prefix < next.length &&
          text.codeUnitAt(prefix) == next.codeUnitAt(prefix)) {
        prefix++;
      }
    }
    var oldEnd = text.length;
    final delta = next.length - text.length;
    if (anchored) {
      oldEnd = previousSelection.end;
    } else {
      while (oldEnd > prefix &&
          oldEnd + delta > prefix &&
          text.codeUnitAt(oldEnd - 1) == next.codeUnitAt(oldEnd + delta - 1)) {
        oldEnd--;
      }
    }
    return _InlineDirectionText(next, [
      for (final offset in controls)
        if (offset < prefix) offset else if (offset >= oldEnd) offset + delta,
    ]);
  }
}

TextSelection _clampedSelection(TextSelection selection, int textLength) {
  if (!selection.isValid) {
    return TextSelection.collapsed(offset: textLength);
  }
  return TextSelection(
    baseOffset: selection.baseOffset.clamp(0, textLength).toInt(),
    extentOffset: selection.extentOffset.clamp(0, textLength).toInt(),
    affinity: selection.affinity,
    isDirectional: selection.isDirectional,
  );
}

List<BusyInlineStyleRange> busyInlineStyleRanges(
  List<BusyInline> inlines, {
  bool includeHtml = false,
}) {
  final ranges = <BusyInlineStyleRange>[];
  var offset = 0;

  void visit(BusyInline inline, List<_InheritedInlineStyle> inheritedStyles) {
    final start = offset;
    final children = inline.children;
    final styled =
        _styledKind(inline.kind) ||
        includeHtml &&
            inline.kind == BusyInlineKind.html &&
            semanticHtmlInlineTag(inline.attributes) != null;
    final ownStyle = styled
        ? _InheritedInlineStyle(
            inline.kind,
            inline.destination,
            inline.attributes,
          )
        : null;
    final effectiveStyles = ownStyle == null
        ? inheritedStyles
        : [...inheritedStyles, ownStyle];
    if (children.isEmpty) {
      offset += inline.plainText.length;
    } else {
      for (final child in children) {
        visit(child, effectiveStyles);
      }
      return;
    }
    final end = offset;
    if (end > start) {
      for (final style in effectiveStyles) {
        ranges.add(
          BusyInlineStyleRange(
            start: start,
            end: end,
            kind: style.kind,
            destination: style.destination,
            attributes: style.attributes,
          ),
        );
      }
    }
  }

  for (final inline in inlines) {
    visit(inline, const []);
  }
  return ranges;
}

List<BusyInlineStyleRange> _normalizedRanges(
  List<BusyInlineStyleRange> ranges,
  int textLength,
) {
  return [
    for (final range in ranges)
      if (range.end > range.start)
        BusyInlineStyleRange(
          start: range.start.clamp(0, textLength).toInt(),
          end: range.end.clamp(0, textLength).toInt(),
          kind: range.kind,
          destination: range.destination,
          attributes: range.attributes,
        ),
  ].where((range) => range.end > range.start).toList()..sort((a, b) {
    final byStart = a.start.compareTo(b.start);
    return byStart == 0 ? a.end.compareTo(b.end) : byStart;
  });
}

List<BusyInlineStyleRange> _activeRangesForSegment(
  List<BusyInlineStyleRange> ranges,
  int start,
  int end,
) {
  final byKind = <BusyInlineKind, BusyInlineStyleRange>{};
  for (final range in ranges) {
    if (range.start <= start && range.end >= end) {
      byKind[range.kind] = range;
    }
  }
  return byKind.values.toList()..sort(_compareRangesByStylePriority);
}

int _compareRangesByStylePriority(
  BusyInlineStyleRange a,
  BusyInlineStyleRange b,
) {
  return _stylePriority(a.kind).compareTo(_stylePriority(b.kind));
}

int _stylePriority(BusyInlineKind kind) {
  return switch (kind) {
    BusyInlineKind.link => 0,
    BusyInlineKind.strong => 1,
    BusyInlineKind.emphasis => 2,
    BusyInlineKind.underline => 3,
    BusyInlineKind.strikethrough => 4,
    BusyInlineKind.code => 5,
    BusyInlineKind.image => 6,
    _ => 7,
  };
}

class _InheritedInlineStyle {
  const _InheritedInlineStyle(this.kind, this.destination, this.attributes);

  final BusyInlineKind kind;
  final String? destination;
  final Map<String, String> attributes;
}

bool _styledKind(BusyInlineKind kind) {
  return busyMarkIsSemanticInline(kind) ||
      kind == BusyInlineKind.writersideVariable ||
      {
        BusyInlineKind.strong,
        BusyInlineKind.emphasis,
        BusyInlineKind.underline,
        BusyInlineKind.strikethrough,
        BusyInlineKind.code,
        BusyInlineKind.link,
        BusyInlineKind.image,
      }.contains(kind);
}

bool _inlineStyleRangesEqual(
  List<BusyInlineStyleRange> a,
  List<BusyInlineStyleRange> b,
) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index++) {
    final left = a[index];
    final right = b[index];
    if (left.start != right.start ||
        left.end != right.end ||
        left.kind != right.kind ||
        left.destination != right.destination ||
        !mapEquals(left.attributes, right.attributes)) {
      return false;
    }
  }
  return true;
}
