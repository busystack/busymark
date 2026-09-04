import 'dart:math' as math;

import 'package:flutter/services.dart';

enum SourceInlineCommand { bold, italic, underline, strikethrough, code, link }

enum SourceBlockCommand {
  paragraph,
  heading1,
  heading2,
  heading3,
  heading4,
  heading5,
  heading6,
  orderedList,
  unorderedList,
  taskList,
}

abstract final class SourceCommands {
  const SourceCommands._();

  static const int defaultIndentWidth = 2;

  static TextEditingValue insertTab(
    TextEditingValue value, {
    int indentWidth = defaultIndentWidth,
  }) {
    if (!_normalizedSelection(value).isCollapsed) {
      return indentSelection(value, indentWidth: indentWidth);
    }
    return _replaceSelection(value, ' ' * indentWidth);
  }

  static TextEditingValue indentSelection(
    TextEditingValue value, {
    int indentWidth = defaultIndentWidth,
  }) {
    final range = _selectedLineRange(value);
    final prefix = ' ' * indentWidth;
    return _replaceLineRange(
      value,
      range,
      [
        for (final line in range.lines) line.isEmpty ? line : '$prefix$line',
      ].join('\n'),
    );
  }

  static TextEditingValue outdentSelection(
    TextEditingValue value, {
    int indentWidth = defaultIndentWidth,
  }) {
    final range = _selectedLineRange(value);
    return _replaceLineRange(
      value,
      range,
      [
        for (final line in range.lines)
          if (line.startsWith(' ' * indentWidth))
            line.substring(indentWidth)
          else if (line.startsWith('\t'))
            line.substring(1)
          else if (line.startsWith(' '))
            line.substring(math.min(indentWidth, _leadingSpaces(line)))
          else
            line,
      ].join('\n'),
    );
  }

  static TextEditingValue smartEnter(
    TextEditingValue value, {
    int indentWidth = defaultIndentWidth,
  }) {
    final selection = _normalizedSelection(value);
    if (!selection.isCollapsed) {
      return _replaceSelection(value, '\n');
    }
    final text = value.text;
    final lineStart =
        text.lastIndexOf('\n', math.max(0, selection.start - 1)) + 1;
    final lineEnd = text.indexOf('\n', selection.start);
    final currentLine = text.substring(
      lineStart,
      lineEnd < 0 ? text.length : lineEnd,
    );
    final beforeCursor = text.substring(lineStart, selection.start);

    final emptyList = RegExp(
      r'^(\s*)(?:[-*+]|\d+[.)])\s+(?:\[[ xX]\]\s*)?$',
    ).firstMatch(beforeCursor);
    if (emptyList != null &&
        selection.start == lineStart + beforeCursor.length) {
      final replacement = '\n';
      final nextText = text.replaceRange(
        lineStart,
        selection.start,
        replacement,
      );
      final offset = lineStart + replacement.length;
      return TextEditingValue(
        text: nextText,
        selection: TextSelection.collapsed(offset: offset),
      );
    }

    final task = RegExp(
      r'^(\s*)([-*+]|\d+[.)])\s+\[[ xX]\]\s+',
    ).firstMatch(beforeCursor);
    if (task != null) {
      final marker = _nextListMarker(task.group(2)!);
      return _replaceSelection(value, '\n${task.group(1)!}$marker [ ] ');
    }

    final list = RegExp(r'^(\s*)([-*+]|\d+[.)])\s+').firstMatch(beforeCursor);
    if (list != null) {
      final marker = _nextListMarker(list.group(2)!);
      return _replaceSelection(value, '\n${list.group(1)!}$marker ');
    }

    final quote = RegExp(r'^(\s{0,3}>\s?)').firstMatch(currentLine);
    if (quote != null) {
      final marker = quote.group(1)!;
      if (beforeCursor.trim() == '>') {
        final nextText = text.replaceRange(lineStart, selection.start, '');
        return TextEditingValue(
          text: nextText,
          selection: TextSelection.collapsed(offset: lineStart),
        );
      }
      return _replaceSelection(value, '\n$marker');
    }

    return _replaceSelection(value, '\n');
  }

  static TextEditingValue applyInlineCommand(
    TextEditingValue value,
    SourceInlineCommand command, {
    required String placeholder,
  }) {
    return switch (command) {
      SourceInlineCommand.bold => _toggleWrap(
        value,
        '**',
        '**',
        placeholder: placeholder,
      ),
      SourceInlineCommand.italic => _toggleWrap(
        value,
        '*',
        '*',
        placeholder: placeholder,
      ),
      SourceInlineCommand.underline => _toggleWrap(
        value,
        '<u>',
        '</u>',
        placeholder: placeholder,
      ),
      SourceInlineCommand.strikethrough => _toggleWrap(
        value,
        '~~',
        '~~',
        placeholder: placeholder,
      ),
      SourceInlineCommand.code => _toggleWrap(
        value,
        '`',
        '`',
        placeholder: placeholder,
      ),
      SourceInlineCommand.link => insertLink(
        value,
        labelPlaceholder: placeholder,
      ),
    };
  }

  static TextEditingValue applyBlockCommand(
    TextEditingValue value,
    SourceBlockCommand command,
  ) {
    final range = _selectedLineRange(value);
    final markerPattern = RegExp(
      r'^(\s*)(?:#{1,6}\s+)?(?:[-*+]\s+(?:\[[ xX]\]\s+)?|\d+[.)]\s+)?(.*)$',
    );
    if (command == SourceBlockCommand.orderedList) {
      return _replaceLineRange(
        value,
        range,
        _orderedListLines(range.lines, markerPattern).join('\n'),
      );
    }
    final replacementLines = <String>[];
    for (final line in range.lines) {
      final match = markerPattern.firstMatch(line);
      final indent = match?.group(1) ?? '';
      final content = match?.group(2) ?? line.trimLeft();
      final marker = switch (command) {
        SourceBlockCommand.paragraph => '',
        SourceBlockCommand.heading1 => '# ',
        SourceBlockCommand.heading2 => '## ',
        SourceBlockCommand.heading3 => '### ',
        SourceBlockCommand.heading4 => '#### ',
        SourceBlockCommand.heading5 => '##### ',
        SourceBlockCommand.heading6 => '###### ',
        SourceBlockCommand.orderedList => throw StateError(
          'Ordered lists are handled above.',
        ),
        SourceBlockCommand.unorderedList => '- ',
        SourceBlockCommand.taskList => '- [ ] ',
      };
      replacementLines.add('$indent$marker$content');
    }
    return _replaceLineRange(value, range, replacementLines.join('\n'));
  }

  static TextEditingValue toggleTaskChecked(TextEditingValue value) {
    final range = _selectedLineRange(value);
    return _replaceLineRange(
      value,
      range,
      [
        for (final line in range.lines)
          line.replaceFirstMapped(
            RegExp(r'^(\s*[-*+]\s+\[)([ xX])(\]\s+)'),
            (match) =>
                '${match.group(1)}${match.group(2)!.trim().isEmpty ? 'x' : ' '}${match.group(3)}',
          ),
      ].join('\n'),
    );
  }

  static TextEditingValue applyLinePrefix(
    TextEditingValue value,
    String prefix,
  ) {
    final range = _selectedLineRange(value);
    return _replaceLineRange(
      value,
      range,
      [
        for (final line in range.lines)
          line.isEmpty ? prefix.trimRight() : '$prefix$line',
      ].join('\n'),
    );
  }

  static TextEditingValue insertCodeFence(
    TextEditingValue value, {
    String language = '',
    required String contentPlaceholder,
  }) {
    final selection = _normalizedSelection(value);
    final selected = selection.textInside(value.text);
    final content = selected.isEmpty ? contentPlaceholder : selected;
    final replacement = '```$language\n$content\n```';
    final contentStart = selection.start + 3 + language.length + 1;
    return _replaceSelection(
      value,
      replacement,
      selection: TextSelection(
        baseOffset: contentStart,
        extentOffset: contentStart + content.length,
      ),
    );
  }

  static TextEditingValue insertLink(
    TextEditingValue value, {
    required String labelPlaceholder,
  }) {
    final selection = _normalizedSelection(value);
    final selected = selection.textInside(value.text);
    final label = selected.isEmpty ? labelPlaceholder : selected;
    final replacement = '[$label](url)';
    final urlStart = selection.start + label.length + 3;
    return _replaceSelection(
      value,
      replacement,
      selection: TextSelection(
        baseOffset: urlStart,
        extentOffset: urlStart + 3,
      ),
    );
  }

  static TextEditingValue insertImage(
    TextEditingValue value, {
    required bool block,
    required String altPlaceholder,
  }) {
    final selection = _normalizedSelection(value);
    final selected = selection.textInside(value.text).trim();
    final alt = selected.isEmpty ? altPlaceholder : selected;
    final replacement = '![${alt.replaceAll('\n', ' ')}](url)';
    final inserted = block ? '\n$replacement\n' : replacement;
    final altStart = selection.start + (block ? 3 : 2);
    return _replaceSelection(
      value,
      inserted,
      selection: TextSelection(
        baseOffset: altStart,
        extentOffset: altStart + alt.length,
      ),
    );
  }

  static TextEditingValue insertTable(
    TextEditingValue value, {
    required String Function(int columnNumber) headerTextForColumn,
    required String cellText,
  }) {
    return _replaceSelection(
      value,
      '\n| ${headerTextForColumn(1)} | ${headerTextForColumn(2)} |\n'
      '| --- | --- |\n| $cellText | $cellText |\n',
    );
  }

  static TextEditingValue insertHtmlBlock(
    TextEditingValue value, {
    required String defaultContent,
  }) {
    final selection = _normalizedSelection(value);
    final selected = selection.textInside(value.text).trim();
    final content = selected.isEmpty ? defaultContent : selected;
    final replacement = '\n<div>\n  <p>$content</p>\n</div>\n';
    final contentStart = selection.start + replacement.indexOf(content);
    return _replaceSelection(
      value,
      replacement,
      selection: TextSelection(
        baseOffset: contentStart,
        extentOffset: contentStart + content.length,
      ),
    );
  }

  static TextEditingValue insertBlock(TextEditingValue value, String markdown) {
    final selection = _normalizedSelection(value);
    return _replaceSelection(
      value,
      markdown,
      selection: TextSelection.collapsed(
        offset: selection.start + markdown.length,
      ),
    );
  }
}

({int start, int end, List<String> lines}) _selectedLineRange(
  TextEditingValue value,
) {
  final selection = _normalizedSelection(value);
  final text = value.text;
  var effectiveEnd = selection.end;
  if (!selection.isCollapsed &&
      effectiveEnd > selection.start &&
      text.codeUnitAt(effectiveEnd - 1) == 0x0a) {
    effectiveEnd -= 1;
  }
  final lineStart =
      text.lastIndexOf('\n', math.max(0, selection.start - 1)) + 1;
  final nextBreak = text.indexOf('\n', effectiveEnd);
  final lineEnd = nextBreak < 0 ? text.length : nextBreak;
  return (
    start: lineStart,
    end: lineEnd,
    lines: text.substring(lineStart, lineEnd).split('\n'),
  );
}

List<String> _orderedListLines(List<String> lines, RegExp markerPattern) {
  final levels = <_OrderedListLevel>[];
  final result = <String>[];
  for (final line in lines) {
    final match = markerPattern.firstMatch(line);
    final inputIndent = match?.group(1) ?? '';
    final inputColumns = _indentColumns(inputIndent);
    final content = match?.group(2) ?? line.trimLeft();
    while (levels.isNotEmpty && levels.last.inputColumns > inputColumns) {
      levels.removeLast();
    }
    if (levels.isEmpty || levels.last.inputColumns < inputColumns) {
      final outputIndent = levels.isEmpty
          ? inputIndent
          : '${levels.last.outputIndent}${' ' * (levels.last.markerWidth + 1)}';
      levels.add(
        _OrderedListLevel(
          inputColumns: inputColumns,
          outputIndent: outputIndent,
        ),
      );
    }
    final level = levels.last;
    level.number += 1;
    final marker = '${level.number}.';
    level.markerWidth = marker.length;
    result.add('${level.outputIndent}$marker $content');
  }
  return result;
}

int _indentColumns(String indentation) {
  var columns = 0;
  for (final codeUnit in indentation.codeUnits) {
    columns += codeUnit == 0x09 ? 4 : 1;
  }
  return columns;
}

class _OrderedListLevel {
  _OrderedListLevel({required this.inputColumns, required this.outputIndent});

  final int inputColumns;
  final String outputIndent;
  int number = 0;
  int markerWidth = 2;
}

TextSelection _normalizedSelection(TextEditingValue value) {
  final selection = value.selection;
  if (!selection.isValid) {
    return TextSelection.collapsed(offset: value.text.length);
  }
  final start = selection.start.clamp(0, value.text.length).toInt();
  final end = selection.end.clamp(0, value.text.length).toInt();
  return TextSelection(
    baseOffset: math.min(start, end),
    extentOffset: math.max(start, end),
    affinity: selection.affinity,
    isDirectional: selection.isDirectional,
  );
}

TextEditingValue _replaceLineRange(
  TextEditingValue value,
  ({int start, int end, List<String> lines}) range,
  String replacement,
) {
  final nextText = value.text.replaceRange(range.start, range.end, replacement);
  return TextEditingValue(
    text: nextText,
    selection: TextSelection(
      baseOffset: range.start,
      extentOffset: range.start + replacement.length,
    ),
  );
}

TextEditingValue _replaceSelection(
  TextEditingValue value,
  String replacement, {
  TextSelection? selection,
}) {
  final normalized = _normalizedSelection(value);
  final nextText =
      normalized.textBefore(value.text) +
      replacement +
      normalized.textAfter(value.text);
  return TextEditingValue(
    text: nextText,
    selection:
        selection ??
        TextSelection.collapsed(offset: normalized.start + replacement.length),
  );
}

TextEditingValue _toggleWrap(
  TextEditingValue value,
  String prefix,
  String suffix, {
  required String placeholder,
}) {
  final selection = _normalizedSelection(value);
  final text = value.text;
  if (selection.start >= prefix.length &&
      selection.end + suffix.length <= text.length &&
      text.substring(selection.start - prefix.length, selection.start) ==
          prefix &&
      text.substring(selection.end, selection.end + suffix.length) == suffix) {
    final unwrapped = text
        .replaceRange(selection.end, selection.end + suffix.length, '')
        .replaceRange(selection.start - prefix.length, selection.start, '');
    return TextEditingValue(
      text: unwrapped,
      selection: TextSelection(
        baseOffset: selection.start - prefix.length,
        extentOffset: selection.end - prefix.length,
      ),
    );
  }
  final selected = selection.textInside(text);
  final content = selected.isEmpty ? placeholder : selected;
  final replacement = '$prefix$content$suffix';
  return _replaceSelection(
    value,
    replacement,
    selection: TextSelection(
      baseOffset: selection.start + prefix.length,
      extentOffset: selection.start + prefix.length + content.length,
    ),
  );
}

int _leadingSpaces(String line) {
  var count = 0;
  while (count < line.length && line.codeUnitAt(count) == 32) {
    count++;
  }
  return count;
}

String _nextListMarker(String marker) {
  final ordered = RegExp(r'^(\d+)([.)])$').firstMatch(marker);
  if (ordered == null) {
    return marker;
  }
  final number = int.tryParse(ordered.group(1)!) ?? 1;
  return '${number + 1}${ordered.group(2)!}';
}
