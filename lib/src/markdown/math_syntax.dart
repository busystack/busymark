import 'package:markdown/markdown.dart' as md;

import 'busymark_document.dart';
import 'markdown_model.dart';
import 'markdown_source_annotation.dart';
import 'writerside_variable_syntax.dart';
import 'writerside_authoring_syntax.dart';

const busyMarkLiteralLessThanTag = 'busymark-literal-less-than';

const busyMarkMathInlineTag = 'busymark-math-inline';
const busyMarkMathBlockTag = 'busymark-math-block';
const busyMarkMathExpressionAttribute = 'mathExpression';
const busyMarkMathDisplayAttribute = 'mathDisplay';
const busyMarkMathSourceFormAttribute = 'mathSourceForm';
const busyMarkMathRawExpressionAttribute = 'mathRawExpression';

enum BusyMathSourceForm {
  dollarInline,
  githubDollarBacktick,
  doubleDollarDisplay,
  mathFence,
  writersideTexFence,
  writersideTexElement,
  writersideElement,
}

BusyMathSourceForm busyMathSourceFormFromName(String? value) {
  return BusyMathSourceForm.values.firstWhere(
    (form) => form.name == value,
    orElse: () => BusyMathSourceForm.dollarInline,
  );
}

md.Document busyMarkMarkdownDocument(
  MarkdownMode mode, {
  Iterable<md.InlineSyntax> leadingInlineSyntaxes = const [],
}) {
  return md.Document(
    blockSyntaxes: [
      const BusyDisplayMathSyntax(),
      if (mode == MarkdownMode.writersideMarkdown)
        const WritersideSemanticParagraphSyntax(),
      if (mode == MarkdownMode.writersideMarkdown)
        const WritersideDefinitionListSyntax(),
    ],
    inlineSyntaxes: [
      ...leadingInlineSyntaxes,
      if (mode == MarkdownMode.writersideMarkdown)
        WritersideSemanticInlineSyntax(),
      _LiteralLessThanSyntax(),
      if (mode == MarkdownMode.writersideMarkdown)
        WritersideLiteralPercentSyntax(),
      BusyDollarMathSyntax(),
      if (mode == MarkdownMode.writersideMarkdown) BusyWritersideMathSyntax(),
      _BareUrlSyntax(),
    ],
    extensionSet: md.ExtensionSet.gitHubWeb,
    encodeHtml: false,
  );
}

/// Runs only the configured parser's extended autolink grammar. Everything
/// else remains literal, so recognition in displayed prose cannot interpret
/// Markdown delimiters, escapes, HTML, or math as newly authored syntax.
List<({int start, int end, String destination})> busyMarkBareUrlRanges(
  String text, {
  MarkdownMode mode = MarkdownMode.commonMark,
}) {
  final configured = busyMarkMarkdownDocument(mode);
  final document = md.Document(
    inlineSyntaxes: configured.inlineSyntaxes
        .whereType<md.AutolinkExtensionSyntax>(),
    withDefaultInlineSyntaxes: false,
    encodeHtml: false,
  );
  final ranges = <({int start, int end, String destination})>[];
  var offset = 0;
  for (final node in document.parseInline(text)) {
    final end = offset + node.textContent.length;
    if (node is md.Element &&
        node.attributes[busyMarkBareUrlAttribute] == 'true') {
      ranges.add((
        start: offset,
        end: end,
        destination: node.attributes['href']!,
      ));
    }
    offset = end;
  }
  return ranges;
}

// An escaped '<', or '<' followed by a character reference, is literal
// Markdown text. Keep it in a distinct node so the HTML adapter cannot turn
// the decoded text back into markup. The latter form preserves a bare URL's
// boundary without inserting a backslash that its grammar would consume.
class _LiteralLessThanSyntax extends md.InlineSyntax {
  _LiteralLessThanSyntax() : super(r'\\<|<&#[0-9]{1,7};');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final text = match[0] == r'\<'
        ? '<'
        : '<${parser.document.parseInline(match[0]!.substring(1)).map((node) => node.textContent).join()}';
    parser.addNode(md.Element(busyMarkLiteralLessThanTag, [md.Text(text)]));
    return true;
  }
}

// Delegate matching, punctuation trimming, and destination encoding to the
// locked Markdown implementation; attach source form only to bare URLs.
class _BareUrlSyntax extends md.AutolinkExtensionSyntax {
  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final capture = _AutolinkCaptureParser(parser);
    super.onMatch(capture, match);
    final node = capture.node!;
    if (match[1] != null) {
      node.attributes[busyMarkBareUrlAttribute] = 'true';
    }
    parser
      ..addNode(node)
      ..consume(capture.pos - parser.pos);
    return true;
  }
}

class _AutolinkCaptureParser extends md.InlineParser {
  _AutolinkCaptureParser(md.InlineParser parser)
    : super(parser.source, parser.document) {
    pos = parser.pos;
    start = parser.pos;
  }

  md.Element? node;

  @override
  void addNode(md.Node value) {
    node = value as md.Element;
  }
}

/// Returns the exact key the pinned Markdown parser registers for [label].
/// This deliberately uses the parser rather than maintaining a second
/// whitespace or Unicode case-folding implementation in BusyMark.
String? busyMarkParserReferenceLabel(String label) {
  final document = md.Document(encodeHtml: false)..parse('[$label]: /');
  return document.linkReferences.keys.singleOrNull;
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
              sourceStart: start,
              sourceEnd: end + 2,
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
          sourceStart: start,
          sourceEnd: end + 1,
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
    final rawExpression = parser.source.substring(match.end, closeStart);
    if (rawExpression.isEmpty || rawExpression.contains('\n')) {
      parser.addNode(md.Text(match.group(0)!));
      return true;
    }
    final expression = busyMarkDecodeXmlMathText(rawExpression);
    parser.addNode(
      _mathElement(
        busyMarkMathInlineTag,
        expression,
        BusyMathSourceForm.writersideElement,
        display: false,
        rawExpression: rawExpression,
        sourceStart: match.start,
        sourceEnd: closeEnd,
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
  String? rawExpression,
  int? sourceStart,
  int? sourceEnd,
}) {
  return md.Element.text(tag, expression)
    ..attributes[busyMarkMathExpressionAttribute] = expression
    ..attributes[busyMarkMathDisplayAttribute] = '$display'
    ..attributes[busyMarkMathSourceFormAttribute] = sourceForm.name
    ..attributes.addAll({
      if (rawExpression != null)
        busyMarkMathRawExpressionAttribute: rawExpression,
      if (sourceStart != null)
        busyMarkSourceMappingStartAttribute: '$sourceStart',
      if (sourceEnd != null) busyMarkSourceMappingEndAttribute: '$sourceEnd',
    });
}

String busyMarkDecodeXmlMathText(String source) {
  return source.replaceAllMapped(
    RegExp(r'&(?:lt|gt|amp|quot|apos|#[0-9]+|#[xX][0-9A-Fa-f]+);'),
    (match) {
      final entity = match.group(0)!;
      final named = switch (entity) {
        '&lt;' => '<',
        '&gt;' => '>',
        '&amp;' => '&',
        '&quot;' => '"',
        '&apos;' => "'",
        _ => null,
      };
      if (named != null) {
        return named;
      }
      final hexadecimal = entity.startsWith('&#x') || entity.startsWith('&#X');
      final digits = entity.substring(hexadecimal ? 3 : 2, entity.length - 1);
      final codePoint = int.tryParse(digits, radix: hexadecimal ? 16 : 10);
      final validXmlCharacter =
          codePoint != null &&
          (codePoint == 0x09 ||
              codePoint == 0x0a ||
              codePoint == 0x0d ||
              (codePoint >= 0x20 && codePoint <= 0xd7ff) ||
              (codePoint >= 0xe000 && codePoint <= 0xfffd) ||
              (codePoint >= 0x10000 && codePoint <= 0x10ffff));
      if (!validXmlCharacter) {
        return entity;
      }
      return String.fromCharCode(codePoint);
    },
  );
}

String busyMarkEncodeXmlMathText(String source) => source
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

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
