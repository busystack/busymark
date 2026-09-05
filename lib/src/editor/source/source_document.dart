import 'package:flutter/services.dart';

import 'source_hidden_ranges.dart';
import 'source_line_index.dart';

class SourceVisibleEdit {
  const SourceVisibleEdit({
    required this.visibleStart,
    required this.visibleEnd,
    required this.fullStart,
    required this.fullEnd,
    required this.replacement,
    required this.replacedFullText,
  });

  final int visibleStart;
  final int visibleEnd;
  final int fullStart;
  final int fullEnd;
  final String replacement;
  final String replacedFullText;

  int get fullDelta => replacement.length - replacedFullText.length;

  int get lineDelta =>
      _lineBreakCount(replacement) - _lineBreakCount(replacedFullText);
}

class SourceDocument {
  SourceDocument({required this.fullText, SourceHiddenRanges? hiddenRanges})
    : hiddenRanges =
          hiddenRanges ??
          SourceHiddenRanges(ranges: const [], textLength: fullText.length),
      lineIndex = SourceLineIndex(fullText) {
    visibleText = this.hiddenRanges.visibleTextFor(fullText);
    visibleLineIndex = SourceLineIndex(visibleText);
  }

  SourceDocument._({
    required this.fullText,
    required this.hiddenRanges,
    required this.lineIndex,
    required this.visibleText,
    required this.visibleLineIndex,
  });

  factory SourceDocument.afterVisibleEdit({
    required SourceDocument previous,
    required String fullText,
    required SourceHiddenRanges hiddenRanges,
    required SourceVisibleEdit edit,
  }) {
    final visibleText = hiddenRanges.visibleTextFor(fullText);
    final visibleChange = _changedRange(previous.visibleText, visibleText);
    return SourceDocument._(
      fullText: fullText,
      hiddenRanges: hiddenRanges,
      lineIndex: SourceLineIndex.updated(
        previous: previous.lineIndex,
        source: fullText,
        oldStart: edit.fullStart,
        oldEnd: edit.fullEnd,
      ),
      visibleText: visibleText,
      visibleLineIndex: SourceLineIndex.updated(
        previous: previous.visibleLineIndex,
        source: visibleText,
        oldStart: visibleChange.oldStart,
        oldEnd: visibleChange.oldEnd,
      ),
    );
  }

  final String fullText;
  final SourceHiddenRanges hiddenRanges;
  final SourceLineIndex lineIndex;
  late final String visibleText;
  late final SourceLineIndex visibleLineIndex;

  bool get hasHiddenRanges => hiddenRanges.isNotEmpty;

  int fullOffsetToVisibleOffset(int fullOffset) {
    return hiddenRanges.fullToVisibleOffset(fullOffset);
  }

  int visibleOffsetToFullOffset(
    int visibleOffset, {
    SourceHiddenAffinity affinity = SourceHiddenAffinity.downstream,
  }) {
    return hiddenRanges.visibleToFullOffset(visibleOffset, affinity: affinity);
  }

  SourceMappedRange fullRangeToVisibleRange(int start, int end) {
    return hiddenRanges.fullRangeToVisibleRange(start, end);
  }

  SourceMappedRange visibleRangeToFullRange(int start, int end) {
    return hiddenRanges.visibleRangeToFullRange(start, end);
  }

  TextSelection fullSelectionToVisibleSelection(TextSelection selection) {
    if (!selection.isValid) {
      return TextSelection.collapsed(offset: visibleText.length);
    }
    final start = fullOffsetToVisibleOffset(selection.baseOffset);
    final end = fullOffsetToVisibleOffset(selection.extentOffset);
    return selection.copyWith(
      baseOffset: start.clamp(0, visibleText.length).toInt(),
      extentOffset: end.clamp(0, visibleText.length).toInt(),
    );
  }

  TextSelection visibleSelectionToFullSelection(TextSelection selection) {
    if (!selection.isValid) {
      return TextSelection.collapsed(offset: fullText.length);
    }
    if (selection.isCollapsed) {
      return TextSelection.collapsed(
        offset: visibleOffsetToFullOffset(
          selection.extentOffset,
          affinity: _hiddenAffinityForTextSelection(selection),
        ),
        affinity: selection.affinity,
      );
    }
    final fullStart = visibleOffsetToFullOffset(
      selection.start,
      affinity: SourceHiddenAffinity.downstream,
    );
    final fullEnd = visibleOffsetToFullOffset(
      selection.end,
      affinity: SourceHiddenAffinity.upstream,
    );
    final forward = selection.baseOffset <= selection.extentOffset;
    return selection.copyWith(
      baseOffset: forward ? fullStart : fullEnd,
      extentOffset: forward ? fullEnd : fullStart,
    );
  }

  SourceLine? visibleLineForFullLine(int fullLineNumber) {
    if (fullLineNumber < 1 || fullLineNumber > lineIndex.lineCount) {
      return null;
    }
    final fullLine = lineIndex.lineAt(fullLineNumber);
    if (hiddenRanges.isFullOffsetHidden(fullLine.startOffset)) {
      return null;
    }
    final visibleOffset = fullOffsetToVisibleOffset(fullLine.startOffset);
    return visibleLineIndex.lineAtOffset(visibleOffset);
  }

  SourceVisibleEdit describeVisibleEdit(String newVisibleText) {
    final diff = _changedRange(visibleText, newVisibleText);
    final collapsedInsertion = diff.oldStart == diff.oldEnd;
    final fullStart = visibleOffsetToFullOffset(
      diff.oldStart,
      affinity: collapsedInsertion
          ? SourceHiddenAffinity.downstream
          : _startAffinityForVisibleEdit(diff.oldStart, diff.oldEnd),
    );
    final fullEnd = collapsedInsertion
        ? fullStart
        : visibleOffsetToFullOffset(
            diff.oldEnd,
            affinity: _endAffinityForVisibleEdit(diff.oldStart, diff.oldEnd),
          );
    return SourceVisibleEdit(
      visibleStart: diff.oldStart,
      visibleEnd: diff.oldEnd,
      fullStart: fullStart,
      fullEnd: fullEnd,
      replacement: newVisibleText.substring(diff.newStart, diff.newEnd),
      replacedFullText: fullText.substring(fullStart, fullEnd),
    );
  }

  SourceHiddenAffinity _startAffinityForVisibleEdit(int start, int end) {
    if (start < end && _isCollapsedHiddenBoundary(start)) {
      return SourceHiddenAffinity.upstream;
    }
    return SourceHiddenAffinity.downstream;
  }

  SourceHiddenAffinity _endAffinityForVisibleEdit(int start, int end) {
    if (start < end && _isCollapsedHiddenBoundary(end)) {
      return SourceHiddenAffinity.downstream;
    }
    return SourceHiddenAffinity.upstream;
  }

  bool _isCollapsedHiddenBoundary(int visibleOffset) {
    return visibleOffsetToFullOffset(
          visibleOffset,
          affinity: SourceHiddenAffinity.downstream,
        ) !=
        visibleOffsetToFullOffset(
          visibleOffset,
          affinity: SourceHiddenAffinity.upstream,
        );
  }

  String applyVisibleEdit(String newVisibleText) {
    final edit = describeVisibleEdit(newVisibleText);
    return fullText.replaceRange(
      edit.fullStart,
      edit.fullEnd,
      edit.replacement,
    );
  }
}

({int oldStart, int oldEnd, int newStart, int newEnd}) _changedRange(
  String oldText,
  String newText,
) {
  var start = 0;
  final shortest = oldText.length < newText.length
      ? oldText.length
      : newText.length;
  while (start < shortest &&
      oldText.codeUnitAt(start) == newText.codeUnitAt(start)) {
    start++;
  }

  var oldEnd = oldText.length;
  var newEnd = newText.length;
  while (oldEnd > start &&
      newEnd > start &&
      oldText.codeUnitAt(oldEnd - 1) == newText.codeUnitAt(newEnd - 1)) {
    oldEnd--;
    newEnd--;
  }

  return (oldStart: start, oldEnd: oldEnd, newStart: start, newEnd: newEnd);
}

SourceHiddenAffinity _hiddenAffinityForTextSelection(TextSelection selection) {
  return switch (selection.affinity) {
    TextAffinity.upstream => SourceHiddenAffinity.upstream,
    TextAffinity.downstream => SourceHiddenAffinity.downstream,
  };
}

int _lineBreakCount(String text) {
  var count = 0;
  for (var index = 0; index < text.length; index++) {
    final unit = text.codeUnitAt(index);
    if (unit == 10) {
      count++;
    } else if (unit == 13) {
      count++;
      if (index + 1 < text.length && text.codeUnitAt(index + 1) == 10) {
        index++;
      }
    }
  }
  return count;
}
