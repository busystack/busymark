import 'package:flutter/material.dart';

import '../../app/busymark_design.dart';
import '../../markdown/busymark_document.dart';
import '../../markdown/busymark_markdown_serializer.dart';

bool busyMarkWysiwygBlockContainsMath(BusyBlock block) {
  bool contains(List<BusyInline> inlines) => inlines.any(
    (inline) => inline.kind == BusyInlineKind.math || contains(inline.children),
  );
  return block.kind == BusyBlockKind.math ||
      contains(block.inlines) ||
      block.children.any(busyMarkWysiwygBlockContainsMath);
}

String busyMarkWysiwygEditableText(BusyBlock block) {
  if (!busyMarkWysiwygBlockContainsMath(block)) {
    return block.plainText;
  }
  if (block.kind != BusyBlockKind.math && block.inlines.isNotEmpty) {
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

class BusyInlineStyleRange {
  const BusyInlineStyleRange({
    required this.start,
    required this.end,
    required this.kind,
    this.destination,
  });

  final int start;
  final int end;
  final BusyInlineKind kind;
  final String? destination;
}

class BusyMarkWysiwygTextController extends TextEditingController {
  BusyMarkWysiwygTextController({
    required String text,
    required List<BusyInlineStyleRange> ranges,
  }) : _ranges = ranges,
       super(text: text);

  List<BusyInlineStyleRange> _ranges;

  void updateFromBlock(BusyBlock block) {
    final sourceEditing = busyMarkWysiwygBlockContainsMath(block);
    final nextText = busyMarkWysiwygEditableText(block);
    final nextRanges = sourceEditing
        ? const <BusyInlineStyleRange>[]
        : busyInlineStyleRanges(block.inlines);
    final rangesChanged = !_inlineStyleRangesEqual(_ranges, nextRanges);
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
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    if (text.isEmpty || _ranges.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }
    final spans = <TextSpan>[];
    final ranges = _normalizedRanges(_ranges, text.length);
    final boundaries = <int>{0, text.length};
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
      spans.add(
        TextSpan(
          text: text.substring(start, end),
          style: _styleForRanges(
            context,
            _activeRangesForSegment(ranges, start, end),
            baseStyle,
          ),
        ),
      );
    }
    return TextSpan(style: baseStyle, children: spans);
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
      BusyInlineKind.code => baseStyle.copyWith(
        fontFamily: BusyMarkTypography.monoFontFamily,
        backgroundColor: colors.control,
      ),
      BusyInlineKind.link => baseStyle.copyWith(
        color: colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
      BusyInlineKind.image => baseStyle.copyWith(
        color: colorScheme.primary,
        fontStyle: FontStyle.italic,
      ),
      _ => baseStyle,
    };
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

List<BusyInlineStyleRange> busyInlineStyleRanges(List<BusyInline> inlines) {
  final ranges = <BusyInlineStyleRange>[];
  var offset = 0;

  void visit(BusyInline inline, List<_InheritedInlineStyle> inheritedStyles) {
    final start = offset;
    final children = inline.children;
    final ownStyle = _styledKind(inline.kind)
        ? _InheritedInlineStyle(inline.kind, inline.destination)
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
        if (!_styledKind(style.kind)) {
          continue;
        }
        ranges.add(
          BusyInlineStyleRange(
            start: start,
            end: end,
            kind: style.kind,
            destination: style.destination,
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
  const _InheritedInlineStyle(this.kind, this.destination);

  final BusyInlineKind kind;
  final String? destination;
}

bool _styledKind(BusyInlineKind kind) {
  return {
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
        left.destination != right.destination) {
      return false;
    }
  }
  return true;
}
