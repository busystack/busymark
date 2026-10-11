import 'package:markdown/markdown.dart' as md;
import 'package:xml/xml.dart';

/// Writerside semantic spans participate in the existing inline parser, so
/// Markdown formatting and links inside a span retain their normal behavior.
class WritersideSemanticInlineSyntax extends md.InlineSyntax {
  WritersideSemanticInlineSyntax()
    : super(
        r'<(control|path|ui-path|shortcut)\b[^>]*(?:/>|>)',
        startCharacter: 0x3c,
      );
  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final tag = match.group(1)!;
    var end = match.end;
    var content = '';
    if (!match.group(0)!.endsWith('/>')) {
      final closing = '</$tag>';
      final close = parser.source.indexOf(closing, end);
      if (close < 0) return false;
      content = parser.source.substring(end, close);
      end = close + closing.length;
    }
    try {
      final opening = match.group(0)!;
      final element = XmlDocumentFragment.parse(
        opening.endsWith('/>')
            ? opening
            : opening.replaceFirst(RegExp(r'>$'), '/>'),
      ).children.whereType<XmlElement>().single;
      parser.addNode(
        md.Element(tag, parser.document.parseInline(content))
          ..attributes.addAll({
            for (final a in element.attributes) a.name.qualified: a.value,
          }),
      );
      parser.consume(end - match.end);
      return true;
    } on Object {
      return false;
    }
  }
}

class WritersideSemanticParagraphSyntax extends md.BlockSyntax {
  const WritersideSemanticParagraphSyntax();
  @override
  RegExp get pattern => RegExp(r'^ {0,3}<(?:control|path|ui-path|shortcut)\b');
  @override
  md.Node parse(md.BlockParser parser) {
    final lines = <String>[];
    while (!parser.isDone && parser.current.content.trim().isNotEmpty) {
      lines.add(parser.current.content);
      parser.advance();
    }
    return md.Element('p', parser.document.parseInline(lines.join('\n')));
  }
}

/// The documented term / colon form. Multiple definitions and indented body
/// lines stay in their original pair instead of being flattened into prose.
class WritersideDefinitionListSyntax extends md.BlockSyntax {
  const WritersideDefinitionListSyntax();
  @override
  RegExp get pattern => RegExp(r'^\S');
  @override
  bool canParse(md.BlockParser parser) {
    if (parser.isDone) return false;
    final offset = _attributes(parser.current.content) == null ? 1 : 2;
    return parser.peek(offset) != null &&
        RegExp(r'^:\s+').hasMatch(parser.peek(offset)!.content);
  }

  @override
  md.Node parse(md.BlockParser parser) {
    final attributes =
        _attributes(parser.current.content) ?? const <String, String>{};
    if (attributes.isNotEmpty) parser.advance();
    final definitions = <md.Node>[];
    while (canParse(parser)) {
      final term = parser.current.content;
      parser.advance();
      final body = <String>[
        parser.current.content.replaceFirst(RegExp(r'^:\s+'), ''),
      ];
      parser.advance();
      while (!parser.isDone &&
          RegExp(r'^ {2,}\S').hasMatch(parser.current.content)) {
        body.add(parser.current.content.replaceFirst(RegExp(r'^ {2,4}'), ''));
        parser.advance();
      }
      definitions.add(
        md.Element('def', parser.document.parseLines(body))
          ..attributes['title'] = term,
      );
      if (!parser.isDone &&
          parser.current.content.trim().isEmpty &&
          parser.peek(1) != null &&
          parser.peek(2) != null &&
          RegExp(r'^:\s+').hasMatch(parser.peek(2)!.content)) {
        parser.advance();
      }
    }
    return md.Element('deflist', definitions)
      ..attributes.addAll({
        ...attributes,
        'busymark-definition-form': 'markdown',
      });
  }

  Map<String, String>? _attributes(String source) {
    final value = source.trim();
    if (!value.startsWith('{') || !value.endsWith('}')) return null;
    final result = <String, String>{};
    for (final match in RegExp(
      r'''([\w:-]+)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s}]+))''',
    ).allMatches(value.substring(1, value.length - 1))) {
      result[match[1]!] = match[2] ?? match[3] ?? match[4]!;
    }
    return result.isEmpty ? null : result;
  }
}
