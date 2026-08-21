import 'package:markdown/markdown.dart' as md;

import 'markdown_model.dart';

const busyMarkMathInlineTag = 'busymark-math-inline';
const busyMarkMathBlockTag = 'busymark-math-block';
const busyMarkMathExpressionAttribute = 'mathExpression';
const busyMarkMathDisplayAttribute = 'mathDisplay';
const busyMarkMathSourceFormAttribute = 'mathSourceForm';

enum BusyMathSourceForm {
  dollarInline,
  githubDollarBacktick,
  doubleDollarDisplay,
  mathFence,
  writersideTexFence,
  writersideElement,
}

BusyMathSourceForm busyMathSourceFormFromName(String? value) {
  return BusyMathSourceForm.values.firstWhere(
    (form) => form.name == value,
    orElse: () => BusyMathSourceForm.dollarInline,
  );
}

md.Document busyMarkMarkdownDocument(MarkdownMode mode) {
  return md.Document(
    blockSyntaxes: const [BusyDisplayMathSyntax()],
    inlineSyntaxes: [
      BusyDollarMathSyntax(),
      if (mode == MarkdownMode.writersideMarkdown) BusyWritersideMathSyntax(),
    ],
    extensionSet: md.ExtensionSet.gitHubWeb,
    encodeHtml: false,
  );
}

class BusyDollarMathSyntax extends md.InlineSyntax {
  BusyDollarMathSyntax() : super(r'\$', startCharacter: 0x24);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final source = parser.source;
    final start = match.start;
    if (_isEscaped(source, start)) {
      parser.addNode(md.Text(r'$'));
      parser.consume(1);
      return false;
    }

    if (source.startsWith(r'$`', start)) {
      final end = _findGithubClose(source, start + 2);
      if (end != null) {
        final expression = source.substring(start + 2, end);
        if (expression.isNotEmpty) {
          parser.addNode(
            _mathElement(
              busyMarkMathInlineTag,
              expression,
              BusyMathSourceForm.githubDollarBacktick,
              display: false,
            ),
          );
          parser.consume(end + 2 - start);
          return false;
        }
      }
    }

    // A double-dollar run belongs to the display block syntax. If it occurs
    // in ordinary paragraph text, leave it literal rather than accidentally
    // interpreting the second dollar as an inline opener.
    if (source.startsWith(r'$$', start)) {
      parser.addNode(md.Text(r'$$'));
      parser.consume(2);
      return false;
    }

    final end = _findDollarClose(source, start + 1);
    if (end != null) {
      final expression = source.substring(start + 1, end);
      parser.addNode(
        _mathElement(
          busyMarkMathInlineTag,
          expression,
          BusyMathSourceForm.dollarInline,
          display: false,
        ),
      );
      parser.consume(end + 1 - start);
      return false;
    }

    parser.addNode(md.Text(r'$'));
    parser.consume(1);
    return false;
  }

  int? _findGithubClose(String source, int expressionStart) {
    var index = expressionStart;
    while (index + 1 < source.length) {
      if (source.codeUnitAt(index) == 0x0a ||
          source.codeUnitAt(index) == 0x0d) {
        return null;
      }
      if (source.startsWith(r'`$', index) && !_isEscaped(source, index)) {
        return index;
      }
      index += 1;
    }
    return null;
  }

  int? _findDollarClose(String source, int expressionStart) {
    if (expressionStart >= source.length ||
        _isWhitespace(source.codeUnitAt(expressionStart))) {
      return null;
    }
    var index = expressionStart;
    while (index < source.length) {
      final unit = source.codeUnitAt(index);
      if (unit == 0x0a || unit == 0x0d) {
        return null;
      }
      if (unit == 0x60) {
        return null;
      }
      if (unit == 0x24 && !_isEscaped(source, index)) {
        if (index == expressionStart ||
            _isWhitespace(source.codeUnitAt(index - 1))) {
          // This dollar can begin a later expression, so it terminates the
          // current candidate instead of allowing currency to swallow it.
          return null;
        }
        final next = index + 1 < source.length
            ? source.codeUnitAt(index + 1)
            : null;
        // This avoids consuming currency ranges such as `$5-$10`.
        if (next != null && next >= 0x30 && next <= 0x39) {
          return null;
        }
        return index;
      }
      index += 1;
    }
    return null;
  }
}

class BusyWritersideMathSyntax extends md.InlineSyntax {
  BusyWritersideMathSyntax()
    : super(r'<math(?:\s[^>]*)?>', startCharacter: 0x3c, caseSensitive: false);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final close = RegExp(
      r'</math\s*>',
      caseSensitive: false,
    ).matchAsPrefix(parser.source, match.end);
    final end =
        close ??
        RegExp(
          r'</math\s*>',
          caseSensitive: false,
        ).firstMatch(parser.source.substring(match.end));
    if (end == null) {
      parser.addNode(md.Text(match.group(0)!));
      return true;
    }
    final closeStart = close == null ? match.end + end.start : end.start;
    final closeEnd = close == null ? match.end + end.end : end.end;
    final expression = parser.source.substring(match.end, closeStart);
    if (expression.isEmpty || expression.contains('\n')) {
      parser.addNode(md.Text(match.group(0)!));
      return true;
    }
    parser.addNode(
      _mathElement(
        busyMarkMathInlineTag,
        expression,
        BusyMathSourceForm.writersideElement,
        display: false,
      ),
    );
    parser.consume(closeEnd - match.start);
    return false;
  }
}

class BusyDisplayMathSyntax extends md.BlockSyntax {
  const BusyDisplayMathSyntax();

  @override
  RegExp get pattern => RegExp(r'^ {0,3}\$\$(?!\$)');

  @override
  bool canParse(md.BlockParser parser) {
    if (!pattern.hasMatch(parser.current.content)) {
      return false;
    }
    final first = parser.current.content;
    final opening = first.indexOf(r'$$');
    final firstClose = _displayClose(first, opening + 2);
    if (firstClose != null) {
      return first.substring(opening + 2, firstClose).trim().isNotEmpty;
    }
    final expression = StringBuffer(first.substring(opening + 2));
    var ahead = 1;
    while (true) {
      final line = parser.peek(ahead);
      if (line == null) {
        break;
      }
      final close = _displayClose(line.content, 0);
      if (close != null) {
        if (expression.isNotEmpty) expression.writeln();
        expression.write(line.content.substring(0, close));
        return expression.toString().trim().isNotEmpty;
      }
      if (expression.isNotEmpty) expression.writeln();
      expression.write(line.content);
      ahead += 1;
    }
    // An unclosed delimiter remains ordinary Markdown text.
    return false;
  }

  @override
  md.Node parse(md.BlockParser parser) {
    final first = parser.current.content;
    final opening = first.indexOf(r'$$');
    final tail = first.substring(opening + 2);
    final lines = <String>[];
    final firstClose = _displayClose(tail, 0);
    if (firstClose != null) {
      lines.add(tail.substring(0, firstClose));
      parser.advance();
    } else {
      if (tail.isNotEmpty) {
        lines.add(tail);
      }
      parser.advance();
      while (!parser.isDone) {
        final line = parser.current.content;
        final close = _displayClose(line, 0);
        if (close != null) {
          if (close > 0) {
            lines.add(line.substring(0, close));
          }
          parser.advance();
          break;
        }
        lines.add(line);
        parser.advance();
      }
    }
    return _mathElement(
      busyMarkMathBlockTag,
      lines.join('\n'),
      BusyMathSourceForm.doubleDollarDisplay,
      display: true,
    );
  }

  @override
  bool canEndBlock(md.BlockParser parser) => true;
}

md.Element _mathElement(
  String tag,
  String expression,
  BusyMathSourceForm sourceForm, {
  required bool display,
}) {
  return md.Element.text(tag, expression)
    ..attributes[busyMarkMathExpressionAttribute] = expression
    ..attributes[busyMarkMathDisplayAttribute] = '$display'
    ..attributes[busyMarkMathSourceFormAttribute] = sourceForm.name;
}

int? _displayClose(String source, int start) {
  var index = start;
  while (index + 1 < source.length) {
    if (source.startsWith(r'$$', index) && !_isEscaped(source, index)) {
      final trailing = source.substring(index + 2);
      return trailing.trim().isEmpty ? index : null;
    }
    index += 1;
  }
  return null;
}

bool _isEscaped(String source, int index) {
  var backslashes = 0;
  for (
    var cursor = index - 1;
    cursor >= 0 && source.codeUnitAt(cursor) == 0x5c;
    cursor -= 1
  ) {
    backslashes += 1;
  }
  return backslashes.isOdd;
}

bool _isWhitespace(int unit) {
  return unit == 0x20 || unit == 0x09 || unit == 0x0a || unit == 0x0d;
}
