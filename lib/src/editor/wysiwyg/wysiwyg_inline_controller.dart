import 'package:flutter/material.dart';

import '../../markdown/busymark_document.dart';

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
    final nextText = block.plainText;
    _ranges = busyInlineStyleRanges(block.inlines);
    if (text != nextText) {
      value = value.copyWith(
        text: nextText,
        selection: TextSelection.collapsed(
          offset: nextText.length.clamp(0, nextText.length),
        ),
        composing: TextRange.empty,
      );
    } else {
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
    var offset = 0;
    final ranges = [..._ranges]..sort((a, b) => a.start.compareTo(b.start));
    for (final range in ranges) {
      final start = range.start.clamp(0, text.length).toInt();
      final end = range.end.clamp(start, text.length).toInt();
      if (start > offset) {
        spans.add(TextSpan(text: text.substring(offset, start)));
      }
      if (end > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, end),
            style: _styleForRange(context, range, baseStyle),
          ),
        );
      }
      offset = end;
    }
    if (offset < text.length) {
      spans.add(TextSpan(text: text.substring(offset)));
    }
    return TextSpan(style: baseStyle, children: spans);
  }

  TextStyle _styleForRange(
    BuildContext context,
    BusyInlineStyleRange range,
    TextStyle baseStyle,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (range.kind) {
      BusyInlineKind.strong => baseStyle.copyWith(fontWeight: FontWeight.w700),
      BusyInlineKind.emphasis => baseStyle.copyWith(
        fontStyle: FontStyle.italic,
      ),
      BusyInlineKind.strikethrough => baseStyle.copyWith(
        decoration: TextDecoration.lineThrough,
      ),
      BusyInlineKind.code => baseStyle.copyWith(fontFamily: 'Ubuntu Mono'),
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

List<BusyInlineStyleRange> busyInlineStyleRanges(List<BusyInline> inlines) {
  final ranges = <BusyInlineStyleRange>[];
  var offset = 0;

  void visit(BusyInline inline, BusyInlineKind? inheritedKind) {
    final start = offset;
    final children = inline.children;
    if (children.isEmpty) {
      offset += inline.plainText.length;
    } else {
      for (final child in children) {
        visit(child, inline.kind);
      }
    }
    final end = offset;
    final kind = _styledKind(inline.kind) ? inline.kind : inheritedKind;
    if (kind != null && end > start && _styledKind(kind)) {
      ranges.add(
        BusyInlineStyleRange(
          start: start,
          end: end,
          kind: kind,
          destination: inline.destination,
        ),
      );
    }
  }

  for (final inline in inlines) {
    visit(inline, null);
  }
  return ranges;
}

bool _styledKind(BusyInlineKind kind) {
  return {
    BusyInlineKind.strong,
    BusyInlineKind.emphasis,
    BusyInlineKind.strikethrough,
    BusyInlineKind.code,
    BusyInlineKind.link,
    BusyInlineKind.image,
  }.contains(kind);
}
